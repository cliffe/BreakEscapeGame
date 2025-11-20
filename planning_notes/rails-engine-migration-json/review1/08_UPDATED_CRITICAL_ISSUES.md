# Updated Critical Issues (After Simplification)

**Date:** November 20, 2025
**Status:** With 2-table simplified schema

This document updates the critical issues list based on the **simplified 2-table approach** (missions + games).

---

## Issues RESOLVED by Simplification

### ✅ Issue #2: Shared NPC Schema - RESOLVED
**Status:** NO LONGER APPLICABLE

With no NPC registry, this issue is completely eliminated!

**Old Problem:** Database schema didn't support shared NPCs
**New Solution:** No database storage of NPCs at all - served from filesystem

**Time Saved:** 4 hours of complex schema design

---

## Issues STILL REQUIRING FIXES

### Issue #1: Ink File Structure Mismatch

**Severity:** 🟡 MEDIUM (was CRITICAL, now less critical)
**Impact:** File serving logic needs to handle both `.json` and `.ink.json`

**Problem:**
- Some files: `helper-npc.json`
- Some files: `alice-chat.ink.json`
- Scenarios reference various patterns

**Solution:**
```ruby
# app/controllers/break_escape/games_controller.rb
def resolve_ink_path(story_path)
  # story_path: "scenarios/ink/helper-npc.json"
  path = Rails.root.join(story_path)

  # Try exact path first
  return path if File.exist?(path)

  # Try .ink.json variant
  ink_json_path = path.to_s.gsub(/\.json$/, '.ink.json')
  return Pathname.new(ink_json_path) if File.exist?(ink_json_path)

  # Try .json variant (remove .ink. if present)
  json_path = path.to_s.gsub(/\.ink\.json$/, '.json')
  return Pathname.new(json_path) if File.exist?(json_path)

  # Not found
  path
end
```

**Effort:** 30 minutes
**Priority:** P1 (should fix before Phase 6)

---

### Issue #3: Missing Ink Compilation Pipeline

**Severity:** 🔴 CRITICAL
**Impact:** NPCs won't work without compiled scripts

**Problem:** Same as before - need to compile .ink → .json

**Solution:** Still need compilation script

```bash
# scripts/compile_ink.sh
#!/bin/bash
for ink_file in scenarios/ink/*.ink; do
  base=$(basename "$ink_file" .ink)
  json_out="scenarios/ink/${base}.json"

  # Skip if up-to-date
  if [ -f "$json_out" ] && [ "$json_out" -nt "$ink_file" ]; then
    echo "✓ $base.json is up to date"
    continue
  fi

  echo "Compiling $base.ink..."
  inklecate -o "$json_out" "$ink_file"
done
```

**Effort:** 2-3 hours (script + docs + Rake task)
**Priority:** P0 (must fix before Phase 3)

---

### Issue #4: Incomplete Global State

**Severity:** 🟢 LOW (was MEDIUM, now built into schema)
**Impact:** Already fixed in new schema!

**Solution:** New player_state schema already includes:
```ruby
player_state: {
  biometricSamples: [],
  biometricUnlocks: [],
  bluetoothDevices: [],
  notes: [],
  health: 100
}
```

**Status:** ✅ RESOLVED by new schema

---

### Issue #5: Room Asset Loading

**Severity:** 🟢 LOW
**Impact:** Just needs documentation clarification

**Solution:**
- Tiled maps stay in `public/break_escape/assets/rooms/`
- Served as static files
- Scenario data served via `/games/:id/scenario`

**Effort:** Documentation update only
**Priority:** P2

---

## NEW Issues from Simplified Approach

### New Issue #6: Scenario Data Size in Database

**Severity:** 🟡 MEDIUM
**Impact:** Each game instance stores full scenario JSON

**Problem:**
- Each game stores complete scenario_data JSONB
- 100 players × 50KB scenario = 5MB scenario data
- Not terrible, but worth monitoring

**Mitigation:**
- PostgreSQL JSONB is efficient
- GIN index for fast queries
- Consider cleanup of abandoned games

**Alternative:**
- Store scenario_data reference only
- Generate on-demand (slower but smaller DB)

**Recommendation:** Keep current approach, monitor DB size

**Effort:** 0 hours (just awareness)
**Priority:** P3 (monitor only)

---

### New Issue #7: Ink File Security

**Severity:** 🟡 MEDIUM
**Impact:** Need to validate NPC access per game

**Problem:**
```ruby
# Can player access this NPC?
# Need to verify NPC is actually in their game's scenario
```

**Solution:** Already implemented in `find_npc_in_scenario`
```ruby
def find_npc_in_scenario(npc_id)
  @game.scenario_data['rooms']&.each do |_room_id, room_data|
    npc = room_data['npcs']&.find { |n| n['id'] == npc_id }
    return npc if npc
  end
  nil  # Returns nil if NPC not in this game
end
```

**Status:** ✅ Already handled
**Priority:** N/A

---

## Updated Priority Summary

| Issue | Old Severity | New Severity | Status | Effort |
|-------|--------------|--------------|--------|--------|
| #1: Ink files | 🔴 Critical | 🟡 Medium | Open | 30 min |
| #2: NPC schema | 🟠 High | ✅ Resolved | Resolved | 0h |
| #3: Ink compilation | 🔴 Critical | 🔴 Critical | Open | 2-3h |
| #4: Global state | 🟡 Medium | ✅ Resolved | Resolved | 0h |
| #5: Room assets | 🟡 Medium | 🟢 Low | Open | Docs only |
| #6: DB size | N/A | 🟡 Medium | Monitor | 0h |
| #7: Ink security | N/A | ✅ Handled | Resolved | 0h |

---

## Updated Fix Timeline

### P0: Must-Fix Before Implementation (2-3 hours)

1. **Ink Compilation Pipeline** - 2-3 hours
   - Install inklecate
   - Create compilation script
   - Add Rake task
   - Document in Phase 2

**Total:** 2-3 hours (down from 10 hours!)

---

### P1: Should-Fix Before Phase 6 (30 minutes)

2. **Ink File Path Resolution** - 30 minutes
   - Add fallback logic to `resolve_ink_path`
   - Handle .json and .ink.json variants

---

### P2: Nice-to-Have (Docs only)

3. **Room Asset Clarification** - 15 minutes
   - Document that Tiled maps are static
   - Update architecture docs

---

## Summary of Simplification Benefits

**Eliminated:**
- ✅ NPC schema complexity (Issue #2)
- ✅ Global state tracking (Issue #4 - now in schema)
- ✅ Ink security concerns (Issue #7 - already handled)

**Remaining:**
- ⚠️ Ink compilation (still critical)
- ⚠️ File path handling (now easier)

**Time Saved:**
- Old approach: ~10 hours of P0 fixes
- New approach: ~3 hours of P0 fixes
- **Savings: 7 hours**

---

## New Recommendation

**Before Starting Phase 1:**
1. ✅ Install inklecate compiler
2. ✅ Create compilation script
3. ✅ Compile all .ink files
4. ✅ Document compilation in Phase 2

**Total Prep:** 2-3 hours (was 10-14 hours!)

**Timeline Impact:** +0.5 days (was +1.75 days)

---

**Result:** Much simpler path to implementation! 🎉
