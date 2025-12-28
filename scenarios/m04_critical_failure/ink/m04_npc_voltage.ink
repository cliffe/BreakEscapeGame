// ===========================================
// VOLTAGE - CONFRONTATION (ANTAGONIST)
// Mission 4: Critical Failure
// Break Escape - Climactic Encounter with Critical Mass Leader
// ===========================================

// Variables for tracking confrontation state
VAR voltage_leverage = true              // Does Voltage have active trigger?
VAR voltage_captured = false             // Was Voltage captured?
VAR player_priority = ""                 // capture vs. disable
VAR combat_difficulty = "normal"         // Combat difficulty modifier
VAR voltage_defeated_before_trigger = false
VAR voltage_triggered_attack = false
VAR attack_partially_triggered = false

// External variables (set by game)
EXTERNAL player_name()
EXTERNAL operatives_defeated()
EXTERNAL attack_trigger_secured()
EXTERNAL voltage_defeated()
EXTERNAL voltage_escaped()

// ===========================================
// CONFRONTATION START
// Location: Maintenance Wing
// Task 3.1: Confront Voltage
// ===========================================

=== voltage_confrontation_start ===
#speaker:voltage

// Voltage at laptop, notices player entry

You're good. Better than the usual SAFETYNET drones.

{operatives_defeated >= 2:
    You took out Cipher and Relay. Impressive.
- operatives_defeated == 1:
    You got past my people.
- else:
    Sneaky approach. I respect that.
}

But you're too late. This facility's security is a joke. We've been here for three days setting this up.

* [The attack is over, Voltage. Stand down]
    You: The attack is over, Voltage. Stand down.
    -> voltage_professional_approach

* [You're not contaminating this water supply]
    You: You're not contaminating this water supply.
    -> voltage_confrontational

* {attack_trigger_secured} [Your trigger is disabled. It's over]
    You: Your trigger is disabled. It's over.
    -> voltage_attack_already_disabled

=== voltage_professional_approach ===
#speaker:voltage

Professional to the end. I can respect that.

{attack_trigger_secured:
    -> voltage_attack_disabled_standoff
- else:
    -> voltage_has_leverage
}

=== voltage_confrontational ===
#speaker:voltage

Bold. But conviction doesn't stop attacks.

{attack_trigger_secured:
    -> voltage_attack_disabled_standoff
- else:
    -> voltage_threatens_trigger
}

=== voltage_attack_already_disabled ===
#speaker:voltage

~ voltage_leverage = false

// Voltage checks laptop, realizes attack is neutralized

Smart. You disabled the vectors before coming for me.

-> voltage_no_leverage_combat

// ===========================================
// LEVERAGE PATH: Attack Trigger Still Active
// ===========================================

=== voltage_has_leverage ===
#speaker:voltage

~ voltage_leverage = true

// Voltage hand moves near laptop

One keystroke and I trigger it now. 240,000 people drinking contaminated water by noon.

Your move, agent.

* [Prioritize Capture - Risk engaging with active trigger]
    You: You're not triggering anything. You're coming with me.
    -> player_choice_capture_risky

* [Prioritize Disable - Secure laptop first]
    You: I'm securing that laptop. Now.
    -> player_choice_disable_safe

* [Attempt to talk Voltage down]
    You: Wait. Let's talk about this.
    -> voltage_negotiation_attempt

=== voltage_threatens_trigger ===
#speaker:voltage

~ voltage_leverage = true

// Voltage hand moves to laptop

One keystroke. That's all it takes.

-> voltage_has_leverage

=== player_choice_capture_risky ===
#speaker:voltage

~ player_priority = "capture"
~ combat_difficulty = "hard"

// Player charges Voltage, combat begins

Brave. Or stupid.

// Combat: Voltage + Static, active trigger risk
// If Voltage triggers during combat: Emergency response

-> voltage_combat_with_leverage

=== player_choice_disable_safe ===
#speaker:voltage

~ player_priority = "disable"
~ attack_trigger_secured = true

// Player moves toward laptop, Voltage reacts

Static, cover me!

// Operative #3 engages player while Voltage escapes toward loading dock
// Combat: Operative #3 only, Voltage escapes

-> voltage_escape_route

// ===========================================
// NEGOTIATION PATH
// ===========================================

=== voltage_negotiation_attempt ===
#speaker:voltage

You want to talk? Fine.

This facility? It's one test run. The Architect has operations in six cities.

Coordinated infrastructure attacks with Social Fabric ready to amplify the panic.

You think stopping this changes anything? You stopped ONE attack. How many others can you stop?

* [We'll stop all of them. Starting with you]
    You: We'll stop all of them. Starting with you.
    -> voltage_negotiation_failed_combat

* [Why infrastructure? Why target civilians?]
    You: Why infrastructure? Why target civilians?
    -> voltage_ideology_explanation

* [Who is The Architect?]
    You: Who is The Architect?
    -> voltage_architect_deflection

=== voltage_ideology_explanation ===
#speaker:voltage

You want to understand? Fine.

Infrastructure is the foundation of the system. Power, water, transportation—without them, society collapses.

ENTROPY isn't about ideology. It's about exposing how fragile everything is.

You see this facility? Budget cuts, aging systems, minimal security. One fake maintenance company and we walked right in.

If we can do it, anyone can.

The Architect is forcing people to wake up to how vulnerable they are.

Sometimes that requires... harsh lessons.

* [Terrorizing thousands isn't a lesson. It's murder]
    You: Terrorizing thousands of people isn't a lesson. It's murder.
    -> voltage_rejects_moral_argument

* [You're rationalizing mass casualties]
    You: You're rationalizing mass casualties.
    -> voltage_rejects_moral_argument

=== voltage_rejects_moral_argument ===
#speaker:voltage

Call it what you want. The system failed them, not us. We're just proving it.

Now—are you going to try to stop me, or are we done talking?

-> voltage_negotiation_failed_combat

=== voltage_architect_deflection ===
#speaker:voltage

The Architect? You'll never find them.

The Architect doesn't exist in your databases, your surveillance networks, your informant networks.

The Architect is an idea as much as a person. And ideas? You can't capture those.

-> voltage_negotiation_failed_combat

=== voltage_negotiation_failed_combat ===
#speaker:voltage

// Negotiation ends, combat begins

Enough talking.

{attack_trigger_secured:
    -> voltage_no_leverage_combat
- else:
    -> voltage_combat_with_leverage
}

// ===========================================
// COMBAT PATHS
// ===========================================

=== voltage_combat_with_leverage ===
#speaker:voltage

// COMBAT: Voltage + Static, active trigger laptop
// Risk: Voltage may trigger attack during combat

// [Combat mechanics execute]

{voltage_defeated_before_trigger:
    -> voltage_captured_with_trigger
- voltage_triggered_attack:
    -> voltage_triggered_emergency
- voltage_escaped:
    -> voltage_escape_success
}

=== voltage_no_leverage_combat ===
#speaker:voltage

~ voltage_leverage = false

You disabled it. Smart.

But I'm not getting captured today.

// Combat: Voltage + Static
// Voltage prioritizes escape over fighting

{voltage_defeated:
    -> voltage_captured_no_leverage
- else:
    -> voltage_escape_attempt
}

// ===========================================
// CAPTURE OUTCOMES
// ===========================================

=== voltage_captured_with_trigger ===
#speaker:voltage

~ voltage_captured = true
~ attack_trigger_secured = true

// Voltage restrained, attack trigger secured

You're better than I thought. The Architect will be interested in you.

* [Tell me about The Architect's plans]
    You: Tell me about The Architect's plans.
    -> voltage_interrogation_preview

* [You're done. The attack is stopped]
    You: You're done. The attack is stopped.
    -> voltage_captured_defiant

=== voltage_captured_no_leverage ===
#speaker:voltage

~ voltage_captured = true

// Voltage restrained

Attack failed. But this was a test run anyway. The Architect expected SAFETYNET might interfere.

You stopped this. How many others can you stop?

-> voltage_captured_end

=== voltage_interrogation_preview ===
#speaker:voltage

I'll tell SAFETYNET what I feel like telling them. But here's something for free:

OptiGrid Solutions has contracts at 40 facilities across the country.

Good luck finding which ones we've accessed.

-> voltage_captured_end

=== voltage_captured_defiant ===
#speaker:voltage

This attack. One facility. You stopped your battle. We're winning the war.

-> voltage_captured_end

=== voltage_captured_end ===
#speaker:voltage

// SAFETYNET team arrives to take custody

// TRIGGERS: Task 3.1 complete (confront_voltage)

-> END

// ===========================================
// ESCAPE OUTCOMES
// ===========================================

=== voltage_triggered_emergency ===
#speaker:voltage

// Voltage managed to trigger attack before defeat

~ attack_partially_triggered = true
~ voltage_captured = true

You're too late!

// Chen radio call: "Chemical dosing just spiked!"
// Player must immediately proceed to emergency intervention

-> voltage_triggered_outcome

=== voltage_triggered_outcome ===
#speaker:voltage

// Attack initiated but player can still intervene

// TRIGGERS: attack_partially_triggered event
// Task 3.2 becomes emergency intervention mode

-> END

=== voltage_escape_route ===
#speaker:voltage

~ voltage_captured = false
~ attack_trigger_secured = true

// Voltage escapes through loading dock

This isn't over. You won your battle. We're winning the war.

// Voltage exits to rental van, drives away

-> voltage_escape_success

=== voltage_escape_success ===
#speaker:voltage

~ voltage_captured = false

// Attack still prevented, but Voltage at large

// TRIGGERS: voltage_escaped event
// Task 3.1 complete (confront_voltage)

-> END

=== voltage_escape_attempt ===
#speaker:voltage

~ voltage_captured = false

// Voltage escapes via loading dock

-> voltage_escape_success

=== voltage_attack_disabled_standoff ===
#speaker:voltage

// Attack disabled but player confronts anyway

Smart. You know your way around SCADA systems. Military training?

This was a test run anyway. The Architect expected SAFETYNET might interfere.

-> voltage_no_leverage_combat
