// ===========================================
// Mission 6: NPC - Dr. Elena Volkov
// CTO of HashChain Exchange, Recruitable Asset
// ===========================================

VAR elena_trust = 0              // -50 to 100 scale
VAR elena_suspicious = false
VAR moral_conflict_revealed = false
VAR shown_casualties = false
VAR shown_architects_fund = false
VAR recruitment_offered = false
VAR recruitment_accepted = false
VAR recruitment_refused = false
VAR password_list_given = false
VAR badge_discussion = false
VAR badge_offered = false
VAR first_meeting = true

// External variables
VAR player_name = "Agent 0x00"
VAR found_blockchain_evidence = false
VAR found_architects_fund = false
VAR elena_recruited = false
VAR elena_arrested = false

// ===========================================
// INITIAL MEETING
// ===========================================

=== start ===
#speaker:elena_volkov

{first_meeting:
    ~ first_meeting = false

    #speaker:narrator
    Narrator: A sharp-eyed woman in her mid-thirties looks up from three monitors of blockchain transaction graphs.

    Dr. Elena Volkov: You must be the FinCEN auditor. Dr. Elena Volkov, Chief Technology Officer.

    Dr. Elena Volkov: Cryptocurrency compliance. Always a pleasure. *her tone suggests otherwise*

    + [Thank you for making the time, Dr. Volkov. I know an audit is disruptive.]
        ~ elena_trust += 10
        -> professional_response

    + [Let's make this efficient. I need system access -- backend servers, transaction logs, wallet infrastructure.]
        ~ elena_trust -= 5
        ~ elena_suspicious = true
        -> suspicious_response

    + [Thirty-seven publications, two and a half thousand citations. Your research is extraordinary.]
        ~ elena_trust += 15
        -> academic_response
}

{not first_meeting:
    Dr. Elena Volkov: Back again. What do you need?
    -> hub
}

=== professional_response ===
#speaker:elena_volkov

Dr. Elena Volkov: I appreciate the courtesy. Most auditors treat us like criminals from day one.

Dr. Elena Volkov: We run a legitimate exchange. Privacy-focused, yes. But legal.

~ elena_trust += 5

-> audit_discussion

=== suspicious_response ===
#speaker:elena_volkov

Dr. Elena Volkov: *narrows eyes* Eager, aren't you?

Dr. Elena Volkov: FinCEN auditors usually start with paperwork. KYC compliance, AML procedures.

Dr. Elena Volkov: You're going straight for the technical infrastructure. Unusual.

~ elena_suspicious = true

-> audit_discussion

=== academic_response ===
#speaker:elena_volkov

Dr. Elena Volkov: *surprised* You read my work?

Dr. Elena Volkov: Most auditors see "cryptographer" and assume "hacker." Refreshing to meet someone who understands the difference.

Dr. Elena Volkov: I built this exchange's infrastructure on sound cryptographic principles. Zero-knowledge proofs, homomorphic encryption...

~ elena_trust += 10

-> academic_discussion

=== academic_discussion ===
#speaker:elena_volkov

Dr. Elena Volkov: My research focuses on financial privacy. Governments shouldn't be able to track every transaction.

Dr. Elena Volkov: That's not a criminal position. It's a privacy rights position.

+ [Financial surveillance is genuinely concerning. I understand the principle.]
    ~ elena_trust += 10
    -> hub

+ [It also launders money. Which is why we audit exchanges.]
    Dr. Elena Volkov: Fair. Everything we do is documented and legal.
    ~ elena_trust += 5
    -> hub

=== audit_discussion ===
#speaker:elena_volkov

Dr. Elena Volkov: What specifically does FinCEN want to see?

Dr. Elena Volkov: Our KYC procedures are compliant. Our transaction monitoring meets regulatory thresholds.

{elena_suspicious:
    Dr. Elena Volkov: Unless you're looking for something beyond standard compliance?
}

-> hub

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===

+ {not password_list_given} [I'll need credentials for the backend servers.]
    -> request_passwords

+ {not badge_discussion} [Tell me about your RFID access control.]
    -> discuss_badges

+ {elena_trust >= 20 and found_blockchain_evidence and not shown_casualties} [There's something you need to see.]
    -> show_blockchain_evidence

+ {shown_casualties and not recruitment_offered} [I'm not FinCEN. I'm SAFETYNET.]
    -> reveal_identity

+ {recruitment_offered and not recruitment_accepted and not recruitment_refused} [I need an answer, Dr. Volkov.]
    -> recruitment_decision

+ {elena_trust < -10} [Dr. Volkov, you're under arrest.]
    -> arrest_elena

+ [That's all for now]
    #exit_conversation
    #speaker:elena_volkov
    {elena_trust >= 30:
        Dr. Elena Volkov: Let me know if you need anything else.
    }
    {elena_trust < 30 and elena_trust >= 0:
        Dr. Elena Volkov: Alright. I'll be here.
    }
    {elena_trust < 0:
        Dr. Elena Volkov: *coldly* Fine.
    }
    -> DONE

// ===========================================
// REQUEST PASSWORDS
// ===========================================

=== request_passwords ===
#speaker:elena_volkov

You: I need to test your backend server security. Password strength analysis.

{elena_trust >= 15:
    Dr. Elena Volkov: That's... actually reasonable for a security audit.

    ~ password_list_given = true
    ~ elena_trust += 5
    #give_item:text_file:m06_password_dictionary
    #complete_task:obtain_access_tools
    #set_variable:found_password_lists=true
    Dr. Elena Volkov: Take my audit wordlist. Every crypto firm on earth picks from the same twenty words and a year.

    Dr. Elena Volkov: Sixty-one per cent of our staff accounts fell to that list. Management's response was to stop running the audit.

    -> hub

- else:
    Dr. Elena Volkov: I don't know you well enough to give you server credentials.
    Dr. Elena Volkov: Build trust first. Then we can discuss technical access.
    -> hub
}

// ===========================================
// BADGE DISCUSSION
// ===========================================

=== discuss_badges ===
#speaker:elena_volkov
~ badge_discussion = true

You: Tell me about your RFID access control systems.

Dr. Elena Volkov: Standard corporate setup. Employee badges for the trading floor, my badge for my own office, executive badges for the top floor.

Dr. Elena Volkov: *taps the lanyard at her collar* This one. It has been round my neck for four years.

{elena_trust >= 25:
    Dr. Elena Volkov: Between you and me, the badges are the only part of our security I would defend. Satoshi is paranoid about doors and relaxed about passwords, which is precisely backwards.
    ~ elena_trust += 5
}

+ {elena_trust >= 25 and not badge_offered} [I'll need to check your office reader as part of the audit. Can I borrow the badge?]
    -> lend_badge

+ [Understood.]
    -> hub

=== lend_badge ===
#speaker:elena_volkov
~ badge_offered = true

Dr. Elena Volkov: *unclips it without hesitation* Bring it back. And do not tell facilities I handed it over, they will write a memo.

~ elena_trust += 5
#give_item:keycard:cto_access_badge
#set_variable:elena_badge_obtained=true

Dr. Elena Volkov: My office is the west door. Try not to judge the state of the whiteboard.

-> hub

// ===========================================
// SHOW BLOCKCHAIN EVIDENCE
// ===========================================

=== show_blockchain_evidence ===
#speaker:elena_volkov
~ shown_casualties = true

You: Dr. Volkov, I need to show you something.

#speaker:narrator
Narrator: You lay the transaction analysis on her desk. Hospital ransomware. Corporate espionage. Both arriving at the same destination wallet, both routed through mixers she designed.

#speaker:elena_volkov

Dr. Elena Volkov: *face goes pale* Where did you get this?

Dr. Elena Volkov: That's... that's our internal analysis. How did you...

+ [You analyzed these transactions yourself]
    -> elena_realization

+ [You knew what this infrastructure was being used for]
    -> elena_confrontation

=== elena_realization ===
#speaker:elena_volkov

Dr. Elena Volkov: I... I ran those analyses because the transaction patterns were suspicious.

Dr. Elena Volkov: Hospital ransomware? Corporate espionage? I flagged these for investigation!

{found_architects_fund:
    You: And The Architect's Fund? $12.8 million for coordinated attacks with 180-340 projected casualties?
    ~ shown_architects_fund = true
    -> architects_fund_reaction
- else:
    You: The mixing services you built are enabling terrorism.
    -> moral_conflict
}

=== elena_confrontation ===
#speaker:elena_volkov

Dr. Elena Volkov: *defensive* I built privacy infrastructure! What people use it for isn't my responsibility!

Dr. Elena Volkov: I design cryptographic systems. That's like blaming the inventor of the printing press for propaganda!

+ [You're not that naive]
    -> moral_conflict

+ [You analyzed the transactions. You knew.]
    -> moral_conflict

=== architects_fund_reaction ===
#speaker:elena_volkov

Dr. Elena Volkov: *reads the document* No. No, this can't be...

Dr. Elena Volkov: 180-340 casualties? They CALCULATED death tolls?

Dr. Elena Volkov: I built this for financial freedom. Not... not mass murder.

~ moral_conflict_revealed = true
~ elena_trust += 20

-> moral_conflict

=== moral_conflict ===
#speaker:elena_volkov
~ moral_conflict_revealed = true

Dr. Elena Volkov: *hands shaking* I knew the exchange was being used for... questionable activities.

Dr. Elena Volkov: But I told myself it was financial freedom. Privacy rights. Fighting government surveillance.

{shown_architects_fund:
    Dr. Elena Volkov: Not funding coordinated terrorist attacks. Not calculating how many people would die.
}

Dr. Elena Volkov: *looks up* Who are you? You're not FinCEN.

-> reveal_identity

// ===========================================
// REVEAL SAFETYNET IDENTITY
// ===========================================

=== reveal_identity ===
#speaker:elena_volkov
~ recruitment_offered = true

You: SAFETYNET. Counter-terrorism intelligence.

You: The exchange you built is the financial hub for ENTROPY—every cell we've encountered is funded through your mixing infrastructure.

Dr. Elena Volkov: *closes eyes* My research. My work. Used to kill people.

+ [You didn't know the full scope. You can help us now.]
    -> recruitment_offer_compassionate

+ [You built the systems. You're culpable. But you can make this right.]
    -> recruitment_offer_pragmatic

+ [You're under arrest for facilitating terrorism]
    -> arrest_elena

=== recruitment_offer_compassionate ===
#speaker:elena_volkov

You: Dr. Volkov, you're a brilliant cryptographer who got swept up in ideology.

You: You built these systems for financial freedom. ENTROPY corrupted your work.

You: But you can help us dismantle their network. Your expertise could save hundreds of lives.

~ elena_trust += 15

-> recruitment_choice

=== recruitment_offer_pragmatic ===
#speaker:elena_volkov

You: You face 20-35 years for money laundering and facilitating terrorism.

You: Or you cooperate with SAFETYNET. Provide intelligence, testify against ENTROPY cells, help us trace their funding.

You: Your choice: prison or redemption.

~ elena_trust += 5

-> recruitment_choice

// ===========================================
// RECRUITMENT CHOICE
// ===========================================

=== recruitment_choice ===
#speaker:elena_volkov

Dr. Elena Volkov: *long silence*

Dr. Elena Volkov: If I cooperate... what happens to my research? My career?

+ [Your research continues—for SAFETYNET. Help us instead of ENTROPY.]
    -> recruitment_appeal_purpose

+ [Your career is over either way. But cooperation keeps you free.]
    -> recruitment_appeal_freedom

+ [Time's up. Decide now.]
    -> recruitment_decision

=== recruitment_appeal_purpose ===
#speaker:elena_volkov

You: SAFETYNET needs cryptographers. Your expertise in cryptocurrency forensics, privacy systems, blockchain analysis...

You: You could teach our analysts. Write papers. Actually contribute to stopping terrorism instead of funding it.

~ elena_trust += 10

Dr. Elena Volkov: *softly* Purpose over punishment.

-> recruitment_decision

=== recruitment_appeal_freedom ===
#speaker:elena_volkov

You: Cooperation means witness protection, reduced sentencing, possibly immunity if your intelligence is valuable enough.

You: Refusal means maximum sentencing for every transaction you enabled.

Dr. Elena Volkov: *bitter laugh* Freedom. The thing I thought I was building.

-> recruitment_decision

// ===========================================
// RECRUITMENT DECISION
// ===========================================

=== recruitment_decision ===
#speaker:elena_volkov

{elena_trust >= 40:
    -> recruitment_accepted_path
}
{elena_trust >= 20 and elena_trust < 40:
    -> recruitment_uncertain
}
{elena_trust < 20:
    -> recruitment_refused_path
}

=== recruitment_accepted_path ===
#speaker:elena_volkov
~ recruitment_accepted = true

Dr. Elena Volkov: *takes deep breath* I'll cooperate.

Dr. Elena Volkov: On one condition: I want to see the intelligence I provide being used. Not disappeared into bureaucracy.

Dr. Elena Volkov: I want to know I'm making this right.

+ [Agreed. We'll keep you informed.]
    -> recruitment_finalized

+ [You're not in a position to negotiate]
    ~ elena_trust -= 10
    -> recruitment_uncertain

=== recruitment_finalized ===
#speaker:elena_volkov

#set_variable:elena_recruited=true
#set_variable:elena_fate_decided=true
#complete_task:decide_elena_fate

Dr. Elena Volkov: Then yes. I'll help you dismantle ENTROPY's financial network.

Dr. Elena Volkov: Starting with Crypto Anarchist cells in three countries I haven't told Satoshi about.

Dr. Elena Volkov: And {player_name}? Thank you. For giving me a chance to fix what I broke.

#exit_conversation
-> DONE

=== recruitment_uncertain ===
#speaker:elena_volkov

Dr. Elena Volkov: I... I need more time. This is my life you're asking me to turn over.

+ [You don't have time. ENTROPY is distributing $12.8M in 72 hours.]
    {shown_architects_fund:
        Dr. Elena Volkov: *anguished* I know! I analyzed those transactions!
        ~ elena_trust += 10
        -> recruitment_decision
    }
    {not shown_architects_fund:
        Dr. Elena Volkov: What are you talking about?
        -> explain_time_pressure
    }

+ [Fine. But I'm not offering this again.]
    -> recruitment_refused_path

=== explain_time_pressure ===
#speaker:elena_volkov

You: The Architect's Fund. $12.8 million allocated to six ENTROPY cells. Coordinated attacks.

You: If you don't help us stop the fund distribution, 180-340 people die.

~ shown_architects_fund = true
~ elena_trust += 15

-> recruitment_decision

=== recruitment_refused_path ===
#speaker:elena_volkov
~ recruitment_refused = true

Dr. Elena Volkov: I won't betray Satoshi. Or the principles this exchange was built on.

Dr. Elena Volkov: Financial privacy is a right. If some people abuse it, that's on them.

+ [Then you're complicit in terrorism]
    -> arrest_elena

+ [You're making a mistake]
    -> arrest_elena

// ===========================================
// ARREST ELENA
// ===========================================

=== arrest_elena ===
#speaker:elena_volkov

You: Dr. Elena Volkov, you're under arrest for money laundering, facilitating terrorism, and conspiracy.

#set_variable:elena_arrested=true
#set_variable:elena_fate_decided=true
#complete_task:decide_elena_fate

{elena_trust >= 20:
    Dr. Elena Volkov: *quietly* I really thought I was doing the right thing.
    Dr. Elena Volkov: Financial freedom. Privacy rights. I was so sure...
- else:
    Dr. Elena Volkov: *defiant* This is a violation of everything crypto stands for.
    Dr. Elena Volkov: You're proving our point. Government tyranny.
}

Dr. Elena Volkov: *hands offered for cuffs* I hope arresting me was worth it.

#exit_conversation
-> DONE
