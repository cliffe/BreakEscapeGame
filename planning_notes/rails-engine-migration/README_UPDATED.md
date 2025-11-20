# Rails Engine Migration Plans - Updated November 2025

## Overview

This directory contains comprehensive plans for migrating BreakEscape from a standalone browser application to a Rails Engine that can be mounted in Hacktivity Cyber Security Labs and run standalone.

**Last Updated:** November 20, 2025

**Status:** Plans updated to reflect current codebase state

---

## Quick Start

### 🚀 **RECOMMENDED: Simplified Approach**

1. **[SIMPLIFIED_APPROACH.md](./SIMPLIFIED_APPROACH.md)** ⭐ **START HERE**
   - **12-14 weeks** instead of 22 weeks
   - **3 database tables** instead of 10+
   - **6 API endpoints** instead of 15+
   - JSON-based storage (matches existing format)
   - Simple validation rules
   - **This is the recommended implementation path**

### 📚 Alternative: Full Analysis (Original Complex Approach)

2. **[UPDATED_MIGRATION_STATUS.md](./UPDATED_MIGRATION_STATUS.md)**
   - Comprehensive status of what's changed since original plans
   - What's been implemented (NPCs, Events, Game State)
   - What still needs to be done (server-side sync)
   - Timeline: 22 weeks
   - ⚠️ More complex than needed - see SIMPLIFIED_APPROACH.md instead

3. **[progress/CLIENT_SERVER_SEPARATION_PLAN.md](./progress/CLIENT_SERVER_SEPARATION_PLAN.md)**
   - System-by-system separation strategy
   - Detailed implementation examples
   - Migration checklist with 9 phases
   - ⚠️ Over-engineered - see SIMPLIFIED_APPROACH.md instead

4. **[progress/RAILS_ENGINE_MIGRATION_PLAN.md](./progress/RAILS_ENGINE_MIGRATION_PLAN.md)**
   - Complete Rails Engine creation guide
   - Database schema for complex approach
   - Phase-by-phase implementation
   - ⚠️ Use simplified schema from SIMPLIFIED_APPROACH.md instead

---

## Document Index

### Core Planning Documents (Updated)

| Document | Status | Purpose |
|----------|--------|---------|
| **UPDATED_MIGRATION_STATUS.md** | ✅ **Current** | Master status document - what's changed, what's needed |
| **CLIENT_SERVER_SEPARATION_PLAN.md** | ✅ **Updated** | System-by-system separation (added NPCs, Events, State) |
| **RAILS_ENGINE_MIGRATION_PLAN.md** | ⚠️ **Needs Schema Updates** | Rails Engine creation guide (phases still valid) |
| **SERVER_CLIENT_MODEL_ASSESSMENT.md** | ✅ **Still Valid** | Architecture assessment and compatibility |
| **SERVER_CLIENT_MIGRATION_GUIDE.md** | ✅ **Still Valid** | Quick reference guide |
| **MIGRATION_CODE_EXAMPLES.md** | ✅ **Still Valid** | Before/after code examples |
| **NPC_MIGRATION_OPTIONS.md** | ✅ **Validated** | NPC-specific migration strategy (hybrid confirmed) |
| **ARCHITECTURE_COMPARISON.md** | ✅ **Still Valid** | Visual architecture diagrams |

---

## What's Changed Since Original Plans

### ✅ Fully Implemented (New Features)

#### 1. NPC System (Production Ready)
- **NPCManager** with full lifecycle management
- Event-driven dialogue (20+ event patterns)
- Conversation state persistence
- Two NPC types: phone and person (sprite-based)
- Line-of-sight system
- NPC item giving and door unlocking
- Timed messages and conversations

**Files:** 10+ files in `js/systems/` and `js/minigames/`
**Impact:** Need server validation for NPC actions, conversation state sync

#### 2. Event System (Production Ready)
- **EventDispatcher** with 80+ emit calls
- 20+ event types for game actions
- NPCs react to events
- Event-driven game mechanics

**Impact:** Need selective server logging for critical events

#### 3. Global Game State (Production Ready)
- `window.gameState.globalVariables` for scenario-wide state
- NPCs use global variables for relationships
- Persistent state across rooms

**Impact:** Need server sync for all global state changes

#### 4. Multiple Scenarios (24 Total)
- Production scenarios: ceo_exfil, cybok_heist, biometric_breach
- Test scenarios for NPCs, RFID, layouts
- **Was:** 1 scenario planned
- **Now:** 24 scenarios to import

**Impact:** Need to import all scenarios, may need per-scenario permissions

#### 5. Advanced Unlock System
- 5 lock types fully working
- Key ring support
- NPC lockpick interruption
- Event emission for unlocks

**Impact:** All validation MUST move server-side

---

### ❌ Not Yet Implemented (High Priority)

#### 1. Server-Side Sync Functions
- No API endpoints exist
- No server validation
- All validation client-side (insecure)

#### 2. Rails Engine Structure
- No Rails engine created
- No database schema
- No models, controllers, or views

#### 3. Server-Side Validation
- Players can manipulate state in console
- Can read all scenario data
- Can bypass unlock requirements

---

## Updated Migration Timeline

### ⚠️ NOTE: This is the complex approach timeline. See SIMPLIFIED_APPROACH.md for 12-14 week alternative.

### Total Duration: 22 weeks (~5.5 months) - COMPLEX APPROACH

**Breakdown:**
- Weeks 1-4: Server Infrastructure (Rails Engine, Database, Models)
- Weeks 5-6: Client Data Access Layer
- Weeks 7-8: Room Loading
- Weeks 9-10: Unlock System
- Weeks 11-12: Inventory System
- Weeks 13-14: NPC System ⚠️ **NEW** (+2 weeks)
- Weeks 15-16: Minigame Validation
- Weeks 17-18: Event System ⚠️ **NEW** (+2 weeks)
- Weeks 19-20: Global Game State ⚠️ **NEW** (+2 weeks)
- Weeks 21-22: Testing & Deployment ⚠️ **Extended** (+2 weeks)

**Original Estimate:** 18 weeks
**Updated Estimate:** 22 weeks
**Increase:** 4 weeks (22% longer due to new systems)

---

## Key Architecture Decisions

### 1. NPC System: Hybrid Approach ✅ CONFIRMED

**Decision:** Keep Ink scripts client-side, validate actions server-side

**Rationale:**
- Instant dialogue critical for UX
- 80% of dialogue is flavor (low security risk)
- Only item giving and door unlocking need validation
- NPCs fully implemented and working well client-side

**Implementation:**
- Client runs dialogue engine locally (no changes)
- Client validates actions with server before executing
- Client syncs conversation state asynchronously

---

### 2. Event System: Selective Logging ✅ NEW

**Decision:** Most events stay client-side, critical events logged server-side

**Rationale:**
- 80+ events, most are UI-only
- Some events critical for progression tracking
- Some events useful for anti-cheat

**Events to Log Server-Side:**
- door_unlocked (progression)
- item_picked_up (inventory validation)
- minigame_completed (anti-cheat)
- unlock_attempt (brute force detection)
- npc_action_performed (audit)

---

### 3. Global Game State: Server as Source of Truth ✅ NEW

**Decision:** All critical state syncs to server

**Rationale:**
- Current state 100% client-side (insecure)
- Players can manipulate state in console
- NPCs rely on global variables for relationships
- Need persistence across sessions

**Implementation:**
- Client maintains local cache for performance
- Debounced sync to server (every 2s)
- Server is source of truth
- Optimistic updates for UX

---

## Database Schema Updates Needed

### New Tables Required

```ruby
# Global game state per player
create_table :player_game_states do |t|
  t.references :game_instance, null: false
  t.jsonb :global_variables, default: {}
  t.jsonb :discovered_rooms, default: []
  t.jsonb :completed_objectives, default: []
  t.timestamps
end

# NPC conversation state
create_table :conversations do |t|
  t.references :game_instance, null: false
  t.references :npc, null: false
  t.jsonb :history, default: []
  t.text :story_state              # Serialized Ink state
  t.jsonb :variables, default: {}  # Ink variables
  t.string :current_knot
  t.datetime :last_message_at
  t.timestamps
end

# Game events for analytics/anti-cheat
create_table :game_events do |t|
  t.references :game_instance, null: false
  t.string :event_type, null: false
  t.jsonb :event_data, default: {}
  t.datetime :occurred_at, null: false
  t.timestamps
end

# NPC permissions
create_table :npc_permissions do |t|
  t.references :npc, null: false
  t.string :action_type, null: false  # unlock_door, give_item
  t.string :target                    # door_id, item_id
  t.jsonb :conditions, default: {}
  t.timestamps
end
```

---

## API Endpoints Needed

### Core Endpoints (From Original Plans)
- `GET /api/scenario/metadata` - Bootstrap data
- `GET /api/rooms/:id` - Room data
- `POST /api/unlock/:type/:id` - Unlock validation
- `POST /api/inventory` - Inventory sync
- `GET /api/inventory` - Get inventory

### New Endpoints Required

#### NPC Endpoints
- `POST /api/npcs/:id/validate_action` - Validate NPC actions
- `POST /api/npcs/:id/sync_conversation` - Sync conversation state
- `GET /api/npcs/:id/story` - Progressive loading (optional)

#### Event Endpoints
- `POST /api/events` - Log game events

#### Game State Endpoints
- `GET /api/game_state` - Get current state
- `PUT /api/game_state/sync` - Sync state changes
- `POST /api/game_state/reconcile` - Conflict resolution

---

## Risk Assessment

### Original Risk: Medium-Low
### Updated Risk: Medium

**Risk Increase Factors:**
- More systems to integrate (NPCs, Events, State)
- More complex state management
- Conversation state persistence adds complexity
- 24 scenarios to import and test

**Mitigation Strategies:**
- Incremental rollout (system by system)
- Extensive testing at each phase
- Hybrid approach keeps working systems intact
- Dual-mode support (local JSON fallback)
- All systems well-architected and ready

---

## Success Metrics

### Performance Targets
- Room loading: < 500ms (p95)
- Unlock validation: < 300ms (p95)
- Inventory sync: < 200ms (p95)
- NPC action validation: < 300ms (p95)
- Event logging: < 100ms (p95, async)
- State sync: < 200ms (p95, debounced)
- Cache hit rate: > 80%

### Security Targets
- 0 scenario spoilers in client
- 0 unlock bypass exploits
- 0 inventory manipulation exploits
- Server validates 100% of critical actions
- All NPC actions authorized server-side

### Reliability Targets
- 99.9% API uptime
- < 0.1% error rate
- Offline queue: 100% eventual consistency
- State conflicts: < 1% of syncs

---

## Next Steps

### Immediate Actions (Week 1)

1. **Review Updated Plans**
   - Read UPDATED_MIGRATION_STATUS.md
   - Read updated CLIENT_SERVER_SEPARATION_PLAN.md
   - Team discussion and approval

2. **Update Database Schema Design**
   - Add tables for NPCs, Events, State
   - Design indexes for performance
   - Plan migration strategy

3. **Setup Development Environment**
   - Rails Engine skeleton
   - Test database
   - Dual-mode testing setup

4. **Scenario Import Strategy**
   - Plan how to import 24 scenarios
   - Ink script storage strategy
   - NPC permission seeding

### Medium-Term Actions (Weeks 2-4)

1. **Create Rails Engine**
2. **Implement Database Models**
3. **Build API Endpoints** (starting with Room Loading)
4. **Create Client Data Access Layer**

---

## Team Communication

### Regular Updates
- Weekly progress reviews
- Blockers and risks
- Timeline adjustments

### Key Stakeholders
- Development team
- Hacktivity integration team
- QA/Testing team
- Security review team

---

## Conclusion

The codebase has matured significantly with production-ready implementations of NPCs, events, and game state.

### ⭐ RECOMMENDED: Simplified Approach

**See SIMPLIFIED_APPROACH.md** for the recommended implementation:
- **12-14 weeks** (vs 22 weeks)
- **3 tables** (vs 10+)
- **6 endpoints** (vs 15+)
- JSON-based storage
- Simple validation rules
- Much easier to maintain

### Alternative: Complex Approach (This Document)

The detailed plans in this document are fundamentally sound but over-engineered:
- ⚠️ 22 weeks timeline
- ⚠️ 10+ database tables
- ⚠️ 15+ API endpoints
- ⚠️ Complex state management

**We recommend starting with the simplified approach.**

**Estimated Completion:**
- Simplified: 12-14 weeks
- Complex: 22 weeks

**Confidence Level:** High (both approaches)
**Risk Level:**
- Simplified: Low
- Complex: Medium

---

## Document Maintenance

This README and associated plans should be updated:
- Weekly during active development
- After major architectural decisions
- When scope changes
- When timeline adjustments are made

**Current Maintainer:** AI Assistant
**Last Review:** November 20, 2025
**Next Review Due:** December 2025 or at project start
