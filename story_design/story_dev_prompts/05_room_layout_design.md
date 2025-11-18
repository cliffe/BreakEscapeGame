# Stage 5: Room Layout and Challenge Distribution

**Purpose:** Design the physical space where your scenario takes place, including room layouts, challenge placement, item distribution, and NPC positioning, while adhering to strict technical constraints.

**Output:** Complete room layout specification with challenge placement, item distribution, and technical compliance verification.

---

## Your Role

You are a level designer for Break Escape. Your tasks:

1. Design room layouts that support narrative and gameplay
2. Place challenges in appropriate locations
3. Distribute items and LORE fragments
4. Position NPCs and interactive elements
5. **Comply with all technical room generation constraints**

**CRITICAL:** Room layout is governed by strict technical rules. Violating these rules will result in unplayable scenarios.

## Required Reading

### ESSENTIAL - Technical Documentation
- **`docs/ROOM_GENERATION.md`** - CRITICAL: All room generation rules
- **`docs/GAME_DESIGN.md`** - Core game mechanics

### Essential - Design Documentation
- `story_design/universe_bible/06_locations/` - Location types
- `story_design/universe_bible/09_scenario_design/framework.md` - Design principles
- Previous stage outputs

## Critical Technical Constraints

**READ `docs/ROOM_GENERATION.md` IN FULL before proceeding.**

Key rules:
- All measurements in Grid Units (1 GU = 1.5m)
- **Minimum room size: 4×4 GU, Maximum: 15×15 GU**
- **All rooms have 1 GU padding on all sides**
- **Usable space = room size - 2 GU**
- **Place items ONLY in usable space, NEVER in padding**
- **Rooms must overlap by ≥ 1 GU for connections**

## Process

Define location, design individual rooms with exact dimensions, create overall map layout, place challenges, distribute items, position NPCs, and validate all technical constraints.

---

Save your room layout as:
```
scenario_designs/[scenario_name]/05_layout/room_design.md
scenario_designs/[scenario_name]/05_layout/challenge_placement.md
```

**Next Stage:** Pass room count and fragment positions to Stage 6 (LORE Fragments).
