# Grid Unit System

## Definition

The **grid unit** is the fundamental building block for room sizing and positioning.

### Base Grid Unit
- **Width**: 5 tiles = 160px
- **Height**: 4 tiles = 128px (stacking height, excludes top 2 visual wall tiles)
- **Total Height**: 6 tiles = 192px (including top 2 visual wall tiles)

## Room Size Specification

### In Tiled
Rooms are created in Tiled using standard 32px tiles:
- Total room dimensions include all tiles (walls + floor + visual top)
- Example: Standard room is 10 tiles wide × 8 tiles tall

### In Code
Rooms are tracked using grid units for positioning:
- **Grid Width**: `Math.floor(tileWidth / 5)`
- **Grid Height**: `Math.floor((tileHeight - 2) / 4)` (excludes visual top)
- Example: Standard room (10×8 tiles) = 2×1.5 grid units
  - But for alignment, we treat as 2×2 grid units (10 tiles wide × (2 + 4 + 2) tiles tall)

### Calculation Formula

```javascript
const TILE_SIZE = 32; // pixels
const GRID_UNIT_WIDTH_TILES = 5;
const GRID_UNIT_HEIGHT_TILES = 4; // stackable area only
const VISUAL_TOP_TILES = 2;

// Convert tile dimensions to grid units
function tilesToGridUnits(tileWidth, tileHeight) {
    const gridWidth = Math.floor(tileWidth / GRID_UNIT_WIDTH_TILES);
    const stackingHeight = tileHeight - VISUAL_TOP_TILES;
    const gridHeight = Math.floor(stackingHeight / GRID_UNIT_HEIGHT_TILES);

    return { gridWidth, gridHeight };
}

// Convert grid units to pixel dimensions
function gridUnitsToPixels(gridWidth, gridHeight) {
    const pixelWidth = gridWidth * GRID_UNIT_WIDTH_TILES * TILE_SIZE;
    const stackingHeight = gridHeight * GRID_UNIT_HEIGHT_TILES * TILE_SIZE;
    const totalHeight = stackingHeight + (VISUAL_TOP_TILES * TILE_SIZE);

    return {
        width: pixelWidth,
        height: totalHeight,
        stackingHeight: stackingHeight
    };
}
```

## Valid Room Sizes

All rooms must be exact multiples of grid units in both dimensions.

### Standard Sizes

**IMPORTANT**: Total room height must equal: `2 + (gridHeight × 4)` tiles
- 2 tiles for visual top wall
- gridHeight × 4 tiles for stackable area

**Valid Heights**: 6, 10, 14, 18, 22, 26... (formula: 2 + 4N where N ≥ 1)

| Room Type | Tiles (W×H) | Grid Units | Pixels (W×H) | Formula Check |
|-----------|-------------|------------|--------------|---------------|
| Closet | 5×6 | 1×1 | 160×192 | 2 + (1×4) = 6 ✓ |
| Standard | 10×10 | 2×2 | 320×320 | 2 + (2×4) = 10 ✓ |
| Wide Hall | 20×6 | 4×1 | 640×192 | 2 + (1×4) = 6 ✓ |
| Tall Hall | 10×6 | 2×1 | 320×192 | 2 + (1×4) = 6 ✓ |
| Tall Room | 10×14 | 2×3 | 320×448 | 2 + (3×4) = 14 ✓ |
| Large Room | 15×10 | 3×2 | 480×320 | 2 + (2×4) = 10 ✓ |

### Important Notes

1. **Total Height Calculation**:
   - Grid units count stackable area only (4 tiles per grid unit)
   - Add 2 tiles for visual top wall
   - **Formula**: totalHeight = 2 + (gridHeight × 4)
   - **Valid heights ONLY**: 6, 10, 14, 18, 22, 26... (increments of 4 after initial 2)

2. **Minimum Floor Space**:
   - After removing walls (1 tile each side)
   - Minimum: 3 tiles wide × 2 tiles tall
   - Closet (5×6): 3×2 floor area

3. **Door Space**:
   - North/South doors: 1 tile wide, need 1.5 tile inset
   - East/West doors: 1 tile tall, placed at edges
   - Minimum width: 5 tiles (supports 1 door per side)
   - Multiple E/W doors: minimum 8 tiles height recommended

4. **Invalid Room Sizes**:
   - Width not multiple of 5: ❌ Invalid
   - Height not matching formula: ❌ Invalid (e.g., 8, 9, 11, 12, 13 are all invalid)
   - Height less than 6: ❌ Too small

## Grid Coordinate System

### Purpose
Used for deterministic door placement and overlap detection.

### Coordinates

```
Grid Origin (0, 0) = Starting Room Top-Left

    -2  -1   0   1   2   3   (grid X)
-2  [ ][ ][  ][  ][  ][  ]
-1  [ ][ ][  ][  ][  ][  ]
 0  [ ][ ][R0][R0][  ][  ]  <- Starting room at (0,0), size 2×2
 1  [ ][ ][R0][R0][  ][  ]
 2  [ ][ ][  ][  ][  ][  ]
 3  [ ][ ][  ][  ][  ][  ]

(grid Y)
```

### Conversion

```javascript
// World position to grid coordinates
function worldToGrid(worldX, worldY) {
    const gridX = Math.floor(worldX / (GRID_UNIT_WIDTH_TILES * TILE_SIZE));
    const gridY = Math.floor(worldY / (GRID_UNIT_HEIGHT_TILES * TILE_SIZE));
    return { gridX, gridY };
}

// Grid coordinates to world position
function gridToWorld(gridX, gridY) {
    const worldX = gridX * GRID_UNIT_WIDTH_TILES * TILE_SIZE;
    const worldY = gridY * GRID_UNIT_HEIGHT_TILES * TILE_SIZE;
    return { worldX, worldY };
}
```

## Overlap Detection

### Algorithm

```javascript
function checkRoomOverlap(room1, room2) {
    // Get grid positions and sizes
    const r1 = {
        gridX: room1.gridX,
        gridY: room1.gridY,
        gridWidth: room1.gridWidth,
        gridHeight: room1.gridHeight
    };

    const r2 = {
        gridX: room2.gridX,
        gridY: room2.gridY,
        gridWidth: room2.gridWidth,
        gridHeight: room2.gridHeight
    };

    // Check for overlap using AABB (Axis-Aligned Bounding Box)
    const noOverlap = (
        r1.gridX + r1.gridWidth <= r2.gridX ||  // r1 is left of r2
        r2.gridX + r2.gridWidth <= r1.gridX ||  // r2 is left of r1
        r1.gridY + r1.gridHeight <= r2.gridY || // r1 is above r2
        r2.gridY + r2.gridHeight <= r1.gridY    // r2 is above r1
    );

    return !noOverlap;
}
```

### Usage
- Check all room pairs after positioning
- Log errors for any overlaps found
- Continue loading despite overlaps (for debugging)

## Alignment Requirements

### CRITICAL: Grid Alignment Rounding

**Important**: All positioning code must use `Math.floor()` for grid alignment, NOT `Math.round()`.

**Reason**: JavaScript's `Math.round()` has ambiguous behavior with negative 0.5:
- `Math.round(-0.5)` could be `-0` or `-1` (implementation-dependent)
- `Math.floor(-0.5)` is always `-1` (consistent)

**Correct Implementation**:
```javascript
function alignToGrid(worldX, worldY) {
    const gridX = Math.floor(worldX / GRID_UNIT_WIDTH_PX);
    const gridY = Math.floor(worldY / GRID_UNIT_HEIGHT_PX);
    return {
        x: gridX * GRID_UNIT_WIDTH_PX,
        y: gridY * GRID_UNIT_HEIGHT_PX
    };
}
```

**Examples**:
```javascript
// Positive coordinates
alignToGrid(80, 0) → (0, 0)  // rounds down
alignToGrid(160, 128) → (160, 128)  // exact

// Negative coordinates
alignToGrid(-80, -256) → (-160, -256)  // rounds toward -infinity
alignToGrid(0, -64) → (0, -128)  // rounds toward -infinity
```

### Room Positions
All room positions must align to grid boundaries:

```javascript
function validateRoomAlignment(worldX, worldY) {
    const gridUnitWidthPx = GRID_UNIT_WIDTH_TILES * TILE_SIZE;
    const gridUnitHeightPx = GRID_UNIT_HEIGHT_TILES * TILE_SIZE;

    const alignedX = (worldX % gridUnitWidthPx) === 0;
    const alignedY = (worldY % gridUnitHeightPx) === 0;

    if (!alignedX || !alignedY) {
        console.error(`Room not aligned to grid: (${worldX}, ${worldY})`);
        console.error(`Expected multiples of (${gridUnitWidthPx}, ${gridUnitHeightPx})`);
    }

    return alignedX && alignedY;
}
```

### Door Alignment
Doors between rooms must align perfectly:
- Both rooms calculate door position independently
- Positions must match exactly (within 1px tolerance for floating point)
- Misalignment indicates positioning error

## Migration Notes

### Existing Rooms
Current standard rooms (320×320px) are 10×10 tiles:
- **New interpretation**: 2×2 grid units with extra tiles
- **Actual size needed**: 10×8 tiles (2×2 grid units)
- **Action**: Update room JSONs to 10×8 tiles

### Backward Compatibility
The system should gracefully handle non-aligned rooms:
- Calculate nearest grid position
- Log warning about alignment
- Continue with nearest valid position
- **Note**: Not needed per requirements, but good for debugging

## Testing

### Unit Tests
```javascript
// Test grid unit calculations
assert(tilesToGridUnits(5, 6) === {gridWidth: 1, gridHeight: 1});
assert(tilesToGridUnits(10, 8) === {gridWidth: 2, gridHeight: 1.5}); // rounds to 2×2
assert(tilesToGridUnits(20, 6) === {gridWidth: 4, gridHeight: 1});

// Test grid alignment
assert(validateRoomAlignment(0, 0) === true);
assert(validateRoomAlignment(160, 128) === true);
assert(validateRoomAlignment(100, 100) === false);
```

### Integration Tests
- Create scenario with various room sizes
- Verify all rooms align to grid
- Verify no overlaps
- Verify door alignment
