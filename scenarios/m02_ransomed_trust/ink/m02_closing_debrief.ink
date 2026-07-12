// ===========================================
// ACT 3: CLOSING DEBRIEF
// Mission 2: Ransomed Trust
// Break Escape - Consequences and Reflection
// ===========================================

// Variables synced from globalVars by engine at call-open
VAR paid_ransom = false
VAR exposed_hospital = false
VAR marcus_protected = false
VAR kim_guilt_revealed = false
VAR ghost_deal_accepted = false
VAR advised_board_pay = false
VAR advised_board_refuse = false
VAR flag_ghost_log_submitted = false
VAR lore_ghosts_manifesto_found = false
VAR lore_cryptosecure_found = false
VAR lore_zds_invoice_found = false

// Inside-asset investigation outcomes
VAR insider_identified = false
VAR insider_confronted = false
VAR insider_asset_arrested = false
VAR insider_asset_escaped = false
VAR insider_asset_exposed = false
VAR accused_wrong_suspect = false
VAR night_security_supervisor_ko = false

// Local: how the player carries the weight of the mission. Set in the hub,
// paid off in the final reflection. Not a global -- self-contained to this scene.
VAR player_shaken = false
VAR player_cold = false

EXTERNAL player_name()

// ===========================================
// DEBRIEF START
// ===========================================

=== start ===
#speaker:narrator
Narrator: SAFETYNET headquarters. Forty-eight hours after St. Catherine's.

#speaker:agent_0x99
Agent HaX: {player_name()}. Good to see you back on your feet. That's not nothing, after a night like that.

Agent HaX: Systems are back. Patients are stable. But I've read your field notes twice and I keep landing on the same thing.

Agent HaX: This wasn't a burglary. Ghost didn't want money -- they wanted a lesson taught in bodies. Casualties, calculated in advance, signed off before the operation ever started.

Agent HaX: We've seen that signature before. You've seen it before.

* [You mean Derek. Social Fabric.]
    ~ player_cold = true
    Agent HaX: I mean Derek. Same fingerprints, different hands.
    Agent HaX: Operation Shatter, this -- ENTROPY doesn't improvise. Somebody's teaching them.
    -> debrief_hub
* [Say that plainly. Who's really behind this?]
    ~ player_shaken = true
    Agent HaX: You already know the answer you don't want. So do I.
    Agent HaX: We'll get to it. Ask me what you need first.
    -> debrief_hub

// ===========================================
// DEBRIEF HUB -- player-driven questions
// Each answer is distinct. Nothing here is on rails; the consequence
// report plays in full once you're done, no matter what you skip.
// ===========================================

=== debrief_hub ===
#speaker:agent_0x99

- (options)
Agent HaX: {&What do you want to know?|What else?|Anything more before we get to the cost?|Ask.}

* [Who was Ghost, really?]
    -> q_ghost_identity
* {q_entropy_link < 1} [This was ENTROPY again -- like Derek's cell at Viral Dynamics.]
    -> q_entropy_link
* {q_entropy_link > 0 and q_architect < 1} [Then who's running the cells? The Architect?]
    -> q_architect
* [Enough. Walk me through what it cost.]
    -> mission_summary

=== q_ghost_identity ===
#speaker:agent_0x99

Agent HaX: Honestly? We don't know. "Ghost" is a handle, not a name.

Agent HaX: Fourteen months of preparation. A device planted during a fire drill six weeks before you ever arrived. Comms discipline so clean we've got nothing -- no face, no voice print, no trail out.

Agent HaX: What we do know is the shape of them. A true believer. Ransomware Incorporated's field operative, and they meant every word of it. To Ghost, the patients weren't victims. They were the argument.

{q_entropy_link > 0:
    Agent HaX: And that discipline? It's trained. Nobody's that careful by accident. Same school as Derek.
}

-> debrief_hub

=== q_entropy_link ===
#speaker:agent_0x99

Agent HaX: Yes. ENTROPY. The same network that ran Social Fabric out of Viral Dynamics.

Agent HaX: Derek Lawson kept casualty projections -- a spreadsheet of how many people Operation Shatter would kill, approved before he pulled the trigger. Ghost kept mortality calculations. Different cell, different weapon. Identical arithmetic.

Agent HaX: That's not coincidence. That's a method. Somebody taught both of them to do the math and sleep at night.

* [So the cells don't even know each other?]
    Agent HaX: Compartmentalised. Social Fabric never heard of Ransomware Incorporated. That's by design -- you can't burn a network you can't see.
    Agent HaX: But they all learned from the same source.
    -> debrief_hub
* [Then Derek was never the end of it.]
    Agent HaX: Derek was one node. Whatever happened to him at Viral Dynamics, the network kept moving. Ghost is proof.
    Agent HaX: We don't win this by catching operatives. We win it by finding the one who trains them.
    -> debrief_hub

=== q_architect ===
#speaker:agent_0x99

Agent HaX: The Architect. Derek's letter named them. Ghost's logs point the same way, without ever saying it.

Agent HaX: One person -- or one mind -- coordinating every cell. Social Fabric. Ransomware Incorporated. The two you haven't met yet.

Agent HaX: We don't have a name. We have a philosophy, a signature, and now two data points that rhyme. That's more than we had a week ago. Because of you.

-> debrief_hub

// ===========================================
// MISSION SUMMARY -- consequence spine begins here
// ===========================================

=== mission_summary ===
#speaker:agent_0x99

{flag_ghost_log_submitted:
    Agent HaX: You found Ghost's operational log. The mortality calculations.
    Agent HaX: Pre-planned. Spreadsheet-precise. They knew what the statistics meant before the operation started and ran it anyway.
}

{lore_ghosts_manifesto_found:
    Agent HaX: The manifesto -- read it again when you have time. It's how they see themselves. Understanding their ideology matters for what comes next.
}

{not flag_ghost_log_submitted and not lore_ghosts_manifesto_found:
    Agent HaX: The exploit chain was exactly what Ghost's communications suggested -- CVE-2010-4652, fourteen years unpatched. Standard ENTROPY playbook.
}

{ghost_deal_accepted:
    Agent HaX: And you negotiated with Ghost. Got the keys without the ransom payment.
    Agent HaX: That was unconventional. The ethics of it depend entirely on what you did at the press terminal.
}

-> patient_outcomes

// ===========================================
// PATIENT OUTCOMES (Critical Callback)
// ===========================================

=== patient_outcomes ===
#speaker:agent_0x99

{paid_ransom:
    -> ransom_paid_outcomes
- else:
    -> manual_recovery_outcomes
}

=== ransom_paid_outcomes ===
#speaker:agent_0x99

Agent HaX: You paid the ransom. Systems restored in under four hours.

Agent HaX: Patient outcomes: 2 fatalities. Cardiac events during system transition -- both had pre-existing complications.

Agent HaX: 45 patients survived. Medical board ruled the deaths statistically probable regardless of the attack.

* [45 people are alive because we moved fast.]
    Agent HaX: Yes. That's real. Those families don't have funerals.
    Agent HaX: But the $87,000 is already gone. You should know where it went.
    -> entropy_funding_discussion

* [2 people died. That's not nothing.]
    Agent HaX: No. It's not. They were elderly, critical -- but they were alive when we arrived.
    Agent HaX: Medical review concluded the attack accelerated what would have happened anyway. I'm not sure that's the comfort it's supposed to be.
    -> ransom_paid_funding

* [What does $87,000 actually buy them?]
    -> entropy_funding_discussion

=== ransom_paid_funding ===
#speaker:agent_0x99

Agent HaX: The $87,000. You should know where it goes.

-> entropy_funding_discussion

=== manual_recovery_outcomes ===
#speaker:agent_0x99

Agent HaX: You chose manual recovery. Eleven hours, thirty-four minutes. Just inside the window.

Agent HaX: Patient outcomes: 6 fatalities. Ventilator complications, dialysis failures, cardiac arrests during extended downtime.

* [6 people died because I refused to pay.]
    -> manual_recovery_guilt

* [But ENTROPY got nothing. No operational funding.]
    -> manual_recovery_vindication

=== manual_recovery_guilt ===
#speaker:agent_0x99

Agent HaX: 6 people died during a crisis Ghost created. Not you.

Agent HaX: Medical review: 4 of the 6 had terminal diagnoses -- life expectancy under six months regardless. 2 were critical ICU patients, 50/50 odds even without the attack.

* [Ghost told me those deaths would be on my conscience.]
    Agent HaX: Ghost designed that line for maximum effect. They calculated patient death probabilities specifically to weaponise your empathy.
    Agent HaX: Don't let them win twice -- once with the attack, again with guilt.
    -> manual_recovery_vindication

* [I made the best decision I could]
    -> manual_recovery_vindication

=== manual_recovery_vindication ===
#speaker:agent_0x99

Agent HaX: You denied ENTROPY $87,000. No operational funding for Ransomware Incorporated.

Agent HaX: Ghost's next hospital target -- delayed. Possibly cancelled. And we have no transaction to trace, which means they have less financial signal to hide behind.

-> entropy_funding_discussion

// ===========================================
// ENTROPY FUNDING DISCUSSION
// ===========================================

=== entropy_funding_discussion ===
#speaker:agent_0x99

{paid_ransom:
    Agent HaX: 2.5 BTC. HashChain Exchange, Monero mixing, multi-hop routing. The trail goes cold within hours.
    Agent HaX: Ransomware Incorporated has operational funding for their next two or three operations.
}
{not paid_ransom:
    Agent HaX: No transaction means no financial trail -- which cuts both ways. Less to trace, but they have less too.
}

Agent HaX: Either way, Crypto Anarchists handle ENTROPY's payment infrastructure across all cells. That's a mission for another day.

{paid_ransom:
    Agent HaX: Your ransom gives us a fresh transaction to trace. Specific wallets. Specific timing. That's data.
- else:
    Agent HaX: ENTROPY goes into their next operation short-funded. That changes what they can afford to do.
}

-> hospital_status

// ===========================================
// HOSPITAL STATUS
// ===========================================

=== hospital_status ===
#speaker:agent_0x99

{exposed_hospital:
    -> hospital_exposed_path
- else:
    -> hospital_quiet_path
}

=== hospital_exposed_path ===
#speaker:agent_0x99

Agent HaX: You published the evidence.

Agent HaX: "Hospital Ignored IT Warnings for Six Months Before Ransomware Attack." The story ran within the hour.

Agent HaX: Congressional hearings. Forty-plus hospitals implementing emergency security audits within a fortnight.

{ghost_deal_accepted:
    Agent HaX: Ghost got exactly what they wanted -- the public lesson. Without spending a penny.
    Agent HaX: Whether that matters depends on what you think counts as winning.
}

* [Did I do the right thing by exposing them?]
    -> exposure_reflection

* [What happened to Dr. Kim and Marcus?]
    -> npc_outcomes_exposed

=== exposure_reflection ===
#speaker:agent_0x99

Agent HaX: Forty hospitals upgraded their security posture within two weeks of the story breaking.

Agent HaX: Long-term lives saved -- hard to count, but real.

Agent HaX: St. Catherine's is going to spend years in legal proceedings. Their reputation is damaged in ways that will cost the patients who still need care there.

Agent HaX: I don't know if it was right. I know it was consequential.

-> npc_outcomes_exposed

=== hospital_quiet_path ===
#speaker:agent_0x99

Agent HaX: You kept the evidence internal. St. Catherine's board has privately committed to a security overhaul -- cybersecurity budget tripled. $250,000 annual allocation.

Agent HaX: Reputation intact. Public unaware.

{ghost_deal_accepted:
    Agent HaX: Ghost considers the deal broken. They'll remember that.
}

* [Should I have exposed them?]
    -> quiet_resolution_reflection

* [What happened to Dr. Kim and Marcus?]
    -> npc_outcomes_quiet

=== quiet_resolution_reflection ===
#speaker:agent_0x99

Agent HaX: 214 hospitals scanned. 147 with critical vulnerabilities. None of them know what happened here.

Agent HaX: Some of them will be hit before someone publishes the lesson. I don't know how many.

Agent HaX: St. Catherine's is safer. The rest of the sector -- unchanged.

-> npc_outcomes_quiet

// ===========================================
// NPC OUTCOMES (Exposed Path)
// ===========================================

=== npc_outcomes_exposed ===
#speaker:agent_0x99

Agent HaX: Dr. Kim resigned under pressure. Congressional testimony. Reputation damaged, not destroyed -- she's consulting in healthcare tech now.

{kim_guilt_revealed:
    Agent HaX: She told investigators she recommended the budget cuts. Accepted responsibility publicly.
    Agent HaX: That took something. Not many executives do that.
}

Agent HaX: Marcus Webb...

{marcus_protected:
    -> marcus_protected_exposed
- else:
    -> marcus_unprotected_exposed
}

=== marcus_protected_exposed ===
#speaker:agent_0x99

Agent HaX: Vindicated. Your documentation of his warnings went public alongside everything else.

Agent HaX: He's Director of Cybersecurity at Metro General now. Full team, proper budget.

Agent HaX: He asked us to pass something on: "Tell the agent who documented my warnings. They gave me my career back."

-> ghost_status

=== marcus_unprotected_exposed ===
#speaker:agent_0x99

Agent HaX: He was fired within 48 hours of the attack. Scapegoated.

Agent HaX: But when the story broke -- his emails were in it. Seven warnings, ignored. The backlash forced St. Catherine's to rehire him. He's IT Security Director now.

Agent HaX: He survived it. But he asked me: "Does the agency know what happened to me here?"

Agent HaX: I told him yes. We know.

-> ghost_status

// ===========================================
// NPC OUTCOMES (Quiet Path)
// ===========================================

=== npc_outcomes_quiet ===
#speaker:agent_0x99

Agent HaX: Dr. Kim kept her position. Private reprimand, no public consequences.

{kim_guilt_revealed:
    Agent HaX: She told me she'll never ignore an IT warning again. I believe her. Guilt is a better teacher than public shame, sometimes.
}

Agent HaX: Marcus Webb...

{marcus_protected:
    -> marcus_protected_quiet
- else:
    -> marcus_unprotected_quiet
}

=== marcus_protected_quiet ===
#speaker:agent_0x99

Agent HaX: You protected him. Your documentation went into the internal review.

Agent HaX: Promoted to Director of Cybersecurity. Full budget authority. He sent a message: "Thank whoever it was who documented the warnings. Saved my career."

-> ghost_status

=== marcus_unprotected_quiet ===
#speaker:agent_0x99

Agent HaX: He was fired quietly. No public scapegoat narrative -- but the career's gone.

Agent HaX: Blacklisted in healthcare IT. "Failed to prevent catastrophic breach."

Agent HaX: He did everything right. Warned them. Documented the risk. Seven times.

Agent HaX: Last I heard, he's working help desk at a community college. $45,000 a year.

#speaker:narrator
Narrator: A pause.

#speaker:agent_0x99
Agent HaX: That's the injustice that radicalises people. The ones who did the right thing and got ground up for it anyway.

Agent HaX: Remember that when you think about Ghost's ideology. They're not wrong about the problem.

-> ghost_status

// ===========================================
// GHOST STATUS
// ===========================================

=== ghost_status ===
#speaker:agent_0x99

Agent HaX: Ghost vanished. Ghost Protocol anonymity architecture performed exactly as designed. No trace. No leads.

Agent HaX: Ransomware Incorporated is still operational.

* [Ghost escaped. We failed.]
    Agent HaX: We disrupted their operation and gathered intelligence on how they work. That's not failure.
    {paid_ransom:
        Agent HaX: We have a transaction trail. Financial data for an operation further down the line.
    - else:
        Agent HaX: We denied them funding. They go into the next operation short.
    }
    Agent HaX: We learned their methodology. Calculated harm, ideological certainty, coordinated cells. That matters.
    -> insider_status

* [What about ENTROPY's structure?]
    -> insider_status

// ===========================================
// INSIDE ASSET OUTCOME
// ===========================================

=== insider_status ===
#speaker:agent_0x99

{insider_asset_arrested:
    -> insider_rolled_up
}
{insider_asset_escaped:
    -> insider_escaped
}
{night_security_supervisor_ko:
    -> insider_neutralised_ko
}
{insider_identified:
    -> insider_flagged
}
{accused_wrong_suspect:
    -> insider_missed_wrong
}
-> insider_unnoticed

=== insider_rolled_up ===
#speaker:agent_0x99

Agent HaX: And you got the one Ghost planted inside. The night security supervisor -- badge SC-4471. He authorised the fire drill that put ENTROPY's device on the LAN.

{insider_asset_exposed:
    Agent HaX: You named him publicly alongside the board. He'll stand next to their negligence in every story that runs.
}

Agent HaX: We've had his post assignments, his access logs, his handler contacts for six hours now. That's not one arrest -- that's a thread into the whole cell.

Agent HaX: Underpaid, ignored, radicalised by the same negligence he helped punish. Remember what I said about the injustice that makes people. He's the proof.

Agent HaX: Good work finding him. Intelligence like that feeds every mission that comes after this one.

-> entropy_coordination_reveal

=== insider_neutralised_ko ===
#speaker:agent_0x99

{insider_identified:
    Agent HaX: And you put down the inside asset yourself. The night security supervisor -- badge SC-4471. No interrogation, so the cell thread is thinner than an arrest would've given us, but he's off the board and contained.
- else:
    Agent HaX: One more thing. The night security supervisor you took down in the conference room -- we ran him afterwards. Badge SC-4471. He authorised the fire drill that planted ENTROPY's device.
    Agent HaX: You had the right man. You just never knew what you were holding. We recovered what we could from his post logs, but he wasn't talking.
}

Agent HaX: Underpaid, ignored, radicalised by the same negligence he helped punish. Remember what I said about the injustice that makes people.

-> entropy_coordination_reveal

=== insider_flagged ===
#speaker:agent_0x99

Agent HaX: You identified Ghost's inside asset -- the night security supervisor, badge SC-4471. You didn't get to close it out yourself, but your identification was enough.

Agent HaX: SAFETYNET moved on the intel and picked him up before he could disappear. His access logs and handler contacts are ours now. A thread into the cell.

-> entropy_coordination_reveal

=== insider_escaped ===
#speaker:agent_0x99

Agent HaX: There's one more thing you should know. Ghost told you the truth -- there was an affiliate inside the building. The night security supervisor.

Agent HaX: He was standing at the press terminal the whole time. When you transmitted, he moved on you and got out in the confusion. By the time backup reached the conference room, he was gone.

Agent HaX: Vanished. No trace. The same way Ghost went. That one's on the clock we were racing -- but if we'd read the signs earlier, we'd have had him.

-> entropy_coordination_reveal

=== insider_missed_wrong ===
#speaker:agent_0x99

Agent HaX: One loose end. Ghost wasn't bluffing about an inside affiliate -- there was one. And you spent your suspicion on the wrong person.

Agent HaX: The real asset was the night security supervisor on the conference-room post. Badge SC-4471. He walked out the same night, unquestioned.

Agent HaX: It happens. The evidence pointed where they wanted it to point. But it's a lead we'll be chasing cold now.

-> entropy_coordination_reveal

=== insider_unnoticed ===
#speaker:agent_0x99

Agent HaX: One thing we never closed. Ghost said someone in that building confirmed their operational timing. An ENTROPY affiliate.

Agent HaX: We never identified them. Whoever it was is still on staff, still trusted, still inside. Next time we go into one of these, we look harder for the person holding the door.

-> entropy_coordination_reveal

=== entropy_coordination_reveal ===
#speaker:agent_0x99

Agent HaX: Ghost's logs confirmed what we suspected -- Zero Day Syndicate sourced the ProFTPD exploit. Crypto Anarchists handle payment processing across all cells.

{lore_cryptosecure_found:
    Agent HaX: The CryptoSecure intelligence you recovered -- that's their financial front. We're building a picture of the network.
}

{lore_zds_invoice_found:
    Agent HaX: The Zero Day Syndicate invoice you found -- specific evidence of the procurement chain between ENTROPY cells. That's going straight into planning for what comes next.
}

Agent HaX: The Zero Day Syndicate is next in our sights. The Crypto Anarchists, further down the line.

Agent HaX: Your work here feeds both.

-> final_reflection

// ===========================================
// FINAL REFLECTION
// ===========================================

=== final_reflection ===
#speaker:agent_0x99

Agent HaX: Here's what I'll say, {player_name()}.

{player_cold:
    Agent HaX: When you walked in here, you named Derek before I could. Cold. Focused. That's useful in this work -- but I want you to hear the next part anyway.
}
{player_shaken:
    Agent HaX: You couldn't say the Architect's name out loud when you came in. Good. The day this stops costing you something is the day I start worrying about you.
}

{advised_board_refuse and paid_ransom:
    Agent HaX: One more thing. Dr. Kim held the board off because you told her you'd have the keys in time. In the end, someone wrote the cheque anyway. She spent trust she didn't have to spare -- on your word. People remember that.
}
{advised_board_pay and not paid_ransom:
    Agent HaX: For what it's worth -- you told Kim to pay, then found a way that didn't need paying. She'll have gone into that boardroom arguing for a cheque nobody had to write. A small thing. She noticed it anyway.
}
{advised_board_refuse and not paid_ransom:
    Agent HaX: And you kept your word to Kim. You told her you'd get the keys without paying, and you did. In this line of work, that's rarer than it should be. She knows what you spent to make good on it.
}
{advised_board_pay and paid_ransom:
    Agent HaX: You told Kim to pay, and that's how it ended. No surprises for her. She trusted your read, and your read held. That matters more than you'd think, next time you need someone on the inside to believe you.
}

Agent HaX: You faced a dilemma Ghost designed specifically to have no clean answer. Pay or don't pay -- both choices cost lives. Just different lives, different timeframes.

Agent HaX: You made a call under time pressure, with incomplete information, in a building full of people depending on you.

* [I made the best decision I could with what I had.]
    Agent HaX: That's all this job ever gives you. Best decision, available information, time pressure.
    Agent HaX: ENTROPY creates impossible dilemmas on purpose. They want you paralysed, or they want you to act and feel guilty either way.
    Agent HaX: You acted. That counts.
    -> mission_3_setup

* [I'm still not sure it was the right call.]
    {paid_ransom:
        Agent HaX: 45 people are alive today. That's real. Those are real families not burying someone.
        Agent HaX: ENTROPY has funding. That's also real. Both things are true simultaneously.
    - else:
        Agent HaX: You denied ENTROPY $87,000. Long-term, that matters.
        Agent HaX: Six people died in the downtime. That also matters.
    }
    Agent HaX: I won't tell you which weighs more. I genuinely don't know. Neither does anyone who hasn't stood where you stood.
    -> mission_3_setup

* [What's next?]
    -> mission_3_setup

// ===========================================
// MISSION 3 SETUP
// ===========================================

=== mission_3_setup ===
#speaker:agent_0x99

Agent HaX: Zero Day Syndicate. They sold Ghost the ProFTPD exploit. They scanned 214 hospitals and recommended St. Catherine's specifically.

Agent HaX: Shut down their exploit marketplace and ENTROPY loses its technical supply chain across all cells.

Agent HaX: Operation Cyber Arsenal.

* [Let's take them down.]
    -> debrief_close

* [Ghost mentioned The Architect. Who coordinates ENTROPY?]
    -> architect_tease

=== architect_tease ===
#speaker:agent_0x99

Agent HaX: The Architect runs all six cells. We don't know who they are yet.

Agent HaX: But each mission reveals more. Social Fabric, Ransomware Incorporated -- patterns emerging in how the cells communicate, how they're structured.

Agent HaX: Eventually we'll have enough to identify them. Then we end this.

-> debrief_close

// ===========================================
// DEBRIEF CLOSE
// ===========================================

=== debrief_close ===
#speaker:agent_0x99

Agent HaX: Get some rest, {player_name()}.

Agent HaX: You saved lives. You stopped an ENTROPY operation. You gathered intelligence on their network.

Agent HaX: That's what you came in there to do.

Agent HaX: We'll brief the next operation when you're ready.

#complete_mission
#exit_conversation

-> END
