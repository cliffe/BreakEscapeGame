# Updated Rails Engine Migration Status & Plans
## Last Updated: 2025-11-20

## Executive Summary

This document provides an updated assessment of the BreakEscape codebase and Rails Engine migration plans based on the **current state of implementation**. The codebase has evolved significantly since the original plans were created, with major systems now fully implemented.

---

## What's Changed Since Original Plans

### ✅ Fully Implemented (New Since Original Plans)

#### 1. **Comprehensive NPC System**
**Status:** ✅ **COMPLETE** - Production ready

**What's Implemented:**
- **NPCManager** (`js/systems/npc-manager.js`)
  - Full lifecycle management for NPCs
  - Event mapping system (20+ event patterns)
  - Conversation history tracking per NPC
  - Timed messages and timed conversations
  - InkEngine caching and optimization
  - NPC item inventory ("itemsHeld")

- **Two NPC Types:**
  - `phone`: Text-only NPCs on phones
  - `person`: In-world sprite-based NPCs

- **Line-of-Sight (LOS) System** (`js/systems/npc-los.js`)
  - NPCs can detect player in their field of view
  - Configurable range and angle
  - Can interrupt lockpicking if player is seen

- **Conversation State Management** (`js/systems/npc-conversation-state.js`)
  - Persists Ink story state across conversations
  - Saves variables (favor, trust_level, etc.)
  - Restores conversation progress
  - Handles story endings gracefully

- **Event-Driven Dialogue:**
  - NPCs react to game events (item_picked_up, door_unlocked, room_entered, etc.)
  - Configurable cooldowns and "once-only" triggers
  - Pattern matching for flexible event routing

- **NPC Item Giving:**
  - NPCs can give items to player via Ink tags
  - Integrated with inventory system
  - Server validation will be needed for this

**Files:**
- `js/systems/npc-manager.js` (500+ lines)
- `js/systems/npc-conversation-state.js`
- `js/systems/npc-barks.js`
- `js/systems/npc-lazy-loader.js`
- `js/systems/npc-los.js`
- `js/systems/npc-game-bridge.js`
- `js/systems/npc-behavior.js`
- `js/systems/npc-hostile.js`
- `js/minigames/person-chat/person-chat-minigame.js`
- `js/minigames/person-chat/person-chat-conversation.js`
- `js/minigames/phone-chat/phone-chat-minigame.js`
- `js/minigames/phone-chat/phone-chat-conversation.js`

**Migration Impact:**
- ✅ Original NPC_MIGRATION_OPTIONS.md is still relevant
- ⚠️ Need to add conversation state sync to server
- ⚠️ Need server validation for NPC actions (give items, unlock doors)
- ⚠️ Need to handle event system on server

---

#### 2. **Comprehensive Event System**
**Status:** ✅ **COMPLETE** - Production ready

**What's Implemented:**
- **EventDispatcher** with 80+ emit calls across codebase
- **20+ Event Types:**
  - `door_unlock_attempt`
  - `door_unlocked`
  - `item_picked_up`
  - `item_used`
  - `minigame_completed`
  - `room_entered`
  - `room_revealed`
  - `container_opened`
  - `lockpick_used_in_view`
  - `health_changed`
  - `player_detected`
  - Many more...

**Migration Impact:**
- ⚠️ Server needs to track player actions for event validation
- ⚠️ Some events may need server authorization (e.g., door_unlocked)
- ⚠️ Event history could be used for anti-cheat
- ✅ Most events can stay client-side for UI/NPC reactions

---

#### 3. **Game State Management**
**Status:** ✅ **COMPLETE** - Production ready

**What's Implemented:**
- **Global Variables System:**
  - `window.gameState.globalVariables` - persists across rooms
  - Used by NPCs for tracking player relationships
  - Used for scenario-wide flags and progression

- **Player State:**
  - Health system (`js/systems/player-health.js`)
  - Position tracking
  - Room discovery
  - Inventory

- **NPC State:**
  - Conversation history per NPC
  - Story variables (favor, trust, etc.)
  - Items held by NPCs

- **Scenario State:**
  - Unlocked rooms
  - Unlocked objects
  - Completed objectives

**Migration Impact:**
- ⚠️ Server must become source of truth for all game state
- ⚠️ Need state reconciliation on connect/reconnect
- ⚠️ Need atomic updates to prevent race conditions
- ⚠️ Need to sync state changes server-side

---

#### 4. **Multiple Scenarios**
**Status:** ✅ **COMPLETE** - 24 scenarios exist

**What's Implemented:**
- **Production Scenarios:**
  - `ceo_exfil.json` - Original CEO heist scenario
  - `cybok_heist.json` - Educational CyBOK scenario
  - `biometric_breach.json` - Biometrics-focused scenario

- **Test Scenarios:**
  - NPC testing scenarios (patrol, waypoints, LOS, personal space)
  - RFID testing scenarios
  - Layout testing scenarios (vertical, horizontal, complex)
  - Timed messages demo

- **Total:** 24 different scenarios in `scenarios/` directory

**Migration Impact:**
- ✅ Need to import all scenarios into database
- ✅ Need scenario versioning/updates strategy
- ✅ Multiple scenarios handled by original plans
- ⚠️ May want scenario-level permissions (which users can access which scenarios)

---

#### 5. **Advanced Unlock System**
**Status:** ✅ **COMPLETE** - Production ready

**What's Implemented:**
- **Lock Types Supported:**
  - `key` - Physical keys with key ring support
  - `pin` - PIN code entry
  - `password` - Password entry with hints
  - `biometric` - Fingerprint/DNA matching
  - `bluetooth` - Bluetooth pairing
  - `lockpick` - Lockpicking minigame (uses keyPins)

- **Advanced Features:**
  - Key rings (multiple keys in one item)
  - NPC lockpick interruption (if NPC sees player)
  - Event emission for unlock attempts
  - Testing mode (`window.DISABLE_LOCKS`)
  - Support for both snake_case and camelCase property names

**Files:**
- `js/systems/unlock-system.js`
- `js/systems/minigame-starters.js`
- 16 different minigame implementations

**Migration Impact:**
- ⚠️ **CRITICAL:** All unlock validation MUST move server-side
- ⚠️ Server must validate key matches lock
- ⚠️ Server must validate PIN/password correctness
- ⚠️ Server must check lockpick success (anti-cheat)
- ⚠️ Server must authorize NPC lockpick interruptions
- ✅ Minigame UI can stay client-side

---

### ❌ Not Yet Implemented (Still Needed)

#### 1. **Server-Side Sync Functions**
**Status:** ❌ **NOT IMPLEMENTED** - High Priority

**What's Missing:**
- No server API endpoints exist yet
- No sync functions for:
  - Game state changes
  - Inventory updates
  - Unlock validation
  - NPC action validation
  - Conversation state sync
  - Event logging

**What's Needed:**
See updated CLIENT_SERVER_SEPARATION_PLAN.md for details.

Key areas:
1. Room loading API
2. Unlock validation API
3. Inventory sync API
4. NPC action validation API
5. Game state sync API
6. Event logging API

---

#### 2. **Rails Engine Structure**
**Status:** ❌ **NOT IMPLEMENTED** - Medium Priority

**What's Missing:**
- No Rails engine created yet
- No database schema
- No models, controllers, or views
- No Rails integration

**What's Needed:**
Follow RAILS_ENGINE_MIGRATION_PLAN.md phases 1-12.

---

#### 3. **Server-Side Validation**
**Status:** ❌ **NOT IMPLEMENTED** - High Priority

**What's Missing:**
- All validation is client-side (insecure)
- Players can:
  - Modify `window.DISABLE_LOCKS = true`
  - Edit inventory in console
  - Read all scenario data from network tab
  - Manipulate game state variables
  - Bypass unlock requirements

**What's Needed:**
- Server validates every critical action
- Server is source of truth for game state
- Client is just UI presentation layer

---

## Updated Migration Approach

### Phase 1: Server Infrastructure (Weeks 1-4)
**Goal:** Build Rails Engine with database and basic API

**Tasks:**
- [ ] Create Rails Engine skeleton (`rails plugin new break_escape --mountable`)
- [ ] Design database schema accounting for:
  - NPCs with conversation state
  - Event system tracking
  - Global variables
  - Multiple scenarios
- [ ] Create models: GameInstance, Scenario, Room, RoomObject, NPC, Conversation, PlayerState, InventoryItem
- [ ] Add NPC-specific models:
  - ConversationState (stores Ink story state per player-NPC pair)
  - NPCPermission (which NPCs can give which items/unlock which doors)
  - GameEvent (log of player actions)
- [ ] Create seed data importer for 24 scenarios
- [ ] Setup test framework

**Updated Schema Additions:**

```ruby
# New: Global game state per player
create_table :player_game_states do |t|
  t.references :game_instance, null: false
  t.jsonb :global_variables, default: {}
  t.jsonb :discovered_rooms, default: []
  t.jsonb :completed_objectives, default: []
  t.timestamps

  t.index :global_variables, using: :gin
end

# Updated: NPC conversations with state
create_table :conversations do |t|
  t.references :game_instance, null: false
  t.references :npc, null: false
  t.jsonb :history, default: []           # Message array
  t.text :story_state                     # Serialized Ink state
  t.jsonb :variables, default: {}         # Ink variables
  t.string :current_knot
  t.datetime :last_message_at
  t.timestamps

  t.index [:game_instance_id, :npc_id], unique: true
  t.index :variables, using: :gin
end

# New: Track game events for analytics and anti-cheat
create_table :game_events do |t|
  t.references :game_instance, null: false
  t.string :event_type, null: false       # door_unlocked, item_picked_up, etc.
  t.jsonb :event_data, default: {}        # Event-specific data
  t.datetime :occurred_at, null: false
  t.timestamps

  t.index [:game_instance_id, :event_type]
  t.index :occurred_at
  t.index :event_data, using: :gin
end

# New: NPC permissions for action validation
create_table :npc_permissions do |t|
  t.references :npc, null: false
  t.string :action_type, null: false      # unlock_door, give_item
  t.string :target                        # door_id, item_id
  t.jsonb :conditions, default: {}        # trust_level, flags, etc.
  t.timestamps

  t.index [:npc_id, :action_type, :target], unique: true
end
```

---

### Phase 2: Client Data Access Layer (Weeks 5-6)
**Goal:** Create abstraction for server communication

**Tasks:**
- [ ] Create `GameDataAccess` class (`js/core/game-data-access.js`)
- [ ] Add dual-mode support (local JSON fallback for development)
- [ ] Implement methods:
  - `getRoomData(roomId)` → replaces `window.gameScenario.rooms[roomId]`
  - `validateUnlock(targetType, targetId, attempt)` → server validation
  - `syncInventory(action, itemData)` → inventory changes
  - `validateNPCAction(npcId, action, context)` → NPC actions
  - `syncConversationState(npcId, state)` → conversation persistence
  - `syncGameState(globalVariables)` → global state
  - `logEvent(eventType, eventData)` → event logging
- [ ] Add error handling, retry logic, caching
- [ ] Add offline queue for operations

---

### Phase 3: System-by-System Migration (Weeks 7-14)

#### Week 7-8: Room Loading
- [ ] Modify `loadRoom()` to use `GameDataAccess.getRoomData()`
- [ ] Add loading indicators
- [ ] Test room lazy loading from server
- [ ] Add prefetching for adjacent rooms

#### Week 9-10: Unlock System
- [ ] Create `Api::UnlockController`
- [ ] Add validation for all lock types
- [ ] Modify `handleUnlock()` to call server
- [ ] Server returns unlocked content
- [ ] Add rate limiting for brute force protection

#### Week 11-12: Inventory System
- [ ] Create `Api::InventoryController`
- [ ] Add server sync to `addToInventory()`, `removeFromInventory()`
- [ ] Implement optimistic UI updates
- [ ] Add rollback on server rejection
- [ ] Handle offline mode

#### Week 13-14: NPC System
- [ ] Create `Api::NpcsController`
- [ ] Add endpoints:
  - `POST /api/npcs/:id/validate_action` - Validate NPC actions
  - `POST /api/npcs/:id/sync_conversation` - Sync conversation state
  - `GET /api/npcs/:id/story` - Optional progressive loading
- [ ] Modify NPC action handlers to validate with server
- [ ] Add conversation state sync (async)
- [ ] Server validates:
  - Can NPC give this item?
  - Can NPC unlock this door?
  - Does player meet trust requirements?

**NPC Migration Strategy (Hybrid Approach):**
✅ **Keep client-side:** Ink scripts, dialogue engine, conversation UI
✅ **Keep client-side:** Event listener setup, timed messages
⚠️ **Add server validation:** Item giving, door unlocking, trust checks
⚠️ **Add server sync:** Conversation state, story variables

---

### Phase 4: Game State Management (Weeks 15-16)
- [ ] Create `Api::GameStateController`
- [ ] Add endpoints:
  - `GET /api/game_state` - Get current state
  - `PUT /api/game_state/global_variables` - Update globals
  - `POST /api/game_state/sync` - Full state sync
- [ ] Modify `window.gameState` to sync changes to server
- [ ] Add state reconciliation on connect
- [ ] Handle offline queue

---

### Phase 5: Event System Integration (Weeks 17-18)
- [ ] Create `Api::EventsController`
- [ ] Add event logging endpoint
- [ ] Modify event dispatcher to log critical events server-side
- [ ] Events to log:
  - door_unlocked (for progression tracking)
  - item_picked_up (for inventory validation)
  - minigame_completed (for anti-cheat)
  - health_changed (for failure detection)
  - npc_action_performed (for permissions audit)
- [ ] Add analytics dashboard for game events

---

### Phase 6: Testing & Deployment (Weeks 19-22)
- [ ] Integration tests for all systems
- [ ] Performance testing (latency, throughput)
- [ ] Security audit (authorization, validation)
- [ ] Load testing
- [ ] Deploy to staging
- [ ] User acceptance testing
- [ ] Deploy to production

**Total Timeline: 22 weeks (~5 months)**

---

## Key Architecture Decisions

### 1. NPC System: Hybrid Approach (Confirmed)
**Decision:** Keep Ink scripts client-side, validate actions server-side

**Rationale:**
- ✅ NPCs are fully implemented with complex dialogue trees
- ✅ Instant dialogue response critical for UX
- ✅ 80% of dialogue is flavor text (low security risk)
- ⚠️ Only item giving and door unlocking need validation
- ⚠️ Can add progressive loading for high-security NPCs later

**Implementation:**
- Client loads Ink scripts at startup (or progressively)
- Client runs dialogue engine locally
- When NPC performs action (give item, unlock door):
  - Client asks server: "Can this NPC do this?"
  - Server validates conditions (trust level, permissions, prerequisites)
  - Server executes action if allowed
- Client syncs conversation state periodically (async)

---

### 2. Event System: Selective Server Logging
**Decision:** Most events stay client-side, critical events logged server-side

**Rationale:**
- ✅ 80+ events emitted across codebase
- ✅ Most are for UI reactions (don't need server)
- ⚠️ Some events critical for progression tracking
- ⚠️ Some events useful for anti-cheat

**Events to Log Server-Side:**
- door_unlocked → Track progression
- item_picked_up → Validate inventory
- minigame_completed → Anti-cheat metrics
- unlock_attempt → Brute force detection
- npc_action_performed → Audit NPC permissions

**Events to Keep Client-Only:**
- room_revealed → UI only
- player_moved → Too frequent
- container_opened → UI only
- bark_displayed → UI only

---

### 3. Game State: Server as Source of Truth
**Decision:** All critical state must sync to server

**Rationale:**
- ⚠️ Current state is 100% client-side (insecure)
- ⚠️ Players can manipulate state in console
- ✅ Server must validate all state changes
- ✅ Client should optimistically update for UX

**Critical State (Must Sync):**
- Player inventory
- Unlocked rooms/objects
- Global variables
- NPC conversation state
- Player health
- Completed objectives

**UI State (Can Stay Client-Only):**
- Camera position
- UI panel states
- Volume settings
- Debug visualizations

---

## Risk Assessment

### High Risk Areas

#### 1. Network Latency
**Risk:** Server round-trips add 100-300ms delay

**Mitigation:**
- ✅ Aggressive client-side caching
- ✅ Prefetch adjacent rooms in background
- ✅ Optimistic UI updates
- ✅ Keep minigames 100% client-side
- ✅ Keep dialogue engine client-side

#### 2. State Consistency
**Risk:** Client and server state diverge

**Mitigation:**
- ✅ Server is source of truth (always)
- ✅ Periodic state reconciliation
- ✅ Rollback on server rejection
- ✅ Audit log of all state changes
- ✅ Offline queue with conflict resolution

#### 3. NPC Complexity
**Risk:** NPC system is complex with many interactions

**Mitigation:**
- ✅ Start with action validation only (minimal change)
- ✅ Add conversation sync as async background task
- ✅ Progressive enhancement (don't break existing features)
- ✅ Extensive testing of NPC interactions

---

## Success Metrics

### Performance Targets
- Room loading: < 500ms (p95)
- Unlock validation: < 300ms (p95)
- Inventory sync: < 200ms (p95)
- NPC action validation: < 300ms (p95)
- Cache hit rate: > 80%

### Security Targets
- 0 scenario spoilers in client
- 0 unlock bypass exploits
- 0 inventory manipulation exploits
- Server validates 100% of critical actions

### Reliability Targets
- 99.9% API uptime
- < 0.1% error rate
- Offline queue: 100% eventual consistency

---

## Next Steps (Immediate Actions)

1. **Review this document** with team
2. **Approve updated timeline** (22 weeks vs original 18 weeks)
3. **Begin Phase 1:** Rails Engine creation
4. **Setup development environment** for server-client testing
5. **Create test scenarios** for each migration phase

---

## Document References

### Planning Documents (Updated)
- ✅ `SERVER_CLIENT_MODEL_ASSESSMENT.md` - Still accurate
- ⚠️ `CLIENT_SERVER_SEPARATION_PLAN.md` - Needs NPC/Event updates (below)
- ✅ `NPC_MIGRATION_OPTIONS.md` - Confirmed: Hybrid approach
- ✅ `RAILS_ENGINE_MIGRATION_PLAN.md` - Needs Phase updates (below)
- ✅ `MIGRATION_CODE_EXAMPLES.md` - Still accurate

### New Documentation Needed
- [ ] Event system migration guide
- [ ] NPC conversation state sync specification
- [ ] Global game state sync specification
- [ ] Offline queue design document
- [ ] Anti-cheat strategy document

---

## Conclusion

**The codebase has matured significantly** with production-ready implementations of NPCs, events, game state, and multiple scenarios. The original migration plans are still fundamentally sound, but need updates to account for:

1. **NPC system complexity** - More sophisticated than originally planned
2. **Event system** - Wasn't in original plans, needs integration
3. **Game state management** - More comprehensive than originally planned
4. **Multiple scenarios** - 24 vs 1 expected

**Recommended Approach:**
- ✅ Follow original plan structure (phases 1-12)
- ⚠️ Add 4 weeks for NPC/Event/State integration
- ✅ Use hybrid approach for NPCs (validated in plans)
- ✅ Start with Phase 1 (Rails Engine creation)
- ✅ Implement dual-mode testing (local JSON fallback)

**Total Effort: 22 weeks (~5 months)**

**Risk Level: Medium** (more complexity but clearer requirements)

**Confidence: High** (architecture proven, team experienced)
