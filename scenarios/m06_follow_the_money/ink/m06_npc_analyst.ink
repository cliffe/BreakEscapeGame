// ===========================================
// Mission 6: NPC - Blockchain Analyst
// Technical expert, innocent employee
// ===========================================

VAR analyst_talked = false
VAR topic_forensics = false
VAR topic_patterns = false
VAR topic_concerns = false
VAR first_meeting = true

// External variables
VAR player_name = "Agent 0x00"

// ===========================================
// INITIAL MEETING
// ===========================================

=== start ===
#speaker:analyst

{first_meeting:
    ~ first_meeting = false
    #display:analyst-focused

    A focused analyst examines transaction graphs on a large monitor, nodes and edges forming complex networks.

    Analyst: *doesn't look up* If you're here about the flagged transactions, talk to Elena.

    Analyst: I just run the analysis. She makes the compliance decisions.

    + [I'm from FinCEN. Just observing your process.]
        You: Impressive analysis setup.
        Analyst: *glances up* Oh. Compliance audit. Right.
        -> audit_response

    + [What transactions are you analyzing?]
        -> transaction_work

    + [I'll talk to Elena then]
        #exit_conversation
        Analyst: *already back to screens* Okay.
        -> DONE
}

{not first_meeting:
    #display:analyst-neutral
    Analyst: Need something?
    -> hub
}

=== audit_response ===
#speaker:analyst

Analyst: Thanks. I built most of this myself. Transaction graph analysis, wallet clustering algorithms.

Analyst: We track patterns that might indicate money laundering or sanctions violations.

+ [Do you find many violations?]
    -> violations_discussion

+ [Tell me about your methodology]
    -> methodology_discussion

=== transaction_work ===
#speaker:analyst

Analyst: Current project: mapping large-volume mixing patterns through our exchange.

Analyst: Multiple wallets converting to Monero simultaneously, similar amounts, coordinated timing.

+ [Is that suspicious?]
    -> suspicious_patterns

+ [What do the patterns show?]
    -> suspicious_patterns

// ===========================================
// CONVERSATION HUB
// ===========================================

=== hub ===

+ {not topic_forensics} [Ask about blockchain forensics]
    -> forensics_discussion

+ {not topic_patterns} [Ask about concerning patterns]
    -> pattern_concerns

+ {not topic_concerns} [Ask if analyst has concerns about the exchange]
    -> personal_concerns

+ [Thanks for your time]
    #exit_conversation
    #speaker:analyst
    Analyst: *already back to work* Uh-huh.
    -> DONE

// ===========================================
// FORENSICS DISCUSSION
// ===========================================

=== forensics_discussion ===
#speaker:analyst
~ topic_forensics = true

Analyst: Blockchain forensics is fascinating. Every transaction is public, but attribution is hard.

Analyst: You track wallet behaviors, cluster related addresses, analyze timing patterns.

Analyst: Like digital detective work. Follow the money across thousands of transactions.

+ [Can you trace privacy coins like Monero?]
    -> monero_forensics

+ [What patterns indicate illegal activity?]
    -> illegal_patterns

=== monero_forensics ===
#speaker:analyst

Analyst: Not really. Monero uses ring signatures and stealth addresses. Transactions are genuinely untraceable.

Analyst: That's why exchanges like ours are critical choke points. We see the conversion: Bitcoin in, Monero mix, Bitcoin out.

Analyst: Blockchain doesn't show the middle step, but our internal logs do.

+ [So you can map what the blockchain can't?]
    -> internal_logs_value

+ [That makes your logs valuable]
    -> internal_logs_value

=== internal_logs_value ===
#speaker:analyst

Analyst: Exactly. Our internal database is way more valuable than the public blockchain for forensics.

Analyst: Which is why Elena's so careful about access. If someone gets our logs, they can unmix transactions we've processed.

Analyst: Privacy customers would not be happy about that.

-> hub

=== illegal_patterns ===
#speaker:analyst

Analyst: High-volume mixing with no clear business purpose. Coordinated multi-wallet behaviors.

Analyst: Amounts just under reporting thresholds—structuring. Rapid conversions avoiding single-transaction limits.

Analyst: And timing patterns. If multiple unrelated wallets mix simultaneously with similar amounts? Coordinated operation.

-> hub

// ===========================================
// VIOLATIONS DISCUSSION
// ===========================================

=== violations_discussion ===
#speaker:analyst

Analyst: We file SARs—Suspicious Activity Reports—pretty regularly.

Analyst: High-value privacy coin mixing attracts... a certain clientele.

Analyst: But most of it's legal. People have a right to financial privacy.

-> methodology_discussion

=== methodology_discussion ===
#speaker:analyst

Analyst: I run transaction graph analysis—map all connected wallets, identify clusters.

Analyst: Then timing analysis—look for coordinated behaviors.

Analyst: Finally, amount analysis—large conversions, unusual patterns.

Analyst: Flag anything suspicious to Elena. She decides whether to file SARs or investigate deeper.

-> hub

// ===========================================
// SUSPICIOUS PATTERNS
// ===========================================

=== suspicious_patterns ===
#speaker:analyst

Analyst: *frowns* Yeah. Very.

Analyst: Multiple large wallets. Coordinated conversions. Consistent timing every Friday night.

Analyst: Amounts totaling... *checks screen* ...about $12-13 million over the past month.

+ [Where's the money going?]
    -> destination_discussion

+ [Have you reported this?]
    -> reporting_status

=== destination_discussion ===
#speaker:analyst

Analyst: That's the weird part. After mixing, it all reconverges to a single destination wallet.

Analyst: Different source wallets, different mixing paths, same destination.

Analyst: Either someone's consolidating funds from multiple sources, or...

+ [Or what?]
    -> coordinated_funding

+ [Did you flag this to Elena?]
    -> elena_flagging

=== coordinated_funding ===
#speaker:analyst

Analyst: Or it's coordinated funding for something. Multiple cells paying into a central operation.

Analyst: That's... that's the kind of pattern you see with organized crime or terrorism.

Analyst: I really hope Elena knows what she's doing with this investigation.

-> hub

=== elena_flagging ===
#speaker:analyst

Analyst: Yeah, like two weeks ago. She's been analyzing it personally.

Analyst: Hasn't told me her conclusions yet. Just said to keep monitoring.

+ [Does she seem concerned?]
    -> elena_concern

+ [What's your read on it?]
    -> analyst_opinion

=== elena_concern ===
#speaker:analyst

Analyst: Hard to tell. Elena's always intense.

Analyst: But yeah, she's been stressed. Stays late, re-runs my analyses, asks detailed questions.

Analyst: Either she's being thorough, or something's really bothering her.

-> hub

=== analyst_opinion ===
#speaker:analyst

Analyst: *uncomfortable* Honestly? It looks bad.

Analyst: Coordinated mixing, consistent timing, large amounts, single destination...

Analyst: If I saw this pattern at any other exchange, I'd assume criminal network funding.

Analyst: But Satoshi says we're a legitimate business. Elena vouches for our compliance.

Analyst: So I'm trying not to jump to conclusions.

-> hub

=== reporting_status ===
#speaker:analyst

Analyst: Flagged to Elena. She's investigating.

Analyst: She hasn't filed an external SAR yet, which means either it's legitimate activity or she's gathering more evidence.

Analyst: I trust her judgment. She's way smarter than me.

-> hub

// ===========================================
// PATTERN CONCERNS
// ===========================================

=== pattern_concerns ===
#speaker:analyst
~ topic_patterns = true

Analyst: *pulls up a graph* Look at this. Five different source wallets.

Analyst: They convert to Monero on the same schedule. Mix through our infrastructure. Reconverge to one destination.

Analyst: Pattern repeats weekly. Like clockwork.

+ [What do you think it means?]
    -> pattern_interpretation

+ [Can you identify the source wallets?]
    -> source_identification

=== pattern_interpretation ===
#speaker:analyst

Analyst: My guess? Coordinated fundraising. Multiple revenue streams feeding a central operation.

Analyst: Could be legit—distributed business with centralized accounting.

Analyst: Could be money laundering—criminal network consolidating funds.

Analyst: Without knowing who controls the wallets, it's hard to say.

-> hub

=== source_identification ===
#speaker:analyst

Analyst: Not from blockchain alone. Monero anonymization is really good.

Analyst: Our internal logs have more info, but Elena restricts access.

Analyst: I can see the patterns. She can see the actual wallet addresses and transaction details.

-> hub

// ===========================================
// PERSONAL CONCERNS
// ===========================================

=== personal_concerns ===
#speaker:analyst
~ topic_concerns = true

Analyst: *pauses work* You want my honest opinion?

Analyst: I love blockchain forensics. I love privacy technology. I believe in what we're supposed to be doing.

+ [But?]
    -> but_response

+ [What are you worried about?]
    -> worry_response

=== but_response ===
#speaker:analyst

Analyst: But some of these patterns scare me.

Analyst: I'm analyzing transactions that might be funding... I don't know. Terrorism? Organized crime?

Analyst: And I tell myself it's not my job to judge. I'm just the analyst. Elena makes the decisions.

Analyst: But that feels like an excuse.

-> moral_conflict

=== worry_response ===
#speaker:analyst

Analyst: That we're not just providing privacy. We're providing cover.

Analyst: That our ideals about financial freedom are being exploited by people who... aren't idealists.

-> moral_conflict

=== moral_conflict ===
#speaker:analyst

Analyst: *looks at you* That's why you're here, isn't it? FinCEN doesn't audit mid-size exchanges unless something's flagged.

Analyst: Someone thinks we're dirty.

+ [I can't comment on ongoing investigations]
    -> professional_response

+ [Do you think the exchange is being used illegally?]
    -> direct_question

=== professional_response ===
#speaker:analyst

Analyst: *laughs bitterly* Right. Professional.

Analyst: Well, when your investigation concludes, I hope you tell me whether I've been helping criminals.

Analyst: I'd like to know if my work has been... meaningful. Or just enabling.

#exit_conversation
-> DONE

=== direct_question ===
#speaker:analyst

Analyst: *long pause*

Analyst: I think some of our customers are using our privacy infrastructure for things that would horrify me if I knew the details.

Analyst: I think Elena knows more than she's telling me.

Analyst: And I think Satoshi cares more about ideology than consequences.

Analyst: So yeah. Probably.

#exit_conversation
-> DONE
