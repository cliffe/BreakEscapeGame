# Scenario Design Constraints in Hacktivity Cyber Security Labs

There are several constraints and patterns for designing scenarios for BreakEscape.

## Scenario Structure Constraints

### Basic Structure
- Each scenario must have a `scenario_brief` that explains the mission
- Each scenario must define a `startRoom` where the player begins
- Some scenarios include an `endGoal` property (like in biometric_breach.json)
- All scenarios must have a `rooms` object containing individual room definitions

### Room Connections

Rooms can connect in **four directions**: `north`, `south`, `east`, `west`

**Connection Syntax**:
```json
"connections": {
  "north": "office1",           // Single connection
  "south": ["reception", "hall"], // Multiple connections (array)
  "east": "serverroom",
  "west": ["closet1", "closet2"]
}
```

**Key Points**:
- All directions support both single connections (string) and multiple connections (array)
- The room layout algorithm positions rooms using breadth-first traversal
- Multiple rooms in the same direction are positioned side-by-side (N/S) or stacked (E/W)
- All rooms align to grid boundaries for consistent door placement

#### Door Validation and Locking

The code in `validateDoorsByRoomOverlap()` (lines 3236-3323) shows that:

1. Doors must connect exactly two rooms (line 3281)
2. If a door connects to a locked room, the door inherits the lock properties (lines 3296-3303)
3. Doors that don't connect exactly two rooms are removed (lines 3281-3291)

#### Designing Solvable Scenarios with the Grid System

The grid-based room layout system provides significant flexibility for scenario design:

1. **Flexible Layout Patterns**: Design scenarios using any combination of directions:
   - **Vertical**: Stack rooms north/south for traditional layouts
   - **Horizontal**: Connect rooms east/west for wide facilities
   - **Mixed**: Combine directions for complex, non-linear layouts
   - **Branching**: All directions support multiple connections

2. **Room Size Variety**: Mix different room sizes for visual interest and gameplay:
   - Use **1×1 GU closets** for small storage rooms or utility spaces
   - Use **2×2 GU standard rooms** for offices, reception areas
   - Use **1×2 GU or 4×1 GU halls** to connect distant areas
   - Ensure all room dimensions follow the valid size formula

3. **Lock Progression**: Design logical progression through the facility:
   - Place keys, codes, and unlock items in accessible rooms first
   - Create puzzles that require backtracking or exploring side rooms
   - Use east/west connections for optional areas with bonus items
   - Layer security with multiple lock types (key → PIN → biometric)

4. **Connection Planning**:
   - Start by sketching your layout on grid paper (5-tile width increments)
   - Ensure all rooms are reachable from the starting room
   - Verify room dimensions before creating Tiled maps
   - Test door alignment between connected rooms

5. **Avoid Common Pitfalls**:
   - **Invalid heights**: Heights of 7, 8, 9, 11, 12, 13 will cause issues
   - **Room overlaps**: System validates and warns, but plan carefully
   - **Disconnected rooms**: Ensure all rooms connect to the starting room
   - **Asymmetric connections**: When connecting single-door to multi-door rooms, the system handles alignment automatically

#### Example Layout Structures

**Vertical Tower** (traditional):
```
        [Server Room]
             ↑
        [CEO Office]
             ↑
    [Office1] [Office2]
         ↑       ↑
        [Reception]
```

**Horizontal Facility** (wide):
```
[Closet1] ← [Office] → [Meeting] → [Server]
                ↑
           [Reception]
```

**Complex Multi-Direction**:
```
    [Storage]   [CEO]
        ↑         ↑
    [Closet] ← [Office] → [Server]
                  ↑
             [Reception]
```

**With Hallways**:
```
    [Office1]  [Office2]
        ↑          ↑
    [---- Hall ----]
           ↑
      [Reception]
```

These layouts demonstrate the flexibility of the new grid system for creating engaging, solvable scenarios.


### Room Properties
- Each room has a `type` property (e.g., "room_reception", "room_office", "room_ceo", "room_servers", "room_closet")
- Rooms can be `locked` with different lock types:
  - `lockType`: "key", "pin", "password", "bluetooth", or "biometric"
  - `requires`: The specific key_id, PIN code, password, MAC address, or fingerprint owner name needed
  - For biometric locks, a `biometricMatchThreshold` can be specified (e.g., 0.5, 0.7, 0.9)
- Each room contains an array of `objects` that players can interact with

### Object Properties
- Objects must have a `type` (e.g., "phone", "notes", "pc", "key", "safe", "suitcase", "fingerprint_kit")
- Objects must have a `name` for display purposes
- Objects have a `takeable` boolean property indicating if they can be added to inventory
- Objects can have `observations` text that describes what the player sees
- Readable objects have a `readable` property and `text` content
- Objects can be locked with the same lock types as rooms
- Container objects (like safes and suitcases) can have `contents` arrays with nested objects

### Starting Inventory
- Use the `startItemsInInventory` array at the root level of your scenario
- Players will have these items automatically when they start the game
- Example:
```json
{
  "scenario_brief": "...",
  "startRoom": "reception",
  "startItemsInInventory": [
    {
      "type": "workstation",
      "name": "Crypto Analysis Station",
      "takeable": true,
      "observations": "A powerful workstation for cryptographic analysis"
    }
  ],
  "rooms": { ... }
}
```

### Special Object Types
- `fingerprint_kit`: Used to collect fingerprints
- `workstation`: For cryptographic analysis
- `bluetooth_scanner`: For detecting Bluetooth devices
- `lockpick`: For picking locks
- Objects can have `hasFingerprint` with properties like `fingerprintOwner` and `fingerprintDifficulty`

## Room Layout System (Grid-Based)

The game uses a **grid unit system** for room positioning that supports variable room sizes and four-direction connections.

### Grid Unit System

- **Base Grid Unit (GU)**: 5 tiles wide × 4 tiles tall (160px × 128px)
- **Tile Size**: 32px × 32px
- **Room Structure**:
  - Top 2 rows: Visual wall (overlaps room to north)
  - Middle rows: Stackable area (used for positioning calculations)
  - All rooms must be multiples of grid units

### Valid Room Sizes

**Width**: Must be multiple of 5 tiles (5, 10, 15, 20, 25...)

**Height**: Must follow formula `2 + (N × 4)` where N ≥ 1
- **Valid heights**: 6, 10, 14, 18, 22, 26... (increments of 4 after initial 2)
- **Invalid heights**: 7, 8, 9, 11, 12, 13...

**Examples**:
- **1×1 GU** (Closet): 5×6 tiles = 160×192px
- **2×2 GU** (Standard): 10×10 tiles = 320×320px
- **1×2 GU** (Hall): 5×10 tiles = 160×320px
- **4×1 GU** (Wide Hall): 20×6 tiles = 640×192px

### Room Positioning Algorithm

1. The `startRoom` is positioned at grid coordinates (0,0)
2. Rooms are positioned outward from the starting room using breadth-first traversal
3. Rooms align to grid boundaries using `Math.floor()` for consistent rounding
4. **North/South**: Rooms stack vertically, centered or side-by-side when multiple
5. **East/West**: Rooms align horizontally, stacked vertically when multiple
6. All positions are validated to detect overlaps

### Door Placement Rules

**North/South Doors**:
- **Size**: 1 tile wide × 2 tiles tall
- **Single door**: Placed in corner (NW or NE), determined by grid coordinates using `(gridX + gridY) % 2`
- **Multiple doors**: Evenly spaced across room width with 1.5 tile inset from edges

**East/West Doors**:
- **Size**: 1 tile wide × 1 tile tall
- **Single door**: North corner of edge, 2 tiles from top
- **Multiple doors**: First at north corner, last 3 tiles up from south, others evenly spaced

**Alignment**: Doors must align perfectly between connecting rooms. Special logic handles asymmetric connections (single door to multi-door room).

### Four-Direction Connections

Unlike the old system (north/south only), the new system supports:
- **North**: Connects to rooms above
- **South**: Connects to rooms below
- **East**: Connects to rooms on the right
- **West**: Connects to rooms on the left

Each direction supports multiple connections (arrays).

## Designing Solvable Scenarios

Based on the grid-based room layout system, here are comprehensive guidelines for creating solvable scenarios:

1. **Clear Progression Path**: Design a logical sequence of rooms that can be unlocked in order
   - Ensure keys/codes for locked rooms are obtainable before they're needed
   - Use the four-direction connection system to create interesting navigation puzzles

2. **Tool Placement**: Place necessary tools early in the scenario
   - Critical tools like fingerprint kits, lockpicks, or bluetooth scanners should be available before they're needed
   - Consider adding some tools to the initial inventory with `startItemsInInventory`

3. **Clue Distribution**: Spread clues logically throughout the scenario
   - Place hints for codes/passwords in accessible locations
   - Use readable objects (notes, phones, computers) to provide guidance

4. **Lock Complexity Progression**: Increase difficulty gradually
   - Start with simpler locks (keys, simple PINs)
   - Progress to more complex locks (biometric with high thresholds)

5. **Nested Containers**: Use containers within containers strategically
   - Don't create unsolvable dependency loops (e.g., key A locked in a box requiring key B, which is locked in a box requiring key A)

6. **End Goal Items**: For scenarios with specific goals (like recovering the prototype in biometric_breach.json):
   - Mark important items with `important: true`
   - Use `isEndGoal: true` for the final objective item

7. **Room Layout with Grid System**: Design layouts using the grid unit system
   - Use valid room sizes (widths: multiples of 5 tiles; heights: 2 + 4N where N ≥ 1)
   - Mix room sizes for variety (1×1 GU closets, 2×2 GU standard rooms, hallways)
   - Leverage all four directions (north, south, east, west) for complex layouts
   - Ensure all rooms are reachable from the starting room

8. **Fingerprint Mechanics**: When using biometric locks:
   - Ensure the required fingerprints can be collected from objects in accessible rooms
   - Set appropriate difficulty thresholds (higher = more difficult)

9. **Testing Your Scenario**:
   - Verify all room dimensions follow the valid size formula
   - Check that all rooms connect properly (no isolated rooms)
   - Ensure door alignment by testing connections between different-sized rooms
   - Play through to verify the scenario is solvable

By following these constraints and guidelines, you can create scenarios that are both technically valid for the game engine and provide an engaging, solvable experience for players.
