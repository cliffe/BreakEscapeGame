# Ink Best Practices for Break Escape

This document outlines the patterns and best practices we use for Ink scripting in Break Escape.

## Table of Contents
1. [Hub Architecture](#hub-architecture)
2. [Influence Tags System](#influence-tags-system)
3. [External Functions](#external-functions)
4. [Variable Persistence](#variable-persistence)
5. [Common Patterns](#common-patterns)

---

## Hub Architecture

### Mission Hub Pattern

Every NPC hub file uses a standardized `mission_hub` knot that serves as the central routing point. This is **internal architecture** (not visible to players) that enables seamless conversation flow.

```ink
=== npc_conversation_entry ===
// Initial greeting based on location
{
    - npc_location() == "lab":
        Dr. Chen: Hey! What brings you by?
    - else:
        Dr. Chen: Hello!
}
-> mission_hub

=== mission_hub ===
// Central routing point - routes to personal or mission topics
+ [Personal chat] -> jump_to_personal_conversations
+ [Mission briefing] -> mission_briefing
+ [Equipment check] -> equipment_discussion
```

**Key Benefits:**
- Personal conversations can `#exit_conversation` and return to `mission_hub`
- Mission topics return to `mission_hub` after completion
- Player sees continuous conversation, game manages routing

### How #end_conversation Works

When personal conversations end, they use `#end_conversation` tag and return to mission_hub:

```ink
=== conversation_end ===
Dr. Chen: Great talking with you!
#end_conversation
-> mission_hub
```

**What happens:**
1. Ink script diverts to `mission_hub` - **preserving conversation state**
2. Game code detects `#end_conversation` tag and closes the UI
3. Next time player talks to this NPC, conversation resumes from `mission_hub`
4. NPC remembers where they left off, can offer new mission/personal topics

**Why this matters:**
- ✅ **State preservation** - Conversation picks up where it left off
- ✅ **Flexible re-entry** - Player can talk to NPC multiple times in a session
- ✅ **Context awareness** - Hub can show different options based on what was discussed

---

## Influence Tags System

### Visual Feedback for Relationship Changes

Every time an NPC's influence/rapport/respect/friendship changes, add a tag for visual feedback to the player.

### Tag Format

```ink
// Variable change
~ npc_chen_rapport += 5

// Visual feedback tag (on next line)
#rapport_gained:5
```

### Available Tags

**Positive Changes:**
- `#rapport_gained:X` - Dr. Chen likes this (+X rapport)
- `#respect_gained:X` - Director Netherton approves (+X respect)
- `#friendship_gained:X` - Haxolottle appreciates this (+X friendship)
- `#influence_gained:X` - Generic influence increase

**Negative Changes:**
- `#rapport_lost:X` - Dr. Chen is disappointed (-X rapport)
- `#respect_lost:X` - Director Netherton disapproves (-X respect)
- `#friendship_lost:X` - Haxolottle is hurt (-X friendship)
- `#influence_lost:X` - Generic influence decrease

### Complete Example

```ink
=== helpful_conversation ===
You: I want to understand the tech better.
Dr. Chen: That's great! Let me explain...

// Small rapport gain for showing interest
~ npc_chen_rapport += 3
#rapport_gained:3

+ [Ask follow-up questions]
    You: Can you tell me more?
    Dr. Chen: Of course! *enthusiastically explains*

    // Larger rapport gain for deeper engagement
    ~ npc_chen_rapport += 8
    #rapport_gained:8

+ [Dismiss the explanation]
    You: Never mind, not important.
    Dr. Chen: Oh... okay. *slightly hurt*

    // Lose rapport for being dismissive
    ~ npc_chen_rapport -= 5
    #rapport_lost:5
```

### Visual Feedback Messages

The game displays context-appropriate messages based on the tag:

| Tag | Small Change (<10) | Large Change (≥10) |
|-----|-------------------|-------------------|
| `#rapport_gained` | "Dr. Chen appreciates that" | "Dr. Chen likes that" |
| `#rapport_lost` | "Dr. Chen is uncertain" | "Dr. Chen is disappointed" |
| `#respect_gained` | "Director Netherton approves" | "Director Netherton is impressed" |
| `#respect_lost` | "Director Netherton notes this" | "Director Netherton is displeased" |
| `#friendship_gained` | "Haxolottle likes that" | "Haxolottle really appreciates that" |
| `#friendship_lost` | "Haxolottle seems disappointed" | "Haxolottle is hurt" |

### When to Use Influence Tags

**Add influence changes (and tags) for:**
- Player choices that show emotional intelligence
- Showing interest in NPC's personal life
- Professional competence or incompetence
- Trust-building moments
- Humor and shared experiences
- Vulnerability and openness
- Dismissive or insensitive responses (negative)

**Frequency:**
- Small changes (±2-5): Frequent, for minor positive/negative interactions
- Medium changes (±5-10): For meaningful choices and conversations
- Large changes (±10-15): For major trust moments or significant breaches

**Example Flow:**
```ink
=== deep_conversation ===
Haxolottle: I lost an agent six months ago. Still think about them.

+ [Express sympathy]
    You: I'm so sorry. That must be really hard.
    Haxolottle: Thanks. It helps to talk about it.
    ~ npc_haxolottle_friendship_level += 10
    #friendship_gained:10
    -> conversation_continues

+ [Ask tactical questions only]
    You: What was the mission profile?
    Haxolottle: *pause* ...Let's focus on your current operation.
    ~ npc_haxolottle_friendship_level -= 3
    #friendship_lost:3
    -> conversation_continues

+ [Share your own loss]
    You: I understand. I've lost people too.
    Haxolottle: *eyes soften* Yeah. You get it.
    ~ npc_haxolottle_friendship_level += 15
    #friendship_gained:15
    ~ npc_haxolottle_shared_loss = true
    -> deeper_connection
```

---

## External Functions

### Required External Functions for NPC Hubs

All NPC hub files require these EXTERNAL function declarations:

```ink
EXTERNAL player_name()           // Returns player's agent name
EXTERNAL current_mission_id()    // Returns active mission ID
EXTERNAL npc_location()          // Where conversation happens
EXTERNAL mission_phase()         // Planning/active/debriefing/downtime
```

### NPC-Specific External Functions

**For Dr. Chen (tech specialist):**
```ink
EXTERNAL equipment_status()      // nominal/damaged/needs_upgrade
```

**For Haxolottle (handler):**
```ink
EXTERNAL operational_stress_level()  // low/moderate/high/crisis
```

### Usage in Conditionals

```ink
// Correct - call with parentheses
{player_name() == "Shadow":
    Dr. Chen: Welcome back, Shadow!
}

// Correct - in dialogue
Dr. Chen: Hey there, {player_name()}!

// Correct - conditional branching
{
    - mission_phase() == "active":
        Dr. Chen: Not now, I'm tracking your mission!
    - mission_phase() == "downtime":
        Dr. Chen: Got time to chat?
}
```

---

## Variable Persistence

### Three-Tier Variable System

**1. PERSISTENT Variables** - Saved across all game sessions
```ink
VAR PERSISTENT npc_chen_rapport = 0
VAR PERSISTENT total_missions_completed = 0
VAR PERSISTENT npc_haxolottle_talked_axolotls = false
```

**2. GLOBAL Variables** - Persist within current session only
```ink
VAR npc_current_conversation_topic = ""
VAR temporary_mission_flag = false
```

**3. EXTERNAL Variables** - Provided by game engine
```ink
EXTERNAL player_name()
EXTERNAL mission_phase()
```

### Naming Conventions

```ink
// Persistent relationship variables
VAR PERSISTENT npc_chen_rapport = 0              // Dr. Chen's relationship
VAR PERSISTENT npc_netherton_respect = 0          // Netherton's respect
VAR PERSISTENT npc_haxolottle_friendship_level = 0 // Haxolottle's friendship

// Conversation flags (has this topic been discussed?)
VAR PERSISTENT npc_chen_talked_childhood = false
VAR PERSISTENT npc_netherton_discussed_handbook = false

// Shared experiences
VAR PERSISTENT npc_haxolottle_humor_shared = 0    // Count of jokes shared
VAR PERSISTENT npc_chen_projects_collaborated = 0  // Projects worked on together
```

---

## Common Patterns

### Has Available Topics Pattern

Use functions to check if there are topics available:

```ink
=== function has_available_personal_topics() ===
// Check if any personal topics are available
{
    - total_missions_completed <= 5:
        // Phase 1 topics
        {
            - not npc_chen_talked_childhood: ~ return true
            - not npc_chen_talked_motivation: ~ return true
            - else: ~ return false
        }
    - total_missions_completed <= 10:
        // Phase 2 topics
        {
            - not npc_chen_shared_doubt and npc_chen_rapport >= 40: ~ return true
            - not npc_chen_talked_research and npc_chen_rapport >= 30: ~ return true
            - else: ~ return false
        }
    - else:
        ~ return false
}

// Usage in hub
+ {has_available_personal_topics()} [Chat personally with Dr. Chen]
    -> jump_to_personal_conversations
```

### Jump to Phase Pattern

Route to appropriate phase based on mission progress:

```ink
=== jump_to_personal_conversations ===
{
    - total_missions_completed <= 5:
        -> phase_1_hub
    - total_missions_completed <= 10:
        -> phase_2_hub
    - total_missions_completed <= 15:
        -> phase_3_hub
    - total_missions_completed > 15:
        -> phase_4_hub
}
```

### Conversation End Pattern

Always end personal conversations by returning to mission_hub:

```ink
=== conversation_end ===
{
    - npc_chen_rapport >= 70:
        Dr. Chen: Always a pleasure, {player_name()}!
    - npc_chen_rapport >= 50:
        Dr. Chen: Thanks for the chat.
    - else:
        Dr. Chen: Talk later.
}

#end_conversation
-> mission_hub
```

**Important:** The divert to `mission_hub` preserves state. The `#end_conversation` tag signals the UI to close. Next interaction resumes from the hub with full context.

### Conditional Relationship Responses

Vary NPC responses based on relationship level:

```ink
=== greeting ===
{
    - npc_haxolottle_friendship_level >= 70:
        Haxolottle: {player_name()}! *genuine smile* Always good to see you.
    - npc_haxolottle_friendship_level >= 40:
        Haxolottle: Hey {player_name()}. What's up?
    - npc_haxolottle_friendship_level >= 20:
        Haxolottle: Agent {player_name()}. Need something?
    - else:
        Haxolottle: Agent. What do you need?
}
```

### Gated Content Pattern

Lock topics behind relationship thresholds:

```ink
+ {npc_netherton_respect >= 60 and not npc_netherton_shared_past}
    [Ask about Netherton's field days]
    -> netherton_field_stories

+ {npc_chen_rapport >= 80 and not npc_chen_shared_doubts}
    [Notice Dr. Chen seems troubled]
    -> chen_vulnerability_moment
```

### Multi-Choice Influence Pattern

Give players meaningful choices with different influence outcomes:

```ink
=== difficult_question ===
Netherton: Do you think the ends justify the means?

+ [Agree completely]
    You: Always. Results matter more than methods.
    Netherton: *approving nod* Practical thinking.
    ~ npc_netherton_respect += 10
    #respect_gained:10

+ [Disagree completely]
    You: No. How we achieve our goals defines who we are.
    Netherton: *slight frown* Idealistic. But noted.
    ~ npc_netherton_respect -= 5
    #respect_lost:5

+ [It's complicated]
    You: It depends on the situation and the stakes.
    Netherton: *considering* Nuanced. Good.
    ~ npc_netherton_respect += 5
    #respect_gained:5
```

---

## Quick Reference

### Checklist for New NPC Conversations

- [ ] Declare all EXTERNAL functions at top of hub file
- [ ] Use `mission_hub` knot as central routing point
- [ ] End personal conversations with `#end_conversation` and `-> mission_hub`
- [ ] Add influence tags after every relationship variable change
- [ ] Use `has_available_personal_topics()` function
- [ ] Implement phase-based content routing
- [ ] Gate advanced topics behind relationship thresholds
- [ ] Include context-aware greetings based on location
- [ ] Vary dialogue tone based on relationship level
- [ ] Test compilation with inklecate

### Common Mistakes to Avoid

❌ **Wrong:**
```ink
{player_name}           // Missing parentheses
~ npc_chen_rapport += 5 // No visual feedback tag
-> chen_hub             // Non-standard hub name
#exit_conversation      // Old tag name
-> END                  // Doesn't preserve state
```

✅ **Correct:**
```ink
{player_name()}         // External function with parentheses
~ npc_chen_rapport += 5 // Variable change
#rapport_gained:5       // Visual feedback tag
-> mission_hub          // Standard hub knot name
#end_conversation       // Correct tag to close UI
-> mission_hub          // Preserves state for next interaction
```

---

## Examples by NPC Type

### Dr. Chen (Technical Specialist)
- **Rapport** variable for relationship
- **Equipment-focused** mission content
- **Enthusiasm** in dialogue for high rapport
- **Collaborative** personal conversations

### Director Netherton (Authority Figure)
- **Respect** variable for relationship
- **Strategic** mission content
- **Professional distance** that slowly softens
- **Rare vulnerability** at high respect levels

### Haxolottle (Handler/Support)
- **Friendship** variable for relationship
- **Real-time support** during missions
- **Humor and references** (axolotls, regeneration metaphors)
- **Trust built through** shared operational stress

---

## File Checklist

When creating a new NPC:

1. **Hub File** (`npc_hub.ink`)
   - [ ] EXTERNAL function declarations
   - [ ] `npc_conversation_entry` knot
   - [ ] `mission_hub` knot
   - [ ] INCLUDE statements for personal and mission files
   - [ ] Context-aware option routing

2. **Personal Conversations File** (`npc_ongoing_conversations.ink`)
   - [ ] PERSISTENT relationship variables
   - [ ] Phase hubs (phase_1_hub through phase_4_hub)
   - [ ] `has_available_personal_topics()` function
   - [ ] `jump_to_personal_conversations` knot
   - [ ] `conversation_end` knot with `#end_conversation` and `-> mission_hub`
   - [ ] Influence tags on all relationship changes

3. **Mission-Specific Files** (optional, `npc_mission_*.ink`)
   - [ ] Mission-specific support content
   - [ ] Return to `mission_hub` after completion
   - [ ] Contextual dialogue based on mission phase
