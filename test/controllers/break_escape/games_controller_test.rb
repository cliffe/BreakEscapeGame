require 'test_helper'

module BreakEscape
  class GamesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @mission = break_escape_missions(:ceo_exfil)
      @player = break_escape_demo_users(:test_user)
      @game = Game.create!(
        mission: @mission,
        player: @player,
        scenario_data: {
          "startRoom" => "reception",
          "startItemsInInventory" => [
            {
              "type" => "lockpick",
              "name" => "Lockpick",
              "id" => "lockpick_1",
              "takeable" => true
            }
          ],
          "rooms" => {
            "reception" => {
              "type" => "room_reception",
              "connections" => { "north" => "office" },
              "locked" => false,
              "objects" => []
            },
            "office" => {
              "type" => "office",
              "connections" => { "south" => "reception" },
              "locked" => true,
              "lockType" => "pin",
              "requires" => "1234",
              "objects" => []
            }
          }
        },
        player_state: {
          "currentRoom" => "reception",
          "unlockedRooms" => ["reception"],
          "unlockedObjects" => [],
          "inventory" => [],
          "encounteredNPCs" => [],
          "globalVariables" => {},
          "biometricSamples" => [],
          "biometricUnlocks" => [],
          "bluetoothDevices" => [],
          "notes" => [],
          "health" => 100
        }
      )
    end

    test "should show game" do
      get game_url(@game)
      assert_response :success
    end

    test "show should return HTML with game container" do
      get game_url(@game)
      assert_response :success
      assert_select '#game-container'
      assert_match /window\.breakEscapeConfig/, response.body
    end

    test "show should inject game configuration" do
      get game_url(@game)
      assert_response :success

      # Check that config is in the page
      assert_match /gameId.*#{@game.id}/, response.body
      assert_match /apiBasePath/, response.body
      assert_match /csrfToken/, response.body
    end

    test "scenario endpoint should return JSON" do
      get scenario_game_url(@game)
      assert_response :success
      assert_equal 'application/json', @response.media_type

      json = JSON.parse(@response.body)
      assert json['startRoom']
      assert json['rooms']
    end

    test "sync_state should update player state for current room" do
      put sync_state_game_url(@game), params: {
        currentRoom: 'reception'
      }

      assert_response :success
      json = JSON.parse(@response.body)
      assert json['success']

      @game.reload
      assert_equal 'reception', @game.player_state['currentRoom']
    end

    test "unlock endpoint should reject invalid attempts" do
      post unlock_game_url(@game), params: {
        targetType: 'room',
        targetId: 'office',
        attempt: 'wrong_code',
        method: 'pin'
      }

      assert_response :unprocessable_entity
      json = JSON.parse(@response.body)
      assert_equal false, json['success']
      assert_equal 'Invalid attempt', json['message']
    end

    test "game setup has correct scenario data" do
      # Verify the test setup is correct before running unlock tests
      assert @game.scenario_data['rooms']['office'].present?
      office = @game.scenario_data['rooms']['office']
      assert_equal true, office['locked']
      assert_equal 'pin', office['lockType']
      assert_equal '1234', office['requires']
    end

    test "unlock endpoint should accept correct pin code" do
      # Debug: Check scenario before making request
      assert @game.scenario_data['rooms']['office']['requires'] == '1234',
        "Office room should require PIN 1234, but requires: #{@game.scenario_data['rooms']['office']['requires']}"

      post unlock_game_url(@game), params: {
        targetType: 'door',
        targetId: 'office',
        attempt: '1234',
        method: 'pin'
      }

      assert_response :success,
        "Expected 200, got #{@response.status}. Response: #{response.body}"
      json = JSON.parse(@response.body)
      assert json['success'], "Response success should be true: #{json}"
      assert_equal 'door', json['type']
      assert json['roomData']

      @game.reload
      assert_includes @game.player_state['unlockedRooms'], 'office'
    end

    test "inventory endpoint should add items" do
      # Create a test scenario that doesn't include the lockpick in starting items
      @game.scenario_data['startItemsInInventory'] = []
      @game.scenario_data['rooms']['reception']['objects'] = [
        {
          "id" => "note_1",
          "type" => "note",
          "name" => "Test Note",
          "takeable" => true
        }
      ]
      @game.player_state['inventory'] = []
      @game.save!

      post inventory_game_url(@game), params: {
        action_type: 'add',
        item: { type: 'note', name: 'Test Note', id: 'note_1' }
      }

      assert_response :success
      json = JSON.parse(@response.body)
      assert json['success']
      assert_equal 1, json['inventory'].length

      @game.reload
      assert_equal 1, @game.player_state['inventory'].length
    end

    # Ink endpoint tests
    test "ink endpoint should require npc parameter" do
      get ink_game_url(@game)
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_includes json['error'], 'npc'
    end

    test "ink endpoint should return 404 for non-existent NPC" do
      get ink_game_url(@game), params: { npc: 'non-existent' }
      assert_response :not_found
    end

    test "ink endpoint should return 404 for NPC without story file" do
      # Game doesn't have NPCs with story files by default
      get ink_game_url(@game), params: { npc: 'missing-npc' }
      assert_response :not_found
    end

    # ─── Security: flag answers must never reach the client ──────────────────

    SECRET_FLAGS = ["FLAG{s3cr3t_v4lu3}", "FLAG{4n0th3r_fl4g}"].freeze

    def game_with_flag_objectives
      Game.create!(
        mission:       @mission,
        player:        @player,
        scenario_data: @game.scenario_data.merge(
          "objectives" => [
            {
              "aimId" => "capture_flag",
              "title" => "Capture the Flag",
              "tasks" => [
                {
                  "taskId"      => "submit_flag_1",
                  "type"        => "submit_flags",
                  "title"       => "Submit the CTF flag",
                  "targetFlags" => SECRET_FLAGS
                }
              ]
            }
          ]
        ),
        player_state: @game.player_state.dup
      )
    end

    test "SECURITY: scenario endpoint does not expose targetFlags" do
      game = game_with_flag_objectives
      get scenario_game_url(game)
      assert_response :success

      body = response.body
      SECRET_FLAGS.each do |flag|
        assert_not body.include?(flag),
          "SECURITY: scenario endpoint must not leak flag answer '#{flag}'"
      end

      json = JSON.parse(body)
      json["objectives"]&.each do |aim|
        aim["tasks"]&.each do |task|
          assert_nil task["targetFlags"],
            "targetFlags must be absent from /scenario response (task: #{task['taskId']})"
        end
      end
    end

    test "SECURITY: objectives endpoint does not expose targetFlags" do
      game = game_with_flag_objectives
      get objectives_game_url(game)
      assert_response :success

      body = response.body
      SECRET_FLAGS.each do |flag|
        assert_not body.include?(flag),
          "SECURITY: objectives endpoint must not leak flag answer '#{flag}'"
      end

      json = JSON.parse(body)
      json["objectives"]&.each do |aim|
        aim["tasks"]&.each do |task|
          assert_nil task["targetFlags"],
            "targetFlags must be absent from /objectives response (task: #{task['taskId']})"
        end
      end
    end

    test "SECURITY: scenario endpoint strips targetFlags but preserves other task fields" do
      game = game_with_flag_objectives
      get scenario_game_url(game)
      assert_response :success

      json = JSON.parse(response.body)
      task = json["objectives"]&.first&.dig("tasks", 0)
      assert task, "Task should be present in objectives"
      assert_equal "submit_flag_1", task["taskId"]
      assert_equal "submit_flags",  task["type"]
      assert_equal "Submit the CTF flag", task["title"]
      assert_nil task["targetFlags"], "targetFlags must be stripped"
    end

    test "SECURITY: requires field is absent from scenario response for pin-locked rooms" do
      get scenario_game_url(@game)
      assert_response :success

      json = JSON.parse(response.body)
      office = json.dig("rooms", "office")
      assert office, "Office room should be present in scenario"
      assert_nil office["requires"],
        "SECURITY: 'requires' (PIN answer) must not be sent to the client for pin-locked rooms"
    end
  end
end
