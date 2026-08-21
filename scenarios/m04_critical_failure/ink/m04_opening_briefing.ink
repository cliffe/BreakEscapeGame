// ===========================================
// OPENING BRIEFING
// Mission 4: Critical Failure
// Break Escape - ENTROPY Cell: Critical Mass
// ===========================================

// Variables for tracking player choices and state
VAR player_approach = ""          // tactical, methodical, aggressive
VAR handler_trust = 50            // 0-100 Handler's confidence in player
VAR knows_full_threat = false     // Did player ask about chemical threat?
VAR knows_entropy_cell = false    // Did player ask about Critical Mass?
VAR mission_priority = ""         // investigation, speed, stealth
VAR combat_ready = false          // Player acknowledged combat risk
VAR mission_briefed = false       // Briefing completed

// External variables (set by game)
EXTERNAL player_name()

// ===========================================
// OPENING
// ===========================================

=== start ===
#speaker:agent_0x99

{player_name()}, we've got a critical infrastructure threat. ENTROPY's back.

This one's different from Ransomware Incorporated. More dangerous.

* [Go ahead. I'm listening.]
    ~ handler_trust += 5
    Narrator: You sit forward. Whatever this is, HaX has not bothered with the usual warm-up.
    -> briefing_main

* [What makes this cell more dangerous?]
    Agent HaX: They're infrastructure specialists. Not just disruption—they weaponize critical systems.
    -> briefing_main

* [I'm ready. What's the target?]
    ~ handler_trust += 10
    ~ player_approach = "confident"
    Agent HaX: Good. You'll need that confidence—this one involves combat.
    ~ combat_ready = true
    -> briefing_main

// ===========================================
// MAIN BRIEFING
// ===========================================

=== briefing_main ===
#speaker:agent_0x99

Agent HaX: Albion Energy Storage — 200 megawatt-hours of grid battery storage. ENTROPY cell called "Critical Mass."

Agent HaX: They've infiltrated the facility under cover as maintenance contractors—OptiGrid Solutions.

Agent HaX: Three operatives compromised the SCADA network controlling battery management systems.

Agent HaX: 240,000 residents depend on this grid.

* [Thermal runaway—what's the threat?]
    ~ knows_full_threat = true
    ~ handler_trust += 5
    -> chemical_threat_explanation

* [Critical Mass—what do we know about them?]
    ~ knows_entropy_cell = true
    -> critical_mass_explanation

* [Do we have a timeline for the attack?]
    -> timeline_explanation

=== chemical_threat_explanation ===
#speaker:agent_0x99

Agent HaX: Lithium-ion thermal runaway. The battery cells are safe inside their charge ceiling and cooling.

Agent HaX: They've fitted interlock-bypass modules on three rack banks and spoofed the thermal sensors. Remote overcharge trigger ready.

Agent HaX: If they activate it—the cells overcharge, heat past the runaway threshold, and ignite.

Agent HaX: A chain battery fire and a hydrogen explosion. The grid drops for 240,000 people and the hall goes up.

+ [We have to stop them before they trigger it.]
    ~ handler_trust += 5
    Agent HaX: Exactly. That's the priority.
    -> mission_stakes

+ [Why attack grid storage?]
    -> entropy_ideology

+ {not knows_entropy_cell} [Who is Critical Mass?]
    ~ knows_entropy_cell = true
    -> critical_mass_explanation

=== critical_mass_explanation ===
#speaker:agent_0x99

Agent HaX: Critical Mass—ENTROPY cell specializing in infrastructure attacks.

Agent HaX: Power storage, generation, transportation. They target critical lifelines.

Agent HaX: The cell answers to "Blackout" — Dr James Mercer. He signs the models, including the casualty figures, and he has never once revised one down.

Agent HaX: Blackout won't be on site. The man running Albion for him is a field lieutenant, calls himself Voltage. Former grid engineer, which is exactly why he was given this one.

Agent HaX: Don't go in expecting to talk him round. He isn't confused about what happens to the night crew. He costed them.

+ [Understood. What's the plan?]
    -> mission_objectives

+ {not knows_full_threat} [What's the threat to the grid?]
    ~ knows_full_threat = true
    ~ handler_trust += 5
    -> chemical_threat_explanation

=== timeline_explanation ===
#speaker:agent_0x99

Agent HaX: Intercepted encrypted traffic shows attack scheduled for 0800 local time.

Agent HaX: You've got a window, but it's tight. They're prepared for interference.

Agent HaX: Three operatives on-site: codenames Cipher, Relay, and Static. Plus Voltage.

+ [Four armed operatives. Should I expect combat?]
    ~ combat_ready = true
    ~ handler_trust += 10
    -> combat_warning

+ [Understood. What's my cover?]
    -> cover_identity_explanation

=== combat_warning ===
#speaker:agent_0x99

Agent HaX: Yes. This is your first mission with hostile ENTROPY operatives.

Agent HaX: They're not amateurs. Cipher guards the battery hall. Relay patrols inverter room.

Agent HaX: Static and Voltage are in the plant room—final defensive position.

Agent HaX: You can go stealth, but if compromised, you'll need to fight.

Agent HaX: I've authorized you for lethal force if necessary. But capture Voltage if possible—he knows things.

+ [I understand. Neutralize threats, prioritize Voltage's capture if possible.]
    ~ handler_trust += 15
    ~ player_approach = "tactical"
    Agent HaX: Good. That's the right mindset.
    -> mission_objectives

+ [I'll avoid combat where possible. Smarter to stay undetected.]
    ~ player_approach = "methodical"
    Agent HaX: Smart. But be prepared—they're expecting interference.
    -> mission_objectives

=== entropy_ideology ===
#speaker:agent_0x99

Agent HaX: ENTROPY believes society's infrastructure is built on exploitable vulnerabilities.

Agent HaX: They demonstrate this through attacks. Power, grid, transit—all "critical points of failure."

Agent HaX: It's ideological terrorism disguised as activism. They claim they're exposing systemic weaknesses.

Agent HaX: But people die. That's what makes them dangerous.

+ [They're rationalizing murder as a public service.]
    ~ handler_trust += 5
    Agent HaX: Exactly. Don't let their rhetoric confuse you.
    -> mission_stakes

=== cover_identity_explanation ===
#speaker:agent_0x99

Agent HaX: Your cover: grid-safety regulator conducting a surprise regulatory inspection.

Agent HaX: Forged credentials in your phone. Facility manager is Robert Vance—he's expecting an auditor today.

Agent HaX: Use the cover to get inside. Vance doesn't know about the threat yet.

+ [Once I'm inside, should I brief the facility manager?]
    -> chen_briefing_advice

+ [Understood. Once inside?]
    -> mission_objectives

=== chen_briefing_advice ===
#speaker:agent_0x99

Agent HaX: Your call. Vance's a career engineer—safety-focused, competent.

Agent HaX: If you reveal the truth, he'll cooperate fully. SCADA expertise could help.

Agent HaX: But operational security risk. If operatives monitor him, cover's blown.

Agent HaX: I trust your judgment. You'll know when it's safe.

+ [I'll assess Vance in person before deciding.]
    ~ handler_trust += 10
    ~ player_approach = "methodical"
    Agent HaX: Good tactical thinking.
    -> mission_objectives

=== mission_stakes ===
#speaker:agent_0x99

Agent HaX: This isn't just about stopping an attack.

Agent HaX: Intelligence suggests Critical Mass is coordinating with another ENTROPY cell—Social Fabric.

Agent HaX: Simultaneous infrastructure strikes across the region.

Agent HaX: We think someone's coordinating multiple cells. Call sign "The Architect."

Agent HaX: Capture Voltage, and we might get answers about this larger network.

+ [Stop the attack, capture Voltage if possible, gather intelligence on The Architect.]
    ~ handler_trust += 10
    Agent HaX: Exactly. In that order.
    -> mission_objectives

+ [The Architect is coordinating all ENTROPY cells?]
    Agent HaX: We think so. But we need proof. Voltage might have it.
    -> mission_objectives

// ===========================================
// MISSION OBJECTIVES
// ===========================================

=== mission_objectives ===
#speaker:agent_0x99

Agent HaX: Here's the mission breakdown:

Agent HaX: One—infiltrate the facility using your grid-safety regulator cover.

Agent HaX: Two—investigate the SCADA network. Identify how they compromised it.

Agent HaX: Three—stop it at the plant room. There's a hardwired Emergency Shutdown pushbutton in there, physical contacts, no network path. It's the one control they couldn't take. Press it and the banks isolate.

Agent HaX: Four—capture or eliminate ENTROPY operatives. Voltage is the priority for intelligence.

Agent HaX: VM access is set up for SCADA network investigation. Submit flags to the drop-site terminal.

* [Understood. Infiltrate, investigate, neutralize, capture. Moving out now.]
    ~ handler_trust += 10
    Agent HaX: Stay sharp. These operatives are prepared.
    -> mission_departure

* [What if I need backup?]
    -> backup_explanation

* [If I have to choose—stop the attack or capture Voltage?]
    -> priority_clarification

=== backup_explanation ===
#speaker:agent_0x99

Agent HaX: You're solo on this one. Local authorities can't be briefed—security risk.

Agent HaX: But Robert Vance can assist once you establish trust. He knows the systems.

Agent HaX: I'm monitoring remotely. Call if you need strategic guidance.

Agent HaX: This is on you. I trust you can handle it.

+ [Solo insertion. I've got this.]
    ~ handler_trust += 15
    ~ player_approach = "confident"
    Agent HaX: That's what I like to hear.
    -> mission_departure

+ [Understood. I'll adapt as needed.]
    ~ handler_trust += 5
    -> mission_departure

=== priority_clarification ===
#speaker:agent_0x99

Agent HaX: Attack prevention is absolute priority. 240,000 lives.

Agent HaX: Capture Voltage if you can—intelligence value is enormous.

Agent HaX: But if he threatens to trigger the attack, stop him by any means necessary.

Agent HaX: Lives first. Intelligence second.

+ [Attack prevention is priority one. Got it.]
    ~ handler_trust += 10
    Agent HaX: Good.
    -> mission_departure

=== mission_departure ===
#speaker:agent_0x99

Agent HaX: Facility is 20 minutes out. Security checkpoint will ask for credentials.

Agent HaX: Present your regulator credentials. Act like a routine surprise inspection.

Agent HaX: {combat_ready: Combat may be unavoidable. Stay tactical.| Stay alert. ENTROPY's waiting.}

Agent HaX: Good luck, {player_name()}. Bring those operatives down.

~ mission_briefed = true

// This is a linear cutscene, not a hub conversation: it must terminate, not
// loop back to `start`. The old `-> start` re-entered a knot whose once-only
// choices were already consumed, which is what produced "ran out of content"
// on every one of the 601 enumerated paths.
// Pattern follows m02_opening_briefing.ink:227-229.
//
// NOTE: the old `#complete_task:opening_briefing` named a task that does not
// exist in scenario.json.erb and did nothing. It is removed. No `#unlock_aim`/
// `#start_gameplay` tags are needed here: like m01 (the gold standard), this
// mission stages aims declaratively via each aim's `unlockCondition` in
// scenario.json.erb, so the first aim is already active when gameplay begins.
#exit_conversation

-> END
