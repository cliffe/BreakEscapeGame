require 'open3'

module BreakEscape
  class GamesController < ApplicationController
    helper PlayerPreferencesHelper
    
    before_action :set_game, only: [:show, :scenario, :scenario_map, :ink, :room, :container, :sync_state, :update_room, :unlock, :inventory, :objectives, :complete_task, :update_task_progress, :submit_flag, :tts]

    # GET /games/new?mission_id=:id
    # Show VM set selection page for VM-required missions
    def new
      @mission = Mission.find(params[:mission_id])
      authorize @mission, :create_game? if defined?(Pundit)

      if @mission.requires_vms?
        @available_vm_sets = @mission.valid_vm_sets_for_user(current_player)
        @existing_games = Game.where(player: current_player, mission: @mission)
      end
    end

    # POST /games
    # Create a new game instance for a mission
    def create
      @mission = Mission.find(params[:mission_id])
      authorize @mission, :create_game? if defined?(Pundit)

      # Build initial player_state with VM/flag context
      initial_player_state = {}

      # Hacktivity mode with VM set
      if params[:vm_set_id].present? && defined?(::VmSet)
        vm_set = ::VmSet.find_by(id: params[:vm_set_id])
        return render json: { error: 'VM set not found' }, status: :not_found unless vm_set

        # Validate VM set belongs to user and matches mission
        if BreakEscape::Mission.hacktivity_mode?
          unless @mission.valid_vm_sets_for_user(current_user).include?(vm_set)
            return render json: { error: 'Invalid VM set for this mission' }, status: :forbidden
          end
          initial_player_state['vm_set_id'] = vm_set.id
        else
          # Standalone mode - vm_set_id shouldn't be used
          Rails.logger.warn "[BreakEscape] vm_set_id provided but not in Hacktivity mode, ignoring"
        end
      end

      # Standalone mode with VM IPs JSON
      if params[:vm_ips_json].present?
        begin
          vm_ips = JSON.parse(params[:vm_ips_json])
          initial_player_state['vm_ips'] = vm_ips if vm_ips.is_a?(Hash)
        rescue JSON::ParserError => e
          Rails.logger.warn "[BreakEscape] Invalid vm_ips_json: #{e.message}"
        end
      end

      # Standalone mode with XML flag hints
      if params[:flag_hints_xml].present?
        flags_by_vm = Mission.parse_flag_hints_xml(params[:flag_hints_xml])
        initial_player_state['flags_by_vm'] = flags_by_vm
        # Also store flat list for backward compatibility
        initial_player_state['standalone_flags'] = flags_by_vm.values.flatten.uniq
      # Legacy: comma-separated flags (backward compatibility)
      elsif params[:standalone_flags].present?
        flags = if params[:standalone_flags].is_a?(Array)
                  params[:standalone_flags]
        else
                  params[:standalone_flags].split(',').map(&:strip).reject(&:blank?)
        end
        initial_player_state['standalone_flags'] = flags
      end

      # CRITICAL: Set player_state BEFORE save! so callbacks can read vm_set_id
      # Callback order is:
      # 1. before_create :generate_scenario_data_with_context (reads player_state['vm_set_id'])
      # 2. before_create :initialize_player_state (adds default fields)
      @game = Game.new(
        player: current_player,
        mission: @mission
      )
      @game.player_state = initial_player_state
      @game.save!

      # Check if player's sprite is valid for this scenario
      player_pref = current_player_preference || create_default_preference

      if !player_pref.sprite_selected?
        # No sprite selected - MUST configure
        flash[:alert] = 'Please select your character before starting.'
        redirect_to configuration_path(game_id: @game.id)
      elsif !player_pref.sprite_valid_for_scenario?(@game.scenario_data)
        # Sprite selected but invalid for this scenario
        flash[:alert] = 'Your selected character is not available for this mission. Please choose another.'
        redirect_to configuration_path(game_id: @game.id)
      else
        # All good - start game
        redirect_to game_path(@game)
      end
    end

    def show
      authorize @game if defined?(Pundit)
      @mission = @game.mission
      
      # Load player preference data for the in-game modal
      @player_preference = current_player_preference || create_default_preference
      @available_sprites = PlayerPreference::AVAILABLE_SPRITES
      
      # Debug logging
      Rails.logger.info "[BreakEscape] Loading game#show for player: #{current_player.class.name}##{current_player.id}"
      Rails.logger.info "[BreakEscape] Player preference: #{@player_preference.inspect}"
      Rails.logger.info "[BreakEscape] Selected sprite: #{@player_preference.selected_sprite.inspect}"
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

        # Include objectives state for page reload recovery
        # This allows the client to restore completed/progress state
        if @game.player_state['objectivesState'].present?
          filtered['objectivesState'] = @game.player_state['objectivesState']
        end

        # Include submitted flags for flag station minigame
        if @game.player_state['submitted_flags'].present?
          filtered['submittedFlags'] = @game.player_state['submitted_flags']
        end

        # Include current inventory from player_state for page reload recovery
        # This allows the client to restore inventory state on reload
        if @game.player_state['inventory'].present? && @game.player_state['inventory'].is_a?(Array)
          filtered['playerInventory'] = @game.player_state['inventory']
          
          # Remove startItemsInInventory from scenario to prevent duplicates
          # Since we're sending the actual inventory, we don't need the starting items
          filtered.delete('startItemsInInventory')
        end

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

        # Check if room exists in scenario FIRST (before accessibility check)
        unless @game.scenario_data['rooms']&.key?(room_id)
          return render_error("Room not found: #{room_id}", :not_found)
        end

        # Check if room is accessible (starting room OR in unlockedRooms)
        is_start_room = @game.scenario_data['startRoom'] == room_id
        is_unlocked = @game.player_state['unlockedRooms']&.include?(room_id)

        unless is_start_room || is_unlocked
          return render_error("Room not accessible: #{room_id}", :forbidden)
        end

        # Auto-add room to unlockedRooms when accessed
        # This ensures items in the room can be collected
        if !is_unlocked
          @game.player_state['unlockedRooms'] ||= []
          @game.player_state['unlockedRooms'] << room_id unless @game.player_state['unlockedRooms'].include?(room_id)
          @game.save!
          Rails.logger.info "[BreakEscape] Auto-unlocked room #{room_id} on access"
        end

        # Get and filter room data
        room_data = @game.filtered_room_data(room_id)
        return render_error("Room not found: #{room_id}", :not_found) unless room_data

        # Track NPC encounters BEFORE sending response
        npc_count = room_data['npcs']&.length || 0
        Rails.logger.info "[BreakEscape] 📦 Loading room: #{room_id} (NPCs: #{npc_count})"
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

      # Reload game to get latest player_state (in case inventory was updated)
      @game.reload

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

      Rails.logger.info "[BreakEscape] Serving container contents for: #{container_id} - returning #{contents.length} items"
      Rails.logger.debug "[BreakEscape] Container contents: #{contents.map { |c| "#{c['type']}/#{c['id']}/#{c['name']}" }.join(', ')}"

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

    # POST /games/:id/tts
    # Generate TTS audio for NPC dialogue line
    def tts
      authorize @game if defined?(Pundit)

      npc_id = params[:npc_id]
      text = params[:text]

      return render_error('Missing npc_id or text', :bad_request) unless npc_id.present? && text.present?
      return render_error('Text too long', :bad_request) if text.length > 500

      # Find NPC in scenario
      npc = find_npc_in_scenario(npc_id)
      return render_error("NPC not found: #{npc_id}", :not_found) unless npc

      # Get voice config — NPCs use 'voice' (Hash), room objects use 'ttsVoice'
      voice_config = npc['voice'].is_a?(Hash) ? npc['voice'] : npc['ttsVoice']
      return render_error("No voice configured for NPC: #{npc_id}", :bad_request) unless voice_config

      # Validate text exists in the NPC's content (anti-abuse)
      if npc['storyPath']
        # Full Ink story — validate against compiled JSON
        ink_json_path = resolve_and_compile_ink(npc['storyPath'])
        unless ink_json_path
          Rails.logger.error "[TTS] Ink story file not found for NPC #{npc_id}: #{npc['storyPath']}"
          return render_error('NPC story file not found', :not_found)
        end

        unless InkTextValidator.validate(ink_json_path.to_s, text)
          Rails.logger.warn "[TTS] Text validation failed for NPC #{npc_id}: #{text.truncate(60)}"
          return render_error('Text not found in NPC story', :forbidden)
        end
      elsif npc['voice'].is_a?(String)
        # Room object with a fixed voice message — validate directly
        normalized_request = text.downcase.gsub(/[^\w\s]/, '').strip.gsub(/\s+/, ' ')
        normalized_stored  = npc['voice'].downcase.gsub(/[^\w\s]/, '').strip.gsub(/\s+/, ' ')
        unless normalized_request == normalized_stored
          Rails.logger.warn "[TTS] Text validation failed for room object #{npc_id}: #{text.truncate(60)}"
          return render_error('Text not found in object', :forbidden)
        end
      else
        return render_error('Cannot validate text for this object', :bad_request)
      end

      # Generate or retrieve cached audio
      tts_service = TtsService.new
      unless tts_service.enabled?
        return render_error('TTS not configured (missing GEMINI_API_KEY)', :service_unavailable)
      end

      mp3_path = tts_service.generate(text, voice_config['name'], voice_config['style'], voice_config['language'])
      unless mp3_path && File.exist?(mp3_path)
        return render_error('TTS generation failed', :internal_server_error)
      end

      send_file mp3_path, type: 'audio/mpeg', disposition: 'inline'
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

    # POST /games/:id/update_room
    # Update dynamic room state (items added/removed, NPCs moved, object state changes)
    def update_room
      authorize @game if defined?(Pundit)

      room_id = params[:roomId]
      action_type = params[:actionType]  # Renamed from 'action' to avoid Rails conflict
      data = params[:data]

      unless room_id.present? && action_type.present?
        return render json: { success: false, message: 'Missing roomId or actionType' }, status: :bad_request
      end

      # Validate room is accessible
      unless @game.room_unlocked?(room_id)
        return render json: { success: false, message: 'Room not accessible' }, status: :forbidden
      end

      success = case action_type
      when 'add_object'
        # Validate item data (data is ActionController::Parameters)
        unless data.present? && (data[:type].present? || data['type'].present?)
          return render json: { success: false, message: 'Invalid item data' }, status: :bad_request
        end
        
        source_data = {
          'npc_id' => params[:sourceNpcId],
          'source_type' => params[:sourceType]
        }.compact
        
        # Use strong parameters instead of to_unsafe_h
        @game.add_item_to_room!(room_id, item_add_params, source_data)

      when 'remove_object'
        item_id = data[:id] || data['id'] || data[:itemId] || data['itemId']
        unless item_id.present?
          return render json: { success: false, message: 'Missing item id' }, status: :bad_request
        end
        
        @game.remove_item_from_room!(room_id, item_id)

      when 'update_object_state'
        object_id = data[:objectId] || data['objectId']
        state_changes = data[:stateChanges] || data['stateChanges']
        
        unless object_id.present? && state_changes.present?
          return render json: { success: false, message: 'Invalid object state data' }, status: :bad_request
        end
        
        # Use strong parameters instead of to_unsafe_h
        @game.update_object_state!(room_id, object_id, object_state_params)

      when 'update_npc_state'
        npc_id = data[:npcId] || data['npcId']
        state_changes = data[:stateChanges] || data['stateChanges']
        
        unless npc_id.present? && state_changes.present?
          return render json: { success: false, message: 'Invalid NPC state data' }, status: :bad_request
        end
        
        # Use strong parameters instead of to_unsafe_h
        @game.update_npc_state!(room_id, npc_id, npc_state_params)

      when 'move_npc'
        npc_id = data[:npcId] || data['npcId']
        from_room = data[:fromRoom] || data['fromRoom']
        to_room = data[:toRoom] || data['toRoom']
        
        unless npc_id.present? && from_room.present? && to_room.present?
          return render json: { success: false, message: 'Invalid NPC move data' }, status: :bad_request
        end
        
        @game.move_npc_to_room!(npc_id, from_room, to_room)

      else
        return render json: { success: false, message: "Unknown action: #{action_type}" }, status: :bad_request
      end

      if success
        render json: { success: true }
      else
        render json: { success: false, message: 'Failed to update room state' }, status: :unprocessable_entity
      end
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

          # Track NPC encounters when unlocking a door (room data is cached by client)
          # This ensures NPCs are tracked even if loadRoom() uses cached data
          track_npc_encounters(target_id, room_data)

          render json: {
            success: true,
            type: 'door',
            roomData: room_data
          }
        else
          # Object/container unlock
          @game.unlock_object!(target_id)

          # Find the unlocked object and return its contents if it's a container
          object_data = find_object_in_scenario(target_id)
          response = {
            success: true,
            type: 'object'
          }

          # If object has contents, include them in response
          if object_data && object_data['contents'].present?
            response[:hasContents] = true
            response[:contents] = object_data['contents']
          end

          render json: response
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

      Rails.logger.info "[BreakEscape] inventory endpoint: action=#{action_type}, item=#{item.inspect}"

      begin
        case action_type
        when 'add'
          # Validate item exists and is collectible
          validation_error = validate_item_collectible(item)
          if validation_error
            Rails.logger.warn "[BreakEscape] inventory validation failed: #{validation_error}"
            return render json: { success: false, message: validation_error },
                         status: :unprocessable_entity
          end

          Rails.logger.info "[BreakEscape] Adding item to inventory: #{item['type']} / #{item['name']}"
          @game.add_inventory_item!(item.to_unsafe_h)
          Rails.logger.info "[BreakEscape] Item added successfully. Current inventory size: #{@game.player_state['inventory']&.length}"
          render json: { success: true, inventory: @game.player_state['inventory'] }

        when 'remove'
          @game.remove_inventory_item!(item['id'])
          render json: { success: true, inventory: @game.player_state['inventory'] }

        else
          render json: { success: false, message: 'Invalid action' }, status: :bad_request
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "[BreakEscape] Inventory save failed: #{e.message}"
        render json: { success: false, message: "Failed to save inventory: #{e.message}" }, 
               status: :unprocessable_entity
      rescue => e
        Rails.logger.error "[BreakEscape] Inventory error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { success: false, message: "Inventory error: #{e.message}" }, 
               status: :internal_server_error
      end
    end

    # ==========================================
    # Objectives System
    # ==========================================

    # GET /games/:id/objectives
    # Returns current objectives and their state
    def objectives
      authorize @game if defined?(Pundit)

      render json: @game.objectives_state
    end

    # POST /games/:id/objectives/tasks/:task_id
    # Complete a specific task
    def complete_task
      authorize @game if defined?(Pundit)

      task_id = params[:task_id]

      unless task_id.present?
        return render json: { success: false, error: 'Missing task_id' }, status: :bad_request
      end

      # For submit_flags tasks, accept submittedFlags from request body for validation
      validation_data = params[:validation_data] || {}
      if params[:submittedFlags].present?
        validation_data[:submittedFlags] = params[:submittedFlags]
      end

      result = @game.complete_task!(task_id, validation_data)

      if result[:success]
        Rails.logger.info "[BreakEscape] Task completed: #{task_id}"
        render json: result
      else
        Rails.logger.warn "[BreakEscape] Task completion failed: #{task_id} - #{result[:error]}"
        render json: result, status: :unprocessable_entity
      end
    end

    # PUT /games/:id/objectives/tasks/:task_id
    # Update task progress (for collect_items and submit_flags tasks)
    def update_task_progress
      authorize @game if defined?(Pundit)

      task_id = params[:task_id]
      progress = params[:progress].to_i
      submitted_flags = params[:submittedFlags]

      unless task_id.present?
        return render json: { success: false, error: 'Missing task_id' }, status: :bad_request
      end

      result = @game.update_task_progress!(task_id, progress, submitted_flags)

      Rails.logger.debug "[BreakEscape] Task progress updated: #{task_id} = #{progress}, submittedFlags: #{submitted_flags&.length || 0}"
      render json: result
    end

    # ==========================================
    # VM/Flag Integration
    # ==========================================

    # POST /games/:id/flags
    # Submit a CTF flag for validation
    def submit_flag
      authorize @game if defined?(Pundit)

      flag_key = params[:flag]

      unless flag_key.present?
        return render json: { success: false, message: 'No flag provided' }, status: :bad_request
      end

      result = @game.submit_flag(flag_key)

      if result[:success]
        # Find flag-station and generate flag identifier
        flag_station = find_flag_station_for_flag(flag_key)
        flag_id = generate_flag_identifier(flag_key, flag_station)
        vm_id = flag_station&.dig('acceptsVms', 0)

        # Find rewards for this flag in scenario
        rewards = find_flag_rewards(flag_key)

        # Process rewards
        reward_results = process_flag_rewards(flag_key, rewards)

        Rails.logger.info "[BreakEscape] Flag submitted: #{flag_key}, flagId: #{flag_id}, rewards: #{reward_results.length}"

        render json: {
          success: true,
          message: result[:message],
          flag: flag_key,
          flagId: flag_id,
          vmId: vm_id,
          rewards: reward_results
        }
      else
        render json: result, status: :unprocessable_entity
      end
    end

    private

    def set_game
      @game = Game.find(params[:id])
    end

    def filter_requires_recursive(obj)
      case obj
      when Hash
        # Remove 'requires' for exploitable lock types (key/pin/password)
        # Keep it for biometric/bluetooth/rfid since they reference collectible items, not answers
        # - biometric: requires fingerprint owner name (e.g., "Mrs Moo")
        # - bluetooth: requires device MAC/name (e.g., "00:11:22:33:44:55")
        # - rfid: requires card IDs (e.g., ["master_keycard"])
        lock_type = obj['lockType']
        if lock_type && !%w[biometric bluetooth rfid].include?(lock_type)
          obj.delete('requires')
        end

        # Recursively filter nested structures
        obj.each_value { |value| filter_requires_recursive(value) }
      when Array
        obj.each { |item| filter_requires_recursive(item) }
      end
    end

    def track_npc_encounters(room_id, room_data)
      return unless room_data['npcs'].present?

      begin
        npc_ids = room_data['npcs'].map { |npc| npc['id'] }

        # Ensure player_state is a hash
        unless @game.player_state.is_a?(Hash)
          Rails.logger.error "[BreakEscape] player_state is not a Hash: #{@game.player_state.class}"
          @game.player_state = {}
        end

        # Ensure encounteredNPCs is an array
        @game.player_state['encounteredNPCs'] ||= []

        # Handle case where encounteredNPCs might not be an array (legacy data)
        unless @game.player_state['encounteredNPCs'].is_a?(Array)
          Rails.logger.warn "[BreakEscape] encounteredNPCs is not an Array: #{@game.player_state['encounteredNPCs'].class}, resetting"
          @game.player_state['encounteredNPCs'] = []
        end

        new_npcs = npc_ids - @game.player_state['encounteredNPCs']
        return if new_npcs.empty?

        # Log detailed information about each new NPC encountered
        new_npcs.each do |npc_id|
          npc_data = room_data['npcs'].find { |npc| npc['id'] == npc_id }
          if npc_data
            display_name = npc_data['displayName'] || npc_id
            npc_type = npc_data['npcType'] || 'unknown'
            Rails.logger.info "[BreakEscape] 🎭 NPC ENCOUNTERED: #{display_name} (#{npc_id}) - Type: #{npc_type} - Room: #{room_id}"
          else
            Rails.logger.info "[BreakEscape] 🎭 NPC ENCOUNTERED: #{npc_id} - Room: #{room_id}"
          end
        end

        @game.player_state['encounteredNPCs'] = (@game.player_state['encounteredNPCs'] + new_npcs).uniq
        @game.save!

        total_encountered = @game.player_state['encounteredNPCs'].length
        Rails.logger.info "[BreakEscape] ✅ Tracked #{new_npcs.length} new NPC encounter(s) in room #{room_id}. Total NPCs encountered: #{total_encountered}"
      rescue => e
        Rails.logger.error "[BreakEscape] Error tracking NPC encounters: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        # Continue without tracking to avoid breaking room loading
      end
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

    def find_object_in_scenario(object_id)
      # Search all rooms for the object
      @game.scenario_data['rooms'].each do |_room_id, room_data|
        object = room_data['objects']&.find { |obj|
          obj['id'] == object_id || obj['name'] == object_id
        }
        return object if object
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

      # Only match by ID — never by name or type, which are non-unique and could
      # grant access to all containers sharing a type/name string.
      unlocked_list.include?(container_id) ||
      unlocked_list.include?(container_data['id'])
    end

    def filter_container_contents(container_data)
      contents = container_data['contents']&.map do |item|
        item_copy = item.deep_dup
        @game.send(:filter_requires_and_contents_recursive, item_copy)
        item_copy
      end || []

      # Filter out items that are already in the player's inventory
      inventory = @game.player_state['inventory'] || []
      Rails.logger.debug "[BreakEscape] Filtering container contents. Inventory has #{inventory.length} items"
      Rails.logger.debug "[BreakEscape] Container has #{contents.length} items before filtering"

      filtered_contents = contents.reject do |item|
        in_inventory = item_in_inventory?(item, inventory)
        if in_inventory
          Rails.logger.debug "[BreakEscape] Filtering out item: #{item['type']} / #{item['id']} / #{item['name']} (already in inventory)"
        end
        in_inventory
      end

      Rails.logger.debug "[BreakEscape] Container has #{filtered_contents.length} items after filtering"
      filtered_contents
    end

    # Check if an item is already in the player's inventory
    # Matches by type, id, or name (similar to validation logic)
    def item_in_inventory?(item, inventory)
      return false if inventory.blank? || item.blank?

      # Normalize item data (handle both string and symbol keys)
      item_type = item['type'] || item[:type]
      item_id = item['key_id'] || item[:key_id] || item['id'] || item[:id]
      item_name = item['name'] || item[:name]

      Rails.logger.debug "[BreakEscape] Checking if item in inventory: type=#{item_type}, id=#{item_id}, name=#{item_name}"

      inventory.any? do |inv_item|
        # Inventory items are stored as flat objects (not nested in scenarioData)
        # Handle both string and symbol keys
        inv_type = inv_item['type'] || inv_item[:type]
        inv_id = inv_item['key_id'] || inv_item[:key_id] || inv_item['id'] || inv_item[:id]
        inv_name = inv_item['name'] || inv_item[:name]

        Rails.logger.debug "[BreakEscape] Comparing with inventory item: type=#{inv_type}, id=#{inv_id}, name=#{inv_name}"

        # Must match type
        next false unless inv_type == item_type

        # If both have IDs, match by ID (most specific)
        if item_id.present? && inv_id.present?
          match = inv_id.to_s == item_id.to_s
          Rails.logger.debug "[BreakEscape] ID match: #{match} (#{item_id} == #{inv_id})"
          return true if match
        end

        # If both have names, match by name (fallback if no ID match)
        if item_name.present? && inv_name.present?
          match = inv_name.to_s == item_name.to_s
          Rails.logger.debug "[BreakEscape] Name match: #{match} (#{item_name} == #{inv_name})"
          return true if match
        end

        # If item has no ID or name, match by type only (less specific, but works for generic items)
        if item_id.blank? && item_name.blank?
          Rails.logger.debug "[BreakEscape] Type-only match (no ID/name)"
          return true
        end

        false
      end
    end

    # Items that are always allowed in inventory (core game mechanics)
    ALWAYS_ALLOWED_ITEMS = %w[notepad].freeze

    def validate_item_collectible(item)
      item_type = item['type']
      # Use key_id for keys (more unique), fall back to id for other items
      item_id = item['key_id'] || item['id']
      item_name = item['name']

      Rails.logger.info "[BreakEscape] validate_item_collectible: type=#{item_type}, id=#{item_id}, name=#{item_name}"

      # Always allow core game items like notepad
      if ALWAYS_ALLOWED_ITEMS.include?(item_type)
        Rails.logger.info "[BreakEscape] Item is always allowed: #{item_type}"
        return nil
      end

      # Check if this is a starting item first (if so, skip all other checks)
      is_starting_item = @game.scenario_data['startItemsInInventory']&.any? do |start_item|
        start_item['type'] == item_type && (start_item['id'] == item_id || start_item['name'] == item_name)
      end

      if is_starting_item
        Rails.logger.info "[BreakEscape] Item is a starting item, skipping room/container checks"
        return nil # Starting items are always valid
      end

      # Search for item, prioritizing accessible locations (not locked containers/rooms)
      found_item_info = find_accessible_item(item_type, item_id, item_name)

      unless found_item_info
        error_msg = "Item not found in scenario: #{item_type}"
        Rails.logger.warn "[BreakEscape] #{error_msg}"
        return error_msg
      end

      found_item = found_item_info[:item]
      location = found_item_info[:location]

      # Check if item is takeable
      unless found_item['takeable']
        error_msg = "Item is not takeable: #{found_item['name']}"
        Rails.logger.warn "[BreakEscape] #{error_msg}"
        return error_msg
      end

      # Check access based on location type
      if location[:type] == 'container'
        container_id = location[:container_id]
        unless @game.player_state['unlockedObjects'].include?(container_id)
          error_msg = "Container not unlocked: #{container_id}"
          Rails.logger.warn "[BreakEscape] #{error_msg}"
          return error_msg
        end
      elsif location[:type] == 'room'
        room_id = location[:room_id]
        room_info = @game.scenario_data['rooms'][room_id]
        if room_info && room_info['locked'] && !@game.player_state['unlockedRooms'].include?(room_id)
          error_msg = "Room not unlocked: #{room_id}"
          Rails.logger.warn "[BreakEscape] #{error_msg}"
          return error_msg
        end
      elsif location[:type] == 'npc'
        npc_id = location[:npc_id]
        unless @game.player_state['encounteredNPCs'].include?(npc_id)
          error_msg = "NPC not encountered: #{npc_id}"
          Rails.logger.warn "[BreakEscape] #{error_msg}"
          return error_msg
        end
      elsif location[:type] == 'flag_station'
        # Flag station items are valid if they're in the player's inventory (already awarded server-side)
        # or if the corresponding flag has been submitted
        flag_station_id = location[:flag_station_id]
        Rails.logger.info "[BreakEscape] Item from flag station #{flag_station_id}, allowing (flag reward)"
        # Flag rewards are always valid - the server already validated and added them
      end

      Rails.logger.info "[BreakEscape] Item collection valid: #{item_type}"
      nil # No error
    end

    def find_accessible_item(item_type, item_id, item_name)
      # Priority 0: Dynamically-added items (e.g., dropped by defeated NPCs).
      # These were already security-validated by add_item_to_room! so they are always allowed.
      @game.player_state['room_states']&.each do |room_id, room_state|
        room_state['objects_added']&.each do |added_obj|
          next unless added_obj['type'] == item_type
          next unless added_obj['key_id'] == item_id || added_obj['id'] == item_id ||
                      added_obj['name'] == item_name || added_obj['name'] == item_id ||
                      item_id.nil?
          return { item: added_obj, location: { type: 'room', room_id: room_id } }
        end
      end

      # Priority 1: Items in unlocked rooms (most accessible)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        if room_data['locked'] == false || @game.player_state['unlockedRooms'].include?(room_id)
          room_data['objects']&.each do |obj|
            if obj['type'] == item_type && (obj['key_id'] == item_id || obj['id'] == item_id || obj['name'] == item_name || obj['name'] == item_id)
              return { item: obj, location: { type: 'room', room_id: room_id } }
            end
          end
        end
      end

      # Priority 2: Items in any room (including locked ones - will validate in main method)
      @game.scenario_data['rooms'].each do |room_id, room_data|
        room_data['objects']&.each do |obj|
          if obj['type'] == item_type && (obj['key_id'] == item_id || obj['id'] == item_id || obj['name'] == item_name || obj['name'] == item_id)
            return { item: obj, location: { type: 'room', room_id: room_id } }
          end

          # Search nested contents in room objects
          obj['contents']&.each do |content|
            if content['type'] == item_type && (content['key_id'] == item_id || content['id'] == item_id || content['name'] == item_name || content['name'] == item_id)
              return { item: content, location: { type: 'container', container_id: obj['id'] || obj['name'] } }
            end
          end

          # Search flag-station itemsHeld (flag reward items)
          if obj['type'] == 'flag-station' && obj['itemsHeld'].present?
            obj['itemsHeld'].each do |held_item|
              if held_item['type'] == item_type && (held_item['key_id'] == item_id || held_item['keyId'] == item_id || held_item['id'] == item_id || held_item['name'] == item_name || held_item['name'] == item_id)
                return { item: held_item, location: { type: 'flag_station', flag_station_id: obj['id'] || obj['name'], room_id: room_id } }
              end
            end
          end
        end

        # Priority 3: Items held by NPCs in this room
        room_data['npcs']&.each do |npc|
          next unless npc['itemsHeld'].present?

          npc['itemsHeld'].each do |held_item|
            if held_item['type'] == item_type && (held_item['key_id'] == item_id || held_item['id'] == item_id || held_item['name'] == item_name || held_item['name'] == item_id)
              return { item: held_item, location: { type: 'npc', npc_id: npc['id'], room_id: room_id } }
            end
          end
        end
      end

      nil
    end

    def find_item_in_scenario(item_type, item_id, item_name = nil)
      # First check startItemsInInventory (items the player begins with)
      @game.scenario_data['startItemsInInventory']&.each do |item|
        if item['type'] == item_type && (item['key_id'] == item_id || item['id'] == item_id || item['name'] == item_name || item['name'] == item_id)
          return item
        end
      end

      # Then search room objects
      @game.scenario_data['rooms'].each do |room_id, room_data|
        # Search room objects
        room_data['objects']&.each do |obj|
          if obj['type'] == item_type && (obj['key_id'] == item_id || obj['id'] == item_id || obj['name'] == item_name || obj['name'] == item_id)
            return obj
          end

          # Search nested contents
          obj['contents']&.each do |content|
            if content['type'] == item_type && (content['key_id'] == item_id || content['id'] == item_id || content['name'] == item_name || content['name'] == item_id)
              return content
            end
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

        # Also search room objects (e.g. phone items with ttsVoice config)
        room_data['objects']&.each do |obj|
          next unless obj['id'] == npc_id
          return obj
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
      inklecate_path = BreakEscape::Engine.root.join('bin', 'inklecate')

      stdout, stderr, status = Open3.capture3(
        inklecate_path.to_s,
        '-jo', output_path,
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
    
    # Strong parameters for room state sync (SECURITY)
    def item_add_params
      # Allow common item properties, including nested scenarioData
      params.require(:data).permit(
        :id, :type, :name, :texture, :x, :y, :takeable, :interactable,
        scenarioData: [
          :type, :name, :takeable, :key_id, :observations, :active, :visible, :interactable,
          keyPins: []
        ]
      ).to_h
    end
    
    def object_state_params
      # Only allow safe state changes (not 'locked' which bypasses puzzles)
      params.require(:data).require(:stateChanges).permit(
        :opened, :on, :brightness, :screen_state
      ).to_h
    end
    
    def npc_state_params
      # Only allow KO status and HP changes (validated further in model)
      params.require(:data).require(:stateChanges).permit(
        :isKO, :currentHP
      ).to_h
    end

    # ==========================================
    # Flag Reward Helpers
    # ==========================================

    def find_flag_rewards(flag_key)
      rewards = []

      # Search scenario for flag-station with this flag
      @game.scenario_data['rooms']&.each do |room_id, room|
        room['objects']&.each do |obj|
          next unless obj['type'] == 'flag-station'
          next unless obj['flags']&.any? { |f| f.downcase == flag_key.downcase }

          flag_station_id = obj['id'] || obj['name']

          # Support both hash structure (preferred) and array structure (legacy)
          if obj['flagRewards'].is_a?(Hash)
            # Hash structure: { "flag{key}": { "type": "unlock_door", ... } }
            # Case-insensitive lookup
            reward_key = obj['flagRewards'].keys.find { |k| k.downcase == flag_key.downcase }
            reward = obj['flagRewards'][reward_key] if reward_key
            if reward
              rewards << reward.merge(
                'flag_station_id' => flag_station_id,
                'room_id' => room_id
              )
            end
          elsif obj['flagRewards'].is_a?(Array)
            # Array structure (legacy): rewards[i] corresponds to flags[i]
            flag_index = obj['flags'].find_index { |f| f.downcase == flag_key.downcase }
            if flag_index && obj['flagRewards'][flag_index]
              rewards << obj['flagRewards'][flag_index].merge(
                'flag_station_id' => flag_station_id,
                'room_id' => room_id
              )
            end
          end
        end
      end

      rewards
    end

    def process_flag_rewards(flag_key, rewards)
      results = []

      rewards.each do |reward|
        # Skip if already claimed
        if @game.player_state['flag_rewards_claimed']&.include?(flag_key)
          results << { type: 'skipped', reason: 'Already claimed' }
          next
        end

        # Process each reward type
        case reward['type']
        when 'give_item'
          results << process_item_reward(reward, flag_key)

        when 'unlock_door'
          results << process_door_unlock_reward(reward, flag_key)

        when 'emit_event'
          results << process_event_reward(reward, flag_key)

        else
          results << { type: 'unknown', data: reward }
        end
      end

      # Mark rewards as claimed
      @game.player_state['flag_rewards_claimed'] ||= []
      @game.player_state['flag_rewards_claimed'] << flag_key
      @game.save!

      results
    end

    def process_item_reward(reward, flag_key)
      # Find the flag-station object to pull item from its itemsHeld
      flag_station = find_flag_station_by_id(reward['flag_station_id'])

      return { type: 'error', message: 'Flag station not found' } unless flag_station

      # Get item from itemsHeld (similar to NPC item giving)
      item = flag_station['itemsHeld']&.find { |i| i['type'] == reward['item_type'] || i['name'] == reward['item_name'] }

      return { type: 'error', message: 'Item not found in flag station' } unless item

      # Add to player inventory
      @game.add_inventory_item!(item)

      { type: 'give_item', item: item, success: true }
    end

    def process_door_unlock_reward(reward, flag_key)
      room_id = reward['room_id'] || reward['target_room']

      return { type: 'error', message: 'No room_id specified' } unless room_id

      # Unlock the door (same as NPC door unlock)
      @game.unlock_room!(room_id)

      { type: 'unlock_door', room_id: room_id, success: true }
    end

    def process_event_reward(reward, flag_key)
      # Emit event (NPC can listen and trigger conversations)
      event_name = reward['event_name'] || "flag_submitted:#{flag_key}"

      # Store event in player_state for client to emit
      @game.player_state['pending_events'] ||= []
      @game.player_state['pending_events'] << {
        'name' => event_name,
        'data' => { 'flag' => flag_key, 'timestamp' => Time.current.to_i }
      }
      @game.save!

      { type: 'emit_event', event_name: event_name, success: true }
    end

    def find_flag_station_by_id(flag_station_id)
      @game.scenario_data['rooms']&.each do |_room_id, room|
        room['objects']&.each do |obj|
          return obj if (obj['id'] || obj['name']) == flag_station_id && obj['type'] == 'flag-station'
        end
      end
      nil
    end

    # Find the flag-station that contains the submitted flag
    def find_flag_station_for_flag(flag_key)
      @game.scenario_data['rooms']&.each do |_room_id, room|
        room['objects']&.each do |obj|
          next unless obj['type'] == 'flag-station'
          next unless obj['flags']&.any? { |f| f.downcase == flag_key.downcase }

          return obj
        end
      end
      nil
    end

    # Generate a flag identifier in the format: {vmId}-flag{index}
    # Example: "desktop-flag1", "kali-flag2"
    def generate_flag_identifier(flag_key, flag_station)
      return nil unless flag_station

      # Find flag index in flags array (0-based)
      flag_index = flag_station['flags']&.find_index { |f| f.downcase == flag_key.downcase }
      return nil unless flag_index

      # Get VM ID (use first VM if multiple)
      vm_id = flag_station['acceptsVms']&.first
      return nil unless vm_id

      # Generate identifier: "desktop-flag1" (1-indexed for display)
      "#{vm_id}-flag#{flag_index + 1}"
    end

    # Get current player's preference record
    def current_player_preference
      if current_player.respond_to?(:break_escape_preference)
        current_player.break_escape_preference
      elsif current_player.respond_to?(:preference)
        # Reload association to ensure fresh data
        current_player.reload.preference
      end
    end

    # Create default preference for player
    def create_default_preference
      if current_player.respond_to?(:ensure_break_escape_preference!)
        current_player.ensure_break_escape_preference!
        current_player.break_escape_preference
      elsif current_player.respond_to?(:ensure_preference!)
        current_player.ensure_preference!
        current_player.preference
      else
        # Fallback: create directly
        PlayerPreference.create!(player: current_player)
      end
    end
  end
end
