# Break Escape Scenario Development Prompts

This directory contains a comprehensive set of AI agent prompts for building complete Break Escape scenarios through a structured, multi-stage process.

## Overview

Building a rich, educationally sound, and narratively compelling Break Escape scenario requires coordinating multiple design concerns: technical challenges, narrative structure, character development, moral choices, world-building, and interactive dialogue. This prompt system breaks the development process into 9 distinct stages, each handled by a specialized AI agent.

## The Development Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│ Stage 0: Scenario Initialization                               │
│ Output: Technical challenge outline + Narrative theme options  │
└─────────────────────┬───────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 1: Narrative Structure Development                       │
│ Output: Complete narrative arc with acts and key moments       │
└─────────────────────┬───────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 2: Storytelling Elements Design                          │
│ Output: Characters, dialogue, atmosphere, pacing               │
└─────────────────────┬───────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 3: Moral Choices and Consequences                        │
│ Output: Choice points with narrative branching                 │
└─────────────────────┬───────────────────────────────────────────┘
│                     │
│  ┌──────────────────┴──────────────────┐
│  ↓                                      ↓
│ ┌────────────────────────────┐  ┌────────────────────────────┐
│ │ Stage 4: Player Objectives │  │ Stage 5: Room Layout       │
│ │ Output: Goals & win states │  │ Output: Physical design    │
│ └──────────┬─────────────────┘  └────────┬───────────────────┘
│            └────────────┬────────────────┘
│                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 6: LORE Fragments Creation                               │
│ Output: Collectible fragments placed in scenario               │
└─────────────────────┬───────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 7: Ink Scripting (NPCs and Cutscenes)                    │
│ Output: Complete Ink files with dialogue and choices           │
└─────────────────────┬───────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 8: Scenario Review and Validation                        │
│ Output: Complete, validated scenario ready for implementation  │
└─────────────────────────────────────────────────────────────────┘
```

## Prompt Files

| File | Stage | Purpose | Key Outputs |
|------|-------|---------|-------------|
| `00_scenario_initialization.md` | 0 | Select technical challenges and narrative themes | Challenge outline, theme options, ENTROPY cell selection |
| `01_narrative_structure.md` | 1 | Build the story arc | Three-act structure, key story beats, dramatic moments |
| `02_storytelling_elements.md` | 2 | Flesh out story details | Character voices, atmosphere, pacing, dramatic tension |
| `03_moral_choices.md` | 3 | Design player choices | Choice points, consequences, branching paths |
| `04_player_objectives.md` | 4 | Define player goals | Win conditions, narrative objectives, optional goals |
| `05_room_layout_design.md` | 5 | Design physical space | Room layout, challenge placement, puzzle design |
| `06_lore_fragments.md` | 6 | Create collectibles | LORE fragments, placement strategy, progressive revelation |
| `07_ink_scripting.md` | 7 | Write dialogue | Ink scripts for NPCs, cutscenes, interactive dialogue |
| `08_scenario_review.md` | 8 | Validate scenario | Consistency check, educational alignment, playability |

## How to Use This System

### For AI Orchestrators

If you're coordinating multiple AI agents to build a scenario:

1. **Run each stage sequentially** - Each stage builds on outputs from previous stages
2. **Pass outputs forward** - Ensure each agent receives relevant outputs from previous stages
3. **Allow iteration** - Some stages (especially review) may require going back to earlier stages
4. **Maintain context** - Keep a master document that accumulates all decisions and outputs

### For Single AI Sessions

If you're working with a single AI in a long conversation:

1. **Copy the prompt content** from each file into your conversation at the appropriate stage
2. **Maintain a working document** that captures outputs from each stage
3. **Reference universe bible** documents as needed throughout the process
4. **Iterate as needed** - Don't be afraid to revisit earlier stages if new ideas emerge

### For Human Designers

If you're using these prompts to guide your own design process:

1. **Use as checklists** - Each prompt contains key questions and considerations
2. **Adapt as needed** - Not every scenario needs every element
3. **Reference examples** - The universe bible contains example scenarios to learn from
4. **Start small** - Your first scenario doesn't need to use every advanced feature

## Required Context

Before starting, ensure you have access to:

### Essential Universe Bible Documents

- `story_design/universe_bible/01_universe_overview/world_rules.md`
- `story_design/universe_bible/02_organisations/safetynet/README.md`
- `story_design/universe_bible/02_organisations/entropy/README.md`
- `story_design/universe_bible/03_entropy_cells/README.md`
- `story_design/universe_bible/05_world_building/rules_and_tone.md`
- `story_design/universe_bible/09_scenario_design/framework.md`
- `story_design/universe_bible/10_reference/style_guide.md`

### Technical Documentation

- `docs/GAME_DESIGN.md` - Core game mechanics
- `docs/ROOM_GENERATION.md` - Room layout rules and constraints
- `docs/INK_INTEGRATION.md` - Ink scripting guide
- Technical challenge specifications (varies by scenario type)

## Output Structure

Each stage should produce structured outputs in this format:

```
scenario_designs/[scenario_name]/
├── 00_initialization/
│   ├── technical_challenges.md
│   └── narrative_themes.md
├── 01_narrative/
│   └── story_arc.md
├── 02_storytelling/
│   ├── characters.md
│   ├── atmosphere.md
│   └── pacing.md
├── 03_choices/
│   └── moral_choices.md
├── 04_objectives/
│   └── player_goals.md
├── 05_layout/
│   ├── room_design.md
│   └── challenge_placement.md
├── 06_lore/
│   └── lore_fragments.md
├── 07_ink/
│   ├── opening_cutscene.ink
│   ├── closing_cutscene.ink
│   ├── npc_dialogues.ink
│   └── choice_moments.ink
├── 08_review/
│   └── validation_report.md
└── SCENARIO_COMPLETE.md (master document)
```

## Quality Standards

All scenarios must meet these criteria:

### Educational Requirements
- Map to specific CyBOK knowledge areas
- Teach genuine cybersecurity concepts
- Avoid teaching bad practices or unrealistic techniques
- Progressive difficulty appropriate for target audience

### Narrative Requirements
- Consistent with universe bible tone and lore
- Character voices match established profiles
- World rules respected throughout
- Satisfying story arc with clear beginning, middle, end

### Game Design Requirements
- Respect room generation constraints (see `docs/ROOM_GENERATION.md`)
- Challenge difficulty appropriate for scenario tier
- Clear player objectives
- Multiple solution paths where possible
- Failure states that teach rather than frustrate

### Technical Requirements
- Valid Ink syntax
- Proper LORE fragment JSON structure
- Room layouts within Grid Unit constraints
- Challenge placement follows technical specifications

## Tips for Success

### Start with Constraints
- Pick your technical challenges first - they're the hardest constraint
- Let the challenges inform the narrative, not vice versa
- Choose an ENTROPY cell whose philosophy aligns with your challenges

### Build Incrementally
- Don't try to design everything at once
- Each stage adds detail to the previous stage
- It's OK to go back and revise earlier stages as new ideas emerge

### Use Examples
- Reference the example scenarios in `story_design/universe_bible/09_scenario_design/examples/`
- Look at existing ENTROPY cells for inspiration
- Study character profiles for dialogue voice

### Focus on Player Experience
- What will the player learn?
- What will the player feel?
- What choices will matter to the player?
- How will the player know they're making progress?

### Iterate Through Review
- Stage 8 (review) often reveals issues
- Don't be afraid to cycle back to earlier stages
- Small refinements make big differences
- Test your scenario logic before finalizing

## Common Pitfalls to Avoid

1. **Challenge-narrative mismatch** - When the story doesn't support why the technical challenge exists
2. **Overly complex layouts** - Trying to fit too many rooms/challenges into one scenario
3. **Inconsistent character voices** - NPCs that don't sound like their established profiles
4. **Unclear objectives** - Player doesn't know what they're trying to accomplish
5. **Dead-end choices** - Moral choices that don't actually affect anything
6. **LORE overload** - Too many fragments or fragments that don't add value
7. **Exposition dumps** - Telling instead of showing through gameplay
8. **Rule violations** - Breaking established world rules or technical constraints

## Getting Help

If you encounter issues:

1. **Consult the universe bible** - Most questions are answered there
2. **Review example scenarios** - See how others solved similar problems
3. **Check technical docs** - Especially for room generation and Ink syntax
4. **Simplify** - When in doubt, reduce scope
5. **Iterate** - First draft doesn't need to be perfect

## Version History

- v1.0 (2025-01-17) - Initial prompt system creation
  - 9-stage development pipeline
  - Comprehensive prompts for each stage
  - Integration with expanded universe bible

---

**Ready to build your first scenario?** Start with `00_scenario_initialization.md` and work through the stages sequentially. Good luck, and remember: the best scenarios teach cybersecurity while telling compelling stories!
