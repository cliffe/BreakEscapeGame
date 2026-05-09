// ===========================================
// Ward Patient: Bed 2 (Mrs Hargreaves, ECMO)
// Mission 2: Ransomed Trust
// Break Escape - Stakes witness / critical dependency
// ===========================================

VAR spoke_to_player = false

=== start ===
{not spoke_to_player:
    ~ spoke_to_player = true
    Mrs Hargreaves: *eyes open, very weakly* ...someone there?
    -> first_words
}
{spoke_to_player:
    Mrs Hargreaves: ...still here?
    -> hub
}

=== first_words ===

Mrs Hargreaves: ...can't see the screen. The nurse said the screen was down.

Mrs Hargreaves: That screen... told them if my heart was doing what it's supposed to.

* [Try to reassure her]
    You: The machine keeping you going is still working. We're working to restore the monitors.
    Mrs Hargreaves: ...good. I know this machine. Been on it three weeks.
    Mrs Hargreaves: Just... don't like not being able to see.
    -> hub

* [Ask how she's feeling]
    You: How are you feeling right now?
    Mrs Hargreaves: Like I'm on a machine that I can't switch off. Which I am.
    Mrs Hargreaves: *very faint* Don't worry. I've had good days and bad days on this thing. Today's... a day.
    -> hub

=== hub ===
+ [Leave her to rest]
    #exit_conversation
    -> hub
