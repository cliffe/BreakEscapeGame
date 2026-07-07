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
VAR flag_ghost_log_submitted = false
VAR lore_ghosts_manifesto_found = false
VAR lore_cryptosecure_found = false
VAR lore_zds_invoice_found = false

EXTERNAL player_name()

// ===========================================
// DEBRIEF START
// ===========================================

=== start ===
#speaker:narrator
Narrator: SAFETYNET secure channel. Forty-eight hours after the mission.

#speaker:agent_0x99
Agent 0x99: {player_name()}. Good to see you back.

Agent 0x99: St. Catherine's is stabilised. Systems restored. The immediate crisis is over.

Agent 0x99: Let's debrief.

* [How are the patients?]
    -> patient_outcomes

* [What happened to Ghost?]
    -> ghost_status

* [Walk me through what we found]
    -> mission_summary

// ===========================================
// MISSION SUMMARY
// ===========================================

=== mission_summary ===
#speaker:agent_0x99

{flag_ghost_log_submitted:
    Agent 0x99: You found Ghost's operational log. The mortality calculations.
    Agent 0x99: Pre-planned. Spreadsheet-precise. They knew what the statistics meant before the operation started and ran it anyway.
}

{lore_ghosts_manifesto_found:
    Agent 0x99: The manifesto -- read it again when you have time. It's how they see themselves. Understanding their ideology matters for what comes next.
}

{not flag_ghost_log_submitted and not lore_ghosts_manifesto_found:
    Agent 0x99: The exploit chain was exactly what Ghost's communications suggested -- CVE-2010-4652, fourteen years unpatched. Standard ENTROPY playbook.
}

{ghost_deal_accepted:
    Agent 0x99: And you negotiated with Ghost. Got the keys without the ransom payment.
    Agent 0x99: That was unconventional. The ethics of it depend entirely on what you did at the press terminal.
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

Agent 0x99: You paid the ransom. Systems restored in under four hours.

Agent 0x99: Patient outcomes: 2 fatalities. Cardiac events during system transition -- both had pre-existing complications.

Agent 0x99: 45 patients survived. Medical board ruled the deaths statistically probable regardless of the attack.

* [We saved 45 lives]
    You: 45 people are alive because we moved fast.
    Agent 0x99: Yes. That's real. Those families don't have funerals.
    Agent 0x99: But the $87,000 is already gone. You should know where it went.
    -> entropy_funding_discussion

* [2 people still died]
    You: 2 people died. That's not nothing.
    Agent 0x99: No. It's not. They were elderly, critical -- but they were alive when we arrived.
    Agent 0x99: Medical review concluded the attack accelerated what would have happened anyway. I'm not sure that's the comfort it's supposed to be.
    -> ransom_paid_funding

* [What does $87,000 actually buy them?]
    -> entropy_funding_discussion

=== ransom_paid_funding ===
#speaker:agent_0x99

Agent 0x99: The $87,000. You should know where it goes.

-> entropy_funding_discussion

=== manual_recovery_outcomes ===
#speaker:agent_0x99

Agent 0x99: You chose manual recovery. Eleven hours, thirty-four minutes. Just inside the window.

Agent 0x99: Patient outcomes: 6 fatalities. Ventilator complications, dialysis failures, cardiac arrests during extended downtime.

* [6 people died because of my decision]
    You: 6 people died because I refused to pay.
    -> manual_recovery_guilt

* [We denied ENTROPY their funding]
    You: But ENTROPY got nothing. No operational funding.
    -> manual_recovery_vindication

=== manual_recovery_guilt ===
#speaker:agent_0x99

Agent 0x99: 6 people died during a crisis Ghost created. Not you.

Agent 0x99: Medical review: 4 of the 6 had terminal diagnoses -- life expectancy under six months regardless. 2 were critical ICU patients, 50/50 odds even without the attack.

* [Ghost said those deaths were on my conscience]
    You: Ghost told me those deaths would be on my conscience.
    Agent 0x99: Ghost designed that line for maximum effect. They calculated patient death probabilities specifically to weaponise your empathy.
    Agent 0x99: Don't let them win twice -- once with the attack, again with guilt.
    -> manual_recovery_vindication

* [I made the best decision I could]
    -> manual_recovery_vindication

=== manual_recovery_vindication ===
#speaker:agent_0x99

Agent 0x99: You denied ENTROPY $87,000. No operational funding for Ransomware Incorporated.

Agent 0x99: Ghost's next hospital target -- delayed. Possibly cancelled. And we have no transaction to trace, which means they have less financial signal to hide behind.

-> entropy_funding_discussion

// ===========================================
// ENTROPY FUNDING DISCUSSION
// ===========================================

=== entropy_funding_discussion ===
#speaker:agent_0x99

{paid_ransom:
    Agent 0x99: 2.5 BTC. HashChain Exchange, Monero mixing, multi-hop routing. The trail goes cold within hours.
    Agent 0x99: Ransomware Incorporated has operational funding for their next two or three operations.
}
{not paid_ransom:
    Agent 0x99: No transaction means no financial trail -- which cuts both ways. Less to trace, but they have less too.
}

Agent 0x99: Either way, Crypto Anarchists handle ENTROPY's payment infrastructure across all cells. That's Mission 6.

{paid_ransom:
    Agent 0x99: Your ransom gives us a fresh transaction to trace. Specific wallets. Specific timing. That's data.
- else:
    Agent 0x99: ENTROPY goes into their next operation short-funded. That changes what they can afford to do.
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

Agent 0x99: You published the evidence.

Agent 0x99: "Hospital Ignored IT Warnings for Six Months Before Ransomware Attack." The story ran within the hour.

Agent 0x99: Congressional hearings. Forty-plus hospitals implementing emergency security audits within a fortnight.

{ghost_deal_accepted:
    Agent 0x99: Ghost got exactly what they wanted -- the public lesson. Without spending a penny.
    Agent 0x99: Whether that matters depends on what you think counts as winning.
}

* [Was that the right call?]
    You: Did I do the right thing by exposing them?
    -> exposure_reflection

* [What happened to Dr. Kim and Marcus?]
    -> npc_outcomes_exposed

=== exposure_reflection ===
#speaker:agent_0x99

Agent 0x99: Forty hospitals upgraded their security posture within two weeks of the story breaking.

Agent 0x99: Long-term lives saved -- hard to count, but real.

Agent 0x99: St. Catherine's is going to spend years in legal proceedings. Their reputation is damaged in ways that will cost the patients who still need care there.

Agent 0x99: I don't know if it was right. I know it was consequential.

-> npc_outcomes_exposed

=== hospital_quiet_path ===
#speaker:agent_0x99

Agent 0x99: You kept the evidence internal. St. Catherine's board has privately committed to a security overhaul -- cybersecurity budget tripled. $250,000 annual allocation.

Agent 0x99: Reputation intact. Public unaware.

{ghost_deal_accepted:
    Agent 0x99: Ghost considers the deal broken. They'll remember that.
}

* [Should I have published?]
    You: Should I have exposed them?
    -> quiet_resolution_reflection

* [What happened to Dr. Kim and Marcus?]
    -> npc_outcomes_quiet

=== quiet_resolution_reflection ===
#speaker:agent_0x99

Agent 0x99: 214 hospitals scanned. 147 with critical vulnerabilities. None of them know what happened here.

Agent 0x99: Some of them will be hit before someone publishes the lesson. I don't know how many.

Agent 0x99: St. Catherine's is safer. The rest of the sector -- unchanged.

-> npc_outcomes_quiet

// ===========================================
// NPC OUTCOMES (Exposed Path)
// ===========================================

=== npc_outcomes_exposed ===
#speaker:agent_0x99

Agent 0x99: Dr. Kim resigned under pressure. Congressional testimony. Reputation damaged, not destroyed -- she's consulting in healthcare tech now.

{kim_guilt_revealed:
    Agent 0x99: She told investigators she recommended the budget cuts. Accepted responsibility publicly.
    Agent 0x99: That took something. Not many executives do that.
}

Agent 0x99: Marcus Webb...

{marcus_protected:
    -> marcus_protected_exposed
- else:
    -> marcus_unprotected_exposed
}

=== marcus_protected_exposed ===
#speaker:agent_0x99

Agent 0x99: Vindicated. Your documentation of his warnings went public alongside everything else.

Agent 0x99: He's Director of Cybersecurity at Metro General now. Full team, proper budget.

Agent 0x99: He asked us to pass something on: "Tell the agent who documented my warnings. They gave me my career back."

-> ghost_status

=== marcus_unprotected_exposed ===
#speaker:agent_0x99

Agent 0x99: He was fired within 48 hours of the attack. Scapegoated.

Agent 0x99: But when the story broke -- his emails were in it. Seven warnings, ignored. The backlash forced St. Catherine's to rehire him. He's IT Security Director now.

Agent 0x99: He survived it. But he asked me: "Does the agency know what happened to me here?"

Agent 0x99: I told him yes. We know.

-> ghost_status

// ===========================================
// NPC OUTCOMES (Quiet Path)
// ===========================================

=== npc_outcomes_quiet ===
#speaker:agent_0x99

Agent 0x99: Dr. Kim kept her position. Private reprimand, no public consequences.

{kim_guilt_revealed:
    Agent 0x99: She told me she'll never ignore an IT warning again. I believe her. Guilt is a better teacher than public shame, sometimes.
}

Agent 0x99: Marcus Webb...

{marcus_protected:
    -> marcus_protected_quiet
- else:
    -> marcus_unprotected_quiet
}

=== marcus_protected_quiet ===
#speaker:agent_0x99

Agent 0x99: You protected him. Your documentation went into the internal review.

Agent 0x99: Promoted to Director of Cybersecurity. Full budget authority. He sent a message: "Thank whoever it was who documented the warnings. Saved my career."

-> ghost_status

=== marcus_unprotected_quiet ===
#speaker:agent_0x99

Agent 0x99: He was fired quietly. No public scapegoat narrative -- but the career's gone.

Agent 0x99: Blacklisted in healthcare IT. "Failed to prevent catastrophic breach."

Agent 0x99: He did everything right. Warned them. Documented the risk. Seven times.

Agent 0x99: Last I heard, he's working help desk at a community college. $45,000 a year.

#speaker:narrator
Narrator: A pause.

#speaker:agent_0x99
Agent 0x99: That's the injustice that radicalises people. The ones who did the right thing and got ground up for it anyway.

Agent 0x99: Remember that when you think about Ghost's ideology. They're not wrong about the problem.

-> ghost_status

// ===========================================
// GHOST STATUS
// ===========================================

=== ghost_status ===
#speaker:agent_0x99

Agent 0x99: Ghost vanished. Ghost Protocol anonymity architecture performed exactly as designed. No trace. No leads.

Agent 0x99: Ransomware Incorporated is still operational.

* [We failed to stop them]
    You: Ghost escaped. We failed.
    Agent 0x99: We disrupted their operation and gathered intelligence on how they work. That's not failure.
    {paid_ransom:
        Agent 0x99: We have a transaction trail. Financial data for Mission 6.
    - else:
        Agent 0x99: We denied them funding. They go into the next operation short.
    }
    Agent 0x99: We learned their methodology. Calculated harm, ideological certainty, coordinated cells. That matters.
    -> entropy_coordination_reveal

* [What about ENTROPY's structure?]
    -> entropy_coordination_reveal

=== entropy_coordination_reveal ===
#speaker:agent_0x99

Agent 0x99: Ghost's logs confirmed what we suspected -- Zero Day Syndicate sourced the ProFTPD exploit. Crypto Anarchists handle payment processing across all cells.

{lore_cryptosecure_found:
    Agent 0x99: The CryptoSecure intelligence you recovered -- that's their financial front. We're building a picture of the network.
}

{lore_zds_invoice_found:
    Agent 0x99: The Zero Day Syndicate invoice you found -- specific evidence of the procurement chain between ENTROPY cells. That's going into Mission 3 planning.
}

Agent 0x99: Mission 3 targets Zero Day Syndicate. Mission 6 targets Crypto Anarchists.

Agent 0x99: Your work here feeds both.

-> final_reflection

// ===========================================
// FINAL REFLECTION
// ===========================================

=== final_reflection ===
#speaker:agent_0x99

Agent 0x99: Here's what I'll say, {player_name()}.

Agent 0x99: You faced a dilemma Ghost designed specifically to have no clean answer. Pay or don't pay -- both choices cost lives. Just different lives, different timeframes.

Agent 0x99: You made a call under time pressure, with incomplete information, in a building full of people depending on you.

* [I did the best I could]
    You: I made the best decision I could with what I had.
    Agent 0x99: That's all this job ever gives you. Best decision, available information, time pressure.
    Agent 0x99: ENTROPY creates impossible dilemmas on purpose. They want you paralysed, or they want you to act and feel guilty either way.
    Agent 0x99: You acted. That counts.
    -> mission_3_setup

* [I'm not sure I chose right]
    You: I'm still not sure it was the right call.
    {paid_ransom:
        Agent 0x99: 45 people are alive today. That's real. Those are real families not burying someone.
        Agent 0x99: ENTROPY has funding. That's also real. Both things are true simultaneously.
    - else:
        Agent 0x99: You denied ENTROPY $87,000. Long-term, that matters.
        Agent 0x99: Six people died in the downtime. That also matters.
    }
    Agent 0x99: I won't tell you which weighs more. I genuinely don't know. Neither does anyone who hasn't stood where you stood.
    -> mission_3_setup

* [What's next?]
    -> mission_3_setup

// ===========================================
// MISSION 3 SETUP
// ===========================================

=== mission_3_setup ===
#speaker:agent_0x99

Agent 0x99: Zero Day Syndicate. They sold Ghost the ProFTPD exploit. They scanned 214 hospitals and recommended St. Catherine's specifically.

Agent 0x99: Shut down their exploit marketplace and ENTROPY loses its technical supply chain across all cells.

Agent 0x99: Mission 3: Operation Cyber Arsenal.

* [I'm ready]
    You: Let's take them down.
    -> debrief_close

* [Who is The Architect?]
    You: Ghost mentioned The Architect. Who coordinates ENTROPY?
    -> architect_tease

=== architect_tease ===
#speaker:agent_0x99

Agent 0x99: The Architect runs all six cells. We don't know who they are yet.

Agent 0x99: But each mission reveals more. Social Fabric, Ransomware Incorporated -- patterns emerging in how the cells communicate, how they're structured.

Agent 0x99: Eventually we'll have enough to identify them. Then we end this.

-> debrief_close

// ===========================================
// DEBRIEF CLOSE
// ===========================================

=== debrief_close ===
#speaker:agent_0x99

Agent 0x99: Get some rest, {player_name()}.

Agent 0x99: You saved lives. You stopped an ENTROPY operation. You gathered intelligence on their network.

Agent 0x99: That's what you came in there to do.

Agent 0x99: We'll brief Mission 3 when you're ready.

#complete_mission
#exit_conversation

-> END
