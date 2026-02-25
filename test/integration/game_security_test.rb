require 'test_helper'

# Security-focused integration tests covering attack surfaces that are not
# exercised by the regular happy-path or authorization tests.
#
# Each test is labelled SECURITY to make failures conspicuous in CI output.
# Tests labelled BUG CONFIRMED reproduce a known vulnerability and are
# expected to pass (they document the current broken behaviour).  The paired
# SECURITY tests assert the desired secure behaviour and will fail until the
# underlying code is fixed.
module BreakEscape
  class GameSecurityTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    PLAYER_STATE = {
      "currentRoom"      => "lobby",
      "unlockedRooms"    => ["lobby"],
      "unlockedObjects"  => [],
      "inventory"        => [],
      "encounteredNPCs"  => [],
      "globalVariables"  => {},
      "biometricSamples" => [],
      "biometricUnlocks" => [],
      "bluetoothDevices" => [],
      "notes"            => [],
      "health"           => 100
    }.freeze

    setup do
      @mission = break_escape_missions(:ceo_exfil)
      @player  = break_escape_demo_users(:test_user)

      @game = Game.create!(
        mission:       @mission,
        player:        @player,
        scenario_data: scenario_data,
        player_state:  PLAYER_STATE.dup
      )
    end

    # =========================================================================
    # sync_state — locked room teleport
    # =========================================================================

    test "SECURITY: sync_state cannot teleport player to a locked room" do
      put sync_state_game_url(@game), params: { currentRoom: "locked_office" }

      assert_response :forbidden
      json = JSON.parse(response.body)
      assert_equal false, json["success"]
      assert_match(/locked room/i, json["message"])

      @game.reload
      assert_equal "lobby", @game.player_state["currentRoom"],
        "Current room must not change to a locked room via sync_state"
    end

    test "SECURITY: sync_state cannot teleport player to a non-existent room" do
      put sync_state_game_url(@game), params: { currentRoom: "made_up_room" }

      assert_response :forbidden
      @game.reload
      assert_equal "lobby", @game.player_state["currentRoom"]
    end

    test "SECURITY: sync_state allows movement to already-unlocked rooms" do
      @game.player_state["unlockedRooms"] << "server_room"
      @game.save!

      put sync_state_game_url(@game), params: { currentRoom: "server_room" }

      assert_response :success
      @game.reload
      assert_equal "server_room", @game.player_state["currentRoom"]
    end

    # =========================================================================
    # sync_state — globalVariables injection
    # =========================================================================

    test "SECURITY: sync_state accepts legitimate globalVariables" do
      put sync_state_game_url(@game), params: {
        globalVariables: { "has_spoken_to_guard" => "true", "door_code_known" => "false" }
      }
      assert_response :success
      @game.reload
      assert @game.player_state["globalVariables"].key?("has_spoken_to_guard"),
        "Legitimate globalVariable should be persisted"
    end

    test "SECURITY: sync_state does not overwrite top-level player_state keys via globalVariables" do
      # globalVariables is nested inside player_state — sending keys like 'health'
      # or 'unlockedRooms' must not affect those sibling fields.
      put sync_state_game_url(@game), params: {
        globalVariables: { "health" => 9999, "unlockedRooms" => ["lobby", "locked_office"] }
      }
      assert_response :success

      @game.reload
      assert_equal 100, @game.player_state["health"],
        "health must not be overwritten via globalVariables injection"
      assert_not_includes @game.player_state["unlockedRooms"], "locked_office",
        "unlockedRooms must not be expanded via globalVariables injection"
    end

    # =========================================================================
    # inventory — cannot take items from inaccessible locations
    # =========================================================================

    test "SECURITY: inventory cannot add item from a locked room" do
      # office_key lives in locked_office which the player has not unlocked
      post inventory_game_url(@game), params: {
        action_type: "add",
        item: { type: "key", name: "Office Key", id: "office_key" }
      }

      assert_response :unprocessable_entity,
        "SECURITY FAIL: item was taken from a locked room"
      json = JSON.parse(response.body)
      assert_equal false, json["success"]

      @game.reload
      assert_empty @game.player_state["inventory"],
        "Inventory must not contain item from a locked room"
    end

    test "SECURITY: inventory cannot add item from a locked container" do
      # secret_doc lives inside lobby_safe which is locked
      post inventory_game_url(@game), params: {
        action_type: "add",
        item: { type: "document", name: "Secret Document", id: "secret_doc" }
      }

      assert_response :unprocessable_entity,
        "SECURITY FAIL: item was taken from a locked container"
      json = JSON.parse(response.body)
      assert_equal false, json["success"]

      @game.reload
      assert_empty @game.player_state["inventory"]
    end

    test "SECURITY: inventory cannot add a non-takeable item" do
      post inventory_game_url(@game), params: {
        action_type: "add",
        item: { type: "desk", name: "Heavy Desk", id: "lobby_desk" }
      }

      assert_response :unprocessable_entity,
        "SECURITY FAIL: non-takeable item was added to inventory"
      json = JSON.parse(response.body)
      assert_equal false, json["success"]
    end

    test "SECURITY: inventory can add a takeable item from an accessible room" do
      post inventory_game_url(@game), params: {
        action_type: "add",
        item: { type: "notepad", name: "Notepad", id: "lobby_notepad" }
      }

      assert_response :success
      @game.reload
      assert_equal 1, @game.player_state["inventory"].length
    end

    test "SECURITY: inventory can add item from a container once it is unlocked" do
      @game.player_state["unlockedObjects"] << "lobby_safe"
      @game.save!

      post inventory_game_url(@game), params: {
        action_type: "add",
        item: { type: "document", name: "Secret Document", id: "secret_doc" }
      }

      assert_response :success
    end

    # =========================================================================
    # GET /games/:id/container/:container_id — access without unlock
    #
    # The container route has no named URL helper (no `as:` in routes.rb),
    # so the path is constructed from the game path.
    # =========================================================================

    test "SECURITY: container endpoint returns 403 for a locked container" do
      get "#{game_path(@game)}/container/lobby_safe"
      assert_response :forbidden,
        "SECURITY FAIL: container contents were served without the container being unlocked"
    end

    test "SECURITY: container endpoint serves contents once unlocked" do
      @game.player_state["unlockedObjects"] << "lobby_safe"
      @game.save!

      get "#{game_path(@game)}/container/lobby_safe"
      assert_response :success
      json = JSON.parse(response.body)
      assert json["contents"].any?, "Expected contents after container is unlocked"
    end

    test "SECURITY: container endpoint returns 404 for a non-existent container" do
      get "#{game_path(@game)}/container/phantom_safe"
      assert_response :not_found
    end

    # =========================================================================
    # BUG: container type-based unlock bypass
    #
    # check_container_unlocked (games_controller.rb:844) checks
    #   unlocked_list.include?(container_data['type'])
    # This means that once ANY container of type "safe" is unlocked, ALL other
    # containers whose type is "safe" become readable — regardless of whether
    # they were individually unlocked.
    #
    # Fix: remove the `unlocked_list.include?(container_data['type'])` branch
    # from check_container_unlocked (games_controller.rb:844).
    # =========================================================================

    test "BUG CONFIRMED: type string in unlockedObjects grants access to all containers of that type" do
      # The type-based check fires when the TYPE string itself (e.g. "safe") appears
      # in unlockedObjects.  This can occur if a container whose id == a common type
      # name (e.g. id: "safe") is legitimately unlocked — its id gets pushed into
      # unlockedObjects, which is then matched against container_data['type'] for
      # every subsequent container of that type.
      # Reproduce by directly injecting the type string to simulate the post-exploit state.
      @game.player_state["unlockedObjects"] << "safe"  # type string, not a container id
      @game.save!

      # Both lobby_safe and office_safe have type "safe", so both become accessible
      get "#{game_path(@game)}/container/office_safe"

      assert_equal 200, response.status,
        "BUG CONFIRMED: the type string 'safe' in unlockedObjects grants access to ALL " \
        "containers of type 'safe'. See check_container_unlocked, games_controller.rb:844."
    end

    test "SECURITY: unlocking one container must not grant access to other containers of the same type" do
      @game.player_state["unlockedObjects"] << "lobby_safe"
      @game.save!

      get "#{game_path(@game)}/container/office_safe"

      # Will FAIL until the type-based check is removed from check_container_unlocked
      assert_response :forbidden,
        "SECURITY FAIL (known bug): unlocking lobby_safe must not grant access to office_safe. " \
        "Fix: remove the container_data['type'] branch from check_container_unlocked " \
        "(games_controller.rb:844)."
    end

    # =========================================================================
    # BUG: update_task_progress — unbounded progress value
    #
    # update_task_progress! (game.rb:804) does no bounds checking.
    # A client can set progress to any integer, including negative values or
    # values far exceeding maxProgress.
    # =========================================================================

    test "BUG CONFIRMED: update_task_progress stores negative progress without rejection" do
      setup_collect_task

      put update_task_progress_game_url(@game, task_id: "task_collect"),
          params: { progress: -99 }

      @game.reload
      stored = @game.player_state.dig("objectivesState", "tasks", "task_collect", "progress").to_i
      assert_equal(-99, stored,
        "BUG CONFIRMED: negative progress (-99) was stored without rejection. " \
        "Fix: add `progress = [progress, 0].max` in update_task_progress!.")
    end

    test "SECURITY: update_task_progress should reject negative progress" do
      setup_collect_task

      put update_task_progress_game_url(@game, task_id: "task_collect"),
          params: { progress: -99 }

      @game.reload
      stored = @game.player_state.dig("objectivesState", "tasks", "task_collect", "progress").to_i
      assert stored >= 0,
        "SECURITY FAIL (known bug): negative progress must not be stored (got #{stored})."
    end

    test "BUG CONFIRMED: update_task_progress stores progress beyond maxProgress" do
      setup_collect_task

      put update_task_progress_game_url(@game, task_id: "task_collect"),
          params: { progress: 9999 }

      @game.reload
      stored = @game.player_state.dig("objectivesState", "tasks", "task_collect", "progress").to_i
      assert_equal 9999, stored,
        "BUG CONFIRMED: progress 9999 was stored despite maxProgress=3. " \
        "Fix: clamp progress against the task's maxProgress in update_task_progress!."
    end

    test "SECURITY: update_task_progress should cap progress at maxProgress" do
      setup_collect_task

      put update_task_progress_game_url(@game, task_id: "task_collect"),
          params: { progress: 9999 }

      @game.reload
      stored = @game.player_state.dig("objectivesState", "tasks", "task_collect", "progress").to_i
      assert stored <= 3,
        "SECURITY FAIL (known bug): progress must be capped at maxProgress=3 (got #{stored})."
    end

    # =========================================================================
    # complete_task — server validates prerequisites
    # =========================================================================

    test "SECURITY: complete_task rejects unlock_room task when room is still locked" do
      setup_unlock_room_task

      post complete_task_game_url(@game, task_id: "task_unlock")

      json = JSON.parse(response.body)
      assert_equal false, json["success"],
        "SECURITY FAIL: unlock_room task was completed without the room being unlocked"

      @game.reload
      task_status = @game.player_state.dig("objectivesState", "tasks", "task_unlock", "status")
      assert_not_equal "completed", task_status,
        "Task must not be marked completed when the target room is still locked"
    end

    test "SECURITY: complete_task accepts unlock_room task when room is genuinely unlocked" do
      setup_unlock_room_task
      @game.player_state["unlockedRooms"] << "locked_office"
      @game.save!

      post complete_task_game_url(@game, task_id: "task_unlock")

      json = JSON.parse(response.body)
      assert json["success"],
        "Task should complete when the target room is genuinely unlocked"

      @game.reload
      task_status = @game.player_state.dig("objectivesState", "tasks", "task_unlock", "status")
      assert_equal "completed", task_status
    end

    private

    # ── Scenario data ─────────────────────────────────────────────────────────

    def scenario_data
      {
        "startRoom"             => "lobby",
        "startItemsInInventory" => [],
        "rooms" => {
          "lobby" => {
            "locked"      => false,
            "connections" => { "north" => "locked_office" },
            "objects" => [
              # Takeable item in accessible room
              { "id" => "lobby_notepad", "type" => "notepad", "name" => "Notepad", "takeable" => true },
              # Non-takeable fixture
              { "id" => "lobby_desk", "type" => "desk", "name" => "Heavy Desk", "takeable" => false },
              # Locked safe — first "safe"-type container (pivot for type-bypass bug)
              {
                "id" => "lobby_safe", "type" => "safe", "name" => "Lobby Safe",
                "locked" => true, "lockType" => "pin", "requires" => "1234",
                "contents" => [
                  { "id" => "secret_doc", "type" => "document", "name" => "Secret Document", "takeable" => true }
                ]
              },
              # Second "safe"-type container — the unintended beneficiary of the type-bypass bug
              {
                "id" => "office_safe", "type" => "safe", "name" => "Office Safe",
                "locked" => true, "lockType" => "pin", "requires" => "9876",
                "contents" => [
                  { "id" => "classified", "type" => "document", "name" => "Classified File", "takeable" => true }
                ]
              }
            ],
            "npcs" => []
          },
          "locked_office" => {
            "locked" => true, "lockType" => "pin", "requires" => "9999",
            "connections" => { "south" => "lobby" },
            "objects" => [
              # Item behind a locked door — must not be takeable without unlocking
              { "id" => "office_key", "type" => "key", "key_id" => "master_key",
                "name" => "Office Key", "takeable" => true }
            ]
          },
          "server_room" => {
            "locked" => true, "lockType" => "password", "requires" => "r00t",
            "connections" => { "south" => "lobby" },
            "objects" => []
          }
        }
      }
    end

    # Set up a collect_items task with maxProgress=3
    def setup_collect_task
      @game.scenario_data["objectives"] = [{
        "aimId" => "aim_evidence",
        "title" => "Gather evidence",
        "tasks" => [{
          "taskId"      => "task_collect",
          "type"        => "collect_items",
          "title"       => "Collect 3 items",
          "maxProgress" => 3
        }]
      }]
      @game.player_state["objectivesState"] = {
        "aims"  => { "aim_evidence" => { "status" => "active" } },
        "tasks" => { "task_collect" => { "status" => "active", "progress" => 0 } }
      }
      @game.save!
    end

    # Set up an unlock_room task targeting locked_office
    def setup_unlock_room_task
      @game.scenario_data["objectives"] = [{
        "aimId" => "aim_office",
        "title" => "Get into the office",
        "tasks" => [{
          "taskId"     => "task_unlock",
          "type"       => "unlock_room",
          "title"      => "Unlock the office",
          "targetRoom" => "locked_office"
        }]
      }]
      @game.player_state["objectivesState"] = {
        "aims"  => { "aim_office" => { "status" => "active" } },
        "tasks" => { "task_unlock" => { "status" => "active", "progress" => 0 } }
      }
      @game.save!
    end
  end
end
