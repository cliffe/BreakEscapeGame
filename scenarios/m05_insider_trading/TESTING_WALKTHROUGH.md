# Mission 5: "Insider Trading" — Testing Walkthrough

> Reconciled against: dungeon_graph.md (regenerated same day by validate_scenario.rb).
> Setting: Quantum Dynamics Corporation — quantum-safe cryptography research for the DoD.

## Prerequisites

- **Validator passes** — schema OK, 0 room-layout overlaps, critical path resolves (4 hops).
- **Ink compiled** — 10/10 `.ink` → `.json` clean (only benign "END doesn't follow hub return convention" notices on terminal knots, which is expected for one-shot cutscenes/confrontation endings).
- **Minigames on the critical path:**
  - Person-chat (Patricia, Kevin, Torres, Dr. Chen, Lisa)
  - Phone-chat (Agent 0x99 briefing/hub, The Recruiter, closing debrief)
  - VM launcher + flag-station (Bludit CMS server, 4 flags)
- ⚠️ **6 item-type sprites missing** — see "Known Gaps" below. This does not block the validator (item types are valid; only the `.png` sprite is absent) but the objects render with a placeholder/fallback sprite in-game until generated.

## Room spine

```
reception_lobby (Agent 0x99, The Recruiter phone, briefing)     [start]
  ├─E─ patricia_office (Patricia Morgan → visitor badge, financial records)
  └─S─ main_corridor
         ├─W─ break_room (Lisa Park, optional; ENTROPY pamphlet)
         ├─mid─ server_hallway [rfid: employee_badge]
         │        └─N─ server_room [password: server_password]
         │                 ├─ Bludit VM + flag-station (4 flags)
         │                 ├─ Drop-Site Terminal (3 physical evidence docs)
         │                 └─N─ data_center [key] (upload terminal, upload schedule)
         ├─left─ open_office_area (Kevin Park → badge/lockpick/cloner/Torres keycard)
         │         └─N─ torres_office [rfid: office_keycard] (Torres, medical bills, journal)
         └─right─ research_lab (Dr. Chen → research badge, optional)
```

## Aim 1 — Get Inside Quantum Dynamics
[Unlocks at start — `status: active`]

1. **Opening briefing (cutscene)** — `opening_briefing_cutscene`/`m05_insider_trading_opening.ink` plays once (`skipIfGlobal`); Agent 0x99 lays out the stakes: quantum-safe key material for the National Emergency-Services Dispatch Network, 6–11 minute dispatch delay, thirty-to-forty-five projected excess deaths in the first rollout wave. **task `receive_mission_briefing` completes** on exit.
2. **Patricia Morgan (Patricia Office)** — Talk to her → **task `meet_handler` completes** (`npc_conversation`, auto-completes on encounter per the engine's `npc_conversation` handling — no ink tag required). She hands a **Visitor Badge** (`id_badge`, itemsHeld) → **task `obtain_security_badge` completes** (`collect_items: id_badge`). *KO-safety:* `taskOnKO: meet_handler` + Visitor Badge is a takeable held item, so a KO'd Patricia still yields the badge on loot. Aim complete → **`investigate_employees` unlocks**.

## Aim 2 — Work Out Who Has Been in the Servers
[Unlocks after: `establish_access` complete]

3. **Kevin Park (Open Office Area)** — Talk to him → **task `talk_to_kevin` completes**. He holds five items: **Employee Badge** (`keycard`), **Lockpick Set**, **RFID Badge Cloner**, **Torres Office Keycard**, and a **Cloned Employee Badge**. Picking these up completes `find_lockpick`, `obtain_rfid_cloner`, `obtain_torres_keycard`. *KO-safety:* `taskOnKO: talk_to_kevin`; all items are `itemsHeld`/takeable, recoverable by loot.
4. **Lisa Park (Break Room)** — Optional. Talk to her → `talk_to_lisa` completes (optional, humanises Torres via family context). No items gate progression here.
5. **Dr. Sarah Chen (Research Lab)** — Optional. Talk to her → `talk_to_dr_chen` completes; she can issue a **Research Lab Badge** (`research_badge`, takeable) → `obtain_research_access` completes. *KO-safety:* `taskOnKO: talk_to_dr_chen`; her high-clearance badge is `takeable: false`, but the duplicate Research Lab Badge she issues is takeable, so KO+loot still works.
6. Aim complete once `talk_to_kevin`, `find_lockpick`, `obtain_rfid_cloner`, `obtain_torres_keycard` are done (Lisa/Chen/research badge are optional) → **`gather_evidence` unlocks**.

## Aim 3 — Get Behind the Badge Readers
[Unlocks after: `investigate_employees` complete]

7. **Torres Office** — Enter with the Torres Office Keycard [rfid: `office_keycard`] → **task `access_torres_office` completes** (`enter_room`).
8. **Medical Bills** — Pick up → sets `found_medical_bills`, `evidence_level += 1` → **completes `find_medical_bills`**.
9. **Personal Journal** — Pick up → sets `found_torres_journal`, `evidence_level += 1` → **completes `find_journal`**.
10. **ENTROPY Pamphlet (Break Room)** — Optional. Pick up → sets `entropy_program_exposed`, `evidence_level += 1`, `lore_collected += 1` → completes `find_entropy_pamphlet`.
11. Aim complete (mandatory: `access_torres_office`, `find_medical_bills`, `find_journal`) → **`exploit_infrastructure` unlocks**.

## Aim 4 — Prove the Exfiltration on the Server
[Unlocks after: `gather_evidence` complete]

12. **Clone Kevin's badge** — Use the RFID cloner on the Employee Badge → sets a clone-badge flag → **completes `clone_employee_badge`** (custom). *KO-safety:* handler eventMapping on `kevin_ko` explicitly fires `completeTask: clone_employee_badge` and remotely pushes a cloned badge, so knocking Kevin out before cloning still unlocks the hallway.
13. **Server Password Note (Open Office Area)** — Pick up → **completes `find_server_password`**.
14. **Server Hallway** — Enter with the (cloned) Employee Badge [rfid: `employee_badge`].
15. **Server Room** — Enter with the password [password: `server_password`] → **completes `access_server_room`**.
16. **Bludit CMS VM + flag-station** — Launch the VM; submit flags at the **SAFETYNET Evidence Drop-Site** (`acceptsVms: qdc_research_server`):

| Flag | Source | Task |
|---|---|---|
| flag_1 | leaked Bludit admin credentials (recon) | `submit_flag1` |
| flag_2 | authenticated Bludit image-upload RCE | `submit_flag2` |
| flag_3 | Torres' exfiltration staging manifest (user access) | `submit_flag3` |
| flag_4 | The Architect's acquisition authorisation (root) | `submit_flag4` |

Flag_4's recovered document carries the casualty projection: **30–45 excess civilian deaths, first rollout wave, 6–11 minute dispatch delay, twelve regions in the first rollout wave** — matches the figures Agent 0x99 gives in the opening briefing and the numbers Torres/the Recruiter cite in the confrontation.

17. **Drop-Site Terminal (Server Room)** — Pick up the three physical documents (**Data Package Staging Manifest**, **Recruitment Timeline**, **Architect Approval Communications**) — each raises `evidence_level`.
18. **Data Center** — Enter [key] → **completes `access_data_center`**. Pick up the **Upload Schedule** → **completes `find_upload_schedule`**.
19. By this point `evidence_level` should be at least 7–8 (medical bills, journal, pamphlet, 3 drop-site docs, financial records, security log) — comfortably clears the `evidence_level >= 4` gate the mission brief describes and the `evidence_level >= 5` gate Patricia's dialogue needs to name Torres. Aim complete (all four flag submits + `access_data_center` + `find_upload_schedule`) → **`confront_insider` unlocks**.

## Aim 5 — Decide What Happens to Him  *(mission conclusion)*
[Unlocks after: `exploit_infrastructure` complete]
`missionConclusion: true` — `requiresCompleted: [confront_torres, make_critical_choice, submit_flag1, submit_flag2, submit_flag3, submit_flag4]` → `bond_visualiser`.

20. **Identify Torres to Patricia** — Return to Patricia Office with `evidence_level >= 5` → choose "I want to compare notes on what I've found" → `significant_findings` branch → sets `torres_identified = true`, `patricia_trust += 2` → **completes `identify_torres`** (side objective — not in `requiresCompleted`, so it does not gate the conclusion). *No KO-safe fallback exists for this task* (validator flags this explicitly as acceptable: it is a side/lore objective, not on the critical path).
21. `torres_identified` fires music cue (`spy-action`) and unlocks **The Recruiter**'s phone call (`eventMapping: global_variable_changed:torres_identified` → sends a timed "TalentStack Executive Recruiting" call). Optional but recommended before the confrontation — she offers her side of the moral argument (47 other targets already in the pipeline).
22. **Confront David Torres (Torres Office)** — Talk to him → `confrontation_scene` → `torres_confrontation` → `torres_rationalization` → `evidence_revelation` → `final_choice_moment`. **task `confront_torres` completes** on encounter (`npc_conversation`, auto-completes) — reachable via the live conversation *or* the KO path (see below).
23. **`final_choice_moment`** — four options, each sets `final_choice` and fires `#complete_task:confront_torres` again + `#complete_task:make_critical_choice` (except combat, which routes through `combat_offer` → hostile fight → `post_ko_choice`):

| Choice | `final_choice` | Path |
|---|---|---|
| "You're not too far gone. Help us, and we'll help Elena." | `turn_double_agent` | `turn_double_agent_path` → `torres_deal_offered` → `torres_accepts_turn` |
| "You're under arrest for espionage and treason." | `arrest` | `arrest_path` → `arrest_family_question` → `arrest_cooperation` / `arrest_no_cooperation` |
| "Drop the philosophy. Fight or surrender. Your choice." | (deferred) | `combat_offer` → hostile fight → KO → `post_ko_choice` |
| "I'm exposing everything." | `public_exposure` | `public_exposure_path` → `public_exposure_consequence` |

24. **Combat path detail** — choosing "fight or surrender" sets `#hostile:david_torres` and ends the conversation; Torres must be knocked out in a fight. His `eventMapping: npc_ko:david_torres` then opens `post_ko_choice`, offering a further choice:
    - **"Cuff him"** → `final_choice = combat_nonlethal`, `torres_arrested = true` → `post_ko_arrest`.
    - **"Leave him for cleanup"** → `final_choice = combat_lethal`, `torres_killed = true` → `post_ko_handoff`.
    Both set **`stop_final_exfiltration`** and complete `make_critical_choice` (also redundantly via `taskOnKO: make_critical_choice` and the handler's `completeTask: confront_torres` on `torres_ko`).
25. All four live-path endings converge on **`stop_upload`**, which sets `stop_final_exfiltration` and branches epilogue dialogue on `torres_turned` / `torres_arrested` / `entropy_program_exposed`, then `-> END` (a standalone terminal ink, correctly not routed back through the hub).
26. **Closing debrief (phone cutscene)** — `closing_debrief_trigger` fires on `global_variable_changed:final_choice` (`value !== ''`), `disableClose: true`. Credits scroll branches the "DAVID TORRES" line on `final_choice`, the "ELENA TORRES" line on `elena_treatment_funded`/`torres_killed`, and the "EVIDENCE" line on `entropy_program_exposed`.

**WIN:** `confront_torres` + `make_critical_choice` + all four `submit_flagN` complete → `confront_insider` mission-conclusion satisfied → `bond_visualiser`. Five distinct endings, all unranked:

| Ending | Trigger | Elena | Torres |
|---|---|---|---|
| **Turn double agent** | c-0 at `final_choice_moment` | Treatment funded | Free, working undercover |
| **Arrest (cooperative)** | c-1 → cooperate at `arrest_family_question` | Treatment funded | 15–25yr, reduced |
| **Arrest (no cooperation)** | c-1 → refuse at `arrest_family_question` | Untreated | 15–25yr, standard |
| **Combat non-lethal** | c-2 → KO → "Cuff him" | Untreated (unless prior deal) | Arrested |
| **Combat lethal** | c-2 → KO → "Leave him for cleanup" | Widowed | Dead |
| **Public exposure** | c-3 | Untreated | Publicly named, family exposed |

## Global Variable State (end of critical path)

| Global | Set by |
|---|---|
| `briefing_played` | opening cutscene |
| `evidence_level` | medical bills, journal, pamphlet, 3 drop-site docs, financial records, security log (steps 8–19) — accumulates well past the `>=4`/`>=5` gates |
| `torres_identified` | naming Torres to Patricia at `evidence_level >= 5` (step 20) — **starts spy-action music, unlocks the Recruiter's call** |
| `flag1_submitted`…`flag4_submitted` | flag-station submissions (step 16) |
| `architect_approval_confirmed` | flag4_submitted (HaX eventMapping) |
| `final_choice` | the confrontation's terminal choice (step 23/24) |
| `torres_turned` / `torres_arrested` / `torres_killed` | resolution branch |
| `elena_treatment_funded` | turn / cooperative-arrest deals only |
| `entropy_program_exposed` | pamphlet pickup, or public-exposure ending |
| `stop_final_exfiltration` | `stop_upload` knot (all live-path endings) or `post_ko_arrest`/`post_ko_handoff` (KO path) |

## Reconciliation against the dungeon graph (Puzzle Graph)

| Graph node | Walkthrough step | Status |
|---|---|---|
| `reception_lobby` (start) | Step 1 | ✅ covered |
| `npc_kevin_park` → `lockpick_set` → `lock_patricia_filing_cabinet` | Step 3 (side content) | ✅ covered — filing cabinet is a side container, not on the critical path |
| `door_server_hallway` (rfid) | Step 14 | ✅ covered |
| `door_server_room` (password) | Step 15 | ✅ covered |
| `door_torres_office` (rfid) | Step 7 | ✅ covered |
| `vmch_submit_flag1..4` → `vmfl_submit_flag1..4` → `aim_exploit_infrastructure` | Steps 16, 19 | ✅ covered |
| `aim_establish_access` → `aim_investigate_employees` → `aim_gather_evidence` → `aim_exploit_infrastructure` → `aim_confront_insider` | Steps 1–26 | ✅ covered |
| `patricia_office`, `open_office_area`, `research_lab`, `break_room` rooms | Steps 2–6 | ✅ covered |
| `data_center` room + upload terminal | Step 18 | ✅ covered |
| Identify Torres / confrontation / final choice (ink-driven) | Steps 20–24 | ⚠️ no puzzle-graph node (conversation-gated, not a lock) — expected, matches m04's `confront_voltage`/`report_to_0x99` precedent |
| `financial_records_access`, `research_badge` item types held by Patricia/Chen | Steps 2, 5 | ⚠️ **needs sprite** — see Known Gaps; not a dependency gap, purely a missing asset |

No dependency the walkthrough relies on is absent from the graph. The only graph/walkthrough gaps are the expected ones: conversation-gated story beats (identify/confront Torres, the final choice, the debrief) that the puzzle graph intentionally does not model as locks, matching the precedent set in `m04_critical_failure`.

## Testing Checklist

- [ ] Opening briefing plays once; `receive_mission_briefing` completes on exit.
- [ ] Patricia hands a Visitor Badge; `meet_handler` and `obtain_security_badge` complete; `investigate_employees` unlocks.
- [ ] Kevin's five items are all takeable and recoverable; `find_lockpick`, `obtain_rfid_cloner`, `obtain_torres_keycard` complete.
- [ ] Torres office opens with his keycard; medical bills + journal raise `evidence_level` and complete their tasks.
- [ ] Badge clone completes `clone_employee_badge`; server hallway + server room open in sequence.
- [ ] All four flags submit and complete; `architect_approval_confirmed` sets on flag_4.
- [ ] Data center opens with the key; upload schedule picked up.
- [ ] Naming Torres at `evidence_level >= 5` completes `identify_torres` and unlocks the Recruiter's call.
- [ ] All five confrontation endings reachable and each sets a distinct `final_choice` value.
- [ ] Combat path: Torres goes hostile, KO triggers `post_ko_choice`, both sub-choices (`combat_nonlethal`/`combat_lethal`) complete `make_critical_choice` and `stop_final_exfiltration`.
- [ ] Closing debrief plays on any `final_choice` value; credits branch correctly per ending.

### Edge Cases — NPC-KO fallback trace

| NPC | Gated task(s) | KO fallback | Verdict |
|---|---|---|---|
| **Patricia Morgan** | `meet_handler`, `obtain_security_badge` | `taskOnKO: meet_handler`; Visitor Badge + Financial Records Access are `itemsHeld`/takeable → loot on KO | ✅ reaches conclusion |
| **Kevin Park** | `talk_to_kevin`, `find_lockpick`, `obtain_rfid_cloner`, `obtain_torres_keycard`, `clone_employee_badge` | `taskOnKO: talk_to_kevin`; all 5 items are `itemsHeld`/takeable; handler eventMapping on `kevin_ko` fires `completeTask: clone_employee_badge` directly | ✅ reaches conclusion |
| **Dr. Sarah Chen** | `talk_to_dr_chen`, `obtain_research_access` (both optional) | `taskOnKO: talk_to_dr_chen`; duplicate Research Lab Badge is takeable even though her personal badge is not | ✅ optional path unaffected either way |
| **Lisa Park** | `talk_to_lisa` (optional) | `taskOnKO: talk_to_lisa`; no items required | ✅ optional path unaffected either way |
| **David Torres** | `confront_torres`, `make_critical_choice`, `stop_final_exfiltration` | `taskOnKO: make_critical_choice`; `eventMapping: npc_ko:david_torres` → `post_ko_choice` conversation (auto-completes `confront_torres` via encounter, then offers cuff/leave choice → `combat_nonlethal`/`combat_lethal`); handler eventMapping on `torres_ko` also fires `completeTask: confront_torres` as a third, redundant safety net | ✅ reaches conclusion via a sixth path (KO before dialogue) that still resolves to one of the two combat endings |

Every named NPC has a working KO-first path to `missionConclusion`. Patricia's `identify_torres` is the sole task with no KO-safe fallback, and it is explicitly a non-blocking side objective (the validator surfaces this as a suggestion, not an error).

## Known Gaps

- **6 missing item-type sprites** (Phase 1 added these item types; no `.png` has been generated yet). The validator reports these as `❌ INVALID` (schema-blocking for a full pass, though `validate_scenario.rb`'s overall run still reports "Validation complete" because these are asset warnings, not JSON-schema failures). Missing files, and where they belong:
  - `assets/objects/employee_badge.png` — held by Kevin Park, `open_office_area`
  - `assets/objects/payment_records_document.png` — held by Drop-Site Terminal, `server_room` ("Data Package Staging Manifest")
  - `assets/objects/recruitment_timeline_document.png` — held by Drop-Site Terminal, `server_room` ("Recruitment Timeline")
  - `assets/objects/architect_approval_document.png` — held by Drop-Site Terminal, `server_room` ("Architect Approval Communications")
  - `assets/objects/research_badge.png` — held by Dr. Sarah Chen, `research_lab` ("Research Lab Badge")
  - `assets/objects/financial_records_access.png` — held by Patricia Morgan, `patricia_office` ("Employee Financial Records")

  These need pixel-art PNGs generated (128×128, matching the house style) — a separate asset task requiring sign-off on image-generation scope/cost before running. Not resolved in this pass.

- **3 doors without `puzzle_graph_unlocks` metadata** (`server_hallway`, `server_room`, `torres_office`) — the validator warns that the dungeon-graph key/door mapping is incomplete for these three locks (the keys themselves work fine in-game; this only affects the auto-generated graph's ability to draw the dependency edge). Cosmetic, not a gameplay defect.
- **7 ink "speaker prefix" suggestions** in `m05_dropsite_terminal.ink` (`Target:`, `Exploit:`, `Classification:`, `Subject:`, `Source:`, `Handler:`, `Recommendation:`) — these are intentional in-document labels (leaked staging manifest / recruitment timeline formatting), not misattributed dialogue. No action needed.

## Development Status

| Minigame | Status |
|---|---|
| person-chat (5 NPCs) | ✅ Implemented |
| phone-chat (briefing hub, Recruiter, closing debrief) | ✅ Implemented |
| VM launcher + flag-station (Bludit CMS, 4 flags) | ✅ Implemented |
| Item sprites | ⚠️ 6 missing — see Known Gaps |

---

Run `/scenario-design-review` for full objectives scaffolding analysis.
