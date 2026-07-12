// ===========================================
// SECURITY GUARD NPC - Mission 2: Ransomed Trust
// Break Escape - St. Catherine's Hospital
//
// Talk / persuade / react-to-lockpicking only.
// Physical combat is NOT scripted here: aggression sets the guard hostile
// via #hostile:security_guard and hands control to the game's combat system.
// Scene description and action beats are spoken by the Narrator.
// ===========================================

// Variables for tracking player choices and state
VAR influence = 0
VAR caught_lockpicking = false
VAR confrontation_attempts = 0
VAR warned_player = false
VAR player_has_id_badge = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// INITIAL ENCOUNTER
// ===========================================

=== start ===
#speaker:security_guard

{not warned_player:
    #display:guard-patrol
    #speaker:narrator
    Narrator: A hospital security guard patrols the north corridor, watching the area carefully. They notice you and approach.

    ~ warned_player = true
    #speaker:security_guard
    Guard: Hold on. This is a restricted area during the crisis. What's your business here?

    -> initial_response
}

{warned_player and not caught_lockpicking:
    #display:guard-patrol
    #speaker:narrator
    Narrator: The guard nods at you as they continue their patrol.

    #speaker:security_guard
    Guard: Still working on the crisis?

    -> hub
}

-> hub

// ===========================================
// INITIAL RESPONSE OPTIONS
// ===========================================

=== initial_response ===

+ [I'm the external security consultant. Dr. Kim authorized my access.]
    ~ influence += 20
    # influence_increased
    Guard: Oh, right. The ransomware crisis. Dr. Kim mentioned someone was coming.

    Guard: Still, I need to see your visitor badge.

    {player_has_id_badge:
        #speaker:narrator
        Narrator: You show the visitor badge from reception.

        ~ influence += 10
        # influence_increased
        #speaker:security_guard
        Guard: Checks out. Be careful in there. It's a mess.

        -> hub
    - else:
        You: I... must have left it at reception.

        ~ influence -= 5
        # influence_decreased
        Guard: Then go get it. Security protocols exist for a reason.

        -> hub
    }

+ [Just passing through. No trouble.]
    Guard: During a ransomware crisis? Nothing is "just passing through" right now.

    -> hub

+ [This is urgent. The hospital systems are down. Lives are at stake.]
    ~ influence += 5
    # influence_increased
    Guard: I know. That's why I'm here securing this area.

    Guard: You need proper authorization to access restricted systems.

    -> hub

+ [That's not your concern.]
    ~ influence -= 30
    # influence_decreased
    Guard: Wrong answer. Everything in this corridor is my concern.

    #display:guard-hostile
    -> hostile_stance

// ===========================================
// HUB - MAIN CONVERSATION LOOP
// ===========================================

=== hub ===

+ [What can you tell me about the ransomware attack?]
    -> ask_about_attack

+ [I need access to the restricted areas.]
    -> request_access

+ {caught_lockpicking} [About that lockpicking...]
    -> explain_lockpick_again

+ [I should get moving.]
    #exit_conversation
    Guard: Stay safe. This crisis has everyone on edge.
    -> DONE

// ===========================================
// LOCKPICK DETECTION EVENT
// ===========================================

=== on_lockpick_used ===
#speaker:security_guard

{caught_lockpicking < 1:
    ~ caught_lockpicking = true
    ~ confrontation_attempts = 0
}

~ confrontation_attempts++
#display:guard-confrontation

{confrontation_attempts == 1:
    Guard: HEY! What the hell are you doing with those lockpicks?!

    Guard: Step away from that door RIGHT NOW!

    * [I have authorization from Dr. Kim!]
        -> claim_authorization

    * [I'm trying to recover critical patient data!]
        -> explain_emergency

    * [I was just... looking for something I dropped]
        -> poor_excuse

    * [This is official security testing]
        -> claim_audit

    * [Back off - this is more important than you know]
        -> hostile_response
}

{confrontation_attempts > 1:
    Guard: I ALREADY TOLD YOU TO STOP!

    Guard: This is your FINAL warning before I call backup!

    * [Okay, I'm backing away]
        -> back_down

    * [You don't understand the stakes here]
        -> escalate_conflict
}

// ===========================================
// LOCKPICK CONFRONTATION RESPONSES
// ===========================================

=== claim_authorization ===
#speaker:security_guard

{influence >= 30:
    ~ influence -= 10
    # influence_decreased
    Guard: Dr. Kim authorized lockpicking? That's... unusual.

    Guard: Fine. But if she didn't, you're in deep trouble.

    #display:guard-skeptical
    -> hub
}

{influence < 30:
    ~ influence -= 20
    # influence_decreased
    Guard: Authorization doesn't mean breaking into rooms! Where's your paperwork?

    Guard: Move along before this gets reported.

    #display:guard-hostile
    #exit_conversation
    -> DONE
}

=== explain_emergency ===
#speaker:security_guard

{influence >= 25:
    ~ influence -= 5
    # influence_decreased
    Guard: Patient data? In a locked room?

    Guard: Look, I get the emergency, but protocol is protocol.

    Guard: Get proper authorization or I can't let this slide.

    #display:guard-concerned
    -> hub
}

{influence < 25:
    ~ influence -= 15
    # influence_decreased
    Guard: Nice try. Security breach is security breach, crisis or not.

    Guard: Backup is on the way.

    #display:guard-alert
    #exit_conversation
    -> DONE
}

=== poor_excuse ===
#speaker:security_guard
~ influence -= 15
# influence_decreased
Guard: Looking for something you dropped? With lockpicks?

Guard: That's the weakest excuse I've heard all week.

#display:guard-annoyed
-> hub

=== claim_audit ===
#speaker:security_guard

{influence >= 40:
    ~ influence -= 5
    # influence_decreased
    Guard: Security audit during a ransomware crisis? Bold timing.

    Guard: You better have documentation for this.

    #display:guard-neutral
    -> hub
}

{influence < 40:
    ~ influence -= 25
    # influence_decreased
    Guard: An audit would be scheduled with security. This isn't official.

    Guard: You're coming with me to speak with my supervisor.

    #display:guard-arrest
    #exit_conversation
    -> DONE
}

// ===========================================
// HOSTILE RESPONSES
// Aggression hands control to the combat system via #hostile.
// No fighting is scripted in ink.
// ===========================================

=== hostile_response ===
#speaker:security_guard
~ influence -= 30
# influence_decreased
Guard: More important than hospital security? You just crossed a line.

Guard: SECURITY! CODE VIOLATION IN THE ADMINISTRATIVE WING!

#display:guard-aggressive
#hostile:security_guard
#exit_conversation
-> DONE

=== escalate_conflict ===
#speaker:security_guard
~ influence -= 40
# influence_decreased
Guard: The stakes? You're breaking hospital protocol during an emergency!

Guard: LOCKDOWN! INTRUDER ALERT!

#display:guard-alarm
#hostile:security_guard
#exit_conversation
-> DONE

// ===========================================
// DE-ESCALATION
// ===========================================

=== back_down ===
#speaker:security_guard

{influence >= 15:
    ~ influence -= 5
    # influence_decreased
    Guard: Smart move. Now get out of this wing and don't come back without authorization.

    #display:guard-neutral
    #exit_conversation
    -> DONE
}

{influence < 15:
    Guard: Good thinking. But I've got your description documented now.

    Guard: One more incident and you're banned from the facility.

    #display:guard-watchful
    #exit_conversation
    -> DONE
}

// ===========================================
// GENERAL CONVERSATION
// ===========================================

=== ask_about_attack ===
#speaker:security_guard

Guard: The ransomware? It's bad. Really bad.

Guard: 47 patients on life support. Backup power for maybe 12 hours.

Guard: IT says someone exploited our backup server. We're locked out of everything.

~ influence += 5
# influence_increased
+ [Did anyone see suspicious activity?]
    Guard: Marcus in IT was warning about security issues for months.

    Guard: Management ignored him. Now look where we are.

    -> hub

+ [What's your job during the crisis?]
    Guard: Secure critical areas. Make sure nobody makes things worse.

    Guard: And prevent anyone from... tampering with evidence, if you know what I mean.

    -> hub

+ [Thanks for the info]
    -> hub

=== request_access ===
#speaker:security_guard

{influence >= 50:
    Guard: Access to where? The server room?

    Guard: That's locked down. Only Dr. Kim or Marcus can authorize that.

    -> hub
}

{influence >= 30:
    Guard: You need proper credentials for restricted areas.

    Guard: Talk to Dr. Kim or IT if you have legitimate business.

    -> hub
}

{influence < 30:
    Guard: Access? Not without authorization from administration.

    #display:guard-skeptical
    -> hub
}

=== explain_lockpick_again ===
#speaker:security_guard

Guard: We already discussed this. No lockpicking without authorization.

Guard: I'm being patient because of the crisis, but don't push it.

~ influence -= 5
# influence_decreased#display:guard-annoyed
-> hub

// ===========================================
// HOSTILE STANCE (AFTER AGGRESSIVE RESPONSE)
// ===========================================

=== hostile_stance ===
#speaker:security_guard

Guard: I don't like your attitude. You're on thin ice.

* [Sorry. This crisis has me on edge. I'm just trying to help.]
    ~ influence += 10
    # influence_increased
    Guard: Fine. We're all stressed. But watch your tone.

    #display:guard-neutral
    -> hub

* [I don't have time for this security theater.]
    Guard: That's it. You're leaving. NOW.

    #display:guard-aggressive
    #hostile:security_guard
    #exit_conversation
    -> DONE

// ===========================================
// SERVER ROOM ACCESS EVENT
// ===========================================

=== on_server_room_access ===
#speaker:security_guard

Guard: Hey! Server room access -- that's restricted to authorised IT personnel only.

* [Security consultant. Dr. Kim authorised full access. I have the badge right here.]
    Guard: ...fine. But I'm logging this. Stay visible.
    #exit_conversation
    -> DONE

* [I've been all over this building tonight. Dr. Kim's orders. Crisis response.]
    Guard: Yeah, well. I'm watching.
    #exit_conversation
    -> DONE

* [Say nothing, walk past]
    ~ influence -= 10
    # influence_decreased
    Guard: Hey! I said restricted! Don't make me follow you in there.
    #exit_conversation
    -> DONE
