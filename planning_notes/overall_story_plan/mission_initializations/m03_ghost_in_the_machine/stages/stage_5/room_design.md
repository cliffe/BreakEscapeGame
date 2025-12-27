# Room Layout: "Ghost in the Machine"

**Mission ID:** m03_ghost_in_the_machine
**Stage:** 5 - Room Layout and Challenge Distribution
**Date Created:** 2025-12-27

---

## Overview

**Location:** WhiteHat Security Services - Corporate Office Building
**Total Rooms:** 7 rooms
**Playable Area:** Small (5-8 rooms)
**Security Level:** Medium
**Time Phases:** Daytime (Act 1) → Nighttime (Act 2-3)

**Design Philosophy:**

Mission 3 uses a **hub-and-spoke layout** centered around a main hallway:
- **Central Hub:** Main hallway with guard patrol
- **Spoke Branches:** Conference room, server room, executive office, James's office
- **Progressive Unlocking:** Start with reception + conference room (Act 1), unlock server room via RFID card (Act 2), explore executive office for evidence
- **Backtracking:** Return to server room for decoding after finding evidence in executive office
- **Dual-Phase Design:** Same location visited daytime (safe, social) and nighttime (tense, infiltration)

---

## Location Description

**WhiteHat Security Services** presents itself as a legitimate penetration testing and security consulting firm operating from a modern office building. The space is professionally decorated with security certifications on walls, client testimonials, and technical equipment. During the daytime visit (Act 1), the office is lit, clean, and welcoming—a perfect corporate facade. During the nighttime infiltration (Act 2-3), the same spaces transform: dim emergency lighting, shadows, the sound of HVAC systems, and a single guard on patrol create tension.

The office layout is designed to separate public-facing areas (reception, conference room) from secured operational spaces (server room, executive offices). This physical separation mirrors Zero Day's compartmentalization: legitimate business in front, criminal operations hidden behind RFID-locked doors.

The server room serves as the investigation hub—where VM challenges unlock digital intelligence that correlates with physical evidence gathered from executive spaces. Players will repeatedly return here to decode messages using the CyberChef workstation, creating a satisfying loop of discovery and synthesis.

---

## Individual Room Designs

### Room 1: Reception Lobby

**ID:** `reception_lobby`
**Dimensions:** 8 × 6 GU (12m × 9m)
**Usable Space:** 6 × 4 GU
**Type:** Reception / Entrance
**Act:** Act 1 (Daytime) & Act 2 (Nighttime - guard patrol start)

**Description:**
Professional reception area with modern furniture. WhiteHat Security logo on wall. Reception desk with dual monitors. Company awards and certifications (OSCP, CEH, PCI-DSS compliance) displayed prominently. During daytime: bright, welcoming. During nighttime: single desk lamp, shadows, empty.

**Connections:**
- **North:** `main_hallway` (open door - always accessible)

**Containers:**
1. **Reception Desk Drawer**
   - **Position:** (3, 2) in usable space
   - **Lock:** None
   - **Contents:** Building directory, company brochure
   - **Narrative Purpose:** First impression of WhiteHat's legitimate facade

2. **Wall-Mounted Display Case**
   - **Position:** (1, 1) in usable space
   - **Lock:** None (decorative)
   - **Contents:** Security certifications (visual only - not pickupable)
   - **Narrative Purpose:** Establish company credibility

**Interactive Objects:**
- **Company Founding Plaque**
  - **Position:** (5, 2) on east wall
  - **Interaction:** Examine to read "WhiteHat Security Services - Founded 2010"
  - **Result:** Provides safe PIN clue (2010 is executive safe combination)
  - **Objectives:** Optional discovery for `lore_fragment_2`

**NPCs:**
- **Receptionist** (In-Person - Daytime Only)
  - **Position:** (3, 2) at desk
  - **Dialogue Trigger:** Automatic when player enters (first visit)
  - **Gives Items:** None
  - **Objectives:** Establishes cover story, directs player to conference room
  - **Daytime Only:** Not present during nighttime infiltration

- **Night Security Guard** (Patrol Route - Nighttime Only)
  - **Starting Position:** (3, 2) - begins patrol from reception
  - **Patrol Route:** Reception (15 ticks) → Hallway → Executive wing → Server wing → Return
  - **Dialogue Trigger:** If detected by player
  - **Objectives:** Stealth challenge for `perfect_stealth` optional objective
  - **Nighttime Only:** Not present during daytime visit

**Objectives Completed Here:**
- `meet_receptionist` (daytime) - Establish cover story
- Optional: Discovery of safe PIN clue (2010 founding year)

**LORE Fragments:** None

**Technical Notes:**
- Receptionist NPC conditionally spawned: `time_of_day == "daytime"`
- Guard NPC conditionally spawned: `time_of_day == "nighttime"`
- Guard patrol implemented via waypoint system

---

### Room 2: Conference Room

**ID:** `conference_room_01`
**Dimensions:** 10 × 8 GU (15m × 12m)
**Usable Space:** 8 × 6 GU
**Type:** Conference / Meeting Room
**Act:** Act 1 (Daytime - Victoria meeting)

**Description:**
Professional conference room with large table (seats 8), whiteboard on east wall, projector screen, windows overlooking city. Corporate but comfortable. Victoria Sterling's domain for client meetings.

**Connections:**
- **South:** `main_hallway` (open door during daytime, unlocked during nighttime)

**Containers:**
1. **Conference Table Storage**
   - **Position:** (4, 3) center of room
   - **Lock:** None
   - **Contents:** Presentation materials, company portfolio
   - **Narrative Purpose:** Flavor/atmosphere

**Interactive Objects:**
- **Whiteboard** (No encoding - clear for meeting space)
  - **Position:** (7, 4) on east wall
  - **Interaction:** Examine
  - **Result:** Shows legitimate security diagrams (cover business)
  - **Note:** Different from server room whiteboard with ROT13

**NPCs:**
- **Victoria Sterling** (In-Person - Daytime Only)
  - **Position:** (4, 3) at conference table
  - **Dialogue Trigger:** Automatic when player enters (Scene 3)
  - **Gives Items:** None (player clones RFID card via proximity)
  - **Objectives:**
    - `meet_victoria` - Completed automatically when dialogue starts
    - `clone_rfid_card` - Player uses RFID cloner device during meeting
  - **RFID Cloning Mechanic:** Player must remain within 2 GU of Victoria for 10 seconds
  - **Daytime Only:** Victoria not present during nighttime

**Objectives Completed Here:**
- `meet_victoria` - Meet Victoria Sterling at WhiteHat Security
- `clone_rfid_card` - Clone Victoria Sterling's executive keycard (PRIMARY - unlocks Act 2)

**LORE Fragments:** None

**Technical Notes:**
- Victoria NPC conditionally spawned: `time_of_day == "daytime" AND mission_phase == "act1_meeting"`
- RFID cloning minigame: proximity-based, 10-second timer, progress bar overlay
- Completing `clone_rfid_card` unlocks Aim 1.2 and Aim 1.3 (server room + executive office accessible nighttime)

---

### Room 3: Main Hallway

**ID:** `main_hallway`
**Dimensions:** 12 × 4 GU (18m × 6m) - Long corridor
**Usable Space:** 10 × 2 GU
**Type:** Corridor / Circulation
**Act:** Acts 1-3 (All phases)

**Description:**
Central corridor connecting all office areas. Corporate carpeting, recessed lighting (bright daytime, emergency lighting nighttime), office doors on both sides. Professional but utilitarian.

**Connections:**
- **South:** `reception_lobby` (open - always accessible)
- **West:** `conference_room_01` (open daytime, unlocked nighttime)
- **North:** `server_room` (RFID locked - requires cloned keycard)
- **East:** `executive_wing_hallway` (open - connects to executive office)

**Containers:** None (hallway - no storage)

**Interactive Objects:** None (circulation space)

**NPCs:**
- **Night Security Guard** (Patrol Route - Nighttime Only)
  - **Patrol Waypoints:**
    - Waypoint 1: (2, 1) near reception connection - 15 tick pause
    - Waypoint 2: (6, 1) center hallway - 15 tick pause
    - Waypoint 3: (9, 1) near server room door - 20 tick pause
    - Loop back to Waypoint 1
  - **Total Patrol Time:** ~60 seconds per loop
  - **Line of Sight:** 150 pixels (~7.5 GU), 120° cone in facing direction
  - **Dialogue Trigger:** If player detected
  - **Objectives:** Stealth challenge - avoid detection for `perfect_stealth`

**Objectives Completed Here:** None (circulation/navigation space)

**LORE Fragments:** None

**Technical Notes:**
- Guard patrol critical for stealth challenge
- Server room door requires `victoria_keycard_clone` item to unlock
- Executive wing accessible without lock (public-facing management area)

---

### Room 4: Server Room (PRIMARY INVESTIGATION HUB)

**ID:** `server_room`
**Dimensions:** 10 × 10 GU (15m × 15m)
**Usable Space:** 8 × 8 GU
**Type:** IT / Server Room / Data Center
**Act:** Act 2-3 (Nighttime - investigation hub)

**Description:**
Technical space with racks of servers (blinking LEDs - green/amber), three distinct workstation areas, whiteboard on north wall, filing cabinet, wall-mounted safe. HVAC hum provides constant background ambiance. Emergency lighting creates blue/green tech aesthetic mixed with shadows. This is the investigation nerve center where VM challenges and physical evidence converge.

**Connections:**
- **South:** `main_hallway` (RFID locked - requires `victoria_keycard_clone` item)
  - **Unlock Condition:** Player must have completed `clone_rfid_card` task
  - **Lock Type:** RFID keycard reader
  - **Alternative:** If victoria_trust >= 40, Victoria grants access (bypasses cloning)

**Containers:**
1. **Filing Cabinet (Northwest Corner)**
   - **Position:** (1, 7) in usable space
   - **Lock:** Physical lock (requires lockpicking)
   - **Contents:** Client list documents, network diagrams
   - **Narrative Purpose:** Additional evidence correlating with VM findings
   - **Objectives:** Optional - provides context for `decode_client_roster`

2. **Wall-Mounted Safe**
   - **Position:** (7, 7) on east wall
   - **Lock:** PIN lock (code: 2010)
   - **Contents:** LORE Fragment 2 "Q3 2024 Exploit Catalog"
   - **Narrative Purpose:** Optional LORE collection
   - **Objectives:** `lore_fragment_2` - Open Victoria's safe
   - **PIN Source:** Founding year on reception plaque

**Interactive Objects:**

1. **Whiteboard with ROT13 Message**
   - **Position:** (4, 7) on north wall
   - **Interaction:** Examine to photograph/copy encoded text
   - **Content:** "ZRRG JVGU GUR NEPUVGRPG - CEVBEVGVMR VASENFGEHPGHER RKCYBVGF"
   - **Decoded:** "MEET WITH THE ARCHITECT - PRIORITIZE INFRASTRUCTURE EXPLOITS"
   - **Objectives:** `decode_whiteboard` - Decode ROT13 message
   - **Workflow:** Examine whiteboard → Copy text → Decode at CyberChef workstation

2. **VM Access Terminal (Left Workstation)**
   - **Position:** (2, 4) in usable space
   - **Interaction:** Access VM challenges (terminal minigame)
   - **Purpose:** Player runs nmap, netcat, HTTP analysis, Metasploit
   - **Network:** 192.168.100.0/24 (Zero Day training network)
   - **Objectives:**
     - `scan_network` - nmap port scanning
     - `ftp_banner` - Banner grabbing
     - `http_analysis` - HTTP service analysis
     - `distcc_exploit` - distcc exploitation (CRITICAL - triggers M2 revelation)

3. **CyberChef Workstation (Right Workstation)**
   - **Position:** (6, 4) in usable space
   - **Interaction:** Decoding station for ROT13, Hex, Base64
   - **Purpose:** Player decodes messages found elsewhere
   - **Objectives:**
     - `decode_whiteboard` - ROT13 decode
     - `decode_client_roster` - Hex decode (from Victoria's computer)
     - `lore_fragment_3` - Double-decode (ROT13+Base64 from USB drive)

4. **Drop-Site Terminal (Center Workstation)**
   - **Position:** (4, 4) center of room
   - **Interaction:** Submit VM flags, receive Agent 0x99 messages
   - **Purpose:** Flag submission unlocks narrative intel
   - **Objectives:**
     - All VM flag submissions (`scan_network`, `ftp_banner`, `http_analysis`, `distcc_exploit`)
     - Triggers Agent 0x99 event conversations

5. **Operational Logs File (Event-Spawned)**
   - **Position:** Appears on drop-site terminal after `distcc_exploit` completed
   - **Interaction:** Examine text file
   - **Content:** "ProFTPD exploit sold to Ransomware Inc for $12,500 (healthcare premium)"
   - **Objectives:** `find_operational_logs` - **MIDPOINT TWIST** (M2 hospital connection)
   - **Event Trigger:** Spawns when `distcc_exploit` task completed

**NPCs:**
- **Agent 0x99** (Phone/Event-Triggered)
  - **Mode:** Not physically present (phone chat + event-triggered messages)
  - **Event Triggers:**
    - When `distcc_exploit` completed → Auto-triggered conversation "M2 Connection Revealed"
    - When all evidence gathered → Available for debrief preparation
  - **Dialogue Purpose:** Handler guidance, M2 revelation response
  - **Objectives:** Narrative progression via event system

**Objectives Completed Here:**
- **VM Flag Tasks (Aim 1.2):**
  - `scan_network` - Use nmap to scan training network
  - `ftp_banner` - Connect to FTP and extract banner intelligence
  - `http_analysis` - Analyze HTTP service and decode Base64 pricing data
  - `distcc_exploit` - Exploit legacy distcc service (CRITICAL)

- **Physical Evidence Tasks (Aim 1.3):**
  - `decode_whiteboard` - Decode ROT13 message on whiteboard
  - `find_operational_logs` - Correlate VM logs with physical evidence (M2 revelation)

- **Optional:**
  - `lore_fragment_2` - Open safe with PIN 2010

**LORE Fragments:**
- **Fragment 2:** "Q3 2024 Exploit Catalog" (in wall safe, PIN 2010)

**Technical Notes:**
- **RFID Door Lock:** Requires `victoria_keycard_clone` item OR `victoria_trust >= 40`
- **VM Terminal:** Separate minigame system for command input
- **CyberChef:** Decoding interface (ROT13, Hex, Base64 supported)
- **Drop-Site Terminal:** Flag submission triggers Ink tags + event conversations
- **Event Spawn:** operational_logs.txt appears after distcc_exploit flag submitted
- **Agent 0x99 Event:** Auto-triggers when distcc_exploit completed (M2 revelation cutscene)

---

**Status:** 🔄 IN PROGRESS (Part 2/4 - 4 rooms complete)
**Next:** Executive office, James's office, executive wing hallway
