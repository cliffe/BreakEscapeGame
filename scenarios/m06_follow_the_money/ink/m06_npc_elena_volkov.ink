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
    #display:elena-professional

    A sharp-eyed woman in her mid-30s looks up from three monitors displaying blockchain transaction graphs.

    Elena: You must be the FinCEN auditor. Dr. Elena Volkov, Chief Technology Officer.

    Elena: Cryptocurrency compliance. Always a pleasure. *her tone suggests otherwise*

    + [Thank you for meeting with me, Dr. Volkov]
        You: I understand regulatory audits can be disruptive.
        ~ elena_trust += 10
        -> professional_response

    + [Let's make this efficient. I need system access]
        You: Backend servers, transaction logs, wallet infrastructure.
        ~ elena_trust -= 5
        ~ elena_suspicious = true
        -> suspicious_response

    + [Your cryptography research is impressive]
        You: 37 publications, 2,847 citations. That's extraordinary.
        ~ elena_trust += 15
        -> academic_response
}

{not first_meeting:
    #display:elena-neutral
    Elena: Back again. What do you need?
    -> hub
}

=== professional_response ===
#speaker:elena_volkov

Elena: I appreciate the courtesy. Most auditors treat us like criminals from day one.

Elena: We run a legitimate exchange. Privacy-focused, yes. But legal.

~ elena_trust += 5

-> audit_discussion

=== suspicious_response ===
#speaker:elena_volkov

Elena: *narrows eyes* Eager, aren't you?

Elena: FinCEN auditors usually start with paperwork. KYC compliance, AML procedures.

Elena: You're going straight for the technical infrastructure. Unusual.

~ elena_suspicious = true

-> audit_discussion

=== academic_response ===
#speaker:elena_volkov

Elena: *surprised* You read my work?

Elena: Most auditors see "cryptographer" and assume "hacker." Refreshing to meet someone who understands the difference.

Elena: I built this exchange's infrastructure on sound cryptographic principles. Zero-knowledge proofs, homomorphic encryption...

~ elena_trust += 10

-> academic_discussion

=== academic_discussion ===
#speaker:elena_volkov

Elena: My research focuses on financial privacy. Governments shouldn't be able to track every transaction.

Elena: That's not a criminal position. It's a privacy rights position.

+ [Privacy has legitimate uses]
    You: Financial surveillance is concerning. I understand the principle.
    ~ elena_trust += 10
    -> hub

+ [Privacy also enables money laundering]
    You: Which is why we audit exchanges.
    Elena: Fair. Everything we do is documented and legal.
    ~ elena_trust += 5
    -> hub

=== audit_discussion ===
#speaker:elena_volkov

Elena: What specifically does FinCEN want to see?

Elena: Our KYC procedures are compliant. Our transaction monitoring meets regulatory thresholds.

{elena_suspicious:
    Elena: Unless you're looking for something beyond standard compliance?
}

-> hub

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===

+ {not password_list_given} [Ask about server access credentials]
    -> request_passwords

+ {not badge_discussion} [Ask about access control systems]
    -> discuss_badges

+ {elena_trust >= 20 and found_blockchain_evidence and not shown_casualties} [Show blockchain transaction analysis]
    -> show_blockchain_evidence

+ {shown_casualties and not recruitment_offered} [Reveal SAFETYNET identity]
    -> reveal_identity

+ {recruitment_offered and not recruitment_accepted and not recruitment_refused} [Press for recruitment decision]
    -> recruitment_decision

+ {elena_trust < -10} [Arrest Elena Volkov]
    -> arrest_elena

+ [That's all for now]
    #exit_conversation
    #speaker:elena_volkov
    {elena_trust >= 30:
        Elena: Let me know if you need anything else.
    }
    {elena_trust < 30 and elena_trust >= 0:
        Elena: Alright. I'll be here.
    }
    {elena_trust < 0:
        Elena: *coldly* Fine.
    }
    -> DONE

// ===========================================
// REQUEST PASSWORDS
// ===========================================

=== request_passwords ===
#speaker:elena_volkov

You: I need to test your backend server security. Password strength analysis.

{elena_trust >= 15:
    Elena: That's... actually reasonable for a security audit.
    Elena: Here's a password dictionary we use for testing. Crypto-themed patterns are common in this industry.

    #give_item:password_list
    #complete_task:obtain_access_tools

    ~ password_list_given = true
    ~ elena_trust += 5

    Elena: Bitcoin2024, ethereum2025, satoshi2024... you get the idea.

    -> hub

- else:
    Elena: I don't know you well enough to give you server credentials.
    Elena: Build trust first. Then we can discuss technical access.
    -> hub
}

// ===========================================
// BADGE DISCUSSION
// ===========================================

=== discuss_badges ===
#speaker:elena_volkov
~ badge_discussion = true

You: Tell me about your RFID access control systems.

Elena: Standard corporate setup. Employee badges for trading floor, CTO badge for server room, executive badges for restricted areas.

{elena_trust >= 25:
    Elena: Between you and me, our security is solid. Satoshi gets paranoid about access control.
    ~ elena_trust += 5
}

-> hub

// ===========================================
// SHOW BLOCKCHAIN EVIDENCE
// ===========================================

=== show_blockchain_evidence ===
#speaker:elena_volkov
~ shown_casualties = true

You: Dr. Volkov, I need to show you something.

You show her the ENTROPY transaction network analysis: Mission 2 ransomware, Mission 5 espionage, all flowing through HashChain's mixers.

Elena: *face goes pale* Where did you get this?

Elena: That's... that's our internal analysis. How did you...

+ [You analyzed these transactions yourself]
    -> elena_realization

+ [You knew what this infrastructure was being used for]
    -> elena_confrontation

=== elena_realization ===
#speaker:elena_volkov

Elena: I... I ran those analyses because the transaction patterns were suspicious.

Elena: Hospital ransomware? Corporate espionage? I flagged these for investigation!

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

Elena: *defensive* I built privacy infrastructure! What people use it for isn't my responsibility!

Elena: I design cryptographic systems. That's like blaming the inventor of the printing press for propaganda!

+ [You're not that naive]
    -> moral_conflict

+ [You analyzed the transactions. You knew.]
    -> moral_conflict

=== architects_fund_reaction ===
#speaker:elena_volkov

Elena: *reads the document* No. No, this can't be...

Elena: 180-340 casualties? They CALCULATED death tolls?

Elena: I built this for financial freedom. Not... not mass murder.

~ moral_conflict_revealed = true
~ elena_trust += 20

-> moral_conflict

=== moral_conflict ===
#speaker:elena_volkov
~ moral_conflict_revealed = true

Elena: *hands shaking* I knew the exchange was being used for... questionable activities.

Elena: But I told myself it was financial freedom. Privacy rights. Fighting government surveillance.

{shown_architects_fund:
    Elena: Not funding coordinated terrorist attacks. Not calculating how many people would die.
}

Elena: *looks up* Who are you? You're not FinCEN.

-> reveal_identity

// ===========================================
// REVEAL SAFETYNET IDENTITY
// ===========================================

=== reveal_identity ===
#speaker:elena_volkov
~ recruitment_offered = true

You: SAFETYNET. Counter-terrorism intelligence.

You: The exchange you built is the financial hub for ENTROPY—every cell we've encountered is funded through your mixing infrastructure.

Elena: *closes eyes* My research. My work. Used to kill people.

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

Elena: *long silence*

Elena: If I cooperate... what happens to my research? My career?

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

Elena: *softly* Purpose over punishment.

-> recruitment_decision

=== recruitment_appeal_freedom ===
#speaker:elena_volkov

You: Cooperation means witness protection, reduced sentencing, possibly immunity if your intelligence is valuable enough.

You: Refusal means maximum sentencing for every transaction you enabled.

Elena: *bitter laugh* Freedom. The thing I thought I was building.

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

Elena: *takes deep breath* I'll cooperate.

Elena: On one condition: I want to see the intelligence I provide being used. Not disappeared into bureaucracy.

Elena: I want to know I'm making this right.

+ [Agreed. We'll keep you informed.]
    -> recruitment_finalized

+ [You're not in a position to negotiate]
    ~ elena_trust -= 10
    -> recruitment_uncertain

=== recruitment_finalized ===
#speaker:elena_volkov

#set_variable:elena_recruited=true
#complete_task:decide_elena_fate

Elena: Then yes. I'll help you dismantle ENTROPY's financial network.

Elena: Starting with Crypto Anarchist cells in three countries I haven't told Satoshi about.

Elena: And {player_name}? Thank you. For giving me a chance to fix what I broke.

#exit_conversation
-> DONE

=== recruitment_uncertain ===
#speaker:elena_volkov

Elena: I... I need more time. This is my life you're asking me to turn over.

+ [You don't have time. ENTROPY is distributing $12.8M in 72 hours.]
    {shown_architects_fund:
        Elena: *anguished* I know! I analyzed those transactions!
        ~ elena_trust += 10
        -> recruitment_decision
    }
    {not shown_architects_fund:
        Elena: What are you talking about?
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

Elena: I won't betray Satoshi. Or the principles this exchange was built on.

Elena: Financial privacy is a right. If some people abuse it, that's on them.

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
#complete_task:decide_elena_fate

{elena_trust >= 20:
    Elena: *quietly* I really thought I was doing the right thing.
    Elena: Financial freedom. Privacy rights. I was so sure...
- else:
    Elena: *defiant* This is a violation of everything crypto stands for.
    Elena: You're proving our point. Government tyranny.
}

Elena: *hands offered for cuffs* I hope arresting me was worth it.

#exit_conversation
-> DONE
