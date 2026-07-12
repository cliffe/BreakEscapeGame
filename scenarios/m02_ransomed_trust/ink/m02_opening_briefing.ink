// ===========================================
// ACT 1: OPENING BRIEFING
// Mission 2: Ransomed Trust
// Break Escape - ENTROPY Cell: Ransomware Incorporated
// ===========================================

// Variables for tracking what player asked about (affects nothing in the debrief --
// the debrief is driven entirely by what the player actually does in the mission,
// not by a self-reported approach chosen here. See m01_opening_briefing.ink.)
VAR handler_trust = 50            // 0-100 Handler's confidence in player
VAR knows_full_stakes = false     // Did player ask about patient risk?
VAR knows_timeline = false        // Did player ask about time pressure?

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// OPENING
// ===========================================

=== start ===
#speaker:agent_0x99

{player_name()}, thanks for getting here fast.

We have an emergency situation at St. Catherine's Regional Medical Center.

* [I'm listening. Go ahead.]
    ~ handler_trust += 5
    -> briefing_main

* [What's happened?]
    -> briefing_main

* [I'm ready. What's the mission?]
    ~ handler_trust += 10
    Agent HaX: Good. Let's get straight to it.
    -> briefing_main

// ===========================================
// MAIN BRIEFING
// ===========================================

=== briefing_main ===
#speaker:agent_0x99

Agent HaX: Hospital ransomware attack. ENTROPY signature detected--Ransomware Incorporated.

Agent HaX: 47 patients on life support. Backup power holds 12 hours.

Agent HaX: If systems aren't restored... the math gets ugly.

* [How much time do we have?]
    ~ knows_timeline = true
    -> timeline_explanation

* [What's the actual risk to those patients?]
    ~ knows_full_stakes = true
    ~ handler_trust += 5
    -> patient_risk_explanation

* [Ransomware Incorporated -- what do we know?]
    -> entropy_explanation

=== timeline_explanation ===
#speaker:agent_0x99

Agent HaX: 12 hours of backup power. Maybe less if systems fail cascading.

Agent HaX: Hospital board's voting on paying the ransom in 4 hours.

Agent HaX: We need to recover decryption keys before they make that decision.

+ [Understood. What's the plan?]
    -> mission_objectives

+ {not knows_full_stakes} [What's the risk to patients?]
    ~ knows_full_stakes = true
    ~ handler_trust += 5
    -> patient_risk_explanation

=== patient_risk_explanation ===
#speaker:agent_0x99

Agent HaX: 47 patients: ventilators, ECMO, dialysis. All dependent on networked systems.

Agent HaX: Statistical risk increases every hour. 0.3% per hour without full systems.

Agent HaX: If we hit 12 hours... 4-6 expected fatalities. Those are real people.

+ [Those are real lives. We have to move fast.]
    ~ handler_trust += 5
    Agent HaX: Exactly. Every minute counts.
    -> mission_objectives

+ [If they pay, systems restore faster, right?]
    -> ransom_preliminary_discussion

=== ransom_preliminary_discussion ===
#speaker:agent_0x99

Agent HaX: Yes. Ransom payment gets decryption keys immediately--maybe 1-2 patient deaths.

Agent HaX: But that's $87,000 funding ENTROPY's next attack.

Agent HaX: This won't be a simple mission, agent.

+ [I understand the stakes]
    ~ knows_full_stakes = true
    -> mission_objectives

=== entropy_explanation ===
#speaker:agent_0x99

Agent HaX: Ransomware Incorporated. They believe suffering "teaches resilience."

Agent HaX: Not profit-motivated--ideologically driven. They calculate harm.

Agent HaX: Ghost's their operative. Cold, methodical. No remorse.

+ [How do we stop them?]
    -> mission_objectives

+ [They calculated how many people might die?]
    Agent HaX: Spreadsheet of projected fatalities. This is ENTROPY's ideology.
    ~ knows_full_stakes = true
    -> mission_objectives

+ [This isn't ENTROPY's first operation, is it?]
    Agent HaX: No. It isn't. Social Fabric ran a misinformation campaign out of Viral Dynamics -- Operation Shatter. Same network. Same playbook.
    Agent HaX: Different cell, but every one of them answers to the same person. The Architect. We still don't have a name.
    Agent HaX: Ransomware Incorporated is another head on the same body. Cut carefully -- and watch what it tells you about the rest.
    -> mission_objectives

// ===========================================
// MISSION OBJECTIVES
// ===========================================

=== mission_objectives ===
#speaker:agent_0x99

Agent HaX: Your objectives:

Agent HaX: One--infiltrate St. Catherine's as external security consultant.

Agent HaX: Two--access hospital's IT systems, identify attack vector.

Agent HaX: Three--exploit ENTROPY's backdoor on backup server, recover decryption keys.

* [What's my cover story?]
    -> cover_story

* [What about hospital security?]
    -> security_warning

* [I'm ready to go]
    -> final_instructions

=== cover_story ===
#speaker:agent_0x99

Agent HaX: You're a cybersecurity consultant brought in for emergency recovery.

Agent HaX: Dr. Sarah Kim, Hospital CTO, is expecting you. She'll grant access.

Agent HaX: Staff is stressed, desperate. Use that. Build trust.

+ [Understood]
    -> security_warning

=== security_warning ===
#speaker:agent_0x99

Agent HaX: Security is heightened. Guards patrolling. Stay low profile.

Agent HaX: You'll need lockpicking, social engineering, and technical exploitation. Read the room as you go.

+ [I can handle it]
    -> final_instructions

+ [What else should I know?]
    Agent HaX: IT admin is named Marcus Webb. He warned them about vulnerabilities six months ago.
    Agent HaX: They ignored him. Now he's devastated. Might be an ally.
    -> final_instructions

// ===========================================
// FINAL INSTRUCTIONS
// ===========================================

=== final_instructions ===
#speaker:agent_0x99

Agent HaX: You'll have comms support. Call if you need guidance.

* [Any last advice?]
    Agent HaX: Marcus Webb, the IT admin. He's guilty and desperate.
    Agent HaX: That makes him vulnerable. Build trust, get access.
    Agent HaX: And watch for Ghost. They're calculated. Expect spreadsheets, not rage.
    -> deployment

* [I'm ready to go]
    -> deployment

=== deployment ===
#speaker:agent_0x99

Agent HaX: Good luck, {player_name()}.

Agent HaX: 47 lives. 12 hours. SAFETYNET is counting on you.

{knows_full_stakes:
    Agent HaX: And remember--those patient deaths? They're on ENTROPY, not you.
    Agent HaX: Do your best. That's all anyone can ask.
}

#complete_task:receive_mission_briefing
#unlock_aim:infiltrate_hospital
#start_gameplay
#exit_conversation

-> END
