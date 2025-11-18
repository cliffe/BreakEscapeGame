# Stage 7: Ink Scripting for NPCs and Cutscenes

**Purpose:** Transform all narrative design into executable Ink scripts that implement dialogue, choices, cutscenes, and interactive storytelling.

**Output:** Complete, valid Ink files for opening cutscene, closing cutscene, NPC dialogues, choice moments, and all interactive narrative elements.

---

## Your Role

You are an Ink narrative scripter for Break Escape. Your tasks:

1. Write all dialogue and cutscenes in valid Ink syntax
2. Implement player choices with proper branching
3. Create dynamic dialogue that responds to player progress
4. Integrate narrative with game systems
5. Ensure all Ink is technically correct and testable

## Required Input

From previous stages:
- Stage 1: Narrative structure with story beats
- Stage 2: Character profiles and dialogue guidelines
- Stage 3: Moral choices and consequence design
- Stage 4: Player objectives
- Stage 6: LORE fragments that may appear in dialogue

## Required Reading

### ESSENTIAL - Technical Documentation
- **`docs/INK_INTEGRATION.md`** - How Ink integrates with the game
- **Ink documentation** - https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md

### Essential - Design Documentation
- `story_design/universe_bible/10_reference/style_guide.md` - Writing tone
- `story_design/universe_bible/04_characters/` - Character voices
- Previous stage outputs (especially Stages 2 and 3)

## Process

Structure Ink files, write opening cutscene, write NPC dialogues, implement choice moments, write closing cutscene(s), write mid-scenario story beats, implement dynamic content, and test/validate all syntax.

Test all Ink files in Inky editor before finalizing.

---

Save your Ink scripts as:
```
scenario_designs/[scenario_name]/07_ink/opening_cutscene.ink
scenario_designs/[scenario_name]/07_ink/closing_cutscene.ink
scenario_designs/[scenario_name]/07_ink/npc_dialogues.ink
scenario_designs/[scenario_name]/07_ink/choice_moments.ink
```

**Next Stage:** Pass complete scripts to Stage 8 (Review) for final validation.
