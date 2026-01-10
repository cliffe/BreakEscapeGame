// Mission 7: Option D - Corporate Warfare
// Dual antagonists: Victoria "V1per" Zhang (Digital Vanguard) + Marcus "Shadow" Chen (Zero Day Syndicate)

VAR confronted_victoria = false
VAR confronted_marcus = false
VAR showed_victoria_casualties = false
VAR victoria_recruited = false
VAR marcus_escaped = false
VAR victoria_fate = ""  // "recruited", "arrested", "killed"
VAR exploits_deployed = false
VAR countermeasures_deployed = false

=== confrontation ===
You enter the TechCore Security Operations Center server room.

Two figures are present:

**VICTORIA "V1PER" ZHANG** stands at the defense automation terminal, armed and alert. Digital Vanguard operations coordinator. She sees you immediately.

**MARCUS "SHADOW" CHEN** works at a secondary terminal, monitoring zero-day exploit staging. Zero Day Syndicate broker. Non-violent, already looking for exits.

Victoria draws her weapon.

"Agent 0x00. TechCore security is compromised. You're too late." #speaker:Victoria Zhang

Marcus doesn't look up from his screen.

"Victoria, we discussed this. No unnecessary violence. Let me finish the deployment." #speaker:Marcus Chen

**EXPLOIT DEPLOYMENT: T-MINUS 3:54**
**TARGETS: 12 corporations, 47 zero-day vulnerabilities**

+ [Both of you are under arrest.] -> arrest_attempt
+ [Victoria, lower your weapon.] -> victoria_confrontation
+ [Marcus, step away from that terminal.] -> marcus_confrontation
+ [This attack will destroy the economy.] -> economic_argument

=== arrest_attempt ===
Victoria doesn't lower her weapon.

"We're not getting arrested. We're exposing corporate negligence." #speaker:Victoria Zhang

Marcus starts typing faster.

"Victoria handles security. I'm just finishing the technical work." #speaker:Marcus Chen

**T-MINUS 3:41**

+ [Victoria, you're Digital Vanguard. Anti-corporate ideology.] -> victoria_motivation
+ [Marcus, you're Zero Day Syndicate. You sell exploits.] -> marcus_motivation
+ [Show them ENTROPY's true scope] -> show_casualties

=== victoria_confrontation ===
"Lower my weapon so you can stop us? Not happening." #speaker:Victoria Zhang

"These corporations prioritize profits over security. People's data, people's privacy - they don't care. We're teaching them the cost."

**T-MINUS 3:32**

+ [By ransomwaring hospitals?] -> healthcare_argument
+ [Corporate security failures are real, but this isn't the answer.] -> empathy_approach
+ [You're not anti-corporate activists. You're ENTROPY weapons.] -> entropy_accusation

=== marcus_confrontation ===
Marcus finally looks up, calm.

"I'm a businessman, Agent. I find vulnerabilities. I sell them. Market dynamics." #speaker:Marcus Chen

"Except tonight, The Architect is paying VERY well for coordinated deployment. So here we are."

Victoria glares at him.

"It's not about money, Shadow. It's about accountability."

Marcus shrugs.

"You have your motivations. I have mine."

**T-MINUS 3:19**

+ [You're working together but want different things.] -> exploit_division
+ [Marcus, how much is The Architect paying you?] -> bribery_attempt

=== exploit_division ===
You recognize the crack in their alliance.

"Victoria, you're ideological. Marcus, you're mercenary. Why are you working together?"

Victoria: "Because we both benefit from exposing corporate failures." #speaker:Victoria Zhang

Marcus: "Because the pay is exceptional and our methods align. Temporarily." #speaker:Marcus Chen

**T-MINUS 3:04**

+ [Victoria, does Marcus care about your cause?] -> divide_victoria
+ [Marcus, what happens when Victoria realizes you're just profiting?] -> divide_marcus

=== divide_victoria ===
"Shadow, do you even BELIEVE in corporate accountability? Or are you just here for the money?" #speaker:Victoria Zhang

Marcus smiles slightly.

"I believe in supply and demand. I supply exploits. You demand corporate punishment. The Architect pays both of us. Efficient." #speaker:Marcus Chen

Victoria's expression hardens. She's realizing they're not ideological allies.

+ [Show Victoria ENTROPY's true casualty scope] -> show_casualties
+ [Exploit this division further] -> continue_division

=== show_casualties ===
~ showed_victoria_casualties = true

You pull up the classified briefing on your phone.

"Operation Blackout: 240-385 civilian deaths from power grid failure."
"Operation Fracture: 187M identities stolen, 20-40 deaths from civil unrest."
"Operation Trojan Horse: 47M backdoor infections."

Victoria stares at the projections.

"This is all ENTROPY? Tonight? All coordinated?" #speaker:Victoria Zhang

She looks at Marcus.

"You KNEW about this?"

Marcus remains calm.

"I knew The Architect coordinates multiple cells. It's good business."

Victoria's weapon wavers.

"I thought we were punishing negligent corporations. Not... not killing hundreds of people."

**T-MINUS 2:47**

+ [You're part of something bigger than corporate accountability.] -> architect_revelation
+ [You can still stop this, Victoria.] -> victoria_recruitment

=== architect_revelation ===
"The Architect isn't about reform. They're about chaos. 'Accelerated entropy.'" #speaker:You

You explain ENTROPY's structure. The coordinated cells. The philosophy.

Victoria lowers her weapon slightly.

"I joined Digital Vanguard to fight corporate corruption. To protect people from negligent companies. Not to... to be part of mass casualty terrorism." #speaker:Victoria Zhang

Marcus interjects:

"Motivations are irrelevant. The exploits are ready. Deployment proceeds." #speaker:Marcus Chen

**T-MINUS 2:29**

Victoria turns to Marcus, angry.

"Shadow, people are DYING at the other targets. Did you know?"

"I suspected. Didn't ask questions. Not my concern." #speaker:Marcus Chen

+ [Victoria, help me stop this.] -> victoria_recruitment
+ [Shoot Marcus before he deploys] -> shoot_marcus

=== victoria_recruitment ===
"SAFETYNET needs people like you. Real security professionals who understand corporate negligence." #speaker:You

"Help us expose these vulnerabilities PROPERLY. Regulation. Enforcement. Not terrorism."

Victoria looks at the casualty projections, then at Marcus working at the terminal.

"If I help you... those corporate security failures I've been documenting. SAFETYNET will force companies to fix them?" #speaker:Victoria Zhang

**T-MINUS 2:14**

+ [Yes. You'll work directly with regulatory enforcement.] -> recruitment_success
+ [I can't guarantee corporate compliance, but we'll try.] -> honest_answer

=== recruitment_success ===
~ victoria_recruited = true
~ victoria_fate = "recruited"

Victoria makes her decision. She turns her weapon toward Marcus.

"Shadow, stop the deployment. Now." #speaker:Victoria Zhang

Marcus sighs.

"I was wondering when you'd have a crisis of conscience. Fine." #speaker:Marcus Chen

He rapidly types something.

"Remote wipe initiated. Evidence deletion in progress. Goodbye, Victoria."

He triggers a smoke grenade and vanishes through a pre-planned exit.

~ marcus_escaped = true

Victoria curses.

"He's Ghost Protocol-trained. He's gone. But I can help you deploy countermeasures."

Together you work frantically:
1. Use VM-extracted codes
2. Deploy patches to all 12 corporations
3. Neutralize exploit staging systems

**T-MINUS 1:48**

**COUNTERMEASURES DEPLOYED**
**ALL 47 ZERO-DAYS NEUTRALIZED**

~ countermeasures_deployed = true

Victoria steps back, hands raised.

"I want immunity. And I want to help regulate corporate security for real."

+ [You have my word.] -> victoria_cooperation
+ [You'll provide intelligence on Digital Vanguard first.] -> victoria_intelligence

=== victoria_intelligence ===
"I'll tell you everything. Cell structure. Corporate targets. The Architect's communications." #speaker:Victoria Zhang

"But I want to help fix this system. That was always my goal."

Director Morgan's voice:

"Agreed. Victoria Zhang's intelligence is extremely valuable. Bring her in for debrief and contracting." #speaker:Director Morgan

+ [Search for ENTROPY intelligence together] -> corporate_intel

=== victoria_cooperation ===
"Thank you for showing me what this really was. The Architect used my anger at corporations as a weapon." #speaker:Victoria Zhang

"Let me help you search for intelligence. I know where The Architect's communications might be."

+ [Search together] -> corporate_intel

=== honest_answer ===
"At least you're honest about the limits." #speaker:Victoria Zhang

"I'll help anyway. Because 47 zero-days against hospitals is wrong. Even if corporations are negligent."

-> recruitment_success

=== shoot_marcus ===
You fire at Marcus. He's already moving - hits his shoulder, not fatal.

"Hostile! Accelerating deployment!" #speaker:Marcus Chen

He slaps a key sequence and vanishes through his exit.

**DEPLOYMENT ACCELERATED: T-MINUS 1:15**

~ marcus_escaped = true

Victoria is shocked by the violence.

"Was that necessary?!"

**T-MINUS 1:10**

+ [Help me deploy countermeasures, now!] -> emergency_deployment
+ [Show her the casualty evidence] -> show_casualties

=== emergency_deployment ===
Victoria helps despite her shock.

Together you frantically deploy countermeasures.

**T-MINUS 0:44**

You manage to neutralize MOST exploits, but not all.

**PARTIAL SUCCESS: 34 zero-days stopped, 13 deployed**

~ countermeasures_deployed = false

Some healthcare ransomware succeeds. Some banking attacks go through.

Limited damage instead of total economic collapse.

+ [Arrest Victoria] -> victoria_arrested
+ [Recruit Victoria after showing casualties] -> show_casualties

=== bribery_attempt ===
"How much is The Architect paying you? I can double it." #speaker:You

Marcus actually considers this.

"Interesting. But The Architect pays in anonymized cryptocurrency with guaranteed future contracts. Can SAFETYNET match that?" #speaker:Marcus Chen

**T-MINUS 2:52**

+ [SAFETYNET doesn't negotiate with criminals.] -> bribery_failure
+ [Name your price.] -> bribery_negotiation

=== bribery_negotiation ===
Marcus names an astronomical figure.

"Plus immunity for all past zero-day sales. And future consulting contracts."

Victoria interrupts:

"Shadow, you're seriously negotiating while people die?" #speaker:Victoria Zhang

This creates division between them.

+ [Exploit Victoria's disgust] -> divide_via_greed
+ [Accept Marcus's terms to buy time] -> false_deal

=== divide_via_greed ===
"Victoria, you see what he is? He doesn't care about corporate accountability. Just profit." #speaker:You

Victoria looks at Marcus with contempt.

"I knew you were mercenary, but THIS? While people die?"

Marcus shrugs.

"Business is business."

+ [Victoria, help me stop this.] -> victoria_recruitment

=== false_deal ===
"Fine. Deal. Halt the deployment." #speaker:You

Marcus grins.

"You're lying. But points for trying." #speaker:Marcus Chen

He continues working.

-> exploit_division

=== bribery_failure ===
"Expected. Then we proceed with deployment." #speaker:Marcus Chen

-> exploit_division

=== continue_division ===
"You're using each other. Victoria wants reform. Marcus wants money. Neither of you are achieving your real goals." #speaker:You

Victoria lowers her weapon further, thinking.

Marcus remains focused on the terminal.

**T-MINUS 2:38**

+ [Show Victoria the full casualty scope] -> show_casualties
+ [Appeal to Marcus's self-interest] -> marcus_self_interest

=== marcus_self_interest ===
"Marcus, when this goes sideways - and it will - The Architect disappears. Victoria gets caught or killed. And you? You're a wanted fugitive forever." #speaker:You

"Is the payout worth that?"

Marcus pauses for the first time.

"The Architect guarantees extraction to Tomb Gamma if operations fail."

"Do you TRUST that guarantee?" #speaker:You

**T-MINUS 2:21**

+ [Let me offer you a better deal.] -> bribery_negotiation
+ [Victoria, while he's thinking, make your choice.] -> victoria_decision_point

=== victoria_decision_point ===
Victoria looks at you, at Marcus, at the casualty projections.

"I need to see the full scope. What's really happening tonight."

+ [Show her ENTROPY's operations] -> show_casualties

=== economic_argument ===
"$4.2 trillion in market value destroyed. 140,000+ job losses. Healthcare ransomware killing patients." #speaker:You

Victoria: "Corporations should have invested in security. This is the consequence." #speaker:Victoria Zhang

Marcus: "Market volatility creates opportunity. I'm unconcerned." #speaker:Marcus Chen

**T-MINUS 3:27**

+ [Victoria, this isn't just punishing corporations - people lose jobs.] -> human_cost_argument
+ [Marcus, economic collapse affects you too.] -> marcus_economic_argument

=== human_cost_argument ===
"140,000 people losing their jobs. Families losing homes. Retirements wiped out. Those aren't corporations - those are people." #speaker:You

Victoria hesitates.

"I... I didn't think about layoffs. I thought this would just hurt shareholders."

+ [Show her the full casualty picture] -> show_casualties

=== healthcare_argument ===
"Healthcare ransomware. 80-140 deaths from delayed surgeries and care." #speaker:You

Victoria's face pales.

"Healthcare? We're attacking HOSPITALS?"

Marcus: "Collateral damage. Hospitals use exploitable software." #speaker:Marcus Chen

Victoria: "That's not... that's not what I signed up for."

+ [Show her what ENTROPY really is] -> show_casualties

=== empathy_approach ===
"I've read your research, Victoria. Your exposés on corporate data breaches. You were RIGHT about negligent security practices." #speaker:You

She's surprised.

"You read my work? Most government agents dismiss it as anti-corporate propaganda."

**T-MINUS 2:55**

+ [It wasn't propaganda. But this attack isn't the answer.] -> research_vs_attack
+ [Help me fix it the right way.] -> victoria_recruitment

=== research_vs_attack ===
"Exposing corporate negligence is legitimate. But killing people isn't." #speaker:You

Victoria looks uncertain.

"I thought... I thought this would just be financial damage. Punishing irresponsible companies."

+ [Show her the human cost] -> show_casualties

=== entropy_accusation ===
"Digital Vanguard is part of ENTROPY. The Architect coordinates you with Ghost Protocol, Critical Mass, Social Fabric, Supply Chain Saboteurs." #speaker:You

"This isn't activism. It's terrorism."

Victoria: "ENTROPY? We're DIGITAL VANGUARD. We're independent." #speaker:Victoria Zhang

Marcus: "Actually, The Architect coordinates all cells. I thought you knew." #speaker:Marcus Chen

Victoria glares at him.

"What?"

+ [Show her the full ENTROPY operational picture] -> show_casualties

=== divide_marcus ===
"Marcus will sell you out the second it's profitable. You know that, right?" #speaker:You

Marcus doesn't deny it.

"If Victoria gets caught, that's her problem. I have extraction protocols."

Victoria's trust in him cracks further.

+ [Victoria, he's using you.] -> victoria_recruitment

=== victoria_arrested ===
~ victoria_fate = "arrested"

"I understand. I made my choice." #speaker:Victoria Zhang

SAFETYNET team takes her into custody.

As they lead her away:

"Those corporate vulnerabilities are still there. If you don't regulate enforcement, someone else will do what I tried." #speaker:Victoria Zhang

+ [Search for intelligence] -> corporate_intel

=== marcus_motivation ===
"I'm a vulnerability researcher who realized selling is more profitable than reporting." #speaker:Marcus Chen

"The Architect pays extremely well for coordinated deployment. Business opportunity."

"I don't care about Victoria's ideology or The Architect's philosophy. I care about cryptocurrency transfers."

**T-MINUS 3:09**

+ [You're enabling terrorism for profit.] -> moral_accusation_marcus
+ [Offer him a deal] -> bribery_negotiation

=== moral_accusation_marcus ===
"I'm enabling market corrections. Corporations should pay for security failures." #speaker:Marcus Chen

He's completely amoral about it.

-> exploit_division

=== victoria_motivation ===
She's passionate about this.

"I worked in corporate security for eight years. I SAW the negligence. Board meetings where security budgets were cut for executive bonuses." #speaker:Victoria Zhang

"Data breaches that hurt customers, but companies paid small fines and moved on."

"Tonight, they learn. Real consequences."

**T-MINUS 3:24**

+ [By hurting innocent employees?] -> human_cost_argument
+ [Your anger is justified, but this method isn't.] -> empathy_approach

=== corporate_intel ===
You search the TechCore Security Operations Center.

**FOUND: Tomb Gamma Coordinates**
Victoria's encrypted communication:
* Location: Abandoned Cold War bunker, Montana wilderness
* Coordinates: 47.2382° N, 112.5156° W
* Message: "If operation fails, extract to Tomb Gamma"

**FOUND: SAFETYNET Mole Evidence**
Intercepted email:
* From: [REDACTED]@safetynet.gov
* To: architect@entropy.onion
* Subject: Target selection confirmed
* Body: "0x00 to corporate warfare. Teams handle infrastructure/data/supply chain"

{victoria_recruited == true:
    **FOUND: Digital Vanguard Intelligence (from Victoria)**
    * Cell structure and membership
    * Corporate target assessments
    * The Architect's coordination methods
    * Future attack plans
}

-> END

-> END
