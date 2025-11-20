require "break_escape/version"
require "break_escape/engine"

module BreakEscape
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.standalone_mode?
    configuration&.standalone_mode || false
  end

  class Configuration
    attr_accessor :standalone_mode, :demo_user_handle

    def initialize
      @standalone_mode = false
      @demo_user_handle = 'demo_player'
    end
  end
end

# Initialize with defaults
BreakEscape.configure {}
