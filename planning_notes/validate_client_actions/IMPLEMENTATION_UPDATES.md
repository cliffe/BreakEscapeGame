# Implementation Plan Updates
**Date:** November 21, 2025  
**Status:** Updated based on review feedback  

---

## Summary of Changes

This document summarizes the updates made to `IMPLEMENTATION_PLAN.md` based on the comprehensive review in `review2.md`.

---

## Key Fixes Applied

### 1. ✅ Fixed Data Filtering Logic

**Issue:** Current `filtered_room_data` removes `lockType`, breaking client UI.

**Fix Applied:**
- Updated `filter_requires_and_contents_recursive` to **keep** `lockType` and `locked` fields visible
- Only removes `requires` (the answer/solution) and locked `contents`
- Aligns with design decision in GOALS_AND_DECISIONS.md

### 2. ✅ Added Starting Items Initialization

**Issue:** Plan didn't verify starting items are added to inventory on game creation.

**Fix Applied:**
- Updated `initialize_player_state` to populate inventory with items from `startItemsInInventory`
- Uses `deep_dup` to prevent shared object references

### 3. ✅ Fixed NPC itemsHeld Validation

**Issue:** Validation code didn't match actual data structure (array of full objects, not just IDs).

**Fix Applied:**
- Updated `find_npc_holding_item` to handle full item objects in `itemsHeld` array
- Matches by `type` primarily, with optional `id`/`name` verification
- Returns full NPC and item info for validation context

### 4. ✅ Added Transaction Safety

**Issue:** State mutations could fail mid-operation, causing client-server desync.

**Fix Applied:**
- Wrapped `unlock` endpoint in `ActiveRecord::Base.transaction`
- Added rescue for `RecordInvalid` with proper error response
- Ensures atomic updates to `player_state`

### 5. ✅ Added Defensive Start Room Check

**Issue:** Race condition could deny access to starting room on first request.

**Fix Applied:**
- Room endpoint checks both `is_start_room` OR `is_unlocked`
- Auto-adds start room to `unlockedRooms` if missing (defensive programming)
- Prevents 403 error on legitimate first room access

### 6. ✅ Renamed Scenario Endpoint

**Issue:** Current `/games/:id/scenario` returns full unfiltered data.

**Fix Applied:**
- Renamed to `/games/:id/scenario_map`
- Returns minimal metadata (connections, types, lock status) without object contents
- **BREAKING CHANGE:** Client code must be updated

### 7. ✅ Fixed Container ID Resolution

**Issue:** Containers might be identified by `id`, `name`, `objectId`, or `type`.

**Fix Applied:**
- Added `check_container_unlocked` helper that checks all possible identifiers
- Prevents unlock bypass via ID mismatch

### 8. ✅ Fixed Container Endpoint Route

**Issue:** Plan showed `get 'container/:container_id'` without `to:` parameter.

**Fix Applied:**
- Updated to `get 'container/:container_id', to: 'games#container'`

### 9. ✅ Added Phase 9: Client Integration

**Issue:** Plan had no guidance for updating client code to call new endpoints.

**Fix Applied:**
- Added detailed Phase 9 with specific file changes
- Includes code examples for:
  - `addToInventory()` server validation
  - Container minigame lazy-loading
  - Scenario map endpoint usage
  - Error handling and retry logic

### 10. ✅ Merged NPC Tracking into Room Endpoint

**Issue:** Plan had separate Phase 5 for NPC tracking, but it's done in room endpoint.

**Fix Applied:**
- Moved NPC tracking logic into Phase 2 (room endpoint update)
- Tracks encounters **before** sending response (transactional)
- Phase 5 now just has testing tasks

---

## Items Deferred Based on Feedback

### ⏸️ Rate Limiting
- **Decision:** Defer to later phase
- **Rationale:** Can be added via Rack::Attack at API gateway level
- **Status:** Moved to "Future Enhancements (Deferred)"

### ⏸️ Cached Filtered Room Data
- **Decision:** Not implementing
- **Rationale:** Rooms won't be re-requested in typical gameplay
- **Status:** Moved to "Future Enhancements (Deferred)"

### ⏸️ Item Index Caching
- **Decision:** Not implementing in Phase 1
- **Rationale:** Premature optimization; validate performance need first
- **Status:** Moved to "Future Enhancements (Deferred)"

### ⏸️ Starting Inventory Duplication Prevention
- **Decision:** Out of scope
- **Rationale:** Scenario design issue, not server validation issue
- **Status:** Documented as scenario author responsibility

---

## Breaking Changes

### 1. Scenario Endpoint Renamed
- **Before:** `GET /games/:id/scenario`
- **After:** `GET /games/:id/scenario_map`
- **Impact:** Client code must update fetch URL
- **Response:** Now returns minimal metadata, not full scenario with objects

### 2. Container Contents Lazy-Loaded
- **Before:** Contents included in room data
- **After:** Contents fetched via `GET /games/:id/container/:container_id`
- **Impact:** Container minigame must call server to load contents
- **Benefit:** Security - can't extract all contents without unlocking

### 3. Inventory Adds Require Server Validation
- **Before:** Local-only inventory updates
- **After:** `POST /games/:id/inventory` validates before adding
- **Impact:** `addToInventory()` becomes async
- **Benefit:** Prevents collecting items from locked rooms/containers

---

## Updated Phase Order

### Original Plan
1. Data Model & Initialization
2. Data Filtering
3. Container Lazy-Loading
4. Inventory Validation
5. NPC Encounter Tracking
6. Unlock Tracking
7. Sync State Validation
8. Routing
9. Testing & Validation
10. Client Updates

### Updated Plan
1. Data Model & Initialization *(verify starting items added)*
2. Data Filtering *(fix to keep lockType, add NPC tracking)*
3. Container Lazy-Loading *(fix ID resolution)*
4. Inventory Validation *(fix NPC itemsHeld structure)*
5. ~~NPC Tracking~~ *(merged into Phase 2)*
6. Unlock Tracking *(add transaction safety)*
7. Sync State Validation
8. Routing *(rename scenario → scenario_map)*
9. **Client Integration** *(NEW - critical missing phase)*
10. Testing & Validation

---

## New TODO Items Added

### Phase 1
- [ ] 1.3 **UPDATE** `initialize_player_state` to add starting items to inventory

### Phase 2
- [ ] 2.1 Create `filter_requires_and_contents_recursive` (replaces current filter)
- [ ] 2.3 Rename `scenario` endpoint to `scenario_map`
- [ ] 2.4 Add NPC tracking to room endpoint

### Phase 3
- [ ] 3.4 Create `check_container_unlocked` helper
- [ ] 3.5 Create `filter_container_contents` helper
- [ ] 3.7 Fix route to include `to:` parameter

### Phase 4
- [ ] 4.5 **UPDATE** `find_npc_holding_item` (fix structure handling)
- [ ] 4.9 Test NPC itemsHeld validation

### Phase 6
- [ ] 6.1 **UPDATE** `unlock` endpoint with transaction safety
- [ ] 6.2 Test unlock operations are atomic

### Phase 9 (NEW)
- [ ] 9.1 Update `addToInventory()` to validate with server
- [ ] 9.2 Update container minigame to lazy-load contents
- [ ] 9.3 Update scenario loading to use `scenario_map`
- [ ] 9.4 Add error handling for room access
- [ ] 9.5 Test client-server validation flow

---

## Documentation Updates

### Added Sections
1. **Client Integration Details** - Complete code examples for all client changes
2. **Breaking Changes** - Clear list of API changes requiring client updates
3. **Future Enhancements (Deferred)** - Items moved out of scope with rationale
4. **Notes & Design Decisions** - Key architectural choices documented

### Updated Sections
1. **Data Structures Reference** - Clarified item structures
2. **Error Handling** - Added transaction error examples
3. **Testing Strategy** - Added NPC itemsHeld and atomic operation tests

---

## Risk Mitigation

### High Risk Issues Addressed ✅
1. ✅ Client integration plan added (was completely missing)
2. ✅ NPC itemsHeld structure clarified and fixed
3. ✅ Transaction safety added to prevent state corruption
4. ✅ Container ID resolution ambiguity resolved

### Medium Risk Issues Addressed ✅
5. ✅ Race condition for start room access fixed
6. ✅ lockType filtering issue corrected
7. ✅ NPC tracking moved to transactional context

---

## Estimated Timeline

### Original Estimate
- **Total:** ~2 weeks

### Updated Estimate
- **Phase 1-8 (Server):** 1.5 weeks
- **Phase 9 (Client Integration):** 3-4 days **[NEW]**
- **Phase 10 (Testing):** 2-3 days
- **Total:** ~3 weeks

**Additional Time:** ~1 week added for client integration and comprehensive testing.

---

## Next Steps

1. **Review updated implementation plan** - Ensure all stakeholders understand breaking changes
2. **Update client code estimates** - Phase 9 is new, may need task breakdown
3. **Plan migration strategy** - Scenario endpoint rename needs coordinated deployment
4. **Begin implementation** - Start with Phase 1 (server-side changes)
5. **Test incrementally** - Don't wait until Phase 10 to test integration

---

## Questions for Review

1. ✅ **Scenario endpoint rename:** Is breaking change acceptable, or should we keep both endpoints temporarily?
   - **Recommended:** Keep `/scenario` as deprecated alias for one release cycle

2. ✅ **Client validation timeout:** How long should client wait for server validation before showing error?
   - **Recommended:** 5 seconds with 3 retries (exponential backoff)

3. ✅ **Container lazy-loading:** Should we show loading spinner, or fetch on minigame open?
   - **Recommended:** Fetch on open with loading state (better UX)

4. ✅ **Error messaging:** How detailed should client errors be (for player vs developer)?
   - **Recommended:** Generic for player ("Cannot collect item"), detailed in console for devs

---

## Conclusion

The implementation plan has been significantly strengthened with:
- **Critical fixes** to filtering, validation, and transaction safety
- **Comprehensive client integration guidance** (previously missing)
- **Clearer scope boundaries** (what's in vs deferred vs out of scope)
- **Realistic timeline** accounting for client changes

The plan is now **ready for implementation** with clear, actionable tasks and minimal ambiguity.
