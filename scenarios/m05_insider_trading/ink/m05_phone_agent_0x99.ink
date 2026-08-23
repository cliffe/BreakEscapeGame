// ===========================================
// PHONE NPC: Agent 0x99 (Handler Support)
// Mission 5: Insider Trading
// Break Escape - Remote Support, Field Guides, Moral Sounding Board
// ===========================================

VAR first_contact = true

// ---- Mission state vars (synced from globalVars by engine at call-open) ----
VAR player_name = "Agent 0x00"
VAR evidence_level = 0
VAR entropy_program_exposed = false
VAR found_medical_bills = false
VAR found_torres_journal = false
VAR architect_approval_confirmed = false
VAR recruiter_contacted_player = false
VAR flag1_submitted = false
VAR flag2_submitted = false
VAR flag3_submitted = false
VAR flag4_submitted = false
VAR bludit_server_discovered = false
VAR torres_identified = false

// Field-guide exposure flags. Engine-owned: each _offered is set by an
// eventMapping when the player actually meets the thing the guide is about
// (exposure-gated, never time-gated), and each _hint_given is set here when
// the guide is handed over.
VAR rfid_guide_offered = false
VAR rfid_guide_hint_given = false
VAR bludit_guide_offered = false
VAR bludit_guide_hint_given = false
VAR lockpicking_guide_offered = false
VAR lockpicking_guide_hint_given = false
VAR recon_guide_offered = false
VAR recon_guide_hint_given = false

// Hub topic retirement flags
VAR recruitment_method_discussed = false
VAR leverage_discussed = false
VAR journal_discussed = false
VAR architect_discussed = false
VAR recruiter_discussed = false
VAR flag1_discussed = false
VAR flag2_discussed = false
VAR flag3_discussed = false
VAR flag4_discussed = false
VAR confrontation_advice_given = false

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

Agent 0x99: {player_name}. You're in. Four hours before the final upload window closes, so let's not waste them.

Agent 0x99: Patricia Morgan runs security here — she's your handler on the ground and she called this in. Get her the picture as you build it.

Agent 0x99: Somewhere in that building is the person feeding ENTROPY's Insider Threat Initiative the quantum-safe key material for the 999 dispatch network. Find them before 3 AM.

+ [Understood]
    -> support_hub

+ [What should I know going in?]
    Agent 0x99: Nobody in that building is your enemy by default. This isn't a hostile compound — it's an office with one person who made a terrible choice under terrible pressure.
    Agent 0x99: Interview people. Build a profile. The evidence will tell you who, and it'll tell you why. You need both before you confront anyone.
    -> support_hub

+ [Anything I should be careful of?]
    Agent 0x99: Don't tip your hand before you're ready. If word gets back to the insider that Security has a name, they accelerate — and you lose the chance to turn them instead of just arresting them.
    Agent 0x99: And watch for anyone who reaches out to you directly. ENTROPY runs a recruitment pipeline. You might not be the only target in the building tonight.
    -> support_hub

// ===========================================
// SUPPORT HUB -- gated by mission state
// Options only appear when they're relevant, and retire once used
// (except the moral sounding board, which stays open)
// ===========================================

=== support_hub ===
#speaker:agent_0x99

// Evidence topics -- unlock as the player finds each piece
+ {entropy_program_exposed and not recruitment_method_discussed} [I've got the Insider Threat Initiative pamphlet -- is this real?]
    -> topic_recruitment_method

+ {found_medical_bills and not leverage_discussed} [Elena Torres has a $380,000 hole in her life. Is that the hook?]
    -> topic_leverage

+ {found_torres_journal and not journal_discussed} [I've read his journal. He knew.]
    -> topic_journal

+ {architect_approval_confirmed and not architect_discussed} [The Architect signed off on the casualty projection.]
    -> topic_architect

+ {recruiter_contacted_player and not recruiter_discussed} [The Recruiter just called me.]
    -> topic_recruiter

// VM flag status -- retiring, one per flag
+ {flag1_submitted and not flag1_discussed} [First flag's in. What's the plan for that Bludit box?]
    -> topic_flag1

+ {flag2_submitted and not flag2_discussed} [Second flag's in. I've got a shell.]
    -> topic_flag2

+ {flag3_submitted and not flag3_discussed} [Third flag's in. Found his staging manifest.]
    -> topic_flag3

+ {flag4_submitted and not flag4_discussed} [Fourth flag's in. Root, and the Architect's sign-off.]
    -> topic_flag4

// Optional field guide: RFID cloning (offered on first failed contact with the server hallway reader)
+ {rfid_guide_offered and not rfid_guide_hint_given} [Can you send me the RFID cloning field guide?]
    -> request_rfid_guide

// Optional field guide: Bludit CMS (offered on reaching the terminal)
+ {bludit_guide_offered and not bludit_guide_hint_given} [This Bludit box -- where do I even start?]
    -> request_bludit_guide

// Optional field guide: lockpicking (offered on first contact with the filing cabinet)
+ {lockpicking_guide_offered and not lockpicking_guide_hint_given} [Can you send me the lockpicking field guide?]
    -> request_lockpicking_guide

// Optional field guide: reconnaissance (offered alongside the Bludit terminal)
+ {recon_guide_offered and not recon_guide_hint_given} [Can you send me the network recon field guide?]
    -> request_recon_guide

// Confrontation approach -- once the case is strong enough
+ {evidence_level >= 4 and not confrontation_advice_given} [I have enough. Do I go in soft or hard?]
    -> confrontation_advice

// Moral sounding board -- returnable, not retired
+ {evidence_level >= 2} [What ENTROPY did to him -- I need to talk it through.]
    -> moral_sounding_board

// Always available
+ [Got any general advice?]
    -> general_advice

+ [I'm good, just checking in]
    Agent 0x99: Stay focused. You're on a timeline.
    #exit_conversation
    -> DONE

// ===========================================
// EVIDENCE TOPICS
// ===========================================

=== topic_recruitment_method ===
#speaker:agent_0x99
~ recruitment_method_discussed = true

Agent 0x99: Real, and textbook. Phase one is financial vulnerability assessment. Phase two, contact and an offer. Phase three, they radicalize you gradually until the casualties stop feeling like the point.

Agent 0x99: That pamphlet didn't fall out of someone's bag by accident. Somebody in that building is either running the pipeline or already caught in it.

+ [So I'm looking for a target, not a recruiter]
    Agent 0x99: Probably a target. ENTROPY doesn't usually put the recruiter on-site — too much exposure. Look for someone the profile fits: access, and a reason to need money fast.
    -> support_hub

+ [Noted]
    -> support_hub

=== topic_leverage ===
#speaker:agent_0x99
~ leverage_discussed = true

Agent 0x99: $380,000 in medical debt, insurance claim denied, and a wife with Stage 3 cancer. That's not a coincidence, that's a target file.

Agent 0x99: ENTROPY doesn't recruit ideologues first. They recruit desperate people and sell them the ideology afterwards, to make the choice feel like it was theirs.

+ [That's monstrous]
    Agent 0x99: It's efficient. Which is worse, depending on your mood tonight.
    -> support_hub

+ [Understood]
    -> support_hub

=== topic_journal ===
#speaker:agent_0x99
~ journal_discussed = true

Agent 0x99: Then you've seen the rationalization work in real time. Thirty to forty-five lives, and he wrote it down and kept going anyway.

Agent 0x99: That's the part that should worry you more than the recruitment pitch. He's not confused about the cost. He's decided he can live with it.

+ [Does that change how I should approach him?]
    Agent 0x99: It means don't expect him to be surprised when you lay out what he's done. He already knows. What you're offering him is a way out he hasn't let himself consider yet.
    -> support_hub

+ [Noted]
    -> support_hub

=== topic_architect ===
#speaker:agent_0x99
~ architect_discussed = true

Agent 0x99: Read that twice. A named casualty projection, reviewed, and signed off as an acceptable cost of doing business.

Agent 0x99: That's not a rogue cell improvising. That's a chain of command that priced human lives and approved the invoice. It's the strongest evidence you'll get all night — it proves this goes above Torres.

+ [This is bigger than one insider]
    Agent 0x99: It always was. Torres is the delivery mechanism. The Architect is the decision. Keep both in the file.
    -> support_hub

+ [Understood]
    -> support_hub

=== topic_recruiter ===
#speaker:agent_0x99
~ recruiter_discussed = true

Agent 0x99: She's ENTROPY's talent pipeline, dressed up as an executive search firm. If she called you directly, you're close enough to worry her.

Agent 0x99: Whatever she offered you, remember she's very good at making a bad trade sound reasonable. That's the entire job.

+ [She tried to sell me a deal]
    Agent 0x99: Of course she did. Weigh it on its own terms, not on how reasonable she made it sound. Her voice is the product.
    -> support_hub

+ [I'll be careful]
    -> support_hub

// ===========================================
// FLAG STATUS TOPICS
// ===========================================

=== topic_flag1 ===
#speaker:agent_0x99
~ flag1_discussed = true

Agent 0x99: First flag verified. That handover note was sloppy IT work — but it got you the login.

Agent 0x99: Keep working that Bludit server. Three more flags to go.

-> support_hub

=== topic_flag2 ===
#speaker:agent_0x99
~ flag2_discussed = true

Agent 0x99: Second flag secured. Authenticated image-upload RCE — you've got a shell.

Agent 0x99: You're building the digital evidence chain. Good work.

-> support_hub

=== topic_flag3 ===
#speaker:agent_0x99
~ flag3_discussed = true

Agent 0x99: Third flag verified. Torres' own staging manifest — the Data Package Manifest.

Agent 0x99: One more flag — the Architect's authorisation. Find it.

-> support_hub

=== topic_flag4 ===
#speaker:agent_0x99
~ flag4_discussed = true

Agent 0x99: Final flag secured. The Architect's acquisition authorisation.

Agent 0x99: A casualty projection, signed off and filed as acceptable cost. This proves ENTROPY's leadership approved the operation. Excellent work.

-> support_hub

// ===========================================
// FIELD GUIDE HANDOVERS
// Each sets its _hint_given so the offer retires, and pushes the
// lab-workstation item into the player's inventory.
// ===========================================

=== request_rfid_guide ===
#speaker:agent_0x99
~ rfid_guide_hint_given = true
#give_item:lab-workstation:safetynet_field_guide_rfid_cloning

Agent 0x99: Sending it now. Read the card, crack the keys, emulate it at the reader — that's the whole shape of it.

+ [Received]
    Agent 0x99: That badge reader's the only thing between you and the server hallway. Go.
    -> support_hub

=== request_bludit_guide ===
#speaker:agent_0x99
~ bludit_guide_hint_given = true
#give_item:lab-workstation:safetynet_field_guide_bludit_cms

Agent 0x99: Bludit CMS guide uploaded. Start with what's leaked in plain sight, then work up to an authenticated image-upload RCE for the shell.

+ [Got it]
    Agent 0x99: Recon first. Don't skip straight to exploitation — the leaked credentials get you further, faster.
    -> support_hub

=== request_lockpicking_guide ===
#speaker:agent_0x99
~ lockpicking_guide_hint_given = true
#give_item:lab-workstation:safetynet_field_guide_lockpicking

Agent 0x99: Lockpicking guide uploaded to your terminal.

Agent 0x99: Light tension, find the binding pin, set it, repeat. Read the lock by feel — don't force it.

+ [Received]
    Agent 0x99: Quiet and patient gets you through that cabinet. Go.
    -> support_hub

=== request_recon_guide ===
#speaker:agent_0x99
~ recon_guide_hint_given = true
#give_item:lab-workstation:safetynet_field_guide_recon_network_mapping

Agent 0x99: Uploading the recon guide now.

Agent 0x99: Use it to map what's alive on that network before you touch anything — the Bludit box won't be the only thing listening.

+ [Received]
    Agent 0x99: Fast reconnaissance, clean notes, then strike.
    -> support_hub

// ===========================================
// CONFRONTATION ADVICE
// ===========================================

=== confrontation_advice ===
#speaker:agent_0x99
~ confrontation_advice_given = true

Agent 0x99: You have enough to move. Now it's a question of how.

Agent 0x99: Soft: give him the exit ENTROPY never offered — turn double agent, keep his family whole, feed us the network from inside. Slower, and it depends entirely on whether he wants out.

Agent 0x99: Hard: arrest him clean, evidence in hand, no negotiation. Faster, safer for you, and it's the version where nobody gets a second chance to change their mind.

+ [Which do you recommend?]
    Agent 0x99: I'm not going to answer that. You've read his journal. You know what he's carrying. That has to be your call, not mine.
    -> support_hub

+ [I'll decide when I'm standing in front of him]
    Agent 0x99: That's honestly the right answer. Read the room when you get there.
    -> support_hub

// ===========================================
// MORAL SOUNDING BOARD -- returnable hub topic
// ===========================================

=== moral_sounding_board ===
#speaker:agent_0x99

Agent 0x99: ENTROPY weaponizes suffering. They find someone drowning and offer a rope with a hook hidden in it. That's not an excuse for what he's done — it's the machine that built the choice.

Agent 0x99: But they still made choices. Every step from that first pamphlet to tonight's upload window, Torres could have walked into Patricia's office instead. He didn't.

+ [Does knowing why change what he deserves?]
    Agent 0x99: It changes what's just, maybe. It doesn't undo thirty to forty-five projected deaths if that upload goes out. Both things are true at once — that's the part nobody's philosophy handles cleanly.
    -> support_hub

+ [What happens to people like him after this?]
    Agent 0x99: Depends entirely on what you decide tonight. Turned, arrested, or worse — each one writes a different ending for him and for Elena. That's not a small thing to be carrying, {player_name}.
    -> support_hub

+ [I don't know what I think yet]
    Agent 0x99: You don't have to, not until you're standing in front of him. Call me again if it helps to talk it through.
    -> support_hub

// ===========================================
// GENERAL ADVICE (state-aware fallback)
// ===========================================

=== general_advice ===
#speaker:agent_0x99

{not entropy_program_exposed and not found_medical_bills and not found_torres_journal:
    Agent 0x99: Start with people. Interview the staff, and keep your eyes open in the break room and offices. Evidence surfaces from conversation as much as searches.
    -> support_hub
}
{(entropy_program_exposed or found_medical_bills or found_torres_journal) and evidence_level < 4:
    Agent 0x99: You have leads. Now correlate them — physical evidence from the offices plus digital evidence from the Bludit server gets you to a name and a case.
    -> support_hub
}
{evidence_level >= 4 and not torres_identified:
    Agent 0x99: You have enough evidence. Name your suspect to Patricia and get ready to confront him.
    -> support_hub
}
{torres_identified:
    Agent 0x99: You've named him. Whatever you decide when you face him, be ready for anything — ENTROPY trains people in counter-interrogation.
    -> support_hub
}
Agent 0x99: You know what you're doing. Trust your training.
-> support_hub
