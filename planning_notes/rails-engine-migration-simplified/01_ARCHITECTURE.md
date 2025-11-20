# BreakEscape Rails Engine - Technical Architecture

**Complete technical design specification**

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Hacktivity (Host App)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              BreakEscape Rails Engine                 │  │
│  │                                                         │  │
│  │  ┌──────────────┐    ┌────────────────────────────┐  │  │
│  │  │ Controllers  │───▶│  Models (2 tables)         │  │  │
│  │  │  - Games     │    │  - Mission (metadata)      │  │  │
│  │  │  - Missions  │    │  - Game (state + data)     │  │  │
│  │  │  - API       │    │                            │  │  │
│  │  └──────────────┘    └────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌──────────────┐    ┌────────────────────────────┐  │  │
│  │  │ Views        │    │  Policies (Pundit)         │  │  │
│  │  │  - show.html │    │  - GamePolicy              │  │  │
│  │  └──────────────┘    └────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           public/break_escape/                  │  │  │
│  │  │  - js/      (game code, unchanged)              │  │  │
│  │  │  - css/     (stylesheets, unchanged)            │  │  │
│  │  │  - assets/  (images/sounds, unchanged)          │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         app/assets/scenarios/                   │  │  │
│  │  │  - ceo_exfil/scenario.json.erb (ERB template)   │  │  │
│  │  │  - cybok_heist/scenario.json.erb                │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         scenarios/ink/                          │  │  │
│  │  │  - helper-npc.ink (source)                      │  │  │
│  │  │  - helper-npc.json (JIT compiled)               │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │   Devise User Authentication (Hacktivity)           │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

### Final Structure (After Migration)

```
/home/user/BreakEscape/
├── app/
│   ├── controllers/
│   │   └── break_escape/
│   │       ├── application_controller.rb
│   │       ├── games_controller.rb           # Game view + scenario/ink endpoints
│   │       ├── missions_controller.rb         # Scenario selection
│   │       └── api/
│   │           └── games_controller.rb        # Game state API
│   │
│   ├── models/
│   │   └── break_escape/
│   │       ├── application_record.rb
│   │       ├── mission.rb                     # Scenario metadata + ERB generation
│   │       ├── game.rb                        # Game state + validation
│   │       └── demo_user.rb                   # Standalone mode only
│   │
│   ├── policies/
│   │   └── break_escape/
│   │       ├── game_policy.rb
│   │       └── mission_policy.rb
│   │
│   ├── views/
│   │   └── break_escape/
│   │       ├── games/
│   │       │   └── show.html.erb              # Game container
│   │       └── missions/
│   │           └── index.html.erb             # Scenario list
│   │
│   └── assets/
│       └── scenarios/                         # ERB templates
│           ├── ceo_exfil/
│           │   └── scenario.json.erb
│           ├── cybok_heist/
│           │   └── scenario.json.erb
│           └── biometric_breach/
│               └── scenario.json.erb
│
├── lib/
│   ├── break_escape/
│   │   ├── engine.rb                          # Engine configuration
│   │   └── version.rb
│   └── break_escape.rb
│
├── config/
│   ├── routes.rb                              # Engine routes
│   └── initializers/
│       └── break_escape.rb                    # Config loader
│
├── db/
│   └── migrate/
│       ├── 001_create_break_escape_missions.rb
│       └── 002_create_break_escape_games.rb
│
├── test/
│   ├── fixtures/
│   │   └── break_escape/
│   │       ├── missions.yml
│   │       └── games.yml
│   ├── models/
│   │   └── break_escape/
│   ├── controllers/
│   │   └── break_escape/
│   ├── integration/
│   │   └── break_escape/
│   └── policies/
│       └── break_escape/
│
├── public/                                    # Static game assets
│   └── break_escape/
│       ├── js/                                # ES6 modules (moved from root)
│       ├── css/                               # Stylesheets (moved from root)
│       └── assets/                            # Images/sounds (moved from root)
│
├── scenarios/                                 # Ink scripts
│   └── ink/
│       ├── helper-npc.ink                     # Source
│       └── helper-npc.json                    # JIT compiled
│
├── bin/
│   └── inklecate                              # Ink compiler binary
│
├── break_escape.gemspec
├── Gemfile
├── Rakefile
└── README.md
```

---

## Database Schema

### Table 1: break_escape_missions

Stores scenario metadata only (no game data).

```ruby
create_table :break_escape_missions do |t|
  t.string :name, null: false              # 'ceo_exfil' (directory name)
  t.string :display_name, null: false      # 'CEO Exfiltration'
  t.text :description                      # Scenario brief
  t.boolean :published, default: false     # Visible to players
  t.integer :difficulty_level, default: 1  # 1-5 scale

  t.timestamps
end

add_index :break_escape_missions, :name, unique: true
add_index :break_escape_missions, :published
```

**What it stores:** Metadata about scenarios
**What it does NOT store:** Scenario JSON, NPC data, room definitions

**Example Record:**
```ruby
{
  id: 1,
  name: 'ceo_exfil',
  display_name: 'CEO Exfiltration',
  description: 'Infiltrate the office and find evidence...',
  published: true,
  difficulty_level: 3
}
```

---

### Table 2: break_escape_games

Stores player game state with scenario snapshot.

```ruby
create_table :break_escape_games do |t|
  # Polymorphic player (User in Hacktivity, DemoUser in standalone)
  t.references :player, polymorphic: true, null: false, index: true

  # Mission reference
  t.references :mission, null: false, foreign_key: { to_table: :break_escape_missions }

  # Scenario snapshot (ERB-generated at game creation)
  t.jsonb :scenario_data, null: false

  # Player state (all game progress)
  t.jsonb :player_state, null: false, default: {
    currentRoom: nil,
    unlockedRooms: [],
    unlockedObjects: [],
    inventory: [],
    encounteredNPCs: [],
    globalVariables: {},
    biometricSamples: [],
    biometricUnlocks: [],
    bluetoothDevices: [],
    notes: [],
    health: 100
  }

  # Metadata
  t.string :status, default: 'in_progress'  # in_progress, completed, abandoned
  t.datetime :started_at
  t.datetime :completed_at
  t.integer :score, default: 0

  t.timestamps
end

add_index :break_escape_games,
          [:player_type, :player_id, :mission_id],
          unique: true,
          name: 'index_games_on_player_and_mission'
add_index :break_escape_games, :scenario_data, using: :gin
add_index :break_escape_games, :player_state, using: :gin
add_index :break_escape_games, :status
```

**Key Points:**
- `scenario_data` stores the ERB-generated scenario JSON (unique per game)
- `player_state` stores all game progress in one JSONB column
- `health` is inside player_state (not separate column)
- No `position` field (not needed for now)

**Example Record:**
```ruby
{
  id: 123,
  player_type: 'User',
  player_id: 456,
  mission_id: 1,
  scenario_data: {
    startRoom: 'reception',
    rooms: {
      reception: { ... },
      office: { locked: true, requires: 'xK92pL7q' }  # Unique password
    }
  },
  player_state: {
    currentRoom: 'reception',
    unlockedRooms: ['reception'],
    inventory: [],
    health: 100
  },
  status: 'in_progress',
  started_at: '2025-11-20T10:00:00Z'
}
```

---

## Models

### Mission Model

```ruby
# app/models/break_escape/mission.rb
module BreakEscape
  class Mission < ApplicationRecord
    self.table_name = 'break_escape_missions'

    has_many :games, class_name: 'BreakEscape::Game', dependent: :destroy

    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true

    scope :published, -> { where(published: true) }

    # Path to scenario directory
    def scenario_path
      Rails.root.join('app', 'assets', 'scenarios', name)
    end

    # Generate scenario data via ERB
    def generate_scenario_data
      template_path = scenario_path.join('scenario.json.erb')
      raise "Scenario template not found: #{name}" unless File.exist?(template_path)

      erb = ERB.new(File.read(template_path))
      binding_context = ScenarioBinding.new
      output = erb.result(binding_context.get_binding)

      JSON.parse(output)
    rescue JSON::ParserError => e
      raise "Invalid JSON in #{name} after ERB processing: #{e.message}"
    end

    # Binding context for ERB variables
    class ScenarioBinding
      def initialize
        @random_password = SecureRandom.alphanumeric(8)
        @random_pin = rand(1000..9999).to_s
        @random_code = SecureRandom.hex(4)
      end

      attr_reader :random_password, :random_pin, :random_code

      def get_binding
        binding
      end
    end
  end
end
```

---

### Game Model

```ruby
# app/models/break_escape/game.rb
module BreakEscape
  class Game < ApplicationRecord
    self.table_name = 'break_escape_games'

    # Associations
    belongs_to :player, polymorphic: true
    belongs_to :mission, class_name: 'BreakEscape::Mission'

    # Validations
    validates :player, presence: true
    validates :mission, presence: true
    validates :status, inclusion: { in: %w[in_progress completed abandoned] }

    # Scopes
    scope :active, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }

    # Callbacks
    before_create :generate_scenario_data
    before_create :initialize_player_state
    before_create :set_started_at

    # Room management
    def unlock_room!(room_id)
      player_state['unlockedRooms'] ||= []
      player_state['unlockedRooms'] << room_id unless player_state['unlockedRooms'].include?(room_id)
      save!
    end

    def room_unlocked?(room_id)
      player_state['unlockedRooms']&.include?(room_id) || start_room?(room_id)
    end

    def start_room?(room_id)
      scenario_data['startRoom'] == room_id
    end

    # Object management
    def unlock_object!(object_id)
      player_state['unlockedObjects'] ||= []
      player_state['unlockedObjects'] << object_id unless player_state['unlockedObjects'].include?(object_id)
      save!
    end

    def object_unlocked?(object_id)
      player_state['unlockedObjects']&.include?(object_id)
    end

    # Inventory management
    def add_inventory_item!(item)
      player_state['inventory'] ||= []
      player_state['inventory'] << item
      save!
    end

    def remove_inventory_item!(item_id)
      player_state['inventory']&.reject! { |item| item['id'] == item_id }
      save!
    end

    # NPC tracking
    def encounter_npc!(npc_id)
      player_state['encounteredNPCs'] ||= []
      player_state['encounteredNPCs'] << npc_id unless player_state['encounteredNPCs'].include?(npc_id)
      save!
    end

    # Global variables (synced with client)
    def update_global_variables!(variables)
      player_state['globalVariables'] ||= {}
      player_state['globalVariables'].merge!(variables)
      save!
    end

    # Minigame state
    def add_biometric_sample!(sample)
      player_state['biometricSamples'] ||= []
      player_state['biometricSamples'] << sample
      save!
    end

    def add_bluetooth_device!(device)
      player_state['bluetoothDevices'] ||= []
      unless player_state['bluetoothDevices'].any? { |d| d['mac'] == device['mac'] }
        player_state['bluetoothDevices'] << device
      end
      save!
    end

    def add_note!(note)
      player_state['notes'] ||= []
      player_state['notes'] << note
      save!
    end

    # Health management
    def update_health!(value)
      player_state['health'] = value.clamp(0, 100)
      save!
    end

    # Scenario data access
    def room_data(room_id)
      scenario_data.dig('rooms', room_id)
    end

    def filtered_room_data(room_id)
      room = room_data(room_id)&.deep_dup
      return nil unless room

      # Remove solutions
      room.delete('requires')
      room.delete('lockType') if room['locked']

      # Remove solutions from objects
      room['objects']&.each do |obj|
        obj.delete('requires')
        obj.delete('lockType') if obj['locked']
        obj.delete('contents') if obj['locked']
      end

      room
    end

    # Unlock validation
    def validate_unlock(target_type, target_id, attempt, method)
      if target_type == 'door'
        room = room_data(target_id)
        return false unless room && room['locked']

        case method
        when 'key'
          room['requires'] == attempt
        when 'pin', 'password'
          room['requires'].to_s == attempt.to_s
        when 'lockpick'
          true # Client minigame succeeded
        else
          false
        end
      else
        # Find object in all rooms
        scenario_data['rooms'].each do |_room_id, room_data|
          object = room_data['objects']&.find { |obj| obj['id'] == target_id }
          next unless object && object['locked']

          case method
          when 'key'
            return object['requires'] == attempt
          when 'pin', 'password'
            return object['requires'].to_s == attempt.to_s
          when 'lockpick'
            return true
          end
        end
        false
      end
    end

    private

    def generate_scenario_data
      self.scenario_data = mission.generate_scenario_data
    end

    def initialize_player_state
      self.player_state ||= {}
      self.player_state['currentRoom'] ||= scenario_data['startRoom']
      self.player_state['unlockedRooms'] ||= [scenario_data['startRoom']]
      self.player_state['unlockedObjects'] ||= []
      self.player_state['inventory'] ||= []
      self.player_state['encounteredNPCs'] ||= []
      self.player_state['globalVariables'] ||= {}
      self.player_state['biometricSamples'] ||= []
      self.player_state['biometricUnlocks'] ||= []
      self.player_state['bluetoothDevices'] ||= []
      self.player_state['notes'] ||= []
      self.player_state['health'] ||= 100
    end

    def set_started_at
      self.started_at ||= Time.current
    end
  end
end
```

---

## Routes

```ruby
# config/routes.rb
BreakEscape::Engine.routes.draw do
  # Mission selection
  resources :missions, only: [:index, :show]

  # Game management
  resources :games, only: [:show, :create] do
    member do
      # Scenario and NPC data (JIT compiled)
      get 'scenario'  # Returns scenario_data JSON
      get 'ink'       # Returns NPC script (JIT compiled)

      # API endpoints (namespaced under /api for clarity)
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
```

**Mounted URLs (in Hacktivity):**
```
https://hacktivity.com/break_escape/missions
https://hacktivity.com/break_escape/games/123
https://hacktivity.com/break_escape/games/123/scenario
https://hacktivity.com/break_escape/games/123/ink?npc=helper1
https://hacktivity.com/break_escape/games/123/bootstrap
```

---

## API Endpoints

See `04_API_REFERENCE.md` for complete documentation.

**Summary:**
1. `GET /games/:id/scenario` - Scenario JSON for this game
2. `GET /games/:id/ink?npc=X` - NPC script (JIT compiled)
3. `GET /games/:id/bootstrap` - Initial game data
4. `PUT /games/:id/sync_state` - Sync player state
5. `POST /games/:id/unlock` - Validate unlock
6. `POST /games/:id/inventory` - Update inventory

---

## JIT Ink Compilation

### How It Works

```ruby
# GET /games/:id/ink?npc=helper1

1. Find NPC in game's scenario_data
2. Get storyPath (e.g., "scenarios/ink/helper-npc.json")
3. Check if .json exists and is newer than .ink
4. If not, compile: bin/inklecate -o helper-npc.json helper-npc.ink
5. Serve compiled JSON
```

### Performance

- Compilation: ~300ms (benchmarked)
- Cached reads: ~15ms
- Only compiles if needed (timestamp check)

### Controller Implementation

See `03_IMPLEMENTATION_PLAN.md` Phase 6 for complete code.

---

## ERB Scenario Templates

### Template Example

```erb
<%# app/assets/scenarios/ceo_exfil/scenario.json.erb %>
{
  "scenarioName": "CEO Exfiltration",
  "startRoom": "reception",
  "rooms": {
    "office": {
      "locked": true,
      "lockType": "password",
      "requires": "<%= random_password %>",
      "objects": [
        {
          "type": "safe",
          "locked": true,
          "lockType": "pin",
          "requires": "<%= random_pin %>"
        }
      ]
    }
  }
}
```

### Variables Available

- `random_password` - 8-character alphanumeric
- `random_pin` - 4-digit number
- `random_code` - 8-character hex

### Generation

Happens once when Game is created:
```ruby
before_create :generate_scenario_data
# Calls mission.generate_scenario_data
# Stores in game.scenario_data JSONB
```

---

## Polymorphic Player

### User (Hacktivity Mode)

```ruby
# Hacktivity's existing User model
class User < ApplicationRecord
  devise :database_authenticatable, :registerable
  has_many :games, as: :player, class_name: 'BreakEscape::Game'
end
```

### DemoUser (Standalone Mode)

```ruby
# app/models/break_escape/demo_user.rb
module BreakEscape
  class DemoUser < ApplicationRecord
    self.table_name = 'break_escape_demo_users'

    has_many :games, as: :player, class_name: 'BreakEscape::Game'

    validates :handle, presence: true, uniqueness: true
  end
end
```

### Controller Logic

```ruby
def current_player
  if BreakEscape.standalone_mode?
    @current_player ||= BreakEscape::DemoUser.first_or_create!(
      handle: 'demo_player'
    )
  else
    current_user  # From Devise
  end
end
```

---

## Authorization (Pundit)

### GamePolicy

```ruby
# app/policies/break_escape/game_policy.rb
module BreakEscape
  class GamePolicy < ApplicationPolicy
    def show?
      # Owner or admin
      record.player == user || user&.admin?
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

---

## Security (CSP)

### Layout with Nonces

```erb
<%# app/views/break_escape/games/show.html.erb %>
<!DOCTYPE html>
<html>
<head>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag '/break_escape/css/styles.css' %>
</head>
<body>
  <div id="break-escape-game"></div>

  <script nonce="<%= content_security_policy_nonce %>">
    window.breakEscapeConfig = {
      gameId: <%= @game.id %>,
      apiBasePath: '<%= break_escape_game_path(@game) %>',
      csrfToken: '<%= form_authenticity_token %>'
    };
  </script>

  <%= javascript_include_tag '/break_escape/js/main.js', type: 'module', nonce: content_security_policy_nonce %>
</body>
</html>
```

---

## Summary

**Architecture Highlights:**

- ✅ 2 database tables (missions, games)
- ✅ JSONB for flexible state storage
- ✅ JIT Ink compilation (~300ms)
- ✅ ERB scenario randomization
- ✅ Polymorphic player (User/DemoUser)
- ✅ Session-based auth
- ✅ Pundit authorization
- ✅ CSP with nonces
- ✅ Static assets in public/
- ✅ Minimal client changes

**Next:** See `03_IMPLEMENTATION_PLAN.md` for step-by-step instructions.
