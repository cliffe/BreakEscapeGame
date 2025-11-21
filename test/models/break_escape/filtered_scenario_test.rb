require 'test_helper'

module BreakEscape
  class FilteredScenarioTest < ActiveSupport::TestCase
    setup do
      @scenario_data = {
        "scenario_brief" => "Test mission",
        "startRoom" => "start",
        "startItemsInInventory" => [
          { "type" => "phone", "name" => "Test Phone" }
        ],
        "rooms" => {
          "start" => {
            "type" => "room_office",
            "connections" => { "north" => "next_room" },
            "locked" => false,
            "objects" => [
              { "type" => "desk", "name" => "Desk", "takeable" => false }
            ],
            "npcs" => [
              { "id" => "npc1", "displayName" => "NPC One" }
            ]
          },
          "next_room" => {
            "type" => "room_server",
            "connections" => { "south" => "start" },
            "locked" => true,
            "lockType" => "key",
            "requires" => "key123",
            "objects" => [
              { "type" => "server", "name" => "Server", "takeable" => false }
            ]
          }
        }
      }
    end

    test 'filtered_scenario_for_bootstrap removes room contents' do
      # Create a game with custom scenario data, bypassing the generate callback
      mission = break_escape_missions(:ceo_exfil)
      player = break_escape_demo_users(:test_user)
      
      game = Game.new(
        mission: mission,
        player: player,
        scenario_data: @scenario_data
      )
      # Manually skip callback and save
      game.save(validate: false)
      
      filtered = game.filtered_scenario_for_bootstrap
      
      # Check top-level fields are preserved
      assert_equal "Test mission", filtered["scenario_brief"]
      assert_equal "start", filtered["startRoom"]
      assert filtered["startItemsInInventory"].present?
      
      # Check rooms structure exists
      assert filtered["rooms"].present?
      assert filtered["rooms"]["start"].present?
      assert filtered["rooms"]["next_room"].present?
    end

    test 'filtered_scenario_for_bootstrap preserves navigation structure' do
      mission = break_escape_missions(:ceo_exfil)
      player = break_escape_demo_users(:test_user)
      
      game = Game.new(mission: mission, player: player, scenario_data: @scenario_data)
      game.save(validate: false)
      
      filtered = game.filtered_scenario_for_bootstrap
      
      start_room = filtered["rooms"]["start"]
      
      # Keep connections for navigation
      assert_equal({ "north" => "next_room" }, start_room["connections"])
      
      # Keep type for room rendering
      assert_equal "room_office", start_room["type"]
      
      # Keep lock info for validation
      assert_equal false, start_room["locked"]
    end

    test 'filtered_scenario_for_bootstrap removes objects and npcs' do
      mission = break_escape_missions(:ceo_exfil)
      player = break_escape_demo_users(:test_user)
      
      game = Game.new(mission: mission, player: player, scenario_data: @scenario_data)
      game.save(validate: false)
      
      filtered = game.filtered_scenario_for_bootstrap
      
      start_room = filtered["rooms"]["start"]
      
      # Objects and NPCs should be removed
      assert_nil start_room["objects"]
      assert_nil start_room["npcs"]
    end

    test 'filtered_scenario_for_bootstrap preserves lock requirements' do
      mission = break_escape_missions(:ceo_exfil)
      player = break_escape_demo_users(:test_user)
      
      game = Game.new(mission: mission, player: player, scenario_data: @scenario_data)
      game.save(validate: false)
      
      filtered = game.filtered_scenario_for_bootstrap
      
      locked_room = filtered["rooms"]["next_room"]
      
      # Keep lock data for server-side validation
      assert_equal true, locked_room["locked"]
      assert_equal "key", locked_room["lockType"]
      assert_equal "key123", locked_room["requires"]
    end

    test 'filtered_scenario_for_bootstrap does not modify original' do
      mission = break_escape_missions(:ceo_exfil)
      player = break_escape_demo_users(:test_user)
      
      game = Game.new(mission: mission, player: player, scenario_data: @scenario_data)
      game.save(validate: false)
      
      original_rooms = game.scenario_data["rooms"].keys
      filtered = game.filtered_scenario_for_bootstrap
      
      # Original should still have all data
      assert game.scenario_data["rooms"]["start"]["objects"].present?
      assert game.scenario_data["rooms"]["start"]["npcs"].present?
      
      # Filtered should not
      assert_nil filtered["rooms"]["start"]["objects"]
      assert_nil filtered["rooms"]["start"]["npcs"]
    end
  end
end
