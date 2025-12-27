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

### Room 5: Executive Wing Hallway

**ID:** `executive_wing_hallway`
**Dimensions:** 8 × 4 GU (12m × 6m)
**Usable Space:** 6 × 2 GU
**Type:** Corridor
**Act:** Acts 1-3 (All phases)

**Description:**
Short hallway connecting main circulation to executive offices. More upscale than main hallway: wood paneling, framed corporate achievements, better carpet. Represents management tier of organization.

**Connections:**
- **West:** `main_hallway` (open - always accessible)
- **North:** `executive_office` (locked - requires lockpicking OR victoria_trust >= 40)
- **South:** `james_office` (unlocked - public consultant office)

**Containers:** None

**Interactive Objects:** None

**NPCs:** None

**Objectives Completed Here:** None (circulation space)

**LORE Fragments:** None

**Technical Notes:**
- Executive office door: Physical lock (lockpicking) OR granted access if high trust
- James's office: Unlocked (he's just a consultant, not executive)

---

### Room 6: Executive Office (Victoria Sterling's Workspace)

**ID:** `executive_office`
**Dimensions:** 10 × 8 GU (15m × 12m)
**Usable Space:** 8 × 6 GU
**Type:** Private Office / Executive
**Act:** Act 2-3 (Nighttime investigation)

**Description:**
Victoria Sterling's private office. Expensive desk, leather chair, floor-to-ceiling windows overlooking city, corporate art. Professional facade with criminal evidence hidden in plain sight. Locked filing cabinet, wall safe, executive computer. No Victoria present during nighttime (she's left for the day).

**Connections:**
- **South:** `executive_wing_hallway` (locked door - lockpicking OR victoria_trust >= 40)
  - **Lock Type:** Physical lock (lockpicking)
  - **Alternative:** If victoria_trust >= 40, Victoria grants access (social engineering path)

**Containers:**

1. **Filing Cabinet**
   - **Position:** (1, 5) northwest corner
   - **Lock:** Physical lock (lockpicking)
   - **Contents:** LORE Fragment 1 "Zero Day: A Brief History"
   - **Narrative Purpose:** LORE collection
   - **Objectives:** `lore_fragment_1` - Find document detailing Zero Day's founding

2. **Desk Drawer (Hidden Compartment)**
   - **Position:** (4, 3) at desk
   - **Lock:** None (but hidden - requires examination)
   - **Contents:** Hidden USB drive with double-encoded message
   - **Narrative Purpose:** Advanced encoding puzzle
   - **Objectives:** `lore_fragment_3` - Decode double-encoded USB drive message

3. **Wall Safe**
   - **Position:** (7, 5) behind painting on east wall
   - **Lock:** PIN lock (code: 2010)
   - **Contents:** LORE Fragment 2 DUPLICATE NOTE: This should be in server room instead
   - **Narrative Purpose:** CORRECTION - This safe should contain different evidence
   - **Technical Note:** Actually, safe in SERVER ROOM has LORE 2. This executive safe should have exploit catalog or evidence documents

**Interactive Objects:**

1. **Victoria's Executive Computer**
   - **Position:** (4, 3) on desk
   - **Interaction:** Login (requires password OR bypass)
   - **Purpose:** Access email drafts, hex-encoded client files
   - **Contents:**
     - Email draft (Base64): Pricing update to Cipher
     - Client roster file (Hex-encoded): Zero Day Syndicate client list
   - **Objectives:**
     - `access_victoria_computer` - Access Victoria's computer
     - `decode_client_roster` - Decode hex-encoded client roster (at CyberChef)

2. **Hidden USB Drive (in desk drawer)**
   - **Position:** (4, 3) hidden compartment
   - **Interaction:** Find via careful desk examination
   - **Contents:** File with double-encoding (Base64 → ROT13)
   - **Decoded Message:** The Architect's directive about Phase 1
   - **Objectives:** `lore_fragment_3` - Decode double-encoded message

**NPCs:** None (Victoria not present during nighttime infiltration)

**Objectives Completed Here:**
- **Physical Evidence Tasks:**
  - `access_victoria_computer` - Access executive computer
  - `decode_client_roster` - Find hex-encoded files (decode at server room CyberChef)

- **Optional LORE:**
  - `lore_fragment_1` - Filing cabinet (lockpick)
  - `lore_fragment_3` - Hidden USB drive (double-encode puzzle)

**LORE Fragments:**
- **Fragment 1:** "Zero Day: A Brief History" (filing cabinet, lockpick required)
- **Fragment 3:** "The Architect's Directive" (hidden USB, double-encode: Base64+ROT13)

**Technical Notes:**
- Door lock: Physical lock (lockpicking skill) OR social engineering bypass (victoria_trust >= 40)
- Computer password: Can be found via investigation OR bypass via hacking minigame
- USB drive: Hidden interaction (requires "Search desk carefully" action)
- Hex-encoded files must be decoded at CyberChef workstation in server room (backtracking)

---

### Room 7: James Park's Office (Optional Investigation)

**ID:** `james_office`
**Dimensions:** 8 × 6 GU (12m × 9m)
**Usable Space:** 6 × 4 GU
**Type:** Consultant Office
**Act:** Act 2 (Optional - moral complexity discovery)

**Description:**
Small consultant office. Modest desk with dual monitors, OSCP and CEH certifications framed on wall, family photos prominent. Neat, organized, genuinely professional. Evidence of ethical hacking work: penetration testing reports for hospitals, banks, legitimate clients. **This room establishes James's innocence.**

**Connections:**
- **North:** `executive_wing_hallway` (unlocked - James is just a consultant)

**Containers:**
1. **Desk Drawer**
   - **Position:** (3, 2)
   - **Lock:** None (unlocked - James has nothing to hide)
   - **Contents:** Performance review document (exceptional ethical standards)
   - **Narrative Purpose:** Establishes innocence
   - **Objectives:** `james_choice_made` trigger - Discovery unlocks moral choice

**Interactive Objects:**

1. **Family Photo on Desk**
   - **Position:** (3, 2) prominently displayed
   - **Interaction:** Examine
   - **Content:** James with wife Emily and daughter Sophie (age 4)
   - **Description:** Sophie holding sign "My Daddy is a Good Hacker!"
   - **Narrative Purpose:** Emotional impact - humanizes potential collateral damage
   - **Objectives:** Part of james_innocence_confirmed discovery

2. **Computer (James's Workstation)**
   - **Position:** (3, 3)
   - **Interaction:** Optional - examine emails
   - **Contents:** Email to wife Emily about Sophie's school presentation
   - **Narrative Purpose:** Further establishes innocence and family connection
   - **Objectives:** Optional depth for moral choice

3. **Certification Wall**
   - **Position:** (1, 3) west wall
   - **Interaction:** Examine
   - **Content:** OSCP (Offensive Security Certified Professional), CEH (Certified Ethical Hacker)
   - **Narrative Purpose:** Proves James's ethical hacking background
   - **Objectives:** Reinforces innocence

**NPCs:** None (James not present during nighttime - he's home with family)

**Objectives Completed Here:**
- **Optional Moral Choice:**
  - Discovery of innocence evidence triggers `james_choice_made` opportunity
  - Player can choose: warn James, plant evidence, or ignore

**LORE Fragments:** None

**Technical Notes:**
- Room is OPTIONAL - player doesn't need to visit for main objectives
- Discovering innocence evidence sets `james_innocence_confirmed = true`
- This unlocks moral choice dialogue in later scene
- All containers unlocked (James has nothing to hide)
- Evidence of innocence: performance review, family photo, certifications, email

---

## Overall Map Layout

```
                    ┌─────────────────┐
                    │  Server Room    │
                    │    (10×10)      │
                    │   [RFID LOCK]   │
                    └────────┬────────┘
                             │
┌──────────────┐    ┌────────┴─────────┐    ┌──────────────────┐
│ Conference   │────│  Main Hallway    │────│ Executive Wing   │
│   Room       │    │     (12×4)       │    │    Hallway       │
│  (10×8)      │    │  [Guard Patrol]  │    │     (8×4)        │
└──────────────┘    └────────┬─────────┘    └────┬─────┬───────┘
                             │                   │     │
                    ┌────────┴────────┐          │     │
                    │  Reception      │     ┌────┴─┐   │
                    │   Lobby         │     │James'│   │
                    │    (8×6)        │     │Office│   │
                    │  [START/ENTRY]  │     │(8×6) │   │
                    └─────────────────┘     └──────┘   │
                                                        │
                                                  ┌─────┴──────┐
                                                  │ Executive  │
                                                  │   Office   │
                                                  │   (10×8)   │
                                                  │  [LOCKED]  │
                                                  └────────────┘
```

**Key:**
- [RFID LOCK] - Requires cloned Victoria keycard
- [LOCKED] - Requires lockpicking OR high victoria_trust
- [Guard Patrol] - Security guard patrols this area (nighttime)
- [START/ENTRY] - Player enters here (both daytime and nighttime)

**Room Count:** 7 rooms total
**Critical Path:** Reception → Hallway → Conference Room (daytime) → Server Room (nighttime) → Evidence gathering
**Optional Path:** Executive Office, James's Office

---

## Progressive Unlocking Flow

### Initial State (Mission Start - Daytime Act 1)

**✅ Accessible:**
- Reception Lobby (starting room)
- Main Hallway
- Conference Room (Victoria meeting location)

**🔒 Locked:**
- Server Room (RFID locked - requires Victoria's keycard clone)
- Executive Office (physical lock - requires lockpicking OR victoria_trust >= 40)
- James's Office (unlocked but not visited yet)
- Executive Wing Hallway (accessible but leads to locked areas)

**Mission Phase:** Daytime undercover meeting with Victoria

---

### After Task: clone_rfid_card (End of Act 1)

**🔓 Unlocks:**
- Server Room via cloned RFID keycard
- **Alternative Path:** If victoria_trust >= 40, Victoria grants server room access voluntarily

**New Accessible:**
- Server Room (PRIMARY INVESTIGATION HUB)
  - VM terminal for challenges
  - CyberChef workstation for decoding
  - Drop-site terminal for flag submission

**Mission Transition:** Daytime → Nighttime (time skip to 2:00 AM)

---

### After Nighttime Infiltration Begins (Act 2 Start)

**✅ Now Accessible:**
- All daytime rooms (but empty - no NPCs except guard)
- Server Room (if RFID cloned OR trust path)
- Executive Wing Hallway (can explore)
- James's Office (optional - unlocked)

**🔒 Still Locked:**
- Executive Office (lockpicking required OR victoria_trust >= 40)

**New Challenges:**
- Night security guard on patrol (stealth challenge)
- RFID door to server room (unless already have keycard/access)

---

### After Task: access_victoria_computer

**🔓 Unlocks:**
- Executive Office interior (via lockpicking door OR social engineering)
- Access to Victoria's computer (password required OR hack)
- Filing cabinet, desk drawer, wall safe all become accessible

**New Accessible:**
- LORE Fragment 1 (filing cabinet, requires lockpicking)
- LORE Fragment 3 (hidden USB drive in desk)
- Hex-encoded client roster (computer file)
- Email drafts (computer)

**Backtracking Required:**
- Must return to Server Room CyberChef to decode hex files

---

### After Task: distcc_exploit (MIDPOINT TWIST)

**🔓 Event-Unlocked:**
- Operational logs file spawns on drop-site terminal
- Agent 0x99 auto-triggered conversation (M2 revelation)

**New Intelligence:**
- M2 hospital connection revealed
- ProFTPD sale to GHOST for $12,500 discovered
- Campaign narrative escalation

---

### Final State (All Evidence Collected)

**✅ All Accessible:**
- All 7 rooms fully explored
- All containers opened (lockpicking, PIN codes)
- All evidence gathered (physical + digital)
- All VM flags submitted

**Mission Progression:**
- Optional: Victoria confrontation
- Optional: James protection choice
- Mission completion criteria met

---

## Lock Variety Analysis

### Lock Types Used: ✅ 5 different types

- ✅ **RFID Keycard** (social/technical)
- ✅ **Physical Locks / Lockpicking** (skill-based)
- ✅ **PIN Codes** (cognitive/investigation)
- ✅ **Passwords** (hacking/investigation)
- ✅ **Hidden Items** (exploration/examination)

**Variety Score:** Excellent - 5 different lock types across 7 rooms

### Lock Progression Order:

#### Lock 1: RFID Keycard Clone (Social Engineering + Technical)
- **Location:** Server Room door
- **Unlock Method:** Clone Victoria's keycard during meeting (proximity-based minigame)
- **Difficulty:** Medium
- **Rewards:** Access to server room (PRIMARY HUB)
- **Blocks Critical Path:** YES (must access server room for VM challenges)
- **Type:** RFID/Keycard

#### Lock 2: PIN Code Safe (Cognitive Discovery)
- **Location:** Server Room wall safe
- **Unlock Method:** Discover founding year (2010) from reception plaque
- **Difficulty:** Easy (hint in plain sight)
- **Rewards:** LORE Fragment 2 "Exploit Catalog"
- **Blocks Critical Path:** NO (optional LORE)
- **Type:** PIN

#### Lock 3: Executive Office Door (Physical Lock)
- **Location:** Executive Office entrance
- **Unlock Method:** Lockpicking OR victoria_trust >= 40 (social engineering bypass)
- **Difficulty:** Medium
- **Rewards:** Access to Victoria's workspace (computer, filing cabinet, LORE)
- **Blocks Critical Path:** NO (server room has enough for minimum objectives)
- **Type:** Physical Lock / Lockpicking

#### Lock 4: Filing Cabinet in Executive Office (Physical Lock)
- **Location:** Executive Office filing cabinet
- **Unlock Method:** Lockpicking
- **Difficulty:** Easy (lockpicking skill)
- **Rewards:** LORE Fragment 1 "Zero Day Origins"
- **Blocks Critical Path:** NO (optional LORE)
- **Type:** Physical Lock / Lockpicking

#### Lock 5: Filing Cabinet in Server Room (Physical Lock)
- **Location:** Server Room filing cabinet
- **Unlock Method:** Lockpicking
- **Difficulty:** Easy
- **Rewards:** Additional client documents
- **Blocks Critical Path:** NO (optional context)
- **Type:** Physical Lock / Lockpicking

#### Lock 6: Victoria's Computer (Password)
- **Location:** Executive Office computer
- **Unlock Method:** Find password hints OR bypass via hacking minigame
- **Difficulty:** Medium
- **Rewards:** Hex-encoded client roster, email drafts
- **Blocks Critical Path:** Partially (required for `access_victoria_computer` task)
- **Type:** Password

#### Lock 7: Hidden USB Drive (Exploration)
- **Location:** Executive Office desk hidden compartment
- **Unlock Method:** Careful desk examination (no lock, just hidden)
- **Difficulty:** Easy (search action)
- **Rewards:** LORE Fragment 3 (double-encoded message)
- **Blocks Critical Path:** NO (optional LORE)
- **Type:** Hidden Item

### Critical Path Locks:
1. **RFID Keycard** (server room) → **REQUIRED**
2. **Passwords** (Victoria's computer) → **REQUIRED** for full evidence

**Optional Locks:** PIN safe, filing cabinets, hidden USB (all LORE/optional)

### Validation Checklist:

- ✅ At least 3 different lock types used (5 total)
- ✅ Keys used BEFORE lockpick obtained: N/A (no traditional keys in this mission)
- ✅ Locks ordered easy → medium → hard: YES (founding year → RFID clone → lockpicking + passwords)
- ✅ Lockpick comes after key-based progression: N/A (lockpick pre-existing skill, not obtained mid-mission)
- ✅ No "same-y" gameplay: Excellent variety (social engineering, investigation, technical, skill-based)
- ✅ PIN codes have discoverable hints: YES (2010 founding year on plaque)

**Design Notes:**
- Mission focuses on **social engineering** (RFID cloning) and **investigation** (finding passwords, decoding) rather than traditional key-finding
- Lockpicking is a **supplementary skill** for optional content, not critical path
- RFID cloning mechanic is NEW for Mission 3, providing fresh gameplay
- Lock variety supports multiple playstyles: stealth, social engineering, technical exploitation

---

**Status:** 🔄 IN PROGRESS (Part 5/6)
**Next:** Container summary, NPC placement, hybrid architecture integration
