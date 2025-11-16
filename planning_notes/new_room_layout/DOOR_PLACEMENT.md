# Door Placement System

## Overview

Doors must be placed such that they:
1. Align perfectly between connecting rooms
2. Follow visual conventions (corners for N/S, edges for E/W)
3. Use deterministic positioning for consistent layouts
4. Support multiple doors per room edge

## Door Types

### North/South Doors
- **Sprite**: `door_32.png` (sprite sheet: `door_sheet_32.png`)
- **Size**: 1 tile wide × 2 tiles tall
- **Placement**: In corners of the room
- **Visual**: Represents passage through wall with visible door frame

### East/West Doors
- **Sprite**: `door_side_sheet_32.png`
- **Size**: 1 tile wide × 1 tile tall
- **Placement**: At edges, based on connection count
- **Visual**: Side view of door

## Placement Rules

### North Connections

#### Single Door
- **Position**: Determined by grid coordinates using modulus for alternation
- **Options**: Northwest corner or Northeast corner
- **Inset**: 1.5 tiles from edge (half tile for wall, 1 tile for door)

```javascript
function placeNorthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords,
                              connectedRoom, gameScenario, allPositions, allDimensions) {
    const roomWidthPx = roomDimensions.widthPx;

    // CRITICAL: Check if connected room has multiple connections in opposite direction
    // If so, we must align with that room's multi-door layout
    const connectedRoomData = gameScenario.rooms[connectedRoom];
    const connectedSouthConnections = connectedRoomData?.connections?.south;

    if (Array.isArray(connectedSouthConnections) && connectedSouthConnections.length > 1) {
        // Connected room has multiple south doors - align with the correct one
        const indexInArray = connectedSouthConnections.indexOf(roomId);

        if (indexInArray >= 0) {
            // Calculate where the connected room's door is positioned
            const connectedPos = allPositions[connectedRoom];
            const connectedDim = allDimensions[connectedRoom];

            // Use same spacing logic as placeNorthDoorsMultiple
            const edgeInset = TILE_SIZE * 1.5;
            const availableWidth = connectedDim.widthPx - (edgeInset * 2);
            const doorCount = connectedSouthConnections.length;
            const spacing = availableWidth / (doorCount - 1);

            const alignedDoorX = connectedPos.x + edgeInset + (spacing * indexInArray);
            const doorY = roomPosition.y + TILE_SIZE;

            return { x: alignedDoorX, y: doorY };
        }
    }

    // Default: Deterministic left/right placement based on grid position
    // CRITICAL FIX: Handle negative grid coordinates correctly
    // JavaScript modulo with negatives: -5 % 2 = -1 (not 1)
    const sum = gridCoords.x + gridCoords.y;
    const useRightSide = ((sum % 2) + 2) % 2 === 1;

    let doorX;
    if (useRightSide) {
        // Northeast corner
        doorX = roomPosition.x + roomWidthPx - (TILE_SIZE * 1.5);
    } else {
        // Northwest corner
        doorX = roomPosition.x + (TILE_SIZE * 1.5);
    }

    // Door Y is 1 tile from top
    const doorY = roomPosition.y + TILE_SIZE;

    return { x: doorX, y: doorY };
}
```

#### Multiple Doors
- **Position**: Evenly spaced across room width
- **Spacing**: Maintains 1.5 tile inset from edges
- **Count**: Supports 2+ doors

```javascript
function placeNorthDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms) {
    const roomWidthPx = roomDimensions.widthPx;
    const doorPositions = [];

    // Available width after edge insets
    const edgeInset = TILE_SIZE * 1.5;
    const availableWidth = roomWidthPx - (edgeInset * 2);

    // Space between doors
    const doorCount = connectedRooms.length;
    const doorSpacing = availableWidth / (doorCount - 1);

    connectedRooms.forEach((connectedRoom, index) => {
        const doorX = roomPosition.x + edgeInset + (doorSpacing * index);
        const doorY = roomPosition.y + TILE_SIZE;

        doorPositions.push({
            connectedRoom,
            x: doorX,
            y: doorY
        });
    });

    return doorPositions;
}
```

### South Connections

Same as North, but door Y position is at bottom:

```javascript
function placeSouthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords,
                              connectedRoom, gameScenario, allPositions, allDimensions) {
    const roomWidthPx = roomDimensions.widthPx;
    const roomHeightPx = roomDimensions.heightPx;

    // CRITICAL: Check if connected room has multiple north connections
    const connectedRoomData = gameScenario.rooms[connectedRoom];
    const connectedNorthConnections = connectedRoomData?.connections?.north;

    if (Array.isArray(connectedNorthConnections) && connectedNorthConnections.length > 1) {
        // Connected room has multiple north doors - align with the correct one
        const indexInArray = connectedNorthConnections.indexOf(roomId);

        if (indexInArray >= 0) {
            const connectedPos = allPositions[connectedRoom];
            const connectedDim = allDimensions[connectedRoom];

            const edgeInset = TILE_SIZE * 1.5;
            const availableWidth = connectedDim.widthPx - (edgeInset * 2);
            const doorCount = connectedNorthConnections.length;
            const spacing = availableWidth / (doorCount - 1);

            const alignedDoorX = connectedPos.x + edgeInset + (spacing * indexInArray);
            const doorY = roomPosition.y + roomHeightPx - TILE_SIZE;

            return { x: alignedDoorX, y: doorY };
        }
    }

    // Default: deterministic placement with negative modulo fix
    const sum = gridCoords.x + gridCoords.y;
    const useRightSide = ((sum % 2) + 2) % 2 === 1;

    let doorX;
    if (useRightSide) {
        doorX = roomPosition.x + roomWidthPx - (TILE_SIZE * 1.5);
    } else {
        doorX = roomPosition.x + (TILE_SIZE * 1.5);
    }

    // Door Y is at bottom (room height - 1 tile)
    const doorY = roomPosition.y + roomHeightPx - TILE_SIZE;

    return { x: doorX, y: doorY };
}
```

### East Connections

#### Single Door
- **Position**: North corner of east edge
- **Inset**: 2 tiles from top (below visual wall)

```javascript
function placeEastDoorSingle(roomId, roomPosition, roomDimensions,
                             connectedRoom, gameScenario, allPositions, allDimensions) {
    const roomWidthPx = roomDimensions.widthPx;

    // CRITICAL: Check if connected room has multiple west connections
    const connectedRoomData = gameScenario.rooms[connectedRoom];
    const connectedWestConnections = connectedRoomData?.connections?.west;

    if (Array.isArray(connectedWestConnections) && connectedWestConnections.length > 1) {
        // Connected room has multiple west doors - align with the correct one
        const indexInArray = connectedWestConnections.indexOf(roomId);

        if (indexInArray >= 0) {
            const connectedPos = allPositions[connectedRoom];
            const connectedDim = allDimensions[connectedRoom];

            // Calculate door Y based on connected room's multi-door spacing
            const doorCount = connectedWestConnections.length;
            let alignedDoorY;

            if (doorCount === 1) {
                alignedDoorY = connectedPos.y + (TILE_SIZE * 2);
            } else if (indexInArray === 0) {
                alignedDoorY = connectedPos.y + (TILE_SIZE * 2);
            } else if (indexInArray === doorCount - 1) {
                alignedDoorY = connectedPos.y + connectedDim.heightPx - (TILE_SIZE * 3);
            } else {
                const firstDoorY = connectedPos.y + (TILE_SIZE * 2);
                const lastDoorY = connectedPos.y + connectedDim.heightPx - (TILE_SIZE * 3);
                const spacing = (lastDoorY - firstDoorY) / (doorCount - 1);
                alignedDoorY = firstDoorY + (spacing * indexInArray);
            }

            const doorX = roomPosition.x + roomWidthPx - TILE_SIZE;
            return { x: doorX, y: alignedDoorY };
        }
    }

    // Default: place at north corner of east edge
    const doorX = roomPosition.x + roomWidthPx - TILE_SIZE;
    const doorY = roomPosition.y + (TILE_SIZE * 2); // Below visual wall

    return { x: doorX, y: doorY };
}
```

#### Multiple Doors
- **First Door**: North corner (2 tiles from top)
- **Second Door**: 3 tiles up from south edge (avoids overlap)
- **More Doors**: Evenly spaced between first and second

```javascript
function placeEastDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms) {
    const roomWidthPx = roomDimensions.widthPx;
    const roomHeightPx = roomDimensions.heightPx;
    const doorPositions = [];

    const doorCount = connectedRooms.length;

    if (doorCount === 1) {
        return [placeEastDoorSingle(roomId, roomPosition, roomDimensions)];
    }

    connectedRooms.forEach((connectedRoom, index) => {
        const doorX = roomPosition.x + roomWidthPx - TILE_SIZE;

        let doorY;
        if (index === 0) {
            // First door: north corner
            doorY = roomPosition.y + (TILE_SIZE * 2);
        } else if (index === doorCount - 1) {
            // Last door: 3 tiles up from south
            doorY = roomPosition.y + roomHeightPx - (TILE_SIZE * 3);
        } else {
            // Middle doors: evenly spaced
            const firstDoorY = roomPosition.y + (TILE_SIZE * 2);
            const lastDoorY = roomPosition.y + roomHeightPx - (TILE_SIZE * 3);
            const spacing = (lastDoorY - firstDoorY) / (doorCount - 1);
            doorY = firstDoorY + (spacing * index);
        }

        doorPositions.push({
            connectedRoom,
            x: doorX,
            y: doorY
        });
    });

    return doorPositions;
}
```

### West Connections

Mirror of East connections:

```javascript
function placeWestDoorSingle(roomId, roomPosition, roomDimensions,
                             connectedRoom, gameScenario, allPositions, allDimensions) {
    // CRITICAL: Check if connected room has multiple east connections
    const connectedRoomData = gameScenario.rooms[connectedRoom];
    const connectedEastConnections = connectedRoomData?.connections?.east;

    if (Array.isArray(connectedEastConnections) && connectedEastConnections.length > 1) {
        // Connected room has multiple east doors - align with the correct one
        const indexInArray = connectedEastConnections.indexOf(roomId);

        if (indexInArray >= 0) {
            const connectedPos = allPositions[connectedRoom];
            const connectedDim = allDimensions[connectedRoom];

            // Calculate door Y based on connected room's multi-door spacing
            const doorCount = connectedEastConnections.length;
            let alignedDoorY;

            if (doorCount === 1) {
                alignedDoorY = connectedPos.y + (TILE_SIZE * 2);
            } else if (indexInArray === 0) {
                alignedDoorY = connectedPos.y + (TILE_SIZE * 2);
            } else if (indexInArray === doorCount - 1) {
                alignedDoorY = connectedPos.y + connectedDim.heightPx - (TILE_SIZE * 3);
            } else {
                const firstDoorY = connectedPos.y + (TILE_SIZE * 2);
                const lastDoorY = connectedPos.y + connectedDim.heightPx - (TILE_SIZE * 3);
                const spacing = (lastDoorY - firstDoorY) / (doorCount - 1);
                alignedDoorY = firstDoorY + (spacing * indexInArray);
            }

            const doorX = roomPosition.x + TILE_SIZE;
            return { x: doorX, y: alignedDoorY };
        }
    }

    // Default: place at north corner of west edge
    const doorX = roomPosition.x + TILE_SIZE;
    const doorY = roomPosition.y + (TILE_SIZE * 2);

    return { x: doorX, y: doorY };
}
```

## Door Alignment Verification

Critical: Doors between two connecting rooms must align exactly.

```javascript
function verifyDoorAlignment(room1Id, room2Id, door1Pos, door2Pos, direction) {
    const tolerance = 1; // 1px tolerance for floating point errors

    const deltaX = Math.abs(door1Pos.x - door2Pos.x);
    const deltaY = Math.abs(door1Pos.y - door2Pos.y);

    if (deltaX > tolerance || deltaY > tolerance) {
        console.error(`❌ Door misalignment between ${room1Id} and ${room2Id}`);
        console.error(`   ${room1Id} door: (${door1Pos.x}, ${door1Pos.y})`);
        console.error(`   ${room2Id} door: (${door2Pos.x}, ${door2Pos.y})`);
        console.error(`   Delta: (${deltaX}, ${deltaY}) [tolerance: ${tolerance}]`);
        return false;
    }

    console.log(`✅ Door alignment verified: ${room1Id} ↔ ${room2Id}`);
    return true;
}
```

## Complete Door Placement Algorithm

```javascript
function calculateDoorPositions(roomId, roomPosition, roomDimensions, connections, allPositions, allDimensions) {
    const doors = [];
    const gridCoords = worldToGrid(roomPosition.x, roomPosition.y);

    // Process each direction
    ['north', 'south', 'east', 'west'].forEach(direction => {
        if (!connections[direction]) return;

        const connected = connections[direction];
        const connectedRooms = Array.isArray(connected) ? connected : [connected];

        let doorPositions;

        // Calculate door positions based on direction and count
        if (direction === 'north') {
            doorPositions = connectedRooms.length === 1
                ? [{ connectedRoom: connectedRooms[0], ...placeNorthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords) }]
                : placeNorthDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms);
        } else if (direction === 'south') {
            doorPositions = connectedRooms.length === 1
                ? [{ connectedRoom: connectedRooms[0], ...placeSouthDoorSingle(roomId, roomPosition, roomDimensions, gridCoords) }]
                : placeSouthDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms);
        } else if (direction === 'east') {
            doorPositions = placeEastDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms);
        } else if (direction === 'west') {
            doorPositions = placeWestDoorsMultiple(roomId, roomPosition, roomDimensions, connectedRooms);
        }

        // Add to doors list
        doorPositions.forEach(doorPos => {
            doors.push({
                roomId,
                connectedRoom: doorPos.connectedRoom,
                direction,
                x: doorPos.x,
                y: doorPos.y
            });
        });
    });

    return doors;
}
```

## Door Sprite Creation

Unchanged from current implementation, but now uses calculated positions:

```javascript
function createDoorSprite(doorInfo, gameInstance) {
    const { roomId, connectedRoom, direction, x, y } = doorInfo;

    // Create door sprite
    const doorSprite = gameInstance.add.sprite(x, y, getDoorTexture(direction));
    doorSprite.setOrigin(0.5, 0.5);
    doorSprite.setDepth(y + 0.45);

    // Set up door properties
    doorSprite.doorProperties = {
        roomId,
        connectedRoom,
        direction,
        worldX: x,
        worldY: y,
        open: false,
        locked: getLockedState(connectedRoom),
        lockType: getLockType(connectedRoom),
        // ... other properties
    };

    // Set up collision and interaction
    setupDoorPhysics(doorSprite, gameInstance);
    setupDoorInteraction(doorSprite, gameInstance);

    return doorSprite;
}

function getDoorTexture(direction) {
    if (direction === 'north' || direction === 'south') {
        return 'door_32';
    } else {
        return 'door_side_sheet_32';
    }
}
```

## Special Cases

### Connecting Rooms of Different Sizes

When a small room connects to a large room:

```
    [Small - 1 grid unit]
    [Large - 4 grid units]
```

The small room's door will be in its corner (deterministic placement).
The large room's door will align with the small room's door position.

**Implementation**: Both rooms calculate their door positions independently, but because positioning is deterministic and based on the same grid alignment, doors will align.

### Hallway Connectors

Hallways are just narrow rooms:

```
    [Room1][Room2]
    [---Hallway--]
    [---Room0---]
```

- Hallway is 4 grid units wide × 1 grid unit tall
- Has 2 north doors (connecting to Room1 and Room2)
- Has 1 south door (connecting to Room0)
- Door placement follows standard rules

### Corner vs Center Placement

For aesthetic variety, doors alternate left/right based on grid coordinates:

```
Vertical stack of rooms:
    [Room3]    <- Door on left (grid sum = odd)
    [Room2]    <- Door on right (grid sum = even)
    [Room1]    <- Door on left (grid sum = odd)
    [Room0]    <- Starting room
```

This creates a more interesting zigzag pattern rather than all doors being on the same side.

## Testing Door Placement

```javascript
function testDoorPlacement() {
    // Test case: Two rooms connected north-south
    const room1 = {
        id: 'room1',
        position: { x: 0, y: 0 },
        dimensions: { widthPx: 320, heightPx: 256 }
    };

    const room2 = {
        id: 'room2',
        position: { x: 0, y: -192 }, // Stacking height = 192px
        dimensions: { widthPx: 320, heightPx: 256 }
    };

    // Calculate door positions
    const room1Door = calculateDoorPositions('room1', room1.position, room1.dimensions,
                                            { north: 'room2' }, {}, {});

    const room2Door = calculateDoorPositions('room2', room2.position, room2.dimensions,
                                            { south: 'room1' }, {}, {});

    // Verify alignment
    verifyDoorAlignment('room1', 'room2',
                       room1Door[0], room2Door[0], 'north');

    // Expected: Doors align exactly at same (x, y) world position
}
```

## Migration from Current System

Current system has special logic for detecting which side to place doors based on the connecting room's connections. This is replaced with:

1. **Grid-based deterministic placement**: Uses `(gridX + gridY) % 2` for left/right
2. **Simpler logic**: No need to check connecting room's connections
3. **More flexible**: Works with any room size combinations

The current code in `js/systems/doors.js` lines 86-159 will be replaced with the new door placement functions.
