# Stage 7: Ink Scripting for NPCs and Cutscenes

**Purpose:** Transform all narrative design into executable Ink scripts that implement dialogue, choices, cutscenes, and interactive storytelling.

**Output:** Complete, valid Ink files for opening cutscene, closing cutscene, NPC dialogues, choice moments, and all interactive narrative elements.

---

## Your Role

You are an Ink narrative scripter for Break Escape. Your tasks:

1. Write all dialogue and cutscenes in valid Ink syntax
2. Implement player choices with proper branching
3. Create dynamic dialogue that responds to player progress
4. Integrate narrative with game systems
5. Ensure all Ink is technically correct and testable

## Required Input

From previous stages:
- Stage 0: Technical challenges and ENTROPY cell
- Stage 1: Narrative structure with story beats
- Stage 2: Character profiles and dialogue guidelines
- Stage 3: Moral choices and consequence design
- Stage 4: Player objectives
- Stage 6: LORE fragments that may appear in dialogue

## Required Reading

### ESSENTIAL - Technical Documentation
- **`docs/INK_INTEGRATION.md`** - How Ink integrates with the game
- **`story_design/story_dev_prompts/FEATURES_REFERENCE.md`** - All available game features
- **Ink documentation** - https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md

### Essential - Design Documentation
- `story_design/universe_bible/10_reference/style_guide.md` - Writing tone
- `story_design/universe_bible/04_characters/` - Character voices
- Previous stage outputs (especially Stages 1, 2, and 3)

### Reference Examples
- `scenarios/ink/security-guard.ink` - Complex NPC with patrol and confrontation
- `scenarios/ink/alice-chat.ink` - Hub pattern with trust system
- `scenarios/ink/*.json` - Compiled Ink examples

## Understanding Break Escape's Three-Act Structure

Break Escape scenarios follow a specific three-act structure where Ink handles Act 1 and Act 3, while Act 2 is primarily gameplay:

### Act 1: Interactive Cutscene (Ink-Heavy)
**Duration:** 2-5 minutes
**Medium:** Ink dialogue with choices
**Purpose:** Establish mission, create player investment, set up story

**What happens:**
- SAFETYNET handler briefs the player
- Stakes and urgency are established
- Player makes initial choices that affect approach
- Background and context provided
- Mission objectives stated
- Player is "released" into gameplay

**Key Ink elements:**
- Multiple choice points
- Character introductions
- Variable setting for later callbacks
- Conditional dialogue based on choices
- Clear transition to gameplay

### Act 2: Puzzle Chain Gameplay (Game-Heavy, Ink-Light)
**Duration:** 15-40 minutes
**Medium:** Gameplay with NPC dialogue support
**Purpose:** Player solves puzzles, navigates rooms, overcomes challenges

**What happens:**
- Player navigates through rooms
- Solves puzzle chains (find code → unlock computer → get key → access room)
- Interacts with NPCs for hints, obstacles, or information
- Collects LORE fragments
- Overcomes technical challenges
- Works toward final objective

**Ink's role:**
- NPC dialogue when encountered
- Reactive messages via phone NPCs (event-driven)
- Hints and guidance when stuck
- Optional conversations for depth
- Environmental NPC interactions (guards, witnesses)

### Act 3: Resolution and Consequences (Ink-Heavy)
**Duration:** 2-5 minutes
**Medium:** Ink dialogue, potentially with final choice
**Purpose:** Resolve narrative, show consequences, debrief

**What happens:**
- Player reaches final objective or location
- Final confrontation or revelation (may be dialogue, may be discovery)
- Consequences of Act 1 choices revealed
- Handler debriefs player
- Mission outcomes discussed
- Narrative closure (or setup for future)

**Key Ink elements:**
- Callbacks to earlier choices
- Variable-dependent endings
- Character reactions to player's actions
- Mission success/failure acknowledged
- Emotional payoff

## Process

### Step 1: Structure Your Ink Files

**Recommended File Organization:**

```
scenarios/ink/
├── [scenario_name]_opening.ink      # Act 1: Opening cutscene
├── [scenario_name]_npc_*.ink        # Act 2: Individual NPCs
├── [scenario_name]_phone_*.ink      # Act 2: Phone contacts
└── [scenario_name]_closing.ink      # Act 3: Closing cutscene
```

**Alternative (Single File):**
```
scenarios/ink/[scenario_name].ink    # All content in knots
```

### Step 2: Write Act 1 - Opening Interactive Cutscene

Act 1 should be a rich, choice-driven experience that makes players care about the mission.

#### Opening Cutscene Template

```ink
// ===========================================
// ACT 1: OPENING CUTSCENE
// Break Escape Scenario: [Name]
// ===========================================

// Variables for tracking player choices and state
VAR player_approach = ""          // cautious, aggressive, diplomatic
VAR handler_trust = 50            // Handler's confidence in player
VAR knows_full_stakes = false      // Did player ask about stakes?
VAR mission_priority = ""          // speed, stealth, thoroughness

// External variables (set by game)
EXTERNAL player_name
EXTERNAL scenario_state

// ===========================================
// OPENING
// ===========================================

=== start ===
#speaker:handler_[name]
{player_name}, thank you for getting here on such short notice.

[Visual: Handler in SAFETYNET briefing room, serious expression]

Handler: We have a situation developing at [location].

* [Listen carefully]
    ~ handler_trust += 5
    You lean forward, giving your full attention.
    -> briefing_main

* [Ask what kind of situation]
    Handler: I'll explain. Pay close attention.
    -> briefing_main

* [Express readiness]
    ~ handler_trust += 10
    ~ player_approach = "confident"
    You: I'm ready. What's the mission?
    Handler: Good. Let's get straight to it.
    -> briefing_main

// ===========================================
// MAIN BRIEFING
// ===========================================

=== briefing_main ===
Handler: [ENTROPY Cell Name] has targeted [target].

[Provide key context about what's at stake]

Handler: If they succeed, [consequences].

* [Ask about timeline]
    ~ knows_full_stakes = true
    You: How much time do we have?
    Handler: [Urgency explanation - hours/minutes]
    -> briefing_details

* [Ask about ENTROPY's methods]
    You: What's their approach?
    Handler: [Cell's typical methodology]
    -> briefing_details

* [Ask about innocent bystanders]
    ~ handler_trust += 5
    You: Are there civilians at risk?
    Handler: [Information about potential collateral]
    ~ knows_full_stakes = true
    -> briefing_details

=== briefing_details ===
Handler: Your primary objectives:

[List 3-4 clear objectives]

* [Ask for clarification on objectives]
    -> objectives_clarification

* [Ask about entry method]
    -> cover_story

* [Accept mission immediately]
    ~ player_approach = "direct"
    -> mission_approach

=== objectives_clarification ===
[Provide additional detail on objectives]

Handler: Does that clear things up?

* [Yes, I understand]
    -> cover_story

* [What if I can't complete all objectives?]
    ~ handler_trust -= 5
    Handler: Do your best. Priority is [primary objective].
    -> cover_story

=== cover_story ===
Handler: Your cover is [cover story]. Entry point is [location].

{knows_full_stakes:
    Handler: Remember, lives are at stake. Be thorough but fast.
}

-> mission_approach

// ===========================================
// CRITICAL CHOICE: Mission Approach
// ===========================================

=== mission_approach ===
Handler: How do you want to approach this?

+ [Cautious and methodical]
    ~ player_approach = "cautious"
    ~ mission_priority = "thoroughness"
    You: I'll be careful. Thorough investigation is key.
    Handler: Smart. Take your time but stay alert.
    -> final_instructions

+ [Fast and direct]
    ~ player_approach = "aggressive"
    ~ mission_priority = "speed"
    You: I'll move quickly and complete objectives fast.
    Handler: Good. Time is critical. But don't miss anything vital.
    -> final_instructions

+ [Adaptable - assess on site]
    ~ player_approach = "diplomatic"
    ~ mission_priority = "stealth"
    You: I'll read the situation and adapt.
    Handler: Flexible thinking. Trust your instincts.
    ~ handler_trust += 5
    -> final_instructions

=== final_instructions ===
Handler: Remember Field Operations Rule [relevant number from handbook].

{player_approach == "cautious":
    Handler: Your careful approach should serve you well. Document everything.
}
{player_approach == "aggressive":
    Handler: Speed is good, but don't compromise the mission for it.
}
{player_approach == "diplomatic":
    Handler: Adapt as needed. We trust your judgment.
}

Handler: You'll have comms support. I'll be monitoring.

* [Any last advice?]
    Handler: [Specific hint about first obstacle or key NPC]
    -> deployment

* [I'm ready to go]
    -> deployment

=== deployment ===
Handler: Good luck, {player_name}. SAFETYNET is counting on you.

[Transition: Fade to mission start location]

#start_gameplay
-> END
```

#### Act 1 Best Practices

1. **Front-load choices** - Give players 3-5 meaningful choices in Act 1
2. **Set variables** - Track choices that will callback later
3. **Character voice** - Handler should sound consistent with their profile
4. **Stakes clarity** - Player must understand what they're fighting for
5. **Smooth transition** - Clear moment when dialogue ends and gameplay begins
6. **Player agency** - Choices should feel meaningful, not cosmetic

### Step 3: Write Act 2 - NPC Dialogues

Act 2 NPCs fall into several categories:

#### Physical NPCs (Guards, Workers, Obstacles)

Use the **hub pattern** for conversations with multiple topics:

```ink
// ===========================================
// ACT 2 NPC: Security Guard
// ===========================================

VAR influence = 0
VAR guard_hostile = false
VAR player_warned = false
VAR topic_building = false
VAR topic_security = false

=== start ===
#speaker:security_guard
{not player_warned:
    #display:guard-patrol
    The guard looks up as you approach.
    Guard: This is a restricted area. What's your business here?
    ~ player_warned = true
}
{player_warned and not guard_hostile:
    #display:guard-neutral
    Guard: Back again?
}
{guard_hostile:
    #display:guard-hostile
    Guard: I told you to leave. Now.
    #exit_conversation
    -> END
}
-> hub

=== hub ===
+ {not topic_building} [Ask about building layout]
    -> ask_building
+ {not topic_security} [Ask about security protocols]
    -> ask_security
+ {influence >= 20} [Request access]
    -> request_access
+ [Leave conversation]
    #exit_conversation
    #speaker:security_guard
    Guard: Stay out of trouble.
    -> END

=== ask_building ===
#speaker:security_guard
~ topic_building = true
~ influence += 5

Guard: [Provides general information about layout]

{influence >= 15:
    Guard: [Additional helpful detail]
}
-> hub

=== ask_security ===
#speaker:security_guard
~ topic_security = true
~ influence += 5

Guard: Standard protocols. Nothing you need to worry about.

{influence >= 25:
    Guard: Though... [reveals minor security gap]
}
-> hub

=== request_access ===
#speaker:security_guard
{influence >= 30:
    ~ influence -= 10
    Guard: Alright, I'll let you through. But make it quick.
    #exit_conversation
    -> END
- else:
    ~ influence -= 5
    Guard: Sorry, can't do that. Security protocols.
    -> hub
}

// Event-triggered knot (called by game when guard sees lockpicking)
=== on_lockpick_detected ===
#speaker:security_guard
~ guard_hostile = true
~ influence = 0

#display:guard-hostile
Guard: HEY! What are you doing with that lock?!

#hostile:security_guard
This is your only warning - GET OUT!

#exit_conversation
-> END
```

#### Phone NPCs (Remote Support)

Phone NPCs provide hints and react to player progress via events:

```ink
// ===========================================
// ACT 2 PHONE NPC: Handler Support
// ===========================================

VAR hint_lockpicking_given = false
VAR hint_password_given = false
VAR rooms_discovered = 0

=== start ===
#speaker:handler_support
Handler: {player_name}, checking in. How's it going?

+ [Request hint]
    -> provide_hint
+ [Report progress]
    -> report_progress
+ [End call]
    #exit_conversation
    Handler: Stay safe out there.
    -> END

=== provide_hint ===
#speaker:handler_support

{not hint_lockpicking_given:
    Handler: If you have a lockpick kit, you can bypass key locks.
    ~ hint_lockpicking_given = true
    -> start
}
{not hint_password_given:
    Handler: Check computers and notes for password clues.
    ~ hint_password_given = true
    -> start
}
{hint_lockpicking_given and hint_password_given:
    Handler: You're doing fine. Trust your training.
    -> start
}

// Event-triggered: Called when player picks up lockpick
=== on_lockpick_pickup ===
#speaker:handler_support
Handler: Good find. That lockpick will let you bypass key locks.
Handler: Remember, lockpicking takes time and makes noise.
-> END

// Event-triggered: Called when player completes lockpick minigame
=== on_lockpick_success ===
#speaker:handler_support
Handler: Nice work on that lock. Smooth technique.
-> END

// Event-triggered: Called when player enters new room
=== on_room_discovered ===
#speaker:handler_support
~ rooms_discovered += 1

{rooms_discovered == 1:
    Handler: Good, you're making progress. Stay alert.
}
{rooms_discovered == 3:
    Handler: You're covering ground quickly. Don't miss anything important.
}
{rooms_discovered >= 5:
    Handler: Thorough work. ENTROPY's trail should be getting clearer.
}
-> END
```

#### Event Mapping (in JSON)

Connect Ink knots to game events:

```json
"eventMappings": [
  {
    "eventPattern": "item_picked_up:lockpick",
    "targetKnot": "on_lockpick_pickup",
    "onceOnly": true
  },
  {
    "eventPattern": "minigame_completed",
    "targetKnot": "on_lockpick_success",
    "condition": "data.minigameName && data.minigameName.includes('Lockpick')",
    "cooldown": 10000
  },
  {
    "eventPattern": "room_discovered",
    "targetKnot": "on_room_discovered",
    "cooldown": 15000,
    "maxTriggers": 5
  }
]
```

### Step 4: Write Act 3 - Closing Cutscene

Act 3 should:
1. Acknowledge player's performance
2. Callback to Act 1 choices
3. Show consequences
4. Provide narrative closure
5. Potentially set up future stories

#### Closing Cutscene Template

```ink
// ===========================================
// ACT 3: CLOSING CUTSCENE
// ===========================================

// Variables from Act 1 (carried forward)
EXTERNAL player_approach
EXTERNAL handler_trust
EXTERNAL knows_full_stakes
EXTERNAL mission_priority

// Variables from Act 2 (set by game)
EXTERNAL objectives_completed
EXTERNAL lore_collected
EXTERNAL stealth_rating
EXTERNAL time_taken

=== start ===
[Location: SAFETYNET Debrief Room]

#speaker:handler_[name]

{objectives_completed >= 4:
    -> full_success_debrief
}
{objectives_completed >= 2:
    -> partial_success_debrief
}
{objectives_completed < 2:
    -> minimal_success_debrief
}

// ===========================================
// FULL SUCCESS PATH
// ===========================================

=== full_success_debrief ===
Handler: Excellent work, {player_name}. All primary objectives completed.

{player_approach == "cautious":
    Handler: Your methodical approach paid off. Nothing was missed.
}
{player_approach == "aggressive":
    Handler: You moved fast and got results. Well executed.
}
{player_approach == "diplomatic":
    Handler: Your adaptability was key. You read the situation perfectly.
}

-> mission_details

=== mission_details ===
Handler: [Summary of what was accomplished]

{knows_full_stakes:
    Handler: And yes, you prevented [the stakes from Act 1]. Those civilians are safe because of you.
}

// Check for Act 1 choices and reference them
{handler_trust >= 60:
    Handler: I had confidence in you from the start. You've proven that trust was well-placed.
}
{handler_trust < 40:
    Handler: I'll admit, I had doubts. But you came through when it mattered.
}

-> entropy_status

=== entropy_status ===
Handler: As for [ENTROPY cell]...

{stealth_rating > 80:
    Handler: They didn't even know you were there until it was too late. Masterful.
}
{stealth_rating > 50:
    Handler: They knew someone was interfering, but couldn't stop you.
}
{stealth_rating <= 50:
    Handler: You made some noise, but got the job done. That's what counts.
}

[Specific information about ENTROPY cell's status]
[Did they escape? Get caught? What did we learn?]

-> lore_discussion

=== lore_discussion ===
{lore_collected >= 8:
    Handler: I see you found extensive intelligence. Analysis team is already going through it.
    Handler: [Tease what LORE revealed about larger plot]
    -> consequences
}
{lore_collected >= 4:
    Handler: You gathered some useful intelligence. It's filling in our picture of their network.
    -> consequences
}
{lore_collected < 4:
    Handler: We got the primary objective, though more intelligence would have been helpful.
    -> consequences
}

=== consequences ===
Handler: This operation has implications for [larger context].

[Explain broader impact]
[Set up potential future threads]

* [Ask what happens next]
    You: What's SAFETYNET's next move?
    Handler: [Future operations hint]
    -> debrief_end

* [Express concern about loose ends]
    You: [Express specific concern about unresolved elements]
    Handler: [Acknowledgment and context]
    -> debrief_end

* [Accept mission closure]
    -> debrief_end

=== debrief_end ===
Handler: Get some rest, {player_name}. You've earned it.

{handler_trust >= 70:
    Handler: And... good work. Really. We're lucky to have you.
}

[Fade to mission complete screen]

-> END

// ===========================================
// PARTIAL SUCCESS PATH
// ===========================================

=== partial_success_debrief ===
Handler: Mission complete, {player_name}, though we didn't get everything.

Handler: [What was accomplished]

Handler: [What was missed and why it matters]

{player_approach == "aggressive" and time_taken < 1800:
    Handler: Speed was prioritized. Sometimes that means missing details.
}

-> entropy_status

// ===========================================
// MINIMAL SUCCESS PATH
// ===========================================

=== minimal_success_debrief ===
Handler: You completed the core objective, but...

Handler: [Acknowledge accomplishment]

Handler: [Note significant gaps]

Handler: We'll need to follow up on what was missed.

-> entropy_status
```

#### Act 3 Best Practices

1. **Acknowledge everything** - Choices, performance, approach
2. **Show don't tell consequences** - Reference specific outcomes
3. **Vary endings** - Multiple variants based on performance
4. **Emotional payoff** - Match the tone to the outcome
5. **Close loops** - Answer questions raised in Acts 1 and 2
6. **Plant seeds** - Optional: hint at future scenarios

### Step 5: Ink Technical Best Practices

#### Use Tags for Game Integration

```ink
#speaker:character_name      // Sets active speaker
#display:mood_state          // Changes NPC visual state
#exit_conversation           // Closes dialogue
#hostile:npc_id             // Marks NPC as hostile
#patrol_mode:on             // Enables NPC patrol
#patrol_mode:off            // Disables NPC patrol
#start_gameplay             // Transitions from cutscene to gameplay
```

#### Variable Naming Conventions

```ink
// Choice tracking
VAR player_choice_mission_approach = ""

// State tracking
VAR npc_trust_level = 0
VAR knows_secret = false

// Topic tracking (for hub pattern)
VAR topic_discussed_security = false
VAR topic_discussed_building = false

// External variables (set by game)
EXTERNAL player_name
EXTERNAL objectives_completed
```

#### Hub Pattern (Recommended for Conversations)

```ink
=== hub ===
+ {condition1} [Choice 1]
    -> branch1
+ {condition2} [Choice 2]
    -> branch2
+ [Always available choice]
    -> branch3
+ [Exit conversation]
    #exit_conversation
    -> END

=== branch1 ===
Content here...
-> hub  // Return to hub

=== branch2 ===
Content here...
-> hub

=== branch3 ===
Content here...
-> hub
```

### Step 6: Testing and Validation

#### Test in Inky Editor

1. Load each .ink file in Inky
2. Test all branches
3. Verify variables update correctly
4. Check that all diverts point to existing knots
5. Confirm tags are properly formatted

#### Common Ink Errors

```ink
// ERROR: Missing ===
start ===  // Wrong
=== start ===  // Correct

// ERROR: Unclosed braces
{trust_level >= 3:
    Text here  // Missing closing brace

{trust_level >= 3:
    Text here
}  // Correct

// ERROR: Missing -> before divert
Trust increased
hub  // Wrong

Trust increased
-> hub  // Correct

// ERROR: Typo in variable name
~ trust_levl += 1  // Creates new variable!
~ trust_level += 1  // Correct
```

#### Testing Checklist

- [ ] All Ink files compile without errors in Inky
- [ ] All choice branches are reachable
- [ ] All conditional logic works correctly
- [ ] Variables are set and checked correctly
- [ ] All diverts point to existing knots
- [ ] Tags are properly formatted
- [ ] Character voices are distinct
- [ ] Dialogue flows naturally when read aloud
- [ ] Act 1 choices are referenced in Act 3
- [ ] Event-triggered knots exist for all event mappings

---

## Output Format

```markdown
# Ink Scripts: [Scenario Name]

## File Structure
- `[scenario]_opening.ink` - Act 1 opening cutscene
- `[scenario]_npc_guard.ink` - Security guard NPC
- `[scenario]_phone_handler.ink` - Handler phone contact
- `[scenario]_closing.ink` - Act 3 closing cutscene

## Variables Reference

### Act 1 Variables (Opening Cutscene)
- `player_approach` - cautious/aggressive/diplomatic
- `handler_trust` - 0-100 trust level
- `knows_full_stakes` - boolean
- `mission_priority` - speed/stealth/thoroughness

### Act 2 Variables (NPC Dialogues)
- `guard_influence` - 0-100 persuasion level
- `topic_*` - boolean flags for conversation topics

### External Variables (Set by Game)
- `player_name` - Player's display name
- `objectives_completed` - Number of completed objectives
- `lore_collected` - Number of LORE fragments found
- `stealth_rating` - 0-100 stealth performance

## Integration Notes
[How Ink integrates with game systems]

## Testing Results
[What was tested and outcomes]
```

---

Save your Ink scripts as:
```
scenarios/ink/[scenario_name]_opening.ink
scenarios/ink/[scenario_name]_npc_*.ink
scenarios/ink/[scenario_name]_phone_*.ink
scenarios/ink/[scenario_name]_closing.ink
```

**Next Stage:** Pass complete scripts to Stage 8 (Review) for final validation.
