// ===========================================
// Mission 5: NPC - Kevin Park
// IT Systems Administrator, Badge Clone Target
// ===========================================

VAR kevin_influence = 0           // 0-100 scale
VAR badge_cloned = false
VAR topic_network = false
VAR topic_torres = false
VAR topic_security = false
VAR offered_help = false
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
#complete_task:talk_to_kevin

{first_meeting:
    ~ first_meeting = false
    #speaker:narrator
    #display:kevin-casual

    A guy in his late 20s sits at a workstation, headphones on, fingers flying across the keyboard.

    He notices you and pulls off his headphones.

    #speaker:kevin_park
    Kevin Park: Hey! You must be the security consultant. Kevin Park, IT sysadmin.

    Kevin Park: Finally someone who might actually fix our mess.

    + [Nice to meet you. What can you tell me about the breach?]
        You: What can you tell me about the data breach?
        ~ kevin_influence += 10
        -> network_situation

    + [I'll need your help with technical access.]
        You: Server logs, network diagrams, that kind of thing.
        Kevin Park: Oh yeah, totally. Whatever you need.
        ~ kevin_influence += 5
        ~ offered_help = true
        -> hub

    + [Just point me to the network logs. I'll take it from here.]
        You: I can take it from here.
        Kevin Park: Sure, terminal's over there. Let me know if you need anything.
        -> hub
}

{not first_meeting:
    #display:kevin-friendly
    Kevin Park: What's up?
    -> hub
}

=== network_situation ===
#speaker:kevin_park

Kevin Park: Yeah, someone's been uploading huge files at like 2 AM.

Kevin Park: At first I thought it was legit remote work, but...

Kevin Park: Pattern's too consistent. Same time every Friday. Same encrypted protocols.

+ [Why didn't you report it earlier?]
    You: Why didn't you report it earlier?
    Kevin Park: I did! Patricia's been investigating for three weeks.
    ~ kevin_influence += 5
    -> hub

+ [That's helpful. Thanks.]
    You: That's helpful. Thanks.
    ~ kevin_influence += 10
    -> hub

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===

+ {not topic_network} [Walk me through the network infrastructure.]
    -> ask_network

+ {not topic_torres} [What's David Torres like?]
    -> ask_torres

+ {not topic_security} [Where are the security gaps?]
    -> ask_security

+ {kevin_influence >= 20 and not badge_cloned} [I need a copy of your badge.]
    -> request_badge_clone

+ {kevin_influence >= 30} [I need a lockpick set.]
    -> request_lockpick

+ [That's everything for now. Catch you later.]
    You: That's everything for now. Catch you later.
    #exit_conversation
    #speaker:kevin_park
    Kevin Park: Cool, catch you later!
    -> DONE

=== ask_network ===
#speaker:kevin_park
~ topic_network = true
~ kevin_influence += 5

Kevin Park: Our network's pretty standard. Corporate VPN, segmented VLANs.

Kevin Park: Server room's locked down - RFID badge access only. I can get you in if you need.

{kevin_influence >= 15:
    Kevin Park: There's a terminal in the server room that logs all network traffic. Super useful.
    ~ kevin_influence += 5
}

-> hub

=== ask_torres ===
#speaker:kevin_park
~ topic_torres = true
~ kevin_influence += 5

Kevin Park: David? He's like, crazy smart. PhD in cryptography.

Kevin Park: Works late a lot. Always stressed. His wife's sick, so...

{kevin_influence >= 20:
    Kevin Park: Saw him in the server room the other night. Just... standing there. Looking exhausted.
    ~ kevin_influence += 10
}

-> hub

=== ask_security ===
#speaker:kevin_park
~ topic_security = true
~ kevin_influence += 5

Kevin Park: Security's... not great. Budget cuts.

Kevin Park: We log access but don't monitor in real-time. PIN codes are weak.

{kevin_influence >= 25:
    Kevin Park: Want a pro tip? Check the server room at night. Some people think the cameras have blind spots.
    Kevin Park: They're right.
    ~ kevin_influence += 5
}

-> hub

=== request_badge_clone ===
#speaker:kevin_park

You: Kevin, I need a favor. I need access to restricted areas.

{kevin_influence >= 30:
    #give_item:keycard:Cloned Employee Badge
    Kevin Park: Say no more. Here's my badge.
    Kevin Park: Just... don't tell Patricia I gave this to you, okay?

    #complete_task:clone_employee_badge
    #unlock_room:server_hallway

    ~ badge_cloned = true
    ~ kevin_influence -= 5

    Kevin Park: Server hallway's all yours now.
    -> hub
- else:
    Kevin Park: Uh... I don't know you well enough for that, man.
    Kevin Park: Talk to me more, build some trust first.
    -> hub
}

=== request_lockpick ===
#speaker:kevin_park

You: Do you have a lockpick kit? For... legitimate security testing.

{kevin_influence >= 40:
    #give_item:lockpick
    Kevin Park: *grins* "Security testing." Right.
    Kevin Park: Actually, yeah. Left over from a pen test last year.

    Kevin Park: Don't tell anyone where you got it.
    ~ kevin_influence += 5
    -> hub
- else:
    Kevin Park: Dude, I barely know you. Ask me when we're cool.
    -> hub
}

// ===========================================
// EVENT-TRIGGERED: Player Found Evidence
// ===========================================

=== on_evidence_discovered ===
#speaker:kevin_park

Kevin Park: Hey, did you find something? You look... intense.

+ [Just following leads]
    You: Nothing concrete yet.
    Kevin Park: Cool, let me know if I can help.
    -> DONE

+ [I think I know who the insider is]
    Kevin Park: Wait, seriously? Who?
    + + [I can't share details yet]
        Kevin Park: Right, right. Classified. Good luck.
        -> DONE
    + + [David Torres]
        Kevin Park: *shocked* David? No way. He wouldn't...
        Kevin Park: *pause* Shit. I should have seen it.
        -> DONE

// ===========================================
// EVENT-TRIGGERED: Mission Complete
// ===========================================

=== on_mission_complete ===
#speaker:kevin_park

Kevin Park: So... is it over?

{torres_turned:
    You: It's resolved. That's all I can say.
    Kevin Park: But David's okay?
    You: He's cooperating. It's complicated.
    Kevin Park: *relieved* Okay. Good.
}

{torres_arrested:
    You: The insider's been arrested.
    {torres_identified:
        Kevin Park: David? Damn. I can't believe it.
        Kevin Park: But... yeah. I guess it makes sense.
    }
}

{torres_killed:
    Kevin Park: I heard... someone died?
    You: Lethal force was necessary.
    Kevin Park: *quiet* Okay. That's... that's heavy.
}

Kevin Park: Thanks for, you know, fixing this.

#exit_conversation
-> DONE
