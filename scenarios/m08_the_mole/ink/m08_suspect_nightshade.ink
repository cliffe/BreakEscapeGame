// ================================================
// Mission 8: The Mole - Suspect: Agent 0x47 'Nightshade' (THE MOLE, pre-reveal)
// Speaker: Agent 0x47 'Nightshade'
// Entry knot: start   Sets: nightshade_interviewed
// The tell is that nothing rattles him. Warm, not sinister. An attentive player
// leaves suspicious (nightshade_suspected); accusing him early gets a graceful,
// chilling deflection -- never a confession. The box makes the case, not this.
// ================================================

VAR nightshade_interviewed = false
VAR nightshade_influence = 0
VAR nightshade_suspected = false
VAR found_nightshade_profile = false
VAR asked_alibi = false
VAR asked_fear = false
VAR asked_dead = false
VAR asked_training = false
VAR accused_nightshade = false

=== start ===
{ nightshade_interviewed:
    Agent 0x47 'Nightshade': Back so soon. You must be enjoying my company, or getting nowhere. I hope it's the first.
    -> hub
}
Narrator: The cryptography lab is quiet in a way the rest of the building is not. Nightshade looks up from a desk with nothing on it -- no photographs, no mug, no clutter -- and smiles like the last nine days never happened.

Agent 0x47 'Nightshade': There you are. I wondered when they'd send you. Of everyone in this building, they picked the one person who knows my tells. That's either a compliment or very poor planning. Sit. Ask me anything.
~ nightshade_interviewed = true
-> hub

=== hub ===
+ { not asked_alibi } [Where were you when the plan leaked?]
    ~ asked_alibi = true
    Agent 0x47 'Nightshade': Here, most likely. I'm always here. Pull the terminal logs -- I'd genuinely encourage it. Nothing clears a person like the truth, properly examined. And nothing convicts them like it either, of course, but I try not to dwell on the second half.
    Narrator: He offers it without a flicker. In a building where everyone else is shaking, he is a still pond.
    -> hub
+ { not asked_fear } [Everyone here is terrified. You're not.]
    ~ asked_fear = true
    ~ nightshade_suspected = true
    Agent 0x47 'Nightshade': Should I be? Fear is what you feel when the outcome is still uncertain. I made my peace with most outcomes a long time ago. It's a discipline. I could teach it to you -- though I don't think we're going to have the time. #set_global:nightshade_suspected:true
    Narrator: You file that away. It is the first genuinely strange thing anyone has said to you tonight.
    -> hub
+ { not asked_dead } [Two of ours are dead.]
    ~ asked_dead = true
    ~ nightshade_suspected = true
    Agent 0x47 'Nightshade': *quietly* I know. I do know that. Don't mistake my calm for not caring -- it's the opposite. It's what caring costs, once you've decided the ship is going down and the only question left is how kind you can be on the way. #set_global:nightshade_suspected:true
    Narrator: It is the right sentiment, delivered a half-second too smoothly, like a line rehearsed alone in the dark.
    -> hub
+ { found_nightshade_profile and not asked_training } [Dr Chen flagged you a year ago. "Entropy is inevitable."]
    ~ asked_training = true
    ~ nightshade_suspected = true
    Agent 0x47 'Nightshade': *the smile holds, but something behind it goes cold* You've been in the Director's safe. Good. Then you know Chen was right, and you know he buried it. Yes, I said those words. I say a great many true things and nobody minds until the day they do.
    Agent 0x47 'Nightshade': Careful, 0x00. You're close to something now. Closer than is comfortable for either of us. #set_global:nightshade_suspected:true
    ~ nightshade_influence -= 1
    # influence_decreased
    -> hub
+ [I think it's you, Nightshade.] -> accuse
+ [We're done here.] -> leave

=== accuse ===
~ accused_nightshade = true
~ nightshade_suspected = true
Agent 0x47 'Nightshade': *he doesn't blink* Do you. On instinct, or on evidence? Because I know you, and I know which one you're running on, and it isn't evidence yet.
Agent 0x47 'Nightshade': Here's what will happen. You'll leave, because you have to -- a hunch won't hold me. And I'll still be here when you come back, because I've nowhere I'd rather be and nothing I'm afraid of. Go and get your proof. I'd honestly rather you found me than guessed me.
Narrator: It is the calmest denial you have ever heard, and it convinces you of nothing except that you are right.
#set_global:nightshade_suspected:true
-> hub

=== leave ===
{ accused_nightshade:
    Agent 0x47 'Nightshade': Bring proof next time. It's the only thing worth bringing.
- else:
    Agent 0x47 'Nightshade': Come back when you can prove something. I'll be right here. I always am.
}
#set_global:nightshade_interviewed:true #complete_task:interview_nightshade
#exit_conversation
-> DONE
