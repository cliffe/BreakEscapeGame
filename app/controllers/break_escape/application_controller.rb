module BreakEscape
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    # Include Pundit if available
    include Pundit::Authorization if defined?(Pundit)

    # Helper method to get current player (polymorphic)
    def current_player
      if BreakEscape.standalone_mode?
        # Standalone mode - get/create demo user
        @current_player ||= DemoUser.first_or_create!(handle: 'demo_player')
      else
        # Mounted mode - use Hacktivity's current_user
        current_user
      end
    end
    helper_method :current_player

    # Tell Pundit to use current_player as the user for authorization
    def pundit_user
      current_player
    end

    # Handle authorization errors
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end
end
