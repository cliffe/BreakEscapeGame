// ===========================================
// OPERATIVE RELAY - COMBAT ENCOUNTER
// Mission 4: Critical Failure
// Break Escape - ENTROPY Operative #2 (Chemical Storage Patrol)
// ===========================================

// Variables for tracking combat state
VAR relay_alerted_team = false
VAR relay_defeated = false
VAR radio_interrupted = false
VAR player_health_low = false
VAR player_defeated = false

// ===========================================
// RELAY DETECTION
// Location: Chemical Storage
// Optional Task 2.10: Neutralize Operative #2
// ===========================================

=== start ===
-> relay_patrol_alert

=== relay_patrol_alert ===
#speaker:operative_relay

// Triggered if Relay detects player

Intruder in chemical storage! Relay responding!

// Radio call attempt

{radio_interrupted:
    // Player interrupts radio
    -> relay_combat_silent
- else:
    // Radio call succeeds

    All units, intruder in chemical storage!

    -> relay_combat_team_alerted
}

=== relay_combat_silent ===
#speaker:operative_relay

// Combat without team alert

You're not getting to those dosing stations!

// Combat begins

-> relay_combat_sequence

=== relay_combat_team_alerted ===
#speaker:operative_relay

~ relay_alerted_team = true

// Team alerted - backup may arrive

Voltage, we've got company!

-> relay_combat_sequence

=== relay_combat_sequence ===
#speaker:operative_relay

// Combat in progress

{player_health_low:
    Almost done with you!
- else:
    You picked the wrong fight!
}

// Combat continues

-> relay_combat_resolution

=== relay_combat_resolution ===
#speaker:operative_relay

{relay_defeated:
    -> relay_defeated_outcome
}
{player_defeated:
    -> relay_victory
}
{not relay_defeated and not player_defeated:
    -> relay_combat_sequence
}
-> relay_combat_sequence

=== relay_defeated_outcome ===
#speaker:operative_relay

~ relay_defeated = true

// Relay incapacitated

The attack... will still... happen...

// Relay drops Master keycard, radio, bypass device schematics

// TRIGGERS: Task 2.10 complete (optional)
#complete_task:neutralize_operative_relay
#exit_conversation
-> start

=== relay_victory ===
#speaker:operative_relay

// Player defeated - respawn

Stay out of Critical Mass operations.

// Player respawns at checkpoint
#player_defeated
#exit_conversation
-> start

// ===========================================
// OPTIONAL: RELAY SURRENDER/INTERROGATION
// ===========================================

=== relay_surrender ===
#speaker:operative_relay

~ relay_defeated = true

Alright! I yield!

* [How many of you are there?]
    You: How many operatives are here?
    -> relay_interrogation_count

* [Where are the bypass devices?]
    You: Where are the physical bypass devices?
    -> relay_interrogation_devices

* [Secure Relay and move on]
    -> relay_secured

=== relay_interrogation_count ===
#speaker:operative_relay

Four of us. Cipher, me, Static, and Voltage.

By now you probably already dealt with Cipher.

Good luck with Voltage. He doesn't surrender.

-> relay_secured

=== relay_interrogation_devices ===
#speaker:operative_relay

Dosing stations in Chemical Storage. Three of them.

We installed bypass hardware on all three. Remote controllable.

You'd need to physically disconnect them.

-> relay_secured

=== relay_secured ===
#speaker:operative_relay

~ relay_defeated = true

// Relay restrained and secured

// TRIGGERS: Task 2.10 complete (optional)
#complete_task:neutralize_operative_relay
#exit_conversation
-> start
