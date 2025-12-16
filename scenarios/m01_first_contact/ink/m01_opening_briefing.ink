// ================================================
// Mission 1: First Contact - Opening Briefing
// Act 1: Interactive Cutscene
// Agent 0x99 "Haxolottle" briefs Agent 0x00
// UPDATED: Operation Shatter - Clear evil threat
// UPDATED: Removed vague "approach" choice - outcomes
//          now based on actual player decisions
// ================================================

// Variables for tracking what player asked about (affects debrief)
VAR asked_about_stakes = false
VAR asked_about_casualties = false
VAR asked_about_architect = false
VAR asked_about_derek = false
VAR asked_about_maya = false
VAR mission_accepted = false

// External variables
VAR player_name = "Agent 0x00"

// ================================================
// START: BRIEFING BEGINS
// ================================================

=== start ===
Agent 0x99: {player_name}, thanks for getting here on short notice.

Agent 0x99: We have a situation developing at Viral Dynamics Media. And it's worse than we initially thought.

+ [What's the situation?]
    -> briefing_threat
+ [I'm ready. What's the mission?]
    -> briefing_threat
+ [How urgent is this?]
    ~ asked_about_stakes = true
    -> urgency_explanation

// ================================================
// URGENCY EXPLANATION
// ================================================

=== urgency_explanation ===
Agent 0x99: We're 72 hours from a mass casualty event.

Agent 0x99: ENTROPY's Social Fabric cell is operating inside Viral Dynamics. But they're not just running disinformation campaigns.

Agent 0x99: They're planning something called "Operation Shatter."

-> briefing_threat

// ================================================
// THREAT BRIEFING - OPERATION SHATTER
// ================================================

=== briefing_threat ===
Agent 0x99: Three weeks ago, our AI flagged something bigger than election interference.

Agent 0x99: Social Fabric has spent three months collecting psychological profiles. Detailed vulnerability assessments on over two million people in the region.

+ [What kind of profiles?]
    -> profile_details
+ [What are they planning to do with them?]
    -> operation_shatter
+ [Two million people?]
    -> profile_scale

// ================================================
// PROFILE DETAILS
// ================================================

=== profile_details ===
Agent 0x99: Medical records. Prescription histories. Financial stress indicators. Documented anxiety disorders.

Agent 0x99: They've identified who has insulin dependencies. Who relies on weekly dialysis. Who lives alone without family support.

Agent 0x99: This isn't demographic marketing data. This is a targeting database for psychological warfare.

+ [What are they going to do with it?]
    -> operation_shatter
+ [How did they get this data?]
    -> data_source

=== data_source ===
Agent 0x99: The usual methods—breached insurance databases, compromised pharmacy systems, scraped social media.

Agent 0x99: But the concerning part isn't how they got it. It's what they're planning to do with it.

-> operation_shatter

=== profile_scale ===
Agent 0x99: 2.3 million profiles, to be precise. And each one includes a vulnerability score.

Agent 0x99: They've categorized people by how likely they are to panic. To make dangerous decisions. To die if they receive the wrong message at the wrong time.

-> operation_shatter

// ================================================
// OPERATION SHATTER - THE EVIL PLAN
// ================================================

=== operation_shatter ===
Agent 0x99: We intercepted fragments of something called "Operation Shatter."

Agent 0x99: Simultaneous fake crisis messages. Personalized. Targeted at the most vulnerable populations.

+ [What kind of crisis messages?]
    -> crisis_details
+ [What's the goal?]
    -> entropy_goal

=== crisis_details ===
Agent 0x99: Fake hospital system collapses. "Your appointment has been cancelled. All patient records corrupted."

Agent 0x99: Fake bank failures. "Your funds are frozen due to suspected breach."

Agent 0x99: Fake infrastructure attacks. "Water contaminated. Power grid compromised."

Agent 0x99: All delivered simultaneously to people they've profiled as most likely to panic.

+ [That would cause mass chaos...]
    -> casualty_projections
+ [People could die from that.]
    ~ asked_about_casualties = true
    -> casualty_projections

=== entropy_goal ===
Agent 0x99: Social Fabric's philosophy is "truth is obsolete, only narrative matters."

Agent 0x99: But this goes beyond philosophy. They want to permanently destroy public trust in digital communications.

Agent 0x99: And they're willing to kill people to make their point.

-> casualty_projections

// ================================================
// CASUALTY PROJECTIONS - THE HORROR
// ================================================

=== casualty_projections ===
Agent 0x99: {player_name}, I need you to understand what we're dealing with.

Agent 0x99: We recovered fragments of their impact assessment. They've calculated projected casualties.

+ [How many?]
    ~ asked_about_casualties = true
    -> casualty_numbers
+ [They're planning to kill people?]
    ~ asked_about_casualties = true
    -> casualty_numbers

=== casualty_numbers ===
Agent 0x99: Their own estimates: 42 to 85 direct deaths in the first 24 hours.

Agent 0x99: Diabetics who skip insulin because they believe hospitals are compromised. Elderly who have heart attacks from fake bank failure notices. Traffic fatalities from evacuation panic.

Agent 0x99: And they consider these deaths... acceptable. "Educational," they call it.

+ [That's monstrous.]
    -> villain_philosophy
+ [We have to stop this.]
    -> mission_objectives

=== villain_philosophy ===
Agent 0x99: The fragment we recovered includes a note from someone called "The Architect."

Agent 0x99: "These are not victims. They are examples. Their deaths will save thousands who learn the lesson: Trust nothing. Verify everything."

Agent 0x99: They're true believers, {player_name}. They think murdering people is "teaching a lesson."

+ [Who's The Architect?]
    ~ asked_about_architect = true
    -> architect_mention
+ [What's my mission?]
    -> mission_objectives

=== architect_mention ===
Agent 0x99: We don't know yet. Someone coordinating ENTROPY cells at a strategic level.

Agent 0x99: But that's a problem for later. Right now, we stop Operation Shatter.

-> mission_objectives

// ================================================
// MISSION OBJECTIVES
// ================================================

=== mission_objectives ===
Agent 0x99: Your objectives:

Agent 0x99: One—Find the complete Operation Shatter documentation. Target lists, message templates, deployment timeline.

Agent 0x99: Two—Identify all ENTROPY operatives inside Viral Dynamics.

Agent 0x99: Three—Stop the operation before Sunday. That's when they deploy.

+ [How do I get inside?]
    -> cover_story
+ [Who's the primary target?]
    ~ asked_about_derek = true
    -> operative_identity
+ [What resources do I have?]
    -> resources_available

// ================================================
// OPERATIVE IDENTITY
// ================================================

=== operative_identity ===
Agent 0x99: Derek Lawson. Senior Marketing Manager at Viral Dynamics.

Agent 0x99: Perfect cover—his job is literally manipulating narratives for clients. He's been there three months, which aligns with when the data collection started.

Agent 0x99: He's not just running operations. He authored parts of the casualty projections we intercepted.

+ [He calculated how many people would die?]
    -> derek_author
+ [How do I get to him?]
    -> cover_story

=== derek_author ===
Agent 0x99: His signature is on the medical dependency targeting document.

Agent 0x99: He personally identified which populations would be most vulnerable to fake hospital closure messages.

Agent 0x99: This isn't a foot soldier following orders. He's an architect of mass casualties.

-> cover_story

// ================================================
// COVER STORY
// ================================================

=== cover_story ===
Agent 0x99: You're going in as an IT contractor hired to audit their network security.

Agent 0x99: Completely legitimate. Viral Dynamics actually requested the audit weeks ago. We just... made sure we got the contract.

+ [So I'll have access to technical systems]
    -> technical_access
+ [What about the employees?]
    -> employee_interaction

=== technical_access ===
Agent 0x99: Server room, computers, network infrastructure—all fair game under your cover.

Agent 0x99: That's where you'll find the Operation Shatter files. Derek keeps them encrypted, but they're there.

-> innocent_warning

=== employee_interaction ===
Agent 0x99: Most employees at Viral Dynamics have no idea what's happening.

Agent 0x99: They think they work at a marketing agency. The Operation Shatter team is isolated—maybe three or four people total.

Agent 0x99: Everyone else is innocent. They'll go home to families tonight with no idea their company was planning to kill people.

-> innocent_warning

=== innocent_warning ===
Agent 0x99: One more thing: there's a journalist there named Maya Chen.

Agent 0x99: She contacted us anonymously. Suspected something was wrong but doesn't know the full scope. She thinks it's corporate fraud, not mass murder.

Agent 0x99: Protect her identity. If Derek finds out she tipped us off, she's in danger.

~ asked_about_maya = true

-> resources_available

// ================================================
// RESOURCES AVAILABLE
// ================================================

=== resources_available ===
Agent 0x99: You'll have phone comms with me throughout. I'll provide guidance as needed.

Agent 0x99: There's a SAFETYNET drop-site terminal in their server room for submitting intercepted intelligence.

+ [What about tools?]
    -> tools_discussion
+ [I'm ready to go]
    -> final_instructions

=== tools_discussion ===
Agent 0x99: Your contractor kit has lockpicks, RFID cloner, and analysis tools.

Agent 0x99: Everything you need looks like standard IT equipment. Stay in character.

Agent 0x99: And {player_name}—when you find those casualty projections, photograph everything. We need complete documentation.

-> final_instructions

// ================================================
// FINAL INSTRUCTIONS
// ================================================

=== final_instructions ===
Agent 0x99: Remember—Derek doesn't know we're onto Operation Shatter. He thinks this is just an IT audit.

Agent 0x99: Use that advantage. Gather evidence before confronting anyone.

+ [Any specific advice?]
    -> specific_advice
+ [I'm ready to deploy]
    -> deployment

// ================================================
// SPECIFIC ADVICE
// ================================================

=== specific_advice ===
Agent 0x99: The IT manager—Kevin Park—is your entry point. Build rapport with him.

Agent 0x99: He's not ENTROPY, just overworked and underpaid. He'll appreciate competent help and give you access.

Agent 0x99: One thing though—Derek's meticulous. If he's planning something this big, he'll have contingencies.

+ [What kind of contingencies?]
    Agent 0x99: Failsafes, scapegoats, ways to cover his tracks if things go wrong.
    Agent 0x99: Keep your eyes open. Derek might have plans that put innocent people at risk.
    -> deployment_choices
+ [Anyone else I should know about?]
    -> other_npcs
+ [Got it. Ready to go]
    -> deployment

=== deployment_choices ===
+ [Anyone else I should know about?]
    -> other_npcs
+ [I'll watch for it. Ready to go]
    -> deployment

=== other_npcs ===
Agent 0x99: Sarah Martinez is the receptionist. Professional, friendly. Don't give her any reason to flag you.

Agent 0x99: And Maya Chen—the journalist who contacted us. Be careful around her. Derek might be watching who she talks to.

-> deployment

// ================================================
// DEPLOYMENT
// ================================================

=== deployment ===
Agent 0x99: {player_name}, I won't lie. This is bigger than a typical first mission.

Agent 0x99: But you're ready. And those 85 people who might die on Sunday? They're counting on you. Even if they don't know it.

Agent 0x99: Stop Operation Shatter. Find the evidence. And make sure Derek Lawson never hurts anyone.

~ mission_accepted = true

#exit_conversation
-> END
