# BreakEscape Rails Engine - Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Hacktivity (Host App)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              BreakEscape Rails Engine                 │  │
│  │                                                         │  │
│  │  ┌──────────────┐    ┌────────────────────────────┐  │  │
│  │  │ Controllers  │───▶│  Models (3 tables)         │  │  │
│  │  │  - Games     │    │  - GameInstance (JSONB)    │  │  │
│  │  │  - API       │    │  - Scenario (JSONB)        │  │  │
│  │  │  - Scenarios │    │  - NpcScript (TEXT)        │  │  │
│  │  └──────────────┘    └────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌──────────────┐    ┌────────────────────────────┐  │  │
│  │  │ Views        │    │  Policies (Pundit)         │  │  │
│  │  │  - show.html │    │  - GameInstancePolicy      │  │  │
│  │  └──────────────┘    └────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           public/break_escape/                  │  │  │
│  │  │  - js/      (ES6 modules, unchanged)            │  │  │
│  │  │  - css/     (stylesheets, unchanged)            │  │  │
│  │  │  - assets/  (images/sounds, unchanged)          │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │   Devise User Authentication (Hacktivity)           │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

### Final Structure (After Migration)

```
/home/user/BreakEscape/
├── app/
│   ├── controllers/
│   │   └── break_escape/
│   │       ├── application_controller.rb
│   │       ├── games_controller.rb              # Main game view
│   │       └── api/
│   │           ├── games_controller.rb          # Game state API
│   │           ├── rooms_controller.rb          # Room loading
│   │           ├── unlocks_controller.rb        # Unlock validation
│   │           ├── inventory_controller.rb      # Inventory sync
│   │           └── npcs_controller.rb           # NPC script loading
│   │
│   ├── models/
│   │   └── break_escape/
│   │       ├── application_record.rb
│   │       ├── game_instance.rb                 # JSONB player state
│   │       ├── scenario.rb                      # JSONB scenario data
│   │       └── npc_script.rb                    # Ink scripts
│   │
│   ├── policies/
│   │   └── break_escape/
│   │       ├── game_instance_policy.rb
│   │       └── scenario_policy.rb
│   │
│   ├── views/
│   │   └── break_escape/
│   │       └── games/
│   │           └── show.html.erb                # Game container
│   │
│   ├── assets/
│   │   └── scenarios/                           # ERB templates
│   │       ├── common/
│   │       │   └── ink/
│   │       │       └── shared_dialogue.ink.json
│   │       │
│   │       ├── ceo_exfil/
│   │       │   ├── scenario.json.erb
│   │       │   └── ink/
│   │       │       ├── security_guard.ink
│   │       │       └── security_guard.ink.json
│   │       │
│   │       ├── cybok_heist/
│   │       │   ├── scenario.json.erb
│   │       │   └── ink/
│   │       │
│   │       └── biometric_breach/
│   │           ├── scenario.json.erb
│   │           └── ink/
│   │
│   └── helpers/
│       └── break_escape/
│           └── application_helper.rb
│
├── lib/
│   ├── break_escape/
│   │   ├── engine.rb                            # Engine config
│   │   ├── version.rb
│   │   └── scenario_loader.rb                   # ERB processor
│   │
│   └── break_escape.rb
│
├── config/
│   ├── routes.rb                                # Engine routes
│   ├── initializers/
│   │   └── break_escape.rb                      # Config
│   └── break_escape_standalone.yml              # Standalone config
│
├── db/
│   ├── migrate/
│   │   ├── 001_create_break_escape_scenarios.rb
│   │   ├── 002_create_break_escape_npc_scripts.rb
│   │   └── 003_create_break_escape_game_instances.rb
│   └── seeds.rb                                 # Import scenarios
│
├── test/
│   ├── fixtures/
│   │   └── break_escape/
│   │       ├── scenarios.yml
│   │       ├── npc_scripts.yml
│   │       └── game_instances.yml
│   │
│   ├── models/
│   │   └── break_escape/
│   │
│   ├── controllers/
│   │   └── break_escape/
│   │
│   ├── integration/
│   │   └── break_escape/
│   │       ├── game_flow_test.rb
│   │       └── api_test.rb
│   │
│   └── policies/
│       └── break_escape/
│
├── public/                                      # Static assets
│   └── break_escape/
│       ├── js/                                  # mv js/ here
│       ├── css/                                 # mv css/ here
│       └── assets/                              # mv assets/ here
│
├── break_escape.gemspec
├── Gemfile
├── Rakefile
└── README.md
```

## Database Schema

### 1. Scenarios Table

Stores scenario metadata and complete JSON data.

```ruby
create_table :break_escape_scenarios do |t|
  t.string :name, null: false              # 'ceo_exfil'
  t.string :display_name, null: false      # 'CEO Exfiltration'
  t.text :description
  t.jsonb :scenario_data, null: false      # Complete scenario with solutions
  t.boolean :published, default: false
  t.integer :difficulty_level, default: 1  # 1-5
  t.timestamps

  t.index :name, unique: true
  t.index :published
  t.index :scenario_data, using: :gin
end
```

**scenario_data structure:**
```json
{
  "startRoom": "room_reception",
  "scenarioName": "CEO Exfiltration",
  "scenarioBrief": "...",
  "rooms": {
    "room_reception": {
      "type": "reception",
      "connections": {"north": "room_office"},
      "locked": false,
      "objects": [...]
    },
    "room_office": {
      "type": "office",
      "connections": {"south": "room_reception"},
      "locked": true,
      "lockType": "password",
      "requires": "admin123",  // Server only
      "objects": [...]
    }
  },
  "npcs": [
    {
      "id": "security_guard",
      "displayName": "Security Guard",
      "phoneId": "player_phone",
      "npcType": "phone",
      "canUnlock": ["room_server"]
    }
  ]
}
```

### 2. NPC Scripts Table

Stores Ink dialogue scripts.

```ruby
create_table :break_escape_npc_scripts do |t|
  t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }
  t.string :npc_id, null: false            # 'security_guard'
  t.text :ink_source                       # .ink source (optional)
  t.text :ink_compiled, null: false        # .ink.json compiled
  t.timestamps

  t.index [:scenario_id, :npc_id], unique: true
end
```

### 3. Game Instances Table

Stores player game state (polymorphic player).

```ruby
create_table :break_escape_game_instances do |t|
  # Polymorphic player (User in Hacktivity, DemoUser in standalone)
  t.references :player, polymorphic: true, null: false

  # Scenario reference
  t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }

  # Player state (JSONB - this is the key simplification!)
  t.jsonb :player_state, null: false, default: {
    currentRoom: 'room_reception',
    position: { x: 0, y: 0 },
    unlockedRooms: [],
    unlockedObjects: [],
    inventory: [],
    encounteredNPCs: [],
    globalVariables: {}
  }

  # Game metadata
  t.string :status, default: 'in_progress'  # in_progress, completed, abandoned
  t.datetime :started_at
  t.datetime :completed_at
  t.integer :score, default: 0
  t.integer :health, default: 100

  t.timestamps

  t.index [:player_type, :player_id, :scenario_id], unique: true, name: 'index_game_instances_on_player_and_scenario'
  t.index :player_state, using: :gin
  t.index :status
end
```

**player_state example:**
```json
{
  "currentRoom": "room_office",
  "position": {"x": 150, "y": 200},
  "unlockedRooms": ["room_reception", "room_office"],
  "unlockedObjects": ["desk_drawer_123"],
  "inventory": [
    {
      "type": "key",
      "name": "Office Key",
      "key_id": "office_key_1",
      "takeable": true
    }
  ],
  "encounteredNPCs": ["security_guard"],
  "globalVariables": {
    "alarm_triggered": false,
    "player_favor": 5,
    "security_alerted": false
  }
}
```

## Models

### GameInstance Model

```ruby
module BreakEscape
  class GameInstance < ApplicationRecord
    # Polymorphic association
    belongs_to :player, polymorphic: true
    belongs_to :scenario

    # Validations
    validates :player, presence: true
    validates :scenario, presence: true
    validates :status, inclusion: { in: %w[in_progress completed abandoned] }

    # Scopes
    scope :active, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }

    # State management
    def unlock_room!(room_id)
      player_state['unlockedRooms'] ||= []
      player_state['unlockedRooms'] << room_id unless player_state['unlockedRooms'].include?(room_id)
      save!
    end

    def unlock_object!(object_id)
      player_state['unlockedObjects'] ||= []
      player_state['unlockedObjects'] << object_id unless player_state['unlockedObjects'].include?(object_id)
      save!
    end

    def add_inventory_item!(item)
      player_state['inventory'] ||= []
      player_state['inventory'] << item
      save!
    end

    def room_unlocked?(room_id)
      player_state['unlockedRooms']&.include?(room_id) || scenario.start_room?(room_id)
    end

    def object_unlocked?(object_id)
      player_state['unlockedObjects']&.include?(object_id)
    end

    def npc_encountered?(npc_id)
      player_state['encounteredNPCs']&.include?(npc_id)
    end

    def encounter_npc!(npc_id)
      player_state['encounteredNPCs'] ||= []
      player_state['encounteredNPCs'] << npc_id unless player_state['encounteredNPCs'].include?(npc_id)
      save!
    end
  end
end
```

### Scenario Model

```ruby
module BreakEscape
  class Scenario < ApplicationRecord
    has_many :game_instances
    has_many :npc_scripts

    validates :name, presence: true, uniqueness: true
    validates :scenario_data, presence: true

    scope :published, -> { where(published: true) }

    def start_room?(room_id)
      scenario_data['startRoom'] == room_id
    end

    def room_data(room_id)
      scenario_data.dig('rooms', room_id)
    end

    def filtered_room_data(room_id)
      room = room_data(room_id)&.dup
      return nil unless room

      # Remove solutions
      room.delete('requires')
      room.delete('lockType') if room['locked']

      # Remove solutions from objects
      room['objects']&.each do |obj|
        obj.delete('requires')
        obj.delete('contents') if obj['locked']
      end

      room
    end

    def validate_unlock(target_type, target_id, attempt, method)
      if target_type == 'door'
        room = room_data(target_id)
        return false unless room

        case method
        when 'key'
          room['requires'] == attempt
        when 'pin', 'password'
          room['requires'] == attempt
        when 'lockpick'
          true # Client minigame succeeded
        else
          false
        end
      else
        # Find object in all rooms
        # Implementation details...
      end
    end
  end
end
```

### NpcScript Model

```ruby
module BreakEscape
  class NpcScript < ApplicationRecord
    belongs_to :scenario

    validates :npc_id, presence: true
    validates :ink_compiled, presence: true
    validates :npc_id, uniqueness: { scope: :scenario_id }
  end
end
```

## Routes

```ruby
# config/routes.rb
BreakEscape::Engine.routes.draw do
  # Main game view
  resources :games, only: [:show] do
    member do
      get :play  # Alias for show
    end
  end

  # Scenario selection
  resources :scenarios, only: [:index, :show]

  # API endpoints
  namespace :api do
    resources :games, only: [] do
      member do
        get :bootstrap         # Initial game data
        put :sync_state        # Periodic state sync
      end

      # Nested resources
      resources :rooms, only: [:show]
      resources :npcs, only: [] do
        member do
          get :script          # Load Ink script
        end
      end

      # Actions
      post :unlock             # Validate unlock attempt
      post :inventory          # Update inventory
    end
  end

  # Root
  root to: 'scenarios#index'
end
```

## API Endpoints

### 1. Bootstrap Game

```
GET /api/games/:id/bootstrap

Response:
{
  "gameId": 123,
  "scenarioName": "CEO Exfiltration",
  "startRoom": "room_reception",
  "playerState": {
    "currentRoom": "room_reception",
    "unlockedRooms": ["room_reception"],
    "inventory": [],
    ...
  },
  "roomLayout": {
    "room_reception": {
      "connections": {"north": "room_office"},
      "locked": false
    },
    "room_office": {
      "connections": {"south": "room_reception"},
      "locked": true  // No lockType or requires!
    }
  }
}
```

### 2. Load Room

```
GET /api/games/:game_id/rooms/:room_id

Authorization: Session (current_user)

Response (if authorized):
{
  "roomId": "room_office",
  "type": "office",
  "connections": {...},
  "objects": [
    {
      "type": "desk",
      "name": "Manager's Desk",
      "locked": true,  // But no requires!
      "observations": "..."
    }
  ]
}

Response (if unauthorized):
403 Forbidden
```

### 3. Validate Unlock

```
POST /api/games/:game_id/unlock

Body:
{
  "targetType": "door",  // or "object"
  "targetId": "room_ceo",
  "method": "password",
  "attempt": "admin123"
}

Response (success):
{
  "success": true,
  "type": "door",
  "roomData": { ... }  // Filtered room data
}

Response (failure):
{
  "success": false,
  "message": "Invalid password"
}
```

### 4. Update Inventory

```
POST /api/games/:game_id/inventory

Body:
{
  "action": "add",  // or "remove"
  "item": {
    "type": "key",
    "name": "Office Key",
    "key_id": "office_key_1"
  }
}

Response:
{
  "success": true,
  "inventory": [...]
}
```

### 5. Load NPC Script

```
GET /api/games/:game_id/npcs/:npc_id/script

Response:
{
  "npcId": "security_guard",
  "inkScript": { ... },  // Full Ink JSON
  "eventMappings": [...],
  "timedMessages": [...]
}
```

### 6. Sync State

```
PUT /api/games/:game_id/sync_state

Body:
{
  "currentRoom": "room_office",
  "position": {"x": 150, "y": 220},
  "globalVariables": {"alarm_triggered": false}
}

Response:
{
  "success": true
}
```

## Policies (Pundit)

### GameInstancePolicy

```ruby
module BreakEscape
  class GameInstancePolicy < ApplicationPolicy
    def show?
      # Owner or admin
      record.player == user || user&.admin?
    end

    def update?
      show?
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
  end
end
```

### ScenarioPolicy

```ruby
module BreakEscape
  class ScenarioPolicy < ApplicationPolicy
    def index?
      true  # Everyone can see scenarios
    end

    def show?
      # Only published or admin
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

## Configuration

### Engine Configuration

```ruby
# lib/break_escape/engine.rb
module BreakEscape
  class Engine < ::Rails::Engine
    isolate_namespace BreakEscape

    config.generators do |g|
      g.test_framework :test_unit, fixture: true
      g.fixture_replacement :factory_bot, dir: 'test/factories'
      g.assets false
      g.helper false
    end

    # Pundit authorization
    config.after_initialize do
      BreakEscape::ApplicationController.include Pundit::Authorization
    end
  end
end
```

### Standalone Configuration

```yaml
# config/break_escape_standalone.yml
development:
  standalone_mode: true
  demo_user:
    handle: "demo_player"
    role: "pro"  # admin, pro, user
  scenarios:
    enabled: ['ceo_exfil', 'cybok_heist']

production:
  standalone_mode: false  # Mounted in Hacktivity
```

### Initializer

```ruby
# config/initializers/break_escape.rb
module BreakEscape
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :standalone_mode, :demo_user, :user_class

    def initialize
      standalone_config = load_standalone_config

      @standalone_mode = standalone_config['standalone_mode']
      @demo_user = standalone_config['demo_user']
      @user_class = @standalone_mode ? 'BreakEscape::DemoUser' : 'User'
    end

    private

    def load_standalone_config
      config_path = Rails.root.join('config/break_escape_standalone.yml')
      return {} unless File.exist?(config_path)

      YAML.load_file(config_path)[Rails.env] || {}
    end
  end
end

BreakEscape.configure do |config|
  # Config loaded from YAML
end
```

## Client Integration

### Game View (Rails)

```erb
<%# app/views/break_escape/games/show.html.erb %>
<!DOCTYPE html>
<html>
<head>
  <title><%= @scenario.display_name %> - BreakEscape</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%= stylesheet_link_tag '/break_escape/css/styles.css', nonce: true %>
</head>
<body>
  <div id="break-escape-game"></div>

  <%# Bootstrap config for client %>
  <script nonce="<%= content_security_policy_nonce %>">
    window.breakEscapeConfig = {
      gameId: <%= @game_instance.id %>,
      apiBasePath: '<%= api_game_path(@game_instance) %>',
      assetsPath: '/break_escape/assets',
      csrfToken: '<%= form_authenticity_token %>'
    };
  </script>

  <%# Load game (ES6 module) %>
  <%= javascript_include_tag '/break_escape/js/main.js', type: 'module', nonce: true %>
</body>
</html>
```

### Client-Side Changes (Minimal)

```javascript
// public/break_escape/js/config.js (NEW FILE)
export const API_BASE = window.breakEscapeConfig?.apiBasePath || '';
export const ASSETS_PATH = window.breakEscapeConfig?.assetsPath || 'assets';
export const GAME_ID = window.breakEscapeConfig?.gameId;
export const CSRF_TOKEN = window.breakEscapeConfig?.csrfToken;

// public/break_escape/js/core/api-client.js (NEW FILE)
import { API_BASE, CSRF_TOKEN } from '../config.js';

export async function apiGet(endpoint) {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    credentials: 'same-origin',
    headers: {
      'Accept': 'application/json'
    }
  });

  if (!response.ok) throw new Error(`API Error: ${response.status}`);
  return response.json();
}

export async function apiPost(endpoint, data) {
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

  if (!response.ok) throw new Error(`API Error: ${response.status}`);
  return response.json();
}
```

Changes to existing files are minimal - mostly importing and using API client instead of loading local JSON.

## Next Steps

See **02_IMPLEMENTATION_PLAN.md** for detailed step-by-step instructions.
