// ===========================================
// Mission 5: NPC - Dr. Sarah Chen
// Chief Scientist, Project Heisenberg Lead
// ===========================================

VAR chen_influence = 0                // 0-100 scale
VAR topic_heisenberg = false
VAR topic_team = false
VAR topic_torres_defense = false
VAR gave_research_access = false
VAR first_meeting = true

// External variables
VAR player_name = "Agent 0x00"
VAR torres_identified = false
VAR torres_turned = false
VAR torres_arrested = false
VAR torres_killed = false

// ===========================================
// INITIAL MEETING
// ===========================================

=== start ===
#complete_task:talk_to_dr_chen

{first_meeting:
    ~ first_meeting = false
    #speaker:narrator
    #display:chen-professional

    A woman in her mid-40s looks up from complex equations on a whiteboard. Sharp eyes behind glasses.

    #speaker:dr_chen
    Dr. Sarah Chen: You're the security consultant. Sarah Chen, Project Heisenberg lead.

    Dr. Sarah Chen: I hope you find whoever did this quickly.

    + [I'll do my best. Can you help me understand what was stolen?]
        You: The technical context will help narrow down suspects.
        ~ chen_influence += 10
        # influence_increased
        -> heisenberg_explanation

    + [I need to interview your team members.]
        You: Everyone with access to Project Heisenberg.
        Dr. Sarah Chen: My team didn't do this.
        -> defensive_response

    + [Could you have missed a behavioural change in your team?]
        You: Could you have missed something? Behavioral changes?
        Dr. Sarah Chen: I know my people.
        ~ chen_influence -= 5
        # influence_decreased
        -> defensive_response
}

{not first_meeting:
    #display:chen-neutral
    Dr. Sarah Chen: Yes?
    -> hub
}

=== heisenberg_explanation ===
#speaker:dr_chen

Dr. Sarah Chen: Project Heisenberg is quantum key distribution for military communications.

Dr. Sarah Chen: Post-quantum cryptography. Secure against quantum computer attacks.

Dr. Sarah Chen: If hostile nations get our protocols, they can develop countermeasures. Decade of research wasted.

{chen_influence >= 15:
    Dr. Sarah Chen: 247 DoD facilities are scheduled for installation. If attackers know the deployment timeline...
    Dr. Sarah Chen: People could die.
    ~ chen_influence += 5
    # influence_increased
}

-> hub

=== defensive_response ===
#speaker:dr_chen

Dr. Sarah Chen: My team is brilliant. Vetted. TS/SCI clearance.

Dr. Sarah Chen: If one of them did this, they had a reason. Pressure. Coercion.

+ [I'm not here to judge. Just to find the truth.]
    ~ chen_influence += 10
    # influence_increased
    You: Whoever did this might be a victim too.
    Dr. Sarah Chen: Thank you for understanding that.
    -> hub

+ [Reason doesn't justify espionage.]
    You: They made a choice.
    Dr. Sarah Chen: We're done here.
    ~ chen_influence -= 10
    # influence_decreased
    #exit_conversation
    -> DONE

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===

+ {not topic_heisenberg} [Explain Project Heisenberg to me in detail.]
    -> ask_heisenberg_details

+ {not topic_team} [Tell me about your team.]
    -> ask_team_members

+ {not topic_torres_defense and chen_influence >= 20} [What can you tell me about David Torres?]
    -> ask_torres

+ {chen_influence >= 30} [I need access to research documentation.]
    -> request_research_access

+ [That's all for now.]
    You: That's all for now.
    #exit_conversation
    #speaker:dr_chen
    Dr. Sarah Chen: Good luck with your investigation.
    -> DONE

=== ask_heisenberg_details ===
#speaker:dr_chen
~ topic_heisenberg = true
~ chen_influence += 5
# influence_increased

Dr. Sarah Chen: Quantum entanglement enables unbreakable encryption. Any eavesdropping attempt collapses the quantum state.

Dr. Sarah Chen: Our work implements this at scale. 847 pages of protocols, algorithms, hardware specifications.

Dr. Sarah Chen: Three years of research. Billions in DoD funding.

{chen_influence >= 25:
    Dr. Sarah Chen: If you want to understand the technical details, check the research lab. Documentation's there.
    #unlock_task:access_heisenberg_documentation
}

-> hub

=== ask_team_members ===
#speaker:dr_chen
~ topic_team = true
~ chen_influence += 5
# influence_increased

Dr. Sarah Chen: Eight people total. I personally recruited most of them.

Dr. Sarah Chen: David Torres is my senior researcher. Brilliant cryptographer. MIT PhD.

Dr. Sarah Chen: The others are equally qualified.

{chen_influence >= 20:
    Dr. Sarah Chen: David's been... distracted lately. Personal issues.
    Dr. Sarah Chen: His wife Elena has cancer. Stage 3. It's been hard on him.
    ~ chen_influence += 5
    # influence_increased
}

-> hub

=== ask_torres ===
#speaker:dr_chen
~ topic_torres_defense = true

Dr. Sarah Chen: David is one of the best cryptographers I've ever worked with.

{chen_influence >= 30:
    Dr. Sarah Chen: I've seen him struggle. Medical bills. Insurance denials.
    ~ chen_influence += 10
    # influence_increased
}

-> hub

=== request_research_access ===
#speaker:dr_chen

You: I need access to Project Heisenberg documentation. Technical specs, team files.

{chen_influence >= 40:
    #give_item:keycard:research_lab_badge
    Dr. Sarah Chen: Alright. You've been thorough and respectful.
    Dr. Sarah Chen: Here's my research badge. Use it wisely.

    #unlock_room:research_lab
    #complete_task:obtain_research_access

    ~ gave_research_access = true
    ~ chen_influence += 5
    # influence_increased

    Dr. Sarah Chen: The research lab has everything you need.
    -> hub
- else:
    Dr. Sarah Chen: I don't know you well enough to grant that level of access.
    Dr. Sarah Chen: Keep investigating. Earn my trust.
    -> hub
}

// ===========================================
// EVENT-TRIGGERED: Player Identifies Torres
// ===========================================

=== on_torres_accused ===
#speaker:dr_chen

{torres_identified:
    Dr. Sarah Chen: Is it true? David Torres?

    + [Yes. The evidence is conclusive]
        Dr. Sarah Chen: *closes eyes* I should have seen it.
        Dr. Sarah Chen: He was pulling away. Working late alone. Avoiding eye contact.
        -> chen_guilt

    + [I'm still gathering evidence]
        Dr. Sarah Chen: Be absolutely certain before you destroy his life.
        -> DONE
}

=== chen_guilt ===
#speaker:dr_chen

Dr. Sarah Chen: I failed him. As a supervisor. As a friend.

+ [This isn't your fault. ENTROPY manipulated him]
    Dr. Sarah Chen: That doesn't make me feel better.
    -> torres_defense

+ [He made his choice]
    Dr. Sarah Chen: *sharp look* He made a choice. So did they, when they picked him.
    -> DONE

=== torres_defense ===
#speaker:dr_chen

Dr. Sarah Chen: What happens to him now?

+ [That depends on how he cooperates]
    Dr. Sarah Chen: Will you... consider his circumstances?
    You: I'll make the right call when I confront him.
    Dr. Sarah Chen: Thank you.
    -> DONE

+ [He'll face justice]
    Dr. Sarah Chen: *quiet* I understand.
    -> DONE

// ===========================================
// EVENT-TRIGGERED: Mission Complete
// ===========================================

=== on_mission_complete ===
#speaker:dr_chen

{torres_turned:
    Dr. Sarah Chen: I heard David's cooperating. Working with SAFETYNET.
    Dr. Sarah Chen: And... Elena's treatment will be covered?
    You: Witness protection program. She'll get the care she needs.
    Dr. Sarah Chen: *exhales* Thank god. Maybe something good comes from this.
}

{torres_arrested:
    Dr. Sarah Chen: David's in federal custody.
    Dr. Sarah Chen: What about Elena? The children?
    You: That's not my jurisdiction.
    Dr. Sarah Chen: *bitter* Of course not.
}

{torres_killed:
    Dr. Sarah Chen: I heard David was killed.
    Dr. Sarah Chen: *long silence*
    Dr. Sarah Chen: Elena's a widow now. Sofia and Miguel have no father.
    Dr. Sarah Chen: I hope it was worth it.
    #exit_conversation
    -> DONE
}

Dr. Sarah Chen: Thank you for... handling this as well as you could.

#exit_conversation
-> DONE
