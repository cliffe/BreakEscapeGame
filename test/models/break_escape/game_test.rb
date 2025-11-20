require 'test_helper'

module BreakEscape
  class GameTest < ActiveSupport::TestCase
    setup do
      @game = games(:active_game)
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
  end
end
