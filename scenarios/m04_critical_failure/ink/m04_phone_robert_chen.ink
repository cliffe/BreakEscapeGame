// ===========================================
// ROBERT CHEN - PHONE SUPPORT
// Mission 4: Critical Failure
// Break Escape - SCADA Technical Guidance (Available After Ally Status)
// ===========================================

// Variables for tracking support interactions
VAR chen_support_calls = 0
VAR guidance_provided = ""

// Game state variables
VAR chen_is_ally = false
VAR chen_trust_level = 0
VAR urgency_stage = 0
VAR attack_mechanism_known = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// PHONE SUPPORT AVAILABILITY CHECK
// Available only after chen_is_ally = true
// ===========================================

=== start ===
-> chen_phone_support_start

=== chen_phone_support_start ===
#speaker:robert_chen

{not chen_is_ally:
    // Chen not yet an ally - shouldn't be callable

    I'm monitoring systems from the Control Room. Come see me if you need something.

    #exit_conversation
-> start
- else:
    // Chen is ally - provides technical support

    ~ chen_support_calls += 1

    {player_name()}, what do you need? I'm monitoring from the Control Room.

    * [I need SCADA guidance]
        You: I need some guidance on the SCADA systems.
        -> scada_guidance_menu

    * [What should I prioritize?]
        You: What should I focus on right now?
        -> priority_guidance

    * [How urgent is the situation?]
        You: How urgent is our timeline?
        -> urgency_assessment
}

=== scada_guidance_menu ===
#speaker:robert_chen

~ chen_trust_level += 3

What specifically?

* [How do the dosing systems work?]
    You: Can you explain how the dosing systems work?
    -> dosing_systems_explanation

* [What am I looking for in the server room?]
    You: I'm in the server room. What should I investigate?
    -> server_room_guidance

* [How do I disable their attack safely?]
    You: How do I disable their attack mechanisms safely?
    -> safe_disabling_guidance

* [Never mind]
    You: Never mind, I'm good for now.
    -> support_call_end

=== dosing_systems_explanation ===
#speaker:robert_chen

~ guidance_provided = "dosing_systems"

Three dosing stations—chlorine, fluoride, pH adjustment.

They're automated via SCADA but have physical controls.

If ENTROPY installed bypass devices, you'd need to disable both the digital control AND the physical hardware.

Careful sequence is critical—wrong order could trigger fail-safes.

+ [That helps, thanks]
    -> scada_guidance_menu

=== server_room_guidance ===
#speaker:robert_chen

~ guidance_provided = "server_room"

{attack_mechanism_known:
    You already identified their attack infrastructure. Good work.

    Now you need to disable it—SCADA malware, physical bypasses, and their trigger mechanism.
- else:
    The VM terminal there has access to our SCADA backup server.

    That's where they would have installed their attack control mechanisms.

    Scan the network, investigate compromised services, find their access points.

    Submit any intelligence you find to the drop-site terminal.
}

+ [Understood]
    -> scada_guidance_menu

=== safe_disabling_guidance ===
#speaker:robert_chen

~ guidance_provided = "disabling"

Three attack vectors need to be neutralized:

One: Physical bypass devices on the dosing stations. Disconnect them manually at Chemical Storage.

Two: Malicious SCADA script. Delete it from the backup server via the VM terminal.

Three: Remote trigger mechanism. Secure and disable Voltage's command laptop.

{urgency_stage >= 3:
    Be careful. We're running out of time.
- else:
    Don't rush. Methodical approach is safer than speed.
}

+ [Got it]
    -> scada_guidance_menu

=== priority_guidance ===
#speaker:robert_chen

~ chen_trust_level += 5

{not attack_mechanism_known:
    Priority one: identify how they're compromising the SCADA network.

    Use the VM terminal in the server room. Find their attack infrastructure.
}
{attack_mechanism_known and urgency_stage >= 3:
    We're in the final stages. You need to disable their attack vectors NOW.

    Physical bypasses, SCADA malware, and the remote trigger. All three.
}
{attack_mechanism_known and urgency_stage < 3:
    You know what they did. Now disable it.

    Three vectors: physical, digital, and the trigger mechanism.
}

+ [Thanks]
    -> support_call_end

=== urgency_assessment ===
#speaker:robert_chen

~ chen_trust_level += 3

// Chen checks SCADA displays

{urgency_stage >= 4:
    We're at critical levels. Chemical parameters are approaching dangerous thresholds.

    If you don't disable their attack soon, we'll have to do emergency shutdown—and that might trigger exactly what they want.
}
{urgency_stage == 3:
    Dosing parameters are drifting into yellow zones. We've got time, but not much.

    Every minute those parameters drift closer to contamination levels.
}
{urgency_stage == 2:
    Systems show anomalies but nothing critical yet.

    We have time to be methodical. Use it wisely.
}
{urgency_stage < 2:
    Systems are stable for now. But those parameters WILL drift if we don't stop them.

    The attack is scheduled for 0800. You've got time, but not unlimited.
}

+ [Understood]
    -> support_call_end

=== support_call_end ===
#speaker:robert_chen

~ chen_trust_level += 2

Call if you need more guidance.

{urgency_stage >= 3:
    But hurry. We're running out of time.
- else:
    I'm monitoring systems from here.
}

#exit_conversation
-> start

// ===========================================
// EMERGENCY CALL (If Attack Partially Triggered)
// ===========================================

=== chen_emergency_call ===
#speaker:robert_chen

{player_name()}! Chemical dosing just spiked!

The attack's been triggered!

You need to disable those vectors RIGHT NOW—physical bypasses, SCADA script, everything!

// TRIGGERS: Emergency intervention mode

#exit_conversation
-> start
