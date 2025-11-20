BreakEscape::Engine.routes.draw do
  # Mission selection
  resources :missions, only: [:index, :show]

  # Game management
  resources :games, only: [:show, :create] do
    member do
      # Scenario and NPC data
      get 'scenario'  # Returns scenario_data JSON
      get 'ink'       # Returns NPC script (JIT compiled)

      # API endpoints
      scope module: :api do
        get 'bootstrap'     # Initial game data
        put 'sync_state'    # Periodic state sync
        post 'unlock'       # Validate unlock attempt
        post 'inventory'    # Update inventory
      end
    end
  end

  root to: 'missions#index'
end
