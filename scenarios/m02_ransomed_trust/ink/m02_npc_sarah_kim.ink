// ===========================================
// ACT 2 NPC: Dr. Sarah Kim (Hospital CTO)
// Mission 2: Ransomed Trust
// Break Escape - Desperate Authority Figure
// ===========================================

// Variables for tracking player relationship and topics
VAR kim_influence = 0             // 0-100 trust/rapport with Dr. Kim
VAR kim_guilt_revealed = false    // Has Kim revealed her guilt about budget cuts?
VAR topic_attack_vector = false   // Discussed how attack happened
VAR topic_marcus = false          // Discussed Marcus Webb
VAR topic_ransom_vote = false     // Discussed board ransom vote
VAR topic_budget = false          // Discussed budget cuts
VAR player_warned_kim = false     // Player warned Kim about scapegoating Marcus
VAR kim_access_given = false      // Has Kim authorized access and pointed player to Marcus?

// Synced from globalVars by engine at call-open (inside-asset investigation)
VAR insider_evidence_partial = false
VAR insider_identified = false

// External variables (set by game)
EXTERNAL player_name()
VAR objectives_completed = 0

// ===========================================
// FIRST ENCOUNTER
// ===========================================

=== start ===
#speaker:dr_kim

{objectives_completed == 0:
    -> first_meeting
}
{objectives_completed > 0 and objectives_completed < 5:
    -> mid_mission_checkin
}
{objectives_completed >= 5:
    -> late_mission_update
}

=== first_meeting ===
#speaker:dr_kim

Dr. Kim: Thank god you're here. We're running out of time.

Dr. Kim: 47 patients on backup power. If we don't restore systems in 12 hours...

Dr. Kim: The board is voting on paying the ransom in 4 hours. I need your opinion.

* [Tell me what happened. How did they get in?]
    ~ kim_influence += 5
    # influence_increased
    -> explain_attack

* [We'll get those systems back. That's why I'm here.]
    ~ kim_influence += 10
    # influence_increased
    Dr. Kim: I hope you're right. Those are real people.
    -> explain_attack

* [Why are they voting so quickly?]
    ~ kim_influence += 5
    # influence_increased
    -> explain_board_vote

=== explain_attack ===
#speaker:dr_kim
~ topic_attack_vector = true

Dr. Kim: Our IT admin, Marcus, kept warning us about some vulnerability in the old file-transfer software. Something on the backup server.

Dr. Kim: I don't know the technical details -- that's his world. What I remember is the number he put next to it. Eighty-five thousand pounds for the server upgrade.

Dr. Kim: We... we deferred it. Budget cuts.

* [Why defer cybersecurity?]
    ~ topic_budget = true
    -> reveal_budget_guilt

* [Where's Marcus now?]
    ~ topic_marcus = true
    -> discuss_marcus

* [We need to focus on recovery. Where's your IT department?]
    -> grant_access

=== reveal_budget_guilt ===
#speaker:dr_kim
~ kim_guilt_revealed = true
~ kim_influence += 5
# influence_increased
Dr. Kim: I recommended those budget cuts. The $85,000 Marcus wanted for server security.

Dr. Kim: We bought a $3.2 million MRI instead. State-of-the-art equipment.

Dr. Kim: Now people might die because I chose shiny technology over unsexy cybersecurity.

* [You made a decision based on patient care priorities. You couldn't have known.]
    ~ kim_influence += 10
    # influence_increased
    Dr. Kim: That's... thank you. But I should have listened.
    -> hub

* [The past doesn't matter now. Let's focus on recovery.]
    ~ kim_influence += 5
    # influence_increased
    Dr. Kim: Right. Professional. I appreciate that.
    -> hub

* [$85K vs. patient data security. That was a risky choice.]
    ~ kim_influence -= 10
    # influence_decreased
    Dr. Kim: I... I know. I know.
    -> hub

=== discuss_marcus ===
#speaker:dr_kim
~ topic_marcus = true

Dr. Kim: Marcus is devastated. Blaming himself.

Dr. Kim: The board... they're planning to blame him too. Scapegoat.

Dr. Kim: But he warned us. He did everything right.

* [I'll make sure the evidence shows Marcus warned you. He shouldn't take the fall.]
    ~ kim_influence += 15
    # influence_increased
    ~ player_warned_kim = true
    Dr. Kim: Thank you. He deserves better than this.
    #complete_task:learn_about_scapegoating
    #set_global:marcus_protected:true
    -> hub

* [Let's focus on the mission first.]
    ~ kim_influence += 0
    Dr. Kim: Of course. IT Department is down the hall.
    -> hub

* [He's the IT admin. He has some responsibility here.]
    ~ kim_influence -= 15
    # influence_decreased
    Dr. Kim: No. We ignored him. This isn't his fault.
    -> hub

=== explain_board_vote ===
#speaker:dr_kim
~ topic_ransom_vote = true

Dr. Kim: Board members are terrified. Malpractice lawsuits, patient deaths, reputation damage.

Dr. Kim: $87,000 seems cheap compared to those risks.

Dr. Kim: But... we'd be funding terrorists. Criminals. What do I tell them?

* [Patient lives first. If it comes to it, pay.]
    ~ kim_influence += 5
    # influence_increased
    #set_global:advised_board_pay:true
    #set_global:advised_board_refuse:false
    Dr. Kim: "Do no harm." That's the oath. Right now it's the only thing I still trust myself on.
    -> hub

* [Don't fund ENTROPY. Whatever they get, they spend on the next hospital.]
    ~ kim_influence += 5
    # influence_increased
    #set_global:advised_board_refuse:true
    #set_global:advised_board_pay:false
    Dr. Kim: You sound like Marcus did. Six months ago. I didn't listen to him either.
    -> hub

* [That's your call, Dr. Kim. I'm here to find the keys, not vote.]
    ~ kim_influence += 10
    # influence_increased
    Dr. Kim: Everyone's got an opinion tonight. You're the first to admit the decision isn't yours to make.
    -> grant_access

=== grant_access ===
#speaker:dr_kim
~ kim_access_given = true

Dr. Kim: I'm authorising you as far as I'm able. Here -- an admin badge. That'll get you the administrative floor.

Dr. Kim: The rest, I can't just hand you. With the breach, everything critical is locked down to named staff, and half our access control is down with the rest of the systems. For the server room you'll need Marcus -- he has the keycard. The other doors... honestly, do what you have to. I'll answer for it later.

Dr. Kim: Find Marcus Webb in the IT department -- east corridor. He's been there all night and knows exactly how they got in.

Dr. Kim: Just save those patients.

#complete_task:meet_dr_kim
#unlock_task:talk_to_marcus
#unlock_task:obtain_password_hints
#unlock_aim:access_it_systems
#give_item:id_badge

-> hub

// ===========================================
// CONVERSATION HUB (Repeatable Dialogue)
// ===========================================

=== hub ===
+ {not topic_attack_vector} [Tell me what happened. How did they get in?]
    -> explain_attack

+ {not topic_marcus} [What's the situation with Marcus Webb?]
    -> discuss_marcus

+ {not topic_ransom_vote} [Why is the board voting so quickly?]
    -> explain_board_vote

+ {not topic_budget and topic_marcus} [What were the board's budget priorities?]
    ~ topic_budget = true
    -> reveal_budget_guilt

+ {topic_marcus and not player_warned_kim} [I can document Marcus's warnings. Make sure he's not scapegoated.]
    ~ kim_influence += 15
    # influence_increased
    ~ player_warned_kim = true
    Dr. Kim: Thank you. He deserves better.
    #complete_task:learn_about_scapegoating
    #set_global:marcus_protected:true
    -> hub

+ {insider_evidence_partial and not insider_identified} [Someone inside this hospital confirmed ENTROPY's timing. You cut the budget. You'd have signed off the fire drill. Was it you?]
    -> accuse_kim

+ [I need to get back to it.]
    #speaker:dr_kim
    {not kim_access_given:
        ~ kim_access_given = true
        Dr. Kim: Find Marcus Webb in the IT department. He knows how they got in.
        Dr. Kim: Good luck. We're counting on you.
        #complete_task:meet_dr_kim
        #unlock_task:talk_to_marcus
        #unlock_task:obtain_password_hints
        #unlock_aim:access_it_systems
    - else:
        Dr. Kim: Keep going. We're counting on you.
    }
    #exit_conversation
    -> hub

// ===========================================
// WRONG ACCUSATION (red herring -- Kim is negligent, not a traitor)
// ===========================================

=== accuse_kim ===
#speaker:dr_kim

Dr. Kim: You think I -- I called SAFETYNET. I brought YOU in. Why would I do that if I were working with them?

Dr. Kim: I made a catastrophic budget decision. I did NOT invite these people into my hospital.

* [You're right. That doesn't add up. I'm sorry.]
    ~ kim_influence -= 5
    # influence_decreased
    Dr. Kim: Then stop wasting the time we don't have and find who did.
    -> hub

* [Guilt over the budget would be a perfect cover.]
    -> accuse_kim_push

=== accuse_kim_push ===
#speaker:dr_kim

Dr. Kim: How DARE you. I have patients dying on backup power and you're playing detective with the one person trying to save them.

Dr. Kim: We are done. Find your own way around my hospital.

#hostile:dr_sarah_kim
#set_global:accused_wrong_suspect:true
#exit_conversation
-> DONE

// ===========================================
// MID-MISSION CHECK-IN
// ===========================================

=== mid_mission_checkin ===
#speaker:dr_kim

Dr. Kim: Any progress?

{objectives_completed >= 2:
    Dr. Kim: I see you're making headway. Thank you.
}
{objectives_completed < 2:
    Dr. Kim: Time's running out. Board votes in less than 2 hours now.
}

+ [I've accessed the IT systems. Working on recovery.]
    ~ kim_influence += 5
    # influence_increased
    Dr. Kim: Good. Keep going.
    -> hub

+ [How are the patients?]
    Dr. Kim: Stable for now. Backup power holding. But every hour increases risk.
    -> hub

+ [I need to keep working.]
    Dr. Kim: Of course. Go.
    #exit_conversation
    -> hub

// ===========================================
// LATE MISSION UPDATE
// ===========================================

=== late_mission_update ===
#speaker:dr_kim

Dr. Kim: The board is meeting right now. Have you found the decryption keys?

{objectives_completed >= 6:
    Dr. Kim: I see you've made significant progress. What do I tell the board?
    -> ransom_decision_input
}
{objectives_completed < 6:
    Dr. Kim: We're running out of time. What should I tell them?
    -> ransom_decision_input
}

=== ransom_decision_input ===
#speaker:dr_kim

Dr. Kim: I walk into that boardroom in five minutes. Whatever you tell me now, I carry in with me. So be sure.

+ [Pay the ransom. Save who you can save tonight.]
    #set_global:advised_board_pay:true
    #set_global:advised_board_refuse:false
    ~ kim_influence += 10
    # influence_increased
    Dr. Kim: Then that's what I'll argue. And if they ask who advised it, I put my name on it. Not yours.
    -> hub

+ [Don't pay. I'll have the keys -- give me the time.]
    #set_global:advised_board_refuse:true
    #set_global:advised_board_pay:false
    ~ kim_influence += 5
    # influence_increased
    Dr. Kim: You're asking me to bet forty-seven lives on you being fast enough.
    Dr. Kim: ...All right. I'll hold them off as long as I can. Don't make me a liar in that room.
    -> hub

+ [The board decides. I'll have keys either way -- just buy me time.]
    ~ kim_influence += 5
    # influence_increased
    Dr. Kim: Time, I can buy. Go.
    -> hub

+ [I need to keep working.]
    #exit_conversation
    -> hub
