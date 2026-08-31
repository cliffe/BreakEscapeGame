# Mission 8: "The Mole" — Solution Guide

Spoiler-complete walkthrough. The mole is **Agent 0x47 "Nightshade"**. The case
is proven on the GitList VM; the interviews and physical evidence are the
investigation layer that lets an attentive player deduce him first.

---

## Overview

SAFETYNET HQ, "The Citadel", after the Mission 7 leak that got two field agents
killed. Three suspects: Cipher (innocent), Phantom (innocent), Nightshade (the
mole). Exploit SAFETYNET's own GitList server for conclusive proof, confront
Nightshade, decide his fate, and learn ENTROPY's real M7 prize (the global threat
database) and the Architect's location (Tomb Gamma).

---

## Critical path

1. **Briefing (Director's Office, north).** Talk to Director Netherton. Ask about
   the three suspects; optionally state a working theory. Take his **all-zones
   keycard**. → completes `brief_with_netherton`, unlocks the investigation.
2. **Get into the Server Room (east of Ops Floor) [RFID].** Use Netherton's
   keycard. *(Redundant: clone a badge at the lobby printer.)*
3. **Exploit GitList** at the VM terminal, submit flags at the Evidence Relay:
   - **Flag 1** — GitList argument-injection RCE (no login).
   - **Flag 2** — stashed credentials from repo history.
   - **Flag 3** — log in properly → home directory holds the ENTROPY
     correspondence.
   - **Flag 4** — `sudo apt-get` → root → access logs place the mole.
   Flag 4 sets `all_flags_submitted` and `mole_identified` (it's Nightshade).
4. **Open the Interrogation Room (south of Crypto Lab) [KEY].** The key is in the
   **Director's Safe** (PIN **2407**, found on Nightshade's personnel record on the
   Ops Floor, or ask ATHENA). *(Redundant: lockpick from your start inventory.)*
5. **Confront Nightshade.** Entering with the case made reveals him. Work the
   topic hub (why / recruitment / the database theft / the Architect), then choose
   his fate.
6. **Decide the fate** at the disposition terminal (arrest or triple agent), then
   **report to Director Netherton** in the Break Room. → mission complete,
   `bond_visualiser`.

---

## The investigation layer (autonomy / optional but rewarding)

- **Interview all three suspects.** Each has an alibi and points at the others:
  - **Cipher (Ops Floor):** odd hours = a classified post-quantum project. His
    badge was never on the mission_planning share. Accusing him after seeing his
    alibi wounds an innocent man.
  - **Phantom (Intel Analysis):** the "suspicious" behaviour is his own off-book
    mole hunt. Airborne during the leak window (flight manifest). **Read his notes**
    (`phantom_notes`) to unlock his Crypto-Lab lead → points at Nightshade.
  - **Nightshade (Crypto Lab):** unnervingly calm. Asking about his composure, the
    dead, or (after reading the psych eval) Dr Chen's warning sets
    `nightshade_suspected` and earns a chilling non-denial.
- **Physical evidence** corroborates the digital case: `tactical_board` (two dead,
  the leak), `nightshade_profile` (Dr Chen's buried warning), `encrypted_backup`
  (base64→ROT13 ENTROPY mail), `deep_state_manual`, `database_catalog` (the M7
  theft), `timeline_reconstruction`, `server_access_logs`.

---

## Locks & codes

| Lock | Where | Solution | Redundant |
|---|---|---|---|
| RFID | Server Room | Netherton's keycard | Lobby badge printer clone |
| Password | Security Archives | `TrustNoOne` | Break-room post-it / ATHENA |
| PIN | Director's Safe | `2407` | Personnel record (Ops) / ATHENA |
| Key | Interrogation Room | key from safe | Start-inventory lockpick |

---

## Moral choice — Nightshade's fate

At the confrontation and the disposition terminal:

- **Arrest** (`nightshade_arrested`): trial, no intelligence, the clean line.
- **Turn triple agent** (`nightshade_triple_agent`): intelligence at the cost of
  using a man who traded lives; Netherton signs it uneasily.

Either way he gives up **Tomb Gamma** (47.2382° N, 112.5156° W, Montana) — the
Architect's workshop and where the stolen database went. A stance in the debrief
(`debrief_stance`: defended / owned) records whether the player lets Netherton off
the hook for burying Dr Chen's warning. All feed the `bond_visualiser` credits.

*Note:* the philosophy ("entropy is inevitable") is argued and **rejected** — the
mission never endorses it.

---

## Full success checklist

- All 4 VM flags submitted; mole identified on the evidence.
- All three suspects interviewed; no innocent left wrongly accused (or corrected).
- Nightshade's fate chosen deliberately; Tomb Gamma secured.
- Database theft understood (read `tactical_board` / `database_catalog`).
- Debriefed with Netherton.
