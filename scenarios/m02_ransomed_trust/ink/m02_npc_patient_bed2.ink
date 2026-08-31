// ===========================================
// Ward Patient: Bed 2 (Mrs Hargreaves, ECMO)
// Mission 2: Ransomed Trust
// Break Escape - Stakes witness / critical dependency
// ===========================================

VAR spoke_to_player = false

=== start ===
{not spoke_to_player:
    ~ spoke_to_player = true
    Mrs Hargreaves: *eyes open, barely* ...that you, love?
    -> first_words
}
{spoke_to_player:
    Mrs Hargreaves: ...still at it, love?
    -> hub
}

=== first_words ===

Mrs Hargreaves: ...can't see me screen. Sister says it's down.

Mrs Hargreaves: *breath* That screen tells them. If me heart's doing what it should.

Mrs Hargreaves: Three weeks I've watched that screen.

* [The machine keeping you going is still working. We're working to restore the monitors.]
    Mrs Hargreaves: ...good.
    Mrs Hargreaves: I know this machine. Me and it have an understanding.
    Mrs Hargreaves: *breath* I just don't like not being able to see.
    -> hub

* [How are you feeling right now?]
    Mrs Hargreaves: Like I'm plugged into summat I can't switch off. Which I am.
    Mrs Hargreaves: *very faint* Don't fuss. I've had good days and bad days on this thing.
    Mrs Hargreaves: Today's... a day.
    -> hub

=== hub ===
+ [I'll let you rest.]
    #exit_conversation
    -> hub
