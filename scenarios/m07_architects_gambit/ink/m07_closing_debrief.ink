// Mission 7: The Architect's Gambit - Closing Debrief
// End-of-mission debrief reviewing all four operations and their outcomes

VAR crisis_choice = ""  // Which operation player chose
VAR player_success = false  // Did player succeed in their operation
VAR found_tomb_gamma = false
VAR found_mole_evidence = false
VAR total_casualties = 0
VAR player_operation_casualties = 0
VAR other_operations_casualties = 0

=== closing_debrief ===
You're back at SAFETYNET Emergency Operations Center. The crisis room is quieter now, but the tension remains.

Director Morgan stands at the central display, reviewing after-action reports from all four operations.

She looks up as you enter.

"Agent 0x00. Take a seat. We need to debrief." #speaker:Director Morgan

You sit. She brings up a comprehensive tactical overview.

"Four simultaneous operations. Four different outcomes. Let's review."

+ [I'm ready.] -> operation_review
+ [How bad is it?] -> casualty_summary
+ [Did we stop The Architect?] -> architect_status

=== operation_review ===
Director Morgan brings up the full operational map.

"Here's what happened across all four targets tonight:" #speaker:Director Morgan

-> player_operation_outcome

=== player_operation_outcome ===
{crisis_choice == "infrastructure":
    **OPERATION A: INFRASTRUCTURE COLLAPSE (Your Operation)**

    {player_success == true:
        "You neutralized Marcus Chen's power grid attack. Zero casualties from the blackout. 8.4 million people kept their power." #speaker:Director Morgan

        "Outstanding work."

        ~ player_operation_casualties = 0
    }

    {player_success == false:
        "The power grid failed. Cascading blackouts across the Pacific Northwest." #speaker:Director Morgan

        "Casualty count: 240-385 deaths over 72 hours. Hospital generators, traffic accidents, hypothermia exposure."

        ~ player_operation_casualties = 312
        ~ total_casualties = total_casualties + 312
    }

    -> other_operations_infrastructure
}

{crisis_choice == "data":
    **OPERATION B: DATA APOCALYPSE (Your Operation)**

    {player_success == true:
        "You stopped both the data breach and the disinformation campaign. Democracy secured. 187 million identities protected." #speaker:Director Morgan

        "Exceptional work under dual-timer pressure."

        ~ player_operation_casualties = 0
    }

    {player_success == false:
        "Both attacks succeeded. 187 million voter records stolen. Disinformation campaign launched nationwide." #speaker:Director Morgan

        "Casualty count: 20-40 deaths from civil unrest in first week. Constitutional crisis unfolding."

        ~ player_operation_casualties = 30
        ~ total_casualties = total_casualties + 30
    }

    -> other_operations_data
}

{crisis_choice == "supply_chain":
    **OPERATION C: SUPPLY CHAIN INFECTION (Your Operation)**

    {player_success == true:
        "You prevented all 47 million backdoor infections. Supply chain integrity maintained." #speaker:Director Morgan

        "Zero immediate casualties. Long-term national security preserved."

        ~ player_operation_casualties = 0
    }

    {player_success == false:
        "Backdoors deployed to 47 million systems. Largest supply chain attack in history." #speaker:Director Morgan

        "No immediate casualties, but long-term consequences: $240-420 billion damage projected over 10 years."

        ~ player_operation_casualties = 0
    }

    -> other_operations_supply_chain
}

{crisis_choice == "corporate":
    **OPERATION D: CORPORATE WARFARE (Your Operation)**

    {player_success == true:
        "You neutralized all 47 zero-day exploits. $4.2 trillion in market value preserved. Zero healthcare ransomware." #speaker:Director Morgan

        "Economic stability maintained."

        ~ player_operation_casualties = 0
    }

    {player_success == false:
        "47 zero-days deployed. Stock market crashed 12-18%. Healthcare ransomware active." #speaker:Director Morgan

        "Casualty count: 80-140 deaths from delayed medical care. 140,000+ job losses imminent."

        ~ player_operation_casualties = 110
        ~ total_casualties = total_casualties + 110
    }

    -> other_operations_corporate
}

=== other_operations_infrastructure ===
"The other three operations, handled by SAFETYNET rapid response teams:" #speaker:Director Morgan

**TEAM ALPHA - SUPPLY CHAIN:** Full success. All backdoor injections prevented.

**TEAM BRAVO - DATA APOCALYPSE:** Partial success. Data breach stopped at 13%, but disinformation campaign deployed. Civil unrest beginning. Estimated 20-40 casualties.

~ other_operations_casualties = other_operations_casualties + 30

**TEAM CHARLIE - CORPORATE WARFARE:** Failure. Healthcare ransomware deployed. 80-140 deaths from delayed care.

~ other_operations_casualties = other_operations_casualties + 110

~ total_casualties = total_casualties + other_operations_casualties

-> casualty_total

=== other_operations_data ===
"The other three operations, handled by SAFETYNET rapid response teams:" #speaker:Director Morgan

**TEAM ALPHA - INFRASTRUCTURE:** Failure. Power grid blackout occurred. 240-385 casualties from power failure.

~ other_operations_casualties = other_operations_casualties + 312

**TEAM BRAVO - CORPORATE WARFARE:** Full success. All zero-days neutralized. Zero economic damage.

**TEAM CHARLIE - SUPPLY CHAIN:** Partial success. Some backdoors prevented, estimated 15 million systems infected (instead of 47M).

~ total_casualties = total_casualties + other_operations_casualties

-> casualty_total

=== other_operations_supply_chain ===
"The other three operations, handled by SAFETYNET rapid response teams:" #speaker:Director Morgan

**TEAM ALPHA - DATA APOCALYPSE:** Full success. Both data breach and disinformation prevented. Democracy secure.

**TEAM BRAVO - INFRASTRUCTURE:** Partial success. Limited blackouts. Estimated 80-120 casualties (reduced from 240-385).

~ other_operations_casualties = other_operations_casualties + 100

**TEAM CHARLIE - CORPORATE WARFARE:** Failure. Healthcare ransomware deployed. 80-140 deaths from delayed care.

~ other_operations_casualties = other_operations_casualties + 110

~ total_casualties = total_casualties + other_operations_casualties

-> casualty_total

=== other_operations_corporate ===
"The other three operations, handled by SAFETYNET rapid response teams:" #speaker:Director Morgan

**TEAM ALPHA - INFRASTRUCTURE:** Full success. Power grid secured. Zero blackout casualties.

**TEAM BRAVO - DATA APOCALYPSE:** Catastrophic failure. Both attacks succeeded. 187M records stolen, disinformation deployed. 20-40 casualties from civil unrest.

~ other_operations_casualties = other_operations_casualties + 30

**TEAM CHARLIE - SUPPLY CHAIN:** Partial success. Most backdoors prevented. Estimated 8 million systems infected (instead of 47M).

~ total_casualties = total_casualties + other_operations_casualties

-> casualty_total

=== casualty_total ===
Director Morgan displays the final casualty count.

{total_casualties == 0:
    "Combined casualties across all operations: ZERO." #speaker:Director Morgan

    "This is unprecedented. Complete success. The Architect's coordinated attack failed."

    "You chose the right operation, and the teams executed perfectly."

    -> success_reflection
}

{total_casualties > 0 and total_casualties < 100:
    "Combined casualties across all operations: {total_casualties} deaths." #speaker:Director Morgan

    She pauses.

    "Every single one of those people had families. Lives. Futures."

    "But given the scale of the attack - four simultaneous operations - this is... this is as good as we could have hoped for."

    -> mixed_reflection
}

{total_casualties >= 100 and total_casualties < 300:
    "Combined casualties across all operations: {total_casualties} deaths." #speaker:Director Morgan

    The weight of that number hangs in the air.

    "Significant casualties. Multiple operations failed or partially succeeded."

    "The Architect achieved some of their objectives tonight."

    -> failure_reflection
}

{total_casualties >= 300:
    "Combined casualties across all operations: {total_casualties} deaths." #speaker:Director Morgan

    She looks exhausted.

    "This is catastrophic. Multiple operations failed. The Architect achieved most of their objectives."

    "We need to understand what went wrong."

    -> failure_reflection
}

=== success_reflection ===
"Agent 0x00, you made an impossible choice and got it RIGHT." #speaker:Director Morgan

{found_tomb_gamma == true:
    "And you recovered Tomb Gamma coordinates. That's our next target - The Architect's command center."
}

{found_mole_evidence == true:
    "You also found evidence of our mole. Internal Affairs is already investigating."
}

+ [What happens to ENTROPY now?] -> entropy_future
+ [What about The Architect?] -> architect_status

=== mixed_reflection ===
"You made the best choice you could with the intelligence available." #speaker:Director Morgan

"The casualties at unchosen operations - that's not your failure. That's The Architect's design. Forcing impossible choices."

{found_tomb_gamma == true:
    "But you recovered Tomb Gamma coordinates. That gives us our next move against The Architect."
}

{found_mole_evidence == true:
    "And the mole evidence you found - that's critical for preventing future leaks."
}

+ [Could I have done better?] -> second_guessing
+ [What happens next?] -> next_steps

=== failure_reflection ===
"Multiple operations failed tonight. The Architect achieved significant objectives." #speaker:Director Morgan

She's not blaming you - just stating facts.

"The choice you made... in hindsight, was it the right one?"

+ [I made the best decision I could.] -> defend_choice
+ [I should have chosen differently.] -> regret_choice
+ [The Architect designed this to be unwinnable.] -> blame_architect

=== defend_choice ===
"You did. You made the call based on available intelligence and your assessment of priorities." #speaker:Director Morgan

"The casualties are on The Architect. Not you."

{found_tomb_gamma == true or found_mole_evidence == true:
    "And you recovered critical intelligence. That's valuable for future operations."
}

-> next_steps

=== regret_choice ===
"Second-guessing yourself in hindsight isn't helpful, Agent." #speaker:Director Morgan

"You didn't have perfect information. Nobody did. The Architect designed it that way."

-> next_steps

=== blame_architect ===
"You're right. This was designed to be impossible. Four simultaneous attacks, one operator." #speaker:Director Morgan

"The Architect wanted to prove that even our best couldn't stop them."

{total_casualties > 0:
    "And they partially succeeded. We took losses."
}

{total_casualties == 0:
    "But you proved them wrong. We stopped them."
}

-> next_steps

=== second_guessing ===
"In hindsight, maybe. But you didn't have hindsight. You had 30 seconds to choose from four crisis scenarios." #speaker:Director Morgan

"You did your job. The teams did theirs. Some succeeded, some didn't."

"That's the reality of coordinated attacks."

-> next_steps

=== casualty_summary ===
Director Morgan pulls up the casualty report.

{total_casualties == 0:
    "Zero casualties across all four operations. Complete success." #speaker:Director Morgan
    -> success_reflection
}

{total_casualties > 0:
    "Total casualties: {total_casualties} deaths across all four operations." #speaker:Director Morgan

    {player_operation_casualties == 0:
        "Your operation: Zero casualties. You succeeded."
    }

    {player_operation_casualties > 0:
        "Your operation: {player_operation_casualties} casualties. The attack succeeded."
    }

    "Other operations: {other_operations_casualties} casualties combined."

    -> casualty_total
}

=== architect_status ===
"The Architect remains at large. Unknown identity. Unknown location." #speaker:Director Morgan

{found_tomb_gamma == true:
    "But you recovered Tomb Gamma coordinates. That's their command center. We're planning a strike."
}

{found_tomb_gamma == false:
    "We still don't have their location. Tomb Gamma remains unknown."
}

"What we DO know: They're planning something bigger. Tonight was a test. A proof-of-concept."

+ [A test for what?] -> architect_endgame
+ [What about the mole?] -> mole_status

=== architect_endgame ===
"We don't know. But coordinating four simultaneous attacks with different cells, different methods, different objectives - that's sophisticated." #speaker:Director Morgan

"It suggests they're building toward something. A larger operation."

"Which is why we need to find Tomb Gamma and stop them before they execute it."

+ [I'm ready for the next mission.] -> mission_conclusion
+ [What about the mole?] -> mole_status

=== mole_status ===
{found_mole_evidence == true:
    "You recovered evidence of communications between someone at SAFETYNET and The Architect." #speaker:Director Morgan

    "Internal Affairs is investigating. We'll find them."

    "Knowing we have a mole is the first step to rooting them out."
}

{found_mole_evidence == false:
    "We still don't have concrete evidence. But the operational timing suggests someone inside leaked details to The Architect." #speaker:Director Morgan

    "We're conducting internal review, but without evidence, it's difficult."
}

+ [What's next for me?] -> next_steps

=== next_steps ===
"Debrief complete. File your after-action report and take 24 hours rest." #speaker:Director Morgan

{found_tomb_gamma == true:
    "Then we plan the Tomb Gamma operation. Striking at The Architect's command center."

    "This is far from over."
}

{found_tomb_gamma == false:
    "We'll continue investigating The Architect's identity and location."

    "This isn't over. ENTROPY is still active. The Architect is still out there."
}

"Good work tonight, Agent. Regardless of the outcome, you made impossible choices under extreme pressure."

"Not many operators could have done what you did."

+ [Thank you, Director.] -> mission_conclusion

=== entropy_future ===
"ENTROPY is damaged but not destroyed. We disrupted their coordinated attack, but the cells remain active." #speaker:Director Morgan

{found_tomb_gamma == true:
    "Tomb Gamma is our next target. If we can strike The Architect's command center, we can decapitate the entire organization."
}

"Critical Mass, Ghost Protocol, Social Fabric, Digital Vanguard, Supply Chain Saboteurs, Zero Day Syndicate - all still operational."

"But now we know their methods. Their coordination patterns. Their weaknesses."

"Tonight was the first battle. Not the last."

+ [I'm ready to continue the fight.] -> mission_conclusion

=== mission_conclusion ===
Director Morgan extends her hand.

"Get some rest, Agent 0x00. You've earned it."

**MISSION 7: THE ARCHITECT'S GAMBIT - COMPLETE**

**YOUR OPERATION: {crisis_choice}**
**OUTCOME: {player_success: SUCCESS | FAILURE}**
**TOTAL CASUALTIES: {total_casualties}**
**TOMB GAMMA DISCOVERED: {found_tomb_gamma: YES | NO}**
**MOLE EVIDENCE FOUND: {found_mole_evidence: YES | NO}**

The war against ENTROPY continues...

-> END

-> END
