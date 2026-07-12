// ===========================================
// ACT 2 NPC: Marcus Webb (IT Administrator)
// Mission 2: Ransomed Trust
// Break Escape - Guilty Ally, Social Engineering Target
// ===========================================

// Variables for tracking player relationship and topics
VAR marcus_influence = 0          // 0-100 trust/rapport with Marcus
VAR marcus_defensive = false      // Is Marcus defensive/hostile?
VAR marcus_trusts_player = false  // Has Marcus reached trust threshold?
VAR topic_warnings = false        // Discussed ignored security warnings
VAR topic_passwords = false       // Discussed password hints
VAR topic_vulnerability = false   // Discussed CVE-2010-4652
VAR topic_family = false          // Discussed Emma (daughter)
VAR gave_keycard = false          // Marcus gave player server room keycard

// Synced from globalVars by engine at call-open (inside-asset investigation)
VAR insider_evidence_partial = false
VAR insider_identified = false

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// FIRST ENCOUNTER
// ===========================================

=== start ===
#speaker:marcus_webb

{marcus_defensive:
    Marcus: I don't have time for this. Systems are down.
    #exit_conversation
    -> hub
}

Marcus: I TOLD them six months ago about CVE-2010-4652!

Marcus: They said "budget constraints." Now look what happened.

Marcus: Nobody listens to IT until everything's on fire.

* [Budget cuts are common. You did your job by warning them.]
    ~ marcus_influence += 15
    # influence_increased
    -> sympathize_response

* [Let's focus on recovery. What do you need from me?]
    ~ marcus_influence += 5
    # influence_increased
    -> professional_response

* [Why didn't you push harder? Make them listen?]
    ~ marcus_influence -= 15
    # influence_decreased
    ~ marcus_defensive = true
    -> defensive_response

=== sympathize_response ===
#speaker:marcus_webb

Marcus: *sighs* Thanks. Nobody else thinks so.

Marcus: Dr. Kim recommended cutting my security budget. Board approved it.

Marcus: Now they're planning to fire me. Scapegoat the IT guy.

~ marcus_trusts_player = true
~ topic_warnings = true

+ [That's wrong. You warned them. I'll make sure that's documented.]
    ~ marcus_influence += 20
    # influence_increased
    Marcus: You... you'd do that?
    Marcus: I have all the emails. Six months of ignored warnings.
    -> offer_help

+ [We need to recover those systems. Can you help me?]
    -> ask_for_help

=== professional_response ===
#speaker:marcus_webb

Marcus: Right. Professional. I appreciate that.

Marcus: Look, I know the FTP server that was compromised. ProFTPD 1.3.5.

Marcus: The vulnerability is CVE-2010-4652. I documented it in May.

~ topic_vulnerability = true
~ marcus_influence += 5
# influence_increased
+ [Can I get access to the server room?]
    -> ask_for_help

+ [Tell me more about those warnings you sent.]
    -> discuss_warnings

=== defensive_response ===
#speaker:marcus_webb
~ marcus_defensive = true

Marcus: Are you SERIOUS? I documented everything!

Marcus: Email chains, risk assessments, budget proposals. Six months of work.

Marcus: They. Didn't. Listen.

Marcus: You know what? Figure it out yourself if you think I'm the problem here.

#exit_conversation
-> DONE

=== discuss_warnings ===
#speaker:marcus_webb
~ topic_warnings = true

Marcus: May 17th, 2024. I sent a formal security advisory to Dr. Kim.

Marcus: "ProFTPD 1.3.5 backdoor vulnerability. CRITICAL severity. Immediate patching required."

Marcus: I sent her seven emails about this CVE. Seven. She always replied "noted" -- then approved another MRI.

Marcus: She forwarded it to the board with a recommendation to defer.

Marcus: $85,000 for server security, or $3.2 million for a new MRI. Guess which they chose.

~ marcus_influence += 5
# influence_increased
+ [That must be frustrating.]
    ~ marcus_influence += 10
    # influence_increased
    Marcus: You have no idea.
    -> hub

+ [Can we recover without paying ransom?]
    -> discuss_recovery

=== discuss_recovery ===
#speaker:marcus_webb

Marcus: Technically, yes. If you can exploit the same backdoor they used.

Marcus: Get the decryption keys from the backup server.

Marcus: But that takes time. 12 hours minimum. Patients at risk the whole time.

+ [I need access to the server room.]
    -> ask_for_help

=== ask_for_help ===
#speaker:marcus_webb

{marcus_influence >= 30:
    -> high_trust_help
}
{marcus_influence >= 10 and marcus_influence < 30:
    -> medium_trust_help
}
{marcus_influence < 10:
    -> low_trust_help
}

=== high_trust_help ===
#speaker:marcus_webb
~ marcus_trusts_player = true
#give_item:keycard
Marcus: I trust you. You're here to actually fix this, not assign blame.

Marcus: Here's my server room keycard. Full access.

Marcus: And... *pulls out sticky note* Common passwords employees used. Embarrassing, really.

Marcus: My daughter's name "Emma", hospital anniversary dates, that kind of thing.

#complete_task:talk_to_marcus
#complete_task:obtain_password_hints
#unlock_task:access_server_room
~ gave_keycard = true
~ topic_passwords = true

-> offer_help

=== medium_trust_help ===
#speaker:marcus_webb

Marcus: Server room's locked. I can't just hand over my keycard--there are protocols.

Marcus: But... *glances around* The lock isn't great. Standard pin tumbler.

Marcus: If you have lockpicks, you could probably get in. I won't stop you.

#complete_task:talk_to_marcus
#unlock_task:access_server_room

~ marcus_influence += 5
# influence_increased
+ [Any password hints that could help me get in?]
    -> request_password_hints

+ [Thanks for the help.]
    Marcus: Just... save those patients. Please.
    -> hub

=== low_trust_help ===
#speaker:marcus_webb

Marcus: Look, I can't give you server room access. There are protocols.

Marcus: Figure it out yourself. I have enough problems.

#complete_task:talk_to_marcus

-> hub

=== request_password_hints ===
#speaker:marcus_webb

{marcus_influence >= 15:
    ~ topic_passwords = true
    ~ marcus_influence += 5
    # influence_increased
    Marcus: *sighs* Fine. But this stays between us.
    Marcus: Common passwords: Emma2018, Hospital1987, StCatherines.
    Marcus: Employees used birthdays, company names, stupid variations.
    #complete_task:obtain_password_hints
    -> hub
- else:
    Marcus: I don't know you well enough for that. Sorry.
    -> hub
}

=== offer_help ===
#speaker:marcus_webb

Marcus: One more thing. There's a filing cabinet in my office.

Marcus: Email archives from the past year. Proof I warned them.

Marcus: It's locked, but if you can open it... that's my vindication.

#unlock_task:investigate_marcus_office

-> hub

// ===========================================
// CONVERSATION HUB (Repeatable Dialogue)
// ===========================================

=== hub ===
+ {not topic_warnings} [What warnings did you send them?]
    -> discuss_warnings

+ {not topic_vulnerability} [Tell me about the ProFTPD vulnerability.]
    -> discuss_vulnerability

+ {not topic_passwords and marcus_influence >= 15} [Any password hints that could help me get in?]
    -> request_password_hints

+ {not topic_family} [Who's in the photo on your desk?]
    -> discuss_family

+ {topic_warnings and marcus_influence >= 20} [I'll make sure the evidence shows you warned them. You won't be scapegoated.]
    -> promise_protection

+ {insider_evidence_partial and not insider_identified} [The insider who confirmed ENTROPY's timing -- that was you, wasn't it?]
    -> accuse_marcus

+ [I should get back to it.]
    #speaker:marcus_webb
    {marcus_trusts_player:
        Marcus: Good luck. And... thanks for listening.
    }
    {not marcus_trusts_player:
        Marcus: Yeah. Go fix things.
    }
    #exit_conversation
    -> hub

// ===========================================
// WRONG ACCUSATION (red herring -- Marcus is innocent of treason)
// ===========================================

=== accuse_marcus ===
#speaker:marcus_webb

Marcus: What? No. NO. I'm the one who WARNED them. Seven times. You've read the emails yourself.

Marcus: You think I'd hand the keys to the people who did this? After what it's cost my patients, my career?

* [You're right. That doesn't add up. I'm sorry.]
    -> accuse_marcus_backdown

* [You had the access and the grievance. Convenient.]
    -> accuse_marcus_push

=== accuse_marcus_backdown ===
#speaker:marcus_webb

Marcus: ...Fine. Just find who actually did this. Don't pin it on the one bloke who tried to stop it.

-> hub

=== accuse_marcus_push ===
#speaker:marcus_webb
~ marcus_defensive = true

Marcus: A grievance? You're building a case against ME now?

Marcus: Get out. Get OUT. I'm done helping you hang me for their crime.

#hostile:marcus_webb
#set_global:accused_wrong_suspect:true
#exit_conversation
-> DONE

=== discuss_vulnerability ===
#speaker:marcus_webb
~ topic_vulnerability = true

Marcus: CVE-2010-4652. ProFTPD versions 1.3.3c through 1.3.5.

Marcus: Backdoor in the source code. Remote code execution.

Marcus: Patched in 2011. We're running a 2010 version because "budgets."

~ marcus_influence += 5
# influence_increased
+ [Running 14-year-old vulnerable software. That's negligent.]
    ~ marcus_influence += 10
    # influence_increased
    Marcus: Exactly! But nobody listens to the IT guy.
    -> hub

+ [Can we use that same vulnerability to recover data?]
    Marcus: That's... actually smart. Fight fire with fire.
    ~ marcus_influence += 5
    # influence_increased
    -> hub

=== discuss_family ===
#speaker:marcus_webb
~ topic_family = true

Marcus: That's Emma. My daughter. She just turned seven.

Marcus: May 17th, 2018. Same day I sent that security warning.

Marcus: Ironic, right? Happiest day of my life, most ignored email of my career.

~ marcus_influence += 5
# influence_increased
+ [She's lucky to have a dad who cares about security.]
    ~ marcus_influence += 10
    # influence_increased
    Marcus: Thanks. I just hope she doesn't read about this in the news.
    -> hub

+ [Let's make sure this gets resolved properly.]
    -> hub

=== promise_protection ===
#speaker:marcus_webb

~ marcus_influence += 20
# influence_increased
Marcus: I... thank you. That means everything.

Marcus: I have all the emails, all the documentation. They can't ignore it if it's public.

Marcus: Just... save those patients first. Then we'll worry about blame.

#complete_task:promise_to_protect_marcus
#set_global:marcus_protected:true

-> hub
