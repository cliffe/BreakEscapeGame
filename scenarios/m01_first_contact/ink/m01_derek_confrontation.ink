// ================================================
// Mission 1: First Contact - Derek Confrontation
// Act 3: Major Moral Choice
// UPDATED: Evil monologue, clear villain, no sympathy
// Player confronts Derek with Operation Shatter evidence
// ================================================

VAR confrontation_approach = ""    // diplomatic, aggressive, evidence_based
VAR derek_knows_safetynet = false
VAR derek_showed_remorse = false   // Spoiler: he won't
VAR final_choice = ""              // arrest, recruit, expose
VAR derek_confronted = false       // Set to true when confrontation ends

// External variables
VAR player_name = "Agent 0x00"
VAR evidence_collected = false
VAR found_casualty_projections = false

// VM flag requirements - player must complete technical investigation
VAR ssh_flag_submitted = false
VAR linux_flag_submitted = false
VAR sudo_flag_submitted = false

// ================================================
// START: DEREK APPEARS
// ================================================

=== start ===
// Check if player has sufficient evidence from VM challenges
{not ssh_flag_submitted or not linux_flag_submitted or not sudo_flag_submitted:
    -> insufficient_evidence
}
// Player has all VM flags - proceed with confrontation
#complete_task:confront_derek

Derek: Working late on the security audit?

Derek: I've been watching you, you know. The lockpicking. The server access. The files you've been copying.

Derek: You're not an IT contractor. And you've found Operation Shatter.

+ [I know what you're planning, Derek.]
    ~ confrontation_approach = "aggressive"
    ~ derek_knows_safetynet = true
    -> derek_response_direct
+ [I've seen the casualty projections.]
    ~ confrontation_approach = "evidence_based"
    ~ derek_knows_safetynet = true
    -> derek_response_evidence
+ [SAFETYNET knows everything.]
    ~ confrontation_approach = "aggressive"
    ~ derek_knows_safetynet = true
    -> derek_response_safetynet

// ================================================
// INSUFFICIENT EVIDENCE - PLAYER NEEDS VM FLAGS
// ================================================

=== insufficient_evidence ===
Derek: Oh, you must be the IT contractor. Security audit, right?

Derek: I'm kind of busy. Maybe check back later?

+ [I need to look at your systems]
    Derek: Feel free to look around the office. But I don't have time for an interview right now.
    Derek: Maybe after you've actually found something worth discussing.
    #exit_conversation
    -> END
+ [We should talk about some irregularities I've found]
    Derek: Irregularities? Like what exactly?
    Derek: If you don't have specifics, I've got work to do. Come back when you have evidence.
    #exit_conversation
    -> END
+ [I'll come back later]
    Derek: Good idea. I'm sure the server room has plenty to keep you busy.
    #exit_conversation
    -> END

// ================================================
// DEREK RESPONDS - DIRECT APPROACH
// ================================================

=== derek_response_direct ===
Derek: "Planning." Such a neutral word for what we're doing.

Derek: We're not planning an attack. We're planning an education.

+ [You're planning to kill people.]
    -> derek_admits_casualties
+ [You're insane.]
    -> derek_calm_response

=== derek_calm_response ===
Derek: Insane? I'm the sanest person in this building.

Derek: Everyone else pretends the systems work. Pretends their data is secure. Pretends that trust is deserved.

Derek: I know the truth. And after Sunday, so will everyone else.

-> derek_admits_casualties

// ================================================
// DEREK RESPONDS - EVIDENCE APPROACH
// ================================================

=== derek_response_evidence ===
Derek: Ah. The casualty projections.

Derek: I was wondering if you'd find those. They're the most honest part of the whole operation.

+ [You calculated how many people would die.]
    -> derek_admits_casualties
+ [42 to 85 people. Those are your numbers.]
    -> derek_admits_casualties

// ================================================
// DEREK RESPONDS - SAFETYNET
// ================================================

=== derek_response_safetynet ===
Derek: SAFETYNET. The organization that thinks surveillance protects people.

Derek: You found the files. The targeting lists. The message templates.

Derek: Good. Then you understand what's coming.

-> derek_admits_casualties

// ================================================
// DEREK ADMITS TO CASUALTIES - THE EVIL MONOLOGUE
// ================================================

=== derek_admits_casualties ===
Derek: Yes. Between 42 and 85 people will die in the first 24 hours.

Derek: Diabetics who panic about hospital closures. Elderly who can't handle the stress of fake bank failures. Heart attacks. Traffic accidents. A few suicides, probably.

Derek: I calculated every one of them.

+ [How can you be so calm about murdering people?]
    -> evil_monologue_part1
+ [You're a monster.]
    -> evil_monologue_part1
+ [Why?]
    -> evil_monologue_part1

// ================================================
// EVIL MONOLOGUE - PART 1
// ================================================

=== evil_monologue_part1 ===
Derek: Murder? No. Think of it as... forced education.

Derek: Every security professional in the world says "humans are the weakest link." They write papers about it. Give talks at conferences. Collect consulting fees.

Derek: But no one actually DEMONSTRATES it. No one shows what happens when you target human psychology at scale.

Derek: We're going to prove—conclusively, undeniably—that digital trust is a lie. That every message you receive could be fake. That nothing is secure.

+ [By killing innocent people.]
    -> evil_monologue_part2
+ [You're just terrorists with a philosophy degree.]
    -> evil_monologue_part2

=== evil_monologue_part2 ===
Derek: "Innocent." That's an interesting word.

Derek: The diabetics we're targeting? They trust hospital notifications without verification. The elderly? They believe bank messages because they look official.

Derek: They're not innocent. They're negligent. They've outsourced their critical thinking to systems that can be manipulated.

Derek: We're teaching them—all of them—that trust is dangerous. Verify everything. Question everything. Or die.

+ [Some of them WILL die. That's murder.]
    -> evil_monologue_part3
+ [You're rationalizing mass murder.]
    -> evil_monologue_part3

// ================================================
// EVIL MONOLOGUE - PART 3 (The Coldest Part)
// ================================================

=== evil_monologue_part3 ===
Derek: Forty-two to eighty-five deaths. Let's call it sixty.

Derek: Do you know how many people die every year because they trusted the wrong email? Clicked the wrong link? Gave credentials to the wrong person?

Derek: Thousands. Tens of thousands. Suicides after financial fraud. Medical errors from compromised records. Violence incited by disinformation.

Derek: We're going to end that. One bad weekend. Sixty deaths. And then NO ONE will ever trust a digital message again without verification.

Derek: Sixty deaths to save tens of thousands per year. That's not murder. That's optimization.

+ [You're calculating human lives like statistics.]
    -> derek_final_philosophy
+ [The Architect taught you this, didn't they?]
    -> architect_reference
+ [This ends now.]
    -> confrontation_choice

=== architect_reference ===
Derek: The Architect opened my eyes. But I chose this path myself.

Derek: Entropy is inevitable. Trust is a lie. Security through obscurity fails.

Derek: We just accelerate the lesson. Make it unavoidable. Make it hurt enough that people remember.

-> derek_final_philosophy

// ================================================
// DEREK'S FINAL PHILOSOPHY
// ================================================

=== derek_final_philosophy ===
Derek: You look at me like I'm a monster.

Derek: But I'm the only honest person in this industry. Every security researcher KNOWS trust is broken. They just profit from pretending it can be fixed.

Derek: I'm the one willing to actually fix it. To burn the comfortable lies so something real can grow from the ashes.

Derek: Those sixty people? Their deaths will save millions.

Derek: And in ten years, when no one falls for phishing because Operation Shatter taught them to verify everything, you'll understand.

Derek: I'm not a villain. I'm a prophet.

+ [You're delusional.]
    -> confrontation_choice
+ [You're going to prison for the rest of your life.]
    -> confrontation_choice
+ [I almost feel sorry for you. Almost.]
    -> confrontation_choice

// ================================================
// CONFRONTATION CHOICE (Major Decision)
// ================================================

=== confrontation_choice ===
Derek: So. Here we are. You've heard my reasoning. You've seen the evidence.

Derek: What happens now is up to you.

Derek: But know this—even if you stop Operation Shatter here, the idea doesn't die. There are other cells. Other believers. Other architects of the inevitable.

+ [I'm taking you down. Now.] #color:red
    ~ final_choice = "fight"
    -> choice_fight
+ [I'm calling in SAFETYNET. You're under arrest.]
    ~ final_choice = "arrest"
    -> choice_arrest
+ [Work with us. Help us stop the other cells.]
    ~ final_choice = "recruit"
    -> choice_recruit
+ [I'm exposing everything publicly. Let the world see what you are.]
    ~ final_choice = "expose"
    -> choice_expose

// ================================================
// CHOICE: FIGHT (Hostile Engagement)
// ================================================

=== choice_fight ===
You: No lawyers. No trials. No platform for your twisted philosophy.

Derek: *steps back* You're making a mistake.

You: The only mistake was thinking you'd get to walk out of here.

Derek: Violence? How disappointing. I expected better from SAFETYNET.

You: You calculated deaths like statistics. You don't get to lecture me about violence.

Derek becomes hostile, reaching for something in his desk.

#hostile
#speaker:derek
#influence:-100

Derek: If you want a fight, {player_name}, you'll get one. But you won't stop ENTROPY. You'll just prove we're right about the system.

Derek: Come on then!

-> fight_outcome

=== fight_outcome ===
The confrontation escalates. Derek fights desperately, but you're trained for this.

After a brief struggle, you subdue him. He's breathing hard, defiant even in defeat.

#speaker:derek
Derek: *coughs* You think... you think this changes anything?

Derek: I'm a martyr now. ENTROPY will remember this. The Architect will remember.

Derek: You didn't arrest me. You attacked me. How noble.

You call in SAFETYNET backup while keeping Derek restrained.

#speaker:agent_0x99

Agent 0x99: Backup team on site. Derek Lawson subdued and in custody.

Agent 0x99: {player_name}... that was aggressive. But he's down. Operation Shatter is over.

Agent 0x99: We'll discuss the methods in debrief.

~ derek_confronted = true
#exit_conversation

-> END

// ================================================
// CHOICE: ARREST (Surgical Strike)
// ================================================

=== choice_arrest ===
You: You're done, Derek. Operation Shatter dies today. And you're going to spend the rest of your life in prison.

Derek: Prison. How quaint.

Derek: You think concrete walls stop ideas? I'll become a martyr. People will study my philosophy. Question why I was silenced.

You: You'll be a case study in how not to become a terrorist.

Derek: Terrorist. That's what they call educators who make people uncomfortable.

You call in SAFETYNET backup. Derek doesn't resist—he's too confident that he's already won something.

-> arrest_outcome

=== arrest_outcome ===
#speaker:agent_0x99

Agent 0x99: Backup team is on site. Derek Lawson in custody.

Agent 0x99: {player_name}... I heard everything. The way he talked about those deaths. Like they were just... numbers.

Agent 0x99: We got him. Operation Shatter is over. You saved those people.

~ derek_confronted = true
#exit_conversation

-> END

// ================================================
// CHOICE: RECRUIT (Double Agent)
// ================================================

=== choice_recruit ===
You: You said there are other cells. Other architects of chaos.

You: Help us stop them. Turn informant. Give us ENTROPY from the inside.

Derek: Become a double agent? Betray The Architect?

Derek: *laughs*

Derek: You think I'd sell out the only people who understand the truth? For what—reduced sentence?

Derek: No. I'm not like you, willing to compromise principles for convenience.

Derek: Arrest me. Expose me. I don't care. But I will never betray ENTROPY.

You: Then you leave me no choice.

You call in SAFETYNET backup. Derek was never going to cooperate—his belief is absolute.

-> recruit_outcome

=== recruit_outcome ===
#speaker:agent_0x99

Agent 0x99: I heard his refusal. Not surprised—true believers don't turn.

Agent 0x99: But you tried. That matters. Sometimes there's no way to reach someone.

Agent 0x99: Derek Lawson is in custody. Operation Shatter is stopped. That's what counts.

~ derek_confronted = true
#exit_conversation

-> END

// ================================================
// CHOICE: EXPOSE (Public Disclosure)
// ================================================

=== choice_expose ===
You: I'm taking everything. The casualty projections. The targeting lists. The messages you wrote for elderly diabetics.

You: I'm giving it all to the press. Let the world see what ENTROPY really is.

Derek: *smiles*

Derek: You think that hurts me? I WANT people to see this.

Derek: Public disclosure means the philosophy spreads. People will read those casualty projections and think—what if it happened? What if next time we're not stopped?

Derek: Fear is the first step to wisdom. You're doing my work for me.

+ [Then the world will also see you in handcuffs.]
    -> expose_execute
+ [At least they'll know to watch for people like you.]
    -> expose_execute

=== expose_execute ===
You: Maybe. But they'll also see that SAFETYNET stopped you. That we found you before you killed anyone.

You: And every time someone reads about Operation Shatter, they'll remember that we caught you. That your "inevitable entropy" wasn't so inevitable after all.

Derek: A temporary setback. Entropy always wins eventually.

You: Not today.

You begin compiling the evidence for public release while calling in backup.

-> expose_outcome

=== expose_outcome ===
#speaker:agent_0x99

Agent 0x99: {player_name}, public disclosure is... complicated. Director Netherton is going to have opinions.

Agent 0x99: But I understand why you did it. People should know what ENTROPY is capable of. What they were willing to do.

Agent 0x99: Derek's in custody. The targeting lists are secured. And those 85 people who were going to die on Sunday? They're going to live.

Agent 0x99: That's what matters.

~ derek_confronted = true
#exit_conversation

-> END
