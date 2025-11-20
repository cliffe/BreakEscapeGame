# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV["BREAK_ESCAPE_STANDALONE"] = "true"  # Use standalone mode for tests

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"

  # Map fixture names to model classes
  ActiveSupport::TestCase.set_fixture_class(
    break_escape_missions: BreakEscape::Mission,
    break_escape_demo_users: BreakEscape::DemoUser
  )

  ActiveSupport::TestCase.fixtures :break_escape_missions, :break_escape_demo_users
end

# Reload configuration after setting ENV variable
BreakEscape.configure do |config|
  config.standalone_mode = true
  config.demo_user_handle = 'test_user'
end
