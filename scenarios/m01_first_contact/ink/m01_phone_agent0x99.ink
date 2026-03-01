// ================================================
// Mission 1: First Contact - Agent 0x99 Phone Support
// Tutorial Guidance & Event Reactions
// Provides help, hints, and contextual support
// ================================================

VAR lockpick_hint_given = false
VAR ssh_hint_given = false
VAR linux_hint_given = false
VAR sudo_hint_given = false
VAR first_contact = true
VAR operation_shatter_reported = false

// External variables
VAR player_name = "Agent 0x00"
VAR current_task = ""
VAR talked_to_maya = false
VAR talked_to_kevin = false
VAR discussed_operation = false

// Closing debrief variables
VAR final_choice = ""
VAR objectives_completed = 0
VAR lore_collected = 0
VAR found_casualty_projections = false
VAR found_target_database = false
VAR maya_identity_protected = true
VAR kevin_choice = ""
VAR kevin_protected = false
VAR security_audit_completed = false
VAR audit_correct_answers = 0
VAR audit_wrong_answers = 0

// NPC casualty tracking
VAR kevin_ko = false
VAR sarah_ko = false
VAR maya_ko = false

// Kevin false-evidence confrontation
VAR kevin_confronted_with_evidence = false

// ================================================
// START: PHONE SUPPORT
// ================================================

=== start ===
{first_contact:
    ~ first_contact = false
    -> first_call
}
{not first_contact:
    -> support_hub
}

// ================================================
// FIRST CALL (Orientation)
// ================================================

=== first_call ===
#speaker:agent_0x99

Agent 0x99: {player_name}, checking in. How's the infiltration going?

Agent 0x99: If you need guidance on any challenges, I'm here. That's what handlers are for.

+ [Everything's going smoothly so far]
    Agent 0x99: Good. Remember, take your time. Rushing creates mistakes.
    -> support_hub
+ [I could use some tips]
    -> support_hub
+ [I'll call if I need help]
    #exit_conversation
    Agent 0x99: Roger that. I'm here when you need me.
    -> support_hub

// ================================================
// SUPPORT HUB (General Help)
// ================================================

=== support_hub ===
#speaker:agent_0x99

Agent 0x99: What do you need help with?

+ {talked_to_maya and discussed_operation and not operation_shatter_reported} [I discovered what ENTROPY is planning - Operation Shatter]
    -> report_operation_shatter
+ {not lockpick_hint_given} [Lockpicking guidance]
    -> lockpick_help
+ {not ssh_hint_given} [SSH brute force help]
    -> ssh_help
+ {not linux_hint_given} [Linux navigation tips]
    -> linux_help
+ {not sudo_hint_given} [Privilege escalation guidance]
    -> sudo_help
+ [General mission advice]
    -> general_advice
+ [I'm good for now]
    #exit_conversation
    Agent 0x99: Copy that. Call anytime.
    -> support_hub

// ================================================
// LOCKPICKING HELP
// ================================================

=== lockpick_help ===
~ lockpick_hint_given = true

Agent 0x99: Lockpicking is about patience and listening.

Agent 0x99: Each pin has a sweet spot. Apply tension, test each pin, feel for the feedback.

Agent 0x99: Start with the storage closet practice safe—low stakes, good for learning.

+ [Any other tips?]
    Agent 0x99: Don't force it. If you're stuck, reset and try again. There's no timer.
    -> support_hub
+ [Got it, thanks]
    -> support_hub

// ================================================
// SSH BRUTE FORCE HELP
// ================================================

=== ssh_help ===
~ ssh_hint_given = true

Agent 0x99: SSH brute force uses Hydra to test password lists against login prompts.

Agent 0x99: The key is using good password lists. Kevin's hints about "ViralDynamics2025" variations are gold.

Agent 0x99: Command format: hydra -l username -P passwordlist.txt ssh://target

+ [What if I don't have a password list?]
    Agent 0x99: Build one from intel. Kevin mentioned patterns, the whiteboard had clues. Social engineering works.
    -> support_hub
+ [Thanks, that helps]
    -> support_hub

// ================================================
// LINUX NAVIGATION HELP
// ================================================

=== linux_help ===
~ linux_hint_given = true

Agent 0x99: Linux navigation basics: ls lists files, cd changes directory, cat reads files.

Agent 0x99: Check the home directory first. User files, hidden configs—look for .bashrc, .ssh, personal directories.

Agent 0x99: Hidden files start with a dot. Use ls -la to see them.

+ [Where should I look for flags?]
    Agent 0x99: Home directories, user documents, sometimes hidden in config files. Explore methodically.
    -> support_hub
+ [Got it]
    -> support_hub

// ================================================
// PRIVILEGE ESCALATION HELP
// ================================================

=== sudo_help ===
~ sudo_hint_given = true

Agent 0x99: Privilege escalation means gaining access to other accounts or higher permissions.

Agent 0x99: Try "sudo -l" to see what sudo permissions you have. Some accounts allow switching users.

Agent 0x99: Command: sudo -u otherusername bash gives you a shell as that user.

+ [What if I don't have sudo access?]
    Agent 0x99: Check for misconfigured files, world-writable directories, or SUID binaries. But for this mission, sudo works.
    -> support_hub
+ [Thanks]
    -> support_hub

// ================================================
// GENERAL ADVICE
// ================================================

=== general_advice ===
Agent 0x99: Remember the mission priorities: gather evidence, identify operatives, minimize innocent casualties.

Agent 0x99: Most people at Viral Dynamics are legitimate employees. We want ENTROPY, not collateral damage.

+ [How do I know who's ENTROPY?]
    Agent 0x99: Evidence correlation. Look for encrypted communications, connections to known cells, suspicious behavior.
    Agent 0x99: Derek's our primary suspect, but gather proof before confronting.
    -> support_hub
+ [What about Maya?]
    Agent 0x99: Protect her. She's the informant who brought this to us. Don't expose her unless absolutely necessary.
    -> support_hub
+ [Understood]
    -> support_hub

// ================================================
// REPORT OPERATION SHATTER DISCOVERY
// ================================================

=== report_operation_shatter ===
~ operation_shatter_reported = true
#unlock_task:inform_safetynet_operation_shatter

Agent 0x99: ...Say that again.

+ [Operation Shatter - coordinated disinformation attack]
    -> shatter_details_1
+ [They're planning mass casualties]
    -> shatter_casualties

=== shatter_details_1 ===
Agent 0x99: Operation Shatter. Christ.

Agent 0x99: What exactly are they planning?

+ [Fake crisis messages targeting vulnerable populations]
    -> shatter_details_2

=== shatter_details_2 ===
Agent 0x99: Talk to me. What did Maya tell you?

+ [Over two million profiles. Fake hospital closures, bank failures, infrastructure attacks.]
    -> shatter_casualties

=== shatter_casualties ===
Agent 0x99: {player_name}, this is worse than we thought.

Agent 0x99: How bad are we talking?

+ [Their own projections: 42 to 85 deaths in the first 24 hours]
    -> shatter_reaction
+ [They've calculated acceptable casualties. They're targeting diabetics, elderly, people with anxiety disorders.]
    -> shatter_reaction

=== shatter_reaction ===
Agent 0x99: ...Forty-two to eighty-five people. Calculated. Deliberate.

Agent 0x99: They're not just terrorists. They're mass murderers with spreadsheets.

Agent 0x99: {player_name}, listen carefully. Your mission just changed priority.

+ [What do I need to do?]
    -> updated_objectives

=== updated_objectives ===
Agent 0x99: New priority objective: Stop Operation Shatter before deployment.

Agent 0x99: Maya said Sunday, 6 AM. That's when the messages go out.

Agent 0x99: Find the complete documentation—target lists, message templates, deployment systems.

Agent 0x99: Gather proof of Derek's involvement. And shut down their attack infrastructure before those messages go out.

+ [What about those 85 people?]
    -> people_at_stake
+ [I'll stop it]
    -> mission_commitment

=== people_at_stake ===
Agent 0x99: They're counting on you, {player_name}. Even if they don't know it.

Agent 0x99: Diabetics who'll skip insulin. Elderly with heart conditions. People who'll panic and make fatal decisions.

Agent 0x99: Every piece of evidence you find brings us closer to stopping this.

-> mission_commitment

=== mission_commitment ===
#complete_task:inform_safetynet_operation_shatter

Agent 0x99: Good work discovering this. Now we know what we're dealing with.

Agent 0x99: Continue investigating. Find the Operation Shatter files, identify all operatives, and prepare to shut this down.

Agent 0x99: Call me if you need support. This just became a race against the clock.

#exit_conversation
-> support_hub

// ================================================
// EVENT: DEREK OFFICE DOOR ATTEMPT (LOCKED)
// ================================================

=== event_derek_office_locked ===
#speaker:agent_0x99

Agent 0x99: That's Derek's office — locked tight. You'll need a way in.

Agent 0x99: A lockpick would do the trick. Kevin in IT might be able to help with that.

Agent 0x99: Or there might be a spare key somewhere. Poke around the other offices.

+ [Got it, I'll find a way in]
    #exit_conversation
    -> support_hub
+ [Where exactly is Kevin?]
    Agent 0x99: IT room, east side of the main office. You'll need the PIN to get in — check around for maintenance notes.
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: LOCKPICK ACQUIRED
// ================================================

=== event_lockpick_acquired ===
#speaker:agent_0x99

{kevin_ko:
    Agent 0x99: Got the lockpick kit. Direct approach — Kevin wasn't going to hand them over like that.
- else:
    Agent 0x99: I see Kevin gave you lockpicks. Smart social engineering.
}

Agent 0x99: Practice on low-risk targets first. Storage closet, unlocked areas.

Agent 0x99: Remember, you're testing security—officially.

+ [Will do]
    #exit_conversation
    -> support_hub
+ [Any lockpicking tips?]
    -> lockpick_help

// ================================================
// EVENT: SERVER ROOM ENTERED
// ================================================

=== event_server_room_entered ===
#speaker:agent_0x99
#complete_task:access_server_room
#unlock_task:access_vm

Agent 0x99: You're in the server room. Good work getting access.

Agent 0x99: Look for the compromised systems. VM access will give you deeper intelligence.

+ [What am I looking for?]
    Agent 0x99: Evidence of ENTROPY's infrastructure. Backdoors, encrypted communications, anything linking Derek to other cells.
    #exit_conversation
    -> support_hub
+ [On it]
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: FIRST FLAG SUBMITTED
// ================================================

=== event_first_flag ===
#speaker:agent_0x99

Agent 0x99: First flag submitted. Nice work, {player_name}.

Agent 0x99: Each flag unlocks intelligence. Keep correlating VM findings with physical evidence.

+ [What should I focus on next?]
    Agent 0x99: Continue the VM challenges, but don't forget physical investigation. Derek's office, filing cabinets, computer access.
    Agent 0x99: Hybrid approach—digital and physical evidence together.
    #exit_conversation
    -> support_hub
+ [Thanks]
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: DEREK'S OFFICE ACCESSED
// ================================================

=== event_derek_office_entered ===
#speaker:agent_0x99
#unlock_task:find_campaign_materials
#unlock_task:discover_manifesto
#unlock_task:decode_communications

Agent 0x99: You're in Derek's office. Good.

Agent 0x99: Look for communications, project documents, anything linking him to ENTROPY.

Agent 0x99: Whiteboard messages, computer files, filing cabinets. Be thorough.

+ [What if Derek catches me?]
    Agent 0x99: Your cover is solid. You're doing a security audit—accessing offices is expected.
    Agent 0x99: But don't tip your hand too early. Gather evidence before confronting.
    #exit_conversation
    -> support_hub
+ [On it]
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: ALL FLAGS SUBMITTED
// ================================================

=== event_all_flags ===
#speaker:agent_0x99

Agent 0x99: All VM flags submitted. Excellent work.

Agent 0x99: Intelligence confirms Derek Lawson as primary operative, coordinating with Zero Day Syndicate.

Agent 0x99: Now correlate with physical evidence. Then we can move to confrontation.

+ [What's the confrontation plan?]
    Agent 0x99: That's your call. Direct, silent extraction, or something creative.
    Agent 0x99: I trust your judgment. You've proven capable.
    #exit_conversation
    -> support_hub
+ [Roger that]
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: CONTINGENCY FILES FOUND - MORAL CHOICE
// ================================================

=== event_contingency_found ===
#speaker:agent_0x99

Agent 0x99: {player_name}, I just saw what you pulled from Derek's computer.

Agent 0x99: He's planning to frame Kevin Park for the entire breach. Fake logs, forged emails, the works.

Agent 0x99: Kevin—the IT guy who gave you access, who trusted you—is going to take the fall for ENTROPY.

+ [That's monstrous]
    -> contingency_reaction
+ [What can I do about it?]
    -> contingency_options

=== contingency_reaction ===
Agent 0x99: It gets worse. Derek's contingency activates automatically when systems are seized.

Agent 0x99: If we don't do something, Kevin gets arrested. His kids watch him taken away in handcuffs.

Agent 0x99: Eventually he'd be cleared, but... that's not something you just walk off.

-> contingency_options

=== contingency_options ===
Agent 0x99: You have options here. None of them are perfect.

Agent 0x99: What do you want to do?

+ [Confront Kevin with Derek's planted evidence]
    -> confront_kevin_choice
+ [Warn Kevin directly - tell him what's coming]
    -> warn_kevin_choice
+ [Leave evidence clearing Kevin for investigators]
    -> plant_evidence_choice
+ [Focus on the mission - Kevin's not my responsibility]
    -> ignore_kevin_choice

// ================================================
// CHOICE: CONFRONT KEVIN WITH PLANTED EVIDENCE
// ================================================

=== confront_kevin_choice ===
Agent 0x99: So — present Derek's manufactured evidence to Kevin and see how he responds.

Agent 0x99: If he's innocent, he'll know exactly what he's looking at. The anomaly report, the forged email — a good IT manager will spot the inconsistencies immediately.

Agent 0x99: Just remember: we already know it's a setup. Whatever Kevin says, you decide what to believe.

Agent 0x99: And if you decide to act on the false evidence anyway — that authority is yours. I won't stop you.

#set_variable:kevin_confronted_with_evidence=true

+ [Let's see what he says for himself]
    Agent 0x99: Find Kevin. Show him what Derek planted. Then make the call.
    #exit_conversation
    -> support_hub
+ [Maybe there's another option...]
    -> contingency_options

// ================================================
// CHOICE: WARN KEVIN
// ================================================

=== warn_kevin_choice ===
Agent 0x99: Direct warning. Risky—if Kevin panics or acts differently, Derek might notice.

Agent 0x99: But if it works, Kevin has time to lawyer up, document everything. He's protected.

+ [I'll take that risk. He deserves to know.]
    #set_variable:kevin_choice=warn
    #set_variable:kevin_protected=true
    Agent 0x99: Understood. Find Kevin, tell him what's coming. Just... be careful how much you reveal.
    Agent 0x99: The more he knows about SAFETYNET, the more complicated this gets.
    #exit_conversation
    -> support_hub
+ [Maybe there's a safer option...]
    -> contingency_options

// ================================================
// CHOICE: PLANT EVIDENCE
// ================================================

=== plant_evidence_choice ===
Agent 0x99: Anonymous help. Leave the frame-up files where our follow-up team will find them.

Agent 0x99: Kevin never knows he was in danger. Investigators see Derek's setup immediately.

Agent 0x99: Clean. Professional. Takes time, but lower risk.

+ [That's the smarter play. Do it that way.]
    #set_variable:kevin_choice=evidence
    #set_variable:kevin_protected=true
    Agent 0x99: Copy the contingency files to a visible location. Investigators will find them during evidence collection.
    Agent 0x99: Kevin walks away clean without ever knowing. That's the professional approach.
    #exit_conversation
    -> support_hub
+ [Maybe there's another option...]
    -> contingency_options

// ================================================
// CHOICE: IGNORE
// ================================================

=== ignore_kevin_choice ===
Agent 0x99: ...You're sure about that?

Agent 0x99: Kevin helped you. If you ignore this, he gets arrested. His family watches.

Agent 0x99: He'll be cleared eventually, but that's trauma that doesn't heal.

+ [The mission has to come first. I can't save everyone.]
    #set_variable:kevin_choice=ignore
    #set_variable:kevin_protected=false
    Agent 0x99: ...Understood. That's your call to make.
    Agent 0x99: Just know that choice has consequences. For Kevin. For his family.
    Agent 0x99: And for you, when you think about it later.
    #exit_conversation
    -> support_hub
+ [Wait. Let me reconsider.]
    -> contingency_options

// ================================================
// EVENT: ACT 2 COMPLETE (READY FOR CONFRONTATION)
// ================================================

=== event_act2_complete ===
#speaker:agent_0x99

Agent 0x99: You've identified the operatives and gathered the evidence.

Agent 0x99: Time to decide: How do you want to resolve this?

Agent 0x99: Confrontation, silent extraction, or public exposure. Each has consequences.

+ [I need to think about this]
    Agent 0x99: Take your time. This is the part where your choices matter most.
    #exit_conversation
    -> support_hub
+ [I'm ready to proceed]
    Agent 0x99: Good luck, {player_name}. You've got this.
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: SARAH MARTINEZ ATTACKED / KO'D
// ================================================

=== event_sarah_attacked ===
#speaker:agent_0x99

Agent 0x99: Unorthodox approach to reception, {player_name}.

Agent 0x99: Sarah's a civilian—nothing operational about her. Her items will be on the floor when she goes down. The visitor badge and the main office key.

Agent 0x99: You've got the authority. Keep moving.

+ [Understood]
    #exit_conversation
    -> support_hub
+ [Needed the key. No time to explain.]
    Agent 0x99: Fair enough. Get it done.
    #exit_conversation
    -> support_hub

=== event_sarah_ko ===
#speaker:agent_0x99

Agent 0x99: Check-in resolved. Sarah's key and badge are on the floor—pick them up and proceed.

Agent 0x99: For the record: Sarah Martinez has no connection to ENTROPY. She's the receptionist.

Agent 0x99: Collateral noted. Keep the mission moving.

+ [Got it. Moving on.]
    #exit_conversation
    -> support_hub
+ [Wasn't ideal, but necessary.]
    Agent 0x99: I know. Field decisions rarely are. Go.
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: MAYA CHEN ATTACKED / KO'D
// ================================================

=== event_maya_attacked ===
#speaker:agent_0x99

Agent 0x99: {player_name}—that's the informant.

Agent 0x99: Maya Chen is the one who contacted SAFETYNET. She's the reason we even know about Operation Shatter.

Agent 0x99: You have the authority to make field calls. Just be aware of what you're losing.

+ [She's in my way right now.]
    Agent 0x99: Noted. Your call. Whatever she knew about Shatter's inner workings goes with her if she goes down.
    #exit_conversation
    -> support_hub
+ [I know. Had to be done.]
    Agent 0x99: Then do it and keep moving. But understand what that costs us.
    #exit_conversation
    -> support_hub

=== event_maya_ko ===
#speaker:agent_0x99

Agent 0x99: We may never know what Maya had to tell us.

Agent 0x99: Whatever she'd gathered on Operation Shatter's inner workings—the names, the connections, the parts we don't have yet—that intelligence is gone.

Agent 0x99: Maya Chen was our contact, {player_name}. Not ENTROPY. She came to us because she trusted SAFETYNET.

Agent 0x99: You had the authority. The mission can still succeed. But we lost something today.

+ [The mission comes first.]
    Agent 0x99: It does. And it succeeded. Just... carry that one.
    #exit_conversation
    -> support_hub
+ [I know. I'm sorry.]
    Agent 0x99: Honest answer. Focus on what's ahead—stop Operation Shatter. That's what Maya wanted.
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: FRIENDLY NPC ATTACKED (Kevin attacked by player)
// ================================================

=== event_kevin_attacked ===
#speaker:agent_0x99

Agent 0x99: That's one way to get the lockpick, {player_name}.

Agent 0x99: You've got full operational authority—do whatever it takes to complete the mission. Just try to minimise collateral where you can.

Agent 0x99: Kevin's items should drop when he goes down. Keep moving.

+ [Understood]
    #exit_conversation
    -> support_hub
+ [He's not ENTROPY. Just in the way.]
    Agent 0x99: Correct. Kevin's clean. Innocent bystander in the wrong place. Happens in the field.
    Agent 0x99: Get what you need and keep pushing.
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: FRIENDLY NPC KO'D (Kevin knocked out)
// ================================================

=== event_kevin_ko ===
#speaker:agent_0x99

Agent 0x99: Kevin's down. His items are on the floor—pick them up and continue.

Agent 0x99: For the record: nothing in Kevin's files connects him to ENTROPY. He was just the IT guy trying to do his job.

Agent 0x99: You had the authority to make that call. The debrief will note it—but this isn't a reprimand.

+ [Mission comes first]
    Agent 0x99: That's the job. Keep going.
    #exit_conversation
    -> support_hub
+ [I know. It wasn't ideal.]
    Agent 0x99: No. But field decisions rarely are. You've got the lockpick and keycard now—use them.
    #exit_conversation
    -> support_hub

// ================================================
// CLOSING DEBRIEF - Mission Complete
// ================================================

=== closing_debrief ===
#speaker:agent_0x99

Agent 0x99: Operation Shatter is neutralized. Let's review what happened.

+ [On my way]
    #set_global:start_debrief_cutscene:true
    #exit_conversation
    -> END

#exit_conversation
-> END
