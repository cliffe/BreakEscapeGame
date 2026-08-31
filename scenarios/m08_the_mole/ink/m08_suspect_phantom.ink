// ================================================
// Mission 8: The Mole - Suspect: Agent 0x88 'Phantom' (RED HERRING, innocent)
// Speaker: Agent 0x88 'Phantom'
// Entry knot: start   Sets: phantom_interviewed
// He's running his own off-book mole hunt. Rewards the player who reads his
// notes (found_phantom_lead) with the Crypto Lab lead -- pointing at Nightshade.
// ================================================

VAR phantom_interviewed = false
VAR phantom_influence = 0
VAR suspect_theory = ""
VAR found_phantom_lead = false
VAR phantom_alibi_known = false
VAR asked_absences = false
VAR asked_alibi = false
VAR asked_list = false
VAR asked_help = false
VAR accused_phantom = false

=== start ===
{ phantom_interviewed:
    Agent 0x88 'Phantom': Back again. Either you've cleared me or you've got nothing. Which is it?
    -> hub
}
Agent 0x88 'Phantom': Agent 0x00. The Director's own bloodhound. Sit. Let me save you the first four questions -- yes I ask too much, yes I disappear for hours, yes I'm on your little list, and yes, I put myself there too. Charmed?
~ phantom_interviewed = true
-> hub

=== hub ===
+ { not asked_absences } [The unlogged absences. Explain them.]
    ~ asked_absences = true
    Agent 0x88 'Phantom': Two of ours are dead and the official investigation is three men staring at each other across a corridor. So I've been off the books, working it myself. Tracking server auth, checking alibis, reading logs I'm not cleared for. That's the absences. I've been doing your job since before you landed.
    ~ phantom_influence += 1
    # influence_increased
    -> hub
+ { not asked_alibi } [Where were you in the leak window?]
    ~ asked_alibi = true
    ~ phantom_alibi_known = true
    Agent 0x88 'Phantom': Airborne. Zurich handover, forty passengers and a flight manifest with my name on it -- the one alibi in this building nobody can fake. Check it. I'll wait. It's the only time I've ever been glad of economy class. #set_global:phantom_alibi_known:true
    -> hub
+ { not asked_list } [Who's on your list?]
    ~ asked_list = true
    Agent 0x88 'Phantom': Same three as yours, minus me. And if you put a gun to it -- the one who never flinches. Money leaves a trail and there is no trail, so it isn't money. It's belief. Ask yourself who in this building has stopped believing we can win.
    ~ phantom_influence += 1
    # influence_increased
    -> hub
+ { found_phantom_lead and not asked_help } [I read your notes. The Crypto Lab terminal.]
    ~ asked_help = true
    Agent 0x88 'Phantom': *leans in, all the charm gone* Then you're further than I got. Someone's been in mission_planning from a Crypto Lab terminal at hours nobody's rostered. I couldn't get root on the repo to prove whose account it was -- that's your part, you've got the Director's blessing and I've got a reprimand pending. Get onto that box. The name's in the logs. I'd bet my pension it's the quiet one.
    ~ phantom_influence += 2
    # influence_increased
    -> hub
+ [I think it's you, Phantom.] -> accuse
+ [We'll talk again.] -> leave

=== accuse ===
~ accused_phantom = true
{ phantom_alibi_known:
    Agent 0x88 'Phantom': *laughs, without warmth* I was thirty thousand feet over France with forty witnesses and you know it, because you're the type who checked. So either you're testing me, or you're lazy, and I don't think you're lazy. Don't waste the one night we've got rattling the wrong man.
    ~ phantom_influence -= 1
    # influence_decreased
- else:
    Agent 0x88 'Phantom': Bold. On what -- a flight manifest you haven't pulled and a vibe? I've been hunting this leak longer than you've known it existed. Accuse me properly or get out of my way and let one of us catch him.
    ~ phantom_influence -= 1
    # influence_decreased
}
-> hub

=== leave ===
{ accused_phantom:
    Agent 0x88 'Phantom': Pull the manifest. Then come and apologise, or come and cuff me. Not both.
- else:
    Agent 0x88 'Phantom': Go and get onto that repo. And when the evidence backs me -- tell the Director I was right to look.
}
#set_global:phantom_interviewed:true #complete_task:interview_phantom
#exit_conversation
-> DONE
