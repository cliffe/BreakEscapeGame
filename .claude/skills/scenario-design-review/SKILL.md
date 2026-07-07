---
name: scenario-design-review
description: Full design review of a Break Escape scenario — runs the validator script then applies higher-level design judgement from README_scenario_design.md. Trigger when the user explicitly asks for a "design review", "full review", "deep review", or "scenario critique", or when the validate-scenario skill has already been run and the user wants to go deeper.
---

# Break Escape scenario design review skill

Two-phase check: (1) run the script, (2) apply design principles from `README_scenario_design.md` that require reading and reasoning about the scenario.

## Step 1 — run the validator script

```bash
ruby scripts/validate_scenario.rb <scenario_path>
```

Work from the repository root (`/home/cliffe/Files/Projects/Code/BreakEscape/BreakEscape`).

**Present the output in four clearly labelled groups — omit any group that is empty:**

| Symbol | Meaning | How to present |
|--------|---------|----------------|
| ❌ INVALID | Must fix before the scenario will work | List all, bold the path |
| ⚠️ WARNING | Should fix; may cause subtle bugs or broken task counters | List all |
| ✅ GOOD PRACTICE | Things already done well | Summarise in one sentence, don't enumerate |
| 💡 SUGGESTION | Optional improvements from `m01_first_contact` reference patterns | List only those that are relevant to this scenario's type and theme; skip generic feature-add suggestions if the scenario is already feature-complete |

**Known false positive**: `puzzle_graph_and_with` pairs are used to represent AND-gate requirements (e.g. dual-authorisation panels). These intentionally appear as multiple-solution warnings in the validator. Note this to the user rather than treating it as a real issue.

Also report the **dungeon graph summary line** printed by the validator:
- Node/edge counts (puzzle / story / integrated)
- Critical path

## Step 2 — design review against README_scenario_design.md

Before reading the scenario JSON, load `dungeon_graph.md` from the same directory (e.g. `scenarios/m01_first_contact/dungeon_graph.md`). This file contains all five Mermaid diagrams — Puzzle Graph, Story Aims, Story + Puzzle, Rooms, and Rooms & Contents — with prose descriptions of what each shows. Use it as your primary reference for the structural checks below; it is much easier to reason from than the raw scenario JSON.

Apply the following checks that the script cannot perform mechanically. Report findings as **CONCERN**, **OK**, or **N/A**.

Do **not** repeat or re-explain errors and warnings already reported in Phase 1. In the design sections below, you may cross-reference a Phase 1 finding (e.g. "see validator warning above") but do not restate the detail.

### 2a. Solvability trace

Walk the critical path from `startRoom` to the final objective:

- For every locked room or object, confirm the key/code/tool that unlocks it is reachable *before* the player needs it (i.e., not locked behind the same target).
- Flag any **circular dependencies** (key A inside box requiring key B, which requires key A).
- Flag any **soft locks** — situations where the player can reach a state with no forward progress.

### 2b. Clue distribution quality

- Are clue notes/phones/files spread across rooms, or clustered in one place?
- Are hints for codes/passwords placed in logically accessible locations before the lock that uses them?
- Are there readable items that exist but appear to serve no puzzle purpose (no `puzzle_graph_unlocks`, no connection to any task)?
- **Navigation-only items**: Are there notes/signs that only provide directional information (e.g. "Room A is north") with no puzzle value? These should be removed — the player can see room connections on the map.

### 2c. Educational coverage

Cross-reference the scenario's lock types against the README teaching objectives:

| Lock type | Teaches |
|-----------|---------|
| `key` + lockpick | Physical security, privilege escalation via tools |
| `pin` | Numeric access control, code hygiene |
| `password` | Credential security, password hygiene |
| `rfid` | Access credentials, badge/card security |
| `bluetooth` | Wireless attack surface |
| `flag` | Technical hacking challenges (VM-based) |

- Does the combination of lock types in this scenario meaningfully address its stated brief?
- If the scenario has a specific security topic (e.g. ransomware response, network segmentation), are the locks/puzzles thematically coherent rather than generic?

### 2d. Narrative structure

Based on `README_scenario_design.md §Designing Solvable Scenarios` points 8 and 9:

- **Opening cutscene**: Does the `startRoom` NPC's `timedConversation` adequately brief the player on their role and immediate objective? Is `skipIfGlobal` set so it doesn't replay on resume?
- **Closing debrief**: Is there a narrative endpoint (hidden person NPC with event-driven reveal, or equivalent)? Does the scenario have a clear win condition?
- **Ink dialogue arcs**: Are key NPCs wired to respond to the major plot events (via `eventMappings`)? Spot-check 2–3 event mappings that seem critical to narrative flow.

### 2e. Dungeon graph metadata completeness

Beyond what the validator checks mechanically:

- Are the major lock–key relationships represented in `puzzle_graph_unlocks` annotations, or is the graph sparse?
- Do `puzzle_graph_actions` nodes exist for the key NPC conversations that gate progress?
- Does the Integrated Graph (as described in the README) have bridge edges between puzzle nodes and story aims, or are the two layers disconnected?
- **Starting items**: If the scenario has `startItemsInInventory` with `puzzle_graph_unlocks` (e.g. a lockpick that opens doors), do these items appear in the Puzzle Graph as nodes sourced from the starting room? Missing starting items break the dependency chain — the graph shows locks with no visible way to open them.
- **VM challenge connections**: If the scenario has VM challenges (vm-launcher objects and submit_flags tasks), is there a connection chain in the Puzzle Graph from `lock_vm_launcher_*` → `vm_access_terminal` (or equivalent) → first VM challenge node (`vmch_*`)? Disconnected VM challenges appear as isolated subgraphs.
- **Backwards edges**: In the Puzzle Graph, check for edges flowing FROM locked rooms back TO the starting room or unlocked areas (e.g. `it_department --> reception_lobby` when `it_department` is locked). These create layout problems and suggest the graph generator didn't skip connections from locked sources. The correct pattern is: unlocked room → door lock → locked room (forward only).

Note: the validator already flags missing `puzzle_graph_unlocks` on clue items inside locked containers and on `submit_flags` tasks with `onComplete`. Focus here on whether the *overall graph tells the right story* at a design level.

### 2f. Room layout and dead ends

- Are any rooms reachable but containing nothing useful (no objects, no NPCs, no connections to further rooms)? These waste player time.
- Do room types (`room_office`, `room_servers`, etc.) match the scenario's physical setting and theme?
- Are there rooms that a player would naturally visit last but that contain early-game clues, creating an awkward backtracking requirement?
- **World-space overlaps (automated)**: The validator script now checks room-layout geometry. Rooms have no explicit world position — the engine lays them out breadth-first from `startRoom`, placing each room edge-to-edge with the *first* neighbour that reaches it, using each room type's real tilemap tile dimensions (not the optional JSON `dimensions` field, which the engine ignores). The validator ports this exactly and reports `⚠️ WARNING: Rooms 'A' and 'B' overlap in world-space layout …` for any pair whose bounding boxes collide. Report these under §2f. Common cause: mixing 2-GU-tall rooms with 1-GU-tall corridors in the same column, or a wide/tall room whose branch collides with another branch — so a fix usually means changing a connection direction, swapping a room type, or reordering which neighbour a room hangs off. The check passes on `m01_first_contact` and `cybok_heist` (known-good layouts) and flags real collisions in `m02_ransomed_trust`; a clean run prints `✓ Room layout geometry OK`. Note that a geometrically *reciprocal* connection graph (each edge mirrored) can still overlap — reciprocity is necessary but not sufficient, so trust this check over hand-reasoning about directions.

### 2g. Objectives scaffolding — the most common failure mode

This is the hardest thing to see when building a scenario piece by piece: the individual components work, but the aims/tasks/objectives layer doesn't actively guide the player toward what they need to do next.

**Check each aim in sequence:**

1. **Is it clear how the player discovers each task exists?** Tasks with `type: "npc_conversation"` or `type: "enter_room"` point somewhere concrete. `type: "manual"` tasks give the player nothing to go on unless something in the world (an NPC bark, a conversation, a readable item) directs them.

2. **Is there a "dead zone" between aims?** The transition between aims is the most vulnerable moment. When aim N completes, is aim N+1 already visible and populated with active tasks? Or does the player find themselves in a world where everything looks complete but the game hasn't told them what comes next? Check every `unlockCondition` — if an aim unlocks only after the previous one *fully* completes, ask whether the last task in the previous aim provides a clear handoff.

3. **Do task titles tell the player what to *do*, not just what *happened*?** A task called "Network isolated" describes an outcome; "Authorise network isolation at the dual-auth panel" tells the player their action. Review all task `title` fields for action-orientation.

4. **Are all the tasks within an aim actually completable in the order a player would naturally encounter them?** Walk the aim's task list and ask: could a player complete task 3 before task 1, leaving task 1 stranded as a confusing leftover? Optional tasks are fine to leave incomplete, but required tasks that become orphaned after the aim's main action feels done are a UX problem.

5. **Are barks and event-driven conversations used to narrate aim transitions?** When an aim completes and the next unlocks, does an NPC say something that acknowledges the shift and points forward? Or does the transition happen silently, leaving the player to discover the new tasks by opening the objectives panel? The best scenarios use NPC barks or auto-opening conversations to narrate each transition — the objectives panel confirms what the player already knows, rather than being the primary discovery mechanism.

6. **Does the aim description match the tasks inside it?** Read each aim's `description` field against its task list. If the description promises four things but the task list only has two visible tasks (the others being optional or gated), the player may feel they've missed something.

Produce a table:

| Aim | # required tasks | # with in-world pointer | Dead zone risk? | Bark/conversation at transition? |
|-----|-----------------|------------------------|-----------------|----------------------------------|

Flag any aim where more than half the required tasks are `manual` with no in-world pointer, or where the transition out of the aim leaves the player without a clear next instruction.

---

## Step 3 — produce a prioritised action list

After both phases, produce a short prioritised list:

**Must fix (blocks play)**
- All ❌ INVALID items from the validator
- **Win-condition failure modes first**: any field that controls the scenario's end state (e.g. `disableClose`, `setVisible` for the final NPC, `onComplete` triggers) that is schema-unknown, misspelled, or missing — list these at the top because they silently prevent the scenario from completing even when the player does everything right

**Should fix (degrades experience)**
- All ⚠️ WARNING items + any CONCERN findings from the design review
- Any aims with a dead-zone risk or missing in-world pointers (from §2g scaffolding table)

**Worth considering (polish)**
- Relevant 💡 SUGGESTION items + minor design review observations

Keep the action list concise — one line per item, grouped by priority. Do not repeat detail already given in the validator output or design review sections.
