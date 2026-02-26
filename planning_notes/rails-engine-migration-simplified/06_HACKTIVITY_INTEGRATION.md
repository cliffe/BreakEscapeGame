# Hacktivity Integration Guide

Complete guide for integrating the BreakEscape Rails Engine into the Hacktivity platform.

**Target:** Hacktivity Rails application
**Engine:** BreakEscape (mountable, isolated namespace)
**Mount Point:** `/break_escape`
**Prerequisites:** Completed Phases 1-12 of implementation plan

---

## Overview

This guide walks through mounting the BreakEscape engine into Hacktivity, ensuring:

- ✅ Engine mounts at `/break_escape`
- ✅ Uses Hacktivity's User model for authentication
- ✅ Shares Hacktivity's session and CSRF protection
- ✅ Database migrations install correctly
- ✅ Static assets serve from `public/break_escape/`
- ✅ Authorization integrates with Hacktivity's policies
- ✅ Tests run in Hacktivity's test suite

---

## Phase 1: Add BreakEscape to Gemfile

### Step 1.1: Update Hacktivity's Gemfile

**Location:** `/path/to/hacktivity/Gemfile`

Add the BreakEscape engine gem:

```ruby
# Gaming engines
gem 'break_escape', path: '../BreakEscape'
```

**Note:** Adjust the `path:` to point to your BreakEscape directory. Use relative or absolute paths.

### Step 1.2: Install the gem

```bash
cd /path/to/hacktivity
bundle install
```

**Expected output:**
```
Fetching gem metadata from https://rubygems.org/...
Using break_escape 0.1.0 from source at `../BreakEscape`
Bundle complete!
```

### Step 1.3: Verify installation

```bash
bundle show break_escape
```

**Expected output:**
```
/path/to/BreakEscape
```

---

## Phase 2: Mount Engine Routes

### Step 2.1: Update Hacktivity's routes.rb

**Location:** `/path/to/hacktivity/config/routes.rb`

Add the engine mount point:

```ruby
Rails.application.routes.draw do
  # Existing Hacktivity routes
  devise_for :users

  # ... other routes ...

  # BreakEscape game engine
  mount BreakEscape::Engine, at: '/break_escape'

  # ... remaining routes ...
end
```

### Step 2.2: Verify routes

```bash
rails routes | grep break_escape
```

**Expected output:**
```
break_escape     /break_escape     BreakEscape::Engine

Routes for BreakEscape::Engine:
       missions GET  /missions(.:format)                    break_escape/missions#index
        mission GET  /missions/:id(.:format)                break_escape/missions#show
          games POST /games(.:format)                       break_escape/games#create
           game GET  /games/:id(.:format)                   break_escape/games#show
  game_scenario GET  /games/:id/scenario(.:format)          break_escape/games#scenario
       game_ink GET  /games/:id/ink(.:format)               break_escape/games#ink
game_bootstrap GET  /games/:id/bootstrap(.:format)          break_escape/api/games#bootstrap
game_sync_state PUT  /games/:id/sync_state(.:format)        break_escape/api/games#sync_state
    game_unlock POST /games/:id/unlock(.:format)            break_escape/api/games#unlock
 game_inventory POST /games/:id/inventory(.:format)         break_escape/api/games#inventory
           root GET  /                                      break_escape/missions#index
```

---

## Phase 3: Install Database Migrations

### Step 3.1: Copy migrations from engine

```bash
cd /path/to/hacktivity
rails break_escape:install:migrations
```

**Expected output:**
```
Copied migration 20251120120001_create_break_escape_missions.break_escape.rb from break_escape
Copied migration 20251120120002_create_break_escape_games.break_escape.rb from break_escape
Copied migration 20251120120003_create_break_escape_demo_users.break_escape.rb from break_escape
```

### Step 3.2: Review migrations

```bash
ls -la db/migrate/ | grep break_escape
```

You should see:
- `*_create_break_escape_missions.break_escape.rb`
- `*_create_break_escape_games.break_escape.rb`
- `*_create_break_escape_demo_users.break_escape.rb` (optional, for standalone mode)

### Step 3.3: Run migrations

```bash
rails db:migrate
```

**Expected output:**
```
== CreateBreakEscapeMissions: migrating =====================================
-- create_table(:break_escape_missions)
   -> 0.0234s
-- add_index(:break_escape_missions, :name, {:unique=>true})
   -> 0.0089s
-- add_index(:break_escape_missions, :published)
   -> 0.0067s
== CreateBreakEscapeMissions: migrated (0.0392s) ============================

== CreateBreakEscapeGames: migrating ========================================
-- create_table(:break_escape_games)
   -> 0.0456s
-- add_index(:break_escape_games, [:player_type, :player_id, :mission_id], {:unique=>true, :name=>"index_games_on_player_and_mission"})
   -> 0.0123s
-- add_index(:break_escape_games, :scenario_data, {:using=>:gin})
   -> 0.0234s
-- add_index(:break_escape_games, :player_state, {:using=>:gin})
   -> 0.0198s
-- add_index(:break_escape_games, :status)
   -> 0.0078s
== CreateBreakEscapeGames: migrated (0.1091s) ===============================
```

### Step 3.4: Verify tables

```bash
rails db:migrate:status
```

Look for:
```
  up     20251120120001  Create break escape missions
  up     20251120120002  Create break escape games
```

Or check in PostgreSQL:
```bash
psql -d hacktivity_development -c "\dt break_escape_*"
```

**Expected output:**
```
                   List of relations
 Schema |          Name           | Type  |  Owner
--------+-------------------------+-------+----------
 public | break_escape_games      | table | postgres
 public | break_escape_missions   | table | postgres
```

---

## Phase 4: Verify User Model Compatibility

### Step 4.1: Check User model

**Location:** `/path/to/hacktivity/app/models/user.rb`

Ensure the User model exists and uses Devise:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # BreakEscape will use polymorphic association
  has_many :break_escape_games,
           class_name: 'BreakEscape::Game',
           as: :player,
           dependent: :destroy
end
```

**Note:** The `has_many :break_escape_games` line is optional but recommended for convenience.

### Step 4.2: Test polymorphic association

```bash
rails console
```

```ruby
# Create a test user
user = User.create!(email: 'test@example.com', password: 'password123')

# Verify BreakEscape can find/use this user
BreakEscape::Game.create!(
  player: user,
  mission: BreakEscape::Mission.first,
  scenario_data: {startRoom: 'test'},
  player_state: {currentRoom: nil}
)

# Should work without errors
```

---

## Phase 5: Seed Mission Data

### Step 5.1: Run BreakEscape seeds

If you have seed data in `db/seeds/break_escape_missions.rb`:

```bash
rails db:seed
```

Or manually create missions:

```bash
rails console
```

```ruby
BreakEscape::Mission.create!([
  {
    name: 'ceo_exfil',
    display_name: 'CEO Exfiltration',
    description: 'Infiltrate the corporate office and gather evidence of insider trading.',
    published: true,
    difficulty_level: 3
  },
  {
    name: 'cybok_heist',
    display_name: 'CybOK Heist',
    description: 'Break into the research facility and steal the CybOK framework.',
    published: true,
    difficulty_level: 4
  }
])
```

### Step 5.2: Verify missions

```bash
rails console
```

```ruby
BreakEscape::Mission.count  # Should be > 0
BreakEscape::Mission.published.pluck(:display_name)
# => ["CEO Exfiltration", "CybOK Heist"]
```

---

## Phase 6: Configure Static Assets

### Step 6.1: Verify public/ directory

Ensure BreakEscape's static assets are in the engine's `public/` directory:

```bash
ls -la /path/to/BreakEscape/public/break_escape/
```

**Expected structure:**
```
public/break_escape/
├── js/
│   ├── phaser.min.js
│   ├── game.js
│   ├── scenes/
│   └── utils/
├── css/
│   └── game.css
└── assets/
    ├── images/
    └── audio/
```

### Step 6.2: Test asset serving

Start the Rails server:

```bash
cd /path/to/hacktivity
rails server
```

Visit in browser:
```
http://localhost:3000/break_escape/js/phaser.min.js
http://localhost:3000/break_escape/css/game.css
```

**Expected:** Files should load correctly (200 status).

**Note:** Rails engines automatically serve files from `public/` at the mount path.

---

## Phase 7: Test the Integration

### Step 7.1: Start Hacktivity server

```bash
cd /path/to/hacktivity
rails server
```

### Step 7.2: Test mission listing

**Visit:** `http://localhost:3000/break_escape`

**Expected:** You should see the missions index page listing all published missions.

### Step 7.3: Test game creation (as logged-in user)

1. **Log in to Hacktivity** as a user
2. **Visit:** `http://localhost:3000/break_escape/missions/1`
3. **Click:** "Start Mission" or similar
4. **Expected:** Redirects to `/break_escape/games/:id`

### Step 7.4: Test API endpoints

Open browser console and run:

```javascript
// Get CSRF token
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

// Get current game ID from URL
const gameId = window.location.pathname.match(/games\/(\d+)/)[1];

// Test bootstrap endpoint
fetch(`/break_escape/games/${gameId}/bootstrap`, {
  method: 'GET',
  credentials: 'same-origin',
  headers: {
    'Accept': 'application/json'
  }
})
  .then(r => r.json())
  .then(data => console.log('Bootstrap:', data));

// Test scenario endpoint
fetch(`/break_escape/games/${gameId}/scenario`, {
  method: 'GET',
  credentials: 'same-origin',
  headers: {
    'Accept': 'application/json'
  }
})
  .then(r => r.json())
  .then(data => console.log('Scenario:', data));
```

**Expected:** Both should return JSON with game data.

### Step 7.5: Test unlock endpoint

```javascript
fetch(`/break_escape/games/${gameId}/unlock`, {
  method: 'POST',
  credentials: 'same-origin',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    targetType: 'door',
    targetId: 'office',
    attempt: 'test_password',
    method: 'password'
  })
})
  .then(r => r.json())
  .then(data => console.log('Unlock result:', data));
```

**Expected:** Returns `{success: true/false, ...}`

---

## Phase 8: Configure Authorization (Optional)

If using Pundit in Hacktivity, ensure policies work correctly.

### Step 8.1: Verify Pundit is installed

**Location:** `/path/to/hacktivity/Gemfile`

```ruby
gem 'pundit'
```

### Step 8.2: Check BreakEscape policies

**Location:** `/path/to/BreakEscape/app/policies/break_escape/`

Ensure these exist:
- `game_policy.rb`
- `mission_policy.rb`

### Step 8.3: Test policy enforcement

```bash
rails console
```

```ruby
user = User.first
game = BreakEscape::Game.create!(player: user, mission: BreakEscape::Mission.first)

# Test policy
policy = BreakEscape::GamePolicy.new(user, game)
policy.show?  # Should be true (user owns game)

# Test with different user
other_user = User.create!(email: 'other@example.com', password: 'password')
policy = BreakEscape::GamePolicy.new(other_user, game)
policy.show?  # Should be false (doesn't own game)
```

---

## Phase 9: Run Tests in Hacktivity

### Step 9.1: Add BreakEscape test helpers to Hacktivity

**Location:** `/path/to/hacktivity/test/test_helper.rb`

Add after existing setup:

```ruby
# Include BreakEscape test helpers
require 'break_escape/test_helper' if defined?(BreakEscape)
```

### Step 9.2: Run BreakEscape tests

```bash
cd /path/to/hacktivity
rails test
```

This runs all tests including BreakEscape's.

To run only BreakEscape tests:

```bash
rails test test/models/break_escape/**/*_test.rb
rails test test/controllers/break_escape/**/*_test.rb
```

### Step 9.3: Verify test fixtures work

Check that Hacktivity's User fixtures are accessible:

```bash
rails console -e test
```

```ruby
# Should find test users
User.find_by(email: 'test@example.com')

# BreakEscape should be able to create games
game = BreakEscape::Game.create!(
  player: User.first,
  mission: BreakEscape::Mission.first
)
```

---

## Phase 10: Configure Session & CSRF

### Step 10.1: Verify session sharing

BreakEscape should automatically share Hacktivity's session. Test:

```bash
rails console
```

```ruby
# Check session store
Rails.application.config.session_store
# => :cookie_store or :active_record_store
```

**Note:** BreakEscape uses `credentials: 'same-origin'` in API calls to share cookies.

### Step 10.2: Verify CSRF protection

Check that Hacktivity includes CSRF meta tags:

**Location:** `/path/to/hacktivity/app/views/layouts/application.html.erb`

Should include:

```erb
<%= csrf_meta_tags %>
```

Test in BreakEscape views:

**Location:** `/path/to/BreakEscape/app/views/layouts/break_escape/application.html.erb`

Should include:

```erb
<!DOCTYPE html>
<html>
<head>
  <meta name="csrf-token" content="<%= form_authenticity_token %>">
  <%= javascript_tag nonce: true do %>
    window.CSRF_TOKEN = '<%= form_authenticity_token %>';
  <% end %>
</head>
<body>
  <%= yield %>
</body>
</html>
```

### Step 10.3: Test CSRF in API calls

From browser console:

```javascript
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
console.log('CSRF Token:', csrfToken);  // Should be a long string
```

Make an API call:

```javascript
fetch('/break_escape/games/1/sync_state', {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({currentRoom: 'test'})
});
```

**Expected:** 200 status, not 422 (CSRF verification failed).

---

## Phase 11: Configure Content Security Policy (CSP)

> **See also:** `HACKTIVITY_INTEGRATION.md` in the engine root for the
> canonical, up-to-date CSP reference with a full source table.

### Step 11.1: Check Hacktivity's CSP configuration

**Location:** `/path/to/hacktivity/config/initializers/content_security_policy.rb`

Hacktivity likely already has a CSP initializer. BreakEscape needs additional
sources appended to it — do **not** replace Hacktivity's existing directives.

### Step 11.2: Add BreakEscape sources to Hacktivity's CSP

Append the following inside (or alongside) Hacktivity's existing
`config.content_security_policy` block:

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    # BreakEscape external scripts: Phaser, EasyStar, Tippy.js, Popper, WebFont
    policy.script_src *policy.script_src,
      "https://cdn.jsdelivr.net",
      "https://unpkg.com",
      "https://ajax.googleapis.com"

    # BreakEscape fonts: Google Fonts CSS + binaries
    policy.style_src *policy.style_src, "https://fonts.googleapis.com"
    policy.font_src  *policy.font_src,  "https://fonts.gstatic.com", :data

    # CyberChef iframe (served from same origin /break_escape/assets/cyberchef/)
    policy.frame_src *policy.frame_src, :self

    # CyberChef Web Workers (Tesseract OCR, Forge prime — run inside the iframe)
    policy.worker_src *policy.worker_src, :self, "blob:"
  end

  # Nonces must cover both script-src AND style-src.
  # BreakEscape uses <style nonce="..."> blocks as well as <script nonce="...">.
  config.content_security_policy_nonce_generator  = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

**Why `unsafe_inline` is NOT needed:** All inline `<script>` and `<style>` blocks
in BreakEscape views carry `nonce="<%= content_security_policy_nonce %>"`.
Inline event handlers (`onclick`, `onerror`) have been removed from the engine.
Do **not** add `:unsafe_inline` — it defeats nonce-based protection entirely.

**Why `style-src` needs to be in `nonce_directives`:** `games/new.html.erb` and
`missions/index.html.erb` both have inline `<style nonce="...">` blocks. If
`style-src` is not in `nonce_directives`, Rails won't inject the nonce and the
styles will be blocked.

### Step 11.3: Verify nonces in BreakEscape views

All `<script>` and `<style>` tags in BreakEscape views use the Rails nonce helper:

```erb
<script nonce="<%= content_security_policy_nonce %>"> ... </script>
<style  nonce="<%= content_security_policy_nonce %>"> ... </style>
<script type="module" src="..." nonce="<%= content_security_policy_nonce %>"></script>
```

Confirm the rendered HTML contains `nonce="..."` attributes on every script/style tag.

### Step 11.4: CSP source reference

| Source | Directive | Needed for |
|--------|-----------|------------|
| `cdn.jsdelivr.net` | `script-src` | Phaser 3.60, EasyStar.js |
| `unpkg.com` | `script-src` | Tippy.js 6, Popper.js 2 |
| `ajax.googleapis.com` | `script-src` | WebFont Loader |
| `fonts.googleapis.com` | `style-src` | Google Fonts CSS |
| `fonts.gstatic.com` | `font-src` | Google Fonts binary files |
| `data:` | `font-src` | Icon data URIs |
| `'self'` | `frame-src` | CyberChef iframe |
| `'self'` + `blob:` | `worker-src` | Tesseract/Forge workers inside CyberChef |

---

## Phase 12: Deploy to Staging

### Step 12.1: Update production config

**Location:** `/path/to/hacktivity/config/environments/production.rb`

Ensure static assets are served:

```ruby
config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
```

Or use a CDN/nginx to serve `public/break_escape/` assets.

### Step 12.2: Precompile assets (if using asset pipeline)

```bash
RAILS_ENV=production rails assets:precompile
```

**Note:** BreakEscape uses static assets in `public/`, so this is optional.

### Step 12.3: Run migrations on staging

```bash
RAILS_ENV=staging rails db:migrate
```

### Step 12.4: Seed missions on staging

```bash
RAILS_ENV=staging rails db:seed
```

### Step 12.5: Test on staging

Visit staging URL:
```
https://staging.hacktivity.com/break_escape
```

Test:
1. Mission listing loads
2. User can start a game
3. API endpoints work
4. Ink scripts load correctly
5. Game state persists across page reloads

---

## Troubleshooting

### Problem: "Uninitialized constant BreakEscape"

**Solution:**
1. Verify `gem 'break_escape'` is in Gemfile
2. Run `bundle install`
3. Restart Rails server

### Problem: Routes not found (404)

**Solution:**
1. Check `mount BreakEscape::Engine, at: '/break_escape'` in routes.rb
2. Run `rails routes | grep break_escape`
3. Restart Rails server

### Problem: Migrations don't run

**Solution:**
1. Run `rails break_escape:install:migrations`
2. Check `db/migrate/` for copied migrations
3. Run `rails db:migrate`
4. Verify with `rails db:migrate:status`

### Problem: "Player must exist" validation error

**Solution:**
1. Ensure User model exists
2. Check polymorphic association: `player_type` and `player_id` are set correctly
3. Verify: `BreakEscape::Game.create!(player: User.first, mission: ...)`

### Problem: Static assets return 404

**Solution:**
1. Check files exist: `ls -la /path/to/BreakEscape/public/break_escape/`
2. Verify mount path matches: `mount BreakEscape::Engine, at: '/break_escape'`
3. Restart Rails server
4. Check `config.public_file_server.enabled` in production.rb

### Problem: CSRF token invalid

**Solution:**
1. Verify `<%= csrf_meta_tags %>` in layout
2. Check `window.CSRF_TOKEN` is set in JavaScript
3. Ensure API calls include `'X-CSRF-Token': csrfToken` header
4. Verify `credentials: 'same-origin'` in fetch calls

### Problem: Ink scripts fail to load

**Solution:**
1. Check `bin/inklecate` exists and is executable: `ls -la bin/inklecate`
2. Test compilation manually: `bin/inklecate -o /tmp/test.json scenarios/ink/test.ink`
3. Check file permissions
4. Verify controller `resolve_and_compile_ink` logic

### Problem: Authorization errors (Pundit)

**Solution:**
1. Ensure Pundit is installed: `gem 'pundit'` in Gemfile
2. Check policies exist: `app/policies/break_escape/game_policy.rb`
3. Verify `authorize @game` in controllers
4. Test policy: `BreakEscape::GamePolicy.new(user, game).show?`

### Problem: Tests fail with "table does not exist"

**Solution:**
1. Run migrations in test environment: `RAILS_ENV=test rails db:migrate`
2. Verify schema.rb includes BreakEscape tables
3. Reset test database: `RAILS_ENV=test rails db:reset`

### Problem: Game state doesn't persist

**Solution:**
1. Check `PUT /games/:id/sync_state` endpoint works
2. Verify `player_state` JSONB column exists
3. Test in console: `game.update!(player_state: {currentRoom: 'test'})`
4. Check logs for errors during API calls

### Problem: Scenario randomization not working

**Solution:**
1. Verify ERB templates exist: `app/assets/scenarios/*/scenario.json.erb`
2. Check `Mission#generate_scenario_data` method
3. Test: `mission.generate_scenario_data` in console
4. Ensure `before_create :generate_scenario_data` callback in Game model

---

## Verification Checklist

After integration, verify all these work:

- [ ] Engine mounts at `/break_escape`
- [ ] Mission listing page loads
- [ ] User can start a game
- [ ] Game redirects to `/break_escape/games/:id`
- [ ] API endpoint `/games/:id/bootstrap` works
- [ ] API endpoint `/games/:id/scenario` works
- [ ] API endpoint `/games/:id/ink?npc=X` works
- [ ] API endpoint `/games/:id/sync_state` works
- [ ] API endpoint `/games/:id/unlock` works
- [ ] Static assets load (JS, CSS, images)
- [ ] Ink scripts compile on-demand (~300ms)
- [ ] Scenario has unique passwords per game
- [ ] Game state persists across page reloads
- [ ] Authorization policies work (can't access other user's games)
- [ ] CSRF protection works
- [ ] Tests pass: `rails test`
- [ ] Database has 2 tables: `break_escape_missions`, `break_escape_games`
- [ ] Polymorphic player works (User or DemoUser)
- [ ] Multiple users can play simultaneously

---

## Performance Monitoring

### Monitor JIT Ink Compilation

Add logging to track compilation times:

**Location:** `/path/to/BreakEscape/app/controllers/break_escape/games_controller.rb`

```ruby
def compile_ink(ink_path)
  start_time = Time.now

  # ... compilation logic ...

  duration = ((Time.now - start_time) * 1000).round
  Rails.logger.info "[BreakEscape] Compiled #{File.basename(ink_path)} in #{duration}ms"
end
```

Monitor logs:
```bash
tail -f log/production.log | grep "BreakEscape"
```

**Expected:** Compilation times under 500ms.

### Monitor Database Performance

Check JSONB query performance:

```sql
-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE query LIKE '%break_escape_games%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

Ensure GIN indexes are used:
```sql
EXPLAIN ANALYZE
SELECT * FROM break_escape_games
WHERE player_state->>'currentRoom' = 'office';
```

**Expected:** Should show `Bitmap Index Scan on break_escape_games_player_state_idx`.

---

## Rollback Plan

If integration fails, rollback:

### Step 1: Remove routes

**Location:** `/path/to/hacktivity/config/routes.rb`

Comment out:
```ruby
# mount BreakEscape::Engine, at: '/break_escape'
```

### Step 2: Rollback migrations

```bash
rails db:rollback STEP=3
```

### Step 3: Remove gem

**Location:** `/path/to/hacktivity/Gemfile`

Comment out:
```ruby
# gem 'break_escape', path: '../BreakEscape'
```

Then:
```bash
bundle install
```

### Step 4: Restart server

```bash
rails server
```

---

## Next Steps After Integration

Once integrated successfully:

1. **User Testing**
   - Invite beta users to play
   - Gather feedback on gameplay
   - Monitor for errors

2. **Performance Tuning**
   - Add database indexes if queries are slow
   - Cache compiled Ink scripts if needed
   - Optimize scenario ERB generation

3. **Analytics**
   - Track game completions
   - Monitor average play time
   - Identify difficult missions

4. **Enhancements**
   - Leaderboards
   - Save/load game states
   - Achievements system
   - Admin dashboard

5. **Monitoring**
   - Set up error tracking (Sentry, Rollbar)
   - Monitor server logs
   - Track API response times

---

## Configuration Reference

### Environment Variables

**Optional environment variables for BreakEscape:**

```bash
# .env or config/application.yml
BREAK_ESCAPE_MOUNT_PATH=/break_escape           # Default mount path
BREAK_ESCAPE_INK_COMPILE_TIMEOUT=5000           # Compilation timeout (ms)
BREAK_ESCAPE_MAX_GAMES_PER_USER=10              # Limit games per user
BREAK_ESCAPE_ENABLE_DEMO_USERS=false            # Disable in production
BREAK_ESCAPE_LOG_LEVEL=info                     # debug, info, warn, error
```

### Initializer (Optional)

**Location:** `/path/to/hacktivity/config/initializers/break_escape.rb`

```ruby
# Optional configuration
BreakEscape.configure do |config|
  # Enable/disable features
  config.enable_demo_users = Rails.env.development?

  # Limits
  config.max_games_per_user = 10
  config.ink_compile_timeout = 5000  # milliseconds

  # Logging
  config.log_ink_compilation = true
  config.log_scenario_generation = true
end
```

---

## Support and Documentation

### BreakEscape Documentation

- [00_OVERVIEW.md](./00_OVERVIEW.md) - Project aims and decisions
- [01_ARCHITECTURE.md](./01_ARCHITECTURE.md) - Technical design
- [02_DATABASE_SCHEMA.md](./02_DATABASE_SCHEMA.md) - Database reference
- [03_IMPLEMENTATION_PLAN.md](./03_IMPLEMENTATION_PLAN.md) - Implementation guide
- [04_API_REFERENCE.md](./04_API_REFERENCE.md) - API endpoints
- [05_TESTING_GUIDE.md](./05_TESTING_GUIDE.md) - Testing strategy

### External Documentation

- [Rails Engines Guide](https://guides.rubyonrails.org/engines.html)
- [Pundit Authorization](https://github.com/varvet/pundit)
- [Devise Authentication](https://github.com/heartcombo/devise)
- [PostgreSQL JSONB](https://www.postgresql.org/docs/current/datatype-json.html)
- [Phaser.js](https://phaser.io/docs)
- [Ink](https://github.com/inkle/ink)

---

## Success Criteria

Integration is successful when:

- ✅ All routes work without errors
- ✅ Users can create and play games
- ✅ Game state persists across sessions
- ✅ API endpoints validate correctly
- ✅ Static assets load properly
- ✅ Ink scripts compile on-demand
- ✅ Authorization prevents unauthorized access
- ✅ Tests pass in Hacktivity environment
- ✅ No errors in production logs
- ✅ Performance is acceptable (<500ms for most requests)

---

## Conclusion

BreakEscape is now integrated into Hacktivity! 🎉

Users can:
- Browse missions at `/break_escape`
- Start games with unique passwords
- Play with persistent state
- Complete missions and track progress

The engine is:
- Self-contained (isolated namespace)
- Secure (server-side validation)
- Performant (JIT compilation ~300ms)
- Scalable (2-table architecture)
- Maintainable (well-tested, documented)

For ongoing support, refer to the documentation files and Rails Engine guides.

---

**Version:** 2.0
**Last Updated:** November 2025
**Status:** Ready for Production
**Maintained by:** BreakEscape Team
