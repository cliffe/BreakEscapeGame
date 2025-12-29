// ===========================================
// OPERATIVE CIPHER - COMBAT ENCOUNTER
// Mission 4: Critical Failure
// Break Escape - ENTROPY Operative #1 (Treatment Floor Guard)
// ===========================================

// Variables for tracking combat state
VAR cipher_alerted_team = false
VAR cipher_defeated = false
VAR radio_interrupted = false
VAR player_health_low = false
VAR player_defeated = false

// ===========================================
// CIPHER DETECTION
// Location: Treatment Floor
// Optional Task 2.9: Neutralize Operative #1
// ===========================================

=== start ===
-> cipher_detection

=== cipher_detection ===
#speaker:operative_cipher

// Triggered when player detected by Operative #1

What the—hey! Security, we've got a problem!

// Attempts radio call

{radio_interrupted:
    // Player stops radio call
    You're fast. Won't help you.
    -> cipher_combat_silent
- else:
    // Radio call succeeds
    -> cipher_alerts_team
}

=== cipher_alerts_team ===
#speaker:operative_cipher

~ cipher_alerted_team = true

// Radio transmission

Voltage, security's here! Real security. We're compromised!

// Other operatives go on alert

-> cipher_combat_alerted

=== cipher_combat_silent ===
#speaker:operative_cipher

// Combat without alerting team

You're not stopping this!

// Combat encounter begins

-> cipher_combat_sequence

=== cipher_combat_alerted ===
#speaker:operative_cipher

// Combat with team alerted

You picked the wrong facility to infiltrate.

// Combat encounter - other operatives will be prepared

-> cipher_combat_sequence

=== cipher_combat_sequence ===
#speaker:operative_cipher

// Combat in progress

{player_health_low:
    You're done!
- else:
    Critical Mass doesn't fail!
}

// Combat continues until resolution

-> cipher_combat_resolution

=== cipher_combat_resolution ===
#speaker:operative_cipher

{cipher_defeated:
    -> cipher_defeated_outcome
}
{player_defeated:
    -> cipher_victory
}
{not cipher_defeated and not player_defeated:
    -> cipher_combat_sequence
}
-> cipher_combat_sequence

=== cipher_defeated_outcome ===
#speaker:operative_cipher

~ cipher_defeated = true

// Cipher incapacitated

You won't... stop the attack...

// Cipher drops Level 2 keycard, radio, intelligence document

// TRIGGERS: Task 2.9 complete (optional)
#complete_task:neutralize_operative_cipher
#exit_conversation
-> start

=== cipher_victory ===
#speaker:operative_cipher

// Player defeated - respawn

Stay down.

// Player respawns at checkpoint
#player_defeated
#exit_conversation
-> start

// ===========================================
// OPTIONAL: CIPHER SURRENDER/INTERROGATION
// If player subdues rather than defeats
// ===========================================

=== cipher_surrender ===
#speaker:operative_cipher

~ cipher_defeated = true

Alright, alright! I'm done!

* [Where's Voltage?]
    You: Where's Voltage?
    -> cipher_interrogation_voltage

* [What's the attack mechanism?]
    You: What's the attack mechanism?
    -> cipher_interrogation_attack

* [Secure Cipher and move on]
    -> cipher_secured

=== cipher_interrogation_voltage ===
#speaker:operative_cipher

Maintenance wing. Final defensive position.

Good luck getting past Relay and Static.

-> cipher_secured

=== cipher_interrogation_attack ===
#speaker:operative_cipher

Three vectors. Physical bypasses on dosing stations, SCADA malware, remote trigger.

You'd have to disable all three to stop it.

-> cipher_secured

=== cipher_secured ===
#speaker:operative_cipher

~ cipher_defeated = true

// Cipher restrained and secured

// TRIGGERS: Task 2.9 complete (optional)
#complete_task:neutralize_operative_cipher
#exit_conversation
-> start
