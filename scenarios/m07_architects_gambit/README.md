# Mission 7: The Architect's Gambit (Part 1 of 2)

**Type:** Crisis Defense - Branching Campaign
**Duration:** 80-100 minutes
**Tier:** 3 (Advanced)
**ENTROPY Cell:** Multiple Cells (Coordinated Attack)
**SecGen Scenario:** "Putting it together" (NFS shares, netcat, privilege escalation, multi-stage)

## Mission Overview

The Architect's coordinated attack launches simultaneously across four targets. Player must choose which operation to stop personally, knowing other SAFETYNET teams will handle remaining operations—but some will fail. Player's choice determines which cells are disrupted and which succeed.

This is a **branching mission** where the player makes a critical choice at the start that determines the entire scenario they will play. All four options share common mechanics but have unique settings, NPCs, and narrative contexts.

## Four Simultaneous Operations (Player Chooses ONE)

### Option A: "Infrastructure Collapse" (Critical Mass Cell)
**Setting:** Power grid control facility
**Threat:** Major city blackout, high civilian casualties
**Stakes:** Immediate loss of life vs. long-term infrastructure damage
**Cell Leader:** Marcus "Blackout" Chen - Critical Mass coordinator

### Option B: "Data Apocalypse" (Ghost Protocol + Social Fabric)
**Setting:** Data center / election systems facility
**Threat:** Massive data breach + coordinated disinformation targeting elections
**Stakes:** Democratic integrity, election manipulation, public trust collapse
**Cell Leaders:** Ghost Protocol hacker + Social Fabric narrative coordinator

### Option C: "Supply Chain Infection" (Supply Chain Saboteurs)
**Setting:** Software distribution center
**Threat:** Nationwide software supply chain backdoor insertion
**Stakes:** Long-term espionage capability, millions of systems compromised
**Cell Leader:** Supply Chain Saboteurs operations manager

### Option D: "Corporate Warfare" (Digital Vanguard + Zero Day Syndicate)
**Setting:** Fortune 500 corporate headquarters
**Threat:** Coordinated zero-day attacks on major companies
**Stakes:** Economic damage, market instability, corporate espionage
**Cell Leaders:** Digital Vanguard + Zero Day Syndicate coordinators

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
1. **Emergency briefing** - All four attacks detected, player chooses
2. **Intense infiltration** - Race against clock at chosen target
3. **First contact with The Architect** - Voice only, taunting remotely
4. **Disable attack** - With seconds remaining
5. **Immediate debrief** - Learn outcomes of other operations

## Branching Structure Design

### Pre-Mission: Choice Sequence
Player is presented with crisis briefing showing all four operations:
- Agent 0x99 explains each threat
- Stakes and consequences outlined
- Player makes informed choice
- Other SAFETYNET teams deploy to remaining targets

### During Mission: Chosen Scenario
Player experiences one complete scenario based on choice:
- Unique location, NPCs, and story context
- Shared timer mechanic (30 minutes in-game)
- Shared VM challenge structure
- The Architect taunts via audio/text communications

### Post-Mission: Outcomes Matrix
Based on player choice and performance:
- **Player's operation:** Success or failure (performance-based)
- **Operation 1 (unchosen):** Full success (team got lucky)
- **Operation 2 (unchosen):** Partial success (mitigated, not stopped)
- **Operation 3 (unchosen):** Failure (attack succeeded)

Which unchosen operations succeed/fail is **deterministic** based on player's choice.

## Key NPCs

### Shared NPCs
- **Agent 0x99 "Haxolottle"** - Command support, coordinates response, visible stress
- **The Architect** - First appearance (voice/text only), taunts player throughout
- **SAFETYNET Teams Alpha/Bravo/Charlie** - Handle unchosen operations (referenced)

### Option-Specific NPCs
Each option has 2-3 hostile ENTROPY operatives and 1-2 cell leaders to confront.

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

```
scenarios/m07_architects_gambit/
├── README.md (this file)
├── mission.json (metadata with CyBOK mappings)
├── scenario_choice.json.erb (pre-mission choice sequence)
├── scenario_option_a_infrastructure.json.erb
├── scenario_option_b_data.json.erb
├── scenario_option_c_supply_chain.json.erb
├── scenario_option_d_corporate.json.erb
├── ink/
│   ├── m07_opening_briefing.ink (choice presentation)
│   ├── m07_phone_agent_0x99.ink (handler support, all options)
│   ├── m07_architect_taunts.ink (The Architect's communications)
│   ├── m07_closing_debrief.ink (outcomes reveal)
│   ├── m07_option_a_npcs.ink
│   ├── m07_option_b_npcs.ink
│   ├── m07_option_c_npcs.ink
│   └── m07_option_d_npcs.ink
└── planning/
    ├── stage_0_option_a.md
    ├── stage_0_option_b.md
    ├── stage_0_option_c.md
    └── stage_0_option_d.md
```

## Development Notes

**Complexity Warning:** This is the most complex mission in Season 1. It requires:
- 4 complete scenario files (essentially 4 mini-missions)
- Shared timer and consequence systems
- Branching narrative tracking
- Variable outcome matrix

**Recommended Approach:**
1. Build shared systems first (choice, timer, outcomes)
2. Develop one complete option as template
3. Clone and modify for remaining options
4. Test all paths thoroughly

**Technical Considerations:**
- How does game engine handle scenario selection based on player choice?
- Timer implementation needs to be robust across all scenarios
- Outcome tracking must persist to M8-10
- The Architect's taunts should feel consistent across options
