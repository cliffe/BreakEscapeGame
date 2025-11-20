# BreakEscape Rails Engine - Implementation Plan

**Complete step-by-step guide with explicit commands**

---

## How to Use This Plan

1. **Follow phases in order** - Each phase builds on previous ones
2. **Read the entire phase** before starting - Understand what you're doing
3. **Execute commands exactly as written** - Copy/paste to avoid errors
4. **Test after each phase** - Don't proceed if tests fail
5. **Commit after each phase** - Preserve working state
6. **Use mv, not cp** - Move files to preserve git history

---

## Prerequisites

Before starting Phase 1:

```bash
# Verify you're in the correct directory
cd /home/user/BreakEscape
pwd  # Should print: /home/user/BreakEscape

# Verify git status
git status  # Should be clean or have only expected changes

# Verify Ruby and Rails versions
ruby -v   # Should be 3.0+
rails -v  # Should be 7.0+

# Verify PostgreSQL is running (if testing locally)
psql --version  # Should show PostgreSQL 14+

# Create a checkpoint
git add -A
git commit -m "chore: Checkpoint before Rails Engine migration"
git push

# Create feature branch
git checkout -b rails-engine-migration
```

---

## Phase 1: Setup Rails Engine Structure (Week 1, ~8 hours)

### Objectives

- Generate Rails Engine boilerplate
- Configure engine settings
- Set up gemspec and dependencies
- Verify engine loads

### 1.1 Generate Rails Engine

```bash
# Generate mountable engine with isolated namespace
# --mountable: Creates engine that can be mounted in routes
# --skip-git: Don't create new git repo (we're already in one)
# --dummy-path: Location for test dummy app
rails plugin new . --mountable --skip-git --dummy-path=test/dummy

# This creates:
# - lib/break_escape/engine.rb
# - lib/break_escape/version.rb
# - app/ directory structure
# - config/routes.rb
# - test/ directory structure
# - break_escape.gemspec
```

**Expected output:** Files created successfully

### 1.2 Configure Engine

Edit the generated engine file:

```bash
# Open engine file
vim lib/break_escape/engine.rb
```

**Replace entire contents with:**

```ruby
require 'pundit'

module BreakEscape
  class Engine < ::Rails::Engine
    isolate_namespace BreakEscape

    config.generators do |g|
      g.test_framework :test_unit, fixture: true
      g.assets false
      g.helper false
    end

    # Load lib directory
    config.autoload_paths << File.expand_path('../', __dir__)

    # Pundit authorization
    config.after_initialize do
      if defined?(Pundit)
        BreakEscape::ApplicationController.include Pundit::Authorization
      end
    end

    # Static files from public/break_escape
    config.middleware.use ::ActionDispatch::Static, "#{root}/public"
  end
end
```

**Save and close** (`:wq` in vim)

### 1.3 Update Version

```bash
vim lib/break_escape/version.rb
```

**Replace with:**

```ruby
module BreakEscape
  VERSION = '1.0.0'
end
```

**Save and close**

### 1.4 Update Gemfile

```bash
vim Gemfile
```

**Replace entire contents with:**

```ruby
source 'https://rubygems.org'

gemspec

# Development dependencies
group :development, :test do
  gem 'sqlite3'
  gem 'pry'
  gem 'pry-byebug'
end
```

**Save and close**

### 1.5 Update Gemspec

```bash
vim break_escape.gemspec
```

**Replace entire contents with:**

```ruby
require_relative "lib/break_escape/version"

Gem::Specification.new do |spec|
  spec.name        = "break_escape"
  spec.version     = BreakEscape::VERSION
  spec.authors     = ["BreakEscape Team"]
  spec.email       = ["team@example.com"]
  spec.summary     = "BreakEscape escape room game engine"
  spec.description = "Rails engine for BreakEscape cybersecurity training escape room game"
  spec.license     = "MIT"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "pundit", "~> 2.3"
end
```

**Save and close**

### 1.6 Install Dependencies

```bash
bundle install
```

**Expected output:** Dependencies installed successfully

### 1.7 Test Engine Loads

```bash
# Start Rails console
rails console

# Verify engine loads
puts BreakEscape::Engine.root
# Should print engine root path

# Exit console
exit
```

**Expected output:** Path printed successfully, no errors

### 1.8 Commit

```bash
git add -A
git status  # Review changes
git commit -m "feat: Generate Rails Engine structure

- Create mountable engine with isolated namespace
- Configure Pundit authorization
- Set up gemspec with dependencies
- Configure generators for test_unit with fixtures"

git push -u origin rails-engine-migration
```

---

## Phase 2: Move Game Files to public/ (Week 1, ~4 hours)

### Objectives

- Move static game files to public/break_escape/
- Preserve git history using mv
- Update any absolute paths if needed
- Verify files accessible

### 2.1 Create Directory Structure

```bash
# Create public directory for game assets
mkdir -p public/break_escape
```

### 2.2 Move Game Files

**IMPORTANT:** Use `mv`, not `cp`, to preserve git history

```bash
# Move JavaScript files
mv js public/break_escape/

# Move CSS files
mv css public/break_escape/

# Move assets (images, sounds, Tiled maps)
mv assets public/break_escape/

# Keep index.html as reference (don't move, copy for backup)
cp index.html public/break_escape/index.html.reference
```

### 2.3 Verify Files Moved

```bash
# Check that files exist in new location
ls -la public/break_escape/
# Should see: js/ css/ assets/ index.html.reference

# Check that old locations are gone
ls js 2>/dev/null && echo "ERROR: js still exists!" || echo "✓ js moved"
ls css 2>/dev/null && echo "ERROR: css still exists!" || echo "✓ css moved"
ls assets 2>/dev/null && echo "ERROR: assets still exists!" || echo "✓ assets moved"
```

**Expected output:** ✓ for all three checks

### 2.4 Update .gitignore

```bash
# Ensure public/break_escape is NOT ignored
vim .gitignore
```

**Check that these lines are NOT present:**
```
public/break_escape/
public/break_escape/**/*
```

**If they are, remove them**

**Verify git sees the files:**

```bash
git status | grep "public/break_escape"
# Should show moved files
```

### 2.5 Commit

```bash
git add -A
git status  # Review - should show renames/moves
git commit -m "refactor: Move game files to public/break_escape/

- Move js/ to public/break_escape/js/
- Move css/ to public/break_escape/css/
- Move assets/ to public/break_escape/assets/
- Preserve git history with mv command
- Keep index.html.reference for reference"

git push
```

---

## Phase 3: Create Scenario ERB Templates (Week 1-2, ~6 hours)

### Objectives

- Create app/assets/scenarios directory structure
- Convert scenario JSON files to ERB templates
- Add randomization for passwords/pins
- Keep .ink files in scenarios/ink/ (will be served directly)

### 3.1 Create Directory Structure

```bash
# Create scenarios directory
mkdir -p app/assets/scenarios

# List current scenarios
ls scenarios/*.json
```

**Note the scenario names** (e.g., ceo_exfil, cybok_heist, biometric_breach)

### 3.2 Process Each Scenario

**For EACH scenario file, follow these steps:**

#### Example: ceo_exfil

```bash
# Set scenario name
SCENARIO="ceo_exfil"

# Create scenario directory
mkdir -p "app/assets/scenarios/${SCENARIO}"

# Move scenario JSON and rename to .erb
mv "scenarios/${SCENARIO}.json" "app/assets/scenarios/${SCENARIO}/scenario.json.erb"

# Verify
ls -la "app/assets/scenarios/${SCENARIO}/"
# Should see: scenario.json.erb
```

#### Edit ERB Template to Add Randomization

```bash
vim "app/assets/scenarios/${SCENARIO}/scenario.json.erb"
```

**Find any hardcoded passwords/pins and replace:**

**Before:**
```json
{
  "locked": true,
  "lockType": "password",
  "requires": "admin123"
}
```

**After:**
```erb
{
  "locked": true,
  "lockType": "password",
  "requires": "<%= random_password %>"
}
```

**For PINs:**
```erb
"requires": "<%= random_pin %>"
```

**For codes:**
```erb
"requires": "<%= random_code %>"
```

**Save and close**

#### Repeat for All Scenarios

**Complete conversion script for all main scenarios:**

```bash
#!/bin/bash
# Convert all scenario JSON files to ERB structure

echo "Converting scenario files to ERB templates..."

# Main game scenarios (these are the production scenarios)
MAIN_SCENARIOS=(
  "ceo_exfil"
  "cybok_heist"
  "biometric_breach"
)

# Test/demo scenarios (keep for testing)
TEST_SCENARIOS=(
  "scenario1"
  "scenario2"
  "scenario3"
  "scenario4"
  "npc-hub-demo-ghost-protocol"
  "npc-patrol-lockpick"
  "npc-sprite-test2"
  "test-multiroom-npc"
  "test-npc-face-player"
  "test-npc-patrol"
  "test-npc-personal-space"
  "test-npc-waypoints"
  "test-rfid-multiprotocol"
  "test-rfid"
  "test_complex_multidirection"
  "test_horizontal_layout"
  "test_mixed_room_sizes"
  "test_multiple_connections"
  "test_vertical_layout"
  "timed_messages_example"
  "title-screen-demo"
)

# Process main scenarios
echo ""
echo "=== Processing Main Scenarios ==="
for scenario in "${MAIN_SCENARIOS[@]}"; do
  if [ -f "scenarios/${scenario}.json" ]; then
    echo "Processing: $scenario"

    # Create directory
    mkdir -p "app/assets/scenarios/${scenario}"

    # Move and rename (just rename to .erb, don't modify content yet)
    mv "scenarios/${scenario}.json" "app/assets/scenarios/${scenario}/scenario.json.erb"

    echo "  ✓ Moved to app/assets/scenarios/${scenario}/scenario.json.erb"
    echo "  → Edit later to add <%= random_password %>, <%= random_pin %>, etc."
  else
    echo "  ⚠ File not found: scenarios/${scenario}.json (skipping)"
  fi
done

# Process test scenarios
echo ""
echo "=== Processing Test Scenarios ==="
for scenario in "${TEST_SCENARIOS[@]}"; do
  if [ -f "scenarios/${scenario}.json" ]; then
    echo "Processing: $scenario"

    # Create directory
    mkdir -p "app/assets/scenarios/${scenario}"

    # Move and rename
    mv "scenarios/${scenario}.json" "app/assets/scenarios/${scenario}/scenario.json.erb"

    echo "  ✓ Moved to app/assets/scenarios/${scenario}/scenario.json.erb"
  else
    echo "  ⚠ File not found: scenarios/${scenario}.json (skipping)"
  fi
done

echo ""
echo "=== Summary ==="
echo "Converted files:"
find app/assets/scenarios -name "scenario.json.erb" | wc -l
echo ""
echo "Directory structure:"
ls -d app/assets/scenarios/*/
echo ""
echo "✓ Conversion complete!"
echo ""
echo "IMPORTANT:"
echo "- Files have been renamed to .erb but content is still JSON"
echo "- ERB randomization (random_password, etc.) will be added in Phase 4"
echo "- For now, scenarios work as-is with static passwords"
```

**Save this script** as `scripts/convert-scenarios.sh` and run:

```bash
chmod +x scripts/convert-scenarios.sh
./scripts/convert-scenarios.sh
```

**Alternative: Manual conversion for main scenarios only:**

```bash
# If you only want to convert the 3 main scenarios manually:

# CEO Exfiltration
mkdir -p app/assets/scenarios/ceo_exfil
mv scenarios/ceo_exfil.json app/assets/scenarios/ceo_exfil/scenario.json.erb

# CybOK Heist
mkdir -p app/assets/scenarios/cybok_heist
mv scenarios/cybok_heist.json app/assets/scenarios/cybok_heist/scenario.json.erb

# Biometric Breach
mkdir -p app/assets/scenarios/biometric_breach
mv scenarios/biometric_breach.json app/assets/scenarios/biometric_breach/scenario.json.erb

# Verify
ls -la app/assets/scenarios/*/scenario.json.erb
```

**Note:**
- Files are renamed to `.erb` extension but content remains valid JSON
- ERB randomization code (`<%= random_password %>`) will be added later in Phase 4
- This preserves git history and allows immediate testing
- Test scenarios are useful for development but don't need randomization

### 3.3 Handle Ink Files

**Keep .ink files in scenarios/ink/ - they will be served directly**

```bash
# Verify ink files are still in place
ls scenarios/ink/*.ink | wc -l
# Should show ~30 files

echo "✓ Ink files staying in scenarios/ink/ (served via JIT compilation)"
```

### 3.4 Remove Old scenarios Directory (Optional)

**Only after verifying all scenario.json.erb files are created:**

```bash
# Check if any .json files remain
ls scenarios/*.json 2>/dev/null

# If empty, safe to remove (or keep as backup)
# mv scenarios/old_scenarios_backup
```

### 3.5 Test ERB Processing

```bash
# Start Rails console
rails console

# Test ERB processing
template_path = Rails.root.join('app/assets/scenarios/ceo_exfil/scenario.json.erb')
erb = ERB.new(File.read(template_path))

# Create binding with random values
class TestBinding
  def initialize
    @random_password = 'TEST123'
    @random_pin = '1234'
    @random_code = 'abcd'
  end
  attr_reader :random_password, :random_pin, :random_code
  def get_binding; binding; end
end

output = erb.result(TestBinding.new.get_binding)
json = JSON.parse(output)
puts "✓ ERB processing works!"

exit
```

**Expected output:** "✓ ERB processing works!" with no JSON parse errors

### 3.6 Commit

```bash
git add -A
git status  # Review changes
git commit -m "refactor: Convert scenarios to ERB templates

- Move scenario JSON files to app/assets/scenarios/
- Rename to .erb extension
- Add randomization for passwords and PINs
- Keep .ink files in scenarios/ink/ for JIT compilation
- Each scenario now in own directory"

git push
```

---

## Phase 4: Database Setup (Week 2-3, ~6 hours)

### Objectives

- Generate database migrations
- Create Mission and Game models
- Set up polymorphic associations
- Run migrations

### 4.1 Generate Migrations

```bash
# Generate missions migration
rails generate migration CreateBreakEscapeMissions

# Generate games migration
rails generate migration CreateBreakEscapeGames

# List generated migrations
ls db/migrate/
```

### 4.2 Edit Missions Migration

```bash
# Find the missions migration file
MIGRATION=$(ls db/migrate/*_create_break_escape_missions.rb)
vim "$MIGRATION"
```

**Replace entire contents with:**

```ruby
class CreateBreakEscapeMissions < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_missions do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :published, default: false, null: false
      t.integer :difficulty_level, default: 1, null: false

      t.timestamps
    end

    add_index :break_escape_missions, :name, unique: true
    add_index :break_escape_missions, :published
  end
end
```

**Save and close**

### 4.3 Edit Games Migration

```bash
# Find the games migration file
MIGRATION=$(ls db/migrate/*_create_break_escape_games.rb)
vim "$MIGRATION"
```

**Replace entire contents with:**

```ruby
class CreateBreakEscapeGames < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_games do |t|
      # Polymorphic player
      t.references :player, polymorphic: true, null: false, index: true

      # Mission reference
      t.references :mission, null: false, foreign_key: { to_table: :break_escape_missions }

      # Scenario snapshot (ERB-generated)
      t.jsonb :scenario_data, null: false

      # Player state
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
      t.string :status, default: 'in_progress', null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :score, default: 0, null: false

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

**Save and close**

### 4.4 Run Migrations

```bash
# Run migrations
rails db:migrate

# Verify tables created
rails runner "puts ActiveRecord::Base.connection.tables"
# Should include: break_escape_missions, break_escape_games
```

**Expected output:** Tables listed successfully

### 4.5 Generate Model Files

```bash
# Generate Mission model (skip migration since we already created it)
rails generate model Mission --skip-migration

# Generate Game model
rails generate model Game --skip-migration
```

### 4.6 Edit Mission Model

```bash
vim app/models/break_escape/mission.rb
```

**Replace entire contents with:**

```ruby
module BreakEscape
  class Mission < ApplicationRecord
    self.table_name = 'break_escape_missions'

    has_many :games, class_name: 'BreakEscape::Game', dependent: :destroy

    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true
    validates :difficulty_level, inclusion: { in: 1..5 }

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

**Save and close**

### 4.7 Edit Game Model

```bash
vim app/models/break_escape/game.rb
```

**Replace entire contents with:**

```ruby
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

**Save and close**

### 4.8 Test Models

```bash
# Start Rails console
rails console

# Test Mission model
mission = BreakEscape::Mission.new(name: 'test', display_name: 'Test')
puts mission.valid?  # Should be true

# Test scenario path
mission.name = 'ceo_exfil'
puts mission.scenario_path
# Should print: /home/user/BreakEscape/app/assets/scenarios/ceo_exfil

exit
```

**Expected output:** Valid model, correct path

### 4.9 Commit

```bash
git add -A
git status  # Review changes
git commit -m "feat: Add database schema and models

- Create break_escape_missions table (metadata only)
- Create break_escape_games table (state + scenario snapshot)
- Add Mission model with ERB scenario generation
- Add Game model with state management methods
- Use JSONB for flexible state storage
- Polymorphic player association (User/DemoUser)"

git push
```

---

## Phase 5: Seed Data (Week 3, ~2 hours)

### Objectives

- Create simple seed file for mission metadata
- No scenario data in database (generated on-demand)
- Test mission creation

### 5.1 Create Seed File

```bash
vim db/seeds.rb
```

**Replace entire contents with:**

```ruby
puts "Creating BreakEscape missions..."

# List all scenario directories
scenario_dirs = Dir.glob(Rails.root.join('app/assets/scenarios/*')).select { |f| File.directory?(f) }

scenario_dirs.each do |dir|
  scenario_name = File.basename(dir)
  next if scenario_name == 'common'  # Skip common directory if it exists

  # Create mission metadata
  mission = BreakEscape::Mission.find_or_initialize_by(name: scenario_name)

  if mission.new_record?
    mission.display_name = scenario_name.titleize
    mission.description = "Play the #{scenario_name.titleize} scenario"
    mission.published = true
    mission.difficulty_level = 3  # Default, can be updated later
    mission.save!
    puts "  ✓ Created: #{mission.display_name}"
  else
    puts "  - Exists: #{mission.display_name}"
  end
end

puts "Done! Created #{BreakEscape::Mission.count} missions."
```

**Save and close**

### 5.2 Run Seeds

```bash
# Run seeds
rails db:seed

# Verify missions created
rails runner "puts BreakEscape::Mission.pluck(:name, :display_name)"
```

**Expected output:** List of missions created

### 5.3 Test ERB Generation

```bash
# Start Rails console
rails console

# Test full flow
mission = BreakEscape::Mission.first
puts "Testing: #{mission.display_name}"

scenario_data = mission.generate_scenario_data
puts "✓ Scenario data generated (#{scenario_data.keys.length} keys)"
puts "  Start room: #{scenario_data['startRoom']}"

# Check for randomization
if scenario_data.to_s.include?('random_password')
  puts "✗ ERROR: ERB variable not replaced!"
else
  puts "✓ ERB variables replaced"
end

exit
```

**Expected output:** Scenario generated successfully, no ERB variables in output

### 5.4 Commit

```bash
git add -A
git commit -m "feat: Add seed file for mission metadata

- Create missions from scenario directories
- Auto-discover scenarios in app/assets/scenarios/
- Simple metadata only (no scenario data in DB)
- Scenario data generated on-demand via ERB"

git push
```

---

## Phase 6: Controllers and Routes (Week 4-5, ~12 hours)

**This phase is long - broken into sub-phases**

### 6.1 Generate Controllers

```bash
# Generate main controllers
rails generate controller break_escape/missions index show
rails generate controller break_escape/games show

# Generate API controller
mkdir -p app/controllers/break_escape/api
rails generate controller break_escape/api/games --skip-routes
```

### 6.2 Configure Routes

```bash
vim config/routes.rb
```

**Replace entire contents with:**

```ruby
BreakEscape::Engine.routes.draw do
  # Mission selection
  resources :missions, only: [:index, :show]

  # Game management
  resources :games, only: [:show, :create] do
    member do
      # Scenario and NPC data
      get 'scenario'  # Returns scenario_data JSON
      get 'ink'       # Returns NPC script (JIT compiled)

      # API endpoints
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

**Save and close**

### 6.3 Test Routes

```bash
# List routes
rails routes | grep break_escape

# Should see:
# - missions_path
# - mission_path
# - games_path
# - game_path
# - scenario_game_path
# - ink_game_path
# - bootstrap_game_path
# - etc.
```

**Expected output:** Routes listed successfully

### 6.4 Edit ApplicationController

```bash
vim app/controllers/break_escape/application_controller.rb
```

**Replace entire contents with:**

```ruby
module BreakEscape
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    # Include Pundit if available
    include Pundit::Authorization if defined?(Pundit)

    # Helper method to get current player (polymorphic)
    def current_player
      if BreakEscape.standalone_mode?
        # Standalone mode - get/create demo user
        @current_player ||= DemoUser.first_or_create!(handle: 'demo_player')
      else
        # Mounted mode - use Hacktivity's current_user
        current_user
      end
    end
    helper_method :current_player

    # Handle authorization errors
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end
end
```

**Save and close**

### 6.5 Edit MissionsController

```bash
vim app/controllers/break_escape/missions_controller.rb
```

**Replace entire contents with:**

```ruby
module BreakEscape
  class MissionsController < ApplicationController
    def index
      @missions = if defined?(Pundit)
                    policy_scope(Mission)
                  else
                    Mission.published
                  end
    end

    def show
      @mission = Mission.find(params[:id])
      authorize @mission if defined?(Pundit)

      # Create or find game instance for current player
      @game = Game.find_or_create_by!(
        player: current_player,
        mission: @mission
      )

      redirect_to game_path(@game)
    end
  end
end
```

**Save and close**

### 6.6 Edit GamesController

```bash
vim app/controllers/break_escape/games_controller.rb
```

**Replace entire contents with:**

```ruby
require 'open3'

module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :scenario, :ink]

    def show
      authorize @game if defined?(Pundit)
      @mission = @game.mission
    end

    # GET /games/:id/scenario
    # Returns scenario JSON for this game instance
    def scenario
      authorize @game if defined?(Pundit)
      render json: @game.scenario_data
    end

    # GET /games/:id/ink?npc=helper1
    # Returns NPC script (JIT compiled if needed)
    def ink
      authorize @game if defined?(Pundit)

      npc_id = params[:npc]
      return render_error('Missing npc parameter', :bad_request) unless npc_id.present?

      # Find NPC in scenario data
      npc = find_npc_in_scenario(npc_id)
      return render_error('NPC not found in scenario', :not_found) unless npc

      # Resolve ink file path and compile if needed
      ink_json_path = resolve_and_compile_ink(npc['storyPath'])
      return render_error('Ink script not found', :not_found) unless ink_json_path && File.exist?(ink_json_path)

      # Serve compiled JSON
      render json: JSON.parse(File.read(ink_json_path))
    rescue JSON::ParserError => e
      render_error("Invalid JSON in compiled ink: #{e.message}", :internal_server_error)
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

    # Resolve ink path and compile if necessary
    def resolve_and_compile_ink(story_path)
      base_path = Rails.root.join(story_path)
      json_path = find_compiled_json(base_path)
      ink_path = find_ink_source(base_path)

      if ink_path && needs_compilation?(ink_path, json_path)
        Rails.logger.info "[BreakEscape] Compiling #{File.basename(ink_path)}..."
        json_path = compile_ink(ink_path)
      end

      json_path
    end

    def find_compiled_json(base_path)
      return base_path if File.exist?(base_path)

      ink_json_path = base_path.to_s.gsub(/\.json$/, '.ink.json')
      return Pathname.new(ink_json_path) if File.exist?(ink_json_path)

      json_path = base_path.to_s.gsub(/\.ink\.json$/, '.json')
      return Pathname.new(json_path) if File.exist?(json_path)

      nil
    end

    def find_ink_source(base_path)
      ink_path = base_path.to_s.gsub(/\.(ink\.)?json$/, '.ink')
      File.exist?(ink_path) ? Pathname.new(ink_path) : nil
    end

    def needs_compilation?(ink_path, json_path)
      return true unless json_path && File.exist?(json_path)
      File.mtime(ink_path) > File.mtime(json_path)
    end

    def compile_ink(ink_path)
      output_path = ink_path.to_s.gsub(/\.ink$/, '.json')
      inklecate_path = Rails.root.join('bin', 'inklecate')

      stdout, stderr, status = Open3.capture3(
        inklecate_path.to_s,
        '-o', output_path,
        ink_path.to_s
      )

      unless status.success?
        Rails.logger.error "[BreakEscape] Ink compilation failed: #{stderr}"
        raise "Ink compilation failed for #{File.basename(ink_path)}: #{stderr}"
      end

      if stderr.present?
        Rails.logger.warn "[BreakEscape] Ink compilation warnings: #{stderr}"
      end

      Rails.logger.info "[BreakEscape] Compiled #{File.basename(ink_path)} (#{(File.size(output_path) / 1024.0).round(2)} KB)"

      Pathname.new(output_path)
    end

    def render_error(message, status)
      render json: { error: message }, status: status
    end
  end
end
```

**Save and close**

### 6.7 Edit API GamesController

```bash
vim app/controllers/break_escape/api/games_controller.rb
```

**Replace entire contents with:**

```ruby
module BreakEscape
  module Api
    class GamesController < ApplicationController
      before_action :set_game

      # GET /games/:id/bootstrap
      # Initial game data for client
      def bootstrap
        authorize @game if defined?(Pundit)

        render json: {
          gameId: @game.id,
          missionName: @game.mission.display_name,
          startRoom: @game.scenario_data['startRoom'],
          playerState: @game.player_state,
          roomLayout: build_room_layout
        }
      end

      # PUT /games/:id/sync_state
      # Periodic state sync from client
      def sync_state
        authorize @game if defined?(Pundit)

        # Update allowed fields
        if params[:currentRoom]
          @game.player_state['currentRoom'] = params[:currentRoom]
        end

        if params[:globalVariables]
          @game.update_global_variables!(params[:globalVariables].to_unsafe_h)
        end

        @game.save!

        render json: { success: true }
      end

      # POST /games/:id/unlock
      # Validate unlock attempt
      def unlock
        authorize @game if defined?(Pundit)

        target_type = params[:targetType]
        target_id = params[:targetId]
        attempt = params[:attempt]
        method = params[:method]

        is_valid = @game.validate_unlock(target_type, target_id, attempt, method)

        if is_valid
          if target_type == 'door'
            @game.unlock_room!(target_id)
            room_data = @game.filtered_room_data(target_id)

            render json: {
              success: true,
              type: 'door',
              roomData: room_data
            }
          else
            @game.unlock_object!(target_id)
            render json: {
              success: true,
              type: 'object'
            }
          end
        else
          render json: {
            success: false,
            message: 'Invalid attempt'
          }, status: :unprocessable_entity
        end
      end

      # POST /games/:id/inventory
      # Update inventory
      def inventory
        authorize @game if defined?(Pundit)

        action = params[:action]
        item = params[:item]

        case action
        when 'add'
          @game.add_inventory_item!(item.to_unsafe_h)
          render json: { success: true, inventory: @game.player_state['inventory'] }
        when 'remove'
          @game.remove_inventory_item!(item['id'])
          render json: { success: true, inventory: @game.player_state['inventory'] }
        else
          render json: { success: false, message: 'Invalid action' }, status: :bad_request
        end
      end

      private

      def set_game
        @game = Game.find(params[:id])
      end

      def build_room_layout
        layout = {}
        @game.scenario_data['rooms'].each do |room_id, room_data|
          layout[room_id] = {
            connections: room_data['connections'],
            locked: room_data['locked'] || false
          }
        end
        layout
      end
    end
  end
end
```

**Save and close**

### 6.8 Test Controllers

```bash
# Start Rails server
rails server

# In another terminal, test endpoints
# (Assuming you have a game with id=1)

# Test scenario endpoint
curl http://localhost:3000/break_escape/games/1/scenario

# Test bootstrap endpoint
curl http://localhost:3000/break_escape/games/1/bootstrap
```

**Expected output:** JSON responses (may get auth errors if Pundit enabled, that's fine for now)

### 6.9 Commit

```bash
git add -A
git commit -m "feat: Add controllers and routes

- Add MissionsController for scenario selection
- Add GamesController with scenario/ink endpoints
- Add JIT Ink compilation logic
- Add API::GamesController for game state management
- Configure routes with REST + API endpoints
- Add authorization hooks (Pundit)"

git push
```

---

**Continue to Phase 7 in next section...**

---

## Progress Tracking

Use this checklist to track your progress:

- [ ] Phase 1: Setup Rails Engine (8 hours)
- [ ] Phase 2: Move Game Files (4 hours)
- [ ] Phase 3: Create Scenario Templates (6 hours)
- [ ] Phase 4: Database Setup (6 hours)
- [ ] Phase 5: Seed Data (2 hours)
- [ ] Phase 6: Controllers and Routes (12 hours)
- [ ] Phase 7: Policies (4 hours)
- [ ] Phase 8: Views (6 hours)
- [ ] Phase 9: Client Integration (12 hours)
- [ ] Phase 10: Testing (8 hours)
- [ ] Phase 11: Standalone Mode (4 hours)
- [ ] Phase 12: Deployment (6 hours)

**Total: ~78 hours over 10-12 weeks**

---

## Continued in Part 2

This document contains Phases 1-6. Continue with the next document for:
- Phase 7: Policies
- Phase 8: Views
- Phase 9: Client Integration
- Phase 10: Testing
- Phase 11: Standalone Mode
- Phase 12: Deployment

See `03_IMPLEMENTATION_PLAN_PART2.md` for continuation.
