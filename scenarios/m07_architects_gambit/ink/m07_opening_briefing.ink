// Mission 7: The Architect's Gambit - Opening Briefing
// This is the critical choice point where player selects which crisis to handle

VAR crisis_choice = ""
VAR crisis_choice_made = false

=== opening_briefing ===
The emergency operations center is in controlled chaos. Multiple screens flash red alerts. Director Morgan stands at the central terminal, face grim.

"Agent 0x00. Thank god you're here. We have a Category Five crisis." #speaker:Director Morgan

She brings up four simultaneous threat displays.

"ENTROPY has launched coordinated attacks on four critical targets. All happening RIGHT NOW. We have 30 minutes before catastrophic damage occurs at each location."

She takes a breath, her voice steady but urgent.

"We don't have enough assets to cover all four. You need to choose which operation to lead. The other three will be handled by SAFETYNET rapid response teams - but our models show... mixed outcomes."

She gestures to the displays.

"I need you to understand what you're choosing - and what you're accepting."

+ [View the four crisis scenarios] -> crisis_overview
+ [Ask about team capabilities] -> team_capabilities
+ [Ask about The Architect] -> architect_intel

=== crisis_overview ===
Director Morgan brings up detailed tactical displays for each crisis.

"Here's what we're facing:"

-> option_a_brief

=== option_a_brief ===
# OPTION A: INFRASTRUCTURE COLLAPSE
**Target:** Pacific Northwest Regional Power Grid Control Facility
**Threat Actor:** Critical Mass cell, led by Marcus "Blackout" Chen
**Attack:** SCADA system compromise, cascading grid failure

"Critical Mass has infiltrated the Pacific Northwest power grid control facility. In 30 minutes, they'll trigger cascading failures across 147 substations."

**IMMEDIATE CONSEQUENCES IF THEY SUCCEED:**
* 8.4 million people without power for 4-7 days
* 240-385 civilian deaths in first 72 hours
  - 120-180 hospital deaths (life support failures)
  - 40-65 traffic deaths (signal failures)
  - 80-140 exposure deaths (winter hypothermia)
* 23 major transformers destroyed
* $18 billion economic damage

**YOUR MISSION IF YOU CHOOSE THIS:**
* Breach the facility
* Complete VM exploitation to extract shutdown codes
* Reach SCADA control room before timer expires
* Confront Marcus Chen and disable the attack

+ [Continue to Option B] -> option_b_brief
+ [I'll take this mission] -> confirm_choice_a

=== option_b_brief ===
# OPTION B: DATA APOCALYPSE
**Target:** National Voter Registration Database & Election Systems
**Threat Actors:** Ghost Protocol (data breach) + Social Fabric (disinformation)
**Attack:** Dual-threat - massive data exfiltration + coordinated disinformation campaign

"Ghost Protocol is exfiltrating 187 million voter records while Social Fabric prepares to deploy disinformation narratives that exploit the breach."

**IMMEDIATE CONSEQUENCES IF THEY SUCCEED:**
* 187 million Americans' personal data exposed
* 4-8 million identity theft victims over 5 years
* 20-40 deaths from civil unrest in first week
* Democratic institutions permanently delegitimized
* Election integrity questioned indefinitely

**YOUR MISSION IF YOU CHOOSE THIS:**
* Breach the election security facility
* Complete VM exploitation to extract shutdown codes
* CRITICAL: Dual timers (exfiltration progress + disinformation deployment)
* Confront "Specter" and Rachel Morrow
* Attempt to stop BOTH attacks (extremely difficult)

+ [Continue to Option C] -> option_c_brief
+ [I'll take this mission] -> confirm_choice_b

=== option_c_brief ===
# OPTION C: SUPPLY CHAIN INFECTION
**Target:** TechForge Software Distribution Platform
**Threat Actor:** Supply Chain Saboteurs, led by Adrian Cross
**Attack:** Backdoor injection into software updates for 2,400+ vendors

"Supply Chain Saboteurs have compromised TechForge's code signing infrastructure. In 30 minutes, they'll inject backdoors into software updates for 47 million systems nationwide."

**LONG-TERM CONSEQUENCES IF THEY SUCCEED:**
* 47 million systems infected (hospitals, banks, government agencies)
* Backdoors remain dormant for 90 days (stealth)
* $240-420 billion economic damage over 10 years
* Foreign adversaries gain access to national infrastructure
* Software update trust permanently destroyed

**NOTE:** This option has NO immediate deaths. But choosing this accepts immediate casualties at other targets.

**YOUR MISSION IF YOU CHOOSE THIS:**
* Breach TechForge facility
* Complete VM exploitation to extract shutdown codes
* Disable backdoor injection before updates deploy
* Confront Adrian Cross (recruitable if shown casualty evidence)

+ [Continue to Option D] -> option_d_brief
+ [I'll take this mission] -> confirm_choice_c

=== option_d_brief ===
# OPTION D: CORPORATE WARFARE
**Target:** 12 Fortune 500 Corporations (via TechCore SOC)
**Threat Actors:** Digital Vanguard + Zero Day Syndicate
**Attack:** 47 zero-day exploits deployed simultaneously

"Digital Vanguard and Zero Day Syndicate are coordinating the largest corporate cyber attack in history. They'll deploy 47 zero-day exploits against 12 Fortune 500 companies simultaneously."

**IMMEDIATE CONSEQUENCES IF THEY SUCCEED:**
* Stock market crashes 12-18% ($4.2 trillion destroyed)
* 80-140 deaths from healthcare ransomware
* 140,000-220,000 immediate job losses
* $280-420 billion economic damage in first week
* Banking systems frozen nationwide

**MORAL COMPLEXITY:** You're protecting corporate wealth while civilians may die at other targets.

**YOUR MISSION IF YOU CHOOSE THIS:**
* Breach TechCore Security Operations Center
* Complete VM exploitation to extract countermeasure codes
* Deploy emergency patches to 12 corporations
* Confront Victoria Zhang and Marcus Chen
* Neutralize 47 zero-days before deployment

+ [View deterministic outcomes matrix] -> outcomes_matrix
+ [I'll take this mission] -> confirm_choice_d

=== team_capabilities ===
Director Morgan pulls up team status displays.

"We have three rapid response teams on standby:"

**TEAM ALPHA:** 6 operators, excellent track record, currently 40 minutes from nearest target
**TEAM BRAVO:** 4 operators, specialized in data security, 25 minutes from nearest target
**TEAM CHARLIE:** 5 operators, corporate security focus, 30 minutes from nearest target

"Based on distance, capabilities, and threat complexity, our predictive models show deterministic outcomes for operations you DON'T choose."

She looks at you seriously.

"The matrix isn't random. We know exactly what will happen based on your choice."

+ [View the deterministic outcomes matrix] -> outcomes_matrix
+ [Back to crisis overview] -> crisis_overview

=== architect_intel ===
Director Morgan's expression darkens.

"We believe all four attacks are coordinated by someone called 'The Architect.' ENTROPY's true leader."

"We don't know their identity. But their communication patterns suggest:
* Deep knowledge of SAFETYNET protocols
* Intelligence background (possibly former agency)
* Strategic thinking - these attacks are designed to force impossible choices
* Philosophy: Accelerating societal entropy through coordinated chaos"

"They've been taunting us. Sending messages. They WANT you to feel the weight of this choice."

She pauses.

"Don't let them get in your head. Choose based on your analysis, not their manipulation."

+ [View crisis scenarios] -> crisis_overview
+ [View outcomes matrix] -> outcomes_matrix

=== outcomes_matrix ===
Director Morgan brings up a large matrix display.

"Our predictive models show exactly what happens based on your choice. This isn't guesswork - it's deterministic based on team positioning, capabilities, and threat complexity."

# DETERMINISTIC OUTCOMES MATRIX

**IF YOU CHOOSE OPTION A (Infrastructure):**
* YOU: Handle infrastructure attack
* TEAM ALPHA: Supply Chain - FULL SUCCESS (prevented)
* TEAM BRAVO: Data Apocalypse - PARTIAL SUCCESS (breach mitigated, disinformation succeeds)
* TEAM CHARLIE: Corporate - FAILURE (zero-days deploy, economic damage)

**IF YOU CHOOSE OPTION B (Data Apocalypse):**
* YOU: Handle data/disinformation attack
* TEAM ALPHA: Infrastructure - FAILURE (240-385 deaths, blackout)
* TEAM BRAVO: Corporate - FULL SUCCESS (prevented)
* TEAM CHARLIE: Supply Chain - PARTIAL SUCCESS (some backdoors prevented)

**IF YOU CHOOSE OPTION C (Supply Chain):**
* YOU: Handle supply chain attack
* TEAM ALPHA: Data Apocalypse - FULL SUCCESS (both attacks prevented)
* TEAM BRAVO: Infrastructure - PARTIAL SUCCESS (some blackouts, reduced casualties)
* TEAM CHARLIE: Corporate - FAILURE (zero-days deploy, economic damage)

**IF YOU CHOOSE OPTION D (Corporate):**
* YOU: Handle corporate warfare
* TEAM ALPHA: Infrastructure - FULL SUCCESS (blackout prevented)
* TEAM BRAVO: Data Apocalypse - FAILURE (both attacks succeed, democracy crisis)
* TEAM CHARLIE: Supply Chain - PARTIAL SUCCESS (some backdoors prevented)

Director Morgan looks at you.

"There's no perfect choice. People will die or suffer regardless. Your job is to minimize total damage based on your assessment of priorities."

+ [Choose Option A - Infrastructure] -> confirm_choice_a
+ [Choose Option B - Data Apocalypse] -> confirm_choice_b
+ [Choose Option C - Supply Chain] -> confirm_choice_c
+ [Choose Option D - Corporate Warfare] -> confirm_choice_d

=== confirm_choice_a ===
"Infrastructure. You're prioritizing immediate civilian lives." #speaker:Director Morgan

She inputs your assignment.

"Team Alpha will handle supply chain. Team Bravo will attempt data/disinformation - expect partial success. Team Charlie will try corporate - they'll likely fail."

**ACCEPTED CONSEQUENCES:**
* Corporate zero-day attacks will likely succeed
* Economic damage estimated $280-420 billion
* Healthcare ransomware may cause 80-140 additional deaths

"Transport is waiting. You have 30 minutes. Get to that power grid facility and stop Marcus Chen."

~ crisis_choice = "infrastructure"
~ crisis_choice_made = true

-> mission_start

=== confirm_choice_b ===
"Data Apocalypse. You're prioritizing democratic institutions and data security." #speaker:Director Morgan

She inputs your assignment.

"Team Alpha will handle infrastructure - they'll fail. Expect 240-385 civilian deaths from the blackout. Team Bravo will take corporate - they'll succeed. Team Charlie on supply chain - partial success."

**ACCEPTED CONSEQUENCES:**
* Pacific Northwest blackout (4-7 days)
* 240-385 deaths from power grid failure
* $18 billion infrastructure damage

"Transport is waiting. You have 30 minutes. Dual timers - stop the breach AND the disinformation if you can."

~ crisis_choice = "data"
~ crisis_choice_made = true

-> mission_start

=== confirm_choice_c ===
"Supply Chain. You're prioritizing long-term national security over immediate lives." #speaker:Director Morgan

She inputs your assignment.

"Team Alpha will handle data security - full success. Team Bravo on infrastructure - partial success, some casualties. Team Charlie on corporate - they'll fail."

**ACCEPTED CONSEQUENCES:**
* Partial infrastructure blackout (reduced casualties: 80-120 deaths estimated)
* Corporate zero-day attacks succeed
* Combined economic damage: $300+ billion

"Transport is waiting. You have 30 minutes. Stop Adrian Cross before those backdoors deploy."

~ crisis_choice = "supply_chain"
~ crisis_choice_made = true

-> mission_start

=== confirm_choice_d ===
"Corporate Warfare. You're prioritizing economic stability." #speaker:Director Morgan

Her expression is carefully neutral - no judgment.

"Team Alpha will handle infrastructure - full success. Team Bravo on data - they'll fail, both attacks succeed. Team Charlie on supply chain - partial success."

**ACCEPTED CONSEQUENCES:**
* Voter database breach (187 million records)
* Disinformation campaign launches
* Democratic crisis, 20-40 deaths from civil unrest
* 4-8 million identity theft victims over 5 years

"Transport is waiting. You have 30 minutes. Deploy those countermeasures and stop Victoria Zhang."

~ crisis_choice = "corporate"
~ crisis_choice_made = true

-> mission_start

=== mission_start ===
Director Morgan extends her hand.

"Good luck, Agent. No matter what happens tonight, know that you're making the best choice you can with impossible options."

She pauses.

"And 0x00? The Architect is watching. They'll taunt you. Try to make you question your choice. Don't let them."

You nod and head for the exit.

**MISSION CLOCK STARTS: T-MINUS 30 MINUTES**

The weight of your choice settles on your shoulders. Somewhere, at the three targets you didn't choose, SAFETYNET teams are racing against the clock.

Some will succeed. Some will fail.

You chose your battlefield. Now you have to win it.

-> END
