// ===========================================
// PRESS TERMINAL — Mission 2: Ransomed Trust
// Break Escape - Physical Exposure Decision
//
// The player physically acts to expose or suppress the hospital's negligence.
// Located in the conference room -- the scene of the board's original budget decision.
// Replaces the secondary_decision from the ransom terminal.
// ===========================================

EXTERNAL player_name()

// Synced from globalVars. The exposure decision is the LAST act of the mission
// and setting mission_complete here launches the debrief -- so the terminal must
// stay locked until BOTH gates clear:
//   backdoor_fully_exploited -> the technical investigation is done (full flag
//     chain: SSH -> ProFTPD -> database -> Ghost's operational log). The evidence
//     package can't be authenticated without it.
//   ransom_decision_made     -> the emergency itself has been resolved at the
//     recovery console.
// Without these a player can pick into the conference room early, release the
// evidence, and skip the entire technical mission.
VAR backdoor_fully_exploited = false
VAR ransom_decision_made = false

=== start ===
#speaker:computer

{not backdoor_fully_exploited:
    -> relay_locked_investigation
}
{not ransom_decision_made:
    -> relay_locked_incident
}

HOSPITAL COMMUNICATIONS TERMINAL

Secure outgoing relay — St. Catherine's regional press network.
14 media recipients. 3 national health correspondents. SAFETYNET Evidence Archive.

Available for transmission:
- Board liability email (cover-up plan, Gary Whitlock scapegoating)
- FY2024 Budget Report (£85,000 security deferred, £3.2 million MRI approved)
- Gary Whitlock security advisory archive (May–November 2024, 7 formal warnings)
- SAFETYNET forensic record (ENTROPY backdoor, decryption keys recovered)

Transmission is irreversible. Once sent, this evidence enters permanent public record.

-> decision_menu

// ===========================================
// GATES: the investigation must be complete AND the incident resolved
// before the SAFETYNET evidence package will authenticate for release
// ===========================================

=== relay_locked_investigation ===
#speaker:computer

HOSPITAL COMMUNICATIONS TERMINAL

>>> OUTGOING RELAY LOCKED <<<

Evidence package FAILED AUTHENTICATION.

The SAFETYNET forensic record is incomplete. A public submission must include verified proof of the intrusion -- the exploited backdoor and the recovered decryption keys. Right now there is nothing on file to prove how ENTROPY got in.

Finish working the backup server. Recover the evidence off it. Then the archive will accept a release.

#exit_conversation
-> DONE

=== relay_locked_incident ===
#speaker:computer

HOSPITAL COMMUNICATIONS TERMINAL

>>> OUTGOING RELAY LOCKED <<<

Evidence release held: incident still active.

The forensic record checks out, but the emergency is not yet resolved. Patient systems must be recovered and the ransom decision logged at the recovery console before this evidence can go to public record.

Resolve the incident first. Then decide what the world gets to see.

#exit_conversation
-> DONE

=== decision_menu ===

+ [I'm transmitting everything. The public needs to see this.]
    -> confirm_upload

+ [I'm leaving this undisclosed. The hospital's reputation stays intact.]
    -> confirm_stay_quiet

+ [I'll step away from the terminal for now.]
    #exit_conversation
    -> DONE

// ===========================================
// UPLOAD PATH
// ===========================================

=== confirm_upload ===
#speaker:computer

CONFIRM UPLOAD?

The board chair's cover-up memo, the budget decisions, and six months of Gary Whitlock's ignored security warnings will be authenticated, attributed, and transmitted.

St. Catherine's board cannot suppress this.

Gary Whitlock's warnings enter public record.

+ [Confirmed. Send it all.]
    -> do_upload

+ [Wait -- let me reconsider.]
    -> decision_menu

=== do_upload ===
#speaker:computer

TRANSMITTING...

[SENT] Board liability email — Hospital Board Chair to Legal Department
[SENT] FY2024 Budget Report — IT security deferral vs MRI approval
[SENT] Gary Whitlock advisory archive — 7 warnings, 0 actioned responses, May–November 2024

TRANSMISSION COMPLETE.

14 media recipients confirmed. SAFETYNET Evidence Archive: logged.

St. Catherine's board will face a public inquiry within 48 hours.

Gary Whitlock's warnings are on record. His vindication is not an internal matter anymore.

Forty-three other hospitals on ENTROPY's reconnaissance list will see this story. Some of them will patch their servers before anyone has to teach them the same lesson.

#complete_task:decide_hospital_exposure
#set_global:exposed_hospital:true
#set_global:mission_complete:true
#exit_conversation
-> DONE

// ===========================================
// SUPPRESS PATH
// ===========================================

=== confirm_stay_quiet ===
#speaker:computer

CONFIRM: Do not transmit?

The board liability email, budget decisions, and Gary Whitlock's warning archive remain confidential.

St. Catherine's reputation protected. Board members retain their positions.

Gary Whitlock's situation remains an internal matter.

The sector-wide vulnerability profile does not become public knowledge.

+ [Confirmed. Keep it internal.]
    -> do_stay_quiet

+ [Wait -- let me reconsider.]
    -> decision_menu

=== do_stay_quiet ===
#speaker:computer

Evidence retained. No transmission.

St. Catherine's board has privately committed to a full security overhaul. Gary Whitlock's employment situation will be resolved through internal channels.

The sector-wide risk profile — 214 hospitals scanned, 147 with critical vulnerabilities — remains unpublished.

Other hospitals will not learn from this until something similar happens to them.

#complete_task:decide_hospital_exposure
#set_global:exposed_hospital:false
#set_global:mission_complete:true
#exit_conversation
-> DONE
