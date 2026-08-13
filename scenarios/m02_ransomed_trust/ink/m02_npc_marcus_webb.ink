// ===========================================
// ACT 2 NPC: Marcus Webb -- IT Systems Administrator
// Mission 2: Ransomed Trust
//
// Marcus holds the only credential in the building that still opens anything:
// the server room card, on an isolated reader that survived the encryption.
// He is therefore the mission's hard gate -- which means he must NEVER be a
// dead end. Four routes to the card:
//
//   RAPPORT   -- treat him as a professional who was right. He hands it over,
//                plus the spare contractor lanyard and the credentials.
//   LEVERAGE  -- pick his filing cabinet first and put his own seventh warning
//                on the desk in front of him. Recovers him from ANY state,
//                including hostile. Rewards the player who explored.
//   TRANSACTION -- be cold about it. He gives you the card and nothing else.
//   FORCE     -- KO him; itemsHeld drops both card and lanyard. taskOnKO
//                covers talk_to_marcus, the handler covers the credentials.
//
// So the "wrong" opening costs the player the lanyard, the credentials from
// his mouth, and his good opinion. It never costs them the mission -- the
// sticky note on his monitor carries the credentials regardless.
// ===========================================

EXTERNAL player_name()

VAR marcus_influence = 0
VAR marcus_defensive = false
VAR marcus_trusts_player = false
VAR gave_keycard = false
VAR gave_lanyard = false
VAR topic_warnings = false
VAR topic_vulnerability = false
VAR topic_family = false
VAR topic_passwords = false
VAR showed_him_the_email = false
VAR met_marcus = false                 // prevents replaying first_meeting with its * choices already spent
VAR marcus_protected_locally = false   // local mirror so the boardroom-email hub option retires once used

// Synced from globalVars by engine at call-open
VAR marcus_evidence_recovered = false
VAR board_coverup_email_found = false
VAR cover_burned = false
VAR cover_restored = false
VAR insider_evidence_partial = false
VAR insider_identified = false

// ===========================================
// ENTRY
// ===========================================

=== start ===
{marcus_defensive:
    -> defensive_return
}
{gave_keycard:
    -> returning
}
{met_marcus:
    -> returning
}
-> first_meeting

=== first_meeting ===
~ met_marcus = true

Narrator: Two dead terminals, a cold mug with a skin on it, and squared up on the desk beside the keyboard, printed out, a stack of his own emails.

Marcus Webb: *not turning round* If you're the bloke from head office, the answer's still no, I can't "just restore from backup", because the backup is the bit they encrypted.

Marcus Webb: If you're the police, I've told your mate everything twice.

Marcus Webb: And if you're the board, I've got nothing to say to you that I haven't already put in writing seven times.

* [Seven times. I know. I've read them.]
    ~ marcus_influence += 15
    # influence_increased
    -> open_solidarity

* [I'm the incident responder. Talk me through what you've got.]
    ~ marcus_influence += 8
    # influence_increased
    -> open_professional

* [You're the administrator. This is your estate. How did it get this bad?]
    ~ marcus_influence -= 18
    # influence_decreased
    -> open_blame

// ===========================================
// OPENING 1 -- SOLIDARITY
// ===========================================

=== open_solidarity ===
~ topic_warnings = true
~ marcus_trusts_player = true

Narrator: He turns round properly for the first time.

Marcus Webb: You've read them.

Marcus Webb: *carefully, like he's testing a stair* Nobody's read them. Not properly. Kim read the first one. Somebody in Finance read the one with the number in it. After that it was "noted" and "noted" and "noted".

Marcus Webb: I got so I was writing them for the archive. Not to be actioned. Just so that one day somebody could find them and see I'd said it.

Marcus Webb: Bit pathetic when you say it out loud.

+ [It isn't pathetic. It's a paper trail, and tonight it's the most useful thing in this building.]
    ~ marcus_influence += 12
    # influence_increased
    Narrator: Something goes out of his shoulders.

    Marcus Webb: Right. Yeah.
    Marcus Webb: Right. What do you need?
    -> the_ask

+ [Six months of being ignored, and you're still here at four in the morning fixing it.]
    ~ marcus_influence += 10
    # influence_increased
    Marcus Webb: Well, where else am I going to be? There's people upstairs on generators.
    Marcus Webb: You can be furious and useful. Turns out. Who knew.
    -> the_ask

+ [Then let's make sure this time somebody actions it. What do you need from me?]
    ~ marcus_influence += 8
    # influence_increased
    Marcus Webb: What I need is a time machine and eighty-five grand in May.
    Marcus Webb: Failing that -- ask me your questions.
    -> the_ask

// ===========================================
// OPENING 2 -- PROFESSIONAL
// ===========================================

=== open_professional ===
~ topic_vulnerability = true

Narrator: He swivels the chair round.

Marcus Webb: Finally. Someone who wants the technical version.

Marcus Webb: Backup server. ProFTPD one point three point five. There's a backdoor sat in that source tree -- CVE-2010-4652 -- and it's been public and patchable since 2011. Fourteen years.

Marcus Webb: Whoever did this didn't have to be clever. They had to be awake and have a scanner.

Marcus Webb: That box is where every clinical backup we own lives. That's the whole disaster, in one sentence, and I put that sentence in an email in May.

+ [Fourteen years unpatched on the box that holds every backup. That's not your failure, that's a funding decision.]
    ~ marcus_influence += 12
    # influence_increased
    ~ topic_warnings = true
    ~ marcus_trusts_player = true
    Marcus Webb: *quietly* Say that again in front of the board and I'll buy you a pint.
    -> the_ask

+ [Then we go in the same way they did. Show me the route.]
    ~ marcus_influence += 8
    # influence_increased
    Marcus Webb: *first hint of life* Fight fire with fire. Yeah. Yeah, that's not stupid.
    Marcus Webb: The exploit gets you a shell. From there it's their staging, their logs, their everything.
    -> the_ask

// ===========================================
// OPENING 3 -- BLAME
// A real consequence, not a soft-lock. He still surrenders the card.
// ===========================================

=== open_blame ===
~ marcus_defensive = true

Narrator: He goes very still.

Marcus Webb: My estate.

Marcus Webb: I costed the fix in May. Eighty-five thousand pounds. I sent it seven times. I was told to stop escalating it outside the department, in writing, by the Chief Technology Officer, and I have that email in my hand right now.

Marcus Webb: Then they signed off three point two million on a scanner.

Narrator: He picks the keycard off the desk and puts it down again in front of you, hard enough that it skids.

Marcus Webb: Server room. Take it. That's what you came for.

Marcus Webb: And when they write this up and it says the administrator failed to maintain his estate -- you'll know. You'll have known and said nothing. Same as the rest of them.

#complete_task:talk_to_marcus
#give_item:keycard:server_room_keycard
~ gave_keycard = true

* [Marcus -- ]
    Marcus Webb: Don't.
    -> defensive_hub

* [Take the card back. Let's start again.]
    ~ marcus_influence += 5
    # influence_increased
    Marcus Webb: *flatly* You keep it. I'm not doing this twice.
    -> defensive_hub

// ===========================================
// THE ASK -- the keycard, cooperatively
// ===========================================

=== the_ask ===
+ {not gave_keycard} [I need into the server room. What's it going to take?]
    -> keycard_request

+ {not topic_warnings} [Tell me about the warnings.]
    -> discuss_warnings

+ {not topic_vulnerability} [Walk me through the vulnerability.]
    -> discuss_vulnerability

+ [Nothing yet. I'll come back.]
    #complete_task:talk_to_marcus
    #exit_conversation
    Marcus Webb: I'll be here. Obviously.
    -> hub

=== keycard_request ===
Narrator: He pulls a lanyard out from under his collar and looks at it.

Marcus Webb: Funny thing. Every badge reader in this hospital is dead, because the thing that decides who's allowed where is sat behind the same ransom screen as everything else.

Marcus Webb: Except the server room. That reader's on its own controller, isolated, no network. I argued for that in 2019 and I actually won one, for once.

Marcus Webb: So this is the only card in St Catherine's that still opens anything at all. And there is no way on earth to issue you one of your own, because the thing that issues them is encrypted.

{marcus_influence >= 25:
    -> keycard_trusted
}
{marcus_influence >= 8:
    -> keycard_conditional
}
-> keycard_reluctant

=== keycard_trusted ===
~ gave_keycard = true
~ marcus_trusts_player = true
~ topic_passwords = true
#complete_task:talk_to_marcus
#complete_task:obtain_password_hints
#give_item:keycard:server_room_keycard

Narrator: He takes it off over his head and puts it in your hand without ceremony.

Marcus Webb: There. If this goes wrong it's got my name on it, so don't make me look daft.

Marcus Webb: And you'll want this as well.

Narrator: He pulls a folded sticky note off the monitor bezel and flattens it out.

Marcus Webb: Shared admin credential on the backup box. Never rotated. I know. I KNOW. It's on the list, and the list is four years long, and the list is why we're here.

Marcus Webb: Emma2018. Hospital1987. StCatherines. One of those three gets you an SSH session. I'd try the middle one.

-> offer_cabinet

=== keycard_conditional ===
~ gave_keycard = true
#complete_task:talk_to_marcus
#give_item:keycard:server_room_keycard

Narrator: He hesitates, then holds it out.

Marcus Webb: Right. Take it.

Marcus Webb: But that reader logs every swipe locally, and when this is over somebody is going to read that log and see my card in that room at four in the morning while I was sat in here.

Marcus Webb: So if anybody asks, you tell them I gave it you. Don't get clever and say you found it.

+ [You have my word. It goes in my report exactly as it happened.]
    ~ marcus_influence += 12
    # influence_increased
    Marcus Webb: *nods once* Then we're alright.
    -> offer_cabinet

+ [Understood.]
    ~ marcus_influence += 3
    # influence_increased
    -> the_ask

=== keycard_reluctant ===
~ gave_keycard = true
#complete_task:talk_to_marcus
#give_item:keycard:server_room_keycard

Narrator: He pushes it across the desk without looking at you.

Marcus Webb: There's forty-seven people on generators. I'm not going to be the reason you were stood out there arguing about it.

Marcus Webb: Doesn't mean I've warmed to you.

-> the_ask

// ===========================================
// LEVERAGE ROUTE -- the reward for exploring
// Recovers him from ANY state, including defensive.
// ===========================================

=== show_the_email ===
~ showed_him_the_email = true
~ marcus_defensive = false
~ marcus_trusts_player = true
~ topic_warnings = true
~ marcus_influence += 30
# influence_increased

Narrator: You put the seventh warning on the desk between you. Dated 17 May. Copied to the board secretariat. Answered four days later with a deferral and a request that he stop escalating.

Narrator: Marcus looks at his own words on somebody else's paper for a long moment.

Marcus Webb: Where'd you get that.

* [Your filing cabinet. It's a good lock. Not a great one.]
    Marcus Webb: *almost laughs* No. It isn't.
    -> email_reaction

* [It doesn't matter. What matters is it exists and it's in my hands now.]
    -> email_reaction

=== email_reaction ===
Marcus Webb: Do you know what I've been doing tonight? Between the restores?

Marcus Webb: Printing those. All seven. Because I've been sat here working out how long it takes a hospital board to decide that a thing was one man's fault, and the answer is about a day and a half.

Marcus Webb: So I thought: at least when they come for me, it'll be on paper.

Narrator: He straightens the stack.

Marcus Webb: And now you've walked in with one of them already in your hand.

* [I'm putting all seven in the SAFETYNET record. You won't be carrying this on your own.]
    ~ marcus_influence += 15
    # influence_increased
    #complete_task:learn_about_scapegoating
    #set_global:marcus_protected:true
    Narrator: He has to look away for a second.

    Marcus Webb: Right.
    Marcus Webb: Right, well. Then let's get you what you need, and quick, before I make a show of myself.
    -> leverage_payoff

* [I need the same thing your board needed and ignored. Access.]
    ~ marcus_influence += 5
    # influence_increased
    Marcus Webb: Fair enough. At least you're honest about what this is.
    -> leverage_payoff

=== leverage_payoff ===
~ topic_passwords = true
#complete_task:talk_to_marcus
#complete_task:obtain_password_hints

{not gave_keycard:
    ~ gave_keycard = true
    #give_item:keycard:server_room_keycard
    Narrator: The lanyard comes off over his head and lands in your palm.
    Marcus Webb: Server room. Isolated reader -- it's the only card in the building that still works.
}

Narrator: He peels the sticky note off the monitor bezel.

Marcus Webb: Shared admin credential on the backup box, never rotated. Emma2018, Hospital1987, StCatherines. Middle one, I'd bet.

Marcus Webb: Yes, I know how that looks. Put it in the report. Put all of it in the report.

-> offer_cabinet

// ===========================================
// THE CABINET
// ===========================================

=== offer_cabinet ===
{showed_him_the_email:
    -> hub
}

Marcus Webb: One more thing. Filing cabinet, behind you.

Marcus Webb: Every warning I sent, and every answer I got back. A year of it.

Marcus Webb: It's locked and I've lost the key somewhere between here and 2022, which tells you everything about how this department is resourced.

Marcus Webb: If you can get into it -- take the lot. I'd rather it was in your hands than shredded in a fortnight.

// Task completes when the player actually recovers the email (handler eventMapping
// on item_picked_up:marcus_vindication_email), not when Marcus mentions the cabinet.

-> hub

// ===========================================
// MAIN HUB
// ===========================================

=== hub ===
+ {marcus_evidence_recovered and not showed_him_the_email} [Marcus. Look at this.]
    -> show_the_email

+ {not gave_keycard} [I need into the server room.]
    -> keycard_request

+ {not topic_warnings} [Tell me about the warnings you sent.]
    -> discuss_warnings

+ {not topic_vulnerability} [Walk me through the vulnerability.]
    -> discuss_vulnerability

+ {not topic_passwords} [Is there anything reused on that backup server I should try?]
    -> discuss_passwords

+ {not topic_family} [Who's in the photo?]
    -> discuss_family

+ {board_coverup_email_found and not marcus_protected_locally} [There's something in the boardroom you need to see.]
    -> tell_him_about_board

+ {cover_burned and not cover_restored and not gave_lanyard} [Someone's phoned security and pulled my booking. I need something that holds up in a corridor.]
    -> the_lanyard

+ {insider_evidence_partial and gave_keycard and not insider_identified} [The affiliate who confirmed ENTROPY's timing. Was that you?]
    -> accuse_marcus

+ [I should get on.]
    {marcus_trusts_player:
        Marcus Webb: Go on. And -- thanks. For reading them.
    - else:
        Marcus Webb: Aye.
    }
    #exit_conversation
    -> hub

// ===========================================
// TOPICS
// ===========================================

=== discuss_warnings ===
~ topic_warnings = true

Marcus Webb: Seventeenth of May. First formal one. "Critical severity, immediate patching required." I don't use the word critical lightly, it devalues it.

Marcus Webb: Reply came back on the twenty-first. Deferred to next financial year, and would I please stop escalating outside the department.

Marcus Webb: So I did it six more times anyway, because what else are you going to do.

Marcus Webb: Eighty-five thousand for the server work. Three point two million for the new scanner. Board voted seven to two.

+ [Seven to two. Somebody in that room agreed with you.]
    ~ marcus_influence += 10
    # influence_increased
    Marcus Webb: *pause* Huh.
    Marcus Webb: You know, in six months of this, you're the first person who's asked about the two.
    -> hub

+ [You did your job. They didn't do theirs.]
    ~ marcus_influence += 12
    # influence_increased
    Marcus Webb: Try telling my daughter that in about a week, when it's in the local paper with my name on it.
    -> hub

+ [Seven emails and no escalation to the regulator. That's a gap.]
    ~ marcus_influence -= 8
    # influence_decreased
    Marcus Webb: *bitterly* Right. Yeah. It's the whistleblowing I should've done, on the salary I'm on, with a seven-year-old at home.
    Marcus Webb: Thanks for that.
    -> hub

=== discuss_vulnerability ===
~ topic_vulnerability = true

Marcus Webb: CVE-2010-4652. ProFTPD, versions 1.3.3c through 1.3.5.

Marcus Webb: Somebody put a backdoor in the actual source tree back in 2010 and it shipped. Unauthenticated remote code execution. You don't need a password, you need a port.

Marcus Webb: Patched in 2011. We are running the 2010 build, in 2025, on the box that holds every clinical backup in this hospital.

+ [Why is that box even reachable?]
    ~ marcus_influence += 5
    # influence_increased
    Marcus Webb: Because it was set up in 2011 by a contractor who's dead now, and every year since, moving it has been on a list under something more urgent.
    Marcus Webb: That's how it always is. Nobody decides to be insecure. They just keep deciding something else is more pressing.
    -> hub

+ [Then it works both ways. Their door is my door.]
    ~ marcus_influence += 8
    # influence_increased
    Marcus Webb: *grimly satisfied* It does. Scan it, fingerprint the version, and there's a module that'll walk straight in.
    Marcus Webb: Fourteen years that hole's been sat there. Might as well get one useful night out of it.
    -> hub

=== discuss_passwords ===
~ topic_passwords = true
#complete_task:obtain_password_hints

Narrator: He peels a curling sticky note off the monitor bezel and holds it up without any attempt to hide his embarrassment.

Marcus Webb: Shared admin credential on the backup box. Never rotated. Been on my list since 2021.

Marcus Webb: Emma2018. Hospital1987. StCatherines. One of those three gets you an SSH session and I'd put money on the middle one.

Marcus Webb: Go on, say it. It's a disgrace.

+ [It's a disgrace. It's also completely normal, and that's worse.]
    ~ marcus_influence += 8
    # influence_increased
    Marcus Webb: *tired laugh* Now you sound like my emails.
    -> hub

+ [It's a disgrace. Put it in the remediation plan with everything else.]
    ~ marcus_influence += 4
    # influence_increased
    Marcus Webb: There's a plan. There's been a plan since May.
    -> hub

=== discuss_family ===
~ topic_family = true

Marcus Webb: Emma. She's seven. Well -- she was seven in May.

Marcus Webb: Seventeenth of May, actually. Same day I sent the first warning. Sent it from her party, in the car park, because I'd been chewing on it all week and it wouldn't wait.

Marcus Webb: *quietly* Best day of the year and I spent twenty minutes of it writing an email nobody read.

+ [Then get it back. Go home when this is done and don't bring it with you.]
    ~ marcus_influence += 10
    # influence_increased
    Marcus Webb: *nods, doesn't trust himself to say anything for a second*
    Marcus Webb: Yeah. Yeah, alright.
    -> hub

+ [She'll grow up knowing her dad was the one who said it out loud.]
    ~ marcus_influence += 12
    # influence_increased
    Marcus Webb: If anybody ever tells her. That's the bit that gets me.
    -> hub

=== tell_him_about_board ===
~ marcus_protected_locally = true

Marcus Webb: Go on.

Narrator: You describe the email. Board chair to Legal. Reframe it as an implementation failure, not a budget decision. Prepare termination paperwork and a non-disparagement agreement.

Narrator: He is quiet for long enough that the ventilation is the loudest thing in the room.

Marcus Webb: Non-disparagement.

Marcus Webb: They've written the ending. Before the generators have even run out, they've written the ending, and in it I'm the bloke who let it happen.

* [Not if the record says otherwise. I'll make sure it does.]
    ~ marcus_influence += 20
    # influence_increased
    #complete_task:learn_about_scapegoating
    #set_global:marcus_protected:true
    Marcus Webb: You'd do that.
    Marcus Webb: *steadier* Then do me one favour. Don't do it for me. Do it for whoever's sat in this chair at the next hospital, writing their seventh email.
    -> hub

* [You should get a solicitor before you say another word to anyone here.]
    ~ marcus_influence += 8
    # influence_increased
    Marcus Webb: I can't afford a solicitor. That's rather the point of the exercise, isn't it.
    -> hub

* [Then finish the job first. Argue about it afterwards.]
    ~ marcus_influence -= 5
    # influence_decreased
    Marcus Webb: *flat* Course. Wards first. There's always something first.
    -> hub

// ===========================================
// THE LANYARD -- cover-burn recovery route
// ===========================================

=== the_lanyard ===
Marcus Webb: Somebody's pulled your booking.

Marcus Webb: *slowly* That's not a computer doing that. Everything's down. Somebody picked up a phone and said words.

{marcus_influence >= 15:
    -> lanyard_given
- else:
    -> lanyard_grudging
}

=== lanyard_given ===
~ gave_lanyard = true
#give_item:id_badge:contractor_lanyard
#set_global:staff_lanyard_obtained:true
#set_global:cover_restored:true

Narrator: He opens the second drawer down and digs out a lanyard still in its wrapper.

Marcus Webb: Contractor pass. We issue them to hardware engineers. Blank, no name, real hospital stock, and nobody has ever once questioned one in eleven years of me watching people wave them about.

Marcus Webb: Which is, when you think about it, exactly the sort of thing I've been sending emails about.

Marcus Webb: Go on. And whoever made that phone call -- I'd quite like to know who, when you find out.

+ [You'll know. I'll make sure of it.]
    ~ marcus_influence += 5
    # influence_increased
    Marcus Webb: Right.
    #exit_conversation
    -> hub

=== lanyard_grudging ===
~ gave_lanyard = true
#give_item:id_badge:contractor_lanyard
#set_global:staff_lanyard_obtained:true
#set_global:cover_restored:true

Narrator: He pulls open a drawer, roots about, and drops a blank contractor lanyard on the desk.

Marcus Webb: Take it. Not for you -- for the ward.

Marcus Webb: And when they ask me later whether I gave an unidentified man a hospital pass during a live incident, I'm going to say yes, because I'm not lying about anything else tonight either.

#exit_conversation
-> hub

// ===========================================
// DEFENSIVE STATE
// He still helps, badly. The leverage route can still recover him.
// ===========================================

=== defensive_return ===
Marcus Webb: *doesn't turn round* You've got the card.

-> defensive_hub

=== defensive_hub ===
+ {marcus_evidence_recovered and not showed_him_the_email} [Marcus. Look at this.]
    -> show_the_email

+ {not topic_passwords} [The backup server's on a shared credential. What is it?]
    Marcus Webb: It's on the note. On the monitor. Where I've kept it for four years like the disgrace I am.
    Marcus Webb: Help yourself. You've clearly got opinions about my housekeeping.
    ~ topic_passwords = true
    #complete_task:obtain_password_hints
    -> defensive_hub

+ {cover_burned and not cover_restored and not gave_lanyard} [Someone's pulled my booking with security. I need a pass.]
    -> lanyard_grudging

+ [For what it's worth -- I was wrong. You warned them and they buried it.]
    ~ marcus_defensive = false
    ~ marcus_influence += 20
    # influence_increased
    Marcus Webb: *long silence*
    Marcus Webb: Say that in your report and we'll call it square.
    -> hub

+ [Fine.]
    #exit_conversation
    -> defensive_hub

// ===========================================
// RED HERRING -- Marcus is not the traitor
// ===========================================

=== accuse_marcus ===
Marcus Webb: *very carefully* Say that again.

Marcus Webb: The affiliate. You think the affiliate is the bloke who sent seven emails begging them to close the hole.

Marcus Webb: Have a think about that for a second. Go on. I'll wait.

* [You're right. It doesn't add up. I'm sorry.]
    ~ marcus_influence += 5
    # influence_increased
    Marcus Webb: No, it doesn't.
    Marcus Webb: Look -- go and ask Val on the north corridor. She's had somebody in her notebook for weeks and nobody upstairs wants to hear it.
    Marcus Webb: Ask her. Not me.
    -> hub

* [You had the access, the knowledge and six months of grievance.]
    -> accuse_marcus_push

=== accuse_marcus_push ===
~ marcus_defensive = true

Marcus Webb: Grievance.

Marcus Webb: I have got a grievance because I was RIGHT, and you're stood in my office at four in the morning building it into a motive.

Marcus Webb: That's it. That's the ending. That's them, and now it's you as well.

Marcus Webb: Get out.

#hostile:marcus_webb
#set_global:accused_wrong_suspect:true
#exit_conversation
-> DONE

// ===========================================
// RETURN VISITS
// ===========================================

=== returning ===
{cover_burned and not cover_restored and not gave_lanyard:
    Marcus Webb: *looks up* You've gone grey. What's happened?
    -> hub
}
{marcus_trusts_player:
    Marcus Webb: Any joy?
- else:
    Marcus Webb: What now?
}
-> hub
