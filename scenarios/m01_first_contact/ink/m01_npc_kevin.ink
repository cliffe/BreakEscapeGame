// ================================================
// Mission 1: First Contact - Kevin Park (IT Manager)
// Located in IT Room (PIN locked)
// Provides lockpicks, server keycard, and password hints
// ================================================

VAR influence = 0
VAR met_kevin = false
VAR discussed_audit = false
VAR asked_about_derek = false
VAR asked_about_passwords = false
VAR given_lockpick = false
VAR given_keycard = false
VAR given_password_hints = false
VAR warned_about_derek = false

// Security Audit Variables
VAR security_audit_given = false
VAR audit_questions_asked = 0
VAR audit_correct_answers = 0
VAR audit_wrong_answers = 0

// ================================================
// START: FIRST MEETING
// ================================================

=== start ===
#set_variable:talked_to_kevin=true
{not met_kevin:
    ~ met_kevin = true
    ~ influence += 2
    Kevin: Oh hey! You found the IT room. I'm Kevin—IT manager, sole IT department, and professional worrier.
    Kevin: You're the security auditor, right? Thank god you're here.
    Kevin: I've been telling them we need a review for months.
    -> first_meeting
}
{met_kevin:
    Kevin: Hey, what's up? Found anything interesting yet?
    -> hub
}

// ================================================
// FIRST MEETING
// ================================================

=== first_meeting ===
#complete_task:meet_kevin
+ [Happy to help. What's the security situation?]
    ~ influence += 2
    ~ discussed_audit = true
    -> security_situation
+ [I'll need access to secure areas for testing]
    ~ discussed_audit = true
    -> access_discussion
+ [You seem stressed]
    ~ influence += 1
    ~ discussed_audit = true
    -> kevin_stress

// ================================================
// SECURITY SITUATION
// ================================================

=== security_situation ===
Kevin: Honestly? I'm worried.

Kevin: Someone's been accessing the server room without authorization. Late at night. Multiple times.

Kevin: I flagged it to management three times. Nothing happened.

+ [Who do you think it is?]
    ~ warned_about_derek = true
    ~ influence += 1
    -> derek_suspicion
+ [That's what I'm here to investigate]
    Kevin: Good. Because I'm starting to feel like I'm the only one who cares about security around here.
    -> offer_tools

// ================================================
// DEREK SUSPICION
// ================================================

=== derek_suspicion ===
Kevin: *lowers voice* I think it's Derek Lawson. Senior Marketing Manager.

Kevin: The access logs show his credentials being used at 2 AM. But he says it's for "campaign servers."

Kevin: We don't have campaign servers in that room. It's all internal infrastructure.

Kevin: The last person who raised concerns about Derek was Patricia—our manager. She got fired.

+ [I'll look into it]
    ~ influence += 2
    Kevin: Please do. But be careful. Derek has friends in high places.
    Kevin: Here, let me give you some tools that might help.
    -> offer_tools
+ [Could be someone spoofing his credentials]
    Kevin: Maybe. But I don't think so. I've seen him leaving the office at weird hours.
    -> offer_tools

// ================================================
// ACCESS DISCUSSION
// ================================================

=== access_discussion ===
Kevin: Right, you'll need access to secure areas.

Kevin: I've got a keycard for the server room. It's behind Derek's office, actually.

Kevin: And for physical security testing, I've got something special.

-> offer_tools

// ================================================
// KEVIN STRESS
// ================================================

=== kevin_stress ===
Kevin: Yeah, it's been a rough few months.

Kevin: Ever since Patricia got fired, things have felt... off.

Kevin: She was investigating something. Asking questions about Derek's projects.

Kevin: Now she's gone and nobody will tell me why.

+ [What was she investigating?]
    ~ warned_about_derek = true
    Kevin: I don't know exactly. Something about Derek's "external partners."
    Kevin: She kept her notes in her office safe. I think her briefcase is still in there too.
    -> offer_tools
+ [Let's focus on the audit]
    Kevin: Right. Sorry. Let me get you set up.
    -> offer_tools

// ================================================
// OFFER TOOLS
// ================================================

=== offer_tools ===
Kevin: Okay, so for the audit I can give you:

Kevin: First, a lockpick set. I bought it for when people lock themselves out, but it's useful for testing physical security.

Kevin: Second, my server room keycard. You'll need it to access the main servers.

Kevin: And some notes on password patterns people use around here. Should help with the technical testing.

+ [I'll take all of it]
    ~ given_lockpick = true
    ~ given_keycard = true
    ~ given_password_hints = true
    ~ influence += 3
    #give_item:lockpick
    #give_item:keycard
    #give_item:notes
    Kevin: Here you go. The lockpicks work on most of the older locks around here.
    Kevin: The server room is through Derek's office—there's a door on the east side.
    Kevin: Just... be careful, okay? Something's not right here.
    -> hub
+ [Just the keycard for now]
    ~ given_keycard = true
    #give_item:keycard
    Kevin: Sure. Server room is through Derek's office. Let me know if you need anything else.
    -> hub

// ================================================
// CONVERSATION HUB
// ================================================

=== hub ===
+ {not given_lockpick} [About those lockpicks...]
    -> get_lockpicks
+ {not given_keycard} [I need the server room keycard]
    -> get_keycard
+ {not asked_about_passwords and influence >= 2} [Tell me about password security here]
    -> ask_passwords
+ {not asked_about_derek and influence >= 3} [What else can you tell me about Derek?]
    -> ask_about_derek
+ {not security_audit_given and (given_lockpick or given_keycard) and influence >= 2} [I'd like to give you a preliminary security audit update]
    -> security_audit_start
+ [I'll keep investigating. Thanks for the help.]
    #exit_conversation
    Kevin: No problem. And seriously—if you find anything, let me know. I need to know I'm not going crazy.
    -> hub

// ================================================
// GET LOCKPICKS
// ================================================

=== get_lockpicks ===
~ given_lockpick = true
#give_item:lockpick

Kevin: Here's the lockpick set. It's professional grade.

Kevin: Most of the older locks in the building are vulnerable. Good for testing security.

Kevin: Patricia's office has an old briefcase she left behind. You might be able to pick that open if you're curious what she was working on.

-> hub

// ================================================
// GET KEYCARD
// ================================================

=== get_keycard ===
~ given_keycard = true
#give_item:keycard

Kevin: Here's my server room keycard.

Kevin: The server room is through Derek's office—there's a connecting door on the east wall.

Kevin: The servers hold everything. If there's evidence of unauthorized activity, that's where you'll find it.

-> hub

// ================================================
// ASK ABOUT PASSWORDS
// ================================================

=== ask_passwords ===
~ asked_about_passwords = true
~ given_password_hints = true
~ influence += 1
#give_item:notes

Kevin: Password security here is... not great.

Kevin: I enforce complexity requirements on domain accounts, but people find patterns.

Kevin: Company name plus numbers. Birthdays. Anniversary dates.

Kevin: Derek uses his birthday or anniversary in everything. April 19th. Makes his passwords easy to guess.

+ [0419?]
    ~ influence += 2
    Kevin: Yeah. I've told him it's a security risk but he doesn't listen.
    Kevin: Here, I wrote down the common patterns people use. Might help with the audit.
    -> hub
+ [That's useful, thanks]
    -> hub

// ================================================
// ASK ABOUT DEREK
// ================================================

=== ask_about_derek ===
~ asked_about_derek = true
~ influence += 1

Kevin: Derek's been here about 18 months. Senior Marketing Manager.

Kevin: At first he seemed normal. Then he started requesting "enhanced privacy" for his systems.

Kevin: Wanted separate network segments, encrypted communications, locked office at all times.

Kevin: Said it was for "client confidentiality" but... marketing doesn't need that level of security.

+ [What do you think he's really doing?]
    Kevin: I don't know. But whatever it is, it's not marketing.
    Kevin: He's been meeting with external people—calls them "partners."
    Kevin: I saw notes once that mentioned something called "Operation Shatter."
    ~ influence += 2
    -> hub
+ [Maybe he's just paranoid]
    Kevin: Maybe. But Patricia didn't think so. And now she's gone.
    -> hub

// ================================================
// SECURITY AUDIT - MCQ Assessment
// ================================================

=== security_audit_start ===
~ security_audit_given = true
#set_variable:security_audit_completed=true

Kevin: Oh! Yeah, I'd love to hear what you've found so far.

Kevin: I mean, you're the professional. What's your assessment of our security posture?

Player: I've been observing and testing. Let me give you some preliminary findings.

Kevin: Please, go ahead. I need to know if I'm overreacting or if we really do have problems.

-> audit_question_1

// ================================================
// AUDIT QUESTION 1: Physical Security
// ================================================

=== audit_question_1 ===
~ audit_questions_asked += 1

Player: First, let's talk about physical security. What would you say is the most significant concern?

+ [The building's physical access controls are adequate for a company this size]
    ~ audit_wrong_answers += 1
    Kevin: Really? I was worried about those old door locks...
    Kevin: But I guess if you think they're adequate, maybe I'm being paranoid.
    -> audit_question_2
+ [The old mechanical locks and that PIN pad on the IT room are easily bypassed]
    ~ audit_correct_answers += 1
    ~ influence += 1
    Kevin: Yes! That's exactly what I've been saying!
    Kevin: I requested modern electronic locks six months ago. Budget was "under review."
    Kevin: Anyone with basic lockpicking skills could get into most rooms here.
    -> audit_question_2
+ [Physical security isn't really a priority compared to digital security]
    ~ audit_wrong_answers += 1
    Kevin: Hmm. I thought physical access was important, but you're the expert.
    Kevin: I guess I should focus more on the digital side then.
    -> audit_question_2

// ================================================
// AUDIT QUESTION 2: Access Control
// ================================================

=== audit_question_2 ===
~ audit_questions_asked += 1

Player: Second question—I've been reviewing the access logs. What concerns you most about the patterns?

+ [Everything looks normal. Standard office hours access mostly]
    ~ audit_wrong_answers += 1
    Kevin: But... what about those 2 AM logins to the server room?
    Kevin: Maybe I'm reading too much into it.
    -> audit_question_3
+ [Derek's credentials being used for server room access at 2 AM is a red flag]
    ~ audit_correct_answers += 1
    ~ influence += 1
    Kevin: Thank you! I knew I wasn't crazy!
    Kevin: Management keeps telling me he's just "dedicated" and "works odd hours."
    Kevin: But we don't have anything in that server room that marketing should be accessing at all.
    -> audit_question_3
+ [The access logs seem fine, but you should implement better monitoring]
    ~ audit_wrong_answers += 1
    Kevin: I thought the current logs were already showing problems...
    Kevin: But yeah, better monitoring couldn't hurt.
    -> audit_question_3

// ================================================
// AUDIT QUESTION 3: Password Security
// ================================================

=== audit_question_3 ===
~ audit_questions_asked += 1

Player: Third—password security. What's your assessment of the biggest vulnerability?

+ [Your password complexity requirements are sufficient]
    ~ audit_wrong_answers += 1
    Kevin: I guess the requirements are technically there...
    Kevin: I just worry people are finding predictable ways around them.
    -> audit_question_4
+ [Staff are using predictable patterns—birthdays, company name plus numbers]
    ~ audit_correct_answers += 1
    ~ influence += 1
    Kevin: Exactly! I see it all the time in password reset requests.
    Kevin: "Viral2023" "Viral2024" - I've warned people but they keep doing it.
    Kevin: And Derek... well, you've probably figured out his pattern by now.
    -> audit_question_4
+ [Passwords aren't the real issue—focus on multi-factor authentication instead]
    ~ audit_wrong_answers += 1
    Kevin: We don't have MFA yet—budget constraints.
    Kevin: So I'm stuck with just passwords for now. Wish we could implement MFA.
    -> audit_question_4

// ================================================
// AUDIT QUESTION 4: Personnel Security
// ================================================

=== audit_question_4 ===
~ audit_questions_asked += 1

Player: Fourth—personnel security. What's the biggest red flag you see?

+ [The staff seem trustworthy. No major concerns]
    ~ audit_wrong_answers += 1
    Kevin: I want to believe that, I really do.
    Kevin: But Patricia's firing still bothers me.
    -> audit_question_5
+ [A manager investigating security concerns was suddenly fired—that's suspicious]
    ~ audit_correct_answers += 1
    ~ influence += 2
    Kevin: Right?! That's what worries me most!
    Kevin: Patricia was asking the right questions. Then she was gone.
    Kevin: And nobody will tell me why. Just "performance issues."
    Kevin: It sends a message: don't ask questions about Derek.
    -> audit_question_5
+ [You need better background checks and security clearances]
    ~ audit_wrong_answers += 1
    Kevin: I mean, we do background checks for sensitive positions...
    Kevin: But yeah, we could probably do better.
    -> audit_question_5

// ================================================
// AUDIT QUESTION 5: Data Protection
// ================================================

=== audit_question_5 ===
~ audit_questions_asked += 1

Player: Finally—data protection practices. What concerns you about how sensitive data is handled here?

+ [Standard security practices seem to be followed adequately]
    ~ audit_wrong_answers += 1
    Kevin: I suppose most people follow the basics...
    Kevin: Though Derek's setup still seems excessive to me.
    -> audit_complete
+ [Derek's encrypted comms and separate network segments lack business justification]
    ~ audit_correct_answers += 1
    ~ influence += 2
    Kevin: Yes! That's exactly it!
    Kevin: Marketing doesn't need that level of segmentation. We're not handling credit cards or medical records.
    Kevin: He claims it's for "client confidentiality" but I've never seen documentation justifying the architecture.
    Kevin: It looks less like security and more like... hiding something.
    -> audit_complete
+ [You need better encryption across the board]
    ~ audit_wrong_answers += 1
    Kevin: We have encryption where we need it...
    Kevin: Though I guess more couldn't hurt?
    -> audit_complete

// ================================================
// AUDIT COMPLETE - Kevin's Response
// ================================================

=== audit_complete ===

Kevin: Thank you. Seriously, thank you for taking the time to go through this with me.

{audit_correct_answers >= 4:
    Kevin: You really understand what's happening here. Everything you've flagged matches my concerns exactly.
    Kevin: It's such a relief to have a professional validate what I've been seeing.
    Kevin: I've felt like I'm going crazy, or being paranoid. But you see it too.
    ~ influence += 3
}
{audit_correct_answers == 3:
    Kevin: You've identified some key issues. A few things we see differently, but overall you're confirming my main worries.
    Kevin: At least I know I'm not completely off base with my concerns.
    ~ influence += 2
}
{audit_correct_answers <= 2:
    Kevin: I appreciate the feedback, even if we see some things differently.
    Kevin: Maybe I am being too paranoid about some of this stuff.
    Kevin: But... I still can't shake the feeling something's wrong here.
    ~ influence += 1
}

Kevin: I'm going to document your findings in my incident log.

Kevin: If management won't listen to me, maybe they'll listen to the security auditor.

Kevin: Keep investigating. And please—if you find anything concrete, tell me immediately.

-> hub
