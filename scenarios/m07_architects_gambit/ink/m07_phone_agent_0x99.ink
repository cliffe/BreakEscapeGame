// ===========================================
// PHONE NPC: Agent HaX (Handler Support)
// Mission 7: The Architect's Gambit
// Progress-gated support hub, delegation + redirect interface,
// five field guides, per-stage VM hints.
// ===========================================

// ---- Mission state (synced from globalVariables at call-open) ----
VAR team_assignment = ""
VAR team_assigned = false
VAR projection_revised = false
VAR team_redirected = false
VAR redirect_window_closed = false

VAR morrison_resolved = ""
VAR elena_outcome = ""
VAR mercer_fate = ""
VAR found_coordination_traffic = false
VAR found_tomb_gamma = false
VAR found_mole_evidence = false

VAR flag1_submitted = false
VAR flag2_submitted = false
VAR flag3_submitted = false
VAR flag4_submitted = false

VAR rfid_guide_offered = false
VAR rfid_guide_hint_given = false
VAR lockpicking_guide_offered = false
VAR lockpicking_guide_hint_given = false
VAR recon_guide_offered = false
VAR recon_guide_hint_given = false
VAR scanning_guide_offered = false
VAR scanning_guide_hint_given = false
VAR privesc_guide_offered = false
VAR privesc_guide_hint_given = false

// ---- Local latches (never synced) ----
VAR first_contact = true
VAR delegation_registered = false
VAR moral_discussed = false
VAR redirect_closed_discussed = false
VAR morrison_discussed = false
VAR elena_discussed = false
VAR traffic_discussed = false
VAR mercer_discussed = false
VAR tomb_discussed = false
VAR mole_discussed = false
VAR vm1_hint_given = false
VAR vm2_hint_given = false
VAR vm3_hint_given = false
VAR vm4_hint_given = false

EXTERNAL player_name()

// ===========================================
// ENTRY POINT
// ===========================================

=== start ===
{first_contact:
    ~ first_contact = false
    -> first_call
}
-> hub

=== first_call ===
{team_assigned:
    -> first_call_committed
- else:
    -> first_call_open
}

=== first_call_committed ===
// The briefing (WP3) already set team_assignment. HaX registers the
// delegation operationally -- this is where the task completes.
{not delegation_registered:
    ~ delegation_registered = true
}
#complete_task:assign_tactical_team

Agent HaX: {player_name()}. HaX. I've got your channel and I've got the board.

Agent HaX: I'm running you from the ops room at home and the ops room is covering three continents tonight, so if I go quiet for ten seconds it isn't personal.

Agent HaX: The team's logged for {team_assignment == "fracture": Fracture -- Washington|{team_assignment == "meltdown": Meltdown -- San Francisco|Trojan Horse -- Austin}}. Aircraft's turned, it's on the record, it's done. I'm not going to relitigate it with you.

Agent HaX: What I can't do is be in the other two places. So you're going to be my hands in the one place a person on the ground still changes the ending. Grid control. Get inside.

+ [Walk me through the layout.]
    Agent HaX: Checkpoint, ops floor, server room, control room. Locked chain -- badge, then a keyed door, then a PIN, then a password on the control room itself.
    Agent HaX: One of the guards on the checkpoint shift is bought. Assume every reader you touch is logging you. I'll flag the tools as you hit each lock.
    -> hub
+ [What's the clock?]
    Agent HaX: Cascade timer's running on the SCADA host. Don't let it rush you into sloppiness -- reading the room carefully has never once cost a life. Panicking has.
    -> hub
+ [Understood. Let's go.]
    Agent HaX: Good. Call me the second you hit something you can't open.
    -> hub

=== first_call_open ===
Agent HaX: {player_name()}. HaX. You're on the channel but the board says the team's still uncommitted -- Netherton's holding for your call.

Agent HaX: I can't move a tactical team from a phone. That decision sits with you and the Director. Settle it with him on the briefing channel, then come back to me and I'll run the rest.

+ [On it.]
    Agent HaX: Quickly. Two operations are waiting on which one you don't pick.
    -> hub

// ===========================================
// SUPPORT HUB -- gated on mission state
// ===========================================

=== hub ===

// Register the delegation if the player reached the hub without the intro
// having fired under a committed board (defensive; keeps the task honest).
+ {team_assigned and not delegation_registered} [Confirm the team's away.]
    ~ delegation_registered = true
    #complete_task:assign_tactical_team
    Agent HaX: Logged and confirmed. The aircraft's committed. Now get inside.
    -> hub

// --- The redirect window: open ---
+ {projection_revised and not team_redirected and not redirect_window_closed} [Those numbers were understated. I want the team moved to Trojan Horse.]
    -> redirect_open

// --- The redirect window: closed, refused out loud ---
+ {projection_revised and not team_redirected and redirect_window_closed and not redirect_closed_discussed} [Can I still move the team to Trojan Horse?]
    -> redirect_closed

// --- Moral sounding board ---
+ {team_assigned and not moral_discussed} [Talk to me about the two we're not covering.]
    -> moral_soundingboard

// --- Morrison ---
+ {morrison_resolved != "" and not morrison_discussed} [The guard on the checkpoint -- Morrison. He was dirty.]
    -> topic_morrison

// --- Elena ---
+ {elena_outcome != "" and not elena_discussed} [Elena's numbers don't match the brief.]
    -> topic_elena

// --- The coordination traffic ---
+ {found_coordination_traffic and not traffic_discussed} [The share -- four operations running off one schedule.]
    -> topic_traffic

// --- Mercer ---
+ {mercer_fate != "" and not mercer_discussed} [I've dealt with Mercer.]
    -> topic_mercer

// --- Tomb Gamma ---
+ {found_tomb_gamma and not tomb_discussed} [I found a dossier down in the vault. Tomb Gamma.]
    -> topic_tomb

// --- The mole ---
+ {found_mole_evidence and not mole_discussed} [The intercept in the vault. They didn't leak the operation. They leaked me.]
    -> topic_mole

// --- Per-stage VM hints ---
+ {scanning_guide_offered and not flag1_submitted and not vm1_hint_given} [I'm on the attack host and I don't know where to start.]
    -> vm_hint_1
+ {flag1_submitted and not flag2_submitted and not vm2_hint_given} [I've got the timeline. What's next on the host?]
    -> vm_hint_2
+ {flag2_submitted and not flag3_submitted and not vm3_hint_given} [I've got the C2 channel. I need more than a user shell.]
    -> vm_hint_3
+ {flag3_submitted and not flag4_submitted and not vm4_hint_given} [I'm root. How do I actually stop the cascade?]
    -> vm_hint_4

// --- Field guide requests ---
+ {rfid_guide_offered and not rfid_guide_hint_given} [Send me the RFID cloning field guide.]
    -> guide_rfid
+ {lockpicking_guide_offered and not lockpicking_guide_hint_given} [Send me the lockpicking field guide.]
    -> guide_lockpicking
+ {recon_guide_offered and not recon_guide_hint_given} [Send me the recon and network mapping field guide.]
    -> guide_recon
+ {scanning_guide_offered and not scanning_guide_hint_given} [Send me the scanning and exploitation field guide.]
    -> guide_scanning
+ {privesc_guide_offered and not privesc_guide_hint_given} [Send me the privilege escalation field guide.]
    -> guide_privesc

// --- Sticky exit ---
+ [I'll call you back.]
    Agent HaX: I'm here. Go.
    #exit_conversation
    -> DONE

// ===========================================
// THE REDIRECT
// ===========================================

=== redirect_open ===
Agent HaX: I hear you. And I want to be straight about what you're asking, because I'm not going to dress it up.

Agent HaX: If I move them, they don't teleport. They peel off {team_assignment == "fracture": Fracture|{team_assignment == "meltdown": Meltdown|the current tasking}} and fly to Austin, and they land forty minutes into an injection that's already running. Best case they stop it at a third. Millions of systems still take the backdoor. That's not a save, it's a partial.

Agent HaX: And the place you're pulling them from goes completely dark. Nobody there. Whatever was going to happen there, happens.

Agent HaX: The trade is real: the healthcare and dispatch keys are sequenced late in that manifest, so getting there at all keeps ambulances on the road. But you're paying for it in the operation you abandon. Your call, and it's a hard one.

+ [Move them. Trojan Horse. Now.]
    #set_global:team_redirected:true
    #set_global:team_assignment:trojan_horse
    Agent HaX: Redirecting. Austin confirmed, forty minutes out.
    Narrator: One pin swings across the board to Austin. The pin it left behind goes dark and stays dark.
    Agent HaX: You changed your mind under a clock, on evidence you went and found. Not many can. Live with the half you couldn't reach -- that one's on ENTROPY, not you.
    -> hub

+ [No. Leave them where they are.]
    Agent HaX: Then they stay. I'll note you weighed it and held. That's a decision too, and a defensible one.
    -> hub

=== redirect_closed ===
~ redirect_closed_discussed = true
Agent HaX: No. I'm sorry -- that window's shut.

Agent HaX: The team's committed on the ground now. I can't turn an aircraft mid-approach on a maybe, and there isn't the fuel or the time to peel them off a live objective and re-task them across the country. If we'd moved them earlier it would have meant something. Now it just strands two operations instead of one.

Agent HaX: You learned the numbers were wrong. That knowledge wasn't wasted -- it goes in the report, and it's why M8 starts where it starts. But the team's where it is. Finish the part that's still yours to finish.

+ [Understood.]
    -> hub

// ===========================================
// MORAL SOUNDING BOARD
// ===========================================

=== moral_soundingboard ===
~ moral_discussed = true
Agent HaX: Yeah. I've been sitting with that since you made the call.

Agent HaX: Two of them we don't answer. Whichever way you'd turned it, that stays true -- there was one team and three fires. That's not a failure of nerve, it's arithmetic, and ENTROPY built the arithmetic on purpose.

+ [How do you carry that?]
    Agent HaX: Badly, if you're any good. You don't get to feel clean about triage. The trick is to let it hurt afterwards and not during, because during is when you make it worse.
    Agent HaX: You saved the one place a body on the ground could reach. Hold onto that. Not as an excuse -- as a fact.
    -> hub

+ [Was there a right answer?]
    Agent HaX: No. That's the whole shape of it. Deaths tonight, an election, or every mission after -- you can't put those on the same scale. Anyone who tells you they'd have known is lying or hasn't read the briefs.
    -> hub

// ===========================================
// NPC / LORE TOPICS
// ===========================================

=== topic_morrison ===
~ morrison_discussed = true
Agent HaX: {morrison_resolved == "ko": He's down, then. Fine. He made his choice when he took their money.|Morrison, yeah. We cleared him last month -- routine revalidation, clean sheet.}

Agent HaX: Which is the part that should worry you. Somebody inside our vetting signed off a man ENTROPY already owned. That's a small version of a much bigger question, and you're going to meet the big version before the night's out.
-> hub

=== topic_elena ===
~ elena_discussed = true
Agent HaX: {elena_outcome == "ko": She's not talking now. Shame -- she was the one person in there who'd been lied to as hard as the public had.|She was shown a six-hour demonstration with nobody hurt. What you're standing in is not that.}

Agent HaX: The projections in your brief were ENTROPY's own numbers. They fed them to us as part of the gambit. Elena's the proof they're understated -- if she gave you the real casualty figure, that's your redirect evidence. Same thing the coordination traffic on their share will tell you, if you'd rather not take one frightened engineer's word for it.
-> hub

=== topic_traffic ===
~ traffic_discussed = true
Agent HaX: I've read it. Four operations, one schedule, one authority signing the tasking. They're not four cells improvising in parallel. They're one operation wearing four coats.

Agent HaX: And the Trojan Horse parameters are right there in it -- nine-day dormancy, healthcare and dispatch vendors in the manifest. That's your hard confirmation the brief was cooked. If the window's open, it's enough to move the team on.
-> hub

=== topic_mercer ===
~ mercer_discussed = true
Agent HaX: {mercer_fate == "ko": On the floor, is he. Doesn't change a thing about the sequence -- it's scheduled and local and it never needed him conscious.|Blackout himself. Dr James Mercer. Ex-DoE, built cascading-failure models for a living, now he builds them for real and calls it a lesson.}

Agent HaX: He's read the casualty projection. He signed it. That's not a man you talk down -- you're not choosing whether to convert him, you're choosing what to say to him. Tell him he was a diversion or don't. It won't save anyone. It'll just change what he has to live with.
-> hub

=== topic_tomb ===
~ tomb_discussed = true
Agent HaX: Tomb Gamma. That's the Architect's workshop -- where the whole gambit was assembled. No coordinates on it, you'll notice. Deliberate. He doesn't keep an address.

Agent HaX: Bag it. That dossier is half of what M8 gets built on. The other half's whatever else is down there with you.
-> hub

=== topic_mole ===
~ mole_discussed = true
Agent HaX: *long pause* Say that again slowly, because I want to be sure I'm hearing it.

Agent HaX: He had our deployment before we made it. Not the attack timing -- the agent. Somebody handed ENTROPY you. Which means tonight was never about the grid. It was an experiment to watch how SAFETYNET triages when it can't cover everything, and we just ran it for him in full.

Agent HaX: You still saved eight point four million people. That's real, don't let anyone take it off you. But we've got a leak, and it's near enough the top to know your tasking. Get that intercept out. It's the first thread of the next one.
-> hub

// ===========================================
// PER-STAGE VM HINTS
// ===========================================

=== vm_hint_1 ===
~ vm1_hint_given = true
Agent HaX: Their backup server's got an NFS export sitting wide open. Mount it read-only and go through it -- the attack timeline's in there, and so's the flag that proves you found it.

Agent HaX: showmount to see what's exported, then mount it somewhere local. Read, don't touch. First flag's the coordination traffic, and that's the one that changes what you know.
-> hub

=== vm_hint_2 ===
~ vm2_hint_given = true
Agent HaX: Good. Now enumerate services on the host. There's a netcat listener acting as their command channel -- get onto it and read what's passing.

Agent HaX: That channel's carrying the control room password in clear, so this flag pays you twice: it's flag two, and it's the door into SCADA without needing anyone in there to cooperate.
-> hub

=== vm_hint_3 ===
~ vm3_hint_given = true
Agent HaX: A user shell won't terminate their processes -- you need root. Enumerate for privilege escalation: sudo -l first, then look for the misconfiguration they left behind.

Agent HaX: Least intrusive path that reaches root. Flag three is control of the host. Once you own it, you own the countdown.
-> hub

=== vm_hint_4 ===
~ vm4_hint_given = true
Agent HaX: Now the actual job. Kill the cascade processes and lock out remote access so they can't just restart them from outside. That's flag four.

Agent HaX: When it lands, the control room's crisis system will take an abort. Go upstairs and give it one. That's the grid held.
-> hub

// ===========================================
// FIELD GUIDES -- delivery half
// ===========================================

=== guide_rfid ===
~ rfid_guide_hint_given = true
#give_item:lab-workstation:m07_rfid_field_guide
Agent HaX: RFID cloning guide's on your terminal.

Agent HaX: Read the badge with a Proxmark, clone it to a blank, present the clone. The reader can't tell the difference -- that's the whole weakness. Morrison's badge or the printer, either gets you a valid one to copy.

+ [Got it.]
    Agent HaX: Quiet and quick. Go.
    -> hub

=== guide_lockpicking ===
~ lockpicking_guide_hint_given = true
#give_item:lab-workstation:m07_lockpicking_field_guide
Agent HaX: Lockpicking guide uploaded.

Agent HaX: Light tension, find the binding pin, set it, repeat. Read the lock by feel, don't force it. You're carrying picks -- that keyed door doesn't need the key.

+ [Received.]
    Agent HaX: Patient hands open any of those. Go.
    -> hub

=== guide_recon ===
~ recon_guide_hint_given = true
#give_item:lab-workstation:m07_recon_field_guide
Agent HaX: Recon and network mapping guide sent.

Agent HaX: Before you exploit anything, know what's there. Sweep the subnet, map the hosts, list the services. The attack host and its backup server both turn up here -- find them before you touch them.

+ [Understood.]
    Agent HaX: Map first, act second. Always. Go.
    -> hub

=== guide_scanning ===
~ scanning_guide_hint_given = true
#give_item:lab-workstation:m07_scanning_field_guide
Agent HaX: Scanning and exploitation guide's on your terminal.

Agent HaX: Fingerprint the service, find the version, match it to the exploit, launch, verify you've got a shell. End to end. Don't fire blind -- confirm the target first.

+ [Copy.]
    Agent HaX: Enumerate, then exploit. Go.
    -> hub

=== guide_privesc ===
~ privesc_guide_hint_given = true
#give_item:lab-workstation:m07_privesc_field_guide
Agent HaX: Privilege escalation guide uploaded.

Agent HaX: sudo -l first, then the smallest step that gets you root. Look for what they misconfigured rather than what you'd have to break. Least noise, most access.

+ [Received.]
    Agent HaX: Walk through the door they left open. Go.
    -> hub
