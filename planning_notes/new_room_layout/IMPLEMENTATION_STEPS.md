# Implementation Steps

## Phase 0: Setup and Feature Flags

### Step 0.1: Add Feature Flags

**File**: `js/utils/constants.js`

Add feature flags for gradual migration:

```javascript
// Feature flags for room layout system migration
export const USE_NEW_ROOM_LAYOUT = true;       // Master flag: enable new positioning system
export const USE_NEW_DOOR_ALIGNMENT = true;    // Use array-index-based door alignment
export const USE_GRID_UNITS = true;            // Use grid unit abstraction

// Note: Set all to false to use legacy (current) implementation
// Set individually to test each component separately
```

**Testing**:
- Set all flags to `false` - verify game works with current implementation
- Set `USE_NEW_ROOM_LAYOUT = true`, others `false` - verify graceful fallback
- Toggle flags individually and test scenarios

**Commit**: `feat: Add feature flags for room layout system migration`

---

### Step 0.2: Document Current Room Dimensions

**File**: Create `planning_notes/current_room_audit.md` (documentation only)

```markdown
# Current Room Dimension Audit

Located in `assets/rooms/`:

| File | Width | Height | Notes |
|------|-------|--------|-------|
| room_office.json | ? | 5 | Non-standard height |
| room_office2.json | ? | 10 | Standard height |
| room_closet.json | 10 | 9 | Non-standard height |
| room_closet2.json | ? | 10 | Standard height |
| room_ceo.json | ? | 11 | Non-standard height |
| room_ceo2.json | ? | 10 | Standard height |
| room_reception.json | ? | 9 | Non-standard height |
| room_reception2.json | ? | 10 | Standard height |
| room_servers.json | ? | 9 | Non-standard height |
| room_servers2.json | ? | 10 | Standard height |

**Note**: All heights are valid with relaxed formula (totalHeight = 2 + stackingHeight, stackingHeight ≥ 4).
Heights 6, 10, 14, 18... recommended for perfect grid alignment.
Heights 5, 7, 8, 9, 11... work but create partial grid units (handled with Math.floor()).
```

**Action**: Fill in missing widths by checking each file

**No commit needed** (documentation only)

---

## Phase 1: Constants and Helper Functions

### Step 1.1: Add Grid Unit Constants

**File**: `js/utils/constants.js`

Add new constants for grid units:

```javascript
// Existing constants
export const TILE_SIZE = 32;
export const DOOR_ALIGN_OVERLAP = 64;

// NEW: Grid unit system constants
export const GRID_UNIT_WIDTH_TILES = 5;    // 5 tiles wide
export const GRID_UNIT_HEIGHT_TILES = 4;   // 4 tiles tall (stacking area)
export const VISUAL_TOP_TILES = 2;         // Top 2 rows are visual wall

// Calculated grid unit sizes in pixels
export const GRID_UNIT_WIDTH_PX = GRID_UNIT_WIDTH_TILES * TILE_SIZE;    // 160px
export const GRID_UNIT_HEIGHT_PX = GRID_UNIT_HEIGHT_TILES * TILE_SIZE;  // 128px
```

**Testing**: Verify constants are exported and accessible

---

### Step 1.2: Create Grid Conversion Functions

**File**: `js/core/rooms.js` (add near top, before calculateRoomPositions)

```javascript
/**
 * Convert tile dimensions to grid units
 *
 * Grid units are the base stacking size: 5 tiles wide × 4 tiles tall
 * (excluding top 2 visual wall tiles)
 *
 * @param {number} widthTiles - Room width in tiles
 * @param {number} heightTiles - Room height in tiles (including visual wall)
 * @returns {{gridWidth: number, gridHeight: number}}
 */
function tilesToGridUnits(widthTiles, heightTiles) {
    const gridWidth = Math.floor(widthTiles / GRID_UNIT_WIDTH_TILES);

    // Subtract visual top wall tiles before calculating grid height
    const stackingHeightTiles = heightTiles - VISUAL_TOP_TILES;
    const gridHeight = Math.floor(stackingHeightTiles / GRID_UNIT_HEIGHT_TILES);

    return { gridWidth, gridHeight };
}

/**
 * Convert grid coordinates to world position
 *
 * Grid coordinates are positions in grid unit space.
 * This converts them to pixel world coordinates.
 *
 * @param {number} gridX - Grid X coordinate
 * @param {number} gridY - Grid Y coordinate
 * @returns {{x: number, y: number}}
 */
function gridToWorld(gridX, gridY) {
    return {
        x: gridX * GRID_UNIT_WIDTH_PX,
        y: gridY * GRID_UNIT_HEIGHT_PX
    };
}

/**
 * Convert world position to grid coordinates
 *
 * @param {number} worldX - World X position in pixels
 * @param {number} worldY - World Y position in pixels
 * @returns {{gridX: number, gridY: number}}
 */
function worldToGrid(worldX, worldY) {
    return {
        gridX: Math.floor(worldX / GRID_UNIT_WIDTH_PX),
        gridY: Math.floor(worldY / GRID_UNIT_HEIGHT_PX)
    };
}

/**
 * Align a world position to the nearest grid boundary
 *
 * Ensures rooms are positioned at grid unit boundaries
 *
 * @param {number} worldX - World X position
 * @param {number} worldY - World Y position
 * @returns {{x: number, y: number}}
 */
function alignToGrid(worldX, worldY) {
    return {
        x: Math.round(worldX / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
        y: Math.round(worldY / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
    };
}
```

**Testing**: Create unit tests for conversion functions

---

### Step 1.3: Create Room Dimension Extraction Function

**File**: `js/core/rooms.js` (add before calculateRoomPositions)

```javascript
/**
 * Extract room dimensions from Tiled JSON data
 *
 * Reads the tilemap to get room size and calculates:
 * - Tile dimensions
 * - Pixel dimensions
 * - Grid units
 * - Stacking height (for positioning calculations)
 *
 * @param {string} roomId - Room identifier
 * @param {Object} roomData - Room data from scenario
 * @param {Phaser.Game} gameInstance - Game instance for accessing tilemaps
 * @returns {Object} Dimension data
 */
function getRoomDimensions(roomId, roomData, gameInstance) {
    const map = gameInstance.cache.tilemap.get(roomData.type);

    let widthTiles, heightTiles;

    // Try different ways to access tilemap data
    if (map.json) {
        widthTiles = map.json.width;
        heightTiles = map.json.height;
    } else if (map.data) {
        widthTiles = map.data.width;
        heightTiles = map.data.height;
    } else {
        // Fallback to standard room size
        console.warn(`Could not read dimensions for ${roomId}, using default 10×8`);
        widthTiles = 10;
        heightTiles = 8;
    }

    // Calculate grid units
    const { gridWidth, gridHeight } = tilesToGridUnits(widthTiles, heightTiles);

    // Calculate pixel dimensions
    const widthPx = widthTiles * TILE_SIZE;
    const heightPx = heightTiles * TILE_SIZE;
    const stackingHeightPx = (heightTiles - VISUAL_TOP_TILES) * TILE_SIZE;

    return {
        widthTiles,
        heightTiles,
        widthPx,
        heightPx,
        stackingHeightPx,
        gridWidth,
        gridHeight
    };
}
```

**Testing**: Verify dimensions extracted correctly for test room

---

## Phase 2: Room Positioning Algorithm

### Step 2.1: Create Single Room Positioning Functions

**File**: `js/core/rooms.js` (add before calculateRoomPositions)

Implement these functions as described in POSITIONING_ALGORITHM.md:

```javascript
function positionNorthSingle(currentRoom, connectedRoom, currentPos, dimensions) { /* ... */ }
function positionSouthSingle(currentRoom, connectedRoom, currentPos, dimensions) { /* ... */ }
function positionEastSingle(currentRoom, connectedRoom, currentPos, dimensions) { /* ... */ }
function positionWestSingle(currentRoom, connectedRoom, currentPos, dimensions) { /* ... */ }
```

**Reference**: See POSITIONING_ALGORITHM.md for complete implementations

**Testing**:
- Test each direction individually
- Verify grid alignment
- Verify centering logic

---

### Step 2.2: Create Multiple Room Positioning Functions

**File**: `js/core/rooms.js`

```javascript
function positionNorthMultiple(currentRoom, connectedRooms, currentPos, dimensions) { /* ... */ }
function positionSouthMultiple(currentRoom, connectedRooms, currentPos, dimensions) { /* ... */ }
function positionEastMultiple(currentRoom, connectedRooms, currentPos, dimensions) { /* ... */ }
function positionWestMultiple(currentRoom, connectedRooms, currentPos, dimensions) { /* ... */ }
```

**Reference**: See POSITIONING_ALGORITHM.md

**Testing**:
- Test with 2 rooms
- Test with 3+ rooms
- Verify even spacing

---

### Step 2.3: Create Router Functions

**File**: `js/core/rooms.js`

```javascript
function positionSingleRoom(direction, currentRoom, connectedRoom, currentPos, dimensions) {
    switch (direction) {
        case 'north': return positionNorthSingle(currentRoom, connectedRoom, currentPos, dimensions);
        case 'south': return positionSouthSingle(currentRoom, connectedRoom, currentPos, dimensions);
        case 'east': return positionEastSingle(currentRoom, connectedRoom, currentPos, dimensions);
        case 'west': return positionWestSingle(currentRoom, connectedRoom, currentPos, dimensions);
        default:
            console.error(`Unknown direction: ${direction}`);
            return currentPos;
    }
}

function positionMultipleRooms(direction, currentRoom, connectedRooms, currentPos, dimensions) {
    switch (direction) {
        case 'north': return positionNorthMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        case 'south': return positionSouthMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        case 'east': return positionEastMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        case 'west': return positionWestMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        default:
            console.error(`Unknown direction: ${direction}`);
            return {};
    }
}
```

**Testing**: Verify routing works for all directions

---

### Step 2.4: Rewrite calculateRoomPositions Function

**File**: `js/core/rooms.js` (lines 644-786)

**Current function**: Replace the entire function with new algorithm

**New implementation**: See POSITIONING_ALGORITHM.md for complete algorithm

**Key changes**:
1. Extract all room dimensions first
2. Support all 4 directions (north, south, east, west)
3. Use breadth-first processing
4. Call new positioning functions
5. Align all positions to grid

**Testing**:
- Test with existing scenarios
- Verify starting room at (0, 0)
- Verify breadth-first ordering
- Verify all rooms positioned

---

## Phase 3: Door Placement

### Step 3.1: Create Door Placement Functions

**File**: `js/systems/doors.js` (add before createDoorSpritesForRoom)

Implement door placement functions as described in DOOR_PLACEMENT.md:

```javascript
function placeNorthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords) { /* ... */ }
function placeNorthDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms) { /* ... */ }
function placeSouthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords) { /* ... */ }
function placeSouthDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms) { /* ... */ }
function placeEastDoorSingle(roomId, roomPosition, roomDimensions) { /* ... */ }
function placeEastDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms) { /* ... */ }
function placeWestDoorSingle(roomId, roomPosition, roomDimensions) { /* ... */ }
function placeWestDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms) { /* ... */ }
```

**Reference**: See DOOR_PLACEMENT.md for complete implementations

**Testing**:
- Test each direction
- Test single vs multiple doors
- Verify deterministic placement

---

### Step 3.2: Update createDoorSpritesForRoom Function

**File**: `js/systems/doors.js` (lines 47-308)

**Current**: Has hardcoded door positioning logic

**Changes**:
1. Get room dimensions using `getRoomDimensions()`
2. Calculate grid coordinates using `worldToGrid()`
3. For each connection direction:
   - Determine single vs multiple connections
   - Call appropriate door placement function
   - Create door sprite at returned position
4. Remove old positioning logic (lines 86-187)

**Testing**:
- Verify doors created at correct positions
- Verify door sprites have correct properties
- Verify collision zones work

---

### Step 3.3: Update removeTilesUnderDoor Function

**File**: `js/systems/collision.js` (lines 154-335)

**Current**: Duplicates door positioning logic

**Changes**:
1. Import door placement functions from doors.js
2. Use same door positioning functions as door sprites
3. Remove duplicate positioning logic (lines 197-283)
4. Ensure door position calculation matches exactly

**Alternative**: Create shared `calculateDoorPositions()` function used by both systems

**Testing**:
- Verify wall tiles removed at correct locations
- Verify removed tiles match door sprite positions
- No visual gaps or overlaps

---

## Phase 4: Validation

### Step 4.1: Create Validation Functions

**File**: `js/core/rooms.js` or new file `js/core/validation.js`

Implement validation functions from VALIDATION.md:

```javascript
function validateRoomSize(roomId, dimensions) { /* ... */ }
function validateGridAlignment(roomId, position) { /* ... */ }
function detectRoomOverlaps(positions, dimensions) { /* ... */ }
function validateConnections(gameScenario) { /* ... */ }
function validateDoorAlignment(allDoors) { /* ... */ }
function validateStartingRoom(gameScenario) { /* ... */ }
function validateScenario(gameScenario, positions, dimensions, allDoors) { /* ... */ }
```

**Reference**: See VALIDATION.md

**Testing**: Create test scenarios with known errors

---

### Step 4.2: Integrate Validation into initializeRooms

**File**: `js/core/rooms.js` (function initializeRooms, lines 548-576)

**Add after** `calculateRoomPositions()`:

```javascript
export function initializeRooms(gameInstance) {
    // ... existing code ...

    // Calculate room positions for lazy loading
    window.roomPositions = calculateRoomPositions(gameInstance);
    console.log('Room positions calculated for lazy loading');

    // NEW: Extract dimensions for validation
    const dimensions = {};
    Object.entries(gameScenario.rooms).forEach(([roomId, roomData]) => {
        dimensions[roomId] = getRoomDimensions(roomId, roomData, gameInstance);
    });

    // NEW: Calculate all door positions (for validation)
    const allDoors = [];
    Object.entries(gameScenario.rooms).forEach(([roomId, roomData]) => {
        if (roomData.connections) {
            const doors = calculateDoorPositionsForRoom(
                roomId,
                window.roomPositions[roomId],
                dimensions[roomId],
                roomData.connections,
                window.roomPositions,
                dimensions
            );
            allDoors.push(...doors);
        }
    });

    // NEW: Validate scenario
    const validationResults = validateScenario(
        gameScenario,
        window.roomPositions,
        dimensions,
        allDoors
    );

    // Store validation results for debugging
    window.scenarioValidation = validationResults;

    // Continue initialization even if validation fails
    // (log errors but attempt to continue per requirements)

    // ... rest of existing code ...
}
```

**Testing**: Verify validation runs on scenario load

---

## Phase 5: Testing and Refinement

### Step 5.1: Test with Existing Scenarios

Test each existing scenario:

1. `scenario1.json` (biometric_breach)
2. `cybok_heist.json`
3. `scenario2.json`
4. `ceo_exfil.json`

**Verify**:
- All rooms positioned correctly
- No overlaps
- All doors align
- Player can navigate between rooms
- No visual gaps or clipping

---

### Step 5.2: Create Test Scenarios

Create new test scenarios to verify features:

**Test 1: Different Room Sizes**
```json
{
  "startRoom": "small",
  "rooms": {
    "small": {
      "type": "room_closet",   // 5×6 tiles
      "connections": { "north": "medium" }
    },
    "medium": {
      "type": "room_office",   // 10×8 tiles
      "connections": { "north": "large", "south": "small" }
    },
    "large": {
      "type": "room_wide_hall", // 20×6 tiles (hypothetical)
      "connections": { "south": "medium" }
    }
  }
}
```

**Test 2: East/West Connections**
```json
{
  "startRoom": "center",
  "rooms": {
    "center": {
      "type": "room_office",
      "connections": {
        "east": "east_room",
        "west": "west_room"
      }
    },
    "east_room": {
      "type": "room_office",
      "connections": { "west": "center" }
    },
    "west_room": {
      "type": "room_office",
      "connections": { "east": "center" }
    }
  }
}
```

**Test 3: Multiple Connections**
```json
{
  "startRoom": "base",
  "rooms": {
    "base": {
      "type": "room_office",
      "connections": {
        "north": ["north1", "north2", "north3"]
      }
    },
    "north1": {
      "type": "room_office",
      "connections": { "south": "base" }
    },
    "north2": {
      "type": "room_office",
      "connections": { "south": "base" }
    },
    "north3": {
      "type": "room_office",
      "connections": { "south": "base" }
    }
  }
}
```

**Test 4: Complex Layout**
```json
{
  "startRoom": "reception",
  "rooms": {
    "reception": {
      "type": "room_reception",
      "connections": { "north": "hallway" }
    },
    "hallway": {
      "type": "room_wide_hall",
      "connections": {
        "north": ["office1", "office2"],
        "south": "reception"
      }
    },
    "office1": {
      "type": "room_office",
      "connections": {
        "south": "hallway",
        "east": "office2"
      }
    },
    "office2": {
      "type": "room_office",
      "connections": {
        "south": "hallway",
        "west": "office1"
      }
    }
  }
}
```

---

### Step 5.3: Debug and Fix Issues

**Common issues to watch for**:

1. **Floating point errors**: Door positions off by 1-2px
   - Fix: Use `Math.round()` for all position calculations

2. **Grid misalignment**: Rooms not aligned to grid boundaries
   - Fix: Use `alignToGrid()` function

3. **Door misalignment**: Doors don't line up between rooms
   - Fix: Ensure both rooms use same calculation logic

4. **Visual gaps**: Rooms don't touch properly
   - Fix: Check stacking height calculations

5. **Overlap false positives**: Validation reports overlaps that don't exist
   - Fix: Check overlap detection logic uses stacking height

---

## Phase 6: Documentation and Cleanup

### Step 6.1: Add Code Comments

Add detailed comments to new functions explaining:
- Purpose of function
- How grid units work
- Why certain calculations are done
- Edge cases handled

**Follow the style**: See existing comments in rooms.js for reference

---

### Step 6.2: Update Console Logging

Add helpful debug logging:

```javascript
// Grid unit conversion
console.log(`Room ${roomId}: ${widthTiles}×${heightTiles} tiles = ${gridWidth}×${gridHeight} grid units`);

// Room positioning
console.log(`Positioned ${roomId} at grid(${gridX}, ${gridY}) = world(${worldX}, ${worldY})`);

// Door placement
console.log(`Door at (${doorX}, ${doorY}) for ${roomId} → ${connectedRoom} (${direction})`);

// Validation
console.log(`✅ All ${doorCount} doors aligned correctly`);
console.log(`❌ Overlap detected: ${room1} and ${room2}`);
```

---

### Step 6.3: Create Debug Tools

Add console commands for debugging:

```javascript
// Show room bounds
window.showRoomBounds = function() { /* visualize room stacking areas */ };

// Show grid
window.showGrid = function() { /* draw grid unit overlay */ };

// Check scenario
window.checkScenario = function() { /* print validation results */ };

// List rooms
window.listRooms = function() { /* print all room positions and sizes */ };
```

---

## Implementation Checklist

Use this checklist to track progress:

- [ ] Phase 1: Constants and Helpers
  - [ ] Add grid unit constants
  - [ ] Create grid conversion functions
  - [ ] Create room dimension extraction
  - [ ] Test helper functions

- [ ] Phase 2: Room Positioning
  - [ ] Implement single room positioning (4 directions)
  - [ ] Implement multiple room positioning (4 directions)
  - [ ] Create router functions
  - [ ] Rewrite calculateRoomPositions
  - [ ] Test with existing scenarios

- [ ] Phase 3: Door Placement
  - [ ] Implement door placement functions
  - [ ] Update createDoorSpritesForRoom
  - [ ] Update removeTilesUnderDoor
  - [ ] Test door alignment

- [ ] Phase 4: Validation
  - [ ] Create validation functions
  - [ ] Integrate into initializeRooms
  - [ ] Test validation with error scenarios

- [ ] Phase 5: Testing
  - [ ] Test all existing scenarios
  - [ ] Create and test new scenarios
  - [ ] Debug and fix issues

- [ ] Phase 6: Documentation
  - [ ] Add code comments
  - [ ] Update console logging
  - [ ] Create debug tools
  - [ ] Update user-facing documentation

---

## Estimated Time

- Phase 1: 2-3 hours
- Phase 2: 4-6 hours
- Phase 3: 3-4 hours
- Phase 4: 2-3 hours
- Phase 5: 4-6 hours
- Phase 6: 2-3 hours

**Total**: 17-25 hours of implementation time

---

## Risk Mitigation

### Backup Current Code

Before starting, create backup:
```bash
git checkout -b backup/before-room-layout-refactor
git commit -am "Backup before room layout refactor"
git checkout claude/review-room-layout-system-01Tk2U5qUChpAemwRVNFDR7t
```

### Incremental Implementation

Implement and test each phase before moving to next:
1. Complete Phase 1 → Test → Commit
2. Complete Phase 2 → Test → Commit
3. etc.

### Keep Old Code Available

Comment out old code instead of deleting initially:
```javascript
// OLD IMPLEMENTATION - Remove after testing
// function oldCalculateRoomPositions() { ... }

// NEW IMPLEMENTATION
function calculateRoomPositions() { ... }
```

This allows easy comparison if issues arise.
