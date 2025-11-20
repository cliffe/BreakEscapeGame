module BreakEscape
  class MissionsController < ApplicationController
    def index
      @missions = if defined?(Pundit)
                    policy_scope(Mission)
                  else
                    Mission.published
                  end
    end

    def show
      @mission = Mission.find(params[:id])
      authorize @mission if defined?(Pundit)

      # Create or find game instance for current player
      @game = Game.find_or_create_by!(
        player: current_player,
        mission: @mission
      )

      redirect_to game_path(@game)
    end
  end
end
