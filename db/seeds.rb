# frozen_string_literal: true

puts 'Creating/Updating BreakEscape missions...'

# Directories to skip (not actual playable scenarios)
SKIP_DIRS = %w[common compiled ink].freeze

# Infer collection from scenario name for test/demo scenarios
def infer_collection(scenario_name)
  return 'testing' if scenario_name.start_with?('test', 'npc-', 'scenario')
  return 'testing' if scenario_name.include?('demo') || scenario_name.include?('test')

  'default'
end

# Apply default metadata when mission.json is missing
def apply_default_metadata(mission, scenario_name)
  mission.display_name = scenario_name.titleize if mission.display_name.blank?
  mission.description = "Play the #{scenario_name.titleize} scenario" if mission.description.blank?
  mission.difficulty_level = 3 if mission.difficulty_level.blank? || mission.difficulty_level.zero?
  mission.collection = infer_collection(scenario_name) if mission.collection.blank?
  mission.published = true
  mission
end

# List all scenario directories
scenario_dirs = Dir.glob(BreakEscape::Engine.root.join('scenarios/*')).select { |f| File.directory?(f) }

created_count = 0
updated_count = 0
skipped_count = 0
cybok_total = 0

scenario_dirs.each do |dir|
  scenario_name = File.basename(dir)
  next if SKIP_DIRS.include?(scenario_name)

  # Check for scenario.json.erb (required for valid mission)
  scenario_template = File.join(dir, 'scenario.json.erb')
  unless File.exist?(scenario_template)
    puts "  ⊘ Skipped: #{scenario_name} (no scenario.json.erb)"
    skipped_count += 1
    next
  end

  mission = BreakEscape::Mission.find_or_initialize_by(name: scenario_name)
  is_new = mission.new_record?
  mission_json_path = File.join(dir, 'mission.json')

  if File.exist?(mission_json_path)
    # Load metadata from mission.json
    begin
      metadata = JSON.parse(File.read(mission_json_path))

      mission.display_name = metadata['display_name'] || scenario_name.titleize
      mission.description = metadata['description'] || "Play the #{scenario_name.titleize} scenario"
      mission.difficulty_level = metadata['difficulty_level'] || 3
      mission.secgen_scenario = metadata['secgen_scenario']
      mission.collection = metadata['collection'] || 'default'
      mission.published = true

      if mission.save
        # Sync CyBOK data
        if metadata['cybok'].present?
          cybok_count = BreakEscape::CybokSyncService.sync_for_mission(mission, metadata['cybok'])
          cybok_total += cybok_count
          puts "  ✓ #{is_new ? 'Created' : 'Updated'}: #{mission.display_name} (#{cybok_count} CyBOK entries)"
        else
          puts "  ✓ #{is_new ? 'Created' : 'Updated'}: #{mission.display_name}"
        end
        is_new ? created_count += 1 : updated_count += 1
      else
        puts "  ✗ Failed: #{scenario_name} - #{mission.errors.full_messages.join(', ')}"
      end
    rescue JSON::ParserError => e
      puts "  ⚠ Invalid mission.json for #{scenario_name}: #{e.message}"
      # Fall back to defaults
      apply_default_metadata(mission, scenario_name)
      if mission.save
        puts "  ✓ #{is_new ? 'Created' : 'Updated'} (defaults): #{mission.display_name}"
        is_new ? created_count += 1 : updated_count += 1
      else
        puts "  ✗ Failed: #{scenario_name} - #{mission.errors.full_messages.join(', ')}"
      end
    end
  else
    # No mission.json - use defaults
    apply_default_metadata(mission, scenario_name)
    if mission.save
      puts "  ✓ #{is_new ? 'Created' : 'Updated'} (defaults): #{mission.display_name}"
      is_new ? created_count += 1 : updated_count += 1
    else
      puts "  ✗ Failed: #{scenario_name} - #{mission.errors.full_messages.join(', ')}"
    end
  end
end

puts ''
puts '=' * 50
puts "Done! #{BreakEscape::Mission.count} missions total."
puts "  Created: #{created_count}, Updated: #{updated_count}, Skipped: #{skipped_count}"
puts "  CyBOK entries synced: #{cybok_total}"
puts "  Collections: #{BreakEscape::Mission.collections.join(', ')}"
if BreakEscape::CybokSyncService.hacktivity_mode?
  puts '  Mode: Hacktivity (CyBOK data synced to both tables)'
else
  puts '  Mode: Standalone (CyBOK data in break_escape_cyboks only)'
end
puts '=' * 50

