require 'test_helper'
require 'minitest/mock'
require 'digest'
require 'fileutils'

module BreakEscape
  class TtsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    VOICE_TEXT = "Welcome to the security system. Please verify your identity.".freeze

    setup do
      @mission = break_escape_missions(:ceo_exfil)
      @player  = break_escape_demo_users(:test_user)

      # Scenario with:
      #   - a room NPC with Hash voice + storyPath (ink_npc)  — validated via InkTextValidator
      #   - a room object with String voice + ttsVoice (intercom_1) — validated by text match
      #   - a room object with no voice config (silent_box)   — should 400
      @game = Game.create!(
        mission: @mission,
        player: @player,
        scenario_data: {
          "startRoom" => "lobby",
          "rooms" => {
            "lobby" => {
              "npcs" => [
                {
                  "id"        => "ink_npc",
                  "voice"     => { "name" => "Kore", "style" => "Speak formally.", "language" => "en-GB" },
                  "storyPath" => "scenarios/test/story"
                }
              ],
              "objects" => [
                {
                  "id"       => "intercom_1",
                  "type"     => "intercom",
                  "voice"    => VOICE_TEXT,
                  "ttsVoice" => { "name" => "Aoede", "style" => nil, "language" => nil }
                },
                {
                  "id"   => "silent_box",
                  "type" => "box"
                }
              ]
            }
          }
        },
        player_state: {
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
        }
      )
    end

    # ─── Parameter validation ────────────────────────────────────────────────

    test "tts returns 400 when npc_id is missing" do
      post tts_game_url(@game), params: { text: "Hello" }
      assert_response :bad_request
      assert_match(/npc_id|text/i, json_body["error"])
    end

    test "tts returns 400 when text is missing" do
      post tts_game_url(@game), params: { npc_id: "intercom_1" }
      assert_response :bad_request
      assert_match(/npc_id|text/i, json_body["error"])
    end

    test "tts returns 400 when text exceeds 500 characters" do
      post tts_game_url(@game), params: {
        npc_id: "intercom_1",
        text:   "a" * 501
      }
      assert_response :bad_request
      assert_match(/too long/i, json_body["error"])
    end

    test "tts returns 404 when NPC does not exist in scenario" do
      post tts_game_url(@game), params: {
        npc_id: "nonexistent_entity",
        text:   "Hello world"
      }
      assert_response :not_found
      assert_match(/not found/i, json_body["error"])
    end

    test "tts returns 400 when object has no voice configuration" do
      post tts_game_url(@game), params: {
        npc_id: "silent_box",
        text:   "Hello world"
      }
      assert_response :bad_request
      assert_match(/no voice/i, json_body["error"])
    end

    # ─── TTS service disabled ────────────────────────────────────────────────

    test "tts returns 503 when GEMINI_API_KEY is not set" do
      with_env("GEMINI_API_KEY" => nil) do
        post tts_game_url(@game), params: {
          npc_id: "intercom_1",
          text:   VOICE_TEXT
        }
        assert_response :service_unavailable
        assert_match(/not configured|GEMINI_API_KEY/i, json_body["error"])
      end
    end

    # ─── Text validation for room objects (voice as String) ──────────────────

    test "tts returns 403 when text does not match intercom voice message" do
      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        post tts_game_url(@game), params: {
          npc_id: "intercom_1",
          text:   "This text is completely unrelated to the intercom message."
        }
        assert_response :forbidden
        assert_match(/not found/i, json_body["error"])
      end
    end

    test "tts passes text validation for intercom before reaching TTS generation" do
      # When text matches the stored voice message, validation passes.
      # We use a mock TtsService so no real API call is made.
      # If generate returns nil, the controller returns 500 (generation failed),
      # which proves validation succeeded (403 would have been returned otherwise).
      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        mock_service = Minitest::Mock.new
        mock_service.expect(:enabled?, true)
        mock_service.expect(:generate, nil, [String, String, NilClass, NilClass])

        TtsService.stub(:new, mock_service) do
          post tts_game_url(@game), params: {
            npc_id: "intercom_1",
            text:   VOICE_TEXT
          }
        end

        # 500 means we got past the 403-text-validation gate
        assert_response :internal_server_error
        mock_service.verify
      end
    end

    # ─── Ink NPC — story file not found ─────────────────────────────────────

    test "tts returns 404 when ink story file cannot be resolved" do
      # The ink_npc storyPath ("scenarios/test/story") does not exist on disk
      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        post tts_game_url(@game), params: {
          npc_id: "ink_npc",
          text:   "Any text"
        }
        assert_response :not_found
        assert_match(/story file not found/i, json_body["error"])
      end
    end

    # ─── Ink NPC — text not in story ─────────────────────────────────────────

    test "tts returns 403 when text is not found in ink story" do
      # Place a fake compiled Ink JSON relative to BreakEscape::Engine.root so
      # resolve_and_compile_ink can find it (it joins storyPath with engine root).
      tmp_dir      = BreakEscape::Engine.root.join("tmp", "tts_ink_test_#{Process.pid}")
      FileUtils.mkdir_p(tmp_dir)
      fake_json    = tmp_dir.join("story.json")
      story_path   = "tmp/tts_ink_test_#{Process.pid}/story.json"

      File.write(fake_json, { "inkVersion" => 21, "root" => ["^Narrator: Hello world", "done"] }.to_json)

      # Point the ink_npc's storyPath at our temp file
      @game.scenario_data["rooms"]["lobby"]["npcs"] = [
        {
          "id"        => "ink_npc",
          "voice"     => { "name" => "Kore", "style" => "Speak formally.", "language" => "en-GB" },
          "storyPath" => story_path
        }
      ]
      @game.save!

      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        post tts_game_url(@game), params: {
          npc_id: "ink_npc",
          text:   "Text that is definitely not in the fake story at all"
        }
      end

      assert_response :forbidden
      assert_match(/not found/i, json_body["error"])
    ensure
      FileUtils.rm_rf(tmp_dir) if tmp_dir
    end

    # ─── TTS generation failure ───────────────────────────────────────────────

    test "tts returns 500 when TTS service fails to generate audio" do
      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        mock_service = Minitest::Mock.new
        mock_service.expect(:enabled?, true)
        mock_service.expect(:generate, nil, [String, String, NilClass, NilClass])

        TtsService.stub(:new, mock_service) do
          post tts_game_url(@game), params: {
            npc_id: "intercom_1",
            text:   VOICE_TEXT
          }
        end

        assert_response :internal_server_error
        assert_match(/failed/i, json_body["error"])
        mock_service.verify
      end
    end

    # ─── Successful TTS via cache hit (no real API call) ─────────────────────

    test "tts serves mp3 audio for intercom object when audio is cached" do
      cache_dir = Rails.root.join("tmp", "tts_cache")
      FileUtils.mkdir_p(cache_dir)

      # Compute the exact cache key TtsService will look up
      voice_name   = "Aoede"
      normalized   = VOICE_TEXT.downcase.gsub(/[^\w\s]/, "").strip.gsub(/\s+/, " ")
      cache_key    = Digest::MD5.hexdigest("#{normalized}|#{voice_name}||")
      mp3_path     = cache_dir.join("#{cache_key}.mp3")

      # Write a minimal fake MP3 (non-empty so send_file is satisfied)
      File.binwrite(mp3_path, "\xFF\xFB\x90\x00" + ("\x00" * 128))

      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        post tts_game_url(@game), params: {
          npc_id: "intercom_1",
          text:   VOICE_TEXT
        }
      end

      assert_response :success
      assert_equal "audio/mpeg", response.media_type
    ensure
      File.delete(mp3_path) if mp3_path && File.exist?(mp3_path)
    end

    # ─── Ink NPC — successful TTS via cache hit ───────────────────────────────

    test "tts serves mp3 for ink NPC when text is valid and audio is cached" do
      tmp_dir    = BreakEscape::Engine.root.join("tmp", "tts_ink_ok_#{Process.pid}")
      FileUtils.mkdir_p(tmp_dir)
      fake_json  = tmp_dir.join("story.json")
      story_path = "tmp/tts_ink_ok_#{Process.pid}/story.json"

      npc_text = "Hello world"
      # Compiled Ink stores dialog as ^-prefixed strings
      File.write(fake_json, { "inkVersion" => 21, "root" => ["^Narrator: #{npc_text}", "done"] }.to_json)

      @game.scenario_data["rooms"]["lobby"]["npcs"] = [
        {
          "id"        => "ink_npc",
          "voice"     => { "name" => "Kore", "style" => nil, "language" => nil },
          "storyPath" => story_path
        }
      ]
      @game.save!

      # Pre-populate TTS cache for this request
      cache_dir  = Rails.root.join("tmp", "tts_cache")
      FileUtils.mkdir_p(cache_dir)
      normalized = npc_text.downcase.gsub(/[^\w\s]/, "").strip.gsub(/\s+/, " ")
      cache_key  = Digest::MD5.hexdigest("#{normalized}|Kore||")
      mp3_path   = cache_dir.join("#{cache_key}.mp3")
      File.binwrite(mp3_path, "\xFF\xFB\x90\x00" + ("\x00" * 128))

      with_env("GEMINI_API_KEY" => "dummy_key_for_test") do
        post tts_game_url(@game), params: {
          npc_id: "ink_npc",
          text:   npc_text
        }
      end

      assert_response :success
      assert_equal "audio/mpeg", response.media_type
    ensure
      FileUtils.rm_rf(tmp_dir) if tmp_dir
      File.delete(mp3_path) if mp3_path && File.exist?(mp3_path)
    end

    private

    def json_body
      JSON.parse(response.body)
    end

    # Temporarily set (or unset) ENV variables, restoring originals after block.
    def with_env(vars)
      saved = vars.each_with_object({}) { |(k, _), h| h[k.to_s] = ENV[k.to_s] }
      vars.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v.to_s }
      yield
    ensure
      saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    end
  end
end
