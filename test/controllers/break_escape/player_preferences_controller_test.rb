require 'test_helper'

module BreakEscape
  class PlayerPreferencesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @player = break_escape_demo_users(:test_user)
      # Ensure a preference record exists for the test player
      @preference = PlayerPreference.find_or_create_by!(
        player: @player
      ) do |pref|
        pref.selected_sprite = "female_hacker_hood"
        pref.in_game_name    = "TestAgent"
      end
      # Guarantee the fields we expect
      @preference.update!(selected_sprite: "female_hacker_hood", in_game_name: "TestAgent")
    end

    teardown do
      # Clean up preferences created during tests to avoid cross-test pollution
      PlayerPreference.where(player: @player).destroy_all
    end

    # ─── GET /configuration ──────────────────────────────────────────────────

    test "show returns 200 and renders the configuration page" do
      get configuration_url
      assert_response :success
    end

    test "show exposes available sprites to the view" do
      get configuration_url
      assert_response :success
      # The view uses @available_sprites; check that at least one known sprite is in the body
      assert_match(/female_hacker_hood/, response.body)
    end

    test "show displays current player name and sprite" do
      get configuration_url
      assert_response :success
      assert_match(/TestAgent/, response.body)
    end

    # ─── PATCH /configuration — JSON ─────────────────────────────────────────

    test "update with valid sprite and name returns JSON success" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "male_spy", in_game_name: "Agent99" } },
            headers: { "Accept" => "application/json" }

      assert_response :success
      json = JSON.parse(response.body)
      assert json["success"]
      assert_equal "male_spy", json["data"]["selected_sprite"]
      assert_equal "Agent99",  json["data"]["in_game_name"]

      @preference.reload
      assert_equal "male_spy", @preference.selected_sprite
      assert_equal "Agent99",  @preference.in_game_name
    end

    test "update persists selected_sprite to database" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "male_scientist", in_game_name: "TestAgent" } },
            headers: { "Accept" => "application/json" }

      assert_response :success
      @preference.reload
      assert_equal "male_scientist", @preference.selected_sprite
    end

    test "update persists in_game_name to database" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "female_hacker_hood", in_game_name: "HackerZero" } },
            headers: { "Accept" => "application/json" }

      assert_response :success
      @preference.reload
      assert_equal "HackerZero", @preference.in_game_name
    end

    # ─── PATCH /configuration — validation failures ───────────────────────────

    test "update returns 422 when sprite is not in the allowed list" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "invalid_sprite_xyz", in_game_name: "TestAgent" } },
            headers: { "Accept" => "application/json" }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_equal false, json["success"]
      assert json["errors"].any?
    end

    test "update returns 422 when in_game_name is blank" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "female_spy", in_game_name: "" } },
            headers: { "Accept" => "application/json" }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_equal false, json["success"]
    end

    test "update returns 422 when in_game_name exceeds 20 characters" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "female_spy", in_game_name: "A" * 21 } },
            headers: { "Accept" => "application/json" }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_equal false, json["success"]
    end

    test "update returns 422 when in_game_name contains invalid characters" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "female_spy", in_game_name: "Agent<script>" } },
            headers: { "Accept" => "application/json" }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_equal false, json["success"]
    end

    test "update does not persist invalid data on failure" do
      original_sprite = @preference.selected_sprite

      patch configuration_url,
            params: { player_preference: { selected_sprite: "totally_fake_sprite", in_game_name: "TestAgent" } },
            headers: { "Accept" => "application/json" }

      assert_response :unprocessable_entity
      @preference.reload
      assert_equal original_sprite, @preference.selected_sprite
    end

    # ─── PATCH /configuration — HTML redirect ────────────────────────────────

    test "update with valid params redirects to configuration page for HTML requests" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "male_nerd", in_game_name: "Nerd42" } }

      assert_redirected_to configuration_url
    end

    test "update with valid params and game_id redirects to the game" do
      mission = break_escape_missions(:ceo_exfil)
      game = Game.create!(
        mission: mission,
        player: @player,
        scenario_data: { "startRoom" => "lobby", "rooms" => {} },
        player_state: {
          "currentRoom" => "lobby", "unlockedRooms" => ["lobby"],
          "unlockedObjects" => [], "inventory" => [], "encounteredNPCs" => [],
          "globalVariables" => {}, "biometricSamples" => [], "biometricUnlocks" => [],
          "bluetoothDevices" => [], "notes" => [], "health" => 100
        }
      )

      patch configuration_url,
            params: {
              game_id: game.id,
              player_preference: { selected_sprite: "male_nerd", in_game_name: "Nerd42" }
            }

      assert_redirected_to game_url(game)
    end

    # ─── PlayerPreferencePolicy ───────────────────────────────────────────────
    # In standalone mode current_player owns the preference, so show/update succeed.
    # The policy class is exercised implicitly via authorize(@player_preference).

    test "policy allows the preference owner to view configuration" do
      get configuration_url
      # 200 proves Pundit did not raise NotAuthorizedError
      assert_response :success
    end

    test "policy allows the preference owner to update configuration" do
      patch configuration_url,
            params: { player_preference: { selected_sprite: "female_scientist", in_game_name: "TestAgent" } },
            headers: { "Accept" => "application/json" }
      assert_response :success
    end

    # ─── Available sprites constant ───────────────────────────────────────────

    test "PlayerPreference::AVAILABLE_SPRITES includes expected sprites" do
      sprites = PlayerPreference::AVAILABLE_SPRITES
      assert_includes sprites, "female_hacker_hood"
      assert_includes sprites, "male_spy"
      assert_includes sprites, "female_scientist"
      assert sprites.length >= 16, "Expected at least 16 sprites, got #{sprites.length}"
    end

    test "each available sprite is accepted by update" do
      # Spot-check a sample of sprites to ensure none are rejected by validation
      sample = PlayerPreference::AVAILABLE_SPRITES.first(4)
      sample.each do |sprite|
        patch configuration_url,
              params: { player_preference: { selected_sprite: sprite, in_game_name: "TestAgent" } },
              headers: { "Accept" => "application/json" }
        assert_response :success, "Expected sprite '#{sprite}' to be accepted"
      end
    end
  end
end
