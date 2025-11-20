# BreakEscape - Testing Guide

## Testing Strategy

Follow Hacktivity patterns:
- **Fixtures** for test data
- **Integration tests** for workflows
- **Model tests** for business logic
- **Policy tests** for authorization

---

## Running Tests

```bash
# All tests
rails test

# Specific test file
rails test test/models/break_escape/game_instance_test.rb

# Specific test
rails test test/models/break_escape/game_instance_test.rb:10

# With coverage
rails test:coverage  # If configured
```

---

## Test Structure

```
test/
├── fixtures/
│   ├── break_escape/
│   │   ├── scenarios.yml
│   │   ├── npc_scripts.yml
│   │   ├── game_instances.yml
│   │   └── demo_users.yml
│   └── files/
│       └── test_scenarios/
│           └── minimal_scenario.json
│
├── models/
│   └── break_escape/
│       ├── scenario_test.rb
│       ├── game_instance_test.rb
│       └── npc_script_test.rb
│
├── controllers/
│   └── break_escape/
│       ├── games_controller_test.rb
│       └── api/
│           ├── games_controller_test.rb
│           └── rooms_controller_test.rb
│
├── integration/
│   └── break_escape/
│       ├── game_flow_test.rb
│       └── api_flow_test.rb
│
└── policies/
    └── break_escape/
        ├── game_instance_policy_test.rb
        └── scenario_policy_test.rb
```

---

## Fixtures

### Scenarios

```yaml
# test/fixtures/break_escape/scenarios.yml
minimal:
  name: minimal
  display_name: Minimal Test Scenario
  description: Simple scenario for testing
  published: true
  difficulty_level: 1
  scenario_data: <%= File.read(Rails.root.join('test/fixtures/files/test_scenarios/minimal_scenario.json')) %>

advanced:
  name: advanced
  display_name: Advanced Test Scenario
  published: false
  difficulty_level: 5
  scenario_data: <%= File.read(Rails.root.join('test/fixtures/files/test_scenarios/advanced_scenario.json')) %>
```

### Game Instances

```yaml
# test/fixtures/break_escape/game_instances.yml
active_game:
  player: demo_player (DemoUser)
  scenario: minimal
  status: in_progress
  player_state:
    currentRoom: room_start
    position: {x: 0, y: 0}
    unlockedRooms: [room_start]
    unlockedObjects: []
    inventory: []
    encounteredNPCs: []
    globalVariables: {}

completed_game:
  player: demo_player (DemoUser)
  scenario: minimal
  status: completed
  completed_at: <%= 1.day.ago %>
  score: 100
```

### Demo Users

```yaml
# test/fixtures/break_escape/demo_users.yml
demo_player:
  handle: demo_player
  role: user

pro_player:
  handle: pro_player
  role: pro

admin_player:
  handle: admin_player
  role: admin
```

---

## Model Tests

```ruby
# test/models/break_escape/game_instance_test.rb
require 'test_helper'

module BreakEscape
  class GameInstanceTest < ActiveSupport::TestCase
    setup do
      @game = break_escape_game_instances(:active_game)
    end

    test "initializes with start room unlocked" do
      scenario = break_escape_scenarios(:minimal)
      game = GameInstance.create!(
        player: break_escape_demo_users(:demo_player),
        scenario: scenario
      )

      assert game.room_unlocked?(scenario.start_room)
      assert_includes game.player_state['unlockedRooms'], scenario.start_room
    end

    test "can unlock rooms" do
      @game.unlock_room!('room_office')

      assert @game.room_unlocked?('room_office')
      assert_includes @game.player_state['unlockedRooms'], 'room_office'
    end

    test "can add inventory items" do
      item = {'type' => 'key', 'name' => 'Test Key', 'key_id' => 'test_1'}

      @game.add_inventory_item!(item)

      assert_equal 1, @game.player_state['inventory'].length
      assert_equal 'Test Key', @game.player_state['inventory'].first['name']
    end

    test "can track encountered NPCs" do
      @game.encounter_npc!('guard_1')

      assert @game.npc_encountered?('guard_1')
      assert_includes @game.player_state['encounteredNPCs'], 'guard_1'
    end

    test "validates status values" do
      @game.status = 'invalid_status'

      assert_not @game.valid?
      assert_includes @game.errors[:status], 'is not included in the list'
    end
  end
end
```

```ruby
# test/models/break_escape/scenario_test.rb
require 'test_helper'

module BreakEscape
  class ScenarioTest < ActiveSupport::TestCase
    setup do
      @scenario = break_escape_scenarios(:minimal)
    end

    test "filters room data to remove solutions" do
      room_data = @scenario.filtered_room_data('room_office')

      assert_nil room_data['requires']
      assert_nil room_data['lockType']

      # Objects should also be filtered
      room_data['objects']&.each do |obj|
        assert_nil obj['requires']
        assert_nil obj['lockType'] if obj['locked']
      end
    end

    test "validates unlock attempts" do
      # Valid password
      assert @scenario.validate_unlock('door', 'room_office', 'correct_password', 'password')

      # Invalid password
      assert_not @scenario.validate_unlock('door', 'room_office', 'wrong_password', 'password')

      # Valid key
      assert @scenario.validate_unlock('door', 'room_vault', 'vault_key_123', 'key')
    end

    test "scopes published scenarios" do
      assert_includes Scenario.published, @scenario
      assert_not_includes Scenario.published, break_escape_scenarios(:advanced)
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

    setup do
      @scenario = break_escape_scenarios(:minimal)
      @user = break_escape_demo_users(:demo_player)
    end

    test "complete game flow" do
      # 1. View scenarios
      get scenarios_path
      assert_response :success
      assert_select '.scenario', minimum: 1

      # 2. Select scenario (creates game instance)
      get scenario_path(@scenario)
      assert_response :redirect

      game = GameInstance.find_by(player: @user, scenario: @scenario)
      assert_not_nil game

      # 3. View game
      get game_path(game)
      assert_response :success
      assert_select 'div#break-escape-game'

      # 4. Bootstrap via API
      get bootstrap_api_game_path(game), as: :json
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal game.id, json['gameId']
      assert_equal @scenario.start_room, json['startRoom']
      assert json['playerState']
      assert json['roomLayout']

      # 5. Attempt unlock
      post unlock_api_game_path(game), params: {
        targetType: 'door',
        targetId: 'room_office',
        method: 'password',
        attempt: 'admin123'
      }, as: :json

      assert_response :success
      json = JSON.parse(response.body)
      assert json['success']
      assert json['roomData']

      # 6. Load room
      get api_game_room_path(game, 'room_office'), as: :json
      assert_response :success

      # 7. Load NPC script
      get script_api_game_npc_path(game, 'guard_1'), as: :json
      assert_response :success

      json = JSON.parse(response.body)
      assert_equal 'guard_1', json['npcId']
      assert json['inkScript']
    end

    test "cannot access locked room" do
      game = break_escape_game_instances(:active_game)

      get api_game_room_path(game, 'locked_room'), as: :json
      assert_response :forbidden
    end

    test "invalid unlock attempt fails" do
      game = break_escape_game_instances(:active_game)

      post unlock_api_game_path(game), params: {
        targetType: 'door',
        targetId: 'room_office',
        method: 'password',
        attempt: 'wrong_password'
      }, as: :json

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_not json['success']
    end
  end
end
```

---

## Policy Tests

```ruby
# test/policies/break_escape/game_instance_policy_test.rb
require 'test_helper'

module BreakEscape
  class GameInstancePolicyTest < ActiveSupport::TestCase
    setup do
      @owner = break_escape_demo_users(:demo_player)
      @other_user = break_escape_demo_users(:pro_player)
      @admin = break_escape_demo_users(:admin_player)
      @game = break_escape_game_instances(:active_game)
    end

    test "owner can view own game" do
      policy = GameInstancePolicy.new(@owner, @game)
      assert policy.show?
    end

    test "other user cannot view game" do
      policy = GameInstancePolicy.new(@other_user, @game)
      assert_not policy.show?
    end

    test "admin can view any game" do
      policy = GameInstancePolicy.new(@admin, @game)
      assert policy.show?
    end

    test "owner can update own game" do
      policy = GameInstancePolicy.new(@owner, @game)
      assert policy.update?
    end

    test "scope returns only user's games" do
      scope = GameInstancePolicy::Scope.new(@owner, GameInstance.all).resolve

      assert_includes scope, @game
      # If other games exist for other users, they should not be included
    end
  end
end
```

---

## Test Helpers

```ruby
# test/test_helper.rb
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml
  fixtures :all

  # Helper methods
  def json_response
    JSON.parse(response.body)
  end

  def assert_jsonb_includes(jsonb_column, expected_hash)
    assert jsonb_column.to_h.deep_symbolize_keys >= expected_hash.deep_symbolize_keys
  end
end
```

---

## Coverage

```bash
# If SimpleCov is configured
rails test
open coverage/index.html
```

---

## Continuous Integration

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

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
          bundler-cache: true

      - name: Setup database
        run: |
          bin/rails db:setup
          bin/rails db:migrate

      - name: Run tests
        run: bin/rails test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

---

## Manual Testing Checklist

- [ ] Game loads in standalone mode
- [ ] Can select scenario
- [ ] Game view renders
- [ ] Bootstrap API works
- [ ] Can unlock door with correct password
- [ ] Cannot unlock with wrong password
- [ ] Can load unlocked room
- [ ] Cannot load locked room
- [ ] Can load NPC script after encounter
- [ ] Inventory updates work
- [ ] State syncs to server
- [ ] Game persists across page refresh
