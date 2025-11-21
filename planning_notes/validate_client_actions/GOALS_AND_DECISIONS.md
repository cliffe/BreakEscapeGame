# Client Action Validation & Data Filtering: Goals & Design Decisions

**Date:** November 21, 2025  
**Status:** Design Document  
**Context:** Server-side validation and data filtering for Break Escape game

---

## Executive Summary

This document captures the strategic goals and design decisions for implementing server-side validation and intelligent data filtering in Break Escape. The system prevents client-side cheating by validating all player actions server-side while maintaining clean separation between sensitive data (solutions) and game mechanics.

---

## Strategic Goals

### Primary Goals

1. **Prevent Client-Side Cheating**
   - Players cannot modify client code to unlock doors without solving puzzles
   - Players cannot access locked container contents without unlocking them
   - Players cannot collect items they shouldn't have access to
   - Players cannot access rooms before they're supposed to

2. **Maintain Security Without Exposing Solutions**
   - Send game data to client without revealing answers
   - Hide the `requires` field (the solution/password/PIN)
   - Hide `contents` of locked containers until unlocked
   - Verify all unlock attempts server-side

3. **Enable Rich Client Experience**
   - Client needs enough data to render rooms and interactions
   - Client needs item/object information (descriptions, types, appearances)
   - Client needs NPC presence and information
   - Client needs lock information (type, not answer)

4. **Track Player Progression**
   - Know which rooms player can access
   - Know which objects player has unlocked
   - Know which NPCs player has encountered
   - Know what's in player inventory

5. **Support Lazy-Loading Architecture**
   - Rooms load dynamically as needed
   - Container contents load on-demand after unlock
   - Reduce initial payload size
   - Enable scalable scenarios with many rooms

### Secondary Goals

1. **Audit & Analytics**
   - Track what players collect and when
   - Record unlock attempts and successes
   - Monitor for suspicious activity (future)

2. **Extensibility**
   - Design supports future features (rate limiting, attempt logging)
   - Container system works for any lockable object
   - NPC state tracking foundation for future dialogue progression

3. **Clean Architecture**
   - Separation of concerns (model keeps raw data, controller filters)
   - Reusable validation helpers
   - Consistent error responses

---

## Key Design Decisions

### Decision 1: Filter at Controller Level (Not Model)

**Decision:** Keep `scenario_data` raw in Game model. Filter in controller responses.

**Rationale:**
- ✅ Single source of truth - scenario_data unchanged
- ✅ Different endpoints can filter differently
- ✅ Easier to debug (compare raw vs filtered)
- ✅ Model doesn't need to know about view concerns
- ✅ Faster queries (no JSON transforms in DB)

**Alternative Considered:**
- Filter at model level via method - adds coupling, harder to customize per endpoint

**Implementation:**
```ruby
# Game model stays pure
scenario_data = { "rooms" => { ... }, "requires" => "secret" }

# Controller decides what to expose
filtered_data = @game.filtered_room_data(room_id)  # Returns data minus 'requires'
```

---

### Decision 2: Hide Only `requires` and `contents` (Not `lockType`)

**Decision:** 
- HIDE: `requires` field (the answer: password, PIN, key_id, etc.)
- HIDE: `contents` field (what's inside locked containers)
- SHOW: Everything else (`lockType`, `locked`, `observations`, etc.)

**Rationale:**
- ✅ Client needs to know HOW to unlock (lockType: "password" vs "key" vs "pin")
- ✅ Client needs to know IF something is locked (locked: true/false)
- ✅ Player knows what's in a safe IRL - they see it's a lock, just don't know combo
- ✅ Minimal filtering - removes only what breaks security

**Alternative Considered:**
- Hide `lockType` too - breaks UX, client can't show correct UI for password vs PIN vs key
- Hide `locked` status - breaks feedback, player doesn't know if something is unlocked

**Example:**
```json
// Client sees:
{
  "type": "safe",
  "name": "Reception Safe",
  "locked": true,
  "lockType": "pin",
  "observations": "A small wall safe behind the reception desk. Looks like it needs a 4-digit code."
  // HIDDEN: "requires": "9573"
  // HIDDEN: "contents": [...]
}
```

---

### Decision 3: Separate `contents` Endpoint

**Decision:** Add `/games/:id/container/:container_id` endpoint to load container contents after unlock.

**Rationale:**
- ✅ Lazy-loading - only fetch contents when actually opened
- ✅ Security boundary - can't mass-fetch all contents
- ✅ Clear permission check - container must be in unlockedObjects
- ✅ Performance - reduces room data payload
- ✅ Mirrors real UX - opening a safe reveals its contents

**Alternative Considered:**
- Include contents in room data from start - massive payload, security risk
- Never show contents, only abstract summary - breaks exploration feel

**Implementation:**
```
GET /games/:id/container/reception_safe
→ { container_id: "reception_safe", contents: [...] }
  // Only if reception_safe in unlockedObjects
  // Returns 403 Forbidden otherwise
```

---

### Decision 4: Initialize Player State on Game Creation

**Decision:** On game creation, populate `unlockedRooms` with start room and `inventory` with starting items.

**Rationale:**
- ✅ Single source of truth - scenario defines what player starts with
- ✅ Consistency - all games initialized the same way
- ✅ Simplicity - client doesn't need bootstrap logic
- ✅ Supports game reset (re-initialize if needed)

**Alternative Considered:**
- Initialize on first request - harder to audit, timing issues
- Client-side initialization - security risk, can cheat before sync

**Implementation:**
```ruby
def initialize_player_state!
  player_state['unlockedRooms'] = [scenario_data['startRoom']]
  player_state['inventory'] = scenario_data['startItemsInInventory']
  player_state['currentRoom'] = scenario_data['startRoom']
  save!
end
```

---

### Decision 5: Validate Inventory Operations Against Scenario

**Decision:** Server verifies item exists in scenario AND is in an accessible location AND player meets prerequisites.

**Rationale:**
- ✅ Prevents collecting non-existent items (modified client claims fake item)
- ✅ Prevents collecting from locked rooms (player unlocked on client but not server)
- ✅ Prevents collecting items held by unmet NPCs (client doesn't know encounter requirement)
- ✅ Prevents collecting from locked containers (client somehow gets contents early)

**Validation Chain:**
1. Does item exist in scenario? → Error if not
2. Is item takeable? → Error if not
3. Is item's container unlocked (if nested)? → Error if not
4. Is item's room unlocked (if locked room)? → Error if not
5. Is item held by an NPC? If yes, is NPC encountered? → Error if not

**Alternative Considered:**
- Trust client completely - simple but allows cheating
- Only check existence - allows room/container bypass
- No validation - breaks game integrity

---

### Decision 6: Track NPC Encounters Automatically

**Decision:** When room loads, add all NPC IDs to `encounteredNPCs` in player_state.

**Rationale:**
- ✅ Automatic - no separate API call needed
- ✅ Fair - player must physically reach room with NPC
- ✅ Enables NPC-held items - once encountered, can collect their items
- ✅ Groundwork for future dialogue progression tracking

**Alternative Considered:**
- Only track on conversation start - misses silent encounters, harder to track
- Require explicit "talk to NPC" action - more control but less intuitive

**Implementation:**
```ruby
# In room endpoint, after serving room data:
if room_data['npcs'].present?
  @game.player_state['encounteredNPCs'] ||= []
  @game.player_state['encounteredNPCs'].concat(room_data['npcs'].map { |n| n['id'] })
  @game.player_state['encounteredNPCs'].uniq!
end
```

---

### Decision 7: Permissive Unlock Model (Once Unlocked, Always Unlocked)

**Decision:** When door/container unlocked, stays unlocked. No re-locking on reload or time-based relocking.

**Rationale:**
- ✅ Matches user expectation - unlock a door, it stays unlocked
- ✅ Persistent progress - player doesn't lose progress on page refresh
- ✅ Simple to implement - no timer/state logic needed
- ✅ Aligns with game design - escape room puzzles are one-way progression

**Alternative Considered:**
- Session-based unlocking (unlock disappears on reload) - frustrating UX
- Time-based relocking (unlock expires after N minutes) - confusing gameplay
- Restrictive per-room unlocks - impossible to revisit content

**Note:** If scenario design requires re-locking (e.g., "security system reset"), can be added later with globalVariables tracking.

---

### Decision 8: No Unlock Attempt Tracking (Phase 1)

**Decision:** Validate unlock attempts but don't log failures. Just return success/failure.

**Rationale:**
- ✅ Simpler Phase 1 - focus on validation, not analytics
- ✅ No database bloat - saves storage/queries
- ✅ Can add later - structure supports rate limiting future
- ✅ Sufficient for security - server still validates, prevents brute force client-side

**Alternative Considered:**
- Log all attempts - useful for analytics, adds complexity
- Log only failures - still adds DB overhead

**Future Enhancement:** Add attempt logging in Phase 3 if needed for analytics/security audit.

---

### Decision 9: Scenario Map Endpoint for Layout Metadata

**Decision:** Create `/games/:id/scenario_map` that returns minimal room layout without revealing objects/contents.

**Rationale:**
- ✅ Supports planning - client can show map/navigation hints
- ✅ No solutions exposed - only structure (types, connections, accessibility)
- ✅ Separate from room data - can cache differently
- ✅ Enables UI features - map showing locked vs accessible rooms

**Response Contains:**
- Room IDs and types
- Connections (which rooms connect where)
- Locked status and lock types
- NPC counts (no details)
- Accessibility (based on unlockedRooms)

**Does NOT contain:**
- Object lists
- Container contents
- Solutions (`requires` fields)

---

### Decision 10: NPC-Held Items Validation

**Decision:** Check `itemsHeld` on NPCs. Items can only be collected if NPC is encountered.

**Rationale:**
- ✅ Prevents item duplication - NPC item appears as collectible only after meeting NPC
- ✅ Enforces game flow - can't shortcut conversations
- ✅ Mirrors container logic - items locked until condition met
- ✅ Supports dialogue rewards - future dialogue choices can give items

**Alternative Considered:**
- No NPC item tracking - allows client to claim items arbitrarily
- Only allow after specific dialogue node - too complex for Phase 1

**Implementation:**
```ruby
def find_npc_holding_item(item_type, item_id)
  # Returns NPC info if found
  # Validation: Only allow if npc['id'] in player_state['encounteredNPCs']
end
```

---

## Data Flow Architecture

### Room Loading Flow

```
Client Request:  GET /games/:id/room/office_1
                    ↓
Server:         [1] Check if office_1 in unlockedRooms
                    ↓ (if not, return 403 Forbidden)
                [2] Load scenario_data['rooms']['office_1']
                    ↓
                [3] Filter: Remove 'requires' fields recursively
                    ↓
                [4] Filter: Remove 'contents' fields recursively
                    ↓
                [5] Track NPC encounters (add to encounteredNPCs)
                    ↓
Client Response: { room_id: "office_1", room: {...filtered...} }
```

### Inventory Add Flow

```
Client Request:  POST /games/:id/inventory
                 { action: "add", item: { type: "key", id: "key_1" } }
                    ↓
Server:         [1] Find item in scenario_data (all rooms)
                    ↓ (if not found, return error)
                [2] Check if item is takeable
                    ↓ (if not, return error)
                [3] Find if item in locked container
                    ↓
                [4] If yes, check container in unlockedObjects
                    ↓ (if not, return error)
                [5] Find if item in locked room
                    ↓
                [6] If yes, check room in unlockedRooms
                    ↓ (if not, return error)
                [7] Check if NPC holds item
                    ↓
                [8] If yes, check NPC in encounteredNPCs
                    ↓ (if not, return error)
                [9] Add item to inventory
                    ↓
Client Response: { success: true, inventory: [...] }
```

### Unlock Flow

```
Client Request:  POST /games/:id/unlock
                 { targetType: "door", targetId: "office_1", 
                   attempt: "key_1", method: "key" }
                    ↓
Server:         [1] Validate unlock attempt
                    (@game.validate_unlock checks server secrets)
                    ↓ (if invalid, return error)
                [2] Record unlock: add to unlockedRooms or unlockedObjects
                    ↓
                [3] If door, return filtered room data
                    ↓
Client Response: { success: true, type: "door", roomData: {...} }
```

### Container Opening Flow

```
Client Request:  GET /games/:id/container/safe_1
                    ↓
Server:         [1] Check if safe_1 in unlockedObjects
                    ↓ (if not, return 403 Forbidden)
                [2] Find safe_1 in scenario_data
                    ↓
                [3] Get contents
                    ↓
                [4] Filter: Remove 'requires' from each item
                    ↓
                [5] Filter: Remove nested 'contents'
                    ↓
Client Response: { container_id: "safe_1", contents: [...] }
```

---

## Security Model

### What We're Protecting Against

1. **Client Modification**
   - Malicious client code claiming to have collected items
   - Modifying unlock validation to bypass puzzles
   - Injecting room access that wasn't earned

2. **Browser DevTools Manipulation**
   - Reading cached scenario data to find passwords
   - Modifying player_state in local storage/memory
   - Calling API endpoints with fake parameters

3. **Network Inspection**
   - Reading API responses for password hints
   - Replaying unlock requests to collect same item twice

### What We're NOT Protecting Against (Out of Scope)

1. **Server Compromise**
   - If attacker compromises Rails server, all is lost
   - Assume infrastructure is secure

2. **Network-Level Attacks**
   - HTTPS handles man-in-the-middle
   - Assume secure transport

3. **Brute Force Unlock Attempts**
   - Could add rate limiting in Phase 3
   - Not implemented in Phase 1

---

## Principles

### 1. Server is Source of Truth

- Client state is for UI only
- Server always validates before accepting changes
- Never trust `player_state` sent by client
- Always verify against scenario_data server-side

### 2. Minimal Data Exposure

- Only send data client needs for current action
- Hide solutions (`requires`)
- Hide inaccessible content (`contents` of locked containers)
- Expose lock types and status (needed for UX)

### 3. Lazy Loading Everything

- Room data only on room request
- Container contents only on container request
- NPC scripts only on NPC interaction
- Scenario map available for UI planning

### 4. Fail Securely

- When in doubt, deny access (default deny)
- 403 Forbidden for permission errors
- 404 Not Found for data not found
- Clear error messages for debugging (but not exploitable)

### 5. Consistent Validation

- Same validation logic for all item sources
- Same checks whether item from room, container, or NPC
- Same access control everywhere

---

## Trade-offs & Compromises

### Trade-off 1: Performance vs Security

**Choice:** Full recursive filtering for every request.

**Impact:** Slightly slower responses, but security critical. Caching can mitigate if needed.

**Alternative:** Send unfiltered, filter on client. ❌ Rejected - exposes secrets.

### Trade-off 2: Complexity vs Flexibility

**Choice:** Separate container endpoint adds complexity.

**Benefit:** Enables lazy-loading, prevents mass-extraction of secrets, matches UX expectations.

**Alternative:** Include all contents in room data. ❌ Rejected - security risk and payload bloat.

### Trade-off 3: Features vs Timeline

**Choice:** Phase 1 doesn't include attempt logging or rate limiting.

**Rationale:** Get validation working first, enhance later. Foundation supports it.

**Future Phases:** Attempt logging (Phase 3), rate limiting (Phase 4).

---

## Success Criteria

### Phase 1 Success

- ✅ `requires` field hidden from all room endpoints
- ✅ `contents` field hidden until container unlocked
- ✅ Inventory validation prevents collection from locked areas
- ✅ Room access tied to unlockedRooms
- ✅ NPC encounters tracked automatically
- ✅ Unlock status persists across reloads
- ✅ All tests pass

### Phase 2 Success (Future)

- Attempt logging working
- Analytics dashboard shows unlock patterns
- Rate limiting prevents brute force

### Phase 3 Success (Future)

- Suspicious activity detection
- Audit trail for admin review

---

## Implementation Dependencies

### Must Have Before Starting

- ✅ Game model with scenario_data
- ✅ GamesController with basic room endpoint
- ✅ Player state initialized

### Will Need to Add

- Helper methods in Game model (filter_object_requires_recursive, etc.)
- Validation helpers in controller (find_item_in_scenario, etc.)
- New endpoints (container, scenario_map)
- Tests for each validation path

---

## Open Questions (For Future Phases)

1. **Dialogue Integration:** How do NPC encounters map to dialogue state?
2. **Item Persistence:** Can player permanently lose items? Drop items?
3. **Multiple Solutions:** Can item be unlocked via multiple methods (key OR password)?
4. **Resetting Progress:** Can player reset game state? Affects unlocked tracking.
5. **Analytics:** What unlock/collection metrics matter for learning analysis?

---

## Conclusion

This design provides robust server-side validation and data filtering while maintaining a clean architecture and supporting the lazy-loading model. By filtering at the controller level and validating against scenario data, we prevent client-side cheating while allowing the client to render rich interactions and maintain smooth UX.

The phased approach allows us to implement security first (Phase 1), then add analytics (Phase 2), then refine with rate limiting (Phase 3), without disrupting game functionality.
