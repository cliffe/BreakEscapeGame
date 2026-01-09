// ================================================
// Mission 6: Follow the Money - Opening Briefing
// Agent 0x99 "Haxolottle" briefs Agent 0x00
// Financial investigation of ENTROPY's funding network
// ================================================

// Variables for tracking player questions
VAR asked_about_connections = false
VAR asked_about_exchange = false
VAR asked_about_elena = false
VAR asked_about_architect_fund = false
VAR mission_accepted = false

// External variables
VAR player_name = "Agent 0x00"

// ================================================
// START: BRIEFING BEGINS
// ================================================

=== start ===
Agent 0x99: {player_name}, great work on the previous missions. But now we need to answer the big question.

Agent 0x99: Where's the money coming from?

+ [Following the financial trail?]
    -> financial_investigation
+ [What money are we talking about?]
    -> money_explanation
+ [I'm ready. What's the target?]
    -> financial_investigation

// ================================================
// MONEY EXPLANATION
// ================================================

=== money_explanation ===
Agent 0x99: Think about it. The hospital ransomware from Mission 2? $2.4 million paid.

Agent 0x99: The corporate espionage data from Mission 5? $847,000 in cryptocurrency.

Agent 0x99: All ENTROPY cells are funded. Someone's coordinating the finances.

-> financial_investigation

// ================================================
// FINANCIAL INVESTIGATION
// ================================================

=== financial_investigation ===
Agent 0x99: Our blockchain analysts traced the cryptocurrency payments. And they all lead to one place.

Agent 0x99: HashChain Exchange. A cryptocurrency trading platform run by ENTROPY's Crypto Anarchists cell.

+ [How does the exchange fit in?]
    ~ asked_about_exchange = true
    -> exchange_role
+ [What are we dealing with?]
    -> crypto_anarchists
+ [Where do all the payments go?]
    -> architect_fund_hint

=== exchange_role ===
Agent 0x99: HashChain isn't just a trading platform. It's the financial hub for all ENTROPY operations.

Agent 0x99: They provide mixing services—converting Bitcoin to untraceable privacy coins like Monero, then back again.

Agent 0x99: Every cell funnels money through them. It's the perfect money laundering infrastructure.

-> crypto_anarchists

// ================================================
// CRYPTO ANARCHISTS
// ================================================

=== crypto_anarchists ===
Agent 0x99: The Crypto Anarchists are true believers. "Financial freedom through cryptography."

Agent 0x99: They think government control of money is tyranny. Cryptocurrency is liberation.

+ [So they're ideologically motivated?]
    -> ideology_discussion
+ [Who's running HashChain?]
    -> leadership_discussion
+ [What's our mission objective?]
    -> mission_objectives

=== ideology_discussion ===
Agent 0x99: Absolutely. Their leader calls himself "Satoshi Nakamoto II"—obviously not the real Bitcoin creator.

Agent 0x99: But here's the thing: they're not just running an exchange. They're funding terrorism in the name of accelerating the collapse of centralized finance.

-> leadership_discussion

// ================================================
// LEADERSHIP DISCUSSION
// ================================================

=== leadership_discussion ===
Agent 0x99: Two key targets:

Agent 0x99: "Satoshi Nakamoto II"—the CEO. True believer, charismatic leader, probably unreachable for recruitment.

Agent 0x99: Dr. Elena Volkov—the CTO. Brilliant cryptographer. Former academic. And... potentially recruitable.

+ [Why would she help us?]
    ~ asked_about_elena = true
    -> elena_background
+ [What makes you think she's recruitable?]
    ~ asked_about_elena = true
    -> elena_background
+ [What about the money trail?]
    -> architect_fund_hint

=== elena_background ===
Agent 0x99: Elena's a genius. Published 37 papers on cryptography. 2,847 citations.

Agent 0x99: She built HashChain's privacy infrastructure. But our psychological profile suggests moral conflict.

Agent 0x99: She designed these systems for "financial freedom." Now they're being used for ransomware, espionage, funding attacks.

+ [Think she'll flip?]
    -> recruitment_possibility
+ [What if she refuses?]
    -> arrest_option

=== recruitment_possibility ===
Agent 0x99: It's possible. If you can show her the full scope of what her work is enabling—the casualties, the attacks—she might turn.

Agent 0x99: A cryptographer of her caliber would be a massive intelligence asset.

-> mission_objectives

=== arrest_option ===
Agent 0x99: Then we arrest her and eliminate her expertise from ENTROPY's network.

Agent 0x99: But {player_name}, if there's any chance of recruitment, it's worth trying. Her knowledge could crack multiple cells.

-> mission_objectives

// ================================================
// ARCHITECT FUND HINT
// ================================================

=== architect_fund_hint ===
Agent 0x99: That's what we need you to find out.

Agent 0x99: Our blockchain analysis shows all ENTROPY payments flowing into HashChain's mixers...

Agent 0x99: But then the trail goes dark. Privacy coins make it nearly impossible to track from the outside.

+ [So I need access to their internal records?]
    ~ asked_about_architect_fund = true
    -> internal_access
+ [What am I looking for?]
    ~ asked_about_architect_fund = true
    -> evidence_targets

=== internal_access ===
Agent 0x99: Exactly. Their financial database, transaction logs, wallet recovery keys.

Agent 0x99: The blockchain is public, but their internal mixing records will show us where the money actually goes.

-> evidence_targets

=== evidence_targets ===
Agent 0x99: Look for destination wallets, fund allocations, anything connecting to other ENTROPY cells.

Agent 0x99: If there's a master fund coordinating everything, it'll be in their records.

-> mission_objectives

// ================================================
// MISSION OBJECTIVES
// ================================================

=== mission_objectives ===
Agent 0x99: Your mission objectives:

Agent 0x99: One—Infiltrate HashChain Exchange as a compliance auditor. Perfect cover for financial investigation.

Agent 0x99: Two—Access their backend servers and crack passwords to reach financial records.

Agent 0x99: Three—Map the complete ENTROPY financial network. Every cell, every wallet, every transaction.

+ [How do I access the servers?]
    -> technical_approach
+ [What about Elena and Satoshi?]
    -> npc_strategy
+ [What resources do I have?]
    -> resources

// ================================================
// TECHNICAL APPROACH
// ================================================

=== technical_approach ===
Agent 0x99: Their server room is password-protected. Typical crypto-themed passwords—we'll provide hints.

Agent 0x99: Once you crack the first server, look for credential reuse. System admins get lazy.

Agent 0x99: Your VM access terminal will let you practice password cracking against their infrastructure.

+ [What am I looking for in the financial data?]
    -> financial_targets
+ [Tell me about the cover story]
    -> cover_story

=== financial_targets ===
Agent 0x99: Transaction records connecting Mission 2's ransomware and Mission 5's espionage payments.

Agent 0x99: Wallet addresses for all ENTROPY cells.

Agent 0x99: And anything about coordinated funding—a master fund distributing money to multiple operations.

-> cover_story

// ================================================
// NPC STRATEGY
// ================================================

=== npc_strategy ===
Agent 0x99: Build rapport with Elena. She's your best intelligence source and potential recruit.

Agent 0x99: Satoshi is a true believer—useful for understanding their ideology, but unlikely to cooperate.

Agent 0x99: The traders and analysts are mostly innocent. They think they work at a legitimate exchange.

-> cover_story

// ================================================
// COVER STORY
// ================================================

=== cover_story ===
Agent 0x99: You're a compliance auditor from FinCEN—Financial Crimes Enforcement Network.

Agent 0x99: Cryptocurrency exchanges face constant regulatory scrutiny. Your audit is completely normal.

Agent 0x99: Elena will meet you as CTO. She'll provide access to systems for "compliance verification."

+ [What if they see through the cover?]
    -> cover_backup
+ [I'm ready to deploy]
    -> final_briefing

=== cover_backup ===
Agent 0x99: Your credentials are genuine—we have real FinCEN paperwork. HashChain has no reason to suspect.

Agent 0x99: And even if they do? You'll be inside their systems before they can react.

-> final_briefing

// ================================================
// RESOURCES
// ================================================

=== resources ===
Agent 0x99: You'll have phone contact with me throughout the mission.

Agent 0x99: SAFETYNET flag station in their server room for submitting intelligence.

Agent 0x99: And {player_name}—I've uploaded password cracking tools and dictionaries to your VM environment.

+ [What about physical tools?]
    -> physical_tools
+ [Understood. Ready to go]
    -> final_briefing

=== physical_tools ===
Agent 0x99: RFID badge cloner for accessing restricted areas. You'll find one inside—these crypto types love their security toys.

Agent 0x99: Everything else you need should be available as an "auditor." Leverage your cover.

-> final_briefing

// ================================================
// FINAL BRIEFING
// ================================================

=== final_briefing ===
Agent 0x99: {player_name}, this is a critical mission.

Agent 0x99: We've been fighting individual ENTROPY cells. This is our chance to understand the entire financial infrastructure.

Agent 0x99: Map the network. Find where the money goes. And if you can recruit Elena? That's a strategic intelligence win.

+ [What if I find something bigger than individual cells?]
    -> bigger_picture
+ [Any final advice?]
    -> final_advice
+ [I'm ready to go]
    -> deployment

=== bigger_picture ===
Agent 0x99: Then we've struck gold.

Agent 0x99: If there's a central fund coordinating all ENTROPY operations, that's the kind of intelligence that could let us move against multiple cells simultaneously.

Agent 0x99: Follow the money. It always tells the truth.

-> deployment

=== final_advice ===
Agent 0x99: Remember: Elena is brilliant but conflicted. Appeal to her ethics, not her ideology.

Agent 0x99: Satoshi is a true believer. Understand his perspective but don't expect conversion.

Agent 0x99: And crack those passwords carefully—you'll need access to multiple servers to piece together the complete network.

-> deployment

// ================================================
// DEPLOYMENT
// ================================================

=== deployment ===
Agent 0x99: One more thing: we're racing the clock.

Agent 0x99: Our intelligence suggests a major fund distribution happening soon. If ENTROPY moves money to all cells simultaneously, they're coordinating something big.

Agent 0x99: Get inside. Map the network. Find the fund. And make the critical choices about assets and recruitment.

Agent 0x99: HashChain Exchange is the financial heart of ENTROPY. Let's see if we can stop it from beating.

~ mission_accepted = true

#exit_conversation
-> END
