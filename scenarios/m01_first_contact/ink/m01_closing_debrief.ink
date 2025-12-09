// ================================================
// Mission 1: First Contact - Closing Debrief
// Act 3: Mission Complete
// UPDATED: Feedback based on ACTUAL player choices,
//          not pre-selected "approach"
// ================================================

// Variables from gameplay - these should be set by the game
VAR player_name = "Agent 0x00"
VAR final_choice = ""             // From Derek confrontation (arrest/recruit/expose)
VAR objectives_completed = 0      // Percentage of objectives done
VAR lore_collected = 0            // Number of LORE fragments found
VAR found_casualty_projections = false  // Found the critical evidence
VAR found_target_database = false       // Found the targeting demographics
VAR talked_to_maya = false              // Interacted with Maya Chen
VAR talked_to_kevin = false             // Got help from Kevin
VAR maya_identity_protected = true      // Did player protect Maya's identity

// Moral choice: Kevin's frame-up
VAR kevin_choice = ""             // warn, evidence, ignore
VAR kevin_protected = false       // Did player help Kevin?

// ================================================
// START: DEBRIEF BEGINS
// ================================================

=== start ===
#speaker:agent_0x99

Agent 0x99: {player_name}, return to HQ for debrief.

Agent 0x99: Operation Shatter is neutralized. Let's review what happened.

+ [On my way]
    -> debrief_location

// ================================================
// DEBRIEF LOCATION
// ================================================

=== debrief_location ===
[SAFETYNET HQ - Agent 0x99's Office]

#speaker:agent_0x99

Agent 0x99: {player_name}. First, I need you to understand what you accomplished today.

Agent 0x99: Those casualty projections—42 to 85 people. Diabetics. Elderly. People with anxiety disorders.

Agent 0x99: They're going to live. Because of you.

+ [That's what matters]
    -> evidence_review
+ [It was close. Too close.]
    -> close_call

// ================================================
// CLOSE CALL ACKNOWLEDGMENT
// ================================================

=== close_call ===
Agent 0x99: 72 hours. That's how close we cut it.

Agent 0x99: If our AI hadn't flagged those data collection patterns, if you hadn't found the documentation...

Agent 0x99: But you did. And those people will never know how close they came.

-> evidence_review

// ================================================
// EVIDENCE REVIEW - Based on what player actually found
// ================================================

=== evidence_review ===
Agent 0x99: Let's review what you recovered.

{found_casualty_projections && found_target_database:
    -> evidence_complete
}
{found_casualty_projections && not found_target_database:
    -> evidence_partial_projections
}
{not found_casualty_projections && found_target_database:
    -> evidence_partial_database
}
{not found_casualty_projections && not found_target_database:
    -> evidence_minimal
}

=== evidence_complete ===
Agent 0x99: You found everything. The casualty projections. The target demographics database. The complete Operation Shatter documentation.

Agent 0x99: This is exactly what prosecutors need. Derek's signature on the death calculations. The Architect's approval. The targeting methodology.

Agent 0x99: Thorough work. You didn't rush past the evidence.

+ [I wanted to make sure we had enough to convict]
    Agent 0x99: You do. There's no walking away from this for Derek.
    -> npc_interactions
+ [The more I found, the worse it got]
    Agent 0x99: Yeah. Reading those casualty projections... that stays with you.
    -> npc_interactions

=== evidence_partial_projections ===
Agent 0x99: You found the casualty projections—the smoking gun. Derek's death calculations, The Architect's approval.

Agent 0x99: We're missing the full target demographics database, but that's recoverable from their servers now that we have access.

Agent 0x99: The critical evidence is secured. That's what matters for prosecution.

-> npc_interactions

=== evidence_partial_database ===
Agent 0x99: You found the target demographics database—2.3 million people profiled for vulnerability.

Agent 0x99: We're still missing the casualty projections document, but the database alone proves intent. They were targeting vulnerable populations deliberately.

Agent 0x99: Our forensics team is recovering the rest from their systems.

-> npc_interactions

=== evidence_minimal ===
Agent 0x99: The core Operation Shatter documentation is still being recovered by our forensics team.

Agent 0x99: The operation is stopped, but we're relying on digital forensics for the prosecution evidence.

Agent 0x99: Next time, prioritize document recovery. Physical evidence is harder to deny in court.

-> npc_interactions

// ================================================
// NPC INTERACTIONS - Based on who player talked to
// ================================================

=== npc_interactions ===
{talked_to_kevin && talked_to_maya:
    -> worked_with_both
}
{talked_to_kevin && not talked_to_maya:
    -> worked_with_kevin
}
{not talked_to_kevin && talked_to_maya:
    -> worked_with_maya
}
{not talked_to_kevin && not talked_to_maya:
    -> worked_alone
}

=== worked_with_both ===
Agent 0x99: I noticed you worked with both Kevin and Maya.

Agent 0x99: Kevin gave you legitimate access—that's the IT contractor cover working as intended.

{maya_identity_protected:
    Agent 0x99: And Maya... you protected her identity. She's safe. She can continue her journalism without looking over her shoulder.
    Agent 0x99: That matters. She took a risk contacting us.
- else:
    Agent 0x99: Maya's identity was compromised during the operation. We're relocating her for safety.
    Agent 0x99: She'll be okay, but her career at Viral Dynamics is over. Collateral damage.
}

-> kevin_frame_discussion

=== worked_with_kevin ===
Agent 0x99: Kevin's cooperation was valuable. The IT contractor cover worked perfectly.

Agent 0x99: You got legitimate access without raising suspicion. That's clean infiltration.

-> kevin_frame_discussion

=== worked_with_maya ===
Agent 0x99: Maya was taking a risk talking to you. I hope you appreciated that.

{maya_identity_protected:
    Agent 0x99: Her identity stayed protected. She can continue investigating on her own terms now.
- else:
    Agent 0x99: Unfortunately, her identity was compromised. We're handling her protection.
}

-> kevin_frame_discussion

=== worked_alone ===
Agent 0x99: You handled this mostly solo. Independent approach.

Agent 0x99: Sometimes that's the right call. Fewer people involved means fewer potential leaks.

-> kevin_frame_discussion

// ================================================
// KEVIN FRAME-UP - Moral choice consequences
// ================================================

=== kevin_frame_discussion ===
{kevin_choice == "":
    // Player didn't encounter the frame-up files
    -> derek_discussion
}
{kevin_choice == "warn":
    -> kevin_warned
}
{kevin_choice == "evidence":
    -> kevin_evidence
}
{kevin_choice == "ignore":
    -> kevin_ignored
}

=== kevin_warned ===
Agent 0x99: I saw in your report that you warned Kevin about the frame-up.

Agent 0x99: That was risky. If he'd panicked, if Derek had noticed...

+ [He deserved to know]
    Agent 0x99: He did. And now he's lawyered up, documented everything. When the prosecutors came for him, he was ready.
    Agent 0x99: His career is intact. His life isn't ruined. Because you took five minutes to be decent.
    -> kevin_outcome_positive
+ [I couldn't just let Derek destroy him]
    Agent 0x99: You're right. Kevin didn't ask to be part of this. He helped you because he's a good person.
    Agent 0x99: Derek would have fed him to the wolves. You didn't let that happen.
    -> kevin_outcome_positive

=== kevin_evidence ===
Agent 0x99: The contingency files you left for investigators—that was smart.

Agent 0x99: When the follow-up team found them, they immediately flagged Kevin as a victim, not a suspect.

Agent 0x99: He never even knew he was in danger. Woke up, went to work, found out his company was a front for terrorists, and went home to his family.

Agent 0x99: Clean. Professional. And kind.

-> kevin_outcome_positive

=== kevin_outcome_positive ===
Agent 0x99: You know what Derek would have said? "Kevin is acceptable collateral damage."

Agent 0x99: You disagreed. That matters.

Agent 0x99: Not every agent would have taken the time. Not every agent would have cared.

-> derek_discussion

=== kevin_ignored ===
Agent 0x99: Kevin Park was arrested this morning.

+ [What?]
    -> kevin_arrest_details
+ [The frame-up worked?]
    -> kevin_arrest_details

=== kevin_arrest_details ===
Agent 0x99: Derek's contingency plan activated automatically when Viral Dynamics' systems were seized. Fake logs, forged emails.

Agent 0x99: Kevin spent six hours in interrogation before our team figured out he was being framed.

Agent 0x99: He's cleared now. But he's traumatized. His neighbors saw him taken away in handcuffs. His kids watched.

+ [I... I saw the files. I knew.]
    Agent 0x99: I know. It's in Derek's computer logs.
    Agent 0x99: You made a choice. Focus on the mission. Let Kevin be collateral damage.
    Agent 0x99: Sometimes that's the right call. Sometimes the mission really does come first.
    Agent 0x99: But Kevin's going to need therapy. His kids are going to need therapy.
    Agent 0x99: Just... remember that. Next time you're weighing priorities.
    -> derek_discussion
+ [The mission had to come first]
    Agent 0x99: Did it? You still stopped Operation Shatter. You still caught Derek.
    Agent 0x99: Would five minutes to warn Kevin have changed that?
    Agent 0x99: I'm not judging. Field decisions are hard. But consequences are real.
    Agent 0x99: Kevin's kids watched him get arrested. That happened because of a choice you made.
    Agent 0x99: Live with it. Learn from it.
    -> derek_discussion

// ================================================
// DEREK DISCUSSION - Based on how player handled confrontation
// ================================================

=== derek_discussion ===
Agent 0x99: Now, about Derek Lawson...

{final_choice == "fight":
    -> consequence_fight
}
{final_choice == "arrest":
    -> consequence_arrest
}
{final_choice == "recruit":
    -> consequence_recruit
}
{final_choice == "expose":
    -> consequence_expose
}
// Default if variable not set properly
-> consequence_arrest

// ================================================
// CONSEQUENCE: FIGHT (Hostile Engagement)
// ================================================

=== consequence_fight ===
Agent 0x99: You took Derek down physically. Aggressive approach.

Agent 0x99: Walk me through your tactical reasoning.

+ [He was planning mass murder. I ended the threat.]
    Agent 0x99: Direct and effective. Derek's in custody, Operation Shatter is stopped.
    Agent 0x99: His lawyers will make noise about excessive force, but you had full field authorization.
    -> fight_outcome
+ [He calculated those deaths so coldly. I reacted.]
    Agent 0x99: I saw the footage. The way he talked about those casualties like statistics...
    Agent 0x99: Understandable reaction. Derek's narrative now is that SAFETYNET attacked him, but that's lawyer talk.
    -> fight_outcome
+ [He reached for something. Threat assessment.]
    Agent 0x99: Field decisions happen fast. I saw the footage—he did move toward his desk.
    Agent 0x99: You neutralized a potential threat. Textbook response.
    -> fight_outcome_justified

=== fight_outcome ===
Agent 0x99: Derek's in custody. Mission accomplished.

Agent 0x99: His defense team is spinning the excessive force angle, but you have field immunity as a SAFETYNET operative.

Agent 0x99: The confrontation will be part of his trial narrative. His lawyers will use it. Worth noting for future ops.

{found_casualty_projections:
    Agent 0x99: The hard evidence you recovered—his casualty projections—that's what convicts him. The confrontation is just noise.
- else:
    Agent 0x99: Forensics is building the evidence case. The physical confrontation adds complexity to prosecution, but he's not walking free.
}

Agent 0x99: Different approach than a quiet arrest, but the result's the same. He's neutralized.

+ [Mission complete. That's what matters.]
    Agent 0x99: Agreed. Operation Shatter stopped, lives saved.
    -> phase_3_discussion
+ [He planned to kill 85 people. No sympathy.]
    Agent 0x99: None deserved. Derek's done. ENTROPY lost this round.
    -> phase_3_discussion

=== fight_outcome_justified ===
Agent 0x99: Derek's in custody. You neutralized a potentially armed hostile.

Agent 0x99: Turned out he was reaching for a phone, not a weapon. But split-second decisions don't have hindsight.

Agent 0x99: Response was controlled. Minimal injury. Threat neutralized.

{found_casualty_projections:
    Agent 0x99: The evidence backs up the arrest—his casualty projections with his signature.
- else:
    Agent 0x99: Forensics is pulling evidence from his systems. Prosecution case is solid.
}

Agent 0x99: His lawyers will file complaints, but review board will clear it. Standard hostile engagement protocol.

Agent 0x99: Clean tactical response to a perceived threat.

+ [Threat assessment was correct.]
    Agent 0x99: Agreed. You made the right call in the moment.
    -> phase_3_discussion
+ [I'd make the same call again.]
    Agent 0x99: That's what field agents do. Assess, act, neutralize.
    -> phase_3_discussion

// ================================================
// CONSEQUENCE: ARREST
// ================================================

=== consequence_arrest ===
Agent 0x99: You chose arrest. Legal prosecution through proper channels.

Agent 0x99: He's not cooperating—true believers rarely do. But we have the evidence. His signature on the casualty projections.

Agent 0x99: He'll spend decades in prison explaining why 85 dead people would have been "educational."

+ [Will the charges stick?]
    Agent 0x99: Conspiracy to commit mass murder. Terrorism. Computer crimes.
    {found_casualty_projections:
        Agent 0x99: With the casualty projections you recovered? He's done.
    - else:
        Agent 0x99: We're building the evidence case. It'll take longer, but he's not walking free.
    }
    -> phase_3_discussion
+ [He seemed so certain he was right]
    Agent 0x99: That's what makes true believers dangerous. They've rationalized everything.
    Agent 0x99: Derek doesn't think he's a murderer. He thinks he's an educator.
    Agent 0x99: The jury will disagree.
    -> phase_3_discussion

// ================================================
// CONSEQUENCE: RECRUIT (Derek refuses)
// ================================================

=== consequence_recruit ===
Agent 0x99: You offered him a chance to cooperate. Turn informant.

Agent 0x99: I heard his answer. "I will never betray ENTROPY."

Agent 0x99: True believers don't turn, {player_name}. They'd rather go to prison as martyrs.

+ [I had to try]
    Agent 0x99: It was worth asking. His refusal tells us something about ENTROPY's organizational culture.
    Agent 0x99: These aren't mercenaries. They're ideologues. That's useful intelligence.
    -> recruit_outcome
+ [I thought maybe he'd want to reduce his sentence]
    Agent 0x99: A rational person would. Derek isn't rational. He's a believer.
    Agent 0x99: His ideology matters more than his freedom.
    -> recruit_outcome

=== recruit_outcome ===
Agent 0x99: He's in custody now. Same outcome as arrest.

Agent 0x99: But we learned something important: ENTROPY attracts true believers. They won't flip for deals.

Agent 0x99: We'll need to find other ways to get inside intelligence.

-> phase_3_discussion

// ================================================
// CONSEQUENCE: EXPOSE
// ================================================

=== consequence_expose ===
Agent 0x99: Public disclosure. Full transparency.

Agent 0x99: The casualty projections are on every news site. Derek's death calculations. The targeting lists.

Agent 0x99: The world now knows what ENTROPY was willing to do.

+ [People deserve to know]
    Agent 0x99: Maybe. But now ENTROPY knows we're onto Operation Shatter methodology.
    Agent 0x99: They'll adapt. Change tactics. We've lost the element of surprise.
    -> expose_outcome
+ [Let them see who Derek really is]
    Agent 0x99: They're seeing. "Acceptable losses." "Educational deaths."
    Agent 0x99: The public is horrified. Good. They should be.
    -> expose_outcome

=== expose_outcome ===
Agent 0x99: Director Netherton is... not happy. We don't usually expose methods.

Agent 0x99: But ENTROPY's tactics are now public knowledge. People know to verify. To question.

Agent 0x99: In a twisted way, you taught the lesson Derek wanted—just without the deaths.

{maya_identity_protected:
    Agent 0x99: At least Maya's identity stayed protected through all this.
- else:
    Agent 0x99: Maya's identity came out in the disclosure. She's being handled as a public whistleblower now.
}

-> phase_3_discussion

// ================================================
// PHASE 3 DISCUSSION - THE BIGGER PICTURE
// ================================================

=== phase_3_discussion ===
Agent 0x99: {player_name}, I need you to understand what we learned today.

Agent 0x99: We always thought ENTROPY was sophisticated cybercrime. Data theft. Corporate espionage.

Agent 0x99: This is different. Derek had casualty projections. He calculated deaths and considered them acceptable.

+ [They're willing to kill for their ideology]
    -> true_nature
+ [What does that mean for future missions?]
    -> true_nature

=== true_nature ===
Agent 0x99: It means we're not fighting criminals. We're fighting true believers.

Agent 0x99: People who think killing people is "education." Who see deaths as "acceptable losses."

Agent 0x99: And if Social Fabric was willing to do this... what are the other cells planning?

+ [Who is The Architect?]
    -> architect_mystery
+ [How do we stop them?]
    -> stop_entropy

// ================================================
// THE ARCHITECT MYSTERY
// ================================================

=== architect_mystery ===
Agent 0x99: We don't know. ENTROPY's leader, strategist, philosopher.

Agent 0x99: Derek quoted The Architect. Believed every word. Got approval to kill 85 people.

Agent 0x99: Whoever they are, they've built an organization of true believers.

+ [We have to find them]
    Agent 0x99: Every cell we disrupt, every operation we stop, brings us closer.
    {lore_collected >= 3:
        Agent 0x99: The intelligence you collected today gives us new leads. The Architect's communication patterns. Their philosophical fingerprints.
    }
    -> mission_end
+ [That sounds terrifying]
    Agent 0x99: It is. But that's why SAFETYNET exists.
    Agent 0x99: Today, you stood between ENTROPY and 85 people they'd sacrifice.
    -> mission_end

=== stop_entropy ===
Agent 0x99: Cell by cell. Operation by operation.

Agent 0x99: Today you stopped Operation Shatter. Tomorrow, we stop the next one.

-> mission_end

// ================================================
// MISSION END - Personalized summary
// ================================================

=== mission_end ===
Agent 0x99: First mission complete. Lives saved. True believer in custody.

{lore_collected >= 3:
    Agent 0x99: And {lore_collected} intelligence fragments recovered. That's thorough investigative work.
}
{lore_collected == 0:
    Agent 0x99: You focused on the primary objectives. Efficient.
    Agent 0x99: But next time, look for additional intelligence. Context helps future operations.
}

Agent 0x99: Get some rest. Next briefing is in 48 hours.

Agent 0x99: And {player_name}? You did more than complete a mission today.

Agent 0x99: You saved lives. Real people who will never know your name.

Agent 0x99: That's what SAFETYNET is for.

[MISSION COMPLETE: FIRST CONTACT]

{final_choice == "fight":
    [OUTCOME: Derek Lawson subdued by force - Hostile engagement neutralized]
}
{final_choice == "arrest":
    [OUTCOME: Derek Lawson arrested - Prosecution pending]
}
{final_choice == "recruit":
    [OUTCOME: Derek Lawson arrested - Refused cooperation]
}
{final_choice == "expose":
    [OUTCOME: Full public disclosure - ENTROPY methods exposed]
}

[OPERATION SHATTER: NEUTRALIZED]
[LIVES SAVED: 42-85 (estimated)]

{found_casualty_projections && found_target_database:
    [EVIDENCE: COMPLETE - All critical documents recovered]
}
{found_casualty_projections && not found_target_database:
    [EVIDENCE: SUBSTANTIAL - Casualty projections secured]
}
{not found_casualty_projections && found_target_database:
    [EVIDENCE: SUBSTANTIAL - Target database secured]
}
{not found_casualty_projections && not found_target_database:
    [EVIDENCE: PARTIAL - Forensics team recovering additional files]
}

{maya_identity_protected:
    [MAYA CHEN: Identity protected]
- else:
    [MAYA CHEN: Identity compromised - Under SAFETYNET protection]
}

{kevin_protected:
    [KEVIN PARK: Protected from frame-up - Career intact]
}
{kevin_choice == "ignore":
    [KEVIN PARK: Arrested, later cleared - Traumatized but free]
}
{kevin_choice == "":
    [KEVIN PARK: Status unknown]
}

[The Architect remains at large...]

#exit_conversation
-> END
