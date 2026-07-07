// ===========================================
// PHONE NPC: Agent 0x99 (Handler Support)
// Mission 2: Ransomed Trust
// Break Escape - Remote Support, Tutorial Guide, Moral Sounding Board
// ===========================================

// ---- Local hint tracking (never synced to globalVars) ----
VAR hint_start_given = false
VAR hint_lockpick_given = false
VAR hint_password_given = false
VAR hint_vm_given = false
VAR hint_encoding_given = false
VAR hint_pin_given = false
VAR hint_ransom_given = false
VAR lockpicking_guide_hint_given = false
VAR ssh_guide_hint_given = false
VAR privesc_guide_hint_given = false
VAR scanning_guide_hint_given = false
VAR vulnerability_guide_hint_given = false
VAR exploitation_guide_hint_given = false
VAR ghost_reaction_discussed = false
VAR ghost_deal_discussed = false
VAR board_email_discussed = false
VAR ideology_discussed = false
VAR first_contact = true

// ---- Mission state vars (synced from globalVars by engine at call-open) ----
VAR dr_kim_met = false
VAR flag_ssh_submitted = false
VAR flag_proftpd_submitted = false
VAR flag_database_submitted = false
VAR flag_ghost_log_submitted = false
VAR offline_keys_recovered = false
VAR lockpicking_guide_offered = false
VAR ssh_guide_offered = false
VAR privesc_guide_offered = false
VAR scanning_guide_offered = false
VAR vulnerability_guide_offered = false
VAR exploitation_guide_offered = false
VAR board_coverup_email_found = false
VAR ransom_decision_made = false
VAR ghost_deal_accepted = false
VAR ghost_contacted_player = false
VAR mission_complete = false

EXTERNAL player_name()

// ===========================================
// ENTRY POINT
// ===========================================

=== start ===
{first_contact:
    ~ first_contact = false
    -> first_call
}
-> support_hub

=== first_call ===
#speaker:agent_0x99

Agent 0x99: {player_name()}. You're in. Good.

Agent 0x99: 47 patients. Backup power. Twelve hours.

Agent 0x99: Start with Dr. Kim -- CTO, west of reception. She has the authority you need to access IT systems. Then find Marcus Webb in IT.

+ [Understood]
    -> support_hub

+ [What should I know going in?]
    Agent 0x99: The institutional failure here is going to make you angry. Stay professional.
    Agent 0x99: Marcus Webb warned them about this vulnerability six months ago. Seven times. Nobody listened.
    Agent 0x99: Don't let their negligence distract from the mission. People are depending on you right now.
    -> support_hub

// ===========================================
// SUPPORT HUB  --  gated by mission state
// Options only appear when they're relevant
// ===========================================

=== support_hub ===
#speaker:agent_0x99

// Urgent: Ghost made contact
+ {ghost_contacted_player and not ghost_reaction_discussed} [Ghost just reached out to me]
    -> ghost_contact_reaction

// Ghost deal follow-through
+ {ghost_deal_accepted and not ghost_deal_discussed} [I took Ghost's deal  --  free keys for publishing the evidence]
    -> ghost_deal_reaction

// Board cover-up email surface
+ {board_coverup_email_found and not board_email_discussed} [I found the board's cover-up email]
    -> board_email_reaction

// Pre-Kim: starting point
+ {not dr_kim_met and not hint_start_given} [Where do I start?]
    -> hint_start

// Post-Kim, pre-server-room: getting in
+ {dr_kim_met and not flag_ssh_submitted and not hint_lockpick_given} [Help getting into the server room]
    -> hint_lockpick

// Social engineering Marcus
+ {dr_kim_met and not flag_ssh_submitted and not hint_password_given} [Tips for getting Marcus to cooperate]
    -> hint_password

// Optional field guide: lockpicking (offered early -- offices off reception are locked)
+ {lockpicking_guide_offered and not lockpicking_guide_hint_given} [Send the lockpicking field guide]
    -> request_lockpicking_guide

// Optional field guide: scanning/recon
+ {scanning_guide_offered and not scanning_guide_hint_given} [Send the scanning field guide]
    -> request_scanning_guide

// Optional field guide: SSH access and bruteforce
+ {ssh_guide_offered and not ssh_guide_hint_given} [Send the SSH access and bruteforce field guide]
    -> request_ssh_guide

// VM phase: ProFTPD
+ {flag_ssh_submitted and not flag_proftpd_submitted and not hint_vm_given} [ProFTPD exploitation help]
    -> hint_vm

// Optional field guide: vulnerability triage
+ {vulnerability_guide_offered and not vulnerability_guide_hint_given} [Send the vulnerability analysis field guide]
    -> request_vulnerability_guide

// Optional field guide: exploitation workflow
+ {exploitation_guide_offered and not exploitation_guide_hint_given} [Send the ProFTPD exploitation field guide]
    -> request_exploitation_guide

// Optional field guide: privilege escalation
+ {privesc_guide_offered and not privesc_guide_hint_given} [Send the privilege escalation field guide]
    -> request_privesc_guide

// Encoding/decoding (useful throughout VM phase)
+ {flag_ssh_submitted and not hint_encoding_given} [Encoding and decoding help]
    -> hint_encoding

// Safe phase: offline keys
+ {flag_database_submitted and not offline_keys_recovered and not hint_pin_given} [I need the offline backup keys]
    -> hint_pin_safe

// Decision phase: moral support
+ {offline_keys_recovered and not ransom_decision_made and not hint_ransom_given} [Help thinking through the ransom decision]
    -> hint_ransom_decision

// Ghost deal option when approaching recovery console
+ {offline_keys_recovered and not ransom_decision_made and ghost_deal_accepted} [I have Ghost's decryption keys  --  does that change things?]
    -> ghost_deal_recovery_advice

// ENTROPY ideology discussion (only after Ghost's log is found)
+ {flag_ghost_log_submitted and not ideology_discussed} [ENTROPY's ideology  --  how do we fight true believers?]
    -> discuss_ideology

// Post-decision: point to press terminal
+ {ransom_decision_made and not mission_complete} [I've made the recovery decision  --  what's left?]
    -> hint_press_terminal

// Always available
+ [Got any general advice?]
    -> general_advice

+ [I'm good for now]
    Agent 0x99: Copy that. Call anytime, {player_name()}.
    #exit_conversation
    -> DONE

// ===========================================
// GHOST REACTIONS
// ===========================================

=== ghost_contact_reaction ===
#speaker:agent_0x99
~ ghost_reaction_discussed = true

Agent 0x99: Ghost's watching the network. They've been on it since before you arrived.

Agent 0x99: They know which rooms you've accessed. They may be able to suspend your SAFETYNET connection temporarily.

Agent 0x99: Don't let that rattle you. They can't act against you directly. This is psychological pressure.

+ [Ghost seems to think they're justified]
    Agent 0x99: They do. ENTROPY cells are ideological -- they've convinced themselves that calculated harm is acceptable if it changes the system.
    Agent 0x99: Ghost isn't wrong about St. Catherine's negligence. That doesn't make their methods right.
    Agent 0x99: Their logic is their problem. Your job is those 47 patients.
    -> support_hub

+ [Ghost cut my SAFETYNET connection briefly]
    Agent 0x99: Noted. Network-level access. We knew they had it.
    Agent 0x99: Don't rely on me for anything time-critical from here on. What you're doing has to be done in the field.
    -> support_hub

+ [Understood. Staying focused.]
    -> support_hub

=== ghost_deal_reaction ===
#speaker:agent_0x99
~ ghost_deal_discussed = true

Agent 0x99: You made a deal with Ghost.

Agent 0x99: Free decryption keys. No ransom payment. Faster recovery, ENTROPY denied the money.

Agent 0x99: In exchange: you publish the board's negligence from the press terminal.

#speaker:narrator
Narrator: A pause.

#speaker:agent_0x99
Agent 0x99: Ghost gets exactly what they wanted without spending $87,000.

Agent 0x99: You're still the one making the final choice at that terminal. Ghost's deal doesn't override your judgment.

+ [Is it wrong to have taken it?]
    Agent 0x99: I don't know. You took resources from a terrorist to save lives and deny them funding simultaneously.
    Agent 0x99: The ethics depend entirely on what you do at the press terminal. Don't let Ghost own that decision.
    -> support_hub

+ [I'm going to honour it]
    Agent 0x99: Then publish everything. Make it count.
    -> support_hub

+ [I might not honour it]
    Agent 0x99: That's your call. Ghost will notice the breach. So will I.
    -> support_hub

=== board_email_reaction ===
#speaker:agent_0x99
~ board_email_discussed = true

Agent 0x99: The board was planning to terminate Marcus and bury his warnings before anyone asked questions.

Agent 0x99: That's not negligence anymore. That's deliberate cover-up of the conditions that created this crisis.

Agent 0x99: That email is going to matter at the press terminal. Keep it in mind.

+ [This changes how I see the exposure decision]
    Agent 0x99: It should. Publishing just the budget decisions is one thing. Publishing the cover-up is another.
    Agent 0x99: The hospital made two distinct failures. You'll decide which gets the full public record.
    -> support_hub

+ [Marcus had no idea the board was planning this]
    Agent 0x99: Probably not. He warned them in good faith.
    Agent 0x99: If you want his vindication to be public, the press terminal is the mechanism.
    -> support_hub

+ [Noted]
    -> support_hub

// ===========================================
// CONTEXTUAL HINTS
// ===========================================

=== hint_start ===
#speaker:agent_0x99
~ hint_start_given = true

Agent 0x99: Dr. Kim. CTO. Office wing west of reception.

Agent 0x99: She has authorization authority over IT access, server room, everything you need.

Agent 0x99: She's under extreme pressure -- the board is pushing for a ransom vote. She needs someone who can offer an alternative.

+ [What about Marcus Webb?]
    Agent 0x99: IT administrator. East corridor, IT department.
    Agent 0x99: He's the one who warned them about this vulnerability six months ago. He's furious and guilty in equal measure.
    Agent 0x99: Kim first, then Marcus. Order matters.
    -> support_hub

+ [Understood]
    -> support_hub

=== hint_lockpick ===
#speaker:agent_0x99
~ hint_lockpick_given = true

Agent 0x99: Server room is RFID-locked. You need Marcus's keycard.

Agent 0x99: Build enough trust with Marcus and he'll hand it over voluntarily. He wants those systems recovered as much as anyone.

Agent 0x99: If he's being difficult -- the IT department itself uses a standard pin-tumbler lock. Lockpicks work on it.

+ [What if Marcus is in a defensive spiral?]
    Agent 0x99: Validate the ignored-warnings angle. He needs someone to believe him.
    Agent 0x99: Don't challenge him about responsibility. That's not the conversation you need right now.
    -> support_hub

+ [Got it]
    -> support_hub

=== hint_password ===
#speaker:agent_0x99
~ hint_password_given = true

Agent 0x99: Marcus is a social engineering target. He's been dismissed by management for six months.

Agent 0x99: Sympathize with the experience. Tell him you've read his warnings. Tell him you believe him.

Agent 0x99: High trust gets you his keycard and the employee password list. Low trust gets you nothing useful.

+ [What passwords specifically?]
    Agent 0x99: Hospital environments use weak credentials. Birthdays, company names, simple variations.
    Agent 0x99: Emma2018. Hospital1987. StCatherines. Check his desk too -- he may have written something down.
    -> support_hub

+ [Understood]
    -> support_hub

=== hint_vm ===
#speaker:agent_0x99
~ hint_vm_given = true

Agent 0x99: CVE-2010-4652. ProFTPD 1.3.5 backdoor. Remote code execution via a vulnerability in the source code itself.

Agent 0x99: Patched in 2011. St. Catherine's is running a 2010 version. Your target.

Agent 0x99: The exploit gets you root on the backup server. From there, navigate the filesystem for encrypted database backups.

+ [What's the full exploit chain?]
    Agent 0x99: SSH access to confirm the server's reachable. ProFTPD exploit for root. Then filesystem navigation to the database backups.
    Agent 0x99: Submit each step as a flag at the drop-site terminal. Each flag unlocks the next piece of intelligence.
    -> support_hub

+ [Got it]
    -> support_hub

=== request_lockpicking_guide ===
#speaker:agent_0x99
~ lockpicking_guide_hint_given = true
#set_variable:lockpicking_guide_requested:true
#give_item:lab-workstation:m02_lockpicking_field_guide

Agent 0x99: Lockpicking guide uploaded to your terminal.

Agent 0x99: Light tension, find the binding pin, set it, repeat. Read the lock by feel -- don't force it.

+ [Received]
    Agent 0x99: Quiet and patient gets you through any of those doors. Go.
    -> support_hub

=== request_ssh_guide ===
#speaker:agent_0x99
~ ssh_guide_hint_given = true
#set_variable:ssh_guide_requested:true
#give_item:lab-workstation:m02_ssh_bruteforce_field_guide

Agent 0x99: SSH access and bruteforce guide sent.

Agent 0x99: Confirm the port's open, test a sensible username against a focused wordlist with Hydra, then connect. Foothold first, exploitation after.

+ [Got it]
    Agent 0x99: Start small on the wordlist and expand only if you need to. Move.
    -> support_hub

=== request_privesc_guide ===
#speaker:agent_0x99
~ privesc_guide_hint_given = true
#set_variable:privesc_guide_requested:true
#give_item:lab-workstation:m02_privilege_escalation_field_guide

Agent 0x99: Privilege escalation guide uploaded.

Agent 0x99: Enumerate with sudo -l first, then take the smallest step that reaches the files you need. Read with sudo cat where you can.

+ [Understood]
    Agent 0x99: Least intrusive path that works. Don't kick down doors you can walk through.
    -> support_hub

=== request_scanning_guide ===
#speaker:agent_0x99
~ scanning_guide_hint_given = true
#set_variable:scanning_guide_requested:true
#give_item:lab-workstation:m02_scanning_field_guide

Agent 0x99: Uploading the recon guide now.

Agent 0x99: Use it to map live hosts, enumerate services, and confirm the backup server attack surface before you commit to exploitation.

+ [Received]
    Agent 0x99: Good. Fast reconnaissance, clean notes, then strike.
    -> support_hub

=== request_vulnerability_guide ===
#speaker:agent_0x99
~ vulnerability_guide_hint_given = true
#set_variable:vulnerability_guide_requested:true
#give_item:lab-workstation:m02_vulnerability_field_guide

Agent 0x99: Sending vulnerability analysis guide.

Agent 0x99: You already have access. Now classify exposed services, match likely weakness classes, and avoid wasting time on dead paths.

+ [Got it]
    Agent 0x99: Exactly. Prioritize what is exploitable now, not everything that looks noisy.
    -> support_hub

=== request_exploitation_guide ===
#speaker:agent_0x99
~ exploitation_guide_hint_given = true
#set_variable:exploitation_guide_requested:true
#give_item:lab-workstation:m02_exploitation_field_guide

Agent 0x99: ProFTPD exploitation workflow uploaded.

Agent 0x99: It covers Metasploit module selection, payload/listener alignment, and post-exploitation checks so you can execute without guesswork.

+ [Thanks, I needed this]
    Agent 0x99: Use it, adapt to what the target gives you, and keep momentum.
    -> support_hub

=== hint_encoding ===
#speaker:agent_0x99
~ hint_encoding_given = true

Agent 0x99: Encoding is not encryption. Important distinction.

Agent 0x99: Encoding -- Base64, ROT13, hex -- transforms data for storage or transit. No secret key. Reversible by anyone with the right tool.

Agent 0x99: Encryption requires a key. Without it, the data is meaningless.

Agent 0x99: ENTROPY uses encoding for obfuscation and encryption for actual security. When you find something encoded, use CyberChef.

+ [How do I use CyberChef for Base64?]
    Agent 0x99: Workstation in the server room. Open CyberChef, drag "From Base64" into the recipe, paste your text. Instant decode.
    Agent 0x99: For ROT13, same process -- drag the ROT13 operation in.
    -> support_hub

+ [Understood]
    -> support_hub

=== hint_pin_safe ===
#speaker:agent_0x99
~ hint_pin_given = true

Agent 0x99: Ghost's logs confirmed offline backup keys are in a physical PIN safe. Emergency equipment storage, south corridor.

Agent 0x99: Four-digit code. Hospitals use institutional dates -- founding years, significant administrative anniversaries.

Agent 0x99: The answer's somewhere in the building. Check plaques, framed documents, administrative notices.

+ [I've already found a clue]
    Agent 0x99: Trust it. Hospitals are consistent about this kind of thing.
    -> support_hub

+ [What if I can't find the PIN?]
    Agent 0x99: There should be a PIN cracker device in the storage room itself. Two minutes, covers all combinations. Last resort.
    -> support_hub

+ [Got it]
    -> support_hub

=== hint_ransom_decision ===
#speaker:agent_0x99
~ hint_ransom_given = true

Agent 0x99: You have both key types. That means independent recovery is genuinely on the table.

Agent 0x99: Pay the ransom: 1-2 patient deaths, $87,000 funds ENTROPY's next operation.

Agent 0x99: Manual recovery: 4-6 patient deaths, ENTROPY gets nothing. The hospital recovers independently.

Agent 0x99: Both choices save lives -- different timeframes, different costs. That's what makes it hard.

+ [What would you choose?]
    Agent 0x99: I'm not going to answer that.
    Agent 0x99: What I'll say: don't let Ghost's framing decide it for you. They designed this dilemma. Don't let them own your answer.
    -> support_hub

+ [Is there a third option?]
    {ghost_contacted_player:
        Agent 0x99: Ghost may have offered one. Free keys in exchange for publishing the evidence.
        Agent 0x99: If they did -- that's a real option. Fast recovery, no funding, but Ghost's lesson lands publicly.
        Agent 0x99: It's your call whether to engage with that.
        -> support_hub
    }
    Agent 0x99: Not through official channels. The recovery console has the options available to you.
    -> support_hub

+ [I'll make the call]
    Agent 0x99: Good. Recovery console in the server room. Take the decision you can live with.
    -> support_hub

=== ghost_deal_recovery_advice ===
#speaker:agent_0x99

Agent 0x99: If Ghost's keys are legitimate, that's your fastest path.

Agent 0x99: No ransom paid. No ENTROPY funding. Recovery in under an hour.

Agent 0x99: The cost is the agreement: publish the evidence at the press terminal.

Agent 0x99: Make sure you understand what you're agreeing to before you initiate recovery.

+ [The keys are real  --  Ghost transmitted them]
    Agent 0x99: Then use them. And follow through at the press terminal.
    Agent 0x99: Or don't. You're the one who has to decide what that means.
    -> support_hub

+ [I haven't decided what to do with Ghost's deal yet]
    Agent 0x99: Then decide before you walk into the recovery console. Don't go in uncertain.
    -> support_hub

=== discuss_ideology ===
#speaker:agent_0x99
~ ideology_discussed = true

Agent 0x99: You've read Ghost's calculations. They projected deaths before the operation started and proceeded anyway.

Agent 0x99: This is what ENTROPY looks like across all six cells. Not opportunistic criminals. True believers with risk models.

+ [How do you fight that?]
    Agent 0x99: Evidence and consequences, long term.
    Agent 0x99: True believers lose credibility when their predicted outcomes don't materialize.
    Agent 0x99: If hospitals sector-wide improve security after this -- and attacks drop -- Ghost's ideology loses its proof of concept.
    Agent 0x99: Frustrating timeline. But that's what works against ideological movements.
    -> support_hub

+ [Ghost's diagnosis is hard to argue with]
    Agent 0x99: I know. Institutional negligence is real. The board's decisions were genuinely bad.
    Agent 0x99: The question isn't whether the diagnosis is accurate. It's whether calculating deaths as acceptable costs and proceeding anyway is a line you can cross and still be the good guys.
    Agent 0x99: Ghost crossed it. That's why we're here.
    -> support_hub

+ [Understood. Staying focused.]
    -> support_hub

=== hint_press_terminal ===
#speaker:agent_0x99

Agent 0x99: Conference room. Hospital communications terminal.

Agent 0x99: The board liability email. Marcus's six months of warnings. The full budget record.

Agent 0x99: Transmit and it's public record within the hour. Don't transmit and it stays internal.

Agent 0x99: That's the last decision of this mission.

+ [What's the right choice here?]
    Agent 0x99: Public exposure forces sector-wide change. Forty-three other hospitals on ENTROPY's reconnaissance list might patch before someone teaches them the same lesson.
    Agent 0x99: Quiet resolution protects St. Catherine's. Marcus's vindication stays an internal matter.
    Agent 0x99: I'm not going to tell you which is right.
    -> support_hub

+ {ghost_deal_accepted} [I agreed to publish as part of Ghost's deal]
    Agent 0x99: Then you know what you need to do. The question is whether you're honouring it.
    -> support_hub

+ [Got it. Conference room.]
    -> support_hub

// ===========================================
// GENERAL ADVICE (state-aware fallback)
// ===========================================

=== general_advice ===
#speaker:agent_0x99

{not dr_kim_met:
    Agent 0x99: Get to Dr. Kim first. Authorization unlocks everything else.
    -> support_hub
}
{dr_kim_met and not flag_ssh_submitted:
    Agent 0x99: Marcus is your route to the server room. Build trust -- cooperation beats lockpicking.
    -> support_hub
}
{flag_ssh_submitted and not offline_keys_recovered:
    Agent 0x99: Two tracks in the server room: VM exploitation for digital keys, and the physical safe for offline keys.
    Agent 0x99: You want both for independent recovery.
    -> support_hub
}
{offline_keys_recovered and not ransom_decision_made:
    Agent 0x99: You have everything you need. Recovery console in the server room.
    Agent 0x99: Take the decision you can live with. But remember the clock.
    -> support_hub
}
{ransom_decision_made:
    Agent 0x99: Conference room. Press terminal. That's the last step.
    -> support_hub
}
Agent 0x99: You know what you're doing. Trust your training.
-> support_hub
