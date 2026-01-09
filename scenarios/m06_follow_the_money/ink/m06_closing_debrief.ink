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

Agent 0x99: {player_name}, return to HQ for debrief.

Agent 0x99: The financial investigation is complete. We need to discuss what you found.

+ [On my way]
    -> debrief_location

// ================================================
// DEBRIEF LOCATION
// ================================================

=== debrief_location ===
[SAFETYNET HQ - Agent 0x99's Office]

#speaker:agent_0x99

Agent 0x99: {player_name}. What you accomplished at HashChain Exchange is going to reverberate through the entire ENTROPY network.

Agent 0x99: We've been fighting individual cells. You just mapped their entire financial infrastructure.

+ [The Architect's Fund changes everything]
    -> architects_fund_discussion
+ [How significant is this intelligence?]
    -> strategic_impact

// ================================================
// STRATEGIC IMPACT
// ================================================

=== strategic_impact ===
Agent 0x99: Extremely significant. We now know:

Agent 0x99: Every ENTROPY cell is financially connected through HashChain's mixing infrastructure.

Agent 0x99: The Architect coordinates funding to all cells simultaneously through a master fund.

Agent 0x99: And a major coordinated attack was planned for 72 hours from when you recovered that document.

+ [Was planned? Past tense?]
    -> operation_disrupted
+ [Tell me about The Architect's Fund]
    -> architects_fund_discussion

=== operation_disrupted ===
Agent 0x99: Your choices disrupted the timeline.

{assets_seized:
    Agent 0x99: You seized $12.8 million in cryptocurrency. ENTROPY cells expecting funding got nothing.
    Agent 0x99: Coordinated operations require coordinated funding. You broke the synchronization.
- else:
    Agent 0x99: You enabled monitoring of The Architect's Fund. Intelligence is tracking every wallet receiving funds.
    Agent 0x99: We know which cells are getting money, when, and how much. That's actionable intelligence.
}

-> architects_fund_discussion

// ================================================
// ARCHITECT'S FUND DISCUSSION
// ================================================

=== architects_fund_discussion ===
{found_architects_fund:
    Agent 0x99: The Architect's Fund allocation document you recovered—$12.8M distributed to six cells.
    Agent 0x99: Critical Mass, Social Fabric, Zero Day Syndicate, Digital Vanguard, Ghost Protocol, Supply Chain Saboteurs.
    -> fund_implications
- else:
    Agent 0x99: The blockchain evidence alone is valuable, but without The Architect's Fund allocation, we're missing critical context.
    -> evidence_review
}

=== fund_implications ===
Agent 0x99: 180-340 projected casualties across all coordinated operations.

Agent 0x99: They calculated death tolls, {player_name}. Planned for them. Called it "The Architect's Masterpiece."

+ [How can anyone be that cold?]
    -> ideology_discussion
+ [What happens to the cells now?]
    -> cell_disruption

=== ideology_discussion ===
Agent 0x99: Accelerationism. They believe the current system is doomed to collapse.

Agent 0x99: The Architect thinks causing chaos speeds up the inevitable. "Teaching harsh lessons" that will save more lives in the long run.

Agent 0x99: It's not coldness. It's ideology taken to its horrifying logical extreme.

-> cell_disruption

=== cell_disruption ===
{assets_seized:
    Agent 0x99: With funding cut, cells are scrambling. Some operations are already cancelled.
    Agent 0x99: Short-term impact is massive. But we lose long-term intelligence.
- else:
    Agent 0x99: With monitoring enabled, we're tracking fund distribution in real-time.
    Agent 0x99: Every cell receiving money is mapped. We're building prosecutorial cases against multiple networks.
    Agent 0x99: Long-term strategic value is enormous. But cells continue operating in the short term.
}

-> elena_discussion

// ================================================
// ELENA VOLKOV DISCUSSION
// ================================================

=== elena_discussion ===
Agent 0x99: Now let's talk about Dr. Elena Volkov.

{elena_recruited:
    -> elena_recruited_path
}
{elena_arrested:
    -> elena_arrested_path
}
{not elena_recruited && not elena_arrested:
    -> elena_neutral_path
}

=== elena_recruited_path ===
Agent 0x99: You recruited her. That was... unexpected. And brilliant.

Agent 0x99: Elena is cooperating fully. Her knowledge of ENTROPY's cryptographic infrastructure is extraordinary.

+ [Was it the right call?]
    -> recruitment_validation
+ [She was morally conflicted. I gave her an out.]
    -> moral_reasoning

=== recruitment_validation ===
Agent 0x99: Absolutely. A cryptographer of her caliber is worth more as an asset than a prisoner.

Agent 0x99: She's already provided intelligence on Crypto Anarchist cells in three countries.

Agent 0x99: And {player_name}—she's teaching our analysts. Her expertise is leveling up our entire cryptography division.

-> recruitment_impact

=== moral_reasoning ===
Agent 0x99: You read her correctly. She built that infrastructure for "financial freedom."

Agent 0x99: When she saw the casualty projections, the coordinated attacks, The Architect's plans... it broke something.

Agent 0x99: She's not a terrorist. She's a brilliant person who got swept up in ideology and didn't look at the consequences.

-> recruitment_impact

=== recruitment_impact ===
Agent 0x99: The intelligence she's providing is dismantling Crypto Anarchist cells globally.

Agent 0x99: And she's documenting her work—academic papers on cryptocurrency forensics, training materials for law enforcement.

Agent 0x99: You didn't just recruit an asset. You flipped an ideology.

+ [What about Satoshi Nakamoto II?]
    -> satoshi_aftermath
+ [I'm glad it worked out]
    -> password_cracking_discussion

=== elena_arrested_path ===
Agent 0x99: You arrested Elena Volkov. Clean, professional, by the book.

Agent 0x99: She's facing 20-35 years for money laundering, conspiracy, and facilitating terrorist financing.

+ [She knew what she was enabling]
    -> arrest_justification
+ [Was recruitment possible?]
    -> missed_opportunity

=== arrest_justification ===
Agent 0x99: She did. $12.8 million funneled through her infrastructure to fund attacks with 180-340 projected casualties.

Agent 0x99: Moral conflict doesn't erase culpability. She built the systems. She knew they were being abused.

-> arrest_impact

=== missed_opportunity ===
Agent 0x99: Possibly. Our psychological profile suggested she was conflicted about ENTROPY's use of her work.

Agent 0x99: But recruitment is high-risk. If it fails, you've compromised the operation.

Agent 0x99: You made the safe call. Can't fault that.

-> arrest_impact

=== arrest_impact ===
Agent 0x99: With Elena arrested, Crypto Anarchist cells are losing technical expertise.

Agent 0x99: They'll replace her eventually, but it'll take time. That's operational disruption we can exploit.

+ [What about Satoshi Nakamoto II?]
    -> satoshi_aftermath
+ [What happens next?]
    -> password_cracking_discussion

=== elena_neutral_path ===
Agent 0x99: Elena wasn't arrested or recruited. Interesting.

Agent 0x99: She's under surveillance now. We're monitoring her communications, tracking her movements.

Agent 0x99: Long-term intelligence gathering. Sometimes that's the right play.

-> password_cracking_discussion

// ================================================
// SATOSHI AFTERMATH
// ================================================

=== satoshi_aftermath ===
Agent 0x99: "Satoshi Nakamoto II" was arrested trying to flee the country.

Agent 0x99: True believer to the end. Ranted about "financial freedom" during booking.

Agent 0x99: HashChain Exchange is seized. Their mixing infrastructure is shut down.

Agent 0x99: ENTROPY cells are scrambling to find alternative money laundering channels. That's a major operational disruption.

-> password_cracking_discussion

// ================================================
// PASSWORD CRACKING & VM WORK
// ================================================

=== password_cracking_discussion ===
Agent 0x99: Let's talk about the technical work. Password cracking against their backend servers.

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
Agent 0x99: All four flags submitted. Complete network penetration.

Agent 0x99: You cracked passwords, exploited credential reuse, accessed the financial database, and mapped the entire infrastructure.

Agent 0x99: Textbook password cracking methodology. That's the kind of technical work that gets operations promoted.

-> evidence_review

=== partial_flags ===
Agent 0x99: You submitted some flags but not all. Partial server access.

Agent 0x99: Our forensics team is recovering the rest, but you got the critical systems.

Agent 0x99: Next time, push for complete access. Every flag is intelligence.

-> evidence_review

=== minimal_flags ===
Agent 0x99: No VM flags submitted. The financial intelligence came from physical documents rather than server access.

Agent 0x99: That works, but server access would have given us more—wallet private keys, complete transaction histories, encrypted communications.

Agent 0x99: Consider prioritizing technical exploitation in future missions.

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
Agent 0x99: You recovered both critical documents: the ENTROPY transaction network analysis and The Architect's Fund allocation.

Agent 0x99: Complete financial mapping. Every cell, every wallet, every transaction, and the coordinated attack plan.

Agent 0x99: This is prosecutor-grade evidence. Multiple ENTROPY cells will face financial crime charges.

-> lore_discussion

=== evidence_partial_blockchain ===
Agent 0x99: You found the blockchain transaction analysis—all ENTROPY cells connected financially.

Agent 0x99: Without The Architect's Fund allocation, we're missing the coordinated attack details, but the financial network map is solid intelligence.

-> lore_discussion

=== evidence_partial_fund ===
Agent 0x99: You found The Architect's Fund allocation—the coordinated attack funding plan.

Agent 0x99: Without the blockchain transaction analysis, we're missing some cell connections, but the allocation document is smoking-gun evidence.

-> lore_discussion

=== evidence_minimal ===
Agent 0x99: Limited document recovery. Forensics is pulling data from seized servers.

Agent 0x99: The operation succeeded, but prioritize evidence collection in future missions. Physical documents are harder to dispute in court.

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
Agent 0x99: You collected significant LORE fragments. Crypto Anarchist ideology, their role in ENTROPY, connections to The Architect.

Agent 0x99: And that file you found in Satoshi's safe—The Architect's identity intelligence.

Agent 0x99: Dr. Adrian Tesseract. Former SAFETYNET chief strategist. Defected seven years ago.

+ [The Architect is former SAFETYNET?]
    -> tesseract_revelation
+ [That's horrifying]
    -> tesseract_revelation

=== tesseract_revelation ===
Agent 0x99: 87% probability according to the file. Not confirmed, but... it fits.

Agent 0x99: Tesseract was brilliant. Mentored half the agents currently in the field. Strategic genius.

Agent 0x99: Then he disappeared after a philosophical disagreement. Believed the cybersecurity arms race would accelerate societal collapse.

+ [He's trying to cause what he predicted]
    -> accelerationism_discussion
+ [Do you know him?]
    -> personal_connection

=== accelerationism_discussion ===
Agent 0x99: Accelerationism. If collapse is inevitable, speed it up. Make it happen on controlled terms.

Agent 0x99: Tesseract thinks ENTROPY's attacks are "teaching harsh lessons" that will ultimately save more lives.

Agent 0x99: It's monstrous. But it's not random violence. It's ideology taken to its logical, horrifying extreme.

-> mission_conclusion

=== personal_connection ===
Agent 0x99: ...I was one of his students.

Agent 0x99: Best strategic mind I've ever encountered. Taught me half of what I know about intelligence work.

Agent 0x99: If it's really him... {player_name}, this got personal.

-> mission_conclusion

=== some_lore ===
Agent 0x99: You collected some LORE fragments. Good situational awareness.

Agent 0x99: Understanding ENTROPY's ideology helps predict their behavior. Keep gathering context in future missions.

-> mission_conclusion

=== minimal_lore ===
Agent 0x99: Limited LORE collection. You focused on operational objectives.

Agent 0x99: That works, but context helps predict enemy behavior. Consider exploring more in future missions.

-> mission_conclusion

// ================================================
// MISSION CONCLUSION
// ================================================

=== mission_conclusion ===
Agent 0x99: {player_name}, you just changed the entire campaign against ENTROPY.

{assets_seized:
    Agent 0x99: $12.8 million seized. Coordinated operations disrupted. Immediate strategic impact.
- else:
    Agent 0x99: Fund monitoring enabled. Complete financial network mapped. Long-term strategic intelligence.
}

{elena_recruited:
    Agent 0x99: Elena Volkov recruited. Cryptographic expertise added to SAFETYNET capabilities.
}

{found_blockchain_evidence && found_architects_fund:
    Agent 0x99: Complete financial evidence recovered. Multiple prosecutorial cases enabled.
}

Agent 0x99: This is the kind of mission that gets studied in training programs.

-> final_assessment

// ================================================
// FINAL ASSESSMENT
// ================================================

=== final_assessment ===
Agent 0x99: We're moving into the endgame now.

Agent 0x99: We know The Architect exists. We know they're coordinating all ENTROPY cells. We have a probable identity.

Agent 0x99: And thanks to your work, we understand their financial infrastructure.

+ [What's next?]
    -> next_mission_hint
+ [This is just the beginning]
    -> next_mission_hint

=== next_mission_hint ===
Agent 0x99: More ENTROPY cells. More pieces of The Architect's plan.

Agent 0x99: Every mission gets us closer to the truth. And closer to stopping whatever "Masterpiece" they're planning.

Agent 0x99: Get some rest, {player_name}. You've earned it.

Agent 0x99: SAFETYNET will call when we need you again.

#exit_conversation
-> END
