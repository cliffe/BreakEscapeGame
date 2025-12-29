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

* [Listen carefully]
    ~ handler_trust += 5
    You lean forward, focused.
    -> briefing_main

* [Ask what makes it dangerous]
    You: What makes this cell more dangerous?
    Agent 0x99: They're infrastructure specialists. Not just disruption—they weaponize critical systems.
    -> briefing_main

* [Express readiness]
    ~ handler_trust += 10
    ~ player_approach = "confident"
    You: I'm ready. What's the target?
    Agent 0x99: Good. You'll need that confidence—this one involves combat.
    ~ combat_ready = true
    -> briefing_main

// ===========================================
// MAIN BRIEFING
// ===========================================

=== briefing_main ===
#speaker:agent_0x99

Agent 0x99: Pacific Northwest Regional Water Treatment Facility. ENTROPY cell called "Critical Mass."

Agent 0x99: They've infiltrated the facility under cover as maintenance contractors—OptiGrid Solutions.

Agent 0x99: Three operatives compromised the SCADA network controlling chemical dosing systems.

Agent 0x99: 240,000 residents drink that water.

* [Ask about the chemical threat]
    ~ knows_full_threat = true
    ~ handler_trust += 5
    You: Chemical dosing—what's the threat?
    -> chemical_threat_explanation

* [Ask about Critical Mass]
    ~ knows_entropy_cell = true
    You: Critical Mass—what do we know about them?
    -> critical_mass_explanation

* [Ask about timeline]
    You: Do we have a timeline for the attack?
    -> timeline_explanation

=== chemical_threat_explanation ===
#speaker:agent_0x99

Agent 0x99: Chlorine dosing. Normally safe at 0.5-1.0 ppm for disinfection.

Agent 0x99: They've installed bypass devices on three dosing stations. Remote trigger ready.

Agent 0x99: If they activate it—chlorine concentration spikes to 15+ ppm.

Agent 0x99: Acute chlorine poisoning. Respiratory failure. Mass casualties.

+ [That's horrifying]
    ~ handler_trust += 5
    You: We have to stop them before they trigger it.
    Agent 0x99: Exactly. That's the priority.
    -> mission_stakes

+ [What's their motive?]
    You: Why attack water infrastructure?
    -> entropy_ideology

+ {not knows_entropy_cell} [Who is Critical Mass?]
    ~ knows_entropy_cell = true
    -> critical_mass_explanation

=== critical_mass_explanation ===
#speaker:agent_0x99

Agent 0x99: Critical Mass—ENTROPY cell specializing in infrastructure attacks.

Agent 0x99: Power grids, water systems, transportation. They target critical lifelines.

Agent 0x99: Ideologically motivated. They want to prove society's infrastructure is fragile.

Agent 0x99: Leader goes by "Voltage." Former power grid engineer. Brilliant and dangerous.

+ [Understood. What's the plan?]
    -> mission_objectives

+ {not knows_full_threat} [What's the threat to the water supply?]
    ~ knows_full_threat = true
    ~ handler_trust += 5
    -> chemical_threat_explanation

=== timeline_explanation ===
#speaker:agent_0x99

Agent 0x99: Intercepted encrypted traffic shows attack scheduled for 0800 local time.

Agent 0x99: You've got a window, but it's tight. They're prepared for interference.

Agent 0x99: Three operatives on-site: codenames Cipher, Relay, and Static. Plus Voltage.

+ [Four hostiles. Will I need to engage?]
    ~ combat_ready = true
    ~ handler_trust += 10
    You: Four armed operatives. Should I expect combat?
    -> combat_warning

+ [Understood. What's my cover?]
    -> cover_identity_explanation

=== combat_warning ===
#speaker:agent_0x99

Agent 0x99: Yes. This is your first mission with hostile ENTROPY operatives.

Agent 0x99: They're not amateurs. Cipher guards the treatment floor. Relay patrols chemical storage.

Agent 0x99: Static and Voltage are in the maintenance wing—final defensive position.

Agent 0x99: You can go stealth, but if compromised, you'll need to fight.

Agent 0x99: I've authorized you for lethal force if necessary. But capture Voltage if possible—he knows things.

+ [I'm ready for combat]
    ~ handler_trust += 15
    ~ player_approach = "tactical"
    You: I understand. Neutralize threats, prioritize Voltage's capture if possible.
    Agent 0x99: Good. That's the right mindset.
    -> mission_objectives

+ [I'll try stealth first]
    ~ player_approach = "methodical"
    You: I'll avoid combat where possible. Smarter to stay undetected.
    Agent 0x99: Smart. But be prepared—they're expecting interference.
    -> mission_objectives

=== entropy_ideology ===
#speaker:agent_0x99

Agent 0x99: ENTROPY believes society's infrastructure is built on exploitable vulnerabilities.

Agent 0x99: They demonstrate this through attacks. Water, power, transit—all "critical points of failure."

Agent 0x99: It's ideological terrorism disguised as activism. They claim they're exposing systemic weaknesses.

Agent 0x99: But people die. That's what makes them dangerous.

+ [Twisted logic]
    ~ handler_trust += 5
    You: They're rationalizing murder as a public service.
    Agent 0x99: Exactly. Don't let their rhetoric confuse you.
    -> mission_stakes

=== cover_identity_explanation ===
#speaker:agent_0x99

Agent 0x99: Your cover: state EPA auditor conducting a surprise regulatory inspection.

Agent 0x99: Forged credentials in your phone. Facility manager is Robert Chen—he's expecting an auditor today.

Agent 0x99: Use the cover to get inside. Chen doesn't know about the threat yet.

+ [Should I tell Chen the truth?]
    You: Once I'm inside, should I brief the facility manager?
    -> chen_briefing_advice

+ [Understood. Once inside?]
    -> mission_objectives

=== chen_briefing_advice ===
#speaker:agent_0x99

Agent 0x99: Your call. Chen's a career engineer—safety-focused, competent.

Agent 0x99: If you reveal the truth, he'll cooperate fully. SCADA expertise could help.

Agent 0x99: But operational security risk. If operatives monitor him, cover's blown.

Agent 0x99: I trust your judgment. You'll know when it's safe.

+ [I'll decide based on the situation]
    ~ handler_trust += 10
    ~ player_approach = "methodical"
    You: I'll assess Chen in person before deciding.
    Agent 0x99: Good tactical thinking.
    -> mission_objectives

=== mission_stakes ===
#speaker:agent_0x99

Agent 0x99: This isn't just about stopping an attack.

Agent 0x99: Intelligence suggests Critical Mass is coordinating with another ENTROPY cell—Social Fabric.

Agent 0x99: Simultaneous infrastructure strikes across the region.

Agent 0x99: We think someone's coordinating multiple cells. Call sign "The Architect."

Agent 0x99: Capture Voltage, and we might get answers about this larger network.

+ [Understood. Multiple priorities]
    ~ handler_trust += 10
    You: Stop the attack, capture Voltage if possible, gather intelligence on The Architect.
    Agent 0x99: Exactly. In that order.
    -> mission_objectives

+ [The Architect?]
    You: The Architect is coordinating all ENTROPY cells?
    Agent 0x99: We think so. But we need proof. Voltage might have it.
    -> mission_objectives

// ===========================================
// MISSION OBJECTIVES
// ===========================================

=== mission_objectives ===
#speaker:agent_0x99

Agent 0x99: Here's the mission breakdown:

Agent 0x99: One—infiltrate the facility using your EPA auditor cover.

Agent 0x99: Two—investigate the SCADA network. Identify how they compromised it.

Agent 0x99: Three—neutralize the attack threat. Disable all attack vectors: physical bypass devices, SCADA malware, remote trigger.

Agent 0x99: Four—capture or eliminate ENTROPY operatives. Voltage is the priority for intelligence.

Agent 0x99: VM access is set up for SCADA network investigation. Submit flags to the drop-site terminal.

* [All clear. I'm moving out]
    ~ handler_trust += 10
    You: Understood. Infiltrate, investigate, neutralize, capture. Moving out now.
    Agent 0x99: Stay sharp. These operatives are prepared.
    -> mission_departure

* [Ask about backup]
    You: What if I need backup?
    -> backup_explanation

* [Clarify priority: attack vs. capture]
    You: If I have to choose—stop the attack or capture Voltage?
    -> priority_clarification

=== backup_explanation ===
#speaker:agent_0x99

Agent 0x99: You're solo on this one. Local authorities can't be briefed—security risk.

Agent 0x99: But Robert Chen can assist once you establish trust. He knows the systems.

Agent 0x99: I'm monitoring remotely. Call if you need strategic guidance.

Agent 0x99: This is on you. I trust you can handle it.

+ [I can handle it]
    ~ handler_trust += 15
    ~ player_approach = "confident"
    You: Solo insertion. I've got this.
    Agent 0x99: That's what I like to hear.
    -> mission_departure

+ [I'll make it work]
    ~ handler_trust += 5
    You: Understood. I'll adapt as needed.
    -> mission_departure

=== priority_clarification ===
#speaker:agent_0x99

Agent 0x99: Attack prevention is absolute priority. 240,000 lives.

Agent 0x99: Capture Voltage if you can—intelligence value is enormous.

Agent 0x99: But if he threatens to trigger the attack, stop him by any means necessary.

Agent 0x99: Lives first. Intelligence second.

+ [Understood. Lives first]
    ~ handler_trust += 10
    You: Attack prevention is priority one. Got it.
    Agent 0x99: Good.
    -> mission_departure

=== mission_departure ===
#speaker:agent_0x99

Agent 0x99: Facility is 20 minutes out. Security checkpoint will ask for credentials.

Agent 0x99: Present your EPA badge. Act like a routine surprise inspection.

Agent 0x99: {combat_ready: Combat may be unavoidable. Stay tactical.| Stay alert. ENTROPY's waiting.}

Agent 0x99: Good luck, {player_name()}. Bring those operatives down.

~ mission_briefed = true
#complete_task:opening_briefing
#exit_conversation
-> start
