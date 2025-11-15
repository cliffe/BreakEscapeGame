# Persistent State System - Testing Guide

## Quick Start Testing

### Test 1: Fresh Game (No Persistent State)

1. **Load the game without persistent state:**
   ```
   index.html?scenario=ceo_exfil
   ```

2. **Check console for initialization:**
   ```
   📋 Extracted 7 variable definitions:
      Carry-over: 6
      Session-only: 1
   ```

3. **View persistent state variables:**
   ```javascript
   window.viewPersistentState()
   ```

   Expected output:
   ```
   ═══════════════════════════════════════════════════════════
   📊 PERSISTENT STATE VIEWER
   ═══════════════════════════════════════════════════════════

   🔍 Carry-Over Variables:
      npc_trust_helper: 50 (default: 50)
      npc_trust_gossip_girl: 30 (default: 30)
      topics_discussed_security: [] (default: [])
      topics_discussed_lore: [] (default: [])
      narrative_joined_org: false (default: false)
      mission_ceo_completed: false (default: false)
   ```

4. **Modify some variables (simulate gameplay):**
   ```javascript
   // Change trust level
   window.gameState.globalVariables.npc_trust_helper = 85;

   // Add discussed topics
   window.gameState.globalVariables.topics_discussed_security.push("encryption");
   window.gameState.globalVariables.topics_discussed_security.push("zero_days");

   // Mark narrative decision
   window.gameState.globalVariables.narrative_joined_org = true;
   ```

5. **Export persistent state:**
   ```javascript
   window.downloadPersistentState('my-test-progress.json');
   ```

6. **Verify downloaded file:**
   - Check Downloads folder for `my-test-progress.json`
   - Open and verify structure:
   ```json
   {
     "version": 1,
     "timestamp": "2024-11-15T...",
     "lastScenario": "ceo_exfil",
     "variables": {
       "npc_trust_helper": 85,
       "npc_trust_gossip_girl": 30,
       "topics_discussed_security": ["encryption", "zero_days"],
       "topics_discussed_lore": [],
       "narrative_joined_org": true,
       "mission_ceo_completed": false
     },
     "metadata": {
       "exportedCount": 6,
       "sessionOnlyCount": 1
     }
   }
   ```

### Test 2: Load with Persistent State

1. **Move downloaded file to persistent-states/ directory:**
   ```bash
   mv ~/Downloads/my-test-progress.json persistent-states/
   ```

2. **Reload game with persistent state:**
   ```
   index.html?scenario=ceo_exfil&persistentState=my-test-progress
   ```

3. **Check console for loading messages:**
   ```
   🔄 Persistent state parameter detected: my-test-progress
   🔄 Loading persistent state from: persistent-states/my-test-progress.json
   ✅ Persistent state loaded successfully
      Version: 1
      Last Scenario: ceo_exfil
      Timestamp: 2024-11-15T...
      Variables: 6

   ✅ Loaded npc_trust_helper from persistent state
   ✅ Loaded topics_discussed_security from persistent state
   ✅ Loaded narrative_joined_org from persistent state

   📊 Merge Summary:
      Loaded from persistent state: 6
      Using scenario defaults: 0
   ```

4. **Verify values were loaded:**
   ```javascript
   window.gameState.globalVariables.npc_trust_helper
   // Expected: 85 (not 50!)

   window.gameState.globalVariables.topics_discussed_security
   // Expected: ["encryption", "zero_days"]

   window.gameState.globalVariables.narrative_joined_org
   // Expected: true
   ```

5. **View diff table:**
   ```javascript
   window.viewPersistentState()
   ```

   Expected output shows 📝 markers for changed variables:
   ```
   📝 npc_trust_helper: 85 (default: 50)
   📝 topics_discussed_security: ["encryption","zero_days"] (default: [])
   📝 narrative_joined_org: true (default: false)
      npc_trust_gossip_girl: 30 (default: 30)
   ```

### Test 3: Example Persistent State

1. **Load with provided example:**
   ```
   index.html?scenario=ceo_exfil&persistentState=example-continued-game
   ```

2. **Check console:**
   ```
   ✅ Persistent state loaded successfully
      Version: 1
      Last Scenario: ceo_exfil
      Variables: 5
   ```

3. **Verify values:**
   ```javascript
   window.gameState.globalVariables.npc_trust_helper
   // Expected: 85

   window.gameState.globalVariables.topics_discussed_security
   // Expected: ["encryption", "zero_days", "social_engineering"]

   window.gameState.globalVariables.mission_ceo_completed
   // Expected: true
   ```

### Test 4: Missing File Error Handling

1. **Try to load non-existent file:**
   ```
   index.html?scenario=ceo_exfil&persistentState=does-not-exist
   ```

2. **Check for error handling:**
   - Red notification should appear at top of screen:
     ```
     ⚠️ Persistent state file failed to load
     ```
   - Console should show:
     ```
     ❌ [PSM_004] Persistent state file failed to load
        File may be missing, malformed, or network error occurred
        Proceeding with scenario defaults
     ```
   - Game should continue normally with default values

3. **Verify defaults are used:**
   ```javascript
   window.gameState.globalVariables.npc_trust_helper
   // Expected: 50 (default)
   ```

### Test 5: Type Mismatch Handling

1. **Create malformed persistent state:**

   Create `persistent-states/bad-types.json`:
   ```json
   {
     "version": 1,
     "timestamp": "2024-11-15T00:00:00.000Z",
     "lastScenario": "test",
     "variables": {
       "npc_trust_helper": "not-a-number",
       "topics_discussed_security": "not-an-array",
       "narrative_joined_org": 123
     }
   }
   ```

2. **Load with bad types:**
   ```
   index.html?scenario=ceo_exfil&persistentState=bad-types
   ```

3. **Check console warnings:**
   ```
   ⚠️ [PSM_002] Type mismatch for npc_trust_helper:
      Expected: number, Got: string
      Using default value instead

   ⚠️ [PSM_002] Type mismatch for topics_discussed_security:
      Expected: array, Got: string
      Using default value instead

   ⚠️ [PSM_002] Type mismatch for narrative_joined_org:
      Expected: boolean, Got: number
      Using default value instead

   📊 Merge Summary:
      Loaded from persistent state: 0
      Using scenario defaults: 3
      Type mismatches: 3
   ```

4. **Verify defaults are used for mismatched types:**
   ```javascript
   window.gameState.globalVariables.npc_trust_helper
   // Expected: 50 (default, not "not-a-number")
   ```

### Test 6: Session-Only Variables

1. **Modify both carry-over and session-only variables:**
   ```javascript
   // Carry-over variable
   window.gameState.globalVariables.npc_trust_helper = 100;

   // Session-only variable
   window.gameState.globalVariables.temp_current_mission_phase = 5;
   ```

2. **Export state:**
   ```javascript
   const state = window.exportPersistentState();
   console.log(state);
   ```

3. **Verify session-only variable is NOT exported:**
   ```json
   {
     "variables": {
       "npc_trust_helper": 100,
       // temp_current_mission_phase should NOT be here
     },
     "metadata": {
       "exportedCount": 6,
       "sessionOnlyCount": 1
     }
   }
   ```

### Test 7: Ink Tag Export (Future Test)

This will work once we add the tag to an Ink story:

1. **Add to helper-npc.ink:**
   ```ink
   === mission_success ===
   Congratulations! You've completed the mission!
   ~ mission_ceo_completed = true
   ~ npc_trust_helper = npc_trust_helper + 25
   #export_persistent_state
   -> END
   ```

2. **Trigger the knot in conversation**

3. **Check console:**
   ```
   📤 Export persistent state triggered from Ink
   ✅ Persistent state exported: {...}
   💡 Use window.downloadPersistentState() to save as file
   ```

## Console Commands Reference

```javascript
// View current persistent state (formatted)
window.viewPersistentState()

// Export as JSON object (for inspection)
const state = window.exportPersistentState()
console.log(state)

// Download as file
window.downloadPersistentState()
window.downloadPersistentState('custom-filename.json')

// Access raw global variables
window.gameState.globalVariables

// Access persistent state manager
window.persistentStateManager.debugMode = true  // Enable debug logging
window.persistentStateManager.logStateDiff(window.gameState.globalVariables)
```

## Common Issues & Solutions

### Issue: Persistent state not loading

**Symptoms:**
- No "Persistent state loaded successfully" message
- Variables have default values instead of loaded values

**Solutions:**
1. Check URL parameter is correct: `?persistentState=filename` (no .json needed)
2. Verify file exists in `persistent-states/` directory
3. Check browser console for error messages
4. Verify JSON is valid (use JSONLint.com)

### Issue: Type mismatch warnings

**Symptoms:**
- Console shows `[PSM_002] Type mismatch` warnings
- Variables fall back to defaults

**Solutions:**
1. Check persistent state JSON for correct types:
   - Numbers: `42`, not `"42"`
   - Booleans: `true`, not `"true"`
   - Arrays: `[]`, not `"[]"`
2. Use `window.exportPersistentState()` to generate correct format

### Issue: Variables not persisting

**Symptoms:**
- Export shows variables with default values
- Changes made in-game are not saved

**Solutions:**
1. Verify variable is marked `carryOver: true` in scenario.json
2. Check that you're modifying `window.gameState.globalVariables.varName`
3. Ensure variable exists in scenario's globalVariables definition

### Issue: "Persistent state manager not initialized"

**Symptoms:**
- Console commands return error
- Export doesn't work

**Solutions:**
1. Wait for game to fully load (manager initializes in create())
2. Check browser console for initialization errors
3. Verify game loaded successfully

## Next Steps

After basic testing:

1. **Create cross-scenario test:**
   - Complete ceo_exfil scenario
   - Export state
   - Create a second scenario that uses same variables
   - Load second scenario with exported state
   - Verify variables carry over

2. **Test with Ink integration:**
   - Add carry-over variables to Ink stories
   - Test variable checks in Ink (e.g., `{npc_trust_helper >= 75}`)
   - Test array checks (e.g., `{topics_discussed_security ? encryption}`)
   - Test export tag in victory condition

3. **Performance testing:**
   - Test with 100+ variables
   - Test with large arrays (1000+ items)
   - Test with deeply nested objects

4. **Edge cases:**
   - Empty persistent state file
   - Persistent state with unknown variables
   - Partial persistent state (only some variables)
   - Multiple scenario transitions

## Success Criteria

✅ Fresh game initializes with defaults
✅ Export creates valid JSON file
✅ Load applies persistent state correctly
✅ Type validation catches mismatches
✅ Session-only variables not exported
✅ Missing file handled gracefully
✅ Console commands work as expected
✅ Variables sync to/from Ink stories
✅ Diff viewer shows changes clearly
✅ Cross-scenario persistence works

## Reporting Issues

If you find bugs or unexpected behavior:

1. Note the exact steps to reproduce
2. Include console output (especially error messages)
3. Include persistent state JSON if relevant
4. Note expected vs actual behavior
5. Check error code (PSM_001-005) for context
