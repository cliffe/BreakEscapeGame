// ===========================================
// PRESS TERMINAL — Mission 2: Ransomed Trust
// Break Escape - Physical Exposure Decision
//
// The player physically acts to expose or suppress the hospital's negligence.
// Located in the conference room -- the scene of the board's original budget decision.
// Replaces the secondary_decision from the ransom terminal.
// ===========================================

EXTERNAL player_name()

=== start ===
#speaker:computer

HOSPITAL COMMUNICATIONS TERMINAL

Secure outgoing relay — St. Catherine's regional press network.
14 media recipients. 3 national health correspondents. SAFETYNET Evidence Archive.

Available for transmission:
- Board liability email (cover-up plan, Marcus Webb scapegoating)
- FY2024 Budget Report ($85K security deferred, $3.2M MRI approved)
- Marcus Webb security advisory archive (May–November 2024, 7 formal warnings)

Transmission is irreversible. Once sent, this evidence enters permanent public record.

-> decision_menu

=== decision_menu ===

+ [Upload all evidence — make the negligence public]
    -> confirm_upload

+ [Leave evidence undisclosed — protect hospital reputation]
    -> confirm_stay_quiet

+ [Exit terminal]
    #exit_conversation
    -> DONE

// ===========================================
// UPLOAD PATH
// ===========================================

=== confirm_upload ===
#speaker:computer

CONFIRM UPLOAD?

The board chair's cover-up memo, the budget decisions, and six months of Marcus Webb's ignored security warnings will be authenticated, attributed, and transmitted.

St. Catherine's board cannot suppress this.

Marcus Webb's warnings enter public record.

+ [Confirm — upload everything]
    -> do_upload

+ [Go back]
    -> decision_menu

=== do_upload ===
#speaker:computer

TRANSMITTING...

[SENT] Board liability email — Hospital Board Chair to Legal Department
[SENT] FY2024 Budget Report — IT security deferral vs MRI approval
[SENT] Marcus Webb advisory archive — 7 warnings, 0 actioned responses, May–November 2024

TRANSMISSION COMPLETE.

14 media recipients confirmed. SAFETYNET Evidence Archive: logged.

St. Catherine's board will face a public inquiry within 48 hours.

Marcus Webb's warnings are on record. His vindication is not an internal matter anymore.

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

The board liability email, budget decisions, and Marcus Webb's warning archive remain confidential.

St. Catherine's reputation protected. Board members retain their positions.

Marcus Webb's situation remains an internal matter.

The sector-wide vulnerability profile does not become public knowledge.

+ [Confirm — keep it internal]
    -> do_stay_quiet

+ [Go back]
    -> decision_menu

=== do_stay_quiet ===
#speaker:computer

Evidence retained. No transmission.

St. Catherine's board has privately committed to a full security overhaul. Marcus Webb's employment situation will be resolved through internal channels.

The sector-wide risk profile — 214 hospitals scanned, 147 with critical vulnerabilities — remains unpublished.

Other hospitals will not learn from this until something similar happens to them.

#complete_task:decide_hospital_exposure
#set_global:exposed_hospital:false
#set_global:mission_complete:true
#exit_conversation
-> DONE
