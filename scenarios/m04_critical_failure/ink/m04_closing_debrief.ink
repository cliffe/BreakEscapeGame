// ===========================================
// CLOSING DEBRIEF - AGENT 0x99
// Mission 4: Critical Failure
// Break Escape - Mission Wrap-Up and Task Force Null Revelation
// ===========================================

// Variables for tracking debrief choices
VAR disclosure_choice = ""           // full, quiet, partial
VAR task_force_null_assigned = false // Player assigned to TF Null
VAR mission_debriefed = false        // Debrief completed

// Game state variables
VAR voltage_captured = false
VAR chen_trust_level = 0
VAR attack_vectors_disabled = 0
VAR operatives_defeated = 0

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// DEBRIEF START
// Location: Control Room (phone/video call)
// Task 3.3: Report Mission Outcome
// ===========================================

=== start ===
-> debrief_start

=== debrief_start ===
#speaker:agent_0x99

// Agent 0x99 on screen

{player_name()}, report. What's the status?

* [Attack prevented. Facility secure]
    You: Attack prevented. All three vectors disabled. The facility is secure.
    -> debrief_attack_stopped

* [Attack stopped. Voltage {voltage_captured: captured | escaped}]
    You: Attack fully prevented. Voltage has been {voltage_captured: captured | neutralized. He escaped.}
    -> debrief_voltage_status

=== debrief_attack_stopped ===
#speaker:agent_0x99

Good work. Contamination avoided, systems secured.

{chen_trust_level >= 70:
    Chen speaks highly of your work. Says you saved 240,000 lives.
}

{voltage_captured:
    And you captured Voltage. Excellent.
- else:
    Voltage escaped?
}

-> debrief_intelligence_gathered

=== debrief_voltage_status ===
#speaker:agent_0x99

{voltage_captured:
    Excellent. Voltage is high-value intelligence.

    His interrogation will provide significant insight into The Architect's infrastructure initiative.
- else:
    Unfortunate. But the attack is stopped—that's the priority.

    Lives saved matter more than one operative.
}

-> debrief_intelligence_gathered

=== debrief_intelligence_gathered ===
#speaker:agent_0x99

The intelligence you gathered confirms our worst fears.

Critical Mass and Social Fabric were coordinating this attack.

{voltage_captured:
    Voltage's interrogation has already begun. He's defiant, but he's confirming cross-cell operations.
- else:
    The documents you recovered show clear coordination between cells.
}

This wasn't random.

Social Fabric was ready with disinformation campaigns in three cities—they planned to amplify the panic from contamination.

* [The Architect is coordinating this]
    You: The Architect. They're coordinating all of this.
    -> debrief_architect_revelation

* [How extensive is the coordination?]
    You: How extensive is this coordination?
    -> debrief_scale_explanation

=== debrief_architect_revelation ===
#speaker:agent_0x99

Yes. We've intercepted communications mentioning "The Architect."

Someone is coordinating ENTROPY cells at a level we've never seen before.

This facility was a test run.

The Architect is planning something bigger—coordinated infrastructure attacks with synchronized disinformation campaigns.

-> debrief_task_force_announcement

=== debrief_scale_explanation ===
#speaker:agent_0x99

{voltage_captured:
    Voltage mentioned operations in six cities.

    OptiGrid Solutions—their cover company—has contracts at 40 facilities nationwide.

    We're running full security audits now.
- else:
    The documents reference operations in multiple cities.

    OptiGrid Solutions contracts appear at dozens of critical infrastructure sites.
}

This is coordinated at an unprecedented level.

-> debrief_task_force_announcement

=== debrief_task_force_announcement ===
#speaker:agent_0x99

SAFETYNET is forming a special task force dedicated to hunting The Architect and dismantling coordinated ENTROPY operations.

Task Force Null.

You're being assigned.

* [What's the mission?]
    You: What's Task Force Null's mission?
    -> task_force_mission_explanation

* [I'm ready]
    You: I'm ready. When do we start?
    -> task_force_accepted

=== task_force_mission_explanation ===
#speaker:agent_0x99

This isn't about stopping individual cells anymore.

We're going after the network. The Architect. The coordination infrastructure.

You've proven yourself across four missions now.

First Contact. Ransomed Trust. Ghost in the Machine. And now this—Critical Failure.

You're ready for this.

-> task_force_accepted

=== task_force_accepted ===
#speaker:agent_0x99

~ task_force_null_assigned = true

Good. Task Force Null briefing is tomorrow at 0600.

Now—there's one more decision to make.

This facility is secure. Attack prevented. No casualties.

But...

-> disclosure_decision

=== disclosure_decision ===
#speaker:agent_0x99

// Robert Chen present, listening

How do we handle this publicly?

The facility manager needs to know our approach.

* [Choice: Full Public Disclosure]
    You: Full public disclosure. People have a right to know.
    -> disclosure_full_public

* [Choice: Quiet Patch]
    You: Classify the incident. Let the facility patch vulnerabilities quietly.
    -> disclosure_quiet

* [Choice: Partial Disclosure]
    You: Acknowledge a security incident without full details. Controlled narrative.
    -> disclosure_partial

=== disclosure_full_public ===
#speaker:agent_0x99

~ disclosure_choice = "full"

Full transparency. We reveal the attack attempt, facility vulnerabilities, and ENTROPY threat.

// Robert Chen reacts

#speaker:robert_chen

{chen_trust_level >= 70:
    It'll damage the facility's reputation, but... people have a right to know how close this came.
- else:
    The public backlash will be severe. But I understand the reasoning.
}

#speaker:agent_0x99

Consequences:
- Public protected through awareness of infrastructure risks
- Facility reputation damaged
- Industry-wide security investigations triggered
- Political pressure for infrastructure funding

This will force systemic change.

Approved.

-> disclosure_outcome

=== disclosure_quiet ===
#speaker:agent_0x99

~ disclosure_choice = "quiet"

We classify the incident. Frame it as a "maintenance issue" that was resolved.

Facility patches vulnerabilities quietly.

// Robert Chen reacts

#speaker:robert_chen

{chen_trust_level >= 70:
    I understand the reasoning, but... is it right to hide this from the people we serve?
- else:
    Thank you. The facility can't afford the reputational damage right now.
}

#speaker:agent_0x99

Consequences:
- Public uninformed of risk
- Facility reputation intact
- Security upgrades done discretely
- No systemic pressure for change

Stability over transparency.

Approved.

-> disclosure_outcome

=== disclosure_partial ===
#speaker:agent_0x99

~ disclosure_choice = "partial"

Acknowledge a "security incident" without full details. Controlled narrative.

// Robert Chen reacts

#speaker:robert_chen

{chen_trust_level >= 70:
    A middle ground. People know something happened without full panic. I can work with that.
- else:
    Probably the most politically viable option.
}

#speaker:agent_0x99

Consequences:
- Moderate public awareness
- Balanced transparency and stability
- Some pressure for security improvements
- Controlled narrative

Balanced approach.

Approved.

-> disclosure_outcome

=== disclosure_outcome ===
#speaker:agent_0x99

Decision recorded.

{disclosure_choice == "full":
    Public statement will be coordinated with local authorities.
}
{disclosure_choice == "quiet":
    Incident remains classified. Cover story prepared.
}
{disclosure_choice == "partial":
    Controlled statement will be prepared for media.
}

// Robert Chen final words

#speaker:robert_chen

{chen_trust_level >= 80:
    Thank you.

    I don't know your real name, but... thank you.

    You saved this facility. You saved 240,000 people.
}
{chen_trust_level >= 50 and chen_trust_level < 80:
    You did good work here.

    This facility won't forget it.
}
{chen_trust_level < 50:
    I appreciate what you did, even if I don't fully understand it.
}

#speaker:agent_0x99

* [It was an honor, Mr. Chen]
    You: It was an honor working with you, Mr. Chen.
    -> debrief_end_respectful

* [Just doing my job]
    You: Just doing my job.
    -> debrief_end_professional

=== debrief_end_respectful ===
#speaker:robert_chen

This facility's been operating on hope and duct tape for too long.

That changes now. I'll make sure of it.

-> mission_complete

=== debrief_end_professional ===
#speaker:robert_chen

I'll begin implementing security overhauls immediately.

-> mission_complete

=== mission_complete ===
#speaker:agent_0x99

~ mission_debriefed = true

Get some rest, {player_name()}.

Task Force Null briefing tomorrow at 0600.

{voltage_captured:
    Voltage's interrogation will provide actionable intelligence.
- else:
    We'll find Voltage. And The Architect.
}

{operatives_defeated >= 3:
    You neutralized all their operatives. Textbook operation.
}
{operatives_defeated == 2:
    Two operatives down. Clean work.
}

This is just the beginning.

// TRIGGERS: Task 3.3 complete (report_to_0x99)
// TRIGGERS: Mission complete event

#exit_conversation
-> start
