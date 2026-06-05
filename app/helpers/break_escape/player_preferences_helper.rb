module BreakEscape
  module PlayerPreferencesHelper
    def sprite_valid_for_scenario?(sprite, scenario_data)
      return true unless scenario_data['validSprites'].present?

      valid_sprites = Array(scenario_data['validSprites'])

      valid_sprites.any? do |pattern|
        sprite_matches_pattern?(sprite, pattern)
      end
    end

    # Headshot filename for sprite (prefer _down_headshot for hacker_hood, else _headshot)
    HEADSHOT_VERSION = 2

    def sprite_headshot_path(sprite)
      "/break_escape/assets/characters/#{sprite}_headshot.png?v=#{HEADSHOT_VERSION}"
    end

    private

    def sprite_matches_pattern?(sprite, pattern)
      return true if pattern == '*'

      # Convert wildcard pattern to regex
      regex_pattern = Regexp.escape(pattern).gsub('\*', '.*')
      regex = /\A#{regex_pattern}\z/

      sprite.match?(regex)
    end
  end
end
