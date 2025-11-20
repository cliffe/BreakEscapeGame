# Simplified Database Schema (2 Tables)

**Date:** November 20, 2025
**Status:** RECOMMENDED APPROACH

This document presents a **dramatically simplified** schema that eliminates the NPC registry complexity.

---

## Key Simplifications

### What Changed

**REMOVED:**
- ❌ `break_escape_npc_scripts` table (no NPC registry!)
- ❌ `break_escape_scenario_npcs` join table
- ❌ `scenario_data` JSONB in scenarios table
- ❌ Complex NPC seed logic

**SIMPLIFIED:**
- ✅ 2 tables instead of 3-4
- ✅ Scenarios are just metadata
- ✅ scenario_data generated per game instance (via ERB)
- ✅ Ink files served directly from filesystem
- ✅ No database bloat with duplicate scripts

---

## Philosophy

**"Files on filesystem, metadata in database"**

- **Scenarios** → Directories with ERB templates (filesystem)
- **Ink scripts** → .json files (filesystem)
- **Database** → Only track which scenario, player progress
- **ERB generation** → Happens when game instance is created

---

## Complete Schema

---

## Table 1: missions (scenarios)

Stores scenario metadata only.

```ruby
create_table :break_escape_missions do |t|
  t.string :name, null: false              # 'ceo_exfil'
  t.string :display_name, null: false      # 'CEO Exfiltration'
  t.text :description                      # Scenario brief
  t.boolean :published, default: false
  t.integer :difficulty_level, default: 1  # 1-5

  t.timestamps
end

add_index :break_escape_missions, :name, unique: true
add_index :break_escape_missions, :published
```

**What it stores:**
- Scenario identifier (name)
- Display information
- Published status

**What it does NOT store:**
- ❌ Scenario JSON (generated on demand via ERB)
- ❌ NPC scripts (served from filesystem)
- ❌ Room data (in scenario directory)

---

## Table 2: games (game instances)

Stores player game state with scenario data snapshot.

```ruby
create_table :break_escape_games do |t|
  # Polymorphic player
  t.references :player, polymorphic: true, null: false

  # Scenario reference
  t.references :mission, null: false, foreign_key: { to_table: :break_escape_missions }

  # Scenario snapshot (generated via ERB at creation)
  t.jsonb :scenario_data, null: false      # ← MOVED HERE!

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

  # Game metadata
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

**Key Changes:**
- `scenario_data` is now **per game instance** (supports randomization!)
- `player_state` includes `health` (no separate column)
- Removed `position` (not needed for now)
- Added minigame fields

---

## Migrations

### Migration 1: Create Missions

```ruby
# db/migrate/001_create_break_escape_missions.rb
class CreateBreakEscapeMissions < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_missions do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :published, default: false
      t.integer :difficulty_level, default: 1

      t.timestamps
    end

    add_index :break_escape_missions, :name, unique: true
    add_index :break_escape_missions, :published
  end
end
```

### Migration 2: Create Games

```ruby
# db/migrate/002_create_break_escape_games.rb
class CreateBreakEscapeGames < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_games do |t|
      # Polymorphic player
      t.references :player, polymorphic: true, null: false, index: true

      # Mission reference
      t.references :mission, null: false, foreign_key: { to_table: :break_escape_missions }

      # Scenario snapshot (ERB-generated)
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
      t.string :status, default: 'in_progress'
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
  end
end
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
      raise "Scenario not found: #{name}" unless File.exist?(template_path)

      erb = ERB.new(File.read(template_path))
      binding_context = ScenarioBinding.new
      output = erb.result(binding_context.get_binding)

      JSON.parse(output)
    rescue JSON::ParserError => e
      raise "Invalid JSON in #{name}: #{e.message}"
    end

    # Binding context for ERB
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

    def npc_encountered?(npc_id)
      player_state['encounteredNPCs']&.include?(npc_id)
    end

    # Global variables (synced with client)
    def update_global_variable!(key, value)
      player_state['globalVariables'] ||= {}
      player_state['globalVariables'][key] = value
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
      player_state['bluetoothDevices'] << device unless player_state['bluetoothDevices'].any? { |d| d['mac'] == device['mac'] }
      save!
    end

    def add_note!(note)
      player_state['notes'] ||= []
      player_state['notes'] << note
      save!
    end

    # Health management
    def update_health!(value)
      player_state['health'] = value
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

## API Endpoints

### Simplified API

```ruby
# config/routes.rb
BreakEscape::Engine.routes.draw do
  resources :missions, only: [:index, :show]

  resources :games, only: [:show, :create] do
    member do
      # Serve scenario JSON for this game instance
      get 'scenario', to: 'games#scenario'

      # Serve NPC ink scripts
      get 'ink', to: 'games#ink'

      # API endpoints
      get 'bootstrap', to: 'api/games#bootstrap'
      put 'sync_state', to: 'api/games#sync_state'
      post 'unlock', to: 'api/games#unlock'
      post 'inventory', to: 'api/games#inventory'
    end
  end

  root to: 'missions#index'
end
```

---

### Games Controller

```ruby
# app/controllers/break_escape/games_controller.rb
module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :scenario, :ink]

    def show
      authorize @game if defined?(Pundit)
      # Render game view
    end

    # GET /games/:id/scenario
    def scenario
      authorize @game if defined?(Pundit)

      render json: @game.scenario_data
    end

    # GET /games/:id/ink?npc=helper1
    def ink
      authorize @game if defined?(Pundit)

      npc_id = params[:npc]
      return head :bad_request unless npc_id.present?

      # Find NPC in scenario data
      npc = find_npc_in_scenario(npc_id)
      return head :not_found unless npc

      # Load ink file from filesystem
      ink_path = resolve_ink_path(npc['storyPath'])
      return head :not_found unless File.exist?(ink_path)

      render json: JSON.parse(File.read(ink_path))
    end

    private

    def set_game
      @game = Game.find(params[:id])
    end

    def find_npc_in_scenario(npc_id)
      @game.scenario_data['rooms']&.each do |_room_id, room_data|
        npc = room_data['npcs']&.find { |n| n['id'] == npc_id }
        return npc if npc
      end
      nil
    end

    def resolve_ink_path(story_path)
      # story_path is like "scenarios/ink/helper-npc.json"
      Rails.root.join(story_path)
    end
  end
end
```

---

## Simplified Seed Process

```ruby
# db/seeds.rb
puts "Creating missions..."

# Just create mission metadata - no scenario data!
missions = [
  { name: 'ceo_exfil', display_name: 'CEO Exfiltration', difficulty: 3 },
  { name: 'cybok_heist', display_name: 'CybOK Heist', difficulty: 4 },
  { name: 'biometric_breach', display_name: 'Biometric Breach', difficulty: 2 }
]

missions.each do |mission_data|
  mission = BreakEscape::Mission.find_or_create_by!(name: mission_data[:name]) do |m|
    m.display_name = mission_data[:display_name]
    m.difficulty_level = mission_data[:difficulty]
    m.published = true
  end

  puts "  ✓ #{mission.display_name}"
end

puts "Done! Created #{BreakEscape::Mission.count} missions."
```

---

## Client Integration

### Loading Scenario

```javascript
// Before: Load from static file
const scenario = await fetch('/scenarios/ceo_exfil.json').then(r => r.json());

// After: Load from game instance
const gameId = window.breakEscapeConfig.gameId;
const scenario = await fetch(`/break_escape/games/${gameId}/scenario`).then(r => r.json());
```

### Loading NPC Scripts

```javascript
// Before: Load from static file
const inkScript = await fetch('/scenarios/ink/helper-npc.json').then(r => r.json());

// After: Load from game instance
const gameId = window.breakEscapeConfig.gameId;
const inkScript = await fetch(`/break_escape/games/${gameId}/ink?npc=helper_npc`).then(r => r.json());
```

---

## Benefits of This Approach

### ✅ Dramatically Simpler
- **2 tables** instead of 3-4
- **No NPC registry** complexity
- **No join tables**
- **Simpler seed script** (just metadata)

### ✅ Better Randomization
- Each game instance gets its own ERB-generated scenario
- Different passwords/pins per player
- No shared scenario data

### ✅ No Database Bloat
- Ink scripts stay on filesystem
- No duplicate NPC storage
- Scenario templates on filesystem

### ✅ Easier Development
- No complex migrations for NPC changes
- Update .ink files directly
- No seed script for NPCs

### ✅ Authorization Built-In
- Can't access scenario data without game instance
- Can't access NPC scripts without game instance
- Player-specific access control

---

## Comparison: Old vs New

| Aspect | Old Approach (3-4 tables) | New Approach (2 tables) |
|--------|---------------------------|-------------------------|
| **Tables** | scenarios, npc_scripts, scenario_npcs, games | missions, games |
| **Scenario data** | In scenarios table | Generated per game |
| **NPC scripts** | In database | On filesystem |
| **Seed complexity** | High (import scenarios + NPCs) | Low (just metadata) |
| **Randomization** | Shared scenario data | Per-instance generation |
| **File access** | Via database | Via game instance endpoints |
| **Migration effort** | Complex | Simple |
| **Database size** | Large (duplicates) | Small (metadata only) |

---

## Migration Timeline Impact

**Old Approach:**
- Phase 4: 3-4 complex migrations
- Phase 5: Complex seed with NPC imports
- Total: ~8 hours

**New Approach:**
- Phase 4: 2 simple migrations
- Phase 5: Simple seed (metadata only)
- Total: ~3 hours

**Time Saved:** 5 hours

---

## Summary

**This is the recommended approach!**

- ✅ 2 tables instead of 3-4
- ✅ Files on filesystem (where they belong)
- ✅ Metadata in database (what it's good for)
- ✅ Per-instance scenario generation (better randomization)
- ✅ Simpler, faster, cleaner

**Next Step:** Update implementation plan to use this schema.
