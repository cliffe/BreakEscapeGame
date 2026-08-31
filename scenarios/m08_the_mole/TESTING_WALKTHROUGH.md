# m08 "The Mole" — QA Walkthrough

Numbered critical-path checklist with expected outcomes, reconciled against
`dungeon_graph.md`. Run once clean, then the branch/KO variants.

## Critical path

| # | Action | Expected |
|---|---|---|
| 1 | Load mission | ATHENA opening cutscene plays once (`briefing_played`); noir music; does not replay on resume |
| 2 | Go north, talk to Director Netherton | Briefing hub; can ask re: 3 suspects; can state `suspect_theory`; receives all-zones keycard (`server_zone_badge`); `brief_with_netherton` completes; `work_the_suspects` + `get_into_the_repo` unlock |
| 3 | (optional) Interview Cipher / Phantom / Nightshade | Each sets `*_interviewed` + completes its optional task; alibis/cross-refs shown; Nightshade tells set `nightshade_suspected` |
| 4 | Enter Server Room (east of Ops) with keycard | RFID opens; `breach_server_room` completes |
| 5 | Exploit GitList, submit flag 1 then flag 2 | `flag1/2_submitted`; HaX messages fire; `found_gitlist_vuln`/`found_leaked_creds`; music → tension on flag 2; `get_into_the_repo` completes → `correlate_the_evidence` unlocks |
| 6 | Submit flag 3 then flag 4 | `flag3/4_submitted`; `found_architect_comms`; on flag 4: `all_flags_submitted` + `mole_identified`; music → threat; `correlate_the_evidence` completes → `confront_the_mole` unlocks |
| 7 | Open Director's Safe (PIN 2407) | Yields `interrogation_key` + `nightshade_profile` |
| 8 | Open Interrogation Room (south of Crypto) with key | Key lock opens; `open_interrogation_room` completes; music → spy-action |
| 9 | Enter interrogation room | `nightshade_confrontation` reveals (hidden + `all_flags_submitted`), conversation auto-opens with hq2 background |
| 10 | Work confrontation hub, choose fate | `nightshade_arrested` XOR `nightshade_triple_agent`; `tomb_gamma_location_known`; `confront_nightshade` completes |
| 11 | Use disposition terminal | `mission_complete` + `decide_the_fate` completes |
| 12 | Netherton debrief auto-opens (break room) | Branches on fate/theory/stance; `take_the_debrief` completes; on close → victory music → `bond_visualiser` |

## Branch variants to test

- **Fate = arrest** vs **triple agent** — debrief `disposition` and credits differ.
- **suspect_theory = cipher/phantom** (wrongly accused) vs **nightshade** vs unset — debrief `the_hunt` branch differs; innocents' accuse branches differ with/without alibi seen.
- **nightshade_suspected true/false** — confrontation opener + debrief line differ.
- **debrief_stance = defended/owned**.
- **database_theft_understood** true (read board/catalog) vs false — debrief `the_bigger_picture` differs.

## Knockout matrix (mission must stay completable)

| KO'd NPC | Expected |
|---|---|
| Director Netherton | `netherton_ko`; `brief_with_netherton` auto-completes (taskOnKO); HaX points at printer/ATHENA; keycard replaceable via printer |
| Cipher / Phantom | `cipher_ko`/`phantom_ko`; optional task auto-completes; HaX reassures; case unaffected |
| Nightshade (suspect, crypto lab) | `nightshade_ko`; interview optional; confrontation still proceeds from evidence |
| Nightshade (confrontation) | `nightshade_confront_ko`; `confront_nightshade` auto-completes; HaX resolves fate to **arrest** + sets `tomb_gamma_location_known`; debrief coherent |
| closing_debrief (Netherton) | `take_the_debrief` auto-completes (taskOnKO); mission still closes |

## Automated checks (all currently pass)

- `ruby scripts/validate_scenario.rb scenarios/m08_the_mole/scenario.json.erb` — zero errors, layout overlap-free, objective wiring OK.
- `./scripts/compile-ink.sh m08_the_mole` — 12/12, no warnings.
- `loopcheck.js` on every re-enterable hub — no starved knots.
- `predict_door_sides.py` — no overlaps.

## Known follow-ups

- **VM flag order** vs a live `flags_by_vm['web_server']` build — verify the four
  flags complete their intended tasks in order (fallback strings only, standalone).
- Live playtest of per-speaker voices in the m02–m06 seed briefings.
