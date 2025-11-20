# Database Schema Reference

Complete schema documentation for BreakEscape Rails Engine.

---

## Overview

**Total Tables:** 2 (plus 1 for standalone mode)

1. `break_escape_missions` - Scenario metadata
2. `break_escape_games` - Player game state + scenario snapshot
3. `break_escape_demo_users` - Standalone mode only (optional)

---

## Table 1: break_escape_missions

Stores scenario metadata only. Scenario JSON is generated via ERB when games are created.

### Schema

```sql
CREATE TABLE break_escape_missions (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  display_name VARCHAR NOT NULL,
  description TEXT,
  published BOOLEAN NOT NULL DEFAULT false,
  difficulty_level INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX index_break_escape_missions_on_name ON break_escape_missions(name);
CREATE INDEX index_break_escape_missions_on_published ON break_escape_missions(published);
```

### Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| id | bigint | NO | AUTO | Primary key |
| name | string | NO | - | Scenario identifier (matches directory name) |
| display_name | string | NO | - | Human-readable name |
| description | text | YES | - | Scenario brief/description |
| published | boolean | NO | false | Whether scenario is visible to players |
| difficulty_level | integer | NO | 1 | Difficulty (1-5 scale) |
| created_at | timestamp | NO | NOW() | Record creation time |
| updated_at | timestamp | NO | NOW() | Last update time |

### Indexes

- **Primary Key:** `id`
- **Unique Index:** `name` (ensures scenario names are unique)
- **Index:** `published` (for filtering published scenarios)

### Example Records

```ruby
[
  {
    id: 1,
    name: 'ceo_exfil',
    display_name: 'CEO Exfiltration',
    description: 'Infiltrate the corporate office and gather evidence of insider trading.',
    published: true,
    difficulty_level: 3
  },
  {
    id: 2,
    name: 'cybok_heist',
    display_name: 'CybOK Heist',
    description: 'Break into the research facility and steal the CybOK framework.',
    published: true,
    difficulty_level: 4
  }
]
```

### Relationships

- `has_many :games` - One mission can have many game instances

### Validations

```ruby
validates :name, presence: true, uniqueness: true
validates :display_name, presence: true
validates :difficulty_level, inclusion: { in: 1..5 }
```

---

## Table 2: break_escape_games

Stores player game state and scenario snapshot. This is the main table containing all game progress.

### Schema

```sql
CREATE TABLE break_escape_games (
  id BIGSERIAL PRIMARY KEY,
  player_type VARCHAR NOT NULL,
  player_id BIGINT NOT NULL,
  mission_id BIGINT NOT NULL,
  scenario_data JSONB NOT NULL,
  player_state JSONB NOT NULL DEFAULT '{"currentRoom":null,"unlockedRooms":[],"unlockedObjects":[],"inventory":[],"encounteredNPCs":[],"globalVariables":{},"biometricSamples":[],"biometricUnlocks":[],"bluetoothDevices":[],"notes":[],"health":100}'::jsonb,
  status VARCHAR NOT NULL DEFAULT 'in_progress',
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  score INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (mission_id) REFERENCES break_escape_missions(id)
);

CREATE INDEX index_break_escape_games_on_player
  ON break_escape_games(player_type, player_id);
CREATE INDEX index_break_escape_games_on_mission_id
  ON break_escape_games(mission_id);
CREATE UNIQUE INDEX index_games_on_player_and_mission
  ON break_escape_games(player_type, player_id, mission_id);
CREATE INDEX index_break_escape_games_on_scenario_data
  ON break_escape_games USING GIN(scenario_data);
CREATE INDEX index_break_escape_games_on_player_state
  ON break_escape_games USING GIN(player_state);
CREATE INDEX index_break_escape_games_on_status
  ON break_escape_games(status);
```

### Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| id | bigint | NO | AUTO | Primary key |
| player_type | string | NO | - | Polymorphic type ('User' or 'DemoUser') |
| player_id | bigint | NO | - | Polymorphic foreign key |
| mission_id | bigint | NO | - | Foreign key to missions |
| scenario_data | jsonb | NO | - | ERB-generated scenario JSON (unique per game) |
| player_state | jsonb | NO | {...} | All game progress |
| status | string | NO | 'in_progress' | Game status (in_progress, completed, abandoned) |
| started_at | timestamp | YES | - | When game started |
| completed_at | timestamp | YES | - | When game finished |
| score | integer | NO | 0 | Final score |
| created_at | timestamp | NO | NOW() | Record creation time |
| updated_at | timestamp | NO | NOW() | Last update time |

### Indexes

- **Primary Key:** `id`
- **Composite Index:** `(player_type, player_id)` - For finding user's games
- **Foreign Key Index:** `mission_id` - For mission lookups
- **Unique Index:** `(player_type, player_id, mission_id)` - One game per player per mission
- **GIN Index:** `scenario_data` - Fast JSONB queries
- **GIN Index:** `player_state` - Fast JSONB queries
- **Index:** `status` - For filtering active games

### scenario_data Structure

```json
{
  "scenarioName": "CEO Exfiltration",
  "scenarioBrief": "Gather evidence of insider trading",
  "startRoom": "reception",
  "rooms": {
    "reception": {
      "type": "room_reception",
      "connections": {"north": "office"},
      "locked": false,
      "objects": [...]
    },
    "office": {
      "type": "room_office",
      "connections": {"south": "reception"},
      "locked": true,
      "lockType": "password",
      "requires": "xK92pL7q",  // Unique per game!
      "objects": [
        {
          "type": "safe",
          "locked": true,
          "lockType": "pin",
          "requires": "7342"  // Unique per game!
        }
      ]
    }
  },
  "npcs": [
    {
      "id": "security_guard",
      "displayName": "Security Guard",
      "storyPath": "scenarios/ink/security-guard.json"
    }
  ]
}
```

**Key Points:**
- Generated via ERB when game is created
- Includes solutions (never sent to client)
- Unique passwords/pins per game instance
- Complete snapshot of scenario

### player_state Structure

```json
{
  "currentRoom": "office",
  "unlockedRooms": ["reception", "office"],
  "unlockedObjects": ["desk_drawer_123"],
  "inventory": [
    {
      "type": "key",
      "name": "Office Key",
      "key_id": "office_key_1",
      "takeable": true
    }
  ],
  "encounteredNPCs": ["security_guard"],
  "globalVariables": {
    "alarm_triggered": false,
    "player_favor": 5,
    "security_alerted": false
  },
  "biometricSamples": [
    {
      "type": "fingerprint",
      "data": "base64encodeddata",
      "source": "ceo_desk"
    }
  ],
  "biometricUnlocks": ["door_ceo", "safe_123"],
  "bluetoothDevices": [
    {
      "name": "CEO Phone",
      "mac": "AA:BB:CC:DD:EE:FF",
      "distance": 2.5
    }
  ],
  "notes": [
    {
      "id": "note_1",
      "title": "Password List",
      "content": "CEO password is..."
    }
  ],
  "health": 85
}
```

**Key Points:**
- All game progress in one JSONB column
- Includes minigame state (biometrics, bluetooth, notes)
- Health stored here (not separate column)
- globalVariables synced with client
- No position tracking (not needed)

### Relationships

- `belongs_to :player` (polymorphic) - User or DemoUser
- `belongs_to :mission` - Which scenario

### Validations

```ruby
validates :player, presence: true
validates :mission, presence: true
validates :status, inclusion: { in: %w[in_progress completed abandoned] }
validates :scenario_data, presence: true
validates :player_state, presence: true
```

### Example Record

```ruby
{
  id: 123,
  player_type: 'User',
  player_id: 456,
  mission_id: 1,
  scenario_data: {
    scenarioName: 'CEO Exfiltration',
    startRoom: 'reception',
    rooms: { ... }  # Full scenario with unique passwords
  },
  player_state: {
    currentRoom: 'office',
    unlockedRooms: ['reception', 'office'],
    inventory: [{type: 'key', name: 'Office Key'}],
    health: 85
  },
  status: 'in_progress',
  started_at: '2025-11-20T10:00:00Z',
  score: 0
}
```

---

## Table 3: break_escape_demo_users (Standalone Only)

Optional table for standalone mode development.

### Schema

```sql
CREATE TABLE break_escape_demo_users (
  id BIGSERIAL PRIMARY KEY,
  handle VARCHAR NOT NULL,
  role VARCHAR NOT NULL DEFAULT 'user',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX index_break_escape_demo_users_on_handle
  ON break_escape_demo_users(handle);
```

### Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| id | bigint | NO | AUTO | Primary key |
| handle | string | NO | - | Username |
| role | string | NO | 'user' | Role (user, admin) |
| created_at | timestamp | NO | NOW() | Record creation time |
| updated_at | timestamp | NO | NOW() | Last update time |

### Example Record

```ruby
{
  id: 1,
  handle: 'demo_player',
  role: 'user'
}
```

**Note:** Only created if running in standalone mode. Not needed when mounted in Hacktivity.

---

## Queries

### Common Queries

**Get all published missions:**
```ruby
Mission.published.order(:difficulty_level)
```

**Get player's active games:**
```ruby
user.games.active
```

**Get player's game for a mission:**
```ruby
Game.find_by(player: user, mission: mission)
```

**Get game with scenario data:**
```ruby
game = Game.find(id)
game.scenario_data  # Full scenario JSON
```

**Check if room is unlocked:**
```ruby
game.room_unlocked?('office')  # true/false
```

**Query JSONB fields:**
```ruby
# Find games where player is in 'office'
Game.where("player_state->>'currentRoom' = ?", 'office')

# Find games with specific item in inventory
Game.where("player_state->'inventory' @> ?", [{type: 'key'}].to_json)

# Find completed games
Game.where(status: 'completed')
```

---

## Migrations

### Migration 1: Create Missions

```ruby
class CreateBreakEscapeMissions < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_missions do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :published, default: false, null: false
      t.integer :difficulty_level, default: 1, null: false

      t.timestamps
    end

    add_index :break_escape_missions, :name, unique: true
    add_index :break_escape_missions, :published
  end
end
```

### Migration 2: Create Games

```ruby
class CreateBreakEscapeGames < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_games do |t|
      # Polymorphic player
      t.references :player, polymorphic: true, null: false, index: true

      # Mission reference
      t.references :mission, null: false, foreign_key: { to_table: :break_escape_missions }

      # Scenario snapshot
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
```

### Migration 3: Create Demo Users (Standalone Only)

```ruby
class CreateBreakEscapeDemoUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :break_escape_demo_users do |t|
      t.string :handle, null: false
      t.string :role, default: 'user', null: false

      t.timestamps
    end

    add_index :break_escape_demo_users, :handle, unique: true
  end
end
```

---

## Database Size Estimates

### Per Game Instance

**scenario_data:** ~30-50 KB
**player_state:** ~5-10 KB
**Total per game:** ~35-60 KB

### Scale Estimates

| Players | Games | Database Size |
|---------|-------|---------------|
| 100 | 100 | ~6 MB |
| 1,000 | 1,000 | ~60 MB |
| 10,000 | 10,000 | ~600 MB |

**Note:** PostgreSQL JSONB is efficient. GIN indexes add ~20% overhead but enable fast queries.

---

## Backup and Cleanup

### Backup Active Games

```ruby
# Export active games
Game.active.find_each do |game|
  File.write("backups/game_#{game.id}.json", {
    player: { type: game.player_type, id: game.player_id },
    mission: game.mission.name,
    state: game.player_state,
    started_at: game.started_at
  }.to_json)
end
```

### Cleanup Abandoned Games

```ruby
# Delete games abandoned > 30 days ago
Game.where(status: 'abandoned')
    .where('updated_at < ?', 30.days.ago)
    .destroy_all
```

---

## Summary

**Schema Highlights:**

- ✅ 2 simple tables (missions, games)
- ✅ JSONB for flexible state storage
- ✅ GIN indexes for fast JSONB queries
- ✅ Polymorphic player support
- ✅ Unique constraint (one game per player per mission)
- ✅ Scenario data per instance (enables randomization)
- ✅ Complete game state in one column

**Next:** See `03_IMPLEMENTATION_PLAN.md` for step-by-step migration instructions.
