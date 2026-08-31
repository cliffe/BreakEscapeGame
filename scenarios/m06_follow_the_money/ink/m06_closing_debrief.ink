// ================================================
// Mission 6: Follow the Money - Closing Debrief
// Mission Complete - Financial Network Mapped
// Choices: Elena recruitment, asset seizure/monitoring
// ================================================

// Variables from gameplay
VAR player_name = "Agent 0x00"
VAR final_choice = ""
VAR objectives_completed = 0
VAR lore_collected = 0
VAR found_blockchain_evidence = false
VAR found_architects_fund = false
VAR elena_recruited = false
VAR elena_arrested = false
VAR elena_ko = false
VAR satoshi_ko = false
VAR trader_ko = false
VAR analyst_ko = false
VAR architect_identity_found = false
VAR assets_seized = false
VAR monitoring_enabled = false
VAR flag1_submitted = false
VAR flag2_submitted = false
VAR flag3_submitted = false
VAR flag4_submitted = false

// ================================================
// START: DEBRIEF BEGINS
// ================================================

=== start ===
#speaker:agent_0x99

Agent HaX: {player_name}, return to HQ for debrief.

Agent HaX: The financial investigation is complete. We need to discuss what you found.

+ [On my way]
    -> debrief_location

// ================================================
// DEBRIEF LOCATION
// ================================================

=== debrief_location ===
#speaker:narrator
Narrator: SAFETYNET headquarters. The handler's office, three floors below street level, at four in the morning.

#speaker:agent_0x99

Agent HaX: {player_name}. What you accomplished at HashChain Exchange is going to reverberate through the entire ENTROPY network.

Agent HaX: We've been fighting individual cells. You just mapped their entire financial infrastructure.

+ [The Architect's Fund changes everything]
    -> architects_fund_discussion
+ [How significant is this intelligence?]
    -> strategic_impact

// ================================================
// STRATEGIC IMPACT
// ================================================

=== strategic_impact ===
Agent HaX: Extremely significant. We now know:

Agent HaX: Every ENTROPY cell is financially connected through HashChain's mixing infrastructure.

Agent HaX: The Architect coordinates funding to all cells simultaneously through a master fund.

Agent HaX: And a major coordinated attack was planned for 72 hours from when you recovered that document.

+ [Was planned? Past tense?]
    -> operation_disrupted
+ [Tell me about The Architect's Fund]
    -> architects_fund_discussion

=== operation_disrupted ===
Agent HaX: Your choices disrupted the timeline.

{assets_seized:
    Agent HaX: You seized $12.8 million in cryptocurrency. ENTROPY cells expecting funding got nothing.
    Agent HaX: Coordinated operations require coordinated funding. You broke the synchronization.
- else:
    Agent HaX: You enabled monitoring of The Architect's Fund. Intelligence is tracking every wallet receiving funds.
    Agent HaX: We know which cells are getting money, when, and how much. That's actionable intelligence.
}

-> architects_fund_discussion

// ================================================
// ARCHITECT'S FUND DISCUSSION
// ================================================

=== architects_fund_discussion ===
{found_architects_fund:
    Agent HaX: The Architect's Fund allocation document you recovered—$12.8M distributed to six cells.
    Agent HaX: Critical Mass, Social Fabric, Zero Day Syndicate, Digital Vanguard, Ghost Protocol, Supply Chain Saboteurs.
    -> fund_implications
- else:
    Agent HaX: The blockchain evidence alone is valuable, but without The Architect's Fund allocation, we're missing critical context.
    -> evidence_review
}

=== fund_implications ===
Agent HaX: 180-340 projected casualties across all coordinated operations.

Agent HaX: They calculated death tolls, {player_name}. Planned for them. Called it "The Architect's Masterpiece."

+ [How can anyone be that cold?]
    -> ideology_discussion
+ [What happens to the cells now?]
    -> cell_disruption

=== ideology_discussion ===
Agent HaX: Accelerationism. They believe the current system is doomed to collapse.

Agent HaX: The Architect thinks causing chaos speeds up the inevitable. "Teaching harsh lessons" that will save more lives in the long run.

Agent HaX: It's not coldness. It's ideology taken to its horrifying logical extreme.

-> cell_disruption

=== cell_disruption ===
{assets_seized:
    Agent HaX: With funding cut, cells are scrambling. Some operations are already cancelled.
    Agent HaX: Short-term impact is massive. But we lose long-term intelligence.
- else:
    Agent HaX: With monitoring enabled, we're tracking fund distribution in real-time.
    Agent HaX: Every cell receiving money is mapped. We're building prosecutorial cases against multiple networks.
    Agent HaX: Long-term strategic value is enormous. But cells continue operating in the short term.
}

-> elena_discussion

// ================================================
// ELENA VOLKOV DISCUSSION
// ================================================

=== elena_discussion ===
Agent HaX: Now let's talk about Dr. Elena Volkov.

{elena_ko:
    -> elena_ko_path
}
{elena_recruited:
    -> elena_recruited_path
}
{elena_arrested:
    -> elena_arrested_path
}
{not elena_ko && not elena_recruited && not elena_arrested:
    -> elena_neutral_path
}

=== elena_ko_path ===
Agent HaX: Volkov went down on the trading floor. The medics say she'll be fine in a day and charged within a week.

Agent HaX: I won't pretend that isn't a loss. She had the whole mixer in her head and she was already halfway to walking away from it.

+ [She was complicit. She built the thing.]
    Agent HaX: She was. And she knew it -- there's a note in her own research file where she asks herself what she's become.
    Agent HaX: Doesn't make it a good trade. We had one cryptographer inside ENTROPY's money and now we have a defendant.
    -> password_cracking_discussion

+ [It wasn't a decision. It happened fast.]
    Agent HaX: They usually do. I'm not writing you up for it.
    Agent HaX: But log it honestly. The report should say we lost an asset, not that we neutralised a threat.
    -> password_cracking_discussion

=== elena_recruited_path ===
Agent HaX: You recruited her. That was... unexpected. And brilliant.

Agent HaX: Elena is cooperating fully. Her knowledge of ENTROPY's cryptographic infrastructure is extraordinary.

+ [Was it the right call?]
    -> recruitment_validation
+ [She was morally conflicted. I gave her an out.]
    -> moral_reasoning

=== recruitment_validation ===
Agent HaX: Absolutely. A cryptographer of her caliber is worth more as an asset than a prisoner.

Agent HaX: She's already provided intelligence on Crypto Anarchist cells in three countries.

Agent HaX: And {player_name}—she's teaching our analysts. Her expertise is leveling up our entire cryptography division.

-> recruitment_impact

=== moral_reasoning ===
Agent HaX: You read her correctly. She built that infrastructure for "financial freedom."

Agent HaX: When she saw the casualty projections, the coordinated attacks, The Architect's plans... it broke something.

Agent HaX: She's not a terrorist. She's a brilliant person who got swept up in ideology and didn't look at the consequences.

-> recruitment_impact

=== recruitment_impact ===
Agent HaX: The intelligence she's providing is dismantling Crypto Anarchist cells globally.

Agent HaX: And she's documenting her work—academic papers on cryptocurrency forensics, training materials for law enforcement.

Agent HaX: You didn't just recruit an asset. You flipped an ideology.

+ [What about Satoshi Nakamoto II?]
    -> satoshi_aftermath
+ [I'm glad it worked out]
    -> password_cracking_discussion

=== elena_arrested_path ===
Agent HaX: You arrested Elena Volkov. Clean, professional, by the book.

Agent HaX: She's facing 20-35 years for money laundering, conspiracy, and facilitating terrorist financing.

+ [She knew what she was enabling]
    -> arrest_justification
+ [Was recruitment possible?]
    -> missed_opportunity

=== arrest_justification ===
Agent HaX: She did. $12.8 million funneled through her infrastructure to fund attacks with 180-340 projected casualties.

Agent HaX: Moral conflict doesn't erase culpability. She built the systems. She knew they were being abused.

-> arrest_impact

=== missed_opportunity ===
Agent HaX: Possibly. Our psychological profile suggested she was conflicted about ENTROPY's use of her work.

Agent HaX: But recruitment is high-risk. If it fails, you've compromised the operation.

Agent HaX: You made the safe call. Can't fault that.

-> arrest_impact

=== arrest_impact ===
Agent HaX: With Elena arrested, Crypto Anarchist cells are losing technical expertise.

Agent HaX: They'll replace her eventually, but it'll take time. That's operational disruption we can exploit.

+ [What about Satoshi Nakamoto II?]
    -> satoshi_aftermath
+ [What happens next?]
    -> password_cracking_discussion

=== elena_neutral_path ===
Agent HaX: Elena wasn't arrested or recruited. Interesting.

Agent HaX: She's under surveillance now. We're monitoring her communications, tracking her movements.

Agent HaX: Long-term intelligence gathering. Sometimes that's the right play.

-> password_cracking_discussion

// ================================================
// SATOSHI AFTERMATH
// ================================================

=== satoshi_aftermath ===
{satoshi_ko:
    Agent HaX: Your man was still unconscious on his own office floor when the extraction team walked in. They took a photograph. I've been asked not to circulate it.

    Agent HaX: He came round in the van, and started talking about financial freedom before he'd finished being read his rights.
- else:
    Agent HaX: "Satoshi Nakamoto II" was arrested trying to flee the country.

    Agent HaX: True believer to the end. Ranted about "financial freedom" during booking.
}

Agent HaX: HashChain Exchange is seized. Their mixing infrastructure is shut down.

Agent HaX: ENTROPY cells are scrambling to find alternative money laundering channels. That's a major operational disruption.

-> password_cracking_discussion

// ================================================
// PASSWORD CRACKING & VM WORK
// ================================================

=== password_cracking_discussion ===
Agent HaX: Let's talk about the technical work. Password cracking against their backend servers.

{flag1_submitted && flag2_submitted && flag3_submitted && flag4_submitted:
    -> all_flags_complete
}
{flag1_submitted:
    -> partial_flags
}
{not flag1_submitted:
    -> minimal_flags
}

=== all_flags_complete ===
Agent HaX: All four flags submitted. Complete network penetration.

Agent HaX: You cracked passwords, exploited credential reuse, accessed the financial database, and mapped the entire infrastructure.

Agent HaX: Textbook password cracking methodology. That's the kind of technical work that gets operations promoted.

-> evidence_review

=== partial_flags ===
Agent HaX: You submitted some flags but not all. Partial server access.

Agent HaX: Our forensics team is recovering the rest, but you got the critical systems.

Agent HaX: Next time, push for complete access. Every flag is intelligence.

-> evidence_review

=== minimal_flags ===
Agent HaX: No VM flags submitted. The financial intelligence came from physical documents rather than server access.

Agent HaX: That works, but server access would have given us more—wallet private keys, complete transaction histories, encrypted communications.

Agent HaX: Consider prioritizing technical exploitation in future missions.

-> evidence_review

// ================================================
// EVIDENCE REVIEW
// ================================================

=== evidence_review ===
{found_blockchain_evidence && found_architects_fund:
    -> evidence_complete
}
{found_blockchain_evidence && not found_architects_fund:
    -> evidence_partial_blockchain
}
{not found_blockchain_evidence && found_architects_fund:
    -> evidence_partial_fund
}
{not found_blockchain_evidence && not found_architects_fund:
    -> evidence_minimal
}

=== evidence_complete ===
Agent HaX: You recovered both critical documents: the ENTROPY transaction network analysis and The Architect's Fund allocation.

Agent HaX: Complete financial mapping. Every cell, every wallet, every transaction, and the coordinated attack plan.

Agent HaX: This is prosecutor-grade evidence. Multiple ENTROPY cells will face financial crime charges.

-> lore_discussion

=== evidence_partial_blockchain ===
Agent HaX: You found the blockchain transaction analysis—all ENTROPY cells connected financially.

Agent HaX: Without The Architect's Fund allocation, we're missing the coordinated attack details, but the financial network map is solid intelligence.

-> lore_discussion

=== evidence_partial_fund ===
Agent HaX: You found The Architect's Fund allocation—the coordinated attack funding plan.

Agent HaX: Without the blockchain transaction analysis, we're missing some cell connections, but the allocation document is smoking-gun evidence.

-> lore_discussion

=== evidence_minimal ===
Agent HaX: Limited document recovery. Forensics is pulling data from seized servers.

Agent HaX: The operation succeeded, but prioritize evidence collection in future missions. Physical documents are harder to dispute in court.

-> lore_discussion

// ================================================
// LORE FRAGMENTS
// ================================================

=== lore_discussion ===
{lore_collected >= 3:
    -> significant_lore
}
{lore_collected >= 1:
    -> some_lore
}
{lore_collected == 0:
    -> minimal_lore
}

=== significant_lore ===
Agent HaX: You collected significant LORE fragments. Crypto Anarchist ideology, their role in ENTROPY, connections to The Architect.

Agent HaX: And that file you found in Satoshi's safe—The Architect's identity intelligence.

Agent HaX: Dr. Adrian Tesseract. Former SAFETYNET chief strategist. Defected seven years ago.

+ [The Architect is former SAFETYNET?]
    -> tesseract_revelation
+ [That's horrifying]
    -> tesseract_revelation

=== tesseract_revelation ===
{not architect_identity_found:
    Agent HaX: We never got into that safe, so this is analysis rather than evidence. Take it as a lead, not a fact.
}
Agent HaX: 87% probability according to the file. Not confirmed, but... it fits.

Agent HaX: Tesseract was brilliant. Mentored half the agents currently in the field. Strategic genius.

Agent HaX: Then he disappeared after a philosophical disagreement. Believed the cybersecurity arms race would accelerate societal collapse.

+ [He's trying to cause what he predicted]
    -> accelerationism_discussion
+ [Do you know him?]
    -> personal_connection

=== accelerationism_discussion ===
Agent HaX: Accelerationism. If collapse is inevitable, speed it up. Make it happen on controlled terms.

Agent HaX: Tesseract thinks ENTROPY's attacks are "teaching harsh lessons" that will ultimately save more lives.

Agent HaX: It's monstrous. But it's not random violence. It's ideology taken to its logical, horrifying extreme.

-> mission_conclusion

=== personal_connection ===
Agent HaX: ...I was one of his students.

Agent HaX: Best strategic mind I've ever encountered. Taught me half of what I know about intelligence work.

Agent HaX: If it's really him... {player_name}, this got personal.

-> mission_conclusion

=== some_lore ===
Agent HaX: You collected some LORE fragments. Good situational awareness.

Agent HaX: Understanding ENTROPY's ideology helps predict their behavior. Keep gathering context in future missions.

-> mission_conclusion

=== minimal_lore ===
Agent HaX: Limited LORE collection. You focused on operational objectives.

Agent HaX: That works, but context helps predict enemy behavior. Consider exploring more in future missions.

-> mission_conclusion

// ================================================
// MISSION CONCLUSION
// ================================================

=== mission_conclusion ===
Agent HaX: {player_name}, you just changed the entire campaign against ENTROPY.

{assets_seized:
    Agent HaX: $12.8 million seized. Coordinated operations disrupted. Immediate strategic impact.
- else:
    Agent HaX: Fund monitoring enabled. Complete financial network mapped. Long-term strategic intelligence.
}

{elena_recruited:
    Agent HaX: Elena Volkov recruited. Cryptographic expertise added to SAFETYNET capabilities.
}

{found_blockchain_evidence && found_architects_fund:
    Agent HaX: Complete financial evidence recovered. Multiple prosecutorial cases enabled.
}

Agent HaX: This is the kind of mission that gets studied in training programs.

-> final_assessment

// ================================================
// FINAL ASSESSMENT
// ================================================

=== final_assessment ===
Agent HaX: We're moving into the endgame now.

Agent HaX: We know The Architect exists. We know they're coordinating all ENTROPY cells. We have a probable identity.

Agent HaX: And thanks to your work, we understand their financial infrastructure.

+ [What's next?]
    -> next_mission_hint
+ [This is just the beginning]
    -> next_mission_hint

=== next_mission_hint ===
Agent HaX: More ENTROPY cells. More pieces of The Architect's plan.

Agent HaX: Every mission gets us closer to the truth. And closer to stopping whatever "Masterpiece" they're planning.

Agent HaX: Get some rest, {player_name}. You've earned it.

Agent HaX: SAFETYNET will call when we need you again.

#exit_conversation
-> DONE
