# m07 "The Architect's Gambit" — Rework & Implementation Plan

> Rewritten 2026-08-28 around the **delegation model** (v2). Supersedes the v1 alignment plan
> (kept at `.ALIGNMENT_PLAN.v1.bak`). Plan only — no scenario or ink changes made yet.
> Measured against m01_first_contact and m02_ransomed_trust.
> Inputs: mission-alignment-plan (planner + reviewer), scenario-design-review, npc-dialog-review.

## Why this is a rework and not a repair

m07 was built as four playable branches selected by an ERB variable evaluated at load. That
architecture cannot work, and the three reviews found the mission unstartable, unfinishable and
unspoken: seven NPCs mute, 54–92% of conversation paths ending in an ink runtime error, all 281
speaker attributions resolving to the wrong character, no voice blocks at all, and a debrief that
reports 240–385 dead after a perfect run. The full evidence is in the review sections at the end.

The decisive finding is not any single defect. It is that **three of the four branches were
decorative**: the supply-chain confrontation funnels nine of fourteen knots into one knot, the
corporate branch runs a nine-knot "split the mercenary from the ideologue" subplot that sets no
variable at all, and the closing debrief's four moral-reflection choices are interchangeable. Only
the infrastructure branch has real consequence wiring. Repairing four branches means writing three
of them properly for the first time.

**The pivot:** the player runs one operation. The four-way choice becomes a *delegation* — where to
send SAFETYNET's one available tactical team — and the other three crises resolve off-camera.

This is a better design, not just a cheaper one. "Which crisis do I play" is content-selection: every
option not taken is content not seen, which is why the current briefing is structurally lossy and the
player commits on 25% of the information. Delegation is resource allocation. The player reads all
four briefs *because* they need them to decide, nothing is skipped, and the dilemma moves from a
level-select to the thing the character is actually doing: triage under a clock, on incomplete
information, with the possibility of being wrong.

`planning_notes/overall_story_plan/season_1_arc.md` already frames M7's moral core as four
incommensurable harms — "Infrastructure = civilian lives (immediate) / Elections = democratic
integrity (systemic) / Supply Chain = long-term security (future) / Corporate = economic stability
(widespread) … **No right answer.**" The delegation model serves that intent more directly than the
original: the impossible choice was never which one to play, it was which ones to abandon.

**Salvage note.** The existing `planning/stage_0_option_a_infrastructure.md` describes a far better
mission than the one that was built — a Portland grid-control facility with RFID badges, biometrics,
six guards (two compromised), a cable vault, and four named operatives. The shipped scenario replaced
all of it with seven generic office rooms and zero locks. Much of this rework is **building the
mission its own planning doc already specifies.**

---

## The episode

### Premise

Four ENTROPY operations launch inside the same sixty seconds. SAFETYNET has one field agent in range
and one tactical team. The agent goes to the Pacific Northwest grid control facility outside Portland
— the only target where a person on site within thirty minutes changes the outcome. The team can
reach exactly one of the remaining three. **Two go unanswered.**

### The choice

Where does the team go? Three operations, three incommensurable harms, no arithmetic answer:

| Operation | Cell | If unanswered | The case for sending the team |
|---|---|---|---|
| **Fracture** — national voter registration DB + coordinated disinformation | Ghost Protocol + Social Fabric | 187M voter records exfiltrated; election legitimacy attacked | Irreversible. Records can never be un-leaked. No immediate deaths — which is exactly why it is easy to deprioritise, and why it is the one that changes a country. |
| **Trojan Horse** — TechForge update distribution, 840 vendor signing keys | Supply Chain Saboteurs | Backdoors in updates to 47M systems, dormant then activating | Strategic. This is the one that makes **every future mission harder**. Denies ENTROPY persistent access to healthcare, finance and government estates. |
| **Meltdown** — 47 zero-days against 12 Fortune 500 firms | Digital Vanguard + Zero Day Syndicate | Trading systems frozen, IP stolen, hospitals ransomwared | Immediate. Hospital ransomware means people die tonight, not in a projection. The only option with a body count on the same clock as the player's own. |

Deaths-now against democracy against every-mission-after. Whichever the player picks, the debrief
reports what happened at the two they didn't.

### The revision mechanic — curiosity pays

The projections in the briefing are **ENTROPY's own numbers**, fed to SAFETYNET deliberately as part
of the gambit. Inside the facility the player can find evidence that one of the three is badly
understated — the TechForge signing keys include healthcare and emergency-dispatch vendors, and the
dormancy period is a fraction of what was briefed.

Two independent sources, so a KO can't strand it: **Elena Rodriguez** (dialogue) and the
**coordination traffic on the NFS share** (VM flag 1). Finding either opens a redirect option on the
Agent HaX hub. **The redirect window closes at T-10** — a real decision under pressure, not a free
correction.

This is the fix for the concrete flaw the design review found: intel in the current build is handed
over unconditionally, so nothing can be missed and nothing is earned. Here, a player who investigates
saves people a player who rushes does not — without ever blocking the player who rushes.

### The twist — two turns, Act 3

**Turn one, at the SCADA terminal.** The coordination traffic shows all four operations running from
a single schedule with a single authority. The four crises are one operation. Mercer does not know he
is a diversion. *Telling him is a stance choice that changes his ending.*

**Turn two, in the cable vault and the debrief.** The Architect had SAFETYNET's deployment before
SAFETYNET made it. The mole did not leak the operation timing — the mole leaked **the agent**. The
gambit was never the attack. It was an experiment to learn how SAFETYNET triages when it cannot cover
everything. He now knows.

The player still saved 8.4 million people, and the debrief says so plainly. The victory is real. The
floor that drops out is the discovery that the victory was *measured*. That is the m01 Derek-monologue
shape and the m02 consequence-layer shape, and it hands M8 its mole hunt with the question already
sharpened.

### Beat sheet

| # | Beat | Where | What the player learns | New state |
|---|---|---|---|---|
| 1 | Briefing under way in the car | cutscene, on load | Four operations, one of you, one team. The three briefs. | `briefing_played` |
| 2 | **The delegation** | HaX hub | The choice is theirs and it is not close | `team_assignment` |
| 3 | Checkpoint — Morrison is dirty | Security Checkpoint | ENTROPY had inside help *here*. Small echo of a larger problem. | `morrison_resolved` |
| 4 | The floor is evacuating | Operations Floor | Scale: 8.4M people, 147 substations, the countdown is real | — |
| 5 | **Elena** — the one who was lied to | Server Room | She was shown different numbers. The briefing projections are ENTROPY's. | `elena_outcome`, `projection_revised` |
| 6 | The share — four ops, one schedule | Server Room (VM 1–2) | The crises are one operation | `found_coordination_traffic` |
| 7 | **Redirect window** (closes T-10) | HaX hub | Acting on what she told you costs you time you may not have | `team_redirected` |
| 8 | **Mercer** — the fanatic | SCADA Control | He has read the casualty projection and signed it | `mercer_fate`, `mercer_told_diversion` |
| 9 | Neutralise | SCADA Control (VM 3–4) | The grid holds | `grid_saved` |
| 10 | The vault — how they got in | Cable Vault | Tomb Gamma, and the mole leaked *you* | `found_tomb_gamma`, `found_mole_evidence` |
| 11 | **Debrief** | SCADA Control | What happened at the three. What the Architect was actually doing. | `mission_complete` |

Eight of eleven beats recontextualise the one before. That is the episodic shape the mission is
missing today, where the four briefs are read in a menu and the debrief absolves the player of
everything regardless of what they chose.

---

## Cast

Applying the agreed **three cold, one conflicted** rule *within* the branch — sympathy at the junior
asset, fanaticism at the top, exactly as `story_design/universe_bible/02_organisations/entropy/philosophy.md:31,34`
requires ("players meet a fanatic… not negotiate an ideology"; "classic villains who have read philosophy").

| NPC id | displayName | Role | Temperature |
|---|---|---|---|
| `james_mercer` | **Dr. James Mercer** | Critical Mass cell lead, "Blackout". Canon (`critical_mass.md:26`): ex-DoE grid engineer, professorial, obsessed with elegant cascading failures, "genuinely believes he's teaching society a necessary lesson". | **Cold.** Holds the same casualty sheet the player is holding and defends it. Not recruitable — the player picks a *stance*, which the debrief records. |
| `elena_rodriguez` | **Elena Rodriguez** | Critical Mass electrical engineer. Believed it was a six-hour demonstration with nobody hurt. Mercer showed her different numbers. | **Conflicted.** Where the sympathy lives. Turns on seeing the real projection. Source of the revision intel. |
| `jake_morrison` | **Jake Morrison** | Facility security guard, compromised. First evidence of insider help. | **Cold, hostile.** The evade-or-drop obstacle. |
| `thomas_park` | **Thomas Park** | Critical Mass sabotage tech in the cable vault; will cut backup power. | **Cold, hostile.** Second pressure point, guards the vault. |
| `agent_0x99` | **Agent HaX** | Handler (phone). Progress-gated support hub, field guides, the delegation and redirect interface. | Ally. Visible strain — she is watching three operations she cannot help. |
| `director_netherton` | **Director Magnus Netherton** | Canon SAFETYNET Director of Field Operations (`04_characters/safetynet/director_netherton.md`). Delivers the briefing and takes the debrief. | Ally. **Replaces the invented "Director Patricia Morgan"** (zero hits in the universe bible; near-collides with Patricia Wells in m01). |
| `the_architect` | **The Architect** | Comms only, per `masterminds/the_architect.md:11` ("Never directly encountered… exists as intercepted communications"). Taunts on the countdown. | Cold. |

**Cut:** "Marcus Chen" in both its m07 uses (the name is canonically a Supply Chain Saboteurs member
*and* a possible 0day alias — m07 spent it twice more on two different people), "Adrian Cross",
"Victoria 'V1per' Zhang", "Specter", "Rachel Morrow", "Director Patricia Morgan". The three surviving
cell leads — "Trojan Horse", "The Liquidator", "Big Brother" — are named in delegation briefs and
debrief reports but not met, which seeds them for later missions rather than spending them on thin
confrontations here.

**Canon flag:** the bible contradicts itself on Blackout's real name — `critical_mass.md:26` says
Dr. James Mercer, `09_scenario_design/examples/grid_down.md:364` says Michael Bradford. This plan uses
Mercer. The bible needs reconciling either way; noted as an open decision.

---

## Map and lock spine

Six rooms, one coherent place — replacing the current seven-room generic office block. All six room
types below are **verified to exist** as tilemaps.

| Room | Type | Contains |
|---|---|---|
| Security Checkpoint *(start)* | `room_security` | Morrison, badge printer (redundant badge source), visitor log |
| Operations Floor | `room_office` | Evacuating staff, situation board, substation map |
| Server Room | `room_servers` | **vm-launcher + flag-station**, Elena, NFS coordination traffic |
| SCADA Control Room | `room_control_1x2gu` | Mercer, countdown display, `crisis_control_system`, debrief trigger |
| Backup Generator Room | `room_battery_hall` | Park's sabotage target, vault PIN on the maintenance log |
| Underground Cable Vault | `room_archive_1x2gu` | How the backdoors went in; Tomb Gamma; **mole evidence** |

**Lock chain — five types, five field guides, each with a redundant source so no KO strands it:**

| Gate | Lock | Primary source | Redundant source |
|---|---|---|---|
| Operations Floor → Server Room | `rfid` | Morrison's badge (talk or KO) | Badge printer at the checkpoint |
| Server Room → Generator Room | `key` + lockpick | Maintenance key on the ops floor | Lockpick in start inventory |
| Generator → Cable Vault | `pin` | Maintenance log in the generator room | Elena |
| → SCADA Control Room | `password` | Elena | Netcat C2 channel (VM flag 2) |
| `crisis_control_system` | `flag` | `station:flag_4` | — (this is the win condition) |

Key+lockpick, RFID, PIN, password and flag — the full educational spread from
`README_scenario_design.md`, every type thematically right for an industrial control facility, and
mapping one-to-one onto the five field guides below. This replaces a mission that currently has
**zero locks of any type**.

**Guard space:** Morrison patrols the checkpoint and the ops-floor approach with a directional LOS
cone (~130°, range ~150px, `visualize: true`) in a room large enough to circle — evade, talk past, or
drop. Park is static in the vault and reacts on entry. This is the first hostile presence in a
mission that currently has none, against `season_1_arc.md:576-577` explicitly calling for multiple
hostile ENTROPY operatives.

---

## VM, flags and field guides

SecGen scenario **`putting_it_together`** (NFS shares, netcat, privilege escalation, multi-stage) —
per `mission.json` and the arc doc. Built on the supported pattern from
`scenarios/m02_ransomed_trust/scenario.json.erb:1735-1760`: a real `type: "vm-launcher"` object via
`vm_object(...)`, a separate `type: "flag-station"` with `acceptsVms` and `flags_for_vm(...)`, and
`flagRewards` of `type: "set_global"`. The current build's `type: "pc"` + `unlockMechanism.type:
"vm_launcher"` + `vmConfig` is invented — it appears nowhere in `scripts/scenario-schema.json` and is
wholly inert.

| Flag | Challenge | Narrative payload | Sets |
|---|---|---|---|
| 1 | NFS mount + attack timeline | **The coordination traffic** — four operations, one schedule | `flag1_submitted`, `found_coordination_traffic` |
| 2 | netcat C2 enumeration | Override codes **and the SCADA password** (redundant source) | `flag2_submitted` |
| 3 | Privilege escalation to root | Control of the attack host | `flag3_submitted` |
| 4 | Terminate scripts, lock out remote access | Grid saved | `flag4_submitted`, unlocks `crisis_control_system` |

**Field guides** — exposure-gated offers, delivered on request from the hub, per the m01/m02 pattern
(`#give_item:lab-workstation:<key_id>` behind `{<x>_guide_offered and not <x>_guide_hint_given}`,
with matching `itemsHeld` on the handler carrying `key_id`, `name` and `labUrl`). All five sheets
verified present in `HacktivityLabSheets/_labs/safetynet/`:

| Guide | Offered when | Lab sheet |
|---|---|---|
| RFID cloning | Player first hits the badge door | `rfid-cloning.md` |
| Lockpicking | Player first hits the key lock | `lockpicking.md` |
| Recon & network mapping | `room_entered:server_room` | `reconnaissance-and-network-mapping.md` |
| Scanning & exploitation | vm-launcher first interacted | `scanning-and-exploitation.md` |
| Privilege escalation | `flag2_submitted` | `privilege-escalation.md` |

The current build has **zero** field guides and instead dumps the entire four-stage exploitation
walkthrough unconditionally at `m07_phone_agent_0x99.ink:98-121`. That block is deleted; its content
becomes the five gated guides plus per-stage hub hints gated on the previous flag.

---

## Agent HaX hub — progress gating

Rebuilt as a `support_hub` on the m02 pattern (`m02_phone_agent0x99.ink`), with per-topic
`*_discussed` latches so nothing repeats and nothing appears before the player has met it.

| Topic | Gate |
|---|---|
| The three briefs / make the call | `not team_assigned` |
| Redirect the team | `projection_revised and not team_redirected and timer > 10` |
| "We're not covering two of them" — moral sounding board | `team_assigned` |
| Morrison was cleared last month | `morrison_resolved` |
| Elena's numbers don't match ours | `elena_outcome != ""` |
| Four operations, one schedule | `found_coordination_traffic` |
| Per-stage VM hints ×4 | `flagN-1_submitted and not flagN_submitted` |
| Field guide offers ×5 | `<x>_guide_offered and not <x>_guide_hint_given` |
| Mercer | `mercer_fate != ""` |
| Tomb Gamma / the mole | `found_tomb_gamma` / `found_mole_evidence` |
| Sticky exit | always — `+ [I'll call you back.] #exit_conversation` |

`#exit_conversation` is currently used **zero** times in the entire mission; every hub and every
re-enterable knot gets a sticky unconditional exit, which is also the fix for the starved-knot runtime
errors.

---

## State contract — fix this before any parallel work

**This is the highest-risk item in the plan.** Work packages 3–8 all write ink against these names. If
they are not fixed first, subagents will invent conflicting identifiers and the integration pass
becomes a rewrite. WP1 produces this as a committed table; nothing else starts until it exists.

**Globals** — every one declared in `globalVariables`, `VAR`-declared in every ink file that reads it,
and set via `#set_global` (the mission currently contains **zero** `#set_global` tags, which is why no
ink branch reaches the engine):

```
briefing_played            bool    cutscene skip guard
team_assignment            string  "" | "fracture" | "trojan_horse" | "meltdown"
team_assigned              bool
projection_revised         bool    player found the understated projection
team_redirected            bool    acted on it before T-10
morrison_resolved          string  "" | "talked" | "ko" | "evaded"
elena_outcome              string  "" | "turned" | "fled" | "ko"
found_coordination_traffic bool    four ops, one schedule
flag1..4_submitted         bool    from flagRewards set_global
mercer_fate                string  "" | "arrested" | "ko" | "escaped"
mercer_told_diversion      bool    player told him he was a distraction
mercer_stance              string  "" | "condemned" | "reasoned" | "silent"
grid_saved                 bool    THE win condition
found_tomb_gamma           bool
found_mole_evidence        bool
mission_complete           bool    fires the debrief; set from the terminal, never from a KO-able NPC
```

Everything in the current `globalVariables` block not in this list is deleted — **~30 of 47 declared
globals are inert today**, touched by no ink file.

**Ink knot names** must match each NPC's declared `currentKnot` exactly. Seven are wrong today and the
NPCs are silently mute as a result (`person-chat-minigame.js:436-437` calls `goToKnot()` with no
try/catch). Every file gets `=== start ===` as its entry knot and `=== hub ===` where it has one.

**Attribution:** inline `DisplayName:` prefixes only. The mission's 281 `#speaker:<Full Name>` tags do
not resolve — `determineSpeaker()` accepts only `player` and `npc` for a two-part tag, so every line
currently renders as the room's main NPC, including 34 `#speaker:You` lines that put the player's
words in the antagonist's mouth. Names must match `displayName` **exactly**: `Dr. James Mercer:`,
`Agent HaX:`, `Director Magnus Netherton:`, `Elena Rodriguez:`, `You:`, `Narrator:`.

---

## Debrief and credits

One event-driven debrief on `global_variable_changed:mission_complete`, ending in
`conclusionScreen: { "type": "bond_visualiser" }` behind a `missionConclusion` aim with
`requiresCompleted`. Conditional credit lines on: `grid_saved`, `team_assignment` (which operation was
covered), the two uncovered operations by name and consequence, `team_redirected`, `mercer_fate` +
`mercer_stance` + `mercer_told_diversion`, `elena_outcome`, `morrison_resolved`, `found_tomb_gamma`,
`found_mole_evidence`.

Three things the current debrief does that must not survive: it reports catastrophic failure on every
run (`player_success` is never set, so it defaults false), it never mentions any antagonist's fate
(four `*_fate` variables are written across four files and read in none), and its four moral-reflection
choices all set nothing and receive the same absolution. The player's stance on their own triage is
the emotional payload of this scene — it needs to exist as state and be answered differently.

---

## Work packages

Sized for one subagent each. **WP1 gates everything.** WP3–WP8 can run in parallel *only* after WP1
publishes the state contract.

| WP | Scope | Depends on | Done when |
|---|---|---|---|
| **WP1** | **State contract + scenario skeleton.** Six rooms, types, connections, lock chain, objects, NPC ids/displayNames/knot names, the globals table, flag-station ids. Publishes `CONTRACT.md`. | — | `predict_door_sides.py` clean, no overlaps; contract committed |
| **WP2** | VM launcher + flag-station + `flagRewards`; six aims with `unlockCondition` chain, action-first spoiler-safe titles, `missionConclusion` + `requiresCompleted` + `bond_visualiser`; `taskOnKO` + `globalVarOnKO` on every progress NPC; clear the 106 unknown schema fields | WP1 | Validator 0 ❌ / 0 unknown-field; walkthrough reaches the end; KO run per NPC still completes |
| **WP3** | Ink: opening briefing cutscene + the three delegation briefs + the choice | WP1 | Question-hub shape, no lossy path, sets `team_assignment` |
| **WP4** | Ink: **Mercer confrontation.** Rework the one genuinely good file — keep the four-endings-on-real-state structure, recast as Mercer, make him cold, remove the lethal player firearm, add the diversion reveal as a stance choice | WP1 | `npc-dialog-review`: fanatic not negotiation; `mercer_*` set and read |
| **WP5** | Ink: **Elena** (new) — the conflicted asset, the revision intel, turn/flee/KO | WP1 | Revision reachable; redundant with the NFS source |
| **WP6** | Ink: **Agent HaX hub** rebuild — progress gating, delegation + redirect UI, five field guides, per-stage VM hints, sticky exit; plus `itemsHeld` wiring | WP1, WP2 | Every `#give_item` matches an `itemsHeld` key_id; no guide before its obstacle |
| **WP7** | Ink: Architect countdown taunts (T-30/20/10/5/1) + Morrison and Park barks/hostility | WP1 | Taunts track `team_assignment`; hostility via `#hostile` + engine KO only |
| **WP8** | Ink: closing debrief + conditional credits, reading the full state contract | WP1, WP2 | Every branch reachable and driven by a global the engine has seen |
| **WP9** | Voice blocks for all seven speakers + `narrator` voice; music block on the m02 structure (cutscene / threat / spy-action / victory / credits); briefing `skipIfGlobal` + `setGlobalOnStart` | WP1 | Nothing silent; music shifts on the beats; briefing doesn't replay |
| **WP10** | Integration QA: validator, `compile-ink.sh`, `loopcheck`/`inkcheck` on every file from its declared `currentKnot`, `walkthrough-scenario`, `break-escape-dungeon-graph`, KO matrix, one full manual run | all | Zero runtime errors from any entry knot |

**Standing rules for every ink WP** — these are the defects that made the current build unplayable:
no `**bold**`, no `* ` markdown bullets, no `# ` headings (369 such lines currently parse as choices
or vanish as tags, causing 54–92% of conversation paths to die with `ran out of content`); inline
`DisplayName:` attribution only; `Narrator:` for every scene beat; first-person spoken choice
brackets, never menu labels (134 of 328 choices are labels today); a sticky unconditional `+` exit in
every re-enterable knot; and `#set_global` on every consequence-bearing choice.

---

## Documentation changes

| File | Action |
|---|---|
| `DEVELOPMENT_STATUS.md`, `COMPLETION_SUMMARY.md`, `SESSION_SUMMARY.md` | **Delete.** All three assert "100% COMPLETE — FULLY PLAYABLE / 0 schema errors" for a mission that cannot be started. m01/m02 carry no such files. |
| `SOLUTION_GUIDE.md` | Delete; regenerate from the built mission at WP10. 622 lines describing paths that no longer exist. |
| `README.md` | Rewrite for the delegation model; move plaintext secrets out per the m02 convention. |
| `mission.json` | Reconcile the 10-KA CyBOK claim with what the mission actually teaches; soften "First direct contact" with the Architect (canon says comms only). |
| `planning/stage_0_option_a_infrastructure.md` | Promote to the mission design doc: delegation frame, canon cast, the real lock chain. |
| `planning/stage_0_option_{b,c,d}_*.md` | Move to `planning/archive/`; their casualty arithmetic and target detail feed the delegation briefs and debrief. Archive, do not delete. |
| `planning/delegation_operations.md` | **New.** The three off-camera operations: briefs, projections, true outcomes, debrief text. |
| `planning_notes/overall_story_plan/season_1_arc.md` | **Proposed amendment, needs approval** — M7's section says the player "must choose which operation to stop personally". Under this model the player is assigned Infrastructure and chooses the team's target. Campaign-level doc affecting M8/M10; flagged rather than edited. |

---

## Open decisions

1. ~~**Blackout's canon name**~~ — **RESOLVED 2026-08-30.** Mercer is canon (`03_entropy_cells/critical_mass.md:26`, plus a lore fragment). `09_scenario_design/examples/grid_down.md` renamed Bradford → Mercer throughout (55 occurrences) and marked as a superseded illustrative sketch.
2. **UK or US?** m02 is unambiguously UK (£, Health and Social Care Committee); m07 is unambiguously US (Pacific Northwest, federal elections, $). One campaign, one geography. The grid facility works either way.
3. **"The Professor"** (zero hits in `story_design/`) and the **Montana Tomb Gamma coordinates** (`notable_locations.md:289` deliberately leaves the location unspecified) — promote to canon or cut?
4. **Is the 30-minute timer a real engine timer?** A `timer_system` test scenario exists. Currently every terminal renders a frozen ERB `30`. The redirect window at T-10 needs a real clock to mean anything.
5. **Does `team_assignment` persist to M10?** `season_1_arc.md:1056` makes the M7 choice a campaign branch affecting M10 cell presence and difficulty. Needs a campaign-level global; named here, out of scope for this mission.
6. ~~**Season arc amendment**~~ — **DONE 2026-08-30.** `season_1_arc.md` M7 section rewritten for the delegation model (7 edits + an amendment note). The M10 campaign branch is now "where the team was sent".

---

## Verification

Run after every WP: `ruby scripts/validate_scenario.rb scenarios/m07_architects_gambit/scenario.json.erb`
and `bash scripts/compile-ink.sh m07_architects_gambit`.

1. **Runtime, per file, from each NPC's declared `currentKnot`** — `loopcheck.js` and `inkcheck.js`. This is the check the current build fails hardest (all nine files error; 54–92% of paths). Target: zero runtime errors, zero fatal bad-knots.
2. `python3 scripts/predict_door_sides.py` after WP1 and any connection change.
3. **break-escape-dungeon-graph** after WP2 — the lock/key spine does not exist today, so the graph is the proof it was built.
4. **walkthrough-scenario** after WP2 and WP9, reconciled against the graph.
5. **scenario-design-review** after WP2 and WP9.
6. **npc-dialog-review** after WP4–WP8. Pass condition is "do the choices matter" and "is Mercer a fanatic rather than a negotiation", not compile-clean.
7. **KO matrix** — one run per progress-bearing NPC, each still reaching the conclusion, each acknowledged in the debrief.
8. **Manual run** — music transitions, guide gating, redirect window, credits, bond_visualiser.

---

## Appendix — current-state evidence

Kept for reference; supersedes nothing above. Full detail in the v1 plan (`.ALIGNMENT_PLAN.v1.bak`).

**Validator:** 58 ❌, 255 ⚠️ (106 unknown fields, 148 markdown), 6 missing ink files reported — **ten
actually missing**, four hidden inside the dead ERB conditional. No dungeon graph and no room-geometry
check are produced, because validation aborts at the ink section: **the objective-wiring, item-resolution
and KO checks have never run on this mission.**

**Fatal architecture:** `crisis_choice` is initialised `""` at `scenario.json.erb:63` and consumed by ERB
at `:1208` and ~20 other sites. ERB renders once, at load. The `<% else %>` always wins → `placeholder_npc`
→ a file that does not exist. Because no `#set_global` exists either, every downstream `{crisis_choice == …}`
in five ink files also falls through — **every player gets the corporate-warfare text regardless of choice.**

**Unreachable by construction:** extraction gates on `found_tomb_gamma and found_mole_evidence`, both read
by three files and written by nothing. `final_debrief_complete` is declared, consumed, and never set — the
debrief cannot fire. `player_success` is never declared globally or set, so a perfect run reports the grid
failed and 240–385 dead. Two written ink files (`m07_crisis_data`, `m07_crisis_corporate`) are orphans
referenced by no NPC.

**Dialogue:** zero inline attributions (281 non-resolving `#speaker:` tags), zero voice blocks (m02 has 15),
zero `Narrator:` lines in 3,763 lines of ink, zero `#give_item`, zero `#set_global`, zero
`#exit_conversation`, no `=== start ===` in any file, seven of nine files with no hub. 369 markdown lines
parse as choices or vanish; `loopcheck` errors on all nine files.

**Structure:** zero locks of any type, zero hostiles or patrols, zero `taskOnKO`/`globalVarOnKO` across 13
NPCs with six critical-path tasks conversation-gated, no `unlockCondition` on five locked aims, no
`missionConclusion`, no `conclusionScreen`, no music block, six of seven rooms `room_office`, and
top-level `starting_items` silently ignored by the engine.

**What was worth keeping, and is:** the Blackout confrontation's four-endings-on-real-state structure
(→ WP4), the casualty arithmetic and outcomes matrix (→ delegation briefs), the Architect's countdown
taunts (→ WP7), the Option A planning doc's facility design (→ WP1), and clean door geometry.
