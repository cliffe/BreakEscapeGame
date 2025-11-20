# BreakEscape Rails Engine - Implementation Plan (Part 2)

**Continued from 02_IMPLEMENTATION_PLAN.md**

---

## Phase 6 (Continued): API Controllers (Week 3)

### 6.2 API Games Controller

```ruby
# app/controllers/break_escape/api/games_controller.rb
module BreakEscape
  module Api
    class GamesController < ApplicationController
      before_action :set_game_instance

      # GET /api/games/:id/bootstrap
      def bootstrap
        authorize @game_instance if defined?(Pundit)

        render json: {
          gameId: @game_instance.id,
          scenarioName: @game_instance.scenario.display_name,
          startRoom: @game_instance.scenario.start_room,
          playerState: @game_instance.player_state,
          roomLayout: build_room_layout
        }
      end

      # PUT /api/games/:id/sync_state
      def sync_state
        authorize @game_instance if defined?(Pundit)

        # Update player state (partial update)
        @game_instance.player_state.merge!(sync_params)
        @game_instance.save!

        render json: { success: true }
      end

      # POST /api/games/:id/unlock
      def unlock
        authorize @game_instance if defined?(Pundit)

        target_type = params[:targetType] # 'door' or 'object'
        target_id = params[:targetId]
        attempt = params[:attempt]
        method = params[:method]

        # Validate with scenario
        is_valid = @game_instance.scenario.validate_unlock(
          target_type,
          target_id,
          attempt,
          method
        )

        if is_valid
          if target_type == 'door'
            @game_instance.unlock_room!(target_id)
            room_data = @game_instance.scenario.filtered_room_data(target_id)

            render json: {
              success: true,
              type: 'door',
              roomData: room_data
            }
          else
            @game_instance.unlock_object!(target_id)
            # Get object contents from scenario
            contents = find_object_contents(target_id)

            render json: {
              success: true,
              type: 'object',
              contents: contents
            }
          end
        else
          render json: {
            success: false,
            message: 'Invalid attempt'
          }, status: :unprocessable_entity
        end
      end

      # POST /api/games/:id/inventory
      def inventory
        authorize @game_instance if defined?(Pundit)

        action = params[:action] # 'add' or 'remove'
        item = params[:item]

        case action
        when 'add'
          # Validate item exists in unlocked location
          if validate_item_accessible(item)
            @game_instance.add_inventory_item!(item)
            render json: { success: true, inventory: @game_instance.player_state['inventory'] }
          else
            render json: { success: false, message: 'Item not accessible' }, status: :forbidden
          end
        when 'remove'
          @game_instance.remove_inventory_item!(item['id'])
          render json: { success: true, inventory: @game_instance.player_state['inventory'] }
        else
          render json: { success: false, message: 'Invalid action' }, status: :bad_request
        end
      end

      private

      def set_game_instance
        @game_instance = GameInstance.find(params[:id])
      end

      def sync_params
        params.permit(:currentRoom, position: [:x, :y], globalVariables: {})
      end

      def build_room_layout
        # Return all room connections but no lock details
        layout = {}
        @game_instance.scenario.scenario_data['rooms'].each do |room_id, room_data|
          layout[room_id] = {
            connections: room_data['connections'],
            locked: room_data['locked'] || false
            # Deliberately exclude lockType and requires
          }
        end
        layout
      end

      def find_object_contents(object_id)
        # Search all rooms for this object
        @game_instance.scenario.scenario_data['rooms'].each do |_room_id, room_data|
          object = room_data['objects']&.find { |obj| obj['id'] == object_id }
          return object['contents'] if object
        end
        []
      end

      def validate_item_accessible(item)
        # Check if item is in an unlocked room/object
        # Simplified: trust client for now, add validation later if needed
        true
      end
    end
  end
end
```

### 6.3 API Rooms Controller

```ruby
# app/controllers/break_escape/api/rooms_controller.rb
module BreakEscape
  module Api
    class RoomsController < ApplicationController
      before_action :set_game_instance
      before_action :set_room

      # GET /api/games/:game_id/rooms/:id
      def show
        authorize @game_instance if defined?(Pundit)

        # Check if room is unlocked
        unless @game_instance.room_unlocked?(params[:id])
          render json: { error: 'Room not unlocked' }, status: :forbidden
          return
        end

        render json: @game_instance.scenario.filtered_room_data(params[:id])
      end

      private

      def set_game_instance
        @game_instance = GameInstance.find(params[:game_id])
      end

      def set_room
        @room_id = params[:id]
      end
    end
  end
end
```

### 6.4 API NPCs Controller

```ruby
# app/controllers/break_escape/api/npcs_controller.rb
module BreakEscape
  module Api
    class NpcsController < ApplicationController
      before_action :set_game_instance
      before_action :set_npc

      # GET /api/games/:game_id/npcs/:id/script
      def script
        authorize @game_instance if defined?(Pundit)

        # Check if player has encountered this NPC
        # (Either in current room OR already encountered)
        unless can_access_npc?
          render json: { error: 'NPC not accessible' }, status: :forbidden
          return
        end

        # Mark as encountered
        @game_instance.encounter_npc!(params[:id]) unless @game_instance.npc_encountered?(params[:id])

        # Load NPC script
        npc_script = @game_instance.scenario.npc_scripts.find_by(npc_id: params[:id])
        unless npc_script
          render json: { error: 'NPC script not found' }, status: :not_found
          return
        end

        # Get NPC data from scenario
        npc_data = @game_instance.scenario.scenario_data['npcs']&.find { |npc| npc['id'] == params[:id] }

        render json: {
          npcId: params[:id],
          inkScript: JSON.parse(npc_script.ink_compiled),
          eventMappings: npc_data&.dig('eventMappings') || [],
          timedMessages: npc_data&.dig('timedMessages') || []
        }
      end

      private

      def set_game_instance
        @game_instance = GameInstance.find(params[:game_id])
      end

      def set_npc
        @npc_id = params[:id]
      end

      def can_access_npc?
        # NPC is accessible if already encountered OR in current room
        return true if @game_instance.npc_encountered?(@npc_id)

        # Check if NPC is in current room
        current_room = @game_instance.player_state['currentRoom']
        room_data = @game_instance.scenario.scenario_data['rooms'][current_room]
        npc_in_room = room_data&.dig('npcs')&.include?(@npc_id)

        npc_in_room || false
      end
    end
  end
end
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add API controllers for game state, rooms, and NPCs"
```

---

## Phase 7: Policies (Week 3)

### 7.1 Generate policies

```bash
# Create policies directory
mkdir -p app/policies/break_escape

# Generate policy files
rails generate pundit:policy break_escape/game_instance
rails generate pundit:policy break_escape/scenario
```

**Edit policies:**

```ruby
# app/policies/break_escape/game_instance_policy.rb
module BreakEscape
  class GameInstancePolicy < ApplicationPolicy
    def show?
      owner_or_admin?
    end

    def update?
      owner_or_admin?
    end

    def destroy?
      owner_or_admin?
    end

    class Scope < Scope
      def resolve
        if user&.admin?
          scope.all
        else
          scope.where(player: user)
        end
      end
    end

    private

    def owner_or_admin?
      record.player == user || user&.admin?
    end
  end
end
```

```ruby
# app/policies/break_escape/scenario_policy.rb
module BreakEscape
  class ScenarioPolicy < ApplicationPolicy
    def index?
      true
    end

    def show?
      record.published? || user&.admin?
    end

    class Scope < Scope
      def resolve
        if user&.admin?
          scope.all
        else
          scope.published
        end
      end
    end
  end
end
```

```ruby
# app/policies/break_escape/application_policy.rb
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
        raise Pundit::NotDefinedError, "Cannot resolve #{@scope.name}"
      end

      private

      attr_reader :user, :scope
    end
  end
end
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add Pundit policies for authorization"
```

---

## Phase 8: Views (Week 4)

### 8.1 Create game view

```erb
<%# app/views/break_escape/games/show.html.erb %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= @scenario.display_name %> - BreakEscape</title>

  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%# Load game stylesheets %>
  <%= stylesheet_link_tag '/break_escape/css/styles.css', nonce: true %>
  <%= stylesheet_link_tag '/break_escape/css/game.css', nonce: true if File.exist?(Rails.root.join('public/break_escape/css/game.css')) %>
</head>
<body>
  <%# Game container %>
  <div id="break-escape-game"></div>

  <%# Bootstrap configuration for client %>
  <script nonce="<%= content_security_policy_nonce %>">
    window.breakEscapeConfig = {
      gameId: <%= @game_instance.id %>,
      scenarioName: '<%= j @scenario.display_name %>',
      apiBasePath: '<%= api_game_path(@game_instance) %>',
      assetsPath: '/break_escape/assets',
      csrfToken: '<%= form_authenticity_token %>'
    };
  </script>

  <%# Load main game JS (ES6 module) %>
  <%= javascript_include_tag '/break_escape/js/main.js', type: 'module', nonce: true %>
</body>
</html>
```

### 8.2 Create scenarios index view

```erb
<%# app/views/break_escape/scenarios/index.html.erb %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Select Scenario - BreakEscape</title>

  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <style nonce="<%= content_security_policy_nonce %>">
    body {
      font-family: 'Courier New', monospace;
      background: #1a1a1a;
      color: #00ff00;
      padding: 20px;
    }
    .scenarios {
      max-width: 800px;
      margin: 0 auto;
    }
    .scenario {
      border: 1px solid #00ff00;
      padding: 20px;
      margin: 20px 0;
      cursor: pointer;
      transition: background 0.2s;
    }
    .scenario:hover {
      background: #002200;
    }
    .scenario h2 {
      margin: 0 0 10px 0;
    }
    .difficulty {
      color: #ffff00;
    }
  </style>
</head>
<body>
  <div class="scenarios">
    <h1>BreakEscape - Select Scenario</h1>

    <% @scenarios.each do |scenario| %>
      <div class="scenario" onclick="window.location='<%= scenario_path(scenario) %>'">
        <h2><%= scenario.display_name %></h2>
        <p><%= scenario.description %></p>
        <p class="difficulty">Difficulty: <%= '★' * scenario.difficulty_level %></p>
      </div>
    <% end %>
  </div>
</body>
</html>
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add views for game and scenario selection"
```

---

## Phase 9: Client Integration (Week 4-5)

### 9.1 Create API client module

Create new files in `public/break_escape/js/`:

```javascript
// public/break_escape/js/config.js
export const CONFIG = {
  API_BASE: window.breakEscapeConfig?.apiBasePath || '',
  ASSETS_PATH: window.breakEscapeConfig?.assetsPath || 'assets',
  GAME_ID: window.breakEscapeConfig?.gameId,
  CSRF_TOKEN: window.breakEscapeConfig?.csrfToken,
  SCENARIO_NAME: window.breakEscapeConfig?.scenarioName || 'BreakEscape'
};
```

```javascript
// public/break_escape/js/core/api-client.js
import { CONFIG } from '../config.js';

class ApiClient {
  constructor() {
    this.baseUrl = CONFIG.API_BASE;
    this.csrfToken = CONFIG.CSRF_TOKEN;
  }

  async get(endpoint) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
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

  async post(endpoint, data) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || `API Error: ${response.status}`);
    }

    return response.json();
  }

  async put(endpoint, data) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return response.json();
  }

  // Game-specific methods
  async bootstrap() {
    return this.get('/bootstrap');
  }

  async loadRoom(roomId) {
    return this.get(`/rooms/${roomId}`);
  }

  async validateUnlock(targetType, targetId, attempt, method) {
    return this.post('/unlock', {
      targetType,
      targetId,
      attempt,
      method
    });
  }

  async updateInventory(action, item) {
    return this.post('/inventory', {
      action,
      item
    });
  }

  async loadNpcScript(npcId) {
    return this.get(`/npcs/${npcId}/script`);
  }

  async syncState(stateUpdates) {
    return this.put('/sync_state', stateUpdates);
  }
}

export const apiClient = new ApiClient();
```

### 9.2 Update game initialization

```javascript
// public/break_escape/js/core/game.js (MODIFY EXISTING)

import { apiClient } from './api-client.js';
import { CONFIG } from '../config.js';

// Add at top of file
let serverGameState = null;

// Modify preload function
export function preload() {
  console.log('Preloading game assets...');

  // Load Tiled maps (unchanged)
  // ... existing code ...

  // NEW: Bootstrap from server instead of loading local JSON
  // (This will be called async, so we need to handle it differently)
}

// Modify create function
export async function create() {
  console.log('Creating game...');

  // NEW: Load game state from server
  try {
    serverGameState = await apiClient.bootstrap();
    console.log('Loaded game state from server:', serverGameState);

    // Set window.gameScenario to maintain compatibility
    window.gameScenario = {
      startRoom: serverGameState.startRoom,
      scenarioName: serverGameState.scenarioName,
      rooms: {} // Will be populated on-demand
    };

    // Initialize player state
    window.playerState = serverGameState.playerState;

  } catch (error) {
    console.error('Failed to load game state:', error);
    // Fallback or show error
    return;
  }

  // ... rest of create function unchanged ...
}

// Add periodic state sync
let lastSyncTime = Date.now();
const SYNC_INTERVAL = 5000; // 5 seconds

export function update(time, delta) {
  // ... existing update code ...

  // Sync state periodically
  if (Date.now() - lastSyncTime > SYNC_INTERVAL) {
    syncStateToServer();
    lastSyncTime = Date.now();
  }
}

async function syncStateToServer() {
  if (!window.player) return;

  try {
    await apiClient.syncState({
      currentRoom: window.currentRoomId,
      position: {
        x: window.player.x,
        y: window.player.y
      },
      globalVariables: window.gameState?.globalVariables || {}
    });
  } catch (error) {
    console.warn('Failed to sync state:', error);
  }
}
```

### 9.3 Update room loading

```javascript
// public/break_escape/js/core/rooms.js (MODIFY EXISTING)

import { apiClient } from './api-client.js';

// Modify loadRoom function to be async
export async function loadRoom(roomId) {
  console.log(`Loading room: ${roomId}`);

  // Check if already loaded
  if (window.rooms && window.rooms[roomId]) {
    console.log(`Room ${roomId} already loaded`);
    return;
  }

  const position = window.roomPositions[roomId];
  if (!position) {
    console.error(`Cannot load room ${roomId}: missing position`);
    return;
  }

  try {
    // NEW: Fetch room data from server
    const roomData = await apiClient.loadRoom(roomId);

    console.log(`Received room data for ${roomId}:`, roomData);

    // Store in window.gameScenario for compatibility
    if (!window.gameScenario.rooms) {
      window.gameScenario.rooms = {};
    }
    window.gameScenario.rooms[roomId] = roomData;

    // Create room (existing function, unchanged)
    createRoom(roomId, roomData, position);
    revealRoom(roomId);

  } catch (error) {
    console.error(`Failed to load room ${roomId}:`, error);

    // Show error to player
    if (window.showNotification) {
      window.showNotification(`Failed to load room: ${error.message}`, 'error');
    }
  }
}
```

### 9.4 Update unlock system

```javascript
// public/break_escape/js/systems/unlock-system.js (MODIFY EXISTING)

import { apiClient } from '../core/api-client.js';

// Modify handleUnlock to validate with server
export async function handleUnlock(lockable, type) {
  console.log('UNLOCK ATTEMPT');
  playUISound('lock');

  // Get user attempt (show UI, run minigame, etc.)
  const attempt = await getUserUnlockAttempt(lockable);
  if (!attempt) return; // User cancelled

  try {
    // NEW: Validate with server
    const result = await apiClient.validateUnlock(
      type, // 'door' or 'object'
      lockable.doorProperties?.connectedRoom || lockable.objectId,
      attempt.value,
      attempt.method // 'key', 'pin', 'password', 'lockpick'
    );

    if (result.success) {
      // Unlock locally
      unlockTarget(lockable, type, lockable.layer);

      // If door, load room
      if (type === 'door' && result.roomData) {
        const roomId = lockable.doorProperties.connectedRoom;
        const position = window.roomPositions[roomId];

        // Store room data
        window.gameScenario.rooms[roomId] = result.roomData;

        // Create room
        createRoom(roomId, result.roomData, position);
        revealRoom(roomId);
      }

      // If container, show contents
      if (type === 'container' && result.contents) {
        showContainerContents(lockable, result.contents);
      }

      window.gameAlert('Unlocked!', 'success', 'Success', 2000);
    } else {
      window.gameAlert(result.message || 'Invalid attempt', 'error', 'Failed', 3000);
    }

  } catch (error) {
    console.error('Unlock validation failed:', error);
    window.gameAlert('Server error. Please try again.', 'error', 'Error', 3000);
  }
}

// Helper to get user attempt (combines existing minigame logic)
async function getUserUnlockAttempt(lockable) {
  const lockRequirements = getLockRequirements(lockable);

  switch(lockRequirements.lockType) {
    case 'key':
      // Show key selection or lockpicking
      return await getKeyOrLockpickAttempt(lockable);

    case 'pin':
      // Show PIN pad
      return await getPinAttempt(lockable);

    case 'password':
      // Show password input
      return await getPasswordAttempt(lockable);

    default:
      return null;
  }
}

// ... implement helper functions using existing minigame code ...
```

### 9.5 Update NPC loading

```javascript
// public/break_escape/js/systems/npc-lazy-loader.js (NEW FILE or MODIFY EXISTING)

import { apiClient } from '../core/api-client.js';

export async function loadNPCScript(npcId) {
  // Check if already loaded
  if (window.npcScripts && window.npcScripts[npcId]) {
    return window.npcScripts[npcId];
  }

  try {
    const npcData = await apiClient.loadNpcScript(npcId);

    // Cache locally
    window.npcScripts = window.npcScripts || {};
    window.npcScripts[npcId] = npcData;

    // Register with NPCManager (if not already registered)
    if (window.npcManager && !window.npcManager.getNPC(npcId)) {
      window.npcManager.registerNPC({
        id: npcId,
        displayName: npcData.displayName || npcId,
        storyJSON: npcData.inkScript,
        eventMappings: npcData.eventMappings,
        timedMessages: npcData.timedMessages,
        // ... other NPC properties
      });
    }

    return npcData;

  } catch (error) {
    console.error(`Failed to load NPC script for ${npcId}:`, error);
    throw error;
  }
}
```

**Commit client changes:**

```bash
git add -A
git commit -m "feat: Integrate client with server API"
```

---

## Phase 10: Standalone Mode (Week 5)

### 10.1 Create DemoUser model

```bash
rails generate model DemoUser handle:string role:string --skip-migration
```

**Create migration manually:**

```bash
rails generate migration CreateBreakEscapeDemoUsers
```

```ruby
# db/migrate/xxx_create_break_escape_demo_users.rb
class CreateBreakEscapeDemoUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_demo_users do |t|
      t.string :handle, null: false
      t.string :role, default: 'user'

      t.timestamps
    end

    add_index :break_escape_demo_users, :handle, unique: true
  end
end
```

```ruby
# app/models/break_escape/demo_user.rb
module BreakEscape
  class DemoUser < ApplicationRecord
    self.table_name = 'break_escape_demo_users'

    has_many :game_instances, as: :player, class_name: 'BreakEscape::GameInstance'

    validates :handle, presence: true, uniqueness: true
    validates :role, inclusion: { in: %w[admin pro user] }

    def admin?
      role == 'admin'
    end

    def pro?
      role == 'pro'
    end
  end
end
```

**Run migration:**

```bash
rails db:migrate
```

### 10.2 Create standalone config

```yaml
# config/break_escape_standalone.yml
development:
  standalone_mode: true
  demo_user:
    handle: "demo_player"
    role: "pro"
  scenarios:
    enabled: ['ceo_exfil', 'cybok_heist', 'biometric_breach']

test:
  standalone_mode: true
  demo_user:
    handle: "test_player"
    role: "user"

production:
  standalone_mode: false  # Mounted in Hacktivity
```

### 10.3 Update initializer

```ruby
# config/initializers/break_escape.rb
module BreakEscape
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  class Configuration
    attr_accessor :standalone_mode, :demo_user, :user_class

    def initialize
      load_config
    end

    def load_config
      config_path = Rails.root.join('config/break_escape_standalone.yml')
      return unless File.exist?(config_path)

      config = YAML.load_file(config_path)[Rails.env] || {}

      @standalone_mode = config['standalone_mode'] || false
      @demo_user = config['demo_user'] || {}
      @user_class = @standalone_mode ? 'BreakEscape::DemoUser' : 'User'
    end
  end
end

# Initialize
BreakEscape.configure
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add standalone mode with DemoUser"
```

---

## Phase 11: Testing (Week 6)

### 11.1 Create fixtures

```yaml
# test/fixtures/break_escape/scenarios.yml
ceo_exfil:
  name: ceo_exfil
  display_name: CEO Exfiltration
  description: Break into the CEO's office
  published: true
  difficulty_level: 3
  scenario_data: <%= File.read(Rails.root.join('test/fixtures/files/ceo_exfil_scenario.json')) %>

cybok_heist:
  name: cybok_heist
  display_name: CyBOK Heist
  description: Educational cybersecurity scenario
  published: true
  difficulty_level: 2
  scenario_data: <%= File.read(Rails.root.join('test/fixtures/files/cybok_heist_scenario.json')) %>
```

```yaml
# test/fixtures/break_escape/demo_users.yml
demo_player:
  handle: demo_player
  role: pro

test_player:
  handle: test_player
  role: user

admin_player:
  handle: admin_player
  role: admin
```

```yaml
# test/fixtures/break_escape/game_instances.yml
demo_game:
  player: demo_player (DemoUser)
  scenario: ceo_exfil
  status: in_progress
  player_state:
    currentRoom: room_reception
    unlockedRooms: [room_reception]
    inventory: []
    globalVariables: {}
```

### 11.2 Integration tests

```ruby
# test/integration/break_escape/game_flow_test.rb
require 'test_helper'

module BreakEscape
  class GameFlowTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @scenario = break_escape_scenarios(:ceo_exfil)
      @demo_user = break_escape_demo_users(:demo_player)
    end

    test "can start new game" do
      get scenario_path(@scenario)
      assert_response :success

      # Should create game instance
      game = GameInstance.find_by(player: @demo_user, scenario: @scenario)
      assert_not_nil game
    end

    test "can load game view" do
      game = GameInstance.create!(
        player: @demo_user,
        scenario: @scenario
      )

      get game_path(game)
      assert_response :success
      assert_select 'div#break-escape-game'
    end

    test "can bootstrap game via API" do
      game = GameInstance.create!(
        player: @demo_user,
        scenario: @scenario
      )

      get bootstrap_api_game_path(game)
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal game.id, json['gameId']
      assert_equal @scenario.start_room, json['startRoom']
    end

    test "can validate unlock" do
      game = GameInstance.create!(
        player: @demo_user,
        scenario: @scenario
      )

      # Attempt unlock (this will depend on scenario data)
      post unlock_api_game_path(game), params: {
        targetType: 'door',
        targetId: 'room_office',
        method: 'password',
        attempt: 'correct_password' # Match scenario
      }

      assert_response :success
      json = JSON.parse(response.body)
      assert json['success']
    end
  end
end
```

```ruby
# test/models/break_escape/game_instance_test.rb
require 'test_helper'

module BreakEscape
  class GameInstanceTest < ActiveSupport::TestCase
    test "initializes with start room unlocked" do
      scenario = break_escape_scenarios(:ceo_exfil)
      game = GameInstance.create!(
        player: break_escape_demo_users(:demo_player),
        scenario: scenario
      )

      assert game.room_unlocked?(scenario.start_room)
    end

    test "can unlock additional rooms" do
      game = break_escape_game_instances(:demo_game)

      game.unlock_room!('room_office')

      assert game.room_unlocked?('room_office')
      assert_includes game.player_state['unlockedRooms'], 'room_office'
    end

    test "can manage inventory" do
      game = break_escape_game_instances(:demo_game)

      item = { 'type' => 'key', 'name' => 'Office Key', 'key_id' => 'office_1' }
      game.add_inventory_item!(item)

      assert_equal 1, game.player_state['inventory'].length
      assert_equal 'Office Key', game.player_state['inventory'].first['name']
    end
  end
end
```

**Run tests:**

```bash
rails test
```

**Commit:**

```bash
git add -A
git commit -m "test: Add integration and model tests"
```

---

## Phase 12: Deployment & Documentation (Week 6)

### 12.1 Create README

```markdown
# BreakEscape Rails Engine

Educational escape room cybersecurity training game as a Rails Engine.

## Installation

Add to Gemfile:

\`\`\`ruby
gem 'break_escape', path: 'path/to/break_escape'
\`\`\`

Mount in routes:

\`\`\`ruby
mount BreakEscape::Engine => "/break_escape"
\`\`\`

Run migrations:

\`\`\`bash
rails break_escape:install:migrations
rails db:migrate
\`\`\`

Import scenarios:

\`\`\`bash
rails db:seed
\`\`\`

## Standalone Mode

Configure in `config/break_escape_standalone.yml`:

\`\`\`yaml
development:
  standalone_mode: true
  demo_user:
    handle: "demo_player"
    role: "pro"
\`\`\`

## Testing

\`\`\`bash
rails test
\`\`\`

## License

MIT
```

### 12.2 Final verification checklist

```bash
# Verify structure
ls -la app/
ls -la lib/
ls -la public/break_escape/
ls -la app/assets/scenarios/

# Verify database
rails db:migrate:status

# Verify seeds
rails console
> BreakEscape::Scenario.count
> BreakEscape::NpcScript.count

# Run tests
rails test

# Start server
rails server

# Visit http://localhost:3000/break_escape
```

**Final commit:**

```bash
git add -A
git commit -m "docs: Add README and final documentation"
```

---

## Summary

**All phases complete!**

You now have a fully functional Rails Engine that:
- ✅ Runs standalone or mounts in Hacktivity
- ✅ Uses JSON storage for game state
- ✅ Validates unlocks server-side
- ✅ Loads NPCs on-demand
- ✅ Minimal client-side changes
- ✅ Well-tested with fixtures
- ✅ Pundit authorization
- ✅ Session-based auth

**Next steps:** Mount in Hacktivity and test integration!
