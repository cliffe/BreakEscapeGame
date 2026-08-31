# Mission 8 "The Mole" — Alignment & Advancement Plan

> Produced by the mission-alignment-plan skill. 2026-08-31. **Plan only — not yet implemented.**
> Measured against: `m01_first_contact`, `m02_ransomed_trust`, `m07_architects_gambit`. Reviewed: 1 round (planner → adversarial reviewer → reconciled).

---

## Executive summary

m08 has a thorough design README and a `scenario.json.erb`, but that erb is written to a **superseded schema** (rooms as an array, flat `objectives`, `startingInventory`, `dialogue`/`behavior` NPC blocks, `vmConfig`, `flag-station`/`requiredFlags`, per-room `image`) and **zero ink exists**. It was also authored under the abandoned soft-ENTROPY framing, where Nightshade reads as a sympathetic philosopher. This is a scenario **rebuild** plus a full ink authoring effort (~14 files), not a polish pass.

Two things block the plan from being executable as-is and need a decision before Phase 1:

1. **The VM does not exist.** `mission.json` names `ctf/such_a_git.xml`, but no SecGen checkout is reachable and no scenario summary exists for it. The four "flags" in the erb are literal placeholders `flag1`–`flag4`. Someone must fetch, pick, or author the VM scenario.
2. **Every sprite and room image m08 names is invented.** All seven NPC sprites (`director_cross`, `agent_nightshade`, …) and all nine room `image` PNGs have zero matches in `public/break_escape/assets/`. The rebuild must re-map every NPC onto a real archetype and every room onto an existing room `type` / tilemap.

Continuity with m07 is also broken: m08's README branches on an ERB var `@mission_7_choice ∈ {infrastructure, data, supply_chain}` that does not exist. m07 exposes a **runtime global** `team_assignment ∈ "" | "fracture" | "trojan_horse" | "meltdown"`, and it is not yet persisted across missions.

---

## Validator error — root cause (confirmed)

`ruby scripts/validate_scenario.rb scenarios/m08_the_mole/scenario.json.erb` renders the ERB fine and reports exactly **one** structure error:

> `'rooms' must be a JSON object {}, not an array []`

`scripts/generate_dungeon_graph.rb:108` is `rooms.each do |room_id, room|`; on an array `room` binds to `nil`, and `:109` `room['locked']` raises the reported `undefined method '[]' for nil:NilClass`. Same root cause.

**Fix:** `scenario.json.erb:48` `"rooms": [ … ]` → `"rooms": { "<room_id>": { … } }`, matching `m07/scenario.json.erb:554`.

`music`, staged aims, and `conclusionScreen` are **warnings/suggestions only** (`validate_scenario.rb:1275`, `:2283`) — the schema `required` is just `["scenario_brief", "startRoom", "rooms"]`. So a Phase 1/Phase 2 split is legitimate, but Phase 1's gate must be stated as **"zero errors"**, not "green", because a long warning tail will remain.

### Schema conversion table

| m08 current (obsolete) | Current schema (m07/m02) |
|---|---|
| `"rooms": [ {id, exits:{dir:id}} ]` | `"rooms": { id: { type, door_sign, connections:{dir:id} } }` |
| **absent** | `"scenario_brief"` (required), `"show_scenario_brief": "on_resume"`, `endGoal`, `startPosition` |
| `playerStart:true` on a room | top-level `"startRoom": "main_lobby"` |
| top-level `name`/`description`/`author` | not schema properties — drop or relocate |
| room `"image": "safetynet_lobby.png"` | **dead field** — delete; rooms bind via `type` → `public/break_escape/assets/rooms/*.tmj` |
| NPC `dialogue:"x"`, `behavior:{type:"stationary"}`, invented `sprite` | `npcType`, `storyPath: ".../x.json"`, `currentKnot`, `spriteSheet: "male_spy"`, `spriteTalk: "assets/characters/male_spy_talk.png"`, `voice`, `position` |
| `eventMapping` (singular) | `eventMappings` (plural) |
| `objectives` with `completionVariable`/`completionValue` | staged aims: `aimId`/`title`/`status`/`unlockCondition`/`tasks[]` |
| `startingInventory` | `startItemsInInventory` |
| item `type:"flag-station"` + `requiredFlags` | top-level `"flags": { "<vm>": vm_flags_json(...) }` + `submit_flags` tasks with `targetFlags`/`targetCount` + index-parallel `flagRewards` |
| `vm-launcher` with `vmConfig:{scenario,…}` | `vm-launcher` bound to the declared `flags` host |
| container `lockType`/`lockCode`; room `locks:[{type,…}]` | current lock/container schema (`README_scenario_design.md`) |
| **absent** | `narrator`, `music`, `player` blocks |

---

## Current-state assessment — ten-row rubric

| # | Dimension | Current state | Gap | Target end-state | Anchor |
|---|---|---|---|---|---|
| 1 | **Canon & stakes** | Soft framing: "emotional core", "non-hostile", Nightshade as sympathetic philosopher; `philosophy_book` + `nightshade_profile` risk endorsing "entropy is inevitable". Stakes abstract ("lives were lost"). | **Blocker** | Hard canon: the m07 leak got named SAFETYNET agents and civilians killed at the crises the team couldn't cover, and burned the on-the-ground agent. Nightshade is a true believer **and** a knowing accessory. The philosophy is presented and named as rationalisation; debrief/HaX/credits condemn the actions regardless of player stance. | `m01/ink/m01_derek_confrontation.ink`; `m07/ink/m07_npc_james_mercer.ink`; `universe_bible/02_organisations/entropy/philosophy.md` §Propaganda vs. Operational Reality |
| 2 | **Aims & objective staging** | 7 flat `objectives` on the old `completionVariable` shape; no unlock chain; no `missionConclusion`/`requiresCompleted`/`conclusionScreen`. Titles leak the answer ("Confront Agent Nightshade", "Obtain Tomb Gamma coordinates from Nightshade"). | **Blocker** | 6 staged aims, `status:"locked"` + `unlockCondition:{aimCompleted:…}`, spoiler-safe action titles, all tasks `active`, lore tasks `optional:true`, final aim `missionConclusion:true` + `requiresCompleted:[…]` + `conclusionScreen:{type:"bond_visualiser"}`. | `m07/scenario.json.erb:259–483`; `README_scenario_design.md` §Objectives System |
| 3 | **Agent HaX support hub** | Two flat phone contacts (`m08_phone_0x99`, `m08_phone_director`). No hub, no progress gating, no field guides. | **Major** | `m08_phone_agent_0x99.ink` with a `hub` knot, choices gated on progress globals (`{found_x and not x_discussed}`), per-stage VM hints, 4–5 field guides via `#give_item:lab-workstation:<key>` gated `{x_guide_offered and not x_guide_hint_given}`, KO-acknowledgement lines pointing at redundant sources. | `m07/ink/m07_phone_agent_0x99.ink` (`=== hub ===` :114, gating :171–179, `#give_item` :329–373); `m02/ink/m02_phone_agent0x99.ink` (`=== support_hub ===` :101, VAR pairs :15–42) |
| 4 | **Ink / dialogue craft** | **Zero ink files.** `ink/` does not exist. ~14 needed, including three dialogue ids referenced by the erb with no design behind them (`m08_receptionist_ai`, `m08_background_analyst`, `m08_background_agent`). | **Blocker** | Full set in house style: inline `Speaker:` prefixes matching NPC `id`/`displayName` exactly, `Narrator:` beats, hub structure, first-person consequential choices, `#exit_conversation`/`#complete_task`/`#set_global`. No CYOA terminals, no combat in ink. | `m07/ink/*.ink`; `README_ink_best_practices.md`; `story_dev_prompts/07_ink_scripting.md` |
| 5 | **Moral choices & consequences** | Three choices named in the README (Nightshade's fate / expose SAFETYNET / sympathise with the philosophy). No wiring. `nightshade_arrested`, `nightshade_triple_agent`, `safetynet_exposed` are declared but nothing writes them. | **Major** | Fate via a **non-KO-able terminal** `onComplete.setGlobal` → `nightshade_arrested` XOR `nightshade_triple_agent`. `debrief_stance` recorded in the debrief, convergent on outcome. All feed the debrief branches + conditional `credits[]`. | `README_ink_best_practices.md` §Making Choices Matter; `m07/scenario.json.erb:452–473` |
| 6 | **Music** | None. | **Major** | `"music": { "events": [...] }`: arrival/paranoia, VM breakthrough, revelation (`room_entered:interrogation_room`), confrontation resolved, `conversation_closed:m08_closing_debrief` → victory + conditional `credits[]`. | `m07/scenario.json.erb:105–204` |
| 7 | **Rooms & layout** | 9 rooms. `exits` reciprocity is actually consistent. But no `type`, no grid sizing, nine invented `image` PNGs, never through `predict_door_sides.py`. All NPCs stationary — the arc's "paranoia mechanics" are unimplemented, no guard-evasion space. | **Major** | Every room mapped to a real `type` from the closed vocabulary with a valid GU size; overlap-free per `predict_door_sides.py`; `dungeon_graph.md`/`.html` regenerated. Optional counter-intel roamer with LOS (Open Decision 6). | `m07/scenario.json.erb:23–45`; `m07/CONTRACT.md` §2 |
| 8 | **Mechanics, VM & field guides** | Director keycard is required by the RFID lock but **never placed**. `flag-station`/`requiredFlags` with placeholder flag strings. `all_flags_submitted` referenced but never written. No field guides. **No reachable VM scenario.** | **Blocker** | VM resolved (see Open Decision 7); wired via top-level `"flags"` + `vm_flags_json` + `submit_flags` tasks + index-parallel `flagRewards` writing `flagN_submitted`/`all_flags_submitted`/`mole_identified`. Every lock has a redundant source. Field guides map to **real** lab-sheet slugs only. | `m07/scenario.json.erb:79–81`, `:315–334`, `:988+`; `README_scenario_design.md` §Wiring VM flags |
| 9 | **NPC KO resilience** | Nightshade is **three** NPC entries (suspect / `eventMapping` revelation / `appearCondition` confrontation). Required tasks `suspects_interviewed=3` and `nightshade_confronted` strand on any suspect KO. Director Cross KO strands both bookends. The opening cutscene rides on ATHENA, a normal room NPC. No `taskOnKO`/`globalVarOnKO`. | **Blocker** | Every KO-able NPC gets `globalVarOnKO` + `taskOnKO` or a HaX `eventMappings` bridge. Downed suspect still counts, or the aim completes off evidence. Confrontation reachable from evidence alone. Cutscene detached onto a hidden NPC. Background NPCs carry no globals or task completions. | `m07/scenario.json.erb:611–679`; `m07/CONTRACT.md` §6 Knockout latches |
| 10 | **Opening + closing bookends** | Opening: `timedConversation` on `receptionist_AI` with `once:true` but no `waitForEvent`/`skipIfGlobal`/`setGlobalOnStart` — and on a KO-able, wander-away-from-able NPC. Closing: no debrief ink, no debrief NPC, no `bond_visualiser`. | **Major** | Dedicated hidden cutscene NPC (`initiallyHidden`, `waitForEvent:"game_loaded"`, `skipIfGlobal:"briefing_played"`, `setGlobalOnStart`). `m08_closing_debrief.ink` + debrief NPC gated by the final aim; `conclusionScreen:{type:"bond_visualiser"}`. | `m07/scenario.json.erb:562–588`, `:474–481` |

---

## Target end-state

m08 validates with zero errors, renders a correct dungeon graph, and plays end to end: paranoid HQ arrival cutscene → staged investigation (three suspect interviews plus evidence correlation across nine rooms) → the VM challenge → evidence converges on Nightshade → interrogation-room confrontation on hard-canon terms → non-KO-able fate choice (`nightshade_arrested` XOR `nightshade_triple_agent`) plus a convergent stance → closing debrief with Director Cross → `bond_visualiser` with conditional credit lines. Downstream globals reach m09/m10 coherently because none of them is written by a KO-able conversation. Agent HaX is a reachable progress-gated hub with per-stage VM hints and field guides that point at lab sheets that actually exist. Every lock and every required NPC has a redundant route. `CONTRACT.md`, `SOLUTION_GUIDE.md`, `TESTING_WALKTHROUGH.md`, and `dungeon_graph.md` exist at m07's documentation bar.

---

## Phased plan

Every phase must leave the validator at zero errors before the next one starts.

### Phase 0 — Unblock (do this before touching the erb)

- **Resolve the VM.** `such_a_git` is not reachable anywhere in this repo or `~/Files/Projects/Code/Hacktivity`, and has no entry in `planning_notes/mission_vms/secgen_scenario_summaries.md`. Fetch the SecGen scenario, substitute an available one, or author it. Extract the four real flag strings. Also fix the `mission.json` format: siblings use a bare name (`"rooting_for_a_win"`, `"putting_it_together"`), not `"ctf/such_a_git.xml"`.
- **Resolve assets.** Map all seven invented NPC sprites onto real archetypes in `public/break_escape/assets/characters/` (`male_spy`, `female_spy`, `female_security_guard`, `male_office_worker`, `female_scientist`, …) and all nine rooms onto existing `type` values / `public/break_escape/assets/rooms/*.tmj`. The room-type vocabulary is closed — expect either type reuse or new schema+tilemap work, and cost it.
- **Resolve `team_assignment` persistence** or accept the generic default branch (Open Decision 8).

**Acceptance:** a written mapping table (NPC → sprite archetype, room → type/tilemap) and a named, reachable VM with four real flags.

### Phase 1 — Schema rebuild + layout

- Rewrite `scenario.json.erb` to the current schema per the conversion table: ERB header with `require 'base64'` + `base64_encode`/`rot13` helpers and secret vars (`vault_pin = "2407"`, `archives_password = "TrustNoOne"`); **`scenario_brief` prose** + `show_scenario_brief`, `endGoal`, `startPosition`, `startRoom`; `narrator` and `player` blocks; `flags` (real strings from Phase 0); rooms as a keyed object with `type`/`door_sign`/`connections`/GU size and the `image` fields deleted; NPC blocks converted to `npcType`/`storyPath`/`currentKnot`/`spriteSheet`/`spriteTalk`/`position`; items, containers, and locks to current schema; `eventMapping` → `eventMappings`; drop top-level `name`/`description`/`author`.
- Place the **Director keycard** as a real item plus a redundant RFID route (clone via a printer/workstation object) so `server_room` is never unreachable.
- Add a grid-layout comment block (like `m07:23–45`), run `scripts/predict_door_sides.py`, resolve overlaps.
- Stub `objectives` minimally so the file validates; full staging is Phase 2.
- Create `scenarios/m08_the_mole/ink/` with compiled placeholder stubs so every `storyPath` resolves.

**Acceptance:** `validate_scenario.rb` reports **zero errors**; `predict_door_sides.py` reports no overlap; `generate_dungeon_graph.rb` runs clean.
**Verify:** `validate-scenario`, `break-escape-dungeon-graph`.

### Phase 2 — Aims staging, music, bookends

- Author `CONTRACT.md` on m07's structure: fixed ids for NPCs/rooms/objects, the lock table with redundant sources, VM/flags, global variables (act/state/KO/lore), task ids, attribution rules.
- Replace `objectives` with six staged aims:
  1. `get_the_briefing` — "Report In And Take The Brief"
  2. `work_the_suspects` — "Interview The Three Suspects" (per-suspect KO fallback)
  3. `get_onto_the_repo` — "Get Into The Internal Repository" (`server_room` + flags 1–2)
  4. `correlate_the_evidence` — "Correlate The Leak Timeline" (flags 3–4 + key evidence; sets `mole_identified`)
  5. `confront_the_mole` — "Confront The Mole"
  6. `close_the_investigation` — "Close The Investigation" — `missionConclusion:true`, `requiresCompleted:[…]`, `conclusionScreen:{type:"bond_visualiser"}`
- Lore/optional tasks `optional:true`; all tasks ship `status:"active"`.
- Add `music.events` with the beat map and conditional `credits[]` referencing `nightshade_arrested`/`nightshade_triple_agent`/`debrief_stance`/`team_assignment`/`tomb_gamma_location_known`/`database_theft_understood` and the KO latches.
- **Detach the opening cutscene from ATHENA** onto a dedicated `opening_briefing_cutscene` NPC (`initiallyHidden`, `waitForEvent:"game_loaded"`, `skipIfGlobal`, `setGlobalOnStart`). Add the `closing_debrief` NPC.

**Acceptance:** validator clean; aims reveal in sequence in a dry run; `bond_visualiser` opens only after the final aim's `requiresCompleted` is satisfied.
**Verify:** `validate-scenario`, `scenario-design-review`.

### Phase 3 — Full ink set + HaX hub + field guides + voice

Ink files under `scenarios/m08_the_mole/ink/`:
`m08_opening_briefing`, `m08_receptionist_ai`, `m08_director_cross`, `m08_agent_0x99`, `m08_phone_agent_0x99` (**the hub**), `m08_phone_director`, `m08_suspect_cipher`, `m08_suspect_phantom`, `m08_suspect_nightshade`, `m08_nightshade_revelation`, `m08_nightshade_confrontation`, `m08_closing_debrief`, plus `m08_background_analyst` and `m08_background_agent` (short barks that carry **no** globals or task completions).

- Hub mirrors `m07_phone_agent_0x99.ink`: `VAR` mirrors of synced globals, `first_call` then `hub`, gated topic choices, per-stage VM hints, guide delivery gated `{x_guide_offered and not x_guide_hint_given}`, KO-acknowledgement lines, a moral sounding-board knot that names the m07 dead.
- Scenario wiring: `itemsHeld` lab-workstation guides with `labUrl`, exposure-gating `eventMappings` on the HaX NPC.
- **Author `voice` blocks** for all ~8 speaking NPCs (`name`/`style`/`language: en-GB`), per `m07/scenario.json.erb:565–601`. This is real writing work and is easy to forget.

**Acceptance:** `scripts/compile-ink.sh` compiles everything with no errors; `scripts/verify_ink_roundtrip.py` clean; every `storyPath` resolves; attribution matches NPC ids exactly.
**Verify:** `npc-dialog-review` per NPC, `validate-scenario`.

### Phase 4 — Canon reframe + choice wiring

- Rewrite the stakes surfaces (`tactical_board`, `historical_leaks`, `database_catalog`, `nightshade_profile`, `philosophy_book`, `deep_state_manual_fragment`, `encrypted_file`) for hard canon.
- `m08_nightshade_confrontation.ink`: Nightshade argues to the end; the mission never agrees. Model on `m07_npc_james_mercer.ink`.
- Wire the fate choice via a terminal `onComplete.setGlobal` — never a KO-able conversation. Record `debrief_stance` in the debrief, convergent on outcome. Conditional `credits[]` for every combination.
- Create the bible entries (see Canon section — these are creations, not updates).

**Acceptance:** every choice combination produces a coherent debrief and credits screen; no downstream global is set by a KO-able NPC; `scenario-design-review` finds no endorsement of the accelerationist premise.
**Verify:** `scenario-design-review`, `npc-dialog-review`.

### Phase 5 — VM wiring + docs + graph

- Populate `vm_flags_json` with the Phase 0 flag strings; `submit_flags` tasks with `targetFlags`/`targetCount`/`showProgress`; index-parallel `flagRewards` writing `flagN_submitted`, and `all_flags_submitted`/`mole_identified` on the last. Note `emit_event` is not usable here.
- Decide local `secgen/*.xml` copy vs stock reference (m01/m02/m04 ship local copies; m07 does not; m02 has both — they are not exclusive).
- Field guides → real slugs only.
- Replace all `@mission_7_choice` ERB (including in `README.md`, which itself contains ERB at `:491`) with ink/credits conditions on `globalVars.team_assignment` plus a graceful generic default.
- Reconcile `mission.json`: hybrid field set, `estimated_duration_minutes` missing, and `requiredPrecedingMissions: []` contradicts the arc's "M8–10 campaign-only for narrative integrity".
- Regenerate `dungeon_graph.md`/`.html`; write `SOLUTION_GUIDE.md` and `TESTING_WALKTHROUGH.md`; update `DEVELOPMENT_STATUS.md`.

**Acceptance:** `validate-scenario` clean including VM-flag checks; `walkthrough-scenario` critical path completes with no undocumented dependency; graph matches the walkthrough.
**Verify:** `validate-scenario`, `walkthrough-scenario`, `break-escape-dungeon-graph`.

---

## Canon & lore alignment

- **Hard canon is current doctrine, confirmed.** `story_design/lore_fragments/entropy_intelligence/README_ORGANIZATIONAL_LORE.md:13` and `ideology/IDEOLOGY_001_on_inevitability_manifesto.md:11` both carry superseding notes pointing at `universe_bible/02_organisations/entropy/philosophy.md` §Propaganda vs. Operational Reality. m08's reframe is correctly aligned with it.
- **Nightshade does not exist in the bible.** `grep -rln Nightshade story_design/` returns nothing — the character lives only in `season_1_arc.md`. "Recruited during training alongside 0x00" is bible **creation**: a new `04_characters` entry, not an update. Scope accordingly.
- **"Insider Threat Initiative" / "Deep State" appear only in the legacy monolith** `story_design/break-escape-universe-bible (1).md` (`:640, 651, 672, 674, 711–713, 1129, 1994, 2603`) — not in the structured `universe_bible/02_organisations/` or `03_entropy_cells/`. The cell has no structured-bible home yet.
- **The global threat database as m07's true objective** is in `season_1_arc.md` (~:750), not the bible. Also creation.
- **Doctrinal friction to resolve.** `season_1_arc.md` "Narrative Design Principles" #5 still reads *"No 'wrong' choices, only different consequences / Player philosophy respected regardless of choice"*, which sits awkwardly against the hard-canon "cost it heavily" framing in Open Decisions 2 and 3. Decide which governs before writing the confrontation.
- **m07 continuity, verified.** `m08/README.md:491–495` branches on `@mission_7_choice ∈ {infrastructure, data, supply_chain}`. m07 exposes `team_assignment ∈ "" | "fracture" | "trojan_horse" | "meltdown"` (`m07/CONTRACT.md` ~:232; `m07/scenario.json.erb:1333`, credits conditions `:163–167` including a never-committed branch). Zero value overlap. A rough mapping is `data → fracture` (voter records / Social Fabric, per `m07/planning/delegation_operations.md:332`), `supply_chain → trojan_horse`, `infrastructure → meltdown`; the economic branch has no m07 equivalent and should be dropped. **This mapping is a guess — confirm it.** m08 cannot read this at ERB render time; branch in ink and `credits[]`.
- **Campaign persistence is a live cross-mission gap.** `m07/ALIGNMENT_PLAN.md:359` open decision #5 is still open and explicitly out of m07's scope. Do not invent a second mechanism.
- **Field guides — the real lab-sheet inventory.** `HacktivityLabSheets/_labs/safetynet/` holds **13** sheets: `reconnaissance-and-network-mapping`, `scanning-and-exploitation`, `vulnerability-analysis-and-attack-surface`, `privilege-escalation`, `information-leakage-and-the-pin-oracle`, `ssh-access-and-linux-basics`, `ssh-access-and-bruteforce`, `bludit-cms-exploitation`, `distcc-exploitation`, `encoding-and-decoding-with-cyberchef`, `lockpicking`, `proftpd-exploitation-workflow`. A grep across all of `_labs/` for `gitlist|git-secrets` returns nothing — **no GitList, secret-scanning, sudo-specific, or log-analysis sheet exists**. Suggested set: Recon+Mapping, Scanning+Exploitation, Vulnerability Analysis, Privilege Escalation, Information Leakage, and — given the commit-history/leaked-credentials beat — `encoding-and-decoding-with-cyberchef`. Do not invent URLs.

---

## Open decisions for the user

1. **The VM.** `such_a_git` is unreachable and has no scenario summary. Fetch it, substitute an available SecGen scenario, or author it? This gates Phase 5 and shapes the whole Act 2 puzzle chain.
2. **Asset strategy.** Re-map the seven NPCs onto generic archetypes (`male_spy`, `female_scientist`, …), or commission bespoke sprites for Director Cross and Nightshade given they are recurring campaign characters?
3. **Room types.** The vocabulary is closed (`room_security` was only added in `a481ce77`). Accept type reuse across the nine rooms, or invest in new tilemaps?
4. **How dark do the m07-leak stakes go?** Named dead agents plus a bounded civilian figure tied to `team_assignment`, or a deliberately unquantified "people died"? *Recommendation: named agents plus a bounded figure, per m01/m07 precedent.*
5. **Does "sympathise with the philosophy" survive?** *Recommendation: keep it as a convergent `debrief_stance` — Nightshade's actions are condemned regardless.* Note the friction with arc principle #5.
6. **Triple-agent framing under hard canon.** Keep `nightshade_triple_agent` with explicit in-fiction discomfort and a stated m10 risk, or restrict the fate choice? *Recommendation: keep it, cost it heavily.*
7. **Keep or cut the secondary `safetynet_exposed` choice?** It is a whole extra consequence branch. *Recommendation: cut for the first pass.*
8. **Cell / programme naming.** "Insider Threat Initiative" (cell) vs "Deep State" (programme) — confirm and give it a structured-bible home.
9. **Guard-evasion roamer.** One counter-intel officer with an LOS cone (parity with m01/m02/m07), or social tension only? *Recommendation: one roamer.*
10. **`team_assignment` persistence.** Built before m08 ships, or does m08 launch on the generic default branch?

---

## Risks & regressions to guard

- **Scope.** Rebuild + ~14 ink files + hub + voice blocks + music + docs. `DEVELOPMENT_STATUS.md`'s estimate is far short. Phase it; each phase ends at zero validator errors.
- **Nightshade × 3 NPC entries.** A KO of suspect-Nightshade before the interview makes `suspects_interviewed=3` unreachable, and the `all_flags_submitted` revelation plus the `appearCondition` confrontation NPC can desync. All three need latches and an evidence-only fallback to `nightshade_confronted`.
- **Director Cross KO** strands the opening brief and the closing debrief — both need `skipIfGlobal` / phone fallbacks.
- **Lock redundancy.** Director keycard (currently unplaced), safe PIN `2407` (gates the interrogation key), and `TrustNoOne` (archives) are each single-sourced. Mirror m07's redundant-source table in `CONTRACT.md`.
- **`all_flags_submitted` / `mole_identified`** are referenced but nothing writes them — must come from `flagRewards`.
- **`@mission_7` ERB left anywhere** → nil crash or silently wrong branch. Grep `.md` as well as `.erb`; decide whether `README.md` keeps ERB at all.
- **`bond_visualiser` premature open** — the `victory` playlist auto-opens it; hold that cue to `conversation_closed:m08_closing_debrief`.
- **Ink attribution** must match NPC `id`/`displayName` exactly across 14 new files or lines render as narrator.
- **`mission.json` is a second, unvalidated surface** — hybrid field set, wrong `secgen_scenario` format, missing `estimated_duration_minutes`, and `requiredPrecedingMissions: []` contradicts the arc.
- **Don't invent lab-sheet URLs.** Only the 13 real slugs.

---

## Verification plan

1. **Every phase:** `validate-scenario` — zero errors before moving on.
2. **Phases 1 and 5:** `break-escape-dungeon-graph` (no nil error, graph matches the intended lock chain) and `scripts/predict_door_sides.py` (no room overlap).
3. **Phase 3:** `scripts/compile-ink.sh` + `scripts/verify_ink_roundtrip.py` on all ink; `npc-dialog-review` per NPC.
4. **Phase 4:** `scenario-design-review` — solvability, clue distribution, KO resilience, no endorsement of the accelerationist premise, choices wired end to end.
5. **Phase 5:** `walkthrough-scenario` — full critical path, run once per fate branch and once with each key NPC KO'd to prove completability.
6. **Continuity grep** across `.erb` and `.md`: `@mission_7`, `mission_7_choice`, `emit_event`, `requiredFlags`, `startingInventory`, `eventMapping"` (singular), `"image":` — all must be gone.
7. **Cross-doc:** `CONTRACT.md` ids match the erb, every ink `#complete_task`/`#set_global` tag, `SOLUTION_GUIDE.md`, and `TESTING_WALKTHROUGH.md`.

---

# Implementation Log — 2026-08-31 (first pass built)

The plan above is the full picture. This section records what has actually been
built and the decisions the user resolved.

## Decisions resolved by the user
- **VM:** confirmed real — `SecGen/scenarios/ctf/such_a_git.xml` (GitList 0.4.0
  argument-injection RCE → stashed creds → home-dir flag → sudo apt-get → root).
  SecGen target `system_name` is `web_server`. `mission.json` `secgen_scenario`
  set to `such_a_git`.
- **Assets:** use existing sprites and existing room types now; a new-asset plan
  is documented below for later.
- **Tone:** written as an engaging TV-thriller — snappy dialogue, hard-canon
  stakes (two named-in-fiction agents dead from the m07 leak), Nightshade's
  "entropy is inevitable" argued and explicitly rejected, never endorsed.

## What is built and green
- `scenario.json.erb` rebuilt to current schema. `validate_scenario.rb`:
  **zero errors**, schema passes, room layout overlap-free, dungeon graph
  generates. Critical path: Brief → Repository → Correlate → Confront → Close.
- 12 ink files, all compile clean (no warnings): opening briefing, ATHENA
  console, Director Cross brief, HaX phone **hub** (progress-gated + 5 field
  guides), HaX in person, three suspect interviews, the confrontation (fate
  choice), closing debrief (branches + `debrief_stance`), two background barks.
- Staged spoiler-safe aims + `missionConclusion` + `bond_visualiser`.
- Event-driven `music` block; narrator voice; per-NPC `voice` blocks.
- VM flags wired: top-level `flags.web_server` + index-parallel `flagRewards`
  → `flagN_submitted`; HaX `eventMappings` derive `found_*`,
  `all_flags_submitted`, `mole_identified`.
- KO resilience: `globalVarOnKO` + `taskOnKO`/HaX-bridge on every named NPC;
  the fate is set at a **terminal**, not a conversation; opening + closing are
  hidden cutscene NPCs.
- Lock chain with redundant sources (rfid keycard | printer; password post-it |
  ATHENA; pin record | ATHENA; key safe | lockpick).

## Room + sprite mapping used now (existing assets)
| m08 room | room type used | note |
|---|---|---|
| main_lobby | `room_reception` | reception fits |
| director_office | `room_ceo` | corner-office feel |
| operations_floor | `room_office` | open analyst floor |
| intel_analysis | `room_control_1x2gu` | wall-screen control room |
| server_room | `room_servers` | rfid |
| security_archives | `room_archive_1x2gu` | password vault |
| cryptography_lab | `room_lab` | Nightshade's domain |
| interrogation_room | `room_security` | stark, recorded |
| break_room | `room_break` | — |

| m08 NPC | sprite used | note |
|---|---|---|
| ATHENA (cutscene + console) | `female_office_worker` | placeholder for an AI |
| Director Cross | `female_spy` | recurring — bespoke candidate |
| Agent HaX (phone) | `female_hacker_hood` headshot | matches handler |
| Agent HaX (in person) | `female_hacker_hood` | — |
| Nightshade (suspect/confront) | `male_hacker_hood_down` | recurring — bespoke candidate |
| Cipher | `male_nerd` | fits the awkward-genius red herring |
| Phantom | `male_spy` | charismatic coordinator |
| background analyst / off-duty | `female_office_worker` / `male_office_worker` | — |

## New rooms & sprites — improvement plan (later WP)
The mission plays on stock assets, but four beats would land harder with bespoke art:
1. **The Citadel lobby** — a distinct SAFETYNET HQ reception (biometric gates,
   a wall seal, red-alert lighting) instead of the generic `room_reception`.
   The whole mission's paranoia tone starts here.
2. **Interrogation room** — a purpose-built one-table, two-chair, one-way-glass
   room with visible recording gear. `room_security` reads as an office;
   the confrontation is the emotional climax and deserves its own space.
3. **ATHENA** — an AI receptionist should not be a female office worker. Options:
   a hologram/console sprite, or a stylised avatar. Low priority but it is the
   first face the player sees.
4. **Director Cross & Nightshade portraits** — both recur across the season
   (Cross first appears here; Nightshade returns if turned triple agent in
   m09/m10). Bespoke character sprites + talk portraits would pay off across
   three missions, not one. Follow the `character-talk-animation` skill and the
   PixelLab pipeline (flat subscription — no marginal cost).

Sequencing: ship on stock art now; commission the interrogation room and the
two recurring-character portraits first when art time is available, since they
recur and carry the mission's biggest scenes.

## Design review applied (2026-08-31)
`scenario-design-review` run; all Should-fix and polish items applied:
- **KO of the confrontation NPC now resolves coherently to arrest** (eventMapping
  on `agent_0x99` keyed to `nightshade_confront_ko` sets `nightshade_arrested` +
  `tomb_gamma_location_known`), so the debrief never sees an unset fate. Matches
  the m03 "moral choice in conversation + taskOnKO" idiom rather than a terminal
  redesign.
- **`taskOnKO: take_the_debrief`** added to `closing_debrief`.
- **Backgrounds** added to both person-chat cutscenes (interrogation `hq2`,
  debrief `hq3`) — validator warnings cleared.
- **Field guides now exposure-gated**: `agent_0x99` eventMappings set
  `<x>_guide_offered` when the player first hits each obstacle
  (server-room entry, VM interact, flags 1–3); hub choices gated
  `{x_guide_offered and not x_guide_hint_given}`.
- **`You:` echo antipattern folded** in the confrontation choices (the player's
  line now lives in the bracket).
- **HaX pointer** added for the safe/PIN → interrogation-key chain, plus an
  opening `timedMessages` beat.

## Still open / next work packages
- **CONTRACT.md** not yet written (WP2) — the identifier contract this file
  references. Write before further edits.
- **VM flag order** against a real `flags_by_vm['web_server']` build STILL NEEDS
  VERIFICATION — the four fallback strings render fine standalone, but the
  narrative-to-flag mapping (RCE → creds → home → root) must be confirmed against
  an actual SecGen build so the right flag completes the right task.
- **Info-leak field guide** points at `information-leakage-and-the-pin-oracle`
  (closest real sheet; no git-secrets sheet exists). Swap if a better-matched
  sheet is authored.
- **SOLUTION_GUIDE.md / TESTING_WALKTHROUGH.md** — not yet written.
- **`npc-dialog-review` / `walkthrough-scenario`** — not yet run on the build.
- **Bible entries** — Nightshade, the Insider Threat Initiative / Deep State
  cell, and the database theft are still only in the arc file, not the
  structured `universe_bible/`. Create when the canon pass happens.

---

# Dialogue pass — 2026-08-31 (npc-dialog-review applied)

Review run; the mechanical layer was already clean (12/12 compile, all hubs pass
`loopcheck`, no starved knots). The findings were all depth/craft, and the four
user directives drove this pass.

## Applied
- **Director Cross → Director Magnus Netherton** (canon fix + continuity). Cross
  was invented by the old draft; Netherton is the canonical SAFETYNET director
  (universe bible, m01, m07) and the familiar face who ran m07 and vowed to find
  this leak. NPC id, storyPath, voice (Charon), sprite (`male_spy`), all prose
  and the `netherton_ko` latch converted. HaX is present throughout (phone hub +
  in-person break-room beat).
- **Investigation autonomy + accusation mechanic.** New layer over the intact
  critical path:
  - Netherton's briefing lets the player ask about each suspect and **state a
    working theory** (`suspect_theory` = cipher | phantom | nightshade).
  - Each suspect interview is now a real hub with an **alibi**, cross-references
    to the others, and an **accusation branch**. Accusing an innocent (Cipher /
    Phantom) after seeing their alibi hurts them and drops influence; accusing
    Nightshade gets a graceful, chilling non-confession.
  - Attention is rewarded: reading Phantom's notes unlocks the Crypto-Lab lead;
    reading the psych eval unlocks a Nightshade pressure line; his tells set
    `nightshade_suspected`, which the confrontation and debrief both pay back.
  - The VM flags remain the hard proof (unchanged critical path), but the player
    now *deduces and commits* rather than being handed the answer.
- **Depth.** Confrontation, briefing, and debrief substantially expanded
  (m08 ink 432 → 689 lines). Confrontation now has a topic hub (why / recruitment
  / the database theft / where the Architect is) before the fate choice; debrief
  branches on fate **and** the player's suspicion history (wrongly accused an
  innocent? deduced Nightshade cold? let the box carry it?) **and** stance.
- **Influence variables** added to all three suspects (`cipher_influence`,
  `phantom_influence`, `nightshade_influence`) with `# influence_increased/
  decreased` feedback tags.
- **`You:` echo antipattern** fully removed (folded into brackets).

All 12 files compile; scenario validates zero-error; every `#set_global` is
declared; all hubs pass `loopcheck`.

## Cross-mission mole seeding (directive) — plan, m07 seam already done
The player should not meet the mole cold. Status and plan:
- **m07 → m08: already seeded.** m07's closing has the mole intercept
  ("the leak was the agent") and Netherton's closing vow: *"we find out who has
  been reading."* m08 opens directly on that. No change needed — and it must stay
  spoiler-free (never name Nightshade in m07).
- **m02: already thematically seeded** — the "Asset #47" insider thread.
- **m03–m06: add a light, spoiler-safe drumbeat** (recommended next unit, one
  reviewed pass): in each closing debrief, one line where ENTROPY/the handler
  registers that the enemy "knew too much" / "were waiting" — the recurring
  *"how did they know?"* that pays off in m08. Do **not** name the mole, the
  cell, or Nightshade in any pre-m08 mission; the m08 reveal depends on it.
  This touches shipped missions, so it wants its own compile/validate/dialog-review
  pass rather than being bundled here.

## Docs & canon pass — 2026-08-31 (DONE)
- **CONTRACT.md** written — full identifier contract (NPCs, rooms, lock chain,
  VM/flags, aims/tasks, globals, consequence wiring, KO resilience, attribution).
- **SOLUTION_GUIDE.md** and **TESTING_WALKTHROUGH.md** written (critical path,
  investigation layer, lock table, fate branches, KO matrix, automated checks).
- **Bible entries** — Agent 0x47 "Nightshade" added as a named placed insider in
  `03_entropy_cells/insider_threat_initiative.md`; the cell's "The Mole" scenario
  stub upgraded to canonical Mission 8 (SAFETYNET-internal, GitList, database
  theft, Tomb Gamma). Dr Chen continuity confirmed (`04_characters/dr_chen.md`).

## Still open (external / optional)
- **VM flag-order verification** against a real `flags_by_vm['web_server']` build
  (cannot be done without a live SecGen build; fallback strings render standalone).
- **Info-leak field guide** points at `information-leakage-and-the-pin-oracle`
  (closest existing safetynet sheet; no git-secrets sheet exists to point at).
- Live playtest of the mission and the m02–m06 per-speaker-voice briefings.
