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
        scenario_data: { "startRoom" => "reception", "rooms" => {} },
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
      assert_select '#break-escape-game'
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

    test "bootstrap endpoint should return game state" do
      get bootstrap_game_url(@game)
      assert_response :success
      assert_equal 'application/json', @response.media_type

      json = JSON.parse(@response.body)
      assert_equal @game.id, json['gameId']
      assert_equal 'reception', json['startRoom']
      assert json['playerState']
      assert_equal 'reception', json['playerState']['currentRoom']
      assert_includes json['playerState']['unlockedRooms'], 'reception'
      assert_equal 100, json['playerState']['health']
    end

    test "sync_state should update player state" do
      put sync_state_game_url(@game), params: {
        currentRoom: 'office'
      }

      assert_response :success
      json = JSON.parse(@response.body)
      assert json['success']

      @game.reload
      assert_equal 'office', @game.player_state['currentRoom']
    end

    test "unlock endpoint should reject invalid attempts" do
      post unlock_game_url(@game), params: {
        targetType: 'room',
        targetId: 'office',
        attempt: 'wrong_code',
        method: 'keypad'
      }

      assert_response :unprocessable_entity
      json = JSON.parse(@response.body)
      assert_equal false, json['success']
      assert_equal 'Invalid attempt', json['message']
    end

    test "inventory endpoint should add items" do
      post inventory_game_url(@game), params: {
        action_type: 'add',
        item: { type: 'key', name: 'Test Key', id: 'test_key' }
      }

      assert_response :success
      json = JSON.parse(@response.body)
      assert json['success']
      assert_equal 1, json['inventory'].length

      @game.reload
      assert_equal 1, @game.player_state['inventory'].length
    end
  end
end
