# Recommendations and Improvements

This document provides prioritized recommendations for improving the migration plan.

---

## Priority 0: Must-Fix Before Implementation (Blockers)

These issues **WILL** cause implementation failures if not addressed.

### P0-1: Fix Ink File Structure (Issue #1)

**Problem:** Plan assumes .ink.json files, but codebase uses .json

**Action Required:**
1. Update Phase 3 file movement commands to handle both patterns
2. Add compilation step before file reorganization
3. Update ScenarioLoader to check both file extensions

**Files to Update:**
- `02_IMPLEMENTATION_PLAN.md` - Phase 3 commands
- `02_IMPLEMENTATION_PLAN.md` - Add Phase 2.5 for compilation

**Time:** 2 hours
**Risk if skipped:** Phase 3 will fail with "file not found" errors

---

### P0-2: Add Ink Compilation Pipeline (Issue #3)

**Problem:** No documented process for compiling .ink → .json

**Action Required:**
1. Document Inklecate installation
2. Create compilation script
3. Add Rake task for compilation
4. Add to deployment pipeline

**Files to Create:**
- `scripts/compile_ink.sh`
- `lib/tasks/ink.rake`

**Files to Update:**
- `02_IMPLEMENTATION_PLAN.md` - Add Phase 2.5
- `04_TESTING_GUIDE.md` - Add compilation to CI

**Time:** 4 hours
**Risk if skipped:** NPC scripts won't work, game will break

---

### P0-3: Fix NPC Schema for Shared Scripts (Issue #2)

**Problem:** Current schema doesn't support NPCs shared across scenarios

**Action Required:**
1. Update database migration for shared NPC support
2. Add join table for scenario-npc relationships
3. Update ScenarioLoader to handle shared NPCs
4. Update models and associations

**Files to Update:**
- `02_IMPLEMENTATION_PLAN.md` - Phase 4 migrations
- `03_DATABASE_SCHEMA.md` - Schema reference
- See detailed fix in `06_UPDATED_SCHEMA.md`

**Time:** 4 hours
**Risk if skipped:** Seed script will fail or create duplicate data

---

## Priority 1: Should-Fix Before Implementation (Quality)

These issues won't block implementation but will cause bugs or data loss.

### P1-1: Extend player_state Schema (Issue #4)

**Problem:** Missing fields for minigame state

**Action Required:**
Add to player_state JSONB:
```ruby
biometricSamples: [],
biometricUnlocks: [],
bluetoothDevices: [],
notes: [],
startTime: nil
```

**Files to Update:**
- `02_IMPLEMENTATION_PLAN.md` - Phase 4 migration
- `03_DATABASE_SCHEMA.md` - player_state structure
- `01_ARCHITECTURE.md` - Update examples

**Time:** 1 hour
**Risk if skipped:** Minigame progress lost on page reload

---

### P1-2: Clarify Room Asset Loading (Issue #5)

**Problem:** Unclear how Tiled maps are served

**Action Required:**
1. Document that Tiled maps remain static assets
2. Clarify API returns game logic only
3. Update client integration example

**Files to Update:**
- `01_ARCHITECTURE.md` - API endpoint documentation
- `02_IMPLEMENTATION_PLAN_PART2.md` - Phase 9 client changes

**Time:** 2 hours
**Risk if skipped:** Confusion during implementation, potential rework

---

### P1-3: Add JSON Validation to ERB Processing

**Problem:** ERB errors could produce invalid JSON

**Action Required:**
```ruby
def load
  # ... ERB processing ...
  output = erb.result(binding_context.get_binding)

  # Validate JSON
  JSON.parse(output)
rescue JSON::ParserError => e
  raise "Invalid JSON in #{scenario_name}: #{e.message}"
end
```

**Files to Update:**
- `02_IMPLEMENTATION_PLAN.md` - Phase 5 ScenarioLoader code

**Time:** 30 minutes
**Risk if skipped:** Hard-to-debug runtime errors

---

## Priority 2: Nice-to-Have Improvements (Enhancements)

These are optional improvements that would enhance the system.

### P2-1: Add Minigame Results API Endpoint

**Rationale:** Currently, minigame results are client-side only.

**Proposed Addition:**
```ruby
# POST /api/games/:id/minigame_result
def minigame_result
  authorize @game_instance

  minigame_name = params[:minigameName]
  success = params[:success]
  score = params[:score]

  # Track in player_state
  @game_instance.player_state['minigameResults'] ||= []
  @game_instance.player_state['minigameResults'] << {
    name: minigame_name,
    success: success,
    score: score,
    timestamp: Time.current
  }
  @game_instance.save!

  render json: { success: true }
end
```

**Benefits:**
- Track player performance
- Analytics on minigame difficulty
- Leaderboards possible

**Time:** 2 hours

---

### P2-2: Add Scenario Versioning

**Rationale:** Scenarios will evolve, need version tracking.

**Proposed Addition:**
```ruby
create_table :break_escape_scenarios do |t|
  # ... existing fields ...
  t.string :version, default: '1.0.0'
  t.datetime :published_at
end
```

**Benefits:**
- Track scenario updates
- Support A/B testing
- Rollback capability

**Time:** 1 hour

---

### P2-3: Add Game Instance Snapshots

**Rationale:** Allow players to save/load game state.

**Proposed Addition:**
```ruby
create_table :break_escape_game_snapshots do |t|
  t.references :game_instance
  t.jsonb :snapshot_data
  t.string :snapshot_type  # auto, manual
  t.timestamps
end
```

**Benefits:**
- Auto-save every N minutes
- Manual save points
- Recover from bugs

**Time:** 3 hours

---

### P2-4: Add Performance Monitoring

**Rationale:** Track API performance and errors.

**Proposed Addition:**
```ruby
# lib/break_escape/performance_monitor.rb
module BreakEscape
  class PerformanceMonitor
    def self.track(action_name)
      start = Time.current
      result = yield
      duration = Time.current - start

      Rails.logger.info "[BreakEscape] #{action_name} completed in #{duration}ms"
      result
    rescue => e
      Rails.logger.error "[BreakEscape] #{action_name} failed: #{e.message}"
      raise
    end
  end
end

# Usage in controllers:
def bootstrap
  PerformanceMonitor.track('bootstrap') do
    # ... existing code ...
  end
end
```

**Benefits:**
- Identify slow endpoints
- Track error rates
- Production debugging

**Time:** 2 hours

---

## Priority 3: Documentation Improvements

### P3-1: Add Troubleshooting Guide

**Content to Add:**
- Common installation issues
- Debugging NPC scripts
- Fixing migration errors
- Client-server sync issues

**Location:** `planning_notes/rails-engine-migration-json/08_TROUBLESHOOTING.md`

**Time:** 3 hours

---

### P3-2: Add API Usage Examples

**Content to Add:**
- cURL examples for each endpoint
- JavaScript fetch examples
- Error response formats
- Rate limiting info (if added)

**Location:** `planning_notes/rails-engine-migration-json/09_API_EXAMPLES.md`

**Time:** 2 hours

---

### P3-3: Add Development Workflow Guide

**Content to Add:**
- Setting up local development
- Creating new scenarios
- Testing workflow
- Debugging tips

**Location:** `planning_notes/rails-engine-migration-json/10_DEV_WORKFLOW.md`

**Time:** 2 hours

---

## Priority 4: Testing Enhancements

### P4-1: Add Integration Test for Complete Flow

**Proposed Test:**
```ruby
# test/integration/break_escape/complete_game_flow_test.rb
class CompleteGameFlowTest < ActionDispatch::IntegrationTest
  test "player can complete full scenario" do
    user = users(:user)
    sign_in user

    # 1. Select scenario
    get scenarios_path
    assert_response :success

    # 2. Start game
    post scenario_path(scenarios(:ceo_exfil))
    follow_redirect!
    game = assigns(:game_instance)

    # 3. Bootstrap
    get api_game_bootstrap_path(game)
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'reception', data['startRoom']

    # 4. Unlock room
    post api_game_unlock_path(game), params: {
      targetType: 'door',
      targetId: 'office',
      method: 'password',
      attempt: 'correct_password'
    }
    assert_response :success
    result = JSON.parse(response.body)
    assert result['success']

    # 5. Complete scenario
    # ... test full flow ...
  end
end
```

**Time:** 4 hours

---

### P4-2: Add Performance Tests

**Proposed:**
```ruby
# test/performance/break_escape/api_performance_test.rb
class ApiPerformanceTest < ActionDispatch::IntegrationTest
  test "bootstrap endpoint responds in <200ms" do
    game = game_instances(:active_game)

    benchmark = Benchmark.measure do
      get api_game_bootstrap_path(game)
    end

    assert benchmark.real < 0.2, "Bootstrap took #{benchmark.real}s (>200ms)"
  end
end
```

**Time:** 2 hours

---

## Implementation Priority Matrix

| Priority | Items | Total Time | Start When |
|----------|-------|------------|------------|
| **P0** | 3 items | ~10 hours | Before Phase 1 |
| **P1** | 3 items | ~3.5 hours | Before Phase 4 |
| **P2** | 4 items | ~8 hours | After Phase 12 (post-launch) |
| **P3** | 3 items | ~7 hours | Parallel with implementation |
| **P4** | 2 items | ~6 hours | Phase 10 (Testing) |

---

## Recommended Action Plan

### Week 0: Pre-Implementation Fixes (10-14 hours)

**Day 1-2:**
1. ✅ Fix Ink file structure (P0-1) - 2h
2. ✅ Add Ink compilation pipeline (P0-2) - 4h
3. ✅ Fix NPC schema (P0-3) - 4h

**Day 3:**
4. ✅ Extend player_state schema (P1-1) - 1h
5. ✅ Clarify room asset loading (P1-2) - 2h
6. ✅ Add JSON validation (P1-3) - 0.5h

**Output:** Updated planning documents ready for implementation

---

### During Implementation: Parallel Tasks

**While building Phases 1-6:**
- Write troubleshooting guide (P3-1)
- Write API examples (P3-2)
- Write dev workflow guide (P3-3)

**During Phase 10 (Testing):**
- Add integration tests (P4-1)
- Add performance tests (P4-2)

---

### Post-Launch: Enhancements

**After Phase 12 (Deployment):**
- Minigame results endpoint (P2-1)
- Scenario versioning (P2-2)
- Game snapshots (P2-3)
- Performance monitoring (P2-4)

---

## Summary

**Must fix before starting:** 3 items (P0)
**Should fix before Phase 4:** 3 items (P1)
**Total pre-work:** ~14 hours (1.75 days)

**With fixes applied:**
- ✅ Implementation will succeed
- ✅ No data loss
- ✅ No runtime errors
- ✅ Clean architecture

**Timeline Impact:** +1.75 days prep, but saves 3-5 days of rework

---

**Next Document:** [06_UPDATED_SCHEMA.md](./06_UPDATED_SCHEMA.md) - Corrected database schema with shared NPC support
