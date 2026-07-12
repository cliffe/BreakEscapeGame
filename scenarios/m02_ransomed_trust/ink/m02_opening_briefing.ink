// ===========================================
// ACT 1: OPENING BRIEFING
// Mission 2: Ransomed Trust
// Break Escape - ENTROPY Cell: Ransomware Incorporated
//
// Structure: cold-open hook + stakes, then a question-hub so the player can
// pull the threads (why we know it's ENTROPY, the ZDS exploit supply chain,
// the ransomware cell, the human stakes) in any order without missing content.
// Different questions reveal different intel -- a legitimate briefing
// consequence -- but nothing here carries into the debrief, which is driven by
// what the player actually DOES in the mission. (No influence var: this is a
// handler cutscene, gated on knowledge flags, not on rapport.)
// ===========================================

// What the player has asked about -- gates the closing lines of the briefing.
VAR knows_stakes = false
VAR knows_entropy_link = false
VAR asked_zds = false
VAR asked_ransomware = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// COLD OPEN
// ===========================================

=== start ===
#speaker:agent_0x99

Agent HaX: {player_name()}. I'll be quick -- a hospital doesn't have the patience for me to be slow.

Agent HaX: St. Catherine's Regional went dark at 02:47 this morning. Every clinical system encrypted in the same minute. Patient monitoring, medication records, imaging -- all of it sitting behind a ransom screen.

Agent HaX: Forty-seven people are on life support in there right now, running on backup generators. Twelve hours of power. Less, if anything trips. After that, the machines keeping them breathing start going quiet.

* [Who did this?]
    -> briefing_hub

* [Why is SAFETYNET on a ransomware call? Isn't this one for the police?]
    -> why_us

* [Then we shouldn't be standing here. What do you need?]
    -> briefing_hub

// ===========================================
// WHY SAFETYNET / THE ENTROPY LINK
// ===========================================

=== why_us ===
#speaker:agent_0x99

Agent HaX: Normally? You'd be right. The police work a hospital ransomware case most weeks. This one landed on our desk because of what you pulled out of Viral Dynamics last time.

Agent HaX: Derek Lawson's outfit. Social Fabric. The intelligence from that op didn't just burn his cell -- it gave us the first real map of how ENTROPY's cells trade with each other. Who builds what. Who buys from whom.

Agent HaX: One line in that material matches this attack almost exactly. So no. This isn't ordinary crime. This is them.

~ knows_entropy_link = true
-> briefing_hub

// ===========================================
// QUESTION HUB
// ===========================================

=== briefing_hub ===
#speaker:agent_0x99
{briefing_hub > 1: Agent HaX: Any other questions?}

+ {not knows_entropy_link} [How can you be sure this is ENTROPY and not some ordinary crew?]
    -> q_entropy_link

+ {not asked_zds} [You said the cells trade with each other. Trade what, exactly?]
    -> q_zds

+ {not asked_ransomware} [So who actually pulled the trigger on this?]
    -> q_ransomware

+ {not knows_stakes} [Walk me through the stakes. What happens if I'm too slow?]
    -> q_stakes

+ [Enough background. Give me my objectives.]
    -> mission_objectives

=== q_entropy_link ===
#speaker:agent_0x99
~ knows_entropy_link = true

Agent HaX: Two things. First, the note in Derek's material -- Social Fabric was cataloguing the other cells, and one entry describes this playbook: exploit a neglected system, encrypt everything, squeeze a public service that can't afford downtime.

Agent HaX: Second, the ransom note itself. Same signature we flagged in that intelligence. It's not the usual pay-or-else. It's clinical. Written like a business invoice. That is a tell.

Agent HaX: ENTROPY doesn't do this for money alone. They do it to prove a point -- that everything you rely on is one unpatched box away from collapse. This is a lesson, and the patients are the chalkboard.

-> briefing_hub

=== q_zds ===
#speaker:agent_0x99
~ asked_zds = true

Agent HaX: Exploits, mostly. The Zero Day Syndicate -- that's the name they trade under, and it was all through Derek's notes. ENTROPY's arms shop. Their whole business is finding and weaponising software flaws, then selling them on to whoever's paying.

Agent HaX: They didn't need anything clever here. St. Catherine's backup server is running software that's been known-vulnerable for years. A public advisory, a patch available the whole time. Nobody applied it.

Agent HaX: That's the ugly truth of it. Half the NHS is holding critical systems together with software this old. ENTROPY isn't breaking down the door -- the Syndicate just noticed it was never locked, and sold the address on.

-> briefing_hub

=== q_ransomware ===
#speaker:agent_0x99
~ asked_ransomware = true

Agent HaX: A cell we hadn't confirmed until now -- but Derek's notes named them. Ransomware Incorporated. And they run exactly like the name says. Like a company. Professional ransom notes, a payment portal, even "support" for victims who get stuck paying.

Agent HaX: They buy the way in from the Syndicate, then they specialise in the part that hurts -- hospitals, councils, anyone who'll pay fast because the alternative is unthinkable.

Agent HaX: The operative on the ground goes by Ghost. Cold. Methodical. Runs the numbers on how many people die at each hour of downtime and prices the ransom against it. Part of your job today is confirming this cell is real -- and everything you find in there that ties it back to the Syndicate is gold to us.

-> briefing_hub

=== q_stakes ===
#speaker:agent_0x99
~ knows_stakes = true

Agent HaX: Two clocks, and they're both bad. The generators give you twelve hours before life support starts failing. And the hospital board votes on paying the ransom in about four.

Agent HaX: If they pay, the systems come back fast -- and ENTROPY walks away eighty-seven thousand richer, funding the next hospital, the next council. If they refuse and you don't get those systems back in time, people die on the ward.

Agent HaX: Your job is to take that choice off the table. Recover the decryption keys yourself, and nobody has to decide between their patients and their principles.

-> briefing_hub

// ===========================================
// MISSION OBJECTIVES
// ===========================================

=== mission_objectives ===
#speaker:agent_0x99

Agent HaX: Three things, then. Get inside St. Catherine's and reach their crisis lead -- she's expecting a security consultant.

Agent HaX: Get into their IT systems and find how the attackers got in. It'll be that neglected backup server.

Agent HaX: Then turn their own backdoor against them -- exploit it, recover the decryption keys, and bring those patients' systems home before either clock runs out.

* [What's my cover?]
    -> cover_story

* [What am I walking into? Security?]
    -> security_warning

* [Understood. I'm moving.]
    -> final_instructions

=== cover_story ===
#speaker:agent_0x99

Agent HaX: Their CTO, Dr. Sarah Kim, put out a call for an emergency security consultant to help them through the incident. We made sure you're the one who answered it.

Agent HaX: Understand what that does and doesn't buy you. She's expecting a consultant -- a set of hands to assess the breach and get her systems back. She has no idea SAFETYNET is involved, and no idea this is ENTROPY. To her, you're a contractor on a very bad night. Keep it that way.

+ [So how much access does that actually get me?]
    -> security_warning

=== security_warning ===
#speaker:agent_0x99

Agent HaX: Less than you'd like. A consultant's remit is to assess and advise -- not to be handed the keys to the kingdom. And a hospital mid-breach locks everything down: restricted areas go to named staff badges only. Chain of custody, data governance. Your visitor badge gets you the public and admin floors and a room full of frightened people. It will not open their IT department, their server room, or their records.

Agent HaX: So you earn the rest. Get a member of staff to authorise you or walk you in -- that's your clean route. And where the crisis means nobody's free to sign off a locked door? You improvise. You're carrying a pick kit for exactly that. Just don't do it where a guard can see.

+ [Who's worth leaning on inside?]
    Agent HaX: Their IT admin, Marcus Webb. He flagged this exact weakness to the board six months ago and got overruled. He's drowning in guilt, he holds the server-room keycard, and he's your fastest way past the doors that matter. Win him over.
    -> final_instructions

+ [Understood. I'll talk my way in where I can.]
    -> final_instructions

// ===========================================
// FINAL INSTRUCTIONS
// ===========================================

=== final_instructions ===
#speaker:agent_0x99

Agent HaX: One more thing. Ghost is still in the wires -- watching that network. If they reach out, don't expect threats. Expect arithmetic. Don't let it get in your head.

{knows_stakes:
    Agent HaX: And whatever the ward looks like in there -- those numbers on the board are on ENTROPY. Not on you. Just do the work and get the keys.
}

Agent HaX: Good luck, {player_name()}. Forty-seven lives, twelve hours. Go.

#complete_task:receive_mission_briefing
#unlock_aim:infiltrate_hospital
#start_gameplay
#exit_conversation

-> END
