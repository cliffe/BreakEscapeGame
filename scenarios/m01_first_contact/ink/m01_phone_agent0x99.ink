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
VAR player_name = "Agent 0x00"
VAR current_task = ""

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

Agent 0x99: Lockpicking is about patience and careful observation.

Agent 0x99: Pay attention to feedback. Locks tell you when you're making progress.

Agent 0x99: If you have access to practice locks, use them. Low-risk learning is the best kind.

+ [Any other tips?]
    Agent 0x99: Don't rush. If something isn't working, step back and reconsider your approach.
    -> support_hub
+ [Got it, thanks]
    -> support_hub

// ================================================
// SSH BRUTE FORCE HELP
// ================================================

=== ssh_help ===
~ ssh_hint_given = true

Agent 0x99: SSH access requires credentials. You'll need to find valid username and password combinations.

Agent 0x99: Look for patterns in the environment. People are creatures of habit—they reuse dates, company names, personal information.

Agent 0x99: Kevin might have observations about password habits. Check the office for clues—whiteboards, notes, calendars.

+ [What if I can't guess the passwords?]
    Agent 0x99: Then build a wordlist from what you learn. Every conversation, every note is potential intelligence.
    Agent 0x99: There are tools for testing multiple passwords, but you'll need to discover which ones work in this environment.
    -> support_hub
+ [Thanks, that helps]
    -> support_hub

// ================================================
// LINUX NAVIGATION HELP
// ================================================

=== linux_help ===
~ linux_hint_given = true

Agent 0x99: Linux systems organize files in directories. Learn to navigate and read files—that's where evidence lives.

Agent 0x99: User directories often contain personal files, configurations, and artifacts of their activity.

Agent 0x99: Remember that not everything is visible at first glance. Look deeper.

+ [Where should I look for flags?]
    Agent 0x99: Think like an investigator. Where would someone store sensitive information? User folders, documents, configuration files.
    Agent 0x99: Explore systematically. Don't assume you've seen everything in a directory.
    -> support_hub
+ [Got it]
    -> support_hub

// ================================================
// PRIVILEGE ESCALATION HELP
// ================================================

=== sudo_help ===
~ sudo_hint_given = true

Agent 0x99: Privilege escalation means gaining access to other user accounts or higher permissions.

Agent 0x99: Linux systems often have permissions that allow certain users to execute commands or access other accounts.

Agent 0x99: Investigate what capabilities your current account has. Some accounts can switch to others.

+ [What if I don't have special access?]
    Agent 0x99: Then you'll need to find credentials for other accounts or discover misconfigurations.
    Agent 0x99: For this mission, there should be a path forward. Look for it.
    -> support_hub
+ [Thanks]
    -> support_hub

// ================================================
// GENERAL ADVICE
// ================================================

=== general_advice ===
Agent 0x99: Remember the mission priorities: gather evidence, identify operatives, protect innocents.

Agent 0x99: Most people at Viral Dynamics are legitimate employees. We want ENTROPY operatives, not collateral damage.

+ [How do I know who's ENTROPY?]
    Agent 0x99: Evidence correlation. Look for patterns—unusual access times, encrypted communications, suspicious behavior.
    Agent 0x99: We have a primary suspect, but you need to gather proof before any confrontation.
    -> support_hub
+ [What if I'm not sure about someone?]
    Agent 0x99: Then investigate further. Digital evidence, physical artifacts, behavioral patterns.
    Agent 0x99: Trust the evidence, not assumptions.
    -> support_hub
+ [Understood]
    -> support_hub

// ================================================
// EVENT: LOCKPICK ACQUIRED
// ================================================

=== event_lockpick_acquired ===
#speaker:agent_0x99

Agent 0x99: I see Kevin gave you lockpicks. Smart social engineering.

Agent 0x99: Practice on low-risk targets first. Storage closet, unlocked areas.

Agent 0x99: Remember, you're testing security—officially.

+ [Will do]
    #exit_conversation
    -> support_hub
+ [Any lockpicking tips?]
    -> lockpick_help

// ================================================
// EVENT: FIRST FLAG SUBMITTED
// ================================================

=== event_first_flag ===
#speaker:agent_0x99

Agent 0x99: First flag submitted. Nice work, {player_name}.

Agent 0x99: Each flag unlocks intelligence. Keep correlating VM findings with physical evidence.

+ [What should I focus on next?]
    Agent 0x99: Continue exploring both digital and physical spaces. Evidence doesn't exist in only one domain.
    Agent 0x99: Office areas, computers, filing cabinets—anywhere information might be stored.
    #exit_conversation
    -> support_hub
+ [Thanks]
    #exit_conversation
    -> support_hub

// ================================================
// EVENT: DEREK'S OFFICE ACCESSED
// ================================================

=== event_derek_office ===
#speaker:agent_0x99

Agent 0x99: You're in. Good work gaining access.

Agent 0x99: Look for anything that reveals operational details, communications, or connections to ENTROPY.

Agent 0x99: Be thorough. Evidence can hide in unexpected places.

+ [What if I'm discovered?]
    Agent 0x99: Your cover is solid. You're doing a security audit—this is legitimate.
    Agent 0x99: But don't reveal what you know too early. Evidence first, confrontation later.
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
