#!/usr/bin/env ruby
# frozen_string_literal: true

# Break Escape Scenario Validator
# Validates scenario.json.erb files by rendering ERB to JSON and checking against schema
#
# Usage:
#   ruby scripts/validate_scenario.rb scenarios/ceo_exfil/scenario.json.erb
#   ruby scripts/validate_scenario.rb scenarios/ceo_exfil/scenario.json.erb --schema scripts/scenario-schema.json

require 'erb'
require 'json'
require 'optparse'
require 'pathname'
require 'set'
require 'base64'

# Try to load json-schema gem, provide helpful error if missing
begin
  require 'json-schema'
rescue LoadError
  $stderr.puts <<~ERROR
    ERROR: json-schema gem is required for validation.

    Install it with:
      gem install json-schema

    Or add to Gemfile:
      gem 'json-schema'

    Then run: bundle install
  ERROR
  exit 1
end

# ScenarioBinding class - replicates the one from app/models/break_escape/mission.rb
class ScenarioBinding
  def initialize(vm_context = {})
    require 'securerandom'
    @random_password = SecureRandom.alphanumeric(8)
    @random_pin = rand(1000..9999).to_s
    @random_code = SecureRandom.hex(4)
    @vm_context = vm_context || {}
  end

  attr_reader :random_password, :random_pin, :random_code, :vm_context

  # Get a VM from the context by title, or return a fallback VM object
  def vm_object(title, fallback = {})
    if vm_context && vm_context['hacktivity_mode'] && vm_context['vms']
      vm = vm_context['vms'].find { |v| v['title'] == title }
      return vm.to_json if vm
    end

    result = fallback.dup
    if vm_context && vm_context['vm_ips'] && vm_context['vm_ips'][title]
      result['ip'] = vm_context['vm_ips'][title]
    end
    result.to_json
  end

  # Get flags for a specific VM from the context
  def flags_for_vm(vm_name, fallback = [])
    if vm_context && vm_context['flags_by_vm']
      flags = vm_context['flags_by_vm'][vm_name]
      return flags.to_json if flags
    end
    fallback.to_json
  end

  # Get VM flags as a JSON array for use in the top-level 'flags' object.
  # Mirrors flags_for_vm but used in the top-level flags: { vm_name: vm_flags_json('vm_name') } pattern.
  def vm_flags_json(vm_name, fallback = [])
    flags_for_vm(vm_name, fallback)
  end

  def get_binding
    binding
  end
end

# Load valid item types from the objects asset directory.
# Returns a Set of type strings (filenames without .png extension), or nil if the directory
# cannot be found (in which case callers should skip the check).
def load_valid_item_types(base_dir)
  assets_dir = File.join(base_dir, 'public', 'break_escape', 'assets', 'objects')
  return nil unless Dir.exist?(assets_dir)

  types = Dir.glob(File.join(assets_dir, '*.png')).map do |f|
    File.basename(f, '.png')
  end
  Set.new(types)
end

# Render ERB template to JSON
def render_erb_to_json(erb_path, vm_context = {}, include_rendered: false)
  unless File.exist?(erb_path)
    raise "ERB file not found: #{erb_path}"
  end

  erb_content = File.read(erb_path)
  erb = ERB.new(erb_content)
  binding_context = ScenarioBinding.new(vm_context)
  json_output = erb.result(binding_context.get_binding)

  parsed = JSON.parse(json_output)
  include_rendered ? [parsed, json_output] : parsed
rescue JSON::ParserError => e
  raise "Invalid JSON after ERB processing: #{e.message}\n\nGenerated JSON:\n#{json_output}"
rescue StandardError => e
  raise "Error processing ERB: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
end

# Parse top-level JSON keys directly from rendered text so duplicate keys can be detected
# before JSON.parse key-collision overwrite semantics hide them.
def top_level_key_counts(json_text)
  counts = Hash.new(0)
  i = 0
  depth = 0

  while i < json_text.length
    ch = json_text[i]

    if ch == '"'
      key_text, next_idx = read_json_string(json_text, i)

      if depth == 1
        j = next_idx
        j += 1 while j < json_text.length && json_text[j].match?(/\s/)
        counts[key_text] += 1 if j < json_text.length && json_text[j] == ':'
      end

      i = next_idx
      next
    end

    if ch == '{'
      depth += 1
    elsif ch == '}'
      depth -= 1 if depth > 0
    end

    i += 1
  end

  counts
end

def read_json_string(json_text, start_idx)
  out = +' '
  out.clear
  i = start_idx + 1
  escaped = false

  while i < json_text.length
    ch = json_text[i]

    if escaped
      out << ch
      escaped = false
    elsif ch == '\\'
      out << ch
      escaped = true
    elsif ch == '"'
      return [out, i + 1]
    else
      out << ch
    end

    i += 1
  end

  # Unterminated string: return what we captured so caller can continue safely.
  [out, i]
end

def check_duplicate_show_scenario_brief(rendered_json)
  issues = []
  key_count = top_level_key_counts(rendered_json)['show_scenario_brief']

  if key_count > 1
    issues << "❌ INVALID: Top-level field 'show_scenario_brief' is defined #{key_count} times. Keep exactly one declaration. Use 'show_scenario_brief': 'on_resume' when using an opening timedConversation briefing so both UIs do not appear at mission start."
  end

  issues
end

# Validate JSON against schema
def validate_json(json_data, schema_path)
  unless File.exist?(schema_path)
    raise "Schema file not found: #{schema_path}"
  end

  schema = JSON.parse(File.read(schema_path))
  errors = JSON::Validator.fully_validate(schema, json_data, strict: false)

  errors
rescue JSON::ParserError => e
  raise "Invalid JSON schema: #{e.message}"
end

# Validate that scenario follows proper directory structure
# Scenarios must be in their own directory with a mission.json file
def check_scenario_directory_structure(erb_path)
  # Get the directory containing the scenario.json.erb file
  scenario_dir = File.dirname(erb_path)
  scenario_name = File.basename(scenario_dir)

  # Expected mission.json path
  mission_json_path = File.join(scenario_dir, 'mission.json')

  issues = []

  # Check that mission.json exists in the scenario directory
  unless File.exist?(mission_json_path)
    issues << "❌ INVALID: Scenario directory '#{scenario_name}/' is missing required 'mission.json' file. Structure should be: scenarios/#{scenario_name}/mission.json"
  end

  # Validate mission.json structure if it exists
  if File.exist?(mission_json_path)
    begin
      mission = JSON.parse(File.read(mission_json_path))

      # Check required fields
      required_fields = %w[display_name description difficulty_level]
      missing_fields = required_fields.filter { |field| !mission.key?(field) || mission[field].to_s.strip.empty? }

      if missing_fields.any?
        issues << "❌ INVALID: mission.json is missing required fields: #{missing_fields.join(', ')}"
      end
    rescue JSON::ParserError => e
      issues << "❌ INVALID: mission.json contains invalid JSON: #{e.message}"
    rescue StandardError => e
      issues << "❌ INVALID: Error reading mission.json: #{e.message}"
    end
  end

  issues
end

# Check for unknown fields in JSON that aren't in the schema
def check_unknown_fields(json_data)
  warnings = []

  # Known top-level fields
  known_top_level = %w[
    scenario_id scenario_name scenario_brief endGoal version startRoom startPosition
    show_scenario_brief flags music startItemsInInventory globalVariables
    player objectives rooms npcs phoneNPCs narrator timers _comment
  ]

  # Check top-level unknown fields
  json_data.each_key do |key|
    unless known_top_level.include?(key)
      warnings << "⚠️ WARNING: Top-level field '#{key}' is not recognized in the schema — this field will be ignored by the game engine. Remove it if not needed, or check if the spelling is correct."
    end
  end

  # Known room fields
  known_room_fields = %w[
    type door_sign connections locked lockType requires keyPins difficulty
    ambientSound ambientVolume objects npcs _comment dimensions
  ]

  # Known NPC fields
  known_npc_fields = %w[
    id displayName npcType position spriteSheet spriteTalk spriteConfig
    voice behavior globalVarOnKO taskOnKO storyPath currentKnot avatar
    phoneId phoneTheme unlockable externalVariables persistentVariables
    timedMessages timedConversation eventMappings itemsHeld puzzle_graph_actions
    observations disableClose los _comment
  ]

  # Known NPC behavior fields
  known_behavior_fields = %w[
    initiallyHidden immovable hostile facePlayer patrol staticSprite collisionBox _comment
  ]

  # Known eventMapping fields
  known_event_mapping_fields = %w[
    eventPattern condition onceOnly maxTriggers cooldown
    bark message barkDelay
    targetKnot conversationMode background disableClose
    patrolOverride setPatrolSpeed setDwellMultiplier setVisible
    sendTimedMessage setGlobal completeTask unlockTask unlockAim
    _comment
  ]

  # Load minigameData schemas (flat map; entries with _dispatch:"lockType" are matched by lockType)
  minigame_schemas_path = File.join(__dir__, 'minigame-data-schemas.json')
  minigame_schemas = if File.exist?(minigame_schemas_path)
    JSON.parse(File.read(minigame_schemas_path)).reject { |k, _| k.start_with?('_') }
  else
    {}
  end

  check_minigame_data = lambda do |obj, path|
    md = obj['minigameData']
    return unless md.is_a?(Hash)

    schema      = minigame_schemas[obj['type']] || minigame_schemas[obj['lockType']] || minigame_schemas[obj['id']]
    schema_key  = [obj['type'], obj['lockType'], obj['id']].find { |k| k && minigame_schemas[k] }
    unless schema
      dispatch_key = obj['type'] || obj['lockType'] || obj['id']
      warnings << "⚠️ WARNING: '#{path}' has minigameData but no schema is defined for '#{dispatch_key}' — add an entry to minigame-data-schemas.json."
      return
    end

    required = schema['required'] || []
    optional = schema['optional'] || []
    known    = (required + optional + ['_comment']).to_set

    missing = required.reject { |k| md.key?(k) && !md[k].nil? }
    missing.each do |k|
      warnings << "❌ ERROR: '#{path}' minigameData is missing required field '#{k}'."
    end

    md.each_key do |k|
      unless known.include?(k)
        warnings << "❌ ERROR: '#{path}' minigameData has undeclared field '#{k}' — not in schema for '#{schema_key}'. Add it to minigame-data-schemas.json or remove it."
      end
    end
  end

  # Known item (object) fields — any unknown field should be inside minigameData
  known_item_fields = %w[
    type id name takeable readable interactable active locked important
    position observations observationVariants observationDisplay
    text textVariants
    voice ttsVoice sender timestamp avatar sprite
    collection_group onRead onPickup onInteract
    lockType requires key_id keyPins card_id difficulty
    passwordHint showHint showKeyboard maxAttempts
    postitNote showPostit
    hasFingerprint fingerprintOwner fingerprintDifficulty
    mac canScanBluetooth phoneId npcIds
    hacktivityMode vm acceptsVms flags flagRewards
    mode onAbort onLaunch abortConfirmText launchConfirmText
    itemsHeld contents triggerOnInteract
    minigameData
    gateVar sealedMessage openableReadyMessage
    puzzle_graph_role puzzle_graph_aim puzzle_graph_unlocks
    puzzle_graph_and_with puzzle_graph_reveals puzzle_graph_optional puzzle_graph_note
    storyPath currentKnot
    completesTask completesTaskOnOpen
    puzzle_graph_links
    _comment
  ]

  check_item_fields = lambda do |item, path|
    next unless item.is_a?(Hash)
    item.each_key do |key|
      unless known_item_fields.include?(key)
        warnings << "⚠️ WARNING: '#{path}' has unknown field '#{key}' — if this is minigame-specific configuration data, nest it under 'minigameData' instead."
      end
    end
    item['contents']&.each_with_index { |c, i| check_item_fields.call(c, "#{path}/contents[#{i}](#{c['id'] || c['type'] || '?'})") }
    item['itemsHeld']&.each_with_index { |c, i| check_item_fields.call(c, "#{path}/itemsHeld[#{i}](#{c['type'] || '?'})") }
  end

  # Check startItemsInInventory fields
  json_data['startItemsInInventory']&.each_with_index do |item, idx|
    next unless item.is_a?(Hash)
    inv_path = "startItemsInInventory[#{idx}](#{item['id'] || item['type'] || '?'})"
    check_item_fields.call(item, inv_path)
    check_minigame_data.call(item, inv_path)
  end

  # Check room fields and recurse into NPCs and objects
  if json_data['rooms']
    json_data['rooms'].each do |room_id, room|
      next unless room.is_a?(Hash)
      room.each_key do |key|
        unless known_room_fields.include?(key)
          warnings << "⚠️ WARNING: Room '#{room_id}' has unknown field '#{key}' — this field will be ignored by the game engine."
        end
      end

      # Check object fields
      room['objects']&.each_with_index do |obj, idx|
        next unless obj.is_a?(Hash)
        obj_path = "rooms/#{room_id}/objects[#{idx}](#{obj['id'] || obj['name'] || '?'})"
        check_item_fields.call(obj, obj_path)
        check_minigame_data.call(obj, obj_path)
      end

      # Check NPC fields
      room['npcs']&.each_with_index do |npc, idx|
        next unless npc.is_a?(Hash)
        npc_path = "rooms/#{room_id}/npcs[#{idx}](#{npc['id'] || '?'})"
        npc.each_key do |key|
          unless known_npc_fields.include?(key)
            warnings << "⚠️ WARNING: '#{npc_path}' has unknown field '#{key}' — this field will be ignored by the game engine."
          end
        end

        # Check NPC behavior fields
        if npc['behavior'].is_a?(Hash)
          npc['behavior'].each_key do |key|
            unless known_behavior_fields.include?(key)
              warnings << "⚠️ WARNING: '#{npc_path}/behavior' has unknown field '#{key}' — this field will be ignored by the game engine."
            end
          end
        end

        # Check eventMapping fields
        npc['eventMappings']&.each_with_index do |mapping, midx|
          next unless mapping.is_a?(Hash)
          mapping_path = "#{npc_path}/eventMappings[#{midx}]"
          mapping.each_key do |key|
            unless known_event_mapping_fields.include?(key)
              warnings << "⚠️ WARNING: '#{mapping_path}' has unknown field '#{key}' — this field will be ignored by the game engine."
            end
          end
        end
      end
    end
  end

  warnings
end

# Pre-validation: check critical structure issues before schema validation
# This prevents cryptic nil errors from deeply nested code
def check_structure_validity(json_data)
  issues = []

  # Validate rooms structure
  if json_data.key?('rooms')
    if json_data['rooms'].is_a?(Array)
      issues << "❌ INVALID: 'rooms' must be a JSON object {}, not an array []. Structure should be: \"rooms\": { \"room_id\": { ... }, \"another_room\": { ... } }"
    elsif !json_data['rooms'].is_a?(Hash)
      issues << "❌ INVALID: 'rooms' must be a JSON object {} (hash), got #{json_data['rooms'].class}"
    end
  end

  # Validate startItemsInInventory structure
  if json_data.key?('startItemsInInventory')
    if json_data['startItemsInInventory'].is_a?(Hash)
      issues << "❌ INVALID: 'startItemsInInventory' must be a JSON array [], not an object {}. Structure should be: \"startItemsInInventory\": [ { \"type\": \"phone\", \"name\": \"...\" }, ... ]"
    elsif !json_data['startItemsInInventory'].is_a?(Array)
      issues << "❌ INVALID: 'startItemsInInventory' must be a JSON array [], got #{json_data['startItemsInInventory'].class}"
    end
  end

  # Validate NPCs structure if present
  if json_data.key?('npcs')
    if !json_data['npcs'].is_a?(Array)
      issues << "❌ INVALID: 'npcs' must be a JSON array [], got #{json_data['npcs'].class}"
    end
  end

  # Validate objectives structure if present
  if json_data.key?('objectives')
    if !json_data['objectives'].is_a?(Array)
      issues << "❌ INVALID: 'objectives' must be a JSON array [], got #{json_data['objectives'].class}"
    end
  end

  issues
end

# Check that ink files exist and compile
def check_ink_files(json_data, base_dir, scenario_dir = nil)
  issues = []
  ink_files_to_check = Set.new

  # Collect all referenced ink files from NPCs
  json_data['rooms']&.each do |room_id, room|
    room['npcs']&.each_with_index do |npc, idx|
      if npc['storyPath']
        path = "rooms/#{room_id}/npcs[#{idx}]"
        items_held = npc['itemsHeld'] || []
        items_held_types = (npc['itemsHeld'] || []).map { |item| item['type'] }.compact
        ink_files_to_check.add({ path: path, storyPath: npc['storyPath'], items_held_types: items_held_types, items_held: items_held })
      end
    end
  end

  # Check each ink file
  ink_files_to_check.each do |entry|
    story_path = entry[:storyPath]
    npc_path = entry[:path]

    # Enforce that storyPath uses the full scenarios/ relative path format
    if story_path.start_with?('ink/')
      issues << "❌ INVALID: '#{npc_path}' uses deprecated relative path '#{story_path}'. Must use full path format: \"scenarios/SCENARIO_NAME/ink/FILENAME.ink.json\" (e.g., \"scenarios/test_npc_visibility/ink/test_dispatcher.ink.json\")"
      next
    end

    unless story_path.start_with?('scenarios/')
      issues << "❌ INVALID: '#{npc_path}' storyPath '#{story_path}' must start with 'scenarios/' (e.g., \"scenarios/SCENARIO_NAME/ink/FILENAME.ink.json\"). Absolute paths and other relative paths are not supported."
      next
    end

    # Determine the correct path to check for the ink file
    json_path = story_path.sub(/\.ink$/, '.json')

    # Resolve relative to repo root
    full_json_path = File.join(base_dir, json_path)
    full_ink_path = File.join(base_dir, story_path.sub(/\.json$/, '.ink'))

    source_ink_path = story_path.sub(/\.json$/, '.ink')
    inklecate_bin = File.join(base_dir, 'bin', 'inklecate')

    if full_ink_path && File.exist?(full_ink_path)
      # Source .ink exists — compile it to disk (creates/overwrites the JSON)
      begin
        output = `"#{inklecate_bin}" -o "#{full_json_path}" "#{full_ink_path}" 2>&1`
        status = $?.exitstatus

        if status != 0 || output.include?('ERROR') || output.include?('error')
          issues << "❌ INVALID: '#{npc_path}' references ink file '#{source_ink_path}' which fails to compile:\n#{output.strip}"
        elsif !File.exist?(full_json_path)
          issues << "❌ INVALID: '#{npc_path}' references ink file '#{source_ink_path}' — compiled but output file was not created"
        else
          # Verify the output is valid JSON
          begin
            JSON.parse(File.read(full_json_path))
          rescue JSON::ParserError => e
            issues << "❌ INVALID: '#{npc_path}' compiled ink file produced invalid JSON: #{e.message}"
          end
        end
      rescue => e
        issues << "❌ INVALID: '#{npc_path}' references ink file '#{source_ink_path}' but compilation failed: #{e.message}"
      end

      # Check for #give_item tags placed after a dialogue/text line.
      # In Break Escape, the tag must appear BEFORE the dialogue line so that the item transfer
      # fires on the same story.Continue() call as the text that describes it. A tag on the
      # line immediately after dialogue is attached to that preceding text in Ink semantics,
      # which in some engine paths causes the tag to fire on a later Continue() with no NPC
      # context, silently dropping the item give.
      begin
        ink_lines = File.readlines(full_ink_path)
        ink_lines.each_with_index do |line, i|
          stripped = line.strip
          next unless stripped.start_with?('#give_item:')

          # Find the nearest preceding non-blank line
          j = i - 1
          j -= 1 while j >= 0 && ink_lines[j].strip.empty?
          next if j < 0

          prev = ink_lines[j].strip
          # Skip if preceding line is a tag, choice, divert, code, knot/stitch header, comment, or brace
          next if prev.start_with?('#', '*', '+', '->', '~', '=', '//', '{', '}')
          next if prev.empty?

          item_type = stripped.sub(/^#give_item:/, '').strip
          issues << "⚠️ WARNING: '#{source_ink_path}' line #{i + 1}: '#give_item:#{item_type}' appears after " \
                    "a text/dialogue line. Move '#give_item:#{item_type}' to the line immediately BEFORE " \
                    "the dialogue so the item transfer fires on the same story.Continue() call. " \
                    "Wrong: dialogue → tag. Correct: tag → dialogue."
        end

        # Cross-reference: every #give_item:type used in this file must match an item
        # in the NPC's itemsHeld array. If not, the give will silently fail at runtime.
        items_held_types = entry[:items_held_types] || []
        items_held = entry[:items_held] || []
        ink_lines.each_with_index do |line, i|
          stripped = line.strip
          next unless stripped.start_with?('#give_item:')

          item_spec = stripped.sub(/^#give_item:/, '').strip
          item_type, item_selector = item_spec.split(/[|:]/, 2).map(&:strip)

          if item_selector.nil? || item_selector.empty?
            unless items_held_types.include?(item_type)
              issues << "❌ INVALID: '#{source_ink_path}' line #{i + 1}: '#give_item:#{item_spec}' but " \
                        "NPC '#{npc_path}' has no item with type '#{item_type}' in itemsHeld. " \
                        "Add { \"type\": \"#{item_type}\", ... } to the NPC's itemsHeld array in the scenario JSON."
            end
          else
            matches_selector = items_held.any? do |item|
              next false unless item['type'] == item_type

              candidates = [item['id'], item['key_id'], item['name']].compact.map(&:to_s)
              candidates.include?(item_selector)
            end

            unless matches_selector
              issues << "❌ INVALID: '#{source_ink_path}' line #{i + 1}: '#give_item:#{item_spec}' but " \
                        "NPC '#{npc_path}' has no itemsHeld entry matching type '#{item_type}' and selector '#{item_selector}' " \
                        "(selector checks id, key_id, or name)."
            end
          end
        end
      rescue => e
        # Non-fatal — file was already compiled successfully above
      end
    elsif File.exist?(full_json_path)
      # No source .ink — validate the existing compiled JSON
      begin
        json_content = File.read(full_json_path)
        JSON.parse(json_content)
      rescue JSON::ParserError => e
        issues << "❌ INVALID: '#{npc_path}' references compiled ink file '#{story_path}' but the file contains invalid JSON: #{e.message}"
      rescue => e
        issues << "❌ INVALID: '#{npc_path}' references compiled ink file '#{story_path}' but failed to read it: #{e.message}"
      end
    else
      issues << "❌ INVALID: '#{npc_path}' references ink file '#{story_path}' which does not exist (checked for both .json and .ink versions)"
    end
  end

  issues
end

# Check that objective task completion events are correctly wired.
#
# Three failure modes caught here, each stemming from a real bug in sis01_healthcare:
#
# 1. npc_conversation tasks whose target NPC ink file has no #complete_task:<taskId> tag.
#    The engine's only mechanism for this task type is chat-helpers.js processing that tag,
#    or the NPC being knocked out with taskOnKO set.  Without one of those two paths the
#    task counter never moves.
#
# 2. unlock_object tasks whose target object has a lockType that is not in the known set
#    of types that emit the 'item_unlocked' event.  Standard lock types (password, pin,
#    rfid, bluetooth, key) all call unlockTarget() which emits the event.  Custom minigame
#    lock types may not — the validator warns so the author can verify or fix the minigame.
#
# 3. collect_items tasks that match notes-family items (type: notes, notes2, …) where the
#    item is missing readable: true or a non-empty text field.  interactions.js only enters
#    the notes branch (which emits item_picked_up) when BOTH fields are present.  Without
#    them the item is silently registered server-side but the task counter never increments.
def check_objectives_wiring(json_data, base_dir)
  issues = []
  return issues unless json_data['objectives']&.any?

  # Build lookup maps from room contents
  npc_info_by_id = {}       # npc_id => { story_path:, task_on_ko:, room_id: }
  all_objects_by_id = {}    # object_id => object hash
  objects_by_group = {}     # collection_group => [object, …]

  collect_item = lambda do |item|
    all_objects_by_id[item['id']] = item if item['id']
    if item['collection_group']
      objects_by_group[item['collection_group']] ||= []
      objects_by_group[item['collection_group']] << item
    end
    item['contents']&.each  { |c| collect_item.call(c) }
    item['itemsHeld']&.each { |c| collect_item.call(c) }
  end

  json_data['rooms']&.each do |room_id, room|
    room['npcs']&.each do |npc|
      next unless npc['id']
      npc_info_by_id[npc['id']] = {
        story_path:  npc['storyPath'],
        task_on_ko:  npc['taskOnKO'],
        room_id:     room_id
      }
    end
    room['objects']&.each { |obj| collect_item.call(obj) }
  end
  json_data['startItemsInInventory']&.each { |item| collect_item.call(item) }

  # All items by type (for targetItems array matching)
  all_objects_list = all_objects_by_id.values

  # Lock types guaranteed to emit 'item_unlocked' via unlockTarget() or their own emit.
  # Standard types call unlockTarget() in unlock-system.js.
  # Extended types have explicit window.eventDispatcher.emit('item_unlocked', …) calls.
  standard_unlock_types  = %w[password pin rfid bluetooth key].freeze
  # ransomware_display is intentionally absent: the object stays locked (ransom is never
  # paid), so it completes tasks via completesTask + task_completed_by_npc, not item_unlocked.
  # Use a manual task type and set completesTask on the scenario object instead.
  extended_unlock_types  = %w[
    siem_dashboard network-segmentation-map
    backup_recovery dual_auth infusion_pump ehr-terminal command_board
    esd-pushbutton
  ].freeze
  all_unlock_emitting_types = (standard_unlock_types + extended_unlock_types).freeze

  json_data['objectives']&.each_with_index do |aim, oi|
    aim['tasks']&.each_with_index do |task, ti|
      task_path = "objectives[#{oi}]/tasks[#{ti}] (#{task['taskId']})"
      task_id   = task['taskId']

      case task['type']

      # ─────────────────────────────────────────────────────────────
      # CHECK 1  npc_conversation — #complete_task tag in ink
      # ─────────────────────────────────────────────────────────────
      when 'npc_conversation'
        target_npc = task['targetNPC']
        next unless target_npc

        npc = npc_info_by_id[target_npc]
        unless npc
          # NPC ID mismatch already caught by targetNPC cross-ref check; skip here.
          next
        end

        # taskOnKO is a valid alternative completion path — skip ink check.
        if npc[:task_on_ko] == task_id
          next
        end

        story_path = npc[:story_path]
        unless story_path
          issues << "❌ INVALID: #{task_path} is type 'npc_conversation' targeting NPC '#{target_npc}', " \
                    "but that NPC has no 'storyPath'. Without an Ink story the '#complete_task:#{task_id}' " \
                    "tag can never fire. Add a storyPath to the NPC or use taskOnKO to complete the task " \
                    "when the NPC is knocked out."
          next
        end

        # Resolve compiled .json and source .ink paths (storyPath may end in .ink or .json)
        json_relative = story_path.sub(/\.ink$/, '.json')
        ink_relative  = story_path.sub(/\.json$/, '.ink')
        full_json = File.join(base_dir, json_relative)
        full_ink  = File.join(base_dir, ink_relative)

        content_to_search = nil
        searched_file     = nil

        if File.exist?(full_json)
          content_to_search = File.read(full_json)
          searched_file = json_relative
        elsif File.exist?(full_ink)
          content_to_search = File.read(full_ink)
          searched_file = ink_relative
        else
          # Ink file missing — already caught by check_ink_files; skip.
          next
        end

        tag = "complete_task:#{task_id}"
        unless content_to_search.include?(tag)
          issues << "❌ INVALID: #{task_path} is type 'npc_conversation' targeting NPC '#{target_npc}', " \
                    "but '##{tag}' was not found in '#{searched_file}'. " \
                    "The engine completes npc_conversation tasks only when chat-helpers.js processes a " \
                    "'#complete_task:#{task_id}' ink tag (or when the NPC is knocked out and taskOnKO matches). " \
                    "Add '##{tag}' to the NPC's Ink story — typically at the top of the '=== start ===' knot " \
                    "so it fires on every conversation, or inside the specific knot where the task is resolved."
        end

      # ─────────────────────────────────────────────────────────────
      # CHECK 2  unlock_object — lockType must emit item_unlocked
      # ─────────────────────────────────────────────────────────────
      when 'unlock_object'
        target_id = task['targetObject']
        next unless target_id

        obj = all_objects_by_id[target_id]
        next unless obj  # Missing object already flagged by targetObject cross-ref check.

        lock_type = obj['lockType']
        next unless lock_type  # Unlocked objects can only be targeted via other mechanisms.

        next if all_unlock_emitting_types.include?(lock_type)

        issues << "⚠️ WARNING: #{task_path} is type 'unlock_object' targeting '#{target_id}' " \
                  "(lockType: '#{lock_type}'). This lockType is not in the known set of types that emit " \
                  "the 'item_unlocked' event (which is how unlock_object tasks complete). " \
                  "Standard types (#{standard_unlock_types.join(', ')}) all call unlockTarget() in " \
                  "unlock-system.js which emits the event. " \
                  "Verify that the '#{lock_type}' minigame calls " \
                  "window.eventDispatcher.emit('item_unlocked', { itemId: …, itemType: …, itemName: … }) " \
                  "on completion, or add it. Known safe extended types: #{extended_unlock_types.join(', ')}."

      # ─────────────────────────────────────────────────────────────
      # CHECK 3  collect_items — notes items need readable + text
      # ─────────────────────────────────────────────────────────────
      when 'collect_items'
        # Collect candidate items matched by this task's targeting strategy.
        candidates = []

        if task['targetGroup']
          candidates.concat(objects_by_group[task['targetGroup']] || [])
        end

        if task['targetItemIds']
          task['targetItemIds'].each do |item_id|
            obj = all_objects_by_id[item_id]
            candidates << obj if obj
          end
        end

        if task['targetItems']
          task['targetItems'].each do |type_name|
            matched = all_objects_list.select { |o| o['type'] == type_name }
            candidates.concat(matched)
          end
        end

        candidates.uniq.each do |item|
          next unless /^notes\d*$/.match?(item['type'].to_s)

          item_label = item['id'] || item['name'] || item['type']

          unless item['readable']
            issues << "❌ INVALID: #{task_path} (collect_items) targets item '#{item_label}' " \
                      "(type: #{item['type']}), but the item is missing 'readable: true'. " \
                      "interactions.js only enters the notes branch — which emits 'item_picked_up' " \
                      "and drives task progress — when both 'readable: true' and a non-empty 'text' " \
                      "field are present. Without 'readable: true' the item is silently collected " \
                      "server-side but the task counter never increments. Add 'readable: true' to the item."
          end

          if item['text'].to_s.strip.empty?
            issues << "❌ INVALID: #{task_path} (collect_items) targets item '#{item_label}' " \
                      "(type: #{item['type']}), but the item has no 'text' field (or it is empty). " \
                      "interactions.js only enters the notes branch — which emits 'item_picked_up' " \
                      "and drives task progress — when both 'readable: true' and a non-empty 'text' " \
                      "field are present. Without 'text' the notes minigame never opens and the task " \
                      "counter never increments. Add readable text content to the item."
          end
        end

      end
    end
  end

  issues
end

# Check for common issues and structural problems
def check_common_issues(json_data, valid_item_types = nil)
  issues = []

  # Recursive helper: check item type and all nested contents/itemsHeld
  # A type is valid if an exact asset file exists, OR if any numbered/variant file starting with
  # that type name exists (e.g. type "safe" is valid when safe1.png, safe2.png etc. exist).
  check_item_type = lambda do |item, item_path|
    if valid_item_types && item['type']
      t = item['type']
      exact_match = valid_item_types.include?(t)
      variant_match = !exact_match && valid_item_types.any? { |v| v.start_with?(t) }
      unless exact_match || variant_match
        issues << "❌ INVALID: '#{item_path}' has type '#{t}' but no matching sprite found at assets/objects/#{t}.png (nor any #{t}*.png variant) — check the spelling or add the asset"
      end
    end
    item['contents']&.each_with_index { |c, i| check_item_type.call(c, "#{item_path}/contents[#{i}]") }
    item['itemsHeld']&.each_with_index { |c, i| check_item_type.call(c, "#{item_path}/itemsHeld[#{i}]") }
  end
  start_room_id = json_data['startRoom']
  if json_data.dig('player', 'startRoom')
    issues << "❌ ERROR: 'startRoom' must be a top-level field, not nested under 'player'. Move it to the top level and remove player.startRoom."
  end
  if start_room_id.nil?
    issues << "❌ ERROR: Missing top-level 'startRoom' — every scenario must declare which room the player starts in."
  end

  # Valid directions for room connections
  valid_directions = %w[north south east west]

  # Track features for suggestions
  has_vm_launcher = false
  has_flag_station = false
  has_pc_with_files = false
  has_phone_npc_with_messages = false
  has_phone_npc_with_events = false
  has_opening_cutscene = false
  has_opening_briefing_timed_conversation = false
  has_closing_debrief = false
  has_person_npcs = false
  has_npc_with_waypoints = false
  has_phone_contacts = false
  phone_npcs_without_messages = []
  lock_types_used = Set.new
  has_rfid_lock = false
  has_bluetooth_lock = false
  has_pin_lock = false
  has_password_lock = false
  has_key_lock = false
  has_security_tools = false
  has_container_with_contents = false
  has_readable_items = false
  has_music = json_data.key?('music')
  has_launch_device = false
  has_hostile_npcs = false
  has_global_var_on_ko = false
  has_skip_if_global = false
  has_collection_groups = false
  # For cross-reference checks
  collection_groups_used = Set.new  # collection_group values on items
  target_groups_used = Set.new      # targetGroup values on tasks
  all_npc_ids = Set.new             # all NPC IDs in rooms
  all_room_ids = Set.new            # all room IDs
  all_object_ids = Set.new          # all object IDs with explicit id field
  has_puzzle_graph_metadata = false # true if any object/item has puzzle_graph_unlocks
  puzzle_graph_unlock_targets = []  # [{target: str, path: str}] for post-loop cross-ref
  locked_room_ids = Set.new         # room IDs that are locked (for graph key-coverage analysis)
  locked_objects_info = []          # [{path:, name:, useful:}] locked containers for dead-end check
  vm_launcher_room_ids = Set.new    # room IDs containing a vm-launcher (any variant)
  lockpick_items = []               # [{path:, has_unlocks:}] lockpick items for graph annotation check
  key_locked_targets = []           # [{path:, name:}] all key-lockable things (lockType: 'key') for hint list

  # Collect global variables defined in scenario (needed for cross-reference checks)
  global_variables_defined = Set.new
  if json_data['globalVariables']
    global_variables_defined.merge(json_data['globalVariables'].keys)
  end

  # Collect all valid task IDs from objectives (for taskOnKO and requiresCompleted cross-reference)
  all_task_ids = Set.new
  json_data['objectives']&.each do |obj|
    obj['tasks']&.each { |t| all_task_ids.add(t['taskId']) if t['taskId'] }
  end

  # Validate missionConclusion / requiresCompleted / conclusionScreen on aims
  mission_conclusion_aims = json_data['objectives']&.select { |a| a['missionConclusion'] } || []
  if mission_conclusion_aims.size > 1
    issues << "❌ ERROR: Multiple aims have missionConclusion:true (#{mission_conclusion_aims.map { |a| a['aimId'] }.join(', ')}). At most one aim per scenario may be the conclusion aim."
  end
  json_data['objectives']&.each do |aim|
    aim_path = "objectives/#{aim['aimId']}"
    next unless aim['missionConclusion']
    if aim['conclusionScreen'].nil?
      issues << "⚠️ WARNING: #{aim_path} has missionConclusion:true but no conclusionScreen — the player will see no end-of-mission overlay."
    end
    (aim['requiresCompleted'] || []).each do |task_id|
      unless all_task_ids.include?(task_id)
        issues << "❌ ERROR: #{aim_path} requiresCompleted references unknown taskId '#{task_id}'."
      end
    end
  end

  # Collect targetGroup values from tasks (for collection_group cross-reference)
  json_data['objectives']&.each do |obj|
    obj['tasks']&.each do |t|
      target_groups_used.add(t['targetGroup']) if t['targetGroup']
    end
  end

  # Helper: recursively scan items (including contents) for collection_groups and object IDs
  scan_item_for_groups = lambda do |item|
    collection_groups_used.add(item['collection_group']) if item['collection_group']
    all_object_ids.add(item['id']) if item['id']
    item['contents']&.each { |c| scan_item_for_groups.call(c) }
    item['itemsHeld']&.each { |c| scan_item_for_groups.call(c) }
  end

  # Check rooms
  if json_data['rooms']
    json_data['rooms'].each do |room_id, room|
      all_room_ids.add(room_id)
      locked_room_ids.add(room_id) if room['locked']
      # Collect NPC IDs and object IDs for cross-reference
      room['npcs']&.each { |npc| all_npc_ids.add(npc['id']) if npc['id'] }
      room['objects']&.each_with_index do |obj, idx|
        scan_item_for_groups.call(obj)

        # Check for old x/y format (deprecated in favor of position object)
        path = "rooms/#{room_id}/objects[#{idx}]"
        if obj['x'] && obj['y'] && !obj['position']
          issues << "❌ INVALID: '#{path}' uses deprecated x/y format. Must use position object: \"position\": { \"x\": #{obj['x']}, \"y\": #{obj['y']} } (optional: add \"elevation\": <value> for z-ordering)"
        end
      end

      # Check for invalid room connection directions (diagonal directions)
      if room['connections']
        room['connections'].each do |direction, target|
          unless valid_directions.include?(direction)
            issues << "❌ INVALID: Room '#{room_id}' uses invalid direction '#{direction}' - only north, south, east, west are valid (not northeast, southeast, etc.)"
          end

          # Check reverse connections if target is a single room
          if target.is_a?(String) && json_data['rooms'][target]
            reverse_dir = case direction
            when 'north' then 'south'
            when 'south' then 'north'
            when 'east' then 'west'
            when 'west' then 'east'
            end
            target_room = json_data['rooms'][target]
            if target_room['connections']
              has_reverse = target_room['connections'].any? do |dir, targets|
                (dir == reverse_dir) && (targets == room_id || (targets.is_a?(Array) && targets.include?(room_id)))
              end
              unless has_reverse
                issues << "⚠️ WARNING: Room '#{room_id}' connects #{direction} to '#{target}', but '#{target}' doesn't connect #{reverse_dir} back - bidirectional connections recommended"
              end
            end
          end
        end
      end

      # Check room objects
      if room['objects']
        room['objects'].each_with_index do |obj, idx|
          path = "rooms/#{room_id}/objects[#{idx}]"

          # Check item type (and all nested contents/itemsHeld) against known asset files
          check_item_type.call(obj, path)

          # Check for incorrect VM launcher configuration (type: "pc" with vmAccess)
          if obj['type'] == 'pc' && obj['vmAccess']
            issues << "❌ INVALID: '#{path}' uses type: 'pc' with vmAccess - should use type: 'vm-launcher' instead. See scenarios/secgen_vm_lab/scenario.json.erb for example"
          end

          # Track VM launchers (including variants: vm-launcher-kali, vm-launcher-desktop)
          if obj['type']&.start_with?('vm-launcher')
            vm_launcher_room_ids.add(room_id)
          end
          if obj['type'] == 'vm-launcher'
            has_vm_launcher = true
            unless obj['vm']
              issues << "⚠️ WARNING: '#{path}' (vm-launcher) missing 'vm' object - use ERB helper vm_object()"
            end
            unless obj.key?('hacktivityMode')
              issues << "⚠️ WARNING: '#{path}' (vm-launcher) missing 'hacktivityMode' field"
            end
          end

          # Track launch-device items
          if obj['type'] == 'launch-device'
            has_launch_device = true
            missing_launch_fields = []
            missing_launch_fields << 'mode' unless obj['mode']
            missing_launch_fields << 'acceptsVms' unless obj['acceptsVms'] && !obj['acceptsVms'].empty?
            missing_launch_fields << 'flags' unless obj['flags'] && !obj['flags'].empty?
            missing_launch_fields << 'onAbort' unless obj['onAbort']
            missing_launch_fields << 'onLaunch' unless obj['onLaunch']
            missing_launch_fields << 'abortConfirmText' unless obj['abortConfirmText']
            missing_launch_fields << 'launchConfirmText' unless obj['launchConfirmText']
            if missing_launch_fields.any?
              issues << "⚠️ WARNING: '#{path}' (launch-device) missing fields: #{missing_launch_fields.join(', ')} — launch-device items require mode, acceptsVms, flags, onAbort/onLaunch handlers, and confirm text for player dialogs. See scenarios/m01_first_contact/scenario.json.erb for reference"
            end
          end

          # Track flag stations
          if obj['type'] == 'flag-station'
            has_flag_station = true
            unless obj['acceptsVms'] && !obj['acceptsVms'].empty?
              issues << "⚠️ WARNING: '#{path}' (flag-station) missing or empty 'acceptsVms' array"
            end
            unless obj['flags']
              issues << "⚠️ WARNING: '#{path}' (flag-station) missing 'flags' array - use ERB helper flags_for_vm()"
            end
          end

          # Check for PC containers with files
          if obj['type'] == 'pc' && obj['contents'] && obj['contents'].any? { |item| item['type'] == 'text_file' || item['readable'] }
            has_pc_with_files = true
          end

          # Track containers with contents (safes, suitcases, bins, PCs, briefcases, etc.)
          container_types_with_contents = %w[safe suitcase bin bin1 pc briefcase bag]
          if container_types_with_contents.include?(obj['type']) && obj['contents'] && !obj['contents'].empty?
            has_container_with_contents = true
          end

          # REQUIRED: Containers with contents must specify locked field explicitly
          container_types = ['briefcase', 'bag', 'bag1', 'suitcase', 'safe', 'pc', 'bin1']
          if container_types.include?(obj['type']) && obj['contents'] && !obj['contents'].empty?
            unless obj.key?('locked')
              issues << "❌ INVALID: '#{path}' is a container with contents but missing required 'locked' field - must be explicitly true or false for server-side validation"
            end

            # Track dead-end locks: locked containers where no content is useful to the player
            if obj['locked']
              clue_types = %w[notes notes2 notes3 notes4 notes5 text_file key lockpick
                              fingerprint_kit rfid_cloner pin-cracker bluetooth_scanner phone]
              useful = obj['contents'].any? { |c| c['takeable'] || c['readable'] || clue_types.include?(c['type']) }
              locked_objects_info << { path: path, name: (obj['name'] || obj['type']), useful: useful }
            end
          end

          # Track readable items (notes, documents)
          if obj['readable'] || (obj['type'] == 'notes' && obj['text'])
            has_readable_items = true
          end

          # Track security tools
          if ['lockpick', 'fingerprint_kit', 'pin-cracker', 'bluetooth_scanner', 'rfid_cloner'].include?(obj['type'])
            has_security_tools = true
          end

          # Track lockpick items for graph annotation check
          if obj['type'] == 'lockpick'
            lockpick_items << { path: path, has_unlocks: !obj['puzzle_graph_unlocks'].nil? }
          end

          # Track lock types
          if obj['locked'] && obj['lockType']
            lock_types_used.add(obj['lockType'])
            case obj['lockType']
            when 'rfid'
              has_rfid_lock = true
            when 'bluetooth'
              has_bluetooth_lock = true
            when 'pin'
              has_pin_lock = true
            when 'password'
              has_password_lock = true
            when 'key'
              has_key_lock = true
              key_locked_targets << { path: path, name: (obj['name'] || obj['type']) }
              # Check for key locks without keyPins (REQUIRED, not recommended)
              unless obj['keyPins']
                issues << "❌ INVALID: '#{path}' has lockType: 'key' but missing required 'keyPins' array - key locks must specify keyPins array for lockpicking minigame"
              end
            end
          end

          # Check for key items without keyPins (REQUIRED, not recommended)
          if obj['type'] == 'key' && !obj['keyPins']
            issues << "❌ INVALID: '#{path}' (key item) missing required 'keyPins' array - key items must specify keyPins array for lockpicking"
          end

          # Cross-reference onRead.setVariable against globalVariables
          if obj['onRead']&.dig('setVariable')
            obj['onRead']['setVariable'].each_key do |var_name|
              unless global_variables_defined.include?(var_name)
                issues << "❌ INVALID: '#{path}/onRead/setVariable' references variable '#{var_name}' not defined in scenario.globalVariables. Add '#{var_name}': false to globalVariables."
              end
            end
          end

          # Cross-reference onPickup.setVariable against globalVariables
          if obj['onPickup']&.dig('setVariable')
            obj['onPickup']['setVariable'].each_key do |var_name|
              unless global_variables_defined.include?(var_name)
                issues << "❌ INVALID: '#{path}/onPickup/setVariable' references variable '#{var_name}' not defined in scenario.globalVariables. Add '#{var_name}': false to globalVariables."
              end
            end
          end

          # Cross-reference onInteract.setVariable against globalVariables
          if obj['onInteract']&.dig('setVariable')
            obj['onInteract']['setVariable'].each_key do |var_name|
              unless global_variables_defined.include?(var_name)
                issues << "❌ INVALID: '#{path}/onInteract/setVariable' references variable '#{var_name}' not defined in scenario.globalVariables. Add '#{var_name}': false to globalVariables."
              end
            end
          end

          # Warn if confirmationText appears at the top level instead of inside onInteract
          if obj['confirmationText']
            issues << "⚠️ WARNING: '#{path}' has top-level 'confirmationText' — move it inside 'onInteract': { \"confirmationText\": \"...\", ... }"
          end

          # Validate onInteract.display value
          valid_display_modes = %w[gameAlert gameDisplay]
          if obj['onInteract']&.key?('display')
            mode = obj['onInteract']['display']
            unless valid_display_modes.include?(mode)
              issues << "❌ INVALID: '#{path}/onInteract/display' has unknown value '#{mode}'. Valid values: #{valid_display_modes.join(', ')}."
            end
          end

          # Check for items with id field (should use type field for #give_item tags)
          if obj['itemsHeld']
            obj['itemsHeld'].each_with_index do |item, item_idx|
              if item['id']
                issues << "❌ INVALID: '#{path}/itemsHeld[#{item_idx}]' has 'id' field - items should NOT have 'id' field. Use 'type' field to match #give_item tag parameter"
              end
            end
          end

          # puzzle_graph_* metadata tracking and suggestions (dungeon graph)
          if obj['puzzle_graph_unlocks']
            has_puzzle_graph_metadata = true
            Array(obj['puzzle_graph_unlocks']).each do |target|
              puzzle_graph_unlock_targets << { target: target, path: path, optional: (obj['puzzle_graph_optional'] == true) }
            end
          end

          # Suggest puzzle_graph_unlocks on clue items inside locked containers
          # Only fire when the container itself is already in the graph (has puzzle_graph_unlocks)
          if obj['locked'] && obj['puzzle_graph_unlocks'] && obj['contents']&.any?
            clue_types = %w[notes text_file phone]
            clue_contents = obj['contents'].select { |c| c['readable'] || clue_types.include?(c['type']) }
            clue_contents.each_with_index do |c, ci|
              c_path = "#{path}/contents[#{ci}] (#{c['type'] || c['name']})"
              if c['puzzle_graph_unlocks']
                has_puzzle_graph_metadata = true
                Array(c['puzzle_graph_unlocks']).each do |target|
                  puzzle_graph_unlock_targets << { target: target, path: c_path, optional: (c['puzzle_graph_optional'] == true) }
                end
              else
                issues << "💡 SUGGESTION: '#{c_path}' is a clue item inside locked container '#{obj['name'] || obj['type']}' but has no 'puzzle_graph_unlocks'. Add puzzle_graph_unlocks: '<lock_or_room_id>' to connect this clue to the dungeon graph (scripts/generate_dungeon_graph.rb)"
              end
            end
          end
        end
      end

      # Track room lock types
      if room['locked'] && room['lockType']
        lock_types_used.add(room['lockType'])
        case room['lockType']
        when 'rfid'
          has_rfid_lock = true
        when 'bluetooth'
          has_bluetooth_lock = true
        when 'pin'
          has_pin_lock = true
        when 'password'
          has_password_lock = true
        when 'key'
          has_key_lock = true
          key_locked_targets << { path: "rooms/#{room_id}", name: (room['name'] || room_id) }
          # Check for key locks without keyPins (REQUIRED, not recommended)
          unless room['keyPins']
            issues << "❌ INVALID: 'rooms/#{room_id}' has lockType: 'key' but missing required 'keyPins' array - key locks must specify keyPins array for lockpicking minigame"
          end
        end
      end

      # Check NPCs in rooms
      if room['npcs']
        room['npcs'].each_with_index do |npc, idx|
          path = "rooms/#{room_id}/npcs[#{idx}]"

          # Track person NPCs
          if npc['npcType'] == 'person' || (!npc['npcType'] && npc['position'])
            has_person_npcs = true

            # Check for waypoints in behavior.patrol
            if npc['behavior'] && npc['behavior']['patrol']
              patrol = npc['behavior']['patrol']
              # Check for single-room waypoints
              if patrol['waypoints'] && !patrol['waypoints'].empty?
                has_npc_with_waypoints = true
              end
              # Check for multi-room route waypoints
              if patrol['route'] && patrol['route'].is_a?(Array) && patrol['route'].any? { |segment| segment['waypoints'] && !segment['waypoints'].empty? }
                has_npc_with_waypoints = true
              end
            end
          end

          # Track hostile NPCs (hostile can be true or a config object)
          if npc['behavior']&.key?('hostile') && npc['behavior']['hostile']
            has_hostile_npcs = true
          end

          # Track and cross-reference globalVarOnKO
          if npc['globalVarOnKO']
            has_global_var_on_ko = true
            var_name = npc['globalVarOnKO']
            unless global_variables_defined.include?(var_name)
              issues << "❌ INVALID: '#{path}' globalVarOnKO references '#{var_name}' which is not defined in scenario.globalVariables. Add '#{var_name}': false to globalVariables."
            end
          end

          # Track and cross-reference taskOnKO
          if npc['taskOnKO']
            task_id = npc['taskOnKO']
            unless all_task_ids.include?(task_id)
              issues << "❌ INVALID: '#{path}' taskOnKO references task '#{task_id}' which does not exist in any objective's tasks. Ensure the taskId is correct."
            end
          end

          # Track timedConversation.skipIfGlobal
          if npc['timedConversation']&.dig('skipIfGlobal')
            has_skip_if_global = true
          end

          # Check for opening cutscene in starting room
          if room_id == start_room_id && npc['timedConversation']
            has_opening_cutscene = true
            if npc['timedConversation']['delay'] == 0 &&
               npc['timedConversation']['waitForEvent'] == 'game_loaded'
              has_opening_briefing_timed_conversation = true
            end
            if npc['timedConversation']['delay'] != 0
              issues << "⚠️ WARNING: '#{path}' timedConversation delay is #{npc['timedConversation']['delay']} - opening cutscenes typically use delay: 0"
            end
          end

          # Validate timedConversation structure
          if npc['timedConversation']
            tc = npc['timedConversation']
            # Check for incorrect property name
            if tc['knot'] && !tc['targetKnot']
              issues << "❌ INVALID: '#{path}' timedConversation uses 'knot' property - should use 'targetKnot' instead. Change 'knot' to 'targetKnot'"
            end
            # Check for missing targetKnot
            unless tc['targetKnot']
              issues << "❌ INVALID: '#{path}' timedConversation missing required 'targetKnot' property - must specify the Ink knot to navigate to"
            end
            # Check for missing delay
            unless tc.key?('delay')
              issues << "⚠️ WARNING: '#{path}' timedConversation missing 'delay' property - should specify delay in milliseconds (0 for immediate)"
            end
          end

          # Validate eventMapping vs eventMappings (parameter name mismatch)
          if npc['eventMapping'] && !npc['eventMappings']
            issues << "❌ INVALID: '#{path}' uses 'eventMapping' (singular) - should use 'eventMappings' (plural). The NPCManager expects 'eventMappings' and won't register event listeners with 'eventMapping'"
          end

          # Validate eventMappings structure
          if npc['eventMappings']
            # Check if it's an array
            unless npc['eventMappings'].is_a?(Array)
              issues << "❌ INVALID: '#{path}' eventMappings is not an array - must be an array of event mapping objects"
            else
              npc['eventMappings'].each_with_index do |mapping, idx|
                mapping_path = "#{path}/eventMappings[#{idx}]"

                # Check for incorrect property name (knot vs targetKnot)
                if mapping['knot'] && !mapping['targetKnot']
                  issues << "❌ INVALID: '#{mapping_path}' uses 'knot' property - should use 'targetKnot' instead. Change 'knot' to 'targetKnot'"
                end

                # Check for missing eventPattern
                unless mapping['eventPattern']
                  issues << "❌ INVALID: '#{mapping_path}' missing required 'eventPattern' property - must specify the event pattern to listen for (e.g., 'global_variable_changed:varName')"
                end

                # For person NPCs only: conversationMode: 'person-chat' requires targetKnot.
                # targetKnot alone (without conversationMode) is also valid — it just updates currentKnot
                # for the next conversation, which is the correct pattern for bark-only event mappings.
                # (phone NPCs have a different pattern — see phone NPC checks below)
                if npc['npcType'] != 'phone' && mapping['conversationMode'] == 'person-chat' && !mapping['targetKnot']
                  issues << "⚠️ WARNING: '#{mapping_path}' has conversationMode: 'person-chat' but no targetKnot - person-chat cutscenes need a targetKnot to know which Ink knot to jump to"
                end

                # Validate patrolOverride structure
                if mapping['patrolOverride']
                  po = mapping['patrolOverride']
                  unless po.is_a?(Hash) && po['targetTile'].is_a?(Hash) &&
                         po['targetTile']['x'].is_a?(Numeric) && po['targetTile']['y'].is_a?(Numeric)
                    issues << "❌ INVALID: '#{mapping_path}/patrolOverride' must have targetTile: {x: number, y: number}"
                  end
                  if po['speed'] && (!po['speed'].is_a?(Numeric) || po['speed'] <= 0)
                    issues << "❌ INVALID: '#{mapping_path}/patrolOverride/speed' must be a positive number"
                  end
                end

                # Validate barkDelay
                if mapping.key?('barkDelay') && (!mapping['barkDelay'].is_a?(Numeric) || mapping['barkDelay'] < 0)
                  issues << "❌ INVALID: '#{mapping_path}/barkDelay' must be a non-negative number (milliseconds)"
                end

                # Validate setPatrolSpeed
                if mapping.key?('setPatrolSpeed') && (!mapping['setPatrolSpeed'].is_a?(Numeric) || mapping['setPatrolSpeed'] <= 0)
                  issues << "❌ INVALID: '#{mapping_path}/setPatrolSpeed' must be a positive number"
                end

                # Validate setDwellMultiplier
                if mapping.key?('setDwellMultiplier') && (!mapping['setDwellMultiplier'].is_a?(Numeric) || mapping['setDwellMultiplier'] <= 0)
                  issues << "❌ INVALID: '#{mapping_path}/setDwellMultiplier' must be a positive number"
                end

                # Phone NPC event mapping anti-patterns
                if npc['npcType'] == 'phone'
                  phone_chat_trigger = mapping['conversationMode'] == 'phone-chat' && mapping['targetKnot']

                  # conversationMode: "phone-chat" + targetKnot is the supported phone-terminal trigger pattern.
                  # Any other conversationMode on a phone NPC is not supported.
                  if mapping['conversationMode'] && mapping['conversationMode'] != 'phone-chat'
                    issues << "❌ INVALID: '#{mapping_path}' is a phone NPC event mapping with 'conversationMode: \"#{mapping['conversationMode']}\"' — this field is not used for phone NPCs and has no effect. Remove it."
                  end

                  # targetKnot without conversationMode: "phone-chat" does NOT work after the first conversation.
                  # After the first open, storyState is restored and currentKnot is bypassed entirely.
                  if mapping['targetKnot'] && !phone_chat_trigger
                    issues << "❌ INVALID: '#{mapping_path}' is a phone NPC event mapping with 'targetKnot' — this does NOT work after the first conversation. Once a storyState is saved, targetKnot is ignored on reopen. Correct pattern: use 'setGlobal' to set a flag, then add a conditional hub option in the Ink story: '+ {flag_var} [Ask about it] -> knot'. Also add 'sendTimedMessage' to notify the player that new content is available."
                  end

                  # targetKnot inside sendTimedMessage is not used either
                  if mapping['sendTimedMessage']&.key?('targetKnot')
                    issues << "❌ INVALID: '#{mapping_path}/sendTimedMessage' has a 'targetKnot' field — targetKnot inside sendTimedMessage is not used for phone NPCs and will be silently ignored. Remove it. To surface a new dialogue option, use 'setGlobal' on the event mapping and add a conditional hub choice in the Ink story."
                  end

                  # Event mappings that produce no visible effect are likely broken/incomplete.
                  # phone-chat trigger mappings are self-evidently visible (they open the chat), so skip that check.
                  has_effect = phone_chat_trigger || mapping['setGlobal'] || mapping['sendTimedMessage'] ||
                               mapping['completeTask'] || mapping['unlockTask'] || mapping['unlockAim']
                  unless has_effect
                    issues << "⚠️ WARNING: '#{mapping_path}' is a phone NPC event mapping with no visible effect (no setGlobal, sendTimedMessage, completeTask, unlockTask, or unlockAim). Use 'sendTimedMessage' to notify the player, and 'setGlobal' to flag that a new hub option is available. Example: { \"eventPattern\": \"...\", \"onceOnly\": true, \"setGlobal\": { \"flag_var\": true }, \"sendTimedMessage\": { \"delay\": 1000, \"message\": \"...\" } }"
                  end
                end
              end
            end
          end

          # Track phone NPCs (phone contacts)
          if npc['npcType'] == 'phone'
            has_phone_contacts = true

            # Validate phone NPC structure - should have phoneId
            unless npc['phoneId']
              issues << "❌ INVALID: '#{path}' (phone NPC) missing required 'phoneId' field - phone NPCs must specify which phone they appear on (e.g., 'player_phone')"
            end

            # Validate phone NPC structure - should have storyPath
            unless npc['storyPath']
              issues << "❌ INVALID: '#{path}' (phone NPC) missing required 'storyPath' field - phone NPCs must have a path to their Ink story JSON file"
            end

            # Validate phone NPC structure - should NOT have position (phone NPCs don't have positions)
            if npc['position']
              issues << "⚠️ WARNING: '#{path}' (phone NPC) has 'position' field - phone NPCs should NOT have position (they're not in-world sprites). Remove the position field."
            end

            # Validate phone NPC structure - should NOT have spriteSheet (phone NPCs don't have sprites)
            if npc['spriteSheet']
              issues << "⚠️ WARNING: '#{path}' (phone NPC) has 'spriteSheet' field - phone NPCs should NOT have spriteSheet (they're not in-world sprites). Remove the spriteSheet field."
            end

            # Validate timedMessages structure for phone NPCs
            if npc['timedMessages']
              unless npc['timedMessages'].is_a?(Array)
                issues << "❌ INVALID: '#{path}' timedMessages is not an array - must be an array of timed message objects"
              else
                npc['timedMessages'].each_with_index do |msg, idx|
                  msg_path = "#{path}/timedMessages[#{idx}]"

                  # Check for missing message field
                  unless msg['message']
                    issues << "❌ INVALID: '#{msg_path}' missing required 'message' field - must specify the text content of the message"
                  end

                  # Check for incorrect property name (text vs message)
                  if msg['text'] && !msg['message']
                    issues << "❌ INVALID: '#{msg_path}' uses 'text' property - should use 'message' instead. The NPCManager reads msg.message, not msg.text"
                  end

                  # Check for missing delay field
                  unless msg.key?('delay')
                    issues << "⚠️ WARNING: '#{msg_path}' missing 'delay' property - should specify delay in milliseconds (0 for immediate)"
                  end

                  # Check for incorrect property name (knot vs targetKnot) in timed messages
                  if msg['knot'] && !msg['targetKnot']
                    issues << "❌ INVALID: '#{msg_path}' uses 'knot' property - should use 'targetKnot' instead. Change 'knot' to 'targetKnot'"
                  end
                end
              end
            end

            # Track phone NPCs with messages in rooms
            if npc['timedMessages'] && !npc['timedMessages'].empty?
              has_phone_npc_with_messages = true
            else
              # Track phone NPCs without timed messages
              phone_npcs_without_messages << "#{path} (#{npc['displayName'] || npc['id']})"
            end

            # Track phone NPCs with event mappings in rooms
            if npc['eventMappings'] && !npc['eventMappings'].empty?
              has_phone_npc_with_events = true
            end
          end

          # Check for items with id field in NPC itemsHeld
          if npc['itemsHeld']
            npc['itemsHeld'].each_with_index do |item, item_idx|
              if item['id']
                issues << "❌ INVALID: '#{path}/itemsHeld[#{item_idx}]' has 'id' field - items should NOT have 'id' field. Use 'type' field to match #give_item tag parameter (e.g., type: 'id_badge' matches #give_item:id_badge)"
              end

              # Check item type against known asset files
              check_item_type.call(item, "#{path}/itemsHeld[#{item_idx}]")

              # Track security tools in NPC itemsHeld
              if ['lockpick', 'fingerprint_kit', 'pin-cracker', 'bluetooth_scanner', 'rfid_cloner'].include?(item['type'])
                has_security_tools = true
              end

              # Track lockpick items in NPC itemsHeld for graph annotation check
              if item['type'] == 'lockpick'
                lockpick_items << { path: "#{path}/itemsHeld[#{item_idx}]", has_unlocks: !item['puzzle_graph_unlocks'].nil? }
              end

              # Track launch-device in NPC itemsHeld
              has_launch_device = true if item['type'] == 'launch-device'

              # Track puzzle_graph_unlocks on NPC-held items (e.g., Sarah's key chain)
              if item['puzzle_graph_unlocks']
                has_puzzle_graph_metadata = true
                Array(item['puzzle_graph_unlocks']).each do |target|
                  puzzle_graph_unlock_targets << { target: target, path: "#{path}/itemsHeld[#{item_idx}]", optional: (item['puzzle_graph_optional'] == true) }
                end
              end
            end
          end
        end
      end
    end
  end

  # Check startItemsInInventory for security tools and readable items
  if json_data['startItemsInInventory']
    json_data['startItemsInInventory'].each_with_index do |item, idx|
      check_item_type.call(item, "startItemsInInventory[#{idx}]")
      # Track security tools
      if ['lockpick', 'fingerprint_kit', 'pin-cracker', 'bluetooth_scanner', 'rfid_cloner'].include?(item['type'])
        has_security_tools = true
      end

      # Track lockpick items in startItemsInInventory for graph annotation check
      if item['type'] == 'lockpick'
        lockpick_items << { path: "startItemsInInventory[#{idx}]", has_unlocks: !item['puzzle_graph_unlocks'].nil? }
      end

      # Track readable items
      if item['readable'] || (item['type'] == 'notes' && item['text'])
        has_readable_items = true
      end
    end
  end

  # Check phoneNPCs section - this is the OLD/INCORRECT format
  if json_data['phoneNPCs']
    json_data['phoneNPCs'].each_with_index do |npc, idx|
      path = "phoneNPCs[#{idx}]"

      # Flag incorrect structure - phone NPCs should be in rooms, not phoneNPCs section
      issues << "❌ INVALID: '#{path}' - Phone NPCs should be defined in 'rooms/{room_id}/npcs[]' arrays, NOT in a separate 'phoneNPCs' section. See scenarios/npc-sprite-test3/scenario.json.erb for correct format. Phone NPCs should be in the starting room (or room where phone is accessible) with npcType: 'phone'"

      # Track phone NPCs (phone contacts) - but note they're in wrong location
      has_phone_contacts = true

      # Track phone NPCs with messages
      if npc['timedMessages'] && !npc['timedMessages'].empty?
        has_phone_npc_with_messages = true
      else
        # Track phone NPCs without timed messages
        phone_npcs_without_messages << "#{path} (#{npc['displayName'] || npc['id']})"
      end

      # Track phone NPCs with event mappings (for closing debriefs)
      if npc['eventMappings'] && !npc['eventMappings'].any? { |m| m['eventPattern']&.include?('global_variable_changed') }
        has_phone_npc_with_events = true
      end

      # Check for closing debrief trigger
      if npc['eventMappings']
        npc['eventMappings'].each do |mapping|
          if mapping['eventPattern']&.include?('global_variable_changed')
            has_closing_debrief = true
          end
        end
      end
    end
  end

  # Check for event-driven cutscene architecture patterns
  person_npcs_with_event_cutscenes = []
  global_variables_referenced = Set.new
  # global_variables_defined already populated above

  # Check all NPCs for event-driven cutscene patterns
  json_data['rooms']&.each do |room_id, room|
    room['npcs']&.each_with_index do |npc, idx|
      path = "rooms/#{room_id}/npcs[#{idx}]"

      # Check for person NPCs with eventMappings (cutscene NPCs)
      if npc['npcType'] == 'person' && npc['eventMappings']
        npc['eventMappings'].each_with_index do |mapping, mapping_idx|
          mapping_path = "#{path}/eventMappings[#{mapping_idx}]"

          # Check if this is a cutscene trigger (has conversationMode)
          if mapping['conversationMode'] == 'person-chat'
            person_npcs_with_event_cutscenes << {
              npc_id: npc['id'],
              path: path,
              mapping: mapping
            }

            # Extract global variable name from event pattern
            if mapping['eventPattern']&.match(/global_variable_changed:(\w+)/)
              var_name = $1
              global_variables_referenced << var_name

              # Check if the global variable is defined
              unless global_variables_defined.include?(var_name)
                issues << "❌ INVALID: '#{mapping_path}' references global variable '#{var_name}' in eventPattern, but it's not defined in scenario.globalVariables. Add '#{var_name}' with an initial value (typically false) to globalVariables"
              end
            end

            # Check for missing spriteTalk when using non-numeric frame sprites
            if !npc['spriteTalk'] && npc['spriteSheet']
              # Sprites with named frames (not numeric indices) need spriteTalk
              named_frame_sprites = ['female_spy', 'male_spy', 'female_hacker_hood', 'male_doctor']
              if named_frame_sprites.include?(npc['spriteSheet'])
                issues << "⚠️ WARNING: '#{path}' uses spriteSheet '#{npc['spriteSheet']}' which has named frames, but no 'spriteTalk' property. Person-chat cutscenes will show frame errors. Add 'spriteTalk' property pointing to a headshot image (e.g., 'assets/characters/#{npc['spriteSheet']}_headshot.png')"
              end
            end

            # Validate background for person-chat cutscenes
            unless mapping['background']
              issues << "⚠️ WARNING: '#{mapping_path}' is a person-chat cutscene but has no 'background' property. Person-chat cutscenes should have a background image for better visual presentation (e.g., 'assets/backgrounds/hq1.png')"
            end

            # Check for onceOnly to prevent repeated cutscenes
            unless mapping['onceOnly']
              issues << "⚠️ WARNING: '#{mapping_path}' is a person-chat cutscene without 'onceOnly: true'. Cutscenes typically should only trigger once. Add 'onceOnly: true' unless you want the cutscene to repeat"
            end
          end
        end
      end

      # Check for phone NPCs setting global variables in their stories
      if npc['npcType'] == 'phone' && npc['storyPath']
        if npc['eventMappings']
          # Only flag if an eventMapping's sendTimedMessage looks like a cutscene trigger
          # (has targetKnot or conversationMode), not standard hint messages
          cutscene_event_mappings = npc['eventMappings'].select do |m|
            m['sendTimedMessage']&.key?('targetKnot') || m['sendTimedMessage']&.key?('conversationMode')
          end
          if cutscene_event_mappings.any?
            issues << "💡 BEST PRACTICE: '#{path}' appears to be a mission-ending phone NPC with sendTimedMessage. Consider using event-driven cutscene architecture instead: 1) Add #set_global:variable_name:true tag in Ink story, 2) Add #exit_conversation tag to close phone, 3) Create separate person NPC with eventMapping listening for global_variable_changed:variable_name. See scenarios/m01_first_contact/scenario.json.erb for reference implementation"
          end
        end
      end
    end
  end

  # Detect closing debrief: a person NPC with a person-chat eventMapping that is NOT the
  # opening cutscene (i.e. uses eventPattern, not timedConversation). m01 pattern: person NPC
  # with behavior.initiallyHidden: true listening for a global_variable_changed event.
  if person_npcs_with_event_cutscenes.any?
    has_closing_debrief = true
  end

  # Also detect closing debrief from room NPCs with global_variable_changed eventPatterns
  # (catches the pattern even if conversationMode is absent)
  unless has_closing_debrief
    json_data['rooms']&.each do |room_id, room|
      room['npcs']&.each do |npc|
        next unless npc['npcType'] == 'person' && npc['eventMappings']
        next unless npc['behavior']&.dig('initiallyHidden')
        if npc['eventMappings'].any? { |m| m['eventPattern']&.include?('global_variable_changed') }
          has_closing_debrief = true
          break
        end
      end
      break if has_closing_debrief
    end
  end

  # Check for orphaned global variable references
  orphaned_vars = global_variables_referenced - global_variables_defined
  orphaned_vars.each do |var_name|
    issues << "❌ INVALID: Global variable '#{var_name}' is referenced in eventPatterns but not defined in scenario.globalVariables. Add '#{var_name}' to globalVariables with an initial value (typically false for cutscene triggers)"
  end

  # Cross-reference task targetGroup against item collection_groups
  target_groups_used.each do |group|
    unless collection_groups_used.include?(group)
      issues << "❌ INVALID: Task uses targetGroup '#{group}' but no items have collection_group: '#{group}'. Add collection_group: '#{group}' to the relevant items."
    end
  end
  orphaned_groups = collection_groups_used - target_groups_used
  orphaned_groups.each do |group|
    issues << "⚠️ WARNING: Items use collection_group '#{group}' but no task has targetGroup: '#{group}'. Add a task with targetGroup: '#{group}' to track collection progress."
  end

  # Cross-reference task targetNPC, targetRoom, targetObject
  json_data['objectives']&.each_with_index do |obj, oi|
    obj['tasks']&.each_with_index do |task, ti|
      task_path = "objectives[#{oi}]/tasks[#{ti}] (#{task['taskId']})"
      if task['targetNPC'] && !all_npc_ids.include?(task['targetNPC'])
        issues << "❌ INVALID: #{task_path} references targetNPC '#{task['targetNPC']}' which does not exist in any room. Check the NPC id."
      end
      if task['targetRoom'] && !all_room_ids.include?(task['targetRoom'])
        issues << "❌ INVALID: #{task_path} references targetRoom '#{task['targetRoom']}' which is not a defined room."
      end
      if task['targetObject'] && !all_object_ids.include?(task['targetObject'])
        issues << "⚠️ WARNING: #{task_path} references targetObject '#{task['targetObject']}' but no object with that id was found. Ensure the object has an explicit 'id' field matching '#{task['targetObject']}'."
      end

      # Suggest puzzle_graph_unlocks on submit_flags tasks that gate further progress
      if task['type'] == 'submit_flags' && !task['puzzle_graph_unlocks'] && task['onComplete']
        issues << "💡 SUGGESTION: #{task_path} (submit_flags) has no 'puzzle_graph_unlocks'. Add puzzle_graph_unlocks: '<flag_node_id>' to connect flag submission to the dungeon graph (scripts/generate_dungeon_graph.rb)"
      elsif task['puzzle_graph_unlocks']
        has_puzzle_graph_metadata = true
      end
    end
  end

  # Check music section
  if json_data['music']
    music_events = json_data['music']['events'] || []
    music_events.each_with_index do |event, idx|
      music_path = "music/events[#{idx}]"
      next unless event['trigger']
      if (m = event['trigger'].match(/^conversation_closed:(.+)$/))
        npc_id = m[1]
        unless all_npc_ids.include?(npc_id)
          issues << "⚠️ WARNING: '#{music_path}' trigger references NPC '#{npc_id}' via conversation_closed but that NPC id was not found in any room."
        end
      elsif (m = event['trigger'].match(/^global_variable_changed:(.+)$/))
        var_name = m[1]
        unless global_variables_defined.include?(var_name)
          issues << "⚠️ WARNING: '#{music_path}' trigger references global variable '#{var_name}' via global_variable_changed but it is not defined in scenario.globalVariables."
        end
      end
    end
  end

  # Cross-reference puzzle_graph_unlocks targets against known room/object IDs
  puzzle_graph_unlock_targets.each do |entry|
    target = entry[:target]
    entry_path = entry[:path]
    # Only warn for targets that don't look like lock IDs and aren't known rooms/objects
    unless target.start_with?('lock_') || all_room_ids.include?(target) || all_object_ids.include?(target)
      issues << "⚠️ WARNING: '#{entry_path}' has puzzle_graph_unlocks: '#{target}' which is not a known room ID or object ID and doesn't look like a lock ID (lock_*). Verify this target is correct."
    end
  end

  # Graph structural analysis (when puzzle_graph metadata exists)
  if has_puzzle_graph_metadata && puzzle_graph_unlock_targets.any?
    # Count inbound edges per target — exclude optional paths
    target_counts = Hash.new(0)
    puzzle_graph_unlock_targets.each { |e| target_counts[e[:target]] += 1 unless e[:optional] }

    # Multiple solutions: more than one mandatory item unlocks the same target
    target_counts.each do |target, count|
      next if count < 2
      sources = puzzle_graph_unlock_targets.select { |e| e[:target] == target && !e[:optional] }.map { |e| e[:path] }
      issues << "⚠️ WARNING: #{count} items all point to the same unlock target '#{target}' — multiple solution paths exist. Sources: [#{sources.join(', ')}]. If one path is intentionally optional, add puzzle_graph_optional: true to that item. Otherwise this may allow players to bypass a challenge."
    end

    # Locked rooms with no inbound graph edge: the key for this door isn't mapped
    graph_targets = Set.new(puzzle_graph_unlock_targets.map { |e| e[:target] })
    locked_room_ids.each do |room_id|
      # Locked rooms can be targeted as room_id (door node) in puzzle_graph_unlocks
      unless graph_targets.include?(room_id)
        issues << "⚠️ WARNING: Room '#{room_id}' is locked but nothing has puzzle_graph_unlocks: '#{room_id}' — the key or clue for this door is not mapped in the dungeon graph. Add puzzle_graph_unlocks: '#{room_id}' to the item that provides access (key, PIN note, keycard, etc.)."
      end
    end
  end

  # Dead-end locks: locked containers where no content is useful
  locked_objects_info.each do |info|
    next if info[:useful]
    issues << "⚠️ WARNING: '#{info[:path]}' is locked ('#{info[:name]}') but contains no takeable items, readable notes, or clue objects — players have no reward for solving this lock. Add useful contents or remove the lock (set locked: false)."
  end

  # Lockpick items without puzzle_graph_unlocks
  unannotated_lockpicks = lockpick_items.reject { |lp| lp[:has_unlocks] }
  if unannotated_lockpicks.any?
    hint_list = key_locked_targets.map { |t| "'#{t[:path]}' (#{t[:name]})" }.join(', ')
    hint_list = hint_list.empty? ? 'none found' : hint_list
    unannotated_lockpicks.each do |lp|
      issues << "⚠️ WARNING: '#{lp[:path]}' is a lockpick but has no 'puzzle_graph_unlocks' — the dungeon graph won't show what it opens. Add puzzle_graph_unlocks: '<target>' (or an array). Key-locked targets in this scenario: #{hint_list}"
    end
  end

  # Check for submit_flags bypass: aims where VM flag tasks can be skipped
  json_data['objectives']&.each_with_index do |aim, oi|
    next unless aim['tasks']
    flag_tasks = aim['tasks'].select { |t| t['type'] == 'submit_flags' }
    next if flag_tasks.empty?
    # Non-flag tasks in the same aim that advance the scenario via onComplete
    bypass_tasks = aim['tasks'].reject { |t| t['type'] == 'submit_flags' }.select do |t|
      t.dig('onComplete', 'unlockAim') || t.dig('onComplete', 'unlockTask') || t.dig('onComplete', 'completeTask')
    end
    if bypass_tasks.any?
      task_ids = bypass_tasks.map { |t| t['taskId'] }.join(', ')
      aim_path = "objectives[#{oi}] (#{aim['aimId']})"
      issues << "⚠️ WARNING: #{aim_path} contains submit_flags task(s) but non-flag tasks [#{task_ids}] also have onComplete actions — players may advance the scenario without submitting VM flags. If VM completion is mandatory for this aim, ensure non-flag tasks do not independently unlock subsequent aims or tasks."
    end
  end

  # VM launcher reachability: technical challenge accessible without any physical lock
  vm_launcher_room_ids.each do |room_id|
    unless locked_room_ids.include?(room_id)
      issues << "💡 SUGGESTION: Room '#{room_id}' contains a VM launcher but the room itself is not locked — the technical challenge has no physical access barrier. Consider adding a door lock (rfid, key, or pin) to require players to gain physical access first, reinforcing the layered access control learning objective."
    end
  end

  # Provide best practice guidance for event-driven cutscenes
  if person_npcs_with_event_cutscenes.any?
    issues << "✅ GOOD PRACTICE: Scenario uses event-driven cutscene architecture with #{person_npcs_with_event_cutscenes.size} person-chat cutscene(s). Ensure corresponding phone NPCs use #set_global tags to trigger these cutscenes"
  end

  # Good practice confirmations
  if has_global_var_on_ko
    issues << "✅ GOOD PRACTICE: Scenario uses globalVarOnKO on NPCs — global variables are set when NPCs are knocked out, enabling event-driven story progression. Ensure all referenced variables are in globalVariables."
  end

  if has_skip_if_global
    issues << "✅ GOOD PRACTICE: Scenario uses timedConversation.skipIfGlobal — the opening briefing will not replay when the player resumes the scenario."
  end

  if has_opening_briefing_timed_conversation && json_data['show_scenario_brief'] != 'on_resume'
    issues << "⚠️ WARNING: Scenario has a start-room opening timedConversation briefing (delay: 0 + waitForEvent: 'game_loaded') but show_scenario_brief is '#{json_data['show_scenario_brief'] || 'missing'}'. Set 'show_scenario_brief': 'on_resume' so the scenario brief does not pop at mission start and overlap/close the opening conversation."
  end

  if collection_groups_used.any? && (collection_groups_used & target_groups_used).any?
    issues << "✅ GOOD PRACTICE: Scenario uses collection_group on items with matching task targetGroup — item collection progress is tracked correctly."
  end

  if has_music
    issues << "✅ GOOD PRACTICE: Scenario uses the music system — dynamic music changes based on in-game events significantly enhance immersion."
  end

  if has_launch_device
    issues << "✅ GOOD PRACTICE: Scenario uses a launch-device — this is a high-stakes interactive prop used for the mission climax. See scenarios/m01_first_contact/scenario.json.erb (derek_office) for a complete reference implementation."
  end

  if has_hostile_npcs
    issues << "✅ GOOD PRACTICE: Scenario uses hostile NPCs — this adds physical challenge and urgency. Ensure hostile NPCs have behavior.chaseSpeed, attackDamage, and pauseToAttack configured."
  end

  # Feature suggestions
  unless has_vm_launcher
    issues << "💡 SUGGESTION: Consider adding VM launcher terminals (type: 'vm-launcher') for hacking challenges. See scenarios/m01_first_contact/scenario.json.erb (server_room) for example"
  end

  unless has_flag_station
    issues << "💡 SUGGESTION: Consider adding flag station terminals (type: 'flag-station') for VM flag submission. See scenarios/m01_first_contact/scenario.json.erb (server_room) for example"
  end

  unless has_pc_with_files
    issues << "💡 SUGGESTION: Consider adding at least one PC container (type: 'pc') with files (type: 'text_file') in 'contents' array. Use collection_group on files and a matching targetGroup task to track reading progress. See scenarios/m01_first_contact/scenario.json.erb (it_room/kevin_office) for example"
  end

  unless has_phone_npc_with_messages || has_phone_npc_with_events
    issues << "💡 SUGGESTION: Consider adding at least one phone NPC (npcType: 'phone') with timedMessages and eventMappings. Phone NPCs are contacts in the player's phone that send messages, respond to events, and drive narrative. See scenarios/m01_first_contact/scenario.json.erb (agent_0x99) for a full example"
  end

  unless has_opening_cutscene
    issues << "💡 SUGGESTION: Consider adding an opening briefing cutscene — a person NPC with timedConversation (delay: 0, targetKnot: '...', waitForEvent: 'game_loaded', skipIfGlobal: 'briefing_played', setGlobalOnStart: 'briefing_played') in the starting room. See scenarios/m01_first_contact/scenario.json.erb (briefing_cutscene) for example"
  end

  unless has_closing_debrief
    issues << "💡 SUGGESTION: Consider adding event-driven closing debrief cutscene using this architecture:"
    issues << "   1. Add global variable to scenario.globalVariables (e.g., 'start_debrief_cutscene': false)"
    issues << "   2. In phone NPC's Ink story, add tags: #set_global:start_debrief_cutscene:true and #exit_conversation"
    issues << "   3. Create person NPC with eventMappings: [{eventPattern: 'global_variable_changed:start_debrief_cutscene', condition: 'value === true', conversationMode: 'person-chat', targetKnot: 'start', background: 'assets/backgrounds/hq1.png', onceOnly: true}]"
    issues << "   4. Add behavior: {initiallyHidden: true} to person NPC so it doesn't appear in-world"
    issues << "   See scenarios/m01_first_contact/scenario.json.erb (closing_debrief_person) for complete reference implementation"
  end

  # Check for NPCs without waypoints
  if has_person_npcs && !has_npc_with_waypoints
    issues << "💡 SUGGESTION: Consider adding patrol waypoints to at least one person NPC for dynamic movement. Add behavior.patrol.waypoints array with {x, y} coordinates, or behavior.patrol.route for multi-room patrols. See scenarios/m01_first_contact/scenario.json.erb for NPCs with hostile behavior and movement."
  end

  # Check for phone contacts without timed messages
  if has_phone_contacts && !phone_npcs_without_messages.empty?
    npc_list = phone_npcs_without_messages.join(', ')
    issues << "💡 SUGGESTION: Consider adding timedMessages to phone contacts for narrative delivery — timed messages drive the story forward at key moments. Phone NPCs without timed messages: #{npc_list}. See scenarios/m01_first_contact/scenario.json.erb (agent_0x99) for example"
  end

  # Suggest variety in lock types
  if lock_types_used.size < 2
    issues << "💡 SUGGESTION: Consider adding variety in lock types — scenarios typically use 3+ different mechanisms (key, pin, rfid, password, flag). Currently using: #{lock_types_used.to_a.join(', ').then { |s| s.empty? ? 'none' : s }}. m01 uses all five lock types: key (doors/briefcases), pin (safes/cabinets), rfid (server room), password (computers), flag (encrypted archive). See scenarios/m01_first_contact/scenario.json.erb for examples"
  end

  # Suggest RFID locks
  unless has_rfid_lock
    issues << "💡 SUGGESTION: Consider adding RFID locks (lockType: 'rfid') for high-security areas. Requires an rfid_cloner tool and an NPC or item with a card_id. See scenarios/m01_first_contact/scenario.json.erb (server_room) for example"
  end

  # Suggest PIN locks
  unless has_pin_lock
    issues << "💡 SUGGESTION: Consider adding PIN locks (lockType: 'pin') for safes, cabinets, and doors — PIN codes are found as clues elsewhere in the scenario. See scenarios/m01_first_contact/scenario.json.erb (storage_safe, filing cabinets) for examples"
  end

  # Suggest password locks
  unless has_password_lock
    issues << "💡 SUGGESTION: Consider adding password locks (lockType: 'password') for computers and workstations — passwords are discovered through investigation. See scenarios/m01_first_contact/scenario.json.erb (derek_computer, kevin workstation) for examples"
  end

  # Suggest security tools
  unless has_security_tools
    issues << "💡 SUGGESTION: Consider adding security tools (lockpick, fingerprint_kit, pin-cracker, bluetooth_scanner, rfid_cloner) for interactive gameplay. In m01, a lockpick is held by kevin_park and obtained by defeating him, enabling key-locked doors. See scenarios/m01_first_contact/scenario.json.erb for examples"
  end

  # Suggest containers with contents
  unless has_container_with_contents
    issues << "💡 SUGGESTION: Consider adding containers (safe, bin, pc, briefcase, suitcase) with contents for hidden items and layered puzzle design. In m01, multiple safes and bins contain key evidence items. See scenarios/m01_first_contact/scenario.json.erb for examples"
  end

  # Suggest readable items
  unless has_readable_items
    issues << "💡 SUGGESTION: Consider adding readable items (notes, notes2, notes5, text_file) for storytelling and clues. Readable items with onRead.setVariable can trigger story events when a player reads them. See scenarios/m01_first_contact/scenario.json.erb for examples"
  end

  # Suggest music system
  unless has_music
    issues << "💡 SUGGESTION: Consider adding a 'music' section with events array to drive dynamic music changes. In m01, music changes when the briefing ends, when a threat is revealed, and when the debrief begins. See scenarios/m01_first_contact/scenario.json.erb for example"
  end

  # Suggest hostile NPCs
  unless has_hostile_npcs
    issues << "💡 SUGGESTION: Consider adding at least one hostile NPC (behavior: { hostile: true }) to create physical danger and tension. In m01, sarah_martinez, derek_lawson, and kevin_park are all hostile. See scenarios/m01_first_contact/scenario.json.erb for examples"
  end

  # Dungeon graph metadata
  if has_puzzle_graph_metadata
    issues << "✅ GOOD PRACTICE: Scenario uses puzzle_graph_* metadata — run 'ruby scripts/generate_dungeon_graph.rb scenarios/my_scenario/scenario.json.erb' to generate an interactive puzzle dependency graph."
  else
    issues << "💡 SUGGESTION: Consider adding puzzle_graph_unlocks to key items (clue notes inside locked containers, NPC-held keys, submit_flags tasks) to enable the dungeon graph generator. Run 'ruby scripts/generate_dungeon_graph.rb <scenario>' to visualise puzzle flow. See README_scenario_design.md §Dungeon Graph Metadata for field reference."
  end

  issues
end

# Check for recommended fields and return warnings
def check_recommended_fields(json_data)
  warnings = []

  # Top-level recommended fields
  warnings << "Missing recommended field: 'globalVariables' - useful for Ink dialogue state management" unless json_data.key?('globalVariables')
  warnings << "Missing recommended field: 'player' - player sprite configuration improves visual experience" unless json_data.key?('player')

  # Check for objectives with tasks (recommended for structured gameplay)
  if !json_data['objectives'] || json_data['objectives'].empty?
    warnings << "Missing recommended: 'objectives' array with tasks - helps structure gameplay and track progress"
  elsif json_data['objectives'].none? { |obj| obj['tasks'] && !obj['tasks'].empty? }
    warnings << "Missing recommended: objectives should include tasks - objectives without tasks don't provide clear goals"
  end

  # Track if there's at least one NPC with timed conversation (for cut-scenes)
  has_timed_conversation_npc = false

  # Check rooms
  if json_data['rooms']
    json_data['rooms'].each do |room_id, room|
      # Check room objects
      if room['objects']
        room['objects'].each_with_index do |obj, idx|
          path = "rooms/#{room_id}/objects[#{idx}]"
          # Skip observations warning for readable items that already provide their content via 'text'
          # (the text is the description; observations would be redundant)
          skip_obs = obj['readable'] && obj['text'] && !obj['text'].empty?
          unless obj.key?('observations') || skip_obs
            warnings << "Missing recommended field: '#{path}/observations' - helps players understand what items are"
          end
        end
      end


      # Check NPCs
      if room['npcs']
        room['npcs'].each_with_index do |npc, idx|
          path = "rooms/#{room_id}/npcs[#{idx}]"

          # Phone NPCs should have avatar
          if npc['npcType'] == 'phone' && !npc['avatar']
            warnings << "Missing recommended field: '#{path}/avatar' - phone NPCs should have avatar images"
          end

          # Person NPCs should have position (unless initiallyHidden — cutscene-only NPCs have no in-world sprite)
          if npc['npcType'] == 'person' && !npc['position'] && !npc['behavior']&.dig('initiallyHidden')
            warnings << "Missing recommended field: '#{path}/position' - person NPCs need x,y coordinates (unless behavior.initiallyHidden: true for cutscene-only NPCs)"
          end

          # NPCs with storyPath should have currentKnot
          if npc['storyPath'] && !npc['currentKnot']
            warnings << "Missing recommended field: '#{path}/currentKnot' - specifies starting dialogue knot"
          end

          # Check for NPCs without behavior (no storyPath, no timedMessages, no timedConversation, no eventMappings)
          has_behavior = npc['storyPath'] ||
                         (npc['timedMessages'] && !npc['timedMessages'].empty?) ||
                         npc['timedConversation'] ||
                         (npc['eventMappings'] && !npc['eventMappings'].empty?)

          unless has_behavior
            warnings << "Missing recommended: '#{path}' has no behavior - NPCs should have storyPath, timedMessages, timedConversation, or eventMappings"
          end

          # Track timed conversations (for cut-scene recommendation)
          if npc['timedConversation']
            has_timed_conversation_npc = true
          end
        end
      end
    end
  end

  # Check for at least one NPC with timed conversation (recommended for starting cut-scenes)
  unless has_timed_conversation_npc
    warnings << "Missing recommended: No NPCs with 'timedConversation' - consider adding one for immersive starting cut-scenes"
  end

  # Check objectives
  if json_data['objectives']
    json_data['objectives'].each_with_index do |objective, idx|
      path = "objectives[#{idx}]"
      warnings << "Missing recommended field: '#{path}/description' - helps players understand the objective" unless objective.key?('description')

      if objective['tasks']
        objective['tasks'].each_with_index do |task, task_idx|
          task_path = "#{path}/tasks[#{task_idx}]"
          # Tasks with targetCount should have showProgress
          if task['targetCount'] && !task['showProgress']
            warnings << "Missing recommended field: '#{task_path}/showProgress' - shows progress for collect_items tasks"
          end
        end
      end
    end
  end

  # Check startItemsInInventory
  if json_data['startItemsInInventory']
    json_data['startItemsInInventory'].each_with_index do |item, idx|
      path = "startItemsInInventory[#{idx}]"

      # Check for deprecated position property (must use x/y instead)
      warnings << "Missing recommended field: '#{path}/observations' - helps players understand starting items" unless item.key?('observations')
    end
  end

  warnings
end

# Main execution
def main
  options = {
    schema_path: File.join(__dir__, 'scenario-schema.json'),
    verbose: false,
    output_json: false,
    no_graph: false,
    skip_ink: false
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} <scenario.json.erb> [options]"

    opts.on('-s', '--schema PATH', 'Path to JSON schema file') do |path|
      options[:schema_path] = path
    end

    opts.on('-v', '--verbose', 'Show detailed validation output') do
      options[:verbose] = true
    end

    opts.on('-o', '--output-json', 'Output the rendered JSON to stdout') do
      options[:output_json] = true
    end

    opts.on('--no-graph', 'Skip dungeon graph generation after validation') do
      options[:no_graph] = true
    end

    opts.on('--skip-ink', 'Skip ink file compilation validation (faster, but less thorough)') do
      options[:skip_ink] = true
    end

    opts.on('-h', '--help', 'Show this help message') do
      puts opts
      exit 0
    end
  end.parse!

  erb_path = ARGV[0]

  if erb_path.nil? || erb_path.empty?
    $stderr.puts "ERROR: No scenario.json.erb file specified"
    $stderr.puts "Usage: #{$PROGRAM_NAME} <scenario.json.erb> [options]"
    exit 1
  end

  erb_path = File.expand_path(erb_path)
  schema_path = File.expand_path(options[:schema_path])

  puts "Validating scenario: #{erb_path}"
  puts "Using schema: #{schema_path}"
  puts

  # Check scenario directory structure
  puts "Checking scenario directory structure..."
  dir_issues = check_scenario_directory_structure(erb_path)
  if !dir_issues.empty?
    puts "✗ Directory structure validation failed with #{dir_issues.length} error(s):"
    puts

    dir_issues.each_with_index do |issue, index|
      puts "#{index + 1}. #{issue}"
      puts
    end

    exit 1
  end
  puts "✓ Directory structure is valid"
  puts

  # Load valid item types from assets directory
  repo_root = File.expand_path('..', __dir__)
  valid_item_types = load_valid_item_types(repo_root)
  if valid_item_types
    puts "Loaded #{valid_item_types.size} valid item types from assets/objects/"
  else
    puts "⚠️ assets/objects/ directory not found — item type validation skipped"
  end
  puts

  begin
    # Render ERB to JSON
    puts "Rendering ERB template..."
    json_data, rendered_json = render_erb_to_json(erb_path, {}, include_rendered: true)
    puts "✓ ERB rendered successfully"
    puts

    # Output JSON if requested
    if options[:output_json]
      puts "Rendered JSON:"
      puts JSON.pretty_generate(json_data)
      puts
    end

    # Pre-validate structure before running schema validation
    puts "Checking JSON structure..."
    structure_issues = check_structure_validity(json_data)
    structure_issues.concat(check_duplicate_show_scenario_brief(rendered_json))

    # Report structure issues immediately and exit
    if !structure_issues.empty?
      puts "✗ Structure validation failed with #{structure_issues.length} error(s):"
      puts

      structure_issues.each_with_index do |issue, index|
        puts "#{index + 1}. #{issue}"
        puts
      end

      exit 1
    end
    puts "✓ JSON structure is valid"
    puts

    # Check for unknown fields (warnings, not errors)
    puts "Checking for unknown fields..."
    unknown_fields_warnings = check_unknown_fields(json_data)
    if unknown_fields_warnings.any?
      puts "⚠️ Found #{unknown_fields_warnings.length} unknown field(s):"
      puts
      unknown_fields_warnings.each_with_index do |warning, index|
        puts "#{index + 1}. #{warning}"
      end
      puts
    else
      puts "✓ No unknown fields"
      puts
    end

    # Check ink files exist and compile (unless skipped)
    unless options[:skip_ink]
      puts "Checking ink files..."
      scenario_dir = File.dirname(erb_path)
      ink_issues = check_ink_files(json_data, repo_root, scenario_dir)

      # Report ink issues immediately and exit if critical
      if ink_issues.any? { |issue| issue.start_with?("❌") }
        puts "✗ Ink file validation failed with #{ink_issues.count { |i| i.start_with?("❌") }} error(s):"
        puts

        ink_issues.each_with_index do |issue, index|
          puts "#{index + 1}. #{issue}"
          puts
        end

        exit 1
      elsif ink_issues.any?
        puts "⚠️ Found #{ink_issues.length} ink file warning(s):"
        puts

        ink_issues.each_with_index do |issue, index|
          puts "#{index + 1}. #{issue}"
          puts
        end
      else
        puts "✓ All ink files valid"
      end
      puts
    else
      puts "⏭️ Skipping ink file validation (--skip-ink)"
      puts
    end

    # Check objective task completion wiring
    puts "Checking objective task wiring..."
    wiring_issues = check_objectives_wiring(json_data, repo_root)
    if wiring_issues.any? { |i| i.start_with?("❌") }
      puts "✗ Objective wiring check found #{wiring_issues.count { |i| i.start_with?('❌') }} error(s):"
      puts
      wiring_issues.each_with_index do |issue, index|
        puts "#{index + 1}. #{issue}"
        puts
      end
      # Non-fatal: continue so the author sees all problems at once.
      puts
    elsif wiring_issues.any?
      puts "⚠️ Found #{wiring_issues.length} objective wiring warning(s):"
      puts
      wiring_issues.each_with_index do |issue, index|
        puts "#{index + 1}. #{issue}"
        puts
      end
      puts
    else
      puts "✓ Objective task wiring OK"
      puts
    end

    # Validate against schema
    puts "Validating against schema..."
    errors = validate_json(json_data, schema_path)

    # Check for common issues and structural problems
    puts "Checking for common issues..."
    common_issues = check_common_issues(json_data, valid_item_types)

    # Check for recommended fields
    puts "Checking recommended fields..."
    warnings = check_recommended_fields(json_data)

    # Report errors
    if errors.empty?
      puts "✓ Schema validation passed!"
    else
      puts "✗ Schema validation failed with #{errors.length} error(s):"
      puts

      errors.each_with_index do |error, index|
        puts "#{index + 1}. #{error}"
        puts
      end

      if options[:verbose]
        puts "Full JSON structure:"
        puts JSON.pretty_generate(json_data)
      end

      exit 1
    end

    # Report common issues
    if common_issues.empty?
      puts "✓ No common issues found."
      puts
    else
      puts "⚠️ Found #{common_issues.length} issue(s) and suggestion(s):"
      puts

      common_issues.each_with_index do |issue, index|
        puts "#{index + 1}. #{issue}"
      end
      puts
    end

    # Report warnings
    if warnings.empty?
      puts "✓ No missing recommended fields."
      puts
    else
      puts "⚠️ Found #{warnings.length} missing recommended field(s):"
      puts

      warnings.each_with_index do |warning, index|
        puts "#{index + 1}. #{warning}"
      end
      puts
    end

    # Generate dungeon graph (runs by default, suppress with --no-graph)
    unless options[:no_graph]
      graph_script = File.join(__dir__, 'generate_dungeon_graph.rb')
      if File.exist?(graph_script)
        puts "Generating dungeon graph..."
        result = system('ruby', graph_script, erb_path)
        graph_out = File.join(File.dirname(erb_path), 'dungeon_graph.html')
        if result
          puts "✓ Dungeon graph: #{graph_out}"
        else
          puts "⚠️ Dungeon graph generation failed (non-fatal)"
        end
        puts
      end
    end

    # Exit with success (warnings don't cause failure)
    puts "✓ Validation complete!"
    exit 0
  rescue StandardError => e
    $stderr.puts "ERROR: #{e.message}"
    if options[:verbose]
      $stderr.puts e.backtrace.join("\n")
    end
    exit 1
  end
end

main if __FILE__ == $PROGRAM_NAME
