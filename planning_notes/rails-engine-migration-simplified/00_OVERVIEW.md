# BreakEscape Rails Engine Migration - Overview

**Version:** 2.0 (Simplified Approach)
**Date:** November 2025
**Status:** Ready for Implementation

---

## Project Aims

Transform BreakEscape from a standalone client-side game into a Rails Engine that:

1. **Integrates with Hacktivity** - Mounts seamlessly into existing Hacktivity platform
2. **Supports Standalone Mode** - Can run independently for development/testing
3. **Tracks Player Progress** - Persists game state server-side
4. **Enables Randomization** - Each game instance has unique passwords/pins
5. **Validates Critical Actions** - Server-side validation for unlocks and inventory
6. **Maintains Client Code** - Minimal changes to existing JavaScript game logic
7. **Scales Efficiently** - Simple architecture, low database overhead

---

## Core Philosophy

### "Simplify, Don't Complicate"

- **Files on filesystem, metadata in database**
- **2 tables, not 10+**
- **Generate data when needed, not in advance**
- **JIT compilation, not build pipelines**
- **Move files, don't rewrite code**

### "Trust the Client, Validate What Matters"

- Client handles: Player movement, dialogue, minigames, UI
- Server validates: Unlocks, room access, inventory, critical state
- Server tracks: Progress, completion, achievements

---

## Key Architectural Decisions

### 1. Database: 2 Simple Tables

**Decision:** Use only 2 tables with JSONB for flexible state storage.

**Tables:**
- `break_escape_missions` - Scenario metadata only
- `break_escape_games` - Player state + scenario snapshot

**Rationale:**
- JSONB perfect for hierarchical game state
- No need for complex relationships
- Easy to add new fields without migrations
- Matches game data structure naturally

**Rejected Alternative:** Normalized relational schema (10+ tables)
**Why:** Over-engineering, slow iteration, complex queries

---

### 2. NPC Scripts: Files on Filesystem

**Decision:** No NPC database table. Serve .ink scripts directly from filesystem with JIT compilation.

**Implementation:**
- Source: `scenarios/ink/npc-name.ink` (version controlled)
- Compiled: `scenarios/ink/npc-name.json` (generated on-demand)
- Endpoint: `GET /games/:id/ink?npc=npc_name` (compiles if needed)

**Rationale:**
- Compilation is fast (~300ms, benchmarked)
- No database bloat
- Edit .ink files directly
- No complex seed process
- No duplication across scenarios

**Rejected Alternative:** NPC registry table with join tables
**Why:** Complexity, duplication, over-engineering

---

### 3. Scenario Data: Per-Instance Generation

**Decision:** Generate scenario JSON via ERB when game instance is created, store in game record.

**Implementation:**
```ruby
# Template: app/assets/scenarios/ceo_exfil/scenario.json.erb
# Generated: game.scenario_data (JSONB)
# Each instance gets unique passwords/pins
```

**Rationale:**
- True randomization per player
- Different passwords for each game
- Scenario solutions never sent to client
- Simple to implement

**Rejected Alternative:** Shared scenario_data table
**Why:** Can't randomize per player, requires complex filtering

---

### 4. Static Assets: Move to public/

**Decision:** Move game files to `public/break_escape/` without modification.

**Structure:**
```
public/break_escape/
├── js/       (ES6 modules, unchanged)
├── css/      (stylesheets, unchanged)
└── assets/   (images, sounds, Tiled maps, unchanged)
```

**Rationale:**
- No asset pipeline complexity
- Direct URLs for Phaser
- Engine namespace isolation
- Simple deployment

**Rejected Alternative:** Rails asset pipeline
**Why:** Unnecessary complexity for Phaser game

---

### 5. Authentication: Polymorphic Player

**Decision:** Use polymorphic `belongs_to :player` for User or DemoUser.

**Modes:**
- **Mounted (Hacktivity):** Uses existing User model via Devise
- **Standalone:** Uses DemoUser model for development

**Rationale:**
- Supports both use cases
- Standard Rails pattern
- Authorization works naturally
- No special-casing in code

**Rejected Alternative:** User-only with optional flag
**Why:** Tight coupling to Hacktivity, harder to develop standalone

---

### 6. API Design: Session-Based

**Decision:** Use Rails session authentication (not JWT).

**Endpoints:**
```
GET  /games/:id/scenario     - Get scenario JSON
GET  /games/:id/ink?npc=...  - Get NPC script (JIT compiled)
GET  /api/games/:id/bootstrap - Initial game data
PUT  /api/games/:id/sync_state - Sync player state
POST /api/games/:id/unlock    - Validate unlock attempt
POST /api/games/:id/inventory - Update inventory
```

**Rationale:**
- Matches Hacktivity's Devise setup
- CSRF protection built-in
- Simpler than JWT
- Web-only use case

**Rejected Alternative:** JWT tokens
**Why:** Adds complexity without benefit

---

### 7. File Organization: Cautious Approach

**Decision:** Use `mv` commands to reorganize, minimize code changes.

**Process:**
1. Use `rails generate` for boilerplate
2. Use `mv` to relocate files (not copy)
3. Edit only what's necessary
4. Test after each phase
5. Commit working state

**Rationale:**
- Preserves git history
- Avoids introducing bugs
- Clear audit trail
- Reversible steps

---

### 8. Client Integration: Minimal Changes

**Decision:** Add ~2 new files, modify ~5 existing files.

**New Files:**
- `config.js` - API configuration
- `api-client.js` - Fetch wrapper

**Modified Files:**
- Scenario loading (use API)
- Unlock validation (call server)
- NPC script loading (use API)
- Inventory sync (call server)
- Main game initialization

**Rationale:**
- <5% code change
- Reduces risk
- Preserves game logic
- Faster implementation

**Rejected Alternative:** Rewrite to use API throughout
**Why:** Unnecessary, high risk, no benefit

---

### 9. Testing: Minitest with Fixtures

**Decision:** Use Minitest (matches Hacktivity) with fixture-based tests.

**Test Types:**
- Model tests (validations, methods)
- Controller tests (authorization, responses)
- Integration tests (full game flow)

**Rationale:**
- Matches Hacktivity's test framework
- Consistent testing approach
- Fixtures easier for game state
- Well-documented pattern

**Rejected Alternative:** RSpec
**Why:** Different from Hacktivity, adds dependency

---

### 10. Authorization: Pundit Policies

**Decision:** Use Pundit for authorization (matches Hacktivity).

**Policies:**
- GamePolicy - Player can only access their own games
- MissionPolicy - Published scenarios visible to all
- Admin overrides for management

**Rationale:**
- Explicit, testable policies
- Flexible for complex rules
- Standard gem
- Matches Hacktivity

**Rejected Alternative:** CanCanCan
**Why:** Less explicit, harder to test

---

## Timeline and Scope

**Estimated Duration:** 10-12 weeks

**Phase Breakdown:**
1. Setup Rails Engine (Week 1) - 1 week
2. Move Game Files (Week 1) - 1 week
3. Reorganize Scenarios (Week 1-2) - 1 week
4. Database Setup (Week 2-3) - 1 week
5. Models and Logic (Week 3-4) - 1 week
6. Controllers and Routes (Week 4-5) - 2 weeks
7. API Implementation (Week 5-6) - 2 weeks
8. Client Integration (Week 7-8) - 2 weeks
9. Testing (Week 9-10) - 2 weeks
10. Standalone Mode (Week 10) - 1 week
11. Deployment (Week 11-12) - 2 weeks

**Total:** 10-12 weeks

---

## Success Criteria

### Must Have (P0)

- ✅ Game runs in Hacktivity at `/break_escape`
- ✅ Player progress persists across sessions
- ✅ Unlocks validated server-side
- ✅ Each game instance has unique passwords
- ✅ NPCs work with dialogue
- ✅ All 24 scenarios loadable
- ✅ Standalone mode works for development

### Should Have (P1)

- ✅ Integration tests pass
- ✅ Authorization policies work
- ✅ JIT Ink compilation works
- ✅ Game state includes all minigame data
- ✅ Admin can manage scenarios
- ✅ Error handling graceful

### Nice to Have (P2)

- Performance monitoring
- Leaderboards
- Save/load system
- Scenario versioning
- Analytics tracking

---

## Risk Mitigation

### Risk: Breaking Existing Game Logic

**Mitigation:**
- Minimal client changes (<5%)
- Phased implementation with testing
- Preserve git history with mv
- Integration tests for game flow

### Risk: Performance Issues

**Mitigation:**
- JIT compilation benchmarked (~300ms)
- JSONB with GIN indexes
- Static assets served directly
- Simple database queries

### Risk: Complex State Management

**Mitigation:**
- JSONB for flexible state
- Server validates only critical actions
- Client remains authoritative for movement/UI
- Clear state sync strategy

### Risk: Hacktivity Integration Issues

**Mitigation:**
- Validated against actual Hacktivity code
- Uses same patterns (Devise, Pundit, Minitest)
- Polymorphic player supports both modes
- CSP nonces for security

---

## What's Different from Original Plan?

### Simplified

**Before:** 3-4 tables (scenarios, npc_scripts, scenario_npcs, games)
**After:** 2 tables (missions, games)

**Before:** Complex NPC registry with join tables
**After:** Files on filesystem, JIT compilation

**Before:** Shared scenario_data in database
**After:** Per-instance generation via ERB

**Before:** Pre-compilation build pipeline
**After:** JIT compilation on first request

**Before:** 10-14 hours P0 prep work
**After:** 0 hours P0 prep work

### Results

- **50% fewer tables**
- **No complex relationships**
- **No build infrastructure**
- **Simpler seed process**
- **Better randomization**
- **Easier development**

---

## Documentation Structure

This migration plan consists of:

1. **00_OVERVIEW.md** (this file) - Aims, philosophy, decisions
2. **01_ARCHITECTURE.md** - Technical design details
3. **02_DATABASE_SCHEMA.md** - Complete schema reference
4. **03_IMPLEMENTATION_PLAN.md** - Step-by-step TODO list
5. **04_API_REFERENCE.md** - API endpoint documentation
6. **05_TESTING_GUIDE.md** - Testing strategy and examples
7. **06_HACKTIVITY_INTEGRATION.md** - Integration instructions
8. **README.md** - Quick start and navigation

---

## Quick Start

**To begin implementation:**

1. Read this overview
2. Read `01_ARCHITECTURE.md` for technical details
3. Read `02_DATABASE_SCHEMA.md` for database design
4. Start with `03_IMPLEMENTATION_PLAN.md` Phase 1
5. Follow the step-by-step instructions
6. Test after each phase
7. Commit working state

**Questions?** Each document has detailed rationale and examples.

---

## Summary

This migration transforms BreakEscape into a Rails Engine using the **simplest possible approach**:

- 2 database tables
- Files on filesystem
- JIT compilation
- Minimal client changes
- Standard Rails patterns

**Ready to start!** Proceed to `03_IMPLEMENTATION_PLAN.md` for the step-by-step guide.
