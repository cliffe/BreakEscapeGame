require 'test_helper'

module BreakEscape
  class MissionsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get missions_url
      assert_response :success
    end

    test "should show published mission" do
      mission = break_escape_missions(:ceo_exfil)
      get mission_url(mission)
      assert_response :redirect  # Redirects to game
    end
  end
end
