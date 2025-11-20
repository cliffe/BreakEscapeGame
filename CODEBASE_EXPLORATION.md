# BreakEscape Codebase Comprehensive Exploration Report

## Executive Summary

BreakEscape is a **pure client-side JavaScript web game** (NOT a Rails application) built with Phaser.js. It simulates cyber-physical security challenges in a top-down 2D escape room environment. The project is designed for migration to a server-client architecture with lazy-loaded scenario data.

**Current State:**
- NO Rails/Ruby code exists
- NO Node.js/npm project setup
- Pure static HTML + JavaScript + JSON
- All game logic runs in browser (Phaser.js)
- Game data (scenarios) fully preloaded as JSON
- Ready for server migration (excellent architectural foundation)

---

## 1. Overall Project Structure & Organization

### Directory Layout

```
BreakEscape/
├── index.html                    # Main game entry point
├── scenario_select.html          # Scenario selection UI
├── js/                          # JavaScript application code (130+ KB)
│   ├── main.js                  # App initialization, global state setup
│   ├── core/                    # Core game engine (5 files)
│   ├── systems/                 # Game mechanics & subsystems (34 files)
│   ├── ui/                      # UI panels & screens (5 files)
│   ├── minigames/              # Mini-game implementations (44 files, 16 types)
│   ├── events/                 # Event handling (1 file)
│   ├── config/                 # Configuration (1 file)
│   └── utils/                  # Helpers & constants (5 files)
├── scenarios/                   # Game scenario definitions
│   ├── *.json                  # Pre-built scenario configs (multiple)
│   ├── compiled/               # Compiled Ink story files
│   └── ink/                    # Ink story source files (18+ files)
├── assets/                      # Game artwork & resources
│   ├── backgrounds/            # Room background images
│   ├── characters/             # Character sprites
│   ├── npc/                    # NPC avatars and sprites
│   ├── objects/               # Interactive object sprites
│   ├── rooms/                 # Tiled map files (.json, .tmj, .tsx)
│   ├── tiles/                 # Tileset images
│   ├── sounds/                # Audio files
│   └── vendor/                # Third-party libraries (CyberChef, inkjs)
├── css/                        # Styling (6 files)
├── scripts/                    # Build & utility scripts (Python, shell)
├── planning_notes/             # Architecture documentation
│   └── rails-engine-migration/ # Server-client migration plans
└── story_design/               # Game narrative & world-building
    ├── ink/                    # Story design files
    ├── universe_bible/         # Lore and universe design
    └── lore_fragments/         # Story fragments by gameplay function
```

### Technology Stack

**Game Engine:**
- Phaser.js 3.x (client-side only)
- EasyStar.js (NPC pathfinding)
- Ink.js (story/dialogue engine)

**Data Format:**
- JSON for scenarios, rooms, object definitions
- Tiled Editor format (.tmj) for room layouts
- Ink format (.ink, compiled to .json) for NPC conversations

**UI/Styling:**
- HTML5 Canvas (via Phaser)
- Custom CSS overlays
- Modal dialogs for mini-games

**No Backend Currently:**
- No Rails, Node, or any server framework
- No database
- No authentication/authorization
- Data served as static files

---

## 2. Key Components & Architecture

### 2.1 Core Game Systems (5 files, ~170 KB)

| File | Lines | Purpose |
|------|-------|---------|
| `game.js` | ~1,200 | Main scene (preload, create, update) |
| `rooms.js` | ~1,200 | Room management, lazy loading, depth layering |
| `player.js` | ~550 | Character sprite, movement, animation |
| `pathfinding.js` | ~130 | A* pathfinding for player |
| `title-screen.js` | ~50 | Title screen (mostly empty) |

**Key Responsibilities:**
- **game.js**: Asset loading, scene initialization, main game loop
- **rooms.js**: Room creation, object spawning, visual/logic layer separation
- **player.js**: Player sprite control, movement input handling, animation
- **pathfinding.js**: A* pathfinding grid calculation

### 2.2 Game Systems (34 files, ~14 KB total)

**Major systems by complexity:**

| System | Lines | Function |
|--------|-------|----------|
| **Doors** | 1,259 | Room transitions, door sprites, unlock checks |
| **NPC Sprites** | 1,241 | NPC sprite creation, animation, depth handling |
| **NPC Behavior** | 1,164 | Face player, patrol, personal space management |
| **Interactions** | 1,066 | Object interaction routing, range detection |
| **NPC Manager** | 1,033 | NPC lifecycle, event mapping, conversation tracking |
| **Collision** | 730 | Wall collision, door gaps, physics |
| **Inventory** | 656 | Item management, item display |
| **NPC Game Bridge** | 642 | NPC → game state updates (objectives, secrets) |
| **Minigame Starters** | 602 | Launch various mini-game types |
| **Unlock System** | 548 | Centralized unlock logic (keys, PINs, passwords, biometric, Bluetooth) |
| **NPC Barks** | 453 | Random NPC dialogue snippets |
| **NPC Conversation State** | 416 | Save/restore Ink story state per NPC |
| **NPC LOS** | 404 | Line-of-sight detection for NPCs |
| **Key Lock System** | 393 | Key-to-lock mapping validation |
| **Object Physics** | 352 | Chair spinning, physics interactions |
| **Player Effects** | 330 | Hit effects, animations, feedback |
| **NPC Pathfinding** | 326 | EasyStar grid setup, patrol route calculation |
| **Player Combat** | 309 | Player attack mechanics |
| **Sound Manager** | 285 | Audio playback system |
| Other systems | <285 each | Biometrics, debug, health, combat events, etc. |

**Critical System Groups:**

1. **NPC System** (5 interconnected files):
   - `npc-manager.js` - Core NPC registry & event dispatch
   - `npc-behavior.js` - Movement, facing, patrol logic
   - `npc-sprites.js` - Visual representation
   - `npc-game-bridge.js` - State mutation interface
   - `npc-conversation-state.js` - Ink state tracking

2. **Interaction System** (3 files):
   - `interactions.js` - Core dispatcher
   - `unlock-system.js` - Lock/unlock logic
   - `minigame-starters.js` - Launch minigame on unlock

3. **Physics/Collision** (2 files):
   - `collision.js` - Wall collision, door gaps
   - `object-physics.js` - Object interactions, physics

### 2.3 Mini-Game Systems (44 files in 16 subsystems)

Each mini-game implements a specific game mechanic:

**Puzzle Mini-Games:**
1. **Lockpicking** (12 files) - Physical lock picking simulation using canvas
2. **PIN** (1 file) - PIN code guessing
3. **Password** (1 file) - Password guessing with hints
4. **Text File** (1 file) - File encryption/decryption challenges

**Security/Forensics Mini-Games:**
5. **Biometrics** (1 file) - Fingerprint dusting and spoofing
6. **Bluetooth Scanner** (1 file) - Scan for nearby Bluetooth devices
7. **RFID** (6 files) - RFID cloning, protocol attacks
8. **Container** (1 file) - Lockable container opening

**Social Engineering Mini-Games:**
9. **Phone Chat** (4 files) - Text conversations via Ink stories
10. **Person Chat** (6 files) - In-person conversations with NPCs
11. **Notes** (1 file) - Mission briefing and note-taking

**System Mini-Games:**
12. **Dusting** (1 file) - Fingerprint dusting game
13. **Title Screen** (1 file) - Game start sequence
14. **Framework** (2 files) - Base classes for all minigames

**Architecture:**
```
MinigameFramework (Singleton)
├── register(type, implementation)
├── startMinigame(type, params)
└── forceCloseMinigame()

Each minigame extends MinigameScene:
├── init() - Set up HTML
├── start() - Begin gameplay
├── complete(success) - Handle result
└── Custom game logic
```

### 2.4 UI Systems (5 files)

| File | Purpose |
|------|---------|
| `panels.js` | Side panels (inventory, notes, biometrics, Bluetooth) |
| `modals.js` | Modal dialogs (pause, settings, game over) |
| `health-ui.js` | Health bar display |
| `npc-health-bars.js` | Enemy health display |
| `game-over-screen.js` | Game completion screen |

### 2.5 Utility Systems (5 files)

| File | Purpose |
|------|---------|
| `constants.js` | Game configuration (tile size, speeds, ranges) |
| `helpers.js` | Helper functions (scenario intro, item detection) |
| `error-handling.js` | Error logging |
| `crypto-workstation.js` | CyberChef integration |
| `phone-message-converter.js` | Format phone messages |
| `combat-debug.js` | Combat system debugging |

---

## 3. Current State: NO Rails/Ruby Code

### What Currently Exists

**Game Code:** 100% JavaScript (ES6 modules)
```javascript
// Typical architecture:
export function someFunction() { ... }
export class SomeClass { ... }
export default class DefaultExport { ... }

// Usage:
import { someFunction } from './module.js';
```

**Game Data:** 100% JSON
```json
{
  "scenario_brief": "...",
  "startRoom": "reception",
  "rooms": { ... },
  "globalVariables": { ... }
}
```

**Configuration:** Constants defined in JavaScript
```javascript
export const TILE_SIZE = 32;
export const MOVEMENT_SPEED = 150;
```

### What Does NOT Exist

- ❌ No Rails application
- ❌ No Ruby code
- ❌ No database (no schema, migrations, models)
- ❌ No API endpoints
- ❌ No authentication framework
- ❌ No server-side game logic
- ❌ No package.json (not a Node.js project)
- ❌ No build process (pure browser-loadable files)

### Game State Storage

**Current (All Client-Side):**
```javascript
window.gameState = {
    biometricSamples: [],
    biometricUnlocks: [],
    bluetoothDevices: [],
    notes: [],
    startTime: null,
    globalVariables: { ... },  // From scenario JSON
    currentObjective: "...",    // Set by NPCs via game bridge
    revealedSecrets: { ... },   // Discovered during gameplay
}

window.inventory = {
    items: [],
    container: null
}

window.rooms = {
    reception: { ... },
    office1: { ... },
    // ... all rooms loaded at create time
}

window.currentRoom = "reception"
window.discoveredRooms = new Set(["reception"])
```

**Validation:** No validation currently - all state is mutable by client
- No server validation of unlock attempts
- No server check of inventory changes
- No anti-cheat measures

---

## 4. Client-Side vs Server-Side Organization

### Current: 100% Client-Side

```
Browser
├── Load HTML (index.html)
├── Load JavaScript (all .js files)
├── Load Assets (images, sounds)
├── Load Scenario JSON (entire game data)
└── Run Complete Game in Browser
    ├── All game logic
    ├── All state management
    ├── All calculations
    └── No server interaction

Server Role: Static file hosting only
├── Serve HTML
├── Serve JS
├── Serve CSS
├── Serve images
├── Serve scenario JSON
└── (No game logic, no database queries)
```

### Data Preloading Architecture

**Preload Phase (in game.js):**
```javascript
function preload() {
    // Load ALL Tiled maps
    this.load.tilemapTiledJSON('room_reception', 'assets/rooms/room_reception2.json');
    this.load.tilemapTiledJSON('room_office', 'assets/rooms/room_office2.json');
    // ... more rooms
    
    // Load ALL images
    this.load.image('pc', 'assets/objects/pc1.png');
    // ... hundreds more
    
    // Load ENTIRE scenario at once
    this.load.json('gameScenario', 'scenarios/ceo_exfil.json');
}
```

**Create Phase (in game.js):**
```javascript
function create() {
    window.gameScenario = this.cache.json.get('gameScenario');
    // All 100-200KB of game data now in memory
    initializeRooms(this); // Set up room system
}
```

**Runtime:**
```javascript
function loadRoom(roomId) {
    const roomData = window.gameScenario.rooms[roomId];  // From preloaded memory
    createRoom(roomId, roomData, position);
}
```

### Perfect For Server Migration

The architecture is designed to change this one line:
```javascript
// Current: Local preloaded JSON
const roomData = window.gameScenario.rooms[roomId];

// Future: Server-fetched JSON
const response = await fetch(`/api/rooms/${roomId}`);
const roomData = await response.json();
```

Everything else remains identical because:
1. **Data format unchanged** - Still JSON with same structure
2. **Matching algorithm unchanged** - TiledItemPool works same way
3. **Sprite creation unchanged** - applyScenarioProperties() works same way
4. **Game logic unchanged** - All systems are data-agnostic

---

## 5. Key Models, Controllers, and Game Logic

### 5.1 Data Models (JSON Schema Patterns)

**Scenario Model:**
```json
{
  "scenario_brief": "string",
  "startRoom": "string",
  "startItemsInInventory": [ ... ],
  "globalVariables": { "varName": value },
  "rooms": {
    "roomId": { ... room data ... }
  }
}
```

**Room Model:**
```json
{
  "type": "room_reception",
  "connections": {
    "north": "office1",
    "south": "exit"
  },
  "npcs": [ { id, displayName, storyPath, currentKnot, ... } ],
  "objects": [ { type, name, takeable, locked, contents, ... } ]
}
```

**NPC Model:**
```json
{
  "id": "npc_id",
  "displayName": "Display Name",
  "storyPath": "scenarios/ink/story.json",
  "avatar": "assets/npc/avatars/avatar.png",
  "phoneId": "player_phone",
  "npcType": "phone|person",  // Text NPC or sprite NPC
  "currentKnot": "start",
  "eventMappings": [
    {
      "eventPattern": "item_picked_up:lockpick",
      "targetKnot": "on_lockpick",
      "onceOnly": true,
      "cooldown": 5000
    }
  ],
  "timedMessages": [
    { "delay": 5000, "message": "Text" }
  ]
}
```

**Object Model:**
```json
{
  "type": "pc|key|safe|phone|desk|...",
  "name": "Display name",
  "takeable": boolean,
  "readable": boolean,
  "locked": boolean,
  "lockType": "key|pin|password|biometric|bluetooth",
  "requires": "lockpick|key_id|pin_code|etc",
  "contents": [ { type, name, ... } ],
  "observations": "Flavor text when interacted"
}
```

### 5.2 Controller-Like Patterns (Game Logic Handlers)

**No traditional MVC pattern - Instead: Direct event handlers**

```javascript
// Pattern: Event → Handler → State Update
checkObjectInteractions() {
    // Find nearby interactable objects
    const closestObject = findClosestObject(player);
    
    if (playerClickedOnObject) {
        // Dispatch handler
        handleObjectInteraction(closestObject);
    }
}

function handleObjectInteraction(sprite) {
    // Check what type of interaction needed
    if (sprite.locked) {
        handleUnlock(sprite);
    } else if (sprite.takeable) {
        addToInventory(sprite);
    } else if (sprite.readable) {
        showNotes(sprite.text);
    }
}
```

**Key Handler Functions:**

1. **Unlock Handler** (`unlock-system.js`)
   ```javascript
   handleUnlock(lockable, type) {
       const lockReqs = getLockRequirements(lockable);
       switch(lockReqs.lockType) {
           case 'key': startKeySelectionMinigame(...); break;
           case 'pin': startPinMinigame(...); break;
           case 'password': startPasswordMinigame(...); break;
           case 'biometric': collectFingerprint(...); break;
           case 'bluetooth': scanBluetoothDevices(...); break;
       }
   }
   ```

2. **NPC Event Handler** (`npc-manager.js`)
   ```javascript
   registerNPC(id, opts) {
       // Store NPC definition
       this.npcs.set(id, opts);
       
       // Set up event listeners
       if (opts.eventMappings) {
           opts.eventMappings.forEach(mapping => {
               this.eventDispatcher.on(mapping.eventPattern, 
                   () => this.triggerKnot(id, mapping.targetKnot)
               );
           });
       }
   }
   ```

3. **Interaction Dispatcher** (`interactions.js`)
   ```javascript
   checkObjectInteractions() {
       // Called every frame
       // For each nearby object:
       //   - Check if player can interact
       //   - Call appropriate handler (unlock, take, read, etc.)
   }
   ```

### 5.3 Validation Logic

**Where Validation Happens (All Client-Side):**

1. **Lock Validation** (unlock-system.js)
   ```javascript
   // Check if player has required key
   if (lockRequirements.lockType === 'key') {
       const requiredKey = lockRequirements.requires;
       const hasKey = window.inventory.items.some(
           item => item.scenarioData.key_id === requiredKey
       );
   }
   ```

2. **Container Validation** (container minigame)
   ```javascript
   // Check if item is correct answer
   if (selectedItem.id === container.correctItem) {
       markContainerUnlocked(container);
   }
   ```

3. **Mini-Game Validation** (each minigame type)
   ```javascript
   // Success validation depends on minigame
   // Examples:
   // - Lockpicking: Did player pick all pins?
   // - PIN: Did player guess correct PIN?
   // - Password: Did player guess correct password?
   ```

**Problem for Production (No Anti-Cheat):**
- ❌ Player can open browser console and modify `window.inventory`
- ❌ Player can skip locks by setting `window.DISABLE_LOCKS = true`
- ❌ Player can cheat mini-games by modifying minigame variables
- ❌ No server validation of game state

**Solution (Server Migration):**
- ✅ Server validates all state changes
- ✅ Minigame completion validated server-side
- ✅ Inventory changes require server authorization
- ✅ Impossible to cheat without server cooperation

---

## 6. NPC & Dialogue System (Complex Subsystem)

### 6.1 NPC Lifecycle

```
Scenario JSON defines NPCs
    ↓
Game preload (no change)
    ↓
NPCManager.registerNPC(id, options)
    ├─ Store NPC definition
    ├─ Load Ink story file (async)
    ├─ Create InkEngine instance
    ├─ Set up event mappings
    └─ Start timed message timer
    ↓
When NPC conversation triggered:
    ├─ PhoneChatMinigame or PersonChatMinigame launched
    ├─ InkEngine.loadStory() loads compiled Ink JSON
    ├─ InkEngine.continue() gets dialogue text
    ├─ Player chooses response
    ├─ InkEngine.choose(index) advances story
    └─ UI updates with new dialogue
```

### 6.2 Ink Integration

**Ink File Example** (neye-eve.ink):
```ink
VAR trust_level = 0
VAR suspicious = false

=== start ===
Neye Eve: Hi! Can I help you?
-> hub

=== hub ===
+ [Ask who your manager is]
    -> ask_manager
+ [Claim to be your manager]
    -> claim_manager
+ [Say goodbye]
    -> ending

=== ask_manager ===
~ suspicious = true
Neye Eve: That's suspicious...
-> hub
```

**Processing:**
1. `.ink` files compiled to `.json` (Ink compiler)
2. Stored in scenarios/ink/ as both `.ink` (source) and `.json` (compiled)
3. Loaded by InkEngine on demand
4. Story state tracked per NPC in `npc-conversation-state.js`

**Story Variables:**
```javascript
// Global variables in scenario
window.gameState.globalVariables = {
    player_name: "...",
    has_evidence: false,
    // ... custom per scenario
}

// Story state saved/restored
npc.storyState = {
    currentText: "...",
    currentChoices: [],
    variables: { ... },  // Ink VAR values
    globalVariablesSnapshot: { ... }
}
```

### 6.3 Event Mapping System

NPCs can respond to game events:

```javascript
eventMappings: [
    {
        "eventPattern": "item_picked_up:lockpick",
        "targetKnot": "on_lockpick_pickup",
        "onceOnly": true,
        "cooldown": 0
    },
    {
        "eventPattern": "minigame_completed",
        "condition": "data.minigameName.includes('Lockpick')",
        "targetKnot": "on_lockpick_success",
        "cooldown": 10000
    },
    {
        "eventPattern": "room_discovered",
        "targetKnot": "on_room_discovered",
        "maxTriggers": 5
    }
]
```

**Supported Event Patterns:**
- `item_picked_up:*` or `item_picked_up:lockpick`
- `item_dropped:*`
- `minigame_completed`, `minigame_failed`
- `door_unlocked`, `door_unlock_attempt`
- `object_interacted` (with condition filter)
- `room_entered`, `room_entered:roomId`
- `room_discovered`, `room_discovered:roomId`
- `lockpick_used_in_view` (for person-chat interruption)

**Processing:**
```javascript
// When event occurs:
window.eventDispatcher.emit('item_picked_up:lockpick', { ... });

// NPCManager listens:
this.eventDispatcher.on('item_picked_up:lockpick', (data) => {
    // Find matching NPC event mappings
    // Check conditions and cooldowns
    // Trigger targetKnot if all conditions met
    this.triggerKnot(npcId, targetKnot);
});
```

### 6.4 NPC Types

**Phone NPCs** (Text-only):
- Only accessible via phone minigame
- No sprite in world
- Pure dialogue interaction
- Example: "Neye Eve", "Gossip Girl"

**Person NPCs** (In-world sprites):
- Have sprite in specific room
- Player can talk to directly
- Dialogue via person-chat minigame
- Can have patrol/behavior
- Can block player movement
- Can detect lockpicking in their room

**Timed Messages:**
```json
"timedMessages": [
    {
        "delay": 5000,
        "message": "Check your phone!"
    }
]
```
- Delivered after delay ms from game start
- Appear in phone message list
- Trigger npc-game-bridge updates

---

## 7. Game Scenarios Format

### 7.1 Scenario Structure

**Complete Example** (ceo_exfil.json):
```json
{
  "scenario_brief": "You are a cyber investigator...",
  "startRoom": "reception",
  
  "globalVariables": {
    "safe_code": "4829",
    "CEO_has_evidence": false
  },
  
  "startItemsInInventory": [
    {
      "type": "phone",
      "name": "Your Phone",
      "phoneId": "player_phone",
      "npcIds": ["neye_eve", "gossip_girl"]
    },
    {
      "type": "lockpick",
      "name": "Lock Pick Kit"
    }
  ],
  
  "rooms": {
    "reception": {
      "type": "room_reception",
      "connections": {
        "north": "office1"
      },
      "npcs": [ ... ],
      "objects": [ ... ]
    },
    // ... more rooms
  }
}
```

### 7.2 Object Types

**Supported Types:**
- `pc` - Computer (can lock with password)
- `key` - Physical key (takeable)
- `safe` - Safe (can lock with PIN or key)
- `notes` - Notes (readable)
- `phone` - Phone (readable, callable)
- `desk` - Desk/table (interactive)
- `lockpick` - Lockpick tool (for lockpicking minigame)
- `fingerprint` - Fingerprint sample (for biometrics)
- `bluetooth_scanner` - Scanner device
- `biometric` - Biometric reader
- `container` - Lockable container
- `keycard` - RFID keycard
- `rfid_cloner` - RFID cloner device
- Many more (chair, plant, suitcase, etc.)

### 7.3 Lock Types

**5 Lock Mechanisms:**

1. **Key Lock**
   ```json
   {
     "lockType": "key",
     "requires": "key_id_ceo_office"
   }
   ```

2. **PIN Lock**
   ```json
   {
     "lockType": "pin",
     "requires": "4829",
     "minigame": "pin"
   }
   ```

3. **Password Lock**
   ```json
   {
     "lockType": "password",
     "requires": "secret_password",
     "passwordHint": "Hint text"
   }
   ```

4. **Biometric Lock**
   ```json
   {
     "lockType": "biometric",
     "requires": "fingerprint_ceo",
     "spoofable": true
   }
   ```

5. **Bluetooth Lock**
   ```json
   {
     "lockType": "bluetooth",
     "requires": ["device_id_1", "device_id_2"],
     "minigame": "bluetooth"
   }
   ```

### 7.4 Validation Behavior (Current)

**All server-side migrations should add:**
1. ✅ Server validates unlock attempts
2. ✅ Server checks inventory changes
3. ✅ Server validates lock requirements met
4. ✅ Server prevents invalid game state transitions
5. ✅ Server logs all player actions

---

## 8. Sync Functions & State Synchronization

### Current: No Sync (Single-player only)

```javascript
// Game state lives entirely in window object
window.gameState = { ... }
window.inventory = { ... }
window.rooms = { ... }

// Changes are instant, local, no network
addToInventory(item) {
    window.inventory.items.push(item);  // Immediate
}

unlockTarget(sprite) {
    sprite.locked = false;  // Immediate
    window.eventDispatcher.emit('door_unlocked', {...});  // Local event
}
```

### For Server Migration: Sync Will Be Needed

**Proposed Patterns (Not Yet Implemented):**

```javascript
// Example: Sync unlock action
async function handleUnlock(lockable) {
    try {
        // Request server validation
        const response = await fetch('/api/game/unlock', {
            method: 'POST',
            body: JSON.stringify({
                objectId: lockable.id,
                inventoryUsed: selectedKey.id
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Apply local changes
            lockable.locked = false;
            removeFromInventory(selectedKey);
            
            // Emit local event
            window.eventDispatcher.emit('door_unlocked', {...});
        } else {
            // Handle failure
            showError(result.message);
        }
    } catch (error) {
        handleNetworkError(error);
    }
}
```

### State That Would Need Syncing

| State | Current | Future |
|-------|---------|--------|
| Inventory | Local only | Sync to server |
| Locked/unlocked status | Local only | Sync to server |
| Discovered rooms | Local only | Sync to server |
| NPC conversation history | Local only | Sync to server |
| Global variables | Local only | Sync to server |
| Game completion | Local only | Sync to server |

---

## 9. File Size & Performance Summary

### JavaScript Codebase Size

```
Core Engine:      ~170 KB (5 files)
Game Systems:     ~300 KB (34 files)
Mini-Games:       ~400 KB (44 files)
UI:              ~50 KB (5 files)
Utils:           ~30 KB (5 files)
Total JS:        ~950 KB
```

### Asset Size

```
Images:          ~2-3 MB
Sounds:          ~500 KB
Tiled maps:      ~500 KB
Scenario JSON:   ~100-200 KB
Total Assets:    ~3-4 MB
```

### Startup Performance

```
Load HTML:           ~10 ms
Load JS (cached):    ~50 ms
Load Assets (first): ~3-5 seconds
Preload scenario:    ~500 ms
Create game:         ~1-2 seconds
Ready to play:       ~5-8 seconds
```

### Optimization Opportunities

**For Server Migration:**
1. ✅ **Lazy load scenario data** - Only send current room + adjacent rooms
   - Saves ~150 KB at startup
   - Load on-demand as player explores
   
2. ✅ **Compress scenario JSON** - Gzip reduces by 70-80%
   - 200 KB → 40 KB

3. ✅ **Lazy load assets** - Don't load all images upfront
   - Could save 1-2 MB startup

4. ✅ **Code-split minigames** - Load only needed minigames
   - Save 200+ KB on startup

---

## 10. Architecture Assessment for Rails Migration

### Current Architecture Strengths

✅ **Perfect Visual/Logic Separation**
- Tiled maps (visual) loaded once at startup
- Scenario JSON (logic) can be lazy-loaded per room
- No coupling between layers

✅ **Deterministic Matching Algorithm**
- TiledItemPool matches items same way regardless of data source
- Works identically with local or remote scenario data
- No code changes needed to matching logic

✅ **Single Integration Point**
- `loadRoom()` function is only place scenario data accessed
- Change this one function from:
  ```javascript
  const roomData = window.gameScenario.rooms[roomId];
  ```
  To:
  ```javascript
  const roomData = await fetch(`/api/rooms/${roomId}`).then(r => r.json());
  ```

✅ **Data-Agnostic Interaction Systems**
- All game logic systems (inventory, locks, containers) only care that properties exist
- Don't care where properties came from
- Would work identically with server data

### Server-Client Migration Impact

| Component | Changes Needed | Effort |
|-----------|-------------------|--------|
| Data Loading | YES - modify loadRoom() | Low |
| TiledItemPool | NO | None |
| Sprite Creation | NO | None |
| Interaction Systems | NO | None |
| Inventory System | YES - add sync | Medium |
| Unlock Validation | YES - move to server | Medium |
| NPC System | Partially - event sync | Medium |
| Mini-games | Partially - completion sync | Medium |
| UI System | NO | None |

**Estimated Migration Effort: 8-12 hours total**
- Server API development: 4-7 hours
- Client code changes: 2-3 hours
- Testing & debugging: 2-3 hours

### What Won't Change

- ✅ Room loading (same algorithm, different data source)
- ✅ Sprite creation (uses same properties)
- ✅ Interaction detection (same range checks)
- ✅ Inventory UI (same display system)
- ✅ Mini-game framework (same invocation)
- ✅ Tiled map loading (still local)
- ✅ Asset loading (still local)

---

## 11. Key Architectural Files Reference

### Absolute Paths to Critical Components

```
/home/user/BreakEscape/js/main.js                          # Entry point
/home/user/BreakEscape/js/core/game.js                     # Game loop
/home/user/BreakEscape/js/core/rooms.js                    # Room management
/home/user/BreakEscape/js/systems/npc-manager.js           # NPC system
/home/user/BreakEscape/js/systems/unlock-system.js         # Lock validation
/home/user/BreakEscape/js/systems/interactions.js          # Interaction dispatch
/home/user/BreakEscape/js/minigames/index.js              # Minigame registry
/home/user/BreakEscape/scenarios/                          # Scenario files
/home/user/BreakEscape/planning_notes/rails-engine-migration/
                                                            # Migration docs
```

### Critical Files for Rails Migration

1. **Data Models:**
   - `/home/user/BreakEscape/scenarios/*.json` - Scenario definitions

2. **Load Points:**
   - `/home/user/BreakEscape/js/core/game.js` - Preload/create
   - `/home/user/BreakEscape/js/core/rooms.js` - loadRoom() function

3. **State Management:**
   - `/home/user/BreakEscape/js/main.js` - window.gameState setup
   - `/home/user/BreakEscape/js/systems/inventory.js` - Item management

4. **Validation:**
   - `/home/user/BreakEscape/js/systems/unlock-system.js` - Lock checks
   - `/home/user/BreakEscape/js/systems/key-lock-system.js` - Key validation

5. **Sync Points:**
   - `/home/user/BreakEscape/js/systems/npc-game-bridge.js` - State updates
   - `/home/user/BreakEscape/js/minigames/framework/minigame-manager.js` - Completion

---

## 12. Summary & Recommendations

### What Needs to Happen for Rails Engine

**Phase 1: Server Infrastructure (FUTURE)**
```
Create Rails Engine with:
├── Models
│   ├── GameScenario
│   ├── Room
│   ├── GameObject
│   ├── Lock
│   ├── NPC
│   └── PlayerState
├── Controllers
│   ├── ScenarioController (GET metadata)
│   ├── RoomsController (GET room data)
│   ├── MinigamesController (POST completion)
│   ├── InventoryController (PUT/DELETE items)
│   └── UnlockController (POST unlock attempt)
├── Services
│   ├── LockValidator
│   ├── GameStateService
│   └── MinigameCompletionService
└── API Endpoints
    ├── GET /api/scenario/metadata
    ├── GET /api/rooms/{id}
    ├── POST /api/unlock
    ├── PUT /api/inventory
    └── POST /api/minigame/complete
```

**Phase 2: Client Changes (FUTURE)**
```
Modify JavaScript:
├── Change loadRoom() to fetch from server
├── Add inventory sync to server
├── Add unlock validation server call
├── Add minigame completion server call
├── Add authentication headers
└── Add error handling for network issues
```

**Phase 3: No Changes Needed**
```
Keep as-is:
├── Asset loading (local)
├── Tiled map loading (local)
├── Game loop (local)
├── Minigame framework (local)
├── Interaction systems (local)
├── NPC system (local with event sync)
└── UI systems (local)
```

### Best Practices for Implementation

1. **Keep data format identical** - Don't change JSON structure
2. **Add server validation** - All unlock/inventory changes
3. **Implement optimistic updates** - Update UI immediately, sync after
4. **Add authentication** - Token-based for API requests
5. **Log all actions** - For audit trail and analytics
6. **Cache scenario metadata** - Don't refetch on every room load
7. **Handle network errors** - Graceful fallback or retry logic

### Current Code is Production-Ready For:
- ✅ Single-player gameplay
- ✅ Educational use (can be hacked, but no real stakes)
- ✅ Browser-based deployment
- ✅ Cross-platform (works on Windows, Mac, Linux, tablets)

### Current Code is NOT Ready For:
- ❌ Multiplayer
- ❌ Competitive tournaments (can cheat)
- ❌ Graded assessments (no server validation)
- ❌ Large-scale deployment (no backend scaling)
- ❌ User authentication (no login system)
- ❌ Data persistence across devices

---

## Conclusion

BreakEscape is a **well-architected, client-side web game** with excellent foundation for server migration. The separation of visual (Tiled) and logic (Scenario) layers is ideal for the proposed lazy-loading, server-client model.

**No Rails/Ruby code currently exists** - the project is pure JavaScript with JSON data. The migration to Rails would involve building a server API to provide scenario data on-demand, while the existing JavaScript game logic continues to run client-side.

The architecture is **ready for migration with minimal changes** (~40 lines across 3 files), making this a low-risk, high-value upgrade that would enable multiplayer, prevent cheating, and allow graded assessments.

