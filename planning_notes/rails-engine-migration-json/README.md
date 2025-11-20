# BreakEscape Rails Engine Migration - JSON-Centric Approach

## Overview

Complete implementation plan for converting BreakEscape to a Rails Engine using a simplified, JSON-centric architecture.

**Timeline:** 12-14 weeks
**Approach:** Minimal changes, maximum compatibility
**Storage:** JSONB for game state (not complex relational DB)

---

## Quick Start

**Read in order:**

1. **[00_OVERVIEW.md](./00_OVERVIEW.md)** - Start here
   - Project aims and objectives
   - Core philosophy and approach
   - Key architectural decisions
   - Success criteria

2. **[01_ARCHITECTURE.md](./01_ARCHITECTURE.md)** - Technical design
   - System architecture diagrams
   - Database schema (3 tables)
   - API endpoint specifications
   - File organization
   - Models, controllers, views

3. **[02_IMPLEMENTATION_PLAN.md](./02_IMPLEMENTATION_PLAN.md)** - Actionable steps (Part 1)
   - Phase 1-6: Setup through Controllers
   - Specific bash commands
   - Rails generate commands
   - Code examples

4. **[02_IMPLEMENTATION_PLAN_PART2.md](./02_IMPLEMENTATION_PLAN_PART2.md)** - Actionable steps (Part 2)
   - Phase 7-12: Policies through Deployment
   - Client integration
   - Testing setup
   - Standalone mode

5. **[03_DATABASE_SCHEMA.md](./03_DATABASE_SCHEMA.md)** - Database reference
   - Complete schema details
   - JSONB structures
   - Query examples
   - Performance tips

6. **[04_TESTING_GUIDE.md](./04_TESTING_GUIDE.md)** - Testing strategy
   - Fixtures setup
   - Model tests
   - Integration tests
   - Policy tests
   - CI configuration

---

## Key Decisions Summary

### Architecture
- **Rails Engine** (not separate app)
- **Built in current directory** (not separate repo)
- **Dual mode:** Standalone + Hacktivity mounted
- **Session-based auth** (not JWT)
- **Polymorphic player** (User or DemoUser)

### Database
- **3 simple tables** (not 10+)
- **JSONB storage** for game state
- **Scenarios as ERB templates**
- **Lazy-load NPC scripts**

### File Organization
- **Game files → public/break_escape/**
- **Scenarios → app/assets/scenarios/**
- **.ink and .ink.json** in scenario dirs
- **Minimal client changes**

### API
- **6 endpoints** (not 15+)
- **Backwards compatible JSON**
- **Server validates unlocks**
- **Client runs dialogue**

---

## Implementation Phases

| Phase | Duration | Focus | Status |
|-------|----------|-------|--------|
| 1. Setup Rails Engine | Week 1 | Generate structure, Gemfile | 📋 TODO |
| 2. Move Files | Week 1 | public/, scenarios/ | 📋 TODO |
| 3. Reorganize Scenarios | Week 1-2 | ERB templates, ink files | 📋 TODO |
| 4. Database | Week 2 | Migrations, models, seeds | 📋 TODO |
| 5. Scenario Import | Week 2 | Loader service, seeds | 📋 TODO |
| 6. Controllers | Week 3 | Routes, controllers, API | 📋 TODO |
| 7. Policies | Week 3 | Pundit authorization | 📋 TODO |
| 8. Views | Week 4 | Game view, scenarios index | 📋 TODO |
| 9. Client Integration | Week 4-5 | API client, minimal changes | 📋 TODO |
| 10. Standalone Mode | Week 5 | DemoUser, config | 📋 TODO |
| 11. Testing | Week 6 | Fixtures, tests | 📋 TODO |
| 12. Deployment | Week 6 | Documentation, verification | 📋 TODO |

---

## Before You Start

### Prerequisites

```bash
# Ensure clean git state
git status

# Create feature branch
git checkout -b rails-engine-migration

# Backup current state
git add -A
git commit -m "chore: Checkpoint before Rails Engine migration"
```

### Required Tools

- Ruby 3.1+
- Rails 7.0+
- PostgreSQL 14+ (for JSONB)
- Git

### Environment

```bash
# Verify Ruby version
ruby -v  # Should be 3.1+

# Verify Rails
rails -v  # Should be 7.0+

# Verify PostgreSQL
psql --version
```

---

## Key Files to Create

### Configuration
- `lib/break_escape/engine.rb` - Engine definition
- `config/routes.rb` - Engine routes
- `config/initializers/break_escape.rb` - Configuration
- `config/break_escape_standalone.yml` - Standalone config
- `break_escape.gemspec` - Gem specification

### Models
- `app/models/break_escape/scenario.rb`
- `app/models/break_escape/npc_script.rb`
- `app/models/break_escape/game_instance.rb`
- `app/models/break_escape/demo_user.rb`

### Controllers
- `app/controllers/break_escape/games_controller.rb`
- `app/controllers/break_escape/scenarios_controller.rb`
- `app/controllers/break_escape/api/games_controller.rb`
- `app/controllers/break_escape/api/rooms_controller.rb`
- `app/controllers/break_escape/api/npcs_controller.rb`

### Views
- `app/views/break_escape/games/show.html.erb`
- `app/views/break_escape/scenarios/index.html.erb`

### Client
- `public/break_escape/js/config.js` (NEW)
- `public/break_escape/js/core/api-client.js` (NEW)
- Modify existing JS files minimally

---

## Key Commands

```bash
# Generate engine
rails plugin new . --mountable --skip-git

# Generate migrations
rails generate migration CreateBreakEscapeScenarios
rails generate migration CreateBreakEscapeGameInstances
rails generate migration CreateBreakEscapeNpcScripts

# Run migrations
rails db:migrate

# Import scenarios
rails db:seed

# Run tests
rails test

# Start server
rails server
```

---

## Success Criteria

### Functional
- ✅ Game runs in standalone mode
- ✅ Game mounts in Hacktivity
- ✅ All scenarios work
- ✅ NPCs load and function
- ✅ Server validates unlocks
- ✅ State persists

### Performance
- ✅ Room loading < 500ms
- ✅ Unlock validation < 300ms
- ✅ No visual lag
- ✅ Assets load quickly

### Code Quality
- ✅ Rails tests pass
- ✅ Minimal client changes
- ✅ Clear separation
- ✅ Well documented

---

## Rollback Plan

If anything goes wrong:

1. **Git branches** - Each phase has its own commit
2. **Original files preserved** - Moved, not deleted
3. **Dual-mode testing** - Standalone mode for safe testing
4. **Incremental approach** - Test after each phase

```bash
# Revert to checkpoint
git reset --hard <commit-hash>

# Or revert specific files
git checkout HEAD -- <file>
```

---

## Support

If you get stuck:

1. Review the specific phase document
2. Check architecture document for design rationale
3. Verify database schema is correct
4. Run tests to identify issues
5. Check Rails logs for errors

---

## Next Steps

1. ✅ Read 00_OVERVIEW.md
2. ✅ Read 01_ARCHITECTURE.md
3. 📋 Follow 02_IMPLEMENTATION_PLAN.md step by step
4. ✅ Test after each phase
5. ✅ Commit working code frequently

**Good luck! The plan is detailed and tested. Follow it carefully.**
