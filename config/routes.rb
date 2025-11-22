BreakEscape::Engine.routes.draw do
  # Static files - caught by routes and served by lightweight controller
  # This ensures files are served from the engine's public directory
  # Constraint { path: /.*/ } ensures we capture the full path including filename with extension
  get '/css/*path',    to: 'static_files#serve', constraints: { path: /.*/ }
  get '/js/*path',     to: 'static_files#serve', constraints: { path: /.*/ }
  get '/assets/*path', to: 'static_files#serve', constraints: { path: /.*/ }
  get '/stylesheets/*path', to: 'static_files#serve', constraints: { path: /.*/ }
  get '/:filename.html', to: 'static_files#serve', constraints: { filename: /test-.*|index/ }

  # Mission selection
  resources :missions, only: [:index, :show]

  # Game management
  resources :games, only: [:show, :create] do
    member do
      # Scenario and NPC data
      get 'scenario'          # Returns full scenario_data JSON (for compatibility)
      get 'scenario_map'      # Returns minimal layout metadata for navigation
      get 'ink'               # Returns NPC script (JIT compiled)
      get 'room/:room_id', to: 'games#room', as: 'room'            # Returns room data for lazy-loading
      get 'container/:container_id', to: 'games#container'  # Returns locked container contents

      # Game state and actions
      put 'sync_state'    # Periodic state sync
      post 'unlock'       # Validate unlock attempt
      post 'inventory'    # Update inventory
    end
  end

  root to: 'missions#index'
end
