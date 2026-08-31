EXTERNAL player_name()

VAR player_approach = ""
VAR handler_trust = 50
VAR knows_m2_connection = false
VAR mission_priority = ""
VAR asked_about_victoria = false
VAR asked_clone = false
VAR asked_network = false
VAR asked_cover = false
VAR asked_learn = false

=== start ===
Narrator: A SAFETYNET briefing room. Director Netherton stands by the screen; Agent 0x99 is patched in over comms; and a man in a lab coat sits half-buried in a laptop he clearly built himself.

Director Magnus Netherton: Agent 0x00. Zero Day Syndicate have stopped selling exploits and started deploying them. That is a line I do not let a cell cross. You're going in. HaX runs you, Nightshade runs the technical side. Listen to both.

Agent 0x47 'Nightshade': *not quite looking up from the laptop* Evening. Whatever they've built, I'll take it apart from here. You just get me close to it.

Director Magnus Netherton: HaX. The floor's yours.

Agent 0x99: {player_name()}, thanks for picking up. We have a developing situation.
Agent 0x99: Zero Day Syndicate. You heard of them?
* [Refresh my memory]
    You: Remind me - what's their deal?
    -> briefing_main
* [The exploit marketplace]
    ~ handler_trust = handler_trust + 10
    # influence_increased
    You: The exploit marketplace. They sell zero-day vulnerabilities.
    Agent 0x99: Exactly. And we've got evidence they're escalating.
    -> briefing_main
* [Just brief me]
    ~ player_approach = "direct"
    You: Skip the background. What's the mission?
    Agent 0x99: Right to business. I like it.
    -> briefing_main

=== briefing_main ===
#speaker:agent_0x99
Agent 0x99: Zero Day operates under the cover of WhiteHat Security Services.
Agent 0x99: Legitimate pen testing firm by day. Exploit marketplace by night.
{ player_approach == "direct":
    Agent 0x99: Here's what matters: we need intel on their operations.
    -> objectives
}
Agent 0x99: They've been selling exploits to other ENTROPY cells.
* [Which cells?]
    You: Which ENTROPY cells are they selling to?
    Agent 0x99: Ransomware Incorporated, Social Fabric, Critical Mass... possibly others.
    ~ handler_trust = handler_trust + 5
    # influence_increased
    -> st_catherines_connection
* [What kind of exploits?]
    You: What kind of exploits are we talking about?
    Agent 0x99: Healthcare infrastructure. Energy grid SCADA systems. Critical targets.
    -> st_catherines_connection
* [This sounds serious]
    ~ player_approach = "cautious"
    You: This sounds more serious than usual.
    Agent 0x99: It is. Much more serious.
    -> st_catherines_connection

=== st_catherines_connection ===
#speaker:agent_0x99
Agent 0x99: Remember the St. Catherine's Hospital attack from last month?
Agent 0x99: The ransomware that killed six people in critical care?
* [Of course I remember]
    ~ knows_m2_connection = true
    ~ handler_trust = handler_trust + 5
    # influence_increased
    You: Of course. The ProFTPD exploit. Patient monitoring systems went down.
    Agent 0x99: Right. We think Zero Day sold that exploit.
    -> mission_stakes
* [That was ENTROPY?]
    ~ knows_m2_connection = true
    You: Wait - that hospital attack was ENTROPY?
    Agent 0x99: We didn't have confirmation at the time. Now we do.
    -> mission_stakes
* [I heard about it]
    ~ knows_m2_connection = true
    You: I saw the news coverage. Six deaths.
    Agent 0x99: Six confirmed. The real number might be higher.
    -> mission_stakes

=== mission_stakes ===
#speaker:agent_0x99
Agent 0x99: Zero Day didn't deploy the ransomware. They just sold the exploit.
Agent 0x99: For $12,500. With a "healthcare premium" markup.
{ knows_m2_connection:
    Agent 0x99: They charged MORE because hospitals can't defend themselves as well.
    Agent 0x99: Calculated profit from human suffering.
}
* [That's murder for profit]
    ~ handler_trust = handler_trust + 10
    # influence_increased
    ~ player_approach = "cautious"
    You: That's not hacking. That's murder for profit.
    Agent 0x99: Exactly. And they're planning Phase 2.
    -> objectives
* [We need to stop them]
    ~ handler_trust = handler_trust + 5
    # influence_increased
    You: We need to shut them down. Now.
    Agent 0x99: Agreed. That's the mission.
    -> objectives
* [What's Phase 2?]
    You: You said Phase 2. What's Phase 2?
    Agent 0x99: That's what you're going to find out.
    -> objectives

=== objectives ===
#speaker:agent_0x99
Agent 0x99: Your mission objectives:
Agent 0x99: One - infiltrate WhiteHat Security and clone Victoria Sterling's executive keycard.
Agent 0x99: Two - access their training network and gather intelligence on exploit sales.
Agent 0x99: Three - find physical evidence linking Zero Day to the hospital attack.
Agent 0x99: This tests your network recon, encoding analysis, and intelligence correlation - nmap scanning, banner grabbing, multi-layer decoding. Real pen testing work.
Agent 0x99: Ask me whatever you need before you go in.
-> briefing_hub

=== briefing_hub ===
+ {not asked_about_victoria} [Who's Victoria Sterling?]
    ~ asked_about_victoria = true
    -> topic_victoria
+ {not asked_clone} [How do I clone her keycard?]
    ~ asked_clone = true
    -> topic_clone
+ {not asked_network} [What's the training network?]
    ~ asked_network = true
    -> topic_network
+ {not asked_cover} [How do I get in - what's my cover?]
    ~ asked_cover = true
    -> topic_cover
+ {not asked_learn} [What will I actually learn from this?]
    ~ asked_learn = true
    -> topic_learn
+ [That's everything - let's talk approach]
    -> mission_approach

=== topic_victoria ===
#speaker:agent_0x99
Agent 0x99: Victoria Sterling, CEO of WhiteHat Security. Former DEFCON speaker, respected researcher.
Agent 0x99: And likely the operational lead for Zero Day Syndicate. Codename: "Sable."
Agent 0x99: Smart, charismatic, ideologically committed to "free market vulnerability research."
* [So she's convinced herself selling hospital exploits is just economics?]
    ~ handler_trust = handler_trust + 5
    # influence_increased
    Agent 0x99: Exactly. She's not a sociopath. She's a true believer - which might make her more dangerous.
    -> briefing_hub
* [Any chance she's recruitable? As a double agent?]
    ~ handler_trust = handler_trust + 10
    # influence_increased
    ~ player_approach = "diplomatic"
    Agent 0x99: Possible. If you can make her see the human cost of her philosophy.
    Agent 0x99: But that's optional. Primary mission is intelligence gathering.
    -> briefing_hub
+ [Got it.]
    -> briefing_hub

=== topic_clone ===
#speaker:agent_0x99
Agent 0x99: You'll meet Victoria under the cover of a potential recruit. While you're with her, clone her RFID executive keycard - that's your server room access after hours.
Agent 0x99: We're giving you a pocket-sized RFID cloner. Get within a couple of metres for about ten seconds; it vibrates when the clone's done, then get some distance.
Agent 0x47 'Nightshade': And it's a straight capture-and-replay -- her card broadcasts, we copy, we impersonate. If you feel a pang about how easy that is, hold onto it. It's the same trick the other side uses on us, and one day it'll be our badge someone clones.
* [What if she notices?]
    Agent 0x99: Play the curious recruit - you're interested in their research. The cloner stays passive until you trigger it.
    -> briefing_hub
+ [Understood.]
    -> briefing_hub

=== topic_network ===
#speaker:agent_0x99
Agent 0x99: Once you're in the server room you'll find their training network - a VM environment at 192.168.100.0/24.
Agent 0x99: Zero Day uses it to test exploits before selling them. Run reconnaissance - port scanning, service enumeration, the usual.
* [What am I looking for specifically?]
    Agent 0x99: Operational logs. Client communications. Evidence of the hospital attack. And anything about Phase 2 - their future target list.
    -> briefing_hub
+ [Standard pentest procedures. Got it.]
    ~ handler_trust = handler_trust + 5
    # influence_increased
    Agent 0x99: Exactly. Scan, enumerate, exploit if needed.
    -> briefing_hub

=== topic_cover ===
#speaker:agent_0x99
Agent 0x99: Your cover: a cybersecurity researcher interested in Zero Day's training programs. Victoria's meeting you to size you up as recruit material.
Agent 0x99: Entry point is a conference room meeting at 2 PM. After that you'll have until the building empties to prep.
Agent 0x99: If she asks - you're a freelance pentester, small firms, looking for bigger opportunities, drawn to the "morally grey" side. That'll appeal to her.
* [When do I hit the server room?]
    Agent 0x99: After the daytime meeting. Most staff gone, just a security guard on patrol. That's when you move.
    -> briefing_hub
+ [I understand the setup.]
    Agent 0x99: Good. And be natural with her - she's smart, she'll spot nervousness.
    -> briefing_hub

=== topic_learn ===
#speaker:agent_0x99
Agent 0x99: Good question - this one's educational as well as operational.
Agent 0x99: Network reconnaissance with nmap. Banner grabbing with netcat, and what systems leak unintentionally.
Agent 0x99: Encoding versus encryption - decoding ROT13, hex, and Base64. That's obfuscation, not security.
Agent 0x99: And the big one: correlating digital evidence with physical intelligence, and the economics of the zero-day marketplace.
+ [Understood.]
    -> briefing_hub

=== mission_approach ===
#speaker:agent_0x99
Agent 0x99: Before you go in - how do you want to approach this?
Agent 0x99: Your call. I trust your judgment.
+ [Careful and methodical]
    ~ player_approach = "cautious"
    ~ mission_priority = "thoroughness"
    You: I'll be thorough. Document everything, leave no stone unturned.
    Agent 0x99: Smart approach. The more intel we get, the better our case.
    Agent 0x99: Just remember there's a guard on night patrol. Stealth matters.
    -> final_instructions
+ [Fast and decisive]
    ~ player_approach = "aggressive"
    ~ mission_priority = "speed"
    You: I'll move fast. Get the objectives done and get out.
    Agent 0x99: Speed has advantages. Less time for things to go wrong.
    Agent 0x99: But don't rush past critical evidence. The hospital connection proof is vital.
    -> final_instructions
+ [Adapt to the situation]
    ~ player_approach = "diplomatic"
    ~ mission_priority = "stealth"
    You: I'll read the situation. Stay flexible.
    ~ handler_trust = handler_trust + 10
    # influence_increased
    Agent 0x99: Adaptability. That's why you're good at this.
    Agent 0x99: Trust your instincts. Call if you need guidance.
    -> final_instructions

=== final_instructions ===
#speaker:agent_0x99
{ player_approach == "cautious":
    Agent 0x99: Your careful approach is good for this mission. Zero Day leaves paper trails.
    Agent 0x99: Find the documents. Connect the dots.
}
{ player_approach == "aggressive":
    Agent 0x99: You'll need speed for the network challenges. But take time for physical evidence.
    Agent 0x99: Operational logs, client lists, anything linking them to St. Catherine's.
}
{ player_approach == "diplomatic":
    Agent 0x99: Victoria might respect honesty if you find the right moment.
    Agent 0x99: Optional objective: assess whether she's recruitable as a double agent.
}
Agent 0x99: Field Operations Rule 7 - "When infiltrating corporate environments, remember that the most valuable intelligence is often in the least secure location."
{ knows_m2_connection:
    Agent 0x99: And {player_name()}... six people died because of what Zero Day sold.
    Agent 0x99: Four in critical care. Two during emergency surgery when systems failed.
    Agent 0x99: Whatever you find, make it count.
}
* [I won't let you down]
    ~ handler_trust = handler_trust + 10
    # influence_increased
    You: I'll get the evidence. Zero Day is going down.
    Agent 0x99: That's what I wanted to hear. Stay safe out there.
    -> deployment
* [Any last advice?]
    You: Any last advice before I go in?
    -> last_advice
* [I'm ready]
    -> deployment

=== last_advice ===
#speaker:agent_0x99
Agent 0x99: Victoria will test you. Philosophical questions about security ethics.
Agent 0x99: Play the curious researcher. Don't tip your hand.
Agent 0x99: And if you find evidence of Danny Foster's involvement...
Agent 0x99: He's a mid-level consultant. Might be innocent, might be complicit. Your call on what to do.
* [I'll assess in the field]
    ~ handler_trust = handler_trust + 5
    # influence_increased
    You: I'll make that judgment when I have the facts.
    Agent 0x99: Good answer. Collect evidence first, decide later.
    -> deployment
* [Every ENTROPY operative goes down]
    ~ player_approach = "aggressive"
    You: If he's involved with ENTROPY, he's compromised.
    Agent 0x99: Maybe. But gather proof before making that call.
    -> deployment
* [Understood]
    -> deployment

=== deployment ===
#speaker:agent_0x99
Agent 0x99: WhiteHat Security is at 1247 Market Street, downtown financial district.
Agent 0x99: I'll be on comms if you need support. The drop-site terminal in the server room connects directly to me.
{ handler_trust >= 70:
    Agent 0x99: And {player_name()}? I know you'll do this right. You always do.
}
{ (handler_trust >= 50) && (handler_trust < 70):
    Agent 0x99: Good luck. You've got this.
}
{ handler_trust < 50:
    Agent 0x99: Stay focused. Don't let the stakes psych you out.
}
Agent 0x99: Remember: meet with Victoria, clone her keycard, then night infiltration.
Agent 0x99: Go get 'em, {player_name()}. Haxolottle out.
[Transition: Fade to WhiteHat Security reception lobby, 2 PM]
#start_gameplay
-> DONE
