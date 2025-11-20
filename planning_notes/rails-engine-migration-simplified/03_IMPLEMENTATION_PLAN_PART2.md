# BreakEscape Rails Engine - Implementation Plan (Part 2)

**Continued from 03_IMPLEMENTATION_PLAN.md (Phases 7-12)**

---

## Phase 7: Authorization Policies (Week 5, ~4 hours)

### Objectives

- Create Pundit policies for Game and Mission
- Implement authorization rules
- Test policy logic

### 7.1 Create Policy Directory

```bash
mkdir -p app/policies/break_escape
```

### 7.2 Create ApplicationPolicy

```bash
vim app/policies/break_escape/application_policy.rb
```

**Add:**

```ruby
module BreakEscape
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index?
      false
    end

    def show?
      false
    end

    def create?
      false
    end

    def new?
      create?
    end

    def update?
      false
    end

    def edit?
      update?
    end

    def destroy?
      false
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        raise NotImplementedError
      end

      private

      attr_reader :user, :scope
    end
  end
end
```

**Save and close**

### 7.3 Create GamePolicy

```bash
vim app/policies/break_escape/game_policy.rb
```

**Add:**

```ruby
module BreakEscape
  class GamePolicy < ApplicationPolicy
    def show?
      # Owner or admin/account_manager
      record.player == user || user&.admin? || user&.account_manager?
    end

    def update?
      show?
    end

    def scenario?
      show?
    end

    def ink?
      show?
    end

    def bootstrap?
      show?
    end

    def sync_state?
      show?
    end

    def unlock?
      show?
    end

    def inventory?
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

**Save and close**

### 7.4 Create MissionPolicy

```bash
vim app/policies/break_escape/mission_policy.rb
```

**Add:**

```ruby
module BreakEscape
  class MissionPolicy < ApplicationPolicy
    def index?
      true  # Everyone can see mission list
    end

    def show?
      # Published missions or admin
      record.published? || user&.admin? || user&.account_manager?
    end

    class Scope < Scope
      def resolve
        if user&.admin? || user&.account_manager?
          scope.all
        else
          scope.published
        end
      end
    end
  end
end
```

**Save and close**

### 7.5 Test Policies

```bash
# Start Rails console
rails console

# Test GamePolicy
user = BreakEscape::DemoUser.first_or_create!(handle: 'test_user')
mission = BreakEscape::Mission.first
game = BreakEscape::Game.create!(player: user, mission: mission)

policy = BreakEscape::GamePolicy.new(user, game)
puts policy.show?  # Should be true (owner)

other_user = BreakEscape::DemoUser.create!(handle: 'other_user')
other_policy = BreakEscape::GamePolicy.new(other_user, game)
puts other_policy.show?  # Should be false (not owner)

# Test MissionPolicy
mission_policy = BreakEscape::MissionPolicy.new(user, mission)
puts mission_policy.show?  # Should be true if published

exit
```

**Expected output:** Policy logic works correctly

### 7.6 Commit

```bash
git add -A
git commit -m "feat: Add Pundit authorization policies

- Add ApplicationPolicy base class
- Add GamePolicy (owner or admin can access)
- Add MissionPolicy (published visible to all)
- Implement Scope for filtering records
- Support admin and account_manager roles"

git push
```

---

## Phase 8: Views (Week 5-6, ~6 hours)

### Objectives

- Create mission index view (scenario selection)
- Create game show view (game container)
- Add layout with proper asset loading

### 8.1 Create Missions Index View

```bash
mkdir -p app/views/break_escape/missions
vim app/views/break_escape/missions/index.html.erb
```

**Add:**

```erb
<!DOCTYPE html>
<html>
<head>
  <title>BreakEscape - Select Mission</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
      background: #1a1a1a;
      color: #fff;
    }
    h1 {
      text-align: center;
      color: #00ff00;
    }
    .missions {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 20px;
      margin-top: 40px;
    }
    .mission-card {
      background: #2a2a2a;
      border: 2px solid #00ff00;
      border-radius: 8px;
      padding: 20px;
      text-decoration: none;
      color: #fff;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .mission-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 5px 20px rgba(0, 255, 0, 0.3);
    }
    .mission-title {
      font-size: 24px;
      font-weight: bold;
      margin-bottom: 10px;
      color: #00ff00;
    }
    .mission-description {
      font-size: 14px;
      line-height: 1.6;
      margin-bottom: 15px;
    }
    .mission-difficulty {
      display: inline-block;
      background: #00ff00;
      color: #000;
      padding: 5px 10px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <h1>🔓 BreakEscape - Select Your Mission</h1>

  <div class="missions">
    <% @missions.each do |mission| %>
      <%= link_to mission_path(mission), class: 'mission-card' do %>
        <div class="mission-title"><%= mission.display_name %></div>
        <div class="mission-description">
          <%= mission.description || "An exciting escape room challenge awaits..." %>
        </div>
        <div class="mission-difficulty">
          Difficulty: <%= "⭐" * mission.difficulty_level %>
        </div>
      <% end %>
    <% end %>
  </div>
</body>
</html>
```

**Save and close**

### 8.2 Create Game Show View

```bash
mkdir -p app/views/break_escape/games
vim app/views/break_escape/games/show.html.erb
```

**Add:**

```erb
<!DOCTYPE html>
<html>
<head>
  <title><%= @mission.display_name %> - BreakEscape</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%# Load game CSS %>
  <%= stylesheet_link_tag '/break_escape/css/styles.css' %>
</head>
<body>
  <%# Game container - Phaser will render here %>
  <div id="break-escape-game"></div>

  <%# Loading indicator %>
  <div id="loading" style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #00ff00; font-size: 24px; display: block;">
    Loading game...
  </div>

  <%# Bootstrap configuration for client %>
  <script nonce="<%= content_security_policy_nonce %>">
    window.breakEscapeConfig = {
      gameId: <%= @game.id %>,
      apiBasePath: '<%= game_path(@game) %>',
      assetsPath: '/break_escape/assets',
      csrfToken: '<%= form_authenticity_token %>'
    };
  </script>

  <%# Load game JavaScript (ES6 module) %>
  <%= javascript_include_tag '/break_escape/js/main.js', type: 'module', nonce: content_security_policy_nonce %>
</body>
</html>
```

**Save and close**

### 8.3 Test Views

```bash
# Start Rails server
rails server

# Visit in browser:
# http://localhost:3000/break_escape/

# Should see mission selection screen
# Click a mission
# Should see game view (may not load game yet, that's Phase 9)
```

**Expected output:** Views render correctly

### 8.4 Commit

```bash
git add -A
git commit -m "feat: Add views for missions and game

- Add missions index view with grid layout
- Add game show view with Phaser container
- Include CSP nonces for inline scripts
- Bootstrap game configuration in window object
- Load game CSS and JavaScript"

git push
```

---

## Phase 9: Client Integration (Week 7-8, ~12 hours)

### Objectives

- Create API client wrapper
- Update scenario loading to use API
- Update NPC script loading to use API
- Update unlock validation to use API
- Minimal changes to existing game code

### 9.1 Create Config File

```bash
vim public/break_escape/js/config.js
```

**Add:**

```javascript
// API configuration from server
export const GAME_ID = window.breakEscapeConfig?.gameId;
export const API_BASE = window.breakEscapeConfig?.apiBasePath || '';
export const ASSETS_PATH = window.breakEscapeConfig?.assetsPath || '/break_escape/assets';
export const CSRF_TOKEN = window.breakEscapeConfig?.csrfToken;

// Verify config loaded
if (!GAME_ID) {
  console.error('BreakEscape: Game ID not configured! Check window.breakEscapeConfig');
}
```

**Save and close**

### 9.2 Create API Client

```bash
vim public/break_escape/js/api-client.js
```

**Add:**

```javascript
import { API_BASE, CSRF_TOKEN } from './config.js';

/**
 * API Client for BreakEscape server communication
 */
export class ApiClient {
  /**
   * GET request
   */
  static async get(endpoint) {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      method: 'GET',
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * POST request
   */
  static async post(endpoint, data = {}) {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': CSRF_TOKEN
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new Error(error.error || `API Error: ${response.status}`);
    }

    return response.json();
  }

  /**
   * PUT request
   */
  static async put(endpoint, data = {}) {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': CSRF_TOKEN
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return response.json();
  }

  // Bootstrap - get initial game data
  static async bootstrap() {
    return this.get('/bootstrap');
  }

  // Get scenario JSON
  static async getScenario() {
    return this.get('/scenario');
  }

  // Get NPC script
  static async getNPCScript(npcId) {
    return this.get(`/ink?npc=${npcId}`);
  }

  // Validate unlock attempt
  static async unlock(targetType, targetId, attempt, method) {
    return this.post('/unlock', {
      targetType,
      targetId,
      attempt,
      method
    });
  }

  // Update inventory
  static async updateInventory(action, item) {
    return this.post('/inventory', {
      action,
      item
    });
  }

  // Sync player state
  static async syncState(currentRoom, globalVariables) {
    return this.put('/sync_state', {
      currentRoom,
      globalVariables
    });
  }
}

// Export for global access
window.ApiClient = ApiClient;
```

**Save and close**

### 9.3 Setup CSRF Token Injection (Critical for Security)

**CRITICAL:** Rails requires CSRF tokens for all POST/PUT/DELETE requests. The token must be accessible to JavaScript for API calls.

**IMPORTANT:** If using Hacktivity's application layout, `<%= csrf_meta_tags %>` is already present! You only need to read the existing token.

#### 9.3.1 Determine Your Layout Strategy

**Option A: Using Hacktivity's Application Layout (Recommended)**

If your view uses Hacktivity's layout:

```erb
<!-- app/views/break_escape/games/show.html.erb -->
<!-- Hacktivity's layout already includes <%= csrf_meta_tags %> -->

<div id="game-container"></div>

<!-- CRITICAL: Inject configuration before loading game -->
<%= javascript_tag nonce: true do %>
  // BreakEscape Configuration
  window.breakEscapeConfig = {
    gameId: <%= @game.id %>,
    apiBasePath: '<%= break_escape_path %>/games/<%= @game.id %>',
    assetsPath: '/break_escape/assets',
    // Read CSRF token from meta tag (already in layout)
    csrfToken: document.querySelector('meta[name="csrf-token"]')?.content,
    missionName: '<%= j @game.mission.display_name %>',
    startRoom: '<%= j @game.scenario_data["startRoom"] %>',
    debug: <%= Rails.env.development? %>
  };

  console.log('✓ BreakEscape config loaded:', window.breakEscapeConfig);
<% end %>

<!-- Load Phaser -->
<script src="/break_escape/js/phaser.min.js"></script>

<!-- Load game (as ES6 module) -->
<script type="module" src="/break_escape/js/main.js"></script>
```

**Advantages:**
- ✅ Uses Hacktivity's existing CSRF setup
- ✅ Consistent with other Hacktivity pages
- ✅ Automatic CSRF token rotation handled by Hacktivity
- ✅ No duplicate meta tags

**Option B: Standalone Layout for Engine**

If you create a standalone layout for the engine:

```erb
<!-- app/views/layouts/break_escape/application.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>Break Escape - <%= yield :title %></title>
  <%= csrf_meta_tags %>  <!-- REQUIRED: Add this -->
  <%= csp_meta_tag %>

  <!-- Game CSS -->
  <%= stylesheet_link_tag '/break_escape/css/game.css' %>
</head>
<body>
  <%= yield %>
</body>
</html>
```

```erb
<!-- app/views/break_escape/games/show.html.erb -->
<% content_for :title, @game.mission.display_name %>

<div id="game-container"></div>

<%= javascript_tag nonce: true do %>
  window.breakEscapeConfig = {
    gameId: <%= @game.id %>,
    apiBasePath: '<%= break_escape_path %>/games/<%= @game.id %>',
    assetsPath: '/break_escape/assets',
    csrfToken: '<%= form_authenticity_token %>',  // Generate fresh token
    missionName: '<%= j @game.mission.display_name %>',
    startRoom: '<%= j @game.scenario_data["startRoom"] %>',
    debug: <%= Rails.env.development? %>
  };
<% end %>

<script src="/break_escape/js/phaser.min.js"></script>
<script type="module" src="/break_escape/js/main.js"></script>
```

**When to use:**
- ✅ Engine needs different layout than Hacktivity
- ✅ Full-screen game experience
- ✅ Standalone mode (engine runs independently)

#### 9.3.1a Verify CSRF Meta Tag Exists

**Check that the meta tag is in the rendered HTML:**

```bash
# Start Rails server
rails server

# Visit game page
# View page source (Ctrl+U or Cmd+Option+U)
```

**Look for this in <head>:**
```html
<meta name="csrf-token" content="AaBbCc123...long base64 string..." />
```

**If missing:**
- Check if using Hacktivity's layout
- If standalone layout, add `<%= csrf_meta_tags %>`
- Check `config/application.rb` - forgery protection should be enabled

**Save and close**

#### 9.3.2 Verify CSRF Token in Browser

**After implementing, test in browser console:**

```javascript
// Check if config loaded
console.log(window.breakEscapeConfig);

// Should show:
// {
//   gameId: 123,
//   apiBasePath: "/break_escape/games/123",
//   assetsPath: "/break_escape/assets",
//   csrfToken: "AaBbCc123...long token...",
//   missionName: "CEO Exfiltration",
//   startRoom: "reception",
//   debug: true
// }

// Check CSRF token
console.log('CSRF Token:', window.breakEscapeConfig.csrfToken);
// Should be a long base64 string

// Check meta tag (alternative source)
console.log('Meta tag:', document.querySelector('meta[name="csrf-token"]')?.content);
```

#### 9.3.3 Configure Client-Side Token Reading

**Update config.js to read CSRF token with fallback:**

```bash
vim public/break_escape/js/config.js
```

**Replace with CSRF token reading logic:**

```javascript
// API configuration from server
export const GAME_ID = window.breakEscapeConfig?.gameId;
export const API_BASE = window.breakEscapeConfig?.apiBasePath || '';
export const ASSETS_PATH = window.breakEscapeConfig?.assetsPath || '/break_escape/assets';

// CSRF Token - Try multiple sources (in order of preference)
export const CSRF_TOKEN =
  window.breakEscapeConfig?.csrfToken ||  // From config object (if set in view)
  document.querySelector('meta[name="csrf-token"]')?.content;  // From meta tag (Hacktivity layout)

// Verify critical config loaded
if (!GAME_ID) {
  console.error('❌ CRITICAL: Game ID not configured! Check window.breakEscapeConfig');
  console.error('Expected window.breakEscapeConfig.gameId to be set by server');
}

if (!CSRF_TOKEN) {
  console.error('❌ CRITICAL: CSRF token not found!');
  console.error('This will cause all POST/PUT requests to fail with 422 status');
  console.error('Checked:');
  console.error('  1. window.breakEscapeConfig.csrfToken');
  console.error('  2. meta[name="csrf-token"] tag');
  console.error('');
  console.error('Solutions:');
  console.error('  - If using Hacktivity layout: Ensure layout has <%= csrf_meta_tags %>');
  console.error('  - If standalone: Add <%= csrf_meta_tags %> to layout OR');
  console.error('  - Set window.breakEscapeConfig.csrfToken in view');
}

// Log config for debugging
if (window.breakEscapeConfig?.debug || !CSRF_TOKEN) {
  console.log('✓ BreakEscape config validated:', {
    gameId: GAME_ID,
    apiBasePath: API_BASE,
    assetsPath: ASSETS_PATH,
    csrfToken: CSRF_TOKEN ? `${CSRF_TOKEN.substring(0, 10)}...` : '❌ MISSING',
    csrfTokenSource: window.breakEscapeConfig?.csrfToken ? 'config object' :
                     (document.querySelector('meta[name="csrf-token"]') ? 'meta tag' : 'NOT FOUND'),
    debug: window.breakEscapeConfig?.debug || false
  });
}
```

**Key Features:**
- ✅ Tries `window.breakEscapeConfig.csrfToken` first (if explicitly set)
- ✅ Falls back to meta tag (Hacktivity layout)
- ✅ Detailed error messages showing what was checked
- ✅ Logs token source for debugging

**Save and close**

#### 9.3.4 Test CSRF Protection

**Create a test endpoint call to verify CSRF works:**

```bash
# Start Rails server
rails server

# Open browser to game
# http://localhost:3000/break_escape/games/1

# Open console and test
```

**In browser console:**

```javascript
// Test GET request (no CSRF needed)
fetch('/break_escape/games/1/bootstrap', {
  credentials: 'same-origin',
  headers: { 'Accept': 'application/json' }
})
  .then(r => r.json())
  .then(d => console.log('✓ GET works:', d));

// Test POST without CSRF (should fail with 422)
fetch('/break_escape/games/1/unlock', {
  method: 'POST',
  credentials: 'same-origin',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ targetType: 'door', targetId: 'test' })
})
  .then(r => console.log('Status:', r.status)) // Should be 422
  .then(() => console.log('❌ POST without CSRF failed (expected)'));

// Test POST with CSRF (should work)
const csrfToken = window.breakEscapeConfig.csrfToken;
fetch('/break_escape/games/1/unlock', {
  method: 'POST',
  credentials: 'same-origin',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    targetType: 'door',
    targetId: 'test_room',
    attempt: 'test',
    method: 'password'
  })
})
  .then(r => r.json())
  .then(d => console.log('✓ POST with CSRF works:', d));
```

**Expected results:**
- GET request: ✓ Works (no CSRF needed)
- POST without CSRF: ❌ Returns 422 (CSRF verification failed)
- POST with CSRF: ✓ Works (may fail validation but gets past CSRF)

#### 9.3.5 Common CSRF Issues and Solutions

**Issue 1: "Can't verify CSRF token authenticity"**
```
ActionController::InvalidAuthenticityToken
```

**Solution:**
- Check `<%= csrf_meta_tags %>` is in view
- Check `window.breakEscapeConfig.csrfToken` is set
- Check API client includes `'X-CSRF-Token'` header
- Verify `credentials: 'same-origin'` is set

**Issue 2: CSRF token is null/undefined**

**Solution:** The config.js already implements fallback (see 9.3.3 above):
```javascript
export const CSRF_TOKEN =
  window.breakEscapeConfig?.csrfToken ||  // Try config first
  document.querySelector('meta[name="csrf-token"]')?.content;  // Fall back to meta tag
```

**Additional debugging:**
```javascript
// In browser console
console.log('Config token:', window.breakEscapeConfig?.csrfToken);
console.log('Meta tag token:', document.querySelector('meta[name="csrf-token"]')?.content);
console.log('Using token:', window.CSRF_TOKEN || 'NONE');

// Check if Hacktivity layout is being used
console.log('All meta tags:', Array.from(document.querySelectorAll('meta')).map(m => ({
  name: m.getAttribute('name'),
  content: m.getAttribute('content')?.substring(0, 20) + '...'
})));
```

**Issue 3: Token changes between requests**

**Solution:**
- Rails regenerates tokens periodically (security feature)
- Always use the current token from `window.breakEscapeConfig`
- Don't cache token in localStorage (security risk)

**Issue 4: Development vs Production**

**Solution:**
```ruby
# In config/environments/development.rb (for testing only!)
# DO NOT do this in production!
# config.action_controller.allow_forgery_protection = false
```

Don't disable CSRF in production! Fix the token injection instead.

### 9.4 Update Main Game File

```bash
vim public/break_escape/js/main.js
```

**Find the scenario loading section** (usually near the top of the file or in an init function)

**Before:**
```javascript
// Load scenario
const scenarioData = await fetch('/scenarios/ceo_exfil.json').then(r => r.json());
```

**After:**
```javascript
// Import API client
import { ApiClient } from './api-client.js';

// Load scenario from server
const scenarioData = await ApiClient.getScenario();
```

**Save and close**

### 9.4 Update NPC Loading

**Find where NPC scripts are loaded** (likely in `js/systems/npc-manager.js` or similar)

```bash
# Search for where Ink scripts are loaded
grep -r "storyPath" public/break_escape/js/
```

**Before:**
```javascript
const inkScript = await fetch(npc.storyPath).then(r => r.json());
```

**After:**
```javascript
import { ApiClient } from '../api-client.js';

const inkScript = await ApiClient.getNPCScript(npc.id);
```

### 9.5 Update Unlock Validation with Loading UI

**CRITICAL:** This section handles the conversion from client-side to server-side unlock validation. The unlock system is in `js/systems/unlock-system.js` and is called after minigames succeed.

#### 9.5.1 Create Simple Unlock Loading Helper

**Create a minimal helper for throbbing effect during server validation:**

```bash
vim public/break_escape/js/utils/unlock-loading-ui.js
```

**Add:**

```javascript
/**
 * UNLOCK LOADING UI
 * =================
 * Simple throbbing effect for doors/objects during server unlock validation.
 */

/**
 * Start throbbing effect on sprite
 * @param {Phaser.GameObjects.Sprite} sprite - The door or object sprite
 */
export function startThrob(sprite) {
  if (!sprite || !sprite.scene) return;

  // Blue tint + pulsing alpha
  sprite.setTint(0x4da6ff);

  sprite.scene.tweens.add({
    targets: sprite,
    alpha: { from: 1.0, to: 0.7 },
    duration: 300,
    ease: 'Sine.easeInOut',
    yoyo: true,
    repeat: -1  // Loop forever
  });
}

/**
 * Stop throbbing effect
 * @param {Phaser.GameObjects.Sprite} sprite - The door or object sprite
 */
export function stopThrob(sprite) {
  if (!sprite || !sprite.scene) return;

  // Kill all tweens on this sprite
  sprite.scene.tweens.killTweensOf(sprite);

  // Reset appearance
  sprite.clearTint();
  sprite.setAlpha(1.0);
}
```

**That's it! No complex timeline management, no success/failure flashes, no stored references.**

**Why this is simpler:**
- Door sprite gets removed anyway when it opens
- Container items automatically transition to next state
- Game already shows success/error alerts
- Just need visual feedback during the ~100-300ms API call

**Save and close**

#### 9.5.2 Update unlock-system.js for Server Validation

**Now update the actual unlock system to use server validation:**

```bash
vim public/break_escape/js/systems/unlock-system.js
```

**At the top, add imports:**

```javascript
import { ApiClient } from '../api-client.js';
import { startThrob, stopThrob } from '../utils/unlock-loading-ui.js';
```

**Find the `unlockTarget` function (around line 468) and wrap it with server validation:**

**Before (current code):**
```javascript
export function unlockTarget(lockable, type, layer) {
    console.log('🔓 unlockTarget called:', { type, lockable });

    if (type === 'door') {
        unlockDoor(lockable);
        // ... rest of door unlock logic
    } else {
        // ... item unlock logic
    }
}
```

**After (with server validation):**
```javascript
/**
 * Unlock a target (door or item) with server validation
 * @param {Object} lockable - The door or item sprite
 * @param {string} type - 'door' or 'item'
 * @param {Object} layer - The Phaser layer
 * @param {string} attempt - The password/pin/key used
 * @param {string} method - 'password', 'pin', 'key', 'lockpick', etc.
 */
export async function unlockTarget(lockable, type, layer, attempt = null, method = null) {
    console.log('🔓 unlockTarget called:', { type, lockable, attempt, method });

    // Start throbbing
    startThrob(lockable);

    try {
        // Get target ID
        const targetId = type === 'door'
            ? lockable.doorProperties?.connectedRoom || lockable.doorProperties?.roomId
            : lockable.scenarioData?.id || lockable.objectId;

        // Validate with server
        console.log('🔓 Validating unlock with server...', { targetId, type, method });
        const result = await ApiClient.unlock(type, targetId, attempt, method);

        // Stop throbbing (whether success or failure)
        stopThrob(lockable);

        if (result.success) {
            console.log('✅ Server validated unlock');

            // Perform client-side unlock
            if (type === 'door') {
                unlockDoor(lockable);

                // Emit door unlocked event
                if (window.eventDispatcher) {
                    const doorProps = lockable.doorProperties || {};
                    window.eventDispatcher.emit('door_unlocked', {
                        roomId: doorProps.roomId,
                        connectedRoom: doorProps.connectedRoom,
                        direction: doorProps.direction,
                        lockType: doorProps.lockType
                    });
                }
            } else {
                // Handle item unlocking
                if (lockable.scenarioData) {
                    lockable.scenarioData.locked = false;

                    if (lockable.scenarioData.contents) {
                        lockable.scenarioData.isUnlockedButNotCollected = true;

                        // Emit item unlocked event
                        if (window.eventDispatcher) {
                            window.eventDispatcher.emit('item_unlocked', {
                                itemType: lockable.scenarioData.type,
                                itemName: lockable.scenarioData.name,
                                lockType: lockable.scenarioData.lockType
                            });
                        }

                        // Auto-launch container minigame (throb already stopped)
                        setTimeout(() => {
                            if (window.handleContainerInteraction) {
                                window.handleContainerInteraction(lockable);
                            }
                        }, 500);

                        return;
                    }
                } else {
                    lockable.locked = false;
                    if (lockable.contents) {
                        lockable.isUnlockedButNotCollected = true;
                        return;
                    }
                }

                // For items without containers, collect them
                if (lockable.layer) {
                    lockable.layer.remove(lockable);
                }

                window.gameAlert(`Collected ${lockable.scenarioData?.name || 'item'}`,
                    'success', 'Item Collected', 3000);
            }
        } else {
            // Server rejected unlock
            console.error('❌ Server rejected unlock:', result.message);
            window.gameAlert(result.message || 'Unlock failed', 'error', 'Unlock Failed', 3000);
        }
    } catch (error) {
        // Stop throbbing on error
        stopThrob(lockable);

        console.error('❌ Unlock validation failed:', error);
        window.gameAlert('Failed to validate unlock with server', 'error', 'Network Error', 4000);
    }
}

// Keep original unlockTarget for testing without server (fallback)
export function unlockTargetClientSide(lockable, type, layer) {
    console.log('🔓 unlockTargetClientSide (fallback without server validation)');
    // ... original implementation for testing
}
```

**Key simplifications:**
- Just `startThrob()` at the beginning
- Just `stopThrob()` when done (success, failure, or error)
- No need to track success/failure differently - the game alerts handle that
- Door/container transitions handle removing the sprite

**Save and close**

#### 9.5.3 Update Minigame Callbacks

**The unlock system is triggered AFTER minigames succeed. Update minigame callbacks to pass attempt and method:**

**Find these sections in `unlock-system.js` and update the callbacks:**

**For PIN minigame (around line 175):**

**Before:**
```javascript
startPinMinigame(lockable, type, lockRequirements.requires, (success) => {
    if (success) {
        unlockTarget(lockable, type, lockable.layer);
    }
});
```

**After:**
```javascript
startPinMinigame(lockable, type, lockRequirements.requires, (success, enteredPin) => {
    if (success) {
        unlockTarget(lockable, type, lockable.layer, enteredPin, 'pin');
    }
});
```

**For Password minigame (around line 195):**

**Before:**
```javascript
startPasswordMinigame(lockable, type, lockRequirements.requires, (success) => {
    if (success) {
        unlockTarget(lockable, type, lockable.layer);
    }
}, passwordOptions);
```

**After:**
```javascript
startPasswordMinigame(lockable, type, lockRequirements.requires, (success, enteredPassword) => {
    if (success) {
        unlockTarget(lockable, type, lockable.layer, enteredPassword, 'password');
    }
}, passwordOptions);
```

**For Key minigame (around line 107):**

**Before:**
```javascript
startKeySelectionMinigame(lockable, type, playerKeys, requiredKey, unlockTarget);
```

**After:**
```javascript
startKeySelectionMinigame(lockable, type, playerKeys, requiredKey, (lockable, type, layer, keyId) => {
    unlockTarget(lockable, type, layer, keyId, 'key');
});
```

**For Lockpick minigame (around line 157):**

**Before:**
```javascript
startLockpickingMinigame(lockable, window.game, difficulty, (success) => {
    if (success) {
        setTimeout(() => {
            unlockTarget(lockable, type, lockable.layer);
        }, 100);
    }
});
```

**After:**
```javascript
startLockpickingMinigame(lockable, window.game, difficulty, (success) => {
    if (success) {
        setTimeout(() => {
            unlockTarget(lockable, type, lockable.layer, 'lockpick', 'lockpick');
        }, 100);
    }
});
```

**For Biometric (around line 237):**

**Before:**
```javascript
if (fingerprintQuality >= requiredThreshold) {
    unlockTarget(lockable, type, lockable.layer);
}
```

**After:**
```javascript
if (fingerprintQuality >= requiredThreshold) {
    unlockTarget(lockable, type, lockable.layer, requiredFingerprint, 'biometric');
}
```

**For Bluetooth (around line 287):**

**Before:**
```javascript
if (requiredDeviceData.signalStrength >= minSignalStrength) {
    unlockTarget(lockable, type, lockable.layer);
}
```

**After:**
```javascript
if (requiredDeviceData.signalStrength >= minSignalStrength) {
    unlockTarget(lockable, type, lockable.layer, requiredDevice, 'bluetooth');
}
```

**For RFID (around line 363):**

**Before:**
```javascript
onComplete: (success) => {
    if (success) {
        setTimeout(() => {
            unlockTarget(lockable, type, lockable.layer);
        }, 100);
    }
}
```

**After:**
```javascript
onComplete: (success, cardId) => {
    if (success) {
        setTimeout(() => {
            unlockTarget(lockable, type, lockable.layer, cardId, 'rfid');
        }, 100);
    }
}
```

**Save and close**

#### 9.5.4 Handle Testing Mode

**Add ability to bypass server validation during development:**

```javascript
// At top of unlock-system.js after imports
const USE_SERVER_VALIDATION = !window.DISABLE_SERVER_VALIDATION;

// In unlockTarget function, add fallback:
export async function unlockTarget(lockable, type, layer, attempt = null, method = null) {
    // Check if server validation is disabled for testing
    if (!USE_SERVER_VALIDATION || window.DISABLE_SERVER_VALIDATION) {
        console.log('⚠️ Server validation disabled - using client-side unlock');
        return unlockTargetClientSide(lockable, type, layer);
    }

    // ... rest of server validation code
}
```

**This allows testing without server by setting:**
```javascript
window.DISABLE_SERVER_VALIDATION = true;
```

### 9.6 Add State Sync

**Add periodic state sync** (in main game update loop or create new file)

```bash
vim public/break_escape/js/state-sync.js
```

**Add:**

```javascript
import { ApiClient } from './api-client.js';

/**
 * Periodic state synchronization with server
 */
export class StateSync {
  constructor(interval = 30000) { // 30 seconds
    this.interval = interval;
    this.timer = null;
  }

  start() {
    this.timer = setInterval(() => this.sync(), this.interval);
    console.log('State sync started (every 30s)');
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async sync() {
    try {
      // Get current game state
      const currentRoom = window.currentRoom?.name;
      const globalVariables = window.gameState?.globalVariables || {};

      // Sync to server
      await ApiClient.syncState(currentRoom, globalVariables);
      console.log('✓ State synced to server');
    } catch (error) {
      console.error('State sync failed:', error);
    }
  }
}

// Create global instance
window.stateSync = new StateSync();
```

**Save and close**

**Then in main.js, start sync:**

```javascript
import { StateSync } from './state-sync.js';

// After game loads
const stateSync = new StateSync();
stateSync.start();
```

### 9.7 Update Asset Paths

**Ensure all asset paths use the correct base**

```bash
# Find hardcoded asset paths
grep -r "assets/" public/break_escape/js/ | grep -v "ASSETS_PATH"

# Update any that don't use ASSETS_PATH config
```

**Example fix:**

**Before:**
```javascript
this.load.image('player', 'assets/player.png');
```

**After:**
```javascript
import { ASSETS_PATH } from './config.js';
this.load.image('player', `${ASSETS_PATH}/player.png`);
```

### 9.8 Test Client Integration

```bash
# Start Rails server
rails server

# Visit game in browser
# http://localhost:3000/break_escape/

# Open browser console
# Verify:
# - No 404 errors for assets
# - Scenario loads from /games/X/scenario
# - NPC scripts load from /games/X/ink?npc=X
# - State sync logs every 30 seconds
```

**Expected output:** Game loads and plays, using API for data

### 9.9 Commit

```bash
git add -A
git commit -m "feat: Integrate client with Rails API

- Add api-client.js wrapper for server communication
- Add config.js for API configuration
- Update scenario loading to use API
- Update NPC script loading to use API (JIT compilation)
- Add unlock validation via API
- Add periodic state sync (every 30s)
- Update asset paths to use ASSETS_PATH config
- Minimal changes to existing game logic"

git push
```

---

## Phase 10: Testing (Week 9-10, ~8 hours)

### Objectives

- Create model tests
- Create controller tests
- Create integration tests
- Ensure all tests pass

### 10.1 Create Test Fixtures

```bash
mkdir -p test/fixtures/break_escape
vim test/fixtures/break_escape/missions.yml
```

**Add:**

```yaml
ceo_exfil:
  name: ceo_exfil
  display_name: CEO Exfiltration
  description: Test scenario
  published: true
  difficulty_level: 3

unpublished:
  name: test_unpublished
  display_name: Unpublished Test
  description: Not visible
  published: false
  difficulty_level: 1
```

**Save and close**

```bash
vim test/fixtures/break_escape/demo_users.yml
```

**Add:**

```yaml
test_user:
  handle: test_user

other_user:
  handle: other_user
```

**Save and close**

```bash
vim test/fixtures/break_escape/games.yml
```

**Add:**

```yaml
active_game:
  player: test_user (BreakEscape::DemoUser)
  mission: ceo_exfil
  scenario_data: { "startRoom": "reception", "rooms": {} }
  player_state: { "currentRoom": "reception", "unlockedRooms": ["reception"] }
  status: in_progress
  score: 0
```

**Save and close**

### 10.2 Test Mission Model

```bash
vim test/models/break_escape/mission_test.rb
```

**Add:**

```ruby
require 'test_helper'

module BreakEscape
  class MissionTest < ActiveSupport::TestCase
    test "should validate presence of name" do
      mission = Mission.new(display_name: 'Test')
      assert_not mission.valid?
      assert mission.errors[:name].any?
    end

    test "should validate uniqueness of name" do
      Mission.create!(name: 'test', display_name: 'Test')
      duplicate = Mission.new(name: 'test', display_name: 'Test 2')
      assert_not duplicate.valid?
    end

    test "published scope returns only published missions" do
      assert_includes Mission.published, missions(:ceo_exfil)
      assert_not_includes Mission.published, missions(:unpublished)
    end

    test "scenario_path returns correct path" do
      mission = missions(:ceo_exfil)
      expected = Rails.root.join('app/assets/scenarios/ceo_exfil')
      assert_equal expected, mission.scenario_path
    end
  end
end
```

**Save and close**

### 10.3 Test Game Model

```bash
vim test/models/break_escape/game_test.rb
```

**Add:**

```ruby
require 'test_helper'

module BreakEscape
  class GameTest < ActiveSupport::TestCase
    setup do
      @game = games(:active_game)
    end

    test "should belong to player and mission" do
      assert @game.player
      assert @game.mission
    end

    test "should unlock room" do
      @game.unlock_room!('office')
      assert @game.room_unlocked?('office')
    end

    test "should track inventory" do
      item = { 'type' => 'key', 'name' => 'Test Key' }
      @game.add_inventory_item!(item)
      assert_includes @game.player_state['inventory'], item
    end

    test "should update health" do
      @game.update_health!(50)
      assert_equal 50, @game.player_state['health']
    end

    test "should clamp health between 0 and 100" do
      @game.update_health!(150)
      assert_equal 100, @game.player_state['health']

      @game.update_health!(-10)
      assert_equal 0, @game.player_state['health']
    end
  end
end
```

**Save and close**

### 10.4 Test Controllers

```bash
vim test/controllers/break_escape/missions_controller_test.rb
```

**Add:**

```ruby
require 'test_helper'

module BreakEscape
  class MissionsControllerTest < ActionDispatch::IntegrationTest
    test "should get index" do
      get missions_url
      assert_response :success
    end

    test "should show published mission" do
      mission = missions(:ceo_exfil)
      get mission_url(mission)
      assert_response :redirect  # Redirects to game
    end
  end
end
```

**Save and close**

### 10.5 Run Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/break_escape/mission_test.rb

# Run specific test
rails test test/models/break_escape/mission_test.rb:5
```

**Expected output:** All tests pass

### 10.6 Commit

```bash
git add -A
git commit -m "test: Add comprehensive test suite

- Add fixtures for missions, demo_users, games
- Add model tests for Mission and Game
- Add controller tests
- Test validations, scopes, and methods
- All tests passing"

git push
```

---

## Phase 11: Standalone Mode (Week 10, ~4 hours)

### Objectives

- Create DemoUser model for standalone development
- Add configuration system
- Support both standalone and mounted modes

### 11.1 Create DemoUser Migration

```bash
rails generate migration CreateBreakEscapeDemoUsers
```

**Edit migration:**

```bash
MIGRATION=$(ls db/migrate/*_create_break_escape_demo_users.rb)
vim "$MIGRATION"
```

**Replace with:**

```ruby
class CreateBreakEscapeDemoUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_demo_users do |t|
      t.string :handle, null: false
      t.string :role, default: 'user', null: false

      t.timestamps
    end

    add_index :break_escape_demo_users, :handle, unique: true
  end
end
```

**Save and close**

```bash
rails db:migrate
```

### 11.2 Create DemoUser Model

```bash
vim app/models/break_escape/demo_user.rb
```

**Add:**

```ruby
module BreakEscape
  class DemoUser < ApplicationRecord
    self.table_name = 'break_escape_demo_users'

    has_many :games, as: :player, class_name: 'BreakEscape::Game'

    validates :handle, presence: true, uniqueness: true

    # Mimic User role methods
    def admin?
      role == 'admin'
    end

    def account_manager?
      role == 'account_manager'
    end
  end
end
```

**Save and close**

### 11.3 Create Configuration

```bash
vim lib/break_escape.rb
```

**Add:**

```ruby
require "break_escape/version"
require "break_escape/engine"

module BreakEscape
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.standalone_mode?
    configuration&.standalone_mode || false
  end

  class Configuration
    attr_accessor :standalone_mode, :demo_user_handle

    def initialize
      @standalone_mode = false
      @demo_user_handle = 'demo_player'
    end
  end
end

# Initialize with defaults
BreakEscape.configure {}
```

**Save and close**

### 11.4 Create Initializer

```bash
mkdir -p config/initializers
vim config/initializers/break_escape.rb
```

**Add:**

```ruby
# BreakEscape Engine Configuration
BreakEscape.configure do |config|
  # Set to true for standalone mode (development)
  # Set to false when mounted in Hacktivity (production)
  config.standalone_mode = ENV['BREAK_ESCAPE_STANDALONE'] == 'true'

  # Demo user handle for standalone mode
  config.demo_user_handle = ENV['BREAK_ESCAPE_DEMO_USER'] || 'demo_player'
end
```

**Save and close**

### 11.5 Test Standalone Mode

```bash
# Set environment variable
export BREAK_ESCAPE_STANDALONE=true

# Start server
rails server

# Visit http://localhost:3000/break_escape/
# Should work without Hacktivity User model

# Check demo user created
rails runner "puts BreakEscape::DemoUser.first&.handle"
# Should print: demo_player
```

**Expected output:** Standalone mode works

### 11.6 Commit

```bash
git add -A
git commit -m "feat: Add standalone mode support

- Create DemoUser model for standalone development
- Add configuration system (standalone vs mounted)
- Use ENV variables for configuration
- current_player method supports both modes
- Can run without Hacktivity for development"

git push
```

---

## Phase 12: Final Integration & Deployment (Week 11-12, ~6 hours)

### Objectives

- Final testing of all features
- Create README documentation
- Prepare for Hacktivity integration
- Verify production readiness

### 12.1 Create Engine README

```bash
vim README.md
```

**Replace with:**

```markdown
# BreakEscape Rails Engine

Cybersecurity training escape room game as a mountable Rails Engine.

## Features

- 24+ cybersecurity escape room scenarios
- Server-side progress tracking
- Randomized passwords per game instance
- JIT Ink script compilation
- Polymorphic player support (User/DemoUser)
- Pundit authorization
- 2-table simple schema

## Installation

In your Gemfile:

\`\`\`ruby
gem 'break_escape', path: 'path/to/break_escape'
\`\`\`

Then:

\`\`\`bash
bundle install
rails break_escape:install:migrations
rails db:migrate
\`\`\`

## Mounting in Host App

In your `config/routes.rb`:

\`\`\`ruby
mount BreakEscape::Engine => "/break_escape"
\`\`\`

## Usage

### Standalone Mode (Development)

\`\`\`bash
export BREAK_ESCAPE_STANDALONE=true
rails server
# Visit http://localhost:3000/break_escape/
\`\`\`

### Mounted Mode (Production)

Mount in Hacktivity or another Rails app. The engine will use the host app's `current_user` via Devise.

## Configuration

\`\`\`ruby
# config/initializers/break_escape.rb
BreakEscape.configure do |config|
  config.standalone_mode = false  # true for development
  config.demo_user_handle = 'demo_player'
end
\`\`\`

## Database Schema

- `break_escape_missions` - Scenario metadata
- `break_escape_games` - Player state + scenario snapshot
- `break_escape_demo_users` - Standalone mode only (optional)

## API Endpoints

- `GET /games/:id/scenario` - Scenario JSON
- `GET /games/:id/ink?npc=X` - NPC script (JIT compiled)
- `GET /games/:id/bootstrap` - Initial game data
- `PUT /games/:id/sync_state` - Sync state
- `POST /games/:id/unlock` - Validate unlock
- `POST /games/:id/inventory` - Update inventory

## Testing

\`\`\`bash
rails test
\`\`\`

## License

MIT
\`\`\`

**Save and close**

### 12.2 Final Test Checklist

Run through this checklist:

```bash
# 1. Migrations work
rails db:migrate:reset
rails db:seed

# 2. Models work
rails runner "puts BreakEscape::Mission.count"
rails runner "m = BreakEscape::Mission.first; puts m.generate_scenario_data.keys"

# 3. Controllers work
rails server &
curl http://localhost:3000/break_escape/missions
curl http://localhost:3000/break_escape/games/1/scenario

# 4. Tests pass
rails test

# 5. Standalone mode works
export BREAK_ESCAPE_STANDALONE=true
rails server
# Visit http://localhost:3000/break_escape/

# 6. Game plays end-to-end
# - Select mission
# - Load game
# - Interact with objects
# - Unlock rooms
# - Talk to NPCs
```

**Expected output:** All checks pass

### 12.3 Prepare for Hacktivity Integration

```bash
# Create integration guide
vim HACKTIVITY_INTEGRATION.md
```

**Add:**

```markdown
# Integrating BreakEscape into Hacktivity

## Prerequisites

- Hacktivity running Rails 7.0+
- PostgreSQL database
- User model with Devise

## Installation Steps

### 1. Add to Gemfile

\`\`\`ruby
# Gemfile
gem 'break_escape', path: '../BreakEscape'
\`\`\`

### 2. Install and Migrate

\`\`\`bash
bundle install
rails break_escape:install:migrations
rails db:migrate
\`\`\`

### 3. Mount Engine

\`\`\`ruby
# config/routes.rb
mount BreakEscape::Engine => "/break_escape"
\`\`\`

### 4. Configure

\`\`\`ruby
# config/initializers/break_escape.rb
BreakEscape.configure do |config|
  config.standalone_mode = false  # Mounted mode
end
\`\`\`

### 5. Verify User Model

Ensure your User model has:
- `admin?` method
- `account_manager?` method (optional)

### 6. Restart Server

\`\`\`bash
rails restart
\`\`\`

### 7. Visit

Navigate to: https://your-hacktivity.com/break_escape/

## Troubleshooting

- **404 errors:** Check that engine is mounted
- **Auth errors:** Verify Devise current_user works
- **Asset 404s:** Check public/break_escape/ exists
- **Ink errors:** Verify bin/inklecate executable
\`\`\`

**Save and close**

### 12.4 Final Commit

```bash
git add -A
git commit -m "docs: Add README and integration guide

- Comprehensive README with installation instructions
- Hacktivity integration guide
- Configuration documentation
- API reference
- Testing instructions
- Troubleshooting guide

Migration complete! Ready for production."

git push
```

### 12.5 Merge to Main

```bash
# Ensure all tests pass
rails test

# Merge feature branch
git checkout main
git merge rails-engine-migration
git push origin main

# Tag release
git tag -a v1.0.0 -m "Rails Engine Migration Complete"
git push origin v1.0.0
```

---

## Migration Complete! 🎉

### Summary

**Phases Completed:**
1. ✅ Rails Engine Structure
2. ✅ Move Game Files
3. ✅ Scenario ERB Templates
4. ✅ Database Setup
5. ✅ Seed Data
6. ✅ Controllers & Routes
7. ✅ Authorization Policies
8. ✅ Views
9. ✅ Client Integration
10. ✅ Testing
11. ✅ Standalone Mode
12. ✅ Final Integration

**Total Time:** ~78 hours over 10-12 weeks

**What Was Achieved:**
- ✅ Rails Engine with isolated namespace
- ✅ 2-table database schema (missions + games)
- ✅ JIT Ink compilation (~300ms)
- ✅ ERB scenario randomization
- ✅ Polymorphic player (User/DemoUser)
- ✅ Pundit authorization
- ✅ API for game state
- ✅ Minimal client changes (<5%)
- ✅ Comprehensive test suite
- ✅ Standalone mode support
- ✅ Production-ready

**Next Steps:**
1. Deploy to Hacktivity staging
2. Test in production environment
3. Monitor performance
4. Gather user feedback
5. Iterate and improve

Congratulations! The migration is complete.
