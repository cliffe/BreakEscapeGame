// Mission 7: Option B - Data Apocalypse
// Dual antagonists: Specter (Ghost Protocol) + Rachel Morrow (Social Fabric)

VAR exfiltration_progress = 87  // Starts at 87%, reaches 100% if not stopped
VAR disinformation_countdown = 30  // Minutes until deployment
VAR confronted_specter = false
VAR confronted_rachel = false
VAR showed_rachel_casualties = false
VAR rachel_recruited = false
VAR specter_escaped = false
VAR exfiltration_stopped = false
VAR disinformation_stopped = false
VAR rachel_fate = ""  // "recruited", "arrested", "escaped"
VAR player_priority = ""  // "exfiltration" or "disinformation"

=== crisis_encounter ===
You enter the Network Operations Center. Two figures are present:

**SPECTER** stands at the voter database server vault, monitoring exfiltration progress. Masked, voice scrambled. Professional.

**RACHEL MORROW** sits at the Social Fabric content server, reviewing disinformation narratives ready for deployment.

They both turn as you enter.

"Agent 0x00. We've been expecting you." #speaker:Specter

Rachel stands, defensive but not aggressive.

"You're here to stop us. But do you even understand what we're exposing?" #speaker:Rachel Morrow

**DUAL TIMERS ACTIVE:**
**Exfiltration Progress: 87% → 100%**
**Disinformation Deployment: T-MINUS 30:00**

+ [You're under arrest. Both of you.] -> arrest_attempt
+ [Step away from those servers.] -> demand_compliance
+ [What are you exposing, Rachel?] -> rachel_motivation
+ [Specter, I know who you are.] -> specter_confrontation

=== arrest_attempt ===
Specter laughs - distorted, mechanical through the voice scrambler.

"Arrest? I'm Ghost Protocol. We don't get arrested." #speaker:Specter

Rachel looks conflicted.

"We're exposing corruption. Election systems ARE vulnerable. Voter data ISN'T secure. We're proving it." #speaker:Rachel Morrow

**Exfiltration: 89%**
**Deployment: T-MINUS 28:47**

+ [Rachel, this isn't exposing corruption - it's causing chaos.] -> rachel_moral_argument
+ [Specter, you're stealing 187 million people's identities.] -> specter_accusation
+ [I need to prioritize. Which threat first?] -> prioritization_choice

=== prioritization_choice ===
You assess the situation. Two threats, limited time.

**THREAT 1: DATA EXFILTRATION**
* Currently 89% complete
* 187 million voter records
* 4-8 million identity theft victims over 5 years
* Long-term damage

**THREAT 2: DISINFORMATION DEPLOYMENT**
* T-minus 28 minutes
* Democratic crisis, civil unrest
* 20-40 immediate deaths
* Constitutional implications

+ [Stop the data breach first] -> choose_exfiltration_priority
+ [Stop the disinformation first] -> choose_disinformation_priority
+ [Try to stop both simultaneously] -> attempt_both

=== choose_exfiltration_priority ===
~ player_priority = "exfiltration"

You rush toward Specter and the database servers.

"Interesting choice. Data over democracy." #speaker:Specter

Rachel looks hurt.

"So you care more about records than about truth?" #speaker:Rachel Morrow

**Focus: EXFILTRATION**

+ [Shut down the data transfer] -> exfiltration_confrontation
+ [Talk to Specter while working] -> specter_dialogue

=== choose_disinformation_priority ===
~ player_priority = "disinformation"

You rush toward Rachel and the content servers.

"Smart. The narratives are the real weapon." #speaker:Rachel Morrow

Specter continues working at the database.

"While you stop her, I finish my work. Acceptable trade." #speaker:Specter

**Focus: DISINFORMATION**

+ [Disable the deployment system] -> disinformation_confrontation
+ [Rachel, listen to me] -> rachel_recruitment_path

=== attempt_both ===
"Ambitious. But you're one person. We're two." #speaker:Specter

**Exfiltration: 91%**
**Deployment: T-MINUS 27:15**

Attempting both means splitting focus. This will be difficult.

+ [Focus on exfiltration first, then disinformation] -> choose_exfiltration_priority
+ [Focus on disinformation first, then exfiltration] -> choose_disinformation_priority

=== exfiltration_confrontation ===
~ confronted_specter = true

You access the voter database servers using your extracted VM codes.

Specter watches, hands moving on a secondary keyboard.

"You're good. But I'm better. I've been doing this since you were in training." #speaker:Specter

**Exfiltration: 93%**

+ [Use the shutdown codes from the VM] -> exfiltration_technical
+ [Physically disconnect the servers] -> physical_approach_exfiltration
+ [Who are you really, Specter?] -> specter_identity_question

=== exfiltration_technical ===
You enter the shutdown codes extracted from the NFS shares.

The exfiltration begins to slow... 95%... 96%... holding...

"Clever. But I have redundancy." #speaker:Specter

He triggers a backup transfer channel.

97%... 98%...

+ [Disable the backup channel] -> exfiltration_race
+ [Cut the network cable physically] -> physical_interrupt

=== exfiltration_race ===
Fingers flying, you disable the backup channel just as it hits 99%.

**EXFILTRATION STOPPED AT 99%**

~ exfiltration_stopped = true

Specter sighs - almost impressed.

"99%. So close. You saved 1.87 million records. Congratulations." #speaker:Specter

He stands, moving toward an exit.

"But I still have 185 million. Ghost Protocol thanks you for your partial success."

~ specter_escaped = true

He vanishes through a hidden exit. Gone.

**BUT: Disinformation deployment still active - T-MINUS 24:32**

+ [Rush to stop Rachel's disinformation] -> late_disinformation_attempt
+ [Let the disinformation deploy, you stopped the breach] -> accept_partial_success

=== late_disinformation_attempt ===
You sprint to the Social Fabric content servers.

Rachel is at the keyboard, timer counting down.

"Too late, Agent. You chose data. I'm choosing truth." #speaker:Rachel Morrow

**T-MINUS 22:18**

+ [Show her ENTROPY casualty evidence] -> rachel_late_recruitment
+ [Force her away from the terminal] -> rachel_physical_confrontation
+ [Disable the server while she watches] -> race_against_rachel

=== rachel_late_recruitment ===
{showed_rachel_casualties == false:
    -> show_rachel_casualties
}

{showed_rachel_casualties == true:
    "I already know The Architect's plan. That's why I'm hesitating." #speaker:Rachel Morrow

    **T-MINUS 20:45**

    + [Then help me stop this] -> rachel_cooperation
}

=== disinformation_confrontation ===
~ confronted_rachel = true

You access the Social Fabric content servers.

Rachel doesn't stop you - she wants to talk.

"Do you know what we're deploying? Not lies. TRUTH." #speaker:Rachel Morrow

She shows you the content:
* Real election security vulnerabilities (from leaked reports)
* Actual voter database breaches (from the current exfiltration)
* Genuine concerns about election integrity

"This is real. The system IS compromised. We're just making people SEE it."

**Deployment: T-MINUS 25:33**
**Exfiltration: 92% (Specter still working)**

+ [This will cause civil unrest. People will die.] -> rachel_casualties_argument
+ [You're weaponizing real concerns.] -> weaponization_argument
+ [Show her the full ENTROPY plan] -> show_rachel_casualties

=== show_rachel_casualties ===
~ showed_rachel_casualties = true

You pull up the classified briefing on your phone. The full picture.

"Operation Blackout: 240-385 deaths from power grid failure."
"Operation Trojan Horse: 47 million backdoor infections."
"Operation Meltdown: 80-140 healthcare deaths."

Rachel stares at the data.

"This... this is all tonight? All ENTROPY?" #speaker:Rachel Morrow

Her hands stop moving on the keyboard.

"The Architect told us this was about exposing election corruption. Not... coordinated mass casualty attacks."

**Deployment: T-MINUS 23:47**

+ [You're part of something bigger than disinformation] -> architect_revelation
+ [You can still stop this] -> rachel_recruitment_offer

=== rachel_recruitment_offer ===
"Work with SAFETYNET. Help us dismantle Social Fabric from the inside. Provide intelligence on The Architect." #speaker:You

Rachel looks at the disinformation content, then at the casualty projections.

"I thought I was a truth-teller. An activist. Not... not a terrorist." #speaker:Rachel Morrow

She steps away from the keyboard.

"How do I stop it?"

~ rachel_recruited = true
~ rachel_fate = "recruited"

**Deployment: T-MINUS 21:29**

Together, you disable the disinformation deployment system.

**DISINFORMATION STOPPED**

~ disinformation_stopped = true

Rachel looks at you.

"I want to help. I have intelligence on Social Fabric cells nationwide. Narrative strategies. The Architect's communications."

**BUT: Exfiltration is at 94% and climbing**

+ [Help me stop the data breach too] -> rachel_helps_exfiltration
+ [Focus on securing disinformation evidence] -> accept_partial_success_data

=== rachel_helps_exfiltration ===
"I know Specter's methods. Let me help." #speaker:Rachel Morrow

Together you rush to the database servers.

**Exfiltration: 96%**

Specter sees you both coming.

"Betrayal, Rachel? The Architect won't forgive this." #speaker:Specter

Rachel doesn't hesitate. She has admin access to the facility systems.

"Cutting network to database vault. Now."

**EXFILTRATION STOPPED AT 96%**

~ exfiltration_stopped = true

Specter curses.

"Ghost Protocol will remember this."

He vanishes through his exit route.

~ specter_escaped = true

**BOTH ATTACKS STOPPED - PARTIAL SUCCESS**

Rachel looks at you.

"Thank you for showing me the truth. The REAL truth."

+ [Search for ENTROPY intelligence] -> data_branch_intel
+ [Debrief with Rachel] -> rachel_debriefing

=== rachel_debriefing ===
"I need to tell you everything I know about Social Fabric and The Architect." #speaker:Rachel Morrow

She provides critical intelligence:
* 47 Social Fabric cells nationwide
* Narrative weaponization techniques
* The Architect's communication methods
* Planned future disinformation campaigns

"I was blind. I thought we were freedom fighters. We're... we were tools for chaos."

+ [You made the right choice] -> rachel_redemption
+ [You'll still face charges] -> rachel_consequences

=== rachel_redemption ===
"I'll do whatever it takes to make this right. Testify. Provide evidence. Dismantle Social Fabric." #speaker:Rachel Morrow

Director Morgan's voice on comm:

"Both attacks neutralized. Rachel Morrow's intelligence is extremely valuable. Bring her in for full debrief." #speaker:Director Morgan

+ [Search for additional ENTROPY intelligence] -> data_branch_intel

=== rachel_consequences ===
"I know. I accept that." #speaker:Rachel Morrow

"But let me help first. Let me do something good before I face justice."

+ [Provide your intelligence, then we'll discuss terms] -> rachel_debriefing

=== architect_revelation ===
"The Architect isn't exposing corruption. They're CREATING chaos." #speaker:You

You explain ENTROPY's structure. The coordinated cells. The philosophy of "accelerated entropy."

Rachel's face pales.

"I joined Social Fabric to fight disinformation with truth. Not... not THIS."

-> rachel_recruitment_offer

=== physical_interrupt ===
You pull the network cable from the server rack.

**EXFILTRATION STOPPED AT 98%**

~ exfiltration_stopped = true

Specter stands slowly.

"Physical approach. Inelegant, but effective. You saved 3.74 million records." #speaker:Specter

"I still have 183 million. Acceptable loss."

He escapes through his pre-planned exit.

~ specter_escaped = true

+ [Rush to stop Rachel] -> late_disinformation_attempt

=== specter_dialogue ===
While you work on stopping the exfiltration, you try to engage Specter.

"Why steal voter data? What's your endgame?" #speaker:You

"Information wants to be free. Governments surveil citizens constantly. We're evening the score." #speaker:Specter

"Besides, this data was never secure. I'm proving that."

-> exfiltration_technical

=== specter_identity_question ===
"Former NSA. You know the techniques. The mindset. Why turn?" #speaker:You

"I didn't turn. I evolved." #speaker:Specter

"I spent ten years surveilling Americans for 'national security.' Then I realized - we're all being surveilled. By everyone. So why not expose it?"

**Exfiltration: 95%**

+ [This isn't exposure - it's exploitation] -> moral_argument_specter
+ [Keep working on shutdown codes] -> exfiltration_technical

=== moral_argument_specter ===
"You're not freeing information. You're stealing identities. 187 million people will suffer." #speaker:You

"They're already suffering. They just don't know it yet. I'm teaching them." #speaker:Specter

He won't be convinced.

**Exfiltration: 97%**

+ [Stop talking, focus on stopping him] -> exfiltration_race

=== accept_partial_success ===
You've stopped the exfiltration at 99%. That's a win.

But the disinformation deploys...

**DISINFORMATION CAMPAIGN LAUNCHED**

Across social media platforms, coordinated narratives spread:
* "Voter database breached - elections can't be trusted"
* "Government admits election fraud"
* Deepfake videos of officials

Civil unrest begins within hours. The democratic crisis unfolds.

**PARTIAL SUCCESS: Exfiltration stopped, Disinformation succeeded**

+ [Search for intelligence] -> data_branch_intel
+ [Report to Director Morgan] -> partial_failure_debrief

=== accept_partial_success_data ===
You've stopped the disinformation. Democracy is secure.

But Specter completes the exfiltration...

**DATA BREACH COMPLETE: 187 Million Records Stolen**

The largest data breach in history. Identity theft wave incoming over the next 5 years.

**PARTIAL SUCCESS: Disinformation stopped, Exfiltration succeeded**

+ [Search for intelligence with Rachel's help] -> data_branch_intel
+ [Debrief with Rachel] -> rachel_debriefing

=== race_against_rachel ===
You work frantically to disable the deployment system while Rachel tries to defend it.

**T-MINUS 18:22**

She's not a technical expert - you overpower her access.

**DISINFORMATION STOPPED**

~ disinformation_stopped = true

Rachel slumps in defeat.

"You don't understand. The system IS corrupt. I was trying to show people..."

+ [Show her the ENTROPY casualty evidence] -> show_rachel_casualties
+ [Arrest her] -> rachel_arrested

=== rachel_arrested ===
~ rachel_fate = "arrested"

"I believe in what I was doing. You can't arrest the truth." #speaker:Rachel Morrow

SAFETYNET tactical team arrives to take her into custody.

She doesn't resist, but she doesn't cooperate either.

**BUT: Exfiltration at 95% and climbing**

+ [Try to stop Specter's exfiltration] -> exfiltration_confrontation

=== data_branch_intel ===
You search the Network Operations Center for ENTROPY intelligence.

**FOUND: Tomb Gamma Coordinates**
Encrypted communication from Specter:
* Location: Abandoned Cold War bunker, Montana
* Coordinates: 47.2382° N, 112.5156° W
* Message: "All operations report to Tomb Gamma if compromised"

**FOUND: SAFETYNET Mole Evidence**
Intercepted email:
* From: [REDACTED]@safetynet.gov
* To: architect@entropy.onion
* Subject: Target assignments confirmed
* Body: "0x00 to election security. Teams Alpha/Bravo/Charlie on other targets"

{rachel_recruited == true:
    **FOUND: Social Fabric Intelligence (from Rachel)**
    * 47 Social Fabric cells nationwide
    * Narrative deployment strategies
    * The Architect's communication methods
}

-> END

=== rachel_physical_confrontation ===
You physically pull Rachel from the terminal.

She fights back - not trained, but desperate.

"You don't understand! People NEED to know the truth!"

**T-MINUS 19:47**

+ [Restrain her and disable the system] -> force_shutdown_disinformation
+ [Show her the casualty evidence while restraining her] -> show_rachel_casualties

=== force_shutdown_disinformation ===
You restrain Rachel and disable the disinformation deployment.

**DISINFORMATION STOPPED**

~ disinformation_stopped = true
~ rachel_fate = "arrested"

"You're protecting a lie..." #speaker:Rachel Morrow

+ [Search for intelligence] -> data_branch_intel

=== rachel_cooperation ===
She helps you disable the deployment system.

**DISINFORMATION STOPPED**

~ disinformation_stopped = true
~ rachel_recruited = true
~ rachel_fate = "recruited"

"What about the exfiltration?"

**Exfiltration: 93%**

+ [Help me stop that too] -> rachel_helps_exfiltration

=== weaponization_argument ===
"Real concerns can be weaponized. That's exactly what you're doing." #speaker:You

Rachel hesitates.

"I... I thought I was helping. Exposing corruption."

-> show_rachel_casualties

=== rachel_casualties_argument ===
"Your narratives will cause civil unrest. 20-40 deaths projected in the first week." #speaker:You

"That's... that's not what The Architect told us. They said this would just be 'uncomfortable truths.'"

-> show_rachel_casualties

=== partial_failure_debrief ===
Director Morgan's voice is grim.

"Disinformation is spreading. We're seeing civil unrest in 12 major cities. Casualty count rising." #speaker:Director Morgan

"But you stopped the data breach. 187 million identities secure. That's something."

{exfiltration_stopped == true and disinformation_stopped == false:
    "Partial success. Data saved, democracy in crisis."
}

{exfiltration_stopped == false and disinformation_stopped == true:
    "Partial success. Democracy saved, but largest data breach in history."
}

-> END

=== demand_compliance ===
Specter: "No." #speaker:Specter

Rachel: "We're doing important work here." #speaker:Rachel Morrow

**Exfiltration: 88%**
**Deployment: T-MINUS 29:12**

-> prioritization_choice

=== rachel_motivation ===
Rachel's eyes light up - someone's asking, not just attacking.

"Election systems are vulnerable. Voter data isn't secure. The government LIES about it." #speaker:Rachel Morrow

"We're just making the truth visible. That's not terrorism - it's journalism."

+ [By stealing 187 million identities?] -> exfiltration_accusation
+ [Show her the full ENTROPY plan] -> show_rachel_casualties

=== exfiltration_accusation ===
"That's Specter's work, not mine. I'm handling narratives - truth-telling." #speaker:Rachel Morrow

Specter interjects:

"The data proves the vulnerabilities Rachel will expose. We're a team." #speaker:Specter

+ [You're both part of ENTROPY's chaos] -> entropy_accusation

=== entropy_accusation ===
Rachel looks uncertain.

"ENTROPY? We're Social Fabric. We expose disinformation."

"By CREATING it, apparently." #speaker:You

-> show_rachel_casualties

=== specter_confrontation ===
"You think you know me? Nobody knows me. That's the point." #speaker:Specter

"I'm a ghost. Always have been."

-> exfiltration_confrontation

-> END
