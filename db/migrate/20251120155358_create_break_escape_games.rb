class CreateBreakEscapeGames < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_games do |t|
      # Polymorphic player
      t.references :player, polymorphic: true, null: false, index: true

      # Mission reference
      t.references :mission, null: false, foreign_key: { to_table: :break_escape_missions }

      # Scenario snapshot (ERB-generated)
      t.jsonb :scenario_data, null: false

      # Player state
      t.jsonb :player_state, null: false, default: {
        currentRoom: nil,
        unlockedRooms: [],
        unlockedObjects: [],
        inventory: [],
        encounteredNPCs: [],
        globalVariables: {},
        biometricSamples: [],
        biometricUnlocks: [],
        bluetoothDevices: [],
        notes: [],
        health: 100
      }

      # Metadata
      t.string :status, default: 'in_progress', null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :score, default: 0, null: false

      t.timestamps
    end

    add_index :break_escape_games,
              [:player_type, :player_id, :mission_id],
              unique: true,
              name: 'index_games_on_player_and_mission'
    add_index :break_escape_games, :scenario_data, using: :gin
    add_index :break_escape_games, :player_state, using: :gin
    add_index :break_escape_games, :status
  end
end
