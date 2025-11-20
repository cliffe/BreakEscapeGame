# Testing Guide

Complete testing strategy for BreakEscape Rails Engine.

---

## Testing Philosophy

### What We Test

✅ **Models** - Validations, methods, business logic
✅ **Controllers** - HTTP responses, authorization, API contracts
✅ **Policies** - Authorization rules
✅ **Integration** - Full user flows end-to-end
✅ **ERB Generation** - Scenario template processing
✅ **JIT Compilation** - Ink compilation logic

### What We Don't Test

❌ **Client-side JavaScript** - That's Phaser's domain
❌ **Phaser game logic** - Would require browser automation
❌ **CSS styling** - Visual testing not in scope

---

## Test Framework

**Framework:** Minitest (matches Hacktivity)
**Style:** Test::Unit with fixtures
**Coverage Goal:** 80%+ for critical paths

### Why Minitest?

- Matches Hacktivity's testing framework
- Simpler than RSpec
- Fast execution
- Built into Rails
- Fixture-based (good for game state)

---

## Running Tests

### All Tests

```bash
# Run entire test suite
rails test

# With coverage
COVERAGE=true rails test
```

### Specific Files

```bash
# Run model tests
rails test test/models/

# Run controller tests
rails test test/controllers/

# Run specific file
rails test test/models/break_escape/mission_test.rb

# Run specific test
rails test test/models/break_escape/mission_test.rb:5
```

### Watch Mode

```bash
# Install guard
gem install guard-minitest

# Run guard
guard
```

---

## Test Structure

### Directory Layout

```
test/
├── fixtures/
│   └── break_escape/
│       ├── missions.yml
│       ├── games.yml
│       └── demo_users.yml
├── models/
│   └── break_escape/
│       ├── mission_test.rb
│       └── game_test.rb
├── controllers/
│   └── break_escape/
│       ├── missions_controller_test.rb
│       ├── games_controller_test.rb
│       └── api/
│           └── games_controller_test.rb
├── policies/
│   └── break_escape/
│       ├── mission_policy_test.rb
│       └── game_policy_test.rb
├── integration/
│   └── break_escape/
│       ├── game_flow_test.rb
│       └── api_test.rb
└── test_helper.rb
```

---

## Fixtures

### Mission Fixtures

```yaml
# test/fixtures/break_escape/missions.yml
ceo_exfil:
  name: ceo_exfil
  display_name: CEO Exfiltration
  description: Test scenario for CEO infiltration
  published: true
  difficulty_level: 3

cybok_heist:
  name: cybok_heist
  display_name: CybOK Heist
  description: Test scenario for CybOK
  published: true
  difficulty_level: 4

unpublished:
  name: test_unpublished
  display_name: Unpublished Test
  description: Not visible to players
  published: false
  difficulty_level: 1
```

### Demo User Fixtures

```yaml
# test/fixtures/break_escape/demo_users.yml
test_user:
  handle: test_user
  role: user

admin_user:
  handle: admin_user
  role: admin

other_user:
  handle: other_user
  role: user
```

### Game Fixtures

```yaml
# test/fixtures/break_escape/games.yml
active_game:
  player: test_user (BreakEscape::DemoUser)
  mission: ceo_exfil
  scenario_data:
    startRoom: reception
    rooms:
      reception:
        type: room_reception
        connections:
          north: office
        locked: false
      office:
        type: room_office
        connections:
          south: reception
        locked: true
        requires: "test_password"
  player_state:
    currentRoom: reception
    unlockedRooms:
      - reception
    unlockedObjects: []
    inventory: []
    encounteredNPCs: []
    globalVariables: {}
    biometricSamples: []
    bluetoothDevices: []
    notes: []
    health: 100
  status: in_progress
  score: 0

completed_game:
  player: test_user (BreakEscape::DemoUser)
  mission: cybok_heist
  scenario_data:
    startRoom: entrance
    rooms: {}
  player_state:
    currentRoom: exit
    unlockedRooms: []
    inventory: []
    health: 100
  status: completed
  score: 100
```

---

## Model Tests

### Mission Model Tests

```ruby
# test/models/break_escape/mission_test.rb
require 'test_helper'

module BreakEscape
  class MissionTest < ActiveSupport::TestCase
    test "should require name" do
      mission = Mission.new(display_name: 'Test')
      assert_not mission.valid?
      assert mission.errors[:name].any?
    end

    test "should require display_name" do
      mission = Mission.new(name: 'test')
      assert_not mission.valid?
      assert mission.errors[:display_name].any?
    end

    test "should require unique name" do
      Mission.create!(name: 'test', display_name: 'Test')
      duplicate = Mission.new(name: 'test', display_name: 'Test 2')
      assert_not duplicate.valid?
      assert duplicate.errors[:name].include?('has already been taken')
    end

    test "should validate difficulty_level range" do
      mission = Mission.new(name: 'test', display_name: 'Test', difficulty_level: 10)
      assert_not mission.valid?
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

    test "generate_scenario_data processes ERB and returns JSON" do
      skip "Requires actual scenario ERB file" unless File.exist?(missions(:ceo_exfil).scenario_path.join('scenario.json.erb'))

      mission = missions(:ceo_exfil)
      scenario_data = mission.generate_scenario_data

      assert scenario_data.is_a?(Hash)
      assert scenario_data['startRoom']
      assert scenario_data['rooms']

      # Should not contain ERB tags
      json_string = scenario_data.to_json
      assert_not json_string.include?('<%=')
      assert_not json_string.include?('random_password')
    end

    test "generate_scenario_data raises error for invalid JSON" do
      # Would need to create a bad ERB file to test
      skip "Requires bad scenario file"
    end
  end
end
```

### Game Model Tests

```ruby
# test/models/break_escape/game_test.rb
require 'test_helper'

module BreakEscape
  class GameTest < ActiveSupport::TestCase
    setup do
      @game = games(:active_game)
    end

    test "should belong to player and mission" do
      assert @game.player
      assert_instance_of DemoUser, @game.player
      assert @game.mission
      assert_instance_of Mission, @game.mission
    end

    test "should require player" do
      @game.player = nil
      assert_not @game.valid?
      assert @game.errors[:player].any?
    end

    test "should require mission" do
      @game.mission = nil
      assert_not @game.valid?
      assert @game.errors[:mission].any?
    end

    test "should validate status inclusion" do
      @game.status = 'invalid'
      assert_not @game.valid?
      assert @game.errors[:status].any?
    end

    test "should unlock room" do
      @game.unlock_room!('office')
      assert_includes @game.player_state['unlockedRooms'], 'office'
    end

    test "should not duplicate unlocked rooms" do
      @game.unlock_room!('office')
      @game.unlock_room!('office')
      assert_equal 1, @game.player_state['unlockedRooms'].count('office')
    end

    test "room_unlocked? returns true for start room" do
      assert @game.room_unlocked?('reception')
    end

    test "room_unlocked? returns true for unlocked rooms" do
      @game.unlock_room!('office')
      assert @game.room_unlocked?('office')
    end

    test "room_unlocked? returns false for locked rooms" do
      assert_not @game.room_unlocked?('office')
    end

    test "should unlock object" do
      @game.unlock_object!('safe_123')
      assert_includes @game.player_state['unlockedObjects'], 'safe_123'
    end

    test "should add inventory item" do
      item = { 'type' => 'key', 'name' => 'Test Key' }
      @game.add_inventory_item!(item)
      assert_includes @game.player_state['inventory'], item
    end

    test "should remove inventory item" do
      item = { 'id' => 'key_1', 'type' => 'key', 'name' => 'Test Key' }
      @game.add_inventory_item!(item)
      @game.remove_inventory_item!('key_1')
      assert_not_includes @game.player_state['inventory'], item
    end

    test "should encounter NPC" do
      @game.encounter_npc!('security_guard')
      assert_includes @game.player_state['encounteredNPCs'], 'security_guard'
    end

    test "should update global variables" do
      @game.update_global_variables!({ 'alarm' => true, 'favor' => 5 })
      assert_equal true, @game.player_state['globalVariables']['alarm']
      assert_equal 5, @game.player_state['globalVariables']['favor']
    end

    test "should merge global variables" do
      @game.player_state['globalVariables'] = { 'existing' => 'value' }
      @game.update_global_variables!({ 'new' => 'value2' })
      assert_equal 'value', @game.player_state['globalVariables']['existing']
      assert_equal 'value2', @game.player_state['globalVariables']['new']
    end

    test "should add biometric sample" do
      sample = { 'type' => 'fingerprint', 'data' => 'base64...' }
      @game.add_biometric_sample!(sample)
      assert_includes @game.player_state['biometricSamples'], sample
    end

    test "should add bluetooth device" do
      device = { 'mac' => 'AA:BB:CC:DD:EE:FF', 'name' => 'Phone' }
      @game.add_bluetooth_device!(device)
      assert_includes @game.player_state['bluetoothDevices'], device
    end

    test "should not duplicate bluetooth devices" do
      device = { 'mac' => 'AA:BB:CC:DD:EE:FF', 'name' => 'Phone' }
      @game.add_bluetooth_device!(device)
      @game.add_bluetooth_device!(device)
      assert_equal 1, @game.player_state['bluetoothDevices'].length
    end

    test "should add note" do
      note = { 'id' => 'note_1', 'title' => 'Test', 'content' => 'Content' }
      @game.add_note!(note)
      assert_includes @game.player_state['notes'], note
    end

    test "should update health" do
      @game.update_health!(50)
      assert_equal 50, @game.player_state['health']
    end

    test "should clamp health to 0-100" do
      @game.update_health!(150)
      assert_equal 100, @game.player_state['health']

      @game.update_health!(-10)
      assert_equal 0, @game.player_state['health']
    end

    test "should get room data" do
      room_data = @game.room_data('office')
      assert_equal 'room_office', room_data['type']
    end

    test "should filter room data" do
      room_data = @game.filtered_room_data('office')
      assert_nil room_data['requires']
      assert_nil room_data['lockType']
    end

    test "should validate password unlock" do
      result = @game.validate_unlock('door', 'office', 'test_password', 'password')
      assert result
    end

    test "should reject invalid password" do
      result = @game.validate_unlock('door', 'office', 'wrong', 'password')
      assert_not result
    end

    test "should accept lockpick" do
      result = @game.validate_unlock('door', 'office', '', 'lockpick')
      assert result
    end

    test "active scope returns in_progress games" do
      assert_includes Game.active, games(:active_game)
      assert_not_includes Game.active, games(:completed_game)
    end

    test "completed scope returns completed games" do
      assert_includes Game.completed, games(:completed_game)
      assert_not_includes Game.completed, games(:active_game)
    end

    test "should initialize player state on create" do
      game = Game.create!(
        player: demo_users(:test_user),
        mission: missions(:ceo_exfil)
      )

      assert game.player_state['currentRoom']
      assert game.player_state['unlockedRooms'].include?(game.scenario_data['startRoom'])
      assert_equal 100, game.player_state['health']
    end

    test "should generate scenario data on create" do
      game = Game.create!(
        player: demo_users(:test_user),
        mission: missions(:cybok_heist)
      )

      assert game.scenario_data
      assert game.scenario_data['startRoom']
      assert game.scenario_data['rooms']
    end

    test "should set started_at on create" do
      game = Game.create!(
        player: demo_users(:test_user),
        mission: missions(:ceo_exfil)
      )

      assert game.started_at
      assert game.started_at <= Time.current
    end
  end
end
```

---

## Controller Tests

### Missions Controller Tests

```ruby
# test/controllers/break_escape/missions_controller_test.rb
require 'test_helper'

module BreakEscape
  class MissionsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get missions_url
      assert_response :success
    end

    test "index should show published missions" do
      get missions_url
      assert_response :success
      # Would need to parse HTML to verify, or use system tests
    end

    test "should redirect to game when showing mission" do
      mission = missions(:ceo_exfil)

      # Simulate being logged in (would use Devise helpers in real app)
      # For now, testing with standalone mode
      get mission_url(mission)

      assert_response :redirect
      assert_match /games\/\d+/, @response.location
    end
  end
end
```

### Games Controller Tests

```ruby
# test/controllers/break_escape/games_controller_test.rb
require 'test_helper'

module BreakEscape
  class GamesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @game = games(:active_game)
    end

    test "should get show" do
      # Would need authentication setup
      get game_url(@game)
      assert_response :success
    end

    test "should get scenario JSON" do
      get scenario_game_url(@game), as: :json
      assert_response :success

      json = JSON.parse(@response.body)
      assert json['startRoom']
      assert json['rooms']
    end

    test "should get ink script" do
      skip "Requires ink file setup"

      get ink_game_url(@game, npc: 'security_guard'), as: :json
      assert_response :success

      json = JSON.parse(@response.body)
      assert json.is_a?(Hash)
    end

    test "ink endpoint should return 400 without npc parameter" do
      get ink_game_url(@game), as: :json
      assert_response :bad_request

      json = JSON.parse(@response.body)
      assert_equal 'Missing npc parameter', json['error']
    end
  end
end
```

### API Games Controller Tests

```ruby
# test/controllers/break_escape/api/games_controller_test.rb
require 'test_helper'

module BreakEscape
  module Api
    class GamesControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        @game = games(:active_game)
      end

      test "should get bootstrap" do
        get bootstrap_game_url(@game), as: :json
        assert_response :success

        json = JSON.parse(@response.body)
        assert_equal @game.id, json['gameId']
        assert json['missionName']
        assert json['startRoom']
        assert json['playerState']
        assert json['roomLayout']
      end

      test "should sync state" do
        put sync_state_game_url(@game), params: {
          currentRoom: 'office',
          globalVariables: { alarm: true }
        }, as: :json

        assert_response :success

        @game.reload
        assert_equal 'office', @game.player_state['currentRoom']
        assert_equal true, @game.player_state['globalVariables']['alarm']
      end

      test "should validate unlock with correct password" do
        post unlock_game_url(@game), params: {
          targetType: 'door',
          targetId: 'office',
          attempt: 'test_password',
          method: 'password'
        }, as: :json

        assert_response :success

        json = JSON.parse(@response.body)
        assert json['success']
        assert_equal 'door', json['type']
        assert json['roomData']
      end

      test "should reject unlock with wrong password" do
        post unlock_game_url(@game), params: {
          targetType: 'door',
          targetId: 'office',
          attempt: 'wrong',
          method: 'password'
        }, as: :json

        assert_response :unprocessable_entity

        json = JSON.parse(@response.body)
        assert_not json['success']
      end

      test "should add inventory item" do
        post inventory_game_url(@game), params: {
          action: 'add',
          item: { type: 'key', name: 'Test Key' }
        }, as: :json

        assert_response :success

        json = JSON.parse(@response.body)
        assert json['success']
        assert json['inventory'].any? { |i| i['name'] == 'Test Key' }
      end

      test "should remove inventory item" do
        @game.add_inventory_item!({ 'id' => 'key_1', 'type' => 'key' })

        post inventory_game_url(@game), params: {
          action: 'remove',
          item: { id: 'key_1' }
        }, as: :json

        assert_response :success

        json = JSON.parse(@response.body)
        assert json['success']
        assert_not json['inventory'].any? { |i| i['id'] == 'key_1' }
      end
    end
  end
end
```

---

## Policy Tests

```ruby
# test/policies/break_escape/game_policy_test.rb
require 'test_helper'

module BreakEscape
  class GamePolicyTest < ActiveSupport::TestCase
    setup do
      @user = demo_users(:test_user)
      @admin = demo_users(:admin_user)
      @other_user = demo_users(:other_user)
      @game = games(:active_game)
    end

    test "owner can show game" do
      policy = GamePolicy.new(@user, @game)
      assert policy.show?
    end

    test "other user cannot show game" do
      policy = GamePolicy.new(@other_user, @game)
      assert_not policy.show?
    end

    test "admin can show any game" do
      policy = GamePolicy.new(@admin, @game)
      assert policy.show?
    end

    test "scope returns user's games" do
      scope = GamePolicy::Scope.new(@user, Game).resolve
      assert_includes scope, @game
    end

    test "scope returns all games for admin" do
      scope = GamePolicy::Scope.new(@admin, Game).resolve
      assert_equal Game.count, scope.count
    end
  end
end

# test/policies/break_escape/mission_policy_test.rb
require 'test_helper'

module BreakEscape
  class MissionPolicyTest < ActiveSupport::TestCase
    setup do
      @user = demo_users(:test_user)
      @admin = demo_users(:admin_user)
      @published = missions(:ceo_exfil)
      @unpublished = missions(:unpublished)
    end

    test "anyone can view index" do
      policy = MissionPolicy.new(@user, Mission)
      assert policy.index?
    end

    test "anyone can view published mission" do
      policy = MissionPolicy.new(@user, @published)
      assert policy.show?
    end

    test "user cannot view unpublished mission" do
      policy = MissionPolicy.new(@user, @unpublished)
      assert_not policy.show?
    end

    test "admin can view unpublished mission" do
      policy = MissionPolicy.new(@admin, @unpublished)
      assert policy.show?
    end

    test "scope returns only published for users" do
      scope = MissionPolicy::Scope.new(@user, Mission).resolve
      assert_includes scope, @published
      assert_not_includes scope, @unpublished
    end

    test "scope returns all missions for admin" do
      scope = MissionPolicy::Scope.new(@admin, Mission).resolve
      assert_equal Mission.count, scope.count
    end
  end
end
```

---

## Integration Tests

```ruby
# test/integration/break_escape/game_flow_test.rb
require 'test_helper'

module BreakEscape
  class GameFlowTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "complete game flow" do
      # 1. Visit mission list
      get missions_url
      assert_response :success

      # 2. Select mission (redirects to game)
      mission = missions(:ceo_exfil)
      get mission_url(mission)
      assert_response :redirect
      follow_redirect!

      # Extract game ID from redirect
      game_id = @response.location.match(/games\/(\d+)/)[1]
      game = Game.find(game_id)

      # 3. Bootstrap game
      get bootstrap_game_url(game), as: :json
      assert_response :success
      bootstrap_data = JSON.parse(@response.body)
      assert_equal game.id, bootstrap_data['gameId']

      # 4. Get scenario
      get scenario_game_url(game), as: :json
      assert_response :success
      scenario = JSON.parse(@response.body)
      assert scenario['rooms']

      # 5. Attempt unlock
      post unlock_game_url(game), params: {
        targetType: 'door',
        targetId: 'office',
        attempt: 'test_password',
        method: 'password'
      }, as: :json
      assert_response :success
      unlock_result = JSON.parse(@response.body)
      assert unlock_result['success']

      # 6. Sync state
      put sync_state_game_url(game), params: {
        currentRoom: 'office',
        globalVariables: { progress: 50 }
      }, as: :json
      assert_response :success

      # 7. Verify state persisted
      game.reload
      assert_equal 'office', game.player_state['currentRoom']
      assert game.room_unlocked?('office')
    end
  end
end
```

---

## Test Helpers

```ruby
# test/test_helper.rb
ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def json_response
    JSON.parse(@response.body)
  end

  # Simulate standalone mode
  def enable_standalone_mode
    BreakEscape.configuration.standalone_mode = true
  end

  def disable_standalone_mode
    BreakEscape.configuration.standalone_mode = false
  end
end
```

---

## Coverage

### Setup SimpleCov

```ruby
# Gemfile
group :test do
  gem 'simplecov', require: false
end

# test/test_helper.rb (at the very top)
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/test/'
    add_filter '/config/'
    add_filter '/vendor/'

    add_group 'Models', 'app/models'
    add_group 'Controllers', 'app/controllers'
    add_group 'Policies', 'app/policies'
  end
end
```

### Run with Coverage

```bash
COVERAGE=true rails test
open coverage/index.html
```

---

## Continuous Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0
          bundler-cache: true

      - name: Setup database
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/break_escape_test
        run: |
          bundle exec rails db:create
          bundle exec rails db:migrate

      - name: Run tests
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/break_escape_test
        run: bundle exec rails test
```

---

## Best Practices

### Do

✅ Test one thing per test
✅ Use descriptive test names
✅ Use fixtures for game state
✅ Test both success and failure cases
✅ Test edge cases (empty inventory, max health, etc.)
✅ Test authorization (who can access what)
✅ Use setup/teardown for common setup
✅ Mock external dependencies if any

### Don't

❌ Test framework internals (Rails, Phaser)
❌ Test CSS or JavaScript (that's system test territory)
❌ Write flaky tests (time-dependent, order-dependent)
❌ Test implementation details
❌ Duplicate tests

---

## Summary

**Test Coverage:**
- ✅ 2 models (Mission, Game)
- ✅ 3 controllers (Missions, Games, API::Games)
- ✅ 2 policies (Mission, Game)
- ✅ Integration tests for full flow
- ✅ Fixtures for all models
- ✅ CI/CD ready

**Run tests:**
```bash
rails test
```

**With coverage:**
```bash
COVERAGE=true rails test
```

All tests should pass before merging to main!
