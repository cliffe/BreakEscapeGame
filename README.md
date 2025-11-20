# BreakEscape Rails Engine

Cybersecurity training escape room game as a mountable Rails Engine.

## Features

- 24+ cybersecurity escape room scenarios
- Server-side progress tracking with 2-table schema
- Randomized passwords per game instance via ERB
- JIT Ink script compilation for NPC dialogue
- Polymorphic player support (User/DemoUser)
- Pundit authorization
- RESTful API for game state management
- Session-based state persistence

## Installation

In your Gemfile:

```ruby
gem 'break_escape', path: 'path/to/break_escape'
```

Then:

```bash
bundle install
rails break_escape:install:migrations
rails db:migrate
rails db:seed  # Optional: creates missions from scenarios
```

## Mounting in Host App

In your `config/routes.rb`:

```ruby
mount BreakEscape::Engine => "/break_escape"
```

## Usage

### Standalone Mode (Development)

```bash
export BREAK_ESCAPE_STANDALONE=true
rails server
# Visit http://localhost:3000/break_escape/
```

### Mounted Mode (Production)

Mount in Hacktivity or another Rails app. The engine will use the host app's `current_user` via Devise.

## Configuration

```ruby
# config/initializers/break_escape.rb
BreakEscape.configure do |config|
  config.standalone_mode = false  # true for development
  config.demo_user_handle = 'demo_player'
end
```

## Database Schema

- `break_escape_missions` - Scenario metadata (name, display_name, published, difficulty)
- `break_escape_games` - Player state + scenario snapshot (JSONB)
- `break_escape_demo_users` - Standalone mode only (optional)

## API Endpoints

- `GET /games/:id/scenario` - Scenario JSON (ERB-generated)
- `GET /games/:id/ink?npc=X` - NPC script (JIT compiled from .ink)
- `GET /games/:id/bootstrap` - Initial game data
- `PUT /games/:id/sync_state` - Sync player state
- `POST /games/:id/unlock` - Validate unlock attempt
- `POST /games/:id/inventory` - Update inventory

## Architecture

### ERB Scenario Generation
Scenarios are stored as `.json.erb` templates and rendered on-demand with randomized values:
- `<%= random_password %>` - Generates unique password per game
- `<%= random_pin %>` - Generates unique 4-digit PIN
- `<%= random_code %>` - Generates unique hex code

### JIT Ink Compilation
NPC dialogue scripts compile on first request (~300ms):
1. Check if `.json` exists and is newer than `.ink`
2. If needed, run `inklecate` to compile
3. Cache compiled JSON for subsequent requests

### State Management
Player state stored in JSONB column:
- Current room and unlocked rooms
- Inventory and collected items
- NPC encounters
- Global variables (synced with client)
- Health and minigame state

## Testing

```bash
rails test
```

## License

MIT

## Documentation

See `HACKTIVITY_INTEGRATION.md` for integration guide.
