// Mission 7: The Architect's Gambit - The Architect Communications
// Time-based taunts from the mysterious ENTROPY mastermind

// Global variables (synced with scenario.json.erb)
VAR crisis_choice = ""
VAR architect_t30_shown = false
VAR architect_t20_shown = false
VAR architect_t10_shown = false
VAR architect_t05_shown = false
VAR architect_t01_shown = false

// Local variables for these communications
VAR architect_success_shown = false
VAR architect_failure_shown = false

=== architect_comms ===
// Entry point - this will be called at specific timer intervals
// The game engine should call specific knots based on timer

-> t30_message

=== t30_message ===
~ architect_t30_shown = true

Your phone vibrates. An encrypted message from an unknown sender appears on your screen.

The sender ID shows only: **THE ARCHITECT**

{crisis_choice == "infrastructure":
    "Agent 0x00. I've been watching your career with interest. Let's see if you're as capable as your reputation suggests." #speaker:The Architect

    "You chose infrastructure. Pragmatic. Lives over data, over money. Admirable, in its way."
}

{crisis_choice == "data":
    "Agent 0x00. Welcome to the game." #speaker:The Architect

    "Democracy is an illusion built on public faith. You chose to protect that illusion. Interesting."
}

{crisis_choice == "supply_chain":
    "Agent 0x00. So you're the one they sent." #speaker:The Architect

    "Supply chain attacks are beautiful, aren't they? One compromise, millions infected. Efficiency. You chose to prevent future suffering over present deaths. Utilitarian."
}

{crisis_choice == "corporate":
    "Agent 0x00. I've been expecting you." #speaker:The Architect

    "Capitalism built on insecure foundations. You chose to protect those foundations. Shareholders over citizens. Bold choice."
}

The message continues:

"Let's see if you can stop entropy tonight. Spoiler: you can't. You can only delay it."

**T-MINUS 30 MINUTES**

+ [Ignore the message] -> END
+ [Trace the source] -> trace_attempt

=== trace_attempt ===
You attempt to trace the message source.

**TRACE FAILED:** Routing through 47 proxy servers across 14 countries. Source: Unknown.

The Architect sends another message:

"Nice try. But I'm always three steps ahead." #speaker:The Architect

-> END

=== t20_message ===
~ architect_t20_shown = true

Another encrypted message from THE ARCHITECT.

{crisis_choice == "infrastructure":
    "You chose infrastructure. But tell me - do you know what's happening at the other three targets right now?" #speaker:The Architect

    "Team Charlie is failing. Corporate zero-day attacks are deploying. Healthcare ransomware locking hospitals. People will die from delayed surgeries."

    "Did you choose correctly?"
}

{crisis_choice == "data":
    "You chose to protect data. Noble. But data isn't alive, Agent 0x00. People at the other targets are." #speaker:The Architect

    "Team Alpha is failing. Right now, the Pacific Northwest power grid is cascading toward failure. 240-385 deaths over 72 hours."

    "Was it worth it? Protecting voter records while people freeze in the dark?"
}

{crisis_choice == "supply_chain":
    "You chose long-term threat over immediate deaths. Interesting priorities." #speaker:The Architect

    "Team Bravo is containing infrastructure. But Team Charlie is failing. Economic damage mounting. Healthcare systems being ransomwared."

    "47 million future infections prevented. How many die tonight because you chose tomorrow over today?"
}

{crisis_choice == "corporate":
    "You chose corporations over civilians. The market over mortality." #speaker:The Architect

    "Team Alpha succeeded on infrastructure - well done, them. But Team Bravo is failing catastrophically. Voter database breach complete. Disinformation deploying. Democracy is about to shatter."

    "You saved shareholder value. Was that worth the constitutional crisis?"
}

**T-MINUS 20 MINUTES**

+ [Focus on the mission] -> END
+ [Respond to The Architect] -> respond_attempt

=== respond_attempt ===
You type a response message.

**DELIVERY FAILED:** Sender address does not accept incoming communications.

The Architect sends another line:

"I don't need your words, Agent. Your choices speak volumes." #speaker:The Architect

-> END

=== t10_message ===
~ architect_t10_shown = true

Another message. The Architect's taunts are getting more philosophical.

"The beauty of entropy is its inevitability." #speaker:The Architect

{crisis_choice == "infrastructure":
    "Even if you stop this power grid attack, something else fails. Someone else dies. Infrastructure decays. Systems collapse."

    "Marcus believes in exposing vulnerabilities. Do you know what's tragic? He's RIGHT. The power grid IS vulnerable. You're just delaying the inevitable blackout."
}

{crisis_choice == "data":
    "Even if you stop the breach, even if you wipe the narratives - the distrust persists. Truth is already dead. I killed it."

    "Rachel believes she's exposing corruption. Specter believes in information freedom. They're both tools. As are you."
}

{crisis_choice == "supply_chain":
    "Software updates are built on trust. One betrayal, that trust shatters forever. Even if you stop this, who will update their systems now?"

    "Adrian believes supply chains are vulnerable. He's correct. You're not fixing the vulnerability - just preventing this exploitation."
}

{crisis_choice == "corporate":
    "Corporations prioritize profit over security. Always have, always will. Even if you save them tonight, they'll never invest properly in defense."

    "Victoria believes in corporate accountability. Marcus believes in profit. I believe in entropy. Who's right?"
}

"You can't win, Agent 0x00. You can only choose which way to lose."

**T-MINUS 10 MINUTES**

+ [Stay focused] -> END

=== t05_message ===
~ architect_t05_shown = true

The messages are coming faster now.

"T-minus 5 minutes. Let me ask you a philosophical question." #speaker:The Architect

{crisis_choice == "infrastructure":
    "Marcus believes his cause justifies casualties. Do you believe yours does? You accepted economic collapse elsewhere to save these lives."

    "What's the calculus? 240 lives saved here, 80-140 lost to healthcare ransomware there? Did you maximize survival, or just minimize visible blood on your hands?"
}

{crisis_choice == "data":
    "You chose to protect democracy. But what IS democracy when the public doesn't trust elections? When data is weaponized?"

    "You can stop the breach OR the disinformation. Not both. Choose which lie to preserve."
}

{crisis_choice == "supply_chain":
    "47 million systems. Think about that scale. Every hospital, every bank, every government agency."

    "You chose this over immediate deaths. That's cold calculus, Agent. Utilitarian to the core. Are you comfortable with that choice?"
}

{crisis_choice == "corporate":
    "47 zero-days. 12 corporations. $4.2 trillion market cap. All falling simultaneously."

    "But you know what's interesting? Even if you save them, they'll never properly invest in security. Profits over protection. Always."
}

"Five minutes. Entropy accelerates."

**T-MINUS 5 MINUTES**

+ [Ignore The Architect] -> END

=== t01_message ===
~ architect_t01_shown = true

Final message. One minute remaining.

{crisis_choice == "infrastructure":
    "Impressive. You're about to stop the blackout." #speaker:The Architect

    "But this was never really about the power grid, was it? This was about forcing you to choose. About showing you that every victory comes with a cost elsewhere."

    "Enjoy your pyrrhic victory, Agent."
}

{crisis_choice == "data":
    "Even if you succeed here, the narratives will persist. Disinformation doesn't need deployment - it's already in people's minds." #speaker:The Architect

    "You're fighting an information war you've already lost."
}

{crisis_choice == "supply_chain":
    "You're about to prevent the largest supply chain attack in history. Congratulations." #speaker:The Architect

    "But present-day casualties mount at other targets while you protect future systems. The math doesn't justify itself, does it?"
}

{crisis_choice == "corporate":
    "Look at you, protecting the wealth of corporations while civilians suffer elsewhere." #speaker:The Architect

    "But you know what? Economic stability matters too. Systems matter. You made a defensible choice, even if it feels dirty."
}

"One minute, Agent 0x00. Let's see how this plays out."

**T-MINUS 1 MINUTE**

+ [Final push] -> END

=== success_message ===
~ architect_success_shown = true

After you neutralize the attack, one final message arrives.

{crisis_choice == "infrastructure":
    "Congratulations. You saved 8.4 million people from a blackout. Zero casualties from power grid failure. Meanwhile, at the targets you didn't choose: Corporate healthcare ransomware 80-140 deaths from delayed care, Social Fabric disinformation Democratic trust damaged, Supply Chain prevented by Team Alpha. Total casualties tonight: 80-140 deaths. You minimized death. Well done. But they still died. Was it worth it?" #speaker:The Architect
- else:
    {crisis_choice == "data":
        "Impressive. You stopped both the data breach and the disinformation campaign. Democracy survives another day. Meanwhile, at the targets you didn't choose: Infrastructure 240-385 deaths from power grid blackout (Team Alpha failed), Corporate prevented by Team Bravo, Supply Chain partial success by Team Charlie. Total casualties tonight: 240-385 deaths. You saved democratic institutions. People died in the dark. Was that the right trade?" #speaker:The Architect
    - else:
        {crisis_choice == "supply_chain":
            "Well done. You prevented 47 million backdoor infections. Long-term national security preserved. Meanwhile, at the targets you didn't choose: Infrastructure partial success by Team Bravo (80-120 deaths), Data full success by Team Alpha (zero casualties), Corporate healthcare ransomware deployed (80-140 deaths). Total casualties tonight: 160-260 deaths. You chose future security over present lives. They died while you prevented tomorrow's crisis. Utilitarian calculus." #speaker:The Architect
        - else:
            "Outstanding. All 47 zero-days neutralized. 4.2 trillion in market value preserved. Meanwhile, at the targets you didn't choose: Infrastructure full success by Team Alpha (zero casualties), Data both attacks succeeded (voter breach + disinformation, 20-40 deaths from civil unrest), Supply Chain partial success by Team Charlie. Total casualties tonight: 20-40 deaths. You saved shareholder wealth. People died in civil unrest over a compromised election. What did you really protect?" #speaker:The Architect
        }
    }
}

The message continues:

"But here's what you should understand, Agent 0x00: Tonight was a test. A proof-of-concept. ENTROPY is just beginning."

"You won your battle. But the war? The war is inevitable. Entropy always wins."

"I'll be watching your career with great interest. Until we meet again."

**-- THE ARCHITECT**

+ [Report this to Director Morgan] -> END
+ [Delete the message] -> END

=== failure_message ===
~ architect_failure_shown = true

The timer hits zero. You failed to stop the attack in time.

A final message from THE ARCHITECT arrives.

{crisis_choice == "infrastructure":
    "The grid is falling. Cascading failures across the Pacific Northwest. 8.4 million people in darkness. Over the next 72 hours: 240-385 deaths. Hospital generators failing. Traffic accidents. Hypothermia. You tried. But entropy won." #speaker:The Architect
- else:
    {crisis_choice == "data":
        "The data is gone. 187 million voter records exfiltrated. Disinformation deploying across all platforms. Democracy is about to shatter. Civil unrest incoming. 20-40 deaths in the first week. Constitutional crisis unfolding. You failed to protect the foundation of your republic." #speaker:The Architect
    - else:
        {crisis_choice == "supply_chain":
            "The backdoors are deployed. 47 million systems infected. Hospitals, banks, government agencies - all compromised. They won't know for 90 days. But when they discover it, the damage will be catastrophic. 240-420 billion over 10 years. You failed to prevent the largest supply chain attack in history." #speaker:The Architect
        - else:
            "47 zero-days deployed simultaneously. Stock market crashing. Healthcare ransomware active. Banking systems freezing. 4.2 trillion in value destroyed. 80-140 deaths from delayed medical care. 140,000+ job losses incoming. You failed to protect the economic foundation of your country." #speaker:The Architect
        }
    }
}

"And the other operations? Mixed results, as predicted. But YOUR failure made everything worse."

"This is entropy, Agent 0x00. Inevitable. Beautiful. Accelerating."

"Better luck next time. If there is a next time."

**-- THE ARCHITECT**

+ [Face the consequences] -> END

-> END
