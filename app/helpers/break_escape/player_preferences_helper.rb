module BreakEscape
  module PlayerPreferencesHelper
    def sprite_valid_for_scenario?(sprite, scenario_data)
      return true unless scenario_data['validSprites'].present?

      valid_sprites = Array(scenario_data['validSprites'])

      valid_sprites.any? do |pattern|
        sprite_matches_pattern?(sprite, pattern)
      end
    end

    def sprite_headshot_path(sprite)
      "/break_escape/assets/characters/#{sprite}_headshot.png?v=#{BreakEscape::ASSETS_VERSION}"
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
