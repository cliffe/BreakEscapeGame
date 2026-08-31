# Mission 8: "The Mole" - Design Document

## Mission Overview

**Mission ID:** m08_the_mole
**Type:** Internal Investigation (Standalone with campaign enhancements)
**Duration:** 60-75 minutes
**Difficulty Tier:** 2 (Intermediate)
**ENTROPY Cell:** Insider Threat Initiative (SAFETYNET infiltration)
**SecGen Scenario:** "Such a git" (GitList exploitation, leaked credentials, privilege escalation)

---

## Story Premise

### The Betrayal

Mission 7's coordinated ENTROPY attack revealed a catastrophic security breach: someone inside SAFETYNET leaked operational details to The Architect. ENTROPY knew SAFETYNET's response plans, team assignments, and timing. The leak allowed The Architect to coordinate the simultaneous attacks with deadly precision.

Now, Agent 0x00 must return to SAFETYNET headquarters to conduct an internal investigation. Among the organization's trusted agents, one is a traitor. The atmosphere is thick with paranoia—anyone could be the mole.

### The Horror

The leaked information cost lives. The operations that failed in Mission 7 failed because ENTROPY knew they were coming. Every casualty, every failed operation, traces back to internal betrayal.

**The mission:** Identify the mole, gather evidence, and confront the traitor—all while maintaining operational security and avoiding tipping them off.

---

## Narrative Structure

### Act 1: Return to Headquarters (20 minutes)
**Setup and Initial Investigation**

- Player returns to SAFETYNET HQ after Mission 7
- Atmosphere of paranoia and suspicion
- Director Samantha Cross briefs on mole investigation
- Three suspects identified through behavioral analysis:
  - **Agent 0x47 "Nightshade"** - Operations specialist, access to mission plans
  - **Agent 0x23 "Cipher"** - Intelligence analyst, cryptography expert
  - **Agent 0x88 "Phantom"** - Field coordinator, knows all team movements
- Player must investigate each suspect's activities without alerting them
- Access SAFETYNET's internal systems (ironically vulnerable)

### Act 2: Investigation and Discovery (30 minutes)
**Evidence Gathering and Pattern Recognition**

- Interview suspects (social engineering fellow agents - emotionally complex)
- Access internal GitList repository via exploitation
- Discover leaked commit history showing classified information
- Find credentials accidentally committed to repository
- Privilege escalation to access classified communications
- Trace mole's digital footprint across internal systems
- Discover pattern: information leaked matches Nightshade's access patterns
- Find encrypted communications with ENTROPY addresses
- Emotional weight: these are colleagues, trusted allies

### Act 3: Confrontation and Resolution (15 minutes)
**The Truth Revealed**

- Evidence conclusively points to Agent 0x47 "Nightshade"
- Confront Nightshade in secure interrogation room
- Nightshade's philosophy revealed:
  - Ideological convert to ENTROPY
  - Believes "order is futile, entropy is inevitable"
  - Recruited during training (alongside player - personal betrayal)
  - Insider Threat Initiative's "Deep State" operation
- **Critical Choice:**
  - **Arrest:** Justice served, Nightshade faces prosecution
  - **Turn Triple Agent:** Risky, but provides intelligence on ENTROPY
- Revelation: The Architect's real objective in M7 was to steal SAFETYNET's global threat database
- Nightshade reveals Tomb Gamma location coordinates
- Sets up Mission 9's exploration of abandoned ENTROPY bases

---

## Location Design

### SAFETYNET Headquarters - "The Citadel"

**Theme:** Modern intelligence facility with paranoid security after breach
**Layout:** Single-location investigation with multiple secure areas

#### Rooms and Areas

1. **Main Lobby** (START)
   - Reception desk with AI assistant
   - Security checkpoint
   - Digital directory showing floor layout
   - Suspicious atmosphere, heightened security

2. **Director's Office** (North from Lobby)
   - Director Samantha Cross (first appearance)
   - Mission briefing area
   - Secure terminal with investigation parameters
   - Files on three suspects

3. **Operations Floor** (East from Lobby)
   - Open workspace with multiple agent workstations
   - Agent 0x23 "Cipher" works here
   - Observable suspect behaviors
   - Clues in desk contents

4. **Intelligence Analysis Room** (North from Operations)
   - Agent 0x88 "Phantom" coordinates here
   - Wall screens showing global operations
   - Tactical planning boards
   - Classified mission plans (potential leak sources)

5. **Server Room** (East from Operations) [RFID LOCKED]
   - GitList server hosting internal code repository
   - VM terminal for exploitation
   - Drop-site for flag submission
   - Evidence of unauthorized access

6. **Security Archives** (South from Operations) [PASSWORD LOCKED]
   - Physical evidence locker
   - Backup logs from compromised systems
   - Historical communications
   - Nightshade's personnel file

7. **Cryptography Lab** (West from Lobby)
   - Agent 0x47 "Nightshade" works here
   - Encryption equipment
   - CyberChef workstation
   - Evidence of ENTROPY communications

8. **Interrogation Room** (South from Cryptography Lab) [KEY LOCKED]
   - Secure confrontation space
   - Recording equipment
   - Final confrontation with Nightshade
   - Evidence presentation system

9. **Break Room** (West from Cryptography Lab)
   - Informal agent interactions
   - Overheard conversations (clues)
   - Post-it notes, casual evidence
   - Timeline reconstruction clues

---

## Core Gameplay Mechanics

### New Mechanics Introduced

1. **Ally Investigation System**
   - Interview fellow agents (not hostile, but defensive)
   - Social engineering people who trust you
   - Emotional complexity of suspecting colleagues
   - Non-combat confrontation

2. **Evidence Timeline Reconstruction**
   - Correlate digital and physical evidence
   - Build timeline of leak events
   - Match access logs to leaked information
   - Visual timeline display

3. **Internal Security Systems**
   - SAFETYNET's own vulnerabilities exposed
   - Irony of security organization being insecure
   - Familiar systems from victim's perspective
   - Ethical hacking on friendly infrastructure

4. **Triple Agent Mechanics** (if chosen)
   - Negotiation with turned mole
   - Risk assessment of double-cross
   - Future mission support system
   - Moral weight of using traitor

### Reinforced Mechanics

- **Lockpicking** (interrogation room, security archives)
- **RFID cloning** (server room access)
- **Social engineering** (maximum emotional complexity)
- **Password cracking** (security archives)
- **CyberChef puzzles** (encrypted ENTROPY communications)

---

## VM Challenge Integration

### SecGen "Such a git" Scenario

**Narrative Context:** SAFETYNET's internal GitList repository contains evidence of the leak

#### Challenge Stages

**Stage 1: Access GitList Server**
- Exploit GitList CVE-2018-1000533 (directory traversal)
- Objective: Read sensitive files outside web root
- Flag 1: Located in leaked configuration file
- Narrative: Discover GitList misconfiguration allowing file access

**Stage 2: Leaked Credentials Discovery**
- Find accidentally committed credentials in repository history
- Objective: Extract credentials from old commits
- Flag 2: Found in commit containing database credentials
- Narrative: Nightshade's operational security failure

**Stage 3: Privilege Escalation**
- Use leaked credentials to access system
- Escalate to root via sudo misconfiguration
- Flag 3: Located in root's home directory
- Narrative: Access classified communications showing ENTROPY contact

**Stage 4: Communication Trace**
- Analyze system logs for unauthorized access
- Identify pattern matching Nightshade's behavior
- Flag 4: Final evidence linking Nightshade to leak
- Narrative: Conclusive proof for confrontation

#### Evidence Discovery Mapping

| VM Flag | Evidence Type | Narrative Impact |
|---------|---------------|------------------|
| Flag 1 | GitList vulnerability | SAFETYNET's security gaps |
| Flag 2 | Leaked credentials | Nightshade's first mistake |
| Flag 3 | Classified comms | ENTROPY contact confirmed |
| Flag 4 | Access logs | Timeline proves Nightshade's guilt |

---

## Key NPCs

### Director Samantha Cross
**Role:** SAFETYNET Director (First Major Appearance)
**Personality:** Hardened professional, emotionally controlled, deeply troubled by betrayal
**Function:** Mission briefing, sets investigation parameters, oversees interrogation
**Dialogue:** Formal, tactical, shows cracks when discussing betrayal's impact

### Agent 0x99 "Haxolottle" (Handler)
**Role:** Player's Handler (Recurring Character)
**Personality:** Emotionally devastated - has worked with all suspects for years
**Function:** Remote support, provides emotional context, struggles with paranoia
**Dialogue:** More subdued than usual, questioning trust, personal stakes high

### Agent 0x47 "Nightshade" (THE MOLE)
**Role:** Operations Specialist / ENTROPY Mole
**Background:** Recruited by Insider Threat Initiative during training
**Personality:** Cold, philosophical, ideologically committed
**Philosophy:** "Entropy is inevitable. I'm just being honest about it."
**Recruitment Method:** Targeted for ideological alignment, not blackmail or money
**Motivation:** Genuinely believes ENTROPY's accelerationist philosophy
**Confrontation:** Calm, rational, willing to explain, no regrets

### Agent 0x23 "Cipher" (SUSPECT - INNOCENT)
**Role:** Intelligence Analyst / Red Herring
**Personality:** Brilliant cryptographer, socially awkward, appears suspicious
**Suspicious Behavior:** Works odd hours, secretive about personal projects
**Truth:** Working on classified encryption project, not the mole
**Function:** Misdirection, reinforces paranoia theme

### Agent 0x88 "Phantom" (SUSPECT - INNOCENT)
**Role:** Field Coordinator / Red Herring
**Personality:** Charismatic, well-connected, unusually interested in operations
**Suspicious Behavior:** Asks too many questions, has unexplained absences
**Truth:** Conducting authorized side investigation, paranoid about mole
**Function:** Second misdirection, shows how suspicion affects team

---

## Puzzles and Challenges

### Investigation Puzzles

1. **Interview Correlation**
   - Interview all three suspects
   - Compare statements for inconsistencies
   - Identify behavioral tells
   - Cross-reference with digital evidence

2. **Access Log Analysis**
   - Review server access logs
   - Match timestamps to leak timeline
   - Identify suspicious access patterns
   - Correlate with suspect work schedules

3. **Encrypted Communication Decode**
   - Find encrypted messages in Nightshade's workspace
   - Use CyberChef to decode communications
   - Reveal ENTROPY addresses and coordination
   - Provides smoking gun evidence

4. **Timeline Reconstruction**
   - Collect evidence from multiple sources
   - Build chronological timeline of leak events
   - Visual display shows pattern emerging
   - Final piece confirms Nightshade

### Physical Puzzles

1. **Director's Office Safe**
   - PIN code: **CLASSIFIED** (find in mission plans)
   - Contains: Suspect psych evaluations
   - Reveals: Nightshade's ideological profile flagged but dismissed

2. **Server Room RFID Lock**
   - Requires: RFID cloner + target keycard
   - Target: Director Cross's keycard (visible, must clone during conversation)
   - Unlocks: GitList server access

3. **Security Archives Password**
   - Method: Find password in break room (post-it note, typical security irony)
   - Password: **"TrustNoOne"** (thematic)
   - Unlocks: Historical evidence logs

4. **Interrogation Room Key**
   - Location: Director's desk (visible after investigation complete)
   - Alt Method: Lockpick (medium difficulty)
   - Unlocks: Final confrontation space

---

## Moral Choices and Consequences

### Primary Choice: Nightshade's Fate

#### Option A: Arrest
**Immediate:**
- Nightshade taken into custody
- Justice served, team closure
- No ongoing intelligence from mole

**Long-term:**
- Nightshade prosecuted, likely life sentence
- ENTROPY loses inside source
- Mission 10: No Nightshade support, slightly harder
- Morally clean choice

#### Option B: Turn Triple Agent
**Immediate:**
- Nightshade officially "arrested" but secretly cooperating
- Risky - could be feeding false intelligence
- Director Cross uncomfortable but approves

**Long-term:**
- Nightshade provides ENTROPY intelligence (may be unreliable)
- Mission 9: Nightshade provides Tomb Beta intel
- Mission 10: Nightshade provides Tomb Gamma defensive layout (valuable)
- Constant risk of double-cross
- Moral compromise: using traitor, risking more betrayal

**Player Variables:**
- `nightshade_arrested = true/false`
- `nightshade_triple_agent = true/false`
- `nightshade_cooperation_level = 0-100` (if triple agent)

### Secondary Choice: Expose Internal Vulnerabilities

#### Option A: Public Accountability
- Expose SAFETYNET's security failures publicly
- Forces organizational reform
- Damages SAFETYNET's reputation and operational security
- Terrorist organizations learn SAFETYNET's weaknesses

#### Option B: Quiet Fix
- Internal only reform
- Maintains operational security
- No public accountability
- Vulnerabilities fixed but lesson not shared with other agencies

**Player Variables:**
- `safetynet_exposed = true/false`
- `safetynet_reputation = -20 to 0` (if exposed, hits reputation)

---

## LORE and World-Building

### LORE Collectibles

1. **Insider Threat Initiative "Deep State" Manual**
   - Location: Nightshade's encrypted files
   - Content: Recruitment program targeting intelligence agencies
   - Reveals: Systematic ENTROPY infiltration of government
   - Impact: Shows ENTROPY's long-term planning

2. **The Architect's Communication to Nightshade**
   - Location: Decoded from Nightshade's encrypted archive
   - Content: Approval for database theft, philosophical discussion
   - Reveals: The Architect's voice and personality
   - Impact: Sets up Mission 9's identity revelation

3. **SAFETYNET's Global Threat Database Catalog**
   - Location: Security Archives
   - Content: List of every known vulnerability globally
   - Reveals: Scope of what The Architect stole
   - Impact: Understand M7's real objective, raises M10 stakes

4. **Nightshade's Training Records**
   - Location: Personnel files in Director's safe
   - Content: Psychological profile, recruitment flags ignored
   - Reveals: SAFETYNET missed warning signs
   - Impact: Organizational failure theme, not just individual betrayal

5. **Tomb Gamma Coordinates**
   - Location: Nightshade provides during interrogation
   - Content: 47.2382° N, 112.5156° W (Montana, abandoned Cold War bunker)
   - Reveals: The Architect's base of operations
   - Impact: Sets up Mission 9 (Tomb exploration) and Mission 10 (final raid)

### Connection to Campaign Arc

**From Mission 7:**
- M7's leak enabled The Architect's coordination
- Failed operations in M7 partly due to Nightshade's intelligence
- The Architect's true objective (database theft) now revealed

**To Mission 9:**
- Tomb Gamma location discovered
- Nightshade's intel (if triple agent) helps Tomb Beta exploration
- The Architect's identity narrowed (mentioned in communications)

**To Mission 10:**
- If Nightshade turned: provides defensive layout of Tomb Gamma
- SAFETYNET's vulnerability status affects finale difficulty
- Personal stakes established: betrayal must be avenged

---

## Educational Objectives (CyBOK)

### Primary Knowledge Areas

1. **Human Factors (Primary)**
   - Insider threat psychology
   - Behavioral indicators of compromised insiders
   - Social engineering within trusted environments
   - Trust exploitation in organizational contexts

2. **Security Operations (Primary)**
   - Internal threat hunting
   - Anomaly detection in access logs
   - Forensic timeline reconstruction
   - Evidence correlation across multiple sources

3. **Software Security (Primary)**
   - Version control security (GitList)
   - Secret management failures
   - Configuration vulnerabilities
   - Credential leakage in code repositories

### Secondary Knowledge Areas

4. **Forensics**
   - Digital evidence collection
   - Log analysis and pattern recognition
   - Communication metadata analysis
   - Timeline reconstruction techniques

5. **Applied Cryptography**
   - Encrypted communication analysis
   - Decoding intercepted messages
   - Cryptographic operational security failures

---

## Success Outcomes

### Full Success
- Mole identified with conclusive evidence
- All 4 VM flags submitted
- All LORE collectibles found
- Appropriate choice made for Nightshade
- Global threat database scope understood
- Tomb Gamma location secured
- No operational security compromised

### Partial Success
- Mole identified but some evidence gaps
- 2-3 VM flags submitted
- Some LORE collectibles missed
- Nightshade handled but incomplete intelligence
- Database theft understood but scope unclear

### Minimal Success
- Mole identified but rushed evidence
- 1-2 VM flags submitted
- Limited LORE discovery
- Nightshade confronted but poor choice made
- Incomplete understanding of consequences

---

## Technical Implementation Notes

### ERB Conditional Rendering

Mission 8 adapts based on Mission 7 choice:
```erb
<% if @mission_7_choice == "infrastructure" %>
  "The infrastructure attack killed 240 people because I told them you were coming."
<% elsif @mission_7_choice == "data" %>
  "187 million records stolen because I leaked your team's location."
<% elsif @mission_7_choice == "supply_chain" %>
  "The backdoors infected 47 million devices because I gave them your timeline."
<% else %>
  "Economic collapse, 140,000 jobs lost because I betrayed operational security."
<% end %>
```

### Global Variables

```json
{
  "mission_started": false,
  "suspects_interviewed": 0,
  "evidence_collected": 0,
  "flag1_submitted": false,
  "flag2_submitted": false,
  "flag3_submitted": false,
  "flag4_submitted": false,
  "mole_identified": false,
  "nightshade_arrested": false,
  "nightshade_triple_agent": false,
  "tomb_gamma_location_known": false,
  "database_theft_understood": false,
  "found_deep_state_manual": false,
  "found_architect_communication": false,
  "found_database_catalog": false
}
```

---

## Dialogue System (Ink Files)

### Required Ink Files

1. **m08_opening_briefing.ink**
   - Director Cross's mission briefing
   - Introduction to mole investigation
   - Three suspects presented
   - Investigation parameters established

2. **m08_director_cross.ink**
   - Recurring conversations with Director
   - Emotional impact of betrayal
   - Organizational perspective
   - Authorization for interrogation

3. **m08_agent_0x99.ink**
   - Handler's emotional struggle
   - Personal connections to suspects
   - Tactical support and guidance
   - Doubt and paranoia themes

4. **m08_suspect_cipher.ink**
   - Interview with Agent 0x23 "Cipher"
   - Defensive, appears suspicious
   - Red herring dialogue
   - Eventually cleared

5. **m08_suspect_phantom.ink**
   - Interview with Agent 0x88 "Phantom"
   - Charismatic, deflective
   - Second red herring
   - Eventually cleared

6. **m08_suspect_nightshade.ink**
   - Initial interview (deceptive)
   - Appears cooperative
   - Subtle tells for observant players
   - Pre-reveal tension

7. **m08_nightshade_confrontation.ink**
   - Final interrogation scene
   - Philosophy revealed
   - Insider Threat recruitment explained
   - Critical choice: arrest or turn
   - Tomb Gamma location provided

8. **m08_closing_debrief.ink**
   - Resolution with Director Cross
   - Impact of player's choice
   - Database theft revelation
   - Mission 9 setup

---

## Difficulty and Pacing

### Time Estimates

- **Act 1 (Setup):** 20 minutes
  - Briefing: 5 minutes
  - Initial exploration: 10 minutes
  - First suspect interviews: 5 minutes

- **Act 2 (Investigation):** 30 minutes
  - VM exploitation: 15 minutes
  - Evidence gathering: 10 minutes
  - Pattern recognition: 5 minutes

- **Act 3 (Confrontation):** 15 minutes
  - Final evidence correlation: 3 minutes
  - Nightshade confrontation: 10 minutes
  - Resolution: 2 minutes

**Total:** 60-75 minutes

### Difficulty Curve

```
Difficulty
High    │                          ╭──────╮
        │                     ╭────╯      │
Medium  │           ╭─────────╯           │
        │      ╭────╯                     ╰────╮
Low     ├──────╯                              │
        └──┬────┬────┬────┬────┬────┬────┬────┬─
           0    10   20   30   40   50   60   70
                    Minutes into Mission
```

- **0-20:** Easy (orientation, briefing)
- **20-40:** Medium (investigation, VM challenges)
- **40-55:** High (evidence correlation, pressure builds)
- **55-70:** Medium (confrontation, choice-driven)

---

## Testing and Validation Checklist

- [ ] All rooms accessible and connected correctly
- [ ] All NPCs have complete dialogue trees
- [ ] GitList VM scenario integrated and flags submittable
- [ ] Evidence trail leads conclusively to Nightshade
- [ ] Red herrings sufficient but not misleading
- [ ] Both arrest and triple-agent choices functional
- [ ] LORE collectibles discoverable
- [ ] Timeline reconstruction puzzle solvable
- [ ] Mission 7 variables correctly referenced
- [ ] Mission 9/10 setup variables correctly set
- [ ] Schema validation passes

---

## Production Status

**Status:** Initial Design Phase
**Next Steps:**
1. Create scenario.json.erb
2. Write all 8 Ink dialogue files
3. Map VM flags to evidence discovery
4. Create solution guide
5. Validate and test

---

**Mission 8 represents the emotional core of Season 1's final act—the personal betrayal that makes the conflict with The Architect deeply personal.**
