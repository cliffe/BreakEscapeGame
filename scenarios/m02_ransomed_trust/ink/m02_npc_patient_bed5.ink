// ===========================================
// Ward Patient: Bed 5 (Ms Chen, post-op)
// Mission 2: Ransomed Trust
// Break Escape - Stakes witness / ambient
// ===========================================

VAR spoke_to_player = false

=== start ===
{not spoke_to_player:
    ~ spoke_to_player = true
    Narrator: She lowers her book.

    Ms Chen: You'll be the one they've brought in about the computers.
    -> first_words
}
{spoke_to_player:
    Ms Chen: Any progress, or are we still guessing?
    -> hub
}

=== first_words ===

Ms Chen: They've told us it's a cyber attack. Ransomware, the young doctor said, as though that explained itself.

Ms Chen: Forty years I taught in Edinburgh and I never once had to think about it. Now here we are.

* [We're working on it. Your care isn't affected.]
    Ms Chen: That's what the nurse said, and I believe her about me.
    Ms Chen: But Mrs Hargreaves in bed two is on that machine, and the screen above her is off.
    Ms Chen: I've been watching her since three. I've nothing else to do and Sister cannot be in six places.
    -> hub

* [How are you holding up?]
    Ms Chen: I've had my operation. I'm just waiting now, and waiting I can do.
    Ms Chen: It's the ones who cannot tell you they're in trouble that I'd worry about, if I were you.
    -> hub

=== hub ===
+ [Thank you for watching out for your neighbours.]
    Ms Chen: That's not watching out. That's just being in the same room as somebody.
    -> hub

+ [I'll let you rest.]
    #exit_conversation
    -> hub
