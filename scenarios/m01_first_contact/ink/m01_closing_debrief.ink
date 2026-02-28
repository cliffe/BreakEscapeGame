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

// NPC casualty tracking
VAR kevin_ko = false              // Did player KO Kevin?
VAR sarah_ko = false              // Did player KO Sarah?
VAR maya_ko = false               // Did player KO Maya?

// Security Audit Assessment
VAR security_audit_completed = false    // Did player complete the security audit?
VAR audit_correct_answers = 0           // Number of correct security assessments
VAR audit_wrong_answers = 0             // Number of incorrect assessments

// ================================================
// START: DEBRIEF BEGINS
// ================================================

=== start ===

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
// Both informants removed
{kevin_ko && maya_ko:
    -> both_removed
}
// Maya removed (Kevin still operational)
{maya_ko && talked_to_kevin:
    -> kevin_helped_maya_removed
}
{maya_ko:
    -> maya_removed_alone
}
// Kevin removed (Maya still operational or not talked to)
{kevin_ko && talked_to_maya:
    -> worked_with_maya_kevin_removed
}
{kevin_ko:
    -> kevin_removed_alone
}
// Normal paths
{talked_to_kevin && talked_to_maya:
    -> worked_with_both
}
{talked_to_kevin:
    -> worked_with_kevin
}
{talked_to_maya:
    -> worked_with_maya
}
-> worked_alone

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

=== worked_with_maya_kevin_removed ===
Agent 0x99: You used Maya as your primary source. Good call—she knew exactly what was happening at Viral Dynamics.

{maya_identity_protected:
    Agent 0x99: Her identity stayed protected throughout. She can continue working without looking over her shoulder.
- else:
    Agent 0x99: Unfortunately Maya's identity came out during the operation. We're handling her protection.
}

Agent 0x99: Kevin Park was removed from the picture during the operation.

Agent 0x99: I want to be clear about something: we ran Kevin's background after the fact. Nothing connects him to ENTROPY. He was the IT manager—doing his job, flagging concerns, following procedure.

Agent 0x99: You had the authority to make that call. I'm noting it as an operational decision, not a failure.

-> kevin_ko_discussion

=== kevin_removed_alone ===
Agent 0x99: You ran this operation without building rapport with either Kevin or Maya. Self-sufficient approach.

Agent 0x99: Kevin Park was removed from the picture during the operation.

Agent 0x99: Post-operation check on Kevin's files confirms: no ENTROPY connections. No hidden agenda. He was exactly what he appeared to be—an IT manager who'd been raising security concerns nobody would listen to.

Agent 0x99: You had the authority. The operation succeeded. I'm logging it as an operational casualty, not a failure of judgment.

-> kevin_ko_discussion

=== both_removed ===
Agent 0x99: Both Kevin Park and Maya Chen were removed from the picture during the operation.

Agent 0x99: I want to be direct with you: neither of them was ENTROPY. Kevin was an IT manager flagging concerns. Maya was our own informant—the one who brought us the lead on Operation Shatter in the first place.

Agent 0x99: We lost whatever intelligence Maya had still to share. That's a real cost. ENTROPY's internal connections, the names she hadn't written down yet—gone.

Agent 0x99: You had the authority to make those calls. The mission succeeded. But I'm noting it: two civilians removed, one of them our asset.

-> kevin_ko_discussion

=== kevin_helped_maya_removed ===
Agent 0x99: Kevin gave you access—the IT contractor cover did its job.

Agent 0x99: Maya Chen was removed during the operation.

Agent 0x99: Maya was the one who contacted SAFETYNET. Whatever she'd gathered beyond what was already in her office—whatever she was still going to tell us—we won't get that now.

Agent 0x99: She wasn't ENTROPY. She was trying to help. I'm logging it as an operational casualty.

+ [The mission still succeeded.]
    Agent 0x99: It did. Derek's in custody. Operation Shatter is stopped.
    Agent 0x99: Just remember what it cost. That's what makes you better at this.
    -> kevin_frame_discussion
+ [I know. It wasn't ideal.]
    Agent 0x99: Honest answer. Carry it. It'll make you sharper next time.
    -> kevin_frame_discussion

=== maya_removed_alone ===
Agent 0x99: You ran this mostly solo.

Agent 0x99: Maya Chen was removed during the operation.

Agent 0x99: We may never know what Maya had to tell us. She'd been documenting everything about ENTROPY's operations at Viral Dynamics. The parts she hadn't written down yet—names, contacts, methods—that intelligence is gone.

Agent 0x99: Maya wasn't ENTROPY. She was our informant. She trusted SAFETYNET enough to reach out, and that cost her.

Agent 0x99: You had the authority. The operation succeeded. I'm noting the loss.

+ [Understood. The mission came first.]
    Agent 0x99: And it did. Keep that in proportion—you stopped 85 people from dying.
    Agent 0x99: But we lost Maya's intelligence. That gap shows up in the next mission.
    -> kevin_frame_discussion
+ [It wasn't something I'm proud of.]
    Agent 0x99: Good. The day you stop caring about that is the day I worry about you.
    Agent 0x99: Focus ahead. Operation Shatter is stopped. That's what Maya wanted.
    -> kevin_frame_discussion

// ================================================
// KEVIN KO DISCUSSION - When player removed Kevin
// ================================================

=== kevin_ko_discussion ===
+ [He was in the way. Mission needed to proceed.]
    Agent 0x99: And it did. Derek's in custody. Operation Shatter is stopped.
    Agent 0x99: Kevin's collateral won't be on the official record as anything other than operational necessity.
    -> security_audit_review
+ [I'd make the same call again.]
    Agent 0x99: That's the mark of someone who can handle field work. You made a decision and owned it.
    Agent 0x99: Just carry it with you. It'll make you better at this, not worse.
    -> security_audit_review
+ [It wasn't my finest moment.]
    Agent 0x99: Honest answer. Those are the calls that stay with you.
    Agent 0x99: Kevin will be fine physically. And he'll never know how close he came to being caught in all of this.
    Agent 0x99: You stopped something that would have killed 85 people. Keep that in perspective.
    -> security_audit_review

// ================================================
// KEVIN FRAME-UP - Moral choice consequences
// ================================================

=== kevin_frame_discussion ===
{kevin_ko:
    // Kevin was already removed — the frame-up scenario doesn't apply
    -> security_audit_review
}
{kevin_choice == "":
    // Player didn't encounter the frame-up files
    -> security_audit_review
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

-> security_audit_review

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
    -> security_audit_review
+ [The mission had to come first]
    Agent 0x99: Did it? You still stopped Operation Shatter. You still caught Derek.
    Agent 0x99: Would five minutes to warn Kevin have changed that?
    Agent 0x99: I'm not judging. Field decisions are hard. But consequences are real.
    Agent 0x99: Kevin's kids watched him get arrested. That happened because of a choice you made.
    Agent 0x99: Live with it. Learn from it.
    -> security_audit_review

// ================================================
// SECURITY AUDIT REVIEW - Assess player's security analysis
// ================================================

=== security_audit_review ===
{security_audit_completed:
    -> audit_feedback
}
{not security_audit_completed:
    -> no_audit_feedback
}

=== audit_feedback ===
Agent 0x99: I noticed you gave Kevin a security assessment during your cover operation.

{audit_correct_answers >= 4:
    Agent 0x99: Your security analysis was excellent. You identified every major vulnerability correctly.
    Agent 0x99: Physical access controls, Derek's suspicious access patterns, predictable passwords, Patricia's firing, and Derek's unjustified network segmentation.
    Agent 0x99: That's professional-grade security consulting. Your cover was completely convincing.
    + [I wanted to maintain my cover properly]
        Agent 0x99: And you did. Kevin trusted you completely because you demonstrated real expertise.
        Agent 0x99: That kind of authentic tradecraft makes all the difference in deep cover work.
        -> derek_discussion
    + [The vulnerabilities were pretty obvious once I looked]
        Agent 0x99: Maybe to you. But recognizing them under pressure, while maintaining cover, while gathering intelligence on Operation Shatter?
        Agent 0x99: That's good work. Don't undersell it.
        -> derek_discussion
}

{audit_correct_answers == 3:
    Agent 0x99: Your security analysis was solid. Three out of five correct assessments.
    Agent 0x99: You identified most of the key vulnerabilities—enough to maintain credibility with Kevin.
    Agent 0x99: A few blind spots, but nothing that compromised your cover or the mission.
    + [Which ones did I miss?]
        {audit_wrong_answers >= 1:
            Agent 0x99: You underestimated a couple of the vulnerabilities Kevin had already flagged.
            Agent 0x99: In the field, always trust when an insider is telling you something's wrong. They see the patterns we miss.
        }
        -> derek_discussion
    + [I was focused on the bigger picture]
        Agent 0x99: Fair enough. Your primary mission was Operation Shatter, not a comprehensive security audit.
        Agent 0x99: Kevin bought your cover. That's what mattered.
        -> derek_discussion
}

{audit_correct_answers <= 2:
    Agent 0x99: Your security assessment was... rough. Two or fewer correct answers out of five.
    Agent 0x99: Kevin was asking you about obvious vulnerabilities he'd already identified. You dismissed most of them.
    + [I was trying not to alarm him]
        Agent 0x99: Understandable. But when an insider is showing you red flags, validate their concerns.
        Agent 0x99: You're supposed to be a security expert. Kevin needed you to see what he was seeing.
        Agent 0x99: Fortunately, your other actions kept him cooperative. But that assessment almost blew your cover.
        -> derek_discussion
    + [Security assessment wasn't my priority]
        Agent 0x99: It's part of your cover identity. When you're undercover as an expert, you need to be that expert.
        Agent 0x99: Kevin noticed you were missing things he'd already flagged. That could have raised suspicions.
        Agent 0x99: Mission succeeded anyway, but... work on your tradecraft. Deep cover requires authenticity.
        -> derek_discussion
}

=== no_audit_feedback ===
Agent 0x99: I noticed you didn't provide Kevin with a security assessment during your cover operation.

Agent 0x99: That's fine—it wasn't required for the mission. But it could have strengthened your cover credibility.

Agent 0x99: Next time you're undercover with a professional identity, look for opportunities to demonstrate authentic expertise.

Agent 0x99: It builds trust. And trust gives you access.

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

{sarah_ko:
    [SARAH MARTINEZ: Removed by operative - No ENTROPY connection]
}

{maya_ko:
    [MAYA CHEN: Removed by operative - Intelligence lost - No ENTROPY connection]
}
{not maya_ko && maya_identity_protected:
    [MAYA CHEN: Identity protected]
}
{not maya_ko && not maya_identity_protected:
    [MAYA CHEN: Identity compromised - Under SAFETYNET protection]
}

{kevin_ko:
    [KEVIN PARK: Removed by operative - Evidence confirms no ENTROPY connection]
}
{not kevin_ko && kevin_protected:
    [KEVIN PARK: Protected from frame-up - Career intact]
}
{not kevin_ko && kevin_choice == "ignore":
    [KEVIN PARK: Arrested, later cleared - Traumatized but free]
}
{not kevin_ko && kevin_choice == "":
    [KEVIN PARK: Status unknown]
}

[The Architect remains at large...]

#exit_conversation
-> END
