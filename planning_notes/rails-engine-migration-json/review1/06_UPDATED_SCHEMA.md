# Updated Database Schema (Corrected)

This document provides the corrected database schema that fixes Issue #2 (shared NPCs).

---

## Problem Statement

**Original Schema Issue:**
```ruby
create_table :break_escape_npc_scripts do |t|
  t.references :scenario, null: false
  t.string :npc_id, null: false
  t.index [:scenario_id, :npc_id], unique: true  # ← Forces 1:1 relationship
end
```

**Codebase Reality:**
- Many NPCs are shared across multiple scenarios
- `test-npc.json` used in 10+ scenarios
- `generic-npc.json`, hub NPCs are reusable

**Result:** Schema doesn't match actual usage patterns.

---

## Solution: Shared NPC Registry with Join Table

---

## Migration 1: NPC Scripts (Shared Registry)

```ruby
# db/migrate/xxx_create_break_escape_npc_scripts.rb
class CreateBreakEscapeNpcScripts < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_npc_scripts do |t|
      # Global NPC identifier (no scenario_id!)
      t.string :npc_id, null: false

      # Display information
      t.string :display_name
      t.string :avatar_path

      # Ink scripts
      t.text :ink_source              # Optional .ink source
      t.text :ink_compiled, null: false  # Required .json compiled

      # Metadata
      t.string :npc_type              # 'phone', 'person', 'generic'
      t.jsonb :default_config         # Default timedMessages, eventMappings

      t.timestamps
    end

    # Global registry - each NPC appears once
    add_index :break_escape_npc_scripts, :npc_id, unique: true
    add_index :break_escape_npc_scripts, :npc_type
  end
end
```

---

## Migration 2: Scenario-NPC Join Table

```ruby
# db/migrate/xxx_create_break_escape_scenario_npcs.rb
class CreateBreakEscapeScenarioNpcs < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_scenario_npcs do |t|
      # Foreign keys
      t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }
      t.references :npc_script, null: false, foreign_key: { to_table: :break_escape_npc_scripts }

      # Scenario-specific overrides (optional)
      t.jsonb :config_overrides        # Override timedMessages, eventMappings for this scenario
      t.string :initial_knot           # Starting dialogue knot for this scenario
      t.string :room_id                # Which room NPC appears in

      t.timestamps
    end

    # Many-to-many: scenario can have many NPCs, NPC can be in many scenarios
    add_index :break_escape_scenario_npcs, [:scenario_id, :npc_script_id], unique: true, name: 'index_scenario_npcs_unique'
    add_index :break_escape_scenario_npcs, :room_id
  end
end
```

---

## Migration 3: Scenarios (Unchanged)

```ruby
# db/migrate/xxx_create_break_escape_scenarios.rb
class CreateBreakEscapeScenarios < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_scenarios do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.jsonb :scenario_data, null: false
      t.boolean :published, default: false
      t.integer :difficulty_level, default: 1

      t.timestamps
    end

    add_index :break_escape_scenarios, :name, unique: true
    add_index :break_escape_scenarios, :published
    add_index :break_escape_scenarios, :scenario_data, using: :gin
  end
end
```

---

## Migration 4: Game Instances (Extended)

```ruby
# db/migrate/xxx_create_break_escape_game_instances.rb
class CreateBreakEscapeGameInstances < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_game_instances do |t|
      # Polymorphic player
      t.references :player, polymorphic: true, null: false

      # Scenario reference
      t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }

      # Player state (EXTENDED)
      t.jsonb :player_state, null: false, default: {
        currentRoom: nil,
        position: { x: 0, y: 0 },
        unlockedRooms: [],
        unlockedObjects: [],
        inventory: [],
        encounteredNPCs: [],
        globalVariables: {},

        # NEW: Minigame state
        biometricSamples: [],
        biometricUnlocks: [],
        bluetoothDevices: [],
        notes: [],

        # NEW: Minigame results
        minigameResults: [],

        # NEW: Timestamps
        startTime: nil,
        lastSyncTime: nil
      }

      # Game metadata
      t.string :status, default: 'in_progress'
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :score, default: 0
      t.integer :health, default: 100

      t.timestamps
    end

    add_index :break_escape_game_instances,
              [:player_type, :player_id, :scenario_id],
              unique: true,
              name: 'index_game_instances_on_player_and_scenario'
    add_index :break_escape_game_instances, :player_state, using: :gin
    add_index :break_escape_game_instances, :status
  end
end
```

---

## Updated Models

### NpcScript Model

```ruby
# app/models/break_escape/npc_script.rb
module BreakEscape
  class NpcScript < ApplicationRecord
    self.table_name = 'break_escape_npc_scripts'

    # Many-to-many with scenarios
    has_many :scenario_npcs, class_name: 'BreakEscape::ScenarioNpc', dependent: :destroy
    has_many :scenarios, through: :scenario_npcs

    validates :npc_id, presence: true, uniqueness: true
    validates :ink_compiled, presence: true

    # Return compiled Ink JSON
    def compiled_json
      JSON.parse(ink_compiled)
    rescue JSON::ParserError
      {}
    end
  end
end
```

---

### ScenarioNpc Model (New)

```ruby
# app/models/break_escape/scenario_npc.rb
module BreakEscape
  class ScenarioNpc < ApplicationRecord
    self.table_name = 'break_escape_scenario_npcs'

    belongs_to :scenario, class_name: 'BreakEscape::Scenario'
    belongs_to :npc_script, class_name: 'BreakEscape::NpcScript'

    # Merge NPC defaults with scenario-specific overrides
    def effective_config
      npc_script.default_config.deep_merge(config_overrides || {})
    end
  end
end
```

---

### Scenario Model (Updated)

```ruby
# app/models/break_escape/scenario.rb
module BreakEscape
  class Scenario < ApplicationRecord
    self.table_name = 'break_escape_scenarios'

    has_many :game_instances, class_name: 'BreakEscape::GameInstance'

    # Many-to-many with NPCs
    has_many :scenario_npcs, class_name: 'BreakEscape::ScenarioNpc', dependent: :destroy
    has_many :npc_scripts, through: :scenario_npcs

    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true
    validates :scenario_data, presence: true

    scope :published, -> { where(published: true) }

    # ... existing methods ...

    # Get NPCs for a specific room
    def npcs_in_room(room_id)
      scenario_npcs.where(room_id: room_id).includes(:npc_script)
    end
  end
end
```

---

### GameInstance Model (Extended)

```ruby
# app/models/break_escape/game_instance.rb
module BreakEscape
  class GameInstance < ApplicationRecord
    self.table_name = 'break_escape_game_instances'

    belongs_to :player, polymorphic: true
    belongs_to :scenario, class_name: 'BreakEscape::Scenario'

    validates :player, presence: true
    validates :scenario, presence: true
    validates :status, inclusion: { in: %w[in_progress completed abandoned] }

    scope :active, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }

    before_create :set_started_at
    before_create :initialize_player_state

    # ... existing methods ...

    # NEW: Minigame state management
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

    def record_minigame_result!(minigame_name, success, score = nil)
      player_state['minigameResults'] ||= []
      player_state['minigameResults'] << {
        name: minigame_name,
        success: success,
        score: score,
        timestamp: Time.current.iso8601
      }
      save!
    end

    private

    def initialize_player_state
      self.player_state ||= {}
      self.player_state['currentRoom'] ||= scenario.start_room
      self.player_state['unlockedRooms'] ||= [scenario.start_room]
      self.player_state['position'] ||= { 'x' => 0, 'y' => 0 }
      self.player_state['inventory'] ||= []
      self.player_state['unlockedObjects'] ||= []
      self.player_state['encounteredNPCs'] ||= []
      self.player_state['globalVariables'] ||= {}

      # NEW: Initialize minigame state
      self.player_state['biometricSamples'] ||= []
      self.player_state['biometricUnlocks'] ||= []
      self.player_state['bluetoothDevices'] ||= []
      self.player_state['notes'] ||= []
      self.player_state['minigameResults'] ||= []

      # NEW: Timestamps
      self.player_state['startTime'] ||= Time.current.iso8601
      self.player_state['lastSyncTime'] = Time.current.iso8601
    end
  end
end
```

---

## Updated ScenarioLoader

```ruby
# lib/break_escape/scenario_loader.rb
module BreakEscape
  class ScenarioLoader
    attr_reader :scenario_name

    def initialize(scenario_name)
      @scenario_name = scenario_name
    end

    def import!
      scenario_data = load_and_process_erb

      scenario = Scenario.find_or_initialize_by(name: scenario_name)
      scenario.assign_attributes(
        display_name: scenario_data['scenarioName'] || scenario_name.titleize,
        description: scenario_data['scenarioBrief'],
        scenario_data: scenario_data,
        published: true
      )
      scenario.save!

      # Import NPCs (shared registry)
      import_npc_scripts!(scenario, scenario_data)

      scenario
    end

    private

    def load_and_process_erb
      template_path = Rails.root.join('app/assets/scenarios', scenario_name, 'scenario.json.erb')
      raise "Scenario not found: #{scenario_name}" unless File.exist?(template_path)

      erb = ERB.new(File.read(template_path))
      binding_context = ScenarioBinding.new
      output = erb.result(binding_context.get_binding)

      # Validate JSON
      JSON.parse(output)
    rescue JSON::ParserError => e
      raise "Invalid JSON in #{scenario_name} after ERB processing: #{e.message}"
    end

    def import_npc_scripts!(scenario, scenario_data)
      # Clear existing associations
      scenario.scenario_npcs.destroy_all

      # Process each room's NPCs
      scenario_data['rooms']&.each do |room_id, room_data|
        next unless room_data['npcs']

        room_data['npcs'].each do |npc_data|
          npc_id = npc_data['id']

          # Find or create global NPC script
          npc_script = import_or_find_npc_script(npc_id, npc_data)

          # Create scenario-npc association
          scenario.scenario_npcs.create!(
            npc_script: npc_script,
            room_id: room_id,
            initial_knot: npc_data['currentKnot'] || 'start',
            config_overrides: {
              'timedMessages' => npc_data['timedMessages'],
              'eventMappings' => npc_data['eventMappings']
            }.compact
          )
        end
      end
    end

    def import_or_find_npc_script(npc_id, npc_data)
      # Check if NPC already exists globally
      npc_script = NpcScript.find_by(npc_id: npc_id)
      return npc_script if npc_script

      # Create new NPC script
      # Look for compiled script (check both .json and .ink.json)
      story_path = npc_data['storyPath']
      compiled_path = Rails.root.join(story_path)

      unless File.exist?(compiled_path)
        # Try .ink.json extension
        ink_json_path = compiled_path.to_s.gsub(/\.json$/, '.ink.json')
        compiled_path = Pathname.new(ink_json_path) if File.exist?(ink_json_path)
      end

      raise "NPC script not found: #{story_path}" unless File.exist?(compiled_path)

      # Look for source .ink file
      ink_source_path = compiled_path.to_s.gsub(/\.(ink\.)?json$/, '.ink')
      ink_source = File.exist?(ink_source_path) ? File.read(ink_source_path) : nil

      NpcScript.create!(
        npc_id: npc_id,
        display_name: npc_data['displayName'],
        avatar_path: npc_data['avatar'],
        npc_type: npc_data['npcType'] || 'generic',
        ink_source: ink_source,
        ink_compiled: File.read(compiled_path),
        default_config: {
          'phoneId' => npc_data['phoneId']
        }.compact
      )
    end

    class ScenarioBinding
      def initialize
        @random_password = SecureRandom.alphanumeric(8)
        @random_pin = rand(1000..9999).to_s
      end

      attr_reader :random_password, :random_pin

      def get_binding
        binding
      end
    end
  end
end
```

---

## Benefits of Updated Schema

### ✅ Supports Shared NPCs
```ruby
# test-npc script exists once
npc = NpcScript.find_by(npc_id: 'test_npc')

# Used in multiple scenarios
npc.scenarios.count  # => 10
```

### ✅ Reduces Database Size
- 30 unique NPCs vs 100+ duplicates
- Single update affects all scenarios

### ✅ Scenario-Specific Customization
```ruby
# Global NPC has default config
npc.default_config  # => { phoneId: 'player_phone' }

# Scenario can override
scenario_npc.config_overrides  # => { timedMessages: [...] }
scenario_npc.effective_config  # => Merged config
```

### ✅ Complete Minigame State
```ruby
game.player_state['biometricSamples']  # Persisted ✓
game.player_state['bluetoothDevices']  # Persisted ✓
game.player_state['notes']             # Persisted ✓
```

---

## Migration from Old Schema (If Needed)

If implementation already started with old schema:

```ruby
# db/migrate/xxx_migrate_to_shared_npcs.rb
class MigrateToSharedNpcs < ActiveRecord::Migration[7.0]
  def up
    # 1. Create new tables
    create_table :break_escape_npc_scripts_new do |t|
      # ... new schema ...
    end
    create_table :break_escape_scenario_npcs do |t|
      # ... join table ...
    end

    # 2. Migrate data
    BreakEscape::NpcScript.find_each do |old_npc|
      # Create global NPC if doesn't exist
      new_npc = BreakEscape::NpcScript.find_or_create_by!(
        npc_id: old_npc.npc_id,
        ink_compiled: old_npc.ink_compiled
        # ... other fields ...
      )

      # Create join table entry
      BreakEscape::ScenarioNpc.create!(
        scenario_id: old_npc.scenario_id,
        npc_script_id: new_npc.id
      )
    end

    # 3. Drop old table
    drop_table :break_escape_npc_scripts_old
  end
end
```

---

## Summary

**Changes:**
1. ✅ NPC scripts are now global (no scenario_id)
2. ✅ Join table links scenarios ↔ NPCs (many-to-many)
3. ✅ Scenario-specific overrides supported
4. ✅ Minigame state fields added to player_state
5. ✅ JSON validation in ScenarioLoader

**Files to Update:**
- `02_IMPLEMENTATION_PLAN.md` - Phase 4 migrations
- `03_DATABASE_SCHEMA.md` - All schema documentation
- `01_ARCHITECTURE.md` - Model examples

**Timeline Impact:** +0 days (fix during Phase 4, no delay)

---

**Next Document:** [README.md](./README.md) - Review navigation guide
