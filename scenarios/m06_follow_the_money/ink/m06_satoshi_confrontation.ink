// ===========================================
// Mission 6: Satoshi Nakamoto II Confrontation
// Final showdown with Crypto Anarchists leader
// Critical choices: Asset seizure/monitoring, Elena recruitment
// ===========================================

VAR confrontation_started = false
VAR shown_evidence = false
VAR ideology_discussed = false
VAR asset_choice_made = false
VAR satoshi_arrested = false

// External variables
VAR player_name = "Agent 0x00"
VAR found_blockchain_evidence = false
VAR found_architects_fund = false
VAR elena_recruited = false
VAR elena_arrested = false
VAR assets_seized = false
VAR monitoring_enabled = false

// ===========================================
// INITIAL CONFRONTATION
// ===========================================

=== start ===
#speaker:satoshi

{not confrontation_started:
    ~ confrontation_started = true
    #display:satoshi-defiant

    A charismatic figure in his early 40s sits behind an executive desk, Bitcoin whitepaper framed on the wall behind him.

    Satoshi: You're not from FinCEN. I had you investigated.

    Satoshi: SAFETYNET, correct? Counter-terrorism division.

    Satoshi: Which means you've discovered our true purpose.

    + [You're funding ENTROPY operations]
        You: Every cell we've encountered is financially connected through your exchange.
        -> evidence_reveal

    + [The Architect's Fund. $12.8 million for coordinated attacks.]
        You: 180-340 projected casualties. You calculated death tolls.
        ~ shown_evidence = true
        -> casualties_discussion

    + [You're under arrest for facilitating terrorism]
        -> arrest_attempt
}

{confrontation_started and not asset_choice_made:
    #display:satoshi-calm
    Satoshi: What will it be, Agent {player_name}?
    -> choice_presentation
}

{asset_choice_made:
    -> aftermath
}

// ===========================================
// EVIDENCE REVEAL
// ===========================================

=== evidence_reveal ===
#speaker:satoshi
~ shown_evidence = true

Satoshi: *smiles* You mapped the network. Impressive.

Satoshi: Yes, HashChain Exchange is the financial hub for ENTROPY. We provide infrastructure for all cells.

Satoshi: Money laundering, you'd call it. We call it "enabling financial freedom for freedom fighters."

+ [Freedom fighters? They're terrorists!]
    -> ideology_discussion

+ [You're enabling mass murder]
    -> casualties_discussion

// ===========================================
// CASUALTIES DISCUSSION
// ===========================================

=== casualties_discussion ===
#speaker:satoshi
~ shown_evidence = true

{found_architects_fund:
    Satoshi: Ah, you found The Architect's allocation document. Thorough work.

    Satoshi: 180-340 casualties across coordinated operations. Yes, those are the projections.
- else:
    Satoshi: Casualties are inevitable in any revolution.
}

Satoshi: But let me ask you something: How many people die maintaining the current system?

+ [That's not justification for terrorism]
    -> justification_rejection

+ [You calculated how many people would die and proceeded anyway]
    -> calculated_cruelty

=== justification_rejection ===
#speaker:satoshi

Satoshi: Isn't it? The financial system you protect kills thousands through economic violence.

Satoshi: Poverty. Debt. Medical bankruptcy. Foreclosures.

Satoshi: ENTROPY accelerates the collapse of a system that's already murderous. We just make it obvious.

-> ideology_discussion

=== calculated_cruelty ===
#speaker:satoshi

Satoshi: We calculated casualties to MINIMIZE them.

Satoshi: The Architect's operations are surgical. Targeted. Educational.

Satoshi: Each attack teaches a lesson about system vulnerabilities. Makes people question their trust in centralized institutions.

Satoshi: Those deaths serve a purpose. They're not random violence.

-> ideology_discussion

// ===========================================
// IDEOLOGY DISCUSSION
// ===========================================

=== ideology_discussion ===
#speaker:satoshi
~ ideology_discussed = true

Satoshi: You don't understand our philosophy, do you?

Satoshi: Crypto Anarchists believe centralized control of money is the root of tyranny.

Satoshi: Governments weaponize currency. Financial surveillance enables oppression.

+ [So you fund terrorism to prove a point?]
    -> terrorism_rebuttal

+ [Financial privacy has legitimate uses. This isn't it.]
    -> corrupted_ideals

+ [You're just another criminal hiding behind ideology]
    -> criminal_accusation

=== terrorism_rebuttal ===
#speaker:satoshi

Satoshi: *leans forward* We fund ACCELERATION.

Satoshi: The current system is doomed to collapse. Climate crisis, wealth inequality, technological disruption—it's already failing.

Satoshi: ENTROPY speeds up the inevitable. Makes the collapse happen on OUR terms, with preparation, instead of catastrophic surprise.

Satoshi: We're not terrorists. We're... midwives to a new era.

-> philosophy_challenge

=== corrupted_ideals ===
#speaker:satoshi

Satoshi: *nods approvingly* You understand the distinction. Good.

Satoshi: Financial privacy IS legitimate. But you're right—ENTROPY corrupted our ideals.

{elena_recruited:
    Satoshi: Elena understood that too. That's why she betrayed us, isn't it?
    -> elena_betrayal_reaction
- else:
    Satoshi: At least, Elena thinks so. She's been having... moral difficulties.
    -> elena_conflict
}

=== criminal_accusation ===
#speaker:satoshi

Satoshi: *dismissive laugh* Criminal? By whose law?

Satoshi: Governments that imprison whistleblowers? Intelligence agencies that surveil everyone?

Satoshi: Your legal system is illegitimate. We don't recognize its authority.

-> philosophy_challenge

// ===========================================
// PHILOSOPHY CHALLENGE
// ===========================================

=== philosophy_challenge ===
#speaker:satoshi

Satoshi: But I don't expect you to agree. You're SAFETYNET. You protect the status quo.

Satoshi: So let's discuss the practical matter: You've discovered our network. What will you do about it?

-> choice_presentation

// ===========================================
// ELENA REACTIONS
// ===========================================

=== elena_betrayal_reaction ===
#speaker:satoshi

{elena_recruited:
    Satoshi: You recruited her. Showed her the casualty projections. Appealed to her conscience.
    Satoshi: She was always the weak link. Too much empathy for an anarchist.
- else:
    Satoshi: She refused you, I presume? Good. Her loyalty held.
}

-> choice_presentation

=== elena_conflict ===
#speaker:satoshi

Satoshi: She built this infrastructure for idealism. Now she's uncomfortable with the reality.

Satoshi: Revolutions require sacrifice. Not everyone has the stomach for it.

{not elena_recruited and not elena_arrested:
    Satoshi: Did you try to recruit her? Appeal to her conscience?
    Satoshi: I'm curious whether she chose principles or comfort.
}

-> choice_presentation

// ===========================================
// CHOICE PRESENTATION
// ===========================================

=== choice_presentation ===
#speaker:satoshi

Satoshi: You face a decision, Agent {player_name}.

{found_architects_fund:
    Satoshi: You know about The Architect's Fund. $12.8 million ready for distribution.
- else:
    Satoshi: You've mapped enough of the network to understand the infrastructure.
}

Satoshi: You can seize the cryptocurrency assets. Immediate impact. Cut ENTROPY funding.

Satoshi: Or you can monitor the transactions. Map every cell receiving funds. Long-term intelligence.

+ [I'm seizing the assets. ENTROPY loses its funding.]
    -> seize_assets

+ [I'm enabling monitoring. We'll track every cell.]
    -> enable_monitoring

+ [Why are you telling me this?]
    -> strategic_explanation

=== strategic_explanation ===
#speaker:satoshi

Satoshi: Because either choice serves our purpose.

Satoshi: Seize the assets? We become martyrs. Proof of government tyranny. Recruitment doubles.

Satoshi: Enable monitoring? You commit resources to surveillance. Meanwhile, ENTROPY adapts.

Satoshi: You can't win, {player_name}. You can only choose how you lose.

+ [I'm seizing the assets]
    -> seize_assets

+ [I'm enabling monitoring]
    -> enable_monitoring

+ [I'm arresting you and dismantling the entire network]
    -> arrest_attempt

// ===========================================
// SEIZE ASSETS CHOICE
// ===========================================

=== seize_assets ===
#speaker:satoshi
~ asset_choice_made = true

#set_variable:assets_seized=true
#complete_task:decide_asset_strategy

You: I'm seizing the cryptocurrency. $12.8 million in ENTROPY funding ends now.

{found_architects_fund:
    You: The Architect's "Masterpiece"? Defunded. Coordinated operations? Cancelled.
}

Satoshi: *slow clap* Short-term thinking. SAFETYNET's specialty.

Satoshi: You just proved our point. Government seizes cryptocurrency at will. Financial freedom is an illusion.

Satoshi: Our recruitment will surge. Thank you for the propaganda victory.

+ [We stopped the attack. That's what matters.]
    -> immediate_impact_response

+ [Better than letting 180-340 people die]
    -> casualty_prevention_response

=== immediate_impact_response ===
#speaker:satoshi

Satoshi: This attack, yes. But you've made the NEXT one easier to recruit for.

Satoshi: Every crypto anarchist who was sitting on the fence? You just pushed them to our side.

Satoshi: Congratulations. You won the battle and lost the war.

-> arrest_finale

=== casualty_prevention_response ===
#speaker:satoshi

Satoshi: *nods* At least you're honest about the trade-off.

Satoshi: You value immediate lives over long-term strategy. That's... human. Compassionate, even.

Satoshi: Wrong, from an accelerationist perspective. But human.

-> arrest_finale

// ===========================================
// ENABLE MONITORING CHOICE
// ===========================================

=== enable_monitoring ===
#speaker:satoshi
~ asset_choice_made = true

#set_variable:monitoring_enabled=true
#complete_task:decide_asset_strategy

You: I'm enabling transaction monitoring. Every wallet, every cell, mapped in real-time.

You: We'll know everyone receiving funds. ENTROPY's entire network will be visible.

Satoshi: *impressed* Long-term strategic thinking. I didn't expect that from SAFETYNET.

Satoshi: You're trading immediate prevention for comprehensive intelligence. Bold.

+ [We'll dismantle the entire network, not just stop one attack]
    -> long_term_strategy_response

+ [The intelligence is worth more than one operation]
    -> intelligence_value_response

=== long_term_strategy_response ===
#speaker:satoshi

Satoshi: Perhaps. Or ENTROPY adapts, creates new financial channels, and your monitoring becomes worthless.

Satoshi: Meanwhile, The Architect's operations proceed. Those 180-340 casualties? They happen.

Satoshi: All for intelligence that might pay off eventually. If we don't adapt first.

-> arrest_finale

=== intelligence_value_response ===
#speaker:satoshi

Satoshi: Coldly logical. You're willing to let people die for strategic advantage.

Satoshi: *smiles* We're not so different, you and I.

Satoshi: Both making calculated sacrifices for a larger goal. Both convinced we're serving a greater good.

Satoshi: The only difference is which system we protect.

-> arrest_finale

// ===========================================
// ARREST ATTEMPT
// ===========================================

=== arrest_attempt ===
#speaker:satoshi

You: "Satoshi Nakamoto II," you're under arrest for money laundering, facilitating terrorism, conspiracy, and financial crimes.

#set_variable:satoshi_arrested=true

{asset_choice_made:
    Satoshi: Of course I am. Was there any other ending to this confrontation?
- else:
    Satoshi: Before you do that, you still need to decide: Assets or monitoring?
    {player_name}, you can arrest me, but that choice shapes the investigation.
    -> choice_presentation
}

-> arrest_finale

// ===========================================
// ARREST FINALE
// ===========================================

=== arrest_finale ===
#speaker:satoshi

Satoshi: *stands, offers hands for cuffs*

Satoshi: I'll be convicted, of course. Probably 40 years to life.

{assets_seized:
    Satoshi: But the assets you seized? Proof of government overreach. Our recruitment will surge.
}

{monitoring_enabled:
    Satoshi: And the monitoring you enabled? We'll adapt. Create new channels. Your intelligence will age poorly.
}

{elena_recruited:
    Satoshi: Elena's cooperation will hurt us short-term. Her expertise was valuable.
    Satoshi: But even she couldn't stop the movement. Crypto anarchism is bigger than any individual.
}

{elena_arrested:
    Satoshi: Elena chose loyalty. I'm proud of her, even if it costs her freedom.
}

Satoshi: This isn't over, {player_name}. ENTROPY is decentralized. The Architect will adapt.

-> final_words

// ===========================================
// FINAL WORDS
// ===========================================

=== final_words ===
#speaker:satoshi

Satoshi: Last question: Do you ever wonder if we're right?

Satoshi: If the system you protect is doomed? If acceleration might actually save more lives than preservation?

+ [Your ideology doesn't justify murder]
    -> ideology_rejection

+ [Sometimes. But I chose my side.]
    -> honest_response

+ [I don't engage with terrorist philosophy]
    -> dismissal

=== ideology_rejection ===
#speaker:satoshi

Satoshi: We'll see. History judges ideologies long after we're gone.

Satoshi: Maybe SAFETYNET will still exist in 50 years, protecting a thriving system.

Satoshi: Or maybe you'll look back and realize you were defending the Titanic.

-> mission_complete

=== honest_response ===
#speaker:satoshi

Satoshi: *nods with respect* Honest answer. Rare in your profession.

Satoshi: You're a good agent, {player_name}. You think strategically, question assumptions, understand trade-offs.

Satoshi: That makes you dangerous to us. But I can respect it.

-> mission_complete

=== dismissal ===
#speaker:satoshi

Satoshi: Of course not. Easier to ignore questions than confront them.

Satoshi: That's why the system will fall. It can't adapt. Can't question itself.

Satoshi: ENTROPY can. We evolve. We accelerate.

-> mission_complete

// ===========================================
// MISSION COMPLETE
// ===========================================

=== mission_complete ===
#speaker:satoshi

Satoshi: Take me to whatever holding facility you have prepared.

Satoshi: But know this: You stopped one exchange. One funding channel.

Satoshi: The Architect has contingencies. ENTROPY is decentralized.

Satoshi: This was never just about HashChain. It was about proving the system is vulnerable.

Satoshi: And {player_name}... you just proved it.

#complete_task:confront_satoshi
#exit_conversation
-> END

// ===========================================
// AFTERMATH (if player returns)
// ===========================================

=== aftermath ===
#speaker:satoshi

Satoshi: Mission's over, Agent. I'm already under arrest.

Satoshi: Did you want to gloat? Or are you having second thoughts about your choices?

+ [Just ensuring you're secured]
    #exit_conversation
    Satoshi: *smirks* I'm not going anywhere.
    -> END

+ [I made the right choices]
    #exit_conversation
    Satoshi: Time will tell.
    -> END

+ [Goodbye]
    #exit_conversation
    Satoshi: See you at the trial, {player_name}.
    -> END
