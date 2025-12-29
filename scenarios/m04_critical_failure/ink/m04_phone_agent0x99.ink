// ===========================================
// AGENT 0x99 - PHONE SUPPORT (HANDLER)
// Mission 4: Critical Failure
// Break Escape - Strategic Guidance Throughout Mission
// ===========================================

// Variables for tracking conversation state
VAR handler_contacted = 0              // Number of times player contacted handler
VAR handler_confidence = 50            // 0-100 handler's confidence in mission success
VAR server_room_reached = false
VAR attack_mechanism_known = false
VAR voltage_priority_discussed = false

// Game state variables
VAR chen_is_ally = false
VAR operatives_defeated = 0
VAR urgency_stage = 0
VAR flags_submitted = 0

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// CONVERSATION HUB
// ===========================================

=== start ===
-> first_call

// ===========================================
// FIRST CALL (Initial Contact)
// Triggered: Shortly after mission start
// ===========================================

=== first_call ===
#speaker:agent_0x99

{player_name()}, status check. Are you inside the facility?

* [Yes, I'm in. Met the facility manager]
    ~ handler_contacted += 1
    You: I'm inside. Met Robert Chen, the facility manager.
    -> chen_status_inquiry

* [Inside. Beginning investigation]
    ~ handler_contacted += 1
    You: Inside the facility. Beginning investigation now.
    -> investigation_update

* [Any intel updates on my end?]
    ~ handler_contacted += 1
    You: I'm in. Anything new from your end?
    -> intel_update

=== chen_status_inquiry ===
#speaker:agent_0x99

{chen_is_ally:
    ~ handler_confidence += 15

    Good. Chen's cooperation will be valuable—he knows those systems inside out.

    Use his SCADA expertise when you need it.
- else:
    How's he taking the cover story? Suspicious or cooperative?

    -> chen_cover_status
}

+ [Understood. Continuing investigation]
    -> first_call_objectives

=== chen_cover_status ===
#speaker:agent_0x99

* [He's cooperative so far]
    ~ handler_confidence += 5
    You: Cooperative. Providing facility access.
    -> chen_cooperation_acknowledged

* [Skeptical but complying]
    You: Skeptical, but he's complying with the audit cover.
    -> chen_skeptical_acknowledged

* [I revealed the real mission]
    ~ handler_confidence += 10
    You: I told him the truth about ENTROPY. He's fully on board.
    -> chen_revealed_acknowledged

=== chen_cooperation_acknowledged ===
#speaker:agent_0x99

Good. Maintain the cover until you have hard evidence. Then bring him in fully if needed.

-> first_call_objectives

=== chen_skeptical_acknowledged ===
#speaker:agent_0x99

Keep him cooperative. If you find evidence of compromise, that'll convince him.

-> first_call_objectives

=== chen_revealed_acknowledged ===
#speaker:agent_0x99

~ handler_confidence += 10

Bold move. But if he's committed, use him—SCADA expertise will help identify their attack vector.

-> first_call_objectives

=== investigation_update ===
#speaker:agent_0x99

Copy that. Remember your objectives:

Identify the attack vector. Disable it. Capture operatives if possible—especially Voltage.

-> first_call_objectives

=== intel_update ===
#speaker:agent_0x99

Nothing new. Signals intelligence still shows encrypted traffic between the facility and external nodes.

Whatever they're planning, it's scheduled for 0800. You've got time, but not much.

-> first_call_objectives

=== first_call_objectives ===
#speaker:agent_0x99

Priority one: find how they're compromising the SCADA network.

Look for server room access, network infrastructure, anything that explains remote control.

{chen_is_ally:
    Chen can point you to the right systems.
}

+ [Roger that. Moving to investigate]
    -> first_call_end

=== first_call_end ===
#speaker:agent_0x99

Stay sharp. These aren't amateurs. If you encounter hostiles, defend yourself.

Call if you need guidance.

#exit_conversation
-> start

// ===========================================
// EVENT: SERVER ROOM ENTERED
// Triggered: Player enters server room
// ===========================================

=== event_server_room_entered ===
#speaker:agent_0x99

~ server_room_reached = true
~ handler_confidence += 10

{player_name()}, good work reaching the server room.

That's their access point—SCADA network infrastructure runs through there.

* [I see a VM terminal for network investigation]
    You: There's a network investigation terminal here. SCADA backup server.
    -> vm_guidance

* [What am I looking for?]
    You: What specifically should I investigate?
    -> investigation_guidance

=== vm_guidance ===
#speaker:agent_0x99

~ handler_confidence += 5

Perfect. Use it to scan the SCADA network topology.

Identify compromised systems, enumerate services, find their attack mechanism.

Submit flags at the drop-site terminal when you find intelligence.

+ [Understood. Beginning network analysis]
    -> server_room_event_end

=== investigation_guidance ===
#speaker:agent_0x99

Look for network access points, compromised services, remote control mechanisms.

They had three operatives here for hours—they installed something.

Find it, analyze it, and we'll know how to disable their attack.

+ [On it]
    -> server_room_event_end

=== server_room_event_end ===
#speaker:agent_0x99

{operatives_defeated >= 1:
    And {player_name()}—you've already encountered hostiles. Stay alert. There may be more.
- else:
    Watch your back. Those operatives are armed and won't hesitate.
}

Call when you've got intel.

#exit_conversation
-> start

// ===========================================
// EVENT: ATTACK MECHANISM IDENTIFIED
// Triggered: Player submits final VM flag (distcc exploit)
// ===========================================

=== event_attack_mechanism_identified ===
#speaker:agent_0x99

~ attack_mechanism_known = true
~ handler_confidence += 20

{player_name()}, I'm seeing your flag submissions. Outstanding work.

You've identified their complete attack infrastructure. Three-vector approach: physical bypass devices, SCADA malware, remote trigger.

* [All three vectors need to be disabled]
    You: All three attack vectors need to be neutralized to stop this.
    -> three_vector_confirmation

* [Where's the remote trigger?]
    You: Where's the remote trigger mechanism?
    -> trigger_location_discussion

=== three_vector_confirmation ===
#speaker:agent_0x99

~ handler_confidence += 10

Correct. Physical devices on the dosing stations, malicious SCADA script, and their command laptop.

Disable all three, and the attack is dead.

-> voltage_priority_update

=== trigger_location_discussion ===
#speaker:agent_0x99

Based on your intel, the remote trigger is with Voltage—maintenance wing command center.

That's where you'll find him. And that's where this ends.

-> voltage_priority_update

=== voltage_priority_update ===
#speaker:agent_0x99

~ voltage_priority_discussed = true

Listen carefully. Voltage is high-value intelligence.

He knows about The Architect, multi-cell coordination, future operations.

* [Prioritize capture over speed?]
    You: Should I prioritize capturing Voltage even if it's riskier?
    -> capture_vs_speed_guidance

* [Understood. I'll attempt capture]
    ~ handler_confidence += 10
    You: Understood. I'll attempt to capture him.
    -> capture_attempt_acknowledged

* [Attack prevention comes first]
    You: Attack prevention is priority one. Capture is secondary.
    -> attack_priority_acknowledged

=== capture_vs_speed_guidance ===
#speaker:agent_0x99

Your call on the ground. Here's the analysis:

Capture Voltage: High intel value, but riskier engagement. He may threaten to trigger early.

Prioritize attack disabling: Lower risk, guaranteed mission success, but we lose intelligence.

I trust your judgment. Choose based on the tactical situation.

+ [I'll assess when I confront him]
    ~ handler_confidence += 15
    You: I'll make the call when I confront him. Tactical situation dependent.
    -> judgment_trusted

=== capture_attempt_acknowledged ===
#speaker:agent_0x99

Good. But {player_name()}—if he threatens to trigger the attack, stop him by any means.

Lives first. Intelligence second.

-> final_phase_briefing

=== attack_priority_acknowledged ===
#speaker:agent_0x99

~ handler_confidence += 5

Solid priorities. Stop the attack. If Voltage escapes but the attack fails, that's still a win.

-> final_phase_briefing

=== judgment_trusted ===
#speaker:agent_0x99

That's the right approach. Adapt to what you find.

-> final_phase_briefing

=== final_phase_briefing ===
#speaker:agent_0x99

Final phase objectives:

One—neutralize Voltage and any remaining operatives in the maintenance wing.

Two—secure or destroy the remote trigger laptop.

Three—disable physical bypass devices and SCADA malware.

{operatives_defeated >= 2:
    You've already taken down {operatives_defeated} operatives. You're doing this.
}
{operatives_defeated == 1:
    You've neutralized one operative. Expect resistance from the others.
}
{operatives_defeated == 0:
    All three operatives are still active. Be ready for combat.
}

* [I'm ready. Moving to maintenance wing]
    ~ handler_confidence += 10
    You: Ready. Moving to the maintenance wing now.
    -> final_encouragement

=== final_encouragement ===
#speaker:agent_0x99

{handler_confidence >= 80:
    You've got this, {player_name()}. Textbook operation so far. Finish it.
}
{handler_confidence >= 60 and handler_confidence < 80:
    Good work so far. Stay sharp for the final push.
}
{handler_confidence < 60:
    Be careful. This is the most dangerous phase.
}

240,000 people are counting on you. Bring it home.

#exit_conversation
-> start

// ===========================================
// OPTIONAL: PLAYER-INITIATED CALL (GUIDANCE REQUEST)
// Player can call for hints/support
// ===========================================

=== player_guidance_request ===
#speaker:agent_0x99

~ handler_contacted += 1

{player_name()}, go ahead. What do you need?

* [What's my next priority?]
    -> priority_guidance

* [Intel update?]
    -> intel_status_update

* [I'm stuck. Suggestions?]
    -> tactical_suggestions

=== priority_guidance ===
#speaker:agent_0x99

{not server_room_reached:
    Get to the server room. That's where they accessed the SCADA network.

    {chen_is_ally:
        Chen can tell you how to get there.
    }
}
{server_room_reached and not attack_mechanism_known:
    Use the VM terminal in the server room. Investigate the SCADA network.

    Identify their attack mechanism. Submit flags when you find intel.
}
{server_room_reached and attack_mechanism_known:
    You know the attack mechanism. Now disable it.

    Confront Voltage in the maintenance wing. Secure the remote trigger. Disable all attack vectors.
}

+ [Understood]
    -> guidance_call_end

=== intel_status_update ===
#speaker:agent_0x99

{flags_submitted >= 3:
    You've submitted {flags_submitted} flags. Excellent intel gathering.
}
{flags_submitted >= 1 and flags_submitted < 3:
    You've submitted {flags_submitted} flag(s) so far. Keep investigating.
}
{flags_submitted == 0:
    No flags submitted yet. Find intelligence and submit at the drop-site terminal.
}

{operatives_defeated >= 2:
    Two operatives neutralized. {operatives_defeated == 3: All hostiles down.| One or two remaining.}
}
{operatives_defeated == 1:
    One operative neutralized. Stay alert for the others.
}
{operatives_defeated == 0:
    No confirmed hostile encounters yet. They're here—be ready.
}

+ [Thanks]
    -> guidance_call_end

=== tactical_suggestions ===
#speaker:agent_0x99

What's the situation?

* [Can't find the next area]
    You: I can't find where to go next.
    -> navigation_help

* [Combat encounter is difficult]
    You: Having trouble with a combat encounter.
    -> combat_help

* [VM challenge is confusing]
    You: The VM network challenge is confusing.
    -> vm_challenge_help

=== navigation_help ===
#speaker:agent_0x99

{not server_room_reached:
    Server room access: through the treatment floor. You'll need Level 2 keycard.

    {operatives_defeated >= 1:
        Check the operative you defeated—they may have had a keycard.
    }
    {operatives_defeated == 0 and chen_is_ally:
        Chen can provide access if you ask him.
    }
    {operatives_defeated == 0 and not chen_is_ally:
        Find a keycard or get Chen to provide access.
    }
}
{server_room_reached:
    Maintenance wing: final location. Requires master keycard.

    {operatives_defeated >= 2:
        Check the operative in chemical storage—Relay has the master keycard.
    }
    {operatives_defeated < 2:
        Defeat the operative patrolling chemical storage. They have the master keycard.
    }
}

+ [That helps, thanks]
    -> guidance_call_end

=== combat_help ===
#speaker:agent_0x99

Use cover. These operatives have training, but so do you.

Stealth takedowns when possible. Direct engagement if necessary.

{chen_is_ally:
    Chen might have intel on operative locations if you ask.
}

+ [Understood]
    -> guidance_call_end

=== vm_challenge_help ===
#speaker:agent_0x99

Start with network scanning—Nmap. Map the SCADA topology.

Then enumerate services—FTP and HTTP will have intelligence files.

Finally, exploit vulnerable services to access attack control mechanisms.

{chen_is_ally:
    Chen can provide SCADA context if you need technical clarification.
}

+ [Got it, thanks]
    -> guidance_call_end

=== guidance_call_end ===
#speaker:agent_0x99

~ handler_confidence += 3

Anything else?

* [No, I'm good]
    You: No, I'm good. Thanks.
    -> call_final_end

* [One more thing...]
    -> player_guidance_request

=== call_final_end ===
#speaker:agent_0x99

Stay safe out there. Call if you need me.

#exit_conversation
-> start
