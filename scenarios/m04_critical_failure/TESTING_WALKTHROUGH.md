# Mission 4: "Critical Failure" — QA Walkthrough

**Setting:** Albion Energy Storage — 200 MWh grid-scale lithium-ion BESS
**Rewritten:** 2026-08-21, against the post-alignment mission. Supersedes the 2026-06-12 version,
which described three aims, the old room topology and a phone debrief — all since changed.
See [`ALIGNMENT_PLAN.md`](ALIGNMENT_PLAN.md) for why.

## Preconditions

- Ink: 10/10 compile **and** run clean (`scripts/ink_runtime_check/`).
- Validator: 0 errors, 0 room overlaps, 0 ink warnings.
- ⚠️ **VM flags are unverified.** `secgen/m04_critical_failure.xml` exists but has not been built,
  so flag order/count on `bms_jump_server` is inferred. Steps 8–11 cannot be signed off until a
  SecGen build confirms them.
- ⚠️ Two field guides (`distcc-exploitation`, `rfid-cloning`) 404 until HacktivityLabSheets is rebuilt.

## Room spine

```
main_entrance (guard)
  └─S─ operations_office (Vance: Level 1)
         ├─S─ security_office            [key]    spare Level 1 in locker
         └─E─ scada_control_room
                └─S─ battery_hall_1 (Cipher → Level 2)
                       ├─S─ engineering_workshop   [rfid: Level 2]  VM + drop-site
                       └─E─ battery_hall_2 (Relay → Master) [rfid: Level 1]
                              └─S─ plant_room      [rfid: Master]   Voltage + Static + ESD
                                     └─E─ loading_dock [key]        Voltage's escape
```

---

## Aim 1 — Get Inside Albion Energy Storage

**1. Opening briefing.** Cutscene `opening_briefing_cutscene` plays once (`skipIfGlobal: briefing_played`)
and terminates with `-> END`. Expect Blackout named as the cell's authority and Voltage as his field
lieutenant. → `enter_facility` completes.

**2. Security guard.** Three routes: credentials, bluff, or slip past (raises the alarm).
*Check:* the guard is not mute — his NPC declares `currentKnot: "start"` and the ink defines it.

**3. Robert Vance, operations office.** → `meet_robert_vance` completes. He hands you a **Level 1** keycard (or it drops if you KO him; a spare is in the security locker).
*KO-safety:* `taskOnKO` covers the task, and a spare Level 1 sits in the security-office locker,
so a KO'd Vance cannot strand the mission.

## Aim 2 — Confirm the Telemetry Is Lying

**4. Evidence.** Maintenance work orders → `evidence_maintenance_logs_found` → HaX completes
`find_infiltration_evidence`.

**5. The analog thermometer** (battery hall 1) read against the falsified SCADA panel →
`anomaly_detected`, completing `identify_scada_anomalies`.
*Check:* **this starts both timers and the threat music cue.** Nothing before this point is on a clock.

## Aim 3 — Reach the Engineering Workshop

**6. Cipher** (battery hall 1). Detection bark → hostile via `#hostile`, or stall his radio and talk.
KO or secure → `neutralize_operative_cipher`. He drops **Level 2**.
*Check:* the card is recoverable after KO (`dropNPCItems`, no physics launch).

**7. Engineering workshop** [rfid: Level 2] → `locate_compromised_systems`.
*Check:* there is now only **one** door in — the old SCADA-room door that bypassed Cipher is gone.

## Aim 4 — Map the Attack on the OT Network

**8–11. VM + flags.** Launch **BMS Jump Server Terminal**, submit at the drop-site
(`acceptsVms: bms_jump_server`):

| Flag | Source | Task |
|---|---|---|
| flag_1 | falsified rack status page (web) | `submit_network_scan_flag` |
| flag_2 | ProFTPD — OptiGrid transfer | `submit_ftp_intel_flag` |
| flag_3 | sudo Baron Samedit | `submit_privesc_flag` |
| flag_4 | distcc CVE-2004-2687 | `submit_distcc_exploit_flag` |

*Check:* each task shows progress and completes on submission. **Unverified pending a SecGen build.**
On flag_4, HaX sets `attack_mechanism_known`.

## Aim 5 — Stop the Thermal Runaway *(mission conclusion)*

**12. Relay** (battery hall 2). → `neutralize_operative_relay`; drops **Master**.

**13. Plant room** [rfid: Master]. Static blocks; Voltage is at the laptop.

**14. Confrontation.** Optionally push him for the casualty figure — he states it and owns it.
Then three stances:

| Stance | Result |
|---|---|
| Fight | `#hostile`; KO sets `voltage_captured` |
| Arrest | stands down → `voltage_captured` |
| Go for the button | he reaches the dock → `voltage_escaped` |

*Critical check:* **every** branch fires `#complete_task:confront_voltage` (verified: 56/56 paths),
and `taskOnKO` covers a silent KO. If this ever regresses, the mission cannot conclude.

**15. ESD pushbutton.** Gated on `esd_authorized`, which requires **both** `anomaly_detected` and
`voltage_neutralised`.
*Check:* pressing it with Voltage still up should be refused with the two-part reason. Sets
`attack_prevented`, `mission_complete`, completes `disable_attack_vectors`, cancels both timers.

**16. Debrief.** Hidden-person cutscene on `mission_complete`, HQ background, `disableClose`.
*Check:* `#complete_task:report_to_0x99` fires at the **end**, so the `bond_visualiser` does not
appear over the debrief. Disclosure choice → credits.

---

## Timer paths (the partial-failure ending)

Both start on `anomaly_detected`, both cancel on `attack_prevented`.

- **T+22m — `h2_advisory`:** `hydrogen_alarm`, `urgency_stage: 3`, racks tint red and pulse,
  music escalates, countdown visible.
- **T+40m — `racks_vent`:** `racks_vented`, `casualties_occurred`, `urgency_stage: 4`.

*Check:* the run **does not end** here. The player can still reach the ESD; the debrief plays and
branches on `racks_vented`, and the credits read **COSTLY SUCCESS** with the casualty line.
There is deliberately no `show_end_screen` in this mission.

## Regression checks

1. Talk to every NPC repeatedly, including after KO — no "ran out of content", no empty choice list.
2. Re-open the HaX phone many times across mission states — the hub must never run dry.
3. KO Cipher and Relay in both orders — both keycards recoverable.
4. KO Vance — mission still completable via the spare Level 1.
5. Both endings satisfy `requiresCompleted:
   ["identify_scada_anomalies", "confront_voltage", "disable_attack_vectors"]`.
