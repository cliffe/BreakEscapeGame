---
name: validate-scenario
description: Runs the Break Escape scenario validator script and reports errors and warnings. Trigger when the user asks to "validate", "check the scenario", "run the validator", or "are there any errors". Lighter touch than scenario-design-review — focuses on what's broken rather than what could be better.
---

# Break Escape validate-scenario skill

Run the validator and report what's broken. Offer the full design review if it would add value.

## Step 1 — run the validator

The validator requires the path to the `scenario.json.erb` file, not the scenario directory. If the user passes a directory path, append `/scenario.json.erb` automatically.

```bash
ruby scripts/validate_scenario.rb <scenario_dir>/scenario.json.erb
```

Work from the repository root (`/home/cliffe/Files/Projects/Code/BreakEscape/BreakEscape`).

## Step 2 — report results

Present **only** the items that need attention:

**Errors (must fix)** — all ❌ INVALID items, each on its own line with the path bolded.

**Warnings (should fix)** — all ⚠️ WARNING items.

**Note on false positives**: `puzzle_graph_and_with` pairs intentionally representing AND-gate dual-authentication will sometimes trigger a "multiple solutions" warning. If the scenario uses dual-auth puzzle nodes, note this to the user rather than treating it as a real issue.

**Good practices and suggestions** — don't list these individually. Summarise ✅ in one line. For 💡 suggestions: mention the count, but briefly filter for relevance — skip generic feature-add suggestions if the scenario is already feature-complete or the suggestion doesn't fit the scenario's theme. E.g. *"4 good-practice confirmations. 9 suggestions (2 relevant to this scenario: …)."*

Then on its own line, report the dungeon graph stats:
> Graph: Puzzle 33 nodes / 40 edges · Story 5/4 · Integrated 38/56 · Critical path (4 hops): Aim A → Aim B → …

## Step 3 — offer the design review

After reporting, briefly assess whether a full `/scenario-design-review` would be worthwhile right now. Offer it — with the specific reason — if any of the following are true:

- The scenario has **no blocking errors** and the user seems to be preparing for playtest or finalisation — say *"No errors — want me to run a full `/scenario-design-review` to check objectives scaffolding and narrative coherence before playtesting?"*
- Aims have no tasks, tasks have `type: "manual"` with no NPC or room-entry wiring, or aim unlock conditions look gated with no clear handoff — say *"Objectives scaffolding looks thin — a `/scenario-design-review` would check whether players will know what to do next."*
- Critical path ≤ 2 hops or many disconnected nodes — say *"Short critical path / sparse graph — a `/scenario-design-review` would check whether the puzzle and story layers are well integrated."*
- The user just made structural changes (new aims, rooms, NPCs rewired) — say *"Structural changes — a `/scenario-design-review` would check overall coherence."*

If none of the above apply (e.g. there are still blocking errors to fix first), skip the offer.
