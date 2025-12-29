// ===========================================
// ROBERT CHEN - FACILITY MANAGER (ALLY NPC)
// Mission 4: Critical Failure
// Break Escape - Character Arc: Defensive → Alarmed → Committed Ally
// ===========================================

// Variables for tracking relationship and mission state
VAR chen_trust_level = 0          // 0-100 trust/cooperation level
VAR revealed_mission = false       // Has player revealed SAFETYNET mission?
VAR chen_is_ally = false          // Full ally status activated
VAR chen_provided_keycard = false
VAR discussed_optigrid = false
VAR scada_threat_confirmed = false

// Game state variables
VAR operatives_defeated = 0
VAR urgency_stage = 0

// External variables (set by game)
EXTERNAL player_name()
EXTERNAL current_time()

// ===========================================
// CONVERSATION 1: INITIAL MEETING (Task 1.2)
// Location: Administration Office
// Function: First encounter, establish relationship
// ===========================================

=== initial_meeting ===
#speaker:robert_chen

// Chen looks up from desk, visibly tired and annoyed

State audit at 4 AM? You regulatory people have interesting schedules.

* [Just doing my job, Mr. Chen]
    ~ chen_trust_level += 5
    You: Just doing my job, Mr. Chen.
    -> chen_professional_response

* [I apologize for the inconvenience]
    ~ chen_trust_level += 10
    You: I apologize for the inconvenience. I know this is unexpected.
    -> chen_apologetic_response

* [There have been concerns about this facility]
    ~ chen_trust_level -= 5
    You: There have been concerns about this facility. I need to conduct a thorough review.
    -> chen_defensive_response

=== chen_professional_response ===
#speaker:robert_chen

Right. Well, I run a tight ship here despite our budget constraints.

Whatever boxes you need checked, let's get it done quickly—we have a facility to operate.

+ [I'll need access to employee records]
    -> access_request
+ [Tell me about recent maintenance work]
    ~ discussed_optigrid = true
    -> maintenance_question

=== chen_apologetic_response ===
#speaker:robert_chen

// Chen's expression softens slightly

I appreciate that. Look, I know you're doing your job.

It's just... we're understaffed, underfunded, and now I've got surprise inspections at dawn.

+ [I understand. This won't take long]
    ~ chen_trust_level += 10
    You: I understand the pressure you're under. I'll be as efficient as possible.
    -> chen_cooperation_gained

+ [Has there been unusual activity recently?]
    -> concerns_question

=== chen_defensive_response ===
#speaker:robert_chen

// Chen becomes defensive

Concerns? We passed our last three inspections with flying colors.

Our safety record is spotless. Who's been talking?

+ [It's routine, Mr. Chen. May I see employee records?]
    You: Just routine procedure. May I see your employee records?
    -> access_request_reluctant

+ [I need to be frank with you about something]
    You: Actually, I should be frank with you about why I'm really here.
    -> early_reveal_opportunity

=== access_request ===
#speaker:robert_chen

~ chen_trust_level += 3

Employee records? Fine. But I want to know what you're looking for.

We don't have anything to hide.

-> chen_provides_access

=== access_request_reluctant ===
#speaker:robert_chen

// Chen reluctantly agrees

Fine. But this better be routine. I've got 47 operators keeping 240,000 people supplied with clean water.

-> chen_provides_access

=== maintenance_question ===
#speaker:robert_chen

~ chen_trust_level += 5

Maintenance? We had OptiGrid Solutions in earlier this week for control system upgrades.

Routine stuff, all contracted properly. Background checks passed.

+ [OptiGrid Solutions? Can I see their access logs?]
    ~ chen_trust_level += 5
    You: I'd like to review those access logs if possible.
    -> optigrid_interest

+ [Any other contractors recently?]
    -> contractors_inquiry

=== optigrid_interest ===
#speaker:robert_chen

// Chen shows slight concern at specific interest

Sure, I can pull those. They checked out—proper credentials.

Is there a problem?

+ [Just being thorough]
    You: Just being thorough.
    -> chen_provides_access

+ [Actually, there's something you should know]
    You: Actually, there's something important you should know.
    -> early_reveal_opportunity

=== contractors_inquiry ===
#speaker:robert_chen

Just OptiGrid this month. We've had budget cuts—only essential maintenance.

That's why this surprise audit is... frustrating. We're doing our best with limited resources.

-> chen_provides_access

=== concerns_question ===
#speaker:robert_chen

Unusual activity? Not that I've noticed. Why?

+ [Just part of the inspection process]
    You: Standard question. Part of the inspection process.
    -> chen_provides_access

+ [I think we should talk privately]
    You: I think we should have a private conversation about something.
    -> early_reveal_opportunity

=== chen_cooperation_gained ===
#speaker:robert_chen

// Chen relaxes, becomes cooperative

Alright. What do you need?

Employee records, maintenance logs, facility access—I'll get you whatever you need.

-> chen_provides_access

=== chen_provides_access ===
#speaker:robert_chen

// Chen retrieves keycard from desk drawer

Here's a facility keycard—Level 1 access. That'll get you into most areas.

Restricted zones like the server room need higher clearance, but for an inspection you should be fine.

* [Thank you. I'll start with employee records]
    ~ chen_provided_keycard = true
    You: Thank you. I'll start reviewing employee records.
    -> initial_meeting_end_professional

* [I appreciate your cooperation]
    ~ chen_provided_keycard = true
    ~ chen_trust_level += 5
    You: I appreciate your cooperation, Mr. Chen.
    -> initial_meeting_end_grateful

* {discussed_optigrid} [About those OptiGrid technicians...]
    ~ chen_provided_keycard = true
    You: Before I start—about those OptiGrid technicians. I need the full details.
    -> optigrid_details_request

=== optigrid_details_request ===
#speaker:robert_chen

Three technicians, here for two days. Network infrastructure maintenance and SCADA optimization.

They had all the right paperwork. What's your concern?

+ [Nothing yet. Just compiling information]
    -> initial_meeting_end_professional

+ [I think we should talk about what's really happening here]
    -> early_reveal_opportunity

=== initial_meeting_end_professional ===
#speaker:robert_chen

Let me know if you need anything else. I'll be in the Control Room monitoring systems.

// TRIGGERS: Task 1.2 completion

#exit_conversation
-> initial_meeting

=== initial_meeting_end_grateful ===
#speaker:robert_chen

~ chen_trust_level += 5

Of course. And look... if you do find anything, let me know.

This facility is my responsibility. These people depend on us.

#exit_conversation
-> initial_meeting

// ===========================================
// EARLY REVEAL OPTION
// Player can choose to reveal mission early
// ===========================================

=== early_reveal_opportunity ===
#speaker:robert_chen

// Chen looks concerned

Alright, you've got my attention. What's this really about?

* [Tell Chen the truth about ENTROPY]
    -> chen_early_reveal

* [Never mind, continue with cover story]
    You: Nothing. Just being cautious. Let's continue the inspection.
    -> chen_maintains_cover

=== chen_early_reveal ===
#speaker:robert_chen

~ revealed_mission = true
~ chen_trust_level += 30

// Player reveals truth

You: Mr. Chen, I'm not actually a state auditor.

You: I'm with SAFETYNET. We have intelligence that ENTROPY operatives have infiltrated your facility.

You: They're planning an attack on your water treatment systems.

// Chen's face goes pale, sits down heavily

...What?

ENTROPY? Here? At my facility?

+ [Completely serious. Three operatives]
    ~ chen_trust_level += 10
    You: Completely serious. At least three operatives targeting your chemical dosing systems.
    -> chen_processes_threat

+ [The OptiGrid technicians—that was them]
    ~ chen_trust_level += 5
    You: Those OptiGrid technicians you mentioned? That was them. They weren't contractors.
    -> chen_optigrid_realization

=== chen_processes_threat ===
#speaker:robert_chen

My God. 240,000 people drink this water.

How much time do we have?

+ [Attack scheduled for 0800 hours]
    You: Our intelligence shows an attack scheduled for 0800 hours.
    -> chen_timeline_reaction

+ [I'm working to stop it, but I need your help]
    You: I'm working to identify and stop the attack. But I need your help.
    -> chen_commits_immediately

=== chen_optigrid_realization ===
#speaker:robert_chen

~ chen_trust_level += 10

// Chen's expression shows horror and guilt

I... I let them in. I signed off on their access.

They had proper credentials, background checks... Oh God, what have I done?

+ [You had no way of knowing. We need to act now]
    ~ chen_trust_level += 15
    You: You had no way of knowing. Their credentials were forged. Focus on stopping them now.
    -> chen_commits_to_helping

+ [Don't blame yourself. Help me stop them]
    ~ chen_trust_level += 10
    You: This isn't your fault. Help me stop them—that's what matters.
    -> chen_commits_to_helping

=== chen_timeline_reaction ===
#speaker:robert_chen

~ chen_trust_level += 5

// Checks clock, does mental calculation

That's less than four hours from now.

What do you need from me?

-> chen_commits_to_helping

=== chen_commits_immediately ===
#speaker:robert_chen

~ chen_trust_level += 15

// Chen stands, determined

Tell me what you need. Anything.

-> chen_commits_to_helping

=== chen_commits_to_helping ===
#speaker:robert_chen

~ chen_is_ally = true
~ chen_trust_level += 20

Facility access, SCADA system knowledge, anything.

400,000 people drink this water. We're stopping this.

I'll pull up all the access logs and SCADA monitoring data.

Meet me in the Control Room. We'll find what they did to my systems.

// TRIGGERS: Task 1.2 completion, chen_is_ally activated early

#exit_conversation
-> initial_meeting

=== chen_maintains_cover ===
#speaker:robert_chen

~ chen_trust_level -= 3

// Chen looks confused but lets it go

Alright... well, you know where to find me if you need something.

-> initial_meeting_end_professional

// ===========================================
// CONVERSATION 2: SCADA ANOMALY DISCOVERY (Task 1.4)
// Location: Control Room
// Function: Discover threat, mission reveal (if not done earlier)
// ===========================================

=== scada_anomalies ===
#speaker:robert_chen

// Chen at SCADA terminal when player approaches

{revealed_mission:
    // If mission already revealed
    I've been monitoring the systems. You were right—something's wrong.

    Look at these chemical dosing parameters. They shouldn't be changing like this.
- else:
    // If still maintaining cover
    Can I help you with something?

    These are the SCADA monitoring systems—they control the whole facility.
}

* [Examine the SCADA displays]
    -> scada_examination

* {revealed_mission} [What am I looking at?]
    You: Walk me through what I'm seeing.
    -> scada_technical_explanation

=== scada_examination ===
#speaker:robert_chen

// Player examines terminal, sees yellow warnings

{revealed_mission:
    ~ chen_trust_level += 10

    Those dosing rates shouldn't be changing outside of manual input from this terminal.

    Someone's got remote access to the system.
- else:
    // Chen notices player's concern

    You see something?

    Those parameters have been drifting for the past two days. My operators thought it was sensor issues.
}

* [This isn't sensor drift. The system is compromised]
    -> chen_realizes_threat

* {not revealed_mission} [Mr. Chen, I need to tell you something]
    You: Mr. Chen, I need to tell you something important.
    -> chen_mission_reveal_forced

=== scada_technical_explanation ===
#speaker:robert_chen

~ chen_trust_level += 5

// Chen points to displays

Normal chlorine dosing: 0.5 to 1.0 parts per million for disinfection.

These readings show gradual increases programmed over the past 48 hours.

If this continues to the levels they're targeting... it would be catastrophic.

+ [Can you tell what they're trying to do?]
    -> chen_technical_analysis

+ [How do we stop this?]
    -> chen_asks_how_to_stop

=== chen_realizes_threat ===
#speaker:robert_chen

{revealed_mission:
    ~ chen_trust_level += 10
    ~ scada_threat_confirmed = true

    The attack you mentioned—this is it, isn't it?

    They're setting up a mass contamination event.
- else:
    // Chen becomes alarmed

    Compromised? What are you talking about?

    Who are you really?

    -> chen_mission_reveal_forced
}

+ [Can you tell what they're trying to do?]
    -> chen_technical_analysis

+ [How do we stop this?]
    -> chen_asks_how_to_stop

=== chen_mission_reveal_forced ===
#speaker:robert_chen

// Mission reveal becomes necessary

~ revealed_mission = true
~ chen_trust_level += 20
~ scada_threat_confirmed = true

You: I'm not a state auditor. I'm with SAFETYNET.

You: ENTROPY operatives have infiltrated your facility. They're planning to weaponize your chemical dosing systems.

// Chen's face goes pale

...400,000 people.

My God. How long do we have?

+ [They're scheduled to execute at 0800 hours]
    You: Our intelligence shows execution at 0800 hours.
    -> chen_timeline_reaction_forced

+ [I'm working to identify and stop the attack]
    You: I'm working to stop it. But I need your help.
    -> chen_commits_to_stopping_attack

=== chen_timeline_reaction_forced ===
#speaker:robert_chen

~ chen_trust_level += 5
~ chen_is_ally = true

// Checks clock

Less than four hours.

What do you need from me?

-> chen_commits_to_stopping_attack

=== chen_technical_analysis ===
#speaker:robert_chen

~ chen_trust_level += 10

// Chen examines parameters closely, explains technically

They're increasing chlorine dosing rates while decreasing pH adjustment.

If this continues to the levels they've programmed... toxic byproducts in the treatment process.

The contamination wouldn't be immediate—it would build up over hours.

By the time anyone noticed, thousands would have consumed it.

+ [Can you override their control?]
    -> chen_override_risks

+ [I need to find how they're accessing the system]
    -> chen_suggests_server_room

=== chen_asks_how_to_stop ===
#speaker:robert_chen

~ chen_trust_level += 5

I could try manual override, but if they've corrupted the automation system...

We could trigger fail-safes. Or worse—trigger the attack early.

We need to find their control mechanism and disable it properly.

-> chen_suggests_server_room

=== chen_override_risks ===
#speaker:robert_chen

~ chen_trust_level += 5

Too risky. If they've set up trigger mechanisms, a crude override could accelerate the attack.

We need to find their control point and disable it methodically.

-> chen_suggests_server_room

=== chen_suggests_server_room ===
#speaker:robert_chen

~ chen_trust_level += 10
~ chen_is_ally = true

The server room. If they're accessing SCADA remotely, it's through our network infrastructure.

{operatives_defeated >= 1:
    // If player already defeated an operative

    You probably already have Level 2 access from... whoever you encountered.

    Be careful—there may be more of them.
- else:
    // Chen provides keycard

    I can give you access—Level 2 keycard.

    // Chen retrieves higher-level keycard

    Here. Server room is through the treatment floor.

    Be careful—if those operatives are still here...
}

* [I'll handle it]
    ~ chen_trust_level += 5
    You: I'll handle it. Stay here and monitor the systems.
    -> scada_conversation_end_determined

* [Thank you, Mr. Chen. I'll be careful]
    ~ chen_trust_level += 10
    You: Thank you. I'll be careful.
    -> scada_conversation_end_grateful

=== chen_commits_to_stopping_attack ===
#speaker:robert_chen

~ chen_is_ally = true
~ chen_trust_level += 15

Tell me what you need.

Facility access, SCADA knowledge, system overrides—anything.

-> chen_suggests_server_room

=== scada_conversation_end_determined ===
#speaker:robert_chen

I'll keep monitoring from here.

Call me if you need technical support—I know every system in this facility.

// TRIGGERS: Task 1.4 completion, Objective 1 complete, Objective 2 unlocked

#exit_conversation
-> initial_meeting

=== scada_conversation_end_grateful ===
#speaker:robert_chen

~ chen_trust_level += 10

Be careful out there.

And... thank you. For taking this seriously. For protecting my people.

#exit_conversation
-> initial_meeting
