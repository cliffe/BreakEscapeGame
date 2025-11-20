# Simplified Rails Engine Migration Approach
## Last Updated: 2025-11-20

## Core Philosophy

**Keep it simple:** Use JSON storage for game state (it's already in that format), validate only what matters, and minimize server round-trips.

---

## What We Actually Need to Track

### 1. **Scenario JSON (Filtered for Client)**
**Server stores:** Complete scenario with solutions
**Client receives:** Filtered JSON with:
- Room layouts (connections, types)
- Objects visible but lock requirements hidden
- NPCs present but Ink scripts loaded on-demand
- No PINs, passwords, key IDs, or container contents

### 2. **Player Current State (Simple JSON)**
```json
{
  "currentRoom": "room_reception",
  "position": { "x": 100, "y": 200 },
  "unlockedRooms": ["room_reception", "room_office"],
  "unlockedObjects": ["desk_drawer_123", "safe_456"],
  "inventory": [
    { "type": "key", "name": "Office Key", "key_id": "office_key_1" },
    { "type": "lockpick", "name": "Lockpick Set" }
  ],
  "encounteredNPCs": ["security_guard", "receptionist"],
  "globalVariables": {
    "alarm_triggered": false,
    "player_favor": 5
  }
}
```

That's it! One JSON blob per player per scenario.

### 3. **NPC Ink Scripts (Lazy Loaded)**
- When player encounters NPC → load Ink script
- All conversation happens client-side
- Only validate if NPC grants door unlock (simple check: has player encountered this NPC?)

---

## Simplified Database Schema

### One Main Table: `game_instances`

```ruby
create_table :game_instances do |t|
  t.references :user, null: false
  t.references :scenario, null: false

  # Game state as JSON
  t.jsonb :player_state, default: {
    currentRoom: 'room_reception',
    position: { x: 0, y: 0 },
    unlockedRooms: [],
    unlockedObjects: [],
    inventory: [],
    encounteredNPCs: [],
    globalVariables: {}
  }

  # Metadata
  t.string :status, default: 'in_progress' # in_progress, completed, abandoned
  t.datetime :started_at
  t.datetime :completed_at
  t.integer :score, default: 0

  t.timestamps

  t.index [:user_id, :scenario_id], unique: true
  t.index :player_state, using: :gin  # For JSON queries
end

create_table :scenarios do |t|
  t.string :name, null: false
  t.text :description
  t.jsonb :scenario_data  # Complete scenario JSON (with solutions)
  t.boolean :published, default: false
  t.timestamps
end

create_table :npc_scripts do |t|
  t.references :scenario, null: false
  t.string :npc_id, null: false
  t.text :ink_script  # Ink JSON
  t.timestamps

  t.index [:scenario_id, :npc_id], unique: true
end
```

**That's it! 3 tables instead of 10+**

---

## Simplified API Endpoints

### 1. Bootstrap Game
```
GET /api/games/:game_id/bootstrap

Response:
{
  "startRoom": "room_reception",
  "scenarioName": "CEO Heist",
  "playerState": { currentRoom, position, inventory, ... },
  "roomLayout": {
    // Just room IDs and connections, no solutions
    "room_reception": {
      "connections": { "north": "room_office" },
      "locked": false
    },
    "room_office": {
      "connections": { "south": "room_reception", "north": "room_ceo" },
      "locked": true  // But no lockType or requires!
    }
  }
}
```

### 2. Load Room (When Unlocked)
```
GET /api/games/:game_id/rooms/:room_id

Server checks: Is room in playerState.unlockedRooms?
  - Yes → Return room data (objects, but still no lock solutions)
  - No → 403 Forbidden

Response:
{
  "roomId": "room_office",
  "objects": [
    {
      "type": "desk",
      "name": "Desk",
      "locked": true,  // But no "requires" field
      "observations": "A locked desk drawer"
    }
  ]
}
```

### 3. Attempt Unlock
```
POST /api/games/:game_id/unlock

Body:
{
  "targetType": "door|object",
  "targetId": "room_ceo|desk_drawer_123",
  "method": "key|pin|password|lockpick",
  "attempt": "1234|password123|key_id_5"
}

Server:
- Loads complete scenario JSON
- Checks if attempt matches requirement
- If valid:
  - Adds to playerState.unlockedRooms or unlockedObjects
  - Returns unlocked content
- If invalid:
  - Returns failure message

Response (success):
{
  "success": true,
  "type": "door",
  "roomData": { ... } // If door
  // OR
  "contents": [ ... ] // If container
}
```

### 4. Update Inventory
```
POST /api/games/:game_id/inventory

Body:
{
  "action": "add|remove",
  "item": { "type": "key", "name": "Office Key", "key_id": "..." }
}

Server validates:
- For "add": Is item in an unlocked container/room?
- Updates playerState.inventory

Response:
{ "success": true, "inventory": [...] }
```

### 5. Load NPC Script (On Encounter)
```
GET /api/games/:game_id/npcs/:npc_id/script

Server checks: Is NPC in current room OR already in playerState.encounteredNPCs?
  - Yes → Return Ink script
  - No → 403 Forbidden

Side effect: Add to playerState.encounteredNPCs

Response:
{
  "npcId": "security_guard",
  "inkScript": { ... },  // Full Ink JSON
  "eventMappings": [...],
  "timedMessages": [...]
}
```

### 6. Sync State (Periodic)
```
PUT /api/games/:game_id/state

Body:
{
  "currentRoom": "room_office",
  "position": { "x": 150, "y": 220 },
  "globalVariables": { "alarm_triggered": false }
}

Server: Merges into playerState (validates room is unlocked)
```

**That's it! 6 endpoints instead of 15+**

---

## What We DON'T Track Server-Side

### ❌ Every Event
- No event logging (unless needed for analytics later)
- NPCs listen to events client-side only

### ❌ Every Conversation Turn
- All NPC dialogue happens client-side
- No conversation history sync needed
- No story state tracking

### ❌ Every Minigame Action
- Minigames run 100% client-side
- Only unlock validation matters

### ❌ Complex Permissions
- No NPCPermission table
- Simple rule: If player encountered NPC, NPC can do its thing

---

## Validation Strategy (Simplified)

### When Server Validates

1. **Unlock Attempts** ✅
   - Check attempt against scenario JSON
   - Update unlocked state

2. **Inventory Changes** ✅
   - Verify item exists in unlocked location
   - Update inventory JSON

3. **Room Access** ✅
   - Check room in unlockedRooms
   - Return filtered room data

4. **NPC Script Loading** ✅
   - Check NPC encountered or in current room
   - Return Ink script

### When Server Doesn't Validate

1. **Conversations** ❌ - All client-side
2. **Movement** ❌ - Trust client position
3. **Events** ❌ - Client-side only
4. **Minigame Actions** ❌ - Only result matters
5. **Global Variables** ❌ - Sync periodically, don't validate every change

---

## NPC Door Unlock Simplification

**Scenario defines:** NPC can unlock door X
```json
{
  "id": "security_guard",
  "canUnlock": ["room_server"]
}
```

**Client requests:** NPC unlock door
```
POST /api/games/:game_id/npc_unlock

Body:
{
  "npcId": "security_guard",
  "doorId": "room_server"
}

Server validates:
- Is NPC in playerState.encounteredNPCs?
- Does scenario say NPC can unlock this door?
- If yes: Add to unlockedRooms, return room data
```

**No conversation tracking, no trust levels, no complex permissions!**

---

## Migration Timeline (Simplified)

### Total: 12-14 weeks (vs 22 weeks original)

**Weeks 1-2:** Setup
- Create Rails Engine
- 3 database tables
- Import scenarios as JSON

**Weeks 3-4:** Core API
- Bootstrap endpoint
- Room loading
- Unlock validation

**Weeks 5-6:** Client Integration
- Modify loadRoom() to fetch from server
- Add unlock validation
- NPC script lazy loading

**Weeks 7-8:** Inventory & State Sync
- Inventory API
- State sync endpoint
- Offline queue

**Weeks 9-10:** NPC Integration
- NPC script loading
- NPC door unlock (simple validation)
- Import all Ink scripts

**Weeks 11-12:** Testing & Polish
- Integration testing
- Performance optimization
- Security audit

**Weeks 13-14:** Deployment
- Staging deployment
- Load testing
- Production deployment

**Savings: 8-10 weeks** by simplifying!

---

## Implementation Example: Unlock Validation

### Server-Side (Simple)

```ruby
class Api::UnlockController < ApplicationController
  def create
    game = GameInstance.find(params[:game_id])

    # Load complete scenario (has solutions)
    scenario = game.scenario.scenario_data

    target_type = params[:target_type] # 'door' or 'object'
    target_id = params[:target_id]
    attempt = params[:attempt]
    method = params[:method]

    # Find target in scenario
    target = find_target(scenario, target_type, target_id)

    # Validate attempt
    is_valid = validate_attempt(target, attempt, method)

    if is_valid
      # Update player state JSON
      if target_type == 'door'
        game.player_state['unlockedRooms'] << target_id
        room_data = get_filtered_room_data(scenario, target_id)

        game.save!
        render json: { success: true, roomData: room_data }
      else
        game.player_state['unlockedObjects'] << target_id
        contents = target['contents'] || []

        game.save!
        render json: { success: true, contents: contents }
      end
    else
      render json: { success: false, message: 'Invalid attempt' }, status: 422
    end
  end

  private

  def validate_attempt(target, attempt, method)
    case method
    when 'key'
      target['requires'] == attempt  # key_id matches
    when 'pin', 'password'
      target['requires'] == attempt  # PIN/password matches
    when 'lockpick'
      true  # Client-side minigame passed, trust it
    end
  end

  def get_filtered_room_data(scenario, room_id)
    room = scenario['rooms'][room_id].dup

    # Remove solutions from objects
    room['objects']&.each do |obj|
      obj.delete('requires')
      obj.delete('contents') if obj['locked']
    end

    room
  end
end
```

### Client-Side (Unchanged)

```javascript
async function handleUnlock(lockable, type) {
  // Show minigame or prompt (unchanged)
  const attempt = await getUnlockAttempt(lockable);

  // NEW: Validate with server
  const response = await fetch(`/api/games/${gameId}/unlock`, {
    method: 'POST',
    body: JSON.stringify({
      targetType: type,
      targetId: lockable.objectId,
      method: lockable.lockType,
      attempt: attempt
    })
  });

  const result = await response.json();

  if (result.success) {
    // Unlock locally
    unlockTarget(lockable, type);

    // If door, load room
    if (type === 'door' && result.roomData) {
      createRoom(result.roomData.roomId, result.roomData, position);
    }
  }
}
```

---

## Benefits of Simplified Approach

### 1. **Faster Development**
- 12-14 weeks vs 22 weeks
- 3 tables vs 10+
- 6 endpoints vs 15+

### 2. **Easier Maintenance**
- JSON storage matches existing format
- No ORM complexity
- Simple queries

### 3. **Better Performance**
- Fewer database queries
- Single JSON blob vs many joins
- JSONB indexing is fast

### 4. **Flexible**
- Easy to add new fields to JSON
- No migrations for game state changes
- Scenarios stay as JSON files

### 5. **Simpler Logic**
- No complex permissions
- No conversation state tracking
- Clear validation rules

---

## What We Give Up (And Why It's OK)

### ❌ Conversation History Persistence
**Why OK:** NPCs work great client-side. If player refreshes, conversation resets. This is fine for a game session.

### ❌ Detailed Event Analytics
**Why OK:** Can add later if needed. Start simple.

### ❌ Global Variable Validation
**Why OK:** Sync periodically, rollback if server detects cheating. Don't block gameplay.

### ❌ Fine-Grained Permissions
**Why OK:** Simple rules work: encountered NPC = trusted. Scenario defines what NPCs can do.

---

## Security Model (Simplified)

### What's Secure ✅
- Scenario solutions never sent to client
- Unlock validation server-side
- Room/object access controlled
- NPC scripts lazy-loaded

### What's Client-Trust ⚠️
- Player position (low risk)
- Global variables (sync server, detect cheating)
- Minigame success (only door unlock matters)

### What We Detect
- Player accessing unearned rooms → 403
- Invalid unlock attempts → 422
- Impossible inventory items → reject

**Good enough for educational game!**

---

## Conclusion

**Original approach:** Complex, over-engineered, 22 weeks
**Simplified approach:** Pragmatic, maintainable, 12-14 weeks

**Key insight:** We don't need to track everything. Just track:
1. What's unlocked (rooms/objects)
2. What player has (inventory)
3. Who player met (NPCs)
4. Where player is (room/position)

Everything else can stay client-side!

**Ready to implement this simpler approach.**
