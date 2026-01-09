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

Agent 0x99: {player_name}, you're inside HashChain Exchange. How's the compliance auditor cover holding up?

Agent 0x99: This is a financial investigation. Follow the money, map the network, and find where ENTROPY's funding goes.

+ [Cover is solid so far]
    Agent 0x99: Good. Elena should buy the FinCEN audit story. Crypto exchanges are constantly under regulatory scrutiny.
    -> support_hub
+ [What should I focus on first?]
    -> initial_guidance
+ [I'll call if I need help]
    #exit_conversation
    Agent 0x99: Roger that. I'm tracking your progress. Call anytime.
    -> support_hub

=== initial_guidance ===
Agent 0x99: Priority one: Build rapport with Elena Volkov, the CTO. She's your access point and potential recruit.

Agent 0x99: Priority two: Access the backend servers. That's where the financial records are.

Agent 0x99: Priority three: Map the complete ENTROPY financial network. Every transaction linking cells together.

-> support_hub

// ================================================
// SUPPORT HUB (General Help)
// ================================================

=== support_hub ===
#speaker:agent_0x99

Agent 0x99: What do you need help with?

+ {not password_hint_given} [Password cracking guidance]
    -> password_help
+ {not blockchain_hint_given} [Blockchain analysis tips]
    -> blockchain_help
+ {not elena_guidance_given} [Elena Volkov recruitment strategy]
    -> elena_guidance
+ [General mission advice]
    -> general_advice
+ [I'm good for now]
    #exit_conversation
    Agent 0x99: Copy that. Call anytime.
    -> support_hub

// ================================================
// PASSWORD CRACKING HELP
// ================================================

=== password_help ===
~ password_hint_given = true

Agent 0x99: Server passwords at crypto exchanges follow patterns. Think crypto-themed terms plus years.

Agent 0x99: "bitcoin2024", "ethereum2025", "satoshi2024"—variations on cryptocurrency names and dates.

Agent 0x99: Once you crack the first server, look for credential reuse. Admins get lazy with multiple systems.

+ [What tools should I use?]
    Agent 0x99: Your VM environment has Hydra for brute forcing and John the Ripper for hash cracking.
    Agent 0x99: Look for password lists in Elena's inventory or around the trading floor.
    -> support_hub
+ [Got it, thanks]
    -> support_hub

// ================================================
// BLOCKCHAIN ANALYSIS HELP
// ================================================

=== blockchain_help ===
~ blockchain_hint_given = true

Agent 0x99: Blockchain transactions are public, but privacy coins make tracing nearly impossible without internal records.

Agent 0x99: Look for transaction analysis documents in the Blockchain Analysis Lab. They'll have wallet addresses and fund flows.

Agent 0x99: Key targets: wallets from Mission 2's ransomware and Mission 5's espionage. They should all connect through HashChain.

+ [What am I looking for specifically?]
    Agent 0x99: Destination wallets. A master fund receiving money from all cells.
    Agent 0x99: If there's coordinated funding, the internal records will show it.
    -> support_hub
+ [Thanks]
    -> support_hub

// ================================================
// ELENA VOLKOV GUIDANCE
// ================================================

=== elena_guidance ===
~ elena_guidance_given = true

Agent 0x99: Elena is brilliant but conflicted. She built this infrastructure for "financial freedom."

Agent 0x99: Now it's funding ransomware, espionage, and attacks. Our psych profile says she's morally troubled.

+ [How do I recruit her?]
    -> recruitment_strategy
+ [What if she refuses?]
    -> arrest_strategy

=== recruitment_strategy ===
Agent 0x99: Show her the consequences of her work. The ransomware casualties, the coordinated attacks, The Architect's plan.

Agent 0x99: Appeal to her ethics, not her ideology. She's a cryptographer, not a terrorist.

Agent 0x99: If she sees the full scope, she might flip. And {player_name}—her expertise would be invaluable intelligence.

-> support_hub

=== arrest_strategy ===
Agent 0x99: If recruitment fails, arrest her. Eliminate her expertise from ENTROPY's network.

Agent 0x99: But try recruitment first. A cryptographer of her caliber is worth the effort.

-> support_hub

// ================================================
// GENERAL ADVICE
// ================================================

=== general_advice ===
Agent 0x99: Remember: Most employees at HashChain think they work at a legitimate exchange.

Agent 0x99: Elena and Satoshi know about ENTROPY. The traders and analysts are likely innocent.

+ [What about Satoshi Nakamoto II?]
    -> satoshi_discussion
+ [What's the priority target?]
    -> priority_target
+ [Understood]
    -> support_hub

=== satoshi_discussion ===
Agent 0x99: Satoshi is a true believer. "Financial freedom through cryptography."

Agent 0x99: Useful for understanding Crypto Anarchist ideology, but don't expect cooperation.

Agent 0x99: He'll justify everything in the name of accelerating the collapse of centralized finance.

-> support_hub

=== priority_target ===
Agent 0x99: The Architect's Fund. A master wallet coordinating funding to all ENTROPY cells.

Agent 0x99: If we find it, we can map the entire financial network and potentially seize the assets.

-> support_hub

// ================================================
// EVENT: PASSWORD LISTS FOUND
// ================================================

=== on_password_lists_found ===
#speaker:agent_0x99

Agent 0x99: I see you obtained Elena's password dictionary. Smart.

Agent 0x99: Crypto-themed passwords are common in this industry. Use that list against the backend servers.

Agent 0x99: Hydra and John the Ripper will make quick work of weak passwords.

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

Agent 0x99: First server access confirmed. Excellent password cracking, {player_name}.

Agent 0x99: Now look for credential reuse. Same passwords across multiple servers is common.

Agent 0x99: Each server you crack reveals more of the financial network.

+ [What am I looking for in the data?]
    Agent 0x99: Transaction records, wallet addresses, anything linking ENTROPY cells together.
    Agent 0x99: And keep an eye out for references to a master fund or coordinator.
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

Agent 0x99: {player_name}, I'm seeing the blockchain transaction analysis you just found.

Agent 0x99: This is incredible. Mission 2's ransomware—$2.4 million. Mission 5's espionage—$847,000.

Agent 0x99: They all flow through HashChain's mixers to a single destination wallet.

+ [What's the destination?]
    -> architects_fund_hint
+ [This connects all the cells]
    -> cell_connections

=== architects_fund_hint ===
Agent 0x99: The analysis calls it "1ARCHITECT9FUND."

Agent 0x99: {player_name}, if this is real... this is the financial heart of ENTROPY.

Agent 0x99: Find the complete records. We need to know how much money we're talking about and where it's going.

#exit_conversation
-> support_hub

=== cell_connections ===
Agent 0x99: Exactly. Every ENTROPY cell we've encountered is financially connected through HashChain.

Agent 0x99: Social Fabric, Crypto Anarchists, Insider Threat Initiative—all funded through this network.

Agent 0x99: Find the complete allocation records. We need to map the entire structure.

#exit_conversation
-> support_hub

// ================================================
// EVENT: ARCHITECT'S FUND DISCOVERED
// ================================================

=== on_architects_fund_discovered ===
#speaker:agent_0x99
#complete_task:discover_architects_fund

Agent 0x99: {player_name}... I just saw what you pulled from the data center.

Agent 0x99: The Architect's Fund. $12.8 million USD. Allocated to six different ENTROPY cells.

Agent 0x99: And the timeline says distribution in 72 hours.

+ [This is a coordinated attack]
    -> coordinated_attack
+ [180-340 projected casualties...]
    -> casualty_numbers

=== coordinated_attack ===
Agent 0x99: All cells receiving funding simultaneously. That's not business as usual.

Agent 0x99: {player_name}, this is the kind of intelligence that could let us move against multiple cells at once.

Agent 0x99: But we need to decide: Do we seize the assets now, or monitor the transactions to map the complete network?

-> critical_choice_preview

=== casualty_numbers ===
Agent 0x99: They've calculated projected casualties. They KNOW people will die.

Agent 0x99: And they're calling it "The Architect's Masterpiece."

Agent 0x99: {player_name}, this is bigger than any individual cell. This is the coordination we've been looking for.

-> critical_choice_preview

=== critical_choice_preview ===
Agent 0x99: We're going to face a major choice here.

Agent 0x99: Seize the cryptocurrency now—immediate impact, cuts ENTROPY funding, but ends our surveillance.

Agent 0x99: Or monitor the transactions—long-term intelligence, map everyone receiving funds, but ENTROPY keeps operating.

+ [What do you recommend?]
    -> handler_recommendation
+ [I'll think about it]
    #exit_conversation
    Agent 0x99: Take your time. This decision has strategic implications.
    -> support_hub

=== handler_recommendation ===
Agent 0x99: Honestly? I don't know, {player_name}.

Agent 0x99: Seizing $12.8 million cripples ENTROPY funding immediately. That saves lives.

Agent 0x99: But monitoring reveals their entire network structure. That saves MORE lives long-term.

Agent 0x99: This is above my pay grade. You'll make the call when the time comes.

#exit_conversation
-> support_hub

// ================================================
// EVENT: FINANCIAL NETWORK MAPPED
// ================================================

=== on_network_complete ===
#speaker:agent_0x99
#unlock_task:access_satoshi_office
#unlock_task:confront_satoshi

Agent 0x99: Complete financial network mapped. Outstanding work, {player_name}.

Agent 0x99: We now understand ENTROPY's entire funding infrastructure.

Agent 0x99: Time for confrontation. Satoshi Nakamoto II should be accessible now.

Agent 0x99: And {player_name}—whatever you decide about Elena, make it count. She's either a massive intelligence asset or a dangerous criminal.

+ [What about the asset seizure choice?]
    -> final_choice_reminder
+ [I'm ready]
    #exit_conversation
    Agent 0x99: Good luck. You've done exceptional work on this mission.
    -> support_hub

=== final_choice_reminder ===
Agent 0x99: That choice is yours to make during the confrontation.

Agent 0x99: Seize the crypto assets—immediate impact, ENTROPY loses $12.8M funding.

Agent 0x99: Or monitor the wallets—long-term intelligence, identify everyone receiving funds.

Agent 0x99: Either choice has strategic value. I trust your judgment.

#exit_conversation
-> support_hub

// ================================================
// END OF PHONE SUPPORT
// ================================================
