// ===========================================
// m07 The Architect's Gambit -- JAKE MORRISON
// NPC id: jake_morrison   displayName: Jake Morrison
// Room: security_checkpoint. Patrols with an LOS cone.
//
// Facility security guard. Bought, not converted. He renewed Mercer's
// credentials six months ago for money and has spent six months not thinking
// about it. He is the first evidence that ENTROPY had inside help HERE -- the
// small-scale echo of the mole problem the cable vault turns up later.
//
// Three resolutions per CONTRACT.md morrison_resolved: "talked" / "ko" / "evaded".
// Talking is not the soft option. He is armed, cornered and frightened, and
// the only thing that moves him is the visitor log -- and it costs the player
// the arrest.
// ===========================================

VAR morrison_resolved = ""
VAR morrison_ko = false
VAR visitor_log_read = false
VAR badge_obtained = false
VAR team_assigned = false

VAR pressed_once = false
VAR bluff_burned = false

=== start ===
{morrison_ko:
    -> down_and_out
}
{morrison_resolved == "talked":
    -> already_dealt
}
{morrison_resolved == "evaded":
    -> wary_again
}
-> challenge

=== challenge ===
Narrator: He clocks you at ten metres and his hand goes to his belt before his face does anything at all. The torch beam finds your chest and stays there.

Jake Morrison: Building's evacuated. Has been forty minutes. So you're either lost or you're the other thing.

-> hub

=== hub ===
+ [I'm on the contractor list. Check it.]
    -> bluff
+ [The grid goes down in half an hour. You know that.]
    -> stakes
+ {visitor_log_read} [You renewed Mercer's credentials on the ninth. Your login, your signature.]
    -> leverage
+ [I'm not here to fight you, Jake.]
    -> hostile_option
+ [Back off. I'm leaving.]
    -> evade

=== bluff ===
{bluff_burned:
    Jake Morrison: You already tried that one.
    -> hub
}
~ bluff_burned = true
Narrator: He does not look at a list. He does not have a list. He looks at your hands.

Jake Morrison: Contractors came out with everyone else. I walked them out myself.

Jake Morrison: Try again, and stand still while you do it.
-> hub

=== stakes ===
{pressed_once:
    Jake Morrison: I heard you the first time.
    -> hub
}
~ pressed_once = true
Jake Morrison: What I know is my shift ends at six and there's a number in my account that says stand here.

Narrator: It comes out too fast, and he hears it come out, and something behind his eyes goes very still.

Jake Morrison: That's not what I meant.

+ [No. It's exactly what you meant.]
    Jake Morrison: Walk away. Right now. I'm asking.
    -> hub
+ [How much?]
    Jake Morrison: Enough that I can't give it back. That's the whole trick of it, isn't it.
    -> hub

=== leverage ===
Narrator: You say the date. Not the accusation, just the date, and the way it lands tells you everything the log already told you.

Jake Morrison: That log's meant to be on a closed terminal.

You: It was. It isn't now. Federal building, federal record, and your name is on a credential renewal for a man who is upstairs putting eight point four million people in the dark.

Narrator: The torch beam drops to the floor. His hand stays where it is.

Jake Morrison: I renewed a badge. That's all I did. Nobody said anything about the grid.

+ [Nobody ever does. That's what the money is for.]
    -> deal
+ [Then help me and say so to a magistrate.]
    Jake Morrison: I'm not going to a magistrate. Don't ask me that again.
    -> deal

=== deal ===
Jake Morrison: What do you want.

+ [Your badge. Server zone. Then you go, and you keep going.]
    -> deal_take
+ [Your badge, and you wait here for the arrest team.]
    -> deal_refused

=== deal_take ===
Narrator: He unclips the badge with two fingers and holds it out at arm's length, as if it were the part of him that had done it.

Jake Morrison: Six months I've been waiting for somebody to come and ask. Turns out I just wanted the asking over with.

Jake Morrison: There's a printer behind me runs blank contractor stock. You'd have got in either way. I want you to know I know that.

You: Go.

Narrator: He goes out through the muster door and does not look back. Every hour of what he knows walks out with him.

~ morrison_resolved = "talked"
~ badge_obtained = true
#set_global:morrison_resolved:talked
#set_global:badge_obtained:true
#give_item:keycard:server_zone_badge
#complete_task:clear_the_checkpoint
#exit_conversation
-> DONE

=== deal_refused ===
Narrator: The hand comes back up. Not levelled -- just back up, which is worse, because it means he has stopped deciding and started reacting.

Jake Morrison: No. No, I've thought about that room. I'm not sitting in it.

+ [Sit down, Jake.]
    -> hostile_option
+ [Fine. Badge. Then you're gone.]
    -> deal_take

=== hostile_option ===
Narrator: He backs into the turnstile frame with nowhere further to go, which is the exact circumstance in which frightened men make the loudest decision available to them.

Jake Morrison: Stay there. STAY THERE.

+ [Put it down.]
    -> goes_loud
+ [I'm stepping back. Look at me. I'm stepping back.]
    -> evade

=== goes_loud ===
Jake Morrison: I can't afford you. I'm sorry. I genuinely am.

Narrator: He comes off the frame at you.

~ morrison_resolved = "ko"
#set_global:morrison_resolved:ko
#hostile:jake_morrison
#exit_conversation
-> DONE

=== evade ===
Narrator: You give him the corner and the corner gives you the cone. He sweeps the torch across the turnstiles twice, finds an empty checkpoint both times, and settles back into the pattern he has walked for six months.

Jake Morrison: Yeah. Thought so.

~ morrison_resolved = "evaded"
#set_global:morrison_resolved:evaded
#exit_conversation
-> DONE

=== wary_again ===
Narrator: He is halfway along the patrol and jumpier than he was. The torch comes up fast.

Jake Morrison: Something's in here. I know something's in here.

-> hub

=== already_dealt ===
Narrator: The checkpoint is empty. His radio sits on the desk with the battery out beside it.

+ [Move on.]
    #exit_conversation
    -> DONE

=== down_and_out ===
Narrator: He is face down by the turnstiles, breathing, with his badge lanyard cut. Whatever he knew about the ninth of the month is going with him to a hospital, and then to a lawyer.

+ [Leave him.]
    #exit_conversation
    -> DONE
