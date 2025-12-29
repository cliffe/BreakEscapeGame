// ===========================================
// OPERATIVE STATIC - VOLTAGE SUPPORT
// Mission 4: Critical Failure
// Break Escape - ENTROPY Operative #3 (Voltage's Backup)
// ===========================================

// Variables for tracking combat state
VAR static_defeated = false
VAR voltage_captured = false
VAR player_priority = ""
VAR player_health_low = false
VAR player_defeated = false

// ===========================================
// STATIC CONFRONTATION
// Location: Maintenance Wing
// Part of Task 3.1: Confront Voltage
// ===========================================

=== start ===
-> static_voltage_support

=== static_voltage_support ===
#speaker:operative_static

// During Voltage confrontation

Voltage, we have company!

{player_priority == "capture":
    // Player trying to capture Voltage

    I've got your back!

    // Fights alongside Voltage
    -> static_combat_support
}
{player_priority == "disable":
    // Player prioritizing laptop trigger

    Go! I'll cover you!

    // Covers Voltage's escape
    -> static_combat_delay
}
{player_priority != "capture" and player_priority != "disable":
    // Default combat support

    -> static_combat_support
}
-> static_combat_support

=== static_combat_support ===
#speaker:operative_static

// Fighting alongside Voltage

You're outnumbered, agent!

// Combat: Static + Voltage vs. Player

-> static_combat_sequence

=== static_combat_delay ===
#speaker:operative_static

// Buying time for Voltage to escape

You're not stopping this operation!

// Combat: Static vs. Player (Voltage escaping)

-> static_combat_sequence

=== static_combat_sequence ===
#speaker:operative_static

// Combat in progress

{player_health_low:
    Critical Mass prevails!
- voltage_captured:
    Voltage! No!
- else:
    For The Architect!
}

// Combat continues

-> static_combat_resolution

=== static_combat_resolution ===
#speaker:operative_static

{static_defeated:
    -> static_defeated_outcome
}
{player_defeated:
    -> static_victory
}
{not static_defeated and not player_defeated:
    -> static_combat_sequence
}
-> static_combat_sequence

=== static_defeated_outcome ===
#speaker:operative_static

~ static_defeated = true

// Static incapacitated

The Architect... will continue...

// Static drops radio, encrypted communications device
#exit_conversation
-> start

=== static_victory ===
#speaker:operative_static

// Player defeated

{voltage_captured:
    // If Voltage was captured but player lost

    Voltage is captured, but you're done.
- else:
    // Player defeated, Voltage status varies

    Get out of here. This facility is ours.
}

// Player respawns
#player_defeated
#exit_conversation
-> start

// ===========================================
// STATIC SURRENDER (Rare - Only if Voltage Captured)
// ===========================================

=== static_surrender ===
#speaker:operative_static

~ static_defeated = true

{voltage_captured:
    // If Voltage was captured

    Fine. It's over. Voltage is down.

    * [Who is The Architect?]
        You: Who is The Architect?
        -> static_interrogation_architect

    * [How many operations are planned?]
        You: How many operations like this are planned?
        -> static_interrogation_operations

    * [Secure Static]
        -> static_secured

- else:
    // If Voltage escaped

    Voltage got away. That's what matters.

    Do what you want with me.

    -> static_secured
}

=== static_interrogation_architect ===
#speaker:operative_static

I don't know. None of us do.

The Architect coordinates through encrypted channels. We never meet them.

Only Voltage has direct communication.

-> static_secured

=== static_interrogation_operations ===
#speaker:operative_static

More than you can stop.

This was a test run. The Architect has cells in six cities.

OptiGrid Solutions has access to dozens of facilities.

You stopped this one. How many others can you stop?

-> static_secured

=== static_secured ===
#speaker:operative_static

~ static_defeated = true

// Static restrained

// TRIGGERS: Part of Task 3.1 completion
#exit_conversation
-> start
