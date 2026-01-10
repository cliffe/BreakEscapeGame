# Mission 7: The Architect's Gambit (Part 1 of 2)

**Type:** Crisis Defense - Branching Campaign
**Duration:** 80-100 minutes
**Tier:** 3 (Advanced)
**ENTROPY Cell:** Multiple Cells (Coordinated Attack)
**SecGen Scenario:** "Putting it together" (NFS shares, netcat, privilege escalation, multi-stage)

## Mission Overview

The Architect's coordinated attack launches simultaneously across four targets. Player must choose which operation to stop personally, knowing other SAFETYNET teams will handle remaining operations—but some will fail. Player's choice determines which cells are disrupted and which succeed.

This is a **branching mission** where the player makes a critical choice at the start that determines the entire scenario they will play. All four options share common mechanics but have unique settings, NPCs, and narrative contexts.

## Single Location: SAFETYNET Crisis Operations Center

**Setting:** SAFETYNET headquarters - Emergency Operations Center (EOC)
**Layout:** Single floor plan with 4 specialized crisis response zones
**Context:** All 4 simultaneous attacks are being monitored and coordinated from this central command facility

The player is physically in the SAFETYNET EOC throughout the mission. The "choice" determines which crisis terminal/zone they take direct control of, while other SAFETYNET teams handle the remaining operations from adjacent zones.

## Four Crisis Response Zones (Player Chooses ONE to Directly Control)

### Zone A: "Infrastructure Collapse" (Critical Mass Cell)
**Terminal Focus:** Power grid control systems
**Remote Target:** Pacific Northwest power grid
**Threat:** Major city blackout, high civilian casualties (240-385 deaths)
**Stakes:** Immediate loss of life vs. long-term infrastructure damage
**SAFETYNET Team:** Team Alpha monitors from adjacent zone

### Zone B: "Data Apocalypse" (Ghost Protocol + Social Fabric)
**Terminal Focus:** Election security and data protection systems
**Remote Target:** Federal voter database and election infrastructure
**Threat:** Massive data breach + coordinated disinformation targeting elections
**Stakes:** 187M records stolen, democratic integrity, 20-40 deaths from civil unrest
**SAFETYNET Team:** Team Bravo monitors from adjacent zone

### Zone C: "Supply Chain Infection" (Supply Chain Saboteurs)
**Terminal Focus:** Software distribution and signing infrastructure
**Remote Target:** TechForge software update platform
**Threat:** Nationwide software supply chain backdoor insertion (47M systems)
**Stakes:** Long-term espionage capability, $240-420B damage over 10 years
**SAFETYNET Team:** Team Charlie monitors from adjacent zone

### Zone D: "Corporate Warfare" (Digital Vanguard + Zero Day Syndicate)
**Terminal Focus:** Corporate security and zero-day defense systems
**Remote Target:** 12 Fortune 500 corporations via TechCore SOC
**Threat:** Coordinated zero-day attacks, economic collapse
**Stakes:** $280-420B economic damage, 140K-220K job losses, 80-140 deaths
**SAFETYNET Team:** Team Delta monitors from adjacent zone

## SAFETYNET EOC Floor Plan (Shared Across All Branches)

**Location:** SAFETYNET headquarters underground facility
**Single Floor Layout with Common Rooms:**

### Shared Rooms (All Branches)
1. **Emergency Briefing Room** - Pre-mission choice presentation, Agent 0x99 coordinates
2. **Main Operations Floor** - Central hub, see all 4 crisis zones, other teams working
3. **Server Room** - VM access point, SecGen "Putting it together" challenges
4. **Communications Center** - The Architect's taunts appear here, intercept ENTROPY comms
5. **Intelligence Archive** - Discover Tomb Gamma location, SAFETYNET mole evidence
6. **Debrief Room** - Post-mission outcomes revealed

### Branch-Specific Crisis Terminals (Player Chooses ONE)
7A. **Infrastructure Crisis Terminal** - Power grid control systems (if player chooses Zone A)
7B. **Election Security Terminal** - Voter database protection (if player chooses Zone B)
7C. **Supply Chain Terminal** - Software distribution security (if player chooses Zone C)
7D. **Corporate Defense Terminal** - Zero-day mitigation systems (if player chooses Zone D)

**Layout Design:**
```
┌─────────────────────────────────────────────────┐
│  Emergency Briefing Room (Choice Presentation)  │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│          Main Operations Floor                  │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐       │
│  │Zone A│  │Zone B│  │Zone C│  │Zone D│       │
│  │Team  │  │Team  │  │Team  │  │Team  │       │
│  │Alpha │  │Bravo │  │Charlie│ │Delta │       │
│  └──────┘  └──────┘  └──────┘  └──────┘       │
│                                                  │
│     [Player takes control of ONE zone]          │
└─────┬──────────────┬──────────────┬─────────────┘
      │              │              │
      ▼              ▼              ▼
┌─────────┐   ┌────────────┐   ┌──────────────┐
│ Server  │   │Communica-  │   │Intelligence  │
│  Room   │   │tions Center│   │  Archive     │
│(VM/CTF) │   │(Architect) │   │(Tomb Gamma)  │
└─────────┘   └────────────┘   └──────────────┘
                   │
                   ▼
      ┌────────────────────────┐
      │    Debrief Room        │
      │ (Outcomes Revealed)    │
      └────────────────────────┘
```

**How Branching Works:**
- Player starts in Emergency Briefing Room (all branches identical)
- Makes choice → gains access to ONE crisis terminal on Main Operations Floor
- All shared rooms accessible regardless of choice
- Player's chosen crisis terminal becomes "active" with unique NPCs and challenges
- Other 3 zones show SAFETYNET teams working (background activity)
- Debrief room reveals outcomes of all 4 operations (deterministic based on choice)

## Shared Mechanics Across All Options

### Core Gameplay
- **Maximum difficulty** - All previous mechanics at highest complexity
- **30-minute in-game timer** - Real-time pressure
- **Hostile NPCs** - Multiple ENTROPY operatives who will attack
- **Multi-stage puzzles** - Complex progression requiring all learned skills
- **VM integration** - SecGen "Putting it together" scenario

### VM Challenge (Shared)
- Access distributed systems using NFS shares
- Discover attack timeline via netcat services
- Privilege escalation to access attack control systems
- Disable coordinated attack before timer expires

### Narrative Beats (Shared)
1. **Emergency briefing** - All four attacks detected simultaneously, Agent 0x99 presents crisis
2. **Choice moment** - Player chooses which crisis terminal to take direct control of
3. **Race against clock** - 30-minute timer, work with other teams visible in background
4. **First contact with The Architect** - Taunts via Communications Center throughout
5. **VM exploitation** - Server Room challenges apply to chosen crisis
6. **Disable attack** - Crisis terminal-specific sequence with seconds remaining
7. **Immediate debrief** - Learn outcomes of all 4 operations in Debrief Room

## Branching Structure Design

### Pre-Mission: Emergency Briefing Room
Player starts in SAFETYNET EOC Emergency Briefing Room:
- Agent 0x99 explains all four simultaneous crises
- Display screens show each attack in progress
- Stakes and consequences outlined for each option
- Player makes informed choice of which crisis to take direct control
- Other SAFETYNET teams visible at their crisis terminals

### During Mission: Single Location, Branching Gameplay
Player remains in SAFETYNET EOC throughout mission:
- **Shared rooms:** All players visit same Server Room, Communications Center, Intelligence Archive
- **Branching element:** Player's chosen crisis terminal determines:
  - Which NPCs they interact with (ENTROPY operatives appearing on screens/video feeds)
  - Which technical systems they exploit
  - Which narrative they experience
- **Background activity:** Other 3 crisis zones show SAFETYNET teams working (ambient NPCs)
- **Shared timer:** 30-minute countdown visible on all screens
- **The Architect:** Taunts appear in Communications Center regardless of choice

### Post-Mission: Debrief Room Outcomes
All players end in same Debrief Room:
- **Player's operation:** Success or failure (performance-based)
- **Operation 1 (unchosen):** Full success (Team got lucky)
- **Operation 2 (unchosen):** Partial success (Mitigated, not stopped)
- **Operation 3 (unchosen):** Failure (Attack succeeded)
- Which unchosen operations succeed/fail is **deterministic** based on player's choice

**Example Outcome Matrix:**
- **If player chose Infrastructure (A):** Data (B) partial success, Supply Chain (C) full success, Corporate (D) failure
- **If player chose Data (B):** Infrastructure (A) failure, Supply Chain (C) partial success, Corporate (D) full success
- **If player chose Supply Chain (C):** Infrastructure (A) partial success, Data (B) full success, Corporate (D) failure
- **If player chose Corporate (D):** Infrastructure (A) full success, Data (B) failure, Supply Chain (C) partial success

## Key NPCs

### Shared NPCs (All Branches)
- **Agent 0x99 "Haxolottle"** - Present in Emergency Briefing Room and Debrief Room, coordinates all operations
- **Director Patricia Morgan** - SAFETYNET Director, appears in Debrief Room to deliver consequences
- **The Architect** - First direct contact (text messages in Communications Center), taunts throughout
- **SAFETYNET Team Leads** - Team Alpha/Bravo/Charlie/Delta (3 teams player doesn't control, visible working in background)
- **Tech Analyst David Chen** - Server Room assistant, helps with VM challenges

### Branch-Specific NPCs (Via Video Feeds/Screens)
Each branch features ENTROPY operatives appearing on crisis terminal screens:
- **Option A:** Marcus "Blackout" Chen (Critical Mass) - at power grid facility
- **Option B:** "Specter" + Rachel Morrow (Ghost Protocol + Social Fabric) - at election center
- **Option C:** Adrian Cross (Supply Chain Saboteurs) - at TechForge facility
- **Option D:** Victoria "V1per" Zhang + Marcus "Shadow" Chen (Digital Vanguard + Zero Day Syndicate) - at TechCore SOC

**Key Design Note:** ENTROPY operatives don't physically infiltrate SAFETYNET EOC. Player interacts with them via video feeds, intercepted communications, and crisis terminal displays. This maintains single-location constraint while preserving distinct antagonists per branch.

## LORE Opportunities

### MAJOR Revelations
- **First direct contact with The Architect** - Philosophy revealed
- **"Entropy is inevitable; I merely accelerate"** - Core ideology
- **Tomb Gamma discovery** - The Architect's base of operations location found
- **SAFETYNET mole confirmed** - Someone leaked operation timing
- **The Architect's identity narrowed to 3 suspects** - Progress toward M9 reveal

### Campaign Integration
- The simultaneous attacks are a **distraction** - Real objective achieved during chaos
- Mystery payload revealed in M8
- Failed operations have consequences in M8-10 finale
- Campaign branches based on which cells disrupted vs. succeeded

## Moral Complexity

**THE IMPOSSIBLE CHOICE:** Which operation to stop personally?

All choices are valid. All have consequences. No "right" answer exists.

- **Infrastructure** = Civilian lives (immediate, visible casualties)
- **Elections** = Democratic integrity (systemic, long-term damage)
- **Supply Chain** = Future security (invisible compromise, years of espionage)
- **Corporate** = Economic stability (market crashes, job losses)

Player must choose knowing **someone will suffer** based on their decision.

## Educational Objectives (CyBOK)

### All Options Teach
- **Security Operations & Incident Management (SO):** Crisis response, triage, resource allocation under pressure
- **Systems Security (SS):** Multi-vector attack defense, coordinated threat response
- **Human Factors (HF):** Professional judgment under extreme pressure, ethical decision-making

### Option-Specific Topics
- **Option A:** Critical infrastructure protection, ICS/SCADA security
- **Option B:** Data protection, election security, disinformation defense
- **Option C:** Supply chain security, software integrity, backdoor detection
- **Option D:** Corporate security, zero-day defense, economic cybersecurity

## Implementation Strategy

### Phase 1: Shared Systems (Priority)
- Choice sequence briefing (pre-mission)
- Timer mechanic implementation
- The Architect communication system (audio/text taunts)
- Outcomes matrix and consequence tracking
- Post-mission debrief with variable outcomes

### Phase 2: Individual Options (Parallel Development)
Each option can be developed independently:
- Unique scenario.json.erb file
- Option-specific NPCs and dialogues
- Unique room layouts and puzzles
- Cell-specific narrative context

### Phase 3: Integration and Testing
- Ensure all options share VM challenge structure
- Verify timer works consistently
- Test outcome matrix for all choice combinations
- Validate LORE reveals appear in all paths

## File Structure

**Single Location Design - One Scenario File with Branching Logic:**

```
scenarios/m07_architects_gambit/
├── README.md (this file - design overview)
├── mission.json (metadata with CyBOK mappings)
├── scenario.json.erb (SINGLE scenario file with branching via player choice variable)
│   # Contains all 7 shared rooms + conditional crisis terminals based on choice
│   # Rooms 1-6 identical for all players
│   # Room 7 (crisis terminal) varies: 7A, 7B, 7C, or 7D based on globalVariable "crisis_choice"
├── ink/
│   ├── m07_opening_briefing.ink (Emergency Briefing Room - choice presentation)
│   ├── m07_phone_agent_0x99.ink (agent handler support - all branches)
│   ├── m07_architect_comms.ink (Communications Center - The Architect taunts)
│   ├── m07_closing_debrief.ink (Debrief Room - outcomes based on choice and performance)
│   ├── m07_crisis_terminal_a.ink (Infrastructure Crisis Terminal NPCs - Marcus Chen via video)
│   ├── m07_crisis_terminal_b.ink (Election Security Terminal NPCs - Specter + Rachel via video)
│   ├── m07_crisis_terminal_c.ink (Supply Chain Terminal NPCs - Adrian Cross via video)
│   ├── m07_crisis_terminal_d.ink (Corporate Defense Terminal NPCs - Victoria + Marcus via video)
│   └── m07_director_morgan.ink (Director Patricia Morgan - debrief authority figure)
└── planning/
    ├── stage_0_option_a_infrastructure.md (original design - now adapted)
    ├── stage_0_option_b_data.md (original design - now adapted)
    ├── stage_0_option_c_supply_chain.md (original design - now adapted)
    └── stage_0_option_d_corporate.md (original design - now adapted)
```

**How Single-Scenario Branching Works:**

The scenario.json.erb uses conditional logic based on `globalVariables.crisis_choice`:

```json
{
  "globalVariables": {
    "crisis_choice": "",  // Set to "infrastructure", "data", "supply_chain", or "corporate"
    "crisis_choice_made": false,
    ...
  },
  "rooms": {
    "emergency_briefing": { /* Choice made here */ },
    "operations_floor": { /* Shared room */ },
    "server_room": { /* Shared VM room */ },
    "communications_center": { /* Shared, Architect appears */ },
    "intelligence_archive": { /* Shared, Tomb Gamma discovery */ },

    // Conditional crisis terminal - only ONE appears based on choice
    "crisis_terminal": {
      "type": "<%= crisis_choice == 'infrastructure' ? 'room_control_center' :
               crisis_choice == 'data' ? 'room_servers' :
               crisis_choice == 'supply_chain' ? 'room_office' :
               'room_office' %>",
      "npcs": "<%= /* Load appropriate NPC set based on choice */ %>",
      ...
    },

    "debrief_room": { /* Shared, outcomes revealed */ }
  }
}
```

This approach:
- ✅ Single floor plan (all players visit same rooms 1-6)
- ✅ Branching narrative (crisis terminal content varies)
- ✅ Maintains 4 distinct story paths
- ✅ Simpler to develop and test than 4 separate scenarios
- ✅ Shared VM challenges, timer, and mechanics
- ✅ Reduces file duplication significantly

## Development Notes

**Complexity Warning:** This is the most complex mission in Season 1. It requires:
- Single scenario file with branching ERB logic
- Choice mechanism that sets global variable
- Shared timer and consequence systems
- Branching narrative within same location
- Variable outcome matrix
- 4 distinct crisis terminal implementations

**Recommended Approach:**
1. **Phase 1:** Build shared rooms (Emergency Briefing, Operations Floor, Server Room, Communications Center, Intelligence Archive, Debrief Room)
2. **Phase 2:** Implement choice mechanism in Emergency Briefing Room (set crisis_choice variable)
3. **Phase 3:** Build ONE crisis terminal completely (e.g., Option A Infrastructure) as template
4. **Phase 4:** Clone crisis terminal logic for Options B, C, D with unique NPCs and dialogue
5. **Phase 5:** Implement Debrief Room with deterministic outcomes matrix
6. **Phase 6:** Test all 4 paths thoroughly

**Technical Considerations:**
- ERB conditional logic must cleanly switch crisis terminal content based on globalVariable
- Timer implementation must work consistently regardless of choice
- Outcome tracking must persist to M8-10 via campaign state
- The Architect's taunts in Communications Center should reference player's choice contextually
- NPC dialogues via video feeds must feel present despite remote locations
- Background SAFETYNET teams should show appropriate activity in unchosen zones

**Single-Location Benefits:**
- ✅ Drastically reduces development time (1 scenario file vs. 4)
- ✅ Easier to maintain consistency (shared rooms identical across branches)
- ✅ VM challenges reusable (same Server Room for all players)
- ✅ LORE reveals centralized (Intelligence Archive shared)
- ✅ The Architect presence consistent (same Communications Center)
- ✅ Simpler testing (test shared rooms once, then test 4 crisis variations)
