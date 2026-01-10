// Mission 7: The Architect's Gambit - Director Morgan
// Supportive NPC who provides mission guidance and status updates

VAR mission_started = false
VAR flags_submitted = 0
VAR crisis_neutralized = false
VAR asked_about_other_teams = false
VAR asked_about_architect = false
VAR asked_about_mole = false

=== director_morgan ===
{mission_started == false:
    Director Morgan is reviewing tactical displays, coordinating the response across all four crisis zones.

    "Agent 0x00. Ready for your briefing?" #speaker:Director Morgan

    + [I'm ready]
        "Good. Let's go over your assignment."
        ~ mission_started = true
        -> mission_status
    + [Tell me about the other teams] -> other_teams_status
    + [Who is The Architect?] -> architect_discussion
}

{mission_started == true:
    Director Morgan looks up from her terminal as you approach.

    "Agent 0x00. Status update?" #speaker:Director Morgan

    + [Request situation update] -> mission_status
    + [Ask about other SAFETYNET teams] -> other_teams_status
    + [Ask about The Architect] -> architect_discussion
    + {flags_submitted >= 2} [Ask about intelligence findings] -> intelligence_discussion
    + {crisis_neutralized == false} [Request tactical guidance] -> tactical_guidance
    + [That's all for now] -> END
}

=== mission_status ===
She brings up your mission status display.

{flags_submitted == 0:
    "You haven't submitted any flags yet. Access the VM in the Server Room and begin exploitation. We need that intelligence to neutralize the attack." #speaker:Director Morgan
}

{flags_submitted == 1:
    "One flag submitted. Good progress, but we need all four to extract the shutdown codes. Keep pushing." #speaker:Director Morgan
}

{flags_submitted == 2:
    "Two flags down. You're halfway there. Clock is ticking, Agent." #speaker:Director Morgan
}

{flags_submitted == 3:
    "Three flags submitted. One more and you'll have everything you need to stop this. Final push." #speaker:Director Morgan
}

{flags_submitted == 4 and crisis_neutralized == false:
    "All flags submitted. Excellent work. Now use that intelligence to neutralize the threat. Get to the Crisis Terminal and stop this attack." #speaker:Director Morgan
}

{crisis_neutralized == true:
    "Crisis neutralized. Outstanding work, Agent. But the mission isn't over - search for intelligence about ENTROPY's broader operations." #speaker:Director Morgan
}

+ [Continue conversation] -> director_morgan
+ [End conversation] -> END

=== other_teams_status ===
~ asked_about_other_teams = true

She switches to a tactical overview showing all four operations.

"Here's what's happening at the other targets:" #speaker:Director Morgan

// Status updates are deterministic based on player's choice
// This will be conditional in the actual game based on crisis_choice variable

**TEAM ALPHA** - Current Status: ENGAGED
{crisis_choice == "infrastructure": Supply Chain operation - Proceeding as expected}
{crisis_choice == "data": Infrastructure operation - Facing heavy resistance, casualties expected}
{crisis_choice == "supply_chain": Data Apocalypse operation - Both attacks prevented, clean success}
{crisis_choice == "corporate": Infrastructure operation - Attack neutralized successfully}

**TEAM BRAVO** - Current Status: ENGAGED
{crisis_choice == "infrastructure": Data Apocalypse - Partial success, data breach stopped but disinformation deployed}
{crisis_choice == "data": Corporate Warfare operation - All zero-days neutralized}
{crisis_choice == "supply_chain": Infrastructure operation - Partial success, some casualties}
{crisis_choice == "corporate": Data Apocalypse operation - CRITICAL FAILURE, both attacks succeeded}

**TEAM CHARLIE** - Current Status: ENGAGED
{crisis_choice == "infrastructure": Corporate Warfare - Zero-days deployed, economic damage occurring}
{crisis_choice == "data": Supply Chain operation - Partial success, some backdoors prevented}
{crisis_choice == "supply_chain": Corporate Warfare - Zero-days deployed, economic damage confirmed}
{crisis_choice == "corporate": Supply Chain operation - Partial success, most backdoors prevented}

She looks at you with professional calm.

"The outcomes are unfolding exactly as the models predicted. Your choice determined which crisis gets the best operator - you. The others... they're doing their best."

A pause.

"Focus on your mission. You can't help them now. Win YOUR battle."

+ [Understood] -> director_morgan
+ [What about casualties?] -> casualties_discussion

=== casualties_discussion ===
Her expression is grim.

"We're tracking casualty estimates in real-time based on team performance." #speaker:Director Morgan

{crisis_choice == "infrastructure":
    "Team Bravo stopped the voter data breach, but Social Fabric's disinformation campaign launched. We're seeing civil unrest beginning - estimated 20-40 deaths if it escalates."

    "Team Charlie failed to stop the corporate zero-day attacks. Healthcare ransomware is active at 840 hospitals. Surgeries cancelled. We're projecting 80-140 deaths from delayed medical care."
}

{crisis_choice == "data":
    "Team Alpha couldn't stop the infrastructure attack. Pacific Northwest is going dark. We're estimating 240-385 civilian deaths over 72 hours. Hospital generators, traffic accidents, hypothermia exposure."
}

{crisis_choice == "supply_chain":
    "Team Bravo prevented infrastructure casualties - full success there. But Team Charlie failed on corporate. Healthcare ransomware active, economic damage mounting."
}

{crisis_choice == "corporate":
    "Team Bravo failed. Both data attacks succeeded - voter breach AND disinformation. We're seeing civil unrest. Estimated casualties 20-40 and climbing."
}

She meets your eyes.

"These numbers are real people, Agent. But you made the best choice you could. Now win yours so the total damage is minimized."

+ [I understand] -> director_morgan

=== architect_discussion ===
~ asked_about_architect = true

Director Morgan pulls up an intelligence file marked "ENTROPY - THE ARCHITECT - CLASSIFIED."

"Everything we know about The Architect is speculation and pattern analysis." #speaker:Director Morgan

"**What we know for certain:**
* Coordinates all ENTROPY cells with precision
* Deep knowledge of SAFETYNET protocols and response capabilities
* Strategic thinker - designs operations to force impossible choices
* Communicates via encrypted channels, taunts operatives during missions
* Philosophy: 'Accelerating entropy' - believes in forcing societal collapse

**What we suspect:**
* Former intelligence community (NSA, CIA, or military intelligence)
* Access to classified information about US infrastructure vulnerabilities
* Possibly knows SAFETYNET personnel (references to specific operators)
* The alias 'The Architect' suggests systematic planning, building toward something

**What we don't know:**
* True identity
* Ultimate goal (beyond 'accelerated entropy')
* How many cells they control
* Location of their command center (we call it 'Tomb Gamma' based on intercepts)"

She closes the file.

"They're the most sophisticated threat we've ever faced. And they're watching you right now."

+ [How do they have SAFETYNET intelligence?] -> mole_discussion
+ [What's their ultimate goal?] -> architect_goal_discussion
+ [Continue] -> director_morgan

=== mole_discussion ===
~ asked_about_mole = true

Her voice drops.

"We have a mole. Someone inside SAFETYNET feeding The Architect our operational details." #speaker:Director Morgan

"The timing of these four attacks - simultaneous, coordinated, designed to split our resources - that requires insider knowledge."

"Your assignment to your specific target, the other teams' assignments, our response capabilities... The Architect knew it all before we deployed."

She looks around cautiously.

"I don't know who. Could be anyone with access to operations. Could be... someone in this room."

"If you find evidence during your mission - emails, communications, anything linking SAFETYNET personnel to ENTROPY - secure it immediately."

+ [I'll find them] -> director_morgan
+ [How do we trust anyone?] -> trust_discussion

=== trust_discussion ===
"We don't have the luxury of paranoia right now. We trust our training, our procedures, and each other - until evidence proves otherwise." #speaker:Director Morgan

"After tonight, we'll conduct a full internal investigation. But right now, focus on stopping the attack."

"The mole can't help ENTROPY if ENTROPY fails."

+ [Understood] -> director_morgan

=== architect_goal_discussion ===
She brings up a strategic analysis display.

"Our analysts believe The Architect is testing something. These coordinated attacks are a proof-of-concept." #speaker:Director Morgan

"**Hypothesis 1:** Training exercises for larger future operation
**Hypothesis 2:** Demonstrating capability to recruit nation-state clients
**Hypothesis 3:** Ideological - genuinely believes in accelerating societal collapse
**Hypothesis 4:** Personal vendetta against someone in government/intelligence"

"Honestly? We don't know. But tonight's attacks feel like... a rehearsal. Building toward something bigger."

She pauses.

"That's why stopping them tonight is so critical. Not just for the immediate lives saved, but to disrupt whatever they're planning next."

+ [We'll stop them] -> director_morgan

=== tactical_guidance ===
She reviews your mission profile.

"Tactical guidance for your operation:" #speaker:Director Morgan

{crisis_choice == "infrastructure":
    "**Priority:** Reach the SCADA control room before the timer expires.

    **Key Intel:** Marcus Chen is a true believer. He won't surrender easily, but he's not suicidal. If you present evidence of civilian casualties, he might hesitate.

    **VM Challenge:** Focus on extracting shutdown codes from the NFS shares. You'll need root access to disable the attack scripts.

    **Warning:** Chen has backup operatives. Expect resistance, but avoid prolonged combat - you're on a clock."
}

{crisis_choice == "data":
    "**Priority:** You're facing dual threats - data exfiltration AND disinformation deployment.

    **Critical Choice:** You may not be able to stop both. If forced to choose, prioritize based on your assessment of long-term vs. short-term damage.

    **Key Intel:** Rachel Morrow (Social Fabric) can be recruited. Show her evidence of ENTROPY's casualty projections - she thinks she's exposing corruption, not causing deaths.

    **Warning:** Specter (Ghost Protocol) will escape. Don't waste time chasing them - Ghost Protocol always has exit strategies."
}

{crisis_choice == "supply_chain":
    "**Priority:** Disable backdoor injection before software updates deploy.

    **Key Intel:** Adrian Cross is philosophically opposed to supply chain vulnerabilities, not actually pro-murder. He's recruitable if shown casualty evidence.

    **VM Challenge:** Focus on quarantining already-modified updates AND preventing future injections.

    **Strategic Value:** If you recruit Adrian, he's valuable long-term - deep knowledge of supply chain attack methods."
}

{crisis_choice == "corporate":
    "**Priority:** Deploy countermeasures to all 12 target corporations before zero-days deploy.

    **Key Intel:** Victoria Zhang (Digital Vanguard) is ideologically motivated, Marcus Chen (Zero Day Syndicate) is mercenary. Exploit that difference.

    **VM Challenge:** Extract countermeasure codes and deploy patches via the automated system.

    **Warning:** Marcus will escape. Victoria is recruitable - show her the casualty projections from the other operations."
}

"Good luck, Agent. You're our best operator for a reason."

+ [Thank you] -> director_morgan

=== intelligence_discussion ===
"What have you found so far?" #speaker:Director Morgan

+ [Tell me what I should be looking for] -> intel_targets
+ [I'm still gathering intelligence] -> director_morgan

=== intel_targets ===
She brings up an intelligence priority list.

"**HIGH-PRIORITY INTELLIGENCE TARGETS:**

1. **Tomb Gamma Location** - The Architect's command center. We've intercepted references to coordinates, likely in communications on site.

2. **SAFETYNET Mole Evidence** - Any emails or messages between ENTROPY and someone with a SAFETYNET email address.

3. **ENTROPY Cell Structure** - How the different cells coordinate, who reports to The Architect.

4. **Future Operation Plans** - Any indication of what comes after tonight.

If you find any of this, it's critical for preventing future attacks."

+ [I'll search thoroughly] -> director_morgan

-> END
