# BreakEscape - Database Schema Reference

## Overview

**3 tables using JSONB for flexible storage**

---

## Tables

### 1. break_escape_scenarios

Stores scenario definitions with complete game data.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint | NO | AUTO | Primary key |
| name | string | NO | - | Unique identifier (e.g., 'ceo_exfil') |
| display_name | string | NO | - | Human-readable name |
| description | text | YES | - | Scenario brief |
| scenario_data | jsonb | NO | - | **Complete scenario with solutions** |
| published | boolean | NO | false | Visible to players |
| difficulty_level | integer | NO | 1 | 1-5 scale |
| created_at | timestamp | NO | NOW() | - |
| updated_at | timestamp | NO | NOW() | - |

**Indexes:**
- `name` (unique)
- `published`
- `scenario_data` (gin)

**scenario_data structure:**
```json
{
  "startRoom": "room_reception",
  "scenarioName": "CEO Exfiltration",
  "scenarioBrief": "Break into the CEO's office...",
  "rooms": {
    "room_reception": {
      "type": "reception",
      "connections": {"north": "room_office"},
      "locked": false,
      "objects": [...]
    },
    "room_office": {
      "type": "office",
      "connections": {"south": "room_reception"},
      "locked": true,
      "lockType": "password",
      "requires": "admin123",  // Server only!
      "objects": [...]
    }
  },
  "npcs": [
    {"id": "guard", "displayName": "Security Guard", ...}
  ]
}
```

---

### 2. break_escape_npc_scripts

Stores Ink dialogue scripts per NPC per scenario.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint | NO | AUTO | Primary key |
| scenario_id | bigint | NO | - | Foreign key → scenarios |
| npc_id | string | NO | - | NPC identifier |
| ink_source | text | YES | - | Original .ink file (optional) |
| ink_compiled | text | NO | - | Compiled .ink.json |
| created_at | timestamp | NO | NOW() | - |
| updated_at | timestamp | NO | NOW() | - |

**Indexes:**
- `scenario_id`
- `[scenario_id, npc_id]` (unique)

**Foreign Keys:**
- `scenario_id` → `break_escape_scenarios(id)`

---

### 3. break_escape_game_instances

Stores player game state (one JSONB column!).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint | NO | AUTO | Primary key |
| player_type | string | NO | - | Polymorphic (User/DemoUser) |
| player_id | bigint | NO | - | Polymorphic |
| scenario_id | bigint | NO | - | Foreign key → scenarios |
| player_state | jsonb | NO | {...} | **All game state here!** |
| status | string | NO | 'in_progress' | in_progress, completed, abandoned |
| started_at | timestamp | YES | - | When game started |
| completed_at | timestamp | YES | - | When game finished |
| score | integer | NO | 0 | Final score |
| health | integer | NO | 100 | Current health |
| created_at | timestamp | NO | NOW() | - |
| updated_at | timestamp | NO | NOW() | - |

**Indexes:**
- `[player_type, player_id, scenario_id]` (unique)
- `player_state` (gin)
- `status`

**Foreign Keys:**
- `scenario_id` → `break_escape_scenarios(id)`

**player_state structure:**
```json
{
  "currentRoom": "room_office",
  "position": {"x": 150, "y": 200},
  "unlockedRooms": ["room_reception", "room_office"],
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
    "player_favor": 5
  }
}
```

---

### 4. break_escape_demo_users (Standalone Mode Only)

Simple user model for standalone/testing.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | bigint | NO | AUTO | Primary key |
| handle | string | NO | - | Username |
| role | string | NO | 'user' | admin, pro, user |
| created_at | timestamp | NO | NOW() | - |
| updated_at | timestamp | NO | NOW() | - |

**Indexes:**
- `handle` (unique)

---

## Relationships

```
Scenario (1) ──→ (∞) GameInstance
Scenario (1) ──→ (∞) NpcScript

GameInstance (∞) ←── (1) Player [Polymorphic]
  - User (Hacktivity)
  - DemoUser (Standalone)
```

---

## Migration Commands

```bash
# Generate migrations
rails generate migration CreateBreakEscapeScenarios
rails generate migration CreateBreakEscapeNpcScripts
rails generate migration CreateBreakEscapeGameInstances
rails generate migration CreateBreakEscapeDemoUsers

# Run migrations
rails db:migrate

# Import scenarios
rails db:seed
```

---

## Querying Examples

```ruby
# Find player's active games
GameInstance.where(player: current_user, status: 'in_progress')

# Get unlocked rooms for a game
game.player_state['unlockedRooms']

# Check if room is unlocked
game.room_unlocked?('room_office')

# Unlock a room
game.unlock_room!('room_office')

# Add inventory item
game.add_inventory_item!({'type' => 'key', 'name' => 'Office Key'})

# Query scenarios
Scenario.published.where("scenario_data->>'startRoom' = ?", 'room_reception')

# Complex JSONB queries
GameInstance.where("player_state @> ?", {unlockedRooms: ['room_ceo']}.to_json)
```

---

## Benefits of JSONB Approach

1. **Flexible Schema** - Add new fields without migrations
2. **Fast Queries** - GIN indexes on JSONB
3. **Matches Game Data** - Already in JSON format
4. **Simple** - One table vs many joins
5. **Atomic Updates** - Update entire state in one transaction

---

## Performance Considerations

- **GIN indexes** on all JSONB columns
- **Unique index** on [player, scenario] prevents duplicates
- **player_state** updates are atomic (PostgreSQL JSONB)
- **Scenarios cached** in memory after first load
