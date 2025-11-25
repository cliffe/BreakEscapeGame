module BreakEscape
  module ApplicationHelper
    # Generate a random ID for DOM elements
    def generate_random_id
      SecureRandom.hex(8)
    end
  end
end
