// Mission 7: The Architect's Gambit - Agent 0x99 Phone Calls
// Your SAFETYNET handler provides tactical support and mission guidance

VAR contacted_0x99 = false
VAR flags_submitted = 0
VAR crisis_neutralized = false
VAR found_tomb_gamma = false
VAR found_mole_evidence = false
VAR asked_about_architect_taunts = false

=== phone_0x99 ===
{contacted_0x99 == false:
    Your phone rings. Secure line. Agent 0x99.

    "0x00, it's 0x99. I'm monitoring your operation remotely. Here to provide tactical support." #speaker:Agent 0x99

    ~ contacted_0x99 = true

    "The Architect is coordinating all four attacks. This is the most sophisticated ENTROPY operation we've ever seen."

    + [What do you need me to do?] -> mission_overview
    + [Tell me about The Architect] -> architect_info
}

{contacted_0x99 == true:
    "0x99 here. What do you need?" #speaker:Agent 0x99

    + [Request tactical guidance] -> tactical_support
    + [Ask about VM exploitation] -> vm_guidance
    + {flags_submitted >= 1} [Ask about intelligence analysis] -> intel_analysis
    + {asked_about_architect_taunts == false} [The Architect is sending me messages] -> architect_taunts
    + {crisis_neutralized == true} [Attack neutralized - what's next?] -> post_neutralization
    + [That's all] -> END
}

=== mission_overview ===
"Your mission is straightforward but time-critical:" #speaker:Agent 0x99

{crisis_choice == "infrastructure":
    "**OBJECTIVE:** Stop the power grid attack before cascading failures begin.

    **KEY TASKS:**
    1. Complete VM exploitation to extract shutdown codes
    2. Submit all 4 flags - we need that intelligence
    3. Reach the SCADA control room before timer expires
    4. Confront Marcus Chen and disable the attack
    5. Search for ENTROPY intelligence (Tomb Gamma location, mole evidence)

    **PRIORITY:** Timer is everything. Don't get bogged down in combat - avoid or neutralize quickly."
}

{crisis_choice == "data":
    "**OBJECTIVE:** Stop voter data breach AND disinformation campaign.

    **KEY TASKS:**
    1. Complete VM exploitation to extract shutdown codes
    2. Submit all 4 flags - critical intelligence needed
    3. Prioritize: breach OR disinformation (you may not stop both)
    4. Confront Specter and Rachel Morrow
    5. Search for ENTROPY intelligence

    **WARNING:** Dual timers. If forced to choose, consider: data breach = long-term identity theft, disinformation = immediate democratic crisis."
}

{crisis_choice == "supply_chain":
    "**OBJECTIVE:** Prevent backdoor injection into software updates.

    **KEY TASKS:**
    1. Complete VM exploitation to extract shutdown codes
    2. Submit all 4 flags for intelligence
    3. Disable injection system before updates deploy
    4. Quarantine already-modified updates
    5. Confront Adrian Cross (he's recruitable - show him casualty evidence)
    6. Search for ENTROPY intelligence

    **NOTE:** This has no immediate casualties but massive long-term consequences. Don't let that reduce your urgency."
}

{crisis_choice == "corporate":
    "**OBJECTIVE:** Deploy countermeasures to 12 corporations before zero-day attacks.

    **KEY TASKS:**
    1. Complete VM exploitation to extract countermeasure codes
    2. Submit all 4 flags for intelligence
    3. Deploy emergency patches to all target corporations
    4. Neutralize exploit staging systems
    5. Confront Victoria Zhang and Marcus Chen
    6. Search for ENTROPY intelligence

    **TIP:** Victoria is recruitable. Marcus will escape - don't waste time chasing him."
}

"You have 30 minutes. Clock started when you left the EOC."

+ [Understood] -> phone_0x99
+ [What about the other teams?] -> other_teams_info

=== other_teams_info ===
"The other teams are engaged as we speak. Outcomes are unfolding exactly as Director Morgan predicted." #speaker:Agent 0x99

{crisis_choice == "infrastructure":
    "Team Alpha is handling supply chain - they'll succeed. Team Bravo on data - partial success expected, disinformation will deploy. Team Charlie on corporate - they're failing, healthcare ransomware is going live."
}

{crisis_choice == "data":
    "Team Alpha on infrastructure - they're failing, blackout is happening. Team Bravo on corporate - full success, they're crushing it. Team Charlie on supply chain - partial, some backdoors getting through."
}

{crisis_choice == "supply_chain":
    "Team Alpha on data - full success, both attacks stopped. Team Bravo on infrastructure - partial, some casualties occurring. Team Charlie on corporate - failing, economic damage mounting."
}

{crisis_choice == "corporate":
    "Team Alpha on infrastructure - full success, blackout prevented. Team Bravo on data - catastrophic failure, both attacks succeeded. Team Charlie on supply chain - partial success."
}

"Your choice determined who gets the best operator - you. Focus on winning YOUR operation. You can't help them now."

+ [Copy that] -> phone_0x99

=== tactical_support ===
"What do you need tactical support on?" #speaker:Agent 0x99

+ [How do I handle the VM challenge?] -> vm_guidance
+ [How do I deal with hostile operatives?] -> combat_guidance
+ [Where should I search for intelligence?] -> intel_locations
+ [Back] -> phone_0x99

=== vm_guidance ===
"The VM is running SecGen's 'putting_it_together' scenario. Multi-stage exploitation." #speaker:Agent 0x99

"**EXPLOITATION PATH:**

**Stage 1: NFS Share Discovery**
* Scan for NFS exports (showmount, nmap)
* Mount remote filesystems
* Find attack staging files, timelines, configurations
* **FLAG 1** is in the NFS shares

**Stage 2: Netcat Service Enumeration**
* Enumerate network services (nmap, netcat)
* Find C2 communication channels
* Intercept commands, extract shutdown codes
* **FLAG 2** is in the netcat services

**Stage 3: Privilege Escalation**
* Exploit sudo misconfigurations or SUID binaries
* Gain root access to critical systems
* **FLAG 3** requires root privileges

**Stage 4: Attack Neutralization**
* Use extracted codes to disable attack systems
* Terminate malicious processes
* Lock out ENTROPY remote access
* **FLAG 4** confirms neutralization complete

Submit each flag as you find it - we're analyzing the intelligence in real-time."

+ [Any specific tools I should use?] -> tool_recommendations
+ [Got it] -> phone_0x99

=== tool_recommendations ===
"Standard penetration testing toolkit:" #speaker:Agent 0x99

* **nmap** - Service enumeration, NFS discovery
* **showmount** - Display NFS exports
* **mount** - Mount remote filesystems
* **netcat (nc)** - Connect to services, enumerate ports
* **find** - Search for SUID binaries, configuration files
* **sudo -l** - Check sudo permissions
* **ps aux** - Identify running attack processes
* **grep** - Search logs and files for intelligence

"Nothing exotic. Standard tools, executed correctly under time pressure."

+ [Thanks] -> phone_0x99

=== combat_guidance ===
{crisis_choice == "infrastructure":
    "Marcus Chen has backup operatives. Hostile NPCs you'll encounter:" #speaker:Agent 0x99

    "* **Jake Morrison** (Security Guard) - Armed, aggressive, will attack on sight
    * **Elena Rodriguez** (Engineer) - Non-violent, will flee if confronted
    * **Thomas Park** (Maintenance) - Will sabotage backup power if you get close

    **RECOMMENDATION:** Avoid prolonged combat. Neutralize quickly or bypass. You're on a clock."
}

{crisis_choice == "data":
    "You're facing Ghost Protocol and Social Fabric operatives:" #speaker:Agent 0x99

    "* **Specter** (Ghost Protocol) - Will escape no matter what, don't chase
    * **Rachel Morrow** (Social Fabric) - Non-violent, uses hostages, RECRUITABLE
    * **Marcus Webb** (Hacker) - Will shoot if cornered, technical expert
    * **Sarah Kim** (Narrative Specialist) - Non-violent, emotionally vulnerable

    **RECOMMENDATION:** Minimize violence, focus on recruitment. Rachel is valuable if turned."
}

{crisis_choice == "supply_chain":
    "Supply Chain Saboteurs are primarily non-violent technicals:" #speaker:Agent 0x99

    "* **Adrian Cross** (Leader) - Non-violent, prefers escape, RECRUITABLE
    * **Elena Vasquez** (Code Signing) - Non-violent, will cooperate if Adrian is turned
    * **James Park** (Security) - Armed, will shoot if exposed
    * **Marcus Chen** (Engineer) - Will flee, technical knowledge useful

    **RECOMMENDATION:** Prioritize recruitment over combat. Adrian is valuable long-term asset."
}

{crisis_choice == "corporate":
    "You're facing two ENTROPY cells coordinating:" #speaker:Agent 0x99

    "* **Victoria Zhang** (Digital Vanguard) - Armed, proficient, RECRUITABLE
    * **Marcus 'Shadow' Chen** (Zero Day Syndicate) - Non-violent, will escape
    * **Elena Rodriguez** (Hacker) - Non-violent, follows Victoria's lead
    * **James Park** (Insider) - Unarmed, will flee

    **RECOMMENDATION:** Focus on Victoria recruitment. Marcus always escapes - it's Zero Day Syndicate protocol."
}

+ [Understood] -> phone_0x99

=== intel_locations ===
"Based on ENTROPY communication patterns, high-value intelligence will be in:" #speaker:Agent 0x99

**TOMB GAMMA COORDINATES:**
* Likely on cell leader's personal terminal or workstation
* Look for encrypted communications, coordinate references
* Montana wilderness location - 47°N, 112°W range

**SAFETYNET MOLE EVIDENCE:**
* Email intercepts on compromised servers
* Look for @safetynet.gov addresses in ENTROPY communications
* Subject lines about operation timing, team assignments

**ENTROPY CELL STRUCTURE:**
* Organizational charts, communication logs
* References to "The Professor" or "The Architect"
* Cell coordination methods

"Search the Crisis Terminal room thoroughly after neutralizing the threat. That's where cell leaders operate from."

+ [I'll search thoroughly] -> phone_0x99

=== architect_taunts ===
~ asked_about_architect_taunts = true

"Yeah, The Architect does that. Psychological warfare." #speaker:Agent 0x99

"They're trying to make you question your choice. Make you hesitate. Second-guess yourself."

"**IGNORE THEM.** You made the best tactical decision based on available intelligence. The casualties at other targets - those aren't YOUR fault. They're THE ARCHITECT'S fault."

"Don't let them get in your head. Every second you spend questioning yourself is a second you're not stopping the attack."

{crisis_choice == "infrastructure":
    "You chose to save 240-385 lives from the blackout. That's the right call. Focus on that."
}

{crisis_choice == "data":
    "You chose to protect democratic institutions. That matters. Don't second-guess it now."
}

{crisis_choice == "supply_chain":
    "You chose long-term security. 47 million future victims prevented. Own that choice."
}

{crisis_choice == "corporate":
    "You chose economic stability. Millions of jobs protected. That's legitimate, don't let them make you feel guilty."
}

+ [You're right. Staying focused.] -> phone_0x99

=== intel_analysis ===
"Let me check what intelligence you've submitted so far..." #speaker:Agent 0x99

{flags_submitted == 0:
    "No flags submitted yet. Get on that VM, 0x00. We need that intelligence to neutralize the attack."
}

{flags_submitted == 1:
    "One flag received. Analysis shows: {crisis_choice} attack timeline confirmed, target systems identified. Keep going."
}

{flags_submitted == 2:
    "Two flags. We've extracted partial shutdown codes. Need the remaining flags for complete neutralization capability."
}

{flags_submitted == 3:
    "Three flags submitted. Almost there. One more and you'll have everything needed to stop this."
}

{flags_submitted == 4:
    "All four flags received. Analysis complete. We have full shutdown codes, deactivation sequences, and intelligence on ENTROPY methods."

    "Outstanding work. Now use that intelligence to neutralize the threat."
}

+ [Continue] -> phone_0x99

=== post_neutralization ===
"Attack neutralized. Excellent work, 0x00." #speaker:Agent 0x99

"But the mission isn't complete. We need intelligence about ENTROPY's broader operations."

{found_tomb_gamma == false:
    "**PRIORITY:** Find Tomb Gamma coordinates. This is The Architect's command center. Critical for future operations against ENTROPY."
}

{found_mole_evidence == false:
    "**PRIORITY:** Find evidence of the SAFETYNET mole. Someone inside is feeding The Architect our operational details."
}

{found_tomb_gamma == true and found_mole_evidence == true:
    "You've secured both Tomb Gamma location and mole evidence. Outstanding intelligence gathering."

    "Prepare for debrief. We need to analyze this immediately."
}

"Search the area thoroughly. Cell leaders always leave intelligence behind - they're human, they make mistakes."

+ [I'll keep searching] -> phone_0x99
+ [Requesting extraction] -> extraction_request

=== extraction_request ===
{crisis_neutralized == false:
    "Negative on extraction. Attack is still active. Neutralize the threat first." #speaker:Agent 0x99
    -> phone_0x99
}

{crisis_neutralized == true and (found_tomb_gamma == false or found_mole_evidence == false):
    "Not yet. We need that intelligence. Tomb Gamma location and mole evidence are critical." #speaker:Agent 0x99

    "Take five more minutes. Search thoroughly."
    -> phone_0x99
}

{crisis_neutralized == true and found_tomb_gamma == true and found_mole_evidence == true:
    "Extraction approved. Transport inbound to your location. ETA 3 minutes." #speaker:Agent 0x99

    "Director Morgan wants immediate debrief. You'll be reviewing outcomes from all four operations."

    "Prepare yourself. The casualties from unchosen operations... it's going to be tough to process."

    "But you did your job. You won YOUR battle. Remember that."
    -> END
}

-> END
