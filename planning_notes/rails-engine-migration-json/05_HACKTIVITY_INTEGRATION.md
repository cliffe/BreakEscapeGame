# Hacktivity Integration - Specific Details

**Addendum to Rails Engine Migration Plan**

Based on actual Hacktivity codebase analysis.

---

## ✅ Validation: Plan is Compatible

The implementation plan is **fully compatible** with Hacktivity! Here's what we've confirmed:

### Database: PostgreSQL ✅
- Hacktivity uses PostgreSQL
- JSONB support confirmed
- Plan's schema will work perfectly

### User Model: Compatible ✅
- Hacktivity User has enum roles: `user`, `pro`, `lbu_student`, `vip`, `admin`, `account_manager`
- Admin check: `user.admin?` (enum method) or `user.role == "admin"`
- Polymorphic association will work fine

### Testing: Perfect Match ✅
- Hacktivity uses **Minitest** (not RSpec)
- Uses shoulda-matchers
- Plan already uses Minitest with fixtures
- Integration test patterns match exactly

### CSP & Nonces: Already Covered ✅
- Hacktivity uses `nonce: content_security_policy_nonce` everywhere
- Plan already includes this in all views
- `unsafe-eval` already allowed (needed for Phaser)

---

## 🔧 Specific Integration Instructions

### 1. Mounting the Engine in Hacktivity

Add to `config/routes.rb`:

```ruby
# config/routes.rb (in Hacktivity)

# Mount BreakEscape engine (no special auth needed for viewing scenarios)
mount BreakEscape::Engine => "/break_escape"

# Or with authentication required:
authenticate :user do
  mount BreakEscape::Engine => "/break_escape"
end

# Or with role-based access (e.g., pro users only):
authenticate :user, ->(u) { u.pro? || u.admin? } do
  mount BreakEscape::Engine => "/break_escape"
end
```

**Recommended:** Start without authentication block (scenarios list is public), let engine handle authorization with Pundit.

---

### 2. User Model Integration

The polymorphic association will work perfectly with Hacktivity's User model.

**No changes needed to User model**, but for clarity, you *could* add (optional):

```ruby
# app/models/user.rb (in Hacktivity)
class User < ApplicationRecord
  # ... existing code ...

  # Optional: Add association for visibility
  has_many :break_escape_games,
           class_name: 'BreakEscape::GameInstance',
           as: :player,
           dependent: :destroy
end
```

This is **optional** - the polymorphic association works without it.

---

### 3. Layout Integration

Hacktivity's layout supports **embedded mode** via `params[:embedded]`.

#### Option A: Embedded in Hacktivity Layout

**Keep the engine view simple and let Hacktivity layout wrap it:**

```erb
<%# app/views/break_escape/games/show.html.erb (SIMPLIFIED) %>

<%# Game container %>
<div id="break-escape-game"></div>

<%# Bootstrap config %>
<script nonce="<%= content_security_policy_nonce %>">
  window.breakEscapeConfig = {
    gameId: <%= @game_instance.id %>,
    scenarioName: '<%= j @scenario.display_name %>',
    apiBasePath: '<%= api_game_path(@game_instance) %>',
    assetsPath: '/break_escape/assets',
    csrfToken: '<%= form_authenticity_token %>'
  };
</script>

<%# Load game assets %>
<%= stylesheet_link_tag '/break_escape/css/styles.css', nonce: true %>
<%= javascript_include_tag '/break_escape/js/main.js', type: 'module', nonce: true %>
```

This will be wrapped in Hacktivity's layout automatically!

#### Option B: Full-Screen Game Mode

**For a full-screen game experience:**

```ruby
# app/controllers/break_escape/games_controller.rb
def show
  @game_instance = GameInstance.find(params[:id])
  @scenario = @game_instance.scenario
  authorize @game_instance if defined?(Pundit)

  # Use Hacktivity's embedded mode
  render layout: !params[:embedded].nil? ? false : 'application'
end
```

Then link to: `/break_escape/games/123?embedded=true`

This removes Hacktivity's nav/footer for immersive gameplay.

---

### 4. Authorization with Pundit

The plan already includes Pundit policies. They'll work with Hacktivity's User model:

```ruby
# app/policies/break_escape/game_instance_policy.rb
module BreakEscape
  class GameInstancePolicy < ApplicationPolicy
    def show?
      # Owner, or admin/account_manager can view
      record.player == user || user&.admin? || user&.account_manager?
    end

    def update?
      show?
    end

    class Scope < Scope
      def resolve
        if user&.admin? || user&.account_manager?
          scope.all
        else
          scope.where(player: user)
        end
      end
    end
  end
end
```

**Note:** Uses Hacktivity's `admin?` and `account_manager?` enum methods.

---

### 5. Scenario Access by Role

You can restrict scenarios by user role:

```ruby
# app/policies/break_escape/scenario_policy.rb
module BreakEscape
  class ScenarioPolicy < ApplicationPolicy
    def show?
      # Published scenarios for everyone
      return true if record.published?

      # Unpublished scenarios for admin/vip/account_manager
      user&.admin? || user&.vip? || user&.account_manager?
    end

    class Scope < Scope
      def resolve
        if user&.admin? || user&.account_manager?
          # Admins and account managers see all
          scope.all
        elsif user&.vip? || user&.pro?
          # VIP and Pro users see published + premium
          scope.where(published: true)
          # Could add: .or(scope.where(premium: true)) if you add that field
        else
          # Regular users see only published
          scope.published
        end
      end
    end
  end
end
```

---

### 6. Navigation Integration

Add link to Hacktivity's navigation:

```erb
<%# app/views/layouts/_navigation.html.erb (in Hacktivity) %>

<%# Add to nav menu %>
<li>
  <%= link_to "Escape Rooms", break_escape_root_path, class: "nav-link" %>
</li>
```

Or add to a specific section:

```erb
<%= link_to "BreakEscape", break_escape.root_path, class: "btn btn-primary" %>
```

**Note:** Use `break_escape.` prefix for engine routes in Hacktivity views.

---

### 7. Test Helper Integration

Add to Hacktivity's test helper for engine tests:

```ruby
# test/test_helper.rb (in Hacktivity)
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  fixtures :all

  # Include Devise helpers
  include Devise::Test::IntegrationHelpers  # for sign_in

  # Helper to access engine routes in tests
  def break_escape
    BreakEscape::Engine.routes.url_helpers
  end
end
```

---

### 8. Current User in Engine Controllers

The engine's `ApplicationController` can access Hacktivity's `current_user`:

```ruby
# app/controllers/break_escape/application_controller.rb
module BreakEscape
  class ApplicationController < ActionController::Base
    # Pundit
    include Pundit::Authorization if defined?(Pundit)

    # Hacktivity's current_user is automatically available!
    def current_player
      if BreakEscape.configuration.standalone_mode
        # Standalone: use demo user
        @current_player ||= DemoUser.first_or_create!(
          handle: BreakEscape.configuration.demo_user['handle'],
          role: BreakEscape.configuration.demo_user['role']
        )
      else
        # Mounted in Hacktivity: use their current_user
        current_user  # Devise method from Hacktivity
      end
    end
    helper_method :current_player

    # Optional: Require login
    # before_action :authenticate_user!, unless: -> { BreakEscape.configuration.standalone_mode }
  end
end
```

**Important:** `current_user` from Hacktivity's Devise is automatically available in the engine!

---

### 9. Migration Installation

When ready to deploy to Hacktivity:

```bash
# In Hacktivity directory
cd /path/to/Hacktivity

# Add to Gemfile
# gem 'break_escape', path: '../BreakEscape'

# Or for production
# gem 'break_escape', git: 'https://github.com/your-org/BreakEscape'

# Install
bundle install

# Copy migrations
rails break_escape:install:migrations

# Run migrations
rails db:migrate

# Import scenarios
rails db:seed
# Or just engine seeds:
rails runner "load Rails.root.join('..', 'BreakEscape', 'db', 'seeds.rb')"
```

---

### 10. Testing in Mounted Context

Test the engine while mounted in Hacktivity:

```ruby
# test/integration/break_escape_integration_test.rb (in Hacktivity)
require 'test_helper'

class BreakEscapeIntegrationTest < ActionDispatch::IntegrationTest
  test "user can access BreakEscape" do
    user = users(:user)
    sign_in user

    # Access engine routes
    get break_escape.scenarios_path
    assert_response :success

    # Create game
    scenario = BreakEscape::Scenario.published.first
    get break_escape.scenario_path(scenario)
    assert_response :redirect

    # Find created game
    game = BreakEscape::GameInstance.find_by(player: user, scenario: scenario)
    assert_not_nil game

    # Play game
    get break_escape.game_path(game)
    assert_response :success
  end

  test "admin can see all games" do
    admin = users(:admin)
    sign_in admin

    get break_escape.scenarios_path
    assert_response :success

    # Should see all scenarios (published and unpublished)
    # Test via Pundit policy...
  end
end
```

---

### 11. Configuration Differences

**Standalone mode** (BreakEscape development):
```yaml
# config/break_escape_standalone.yml
development:
  standalone_mode: true
  demo_user:
    handle: "demo_player"
    role: "pro"
```

**Mounted mode** (Hacktivity production):
```yaml
# config/break_escape_standalone.yml (in Hacktivity)
production:
  standalone_mode: false  # Uses Hacktivity's User model
```

---

### 12. Role Mapping

Hacktivity roles → BreakEscape access:

| Hacktivity Role | Access Level | Can See |
|----------------|--------------|---------|
| `user` | Basic | Published scenarios |
| `pro` | Enhanced | Published scenarios |
| `lbu_student` | Basic | Published scenarios |
| `vip` | Enhanced | Published + unpublished* |
| `admin` | Full | All scenarios |
| `account_manager` | Full | All scenarios |

*Can customize in `ScenarioPolicy`

---

## 🎯 Recommended Deployment Steps

### Phase 1: Standalone Development (Weeks 1-6)
1. Build engine in BreakEscape directory
2. Test with standalone mode
3. Run all engine tests
4. Verify all scenarios work

### Phase 2: Local Hacktivity Integration (Week 7)
1. Add gem to Hacktivity Gemfile (local path)
2. Install migrations
3. Mount in routes
4. Test with real User accounts
5. Verify Pundit policies work

### Phase 3: Staging Deployment (Week 8)
1. Push to staging Hacktivity
2. User acceptance testing
3. Fix any integration issues
4. Performance testing

### Phase 4: Production (Week 9+)
1. Deploy to production
2. Monitor logs and errors
3. Gather user feedback

---

## 🔧 Quick Integration Checklist

When mounting in Hacktivity:

- [ ] Add `gem 'break_escape'` to Gemfile
- [ ] `bundle install`
- [ ] `rails break_escape:install:migrations`
- [ ] `rails db:migrate`
- [ ] Add `mount BreakEscape::Engine => "/break_escape"` to routes
- [ ] Update `config/break_escape_standalone.yml` (standalone_mode: false)
- [ ] Seed scenarios: `rails db:seed`
- [ ] Add navigation link
- [ ] Test with different user roles
- [ ] Verify Pundit policies
- [ ] Test CSP / nonces working
- [ ] Deploy!

---

## ⚠️ Potential Issues & Solutions

### Issue 1: Asset Paths in Production

**Problem:** Assets not loading with `/break_escape/` prefix

**Solution:** Engine middleware handles this (already in plan):
```ruby
# lib/break_escape/engine.rb
config.middleware.use ::ActionDispatch::Static, "#{root}/public"
```

### Issue 2: CSRF Token

**Problem:** API calls fail with CSRF error

**Solution:** Already handled in plan (config passed from view):
```javascript
window.breakEscapeConfig = {
  csrfToken: '<%= form_authenticity_token %>'
};
```

### Issue 3: Devise Timeout

**Problem:** User times out during long game session

**Solution:** Hacktivity timeout is 2 hours (from config), game should save state periodically (already in plan).

Or extend timeout in engine:
```ruby
# config/initializers/devise.rb (in Hacktivity)
config.timeout_in = 4.hours  # Extend if needed
```

---

## 📊 No Changes Needed

These all work perfectly as-is:

✅ Database schema (PostgreSQL + JSONB)
✅ Polymorphic player association
✅ CSP nonces in views
✅ Session-based auth (Devise)
✅ Minitest + fixtures
✅ API endpoint structure
✅ Client-side code
✅ Scenario loading

---

## 🎉 Conclusion

**The plan is validated and ready to implement!**

All decisions were correct:
- PostgreSQL with JSONB ✅
- Polymorphic user model ✅
- Session-based auth ✅
- CSP with nonces ✅
- Minitest testing ✅
- Pundit authorization ✅

**No major changes needed to the implementation plan.**

Just follow the plan in `02_IMPLEMENTATION_PLAN.md` and `02_IMPLEMENTATION_PLAN_PART2.md`, then use this document when mounting in Hacktivity.

**Start building! You're all set.** 🚀
