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
  end
end
