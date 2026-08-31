// ================================================
// Mission 8: The Mole - THE CONFRONTATION (major scene)
// Speaker: Agent 0x47 'Nightshade'
// Entry knot: start   Completes: confront_nightshade
// Philosophy PRESENTED and REJECTED, never endorsed. Acknowledges the player's
// investigation (nightshade_suspected, suspect_theory). Fate chosen here and
// mirrored to the disposition terminal. Sets nightshade_arrested XOR triple_agent.
// ================================================

VAR player_name = "Agent 0x00"
VAR nightshade_confronted = false
VAR nightshade_arrested = false
VAR nightshade_triple_agent = false
VAR tomb_gamma_location_known = false
VAR nightshade_suspected = false
VAR suspect_theory = ""
VAR debrief_stance = ""
VAR asked_why = false
VAR asked_recruit = false
VAR asked_database = false
VAR asked_architect = false

=== start ===
Narrator: The interrogation room records everything. Nightshade sits with his hands flat on the table, unhurried, and for the first time in nine days he looks like a man who has set something heavy down.

Agent 0x47 'Nightshade': You found it. All of it. The repository, the credentials, the logs with my account all over them. I could have scrubbed every trace years ago, you know.
You: Why didn't you?
{ nightshade_suspected:
    Agent 0x47 'Nightshade': Because you already knew. I watched you decide, across that desk in the lab. Some part of me wanted it to be you who closed the loop -- not a stranger with a warrant. You, who trained beside me and never quite trusted the quiet.
- else:
    Agent 0x47 'Nightshade': Because some part of me wanted to be caught by someone who'd understand it. I misjudged that, I think. You look at me like I'm a stranger. Fair. Sit down anyway. You've earned the truth.
}
-> the_case

=== the_case ===
You: The logs put you on the Mission 7 plan for forty-seven minutes, forty-eight hours before Portland. The mail resolves to your account and an entropy.onion address. It's over, Nightshade. I only came for the why.
Agent 0x47 'Nightshade': Order is a candle in a hurricane, {player_name}. We stand round it with our hands cupped, night after night, and we call it a career. ENTROPY only told me the truth I'd already worked out alone: the storm always wins. So I stopped shielding the flame. I helped the wind. It felt, God help me, like honesty.
-> hub

=== hub ===
+ { not asked_why } [Two people are dead. You keep talking about wind. Say what you actually did.]
    ~ asked_why = true
    Agent 0x47 'Nightshade': *evenly* I gave them your deployment and I knew, to the site, which crises the team could not reach. I did the arithmetic of who that would kill and I did it anyway. I wrote as much -- you read it. I'm not asking you to forgive the sum. I'm telling you I did it with my eyes open.
    You: That's not honesty. That's a man dressing murder up as physics so he can sleep at night.
    Agent 0x47 'Nightshade': Perhaps. You always were better than me at the part I decided to skip.
    -> hub
+ { not asked_recruit } [When. When did they turn you?]
    ~ asked_recruit = true
    Agent 0x47 'Nightshade': Training. The same barracks as you, the same instructors, the same bad coffee. They don't recruit with money, {player_name} -- money leaves a trail and buys a coward. They recruit the ones who've started to suspect the whole enterprise is a delaying action. They found me at twenty-three, half-formed and already tired. Then they waited. Fifteen years. That's the patience you're really up against tonight.
    -> hub
+ { not asked_database } [Mission 7 wasn't about the four attacks, was it.]
    ~ asked_database = true
    Agent 0x47 'Nightshade': No. The attacks were the noise. While you and Netherton agonised over which fire to fight, they walked the global threat database out through a door I left open. Every vulnerability SAFETYNET has ever catalogued. That was the night's real work. The dead were... the cost of your attention being elsewhere.
    -> hub
+ { asked_database and not asked_architect } [Then where did it go? Where's The Architect?]
    ~ asked_architect = true
    Agent 0x47 'Nightshade': *he studies you for a long moment* You want the workshop. Tomb Gamma. I'll give it to you -- freely, because it's worth more than my silence and because I'd like, just once, to be the one who tips the board over.
    Agent 0x47 'Nightshade': Forty-seven point two-three-eight-two north. One-twelve point five-one-five-six west. An old Cold War bunker in Montana. That's where the database went, and that's where you'll find the man who's been reading your mail for fifteen years. #set_global:tomb_gamma_location_known:true
    ~ tomb_gamma_location_known = true
    -> hub
+ { asked_architect } [Enough. It's time to decide what happens to you.] -> the_choice
+ { not asked_architect } [Enough talk. What happens to you now.] -> the_choice

=== the_choice ===
Narrator: The disposition terminal waits on the wall behind you. Whatever you choose, you enter it there -- but he's asking, and after fifteen years you owe him the answer to his face.
Agent 0x47 'Nightshade': So. What does SAFETYNET do with a man who thinks he was right?
+ [No deals. You stand trial, and the two names you won't say get read out in a courtroom. That's the whole difference between us.]
    ~ nightshade_arrested = true
    Agent 0x47 'Nightshade': Clean. Predictable. I'd have expected nothing else from you, and I mean that as the compliment it is. Enter it. I won't fight it. #set_global:nightshade_arrested:true
    -> to_terminal
+ [No cell and a clear conscience. You get a leash -- you stay in play, you feed us ENTROPY, and you buy back one inch of what you took every single day.]
    ~ nightshade_triple_agent = true
    Agent 0x47 'Nightshade': *a long pause* You've grown a ruthless streak since training. I approve of it, which should frighten you more than it does. I'll be your ghost inside their machine -- for exactly as long as it suits me to be. Never forget I told you that part. #set_global:nightshade_triple_agent:true
    -> to_terminal

=== to_terminal ===
{ tomb_gamma_location_known:
    Agent 0x47 'Nightshade': Go on. The terminal. Make it real -- and take the coordinates to Netherton. Tomb Gamma won't wait for you to grieve me.
- else:
    Agent 0x47 'Nightshade': Go on. The terminal. Make it real. And when you're ready to ask where it all went -- the database, the man behind it -- you know where I'll be. I've one more thing to give you, if you come back for it.
}
Narrator: You hold his eye for a moment longer than you mean to. Then you turn to the terminal.
#set_global:nightshade_confronted:true #complete_task:confront_nightshade
~ nightshade_confronted = true
#exit_conversation
-> DONE
