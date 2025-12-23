// ===========================================
// SECURITY GUARD NPC - Mission 2: Ransomed Trust
// Break Escape - St. Catherine's Hospital
// ===========================================
// Interactive guard with multiple confrontation options
// Based on security-guard.ink with M2-specific context
// ===========================================

// Variables for tracking player choices and state
VAR influence = 0
VAR caught_lockpicking = false
VAR confrontation_attempts = 0
VAR warned_player = false
VAR player_attacked_guard = false
VAR guard_knocked_out = false
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
    You see a hospital security guard patrolling the corridor. They're watching the area carefully.

    The guard notices you and approaches.

    ~ warned_player = true
    Guard: Hold on. This is a restricted area during the crisis. What's your business here?

    -> initial_response
}

{warned_player and not caught_lockpicking and not guard_knocked_out:
    #display:guard-patrol
    The guard nods at you as they continue their patrol.

    Guard: Still working on the crisis?

    -> hub
}

{guard_knocked_out:
    #display:guard-unconscious
    The security guard is unconscious on the floor. You should move quickly before they wake up.

    #exit_conversation
    -> DONE
}

-> hub

// ===========================================
// INITIAL RESPONSE OPTIONS
// ===========================================

=== initial_response ===

+ [I'm the security consultant Dr. Kim called in]
    ~ influence += 20
    You: I'm the external security consultant. Dr. Kim authorized my access.

    Guard: Oh, right. The ransomware crisis. Dr. Kim mentioned someone was coming.

    Guard: Still, I need to see your visitor badge.

    {player_has_id_badge:
        You show the visitor badge from reception.

        ~ influence += 10
        Guard: Checks out. Be careful in there. It's a mess.

        -> hub
    - else:
        You: I... must have left it at reception.

        ~ influence -= 5
        Guard: Then go get it. Security protocols exist for a reason.

        -> hub
    }

+ [Just passing through, officer]
    You: Just passing through. No trouble.

    Guard: During a ransomware crisis? Nothing is "just passing through" right now.

    -> hub

+ [Emergency - I need to access the server room]
    ~ influence += 5
    You: This is urgent. The hospital systems are down. Lives are at stake.

    Guard: I know. That's why I'm here securing this area.

    Guard: You need proper authorization to access restricted systems.

    -> hub

+ [None of your business]
    ~ influence -= 30
    You: That's not your concern.

    Guard: Wrong answer. Everything in this corridor is my concern.

    #display:guard-hostile
    -> hostile_stance

// ===========================================
// HUB - MAIN CONVERSATION LOOP
// ===========================================

=== hub ===

+ [Ask about the ransomware attack]
    -> ask_about_attack

+ [Request access to restricted areas]
    -> request_access

+ {caught_lockpicking} [Explain the lockpicking situation]
    -> explain_lockpick_again

+ [End conversation]
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

    * [Try to physically overpower the guard]
        -> attempt_fight
}

{confrontation_attempts > 1:
    Guard: I ALREADY TOLD YOU TO STOP!

    Guard: This is your FINAL warning before I call backup!

    * [Okay, I'm leaving right now]
        -> back_down

    * [You don't understand the stakes here]
        -> escalate_conflict

    * [Attack the guard before they call backup]
        -> attempt_fight
}

// ===========================================
// LOCKPICK CONFRONTATION RESPONSES
// ===========================================

=== claim_authorization ===
#speaker:security_guard

{influence >= 30:
    ~ influence -= 10
    Guard: Dr. Kim authorized lockpicking? That's... unusual.

    Guard: Fine. But if she didn't, you're in deep trouble.

    #display:guard-skeptical
    -> hub
}

{influence < 30:
    ~ influence -= 20
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
    Guard: Patient data? In a locked storage room?

    Guard: Look, I get the emergency, but protocol is protocol.

    Guard: Get proper authorization or I can't let this slide.

    #display:guard-concerned
    -> hub
}

{influence < 25:
    ~ influence -= 15
    Guard: Nice try. Security breach is security breach, crisis or not.

    Guard: Backup is on the way.

    #display:guard-alert
    #exit_conversation
    -> DONE
}

=== poor_excuse ===
#speaker:security_guard
~ influence -= 15

Guard: Looking for something you dropped? With lockpicks?

Guard: That's the weakest excuse I've heard all week.

#display:guard-annoyed
-> hub

=== claim_audit ===
#speaker:security_guard

{influence >= 40:
    ~ influence -= 5
    Guard: Security audit during a ransomware crisis? Bold timing.

    Guard: You better have documentation for this.

    #display:guard-neutral
    -> hub
}

{influence < 40:
    ~ influence -= 25
    Guard: An audit would be scheduled with security. This isn't official.

    Guard: You're coming with me to speak with my supervisor.

    #display:guard-arrest
    #exit_conversation
    -> DONE
}

// ===========================================
// HOSTILE/COMBAT RESPONSES
// ===========================================

=== hostile_response ===
#speaker:security_guard
~ influence -= 30

Guard: More important than hospital security? You just crossed a line.

Guard: SECURITY! CODE VIOLATION IN ADMINISTRATIVE WING!

#display:guard-aggressive
#hostile:security_guard
#exit_conversation
-> DONE

=== escalate_conflict ===
#speaker:security_guard
~ influence -= 40

Guard: The stakes? You're breaking hospital protocol during an emergency!

Guard: LOCKDOWN! INTRUDER ALERT!

#display:guard-alarm
#hostile:security_guard
#exit_conversation
-> DONE

=== attempt_fight ===
#speaker:security_guard

Guard: You're really going to attack a security officer?!

You lunge at the guard, trying to knock them out before they can call for backup.

* [Go for a quick knockout punch]
    -> fight_punch

* [Try to wrestle them to the ground]
    -> fight_wrestle

* [Use a nearby object as a weapon]
    -> fight_improvise

* [Actually, back down from this]
    -> fight_backdown

=== fight_punch ===
You swing at the guard's jaw.

{influence >= 20:
    Your punch connects! The guard staggers backward, dazed.

    The guard slumps against the wall, unconscious.

    ~ guard_knocked_out = true
    ~ player_attacked_guard = true
    #display:guard-unconscious
    #complete_task:neutralize_guard
    #set_global:attacked_guard:true

    You have a limited window before they wake up or someone finds them.

    #exit_conversation
    -> DONE
}

{influence < 20:
    The guard blocks your punch and counters with a baton strike!

    You fall back, stunned. The guard radios for backup.

    Guard: ASSAULT ON SECURITY! BACKUP NEEDED NOW!

    ~ player_attacked_guard = true
    #display:guard-combat
    #hostile:security_guard
    #take_damage:moderate
    #mission_failed:attacked_security
    #exit_conversation
    -> DONE
}

=== fight_wrestle ===
You attempt to tackle the guard and pin them down.

{influence >= 15:
    You manage to get the guard in a headlock. They struggle but can't break free.

    After a few seconds, the guard goes limp - unconscious.

    ~ guard_knocked_out = true
    ~ player_attacked_guard = true
    #display:guard-unconscious
    #complete_task:neutralize_guard
    #set_global:attacked_guard:true

    Move quickly. You only have a few minutes.

    #exit_conversation
    -> DONE
}

{influence < 15:
    The guard is stronger than you expected!

    They break your grip and shove you hard against the wall.

    Guard: ASSAULT! SECURITY BREACH! ALL UNITS TO ADMINISTRATIVE WING!

    ~ player_attacked_guard = true
    #display:guard-combat
    #hostile:security_guard
    #take_damage:moderate
    #mission_failed:attacked_security
    #exit_conversation
    -> DONE
}

=== fight_improvise ===
You grab a fire extinguisher from the wall mount.

{influence >= 25:
    You swing the extinguisher and connect with the guard's shoulder.

    The guard drops to one knee, stunned. A second swing knocks them out cold.

    ~ guard_knocked_out = true
    ~ player_attacked_guard = true
    #display:guard-unconscious
    #complete_task:neutralize_guard
    #set_global:attacked_guard:true
    #give_item:fire_extinguisher

    The guard is unconscious. Work fast.

    #exit_conversation
    -> DONE
}

{influence < 25:
    The guard sees you reaching for the extinguisher and draws their baton!

    They strike your arm hard before you can swing. The extinguisher clatters to the floor.

    Guard: ARMED ASSAULT! REPEAT - ARMED ASSAULT!

    ~ player_attacked_guard = true
    #display:guard-combat
    #hostile:security_guard
    #take_damage:severe
    #mission_failed:attacked_security
    #exit_conversation
    -> DONE
}

=== fight_backdown ===
You raise your hands and step back.

~ influence -= 10

You: Wait, wait. I'm not going to fight you.

Guard: Smart choice. Now get out of here before I change my mind about calling this in.

#display:guard-wary
#exit_conversation
-> DONE

// ===========================================
// DE-ESCALATION
// ===========================================

=== back_down ===
#speaker:security_guard

{influence >= 15:
    ~ influence -= 5
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
#display:guard-annoyed
-> hub

// ===========================================
// HOSTILE STANCE (AFTER AGGRESSIVE RESPONSE)
// ===========================================

=== hostile_stance ===
#speaker:security_guard

Guard: I don't like your attitude. You're on thin ice.

* [Apologize and explain you're stressed]
    ~ influence += 10
    You: Sorry. This crisis has me on edge. I'm just trying to help.

    Guard: Fine. We're all stressed. But watch your tone.

    #display:guard-neutral
    -> hub

* [Double down on hostility]
    You: I don't have time for this security theater.

    Guard: That's it. You're leaving. NOW.

    #hostile:security_guard
    #exit_conversation
    -> DONE

* [Try to physically intimidate the guard]
    -> attempt_fight
