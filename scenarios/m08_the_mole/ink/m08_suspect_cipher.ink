// ================================================
// Mission 8: The Mole - Suspect: Agent 0x23 'Cipher' (RED HERRING, innocent)
// Speaker: Agent 0x23 'Cipher'
// Entry knot: start   Sets: cipher_interviewed
// Real investigation: alibi, cross-references, an accusation branch that hurts
// an innocent man. Rewards attention (his project detail seeds flag 3's mailbox).
// ================================================

VAR cipher_interviewed = false
VAR cipher_influence = 0
VAR suspect_theory = ""
VAR found_access_logs = false
VAR cipher_alibi_known = false
VAR asked_hours = false
VAR asked_alibi = false
VAR asked_others = false
VAR asked_project = false
VAR accused_cipher = false

=== start ===
{ cipher_interviewed:
    Agent 0x23 'Cipher': You again. Come to cross me off, or add me back on?
    -> hub
}
Narrator: Cipher does not look up until you are right on top of him, and then he looks up too fast, knocking a stylus off the desk.

Agent 0x23 'Cipher': I know how it looks. The hours, the locked screen, me flinching just now. I've run the inference on myself and it's not flattering. Please just ask the questions so I can watch you decide I'm boring.
~ cipher_interviewed = true
-> hub

=== hub ===
+ { not asked_hours } [Why the odd hours, then?]
    ~ asked_hours = true
    Agent 0x23 'Cipher': Because the work is classified above the clerk who writes the roster. I can't put "post-quantum key exchange, do not disturb" on a shared calendar. So I look like I'm hiding something. I am. It's just not the something you're selling tickets to.
    ~ cipher_influence += 1
    # influence_increased
    -> hub
+ { not asked_alibi } [Where were you when the Mission 7 plan leaked?]
    ~ asked_alibi = true
    ~ cipher_alibi_known = true
    Agent 0x23 'Cipher': Right here. Alone. The single worst alibi a person can offer, and completely true. But pull the terminal auth for the leak window -- my badge never went near the mission_planning share. I was in the crypto library the whole night, and the library logs its own door.
    Agent 0x23 'Cipher': Whoever opened that plan did it from a Crypto Lab terminal. My desk is on the ops floor. Do the geography. #set_global:cipher_alibi_known:true
    -> hub
+ { asked_alibi and found_access_logs and not asked_project } [The logs back you. But your screen's still locked.]
    ~ asked_project = true
    Agent 0x23 'Cipher': *quiet, relieved* You actually checked. Thank you. The screen -- fine. It's a mailbox and a key schedule for the new exchange. If ENTROPY ever cracks our old crypto, everything on that box is what keeps them out of the next decade. That's the secret. That's the whole guilty secret. I've been working nights to protect the people who suspect me.
    ~ cipher_influence += 2
    # influence_increased
    -> hub
+ { not asked_others } [Who do you think it is?]
    ~ asked_others = true
    Agent 0x23 'Cipher': *lowers his voice* Phantom asks too much -- but he always did, it's practically a personality. Nightshade asks nothing. Ever. About anything. I used to file that under discipline. Lately I think it's the quiet of a man who already has all his answers and is just waiting for the rest of us to catch up.
    Agent 0x23 'Cipher': But I'm frightened and pattern-matching in the dark, so weight that accordingly.
    -> hub
+ [I think it's you, Cipher.] -> accuse
+ [That's all for now.] -> leave

=== accuse ===
~ accused_cipher = true
{ cipher_alibi_known:
    Agent 0x23 'Cipher': *stricken* You've seen the logs. You KNOW my badge wasn't on that share and you're saying it anyway. Is it because I'm strange? Because I don't smile right? Do the maths again, please, because the maths is the only friend I've got in this building.
    ~ cipher_influence -= 2
    # influence_decreased
- else:
    Agent 0x23 'Cipher': *goes very still* On what? You haven't even pulled the auth logs. You've decided on my face. That's -- that's exactly how the wrong person walks free. You spend your suspicion on the easy target and the careful one just... waits.
    ~ cipher_influence -= 2
    # influence_decreased
}
Agent 0x23 'Cipher': Go and check. Please. Then come back and tell me you're sorry, or come back with cuffs. Either. Just don't leave it hanging.
-> hub

=== leave ===
{ accused_cipher:
    Agent 0x23 'Cipher': Check the logs. That's all I ask.
- else:
    Agent 0x23 'Cipher': You'll clear me on the evidence, not on my face. Good. My face has never once done me a favour.
}
#set_global:cipher_interviewed:true #complete_task:interview_cipher
#exit_conversation
-> DONE
