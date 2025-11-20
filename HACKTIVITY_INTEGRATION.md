# Integrating BreakEscape into Hacktivity

## Prerequisites

- Hacktivity running Rails 7.0+
- PostgreSQL database
- User model with Devise
- Pundit for authorization (recommended)

## Installation Steps

### 1. Add to Gemfile

```ruby
# Gemfile (in Hacktivity repository)
gem 'break_escape', path: '../BreakEscape'
```

### 2. Install and Migrate

```bash
bundle install
rails break_escape:install:migrations
rails db:migrate
rails db:seed  # Creates missions from scenario directories
```

### 3. Mount Engine

```ruby
# config/routes.rb
mount BreakEscape::Engine => "/break_escape"
```

### 4. Configure

```ruby
# config/initializers/break_escape.rb
BreakEscape.configure do |config|
  config.standalone_mode = false  # Mounted mode in Hacktivity
end
```

### 5. Verify User Model

Ensure your User model has these methods for Pundit authorization:

```ruby
class User < ApplicationRecord
  def admin?
    # Your admin check logic
  end

  def account_manager?
    # Optional: account manager check logic
  end
end
```

### 6. Add Navigation Link (Optional)

```erb
<!-- In your Hacktivity navigation -->
<%= link_to "BreakEscape", break_escape_path %>
```

### 7. Restart Server

```bash
rails restart
# or
touch tmp/restart.txt
```

### 8. Verify Installation

Navigate to: `https://your-hacktivity.com/break_escape/`

You should see the mission selection screen.

## Configuration Options

### Environment Variables

```bash
# .env (or similar)
BREAK_ESCAPE_STANDALONE=false  # Mounted mode (default)
```

### Custom Configuration

```ruby
# config/initializers/break_escape.rb
BreakEscape.configure do |config|
  # Mode
  config.standalone_mode = false

  # Demo user (only used in standalone mode)
  config.demo_user_handle = ENV['BREAK_ESCAPE_DEMO_USER'] || 'demo_player'
end
```

## Authorization Integration

BreakEscape uses Pundit policies by default. It expects:

### Game Access
- **Owner**: Users can only access their own games
- **Admin/Account Manager**: Can access all games

### Mission Visibility
- **All Users**: Can see published missions
- **Admin/Account Manager**: Can see all missions (including unpublished)

### Custom Policies

To customize authorization, create policy overrides in Hacktivity:

```ruby
# app/policies/break_escape/game_policy.rb (in Hacktivity)
module BreakEscape
  class GamePolicy < ::BreakEscape::GamePolicy
    def show?
      # Custom logic here
      super || custom_access_check?
    end
  end
end
```

## Database Tables

BreakEscape adds 3 tables to your database:

1. **break_escape_missions** - Metadata for scenarios
   - `name`, `display_name`, `description`, `published`, `difficulty_level`

2. **break_escape_games** - Player game instances
   - `player` (polymorphic: User), `mission_id`, `scenario_data` (JSONB), `player_state` (JSONB)

3. **break_escape_demo_users** - Optional (standalone mode only)
   - Only created if migrations run, can be safely ignored in mounted mode

## API Endpoints

Once mounted, these endpoints are available:

- **Mission List**: `GET /break_escape/missions`
- **Play Mission**: `GET /break_escape/missions/:id`
- **Game View**: `GET /break_escape/games/:id`
- **Scenario Data**: `GET /break_escape/games/:id/scenario`
- **NPC Scripts**: `GET /break_escape/games/:id/ink?npc=:npc_id`
- **Bootstrap**: `GET /break_escape/games/:id/bootstrap`
- **State Sync**: `PUT /break_escape/games/:id/sync_state`
- **Unlock**: `POST /break_escape/games/:id/unlock`
- **Inventory**: `POST /break_escape/games/:id/inventory`

## Asset Serving

Static game assets are served from `public/break_escape/`:
- JavaScript: `public/break_escape/js/`
- CSS: `public/break_escape/css/`
- Images: `public/break_escape/assets/`

These are served by the engine's static file middleware.

## Troubleshooting

### 404 errors on /break_escape/

**Solution**: Ensure engine is mounted in `config/routes.rb`

```ruby
mount BreakEscape::Engine => "/break_escape"
```

### Authentication errors

**Solution**: Verify `current_user` method works in your ApplicationController

```ruby
# In Hacktivity's ApplicationController
def current_user
  # Should return User instance or nil
end
```

### Asset 404s (CSS/JS not loading)

**Solution**: Check that `public/break_escape/` directory exists and contains game files

```bash
ls public/break_escape/js/
ls public/break_escape/css/
ls public/break_escape/assets/
```

### Ink compilation errors

**Solution**: Verify `bin/inklecate` executable exists and is executable

```bash
chmod +x scenarios/inklecate
# Or ensure inklecate is in PATH
```

### CSRF token errors on API calls

**Solution**: Ensure your layout includes CSRF meta tags

```erb
<!-- In application.html.erb -->
<%= csrf_meta_tags %>
```

### Database migration issues

**Solution**: Check PostgreSQL is running and migrations ran successfully

```bash
rails db:migrate:status | grep break_escape
# Should show all migrations as "up"
```

## Performance Considerations

### JIT Ink Compilation
- First NPC interaction compiles `.ink` → `.json` (~300ms)
- Subsequent interactions use cached JSON (~10ms)
- Compiled files persist across restarts
- Production: Pre-compile all .ink files during deployment

### Scenario Generation
- ERB templates render on game creation (~50ms)
- Scenario data cached in `games.scenario_data` JSONB
- No re-rendering during gameplay

### State Sync
- Periodic sync every 30 seconds (configurable)
- Uses Rails cache for temporary state
- Database writes only on unlock/inventory changes

## Security Notes

1. **CSRF Protection**: All POST/PUT endpoints require valid CSRF tokens
2. **Authorization**: Pundit policies enforce access control
3. **XSS Prevention**: Content Security Policy enabled
4. **SQL Injection**: All queries use parameterized statements
5. **Session Security**: Sessions tied to user authentication

## Monitoring

### Key Metrics to Track

- Game session duration
- Mission completion rates
- Unlock attempt failures (may indicate difficulty issues)
- Ink compilation times (should be ~300ms first time)
- State sync success rate

### Logs to Monitor

```ruby
# Game creation
"[BreakEscape] Game created: ID=123, Mission=ceo_exfil"

# Ink compilation
"[BreakEscape] Compiling helper1_greeting.ink..."
"[BreakEscape] Compiled helper1_greeting.ink (45.2 KB)"

# Unlock validation
"[BreakEscape] Unlock validated: door=office, method=password"
```

## Updating BreakEscape

```bash
cd ../BreakEscape
git pull origin main

cd ../Hacktivity
bundle install
rails break_escape:install:migrations  # Install new migrations
rails db:migrate
rails restart
```

## Support

For issues specific to BreakEscape engine:
- Check `README.md` in BreakEscape repository
- Review implementation plan in `planning_notes/`
- Check game client logs in browser console

For Hacktivity integration issues:
- Verify Devise authentication is working
- Check Pundit policies are configured
- Review Rails logs for errors
