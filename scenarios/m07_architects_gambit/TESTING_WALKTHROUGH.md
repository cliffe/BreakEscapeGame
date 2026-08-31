# m07 "The Architect's Gambit" — QA Walkthrough

> Generated at WP10, 2026-08-30, from the built mission. Critical path plus branch and KO variants.
> Validator state at time of writing: **0 errors**, 0 unknown fields, geometry clean, 1 known false-positive warning.

**Map** — a spine with two spurs off the server room:

```
security_checkpoint ─E─ operations_floor ─E─ server_room ─N─ scada_control
     (start)                                      │
                                                  S
                                            generator_room
                                                  │
                                                  S
                                             cable_vault
```

**Lock chain** (each gate has two sources, so no knockout can strand the mission):

| # | Gate | Lock | Primary | Redundant |
|---|---|---|---|---|
| 1 | → `server_room` | `rfid` `server_zone_badge` | Jake Morrison's badge | badge printer at the checkpoint |
| 2 | → `generator_room` | `key` `generator_maintenance_key` | maintenance key, operations floor | lockpick in starting inventory |
| 3 | → `cable_vault` | `pin` **4703** | maintenance log, generator room | Elena Rodriguez |
| 4 | → `scada_control` | `password` **CascadeWindow19** | Elena Rodriguez | netcat C2 channel (flag 2) |
| 5 | `crisis_control_system` | `flag` `scada_attack_host:flag_4` | VM challenge | — (win condition) |

---

## Critical path

| # | Action | Expected |
|---|---|---|
| 1 | Load the scenario | Cutscene briefing plays automatically at SAFETYNET HQ (`hq1.png`); `briefing_played` set; does not replay on resume |
| 2 | Read the three operation briefs in the hub | Fracture / Trojan Horse / Meltdown, each independently repeatable; comparison reachable after the first |
| 3 | Commit the team | Sets `team_assignment` + `team_assigned`; then two narrator lines carry the player from HQ to Portland and the checkpoint handoff; aim 0 task `assign_tactical_team` completes; music shifts to noir |
| 4 | Approach Jake Morrison | Patrols with a visible ~130° vision cone; can be talked past, evaded, or dropped |
| 5 | Obtain the server-zone badge | From Morrison, or print one at the badge printer |
| 6 | East into `operations_floor`, east into `server_room` | RFID gate opens; aim 1 unlocks; recon field guide offered on room entry |
| 7 | Talk to Elena Rodriguez | Gives the SCADA password and the vault PIN if she turns; sets `elena_outcome` |
| 8 | Ask Elena about the vendor manifest | Sets `projection_revised` — the Trojan Horse brief is understated |
| 9 | Open the HaX hub | Redirect option now available while `redirect_window_closed` is false |
| 10 | Launch the VM, submit flag 1 | NFS export; sets `flag1_submitted`, `found_coordination_traffic`, `projection_revised` (redundant route) |
| 11 | Submit flag 2 | netcat C2; sets `flag2_submitted`, `scada_password_found`; privesc guide offered |
| 12 | Submit flag 3 | Privilege escalation; sets `flag3_submitted` **and closes the redirect window** |
| 13 | Submit flag 4 | Sets `flag4_submitted`; unlocks `crisis_control_system` |
| 14 | North into `scada_control` | Password gate; aim 3; music shifts to spy-action |
| 15 | Confront Dr. James Mercer | Stance taken *before* the argument; sets `mercer_stance`, then `mercer_fate` |
| 16 | Use `crisis_control_system` | Prints the Sequence Abort Confirmation; sets `grid_saved` + `mission_complete` |
| 17 | Debrief fires | On `global_variable_changed:mission_complete`, once only; person-chat, set back at SAFETYNET HQ (`hq3.png`) |
| 18 | Conclusion | Victory music → credits → `bond_visualiser` |

**Optional (aim 2, side branch — never gates the conclusion):** south to `generator_room` (key/lockpick), read the maintenance log for the PIN, deal with Thomas Park, south to `cable_vault`, collect `mole_intercept_evidence` and `tomb_gamma_dossier`. Sets `found_mole_evidence` / `found_tomb_gamma`, which unlock the fuller version of the debrief's twist.

---

## Branch variants to test

| Variant | Setup | Expected |
|---|---|---|
| Each delegation target | Commit to fracture / trojan_horse / meltdown | Debrief names the two *not* covered, by name and number |
| Team uncommitted | Reach the debrief with `team_assignment` empty | Debrief has a real branch (team stood by) — must not fall through |
| Redirect taken | Find the revision, redirect before flag 3 | `team_redirected`; debrief pays it off; Architect's sign-off registers surprise |
| Revision found, not acted on | Ask Elena, do not redirect | Debrief notes what was on the table without lecturing |
| Revision never found | Skip Elena and flag 1's payload | Netherton notes the evidence was in the building |
| Redirect window shut | Submit flag 3 first, then try | HaX refuses out loud — the player sees the door close |
| Mercer, each ending | `arrested` (two routes), `ko`, `escaped` | Distinct credits lines; `mercer_ko` excluded from walked-away lines |
| Told he was a diversion | Recover coordination traffic first | `mercer_told_diversion`; unlocks the hollowed arrest ending |
| Skip the vault | Never enter `cable_vault` | Debrief runs the *thin* coda — nobody can explain how he knew |

---

## Knockout matrix

KO is permanent and any NPC can be attacked. Every one of these must still reach the conclusion.

| NPC | Gates | `taskOnKO` | `globalVarOnKO` | Redundant route | Still completable |
|---|---|---|---|---|---|
| `jake_morrison` | checkpoint task, badge | `clear_the_checkpoint` | `morrison_ko` | badge printer | ✔ |
| `elena_rodriguez` | her task, SCADA password, vault PIN, revision | `question_elena` | `elena_ko` | flag 2 (password), maintenance log (PIN), flag 1 (revision) | ✔ |
| `james_mercer` | `confront_mercer` | `confront_mercer` | `mercer_ko` | sequence is scheduled and local — he gates nothing mechanical | ✔ |
| `thomas_park` | `neutralise_park` (optional aim) | `neutralise_park` | `park_ko` | side content only | ✔ |

`agent_0x99`, `the_architect` and both Netherton blocks are phone or hidden cutscene NPCs and cannot be knocked out. The win condition is set by `shut_down_the_cascade`'s `onComplete`, never by a conversation.

**Check in every KO run:** the debrief and credits describe the downed character as neutralised, never as walking away. All four latches are read in both places.

---

## Automated checks

```bash
ruby   scripts/validate_scenario.rb scenarios/m07_architects_gambit/scenario.json.erb
python3 scripts/predict_door_sides.py scenarios/m07_architects_gambit/scenario.json.erb
bash   scripts/compile-ink.sh m07_architects_gambit
node   scripts/ink_runtime_check/loopcheck.js <ink>.json start
node   scripts/ink_runtime_check/inkcheck.js  <ink>.json start [VAR=value ...]
```

All eight ink files pass `loopcheck` and `inkcheck` from their declared `currentKnot` of `start`, with zero failing paths. The two heavily-gated files (`m07_phone_agent_0x99`, `m07_architect_comms`) expose only 1–2 paths under default globals and **must** be re-run under progression states — see the state list in the WP10 report.
