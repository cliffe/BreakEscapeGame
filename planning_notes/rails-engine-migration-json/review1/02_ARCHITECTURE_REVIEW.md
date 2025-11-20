# Architecture Review

This document validates the technical design decisions in the migration plan.

---

## Database Design

### ✅ JSON-Centric Approach - EXCELLENT

**Decision:** Use JSONB columns for flexible state storage instead of normalized relational tables.

**Validation:** ✅ **CORRECT CHOICE**

**Reasoning:**
1. **Game state is hierarchical** - Perfect fit for JSON structure
2. **Rapid iteration** - Can add new state fields without migrations
3. **PostgreSQL JSONB performance** - GIN indexes provide fast queries
4. **Scenario data varies** - Each scenario has different objects/rooms
5. **Reduces complexity** - 3 tables vs 10+ with proper indexes

**Evidence from similar systems:**
- Many game backends use document stores (MongoDB, Firestore)
- Rails + JSONB provides best of both worlds
- Hacktivity already uses PostgreSQL (validated in 05_HACKTIVITY_INTEGRATION.md)

**Recommendation:** ✅ Keep this approach

---

## Polymorphic Player Association

### ✅ Polymorphic Design - CORRECT

**Decision:** Use polymorphic `belongs_to :player` for User or DemoUser.

```ruby
belongs_to :player, polymorphic: true
```

**Validation:** ✅ **CORRECT FOR REQUIREMENTS**

**Reasoning:**
1. **Supports standalone mode** - DemoUser for development
2. **Integrates with Hacktivity** - Uses existing User model
3. **Rails standard pattern** - Well-documented and tested
4. **Authorization compatible** - Pundit handles polymorphic associations

**Hacktivity Compatibility:**
```ruby
# Hacktivity User model has methods needed:
user.admin?         # ✓ Exists
user.account_manager?  # ✓ Exists
user.handle         # ✓ Exists
```

**Recommendation:** ✅ Keep this approach

---

## API Design

### ✅ Session-Based Authentication - APPROPRIATE

**Decision:** Use Rails session-based auth (not JWT).

**Validation:** ✅ **MATCHES HACKTIVITY ARCHITECTURE**

**Reasoning:**
1. **Hacktivity uses Devise** - Session-based by default
2. **Simplifies integration** - No token management needed
3. **CSRF protection** - Built-in with Rails
4. **Secure cookies** - HTTPOnly, Secure flags
5. **No mobile app requirement** - Web-only use case

**Alternative Considered:** JWT tokens
**Why Rejected:** Adds complexity without benefit for web-only game

**Recommendation:** ✅ Keep session-based auth

---

### ✅ 6 API Endpoints - MINIMAL AND SUFFICIENT

**Decision:** Limit API surface to 6 essential endpoints.

**Validation:** ✅ **CORRECT SCOPE**

**Endpoints:**
1. `GET /bootstrap` - Initial game data
2. `PUT /sync_state` - Periodic state sync
3. `POST /unlock` - Server-side validation
4. `POST /inventory` - Inventory updates
5. `GET /rooms/:id` - Load room data
6. `GET /npcs/:id/script` - Lazy-load NPC scripts

**Coverage Analysis:**
- ✅ Unlocking (critical validation)
- ✅ Inventory management
- ✅ NPC interactions
- ✅ Room discovery
- ✅ State persistence
- ⚠️ Missing: Minigame results, combat events (see recommendations)

**Recommendation:** ✅ Keep core 6, consider 2 additions (see 05_RECOMMENDATIONS.md)

---

## Database Schema

### ⚠️ NPC Scripts Table - NEEDS ADJUSTMENT

**Current Design:**
```ruby
create_table :break_escape_npc_scripts do |t|
  t.references :scenario, null: false
  t.string :npc_id, null: false
  t.index [:scenario_id, :npc_id], unique: true
end
```

**Issue:** Doesn't support shared NPCs across scenarios.

**Validation:** ❌ **INCORRECT FOR CODEBASE**

**Evidence:**
- `test-npc.json` used in 10+ scenarios
- `generic-npc.json` designed for reuse
- Hub NPCs (`haxolottle_hub.json`) shared across scenarios

**Recommendation:** ⚠️ See recommended fix in 06_UPDATED_SCHEMA.md

---

### ✅ Game Instances Table - WELL DESIGNED

**Schema:**
```ruby
create_table :break_escape_game_instances do |t|
  t.references :player, polymorphic: true
  t.references :scenario
  t.jsonb :player_state, default: { ... }
  t.string :status
  t.datetime :started_at, :completed_at
  t.integer :score, :health
end
```

**Validation:** ✅ **SOLID DESIGN** (with minor additions)

**Strengths:**
1. Polymorphic player ✅
2. JSONB for flexible state ✅
3. Status tracking ✅
4. Timestamps for analytics ✅
5. GIN index on player_state ✅

**Missing Fields (non-critical):**
- `attempts` counter - How many times player retried
- `hints_used` - Track hint system usage
- `time_elapsed` - For leaderboards

**Recommendation:** ✅ Core design is good, minor additions recommended

---

## Routes Design

### ✅ Engine Mounting - CORRECT PATTERN

**Decision:** Mount engine at `/break_escape` in Hacktivity.

```ruby
# Hacktivity config/routes.rb
mount BreakEscape::Engine => "/break_escape"
```

**Validation:** ✅ **MATCHES HACKTIVITY PATTERNS**

**Evidence:**
```ruby
# From Hacktivity routes.rb (provided by user):
mount Resque::Server.new, at: "/resque"
# Same pattern ✓
```

**Path Structure:**
```
https://hacktivity.com/break_escape/scenarios
https://hacktivity.com/break_escape/games/123/play
https://hacktivity.com/break_escape/api/games/123/bootstrap
```

**Recommendation:** ✅ Keep this approach

---

## File Organization

### ✅ Static Assets in public/ - CORRECT

**Decision:** Move game files to `public/break_escape/`

**Validation:** ✅ **CORRECT FOR RAILS ENGINES**

**Structure:**
```
public/break_escape/
├── js/       (ES6 modules, unchanged)
├── css/      (stylesheets)
└── assets/   (images, sounds, Tiled maps)
```

**Reasoning:**
1. **Engine isolation** - Assets namespaced under /break_escape/
2. **No asset pipeline** - Simpler deployment
3. **Direct serving** - Nginx/Apache can serve static files
4. **Phaser compatibility** - Expects direct asset URLs

**Alternative Considered:** Rails asset pipeline
**Why Rejected:**
- Adds build complexity
- Phaser needs direct file paths
- No benefit for this use case

**Recommendation:** ✅ Keep static assets in public/

---

### ⚠️ Scenarios in app/assets/ - QUESTIONABLE

**Decision:** Store scenarios in `app/assets/scenarios/` with ERB templates.

**Validation:** ⚠️ **UNCONVENTIONAL BUT ACCEPTABLE**

**Reasoning:**
- `app/assets/` typically for CSS/JS/images
- ERB processing needed for randomization
- Not served directly to client (processed server-side)

**Alternative:** `lib/break_escape/scenarios/`
**Why Not Chosen:** Not clear from plan

**Concerns:**
1. Asset pipeline might try to process these files
2. Needs explicit exclusion from sprockets
3. Unconventional location

**Mitigation:**
```ruby
# config/initializers/assets.rb
Rails.application.config.assets.exclude_paths << Rails.root.join("app/assets/scenarios")
```

**Recommendation:** ⚠️ Consider moving to `lib/` or document exclusion

---

## Client Integration Strategy

### ✅ Minimal Changes - EXCELLENT

**Decision:** Minimize client-side code rewrites.

**Validation:** ✅ **CORRECT ENGINEERING PRACTICE**

**Changes Required:**
1. **New files** (2):
   - `config.js` - API configuration
   - `api-client.js` - Fetch wrapper
2. **Modified files** (~5):
   - Update scenario loading
   - Update unlock validation
   - Update NPC script loading
   - Update inventory sync
   - Update state persistence

**What's NOT changed:**
- ✅ Game logic (player.js, rooms.js)
- ✅ Phaser scenes (game.js)
- ✅ Minigames (all minigame files)
- ✅ NPC systems (npc-manager.js, etc.)
- ✅ UI components (ui/, systems/)

**Percentage of Code Changed:** <5% of client codebase

**Recommendation:** ✅ Excellent approach - minimizes risk

---

## ERB Template Usage

### ✅ ERB for Randomization - CLEVER SOLUTION

**Decision:** Use ERB templates for scenario randomization.

**Example:**
```erb
{
  "locked": true,
  "lockType": "password",
  "requires": "<%= random_password %>"
}
```

**Validation:** ✅ **CREATIVE AND APPROPRIATE**

**Strengths:**
1. **Simple randomization** - No complex logic needed
2. **Rails native** - No new dependencies
3. **Cacheable** - Generate once per game instance
4. **Secure** - Passwords server-side only

**Concerns:**
1. **JSON syntax errors** - ERB could break JSON
2. **No syntax checking** - Until runtime
3. **Debugging harder** - Template vs output

**Mitigation:**
```ruby
# Add JSON validation after ERB processing
def load
  template_path = Rails.root.join('app/assets/scenarios', scenario_name, 'scenario.json.erb')
  erb = ERB.new(File.read(template_path))
  output = erb.result(binding_context.get_binding)

  # Validate JSON syntax
  JSON.parse(output)
rescue JSON::ParserError => e
  raise "Scenario #{scenario_name} has invalid JSON after ERB processing: #{e.message}"
end
```

**Recommendation:** ✅ Keep ERB approach, add validation

---

## Testing Strategy

### ✅ Minitest with Fixtures - MATCHES HACKTIVITY

**Decision:** Use Minitest (not RSpec) with fixture-based testing.

**Validation:** ✅ **CORRECT FOR COMPATIBILITY**

**Evidence from Hacktivity:**
```ruby
# test/models/user_test.rb
class UserTest < ActiveSupport::TestCase
  should have_many(:events).through(:results)
  should validate_presence_of(:handle)
end
```

**Plan Matches:**
```ruby
# test/models/break_escape/game_instance_test.rb
class GameInstanceTest < ActiveSupport::TestCase
  test "should unlock room" do
    game = game_instances(:active_game)
    game.unlock_room!('room_office')
    assert game.room_unlocked?('room_office')
  end
end
```

**Recommendation:** ✅ Keep Minitest approach

---

## Pundit Authorization

### ✅ Pundit Policies - APPROPRIATE

**Decision:** Use Pundit for authorization (not CanCanCan).

**Validation:** ✅ **CLEAN AND TESTABLE**

**Policy Example:**
```ruby
class GameInstancePolicy < ApplicationPolicy
  def show?
    record.player == user || user&.admin?
  end
end
```

**Strengths:**
1. **Explicit policies** - Easy to understand
2. **Testable** - Unit test each policy
3. **Flexible** - Supports polymorphic associations
4. **Standard** - Well-documented gem

**Hacktivity Compatibility:**
- User model has `admin?` method ✅
- User model has `account_manager?` method ✅
- Can extend for custom roles ✅

**Recommendation:** ✅ Keep Pundit

---

## Content Security Policy

### ✅ CSP with Nonces - SECURE

**Decision:** Use CSP nonces for inline scripts.

**Validation:** ✅ **MATCHES HACKTIVITY SECURITY**

**Evidence from Hacktivity:**
```erb
<%= javascript_include_tag 'application', nonce: content_security_policy_nonce %>
```

**Plan Implementation:**
```erb
<script nonce="<%= content_security_policy_nonce %>">
  window.breakEscapeConfig = { ... };
</script>
```

**Security Benefits:**
1. **Prevents XSS** - Blocks unauthorized inline scripts
2. **Nonce-based** - Better than unsafe-inline
3. **Rails built-in** - No custom implementation

**Recommendation:** ✅ Keep CSP approach

---

## Summary: Architecture Score Card

| Component | Rating | Notes |
|-----------|--------|-------|
| Database (JSONB) | ✅ Excellent | Perfect for game state |
| Polymorphic Player | ✅ Correct | Supports both modes |
| API Design | ✅ Good | 6 endpoints sufficient |
| NPC Schema | ⚠️ Needs Fix | Shared NPCs issue |
| Routes/Mounting | ✅ Correct | Matches Hacktivity |
| Static Assets | ✅ Correct | public/ is right |
| Scenario Storage | ⚠️ Questionable | Consider lib/ |
| Client Changes | ✅ Minimal | <5% code change |
| ERB Templates | ✅ Clever | Add validation |
| Testing | ✅ Correct | Matches Hacktivity |
| Authorization | ✅ Correct | Pundit is good |
| Security (CSP) | ✅ Correct | Nonces match |

**Overall Architecture Grade: A-** (Would be A+ with NPC schema fix)

---

**Next Document:** [03_MIGRATION_PLAN_REVIEW.md](./03_MIGRATION_PLAN_REVIEW.md) - Phase-by-phase implementation review
