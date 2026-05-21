require 'test_helper'

module BreakEscape
  class GameTest < ActiveSupport::TestCase
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

    test "should belong to player and mission" do
      assert @game.player
      assert @game.mission
    end

    test "should unlock room" do
      @game.unlock_room!('office')
      assert @game.room_unlocked?('office')
    end

    test "should track inventory" do
      item = { 'type' => 'key', 'name' => 'Test Key' }
      @game.add_inventory_item!(item)
      assert_includes @game.player_state['inventory'], item
    end

    test "should update health" do
      @game.update_health!(50)
      assert_equal 50, @game.player_state['health']
    end

    test "should clamp health between 0 and 100" do
      @game.update_health!(150)
      assert_equal 100, @game.player_state['health']

      @game.update_health!(-10)
      assert_equal 0, @game.player_state['health']
    end

    # Tests for key-based door unlock
    test "should validate unlock with correct key" do
      @game.scenario_data = {
        "rooms" => {
          "office1" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "office1_key"
          }
        }
      }
      @game.player_state['inventory'] = [
        { 'type' => 'key', 'key_id' => 'office1_key', 'name' => 'Office Key' }
      ]

      result = @game.validate_unlock('door', 'office1', '', 'key')
      assert result, "Should unlock door with correct key in inventory"
    end

    test "should reject unlock without required key" do
      @game.scenario_data = {
        "rooms" => {
          "office1" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "office1_key"
          }
        }
      }
      @game.player_state['inventory'] = [
        { 'type' => 'key', 'key_id' => 'wrong_key', 'name' => 'Wrong Key' }
      ]

      result = @game.validate_unlock('door', 'office1', '', 'key')
      assert_not result, "Should reject unlock without required key"
    end

    test "should reject locked door without any unlock method" do
      @game.scenario_data = {
        "rooms" => {
          "office1" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "office1_key"
          }
        }
      }
      @game.player_state['inventory'] = []

      result = @game.validate_unlock('door', 'office1', '', nil)
      assert_not result, "Should reject locked door without unlock method"
    end

    # Tests for lockpick-based door unlock
    test "should validate unlock with lockpick" do
      @game.scenario_data = {
        "rooms" => {
          "office1" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "office1_key"
          }
        }
      }
      @game.player_state['inventory'] = [
        { 'type' => 'lockpick', 'name' => 'Lock Pick Kit' }
      ]

      result = @game.validate_unlock('door', 'office1', '', 'lockpick')
      assert result, "Should unlock door with lockpick"
    end

    test "should reject lockpick unlock without lockpick in inventory" do
      @game.scenario_data = {
        "rooms" => {
          "office1" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "office1_key"
          }
        }
      }
      @game.player_state['inventory'] = [
        { 'type' => 'key', 'key_id' => 'office1_key', 'name' => 'Office Key' }
      ]

      result = @game.validate_unlock('door', 'office1', '', 'lockpick')
      assert_not result, "Should reject lockpick unlock without lockpick in inventory"
    end

    # Tests for combined scenarios
    test "lockpick should bypass key requirement" do
      @game.scenario_data = {
        "rooms" => {
          "secure_vault" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "vault_master_key"
          }
        }
      }
      @game.player_state['inventory'] = [
        { 'type' => 'lockpick', 'name' => 'Lock Pick Kit' }
      ]

      # Should succeed with lockpick even without the master key
      result = @game.validate_unlock('door', 'secure_vault', '', 'lockpick')
      assert result, "Lockpick should bypass specific key requirement"
    end

    test "key takes precedence over lockpick attempt" do
      @game.scenario_data = {
        "rooms" => {
          "office1" => {
            "locked" => true,
            "lockType" => "key",
            "requires" => "office1_key"
          }
        }
      }
      @game.player_state['inventory'] = [
        { 'type' => 'key', 'key_id' => 'office1_key', 'name' => 'Office Key' },
        { 'type' => 'lockpick', 'name' => 'Lock Pick Kit' }
      ]

      # Key unlock should succeed
      result = @game.validate_unlock('door', 'office1', '', 'key')
      assert result, "Key unlock should succeed"
    end

    test "should allow access to unlocked doors regardless of method" do
      @game.scenario_data = {
        "rooms" => {
          "reception" => {
            "locked" => false
          }
        }
      }
      @game.player_state['inventory'] = []

      result = @game.validate_unlock('door', 'reception', '', 'unlocked')
      assert result, "Should allow access to unlocked doors"
    end

    test "has_key_in_inventory should find keys by key_id" do
      @game.player_state['inventory'] = [
        { 'type' => 'key', 'key_id' => 'office1_key', 'name' => 'Office Key' }
      ]

      assert @game.has_key_in_inventory?('office1_key'), "Should find key by key_id"
      assert_not @game.has_key_in_inventory?('wrong_key'), "Should not find missing key"
    end

    test "has_lockpick_in_inventory should find lockpicks" do
      @game.player_state['inventory'] = [
        { 'type' => 'lockpick', 'name' => 'Lock Pick Kit' }
      ]

      assert @game.has_lockpick_in_inventory?, "Should find lockpick in inventory"
    end

    test "has_lockpick_in_inventory should not find non-lockpick items" do
      @game.player_state['inventory'] = [
        { 'type' => 'key', 'key_id' => 'office1_key', 'name' => 'Office Key' }
      ]

      assert_not @game.has_lockpick_in_inventory?, "Should not find non-lockpick items as lockpick"
    end

    # ─── vm_set_id column sync ─────────────────────────────────────────────────
    # Use @other_player to avoid colliding with @game (same player+mission is blocked
    # by the unique partial index on in_progress games).

    test "sync_vm_set_id_column populates vm_set_id from player_state on before_create" do
      other_player = break_escape_demo_users(:other_user)
      game = Game.new(
        mission:       @mission,
        player:        other_player,
        scenario_data: { "startRoom" => "reception", "rooms" => {} },
        player_state:  {
          "currentRoom" => "reception", "unlockedRooms" => ["reception"],
          "unlockedObjects" => [], "inventory" => [], "encounteredNPCs" => [],
          "globalVariables" => {}, "biometricSamples" => [], "biometricUnlocks" => [],
          "bluetoothDevices" => [], "notes" => [], "health" => 100,
          "vm_set_id" => 42
        }
      )
      game.save!
      assert_equal 42, game.vm_set_id
    end

    test "sync_vm_set_id_column does not overwrite vm_set_id if already set" do
      other_player = break_escape_demo_users(:other_user)
      game = Game.new(
        mission:       @mission,
        player:        other_player,
        scenario_data: { "startRoom" => "reception", "rooms" => {} },
        player_state:  {
          "currentRoom" => "reception", "unlockedRooms" => ["reception"],
          "unlockedObjects" => [], "inventory" => [], "encounteredNPCs" => [],
          "globalVariables" => {}, "biometricSamples" => [], "biometricUnlocks" => [],
          "bluetoothDevices" => [], "notes" => [], "health" => 100,
          "vm_set_id" => 99
        }
      )
      game.vm_set_id = 7
      game.save!
      assert_equal 7, game.vm_set_id
    end

    test "sync_vm_set_id_column leaves vm_set_id nil when player_state has no vm_set_id" do
      other_player = break_escape_demo_users(:other_user)
      game = Game.new(
        mission:       @mission,
        player:        other_player,
        scenario_data: { "startRoom" => "reception", "rooms" => {} },
        player_state:  {
          "currentRoom" => "reception", "unlockedRooms" => ["reception"],
          "unlockedObjects" => [], "inventory" => [], "encounteredNPCs" => [],
          "globalVariables" => {}, "biometricSamples" => [], "biometricUnlocks" => [],
          "bluetoothDevices" => [], "notes" => [], "health" => 100
        }
      )
      game.save!
      assert_nil game.vm_set_id
    end

    # ─── on_game_complete hook ─────────────────────────────────────────────────

    test "fire_completion_callback delegates to on_game_complete hook" do
      called_with = nil
      BreakEscape.configuration.on_game_complete = ->(game) { called_with = game }

      @game.send(:fire_completion_callback)

      assert_equal @game, called_with
    ensure
      BreakEscape.configuration.on_game_complete = nil
    end

    test "status_previously_changed_to_completed? is true after status changes to completed" do
      @game.update!(status: 'completed', completed_at: Time.current)
      assert @game.send(:status_previously_changed_to_completed?)
    end

    test "fire_completion_callback is NOT called when status changes to abandoned" do
      called = false
      BreakEscape.configuration.on_game_complete = ->(_game) { called = true }

      @game.update!(status: 'abandoned')

      assert_not called
    ensure
      BreakEscape.configuration.on_game_complete = nil
    end

    test "fire_completion_callback is NOT called when other attributes change" do
      called = false
      BreakEscape.configuration.on_game_complete = ->(_game) { called = true }

      @game.update!(score: 50)

      assert_not called
    ensure
      BreakEscape.configuration.on_game_complete = nil
    end

    test "a completion callback that raises does NOT prevent the game from being saved" do
      BreakEscape.configuration.on_game_complete = ->(_game) { raise "scoring error" }

      assert_nothing_raised do
        @game.update!(status: 'completed', completed_at: Time.current)
      end
      assert_equal 'completed', @game.reload.status
    ensure
      BreakEscape.configuration.on_game_complete = nil
    end

    test "nil on_game_complete config does not raise" do
      BreakEscape.configuration.on_game_complete = nil

      assert_nothing_raised do
        @game.update!(status: 'completed', completed_at: Time.current)
      end
    end
  end
end
