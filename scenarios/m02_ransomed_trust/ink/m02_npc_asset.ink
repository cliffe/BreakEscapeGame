// ===========================================
// ACT 3 NPC: Night Security Supervisor (ENTROPY Inside Asset)
// Mission 2: Ransomed Trust
// Break Escape - The hidden affiliate. Derek-lite confrontation.
//
// Cover: polite plainclothes supervisor posted on the press terminal.
// Gated reveal: only drops cover once insider_identified is true.
// If the player never identifies him, he ambushes at the press terminal.
// ===========================================

// Synced from globalVars by engine at call-open
VAR insider_identified = false
VAR insider_confronted = false

EXTERNAL player_name()

=== start ===
{insider_confronted:
    -> already_resolved
}
{insider_identified:
    -> confrontation
}
-> cover_friendly

// ===========================================
// COVER STORY (before identification)
// ===========================================

=== cover_friendly ===
#speaker:night_security_supervisor

Supervisor: Evening. You'll be the consultant Dr. Kim called in.

Supervisor: I'm night security -- posted here to keep the sensitive comms secure while the systems are down. Anything you need through this terminal, you come to me first.

-> cover_hub

=== cover_hub ===
+ [What exactly are you guarding?]
    -> cover_guarding
+ [Why plainclothes, not a uniform?]
    -> cover_plainclothes
+ [Nothing for now]
    #speaker:night_security_supervisor
    Supervisor: Of course. I'll be right here if you need me. Save those patients.
    #exit_conversation
    -> DONE

=== cover_guarding ===
#speaker:night_security_supervisor
Supervisor: The comms relay, mostly. In a crisis like this, the last thing the hospital needs is someone leaking half a story to the press.

Supervisor: I make sure only the right information leaves this room.
-> cover_hub

=== cover_plainclothes ===
#speaker:night_security_supervisor
Supervisor: Crisis protocol. A uniform draws attention. Plainclothes keeps things calm.

Supervisor: I've had this post since the summer. I know this building better than most of the staff do.
-> cover_hub

// ===========================================
// CONFRONTATION (Derek-lite) -- insider_identified true
// ===========================================

=== confrontation ===
#speaker:narrator
Narrator: You stop in front of him and say the badge number aloud. SC-4471. The fire drill six weeks ago. The device on the LAN.

#speaker:narrator
Narrator: The courteous smile doesn't fall so much as switch off.

#speaker:night_security_supervisor
Supervisor: So you did the work. Good. I'd have been disappointed otherwise.

Supervisor: You want to know why. They all want to know why.

* [You opened the door for Ghost. Patients on life support paid for it.]
    -> monologue_1
* [You had a good post here. Why throw it away for them?]
    -> monologue_1

=== monologue_1 ===
#speaker:night_security_supervisor
Supervisor: A career. Eleven years of nights on this post. Do you know what they pay a night supervisor to hold a building full of dying people together?

Supervisor: Less than the board spent catering the meeting where they cut Marcus Webb's security budget.

Supervisor: I watched them choose an MRI over the servers keeping those wards alive. I raised it. I was told to mind my post.

* [Feeling ignored doesn't justify handing them the keys.]
    -> monologue_2
* [And then someone from ENTROPY came along and listened.]
    -> monologue_2

=== monologue_2 ===
#speaker:night_security_supervisor
Supervisor: They didn't recruit me. They agreed with me. There's a difference.

Supervisor: All I did was confirm a timing window and wave a contractor through a fire drill. The negligence was already here. I just stopped it being invisible.

Supervisor: They deferred the fix for six months. I made them face the bill. Tell me which of us actually endangered those patients.

#speaker:narrator
Narrator: His hand rests, quite deliberately, near the lanyard at his collar.

-> confrontation_choice

// ===========================================
// FOCUSED CHOICE
// ===========================================

=== confrontation_choice ===
#speaker:night_security_supervisor
Supervisor: So. You've found me. What happens now is your call, agent.

+ [Quietly. You're under arrest. SAFETYNET has you.]
    ~ insider_confronted = true
    -> choice_arrest
+ [You go public with the rest of them. Name and all.]
    ~ insider_confronted = true
    -> choice_expose
+ [I'm not doing the talking. SAFETYNET takes you in.]
    ~ insider_confronted = true
    -> choice_handover
+ [You don't get to walk out of here.] #color:red
    ~ insider_confronted = true
    -> choice_hostile

=== choice_arrest ===
#speaker:night_security_supervisor
Supervisor: No fuss. Good. I told them a fuss was beneath the point.

You: The point was patients on backup power.

Supervisor: The point was that no one would ever ignore this again. You'll see. Give it a year.

#speaker:narrator
Narrator: He offers his wrists without being asked. Whatever he believes, he came prepared to be caught.

#set_global:insider_confronted:true
#set_global:insider_asset_arrested:true
#exit_conversation
-> DONE

=== choice_expose ===
#speaker:night_security_supervisor
Supervisor: Publish it? Then publish all of it. My name next to the board's. That's the only version of this I'll sign.

You: You'll get your name in it. Alongside the people you helped.

Supervisor: Good. Let them argue about which of us was worse.

#speaker:narrator
Narrator: You log his identity into the SAFETYNET evidence package. He does not resist as backup takes position at the door.

#set_global:insider_confronted:true
#set_global:insider_asset_arrested:true
#set_global:insider_asset_exposed:true
#exit_conversation
-> DONE

=== choice_handover ===
#speaker:night_security_supervisor
Supervisor: Straight to the agency. Cleaner that way. Fewer chances for either of us to say something we mean.

#speaker:narrator
Narrator: You signal SAFETYNET. The supervisor sits, folds his hands, and waits -- calm as a man who thinks he has already won the argument.

#set_global:insider_confronted:true
#set_global:insider_asset_arrested:true
#exit_conversation
-> DONE

=== choice_hostile ===
#speaker:night_security_supervisor
Supervisor: *steps back from the terminal* Then we're past talking.

You: We were past talking the moment you let them in.

Supervisor: Everyone always is. Right up until the lights go out.

#hostile:night_security_supervisor
#set_global:insider_confronted:true
#set_global:insider_hostile:true
#set_global:insider_asset_arrested:true
#exit_conversation
-> DONE

// ===========================================
// PRESS-TERMINAL AMBUSH (insider never identified)
// Fires from eventMapping when decide_hospital_exposure completes
// ===========================================

=== press_terminal_ambush ===
#speaker:narrator
Narrator: As your transmission clears the relay, the courteous supervisor steps between you and the terminal. The warmth is gone from his face.

#speaker:night_security_supervisor
Supervisor: I'm sorry. I can't let you leave here thinking that was just careless budgeting.

You: Who are you?

Supervisor: The one who made sure it happened on schedule. Badge SC-4471. Six weeks ago. A fire drill nobody scheduled.

#speaker:narrator
Narrator: The realisation lands a half-second too late. He is already moving.

#speaker:night_security_supervisor
Supervisor: You should have looked harder.

#hostile:night_security_supervisor
#set_global:insider_confronted:true
#set_global:insider_hostile:true
#set_global:insider_asset_escaped:true
#exit_conversation
-> DONE

// ===========================================
// ALREADY RESOLVED
// ===========================================

=== already_resolved ===
#speaker:narrator
Narrator: The supervisor's post is empty now. There is nothing more to say to him.
#exit_conversation
-> DONE
