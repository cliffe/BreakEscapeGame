BreakEscape::Engine.routes.draw do
  # Static files - match only static file paths (must come BEFORE resource routes)
  # Note: These routes are automatically prefixed with /break_escape by the mount in the parent app
  get '/css/*path',    to: 'static_files#serve', constraints: { path: /.*/ }
  get '/js/*path',     to: 'static_files#serve', constraints: { path: /.*/ }
  get '/assets/*path', to: 'static_files#serve', constraints: { path: /.*/ }
  get '/stylesheets/*path', to: 'static_files#serve', constraints: { path: /.*/ }

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
