# Mission 7: The Architect's Gambit

**Tier:** 3 (Advanced)
**Type:** Crisis defence
**Duration:** 80–100 minutes
**ENTROPY cell on site:** Critical Mass
**SecGen scenario:** `putting_it_together` (NFS shares, netcat, privilege escalation, multi-stage)
**Prerequisite:** m06_follow_the_money · **Unlocks:** m08_the_mole

> **Status: being rebuilt.** The mission does not currently run. See [Status](#status) at the
> bottom before doing anything with this directory.

## Place in the season

M7 is the season's crisis episode and the point at which The Architect stops being a rumour. He
appears here only as intercepted communications and intercom taunts — never in person, per
`story_design/universe_bible/.../masterminds/the_architect.md`. What the mission hands to M8 is the
mole: evidence that SAFETYNET's deployment was leaked before SAFETYNET made it.

## Premise

Four ENTROPY operations go live inside the same sixty seconds. SAFETYNET has one field agent in
range and one tactical team.

Agent 0x00 is briefed at SAFETYNET headquarters and flown out to the Pacific Northwest Regional Grid
Control Facility outside Portland, because it is the only target where a person inside the building
changes the outcome.
Critical Mass has spent six months installing backdoors in the SCADA control stack, and the cascade
script fires on a local, hardcoded timer that cannot be reached from outside the walls. 8.4 million
people across three states are downstream of it.

The player does not choose where they go. The choice they get is where the tactical team goes.

## The delegation

The team can reach exactly one of the remaining three operations. **Two go unanswered, and the
debrief reads out what happened at both.**

| Operation | Cells | The harm |
|---|---|---|
| **Fracture** — federal voter registration data centre | Ghost Protocol + Social Fabric | 187M records exfiltrated, with a disinformation package timed to land on top of the breach. Democratic legitimacy, irreversible. |
| **Trojan Horse** — TechForge update distribution, 840 vendor signing keys | Supply Chain Saboteurs | Backdoors into 47M systems. Briefed as espionage with no body count. |
| **Meltdown** — 47 zero-days against 12 Fortune 500 firms | Digital Vanguard + Zero Day Syndicate | Markets frozen, 4,200 hospitals ransomwared, deaths on the same clock as the player's own. |

There is no exchange rate between deaths tonight, a national election, and the security floor under
every operation for the rest of the season. The mission never implies one, and Agent HaX never makes
the call for the player.

**The revision mechanic.** Every projection in the briefing came from ENTROPY, captured because The
Architect wanted it captured. One brief is understated on purpose. Inside the facility the player can
find that out from Elena Rodriguez in dialogue, or from the coordination traffic on the NFS share
(VM flag 1) — two independent sources, so a knockout cannot strand the route. Either opens a redirect
option on the HaX hub, and the window closes at T-10. Curiosity pays; rushing is never blocked.

**The twist, in two turns.** At the SCADA terminal the coordination traffic shows all four operations
running off one schedule under one authority; they are one operation with four limbs, and Mercer does
not know he is a diversion. In the cable vault, and again in the debrief, the reveal is that the
gambit was never the attack — it was an experiment to learn how SAFETYNET triages when it cannot cover
everything. The player still saves 8.4 million people, and the debrief says so plainly. The floor that
drops is that the victory was measured.

Full specification: [`planning/mission_design.md`](planning/mission_design.md) and
[`planning/delegation_operations.md`](planning/delegation_operations.md).

## The facility

Six rooms, one building. Start at the checkpoint, finish in SCADA control.

| Room | Type | Contains |
|---|---|---|
| Security Checkpoint *(start)* | `room_security` | Morrison, badge printer, visitor log |
| Operations Floor | `room_office` | Evacuating staff, situation board, 147-substation map, maintenance key |
| Server Room | `room_servers` | vm-launcher and flag-station, Elena, NFS coordination traffic |
| SCADA Control Room | `room_control_1x2gu` | Mercer, countdown display, `crisis_control_system`, debrief trigger |
| Backup Generator Room | `room_battery_hall` | Park's sabotage target, maintenance log |
| Underground Cable Vault | `room_archive_1x2gu` | How the backdoors went in, Tomb Gamma, mole evidence |

### Lock chain

Five lock types, one per field guide, each with a redundant source so no knockout can strand a run.

| Gate | Lock | Primary source | Redundant source |
|---|---|---|---|
| Operations Floor → Server Room | `rfid` | Morrison's badge (talk or KO) | Badge printer at the checkpoint |
| Server Room → Generator Room | `key` + lockpick | Maintenance key on the ops floor | Lockpick in starting inventory |
| Generator Room → Cable Vault | `pin` | Maintenance log in the generator room | Elena |
| → SCADA Control Room | `password` | Elena | Netcat C2 channel (VM flag 2) |
| `crisis_control_system` | `flag` | `station:flag_4` | — (win condition) |

Plaintext codes, PINs and passwords are not recorded here. They live in `scenario.json.erb` and in the
`SOLUTION_GUIDE.md` regenerated from the built mission at the end of implementation.

Morrison patrols the checkpoint and the ops-floor approach with a directional LOS cone. Park is static
in the vault and reacts on entry. Hostility is expressed through `#hostile` and engine knockout only.

## VM integration

SecGen scenario `putting_it_together`, implemented as a real `vm-launcher` object plus a separate
`flag-station` with `acceptsVms`, on the m02 pattern
(`scenarios/m02_ransomed_trust/scenario.json.erb:1735-1760`), with `flagRewards` of type `set_global`.

| Flag | Challenge | What it gives the player |
|---|---|---|
| 1 | Mount the misconfigured NFS export, recover the attack timeline | The coordination traffic — four operations, one schedule |
| 2 | Enumerate services, find the netcat C2 channel | Override codes and the SCADA password (the route past Elena) |
| 3 | Privilege escalation to root on the attack host | Control of the machine running the countdown |
| 4 | Identify and terminate the attack processes, lock out remote access | The grid holds; unlocks `crisis_control_system` |

### Field guides

Exposure-gated, offered from the HaX hub on request, never before the player has hit the obstacle they
explain. Sheets live in `HacktivityLabSheets/_labs/safetynet/`.

| Guide | Offered when | Lab sheet |
|---|---|---|
| RFID cloning | First contact with the badge door | `rfid-cloning.md` |
| Lockpicking | First contact with the key lock | `lockpicking.md` |
| Recon & network mapping | `room_entered:server_room` | `reconnaissance-and-network-mapping.md` |
| Scanning & exploitation | vm-launcher first interacted | `scanning-and-exploitation.md` |
| Privilege escalation | `flag2_submitted` | `privilege-escalation.md` |

## Cast

| NPC id | displayName | Role |
|---|---|---|
| `james_mercer` | Dr. James Mercer | Critical Mass cell lead, "Blackout". Ex-Department of Energy grid engineer, professorial, has read the casualty projection and signed it. Cold; the player picks a stance, not a negotiation. |
| `elena_rodriguez` | Elena Rodriguez | Critical Mass electrical engineer who believes she is running a six-hour demonstration blackout with a hospital carve-out. Conflicted, and the mission's intel source. |
| `jake_morrison` | Jake Morrison | Facility security guard, bought. Renewed Mercer's credentials. Cold, hostile, patrols. |
| `thomas_park` | Thomas Park | Critical Mass sabotage tech in the cable vault, ready to cut backup power. Cold, hostile, static. |
| `agent_0x99` | Agent HaX | Handler on the phone. Runs the progress-gated hub: briefs, delegation, redirect window, field guides, VM hints. |
| `director_netherton` | Director Magnus Netherton | Canon SAFETYNET Director of Field Operations. Delivers the briefing, takes the debrief. |
| `the_architect` | The Architect | Comms only. Intercom taunts on the countdown, reading `team_assignment`. |

Cut from the earlier draft: "Marcus 'Blackout' Chen", Adrian Cross, Victoria "V1per" Zhang, Specter,
Rachel Morrow, and the invented "Director Patricia Morgan". Rationale in `ALIGNMENT_PLAN.md`.

**Open canon issue.** The universe bible gives Blackout's real name as Dr. James Mercer in
`critical_mass.md` and as Michael Bradford in `09_scenario_design/examples/grid_down.md`. This mission
uses Mercer; the bible still needs reconciling.

## Status

**The mission is being rebuilt and cannot currently be played.** It was built as four playable
branches selected by an ERB variable evaluated once at load, which cannot work. The reviews found it
unstartable, unfinishable and effectively silent: seven NPCs mute because their declared `currentKnot`
values do not exist, no `#set_global` tags anywhere, no locks of any type, no field guides, and a
debrief that reports a few hundred dead after a perfect run.

Three status documents claiming the mission was complete and validator-clean were deleted, along with
a solution guide describing paths that will not exist. The solution guide is regenerated from the
built mission at the end of implementation.

- **The plan, and the authority for this rework:** [`ALIGNMENT_PLAN.md`](ALIGNMENT_PLAN.md) — work
  packages, state contract, verification steps.
- **The design:** [`planning/mission_design.md`](planning/mission_design.md) and
  [`planning/delegation_operations.md`](planning/delegation_operations.md).
- Everything described above under *The facility*, *VM integration* and *Cast* is the target
  specification, not the current contents of `scenario.json.erb`.

Verification for any work here:

```
ruby scripts/validate_scenario.rb scenarios/m07_architects_gambit/scenario.json.erb
bash scripts/compile-ink.sh m07_architects_gambit
```
