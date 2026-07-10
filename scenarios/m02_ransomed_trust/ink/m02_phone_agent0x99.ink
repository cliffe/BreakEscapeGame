// ===========================================
// PHONE NPC: Agent HaX (Handler Support)
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
VAR scanning_exploitation_guide_hint_given = false
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
VAR scanning_exploitation_guide_offered = false
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

Agent HaX: {player_name()}. You're in. Good.

Agent HaX: 47 patients. Backup power. Twelve hours.

Agent HaX: Start with Dr. Kim -- CTO, west of reception. She has the authority you need to access IT systems. Then find Marcus Webb in IT.

+ [Understood]
    -> support_hub

+ [What should I know going in?]
    Agent HaX: The institutional failure here is going to make you angry. Stay professional.
    Agent HaX: Marcus Webb warned them about this vulnerability six months ago. Seven times. Nobody listened.
    Agent HaX: Don't let their negligence distract from the mission. People are depending on you right now.
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
+ {dr_kim_met and not flag_ssh_submitted and not hint_lockpick_given} [Any tips for getting into the server room?]
    -> hint_lockpick

// Social engineering Marcus
+ {dr_kim_met and not flag_ssh_submitted and not hint_password_given} [How do I get Marcus to cooperate?]
    -> hint_password

// Optional field guide: lockpicking (offered early -- offices off reception are locked)
+ {lockpicking_guide_offered and not lockpicking_guide_hint_given} [Can you send me the lockpicking field guide?]
    -> request_lockpicking_guide

// Optional field guide: scanning/recon
+ {scanning_guide_offered and not scanning_guide_hint_given} [Can you send me the scanning field guide?]
    -> request_scanning_guide

// Optional field guide: SSH access and bruteforce
+ {ssh_guide_offered and not ssh_guide_hint_given} [Can you send me the SSH access and bruteforce field guide?]
    -> request_ssh_guide

// VM phase: ProFTPD
+ {flag_ssh_submitted and not flag_proftpd_submitted and not hint_vm_given} [I need help with the ProFTPD exploitation.]
    -> hint_vm

// Optional field guide: vulnerability triage
+ {vulnerability_guide_offered and not vulnerability_guide_hint_given} [Can you send me the vulnerability analysis field guide?]
    -> request_vulnerability_guide

// Optional field guide: scanning-to-exploitation (offered on reaching the Kali/VM box)
+ {scanning_exploitation_guide_offered and not scanning_exploitation_guide_hint_given} [Can you send me the scanning and exploitation field guide?]
    -> request_scanning_exploitation_guide

// Optional field guide: exploitation workflow
+ {exploitation_guide_offered and not exploitation_guide_hint_given} [Can you send me the ProFTPD exploitation field guide?]
    -> request_exploitation_guide

// Optional field guide: privilege escalation
+ {privesc_guide_offered and not privesc_guide_hint_given} [Can you send me the privilege escalation field guide?]
    -> request_privesc_guide

// Encoding/decoding (useful throughout VM phase)
+ {flag_ssh_submitted and not hint_encoding_given} [I need help with encoding and decoding.]
    -> hint_encoding

// Safe phase: offline keys
+ {flag_database_submitted and not offline_keys_recovered and not hint_pin_given} [I need the offline backup keys]
    -> hint_pin_safe

// Decision phase: moral support
+ {offline_keys_recovered and not ransom_decision_made and not hint_ransom_given} [Can you help me think through the ransom decision?]
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
    Agent HaX: Copy that. Call anytime, {player_name()}.
    #exit_conversation
    -> DONE

// ===========================================
// GHOST REACTIONS
// ===========================================

=== ghost_contact_reaction ===
#speaker:agent_0x99
~ ghost_reaction_discussed = true

Agent HaX: Ghost's watching the network. They've been on it since before you arrived.

Agent HaX: They know which rooms you've accessed. They may be able to suspend your SAFETYNET connection temporarily.

Agent HaX: Don't let that rattle you. They can't act against you directly. This is psychological pressure.

+ [Ghost seems to think they're justified]
    Agent HaX: They do. ENTROPY cells are ideological -- they've convinced themselves that calculated harm is acceptable if it changes the system.
    Agent HaX: Ghost isn't wrong about St. Catherine's negligence. That doesn't make their methods right.
    Agent HaX: Their logic is their problem. Your job is those 47 patients.
    -> support_hub

+ [Ghost cut my SAFETYNET connection briefly]
    Agent HaX: Noted. Network-level access. We knew they had it.
    Agent HaX: Don't rely on me for anything time-critical from here on. What you're doing has to be done in the field.
    -> support_hub

+ [Understood. Staying focused.]
    -> support_hub

=== ghost_deal_reaction ===
#speaker:agent_0x99
~ ghost_deal_discussed = true

Agent HaX: You made a deal with Ghost.

Agent HaX: Free decryption keys. No ransom payment. Faster recovery, ENTROPY denied the money.

Agent HaX: In exchange: you publish the board's negligence from the press terminal.

#speaker:narrator
Narrator: A pause.

#speaker:agent_0x99
Agent HaX: Ghost gets exactly what they wanted without spending $87,000.

Agent HaX: You're still the one making the final choice at that terminal. Ghost's deal doesn't override your judgment.

+ [Is it wrong to have taken it?]
    Agent HaX: I don't know. You took resources from a terrorist to save lives and deny them funding simultaneously.
    Agent HaX: The ethics depend entirely on what you do at the press terminal. Don't let Ghost own that decision.
    -> support_hub

+ [I'm going to honour it]
    Agent HaX: Then publish everything. Make it count.
    -> support_hub

+ [I might not honour it]
    Agent HaX: That's your call. Ghost will notice the breach. So will I.
    -> support_hub

=== board_email_reaction ===
#speaker:agent_0x99
~ board_email_discussed = true

Agent HaX: The board was planning to terminate Marcus and bury his warnings before anyone asked questions.

Agent HaX: That's not negligence anymore. That's deliberate cover-up of the conditions that created this crisis.

Agent HaX: That email is going to matter at the press terminal. Keep it in mind.

+ [This changes how I see the exposure decision]
    Agent HaX: It should. Publishing just the budget decisions is one thing. Publishing the cover-up is another.
    Agent HaX: The hospital made two distinct failures. You'll decide which gets the full public record.
    -> support_hub

+ [Marcus had no idea the board was planning this]
    Agent HaX: Probably not. He warned them in good faith.
    Agent HaX: If you want his vindication to be public, the press terminal is the mechanism.
    -> support_hub

+ [Noted]
    -> support_hub

// ===========================================
// CONTEXTUAL HINTS
// ===========================================

=== hint_start ===
#speaker:agent_0x99
~ hint_start_given = true

Agent HaX: Dr. Kim. CTO. Office wing west of reception.

Agent HaX: She has authorization authority over IT access, server room, everything you need.

Agent HaX: She's under extreme pressure -- the board is pushing for a ransom vote. She needs someone who can offer an alternative.

+ [What about Marcus Webb?]
    Agent HaX: IT administrator. East corridor, IT department.
    Agent HaX: He's the one who warned them about this vulnerability six months ago. He's furious and guilty in equal measure.
    Agent HaX: Kim first, then Marcus. Order matters.
    -> support_hub

+ [Understood]
    -> support_hub

=== hint_lockpick ===
#speaker:agent_0x99
~ hint_lockpick_given = true

Agent HaX: Server room is RFID-locked. You need Marcus's keycard.

Agent HaX: Build enough trust with Marcus and he'll hand it over voluntarily. He wants those systems recovered as much as anyone.

Agent HaX: If he's being difficult -- the IT department itself uses a standard pin-tumbler lock. Lockpicks work on it.

+ [What if Marcus is in a defensive spiral?]
    Agent HaX: Validate the ignored-warnings angle. He needs someone to believe him.
    Agent HaX: Don't challenge him about responsibility. That's not the conversation you need right now.
    -> support_hub

+ [Got it]
    -> support_hub

=== hint_password ===
#speaker:agent_0x99
~ hint_password_given = true

Agent HaX: Marcus is a social engineering target. He's been dismissed by management for six months.

Agent HaX: Sympathize with the experience. Tell him you've read his warnings. Tell him you believe him.

Agent HaX: High trust gets you his keycard and the employee password list. Low trust gets you nothing useful.

+ [What passwords specifically?]
    Agent HaX: Hospital environments use weak credentials. Birthdays, company names, simple variations.
    Agent HaX: Emma2018. Hospital1987. StCatherines. Check his desk too -- he may have written something down.
    -> support_hub

+ [Understood]
    -> support_hub

=== hint_vm ===
#speaker:agent_0x99
~ hint_vm_given = true

Agent HaX: CVE-2010-4652. ProFTPD 1.3.5 backdoor. Remote code execution via a vulnerability in the source code itself.

Agent HaX: Patched in 2011. St. Catherine's is running a 2010 version. Your target.

Agent HaX: The exploit gets you root on the backup server. From there, navigate the filesystem for encrypted database backups.

+ [What's the full exploit chain?]
    Agent HaX: SSH access to confirm the server's reachable. ProFTPD exploit for root. Then filesystem navigation to the database backups.
    Agent HaX: Submit each step as a flag at the drop-site terminal. Each flag unlocks the next piece of intelligence.
    -> support_hub

+ [Got it]
    -> support_hub

=== request_lockpicking_guide ===
#speaker:agent_0x99
~ lockpicking_guide_hint_given = true
#set_variable:lockpicking_guide_requested:true
#give_item:lab-workstation:m02_lockpicking_field_guide

Agent HaX: Lockpicking guide uploaded to your terminal.

Agent HaX: Light tension, find the binding pin, set it, repeat. Read the lock by feel -- don't force it.

+ [Received]
    Agent HaX: Quiet and patient gets you through any of those doors. Go.
    -> support_hub

=== request_ssh_guide ===
#speaker:agent_0x99
~ ssh_guide_hint_given = true
#set_variable:ssh_guide_requested:true
#give_item:lab-workstation:m02_ssh_bruteforce_field_guide

Agent HaX: SSH access and bruteforce guide sent.

Agent HaX: Confirm the port's open, test a sensible username against a focused wordlist with Hydra, then connect. Foothold first, exploitation after.

+ [Got it]
    Agent HaX: Start small on the wordlist and expand only if you need to. Move.
    -> support_hub

=== request_privesc_guide ===
#speaker:agent_0x99
~ privesc_guide_hint_given = true
#set_variable:privesc_guide_requested:true
#give_item:lab-workstation:m02_privilege_escalation_field_guide

Agent HaX: Privilege escalation guide uploaded.

Agent HaX: Enumerate with sudo -l first, then take the smallest step that reaches the files you need. Read with sudo cat where you can.

+ [Understood]
    Agent HaX: Least intrusive path that works. Don't kick down doors you can walk through.
    -> support_hub

=== request_scanning_guide ===
#speaker:agent_0x99
~ scanning_guide_hint_given = true
#set_variable:scanning_guide_requested:true
#give_item:lab-workstation:m02_scanning_field_guide

Agent HaX: Uploading the recon guide now.

Agent HaX: Use it to map live hosts, enumerate services, and confirm the backup server attack surface before you commit to exploitation.

+ [Received]
    Agent HaX: Good. Fast reconnaissance, clean notes, then strike.
    -> support_hub

=== request_vulnerability_guide ===
#speaker:agent_0x99
~ vulnerability_guide_hint_given = true
#set_variable:vulnerability_guide_requested:true
#give_item:lab-workstation:m02_vulnerability_field_guide

Agent HaX: Sending vulnerability analysis guide.

Agent HaX: You already have access. Now classify exposed services, match likely weakness classes, and avoid wasting time on dead paths.

+ [Got it]
    Agent HaX: Exactly. Prioritize what is exploitable now, not everything that looks noisy.
    -> support_hub

=== request_scanning_exploitation_guide ===
#speaker:agent_0x99
~ scanning_exploitation_guide_hint_given = true
#set_variable:scanning_exploitation_guide_requested:true
#give_item:lab-workstation:m02_scanning_exploitation_field_guide

Agent HaX: Scanning and exploitation guide uploaded.

Agent HaX: It runs the whole chain -- Nmap fingerprint, research the CVE, feed the scan into Metasploit, configure the exploit and payload, then validate the shell. Work it top to bottom and you won't miss a step.

+ [Thanks, I needed this]
    Agent HaX: Scan first, match the version exactly, and don't improvise until you've got a stable session.
    -> support_hub

=== request_exploitation_guide ===
#speaker:agent_0x99
~ exploitation_guide_hint_given = true
#set_variable:exploitation_guide_requested:true
#give_item:lab-workstation:m02_exploitation_field_guide

Agent HaX: ProFTPD exploitation workflow uploaded.

Agent HaX: It covers Metasploit module selection, payload/listener alignment, and post-exploitation checks so you can execute without guesswork.

+ [Thanks, I needed this]
    Agent HaX: Use it, adapt to what the target gives you, and keep momentum.
    -> support_hub

=== hint_encoding ===
#speaker:agent_0x99
~ hint_encoding_given = true

Agent HaX: Encoding is not encryption. Important distinction.

Agent HaX: Encoding -- Base64, ROT13, hex -- transforms data for storage or transit. No secret key. Reversible by anyone with the right tool.

Agent HaX: Encryption requires a key. Without it, the data is meaningless.

Agent HaX: ENTROPY uses encoding for obfuscation and encryption for actual security. When you find something encoded, use CyberChef.

+ [How do I use CyberChef for Base64?]
    Agent HaX: Workstation in the server room. Open CyberChef, drag "From Base64" into the recipe, paste your text. Instant decode.
    Agent HaX: For ROT13, same process -- drag the ROT13 operation in.
    -> support_hub

+ [Understood]
    -> support_hub

=== hint_pin_safe ===
#speaker:agent_0x99
~ hint_pin_given = true

Agent HaX: Ghost's logs confirmed offline backup keys are in a physical PIN safe. Emergency equipment storage, south corridor.

Agent HaX: Four-digit code. Hospitals use institutional dates -- founding years, significant administrative anniversaries.

Agent HaX: The answer's somewhere in the building. Check plaques, framed documents, administrative notices.

+ [I've already found a clue]
    Agent HaX: Trust it. Hospitals are consistent about this kind of thing.
    -> support_hub

+ [What if I can't find the PIN?]
    Agent HaX: There should be a PIN cracker device in the storage room itself. Two minutes, covers all combinations. Last resort.
    -> support_hub

+ [Got it]
    -> support_hub

=== hint_ransom_decision ===
#speaker:agent_0x99
~ hint_ransom_given = true

Agent HaX: You have both key types. That means independent recovery is genuinely on the table.

Agent HaX: Pay the ransom: 1-2 patient deaths, $87,000 funds ENTROPY's next operation.

Agent HaX: Manual recovery: 4-6 patient deaths, ENTROPY gets nothing. The hospital recovers independently.

Agent HaX: Both choices save lives -- different timeframes, different costs. That's what makes it hard.

+ [What would you choose?]
    Agent HaX: I'm not going to answer that.
    Agent HaX: What I'll say: don't let Ghost's framing decide it for you. They designed this dilemma. Don't let them own your answer.
    -> support_hub

+ [Is there a third option?]
    {ghost_contacted_player:
        Agent HaX: Ghost may have offered one. Free keys in exchange for publishing the evidence.
        Agent HaX: If they did -- that's a real option. Fast recovery, no funding, but Ghost's lesson lands publicly.
        Agent HaX: It's your call whether to engage with that.
        -> support_hub
    }
    Agent HaX: Not through official channels. The recovery console has the options available to you.
    -> support_hub

+ [I'll make the call]
    Agent HaX: Good. Recovery console in the server room. Take the decision you can live with.
    -> support_hub

=== ghost_deal_recovery_advice ===
#speaker:agent_0x99

Agent HaX: If Ghost's keys are legitimate, that's your fastest path.

Agent HaX: No ransom paid. No ENTROPY funding. Recovery in under an hour.

Agent HaX: The cost is the agreement: publish the evidence at the press terminal.

Agent HaX: Make sure you understand what you're agreeing to before you initiate recovery.

+ [The keys are real  --  Ghost transmitted them]
    Agent HaX: Then use them. And follow through at the press terminal.
    Agent HaX: Or don't. You're the one who has to decide what that means.
    -> support_hub

+ [I haven't decided what to do with Ghost's deal yet]
    Agent HaX: Then decide before you walk into the recovery console. Don't go in uncertain.
    -> support_hub

=== discuss_ideology ===
#speaker:agent_0x99
~ ideology_discussed = true

Agent HaX: You've read Ghost's calculations. They projected deaths before the operation started and proceeded anyway.

Agent HaX: This is what ENTROPY looks like across all six cells. Not opportunistic criminals. True believers with risk models.

+ [How do you fight that?]
    Agent HaX: Evidence and consequences, long term.
    Agent HaX: True believers lose credibility when their predicted outcomes don't materialize.
    Agent HaX: If hospitals sector-wide improve security after this -- and attacks drop -- Ghost's ideology loses its proof of concept.
    Agent HaX: Frustrating timeline. But that's what works against ideological movements.
    -> support_hub

+ [Ghost's diagnosis is hard to argue with]
    Agent HaX: I know. Institutional negligence is real. The board's decisions were genuinely bad.
    Agent HaX: The question isn't whether the diagnosis is accurate. It's whether calculating deaths as acceptable costs and proceeding anyway is a line you can cross and still be the good guys.
    Agent HaX: Ghost crossed it. That's why we're here.
    -> support_hub

+ [Understood. Staying focused.]
    -> support_hub

=== hint_press_terminal ===
#speaker:agent_0x99

Agent HaX: Conference room. Hospital communications terminal.

Agent HaX: The board liability email. Marcus's six months of warnings. The full budget record.

Agent HaX: Transmit and it's public record within the hour. Don't transmit and it stays internal.

Agent HaX: That's the last decision of this mission.

+ [What's the right choice here?]
    Agent HaX: Public exposure forces sector-wide change. Forty-three other hospitals on ENTROPY's reconnaissance list might patch before someone teaches them the same lesson.
    Agent HaX: Quiet resolution protects St. Catherine's. Marcus's vindication stays an internal matter.
    Agent HaX: I'm not going to tell you which is right.
    -> support_hub

+ {ghost_deal_accepted} [I agreed to publish as part of Ghost's deal]
    Agent HaX: Then you know what you need to do. The question is whether you're honouring it.
    -> support_hub

+ [Got it. Conference room.]
    -> support_hub

// ===========================================
// GENERAL ADVICE (state-aware fallback)
// ===========================================

=== general_advice ===
#speaker:agent_0x99

{not dr_kim_met:
    Agent HaX: Get to Dr. Kim first. Authorization unlocks everything else.
    -> support_hub
}
{dr_kim_met and not flag_ssh_submitted:
    Agent HaX: Marcus is your route to the server room. Build trust -- cooperation beats lockpicking.
    -> support_hub
}
{flag_ssh_submitted and not offline_keys_recovered:
    Agent HaX: Two tracks in the server room: VM exploitation for digital keys, and the physical safe for offline keys.
    Agent HaX: You want both for independent recovery.
    -> support_hub
}
{offline_keys_recovered and not ransom_decision_made:
    Agent HaX: You have everything you need. Recovery console in the server room.
    Agent HaX: Take the decision you can live with. But remember the clock.
    -> support_hub
}
{ransom_decision_made:
    Agent HaX: Conference room. Press terminal. That's the last step.
    -> support_hub
}
Agent HaX: You know what you're doing. Trust your training.
-> support_hub
