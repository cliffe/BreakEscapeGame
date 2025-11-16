# Room Layout System Redesign - Implementation Plan

## Quick Start

**Status**: ✅ Planning Complete - Ready for Implementation

This directory contains the complete implementation plan for redesigning the room layout system to support:
- Variable room sizes (in multiples of grid units)
- Four-direction connections (north, south, east, west)
- Intelligent door placement and alignment
- Comprehensive scenario validation

## Document Organization

### Core Concepts (Read First)
1. **[OVERVIEW.md](OVERVIEW.md)** - High-level goals and changes
2. **[TERMINOLOGY.md](TERMINOLOGY.md)** - Definitions of tiles, grid units, etc.
3. **[GRID_SYSTEM.md](GRID_SYSTEM.md)** - Grid unit system explained

### Technical Specifications
4. **[POSITIONING_ALGORITHM.md](POSITIONING_ALGORITHM.md)** - Room positioning logic
5. **[DOOR_PLACEMENT.md](DOOR_PLACEMENT.md)** - Door placement rules
6. **[WALL_SYSTEM.md](WALL_SYSTEM.md)** - Wall collision updates
7. **[VALIDATION.md](VALIDATION.md)** - Scenario validation system

### Implementation Guides
8. **[IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md)** - Step-by-step implementation
9. **[TODO_LIST.md](TODO_LIST.md)** - Detailed task checklist

### Review & Recommendations
10. **[review1/CRITICAL_REVIEW.md](review1/CRITICAL_REVIEW.md)** - Critical issues identified
11. **[review1/RECOMMENDATIONS.md](review1/RECOMMENDATIONS.md)** - Solutions and fixes
12. **[UPDATED_FILES_SUMMARY.md](UPDATED_FILES_SUMMARY.md)** - Review feedback integration

## Critical Information

### Valid Room Sizes

**Width**: Must be multiple of 5 tiles (5, 10, 15, 20, 25...)

**Height**: Must follow formula: `2 + (N × 4)` where N ≥ 1
- **Valid heights**: 6, 10, 14, 18, 22, 26...
- **Invalid heights**: 7, 8, 9, 11, 12, 13...

**Examples**:
- Closet: 5×6 tiles ✅
- Standard: 10×10 tiles ✅
- Wide Hall: 20×6 tiles ✅
- Invalid: 10×8 tiles ❌ (8 is not valid height)

### Critical Fixes Required

Based on code reviews (review1 and review2), these issues MUST be addressed:

1. **Negative Modulo Fix for Door Placement** ⚠️ CRITICAL - ✅ INTEGRATED
   - JavaScript modulo with negatives: `-5 % 2 = -1` (not `1`)
   - Fixed: Use `((sum % 2) + 2) % 2` for deterministic door placement
   - Affects all rooms with negative grid coordinates
   - **Status**: Integrated into DOOR_PLACEMENT.md

2. **Door Alignment for Asymmetric Connections** ⚠️ CRITICAL - ✅ INTEGRATED
   - When single-connection room links to multi-connection room
   - Doors must align by checking connected room's connection array
   - Example: office1 (2 north doors) ↔ office2 (1 south door)
   - **Status**: Integrated into DOOR_PLACEMENT.md (all 4 directions)

3. **Consistent Grid Alignment with Math.floor()** ⚠️ CRITICAL - ✅ INTEGRATED
   - Math.round(-0.5) has ambiguous behavior
   - Use Math.floor() for consistent rounding toward -infinity
   - Ensures deterministic positioning for all grid coordinates
   - **Status**: Integrated into POSITIONING_ALGORITHM.md and GRID_SYSTEM.md

4. **Shared Door Positioning Module** ⚠️ HIGH PRIORITY
   - Create `js/systems/door-positioning.js`
   - Single source of truth for door calculations
   - Eliminates code duplication between doors.js and collision.js
   - **Status**: Specified in plan, needs implementation

5. **Grid Height Clarification** ✅ RESOLVED
   - Valid heights documented in GRID_SYSTEM.md: 6, 10, 14, 18, 22, 26...
   - Formula: totalHeight = 2 + (N × 4) where N ≥ 1
   - Validation function specified

6. **Connectivity Validation** ⚠️ REQUIRED
   - Detect rooms with no path from starting room
   - Log warnings for disconnected rooms
   - **Status**: Specified in VALIDATION.md

7. **Room Dimension Audit** ⚠️ CRITICAL - ⚠️ ACTION REQUIRED
   - Audit all room JSON files for valid dimensions
   - Current rooms may be 10×8 (invalid - should be 10×10 or 10×6)
   - Must be completed BEFORE implementation begins
   - **Status**: Documented in review2, needs execution

## Implementation Strategy

### Recommended Approach: Incremental with Feature Flag

**Phase 0**: Pre-Implementation Audit (2-4 hours) ⚠️ DO FIRST
- Audit all room JSON files for valid dimensions
- Update invalid room heights (8 → 10 or 8 → 6)
- Add feature flag (`USE_NEW_ROOM_LAYOUT = true`)
- Test feature flag toggle
- Document room dimension changes

**Phase 1**: Foundation (2-3 hours)
- Add constants and helper functions
- Test grid conversions

**Phase 2a**: North/South Positioning (3-4 hours)
- Implement N/S room positioning only
- Test with all existing scenarios
- Get early validation

**Phase 2b**: East/West Support (2-3 hours)
- Add E/W positioning
- Test with new scenarios

**Phase 3**: Door Placement (3-4 hours)
- Create shared door positioning module
- Update door sprite creation
- Update wall tile removal
- **Critical**: Implement asymmetric connection handling

**Phase 4**: Validation (2-3 hours)
- Add all validation functions
- Create ValidationReport class
- Test with invalid scenarios

**Phase 5**: Testing & Refinement (4-6 hours)
- Test all existing scenarios
- Create comprehensive test scenarios
- Fix bugs

**Phase 6**: Documentation (2-3 hours)
- Add code comments
- Create debug tools
- Write migration guide

**Total Estimated Time**: 18-26 hours

### Avoid "Big Bang" Approach

❌ Don't implement everything at once
✅ Do implement and test incrementally
✅ Do commit after each phase
✅ Do test existing scenarios early

## Key Design Decisions

### Grid Unit Size: 5×4 tiles

**Why 5 tiles wide?**
- 1 tile each side for walls
- 3 tiles minimum interior space
- Allows single door placement (needs 1.5 tile inset)

**Why 4 tiles tall (stacking)?**
- Plus 2 visual top tiles = 6 tiles minimum total height
- Creates consistent vertical rhythm
- Aligns with standard room proportions

### Deterministic Door Placement

For rooms with single connections, door position (left vs right) is determined by:
```javascript
const useRightSide = (gridX + gridY) % 2 === 1;
```

This creates visual variety while being deterministic.

**EXCEPT**: When connecting to room with multiple connections, must align with that room's door array.

### Breadth-First Positioning

Rooms positioned outward from starting room ensures:
- Deterministic layout
- All rooms reachable
- No forward references needed

## Testing Strategy

### Test Scenarios Required

1. **Different Sizes**: Closet, standard, wide hall combinations
2. **East/West**: Horizontal connections
3. **Multiple Connections**: 3+ rooms in same direction
4. **Complex Layout**: Multi-directional with hallways
5. **Invalid Scenarios**: Wrong sizes, missing connections, overlaps

### Existing Scenarios

All must continue to work:
- scenario1.json (biometric_breach)
- cybok_heist.json
- scenario2.json
- ceo_exfil.json

## Common Pitfalls to Avoid

1. **Floating Point Errors**
   - Always use `Math.round()` for pixel positions
   - Align to grid boundaries

2. **Door Misalignment**
   - Use shared door positioning function
   - Handle asymmetric connections correctly
   - Validate alignment after positioning

3. **Stacking vs Total Height Confusion**
   - Use stacking height for positioning
   - Use total height for rendering
   - Document which is used where

4. **Forgetting Visual Overlap**
   - Top 2 tiles overlap room to north (correct)
   - Don't treat as collision overlap
   - Use in rendering depth calculations

## Debug Tools

Add these to console for debugging:

```javascript
window.showRoomLayout()      // Visualize room bounds and grid
window.checkScenario()       // Print validation results
window.listRooms()           // List all room positions
window.showWallCollisions()  // Visualize collision boxes
```

## Files to Modify

### Core Changes
- `js/utils/constants.js` - Add grid constants
- `js/core/rooms.js` - New positioning algorithm
- `js/systems/doors.js` - New door placement
- `js/systems/collision.js` - Update wall tile removal
- `js/systems/door-positioning.js` - NEW: Shared door module

### New Files
- `js/core/validation.js` - Scenario validation (optional, can be in rooms.js)
- Test scenarios in `scenarios/test_*.json`

### Tiled Room Files
May need to update existing room JSON files to valid heights:
- Check all room_*.json files
- Ensure heights are 6, 10, 14, 18, 22, 26...
- Update if needed

## Success Criteria

- [ ] All existing scenarios load without errors
- [ ] All test scenarios work correctly
- [ ] No validation errors for valid scenarios
- [ ] Validation catches all invalid scenarios
- [ ] All doors align perfectly (verified)
- [ ] No room overlaps detected
- [ ] Navigation works in all 4 directions
- [ ] Performance acceptable (< 1s load time)
- [ ] Code well documented
- [ ] Debug tools functional

## Questions?

Refer to specific documents for details:
- How grid units work? → GRID_SYSTEM.md
- How to position rooms? → POSITIONING_ALGORITHM.md
- How to place doors? → DOOR_PLACEMENT.md
- How to validate? → VALIDATION.md
- What's the critical bug? → review1/CRITICAL_REVIEW.md
- How to fix it? → review1/RECOMMENDATIONS.md

## Next Steps

1. ✅ Read OVERVIEW.md and TERMINOLOGY.md (understand concepts)
2. ✅ Read review1/CRITICAL_REVIEW.md (understand issues)
3. ✅ Read review1/RECOMMENDATIONS.md (understand solutions)
4. ⏭️ Start implementation following IMPLEMENTATION_STEPS.md
5. ⏭️ Use TODO_LIST.md to track progress
6. ⏭️ Test continuously, commit frequently

---

**Last Updated**: 2025-11-15
**Status**: Planning complete, ready for implementation
**Confidence**: 9/10 (all critical issues identified and solutions specified)
