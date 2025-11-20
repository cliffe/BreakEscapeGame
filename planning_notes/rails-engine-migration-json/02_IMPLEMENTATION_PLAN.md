# BreakEscape Rails Engine - Implementation Plan

## Overview

This is the **actionable TODO list** for converting BreakEscape to a Rails Engine.

**Key Principles:**
- ✅ Use `bash mv` commands to move files (don't copy/rewrite)
- ✅ Use `rails generate` and `rails db:migrate` commands
- ✅ Make manual edits only after generating files
- ✅ Test after each phase
- ✅ Commit after each working step

**Estimated Time:** 12-14 weeks

---

## Phase 1: Setup Rails Engine Structure (Week 1)

### Prerequisites

```bash
# Ensure you're in the project directory
cd /home/user/BreakEscape

# Create feature branch
git checkout -b rails-engine-migration

# Commit current state
git add -A
git commit -m "chore: Checkpoint before Rails Engine migration"
```

### 1.1 Generate Rails Engine

```bash
# Generate mountable engine (creates isolated namespace)
rails plugin new . --mountable --skip-git --dummy-path=test/dummy

# This creates:
# - lib/break_escape/engine.rb
# - lib/break_escape/version.rb
# - app/ directory structure
# - config/routes.rb
# - test/ directory structure
```

**Manual edits after generation:**

```ruby
# lib/break_escape/engine.rb
module BreakEscape
  class Engine < ::Rails::Engine
    isolate_namespace BreakEscape

    config.generators do |g|
      g.test_framework :test_unit, fixture: true
      g.assets false
      g.helper false
    end

    # Load lib directory
    config.autoload_paths << File.expand_path('lib', __dir__)

    # Pundit authorization
    config.after_initialize do
      BreakEscape::ApplicationController.send(:include, Pundit::Authorization) if defined?(Pundit)
    end

    # Static files from public/break_escape
    config.middleware.use ::ActionDispatch::Static, "#{root}/public"
  end
end
```

```ruby
# lib/break_escape/version.rb
module BreakEscape
  VERSION = '0.1.0'
end
```

**Update Gemfile:**

```ruby
# Gemfile
source 'https://rubygems.org'

gemspec

# Development dependencies
group :development, :test do
  gem 'sqlite3'
  gem 'pry'
  gem 'pry-byebug'
end

# Runtime dependencies
gem 'rails', '~> 7.0'
gem 'pundit', '~> 2.3'
```

**Update gemspec:**

```ruby
# break_escape.gemspec
require_relative "lib/break_escape/version"

Gem::Specification.new do |spec|
  spec.name        = "break_escape"
  spec.version     = BreakEscape::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.summary     = "BreakEscape escape room game engine"
  spec.description = "Rails engine for BreakEscape escape room cybersecurity training game"
  spec.license     = "MIT"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "pundit", "~> 2.3"
end
```

**Install dependencies:**

```bash
bundle install
```

**Commit:**

```bash
git add -A
git commit -m "feat: Generate Rails Engine structure"
```

---

## Phase 2: Move Game Files to public/ (Week 1)

### 2.1 Create public directory structure

```bash
# Create directory
mkdir -p public/break_escape

# Move existing game files (USING MV, NOT COPY!)
mv js public/break_escape/
mv css public/break_escape/
mv assets public/break_escape/

# Keep index.html for reference (but we'll use Rails view)
cp index.html public/break_escape/index.html.backup
```

**Verify files moved correctly:**

```bash
ls -la public/break_escape/
# Should see: js/ css/ assets/ index.html.backup
```

**Update .gitignore if needed:**

```bash
# .gitignore should NOT ignore public/break_escape/
# Verify:
git check-ignore public/break_escape/js/
# Should return nothing (not ignored)
```

**Commit:**

```bash
git add -A
git commit -m "refactor: Move game files to public/break_escape/"
```

---

## Phase 3: Reorganize Scenarios (Week 1-2)

### 3.1 Create scenario directory structure

```bash
# Create app/assets/scenarios structure
mkdir -p app/assets/scenarios/common/ink

# List current scenarios
ls scenarios/*.json
```

### 3.2 Reorganize each scenario

**For EACH scenario (ceo_exfil, cybok_heist, etc.):**

```bash
# Example for ceo_exfil:
SCENARIO="ceo_exfil"

# Create directory
mkdir -p "app/assets/scenarios/${SCENARIO}/ink"

# Move scenario JSON and rename to .erb
mv "scenarios/${SCENARIO}.json" "app/assets/scenarios/${SCENARIO}/scenario.json.erb"

# Move NPC Ink files
# Find all ink files referenced in the scenario
# Example:
mv "scenarios/ink/security_guard.ink" "app/assets/scenarios/${SCENARIO}/ink/"
mv "scenarios/ink/security_guard.ink.json" "app/assets/scenarios/${SCENARIO}/ink/"

# Repeat for each NPC in the scenario
```

**For common/shared Ink files:**

```bash
# If any ink files are used by multiple scenarios:
mv scenarios/ink/shared_*.ink app/assets/scenarios/common/ink/
mv scenarios/ink/shared_*.ink.json app/assets/scenarios/common/ink/
```

**Manual process (document what you do):**

Create a file to track the reorganization:

```bash
# scenarios/REORGANIZATION_LOG.md
# Document which files went where
# Example:
# ceo_exfil:
#   - scenarios/ceo_exfil.json → app/assets/scenarios/ceo_exfil/scenario.json.erb
#   - scenarios/ink/security_guard.* → app/assets/scenarios/ceo_exfil/ink/
# ...
```

**Remove old scenarios directory (after verification):**

```bash
# ONLY after verifying all files moved:
rm -rf scenarios/

# Or keep for reference:
mv scenarios scenarios.backup
```

**Commit:**

```bash
git add -A
git commit -m "refactor: Reorganize scenarios into app/assets/scenarios/"
```

---

## Phase 4: Database Setup (Week 2)

### 4.1 Generate migrations

```bash
# Generate Scenarios table
rails generate migration CreateBreakEscapeScenarios

# Generate NpcScripts table
rails generate migration CreateBreakEscapeNpcScripts

# Generate GameInstances table
rails generate migration CreateBreakEscapeGameInstances
```

**Edit generated migrations:**

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

```ruby
# db/migrate/xxx_create_break_escape_npc_scripts.rb
class CreateBreakEscapeNpcScripts < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_npc_scripts do |t|
      t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }
      t.string :npc_id, null: false
      t.text :ink_source
      t.text :ink_compiled, null: false

      t.timestamps
    end

    add_index :break_escape_npc_scripts, [:scenario_id, :npc_id], unique: true
  end
end
```

```ruby
# db/migrate/xxx_create_break_escape_game_instances.rb
class CreateBreakEscapeGameInstances < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_game_instances do |t|
      # Polymorphic player
      t.references :player, polymorphic: true, null: false

      # Scenario reference
      t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }

      # Player state (JSONB)
      t.jsonb :player_state, null: false, default: {
        currentRoom: nil,
        position: { x: 0, y: 0 },
        unlockedRooms: [],
        unlockedObjects: [],
        inventory: [],
        encounteredNPCs: [],
        globalVariables: {}
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

**Run migrations:**

```bash
rails db:migrate
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add database schema for scenarios, NPCs, and game instances"
```

### 4.2 Generate models

```bash
# Generate model files (skeleton only, we'll edit them)
rails generate model Scenario --skip-migration
rails generate model NpcScript --skip-migration
rails generate model GameInstance --skip-migration
```

**Edit models:**

```ruby
# app/models/break_escape/scenario.rb
module BreakEscape
  class Scenario < ApplicationRecord
    self.table_name = 'break_escape_scenarios'

    has_many :game_instances, class_name: 'BreakEscape::GameInstance'
    has_many :npc_scripts, class_name: 'BreakEscape::NpcScript'

    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true
    validates :scenario_data, presence: true

    scope :published, -> { where(published: true) }

    def start_room
      scenario_data['startRoom']
    end

    def start_room?(room_id)
      start_room == room_id
    end

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

    def validate_unlock(target_type, target_id, attempt, method)
      if target_type == 'door'
        room = room_data(target_id)
        return false unless room
        return false unless room['locked']

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
          next unless object
          next unless object['locked']

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
  end
end
```

```ruby
# app/models/break_escape/npc_script.rb
module BreakEscape
  class NpcScript < ApplicationRecord
    self.table_name = 'break_escape_npc_scripts'

    belongs_to :scenario, class_name: 'BreakEscape::Scenario'

    validates :npc_id, presence: true
    validates :ink_compiled, presence: true
    validates :npc_id, uniqueness: { scope: :scenario_id }
  end
end
```

```ruby
# app/models/break_escape/game_instance.rb
module BreakEscape
  class GameInstance < ApplicationRecord
    self.table_name = 'break_escape_game_instances'

    # Polymorphic association
    belongs_to :player, polymorphic: true
    belongs_to :scenario, class_name: 'BreakEscape::Scenario'

    validates :player, presence: true
    validates :scenario, presence: true
    validates :status, inclusion: { in: %w[in_progress completed abandoned] }

    scope :active, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }

    before_create :set_started_at
    before_create :initialize_player_state

    # State management methods
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

    def remove_inventory_item!(item_id)
      player_state['inventory'] ||= []
      player_state['inventory'].reject! { |item| item['id'] == item_id }
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

    def update_position!(x, y)
      player_state['position'] = { 'x' => x, 'y' => y }
      save!
    end

    def update_global_variable!(key, value)
      player_state['globalVariables'] ||= {}
      player_state['globalVariables'][key] = value
      save!
    end

    private

    def set_started_at
      self.started_at ||= Time.current
    end

    def initialize_player_state
      self.player_state ||= {}
      self.player_state['currentRoom'] ||= scenario.start_room
      self.player_state['unlockedRooms'] ||= [scenario.start_room]
      self.player_state['position'] ||= { 'x' => 0, 'y' => 0 }
      self.player_state['inventory'] ||= []
      self.player_state['unlockedObjects'] ||= []
      self.player_state['encounteredNPCs'] ||= []
      self.player_state['globalVariables'] ||= {}
    end
  end
end
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add Scenario, NpcScript, and GameInstance models"
```

---

## Phase 5: Scenario Import (Week 2)

### 5.1 Create scenario loader service

```bash
mkdir -p lib/break_escape
```

**Create loader:**

```ruby
# lib/break_escape/scenario_loader.rb
module BreakEscape
  class ScenarioLoader
    attr_reader :scenario_name

    def initialize(scenario_name)
      @scenario_name = scenario_name
    end

    def load
      # Load and process ERB template
      template_path = Rails.root.join('app/assets/scenarios', scenario_name, 'scenario.json.erb')
      raise "Scenario not found: #{scenario_name}" unless File.exist?(template_path)

      erb = ERB.new(File.read(template_path))
      binding_context = ScenarioBinding.new

      JSON.parse(erb.result(binding_context.get_binding))
    end

    def import!
      scenario_data = load

      scenario = Scenario.find_or_initialize_by(name: scenario_name)
      scenario.assign_attributes(
        display_name: scenario_data['scenarioName'] || scenario_name.titleize,
        description: scenario_data['scenarioBrief'],
        scenario_data: scenario_data,
        published: true
      )
      scenario.save!

      # Import NPC scripts
      import_npc_scripts!(scenario, scenario_data)

      scenario
    end

    private

    def import_npc_scripts!(scenario, scenario_data)
      npcs = scenario_data['npcs'] || []

      npcs.each do |npc_data|
        npc_id = npc_data['id']

        # Load Ink files
        ink_path = Rails.root.join('app/assets/scenarios', scenario_name, 'ink', "#{npc_id}.ink")
        ink_json_path = Rails.root.join('app/assets/scenarios', scenario_name, 'ink', "#{npc_id}.ink.json")

        next unless File.exist?(ink_json_path)

        npc_script = scenario.npc_scripts.find_or_initialize_by(npc_id: npc_id)
        npc_script.ink_source = File.read(ink_path) if File.exist?(ink_path)
        npc_script.ink_compiled = File.read(ink_json_path)
        npc_script.save!
      end
    end

    # Binding context for ERB processing
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

### 5.2 Create seed file

```ruby
# db/seeds.rb
puts "Importing scenarios..."

scenarios = Dir.glob(Rails.root.join('app/assets/scenarios', '*')).map do |path|
  File.basename(path)
end.reject { |name| name == 'common' }

scenarios.each do |scenario_name|
  puts "  Importing #{scenario_name}..."
  begin
    loader = BreakEscape::ScenarioLoader.new(scenario_name)
    scenario = loader.import!
    puts "    ✓ #{scenario.display_name}"
  rescue => e
    puts "    ✗ Error: #{e.message}"
  end
end

puts "Done! Imported #{BreakEscape::Scenario.count} scenarios."
```

**Run seeds:**

```bash
rails db:seed
```

**Verify:**

```bash
rails console

# Check scenarios loaded
BreakEscape::Scenario.count
BreakEscape::Scenario.pluck(:name)

# Check NPC scripts
BreakEscape::NpcScript.count
```

**Commit:**

```bash
git add -A
git commit -m "feat: Add scenario loader and import seeds"
```

---

## Phase 6: Controllers and Routes (Week 3)

### 6.1 Generate controllers

```bash
# Main controllers
rails generate controller break_escape/games
rails generate controller break_escape/scenarios

# API controllers
rails generate controller break_escape/api/games
rails generate controller break_escape/api/rooms
rails generate controller break_escape/api/unlocks
rails generate controller break_escape/api/inventory
rails generate controller break_escape/api/npcs
```

**Edit routes:**

```ruby
# config/routes.rb
BreakEscape::Engine.routes.draw do
  # Main game view
  resources :games, only: [:show] do
    member do
      get :play
    end
  end

  # Scenario selection
  resources :scenarios, only: [:index, :show]

  # API endpoints
  namespace :api do
    resources :games, only: [] do
      member do
        get :bootstrap
        put :sync_state
        post :unlock
        post :inventory
      end

      resources :rooms, only: [:show]
      resources :npcs, only: [] do
        member do
          get :script
        end
      end
    end
  end

  root to: 'scenarios#index'
end
```

**Edit application controller:**

```ruby
# app/controllers/break_escape/application_controller.rb
module BreakEscape
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    # Pundit authorization
    include Pundit::Authorization if defined?(Pundit)

    # Helper method to get current player (polymorphic)
    def current_player
      if BreakEscape.configuration.standalone_mode
        # Standalone mode - get/create demo user
        @current_player ||= DemoUser.first_or_create!(
          handle: BreakEscape.configuration.demo_user['handle'],
          role: BreakEscape.configuration.demo_user['role']
        )
      else
        # Mounted mode - use Hacktivity's current_user
        current_user
      end
    end
    helper_method :current_player
  end
end
```

**Edit games controller:**

```ruby
# app/controllers/break_escape/games_controller.rb
module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game_instance

    def show
      @scenario = @game_instance.scenario
      authorize @game_instance if defined?(Pundit)
    end

    alias_method :play, :show

    private

    def set_game_instance
      @game_instance = GameInstance.find(params[:id])
    end
  end
end
```

**Edit scenarios controller:**

```ruby
# app/controllers/break_escape/scenarios_controller.rb
module BreakEscape
  class ScenariosController < ApplicationController
    def index
      @scenarios = if defined?(Pundit)
                     policy_scope(Scenario)
                   else
                     Scenario.published
                   end
    end

    def show
      @scenario = Scenario.find(params[:id])
      authorize @scenario if defined?(Pundit)

      # Create or find game instance
      @game_instance = GameInstance.find_or_create_by!(
        player: current_player,
        scenario: @scenario
      )

      redirect_to game_path(@game_instance)
    end
  end
end
```

**Continue with API controllers in next comment (file getting long)...**

---

## TO BE CONTINUED...

The implementation plan continues with:
- Phase 6 (continued): API Controllers
- Phase 7: Policies
- Phase 8: Views
- Phase 9: Client Integration
- Phase 10: Testing
- Phase 11: Standalone Mode
- Phase 12: Deployment

Each phase includes specific bash commands, rails generate commands, and code examples.

**This is Part 1 of the implementation plan.**

See **02_IMPLEMENTATION_PLAN_PART2.md** for continuation.
