class FixUniqueGameConstraint < ActiveRecord::Migration[7.0]
  def up
    # Try multiple approaches to remove the unique index:
    # 1. Drop it by the expected name
    execute 'DROP INDEX IF EXISTS index_games_on_player_and_mission;'

    # 2. Try without the IF EXISTS in case it's not recognized
    begin
      execute 'DROP INDEX index_games_on_player_and_mission;'
    rescue
      # Index might not exist or name might be different
    end

    # 3. Add a non-unique index with the same columns
    begin
      add_index :break_escape_games,
                [:player_type, :player_id, :mission_id],
                name: 'index_games_on_player_and_mission_non_unique',
                if_not_exists: true
    rescue
      # Index might already exist, that's okay
    end
  end

  def down
    # Not reversible
  end
end
