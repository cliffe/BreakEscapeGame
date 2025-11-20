# Client-Server Separation Plan for BreakEscape
## Last Updated: 2025-11-20

## Executive Summary

This document outlines the preparation needed to cleanly separate BreakEscape into client-side and server-side responsibilities. The goal is to identify what stays client-side (UI, rendering, minigames) vs what moves server-side (validation, content delivery, state management).

**⚠️ NOTE:** This plan has been updated to reflect the current state of the codebase, including:
- Fully implemented NPC system with conversation state
- Comprehensive event system (80+ events)
- Global game state management
- Multiple scenarios (24 total)

---

## Current Architecture: Single Point of Truth

### Data Flow Today

```
Browser at Game Start:
├─ Load scenario JSON (ALL rooms, ALL objects, ALL solutions)
├─ Load all Tiled maps (visual structure)
├─ Load all NPC ink scripts
├─ Load all assets (images, sounds)
│
└─ During Gameplay:
   ├─ Room loading (lazy, but data pre-loaded)
   ├─ Unlock validation (client-side)
   ├─ Inventory management (client-side)
   ├─ Container contents (client-side)
   ├─ NPC conversations (client-side)
   └─ Minigames (client-side)
```

**Problem:** All game logic and solutions are accessible in browser memory/network tab.

---

## Target Architecture: Server as Authority

### Data Flow Future

```
Browser at Game Start:
├─ Load minimal bootstrap JSON (startRoom, scenarioName)
├─ Load all Tiled maps (visual structure - CLIENT SIDE)
├─ Load all assets (images, sounds - CLIENT SIDE)
│
└─ During Gameplay:
   ├─ Room loading: Fetch from server when unlocked
   ├─ Unlock validation: Server validates, returns room data
   ├─ Inventory management: Client UI, server state
   ├─ Container contents: Server sends when unlocked
   ├─ NPC conversations: Hybrid (see NPC_MIGRATION_OPTIONS.md)
   └─ Minigames: Client-side (UI), server validates results
```

**Solution:** Server provides data incrementally as player progresses.

---

## Separation by System

### System 1: Room Loading

#### Current (Client-Side)

```javascript
// Load entire scenario at start
this.load.json('gameScenarioJSON', 'scenarios/ceo_exfil.json');

// When door approached
function loadRoom(roomId) {
    const roomData = window.gameScenario.rooms[roomId]; // All data already here
    createRoom(roomId, roomData, position);
}
```

**What's Client-Side:**
- All room definitions
- All object properties
- All lock requirements (keys, PINs, passwords)
- All container contents

**Issues:**
- Player can read solutions from JSON
- Can see locked room contents
- Can see all room connections

#### Future (Server-Client)

```javascript
// Load minimal bootstrap at start
const bootstrap = await fetch('/api/scenarios/current/bootstrap');
// Returns: { startRoom, scenarioName, availableRooms: ['reception'] }

// When door approached/unlocked
async function loadRoom(roomId) {
    const response = await fetch(`/api/rooms/${roomId}`, {
        headers: { 'Authorization': `Bearer ${playerToken}` }
    });
    
    if (!response.ok) {
        // Room not unlocked yet
        showError('Room not accessible');
        return;
    }
    
    const roomData = await response.json();
    createRoom(roomId, roomData, position);
}
```

**What's Client-Side:**
- Tiled map structure (visual layout)
- Room rendering
- Player movement
- Collision detection
- Room positioning calculations

**What's Server-Side:**
- Room unlock conditions
- Object definitions
- Container contents
- Lock requirements
- Whether player has access

**Changes Needed:**
- ✅ Already has `loadRoom()` hook - perfect
- ✅ Already separates Tiled (visual) from scenario (logic)
- ✅ No changes to `createRoom()` - data source changes only
- ⚠️ Need error handling for room access denied
- ⚠️ Need loading indicators

---

### System 2: Unlock System

#### Current (Client-Side)

```javascript
function handleUnlock(lockable, type) {
    const lockRequirements = getLockRequirements(lockable);
    
    // Check lock type
    switch(lockRequirements.lockType) {
        case 'key':
            // Check if player has key in inventory
            const hasKey = inventory.items.some(item => 
                item.scenarioData.key_id === lockRequirements.requires
            );
            if (hasKey) {
                unlockTarget(lockable, type);
            }
            break;
            
        case 'pin':
            // Show PIN minigame
            startPinMinigame(lockable, type, lockRequirements.requires, (success) => {
                if (success) {
                    unlockTarget(lockable, type);
                }
            });
            break;
    }
}
```

**Issues:**
- Client knows correct PIN (in scenario JSON)
- Client knows correct password
- Client knows which key fits which lock
- Client validates unlock success

#### Future (Server-Client)

```javascript
async function handleUnlock(lockable, type) {
    // Show unlock UI (PIN pad, password prompt, key selection)
    const userAttempt = await showUnlockUI(lockable);
    
    // Send attempt to server
    const response = await fetch(`/api/unlock/${type}/${lockable.id}`, {
        method: 'POST',
        headers: { 
            'Authorization': `Bearer ${playerToken}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            attempt: userAttempt,
            method: lockable.lockType // key, pin, password, lockpick
        })
    });
    
    const result = await response.json();
    
    if (result.success) {
        // Server says unlock successful
        unlockTargetLocally(lockable, type);
        
        // If unlocking a door, server returns room data
        if (type === 'door' && result.roomData) {
            createRoom(result.roomId, result.roomData, result.position);
        }
        
        // If unlocking a container, server returns contents
        if (type === 'container' && result.contents) {
            showContainerContents(lockable, result.contents);
        }
    } else {
        showError(result.message || 'Unlock failed');
    }
}
```

**What's Client-Side:**
- Unlock UI (PIN pad, password input, key selection)
- Lock animations
- Minigame mechanics (lockpicking physics)
- User input collection

**What's Server-Side:**
- Correct PIN/password
- Which key fits which lock
- Whether lockpicking should succeed (based on skill, difficulty)
- Room/container data revealed on unlock
- Unlock event recording

**Changes Needed:**
- 🔄 Refactor `handleUnlock()` to be async
- 🔄 Split into client UI + server validation
- 🔄 Move lock requirements from scenario to server
- 🔄 Return unlocked content from server
- ⚠️ Handle network errors gracefully
- ⚠️ Cache successful unlocks locally (offline resilience)

---

### System 3: Inventory Management

#### Current (Client-Side)

```javascript
// All inventory management happens client-side
function addToInventory(sprite) {
    window.inventory.items.push(sprite);
    updateInventoryUI();
}

function removeFromInventory(sprite) {
    const index = window.inventory.items.indexOf(sprite);
    window.inventory.items.splice(index, 1);
    updateInventoryUI();
}
```

**Issues:**
- Player can manipulate inventory in console
- Can add items they don't have
- Can duplicate items
- Server has no record of inventory

#### Future (Server-Client)

```javascript
// Client-side: UI only
async function addToInventory(sprite) {
    // Optimistically add to UI
    window.inventory.items.push(sprite);
    updateInventoryUI();
    
    // Sync to server
    try {
        const response = await fetch('/api/inventory', {
            method: 'POST',
            headers: { 
                'Authorization': `Bearer ${playerToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                item: {
                    type: sprite.scenarioData.type,
                    name: sprite.scenarioData.name,
                    source: sprite.objectId
                }
            })
        });
        
        if (!response.ok) {
            // Server rejected - remove from UI
            removeFromInventoryLocally(sprite);
            showError('Invalid item');
        }
    } catch (error) {
        // Network error - keep in UI but mark as unsynced
        markItemAsUnsynced(sprite);
    }
}

// Server-side: Source of truth
async function useItem(sprite, target) {
    // Verify with server that player has this item
    const response = await fetch('/api/inventory/use', {
        method: 'POST',
        body: JSON.stringify({
            itemId: sprite.inventoryId,
            targetId: target.objectId
        })
    });
    
    const result = await response.json();
    
    if (result.allowed) {
        // Execute use logic
        executeItemUse(sprite, target, result.effect);
    }
}
```

**What's Client-Side:**
- Inventory UI rendering
- Drag and drop
- Item sprites
- Optimistic updates
- Local caching

**What's Server-Side:**
- Inventory state (source of truth)
- Item acquisition validation
- Item use validation
- Inventory capacity rules
- Item compatibility checks

**Changes Needed:**
- 🔄 Add server sync to `addToInventory()`
- 🔄 Add server sync to `removeFromInventory()`
- 🔄 Add optimistic UI updates
- 🔄 Add rollback on server rejection
- ⚠️ Handle offline mode (queue operations)
- ⚠️ Reconcile state on reconnect

---

### System 4: Container System

#### Current (Client-Side)

```javascript
function handleContainerInteraction(sprite) {
    const contents = sprite.scenarioData.contents; // All contents known
    startContainerMinigame(sprite, contents);
}
```

**Issues:**
- All container contents visible in scenario JSON
- Player can see locked container contents
- Can manipulate contents array

#### Future (Server-Client)

```javascript
async function handleContainerInteraction(sprite) {
    // Check if container is unlocked
    if (sprite.scenarioData.locked) {
        handleUnlock(sprite, 'container');
        return;
    }
    
    // Fetch contents from server
    const response = await fetch(`/api/containers/${sprite.objectId}`, {
        headers: { 'Authorization': `Bearer ${playerToken}` }
    });
    
    if (!response.ok) {
        showError('Container not accessible');
        return;
    }
    
    const data = await response.json();
    startContainerMinigame(sprite, data.contents, data.isTakeable);
}

// Taking items from container
async function takeItemFromContainer(container, item) {
    const response = await fetch(`/api/containers/${container.objectId}/take`, {
        method: 'POST',
        body: JSON.stringify({ itemId: item.id })
    });
    
    const result = await response.json();
    
    if (result.success) {
        // Add to inventory
        addToInventory(item);
        
        // Remove from container UI
        removeFromContainerUI(item);
    }
}
```

**What's Client-Side:**
- Container UI (desktop mode, standard mode)
- Item display
- Drag interactions
- Animations

**What's Server-Side:**
- Container contents
- Item availability
- Taking validation
- State tracking (what's been taken)

**Changes Needed:**
- 🔄 Fetch contents on open (not from scenario)
- 🔄 Validate item taking server-side
- 🔄 Track container state server-side
- ⚠️ Handle empty containers gracefully
- ⚠️ Show loading state while fetching

---

### System 5: NPC System

See detailed analysis in **NPC_MIGRATION_OPTIONS.md**.

**⚠️ UPDATE:** NPC system is now fully implemented with:
- NPCManager (event mappings, conversation history, timed messages)
- Two NPC types: 'phone' and 'person' (sprite-based)
- Line-of-sight system for NPCs
- Conversation state persistence (NPCConversationStateManager)
- NPC item giving system
- Event-driven dialogue (20+ event patterns)

**Summary:**
- **Recommended:** Hybrid approach (scripts client-side, actions server-side) ✅ **CONFIRMED**
- **What's Client-Side:** Ink engine, dialogue rendering, conversation UI, event listeners, timed messages
- **What's Server-Side:** Action validation (give items, unlock doors), conversation state sync, trust level validation

#### Current Implementation (Client-Side)

```javascript
// NPCManager handles full lifecycle
class NPCManager {
  registerNPC(id, opts) {
    // opts: { displayName, storyPath, avatar, currentKnot, phoneId, npcType, eventMappings, timedMessages }
    // Registers NPC with event listeners and timed message scheduling
  }

  // Conversation history tracked per NPC
  conversationHistory = new Map(); // { npcId: [ {type, text, timestamp} ] }

  // Conversation state persisted
  saveNPCState(npcId, story) {
    // Saves Ink story state and variables to NPCConversationStateManager
  }

  // Event-driven dialogue
  _setupEventMappings(npcId, eventMappings) {
    // Maps game events → Ink story knots
    // Supports patterns like "item_picked_up:lockpick" → "on_lockpick_pickup"
  }
}
```

**What Needs Server Migration:**

```javascript
// js/systems/npc-game-bridge.js - NPC Actions
async function handleNPCGiveItem(npcId, itemType, itemName) {
  // CURRENT: Client-side only (insecure)
  const item = { type: itemType, name: itemName };
  addToInventory(createInventorySprite(item));

  // NEEDED: Server validation
  const response = await fetch(`/api/npcs/${npcId}/validate_action`, {
    method: 'POST',
    body: JSON.stringify({
      action: 'give_item',
      context: { itemType, itemName }
    })
  });

  const result = await response.json();
  if (result.allowed) {
    addToInventory(createInventorySprite(item));
  } else {
    showError('NPC cannot give this item');
  }
}

// Conversation state sync (async, non-blocking)
async function syncConversationState(npcId) {
  const state = window.npcConversationStateManager.getState(npcId);

  // Fire and forget - don't block UI
  fetch(`/api/npcs/${npcId}/sync_conversation`, {
    method: 'POST',
    body: JSON.stringify({
      history: state.history,
      variables: state.variables,
      storyState: state.storyState,
      currentKnot: state.currentKnot
    })
  }).catch(err => console.warn('Failed to sync conversation:', err));
}
```

**Changes Needed:**
- 🔄 Add server validation for NPC actions (give items, unlock doors)
- 🔄 Add async conversation state sync
- 🔄 Validate trust levels server-side
- ⚠️ Keep Ink scripts client-side (instant dialogue)
- ⚠️ Keep event listeners client-side (UI reactions)

---

### System 6: Event System (NEW)

#### Current Implementation (Client-Side)

**Status:** ✅ **FULLY IMPLEMENTED** - 80+ events across codebase

```javascript
// EventDispatcher emits events for:
// - door_unlock_attempt
// - door_unlocked
// - item_picked_up
// - item_used
// - minigame_completed
// - room_entered
// - room_revealed
// - container_opened
// - lockpick_used_in_view
// - health_changed
// - player_detected
// - npc_action_performed
// ... and many more

// Example usage:
window.eventDispatcher.emit('door_unlocked', {
  roomId: 'office',
  connectedRoom: 'ceo_office',
  direction: 'north'
});

// NPCs listen to events:
npc.eventMappings = [
  {
    eventPattern: 'item_picked_up:lockpick',
    targetKnot: 'on_lockpick_pickup',
    onceOnly: true,
    cooldown: 0
  }
];
```

**Issues:**
- All events client-side only
- No server visibility into player actions
- Can't use for anti-cheat or analytics
- Event history not persisted

#### Future (Server-Client)

**Strategy:** Selective server logging (not all events need server)

```javascript
// Client-side event system stays the same for UI
window.eventDispatcher.emit('door_unlocked', eventData);

// But critical events also logged server-side
async function logCriticalEvent(eventType, eventData) {
  // Only log events that matter for progression/anti-cheat
  const criticalEvents = [
    'door_unlocked',
    'item_picked_up',
    'minigame_completed',
    'unlock_attempt',
    'npc_action_performed',
    'health_changed'
  ];

  if (!criticalEvents.includes(eventType)) return;

  // Fire and forget - don't block gameplay
  fetch('/api/events', {
    method: 'POST',
    body: JSON.stringify({ eventType, eventData, timestamp: Date.now() })
  }).catch(err => console.warn('Failed to log event:', err));
}

// Hook into event dispatcher
const originalEmit = window.eventDispatcher.emit.bind(window.eventDispatcher);
window.eventDispatcher.emit = function(eventType, eventData) {
  originalEmit(eventType, eventData);
  logCriticalEvent(eventType, eventData); // Async log to server
};
```

**What's Client-Side:**
- Event dispatcher
- Event listener registration
- UI reactions to events
- NPC event mappings
- Timed message triggers
- Bark system triggers

**What's Server-Side:**
- Event logging (for critical events)
- Event validation (e.g., was door unlock legitimate?)
- Event analytics
- Anti-cheat metrics

**Changes Needed:**
- 🔄 Add server event logging endpoint
- 🔄 Hook event dispatcher to log critical events
- 🔄 Server validates event legitimacy (optional)
- ⚠️ Keep event system 100% functional without server (offline mode)

---

### System 7: Global Game State (NEW)

#### Current Implementation (Client-Side)

**Status:** ✅ **FULLY IMPLEMENTED** - Comprehensive state management

```javascript
// Global variables shared across rooms/NPCs
window.gameState = {
  globalVariables: {
    player_favor_with_security: 0,
    player_trust_level: 1,
    ceo_office_unlocked: false,
    alarm_triggered: false,
    // ... many more
  }
};

// NPCs read/write global variables via Ink:
VAR player_favor = 0
VAR trust_level = 1

// Game systems read global state:
if (window.gameState.globalVariables.alarm_triggered) {
  // Handle alarm state
}
```

**Issues:**
- All state client-side only
- Players can manipulate in console: `window.gameState.globalVariables.trust_level = 999`
- No persistence across sessions
- No validation of state changes
- No audit trail

#### Future (Server-Client)

**Strategy:** Server as source of truth, client caches for performance

```javascript
// Client maintains local copy for performance
window.gameState = {
  globalVariables: {}, // Cached from server
  _dirty: new Set(),   // Track unsaved changes
  _syncing: false
};

// Intercept writes to track changes
function setGlobalVariable(key, value) {
  // Optimistically update local state
  window.gameState.globalVariables[key] = value;
  window.gameState._dirty.add(key);

  // Trigger sync (debounced)
  scheduleGameStateSync();
}

// Sync to server (debounced to avoid too many requests)
const scheduleGameStateSync = debounce(async () => {
  if (window.gameState._syncing) return;
  if (window.gameState._dirty.size === 0) return;

  window.gameState._syncing = true;
  const changes = {};
  for (const key of window.gameState._dirty) {
    changes[key] = window.gameState.globalVariables[key];
  }

  try {
    const response = await fetch('/api/game_state/sync', {
      method: 'PUT',
      body: JSON.stringify({ globalVariables: changes })
    });

    if (response.ok) {
      const serverState = await response.json();

      // Server might reject some changes - reconcile
      window.gameState.globalVariables = serverState.globalVariables;
      window.gameState._dirty.clear();
    } else {
      // Server rejected - rollback?
      console.warn('Server rejected state changes');
    }
  } finally {
    window.gameState._syncing = false;
  }
}, 2000); // Sync every 2 seconds

// On game start, load state from server
async function loadGameState() {
  const response = await fetch('/api/game_state');
  const state = await response.json();
  window.gameState.globalVariables = state.globalVariables;
}
```

**What's Client-Side:**
- Local cache of global variables (for performance)
- Optimistic updates
- UI that reads state

**What's Server-Side:**
- Source of truth for all global variables
- Validation of state changes
- State persistence
- State reconciliation
- Audit log of changes

**Changes Needed:**
- 🔄 Add server state management endpoints
- 🔄 Intercept global variable writes
- 🔄 Add debounced sync to server
- 🔄 Add state reconciliation on load
- ⚠️ Handle offline mode (queue changes)

---

### System 8: Minigames

#### Current (Client-Side)

All minigames run entirely client-side:
- Lockpicking
- PIN cracking
- Password guessing
- Biometric matching
- Bluetooth scanning
- Container interaction
- Text file viewing
- Notes management
- Phone chat

#### Future (Server-Client)

**Two Categories:**

**Category A: Pure UI Minigames (Stay Client-Side)**
- Container viewing
- Text file viewing
- Notes management
- Phone chat UI

**Changes:** None needed (purely UI)

**Category B: Validation Minigames (Hybrid)**
- Lockpicking
- PIN cracking
- Password guessing
- Biometric matching
- Bluetooth scanning

**Changes:** Validate result server-side

```javascript
// Example: Lockpicking minigame
function completeLockpickingMinigame(success) {
    if (success) {
        // Client says player succeeded, but verify with server
        validateLockpickSuccess(target);
    }
}

async function validateLockpickSuccess(target) {
    const response = await fetch('/api/minigames/lockpick/validate', {
        method: 'POST',
        body: JSON.stringify({
            targetId: target.objectId,
            // Could include timing, attempts, etc. for anti-cheat
            metrics: {
                timeSpent: lockpickingTime,
                attempts: attemptCount
            }
        })
    });
    
    const result = await response.json();
    
    if (result.allowed) {
        unlockTarget(target);
        // Server returns unlocked content
        if (result.contents) {
            showContents(result.contents);
        }
    } else {
        showError('Lockpicking failed');
    }
}
```

**What's Client-Side:**
- All minigame mechanics
- Physics (lock pins, tension wrench)
- User input
- Animations
- Sound effects
- Success/failure determination (initial)

**What's Server-Side:**
- Final validation
- Content revelation on success
- Attempt tracking (anti-cheat)
- Difficulty modifiers

**Changes Needed:**
- 🔄 Add validation calls after minigame completion
- 🔄 Server returns unlocked content
- ⚠️ Handle validation failures gracefully
- ⚠️ Add metrics for anti-cheat

---

## Clean Separation Strategy

### Phase 1: Identify All Data Access Points

**Audit every place that reads from `window.gameScenario`:**

```bash
# Find all scenario data access
grep -r "window.gameScenario" js/
grep -r "gameScenario\." js/
```

**Result:** List of functions that need refactoring.

### Phase 2: Create Data Access Layer

**Instead of direct access, create abstraction:**

```javascript
// NEW: data-access.js
class GameDataAccess {
    constructor() {
        this.cache = new Map();
        this.serverMode = false; // Toggle for migration
    }
    
    async getRoomData(roomId) {
        if (this.serverMode) {
            // Fetch from server
            if (this.cache.has(`room_${roomId}`)) {
                return this.cache.get(`room_${roomId}`);
            }
            
            const response = await fetch(`/api/rooms/${roomId}`);
            const data = await response.json();
            this.cache.set(`room_${roomId}`, data);
            return data;
        } else {
            // Fallback to local data
            return window.gameScenario.rooms[roomId];
        }
    }
    
    async getContainerContents(containerId) {
        if (this.serverMode) {
            // Fetch from server
            const response = await fetch(`/api/containers/${containerId}`);
            return await response.json();
        } else {
            // Find in scenario data
            // (implementation details)
        }
    }
    
    async validateUnlock(targetId, attempt) {
        if (this.serverMode) {
            // Validate with server
            const response = await fetch('/api/unlock', {
                method: 'POST',
                body: JSON.stringify({ targetId, attempt })
            });
            return await response.json();
        } else {
            // Client-side validation (current logic)
            return this.validateUnlockLocally(targetId, attempt);
        }
    }
}

// Global instance
window.gameData = new GameDataAccess();
```

**Usage:**

```javascript
// OLD:
const roomData = window.gameScenario.rooms[roomId];

// NEW:
const roomData = await window.gameData.getRoomData(roomId);
```

**Benefits:**
- Single place to toggle server/local mode
- Easy to test both modes
- Gradual migration possible
- Caching built-in

### Phase 3: Refactor System by System

**Order of Migration:**

1. **Room Loading** (easiest, already has hook)
   - Change: `loadRoom()` calls `gameData.getRoomData()`
   - Test: Fetch room from server, verify rendering works

2. **Container System** (medium complexity)
   - Change: `handleContainerInteraction()` calls `gameData.getContainerContents()`
   - Test: Open container, verify contents loaded

3. **Unlock System** (more complex)
   - Change: `handleUnlock()` calls `gameData.validateUnlock()`
   - Test: Try correct/incorrect PINs, verify server validation

4. **Inventory System** (most complex)
   - Change: Add server sync to all inventory operations
   - Test: Add/remove items, verify server state matches

5. **NPC System** (separate workstream)
   - See NPC_MIGRATION_OPTIONS.md

### Phase 4: Add Server-Side Validation

**For each system, add validation endpoints:**

```ruby
# app/controllers/api/rooms_controller.rb
class Api::RoomsController < ApplicationController
  before_action :authenticate_player!
  
  def show
    room = Room.find_by!(room_id: params[:id])
    
    # Check if player has unlocked this room
    unless room.accessible_by?(current_player)
      render json: { error: 'Room not unlocked' }, status: :forbidden
      return
    end
    
    render json: RoomSerializer.new(room, current_player).as_json
  end
end

# app/serializers/room_serializer.rb
class RoomSerializer
  def initialize(room, player)
    @room = room
    @player = player
  end
  
  def as_json
    {
      type: @room.room_type,
      connections: @room.connections,
      objects: objects_for_player
    }
  end
  
  private
  
  def objects_for_player
    # Only include objects player has discovered/unlocked
    @room.objects.accessible_by(@player).map do |obj|
      {
        type: obj.object_type,
        name: obj.name,
        takeable: obj.takeable,
        locked: obj.locked_for?(@player),
        observations: obj.observations
        # Don't include: correct_pin, correct_password, contents (until unlocked)
      }
    end
  end
end
```

---

## Data Migration Strategy

### Converting Scenario JSON to Database

**Current:** One large JSON file per scenario
**Future:** Relational database with scenarios, rooms, objects

```ruby
# Rake task: lib/tasks/import_scenario.rake
namespace :scenario do
  desc "Import scenario from JSON"
  task :import, [:file] => :environment do |t, args|
    json = JSON.parse(File.read(args[:file]))
    
    scenario = Scenario.create!(
      name: json['scenario_name'],
      brief: json['scenario_brief'],
      start_room: json['startRoom']
    )
    
    # Import NPCs
    json['npcs']&.each do |npc_data|
      npc = scenario.npcs.create!(
        npc_id: npc_data['id'],
        display_name: npc_data['displayName'],
        story_path: npc_data['storyPath'],
        avatar_url: npc_data['avatar'],
        phone_id: npc_data['phoneId'],
        npc_type: npc_data['npcType'],
        event_mappings: npc_data['eventMappings'],
        timed_messages: npc_data['timedMessages']
      )
      
      # Import ink script
      if npc_data['storyPath']
        ink_json = File.read(npc_data['storyPath'])
        npc.update!(ink_script: ink_json)
      end
    end
    
    # Import rooms
    json['rooms'].each do |room_id, room_data|
      room = scenario.rooms.create!(
        room_id: room_id,
        room_type: room_data['type'],
        connections: room_data['connections'],
        locked: room_data['locked'] || false,
        lock_type: room_data['lockType'],
        lock_requirement: room_data['requires']
      )
      
      # Import objects
      room_data['objects']&.each do |obj_data|
        room.room_objects.create!(
          object_type: obj_data['type'],
          name: obj_data['name'],
          takeable: obj_data['takeable'],
          readable: obj_data['readable'],
          locked: obj_data['locked'] || false,
          lock_type: obj_data['lockType'],
          lock_requirement: obj_data['requires'],
          observations: obj_data['observations'],
          properties: obj_data # Store all other props as JSON
        )
      end
    end
    
    puts "Imported scenario: #{scenario.name}"
  end
end
```

**Run migration:**
```bash
rails scenario:import['scenarios/ceo_exfil.json']
```

---

## Testing Strategy

### Dual-Mode Testing

**Keep both modes working during migration:**

```javascript
// config.js
const CONFIG = {
    SERVER_MODE: process.env.SERVER_MODE === 'true',
    API_BASE: process.env.API_BASE || '/api'
};

// Use throughout codebase
if (CONFIG.SERVER_MODE) {
    // New server-based logic
} else {
    // Old client-side logic
}
```

**Test matrix:**
- ✅ Client-side mode (existing tests continue working)
- ✅ Server-side mode (new tests for API integration)
- ✅ Hybrid mode (progressive migration)

### Integration Tests

```javascript
// test/integration/room-loading.test.js
describe('Room Loading', () => {
    beforeEach(() => {
        // Setup test server with mock data
    });
    
    it('loads room from server when door unlocked', async () => {
        const player = createTestPlayer();
        const door = createTestDoor({ connectedRoom: 'office' });
        
        // Unlock door (triggers room load)
        await handleDoorInteraction(door);
        
        // Verify room was fetched from server
        expect(fetchMock).toHaveBeenCalledWith('/api/rooms/office');
        
        // Verify room was created
        expect(rooms.office).toBeDefined();
        expect(rooms.office.objects).toBeDefined();
    });
    
    it('handles room access denied gracefully', async () => {
        fetchMock.mockResponseOnce({}, { status: 403 });
        
        const result = await gameData.getRoomData('locked_room');
        
        expect(result).toBeNull();
        expect(errorShown).toBe('Room not accessible');
    });
});
```

---

## Migration Checklist (UPDATED)

### Preparation Phase (Week 1-2)

- [ ] Audit all `window.gameScenario` access points
- [ ] Audit all `window.gameState` access points ⚠️ **NEW**
- [ ] Audit all `eventDispatcher.emit` calls ⚠️ **NEW**
- [ ] Create `GameDataAccess` abstraction layer
- [ ] Design database schema (updated for NPCs, events, state)
- [ ] Create Rails models:
  - [ ] Scenario, Room, RoomObject
  - [ ] NPC, Conversation, ConversationState ⚠️ **NEW**
  - [ ] GameEvent ⚠️ **NEW**
  - [ ] PlayerGameState (for global variables) ⚠️ **NEW**
  - [ ] NPCPermission ⚠️ **NEW**
  - [ ] InventoryItem, PlayerState
- [ ] Write import script for 24 scenarios → database ⚠️ **UPDATED** (was 1 scenario)
- [ ] Import all NPC Ink scripts into database ⚠️ **NEW**
- [ ] Setup test scenarios in database

### Phase 1: Room Loading (Week 3)

- [ ] Create `Api::RoomsController`
- [ ] Add room serializer
- [ ] Refactor `loadRoom()` to use `gameData.getRoomData()`
- [ ] Add error handling for room access denied
- [ ] Add loading indicators
- [ ] Test room loading from server
- [ ] Test fallback to local mode

### Phase 2: Container System (Week 4)

- [ ] Create `Api::ContainersController`
- [ ] Add container serializer
- [ ] Refactor `handleContainerInteraction()` to fetch from server
- [ ] Add validation for taking items
- [ ] Test container unlocking
- [ ] Test item taking
- [ ] Test empty containers

### Phase 3: Unlock System (Week 5-6)

- [ ] Create `Api::UnlockController`
- [ ] Add unlock validation logic
- [ ] Refactor `handleUnlock()` to validate with server
- [ ] Add support for all lock types (key, pin, password, biometric, bluetooth)
- [ ] Return unlocked content from server
- [ ] Test each lock type
- [ ] Test incorrect attempts
- [ ] Add rate limiting for brute force protection

### Phase 4: Inventory System (Week 7)

- [ ] Create `Api::InventoryController`
- [ ] Add inventory serializer
- [ ] Add server sync to `addToInventory()`
- [ ] Add server sync to `removeFromInventory()`
- [ ] Add optimistic UI updates
- [ ] Add rollback on server rejection
- [ ] Handle offline mode (queue operations)
- [ ] Reconcile state on reconnect
- [ ] Test add/remove items
- [ ] Test item use validation

### Phase 5: NPC System (Week 8-10) ⚠️ **UPDATED**

See **NPC_MIGRATION_OPTIONS.md** for detailed plan.

✅ **Status:** NPC system fully implemented client-side, needs server integration only

- [ ] Create `Api::NpcsController`
- [ ] Add endpoints:
  - [ ] `POST /api/npcs/:id/validate_action` - Validate NPC actions (give items, unlock doors)
  - [ ] `POST /api/npcs/:id/sync_conversation` - Sync conversation state (async)
  - [ ] `GET /api/npcs/:id/story` - Progressive loading (optional)
- [ ] Create NPC permission system:
  - [ ] `NPCPermission` model (which NPCs can do what)
  - [ ] Server validates trust levels, prerequisites
- [ ] Update NPC action handlers:
  - [ ] `handleNPCGiveItem()` - Add server validation
  - [ ] `handleNPCUnlockDoor()` - Add server validation
- [ ] Add conversation state sync:
  - [ ] Hook into NPCConversationStateManager
  - [ ] Async sync after each conversation turn
  - [ ] Restore state on game load
- [ ] Test NPC actions thoroughly:
  - [ ] Give items (authorized and unauthorized)
  - [ ] Unlock doors (authorized and unauthorized)
  - [ ] Trust level requirements
  - [ ] Conversation state persistence
- [ ] Import all Ink scripts into database
- [ ] Test event-driven dialogue still works

⚠️ **Keep client-side:** Ink engine, dialogue UI, event listeners, timed messages
✅ **Add server-side:** Action validation, conversation state persistence

### Phase 6: Minigame Validation (Week 9)

- [ ] Create `Api::MinigamesController`
- [ ] Add validation for lockpicking
- [ ] Add validation for PIN cracking
- [ ] Add validation for password guessing
- [ ] Add validation for biometric matching
- [ ] Add metrics collection for anti-cheat
- [ ] Test each minigame validation

### Phase 7: Event System Integration (Week 11-12) ⚠️ **NEW**

✅ **Status:** Event system fully implemented client-side, needs server integration only

- [ ] Create `Api::EventsController`
- [ ] Add endpoint:
  - [ ] `POST /api/events` - Log critical game events
- [ ] Create `GameEvent` model
- [ ] Identify critical events to log:
  - [ ] door_unlocked
  - [ ] item_picked_up
  - [ ] minigame_completed
  - [ ] unlock_attempt
  - [ ] npc_action_performed
  - [ ] health_changed
- [ ] Hook event dispatcher:
  - [ ] Intercept `eventDispatcher.emit()`
  - [ ] Log critical events to server (async, non-blocking)
  - [ ] Keep all events client-side for UI reactions
- [ ] Add event analytics:
  - [ ] Dashboard for viewing player progression
  - [ ] Anti-cheat metrics
  - [ ] Completion rates
- [ ] Test event logging:
  - [ ] Events logged correctly
  - [ ] No impact on gameplay performance
  - [ ] Works offline (queues events)

⚠️ **Keep client-side:** All event listeners, UI reactions, NPC event mappings
✅ **Add server-side:** Selective event logging for progression/analytics

---

### Phase 8: Global Game State Management (Week 13-14) ⚠️ **NEW**

✅ **Status:** Global variables system fully implemented client-side, needs server integration

- [ ] Create `Api::GameStateController`
- [ ] Add endpoints:
  - [ ] `GET /api/game_state` - Get current global state
  - [ ] `PUT /api/game_state/sync` - Sync state changes
  - [ ] `POST /api/game_state/reconcile` - Handle conflicts
- [ ] Create `PlayerGameState` model
- [ ] Intercept global variable writes:
  - [ ] Hook `window.gameState.globalVariables` writes
  - [ ] Track dirty changes
  - [ ] Debounced sync to server (every 2s)
- [ ] Add state reconciliation:
  - [ ] Load state from server on game start
  - [ ] Handle conflicts (server wins vs client wins)
  - [ ] Merge offline changes on reconnect
- [ ] Add offline support:
  - [ ] Queue state changes when offline
  - [ ] Sync when reconnected
  - [ ] Conflict resolution strategy
- [ ] Test state management:
  - [ ] NPCs read/write global variables correctly
  - [ ] State persists across sessions
  - [ ] State syncs correctly
  - [ ] Offline mode works

⚠️ **Keep client-side:** Local cache for performance, optimistic updates
✅ **Add server-side:** Source of truth, validation, persistence

---

### Phase 9: Polish & Deployment (Week 15-18+)

- [ ] Add comprehensive error handling
- [ ] Add offline mode support
- [ ] Add state reconciliation
- [ ] Add caching strategies
- [ ] Performance testing
- [ ] Load testing
- [ ] Security audit
- [ ] Deploy to staging
- [ ] User acceptance testing
- [ ] Deploy to production

---

## Risk Mitigation

### Risk 1: Network Latency

**Problem:** Server round-trips add 100-300ms delay

**Mitigations:**
- ✅ Cache aggressively (localStorage, memory)
- ✅ Prefetch adjacent rooms in background
- ✅ Optimistic UI updates
- ✅ Show loading indicators
- ✅ Keep minigames client-side (no lag)

### Risk 2: Offline Play

**Problem:** Game requires server connection

**Mitigations:**
- ✅ Queue operations when offline
- ✅ Sync when reconnected
- ✅ Cache unlocked content locally
- ✅ Graceful degradation (show error, allow retry)

### Risk 3: State Inconsistency

**Problem:** Client and server state diverge

**Mitigations:**
- ✅ Server is source of truth
- ✅ Periodic state reconciliation
- ✅ Rollback on server rejection
- ✅ Conflict resolution strategy
- ✅ Audit log of all state changes

### Risk 4: Performance

**Problem:** More server requests = higher load

**Mitigations:**
- ✅ Aggressive caching
- ✅ Rate limiting
- ✅ Database indexing
- ✅ Query optimization
- ✅ Consider Redis for hot data

### Risk 5: Cheating

**Problem:** Players manipulate client-side state

**Mitigations:**
- ✅ Server validates all critical actions
- ✅ Metrics-based anti-cheat
- ✅ Rate limiting on attempts
- ✅ Server reconciliation detects tampering

---

## Success Metrics

**Measure migration success:**

1. **Latency:** 
   - Room loading: < 500ms
   - Unlock validation: < 300ms
   - Inventory sync: < 200ms

2. **Reliability:**
   - 99.9% uptime
   - < 0.1% error rate
   - Offline queue recovery: 100%

3. **Security:**
   - 0 solution spoilers in client
   - 0 bypass exploits
   - Cheat detection rate: > 95%

4. **Performance:**
   - Server response time: p95 < 500ms
   - Database queries: < 50ms
   - Cache hit rate: > 80%

---

## Conclusion (UPDATED)

**Key Principles:**
1. **Gradual Migration:** Use abstraction layer for dual-mode operation
2. **Server Authority:** Server validates all critical actions
3. **Client Responsiveness:** Keep UI instant with optimistic updates
4. **Graceful Degradation:** Handle offline mode and errors elegantly
5. **Security First:** Never trust client for solutions
6. **Hybrid Approach:** Keep complex client systems (NPCs, dialogue) with server validation ⚠️ **NEW**

**Critical Path (UPDATED):**
Room Loading → Unlock System → Inventory System → NPC Action Validation → Event Logging → Global State Sync

**Timeline:** 18-22 weeks for complete migration ⚠️ **UPDATED** (was 10-12 weeks)
- Added: NPC system integration (2 weeks)
- Added: Event system integration (2 weeks)
- Added: Global state management (2 weeks)
- Added: Additional testing (2 weeks)

**Confidence:** High - architecture already supports this model

**Key Changes Since Original Plans:**
- ✅ NPC system fully implemented (needs server validation only)
- ✅ Event system fully implemented (needs server logging only)
- ✅ Global game state fully implemented (needs server sync only)
- ✅ 24 scenarios exist (vs 1 originally planned)
- ⚠️ More complex state management than originally anticipated
- ⚠️ Conversation state persistence adds complexity
- ✅ But all systems are well-architected and ready for server integration

**Risk Assessment:**
- **Original Risk:** Medium-Low
- **Updated Risk:** Medium (slightly higher due to NPC/event/state complexity)
- **Mitigation:** Incremental rollout, extensive testing, hybrid approach keeps working systems intact




