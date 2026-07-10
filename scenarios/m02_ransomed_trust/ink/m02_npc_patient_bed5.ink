// ===========================================
// Ward Patient: Bed 5 (Ms Chen, post-op)
// Mission 2: Ransomed Trust
// Break Escape - Stakes witness / ambient
// ===========================================

VAR spoke_to_player = false

=== start ===
{not spoke_to_player:
    ~ spoke_to_player = true
    Ms Chen: *glances up from her pillow* You're the person from the computers?
    -> first_words
}
{spoke_to_player:
    Ms Chen: Everything alright?
    -> hub
}

=== first_words ===

Ms Chen: They told us there'd been a... cyber attack. Ransomware.

Ms Chen: I didn't know you had to worry about that sort of thing in a hospital.

* [We're working on it. Your care isn't affected.]
    Ms Chen: That's what the nurse said. But the lady in Bed 2 -- she's on that machine.
    Ms Chen: I keep looking over. She seems alright. But the nurse can't watch everyone at once.
    -> hub

* [How are you holding up?]
    Ms Chen: I've had my operation, so I'm just waiting now. I'm not the one who needs watching.
    Ms Chen: It's the others I'm thinking about. The ones who can't speak for themselves.
    -> hub

=== hub ===
+ [Thank you for watching out for your neighbours.]
    Ms Chen: That's what you do, isn't it. We're all in the same ward.
    -> hub

+ [I'll let you rest.]
    #exit_conversation
    -> hub
