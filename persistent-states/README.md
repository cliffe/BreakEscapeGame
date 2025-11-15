# Persistent Game States

This directory contains persistent state files that carry variable values across game scenarios.

## What is Persistent State?

Persistent state is NOT a "save game" feature - it's a cross-scenario narrative persistence system that allows:
- NPC trust levels to carry over between scenarios
- Discussion topics to be tracked (preventing repetition)
- Narrative decisions to have consequences in later games
- Scenarios to be completed in any order while maintaining continuity

## Usage

### Loading a Persistent State

Add the `persistentState` URL parameter when loading a game:

```
index.html?scenario=ceo_exfil&persistentState=example-continued-game
```

The system will:
1. Load the specified persistent state JSON file
2. Merge it with the scenario's default variable values
3. Initialize global variables with the merged values

### Exporting Your Progress

After completing a game, export your state from the browser console:

```javascript
// View current persistent state
window.viewPersistentState();

// Export as JSON object
const state = window.exportPersistentState();

// Download as JSON file
window.downloadPersistentState('my-progress.json');
```

## File Format

Persistent state files use this JSON structure:

```json
{
  "version": 1,
  "timestamp": "2024-11-14T12:00:00.000Z",
  "lastScenario": "scenario_id",
  "variables": {
    "variable_name": "value"
  },
  "metadata": {
    "exportedCount": 5,
    "sessionOnlyCount": 2
  }
}
```

### Fields

- **version** (number): Schema version for future migrations
- **timestamp** (string): ISO 8601 timestamp of when state was exported
- **lastScenario** (string): ID of the scenario that produced this state
- **variables** (object): Key-value pairs of carry-over variables
- **metadata** (object): Statistics about the export (optional)

## Variable Types

The system supports:
- **Primitives**: strings, numbers, booleans
- **Arrays**: lists of values
- **Objects**: nested data structures

## Examples

### Example 1: Fresh Player

No persistent state file - all variables use scenario defaults.

```
index.html?scenario=ceo_exfil
```

### Example 2: Continued Story

Load with previous progress:

```
index.html?scenario=server_breach&persistentState=example-continued-game
```

NPCs will remember your trust level, topics discussed, and narrative choices.

### Example 3: Custom Progress

Create your own persistent state file:

```json
{
  "version": 1,
  "timestamp": "2024-11-14T15:30:00.000Z",
  "lastScenario": "custom_scenario",
  "variables": {
    "npc_trust_helper": 100,
    "narrative_joined_org": false
  }
}
```

Save as `my-custom-state.json` in this directory, then load:

```
index.html?scenario=next_mission&persistentState=my-custom-state
```

## Creating Carry-Over Variables

### In Scenario JSON

Define which variables carry over in `scenario.json`:

```json
{
  "scenario_id": "my_scenario",
  "globalVariables": {
    "npc_trust_guard": {
      "default": 0,
      "carryOver": true,
      "type": "number",
      "description": "Trust level with security guard"
    },
    "topics_discussed": {
      "default": [],
      "carryOver": true,
      "type": "array"
    },
    "temp_session_var": 42
  }
}
```

**Key points:**
- Variables with `carryOver: true` persist across scenarios
- Variables without metadata (like `temp_session_var`) are session-only
- `default` provides the initial value for new players

### In Ink Stories

Use carry-over variables in your Ink scripts:

```ink
=== start ===
{npc_trust_guard >= 75:
    "Good to see you again, friend! I trust you."
- else:
    "Who are you? State your business."
}

~ npc_trust_guard = npc_trust_guard + 10

{topics_discussed ? encryption:
    // Already discussed this topic
    -> already_know_encryption
- else:
    // New topic
    -> introduce_encryption
}

=== introduce_encryption ===
Let me tell you about encryption...
~ topics_discussed += "encryption"
-> END
```

## Automatic Export on Victory

Trigger export from Ink when the player wins:

```ink
=== mission_complete ===
Congratulations! You've completed the mission.
~ mission_completed = true
#export_persistent_state
-> END
```

The `#export_persistent_state` tag will trigger an automatic export to the console.

## Troubleshooting

### Persistent State Not Loading

Check the browser console for errors:
- `[PSM_004] LOAD_FAILED` - File not found or network error
- `[PSM_001] INVALID_JSON` - Malformed JSON file
- `[PSM_002] TYPE_MISMATCH` - Variable type doesn't match scenario definition

### Variables Not Carrying Over

1. Check that the variable is defined with `carryOver: true` in scenario.json
2. Verify the variable exists in your persistent state file
3. Check console logs for type mismatches
4. Use `window.viewPersistentState()` to see what's loaded

### Type Mismatches

If you see type mismatch warnings, the persistent value will be ignored and the default used instead:

```
⚠️ [PSM_002] Type mismatch for some_var:
   Expected: number, Got: string
   Using default value instead
```

Fix by correcting the type in your persistent state file.

## Best Practices

1. **Use clear naming conventions**:
   - `npc_trust_{npc_id}` - Trust levels
   - `topics_{category}` - Discussion topics
   - `narrative_{decision}` - Major story choices
   - `mission_{name}_completed` - Completion flags

2. **Keep state minimal**: Only persist essential narrative variables

3. **Document variables**: Add descriptions in scenario.json

4. **Test cross-scenario**: Verify variables work across different scenarios

5. **Version your schema**: Increment version when changing variable structure

## See Also

- `/planning_notes/state_save/implementation_plan.md` - Technical implementation details
- `/scenarios/ceo_exfil.json` - Example scenario with carry-over variables
