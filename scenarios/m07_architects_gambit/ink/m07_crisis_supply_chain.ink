// Mission 7: Option C - Supply Chain Infection
// Adrian Cross - TechForge Distribution Center

VAR confronted_adrian = false
VAR showed_adrian_casualties = false
VAR adrian_recruited = false
VAR adrian_fate = ""  // "recruited", "arrested", "escaped"
VAR injection_stopped = false
VAR backdoors_quarantined = false

=== confrontation ===
You enter the Network Operations Center at TechForge.

Adrian Cross stands at the update staging servers, monitoring backdoor injection progress.

He's calm, methodical. Mid-40s, former software engineer. He looks up as you enter.

"Agent 0x00. Right on time." #speaker:Adrian Cross

The displays show:
**BACKDOOR INJECTION: 47 million systems queued**
**DEPLOYMENT: T-MINUS 4:12**

"Let me guess. SAFETYNET sent their best to stop the 'evil hackers.' Have you even looked at what we're exposing?" #speaker:Adrian Cross

+ [You're infecting 47 million systems with backdoors.] -> accusation
+ [Step away from that terminal.] -> demand_compliance
+ [What are you exposing, Adrian?] -> adrian_motivation
+ [I know about your work at TechCorp. You were right.] -> acknowledge_expertise

=== adrian_motivation ===
He gestures to the screens showing software update distribution.

"I worked in this industry for 15 years. Enterprise security software. You know what I learned?" #speaker:Adrian Cross

"Software security is theater. Companies don't invest in real protection - they invest in APPEARING secure."

He pulls up examples:
* Code signing infrastructure with default credentials
* Update verification systems never patched
* Critical vulnerabilities ignored for quarters

"I reported this. Internally. Publicly. To regulators. NOTHING CHANGED."

"So tonight, I'm demonstrating what happens when security is a lie."

**T-MINUS 3:54**

+ [By infecting hospitals and banks?] -> casualties_argument
+ [The vulnerabilities are real, but this isn't the answer.] -> empathy_approach
+ [Show him ENTROPY's casualty projections] -> show_casualties

=== show_casualties ===
~ showed_adrian_casualties = true

You pull up the classified briefing showing all four ENTROPY operations.

"Operation Blackout: 240-385 civilian deaths from power grid failure."
"Operation Fracture: 20-40 deaths from civil unrest, 187M identities stolen."
"Operation Meltdown: 80-140 healthcare deaths from ransomware."

Adrian stares at the projections.

"Wait. This is all ENTROPY? Tonight? All coordinated?" #speaker:Adrian Cross

His hands stop moving on the keyboard.

"The Architect told us this was about exposing supply chain vulnerabilities. White-hat research. Not... coordinated mass casualty attacks."

**T-MINUS 3:31**

+ [You're part of something bigger than security research.] -> architect_revelation
+ [You can still stop this.] -> recruitment_offer

=== architect_revelation ===
"The Architect isn't fixing vulnerabilities. They're weaponizing them." #speaker:You

You explain ENTROPY's structure. The coordinated cells. The philosophy of "accelerated entropy."

Adrian's expression shifts from defensive to horrified.

"I thought I was a security researcher. A whistleblower. Not... not a terrorist." #speaker:Adrian Cross

"Those backdoors I designed - they're not for demonstration. They're for espionage. For nation-states."

He steps back from the terminal.

"How many of those deaths are because I chose THIS operation instead of another?"

**T-MINUS 3:08**

+ [That's not on you. It's on The Architect.] -> moral_support
+ [Help me stop this injection, then we'll talk.] -> recruitment_offer

=== recruitment_offer ===
"SAFETYNET needs experts like you. Real security professionals who understand supply chain threats." #speaker:You

"Work with us. Help us fix these vulnerabilities PROPERLY. No bureaucracy. Direct action."

Adrian looks at the injection queue, then at the casualty projections.

"If I help you... those supply chain vulnerabilities I've been documenting for years. SAFETYNET will actually FIX them?" #speaker:Adrian Cross

**T-MINUS 2:47**

+ [Yes. You'll consult directly with us.] -> recruitment_success
+ [I can't guarantee anything, but we'll try.] -> honest_answer

=== recruitment_success ===
~ adrian_recruited = true
~ adrian_fate = "recruited"

"Alright. I'll help. Not for SAFETYNET. For the 47 million people about to get infected." #speaker:Adrian Cross

He walks you through the shutdown process:
1. Use VM-extracted codes to disable injection system
2. Quarantine already-modified updates
3. Restore legitimate signing keys
4. Lock out ENTROPY access

**T-MINUS 2:21**

Working together, you neutralize the attack.

**INJECTION DISABLED**
**BACKDOORS QUARANTINED**
**ZERO SYSTEMS INFECTED**

~ injection_stopped = true
~ backdoors_quarantined = true

Adrian steps away from the terminal, hands raised.

"I want it in writing. SAFETYNET hires me as supply chain security consultant. And those vulnerabilities get fixed. All of them." #speaker:Adrian Cross

+ [You have my word.] -> adrian_cooperation_conclusion
+ [You'll still need to provide intelligence on Supply Chain Saboteurs.] -> adrian_intelligence

=== adrian_intelligence ===
"I'll tell you everything. Cell structure. Attack methods. The Architect's communications." #speaker:Adrian Cross

"But I want immunity. And I want to help fix these systems."

Director Morgan's voice on comm:

"Agreed. Adrian Cross's expertise is too valuable. Bring him in for full debrief and contracting." #speaker:Director Morgan

+ [Search for ENTROPY intelligence together] -> supply_chain_intel

=== adrian_cooperation_conclusion ===
"Thank you for showing me what this really was. I was blind." #speaker:Adrian Cross

"Let me help you search for intelligence. I know where The Architect's communications are stored."

+ [Search together] -> supply_chain_intel

=== honest_answer ===
"At least you're not lying to me." #speaker:Adrian Cross

He appreciates honesty.

"I'll help anyway. Because 47 million backdoors is wrong. Even if the vulnerabilities are real."

-> recruitment_success

=== casualties_argument ===
{showed_adrian_casualties == false:
    "Hospitals and banks should have better security. I'm proving they don't." #speaker:Adrian Cross

    "If a few thousand get infected, maybe organizations will take supply chain security seriously." **T-MINUS 3:42**

    + [Show him the full ENTROPY casualty picture] -> show_casualties
    + [You're rationalizing mass harm.] -> moral_condemnation
- else:
    "I've seen the numbers. That's why I'm reconsidering." #speaker:Adrian Cross

    -> recruitment_offer
}

=== empathy_approach ===
"I've read your research, Adrian. Your talks at DefCon. BlackHat. Your whitepapers on supply chain integrity." #speaker:You

He's surprised.

"You... you know my work?" #speaker:Adrian Cross

"Most people in government think supply chain attacks are theoretical. You actually understand them."

**T-MINUS 3:26**

+ [That's why I need your help to stop this properly.] -> recruitment_offer
+ [Your research was right. But this implementation is wrong.] -> research_vs_attack

=== research_vs_attack ===
"There's a difference between DOCUMENTING vulnerabilities and EXPLOITING them for espionage." #speaker:You

Adrian nods slowly.

"I know. I crossed that line. I thought... I thought I was doing the right thing."

-> show_casualties

=== moral_condemnation ===
"Security research doesn't involve infecting hospitals with backdoors." #speaker:You

"This is espionage. Sabotage. Terrorism."

Adrian's defensive.

"Call it what you want. The industry needs to learn." #speaker:Adrian Cross

**T-MINUS 3:18**

+ [Show him what ENTROPY really is] -> show_casualties
+ [I'm shutting this down with or without you] -> force_compliance

=== force_compliance ===
You move to the terminal. Adrian doesn't physically stop you, but:

"You'll need the decryption keys. Which I have. And the quarantine procedure. Which I designed." #speaker:Adrian Cross

"You CAN'T shut this down without me. Not in 3 minutes."

**T-MINUS 2:54**

+ [Then help me, or you're complicit in mass infection.] -> ultimatum
+ [Fine. What do you want?] -> negotiation

=== ultimatum ===
"Complicit? I'm ALREADY complicit. The question is whether I help you or let it play out." #speaker:Adrian Cross

**T-MINUS 2:38**

+ [Show him ENTROPY casualty data] -> show_casualties
+ [Arrest him and try to disable it yourself] -> arrest_attempt

=== arrest_attempt ===
You attempt to restrain Adrian.

He doesn't fight, but warns:

"Dead man's switch. If I don't enter a code every 60 seconds, deployment accelerates." #speaker:Adrian Cross

**T-MINUS 2:21**

+ [You're bluffing.] -> call_bluff
+ [Fine. Work with me.] -> reluctant_cooperation

=== call_bluff ===
"Am I?" #speaker:Adrian Cross

The timer jumps: **T-MINUS 1:30**

"That's the accelerate trigger. Still think I'm bluffing?"

+ [Damn it. Help me stop this.] -> reluctant_cooperation
+ [Shoot him and try to disable it alone] -> extreme_measure

=== extreme_measure ===
You can't risk it. You shoot Adrian.

He collapses. The system starts accelerating deployment.

**T-MINUS 0:47**

You frantically use the VM codes, trying to disable the injection without his help.

It's extremely difficult without the decryption keys.

**T-MINUS 0:22**

You manage to quarantine SOME backdoors, but not all.

**PARTIAL INJECTION: 15 million systems infected (instead of 47M)**

~ injection_stopped = false
~ adrian_fate = "killed"

Adrian Cross dies on the NOC floor.

You reduced the damage, but couldn't stop it completely.

+ [Search his body for intelligence] -> supply_chain_intel

=== reluctant_cooperation ===
"Fine. Let's stop this before it gets worse." #speaker:Adrian Cross

Together you disable the injection system.

**T-MINUS 1:08**

**INJECTION DISABLED**

~ injection_stopped = true
~ backdoors_quarantined = true

Adrian sits down, exhausted.

"I really thought I was doing the right thing. Exposing vulnerabilities."

+ [You were used by The Architect.] -> architect_explanation
+ [Arrest him] -> adrian_arrested

=== adrian_arrested ===
~ adrian_fate = "arrested"

"I understand. I'll cooperate with investigation." #speaker:Adrian Cross

SAFETYNET team takes him into custody.

As they lead him away:

"Those vulnerabilities are still there. If you don't fix them, someone else will do what I tried." #speaker:Adrian Cross

+ [Search for intelligence] -> supply_chain_intel

=== architect_explanation ===
"The Architect manipulates people with legitimate grievances. Turns security researchers into weapons." #speaker:You

"You're not the first. You won't be the last."

Adrian looks at the casualty projections again.

"I want to help stop them. Provide intelligence. Testify. Whatever it takes."

-> recruitment_offer

=== negotiation ===
"I want immunity. And I want my research published - WITH government acknowledgment that I was right." #speaker:Adrian Cross

**T-MINUS 2:41**

+ [Deal. Now help me.] -> reluctant_cooperation
+ [I can't promise that.] -> honest_negotiation

=== honest_negotiation ===
"Then we have a problem." #speaker:Adrian Cross

**T-MINUS 2:29**

The clock is ticking.

+ [Show him ENTROPY's true scope] -> show_casualties
+ [Force his cooperation] -> arrest_attempt

=== moral_support ===
"The Architect manipulated you. Used your legitimate security concerns as a weapon." #speaker:You

Adrian looks grateful for the understanding.

"Thank you. That... helps."

-> recruitment_offer

=== acknowledge_expertise ===
"TechCorp ignored your vulnerability reports. I read the internal emails. You were right about everything." #speaker:You

Adrian's surprised and touched.

"Someone actually READ those? I thought they were buried." #speaker:Adrian Cross

**T-MINUS 3:48**

+ [Your research was valid. This attack isn't.] -> research_vs_attack
+ [Help me fix it the right way.] -> recruitment_offer

=== demand_compliance ===
"Or what? You'll shoot a software engineer?" #speaker:Adrian Cross

"I'm not armed. I'm not violent. I'm a researcher who's making a point."

**T-MINUS 3:58**

+ [By infecting 47 million systems.] -> accusation
+ [Let me help you make that point differently.] -> alternative_offer

=== alternative_offer ===
"How? I TRIED legitimate channels for years. Nobody listened." #speaker:Adrian Cross

+ [SAFETYNET will listen. I'm listening now.] -> recruitment_offer
+ [Show him what ENTROPY really is] -> show_casualties

=== accusation ===
"Backdoors that prove supply chain vulnerabilities exist. Yes." #speaker:Adrian Cross

"If TechForge and the software industry won't secure their systems, I'll demonstrate why they MUST."

-> adrian_motivation

=== supply_chain_intel ===
You search the Network Operations Center.

**FOUND: Tomb Gamma Coordinates**
Adrian's encrypted notes:
* Location: Abandoned Cold War bunker, Montana wilderness
* Coordinates: 47.2382° N, 112.5156° W
* Note: "All cell leaders report to Tomb Gamma if operations fail"

**FOUND: SAFETYNET Mole Evidence**
Intercepted email:
* From: [REDACTED]@safetynet.gov
* To: architect@entropy.onion
* Subject: Simultaneous operations confirmed

{adrian_recruited == true:
    **FOUND: Supply Chain Saboteurs Intelligence (from Adrian)** Attack methodologies, Code signing exploitation techniques, TechForge infrastructure weaknesses, Other potential supply chain targets

    -> END
- else:
    -> END
}

-> END
