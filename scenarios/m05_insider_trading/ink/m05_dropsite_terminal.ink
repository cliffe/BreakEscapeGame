// ===========================================
// Mission 5: Drop-Site Terminal
// VM Flag Submission & Intelligence Processing
// ===========================================

VAR flag1_submitted = false
VAR flag2_submitted = false
VAR flag3_submitted = false
VAR flag4_submitted = false

// Flag values for player demonstration
VAR bludit_server_discovered = false
VAR traversal_files_found = false
VAR root_access_achieved = false
VAR architect_approval_confirmed = false

// External variables
VAR player_name = "Agent 0x00"

// ===========================================
// TERMINAL MAIN HUB
// ===========================================

=== start ===
#speaker:computer

SAFETYNET DROP-SITE TERMINAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Secure intelligence submission channel for Operation Insider Trading.

Submit intercepted ENTROPY communications for analysis and resource unlocking.

Target: David Torres' Bludit CMS Server
Exploit: CVE-2019-16113 (Directory Traversal, Auth Bypass)

FLAGS REQUIRED: 4

-> flag_submission_hub

=== flag_submission_hub ===

+ {not flag1_submitted} [Submit FLAG 1: Reconnaissance]
    -> submit_flag1

+ {not flag2_submitted} [Submit FLAG 2: File System Access]
    -> submit_flag2

+ {not flag3_submitted} [Submit FLAG 3: Privilege Escalation]
    -> submit_flag3

+ {not flag4_submitted} [Submit FLAG 4: Architect Communications]
    -> submit_flag4

+ {flag1_submitted or flag2_submitted or flag3_submitted or flag4_submitted} [View Intelligence Summary]
    -> intelligence_summary

+ [Exit terminal]
    #exit_conversation
    -> DONE

// ===========================================
// FLAG 1: RECONNAISSANCE
// ===========================================

=== submit_flag1 ===
#speaker:computer

FLAG SUBMISSION INTERFACE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter flag from Bludit server reconnaissance:

[Player enters: flag{bludit_server_discovered}]

Drop-Site Terminal: Verifying...

Drop-Site Terminal: ✓ FLAG VERIFIED

Drop-Site Terminal: Reconnaissance data extracted:
- Bludit CMS version 3.9.2 (vulnerable to CVE-2019-16113)
- Server hosted on Digital Vanguard infrastructure
- Encrypted database containing ENTROPY communications
- Upload history: 47 encrypted archives

~ flag1_submitted = true
#complete_task:submit_flag1_reconnaissance
#unlock_task:exploit_directory_traversal

+ [Continue]
    Drop-Site Terminal: Intelligence level increased. Unlocking exploit path.
    -> flag_submission_hub

// ===========================================
// FLAG 2: FILE SYSTEM ACCESS
// ===========================================

=== submit_flag2 ===
#speaker:computer

FLAG SUBMISSION INTERFACE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter flag from directory traversal:

[Player enters: flag{traversal_files_found}]

Drop-Site Terminal: Verifying...

Drop-Site Terminal: ✓ FLAG VERIFIED

Drop-Site Terminal: Staging manifest extracted:
- quantum-safe_key_material_v3.tar.gpg — lattice-based key exchange parameters, production candidate set
- dispatch_network_rollout_schedule.xlsx — National Emergency-Services Dispatch Network (999 call routing), phased cutover dates by region, marked DO NOT DISTRIBUTE OUTSIDE QDC / HOME OFFICE LIAISON
- Transfer method: staged locally, pushed via encrypted channel to "The Recruiter" (TalentStack Executive Recruiting — cover entity)
- Torres's own notes found alongside the manifest: Elena's bills, $380,000 and climbing

~ flag2_submitted = true
#complete_task:submit_flag2_file_access
#unlock_task:escalate_privileges
#give_item:notes:Data Package Staging Manifest

+ [Continue]
    Drop-Site Terminal: Staging manifest added to evidence. The transfer chain to the Recruiter is established.
    -> flag_submission_hub

// ===========================================
// FLAG 3: PRIVILEGE ESCALATION
// ===========================================

=== submit_flag3 ===
#speaker:computer

FLAG SUBMISSION INTERFACE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter flag from privilege escalation:

[Player enters: flag{root_access_achieved}]

Drop-Site Terminal: Verifying...

Drop-Site Terminal: ✓ FLAG VERIFIED

Drop-Site Terminal: Root access granted. Full database decrypted.

Drop-Site Terminal: Torres recruitment timeline extracted:
- INITIAL CONTACT: 3 months ago (TalentStack "career consultation")
- FINANCIAL PRESSURE: Elena's medical debt identified via financial distress screening
- ACCESS EVALUATION: TS/SCI clearance, Project Heisenberg lead — high value target
- GRADUAL COMPROMISE: Started with "harmless" financial data
- FULL RECRUITMENT: 6 weeks ago (acquisition authorised by The Architect)

~ flag3_submitted = true
#complete_task:submit_flag3_privilege_escalation
#unlock_task:extract_architect_comms
#give_item:notes:Recruitment Timeline

+ [Continue]
    Drop-Site Terminal: Recruitment methodology exposed. ENTROPY pattern confirmed.
    -> flag_submission_hub

// ===========================================
// FLAG 4: ARCHITECT COMMUNICATIONS
// ===========================================

=== submit_flag4 ===
#speaker:computer

FLAG SUBMISSION INTERFACE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter flag from Architect's encrypted communications:

[Player enters: flag{architect_approval_confirmed}]

Drop-Site Terminal: Verifying...

Drop-Site Terminal: ✓ FLAG VERIFIED - CRITICAL INTELLIGENCE

Drop-Site Terminal: The Architect's acquisition authorisation, decoded from base64:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROJECT HEISENBERG -- ACQUISITION AUTHORISATION
Classification: ENTROPY EYES ONLY -- INSIDER THREAT INITIATIVE

Subject: Quantum-safe key material, National Emergency-Services
Dispatch Network (999 call routing) rollout schedule
Source: D. Torres, CSO, Quantum Dynamics Corporation (recruited asset)
Handler: The Recruiter (cover: TalentStack Executive Recruiting)

DISPOSITION: This capability is not for resale. ENTROPY retains and
integrates directly. No foreign buyer has been, or will be, offered
this package.

RECRUITER'S ASSESSMENT OF SOURCE:
Torres was identified via financial distress screening. Wife's
medical debt ($380,000, non-negotiable, insurer denied trial coverage)
made him a high-probability convert. Two dependents (ages 11 and 8)
increase compliance and reduce flight risk. Our operating philosophy
holds: every person has a price. Torres's was cheaper than most --
debt relief and a standing consultancy retainer. He is a line item,
not a partner. Expect him to be unusable within 18 months; plan
disposal accordingly.

OPERATIONAL IMPACT -- CASUALTY PROJECTION:
Deployment of the compromised key material during the scheduled
key-rotation window will require the dispatch network to fail over
to a degraded routing path for an estimated 40-70 minutes per
affected region. During this window, ambulance, fire, and police
dispatch latency increases by an average of 6-11 minutes per call.

Modelled outcome across the twelve regions in the first rollout
wave: projected 30-45 excess civilian deaths attributable to delayed
emergency response during the degraded-routing interval, concentrated
among cardiac, stroke, and structure-fire incidents where minutes
are decisive.

This figure has been reviewed and is filed as an acceptable cost of
acquiring the capability. No mitigation is authorised that would
also alert QDC or the Home Office liaison to the intrusion.

AUTHORISATION: Proceed with acquisition and integration as staged.
-- The Architect
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

~ flag4_submitted = true
#complete_task:submit_flag4_architect_comms
#unlock_aim:correlate_evidence
#give_item:notes:Architect Approval Communications

+ [This is damning evidence]
    -> architect_analysis

=== architect_analysis ===
#speaker:computer

Drop-Site Terminal: CRITICAL INTELLIGENCE ACQUIRED

Analysis:
- The Architect personally authorised the acquisition, casualty projection included
- Torres is explicitly classified as "a line item, not a partner" — disposal already planned
- Thirty to forty-five excess civilian deaths filed as an acceptable cost
- Proves premeditated organisational responsibility, not a rogue insider acting alone

Recommendation: Evidence sufficient for confrontation and prosecution.

#speaker:agent_0x99

[Agent 0x99 contacts you immediately]

Agent 0x99: {player_name}, I just read the Architect's authorisation. This is the whole case.

Agent 0x99: Torres knew the casualty projection. The Recruiter told him explicitly what it would cost.

Agent 0x99: How you handle the confrontation — that's your call. Good luck.

+ [Understood]
    #exit_conversation
    -> flag_submission_hub

// ===========================================
// INTELLIGENCE SUMMARY
// ===========================================

=== intelligence_summary ===
#speaker:computer

INTELLIGENCE SUMMARY - OPERATION INSIDER TRADING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FLAGS SUBMITTED: {flag1_submitted:1|0} + {flag2_submitted:1|0} + {flag3_submitted:1|0} + {flag4_submitted:1|0} = Total

{flag1_submitted:
    ✓ FLAG 1: Server reconnaissance complete
       • Bludit CMS vulnerable server identified
       • Digital Vanguard infrastructure confirmed
    
}

{flag2_submitted:
    ✓ FLAG 2: File system access achieved
       • Staging manifest: quantum-safe key material + dispatch rollout schedule
       • Transfer chain to "The Recruiter" confirmed

}

{flag3_submitted:
    ✓ FLAG 3: Privilege escalation successful
       • Full recruitment timeline extracted
       • 3-month radicalization process exposed

}

{flag4_submitted:
    ✓ FLAG 4: Architect authorisation decoded
       • Acquisition of 999 dispatch network key material confirmed — not a sale
       • Casualty projection: 30-45 excess civilian deaths, first rollout wave
       • Torres classified as "a line item, not a partner"

}

{flag1_submitted and flag2_submitted and flag3_submitted and flag4_submitted:
    STATUS: FULL INTELLIGENCE PACKAGE ACQUIRED
    RECOMMENDATION: Proceed to evidence correlation and confrontation
    
}

+ [Return to main menu]
    -> flag_submission_hub

// ===========================================
// EXTERNAL EVENT: All Flags Submitted
// ===========================================

=== on_all_flags_complete ===
#speaker:agent_0x99

Agent 0x99: All four flags submitted. Outstanding work, {player_name}.

Agent 0x99: You have the full digital evidence chain.

Agent 0x99: Correlate this with physical evidence and you'll be ready to confront the insider.

#exit_conversation
-> END
