// ================================================
// Mission 6: Follow the Money - Agent 0x99 Phone Support
// Financial Investigation Guidance & Event Reactions
// Provides help, hints, and contextual support
// ================================================

VAR password_hint_given = false
VAR blockchain_hint_given = false
VAR elena_guidance_given = false
VAR first_contact = true

// External variables
VAR player_name = "Agent 0x00"
VAR found_password_lists = false
VAR found_blockchain_evidence = false
VAR found_architects_fund = false
VAR elena_recruited = false
VAR elena_arrested = false
VAR cracking_guide_offered = false
VAR privesc_guide_offered = false
VAR recon_guide_offered = false
VAR rfid_guide_offered = false
VAR cracking_guide_hint_given = false
VAR privesc_guide_hint_given = false
VAR recon_guide_hint_given = false
VAR rfid_guide_hint_given = false
VAR flag1_submitted = false
VAR flag4_submitted = false
VAR blockchain_debrief_available = false
VAR fund_debrief_available = false
VAR reacted_password_lists = false
VAR reacted_first_server = false
VAR reacted_blockchain = false
VAR reacted_fund = false
VAR reacted_network = false

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

Agent HaX: {player_name}, you're inside HashChain Exchange. How's the compliance auditor cover holding up?

Agent HaX: This is a financial investigation. Follow the money, map the network, and find where ENTROPY's funding goes.

+ [Cover is solid so far]
    Agent HaX: Good. Elena should buy the FinCEN audit story. Crypto exchanges are constantly under regulatory scrutiny.
    -> support_hub
+ [What should I focus on first?]
    -> initial_guidance
+ [I'll call if I need help]
    #exit_conversation
    Agent HaX: Roger that. I'm tracking your progress. Call anytime.
    -> support_hub

=== initial_guidance ===
Agent HaX: Priority one: Build rapport with Elena Volkov, the CTO. She's your access point and potential recruit.

Agent HaX: Priority two: Access the backend servers. That's where the financial records are.

Agent HaX: Priority three: Map the complete ENTROPY financial network. Every transaction linking cells together.

-> support_hub

// ================================================
// SUPPORT HUB (General Help)
// ================================================

=== support_hub ===
#speaker:agent_0x99

Agent HaX: What do you need help with?

+ {not password_hint_given} [Password cracking guidance]
    -> password_help
+ {not blockchain_hint_given} [Blockchain analysis tips]
    -> blockchain_help
+ {not elena_guidance_given} [Elena Volkov recruitment strategy]
    -> elena_guidance
+ [Got any general advice?]
    -> general_advice

// Story beats -- reachable once the player has actually hit them
+ {found_password_lists and not reacted_password_lists} [I've got Volkov's wordlist. What do I do with it?]
    ~ reacted_password_lists = true
    -> on_password_lists_found
+ {flag1_submitted and not reacted_first_server} [First server is cracked. What now?]
    ~ reacted_first_server = true
    -> on_first_server_cracked
+ {blockchain_debrief_available and not reacted_blockchain} [Talk me through this transaction graph.]
    ~ reacted_blockchain = true
    -> on_blockchain_discovered
+ {fund_debrief_available and not reacted_fund} [I've found The Architect's Fund.]
    ~ reacted_fund = true
    -> on_architects_fund_discovered
+ {flag4_submitted and not reacted_network} [The whole estate is mapped. Where does that leave us?]
    ~ reacted_network = true
    -> on_network_complete

// Field guides -- offered only once the player has met the thing they explain
+ {cracking_guide_offered and not cracking_guide_hint_given} [Send me the password cracking field guide.]
    -> request_cracking_guide
+ {privesc_guide_offered and not privesc_guide_hint_given} [Send me the privilege escalation and credential reuse guide.]
    -> request_privesc_guide
+ {recon_guide_offered and not recon_guide_hint_given} [Send me the reconnaissance field guide.]
    -> request_recon_guide
+ {rfid_guide_offered and not rfid_guide_hint_given} [Send me the RFID cloning guide.]
    -> request_rfid_guide

+ [I'm good for now]
    #exit_conversation
    Agent HaX: Copy that. Call anytime.
    -> support_hub

// ================================================
// PASSWORD CRACKING HELP
// ================================================

=== password_help ===
~ password_hint_given = true

Agent HaX: Server passwords at crypto exchanges follow patterns. Think crypto-themed terms plus years.

Agent HaX: "bitcoin2024", "ethereum2025", "satoshi2024"—variations on cryptocurrency names and dates.

Agent HaX: Once you crack the first server, look for credential reuse. Admins get lazy with multiple systems.

+ [What tools should I use?]
    Agent HaX: Your VM environment has Hydra for brute forcing and John the Ripper for hash cracking.
    Agent HaX: Look for password lists in Elena's inventory or around the trading floor.
    -> support_hub
+ [Got it, thanks]
    -> support_hub

// ================================================
// BLOCKCHAIN ANALYSIS HELP
// ================================================

=== blockchain_help ===
~ blockchain_hint_given = true

Agent HaX: Blockchain transactions are public, but privacy coins make tracing nearly impossible without internal records.

Agent HaX: Look for transaction analysis documents in the Blockchain Analysis Lab. They'll have wallet addresses and fund flows.

Agent HaX: Key targets: wallets from Mission 2's ransomware and Mission 5's espionage. They should all connect through HashChain.

+ [What am I looking for specifically?]
    Agent HaX: Destination wallets. A master fund receiving money from all cells.
    Agent HaX: If there's coordinated funding, the internal records will show it.
    -> support_hub
+ [Thanks]
    -> support_hub

// ================================================
// ELENA VOLKOV GUIDANCE
// ================================================

=== elena_guidance ===
~ elena_guidance_given = true

Agent HaX: Elena is brilliant but conflicted. She built this infrastructure for "financial freedom."

Agent HaX: Now it's funding ransomware, espionage, and attacks. Our psych profile says she's morally troubled.

+ [How do I recruit her?]
    -> recruitment_strategy
+ [What if she refuses?]
    -> arrest_strategy

=== recruitment_strategy ===
Agent HaX: Show her the consequences of her work. The ransomware casualties, the coordinated attacks, The Architect's plan.

Agent HaX: Appeal to her ethics, not her ideology. She's a cryptographer, not a terrorist.

Agent HaX: If she sees the full scope, she might flip. And {player_name}—her expertise would be invaluable intelligence.

-> support_hub

=== arrest_strategy ===
Agent HaX: If recruitment fails, arrest her. Eliminate her expertise from ENTROPY's network.

Agent HaX: But try recruitment first. A cryptographer of her caliber is worth the effort.

-> support_hub

// ================================================
// GENERAL ADVICE
// ================================================

=== general_advice ===
Agent HaX: Remember: Most employees at HashChain think they work at a legitimate exchange.

Agent HaX: Elena and Satoshi know about ENTROPY. The traders and analysts are likely innocent.

+ [What about Satoshi Nakamoto II?]
    -> satoshi_discussion
+ [What's the priority target?]
    -> priority_target
+ [Understood]
    -> support_hub

=== satoshi_discussion ===
Agent HaX: Satoshi is a true believer. "Financial freedom through cryptography."

Agent HaX: Useful for understanding Crypto Anarchist ideology, but don't expect cooperation.

Agent HaX: He'll justify everything in the name of accelerating the collapse of centralized finance.

-> support_hub

=== priority_target ===
Agent HaX: The Architect's Fund. A master wallet coordinating funding to all ENTROPY cells.

Agent HaX: If we find it, we can map the entire financial network and potentially seize the assets.

-> support_hub

// ================================================
// EVENT: PASSWORD LISTS FOUND
// ================================================

=== on_password_lists_found ===
#speaker:agent_0x99

Agent HaX: I see you obtained Elena's password dictionary. Smart.

Agent HaX: Crypto-themed passwords are common in this industry. Use that list against the backend servers.

Agent HaX: Hydra and John the Ripper will make quick work of weak passwords.

+ [Thanks for the tip]
    #exit_conversation
    -> support_hub
+ [Any other password hints?]
    -> password_help

// ================================================
// EVENT: FIRST SERVER CRACKED
// ================================================

=== on_first_server_cracked ===
#speaker:agent_0x99
#complete_task:submit_flag1
#unlock_task:submit_flag2

Agent HaX: First server access confirmed. Excellent password cracking, {player_name}.

Agent HaX: Now look for credential reuse. Same passwords across multiple servers is common.

Agent HaX: Each server you crack reveals more of the financial network.

+ [What am I looking for in the data?]
    Agent HaX: Transaction records, wallet addresses, anything linking ENTROPY cells together.
    Agent HaX: And keep an eye out for references to a master fund or coordinator.
    #exit_conversation
    -> support_hub
+ [On it]
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: BLOCKCHAIN EVIDENCE DISCOVERED
// ================================================

=== on_blockchain_discovered ===
#speaker:agent_0x99
#complete_task:find_transaction_records

Agent HaX: {player_name}, I'm seeing the blockchain transaction analysis you just found.

Agent HaX: This is incredible. Mission 2's ransomware—$2.4 million. Mission 5's espionage—$847,000.

Agent HaX: They all flow through HashChain's mixers to a single destination wallet.

+ [What's the destination?]
    -> architects_fund_hint
+ [This connects all the cells]
    -> cell_connections

=== architects_fund_hint ===
Agent HaX: The analysis calls it "1ARCHITECT9FUND."

Agent HaX: {player_name}, if this is real... this is the financial heart of ENTROPY.

Agent HaX: Find the complete records. We need to know how much money we're talking about and where it's going.

#exit_conversation
-> support_hub

=== cell_connections ===
Agent HaX: Exactly. Every ENTROPY cell we've encountered is financially connected through HashChain.

Agent HaX: Social Fabric, Crypto Anarchists, Insider Threat Initiative—all funded through this network.

Agent HaX: Find the complete allocation records. We need to map the entire structure.

#exit_conversation
-> support_hub

// ================================================
// EVENT: ARCHITECT'S FUND DISCOVERED
// ================================================

=== on_architects_fund_discovered ===
#speaker:agent_0x99
#complete_task:discover_architects_fund

Agent HaX: {player_name}... I just saw what you pulled from the data center.

Agent HaX: The Architect's Fund. $12.8 million USD. Allocated to six different ENTROPY cells.

Agent HaX: And the timeline says distribution in 72 hours.

+ [This is a coordinated attack]
    -> coordinated_attack
+ [180-340 projected casualties...]
    -> casualty_numbers

=== coordinated_attack ===
Agent HaX: All cells receiving funding simultaneously. That's not business as usual.

Agent HaX: {player_name}, this is the kind of intelligence that could let us move against multiple cells at once.

Agent HaX: But we need to decide: Do we seize the assets now, or monitor the transactions to map the complete network?

-> critical_choice_preview

=== casualty_numbers ===
Agent HaX: They've calculated projected casualties. They KNOW people will die.

Agent HaX: And they're calling it "The Architect's Masterpiece."

Agent HaX: {player_name}, this is bigger than any individual cell. This is the coordination we've been looking for.

-> critical_choice_preview

=== critical_choice_preview ===
Agent HaX: We're going to face a major choice here.

Agent HaX: Seize the cryptocurrency now—immediate impact, cuts ENTROPY funding, but ends our surveillance.

Agent HaX: Or monitor the transactions—long-term intelligence, map everyone receiving funds, but ENTROPY keeps operating.

+ [What do you recommend?]
    -> handler_recommendation
+ [I'll think about it]
    #exit_conversation
    Agent HaX: Take your time. This decision has strategic implications.
    -> support_hub

=== handler_recommendation ===
Agent HaX: Honestly? I don't know, {player_name}.

Agent HaX: Seizing $12.8 million cripples ENTROPY funding immediately. That saves lives.

Agent HaX: But monitoring reveals their entire network structure. That saves MORE lives long-term.

Agent HaX: This is above my pay grade. You'll make the call when the time comes.

#exit_conversation
-> support_hub

// ================================================
// EVENT: FINANCIAL NETWORK MAPPED
// ================================================

=== on_network_complete ===
#speaker:agent_0x99
#unlock_task:access_satoshi_office
#unlock_task:confront_satoshi

Agent HaX: Complete financial network mapped. Outstanding work, {player_name}.

Agent HaX: We now understand ENTROPY's entire funding infrastructure.

Agent HaX: Time for confrontation. Satoshi Nakamoto II should be accessible now.

Agent HaX: And {player_name}—whatever you decide about Elena, make it count. She's either a massive intelligence asset or a dangerous criminal.

+ [What about the asset seizure choice?]
    -> final_choice_reminder
+ [I'm ready]
    #exit_conversation
    Agent HaX: Good luck. You've done exceptional work on this mission.
    -> support_hub

=== final_choice_reminder ===
Agent HaX: That choice is yours to make during the confrontation.

Agent HaX: Seize the crypto assets—immediate impact, ENTROPY loses $12.8M funding.

Agent HaX: Or monitor the wallets—long-term intelligence, identify everyone receiving funds.

Agent HaX: Either choice has strategic value. I trust your judgment.

#exit_conversation
-> support_hub

// ================================================
// END OF PHONE SUPPORT
// ================================================

// ================================================
// FIELD GUIDES
// ================================================

=== request_cracking_guide ===
#speaker:agent_0x99
~ cracking_guide_hint_given = true
#set_variable:cracking_guide_hint_given=true
#give_item:lab-workstation:m06_cracking_field_guide
Agent HaX: Password cracking guide sent.

Agent HaX: Confirm the service is actually listening, point a focused wordlist at one sensible username, and read the failures as carefully as the successes. Elena's audit list is better than anything generic you could download.

+ [On it.]
    Agent HaX: Start narrow. Widen only when narrow fails.
    -> support_hub

=== request_privesc_guide ===
#speaker:agent_0x99
~ privesc_guide_hint_given = true
#set_variable:privesc_guide_hint_given=true
#give_item:lab-workstation:m06_privesc_field_guide
Agent HaX: Privilege escalation and credential reuse guide sent.

Agent HaX: One cracked account is a foothold, not an estate. Enumerate what that account can reach, then try the same credential everywhere before you try anything clever. The rack sheet in the server room says two of those boxes share a service account.

+ [Understood.]
    Agent HaX: Reuse first. Exploits second. It is almost always reuse.
    -> support_hub

=== request_recon_guide ===
#speaker:agent_0x99
~ recon_guide_hint_given = true
#set_variable:recon_guide_hint_given=true
#give_item:lab-workstation:m06_recon_field_guide
Agent HaX: Reconnaissance and network mapping guide sent.

Agent HaX: There is more than one server behind that terminal. Map the segment and fingerprint the services before you start guessing at logins -- you will save yourself an hour of knocking on doors that aren't there.

+ [Copy.]
    Agent HaX: Know the shape of the estate first. Then break into it.
    -> support_hub

=== request_rfid_guide ===
#speaker:agent_0x99
~ rfid_guide_hint_given = true
#set_variable:rfid_guide_hint_given=true
#give_item:lab-workstation:m06_rfid_field_guide
Agent HaX: RFID cloning guide sent.

Agent HaX: The cloner on the trading floor reads at conversational distance. Identify the protocol first -- some cards duplicate in one pass, some want the keys off them before they will talk.

+ [Got it.]
    Agent HaX: Stand close, act bored, read the card. Nobody has ever noticed.
    -> support_hub
