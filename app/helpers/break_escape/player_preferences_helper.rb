module BreakEscape
  module PlayerPreferencesHelper
    # Returns the in_game_name to display in the form. Falls back to the
    # player's handle when the name is blank or the generic 'Zero' default
    # (meaning a custom name has never been set).
    def suggested_in_game_name(preference)
      name = preference.in_game_name
      if (name.blank? || name == 'Zero') && current_player.respond_to?(:handle) && current_player.handle.present?
        current_player.handle
      else
        name
      end
    end

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
