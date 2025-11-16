# Room Positioning Algorithm

## Overview

The positioning algorithm works outward from the starting room, processing rooms level-by-level in a breadth-first manner. This ensures deterministic positioning regardless of scenario structure.

## High-Level Flow

```
1. Extract room dimensions from Tiled JSON
2. Place starting room at origin (0, 0)
3. Initialize queue with starting room
4. While queue not empty:
   a. Pop current room from queue
   b. For each connection direction (north, south, east, west):
      - Calculate positions for connected rooms
      - Add newly positioned rooms to queue
5. Validate all positions (check for overlaps)
6. Return position map
```

## Room Dimension Extraction

### From Tiled JSON

```javascript
function getRoomDimensions(roomId, roomData, gameInstance) {
    const map = gameInstance.cache.tilemap.get(roomData.type);

    let widthTiles, heightTiles;
    if (map.json) {
        widthTiles = map.json.width;
        heightTiles = map.json.height;
    } else if (map.data) {
        widthTiles = map.data.width;
        heightTiles = map.data.height;
    } else {
        // Fallback to standard size
        console.warn(`Could not read dimensions for ${roomId}, using default`);
        widthTiles = 10;
        heightTiles = 8;
    }

    // Calculate grid units
    const gridWidth = Math.floor(widthTiles / GRID_UNIT_WIDTH_TILES);
    const stackingHeightTiles = heightTiles - VISUAL_TOP_TILES;
    const gridHeight = Math.floor(stackingHeightTiles / GRID_UNIT_HEIGHT_TILES);

    return {
        widthTiles,
        heightTiles,
        widthPx: widthTiles * TILE_SIZE,
        heightPx: heightTiles * TILE_SIZE,
        stackingHeightPx: stackingHeightTiles * TILE_SIZE,
        gridWidth,
        gridHeight
    };
}
```

## Positioning Constants

```javascript
// For visual overlap between rooms
const VISUAL_OVERLAP_PX = 64; // 2 tiles (top wall overlaps)

// Grid unit sizes in pixels
const GRID_UNIT_WIDTH_PX = GRID_UNIT_WIDTH_TILES * TILE_SIZE;  // 160px
const GRID_UNIT_HEIGHT_PX = GRID_UNIT_HEIGHT_TILES * TILE_SIZE; // 128px
```

## Connection Processing

### General Approach

For each direction, we need to:
1. Determine how many rooms connect in that direction
2. Calculate total width/height needed for connected rooms
3. Position rooms to align properly
4. Ensure doors will align

### North Connections

**Single Room**:
```
    [Connected Room]
    [Current Room]
```

```javascript
function positionNorthSingle(currentRoom, connectedRoom, currentPos, dimensions) {
    const currentDim = dimensions[currentRoom];
    const connectedDim = dimensions[connectedRoom];

    // Center the connected room above current room
    // Account for visual overlap (top 2 tiles of current room)
    const x = currentPos.x + (currentDim.widthPx - connectedDim.widthPx) / 2;
    const y = currentPos.y - connectedDim.stackingHeightPx;

    // Align to grid using floor (consistent rounding for negatives)
    // CRITICAL: Math.floor ensures consistent behavior with negative coordinates
    // Math.floor(-80/160) = Math.floor(-0.5) = -1 (rounds toward -infinity)
    return {
        x: Math.floor(x / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
        y: Math.floor(y / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
    };
}
```

**Multiple Rooms**:
```
    [Room1][Room2]
    [Current Room]
```

```javascript
function positionNorthMultiple(currentRoom, connectedRooms, currentPos, dimensions) {
    const currentDim = dimensions[currentRoom];
    const positions = {};

    // Calculate total width of all connected rooms
    const totalWidth = connectedRooms.reduce((sum, roomId) => {
        return sum + dimensions[roomId].widthPx;
    }, 0);

    // Determine starting X position (center the group)
    const startX = currentPos.x + (currentDim.widthPx - totalWidth) / 2;

    // Position each room left to right
    let currentX = startX;
    connectedRooms.forEach(roomId => {
        const connectedDim = dimensions[roomId];

        // Y position is based on stacking height
        const y = currentPos.y - connectedDim.stackingHeightPx;

        // Align to grid using floor (consistent rounding)
        positions[roomId] = {
            x: Math.floor(currentX / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
            y: Math.floor(y / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
        };

        currentX += connectedDim.widthPx;
    });

    return positions;
}
```

### South Connections

**Single Room**:
```
    [Current Room]
    [Connected Room]
```

```javascript
function positionSouthSingle(currentRoom, connectedRoom, currentPos, dimensions) {
    const currentDim = dimensions[currentRoom];
    const connectedDim = dimensions[connectedRoom];

    // Center the connected room below current room
    const x = currentPos.x + (currentDim.widthPx - connectedDim.widthPx) / 2;
    const y = currentPos.y + currentDim.stackingHeightPx;

    // Align to grid using floor
    return {
        x: Math.floor(x / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
        y: Math.floor(y / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
    };
}
```

**Multiple Rooms**:
```
    [Current Room]
    [Room1][Room2]
```

```javascript
function positionSouthMultiple(currentRoom, connectedRooms, currentPos, dimensions) {
    const currentDim = dimensions[currentRoom];
    const positions = {};

    // Calculate total width
    const totalWidth = connectedRooms.reduce((sum, roomId) => {
        return sum + dimensions[roomId].widthPx;
    }, 0);

    // Center the group
    const startX = currentPos.x + (currentDim.widthPx - totalWidth) / 2;

    // Position each room
    let currentX = startX;
    connectedRooms.forEach(roomId => {
        const connectedDim = dimensions[roomId];

        const y = currentPos.y + currentDim.stackingHeightPx;

        positions[roomId] = {
            x: Math.floor(currentX / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
            y: Math.floor(y / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
        };

        currentX += connectedDim.widthPx;
    });

    return positions;
}
```

### East Connections

**Single Room**:
```
    [Current][Connected]
```

```javascript
function positionEastSingle(currentRoom, connectedRoom, currentPos, dimensions) {
    const currentDim = dimensions[currentRoom];
    const connectedDim = dimensions[connectedRoom];

    // Position to the right, aligned at top (north edge)
    const x = currentPos.x + currentDim.widthPx;
    const y = currentPos.y; // Align north edges

    // Align to grid using floor
    return {
        x: Math.floor(x / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
        y: Math.floor(y / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
    };
}
```

**Multiple Rooms**:
```
    [Current][Room1]
             [Room2]
```

```javascript
function positionEastMultiple(currentRoom, connectedRooms, currentPos, dimensions) {
    const currentDim = dimensions[currentRoom];
    const positions = {};

    const startX = currentPos.x + currentDim.widthPx;

    // Stack vertically, starting at current room's Y
    let currentY = currentPos.y;
    connectedRooms.forEach(roomId => {
        const connectedDim = dimensions[roomId];

        positions[roomId] = {
            x: Math.floor(startX / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
            y: Math.floor(currentY / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
        };

        currentY += connectedDim.stackingHeightPx;
    });

    return positions;
}
```

### West Connections

Mirror of East connections, but positions to the left.

```javascript
function positionWestSingle(currentRoom, connectedRoom, currentPos, dimensions) {
    const connectedDim = dimensions[connectedRoom];

    // Position to the left, aligned at top
    const x = currentPos.x - connectedDim.widthPx;
    const y = currentPos.y;

    // Align to grid using floor
    return {
        x: Math.floor(x / GRID_UNIT_WIDTH_PX) * GRID_UNIT_WIDTH_PX,
        y: Math.floor(y / GRID_UNIT_HEIGHT_PX) * GRID_UNIT_HEIGHT_PX
    };
}
```

## Complete Algorithm Implementation

```javascript
function calculateRoomPositions(gameScenario, gameInstance) {
    const positions = {};
    const dimensions = {};
    const processed = new Set();
    const queue = [];

    console.log('=== Room Positioning Algorithm ===');

    // 1. Extract all room dimensions
    Object.entries(gameScenario.rooms).forEach(([roomId, roomData]) => {
        dimensions[roomId] = getRoomDimensions(roomId, roomData, gameInstance);
        console.log(`Room ${roomId}: ${dimensions[roomId].widthTiles}×${dimensions[roomId].heightTiles} tiles ` +
                    `(${dimensions[roomId].gridWidth}×${dimensions[roomId].gridHeight} grid units)`);
    });

    // 2. Place starting room at origin
    const startRoom = gameScenario.startRoom;
    positions[startRoom] = { x: 0, y: 0 };
    processed.add(startRoom);
    queue.push(startRoom);

    console.log(`Starting room: ${startRoom} at (0, 0)`);

    // 3. Process rooms breadth-first
    while (queue.length > 0) {
        const currentRoomId = queue.shift();
        const currentRoom = gameScenario.rooms[currentRoomId];
        const currentPos = positions[currentRoomId];
        const currentDim = dimensions[currentRoomId];

        console.log(`\nProcessing: ${currentRoomId} at (${currentPos.x}, ${currentPos.y})`);

        // Process each connection direction
        ['north', 'south', 'east', 'west'].forEach(direction => {
            if (!currentRoom.connections[direction]) return;

            const connected = currentRoom.connections[direction];
            const connectedRooms = Array.isArray(connected) ? connected : [connected];

            // Filter out already processed rooms
            const unprocessedRooms = connectedRooms.filter(id => !processed.has(id));
            if (unprocessedRooms.length === 0) return;

            console.log(`  ${direction}: ${unprocessedRooms.join(', ')}`);

            // Calculate positions based on direction and count
            let newPositions;
            if (unprocessedRooms.length === 1) {
                // Single room connection
                const roomId = unprocessedRooms[0];
                const pos = positionSingleRoom(direction, currentRoomId, roomId,
                                               currentPos, dimensions);
                newPositions = { [roomId]: pos };
            } else {
                // Multiple room connections
                newPositions = positionMultipleRooms(direction, currentRoomId,
                                                     unprocessedRooms, currentPos, dimensions);
            }

            // Apply positions and add to queue
            Object.entries(newPositions).forEach(([roomId, pos]) => {
                positions[roomId] = pos;
                processed.add(roomId);
                queue.push(roomId);
                console.log(`    ${roomId} positioned at (${pos.x}, ${pos.y})`);
            });
        });
    }

    // 4. Validate positions (check for overlaps)
    validateRoomPositions(positions, dimensions);

    console.log('\n=== Final Room Positions ===');
    Object.entries(positions).forEach(([roomId, pos]) => {
        const dim = dimensions[roomId];
        console.log(`${roomId}: (${pos.x}, ${pos.y}) [${dim.widthPx}×${dim.heightPx}px]`);
    });

    return positions;
}

// Helper function to route to correct positioning function
function positionSingleRoom(direction, currentRoom, connectedRoom, currentPos, dimensions) {
    switch (direction) {
        case 'north': return positionNorthSingle(currentRoom, connectedRoom, currentPos, dimensions);
        case 'south': return positionSouthSingle(currentRoom, connectedRoom, currentPos, dimensions);
        case 'east': return positionEastSingle(currentRoom, connectedRoom, currentPos, dimensions);
        case 'west': return positionWestSingle(currentRoom, connectedRoom, currentPos, dimensions);
    }
}

function positionMultipleRooms(direction, currentRoom, connectedRooms, currentPos, dimensions) {
    switch (direction) {
        case 'north': return positionNorthMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        case 'south': return positionSouthMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        case 'east': return positionEastMultiple(currentRoom, connectedRooms, currentPos, dimensions);
        case 'west': return positionWestMultiple(currentRoom, connectedRooms, currentPos, dimensions);
    }
}
```

## Validation

```javascript
function validateRoomPositions(positions, dimensions) {
    console.log('\n=== Validating Room Positions ===');

    const roomIds = Object.keys(positions);
    let overlapCount = 0;

    // Check each pair of rooms
    for (let i = 0; i < roomIds.length; i++) {
        for (let j = i + 1; j < roomIds.length; j++) {
            const room1Id = roomIds[i];
            const room2Id = roomIds[j];

            const r1 = {
                x: positions[room1Id].x,
                y: positions[room1Id].y,
                width: dimensions[room1Id].widthPx,
                height: dimensions[room1Id].stackingHeightPx
            };

            const r2 = {
                x: positions[room2Id].x,
                y: positions[room2Id].y,
                width: dimensions[room2Id].widthPx,
                height: dimensions[room2Id].stackingHeightPx
            };

            // AABB overlap test
            const overlaps = !(
                r1.x + r1.width <= r2.x ||
                r2.x + r2.width <= r1.x ||
                r1.y + r1.height <= r2.y ||
                r2.y + r2.height <= r1.y
            );

            if (overlaps) {
                console.error(`❌ OVERLAP DETECTED: ${room1Id} and ${room2Id}`);
                console.error(`   ${room1Id}: (${r1.x}, ${r1.y}) ${r1.width}×${r1.height}`);
                console.error(`   ${room2Id}: (${r2.x}, ${r2.y}) ${r2.width}×${r2.height}`);
                overlapCount++;
            }
        }
    }

    if (overlapCount === 0) {
        console.log('✅ No overlaps detected');
    } else {
        console.error(`❌ Found ${overlapCount} room overlaps`);
    }

    return overlapCount === 0;
}
```

## Edge Cases

### Narrow Rooms Connecting to Wide Rooms
```
    [Room1 - 1 grid unit wide]
    [Room0 - 4 grid units wide]
```
- Room1 is centered above Room0
- Works automatically with centering logic

### Multiple Small Rooms on Large Room
```
    [R1][R2][R3]
    [---Room0---]
```
- Total width of R1+R2+R3 may be < Room0 width
- Centering ensures balanced layout

### Hallway Connectors
```
    [Room1][Room2]
    [---Hallway--]
    [---Room0---]
```
- Hallway explicitly defined in scenario
- Treated as regular room in positioning
- No special logic needed
