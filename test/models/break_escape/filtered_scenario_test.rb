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

    # ─── targetFlags security tests ──────────────────────────────────────────

    OBJECTIVES_WITH_FLAGS = [
      {
        "aimId"  => "capture_flag",
        "title"  => "Capture the Flag",
        "tasks"  => [
          {
            "taskId"      => "submit_flag_1",
            "type"        => "submit_flags",
            "title"       => "Submit the CTF flag",
            "targetFlags" => ["FLAG{s3cr3t_v4lu3}", "FLAG{4n0th3r_s3cr3t}"]
          },
          {
            "taskId"     => "visit_server",
            "type"       => "enter_room",
            "title"      => "Enter the server room",
            "targetRoom" => "next_room"
          }
        ]
      }
    ].freeze

    test 'filtered_scenario_for_bootstrap strips targetFlags from objectives' do
      mission = break_escape_missions(:ceo_exfil)
      player  = break_escape_demo_users(:test_user)
      data    = @scenario_data.merge("objectives" => OBJECTIVES_WITH_FLAGS)

      game = Game.new(mission: mission, player: player, scenario_data: data)
      game.save(validate: false)

      filtered = game.filtered_scenario_for_bootstrap

      assert filtered["objectives"].present?, "Objectives should still be present"
      filtered["objectives"].each do |aim|
        aim["tasks"]&.each do |task|
          assert_nil task["targetFlags"],
            "targetFlags must be stripped from client-facing scenario (task: #{task['taskId']})"
        end
      end
    end

    test 'filtered_scenario_for_bootstrap preserves objective structure without targetFlags' do
      mission = break_escape_missions(:ceo_exfil)
      player  = break_escape_demo_users(:test_user)
      data    = @scenario_data.merge("objectives" => OBJECTIVES_WITH_FLAGS)

      game = Game.new(mission: mission, player: player, scenario_data: data)
      game.save(validate: false)

      filtered   = game.filtered_scenario_for_bootstrap
      aim        = filtered["objectives"].first
      flag_task  = aim["tasks"].find { |t| t["taskId"] == "submit_flag_1" }
      enter_task = aim["tasks"].find { |t| t["taskId"] == "visit_server" }

      assert_equal "capture_flag",          aim["aimId"]
      assert_equal "Capture the Flag",      aim["title"]
      assert_equal "submit_flags",          flag_task["type"]
      assert_equal "Submit the CTF flag",   flag_task["title"]
      assert_nil   flag_task["targetFlags"], "targetFlags removed"
      assert_equal "next_room",             enter_task["targetRoom"]
    end

    test 'filtered_scenario_for_bootstrap does not mutate the stored scenario_data' do
      mission = break_escape_missions(:ceo_exfil)
      player  = break_escape_demo_users(:test_user)
      data    = @scenario_data.merge("objectives" => OBJECTIVES_WITH_FLAGS)

      game = Game.new(mission: mission, player: player, scenario_data: data)
      game.save(validate: false)

      game.filtered_scenario_for_bootstrap

      # Original stored objectives must retain targetFlags for server-side validation
      original_task = game.scenario_data["objectives"].first["tasks"].first
      assert_equal ["FLAG{s3cr3t_v4lu3}", "FLAG{4n0th3r_s3cr3t}"],
        original_task["targetFlags"],
        "Stored scenario_data must not be mutated — server needs targetFlags for validation"
    end

    test 'objectives_state strips targetFlags' do
      mission = break_escape_missions(:ceo_exfil)
      player  = break_escape_demo_users(:test_user)
      data    = @scenario_data.merge("objectives" => OBJECTIVES_WITH_FLAGS)

      game = Game.new(mission: mission, player: player, scenario_data: data)
      game.save(validate: false)

      state = game.objectives_state
      assert state["objectives"].present?
      state["objectives"].each do |aim|
        aim["tasks"]&.each do |task|
          assert_nil task["targetFlags"],
            "targetFlags must be stripped from objectives_state (task: #{task['taskId']})"
        end
      end
    end

    test 'objectives_state does not mutate stored scenario_data' do
      mission = break_escape_missions(:ceo_exfil)
      player  = break_escape_demo_users(:test_user)
      data    = @scenario_data.merge("objectives" => OBJECTIVES_WITH_FLAGS)

      game = Game.new(mission: mission, player: player, scenario_data: data)
      game.save(validate: false)

      game.objectives_state

      original_task = game.scenario_data["objectives"].first["tasks"].first
      assert_equal ["FLAG{s3cr3t_v4lu3}", "FLAG{4n0th3r_s3cr3t}"],
        original_task["targetFlags"],
        "objectives_state must not mutate stored scenario_data"
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
