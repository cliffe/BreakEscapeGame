# Mission 1: First Contact - Intel Threads Summary

## Overview
This document outlines how incomplete intel from NPCs leads to evidence discovery through player investigation and correlation. The informant (Agent 0x99) and NPCs provide **fragments** rather than complete solutions, requiring the player to piece together the full picture.

---

## Design Philosophy

### Old Approach (Problematic)
- Agent 0x99 gave exact command syntax (e.g., `hydra -l username -P passwordlist.txt ssh://target`)
- Maya revealed Derek's office code directly (0419)
- Kevin stated "Derek uses his birthday in passwords"
- All evidence locations explicitly stated
- Complete tactical walkthrough provided

### New Approach (Discovery-Based)
- NPCs provide **hints and fragments** that point toward evidence
- Players must **explore, observe, and correlate** information
- Multiple sources provide pieces of the puzzle
- Technical knowledge must be **discovered or researched**
- Evidence locations hinted at, not explicitly stated

---

## Intel Thread #1: Derek's Password/Office Code (0419)

### Evidence Trail

#### Fragment 1: Kevin (NPC) - Password Pattern Hint
**Location:** IT Room conversation
**Intel Provided:**
- "Birthdays and anniversaries—classic weak passwords"
- "Derek's one of the worst. Important dates everywhere—sticky notes, calendar reminders, password hints"
- "If you know someone's personal calendar, you can probably guess their passwords"

**What Player Learns:** Derek uses important dates, but WHICH date is not specified.

#### Fragment 2: Office Environment - Calendar/Notes
**Location:** Derek's office (physical environment)
**Intel Provided:**
- Calendar on desk/wall with anniversary marked (April 19)
- Sticky notes with "0419" references
- Personal items suggesting the date

**What Player Learns:** The specific date (0419) that Derek uses.

#### Fragment 3: Correlation
**Action Required:** Player must:
1. Talk to Kevin to learn Derek uses "important dates"
2. Gain access to Derek's office
3. Observe calendar/notes to find 0419
4. Apply this code to filing cabinet, computer login, etc.

**Evidence Unlocked:** Filing cabinet contents, computer files, contingency plans

---

## Intel Thread #2: SSH Access & Password Lists

### Evidence Trail

#### Fragment 1: Agent 0x99 (Handler) - General Guidance
**Location:** Phone support
**Intel Provided:**
- "SSH access requires credentials"
- "Look for patterns in the environment"
- "People reuse dates, company names, personal information"
- "There are tools for testing multiple passwords" (mentions tools exist but not specific commands)

**What Player Learns:** Need to build wordlist from environmental clues, tools exist to test them.

#### Fragment 2: Kevin (NPC) - Company Password Patterns
**Location:** IT Room conversation
**Intel Provided:**
- "Company name variations are popular. 'ViralDynamics' plus numbers or years"
- People use patterns

**What Player Learns:** "ViralDynamics2025" and variations are likely passwords.

#### Fragment 3: Environment - Whiteboards/Notes
**Location:** Office areas, IT room
**Intel Provided:**
- Whiteboard with "ViralDynamics2025" written
- Notes mentioning company password policies
- Year references (2025)

**What Player Learns:** Specific password variations to try.

#### Fragment 4: Research/Discovery
**Action Required:** Player must:
1. Learn about Hydra tool (through research or experimentation)
2. Build password wordlist from gathered intel
3. Identify target systems (server room VMs)
4. Execute SSH brute force

**Evidence Unlocked:** VM access, flags, encrypted files

---

## Intel Thread #3: Linux Navigation & Hidden Files

### Evidence Trail

#### Fragment 1: Agent 0x99 - General Concepts
**Location:** Phone support
**Intel Provided:**
- "User directories contain personal files, configurations"
- "Not everything is visible at first glance. Look deeper"
- "Think like an investigator. Where would someone hide information?"

**What Player Learns:** Hidden files exist, user directories important, need to look carefully.

#### Fragment 2: VM Environment - Discovery
**Location:** Linux VMs in server room
**Intel Provided:**
- Directory structure to explore
- Hidden files (dotfiles) containing flags/evidence

**What Player Learns:** Specific commands (`ls -la`) and locations through experimentation.

#### Fragment 3: Research/Experimentation
**Action Required:** Player must:
1. Learn basic Linux commands (ls, cd, cat) through experimentation or research
2. Discover hidden files concept
3. Explore methodically to find flags

**Evidence Unlocked:** Flags in user directories, .bashrc files, hidden config files

---

## Intel Thread #4: Privilege Escalation

### Evidence Trail

#### Fragment 1: Agent 0x99 - General Concept
**Location:** Phone support
**Intel Provided:**
- "Privilege escalation means gaining access to other accounts"
- "Linux systems have permissions allowing users to execute commands or access other accounts"
- "Investigate what capabilities your current account has"

**What Player Learns:** Concept exists, need to investigate current account permissions.

#### Fragment 2: VM Environment - Discovery
**Location:** Linux VMs
**Intel Provided:**
- `sudo -l` command results showing permissions
- Ability to switch users

**What Player Learns:** Specific commands and techniques through experimentation.

#### Fragment 3: Research/Experimentation
**Action Required:** Player must:
1. Learn about sudo command
2. Discover `sudo -l` to check permissions
3. Learn `sudo -u username bash` syntax
4. Execute privilege escalation

**Evidence Unlocked:** Additional user accounts, higher-level flags, sensitive files

---

## Intel Thread #5: Operation Shatter Discovery

### Evidence Trail

#### Fragment 1: Maya (NPC) - Suspicious Overheard Info
**Location:** Office conversation
**Intel Provided:**
- "Infrastructure targeting. Phase 3 timeline. Network mapping."
- "Once I heard him mention something called 'Operation Shatter' on a call"
- "Marketing campaign name, maybe?"

**What Player Learns:** Derek is involved in something called "Operation Shatter" but unclear what it is.

#### Fragment 2: Kevin (NPC) - Derek's Suspicious Behavior
**Location:** IT Room conversation
**Intel Provided:**
- Derek requesting "enhanced privacy" for his systems
- Server room access at unusual times
- Separate network segments

**What Player Learns:** Derek is hiding something and has unusual technical setup.

#### Fragment 3: Physical Evidence - Derek's Office
**Location:** Filing cabinet, computer files
**Intel Provided:**
- Operation Shatter documents (once cabinet opened with 0419 code)
- Campaign materials
- Manifesto fragments
- Communications (once computer accessed)

**What Player Learns:** Full details of Operation Shatter, target lists, timeline.

#### Fragment 4: Digital Evidence - Server Room VMs
**Location:** VM systems (after SSH access gained)
**Intel Provided:**
- Attack infrastructure
- Target databases
- Technical implementation details

**What Player Learns:** How Operation Shatter will be executed technically.

#### Fragment 5: Correlation
**Action Required:** Player must:
1. Hear Maya mention "Operation Shatter"
2. Learn Derek uses date-based passwords from Kevin
3. Find 0419 in Derek's office environment
4. Open filing cabinet/computer
5. Access VMs with discovered passwords
6. Correlate physical + digital evidence

**Evidence Unlocked:** Complete Operation Shatter plan, proof of ENTROPY involvement

---

## Intel Thread #6: Kevin's Contingency/Frame-Up

### Evidence Trail

#### Fragment 1: Maya (NPC) - Concern About Derek
**Location:** Office conversation
**Intel Provided:**
- Derek is "paranoid" and defensive
- "Sometimes I wonder if he's involved in something bigger"

**What Player Learns:** Derek may have backup plans.

#### Fragment 2: Derek's Computer Files
**Location:** Derek's office computer (after gaining access)
**Intel Provided:**
- "Contingency_Plan.txt" or similar file
- Documents showing plan to frame Kevin
- Forged logs and emails

**What Player Learns:** Derek plans to frame Kevin if discovered.

#### Fragment 3: Agent 0x99 Reaction (Event-Triggered)
**Location:** Phone call after discovering contingency
**Intel Provided:**
- Explains what the contingency means for Kevin
- Presents player with choices (warn Kevin, plant evidence, ignore)

**What Player Learns:** Moral implications and response options.

#### Fragment 4: Correlation
**Action Required:** Player must:
1. Gain access to Derek's computer
2. Read contingency files
3. Understand implications
4. Make choice about Kevin's fate

**Evidence Unlocked:** Moral choice, narrative branch, Kevin's fate determined

---

## Intel Thread #7: Patricia's Investigation

### Evidence Trail

#### Fragment 1: Sarah (Receptionist) - Office Gossip
**Location:** Reception conversation
**Intel Provided:**
- "Patricia got fired about a month ago. Really sudden."
- "She was asking questions about Derek's projects"
- "Her briefcase is still in her office"

**What Player Learns:** Former manager investigated Derek, got fired, left evidence behind.

#### Fragment 2: Kevin (NPC) - Patricia's Concerns
**Location:** IT Room conversation (if asked)
**Intel Provided:**
- "Patricia was investigating something about Derek's external partners"
- "Kept notes in her office safe"

**What Player Learns:** Patricia documented her investigation.

#### Fragment 3: Physical Investigation - Patricia's Office
**Location:** Vacant manager's office
**Intel Provided:**
- Locked briefcase containing investigation notes
- Timeline of ENTROPY infiltration
- Connections to other cells

**What Player Learns:** Historical context, how long operation has been running.

#### Fragment 4: Correlation
**Action Required:** Player must:
1. Hear about Patricia from Sarah/Kevin
2. Gain lockpicking tool from Kevin
3. Find Patricia's office
4. Pick briefcase lock
5. Read investigation notes

**Evidence Unlocked:** Historical timeline, ENTROPY cell structure, additional context

---

## Evidence Correlation Map

```
Agent 0x99 (Handler)
├─> Provides mission context (Derek is suspect)
├─> General technical concepts (no specific commands)
├─> Encourages evidence correlation
└─> Reacts to player discoveries

Kevin (IT Manager)
├─> Password pattern hints (dates, company names)
├─> Derek's suspicious behavior
├─> Physical tools (lockpick, keycard access)
└─> Server room information

Maya (Content Analyst)
├─> "Operation Shatter" mention
├─> Derek's suspicious late-night calls
├─> Concerned but doesn't have full picture
└─> Points toward Derek without proving it

Sarah (Receptionist)
├─> Office layout information
├─> Patricia's firing story
├─> General workplace gossip
└─> Derek's unusual hours

Physical Environment
├─> Derek's office: Calendar (0419), sticky notes
├─> Whiteboards: Password hints, project notes
├─> Filing cabinets: Require discovered codes
├─> Computers: Require discovered passwords
└─> Patricia's briefcase: Requires lockpicking

Digital Environment (VMs)
├─> Require SSH access (discovered techniques)
├─> Hidden files (discovered through exploration)
├─> User accounts (discovered through privilege escalation)
└─> Flags and intelligence (discovered through investigation)
```

---

## Player Discovery Journey

### Act 1: Initial Intel Gathering
1. Receive mission briefing from Agent 0x99 (Derek is suspect, gather evidence)
2. Talk to Sarah at reception (office layout, Patricia story)
3. Meet Kevin in IT room (lockpicks, password hints, Derek's behavior)
4. Encounter Maya (mentions "Operation Shatter", Derek's suspicious calls)

**What Player Knows:** Derek is suspicious, uses important dates, involved in something called "Operation Shatter"

**What Player Doesn't Know:** Specific codes, technical methods, evidence locations

### Act 2: Evidence Discovery
5. Explore Derek's office → Find calendar with April 19 anniversary
6. Connect Kevin's hint ("important dates") + calendar → Deduce 0419 code
7. Open filing cabinet with 0419 → Find Operation Shatter documents
8. Access Derek's computer (0419 or variations) → Find contingency plan
9. Use clues to build SSH password wordlist (ViralDynamics2025, etc.)
10. Research or discover Hydra tool for SSH brute force

**What Player Knows:** Operation Shatter exists, Derek plans to frame Kevin, password patterns

**What Player Doesn't Know:** Full technical infrastructure, all evidence locations

### Act 3: Deep Investigation
11. SSH into VMs using discovered techniques
12. Navigate Linux systems (learn commands through experimentation)
13. Find hidden files (discover ls -la or research dotfiles)
14. Escalate privileges (discover sudo -l and sudo -u techniques)
15. Collect flags from multiple user accounts
16. Pick Patricia's briefcase lock → Historical context

**What Player Knows:** Complete Operation Shatter plan, technical infrastructure, ENTROPY's methods

**What Player Can Do:** Confront Derek, make choices about Kevin, complete mission

---

## Key Design Patterns

### 1. Multiple Sources Per Intel Thread
- No single NPC has complete information
- Player must talk to multiple people
- Environmental clues confirm or complete NPC hints

### 2. Hint → Discovery → Application
- NPCs hint at concepts ("important dates")
- Environment reveals specifics ("April 19")
- Player applies knowledge (0419 code)

### 3. Technical Knowledge Discovery
- Commands not given directly
- Player researches or experiments
- Environment rewards investigation

### 4. Progressive Revelation
- Early: General concepts and suspicions
- Middle: Specific clues and patterns
- Late: Complete picture from correlated evidence

### 5. Optional Depth
- Main path: Follow obvious hints
- Deep investigation: Patricia's notes, all VM flags, complete evidence
- Player choice determines how much they discover

---

## Success Metrics

### Player Successfully Discovers When They:
- Correlate Kevin's "important dates" hint with Derek's calendar
- Build password wordlists from environmental observations
- Research or experiment to find technical commands
- Connect Maya's "Operation Shatter" mention to Derek's files
- Piece together physical + digital evidence for complete picture

### Player Gets Stuck If They:
- Expect NPCs to give exact answers
- Don't explore physical environments thoroughly
- Skip conversations with multiple NPCs
- Don't experiment with systems
- Don't correlate information across sources

### Hints for Stuck Players (via Agent 0x99):
- "Have you talked to everyone in the office?"
- "Derek's office might have personal items revealing his patterns"
- "Environmental observation is as important as digital investigation"
- "Try combining what different people told you"
- "Research security tools if you're not familiar with them"

---

## Narrative Payoff

### Discovery Feels Earned
- Player uses investigation skills, not following waypoints
- "Aha!" moments from connecting clues
- Technical learning integrated into narrative
- Choices emerge from discovered evidence (Kevin's fate)

### Intel Incompleteness Creates Tension
- Player knows Derek is dangerous but must prove it
- "Operation Shatter" is ominous but details unclear initially
- Urgency to discover full plan before it's too late
- Satisfying revelation when all evidence correlates

---

**Document Version:** 1.0
**Last Updated:** 2025-12-10
**Mission:** M01 First Contact
