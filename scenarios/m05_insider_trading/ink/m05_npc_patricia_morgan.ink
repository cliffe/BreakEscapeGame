// ===========================================
// Mission 5: NPC - Patricia Morgan (CSO)
// Chief Security Officer, Mission Handler
// ===========================================

VAR patricia_influence = 5            // 0-10 scale
VAR topic_investigation = false
VAR topic_suspects = false
VAR topic_company_politics = false
VAR gave_security_logs = false
VAR first_meeting = true

// External variables
VAR player_name = "Agent 0x00"
VAR evidence_level = 0
VAR torres_identified = false
VAR torres_turned = false
VAR torres_arrested = false
VAR torres_killed = false

// ===========================================
// INITIAL MEETING
// ===========================================

=== start ===
#complete_task:meet_handler

{first_meeting:
    ~ first_meeting = false
    #speaker:narrator
    #display:patricia-professional

    A woman in her early 50s approaches. Military bearing, sharp eyes. Former Marine, you'd guess.

    #speaker:patricia_morgan
    Patricia Morgan: You must be the SAFETYNET consultant. Patricia Morgan, Chief Security Officer.

    Patricia Morgan: Thanks for coming on short notice.

    + [Glad to help. Fill me in on the situation.]
        You: Fill me in on what you've found so far.
        ~ patricia_influence += 1
        # influence_increased
        -> briefing_details

    + [Let's skip the pleasantries. I need access.]
        You: I'm here to work, not chat. What access do I have?
        Patricia Morgan: Direct. I like it.
        ~ patricia_influence += 1
        # influence_increased
        -> provide_access

    + [Agent 0x99 briefed me. 4.2 TB exfiltration — I know the basics.]
        You: I know the basics. Quantum crypto research, inside job.
        Patricia Morgan: Good. Then let's get to work.
        ~ patricia_influence += 2
        # influence_increased
        -> provide_access
}

{not first_meeting:
    #display:patricia-neutral
    Patricia Morgan: Back for more intel?
    -> hub
}

=== briefing_details ===
#speaker:patricia_morgan

Patricia Morgan: Data exfiltration. 4.2 terabytes over six weeks.

Patricia Morgan: Project Heisenberg. Quantum-safe key material for the national emergency dispatch rollout.

Patricia Morgan: If ENTROPY gets their hands on it, we're not talking about a leak. We're talking about ambulances that don't get there in time.

+ [How did you detect it?]
    Patricia Morgan: Anomalous network traffic. 2-4 AM uploads to external servers.
    Patricia Morgan: Took three weeks to confirm it wasn't legitimate remote work.
    -> provide_access

+ [Who has access to this data?]
    -> suspects_overview

=== suspects_overview ===
#speaker:patricia_morgan

Patricia Morgan: Eight people with TS/SCI clearance. Cryptography division.

Patricia Morgan: Dr. Sarah Chen leads the team. Five senior researchers. Two junior engineers.

Patricia Morgan: All vetted. All trusted. Until now.

+ [I'll need to interview them]
    ~ patricia_influence += 1
    # influence_increased
    You: Can you arrange access without tipping them off?
    Patricia Morgan: Already done. You're here as a "routine security audit."
    -> provide_access

+ [Any prime suspects?]
    Patricia Morgan: Not yet. That's your job.
    -> provide_access

=== provide_access ===
#speaker:patricia_morgan

#give_item:id_badge
Patricia Morgan: Here's your visitor badge. Limited access for now.

#complete_task:obtain_security_badge

Patricia Morgan: For restricted zones, you'll need to... improvise.

Patricia Morgan: I'll be available by phone if you need authorization.

+ [Where should I start?]
    You: Where should I start?
    Patricia Morgan: Security logs in the open office area. Network traffic analysis.
    Patricia Morgan: Talk to people. Someone knows something.
    ~ gave_security_logs = true
    #exit_conversation
    -> DONE

+ [I'll figure it out from here.]
    You: I'll figure it out from here.
    #exit_conversation
    -> DONE

// ===========================================
// CONVERSATION HUB (Return Visits)
// ===========================================

=== hub ===

+ {not topic_investigation} [How's the investigation going?]
    -> ask_investigation

+ {not topic_suspects} [Who's on the suspect list?]
    -> ask_suspects

+ {not topic_company_politics} [What's the politics around this, upstairs?]
    -> ask_company_politics

+ {evidence_level >= 3} [I want to compare notes on what I've found.]
    -> share_findings

+ [I need authorization for something.]
    -> request_authorization

+ [That's everything for now. I'll keep you posted.]
    You: That's everything for now. I'll keep you posted.
    #exit_conversation
    #speaker:patricia_morgan
    Patricia Morgan: Stay in touch.
    -> DONE

=== ask_investigation ===
#speaker:patricia_morgan
~ topic_investigation = true

Patricia Morgan: Internal investigation hit a wall. Insider's too sophisticated.

Patricia Morgan: Access logs look legitimate. No obvious behavioral red flags.

{patricia_influence >= 3:
    Patricia Morgan: Between you and me? I should have caught this sooner.
    ~ patricia_influence += 1
    # influence_increased
}

-> hub

=== ask_suspects ===
#speaker:patricia_morgan
~ topic_suspects = true

Patricia Morgan: Dr. Sarah Chen - team lead. Brilliant cryptographer.

Patricia Morgan: David Torres - senior researcher. Top of his field.

Patricia Morgan: Five others with varying levels of access.

{patricia_influence >= 5:
    Patricia Morgan: Torres has been... distracted lately. Personal issues.
    Patricia Morgan: But distracted doesn't mean traitor.
}

-> hub

=== ask_company_politics ===
#speaker:patricia_morgan
~ topic_company_politics = true

Patricia Morgan: CEO Jennifer Zhao wants this handled quietly.

Patricia Morgan: No press. No prosecution if we can avoid it. Protect the DoD contracts.

{patricia_influence >= 4:
    Patricia Morgan: I want justice. She wants damage control.
    Patricia Morgan: We'll see who wins.
    ~ patricia_influence += 1
    # influence_increased
}

-> hub

=== share_findings ===
#speaker:patricia_morgan

You: I've found some leads. Want to compare notes?

{evidence_level >= 5:
    Patricia Morgan: Talk to me. What have you got?
    -> significant_findings
}
{evidence_level >= 3:
    Patricia Morgan: I'm listening.
    -> moderate_findings
}

=== moderate_findings ===
#speaker:patricia_morgan

You: [Share evidence summary]

Patricia Morgan: Good work. Keep digging.

{patricia_influence >= 6:
    Patricia Morgan: You're thorough. I appreciate that.
}

~ patricia_influence += 1
# influence_increased
-> hub

=== significant_findings ===
#speaker:patricia_morgan

You: David Torres. The medical bills, the after-hours server access, the recruitment pamphlet — it all points to him.

Patricia Morgan: Damn. You're close, aren't you?

Patricia Morgan: Be careful. When you confront him, you're on your own.

Patricia Morgan: But... good work. Really.

~ torres_identified = true
~ patricia_influence += 2
# influence_increased
#set_global:torres_identified:true
#complete_task:identify_torres
-> hub

=== request_authorization ===
#speaker:patricia_morgan

Patricia Morgan: What do you need?

+ [I need access to employee financial records.]
    #give_item:notes:Employee Financial Records
    You: I need access to employee financial records.
    Patricia Morgan: I'll send you the files. Check your device.
    ~ patricia_influence += 1
    # influence_increased
    -> hub

+ [I need a server room access override.]
    You: I need a server room access override.
    Patricia Morgan: Done. Security system updated.
    #unlock_room:server_room
    ~ patricia_influence += 1
    # influence_increased
    -> hub

+ [Actually, that can wait.]
    You: Actually, that can wait.
    -> hub

// ===========================================
// EVENT-TRIGGERED: Player Identifies Insider
// ===========================================

=== on_insider_identified ===
#speaker:patricia_morgan

[Patricia's phone rings. You call her.]

You: Patricia, I've identified the insider.

Patricia Morgan: Who?

{torres_identified:
    You: David Torres.
    Patricia Morgan: *long pause* Damn it.
    Patricia Morgan: His wife. Elena. She's sick, isn't she?
    Patricia Morgan: Financial desperation. ENTROPY's playbook.
}

Patricia Morgan: What do you need from me?

+ [I want backup when I confront him.]
    You: I want backup when I confront him.
    Patricia Morgan: You've got it. When and where?
    -> DONE

+ [Stay ready. I'll handle this myself.]
    You: Stay ready. I'll handle this myself.
    Patricia Morgan: Be careful. Cornered people are dangerous.
    -> DONE

// ===========================================
// EVENT-TRIGGERED: Mission Complete
// ===========================================

=== on_mission_complete ===
#speaker:patricia_morgan

Patricia Morgan: Is it done?

{torres_turned:
    You: He's working with us now. Double agent.
    Patricia Morgan: Risky. But if it maps ENTROPY's network... good call.
}

{torres_arrested:
    You: He's in custody. Evidence is solid.
    Patricia Morgan: By the book. Respect that.
}

{torres_killed:
    You: He resisted. Lethal force was necessary.
    Patricia Morgan: *pause* Understood. I'll handle the paperwork.
}

Patricia Morgan: Thank you, {player_name}. You did good work here.

#exit_conversation
-> DONE
