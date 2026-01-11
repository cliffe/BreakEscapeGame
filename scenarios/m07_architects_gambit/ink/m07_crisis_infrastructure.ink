// Mission 7: Option A - Infrastructure Collapse
// Marcus "Blackout" Chen - SCADA Control Room Confrontation

VAR confronted_chen = false
VAR chen_threatened_timer = false
VAR showed_casualty_evidence = false
VAR chen_hesitating = false
VAR chen_fate = ""  // "arrested", "killed", "recruited", "escaped"
VAR crisis_neutralized = false

=== confrontation ===
You burst into the SCADA control room.

Marcus "Blackout" Chen stands at the master control terminal, fingers flying across the keyboard. The countdown timer on the wall reads: **T-MINUS 3:47**

He doesn't turn around immediately.

"Agent 0x00. Right on schedule." #speaker:Marcus Chen

He finally turns to face you. Mid-thirties, engineer's demeanor, calm despite your entry. A pistol rests on the terminal beside him - within reach, but he doesn't move for it.

"I calculated you'd arrive between 3 and 4 minutes remaining. SAFETYNET training is predictable."

He gestures to the terminal.

"Look at this system. 147 substations. 8.4 million people. All controlled by software last updated in 2011. Security patches from 2018. This infrastructure is a disaster waiting to happen."

+ [Hands up, Chen. You're under arrest.] -> attempt_arrest
+ [Step away from the terminal.] -> demand_compliance
+ [Why are you doing this?] -> chen_motivation
+ [Your attack will kill hundreds of people.] -> casualties_argument

=== attempt_arrest ===
~ confronted_chen = true

"Under arrest? For what? Exposing the truth?" #speaker:Marcus Chen

He doesn't move toward the gun, but he doesn't raise his hands either.

"I worked for the Department of Energy for six years. I WROTE security reports about these exact vulnerabilities. I BEGGED them to upgrade these systems."

His voice is cold, controlled.

"They ignored me. Budget constraints, they said. Not a priority. Well, tonight it's a priority."

The timer ticks down: **T-MINUS 3:21**

+ [People will die if you don't stop this.] -> casualties_argument
+ [Your methods are terrorism.] -> terrorism_accusation
+ [Let me help you do this the right way.] -> alternative_approach

=== demand_compliance ===
He laughs - bitter, not amused.

"Or what? You'll shoot me? Then the timer keeps running and you have no way to stop it." #speaker:Marcus Chen

He's right. You need him alive to get the shutdown codes.

"Besides, I'm not your enemy. The system is. I'm just the teacher delivering an expensive lesson."

**T-MINUS 3:14**

+ [What do you want?] -> chen_demands
+ [Why target civilians?] -> civilians_question
+ [I read your DoE reports. You were right.] -> acknowledge_validity

=== chen_motivation ===
His expression shifts - this is the question he's been waiting for.

"Eight years ago, I discovered critical vulnerabilities in the Pacific Northwest power grid control systems. SCADA networks with default passwords. Unencrypted command channels. No intrusion detection." #speaker:Marcus Chen

"I reported it through proper channels. DoE. FERC. DHS. I documented everything. Provided recommendations. Budgets. Implementation timelines."

He gestures at the screens showing the power grid.

"Know what happened? Nothing. ABSOLUTELY NOTHING. Budget reallocated to 'higher priorities.' My security clearance was revoked for 'making alarmist claims.'"

His voice hardens.

"If they won't fix vulnerabilities when I ASK nicely, maybe they'll fix them when I DEMONSTRATE catastrophically."

**T-MINUS 2:58**

+ [So you're killing people to prove a point?] -> casualties_argument
+ [The system failed you. I get it.] -> empathy_approach
+ [There are other ways to expose this.] -> alternative_approach

=== casualties_argument ===
{showed_casualty_evidence == false:
    He pulls up projections on a secondary screen. "240 to 385 deaths over 72 hours. I know the numbers, Agent. I calculated them myself. 120 to 180 hospital deaths from generator failures. 40 to 65 traffic fatalities. 80 to 140 exposure deaths from hypothermia." #speaker:Marcus Chen

    He meets your eyes.

    "Every single one of those deaths is the government's fault. They had EIGHT YEARS to fix this. The blood is on THEIR hands, not mine." **T-MINUS 2:39**

    * [Show him evidence of other ENTROPY casualties] -> show_casualties
    * [That's rationalizing murder] -> moral_revelation
    * [You're right about the vulnerabilities] -> acknowledge_validity
- else:
    He's staring at the casualty projections you showed him from the other operations.

    His hands have stopped moving on the keyboard.

    "This... this is all ENTROPY? Tonight?" #speaker:Marcus Chen **T-MINUS 2:12**

    ~ chen_hesitating = true

    * [You're part of something bigger than infrastructure] -> reveal_architect
    * [You can still stop this] -> recruitment_attempt
}

=== show_casualties ===
~ showed_casualty_evidence = true

You pull up the classified briefing on your phone. The full picture of tonight's coordinated attacks.

"Operation Fracture: 187 million voter records stolen, 20-40 deaths from civil unrest."

"Operation Trojan Horse: 47 million systems infected with backdoors."

"Operation Meltdown: 80-140 healthcare deaths from ransomware, $4.2 trillion economic damage."

You show him the screen.

"Your attack is ONE of FOUR happening RIGHT NOW. All coordinated by The Architect. You're not a teacher, Marcus. You're a weapon."

He stares at the data. For the first time, uncertainty crosses his face.

"I... The Architect said this was about infrastructure security. Exposing critical vulnerabilities. Not..." #speaker:Marcus Chen

He trails off, looking at the casualty numbers.

**T-MINUS 2:24**

+ [You were used. Help me stop this.] -> recruitment_attempt
+ [Does this change anything?] -> moral_revelation

=== terrorism_accusation ===
"Terrorism? I prefer 'forceful penetration testing.'" #speaker:Marcus Chen

He's not joking.

"The government calls whistle-blowers terrorists. Calls security researchers hackers. Labels anyone who exposes their incompetence as criminals."

"I'm not a terrorist. I'm a teacher. And tuition is expensive."

**T-MINUS 2:45**

+ [This isn't teaching. It's murder.] -> moral_revelation
+ [I understand your frustration] -> empathy_approach

=== alternative_approach ===
"Other ways? I TRIED other ways!" #speaker:Marcus Chen

His calm cracks for the first time. Anger bleeding through.

"Congressional testimony. Media interviews. Academic publications. FREEDOM OF INFORMATION ACT REQUESTS."

"Know what happened? Nothing. News cycle moved on. Politicians ignored it. Infrastructure kept decaying."

He gestures at the terminal.

"This? This they can't ignore. Tomorrow morning, every news channel will cover grid vulnerabilities. Congress will hold hearings. Budgets will be allocated."

"If 240 people have to die to save millions from future attacks, that's a trade I'm willing to make."

**T-MINUS 2:18**

+ [That's not your choice to make] -> moral_revelation
+ [Show him the broader ENTROPY plan] -> show_casualties

=== empathy_approach ===
You lower your weapon slightly.

"I read your reports, Marcus. You were right. The vulnerabilities are real. The government DID fail to act."

His expression shifts - surprise.

"You... you read my work?" #speaker:Marcus Chen

"Not many people did. Most said I was being alarmist. Paranoid. That I didn't understand budget realities."

**T-MINUS 2:31**

+ [But this isn't the answer] -> offer_alternative
+ [Help me understand your plan] -> technical_discussion

=== offer_alternative ===
"What alternative? I tried EVERYTHING." #speaker:Marcus Chen

"The system doesn't change through proper channels. It only changes through crisis."

**T-MINUS 2:08**

+ [Work with SAFETYNET. We can expose this properly.] -> recruitment_attempt
+ [The crisis is happening. People are listening now.] -> crisis_argument

=== crisis_argument ===
"You're right. They're listening NOW. Because there's a timer." #speaker:Marcus Chen

He looks at you seriously.

"If I stop this, they forget. Budget meeting next month, someone says 'Well, we didn't have a blackout, so maybe it's not urgent.'"

"The only way change happens is through consequence."

**T-MINUS 1:52**

+ {showed_casualty_evidence == true} [You're causing consequences across multiple targets] -> reveal_architect
+ [Let me help you find another way] -> final_recruitment_attempt
+ [Time's up, Chen. Shutdown codes. Now.] -> force_compliance

=== reveal_architect ===
"The Architect isn't exposing vulnerabilities. They're weaponizing them." #speaker:Marcus Chen

You explain ENTROPY's true structure. The coordinated cells. The philosophy of "accelerated entropy."

Marcus stares at the SCADA terminal, then at the casualty projections.

"I thought... I thought this was about security research. Forcing the government to take infrastructure seriously." #speaker:Marcus Chen

"But four simultaneous attacks? That's not research. That's..."

He trails off.

**T-MINUS 1:41**

+ [It's warfare. And you're part of it.] -> moral_revelation
+ [Help me stop this. You can still make this right.] -> final_recruitment_attempt

=== moral_revelation ===
~ chen_hesitating = true

He pulls his hands away from the keyboard.

"I wanted to teach lessons. Not... not start a war." #speaker:Marcus Chen

For the first time, he looks uncertain.

"But if I stop this now, does it matter? The vulnerabilities still exist. Nothing changes."

**T-MINUS 1:29**

+ [Work with SAFETYNET. We'll make it public.] -> final_recruitment_attempt
+ [It matters to the 240 people who won't die.] -> moral_imperative
+ [Give me the shutdown codes or I take them by force] -> threat_escalation

=== recruitment_attempt ===
{showed_casualty_evidence == true and chen_hesitating == true:
    -> final_recruitment_attempt
}

{showed_casualty_evidence == false:
    "Recruitment? You think I'd work for the same government that ignored my warnings?" #speaker:Marcus Chen

    "Not interested." **T-MINUS 2:06**

    * [Show him the full ENTROPY casualty picture] -> show_casualties
    * [This is your last chance] -> threat_escalation
}

=== final_recruitment_attempt ===
"SAFETYNET isn't DoE or FERC. We act on real threats." #speaker:You

"You have expertise we need. Help us secure critical infrastructure PROPERLY. No bureaucracy. No budget committees. Direct action."

Marcus looks at the timer. Looks at the casualty projections. Looks at you.

"If I help you... those vulnerabilities I documented. SAFETYNET will fix them? Actually fix them?" #speaker:Marcus Chen

**T-MINUS 1:17**

+ [Yes. I guarantee it.] -> recruitment_success
+ [I can't guarantee anything, but we'll try] -> honest_answer

=== recruitment_success ===
He takes a long breath. Then his hands move to the keyboard.

"Shutdown sequence requires three steps. Watch carefully - if I screw this up, the timer accelerates." #speaker:Marcus Chen

He walks you through the process:
1. Deactivation codes from the NFS shares you extracted
2. Master override password (which he provides)
3. Physical kill switch behind the panel

**T-MINUS 0:54**

"There. Cascade failure sequence disabled. Grid is secure."

The timer stops. The red warning lights go dark.

Marcus steps away from the terminal, hands raised.

"I want it in writing. SAFETYNET hires me as infrastructure security consultant. And those vulnerabilities get fixed. All of them." #speaker:Marcus Chen

~ crisis_neutralized = true
~ chen_fate = "recruited"

+ [You have my word] -> recruitment_conclusion
+ [You'll still face charges] -> recruitment_conclusion

=== honest_answer ===
"At least you're honest." #speaker:Marcus Chen

He appreciates that.

"Alright. I'll help. Not because I trust the government. Because I don't trust The Architect."

He provides the shutdown sequence, same as above.

**T-MINUS 0:49**

The attack is neutralized.

~ crisis_neutralized = true
~ chen_fate = "recruited"

"I'm still angry about the eight years of ignored warnings. But... maybe this is a better path than mass casualties."

-> recruitment_conclusion

=== recruitment_conclusion ===
Director Morgan's voice comes through your comm.

"Attack neutralized. Grid secure. Outstanding work, 0x00. Bring Chen in for debrief." #speaker:Director Morgan

Marcus looks at you.

"I'm trusting you on this. Don't make me regret it." #speaker:Marcus Chen

You escort him toward the exit. He stops at the door, looking back at the SCADA terminal.

"Eight years. That's how long it took for anyone to take this seriously."

"Let's make sure it doesn't take another crisis."

+ [Search for ENTROPY intelligence] -> post_mission_intel
+ [Proceed to extraction] -> END

=== moral_imperative ===
"240 people..." #speaker:Marcus Chen

He's wavering.

"You're right. I calculated the numbers, but I didn't... I didn't think about them as people. Just statistics. Necessary losses."

He looks at you.

"That's what The Architect does, isn't it? Makes you think in numbers instead of lives."

**T-MINUS 1:08**

+ [Help me stop this] -> compliance_granted
+ [Give me the codes. Now.] -> compliance_granted

=== compliance_granted ===
He nods slowly, hands moving to the keyboard.

"Three-step shutdown. I'll walk you through it." #speaker:Marcus Chen

He provides the deactivation sequence using your extracted intelligence plus his admin credentials.

**T-MINUS 0:44**

The attack is neutralized. Timer stops. Grid secure.

~ crisis_neutralized = true
~ chen_fate = "arrested"

"I'm done fighting. Take me in." #speaker:Marcus Chen

He places his hands behind his head. No resistance.

"For what it's worth... I really did think I was doing the right thing."

+ [You were used by The Architect] -> arrest_conclusion
+ [You're responsible for your choices] -> harsh_arrest

=== arrest_conclusion ===
"Yeah. I see that now." #speaker:Marcus Chen

SAFETYNET tactical team arrives to take him into custody.

As they lead him away, he looks back.

"Agent 0x00. Those vulnerabilities I documented - they're still there. If you don't fix them, someone else will do what I tried to do." #speaker:Marcus Chen

"And next time, maybe they won't hesitate."

+ [Search for ENTROPY intelligence] -> post_mission_intel
+ [Proceed to extraction] -> END

=== harsh_arrest ===
"I know." #speaker:Marcus Chen

He doesn't argue. SAFETYNET team takes him into custody without incident.

+ [Search for ENTROPY intelligence] -> post_mission_intel
+ [Proceed to extraction] -> END

=== threat_escalation ===
~ chen_threatened_timer = true

His hand moves toward the keyboard. Hovering over a key sequence.

"You want to threaten me? Fine. This is the master accelerate command. One keystroke, timer drops to 30 seconds. No way you disable it in time." #speaker:Marcus Chen

"So here's MY deal: Let me walk out of here, and I'll give you the shutdown codes. Or we both lose."

**T-MINUS 1:33**

+ [You're bluffing] -> call_bluff
+ [Fine. Give me the codes and go] -> let_him_escape
+ {showed_casualty_evidence == true} [You're not a mass murderer, Marcus] -> last_appeal
+ [Shoot him before he hits the key] -> shoot_chen

=== call_bluff ===
"Try me." #speaker:Marcus Chen

His finger is on the key. You can see in his eyes - he's NOT bluffing.

**T-MINUS 1:21**

+ [Wait! I'll let you go.] -> let_him_escape
+ [Shoot him] -> shoot_chen
+ {showed_casualty_evidence == true} [The Architect used you] -> last_appeal

=== let_him_escape ===
"Smart choice." #speaker:Marcus Chen

He steps back from the terminal, hands still visible.

"Shutdown sequence is three-part: Your NFS codes, plus master password 'GRID_COLLAPSE_2026', plus physical kill switch behind the left panel."

He walks toward the exit, giving you space to work.

**T-MINUS 1:09**

You execute the shutdown sequence. Timer stops. Grid secure.

~ crisis_neutralized = true
~ chen_fate = "escaped"

By the time you look up, Marcus is gone. Vanished into the facility.

Director Morgan's voice on comm:

"Attack neutralized, but Chen escaped. BOLO issued. We'll find him." #speaker:Director Morgan

You secured the grid. But Marcus "Blackout" Chen is still out there.

+ [Search for ENTROPY intelligence] -> post_mission_intel
+ [Proceed to extraction] -> END

=== shoot_chen ===
You don't hesitate. Single shot. Center mass.

Marcus collapses. His hand slaps the keyboard as he falls.

**TIMER ACCELERATES: T-MINUS 0:29**

"Dammit!" #speaker:You

You rush to the terminal. Chen is dying, but conscious.

"Shutdown... codes... on... my phone..." #speaker:Marcus Chen

He gasps out the password to his phone. You grab it, find the shutdown sequence, execute it frantically.

**T-MINUS 0:07**

Grid secure. Timer stops.

~ crisis_neutralized = true
~ chen_fate = "killed"

Marcus "Blackout" Chen dies on the SCADA control room floor.

His last words: "...eight years... they didn't listen..."

The grid is saved. But you had to kill him to do it.

+ [Search his body for intelligence] -> post_mission_intel
+ [Proceed to extraction] -> END

=== last_appeal ===
{showed_casualty_evidence == true:
    "The Architect made you think this was about security. It's not. It's about chaos." #speaker:You

    Marcus hesitates. His finger lifts slightly from the key.

    "I don't want to be a mass murderer. I wanted to FIX things..." #speaker:Marcus Chen **T-MINUS 1:04**

    * [Then help me fix this] -> final_recruitment_attempt
    * [Step away from the keyboard] -> compliance_granted
}

=== acknowledge_validity ===
"You read my reports?" #speaker:Marcus Chen

He's surprised. Genuinely.

"Then you know I'm RIGHT. These systems are catastrophically vulnerable. They SHOULD fail to prove the point."

**T-MINUS 2:28**

+ [But not like this. Not with casualties.] -> casualties_argument
+ [Work with me. We'll expose this properly.] -> recruitment_attempt

=== technical_discussion ===
He actually relaxes slightly - you're speaking his language.

"The cascade failure is elegant. Watch." #speaker:Marcus Chen

He brings up the attack visualization on screen.

"Stage 1: Seattle metro circuit breakers open. Instant blackout.
Stage 2: Excess load redirects to Portland substations. Transformers overload.
Stage 3: Safety shutdowns across Oregon. Blackout expands.
Stage 4: Northern California fails from imbalance. Total regional collapse."

"It's automated. Beautiful. Unstoppable once initiated."

**T-MINUS 1:58**

+ [Help me stop it] -> technical_cooperation
+ [Show him ENTROPY casualty data] -> show_casualties

=== technical_cooperation ===
"If I help you, what do I get?" #speaker:Marcus Chen

**T-MINUS 1:46**

+ [Your life. You avoid murder charges.] -> threat_based_cooperation
+ [A chance to fix this properly with SAFETYNET] -> recruitment_attempt
+ [Nothing. But people live.] -> moral_imperative

=== threat_based_cooperation ===
"Not good enough. I knew the risks when I started." #speaker:Marcus Chen

**T-MINUS 1:34**

+ [What DO you want?] -> chen_demands
+ [Time's running out, Marcus] -> force_compliance

=== chen_demands ===
"Public acknowledgment that I was right. Congressional testimony. And immunity." #speaker:Marcus Chen

**T-MINUS 1:22**

+ [I can't promise that] -> honest_answer
+ [Fine. Deal. Now help me.] -> false_promise

=== false_promise ===
He studies your face.

"You're lying. But I'll help anyway. Not because I trust you - because I'm starting to think I was used." #speaker:Marcus Chen

{showed_casualty_evidence == true:
    "Those casualty numbers from the other operations... that's not infrastructure security. That's warfare."
}

-> compliance_granted

=== force_compliance ===
"Make me." #speaker:Marcus Chen

-> threat_escalation

=== post_mission_intel ===
You search the SCADA control room for intelligence.

**FOUND: Tomb Gamma Coordinates**
Encrypted file on Marcus's terminal:
* Location: Abandoned Cold War bunker, Montana
* Coordinates: 47.2382° N, 112.5156° W
* Note: "Tomb Gamma - The Architect's workshop"

**FOUND: SAFETYNET Mole Evidence**
Email intercept on compromised server:
* From: [REDACTED]@safetynet.gov
* To: architect@entropy.onion
* Subject: Operation timing confirmed
* Body: "0x00 deployed to infrastructure. Teams Alpha/Bravo/Charlie on other targets. Window: 30 minutes."

**FOUND: The Architect Identity Clue**
Marcus's notes reference "The Professor" - someone with deep government knowledge.

You secure all intelligence for analysis.

-> END

=== civilians_question ===
"Civilians are already victims. Victims of government incompetence." #speaker:Marcus Chen

"I'm just making the incompetence visible."

-> casualties_argument

-> END
