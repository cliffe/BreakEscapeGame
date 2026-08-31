// ================================================
// Mission 8: The Mole - Closing debrief
// Speaker: Director Magnus Netherton (the familiar SAFETYNET director from m07)
// Entry knot: start   Completes: take_the_debrief
// Branches on fate, the player's own suspicion history, and stance.
// conversation_ended:m08_closing_debrief triggers victory + bond_visualiser.
// ================================================

VAR player_name = "Agent 0x00"
VAR nightshade_arrested = false
VAR nightshade_triple_agent = false
VAR database_theft_understood = false
VAR nightshade_suspected = false
VAR suspect_theory = ""
VAR tomb_gamma_location_known = false
VAR debrief_stance = ""
VAR asked_how = false
VAR asked_database = false
VAR asked_next = false

=== start ===
Narrator: The break room, cleared. Netherton comes in without the tablet this time, which is somehow worse. He looks older than he did at the briefing, and the briefing was only hours ago.

Director Magnus Netherton: It's done, then. Agent 0x47. Nightshade.
Director Magnus Netherton: A year ago Dr Chen put a warning about him on my desk. Ideological drift, she called it. I read it, and I sealed it, because he was the best planner I had and I did not want it to be true. Two of ours are dead in the space between what I knew and what I did. Say it, Agent. Whatever you think of me tonight. I'd rather hear it than watch you swallow it.
-> stance

=== stance ===
+ [You had a warning and a war and no proof. You backed your best officer. He's the crime, not you.]
    ~ debrief_stance = "defended"
    Director Magnus Netherton: Kinder than I would be. I'll carry it regardless -- but thank you for the shape of it. #set_global:debrief_stance:defended
    -> the_hunt
+ [Chen told you in writing. You sealed it. Own the gap, or you'll do it again.]
    ~ debrief_stance = "owned"
    Director Magnus Netherton: *a long beat* ...Yes. I'll put my own name in the report beside his. You were right to make me say it aloud. #set_global:debrief_stance:owned
    -> the_hunt

=== the_hunt ===
{ suspect_theory == "cipher" || suspect_theory == "phantom":
    Director Magnus Netherton: You told me early it was Cipher, or Phantom. You were wrong, and you came back and corrected it -- which is worth more than being right first. Two good officers spent a night under a suspicion they didn't earn. Go and buy them a drink; the service won't do it for you.
- else:
    { nightshade_suspected:
        Director Magnus Netherton: You had him before the evidence did. You sat across a desk from the calmest man in a frightened building and you didn't buy the calm. I read the transcripts. That instinct is the reason you're still useful to me after they burned you.
    - else:
        Director Magnus Netherton: You let the box make the case and kept your own opinion out of it until it was proven. Cold, and correct. It's how the innocent walk out of a mole hunt with their careers intact.
    }
}
-> disposition

=== disposition ===
{ nightshade_triple_agent:
    Director Magnus Netherton: And you've kept him in play. A triple agent.
    Director Magnus Netherton: I approved it, and I want it on the record that I did so with my eyes open. We are now a service that uses a man who trades lives, to save lives. Watch him as you would a live wire, because that is what he is. If he burns you, it is on my signature, not yours.
- else:
    Director Magnus Netherton: Arrest. He stands trial, and a courtroom hears every name he wouldn't. It buys us not one scrap of intelligence and I do not care. Some lines you hold because they are the line, and a service that forgets that becomes the thing it hunts.
}
-> hub

=== hub ===
+ { not asked_how } [How did they get him in the first place, sir?]
    ~ asked_how = true
    Director Magnus Netherton: Training. Fifteen years ago, in your cohort. They took a tired young idealist and they waited. That is what we're up against -- not a break-in, a plantation. Somewhere in this service there may be others, put down like seeds, still years from flowering. I'll be checking soil for the rest of my career.
    -> hub
+ { database_theft_understood and not asked_database } [The database. How bad is it, honestly.]
    ~ asked_database = true
    Director Magnus Netherton: As bad as it gets. Every weakness we have ever catalogued is now theirs. Portland, Austin, all of it -- theatre, to cover the one door Nightshade left open. We didn't lose a battle nine days ago. We handed the enemy the map to every battle still coming.
    -> hub
+ { not asked_next } [Then what now.] -> the_next
+ [Nothing more, sir.] -> close

=== the_next ===
~ asked_next = true
{ tomb_gamma_location_known:
    Director Magnus Netherton: Now we use the one thing tonight bought us. Tomb Gamma. A coordinate in Montana that Nightshade handed you, and the first hard address we've ever had for The Architect's workshop. That is where the database went. That is where this ends, or where we do.
    Director Magnus Netherton: Take your seventy-two hours. Then we go to Montana and we get it back.
- else:
    Director Magnus Netherton: Now we find where the database went. Nightshade knows -- a place he called Tomb Gamma. Go back and get it out of him before the triple-agent paperwork makes him coy, or before a cell does. We are not finished until we have that coordinate.
}
-> hub

=== close ===
Narrator: Netherton stops at the door.
Director Magnus Netherton: They spent fifteen years turning one of ours into a weapon and pointing it at the rest of us. Tonight you turned it back around. Go home, {player_name}. Sleep if the building will let you. #set_global:mission_complete:true #complete_task:take_the_debrief
#exit_conversation
-> DONE
