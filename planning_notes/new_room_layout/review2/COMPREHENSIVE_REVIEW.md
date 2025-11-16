# Comprehensive Review 2: Room Layout Implementation Plan
## Executive Summary

**Review Date**: 2025-11-16
**Reviewer**: Technical Analysis Team
**Overall Assessment**: 7.5/10

The room layout implementation plan is well-structured and addresses many critical aspects. However, through detailed validation against the `ceo_exfil.json` scenario, several critical issues have been identified that **will cause failures** if not addressed.

**Critical Finding**: The asymmetric door alignment bug identified in review1 is **confirmed** and will manifest in ceo_exfil.json's office1→office2/office3 connections.

---

## Scenario Analysis: ceo_exfil.json

### Room Structure
```
        [closet]          [server1]
           |                  |
         [ceo]            [office3]
           |                  |
       [office2]-------[office1]
                           |
                      [reception]
```

### Room Connections Map
- **reception**: north → office1
- **office1**: north → [office2, office3], south → reception
- **office2**: north → ceo, south → office1
- **office3**: north → server1, south → office1
- **ceo**: north → closet, south → office2
- **closet**: south → ceo
- **server1**: south → office3

### Critical Test Case: office1's Multiple North Connections

This scenario contains the **exact edge case** that will expose the asymmetric door alignment bug:
- office1 has **2 north connections** (office2 and office3)
- office2 has **1 south connection** (office1)
- office3 has **1 south connection** (office1)

---

## Step-by-Step Positioning Simulation

### Assumptions
- All rooms are standard office size: 10×10 tiles (from plan, but **NOTE**: current rooms might be 10×8)
- Grid units: 5 tiles wide × 4 tiles tall
- Standard room = 2×2 grid units (320px wide × 320px tall)
- Stacking height for 2 grid units = 256px (8 tiles)

### Phase 1: Dimension Extraction
```javascript
reception:  10×10 tiles = 2×2 grid units (320×320px, stacking: 256px)
office1:    10×10 tiles = 2×2 grid units (320×320px, stacking: 256px)
office2:    10×10 tiles = 2×2 grid units (320×320px, stacking: 256px)
office3:    10×10 tiles = 2×2 grid units (320×320px, stacking: 256px)
ceo:        10×10 tiles = 2×2 grid units (320×320px, stacking: 256px)
closet:     5×6 tiles  = 1×1 grid units (160×192px, stacking: 128px)
server1:    10×10 tiles = 2×2 grid units (320×320px, stacking: 256px)
```

### Phase 2: Room Positioning

**Step 1**: Place starting room (reception)
```
reception at grid(0, 0) = world(0, 0)
```

**Step 2**: Process reception → office1 (north)
```javascript
// Single north connection
positionNorthSingle(reception, office1, {x:0, y:0}, dimensions)

// Calculation:
x = 0 + (320 - 320) / 2 = 0
y = 0 - 256 = -256

// Aligned:
office1 at grid(0, -2) = world(0, -256)
```

**Step 3**: Process office1 → [office2, office3] (north)
```javascript
// Multiple north connections
positionNorthMultiple(office1, [office2, office3], {x:0, y:-256}, dimensions)

// Total width = 320 + 320 = 640px
// Current width = 320px
// Center offset = (320 - 640) / 2 = -160px
// Start X = 0 + (-160) = -160px

// office2:
x = -160, y = -256 - 256 = -512
aligned: office2 at grid(-1, -4) = world(-160, -512)

// office3:
x = -160 + 320 = 160, y = -512
aligned: office3 at grid(1, -4) = world(160, -512)
```

**Step 4**: Process office2 → ceo (north)
```javascript
// Single north connection
x = -160 + (320 - 320) / 2 = -160
y = -512 - 256 = -768

ceo at grid(-1, -6) = world(-160, -768)
```

**Step 5**: Process ceo → closet (north)
```javascript
// Single north connection
// closet is smaller: 160px wide
x = -160 + (320 - 160) / 2 = -160 + 80 = -80
y = -768 - 128 = -896

// Aligned to grid:
// -80 / 160 = -0.5 → rounds to 0
// Actually: Math.round(-80/160) * 160 = Math.round(-0.5) * 160 = 0 * 160 = 0
// OR: Math.round(-80/160) * 160 = round(-0.5) * 160 = -0 * 160 = 0

// ISSUE: JavaScript Math.round(-0.5) = -0 (which equals 0)
// But we need consistent rounding!

// Using Math.floor for negative division:
// gridX = Math.floor(-80 / 160) = Math.floor(-0.5) = -1
// worldX = -1 * 160 = -160

closet at grid(-1, -7) = world(-160, -896) ❓
// OR possibly grid(0, -7) = world(0, -896) depending on rounding
```

**⚠️ ISSUE 1: Rounding Ambiguity for Odd-Sized Rooms**
- When centering small room (1 grid unit) above large room (2 grid units)
- Offset = (320 - 160) / 2 = 80px
- Position = -160 + 80 = -80px
- **-80px is not grid-aligned!** (grid is 160px)
- Rounding behavior for -0.5 is ambiguous

### Phase 3: Door Placement Analysis

**Critical Case: office1 ↔ office2/office3**

#### office1's North Doors (to office2 and office3)
```javascript
// placeNorthDoorsMultiple called
roomPosition = {x: 0, y: -256}
roomWidth = 320px
connectedRooms = [office2, office3]

// Edge inset = 48px (1.5 tiles)
// Available width = 320 - 96 = 224px
// Door count = 2
// Spacing = 224 / (2-1) = 224px

// Door to office2:
doorX = 0 + 48 + (0 * 224) = 48px
doorY = -256 + 32 = -224px

// Door to office3:
doorX = 0 + 48 + (1 * 224) = 272px
doorY = -224px
```

#### office2's South Door (to office1)
```javascript
// placeSouthDoorSingle called
roomPosition = {x: -160, y: -512}
roomWidth = 320px
roomHeight = 320px
gridCoords = {x: -1, y: -4}

// Deterministic placement:
useRightSide = (-1 + -4) % 2 === 1
// -5 % 2 in JavaScript = -1 (NOT 1!)
// Actually: (-1 + -4) % 2 = -5 % 2 = -1
// So useRightSide = false (LEFT side)

// LEFT side:
doorX = -160 + 48 = -112px
doorY = -512 + 320 - 32 = -224px
```

**⚠️ ISSUE 2: Modulo with Negative Numbers**
- JavaScript: `-5 % 2 = -1` (not `1`)
- Expected: `useRightSide = (-1 + -4) % 2 === 1` → false
- Door placed on LEFT at -112px
- office1's first door is at 48px
- **MISMATCH: |-112 - 48| = 160px = 5 tiles!**

Even if we fix the modulo issue:
```javascript
// Fixed: use Math.abs or different formula
useRightSide = Math.abs((-1 + -4)) % 2 === 1 // = 5 % 2 = 1 → true

// RIGHT side:
doorX = -160 + 320 - 48 = 112px
doorY = -224px
```

**Still MISMATCH!**
- office1's first door: 48px
- office2's door: 112px
- **Delta: 64px = 2 tiles**

#### office3's South Door (to office1)
```javascript
// placeSouthDoorSingle called
roomPosition = {x: 160, y: -512}
gridCoords = {x: 1, y: -4}

// Deterministic: (1 + -4) % 2 = -3 % 2 = -1 (false → LEFT)
// With fix: abs(-3) % 2 = 3 % 2 = 1 (true → RIGHT)

// RIGHT side:
doorX = 160 + 320 - 48 = 432px
doorY = -224px
```

**MISMATCH AGAIN!**
- office1's second door: 272px
- office3's door: 432px
- **Delta: 160px = 5 tiles**

---

## Critical Issues Identified

### Issue 1: Negative Modulo Behavior ⚠️ CRITICAL
**Problem**: JavaScript's modulo operator returns negative results for negative operands
```javascript
-5 % 2 = -1  // NOT 1
-3 % 2 = -1  // NOT 1
```

**Impact**: Door placement alternation will be wrong for rooms with negative grid coordinates

**Solution**: Use proper modulo for alternation
```javascript
// WRONG:
const useRightSide = (gridX + gridY) % 2 === 1;

// CORRECT:
const useRightSide = ((gridX + gridY) % 2 + 2) % 2 === 1;
// OR:
const useRightSide = Math.abs(gridX + gridY) % 2 === 1;
```

**Status**: ❌ Not addressed in current plan

---

### Issue 2: Asymmetric Door Alignment Bug ⚠️ CRITICAL
**Problem**: Confirmed from review1 - doors don't align when:
- Room A has multiple connections in direction D
- Room B has single connection in opposite direction
- Both calculate doors independently using different logic

**Example**: office1 (2 north doors) ↔ office2 (1 south door)
- office1's first door: 48px
- office2's door: 112px (even with fixed modulo)
- **Misalignment: 64px**

**Root Cause**: Deterministic placement uses grid coordinates, but doesn't account for:
1. Which door index in the multi-door array
2. The actual position of the multi-door room
3. The offset created by centering logic

**Solution**: Implement the fix from review1/RECOMMENDATIONS.md
- When placing single door, check if connected room has multiple doors
- Calculate which door to align with
- Match the exact position from the multi-door calculation

**Status**: ✅ Identified in review1, ❌ Not yet integrated into DOOR_PLACEMENT.md

---

### Issue 3: Small Room Centering Misalignment ⚠️ HIGH
**Problem**: When centering odd-width room above even-width room
- closet (1 grid unit = 160px) above ceo (2 grid units = 320px)
- Centered position: -160 + 80 = -80px
- **Not grid-aligned!** (grid is 160px intervals)

**Impact**:
- Room validation will fail (position not aligned to grid)
- Potential visual artifacts
- Door alignment may be off

**Solutions**:
1. **Snap to grid** (current plan uses Math.round)
   - But: Math.round(-80/160) has ambiguous behavior
   - Recommendation: Use consistent rounding (always floor, or always up)

2. **Prevent odd/even mismatches** (validation)
   - Warn when centering creates misalignment
   - Suggest using even multiples of grid units

3. **Allow sub-grid alignment** (change plan)
   - Not recommended - increases complexity

**Recommended**: Snap to grid with consistent rounding
```javascript
// Explicit floor division for grid alignment
function alignToGrid(worldX, worldY) {
    const gridX = Math.floor(worldX / GRID_UNIT_WIDTH_PX);
    const gridY = Math.floor(worldY / GRID_UNIT_HEIGHT_PX);
    return {
        x: gridX * GRID_UNIT_WIDTH_PX,
        y: gridY * GRID_UNIT_HEIGHT_PX
    };
}
```

**Status**: ⚠️ Partially addressed (uses Math.round but not explicit about rounding direction)

---

### Issue 4: Room Dimension Assumptions ⚠️ HIGH
**Problem**: Plan assumes standard rooms are 10×10 tiles
- But review1 notes current standard rooms are 10×8 tiles
- Grid system expects heights of 6, 10, 14, 18... (formula: 2 + 4N)
- **10×8 doesn't match!** (should be 10×10 for 2×2 grid units)

**Impact**:
- Current room files may need updating
- Validation will fail on 10×8 rooms
- Height formula: 8 tiles = 2 + 6 tiles stacking
  - 6 tiles / 4 tiles per grid unit = 1.5 grid units ❌ (fractional!)

**Validation**:
```javascript
// For 10×8 room:
stackingHeight = 8 - 2 = 6 tiles
gridHeight = floor(6 / 4) = floor(1.5) = 1 grid unit

// But total height check:
expectedHeight = 2 + (1 × 4) = 6 tiles ≠ 8 tiles ❌
```

**Action Required**:
1. Audit ALL existing room JSON files
2. Update invalid heights (8 → 10, or 8 → 6)
3. Document migration plan

**Status**: ⚠️ Acknowledged in plan but no concrete migration steps

---

### Issue 5: Connection Reciprocity Not Guaranteed ⚠️ MEDIUM
**Problem**: Scenario might have non-reciprocal connections
- Room A → north → Room B
- Room B → south → Room C (not Room A)

**Current**: Will cause missing doors or one-way passages

**Solution**: Add validation to detect and report
```javascript
function validateConnectionReciprocity(scenario) {
    const errors = [];
    Object.entries(scenario.rooms).forEach(([roomId, room]) => {
        if (!room.connections) return;

        ['north', 'south', 'east', 'west'].forEach(dir => {
            const connected = room.connections[dir];
            if (!connected) return;

            const connectedList = Array.isArray(connected) ? connected : [connected];
            connectedList.forEach(targetId => {
                const targetRoom = scenario.rooms[targetId];
                const oppositeDir = getOppositeDirection(dir);
                const reciprocal = targetRoom?.connections?.[oppositeDir];

                if (!reciprocal) {
                    errors.push(`${roomId} → ${dir} → ${targetId}, but ${targetId} has no ${oppositeDir} connection`);
                } else {
                    const reciprocalList = Array.isArray(reciprocal) ? reciprocal : [reciprocal];
                    if (!reciprocalList.includes(roomId)) {
                        errors.push(`${roomId} → ${dir} → ${targetId}, but ${targetId} → ${oppositeDir} → ${reciprocalList.join(',')} (missing ${roomId})`);
                    }
                }
            });
        });
    });
    return errors;
}
```

**Status**: ✅ Partially addressed in VALIDATION.md but needs strengthening

---

### Issue 6: Grid Unit Height Validation Formula ⚠️ MEDIUM
**Problem**: GRID_SYSTEM.md states valid heights are 6, 10, 14, 18...
- Formula: `totalHeight = 2 + (N × 4)` where N ≥ 1

**But**: Validation function in review1/RECOMMENDATIONS.md checks:
```javascript
const stackingHeight = heightTiles - VISUAL_TOP_TILES;
const validHeight = (stackingHeight % GRID_UNIT_HEIGHT_TILES) === 0 && stackingHeight > 0;
```

**This allows**: 2, 6, 10, 14... (including 2!)
- heightTiles = 2: stacking = 0 tiles → fails `stackingHeight > 0` ✓
- heightTiles = 4: stacking = 2 tiles → 2 % 4 = 2 ≠ 0 → invalid ✓
- heightTiles = 6: stacking = 4 tiles → 4 % 4 = 0 → valid ✓
- heightTiles = 10: stacking = 8 tiles → 8 % 4 = 0 → valid ✓

**Actually correct!** But documentation could be clearer.

**Recommendation**: Add explicit examples to validation function
```javascript
// Valid heights: 6, 10, 14, 18, 22, 26...
// Invalid heights: 2, 3, 4, 5, 7, 8, 9, 11, 12, 13...
```

**Status**: ✓ Correct but needs clarification

---

### Issue 7: Door Placement Assumes Room Exists ⚠️ MEDIUM
**Problem**: Door placement code assumes connected room exists and is positioned

**Scenario**: Door calculation happens during positioning
- Connected room might not be positioned yet
- Can't calculate alignment for future rooms

**Current Plan**: Doors calculated AFTER all positioning (in validation)
- ✓ Good approach

**But**: createDoorSprites runs during room loading
- Needs access to all positions
- Must happen after positioning complete

**Recommendation**: Ensure clear separation of phases
1. Position all rooms
2. Calculate all doors
3. Create door sprites
4. Validate alignment

**Status**: ✓ Addressed in plan but needs emphasis

---

## Additional Findings

### Finding 1: Performance - Dimension Caching
**Current**: getRoomDimensions called multiple times per room
- During positioning
- During door calculation
- During validation

**Impact**: Minimal (tilemap access is fast)

**Recommendation**: Cache dimensions after first extraction
```javascript
const dimensionCache = new Map();
function getRoomDimensionsCached(roomId, roomData, gameInstance) {
    if (!dimensionCache.has(roomId)) {
        dimensionCache.set(roomId, getRoomDimensions(roomId, roomData, gameInstance));
    }
    return dimensionCache.get(roomId);
}
```

**Priority**: LOW (nice to have)

---

### Finding 2: Breadth-First Processing Order
**Current**: Rooms processed in queue order

**Question**: What if multiple rooms connect to same room from different directions?
```
    [R2]
     |
[R3][R1][R4]
     |
    [R0]
```
- R0 processes north → R1 (R1 positioned)
- R1 processes north → R2, east → R4, west → R3
- All positioned correctly ✓

**No issue found** - breadth-first handles this correctly

---

### Finding 3: Visual Overlap for Doors
**Question**: When room A is north of room B, top 2 tiles of room B overlap with room A's floor visually. Do doors account for this?

**Answer**: Yes - doors placed at stacking height boundaries, not visual boundaries
- Room A's south door: at bottom of stacking area
- Room B's north door: at top of stacking area
- Visual overlap (2 tiles) is separate from door placement ✓

**No issue found**

---

### Finding 4: East/West Door Spacing for Different Heights
**Scenario**: Tall room (14 tiles = 3 grid units) connects east to short room (6 tiles = 1 grid unit)
```
[Tall ] 14 tiles
[Room ][Short] 6 tiles
[     ]
```

**Question**: How are doors placed?

**Tall room's east door** (to short room):
```javascript
// placeEastDoorSingle called
doorY = tallRoomY + (TILE_SIZE * 2) = tallRoomY + 64px
```

**Short room's west door** (to tall room):
```javascript
// placeWestDoorSingle called
doorY = shortRoomY + (TILE_SIZE * 2) = shortRoomY + 64px
```

**Alignment check**:
- Rooms aligned at north edge (positionEastSingle uses currentPos.y)
- Both doors at Y + 64px
- ✓ Aligned!

**But**: What if we want multiple east doors on tall room?
- Currently: Only supports multiple doors if multiple connections
- Aesthetic issue: Tall room with one east door looks odd

**Recommendation**: Consider allowing multiple door positions even for single connection to tall rooms (future enhancement)

**Priority**: LOW (aesthetic only)

---

## Validation Against ceo_exfil.json

### Expected Room Positions (with fixes applied)

Assuming all rooms are updated to valid sizes and alignment issues fixed:

```
Room: reception at grid(0, 0) = world(0, 0)
Room: office1 at grid(0, -2) = world(0, -256)
Room: office2 at grid(-1, -4) = world(-160, -512)
Room: office3 at grid(1, -4) = world(160, -512)
Room: ceo at grid(-1, -6) = world(-160, -768)
Room: closet at grid(-1, -7) = world(-160, -896)  // OR grid(0, -7) depending on rounding
Room: server1 at grid(1, -6) = world(160, -768)
```

### Expected Doors (with asymmetric fix applied)

**reception ↔ office1**:
- reception north door: (48px or 272px, -224px) [deterministic based on grid(0,0)]
- office1 south door: matches reception's door ✓

**office1 ↔ office2**:
- office1 north door #1: (48px, -224px) [multi-door at index 0]
- office2 south door: **MUST ALIGN WITH office1's door #1**
  - Check: office1 has 2 north connections
  - Find index of office2 in array: index 0
  - Calculate door position to match office1's calculation
  - Result: (48px, -224px) ✓

**office1 ↔ office3**:
- office1 north door #2: (272px, -224px) [multi-door at index 1]
- office3 south door: **MUST ALIGN WITH office1's door #2**
  - Check: office1 has 2 north connections
  - Find index of office3 in array: index 1
  - Calculate to match: (272px, -224px) ✓

**office2 ↔ ceo**:
- Both single connections, deterministic placement ✓

**ceo ↔ closet**:
- Both single connections
- **ISSUE**: closet might not be grid-aligned (needs rounding fix)

**office3 ↔ server1**:
- Both single connections ✓

### Will It Work?

**Without fixes**: ❌ **NO**
- Issue 1 (negative modulo): Doors on wrong sides
- Issue 2 (asymmetric alignment): office1/office2/office3 doors misaligned by 64-160px
- Issue 3 (small room centering): closet position invalid

**With fixes applied**: ✅ **YES**
- Negative modulo fix: Doors on correct sides
- Asymmetric alignment fix: All doors align perfectly
- Rounding fix: closet aligns to grid (at -160 or 0, both valid)

---

## Recommendations

### Priority 1: CRITICAL FIXES (Must implement before ANY testing)

#### Fix 1.1: Negative Modulo for Door Placement
**File**: DOOR_PLACEMENT.md, doors.js

**Update all deterministic placement logic**:
```javascript
// BEFORE:
const useRightSide = (gridX + gridY) % 2 === 1;

// AFTER:
const sum = gridX + gridY;
const useRightSide = ((sum % 2) + 2) % 2 === 1;
// This handles negative numbers correctly
```

**Test cases**:
```javascript
// grid(0, 0): (0 % 2 + 2) % 2 = 0 → left
// grid(1, 0): (1 % 2 + 2) % 2 = 1 → right
// grid(-1, 0): ((-1 % 2) + 2) % 2 = (-1 + 2) % 2 = 1 → right
// grid(-1, -1): ((-2 % 2) + 2) % 2 = (0 + 2) % 2 = 0 → left
```

#### Fix 1.2: Asymmetric Door Alignment
**File**: Create new `js/systems/door-positioning.js`, update DOOR_PLACEMENT.md

**Implementation**: Use exact code from review1/RECOMMENDATIONS.md

**Key changes**:
1. Check if connected room has multiple connections in opposite direction
2. Find this room's index in that array
3. Calculate door position to match the multi-door spacing
4. Return exact aligned position

**Pseudo-code**:
```javascript
function placeNorthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords,
                              connectedRoom, allRooms, allPositions, allDimensions) {
    // Check if connected room has multiple south connections
    const connectedRoomData = allRooms[connectedRoom];
    const southConnections = connectedRoomData?.connections?.south;

    if (Array.isArray(southConnections) && southConnections.length > 1) {
        // Align with connected room's multi-door layout
        const myIndex = southConnections.indexOf(roomId);
        if (myIndex >= 0) {
            const connectedPos = allPositions[connectedRoom];
            const connectedDim = allDimensions[connectedRoom];

            // Calculate where connected room's doors are
            const edgeInset = TILE_SIZE * 1.5;
            const availableWidth = connectedDim.widthPx - (edgeInset * 2);
            const spacing = availableWidth / (southConnections.length - 1);

            const alignedDoorX = connectedPos.x + edgeInset + (spacing * myIndex);
            const doorY = roomPosition.y + TILE_SIZE;

            return { x: alignedDoorX, y: doorY };
        }
    }

    // Default: deterministic placement
    const sum = gridCoords.x + gridCoords.y;
    const useRightSide = ((sum % 2) + 2) % 2 === 1;

    let doorX;
    if (useRightSide) {
        doorX = roomPosition.x + roomDimensions.widthPx - (TILE_SIZE * 1.5);
    } else {
        doorX = roomPosition.x + (TILE_SIZE * 1.5);
    }

    const doorY = roomPosition.y + TILE_SIZE;
    return { x: doorX, y: doorY };
}
```

**Apply to all four directions**: north, south, east, west

#### Fix 1.3: Consistent Grid Alignment
**File**: POSITIONING_ALGORITHM.md, rooms.js

**Update alignToGrid function**:
```javascript
function alignToGrid(worldX, worldY) {
    // Use floor for consistent rounding of negative numbers
    const gridX = Math.floor(worldX / GRID_UNIT_WIDTH_PX);
    const gridY = Math.floor(worldY / GRID_UNIT_HEIGHT_PX);

    return {
        x: gridX * GRID_UNIT_WIDTH_PX,
        y: gridY * GRID_UNIT_HEIGHT_PX
    };
}
```

**Note**: This will always round towards negative infinity
- Good for consistency
- Keeps rooms in predictable positions
- Document this behavior

#### Fix 1.4: Room Dimension Audit
**Action**: Before implementation begins

1. Use glob to find all room files:
   ```bash
   find assets/tilemaps -name "room_*.json"
   ```

2. For each room, check dimensions:
   ```javascript
   const height = roomData.height;
   const valid = (height === 6 || (height - 2) % 4 === 0);
   ```

3. Update invalid rooms:
   - 10×8 → 10×10 (add 2 rows) OR 10×6 (remove 2 rows)
   - Document changes
   - Test visually

4. Create migration checklist

---

### Priority 2: HIGH PRIORITY (Should implement)

#### Rec 2.1: Shared Door Positioning Module
**Action**: Create `js/systems/door-positioning.js` as specified in review1

**Benefits**:
- Single source of truth
- Easier testing
- Guaranteed consistency between door sprites and wall removal

#### Rec 2.2: Enhanced Validation
**Action**: Expand VALIDATION.md

**Add**:
1. Connectivity validation (detect disconnected rooms)
2. Reciprocity validation (stronger checks)
3. Height formula validation with helpful error messages
4. Door alignment tolerance check (warn if > 1px delta)

#### Rec 2.3: Feature Flag for Gradual Rollout
**Action**: Add to IMPLEMENTATION_STEPS.md Phase 0

```javascript
// In constants.js
export const USE_NEW_ROOM_LAYOUT = true;

// In rooms.js
export function calculateRoomPositions(gameInstance) {
    if (USE_NEW_ROOM_LAYOUT) {
        return calculateRoomPositionsV2(gameInstance);
    } else {
        return calculateRoomPositionsLegacy(gameInstance);
    }
}
```

**Benefits**:
- Easy A/B testing
- Quick rollback if critical bug found
- Can enable per-scenario

#### Rec 2.4: Incremental Implementation Order
**Action**: Update IMPLEMENTATION_STEPS.md

**Recommend**:
1. Phase 0: Feature flag + constants
2. Phase 1: N/S positioning only (test with existing scenarios)
3. Phase 2: Door placement for N/S (test alignment)
4. Phase 3: E/W positioning (test with new scenarios)
5. Phase 4: Validation (test with broken scenarios)
6. Phase 5: Polish and optimize

**Rationale**: Earlier testing catches bugs sooner

---

### Priority 3: MEDIUM (Nice to have)

#### Rec 3.1: Dimension Caching
**Implementation**: Simple Map-based cache

#### Rec 3.2: Validation Report Class
**Implementation**: Structured errors/warnings/info

#### Rec 3.3: Debug Visualization Tools
**Implementation**: window.showRoomLayout(), window.checkScenario()

---

### Priority 4: LOW (Future enhancements)

#### Rec 4.1: Multiple Door Aesthetics
**Idea**: Allow multiple E/W doors on tall rooms even with single connection

#### Rec 4.2: Migration Guide
**Idea**: Document how to update scenarios

#### Rec 4.3: Stress Testing
**Idea**: Test with 50+ rooms

---

## Updated Implementation Steps

### Critical Path Changes

**Phase 0** (NEW): Pre-Implementation
- ✅ Audit all room JSON files for valid dimensions
- ✅ Update invalid room heights (document changes)
- ✅ Add feature flag USE_NEW_ROOM_LAYOUT
- ✅ Test feature flag toggle

**Phase 1**: Constants and Helpers
- Add negative modulo helper function
- Add explicit alignToGrid with floor()
- Test alignment function thoroughly

**Phase 2**: Room Positioning (N/S only first)
- Implement only north/south positioning
- Leave east/west as TODO
- Test with ceo_exfil.json
- Verify office1 positions correctly

**Phase 3**: Door Placement (N/S only, with asymmetric fix)
- Create door-positioning.js module
- Implement asymmetric alignment fix
- Test office1 ↔ office2/office3 alignment
- Verify doors align perfectly

**Phase 4**: Add E/W Support
- Implement east/west positioning
- Implement east/west door placement (with asymmetric fix)
- Test with new scenario

**Phase 5**: Validation
- Implement all validation functions
- Test with intentionally broken scenarios

**Phase 6**: Testing & Polish
- Test all existing scenarios
- Create comprehensive test scenarios
- Add debug tools
- Performance profiling

---

## Test Plan for ceo_exfil.json

### Pre-Implementation Tests
1. Document current room dimensions
2. Identify which rooms need updating
3. Update and visually test each room

### Post-Implementation Tests

**Test 1: Positioning**
- Load scenario
- Check `window.roomPositions`
- Verify:
  - reception at (0, 0) ✓
  - office1 north of reception ✓
  - office2 and office3 north of office1, side by side ✓
  - Positions are grid-aligned ✓
  - No overlaps ✓

**Test 2: Door Alignment**
- Check `window.scenarioValidation.doorAlignment`
- Verify:
  - office1's 2 north doors at (48, Y) and (272, Y) ✓
  - office2's south door at (48, Y) ✓
  - office3's south door at (272, Y) ✓
  - All other doors align ✓
  - Alignment delta < 1px for all doors ✓

**Test 3: Gameplay**
- Play through scenario
- Verify:
  - Can navigate from reception → office1 ✓
  - Can navigate from office1 → office2 ✓
  - Can navigate from office1 → office3 ✓
  - All doors function correctly ✓
  - No visual gaps or overlaps ✓
  - No stuck spots ✓

**Test 4: Validation Warnings**
- Check console output
- Verify:
  - No overlap warnings ✓
  - No alignment warnings ✓
  - No connectivity warnings ✓
  - All validations pass ✓

---

## Confidence Assessment

### Before Fixes
- **Positioning**: 60% confident (rounding issues)
- **Door Alignment**: 30% confident (asymmetric bug will manifest)
- **Overall Success**: 40%

### After Priority 1 Fixes
- **Positioning**: 95% confident
- **Door Alignment**: 95% confident
- **Overall Success**: 90%

### Remaining Risks
1. Unexpected room dimension issues (5% risk)
2. Edge cases in complex scenarios (5% risk)
3. Performance issues with large scenarios (<1% risk)

---

## Final Verdict

**Can this plan work?**
✅ **YES** - with the Priority 1 fixes applied

**Should implementation proceed?**
✅ **YES** - after fixing critical issues

**Required actions before implementation**:
1. ✅ Apply Fix 1.1 (negative modulo)
2. ✅ Apply Fix 1.2 (asymmetric door alignment)
3. ✅ Apply Fix 1.3 (consistent grid alignment)
4. ✅ Complete Fix 1.4 (room dimension audit)

**Time estimate with fixes**: 20-28 hours (add 2-4 hours for fixes)

**Success probability**: 90% (up from 40% without fixes)

---

## Conclusion

This review has validated the core approach while identifying **3 critical bugs** that would have caused the implementation to fail. The good news: all bugs are well-understood and have clear solutions.

The plan is **sound** and **comprehensive** - it just needs the identified fixes integrated before implementation begins.

**Recommendation**:
1. Update planning documents with fixes
2. Complete room dimension audit
3. Proceed with implementation following updated plan
4. Test incrementally (especially the asymmetric door case)

With these changes, high confidence in success.
