# BreakEscape Rails Engine - Migration Documentation

**Complete, self-contained migration plan from standalone game to Rails Engine**

Version: 2.0 (Simplified Approach)
Date: November 2025
Status: Ready for Implementation

---

## Quick Start

**To begin migration:**

1. Read [00_OVERVIEW.md](./00_OVERVIEW.md) - Understand aims and decisions (15 min)
2. Read [01_ARCHITECTURE.md](./01_ARCHITECTURE.md) - Review technical design (20 min)
3. Start [03_IMPLEMENTATION_PLAN.md](./03_IMPLEMENTATION_PLAN.md) - Follow step-by-step (Phases 1-12)

**Estimated time:** 10-12 weeks (78 hours total)

---

## Documentation Structure

### Core Documents (Read in Order)

1. **[00_OVERVIEW.md](./00_OVERVIEW.md)** - Start here!
   - Project aims and philosophy
   - All 10 architectural decisions with rationale
   - Timeline and success criteria
   - What changed from original plan
   - **Read first:** 15 minutes

2. **[01_ARCHITECTURE.md](./01_ARCHITECTURE.md)** - Technical design
   - Complete system diagrams
   - Final directory structure
   - Database schema (2 tables)
   - Model code (Mission, Game)
   - Routes and API endpoints
   - JIT Ink compilation
   - ERB templates
   - Authorization (Pundit)
   - **Read second:** 20 minutes

3. **[02_DATABASE_SCHEMA.md](./02_DATABASE_SCHEMA.md)** - Schema reference
   - break_escape_missions table
   - break_escape_games table
   - Column definitions
   - JSONB structures (scenario_data, player_state)
   - Indexes and relationships
   - Example records
   - Common queries
   - Migrations code
   - **Reference during implementation**

### Implementation (Follow Step-by-Step)

4. **[03_IMPLEMENTATION_PLAN.md](./03_IMPLEMENTATION_PLAN.md)** - Phases 1-6
   - **THE MOST IMPORTANT DOCUMENT**
   - Explicit bash mv commands
   - rails generate commands
   - Code to edit after generation
   - Test instructions
   - Commit messages
   - **Phases:**
     - Phase 1: Setup Rails Engine (8h)
     - Phase 2: Move Game Files (4h)
     - Phase 3: Scenario ERB Templates (6h)
     - Phase 4: Database Setup (6h)
     - Phase 5: Seed Data (2h)
     - Phase 6: Controllers & Routes (12h)

5. **[03_IMPLEMENTATION_PLAN_PART2.md](./03_IMPLEMENTATION_PLAN_PART2.md)** - Phases 7-12
   - **Continuation of implementation**
   - **Phases:**
     - Phase 7: Authorization Policies (4h)
     - Phase 8: Views (6h)
     - Phase 9: Client Integration (12h)
     - Phase 10: Testing (8h)
     - Phase 11: Standalone Mode (4h)
     - Phase 12: Final Integration (6h)

---

## Key Features

### Simplified Architecture

- ✅ **2 database tables** (missions + games)
- ✅ **Files on filesystem** (scenarios, ink scripts)
- ✅ **JIT compilation** (~300ms, benchmarked)
- ✅ **ERB randomization** (unique passwords per game)
- ✅ **Polymorphic player** (User/DemoUser)
- ✅ **Session-based auth** (Devise compatible)
- ✅ **Minimal client changes** (<5% code)

### What Changed from Original Plan

| Aspect | Old Plan | New Plan | Benefit |
|--------|----------|----------|---------|
| **Tables** | 3-4 tables | 2 tables | Simpler |
| **NPC Storage** | Database registry | Files + JIT compilation | No duplication |
| **Scenario Data** | Shared in DB | Per-instance ERB generation | Better randomization |
| **Compilation** | Build pipeline | JIT on-demand | No build step |
| **Prep Work** | 10-14 hours P0 fixes | 0 hours | Eliminated |

---

## Architecture Summary

### Database (PostgreSQL + JSONB)

```
break_escape_missions (metadata only)
├── id
├── name                 # 'ceo_exfil'
├── display_name         # 'CEO Exfiltration'
├── published
└── difficulty_level

break_escape_games (state + snapshot)
├── id
├── player_type         # Polymorphic (User/DemoUser)
├── player_id
├── mission_id
├── scenario_data       # JSONB - ERB-generated scenario
├── player_state        # JSONB - all game progress
├── status
└── timestamps
```

### API Endpoints

```
GET  /games/:id/scenario     - Scenario JSON (ERB-generated)
GET  /games/:id/ink?npc=X    - NPC script (JIT compiled)
GET  /games/:id/bootstrap    - Initial game data
PUT  /games/:id/sync_state   - Sync player state
POST /games/:id/unlock       - Validate unlock
POST /games/:id/inventory    - Update inventory
```

### File Organization

```
app/assets/scenarios/        # ERB templates
├── ceo_exfil/
│   └── scenario.json.erb    # <%= random_password %>
└── cybok_heist/
    └── scenario.json.erb

scenarios/ink/              # Ink scripts (JIT compiled)
├── helper-npc.ink          # Source
└── helper-npc.json         # Compiled on-demand

public/break_escape/        # Static game assets
├── js/                     # Game code (unchanged)
├── css/                    # Stylesheets (unchanged)
└── assets/                 # Images/sounds (unchanged)
```

---

## Prerequisites

Before starting Phase 1:

```bash
# Verify environment
ruby -v   # 3.0+
rails -v  # 7.0+
psql --version  # PostgreSQL 14+

# Verify location
cd /home/user/BreakEscape
pwd  # Should be /home/user/BreakEscape

# Create checkpoint
git add -A
git commit -m "chore: Checkpoint before Rails Engine migration"
git checkout -b rails-engine-migration
```

---

## Phase Checklist

Track your progress:

- [ ] Phase 1: Setup Rails Engine (Week 1, 8h)
- [ ] Phase 2: Move Game Files (Week 1, 4h)
- [ ] Phase 3: Scenario ERB Templates (Week 1-2, 6h)
- [ ] Phase 4: Database Setup (Week 2-3, 6h)
- [ ] Phase 5: Seed Data (Week 3, 2h)
- [ ] Phase 6: Controllers & Routes (Week 4-5, 12h)
- [ ] Phase 7: Authorization Policies (Week 5, 4h)
- [ ] Phase 8: Views (Week 5-6, 6h)
- [ ] Phase 9: Client Integration (Week 7-8, 12h)
- [ ] Phase 10: Testing (Week 9-10, 8h)
- [ ] Phase 11: Standalone Mode (Week 10, 4h)
- [ ] Phase 12: Final Integration (Week 11-12, 6h)

**Total:** 78 hours over 10-12 weeks

---

## Success Criteria

### Must Have (P0)

- ✅ Game runs in Hacktivity at `/break_escape`
- ✅ Player progress persists across sessions
- ✅ Unlocks validated server-side
- ✅ Each game instance has unique passwords
- ✅ NPCs work with dialogue
- ✅ All 24 scenarios loadable
- ✅ Standalone mode works

### Should Have (P1)

- ✅ Tests pass
- ✅ Authorization works
- ✅ JIT compilation works
- ✅ Game state complete

---

## Troubleshooting

### Common Issues

**Problem:** `mv` command fails - "No such file or directory"
**Solution:** Check that source file exists: `ls -la path/to/file`

**Problem:** Rails generates files in wrong location
**Solution:** Ensure you're in project root: `pwd` should show `/home/user/BreakEscape`

**Problem:** Ink compilation fails
**Solution:** Verify inklecate exists and is executable: `ls -la bin/inklecate && bin/inklecate --version`

**Problem:** Scenario ERB has JSON parse error
**Solution:** Check ERB syntax, ensure quotes are escaped properly

**Problem:** Tests fail with "Player must exist"
**Solution:** Check fixtures have correct polymorphic syntax: `player: test_user (BreakEscape::DemoUser)`

### Getting Help

1. **Check the phase instructions** - Re-read carefully
2. **Verify prerequisites** - Ensure previous phases completed
3. **Check git status** - Ensure files moved correctly
4. **Run tests** - `rails test` to verify state
5. **Check Rails console** - Test models directly

---

## Philosophy

### "Simplify, Don't Complicate"

- Files on filesystem, metadata in database
- 2 tables, not 10+
- Generate data when needed, not in advance
- JIT compilation, not build pipelines
- Move files, don't rewrite code

### "Trust the Client, Validate What Matters"

- Client handles: Movement, dialogue, minigames, UI
- Server validates: Unlocks, room access, inventory
- Server tracks: Progress, completion, achievements

---

## Technology Stack

- **Backend:** Rails 7.0+ (Engine)
- **Database:** PostgreSQL 14+ (JSONB)
- **Auth:** Devise (session-based)
- **Authorization:** Pundit
- **Testing:** Minitest with fixtures
- **Frontend:** Phaser.js (unchanged)
- **Dialogue:** Ink.js (JIT compiled)

---

## What This Migration Achieves

### Before (Standalone Game)

- ❌ Client-side only
- ❌ No progress persistence
- ❌ No user tracking
- ❌ Hardcoded passwords
- ❌ Can't integrate with platforms

### After (Rails Engine)

- ✅ Server-side state management
- ✅ Progress persists across sessions
- ✅ Multi-user support
- ✅ Unique passwords per game
- ✅ Mounts in Hacktivity
- ✅ API for future enhancements
- ✅ Standalone mode for development

---

## Next Steps After Migration

1. **Deploy to Hacktivity staging**
2. **Test in production environment**
3. **Monitor performance**
4. **Gather user feedback**
5. **Iterate and improve**

### Future Enhancements (Post-Launch)

- Leaderboards
- Save/load game states
- Scenario versioning
- Analytics tracking
- Admin dashboard
- Performance monitoring

---

## Support

### During Implementation

- Follow phases in order
- Test after each phase
- Commit working state
- Refer to architecture docs

### After Implementation

- See `HACKTIVITY_INTEGRATION.md` (created in Phase 12)
- Consult Rails Engine documentation
- Review Pundit documentation for authorization
- Check Phaser.js docs for game changes

---

## License

MIT

---

## Credits

BreakEscape Team
Migration Plan v2.0 - November 2025

---

**Ready to start?** Begin with [00_OVERVIEW.md](./00_OVERVIEW.md) → [03_IMPLEMENTATION_PLAN.md](./03_IMPLEMENTATION_PLAN.md)

Good luck! 🚀
