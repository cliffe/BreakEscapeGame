# Game State Persistence System - Implementation Plan

## Overview

This system enables variable state to carry over between game scenarios, allowing:
- NPC trust levels to persist across games
- Discussion topics to be tracked (preventing repetition)
- Narrative decisions to have consequences in later scenarios
- Scenarios to be played in any order while maintaining continuity

**Key Principle**: This is NOT a "save game" feature - it's a cross-scenario narrative persistence layer.

---

## Design Decisions

### 1. Variable Declaration Strategy: Metadata Properties

We'll use **Option 1** from the design options - metadata properties in `globalVariables`:

```json
{
  "globalVariables": {
    "npc_trust_guard": {
      "default": 0,
      "carryOver": true,
      "description": "Trust level with security guard"
    },
    "topics_discussed_lore": {
      "default": [],
      "carryOver": true
    },
    "temp_room_discovered": {
      "default": false,
      "carryOver": false
    }
  }
}
```

**Backward Compatibility**: Support simple values for non-carry-over variables:
```json
{
  "globalVariables": {
    "npc_trust_guard": {
      "default": 0,
      "carryOver": true
    },
    "temp_session_var": false  // Simple value = session-only, not carried over
  }
}
```

### 2. Storage Strategy

**Phase 1 (Current Implementation)**:
- **Import**: Load from JSON file via URL parameter `?persistentState=path/to/state.json`
- **Export**: JavaScript function callable from console: `window.exportPersistentState()`
- **Auto-export on Victory**: Hook into victory condition to call export function

**Phase 2 (Future)**:
- POST to server endpoint when game ends in victory
- Server manages persistent state per player

### 3. Data Flow

```
┌─────────────────────┐
│ persistent-state.json│
│ (URL parameter)     │
└──────┬──────────────┘
       │ Load on startup
       ↓
┌─────────────────────┐      ┌──────────────────┐
│ scenario.json       │      │ Persistent State │
│ .globalVariables    │──────┤ (loaded from URL)│
│   with metadata     │ Merge└──────────────────┘
└──────┬──────────────┘  │
       │                 │
       ↓                 ↓
┌──────────────────────────────┐
│ window.gameState             │
│   .globalVariables           │ ←── Synced bidirectionally
│   .persistentStateManager    │     during gameplay
└──────┬───────────────────────┘
       │
       ↓
┌──────────────────────────────┐
│ Ink Stories (NPCs)           │
│   via NPCConversationState   │
└──────┬───────────────────────┘
       │
       ↓ On victory/export
┌──────────────────────────────┐
│ Exported JSON                │
│ (console/server endpoint)    │
└──────────────────────────────┘
```

### 4. Merge Strategy

When loading persistent state:

1. **Parse scenario.json globalVariables** → Extract defaults and carryOver flags
2. **Load persistent state JSON** (if provided via URL)
3. **Merge**:
   - For variables marked `carryOver: true`:
     - Use persistent state value if exists
     - Otherwise use scenario default
   - For variables NOT marked `carryOver: true`:
     - Always use scenario default (ignore persistent state)
4. **Initialize** `window.gameState.globalVariables` with merged values

---

## Data Structures

### Scenario JSON Schema (Enhanced)

```json
{
  "scenario_brief": "Mission description",
  "globalVariables": {
    "npc_trust_security_guard": {
      "default": 0,
      "carryOver": true,
      "type": "number",
      "description": "Trust level with security guard (0-100)"
    },
    "npc_trust_helper_npc": {
      "default": 50,
      "carryOver": true,
      "type": "number"
    },
    "topics_lore_cybersec": {
      "default": [],
      "carryOver": true,
      "type": "array",
      "description": "Cybersecurity lore topics discussed"
    },
    "topics_lore_corporate": {
      "default": [],
      "carryOver": true,
      "type": "array"
    },
    "narrative_joined_org": {
      "default": false,
      "carryOver": true,
      "type": "boolean"
    },
    "narrative_betrayed_contact": {
      "default": false,
      "carryOver": true,
      "type": "boolean"
    },
    "temp_current_mission_phase": {
      "default": 1,
      "carryOver": false,
      "type": "number"
    },
    "simple_session_var": "value"  // Simple values default to carryOver: false
  },
  "startRoom": "reception",
  "rooms": { /* ... */ }
}
```

### Persistent State JSON Format

```json
{
  "version": 1,
  "timestamp": "2024-11-14T12:34:56.789Z",
  "lastScenario": "ceo_exfil",
  "variables": {
    "npc_trust_security_guard": 75,
    "npc_trust_helper_npc": 85,
    "topics_lore_cybersec": ["encryption", "zero_days", "social_engineering"],
    "topics_lore_corporate": ["mergers", "insider_trading"],
    "narrative_joined_org": true,
    "narrative_betrayed_contact": false
  }
}
```

**Key Fields**:
- `version`: Schema version for future migrations (start at 1)
- `timestamp`: When this state was exported
- `lastScenario`: ID of scenario that produced this state (for debugging)
- `variables`: Key-value map of carry-over variables only

---

## Implementation Steps

### Step 1: Create Persistent State Manager Module

**File**: `js/systems/persistent-state-manager.js` (NEW)

**Responsibilities**:
- Load persistent state from URL parameter
- Parse and validate persistent state JSON
- Merge persistent state with scenario defaults
- Extract carry-over metadata from scenario.json
- Export current persistent state as JSON
- Provide console commands for debugging

**Key Functions**:
```javascript
class PersistentStateManager {
  constructor() {
    this.version = 1;
    this.loadedState = null;
    this.carryOverMetadata = new Map(); // varName → { default, type, description }
  }

  // Load persistent state from URL param
  async loadPersistentStateFromURL(urlParams) { }

  // Extract carry-over variable metadata from scenario
  extractCarryOverMetadata(scenarioGlobalVariables) { }

  // Merge persistent state with scenario defaults
  mergeWithScenarioDefaults(persistentState, scenarioGlobalVariables) { }

  // Export current persistent state
  exportPersistentState(lastScenarioId) { }

  // Download as JSON file
  downloadAsJSON(filename) { }

  // Console command: view current state
  viewPersistentState() { }

  // Future: POST to server endpoint
  async postToServer(endpoint, authToken) { }
}
```

### Step 2: Modify game.js to Integrate Persistent State

**File**: `js/core/game.js`

**Location**: `preload()` function (around line 411-430)

**Changes**:

1. **Load persistent state file** (if URL param provided):

```javascript
// After loading scenario.json
const urlParams = new URLSearchParams(window.location.search);

// Load persistent state if provided
let persistentStateFile = urlParams.get('persistentState');
if (persistentStateFile) {
    // Ensure proper path prefix
    if (!persistentStateFile.startsWith('persistent-states/')) {
        persistentStateFile = `persistent-states/${persistentStateFile}`;
    }

    // Ensure .json extension
    if (!persistentStateFile.endsWith('.json')) {
        persistentStateFile = `${persistentStateFile}.json`;
    }

    // Add cache buster
    persistentStateFile = `${persistentStateFile}?v=${Date.now()}`;

    // Load the persistent state
    this.load.json('persistentStateJSON', persistentStateFile);
    console.log('🔄 Loading persistent state from:', persistentStateFile);
}
```

**Location**: `create()` function (around line 461-467)

**Changes**:

2. **Initialize PersistentStateManager and merge state**:

```javascript
import { PersistentStateManager } from '../systems/persistent-state-manager.js';

// In create() function, BEFORE initializing global variables:

// Initialize persistent state manager
window.persistentStateManager = new PersistentStateManager();

// Load persistent state from cache if it was loaded
const persistentStateJSON = this.cache.json.get('persistentStateJSON');
if (persistentStateJSON) {
    console.log('🔄 Loaded persistent state:', persistentStateJSON);
    window.persistentStateManager.loadedState = persistentStateJSON;
}

// Extract carry-over metadata from scenario
if (gameScenario.globalVariables) {
    window.persistentStateManager.extractCarryOverMetadata(gameScenario.globalVariables);
}

// Merge persistent state with scenario defaults
const mergedVariables = window.persistentStateManager.mergeWithScenarioDefaults(
    persistentStateJSON?.variables,
    gameScenario.globalVariables
);

// Initialize global variables with merged values
window.gameState.globalVariables = mergedVariables;
console.log('🌐 Initialized global variables (with persistent state):', window.gameState.globalVariables);
```

### Step 3: Enhance NPCConversationStateManager

**File**: `js/systems/npc-conversation-state.js`

**No major changes needed** - this module already handles global variable syncing.

**Optional Enhancement**: Add logging when persistent variables change:

```javascript
// In syncGlobalVariablesFromStory() around line 267
if (oldValue !== newValue) {
    window.gameState.globalVariables[name] = newValue;
    changed.push({ name, value: newValue });

    // Check if this is a carry-over variable
    const isCarryOver = window.persistentStateManager?.carryOverMetadata.has(name);
    const logPrefix = isCarryOver ? '🔄' : '🔄';
    console.log(`${logPrefix} Global variable ${name} changed from ${oldValue} to ${newValue}` +
                (isCarryOver ? ' [PERSISTENT]' : ''));
}
```

### Step 4: Add Export Functions

**File**: `js/systems/persistent-state-manager.js`

**Functions to implement**:

```javascript
/**
 * Export current carry-over variables as JSON
 * @param {string} lastScenarioId - ID of current scenario
 * @returns {Object} Persistent state object
 */
exportPersistentState(lastScenarioId = 'unknown') {
    const exported = {
        version: this.version,
        timestamp: new Date().toISOString(),
        lastScenario: lastScenarioId,
        variables: {}
    };

    // Extract only carry-over variables
    this.carryOverMetadata.forEach((metadata, varName) => {
        if (window.gameState.globalVariables.hasOwnProperty(varName)) {
            exported.variables[varName] = window.gameState.globalVariables[varName];
        }
    });

    console.log('📤 Exported persistent state:', exported);
    return exported;
}

/**
 * Download persistent state as JSON file
 * @param {string} filename - Output filename
 */
downloadAsJSON(filename = 'persistent-state.json') {
    const scenarioId = window.gameScenario?.scenario_id || 'game';
    const state = this.exportPersistentState(scenarioId);

    const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    console.log('✅ Downloaded persistent state as:', filename);
}

/**
 * Console command to view persistent state
 */
viewPersistentState() {
    console.log('═══════════════════════════════════════');
    console.log('📊 PERSISTENT STATE VIEWER');
    console.log('═══════════════════════════════════════');

    console.log('\n🔍 Carry-Over Variables:');
    this.carryOverMetadata.forEach((metadata, varName) => {
        const currentValue = window.gameState.globalVariables[varName];
        console.log(`  ${varName}:`, currentValue, `(default: ${metadata.default})`);
    });

    console.log('\n📦 Full Export Preview:');
    const exported = this.exportPersistentState();
    console.log(JSON.stringify(exported, null, 2));

    console.log('\n💡 Commands:');
    console.log('  window.exportPersistentState() - Export as JSON');
    console.log('  window.downloadPersistentState() - Download JSON file');
    console.log('═══════════════════════════════════════');
}
```

### Step 5: Add Global Console Commands

**File**: `js/main.js`

**Location**: After initializing window.gameState

**Add**:

```javascript
// Expose persistent state functions to console
window.exportPersistentState = () => {
    if (!window.persistentStateManager) {
        console.error('❌ Persistent state manager not initialized');
        return null;
    }
    const scenarioId = window.gameScenario?.scenario_id || 'game';
    return window.persistentStateManager.exportPersistentState(scenarioId);
};

window.downloadPersistentState = (filename) => {
    if (!window.persistentStateManager) {
        console.error('❌ Persistent state manager not initialized');
        return;
    }
    window.persistentStateManager.downloadAsJSON(filename);
};

window.viewPersistentState = () => {
    if (!window.persistentStateManager) {
        console.error('❌ Persistent state manager not initialized');
        return;
    }
    window.persistentStateManager.viewPersistentState();
};

console.log('💾 Persistent State Commands Available:');
console.log('  window.exportPersistentState() - Export state as JSON object');
console.log('  window.downloadPersistentState(filename) - Download state as file');
console.log('  window.viewPersistentState() - View current persistent state');
```

### Step 6: Hook Export to Victory Condition

**Strategy**: Use the existing event system to trigger export on victory.

**Possible approaches**:

1. **Listen for specific victory events** (if they exist):
   - `scenario_completed`
   - `objective_completed:final`
   - etc.

2. **Hook into item pickup of flag/evidence**:
   - Detect when player picks up the final evidence
   - Trigger export automatically

3. **Manual trigger from Ink** (most flexible):
   - Add an Ink tag: `#export_persistent_state`
   - Process in conversation handlers

**Recommended**: Approach 3 (Ink tag)

**File**: `js/minigames/person-chat/person-chat-conversation.js`

**Location**: `processInkTags()` function (around line 269-457)

**Add**:

```javascript
// Around line 450, add new case:
case 'export_persistent_state':
    console.log('📤 Exporting persistent state (triggered by Ink)');
    if (window.persistentStateManager) {
        const scenarioId = window.gameScenario?.scenario_id || 'game';
        const exported = window.persistentStateManager.exportPersistentState(scenarioId);
        console.log('✅ Persistent state exported:', exported);

        // Future: POST to server
        // await window.persistentStateManager.postToServer('/api/save-state', authToken);
    }
    break;
```

**Same change in**: `js/minigames/phone-chat/phone-chat-conversation.js`

### Step 7: Create Example Files

**File**: `persistent-states/example-continued-game.json` (NEW)

```json
{
  "version": 1,
  "timestamp": "2024-11-14T12:00:00.000Z",
  "lastScenario": "ceo_exfil",
  "variables": {
    "npc_trust_security_guard": 75,
    "npc_trust_helper_npc": 85,
    "topics_lore_cybersec": ["encryption", "zero_days"],
    "narrative_joined_org": true
  }
}
```

**File**: `persistent-states/README.md` (NEW)

```markdown
# Persistent Game States

This directory contains persistent state files that carry variable values across game scenarios.

## Usage

Load a persistent state by adding the `persistentState` URL parameter:

```
index.html?scenario=ceo_exfil&persistentState=example-continued-game
```

## File Format

See `example-continued-game.json` for the schema.

## Exporting State

From the browser console after completing a game:

```javascript
// View current persistent state
window.viewPersistentState();

// Download as JSON file
window.downloadPersistentState('my-progress.json');
```
```

### Step 8: Update Example Scenario

**File**: `scenarios/ceo_exfil.json`

**Add globalVariables section** (if not present) or enhance it:

```json
{
  "scenario_brief": "...",
  "scenario_id": "ceo_exfil",
  "globalVariables": {
    "npc_trust_helper": {
      "default": 50,
      "carryOver": true,
      "type": "number",
      "description": "Trust level with helpful contact"
    },
    "topics_discussed_security": {
      "default": [],
      "carryOver": true,
      "type": "array",
      "description": "Security topics discussed with helper NPC"
    },
    "mission_ceo_completed": {
      "default": false,
      "carryOver": true,
      "type": "boolean",
      "description": "Whether CEO exfil mission was completed"
    }
  },
  "startRoom": "reception",
  "rooms": { /* ... */ }
}
```

### Step 9: Update Ink Stories to Use Persistent Variables

**Example**: `scenarios/ink/helper-npc.ink`

**Add logic that checks persistent state**:

```ink
=== start ===
{topics_discussed_security ? encryption:
    // Already discussed encryption in previous game
    -> already_know_encryption
- else:
    // First time discussing encryption
    -> introduce_encryption
}

=== introduce_encryption ===
Let me tell you about encryption fundamentals...
~ topics_discussed_security += "encryption"
~ npc_trust_helper = npc_trust_helper + 10
-> END

=== already_know_encryption ===
You already know about encryption. Let's talk about something new.
+ [Advanced cryptography] -> advanced_crypto
+ [Social engineering] -> social_engineering
-> END
```

---

## Implementation Todo List

### Phase 1: Core Infrastructure (Essential)

1. **Create PersistentStateManager module** (`js/systems/persistent-state-manager.js`)
   - [ ] Create class skeleton
   - [ ] Implement `extractCarryOverMetadata()`
   - [ ] Implement `mergeWithScenarioDefaults()`
   - [ ] Implement `exportPersistentState()`
   - [ ] Implement `downloadAsJSON()`
   - [ ] Implement `viewPersistentState()`
   - [ ] Add validation and error handling
   - [ ] Add comprehensive logging

2. **Modify game.js for persistent state loading**
   - [ ] Add persistent state file loading in `preload()`
   - [ ] Import PersistentStateManager
   - [ ] Initialize manager in `create()`
   - [ ] Extract carry-over metadata from scenario
   - [ ] Merge persistent state with scenario defaults
   - [ ] Replace current globalVariables initialization with merged values
   - [ ] Add logging for debugging

3. **Add global console commands** (`js/main.js`)
   - [ ] Expose `window.exportPersistentState()`
   - [ ] Expose `window.downloadPersistentState()`
   - [ ] Expose `window.viewPersistentState()`
   - [ ] Add help text to console on startup

4. **Create directory structure**
   - [ ] Create `persistent-states/` directory
   - [ ] Create `persistent-states/README.md`
   - [ ] Create example file: `persistent-states/example-continued-game.json`

### Phase 2: Integration & Triggers (Important)

5. **Add export triggers to conversation handlers**
   - [ ] Add `#export_persistent_state` tag handler to `person-chat-conversation.js`
   - [ ] Add same handler to `phone-chat-conversation.js`
   - [ ] Test tag triggers export correctly

6. **Enhance logging in NPCConversationStateManager** (Optional but helpful)
   - [ ] Mark persistent variables with [PERSISTENT] in logs
   - [ ] Add warnings when persistent variables change unexpectedly

### Phase 3: Documentation & Examples (Helpful)

7. **Update scenario example**
   - [ ] Add/enhance `globalVariables` in `scenarios/ceo_exfil.json`
   - [ ] Add carry-over metadata to key variables
   - [ ] Add `scenario_id` field

8. **Update Ink stories with persistent logic**
   - [ ] Update `helper-npc.ink` to check `topics_discussed` array
   - [ ] Add trust level modifications
   - [ ] Add victory condition with `#export_persistent_state` tag

9. **Create documentation**
   - [ ] Add usage guide to main README
   - [ ] Document globalVariables metadata schema
   - [ ] Document URL parameter usage
   - [ ] Document console commands

### Phase 4: Testing (Critical)

10. **Test persistent state loading**
    - [ ] Test loading valid persistent state JSON
    - [ ] Test loading with missing file (graceful degradation)
    - [ ] Test loading with invalid JSON (error handling)
    - [ ] Test loading with mismatched variables (partial merge)

11. **Test variable merging**
    - [ ] Test carry-over variables override defaults
    - [ ] Test session-only variables use scenario defaults
    - [ ] Test simple value syntax (backward compat)
    - [ ] Test complex metadata syntax

12. **Test export functionality**
    - [ ] Test `exportPersistentState()` returns correct JSON
    - [ ] Test `downloadPersistentState()` creates valid file
    - [ ] Test `viewPersistentState()` displays correctly
    - [ ] Test export triggered from Ink tag

13. **Test cross-scenario persistence**
    - [ ] Complete scenario A, export state
    - [ ] Load scenario B with exported state
    - [ ] Verify carry-over variables maintained
    - [ ] Verify session variables reset

### Phase 5: Future Enhancements (Post-MVP)

14. **Server integration** (Future)
    - [ ] Implement `postToServer()` function
    - [ ] Add authentication token handling
    - [ ] Add retry logic for network failures
    - [ ] Add success/failure callbacks

15. **Advanced features** (Future)
    - [ ] Add schema versioning and migration support
    - [ ] Add variable type validation
    - [ ] Add min/max constraints for numbers
    - [ ] Add debug UI panel for viewing/editing state
    - [ ] Add "reset to defaults" functionality

---

## Testing Scenarios

### Test 1: Fresh Start (No Persistent State)
1. Load game without `persistentState` parameter
2. Verify all variables use scenario defaults
3. Complete game and export state
4. Verify exported JSON contains correct values

### Test 2: Continued Game (With Persistent State)
1. Load game with `persistentState=example-continued-game`
2. Verify carry-over variables loaded from persistent state
3. Verify session-only variables use scenario defaults
4. Modify variables during gameplay
5. Export state and verify changes reflected

### Test 3: Partial Persistent State
1. Create persistent state with only SOME carry-over variables
2. Load game
3. Verify loaded variables use persistent state
4. Verify missing variables use scenario defaults

### Test 4: Cross-Scenario Persistence
1. Complete "CEO Exfil" scenario
2. Export persistent state
3. Load "Server Room" scenario with exported state
4. Verify shared variables (e.g., `npc_trust_helper`) persist
5. Verify scenario-specific variables reset

### Test 5: Backward Compatibility
1. Load scenario using old simple syntax: `"var": value`
2. Verify variables work as session-only
3. Mix simple and metadata syntax
4. Verify both work correctly

---

## File Changes Summary

### New Files
- `js/systems/persistent-state-manager.js` - Core module
- `persistent-states/example-continued-game.json` - Example state
- `persistent-states/README.md` - Documentation

### Modified Files
- `js/core/game.js` - Add persistent state loading and merging
- `js/main.js` - Add global console commands
- `js/minigames/person-chat/person-chat-conversation.js` - Add export tag handler
- `js/minigames/phone-chat/phone-chat-conversation.js` - Add export tag handler
- `scenarios/ceo_exfil.json` - Add enhanced globalVariables with metadata
- `scenarios/ink/helper-npc.ink` - Add persistent variable logic (example)

### Optional Enhancements
- `js/systems/npc-conversation-state.js` - Enhanced logging for persistent vars

---

## Implementation Risks & Mitigations

### Risk 1: Breaking Existing Games
**Mitigation**: Support both simple and metadata syntax. If `globalVariables[key]` is not an object, treat it as simple value with `carryOver: false`.

### Risk 2: Persistent State Conflicts
**Mitigation**: Always prefer persistent state for carry-over variables, but validate types before applying.

### Risk 3: Performance with Large States
**Mitigation**: Limit carry-over variables to essential narrative state. Avoid storing large arrays/objects.

### Risk 4: Invalid JSON Files
**Mitigation**: Wrap JSON parsing in try-catch, log errors, fall back to defaults gracefully.

### Risk 5: Security (Future Server Integration)
**Mitigation**: Validate all incoming persistent state on server, sanitize values, enforce rate limits.

---

## Success Criteria

✅ Can load persistent state from JSON file via URL parameter
✅ Carry-over variables override scenario defaults when loaded
✅ Session-only variables always use scenario defaults
✅ Can export current persistent state via console command
✅ Can download persistent state as JSON file
✅ Export can be triggered from Ink via tag
✅ Backward compatible with simple globalVariables syntax
✅ Clear logging shows when persistent state is loaded/exported
✅ Cross-scenario persistence works (variables carry over between games)
✅ Graceful degradation when persistent state file missing or invalid

---

## Future Considerations

1. **Server-Side Persistence**
   - User authentication and session management
   - Cloud storage of persistent state
   - Automatic sync on game end

2. **Multiple Save Slots**
   - Allow multiple persistent state "profiles"
   - Let players choose which profile to continue

3. **State Versioning**
   - Handle schema changes between game versions
   - Provide migration functions for old states

4. **State Validation**
   - Type checking (string, number, boolean, array)
   - Range validation (min/max for numbers)
   - Required vs optional variables

5. **Debug Tools**
   - In-game UI for viewing/editing persistent state
   - Timeline showing variable changes
   - Diff view between scenarios

6. **Analytics**
   - Track which narrative paths players take
   - Identify popular decision trees
   - Balance game difficulty based on persistence data

---

## Notes

- Keep persistent state **minimal** - only essential narrative variables
- Use **clear naming conventions**: `npc_trust_*`, `topics_*`, `narrative_*`
- Document **all carry-over variables** with descriptions
- Test **cross-scenario compatibility** thoroughly
- Consider **data privacy** for future server integration
