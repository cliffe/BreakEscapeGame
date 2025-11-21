require 'open3'

module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :scenario, :scenario_map, :ink, :room, :container, :sync_state, :unlock, :inventory]

    def show
      authorize @game if defined?(Pundit)
      @mission = @game.mission
    end

    # GET /games/:id/scenario
    # Returns filtered scenario JSON for this game instance
    # Uses filtered_scenario_for_bootstrap for lazy-loading support
    def scenario
      authorize @game if defined?(Pundit)

      begin
        # Use filtered bootstrap scenario and remove 'requires' fields for security
        filtered = @game.filtered_scenario_for_bootstrap

        # Remove 'requires' fields recursively for security
        filter_requires_recursive(filtered)

        render json: filtered
      rescue => e
        Rails.logger.error "[BreakEscape] scenario error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        render_error("Failed to generate scenario: #{e.message}", :internal_server_error)
      end
    end

    # GET /games/:id/scenario_map
    # Returns minimal scenario metadata for navigation (no room contents)
    def scenario_map
      authorize @game if defined?(Pundit)

      begin
        # Check if scenario_data exists
        unless @game.scenario_data.present?
          Rails.logger.error "[BreakEscape] scenario_map: Game #{@game.id} has no scenario_data"
          return render_error('Scenario data not available', :internal_server_error)
        end

        # Return minimal room/connection metadata without contents
        layout = {}
        rooms = @game.scenario_data['rooms'] || {}

        Rails.logger.debug "[BreakEscape] scenario_map: Processing #{rooms.keys.length rescue 0} rooms"

        rooms.each do |room_id, room_data|
          next unless room_data.is_a?(Hash)

          begin
            layout[room_id] = {
              type: room_data['type'],
              connections: room_data['connections'] || {},
              locked: room_data['locked'] || false,
              lockType: room_data['lockType'],
              hasNPCs: (room_data['npcs']&.length || 0) > 0,
              accessible: @game.room_unlocked?(room_id)
            }
          rescue => e
            Rails.logger.error "[BreakEscape] Error processing room #{room_id}: #{e.message}"
            # Skip this room and continue
            next
          end
        end

        render json: {
          startRoom: @game.scenario_data['startRoom'],
          currentRoom: @game.player_state['currentRoom'],
          rooms: layout
        }
      rescue => e
        Rails.logger.error "[BreakEscape] scenario_map error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        render_error("Failed to generate scenario map: #{e.message}", :internal_server_error)
      end
    end

    # GET /games/:id/room/:room_id
    # Returns room data for a specific room (lazy-loading support)
    def room
      authorize @game if defined?(Pundit)

      begin
        room_id = params[:room_id]
        return render_error('Missing room_id parameter', :bad_request) unless room_id.present?

        # Check if scenario_data exists
        unless @game.scenario_data.present?
          Rails.logger.error "[BreakEscape] room: Game #{@game.id} has no scenario_data"
          return render_error('Scenario data not available', :internal_server_error)
        end

        # Check if room is accessible (starting room OR in unlockedRooms)
        is_start_room = @game.scenario_data['startRoom'] == room_id
        is_unlocked = @game.player_state['unlockedRooms']&.include?(room_id)

        unless is_start_room || is_unlocked
          return render_error("Room not accessible: #{room_id}", :forbidden)
        end

        # Auto-add start room if missing (defensive programming)
        if is_start_room && !is_unlocked
          @game.player_state['unlockedRooms'] ||= []
          @game.player_state['unlockedRooms'] << room_id
          @game.save!
        end

        # Get and filter room data
        room_data = @game.filtered_room_data(room_id)
        return render_error("Room not found: #{room_id}", :not_found) unless room_data

        # Track NPC encounters BEFORE sending response
        track_npc_encounters(room_id, room_data)

        Rails.logger.debug "[BreakEscape] Serving room data for: #{room_id}"

        render json: { room_id: room_id, room: room_data }
      rescue => e
        Rails.logger.error "[BreakEscape] room error: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
        render_error("Failed to load room: #{e.message}", :internal_server_error)
      end
    end

    # GET /games/:id/container/:container_id
    # Returns container contents after unlock (lazy-loaded)
    def container
      authorize @game if defined?(Pundit)

      container_id = params[:container_id]
      return render_error('Missing container_id parameter', :bad_request) unless container_id.present?

      # Find container in scenario data
      container_data = find_container_in_scenario(container_id)
      return render_error("Container not found: #{container_id}", :not_found) unless container_data

      # Check if container is unlocked (check multiple possible identifiers)
      is_unlocked = check_container_unlocked(container_id, container_data)

      unless is_unlocked
        return render_error("Container not unlocked: #{container_id}", :forbidden)
      end

      # Return filtered contents
      contents = filter_container_contents(container_data)

      Rails.logger.debug "[BreakEscape] Serving container contents for: #{container_id}"

      render json: {
        container_id: container_id,
        contents: contents
      }
    end

    # GET /games/:id/ink?npc=helper1
    # Returns NPC script (JIT compiled if needed)
    def ink
      authorize @game if defined?(Pundit)

      npc_id = params[:npc]
      return render_error('Missing npc parameter', :bad_request) unless npc_id.present?

      Rails.logger.debug "[BreakEscape] Loading ink for NPC: #{npc_id}"

      # Find NPC in scenario data
      npc = find_npc_in_scenario(npc_id)
      return render_error("NPC not found in scenario: #{npc_id}", :not_found) unless npc

      Rails.logger.debug "[BreakEscape] Found NPC: #{npc['id']} with storyPath: #{npc['storyPath']}"

      # Check if storyPath is set
      unless npc['storyPath'].present?
        Rails.logger.warn "[BreakEscape] NPC #{npc['id']} has no storyPath defined"
        return render_error("NPC #{npc['id']} has no storyPath defined", :bad_request)
      end

      # Resolve ink file path and compile if needed
      ink_json_path = resolve_and_compile_ink(npc['storyPath'])
      unless ink_json_path && File.exist?(ink_json_path)
        Rails.logger.error "[BreakEscape] Ink file not found for #{npc['storyPath']} (resolved to #{ink_json_path})"
        return render_error("Ink script not found for #{npc['storyPath']}", :not_found)
      end

      Rails.logger.debug "[BreakEscape] Serving ink from: #{ink_json_path}"

      # Serve compiled JSON
      render json: JSON.parse(File.read(ink_json_path))
    rescue JSON::ParserError => e
      render_error("Invalid JSON in compiled ink: #{e.message}", :internal_server_error)
    end

    # PUT /games/:id/sync_state
    # Periodic state sync from client
    def sync_state
      authorize @game if defined?(Pundit)

      # Update allowed fields
      if params[:currentRoom]
        # Verify room is accessible
        if @game.player_state['unlockedRooms'].include?(params[:currentRoom]) ||
           @game.scenario_data['startRoom'] == params[:currentRoom]
          @game.player_state['currentRoom'] = params[:currentRoom]
        else
          return render json: {
            success: false,
            message: "Cannot enter locked room: #{params[:currentRoom]}"
          }, status: :forbidden
        end
      end

      if params[:globalVariables]
        @game.update_global_variables!(params[:globalVariables].to_unsafe_h)
      end

      @game.save!

      render json: { success: true }
    end

    # POST /games/:id/unlock
    # Validate unlock attempt
    def unlock
      authorize @game if defined?(Pundit)

      target_type = params[:targetType]
      target_id = params[:targetId]
      attempt = params[:attempt]
      method = params[:method]

      is_valid = @game.validate_unlock(target_type, target_id, attempt, method)

      unless is_valid
        return render json: {
          success: false,
          message: 'Invalid attempt'
        }, status: :unprocessable_entity
      end

      # Use transaction to ensure atomic update
      ActiveRecord::Base.transaction do
        if target_type == 'door'
          @game.unlock_room!(target_id)

          room_data = @game.filtered_room_data(target_id)

          render json: {
            success: true,
            type: 'door',
            roomData: room_data
          }
        else
          # Object/container unlock
          @game.unlock_object!(target_id)

          render json: {
            success: true,
            type: 'object'
          }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        message: "Failed to save unlock: #{e.message}"
      }, status: :unprocessable_entity
    end

    # POST /games/:id/inventory
    # Update inventory
    def inventory
      authorize @game if defined?(Pundit)

      action_type = params[:action_type] || params[:actionType]
      item = params[:item]

      case action_type
      when 'add'
        # Validate item exists and is collectible
        validation_error = validate_item_collectible(item)
        if validation_error
          return render json: { success: false, message: validation_error },
                       status: :unprocessable_entity
        end

        @game.add_inventory_item!(item.to_unsafe_h)
        render json: { success: true, inventory: @game.player_state['inventory'] }

      when 'remove'
        @game.remove_inventory_item!(item['id'])
        render json: { success: true, inventory: @game.player_state['inventory'] }

      else
        render json: { success: false, message: 'Invalid action' }, status: :bad_request
      end
    end

    private

    def set_game
      @game = Game.find(params[:id])
    end

    def filter_requires_recursive(obj)
      case obj
      when Hash
        # Remove 'requires' (the answer/solution) from all objects
        obj.delete('requires')

        # Recursively filter nested structures
        obj.each_value { |value| filter_requires_recursive(value) }
      when Array
        obj.each { |item| filter_requires_recursive(item) }
      end
    end

    def track_npc_encounters(room_id, room_data)
      return unless room_data['npcs'].present?

      npc_ids = room_data['npcs'].map { |npc| npc['id'] }

      # Ensure encounteredNPCs is an array
      @game.player_state['encounteredNPCs'] ||= []

      # Handle case where encounteredNPCs might be a string (legacy data)
      unless @game.player_state['encounteredNPCs'].is_a?(Array)
        @game.player_state['encounteredNPCs'] = []
      end

      new_npcs = npc_ids - @game.player_state['encounteredNPCs']
      return if new_npcs.empty?

      @game.player_state['encounteredNPCs'].concat(new_npcs)
      @game.save!

      Rails.logger.debug "[BreakEscape] Tracked NPC encounters: #{new_npcs.join(', ')}"
    end

    def find_container_in_scenario(container_id)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        # Search objects for container
        container = find_container_recursive(room_data['objects'], container_id)
        return container if container

        # Search nested contents
        room_data['objects']&.each do |obj|
          container = search_nested_contents(obj['contents'], container_id)
          return container if container
        end
      end
      nil
    end

    def find_container_recursive(objects, container_id)
      return nil unless objects

      objects.each do |obj|
        # Check if this object matches
        if obj['id'] == container_id || (obj['name'] && obj['name'] == container_id)
          return obj if obj['contents'].present?
        end

        # Recursively search nested contents
        nested = find_container_recursive(obj['contents'], container_id)
        return nested if nested
      end
      nil
    end

    def search_nested_contents(contents, container_id)
      return nil unless contents

      contents.each do |item|
        return item if (item['id'] == container_id || item['name'] == container_id) && item['contents'].present?
        nested = search_nested_contents(item['contents'], container_id)
        return nested if nested
      end
      nil
    end

    def check_container_unlocked(container_id, container_data)
      unlocked_list = @game.player_state['unlockedObjects'] || []

      # Check multiple possible identifiers
      unlocked_list.include?(container_id) ||
      unlocked_list.include?(container_data['id']) ||
      unlocked_list.include?(container_data['name']) ||
      unlocked_list.include?(container_data['type'])
    end

    def filter_container_contents(container_data)
      contents = container_data['contents']&.map do |item|
        item_copy = item.deep_dup
        @game.send(:filter_requires_and_contents_recursive, item_copy)
        item_copy
      end || []

      contents
    end

    def validate_item_collectible(item)
      item_type = item['type']
      item_id = item['id']

      # Search scenario for this item
      found_item = find_item_in_scenario(item_type, item_id)
      return "Item not found in scenario: #{item_type}" unless found_item

      # Check if item is takeable
      unless found_item['takeable']
        return "Item is not takeable: #{found_item['name']}"
      end

      # If item is in locked container, check if container is unlocked
      container_info = find_item_container(item_type, item_id)
      if container_info.present?
        container_id = container_info[:id]
        unless @game.player_state['unlockedObjects'].include?(container_id)
          return "Container not unlocked: #{container_id}"
        end
      end

      # If item is in locked room, check if room is unlocked
      room_info = find_item_room(item_type, item_id)
      if room_info.present?
        room_id = room_info[:id]
        if room_info[:locked] && !@game.player_state['unlockedRooms'].include?(room_id)
          return "Room not unlocked: #{room_id}"
        end
      end

      # Check if NPC holds this item and if NPC encountered
      npc_info = find_npc_holding_item(item_type, item_id)
      if npc_info.present?
        npc_id = npc_info[:id]
        unless @game.player_state['encounteredNPCs'].include?(npc_id)
          return "NPC not encountered: #{npc_id}"
        end
      end

      nil # No error
    end

    def find_item_in_scenario(item_type, item_id)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        # Search room objects
        room_data['objects']&.each do |obj|
          return obj if obj['type'] == item_type && (obj['id'] == item_id || obj['name'] == item_id)

          # Search nested contents
          obj['contents']&.each do |content|
            return content if content['type'] == item_type && (content['id'] == item_id || content['name'] == item_id)
          end
        end
      end
      nil
    end

    def find_item_container(item_type, item_id)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        room_data['objects']&.each do |obj|
          obj['contents']&.each do |content|
            if content['type'] == item_type && (content['id'] == item_id || content['name'] == item_id)
              return { id: obj['id'] || obj['name'], locked: obj['locked'] }
            end
          end
        end
      end
      nil
    end

    def find_item_room(item_type, item_id)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        room_data['objects']&.each do |obj|
          if obj['type'] == item_type && (obj['id'] == item_id || obj['name'] == item_id)
            return { id: room_id, locked: room_data['locked'] }
          end
        end
      end
      nil
    end

    def find_npc_holding_item(item_type, item_id)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        room_data['npcs']&.each do |npc|
          next unless npc['itemsHeld'].present?

          # itemsHeld is array of full item objects (same structure as room objects)
          npc['itemsHeld'].each do |held_item|
            # Match by type (required) and optionally by id/name
            if held_item['type'] == item_type
              # If item_id provided, verify it matches
              if item_id.present?
                item_matches = (held_item['id'] == item_id) ||
                              (held_item['name'] == item_id) ||
                              (item_id == item_type) # Fallback if no id field
                next unless item_matches
              end

              return {
                id: npc['id'],
                npc: npc,
                item: held_item,
                type: 'npc'
              }
            end
          end
        end
      end
      nil
    end

    def find_npc_in_scenario(npc_id)
      available_npcs = []
      @game.scenario_data['rooms']&.each do |room_id, room_data|
        room_data['npcs']&.each do |npc|
          available_npcs << "#{npc['id']} (#{room_id})"
          return npc if npc['id'] == npc_id
        end
      end
      
      # Log available NPCs for debugging
      if available_npcs.any?
        Rails.logger.debug "[BreakEscape] Available NPCs: #{available_npcs.join(', ')}"
      else
        Rails.logger.warn "[BreakEscape] No NPCs found in scenario data"
      end
      
      nil
    end

    # Resolve ink path and compile if necessary
    def resolve_and_compile_ink(story_path)
      # Use Engine root for Rails Engine context
      engine_root = BreakEscape::Engine.root
      base_path = engine_root.join(story_path)
      json_path = find_compiled_json(base_path)
      ink_path = find_ink_source(base_path)

      if ink_path && needs_compilation?(ink_path, json_path)
        Rails.logger.info "[BreakEscape] Compiling #{File.basename(ink_path)}..."
        json_path = compile_ink(ink_path)
      end

      json_path
    end

    def find_compiled_json(base_path)
      return base_path if File.exist?(base_path)

      ink_json_path = base_path.to_s.gsub(/\.json$/, '.ink.json')
      return Pathname.new(ink_json_path) if File.exist?(ink_json_path)

      json_path = base_path.to_s.gsub(/\.ink\.json$/, '.json')
      return Pathname.new(json_path) if File.exist?(json_path)

      nil
    end

    def find_ink_source(base_path)
      ink_path = base_path.to_s.gsub(/\.(ink\.)?json$/, '.ink')
      File.exist?(ink_path) ? Pathname.new(ink_path) : nil
    end

    def needs_compilation?(ink_path, json_path)
      return true unless json_path && File.exist?(json_path)
      File.mtime(ink_path) > File.mtime(json_path)
    end

    def compile_ink(ink_path)
      output_path = ink_path.to_s.gsub(/\.ink$/, '.json')
      inklecate_path = Rails.root.join('bin', 'inklecate')

      stdout, stderr, status = Open3.capture3(
        inklecate_path.to_s,
        '-o', output_path,
        ink_path.to_s
      )

      unless status.success?
        Rails.logger.error "[BreakEscape] Ink compilation failed: #{stderr}"
        raise "Ink compilation failed for #{File.basename(ink_path)}: #{stderr}"
      end

      if stderr.present?
        Rails.logger.warn "[BreakEscape] Ink compilation warnings: #{stderr}"
      end

      Rails.logger.info "[BreakEscape] Compiled #{File.basename(ink_path)} (#{(File.size(output_path) / 1024.0).round(2)} KB)"

      Pathname.new(output_path)
    end

    def render_error(message, status)
      render json: { error: message }, status: status
    end
  end
end
