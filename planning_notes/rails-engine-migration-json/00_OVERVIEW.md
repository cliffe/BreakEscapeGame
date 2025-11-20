# BreakEscape Rails Engine Migration - Overview

## Project Aims

Convert BreakEscape from a standalone browser game to a **Rails Engine** that can:

1. **Mount in Hacktivity Cyber Security Labs**
   - Integrate with existing Devise user authentication
   - Share user sessions and permissions
   - Embed game canvas in Hacktivity pages
   - Future: Access to VMs and lab infrastructure

2. **Run Standalone**
   - Single-user demo mode for testing and development
   - Simple configuration-based user setup
   - No authentication complexity in standalone mode

3. **Maintain Game Quality**
   - Preserve all existing game functionality
   - Minimal changes to client-side code
   - Keep modular ES6 architecture intact
   - Maintain performance and UX

## Core Philosophy

**Simplify, Don't Complicate**

- Use JSON storage (game state already in this format)
- Keep client-side game logic unchanged where possible
- Validate only what matters server-side
- Move files, don't rewrite them
- Test incrementally

## Architectural Approach

### JSON-Centric Storage

**Instead of** complex relational database:
```ruby
# One JSONB column stores entire player state
{
  "currentRoom": "room_office",
  "unlockedRooms": ["room_reception", "room_office"],
  "unlockedObjects": ["desk_drawer_123"],
  "inventory": [{"type": "key", "name": "Office Key"}],
  "encounteredNPCs": ["security_guard"],
  "globalVariables": {"alarm_triggered": false}
}
```

### Minimal Server Validation

**Server validates:**
- ✅ Unlock attempts (checks scenario solutions)
- ✅ Room access (is room unlocked?)
- ✅ Inventory changes (is item in unlocked location?)
- ✅ NPC encounters (is NPC in current room?)

**Client trusted for:**
- ⚠️ Player position (doesn't affect security)
- ⚠️ Global variables (synced periodically)
- ⚠️ Minigame mechanics (only result validated)

### Static Asset Serving

**Game files stay mostly unchanged:**
- JS/CSS/Assets → `public/break_escape/`
- Scenarios → `app/assets/scenarios/` (with ERB)
- Game served via Rails view (for CSP nonces)
- Assets loaded statically (bypasses asset pipeline)

## Key Decisions Summary

### 1. Database Schema
- **3 simple tables** (not 10+)
- **JSONB storage** for game state
- **Polymorphic user** for flexibility

### 2. API Endpoints
- **6 simple endpoints** (not 15+)
- **Backwards compatible** JSON format
- **Session-based auth** (not JWT)

### 3. File Organization
- **Build in current directory** (not separate repo)
- **Move files with bash** (not copy/rewrite)
- **Keep client code unchanged** where possible

### 4. NPC & Scenarios
- **Lazy-load Ink scripts** on encounter
- **ERB templates** for scenario JSON (randomization)
- **Store .ink source** and compiled .ink.json
- **All conversations client-side** (instant UX)

### 5. Security & Auth
- **Session-based** authentication
- **Pundit policies** for authorization
- **CSP with nonces** for inline scripts
- **Polymorphic player** model

### 6. Testing Strategy
- **Rails fixtures** for test data
- **Integration tests** following Hacktivity patterns
- **Manual testing** steps for each phase

## Timeline Estimate

**12-14 weeks total:**
- Weeks 1-2: Setup Rails Engine structure
- Weeks 3-4: Database, models, API endpoints
- Weeks 5-6: Client integration (minimal changes)
- Weeks 7-8: Scenario ERB templates, NPC loading
- Weeks 9-10: Testing and bug fixes
- Weeks 11-12: Hacktivity integration
- Weeks 13-14: Polish and deployment

## Risk Mitigation

### Low Risk Approach

1. **Keep original files** - work in same repo, use git
2. **Test incrementally** - each phase independently
3. **Dual-mode support** - standalone + mounted
4. **Minimal rewrites** - move files, update paths only
5. **Backwards compatible** - client code expects same data

### Rollback Strategy

- Git branches for each phase
- Original files preserved during moves
- Can revert any step
- Standalone mode for safe testing

## Success Criteria

### Functional Requirements
- ✅ Game runs in standalone mode
- ✅ Game mounts in Hacktivity
- ✅ All scenarios work
- ✅ NPCs and dialogue function
- ✅ Server validates unlocks
- ✅ Progress persists

### Performance Requirements
- ✅ Room loading < 500ms
- ✅ Unlock validation < 300ms
- ✅ No visual lag
- ✅ Assets load quickly

### Code Quality
- ✅ Rails tests pass
- ✅ Minimal client changes
- ✅ Clear separation of concerns
- ✅ Well-documented

## Document Structure

This implementation plan includes:

1. **00_OVERVIEW.md** (this file) - Aims and decisions
2. **01_ARCHITECTURE.md** - Detailed technical design
3. **02_IMPLEMENTATION_PLAN.md** - Step-by-step TODO
4. **03_DATABASE_SCHEMA.md** - Models and migrations
5. **04_API_ENDPOINTS.md** - API specification
6. **05_CLIENT_INTEGRATION.md** - Client-side changes
7. **06_TESTING_GUIDE.md** - Testing strategy
8. **07_DEPLOYMENT.md** - Deployment steps

## Getting Started

**Read in order:**
1. This overview (understand aims)
2. Architecture document (understand design)
3. Implementation plan (follow TODO)

**Before starting:**
- Commit all current changes
- Create feature branch
- Backup database (if exists)

## Questions or Issues

If anything is unclear:
1. Check architecture document
2. Review specific section
3. Test in standalone mode first
4. Ask for clarification

**Remember:** Goal is simplicity. If something feels complex, there's probably a simpler way.
