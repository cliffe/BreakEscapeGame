// ===========================================
// Mission 6: NPC - Crypto Trader
// Innocent employee, provides context
// ===========================================

VAR trader_talked = false
VAR topic_volume = false
VAR topic_monero = false
VAR topic_elena = false
VAR first_meeting = true

// External variables
VAR player_name = "Agent 0x00"

// ===========================================
// INITIAL MEETING
// ===========================================

=== start ===
#speaker:trader

{first_meeting:
    ~ first_meeting = false
    #display:trader-casual

    A young trader watches multiple crypto price charts, occasionally placing trades.

    Trader: Hey, you're the compliance person, right? From FinCEN?

    Trader: Don't worry, we're legit. Mostly. *grins*

    + [Mostly?]
        You: That's an interesting qualifier.
        Trader: *laughs* I'm kidding. Everything's above board. Elena makes sure of that.
        -> hub

    + [I'm just doing a standard audit]
        You: Nothing to worry about if everything's compliant.
        Trader: Cool cool. Let me know if you need anything.
        -> hub

    + [Tell me about the exchange's operations]
        -> operations_overview
}

{not first_meeting:
    #display:trader-friendly
    Trader: What's up?
    -> hub
}

=== operations_overview ===
#speaker:trader

Trader: We're a mid-size crypto exchange. Focus on privacy coins—Monero, Zcash, stuff like that.

Trader: High volume, fast transactions, low fees. Competitive market.

+ [Why focus on privacy coins?]
    -> privacy_coin_focus

+ [What's the daily volume?]
    ~ topic_volume = true
    -> volume_discussion

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===

+ {not topic_volume} [Ask about trading volume]
    -> volume_discussion

+ {not topic_monero} [Ask about Monero usage]
    -> monero_discussion

+ {not topic_elena} [Ask about Elena Volkov]
    -> elena_discussion

+ [That's all, thanks]
    #exit_conversation
    #speaker:trader
    Trader: No problem. Happy trading!
    -> DONE

// ===========================================
// TRADING VOLUME
// ===========================================

=== volume_discussion ===
#speaker:trader
~ topic_volume = true

Trader: We're doing like $800-900 million USD equivalent per day.

Trader: Not bad for a mid-size exchange. Elena's infrastructure is solid.

Trader: Mostly Bitcoin, Ethereum, but the Monero volume has been crazy lately.

+ [Crazy how?]
    -> monero_surge

+ [That's impressive volume]
    Trader: Yeah, privacy coin demand is skyrocketing.
    -> hub

=== monero_surge ===
#speaker:trader

Trader: Like, 3-4x normal. Big wallets converting Bitcoin to Monero, mixing through multiple addresses, converting back.

Trader: Classic mixing pattern. Totally legal, but... yeah.

+ [You report these patterns?]
    -> reporting_discussion

+ [Is that suspicious?]
    -> suspicious_activity

=== reporting_discussion ===
#speaker:trader

Trader: Oh yeah, we flag everything. Elena runs analysis, files SARs when needed.

Trader: We're compliant. Just... we're also privacy-focused. That's our brand.

-> hub

=== suspicious_activity ===
#speaker:trader

Trader: *shrugs* Depends on your perspective.

Trader: Some people want financial privacy. Some want to hide money. Hard to tell which is which from transaction patterns.

Trader: That's your job, I guess. *gestures at you*

-> hub

// ===========================================
// PRIVACY COIN FOCUS
// ===========================================

=== privacy_coin_focus ===
#speaker:trader
~ topic_monero = true

Trader: Satoshi's philosophy. "Financial freedom through cryptography."

Trader: People should be able to transact without government surveillance. Privacy is a right.

+ [That sounds like ideology, not business]
    -> ideology_response

+ [Privacy can enable illegal activity]
    -> illegal_activity_response

=== ideology_response ===
#speaker:trader

Trader: It's both! Satoshi's a true believer, but it's also profitable.

Trader: Privacy coin traders pay premium fees. We make bank.

-> hub

=== illegal_activity_response ===
#speaker:trader

Trader: Sure. And regular currency enables illegal activity too.

Trader: You gonna shut down every bank because some people launder money?

Trader: We follow the law. We file reports. What people do with their privacy is their business.

-> hub

// ===========================================
// MONERO DISCUSSION
// ===========================================

=== monero_discussion ===
#speaker:trader
~ topic_monero = true

Trader: Monero's untraceable. That's the whole point.

Trader: Bitcoin is pseudonymous—you can track wallets. Monero is truly anonymous.

Trader: Makes it perfect for privacy. Also perfect for money laundering, I guess.

+ [Do you think the exchange is being used for money laundering?]
    -> laundering_opinion

+ [How does the mixing work?]
    -> mixing_explanation

=== laundering_opinion ===
#speaker:trader

Trader: *uncomfortable* I mean... I don't ask questions. I just execute trades.

Trader: Elena and Satoshi handle compliance. I'm just the guy watching charts.

+ [You must have suspicions]
    -> trader_suspicions

+ [Fair enough]
    -> hub

=== trader_suspicions ===
#speaker:trader

Trader: *lowers voice* Between you and me? Some of the transaction patterns are... weird.

Trader: Like, coordinated. Multiple big wallets mixing at the same time, same amounts, same destination patterns.

Trader: I flagged it to Elena. She said she's investigating.

Trader: But honestly? I just want to keep my job and not think about it too hard.

-> hub

=== mixing_explanation ===
#speaker:trader

Trader: User sends Bitcoin to us. We convert to Monero. Send through 5-10 different wallets.

Trader: Then convert back to Bitcoin from a completely unlinked address.

Trader: Blockchain shows Bitcoin in, Bitcoin out. But the Monero middle step? Untraceable.

Trader: Perfectly legal mixing service. We're transparent about it.

-> hub

// ===========================================
// ELENA DISCUSSION
// ===========================================

=== elena_discussion ===
#speaker:trader
~ topic_elena = true

Trader: Elena's brilliant. Like, PhD in cryptography brilliant.

Trader: She designed all our privacy protocols. Zero-knowledge proofs, homomorphic encryption...

Trader: Way above my paygrade. I just use the systems she builds.

+ [Does she seem concerned about compliance?]
    -> elena_compliance

+ [What's your impression of her?]
    -> elena_impression

=== elena_compliance ===
#speaker:trader

Trader: Obsessively. She reviews every flagged transaction personally.

Trader: Actually, she's been stressed lately. I think some of the activity patterns are bothering her.

Trader: But she hasn't said anything specific.

-> hub

=== elena_impression ===
#speaker:trader

Trader: Smart, intense, kinda distant. But fair.

Trader: She believes in what we're doing—financial privacy as a right.

Trader: I think she struggles with the fact that good tech can be used for bad things.

-> hub
