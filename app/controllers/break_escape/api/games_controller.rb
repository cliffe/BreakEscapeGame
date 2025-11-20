module BreakEscape
  module Api
    class GamesController < ApplicationController
      before_action :set_game

      # GET /games/:id/bootstrap
      # Initial game data for client
      def bootstrap
        authorize @game if defined?(Pundit)

        render json: {
          gameId: @game.id,
          missionName: @game.mission.display_name,
          startRoom: @game.scenario_data['startRoom'],
          playerState: @game.player_state,
          roomLayout: build_room_layout
        }
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

      def build_room_layout
        layout = {}
        @game.scenario_data['rooms'].each do |room_id, room_data|
          layout[room_id] = {
            connections: room_data['connections'],
            locked: room_data['locked'] || false
          }
        end
        layout
      end
    end
  end
end
