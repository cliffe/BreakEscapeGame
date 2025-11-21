require 'open3'

module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :scenario, :ink, :room, :sync_state, :unlock, :inventory]

    def show
      authorize @game if defined?(Pundit)
      @mission = @game.mission
    end

    # GET /games/:id/scenario
    # Returns scenario JSON for this game instance
    def scenario
      authorize @game if defined?(Pundit)
      render json: @game.scenario_data
    end

    # GET /games/:id/room/:room_id
    # Returns room data for a specific room (lazy-loading support)
    def room
      authorize @game if defined?(Pundit)

      room_id = params[:room_id]
      return render_error('Missing room_id parameter', :bad_request) unless room_id.present?

      # Get room data from scenario
      room_data = @game.scenario_data['rooms']&.[](room_id)
      return render_error("Room not found: #{room_id}", :not_found) unless room_data

      Rails.logger.debug "[BreakEscape] Serving room data for: #{room_id}"

      # Return room data with the room_id for client reference
      render json: { room_id: room_id, room: room_data }
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
        @game.player_state['currentRoom'] = params[:currentRoom]
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

      if is_valid
        if target_type == 'door'
          @game.unlock_room!(target_id)
          room_data = @game.filtered_room_data(target_id)

          render json: {
            success: true,
            type: 'door',
            roomData: room_data
          }
        else
          @game.unlock_object!(target_id)
          render json: {
            success: true,
            type: 'object'
          }
        end
      else
        render json: {
          success: false,
          message: 'Invalid attempt'
        }, status: :unprocessable_entity
      end
    end

    # POST /games/:id/inventory
    # Update inventory
    def inventory
      authorize @game if defined?(Pundit)

      action_type = params[:action_type] || params[:actionType]
      item = params[:item]

      case action_type
      when 'add'
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
