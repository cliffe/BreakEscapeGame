# BreakEscape Engine Configuration
BreakEscape.configure do |config|
  # Set to true for standalone mode (development)
  # Set to false when mounted in Hacktivity (production)
  config.standalone_mode = ENV['BREAK_ESCAPE_STANDALONE'] == 'true'

  # Demo user handle for standalone mode
  config.demo_user_handle = ENV['BREAK_ESCAPE_DEMO_USER'] || 'demo_player'
end
