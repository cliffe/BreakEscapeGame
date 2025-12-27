# Stage 9 Quick Start Guide

**Mission:** Mission 3 - Ghost in the Machine
**Purpose:** Condensed implementation checklist for rapid startup
**For:** Developers beginning Stage 9 assembly
**Date:** 2025-12-27

---

## Prerequisites Checklist

**Before Starting:**
- [ ] Read `/stages/stage_8/validation_report.md` (approval confirmation)
- [ ] Read `/stages/stage_9_prep/IMPLEMENTATION_ROADMAP.md` (full guide)
- [ ] Install Inky editor (https://github.com/inkle/inky)
- [ ] Install Docker Engine 20.10+ and Docker Compose 1.29+
- [ ] Configure game engine with Ink runtime integration

---

## Critical Path (Minimum Viable Implementation)

### Step 1: Compile Ink Scripts (4-6 hours)

**Priority:** ⚠️ CRITICAL BLOCKER

```bash
# Open each .ink file in Inky editor:
cd planning_notes/.../m03_ghost_in_the_machine/stages/stage_7/

# Files to compile (in order):
1. m03_opening_briefing.ink
2. m03_npc_victoria.ink
3. m03_npc_receptionist.ink
4. m03_npc_guard.ink
5. m03_james_choice.ink
6. m03_terminal_vm.ink
7. m03_terminal_cyberchef.ink
8. m03_terminal_dropsite.ink
9. m03_phone_agent0x99.ink
10. m03_closing_debrief.ink
```

**Validation:**
- [ ] All 9 files compile without errors
- [ ] .json output files generated
- [ ] Test load in game's Ink runtime

---

### Step 2: Setup VM Network (6-8 hours)

**Priority:** HIGH (Required for technical challenges)

```bash
# Create project structure
mkdir -p m03_ghost_vm_network/{distcc,ftp-data,http-data/pricing}
cd m03_ghost_vm_network

# Copy configurations from /stages/stage_9_prep/vm_infrastructure_setup.md:
# - docker-compose.yml (lines 46-100)
# - proftpd.conf (lines 110-139)
# - distcc/Dockerfile (lines 166-200)
# - distcc/operational_logs.txt (lines 202-236)
# - http-data/pricing/data.txt (lines 256-276)

# Build and start
docker-compose up -d

# Verify services
docker ps  # Should show 3 running containers
docker exec -it m03_ftp_server nc localhost 21  # Should show ProFTPD banner
```

**Validation:**
- [ ] FTP server responds on 192.168.100.10:21
- [ ] distcc responds on 192.168.100.20:3632
- [ ] HTTP serves pricing data on 192.168.100.30:80
- [ ] Player VM can reach all services

---

### Step 3: Create 7 Room JSONs (10-12 hours)

**Priority:** HIGH (Core gameplay environment)

**Reference:** `/stages/stage_5/room_design.md`

**Implementation Order:**
1. Reception Lobby (lines 40-99) - Entry point
2. Main Hallway (lines 154-195) - Hub corridor
3. Conference Room (lines 102-151) - RFID cloning location
4. Server Room (lines 198-309) - Investigation hub ⭐
5. Executive Wing Hallway (lines 312-341) - Connector
6. Executive Office (lines 344-422) - Victoria's workspace
7. James's Office (lines 426-487) - Moral choice trigger

**Each Room Needs:**
- Background image (or placeholder colored rectangle)
- Dimensions (GU measurements in room_design.md)
- Interactive props (computers, safes, filing cabinets)
- Exits (directional connections to other rooms)
- Lighting state (daytime/nighttime where applicable)

**Use Placeholders Initially:**
- Colored backgrounds with room names
- Text labels for interactive objects
- Simple shapes for props

---

### Step 4: Integrate NPCs (6-8 hours)

**Priority:** HIGH (Core narrative)

**Critical NPCs:**

1. **Victoria Sterling** - `m03_npc_victoria.ink`
   - Location: Conference Room (daytime), Executive Office (nighttime optional)
   - Portraits needed: 5 expressions (neutral, persuasive, defensive, vulnerable, defiant)
   - Key variables: `victoria_influence`, `victoria_suspicious`, `victoria_trusts_player`

2. **Agent 0x99** - `m03_phone_agent0x99.ink`
   - Trigger: After `flag{distcc_legacy_compromised}` submitted
   - Portrait: `agent_0x99_concerned.png`
   - **Critical:** M2 revelation scene

3. **James Park** - `m03_james_choice.ink`
   - Trigger: Examining diary in James's Office
   - Portraits: 3 expressions (neutral, guilty, desperate)

4. **Guard** - `m03_npc_guard.ink`
   - Location: Main Hallway patrol (nighttime)
   - Detection system required

5. **Receptionist** - `m03_npc_receptionist.ink`
   - Location: Reception Lobby (daytime)
   - Simple dialogue tree

---

### Step 5: Implement 4 Core Challenges (8-10 hours)

**Priority:** HIGH (Gameplay mechanics)

**Challenge 1: RFID Cloning** (Scenario Initialization)
- Trigger: Player near Victoria in Conference Room
- Mechanic: Stay within 2m for 10 seconds
- UI: Progress bar
- Success: Unlock Executive access

**Challenge 2: VM Terminal** (Technical Hub)
- nmap scan → `flag{network_scan_complete}`
- netcat FTP banner → `flag{ftp_intel_gathered}`
- curl HTTP + decode → `flag{pricing_intel_decoded}`
- distcc exploit → `flag{distcc_legacy_compromised}` ⭐ M2 trigger

**Challenge 3: CyberChef Workstation** (Decoding)
- ROT13 decoder (whiteboard message)
- Base64 decoder (HTTP pricing data)
- Hex decoder (client roster)
- Cascading: Base64→ROT13 (LORE Fragment 3)

**Challenge 4: Safe PIN Entry**
- Location: Server Room safe
- PIN: 2010 (from Reception founding plaque)
- Contains: LORE Fragment 2 (Exploit Catalog)

---

### Step 6: Objectives System (4-6 hours)

**Priority:** HIGH (Player guidance)

**Reference:** `/stages/stage_4/objectives.json`

**Structure:**
- 3 Aims: `establish_cover`, `network_recon`, `gather_evidence`
- 11 Primary tasks
- 4 Optional objectives

**Progressive Unlocking:**
- `network_recon` unlocks when `clone_rfid_card` completes
- `gather_evidence` unlocks when `clone_rfid_card` completes
- `moral_choices` unlocks when `distcc_exploit` completes (M2 revelation)

**Task Completion Triggers:**
- Ink tag: `#complete_task:<task_id>`
- Flag submission: Auto-complete corresponding task
- Object interaction: Examining LORE fragment

---

### Step 7: M2 Revelation Event (2-4 hours)

**Priority:** ⭐ CRITICAL (Emotional turning point)

**Trigger Sequence:**
1. Player exploits distcc service
2. Submits `flag{distcc_legacy_compromised}` at drop-site terminal
3. Operational logs display: "$12,500 hospital exploit sale to GHOST"
4. **Phone call initiates:** Agent 0x99 reveals St. Catherine's Hospital attack

**Requirements:**
- Phone call overlay UI
- `m03_phone_agent0x99.ink` dialogue integration
- Portrait change: `agent_0x99_concerned.png`
- Music cue: M2 revelation sting
- Unlocks: `moral_choices` optional objective

**Emotional Impact:** This is the mission's emotional climax. Test multiple times to ensure timing and delivery are effective.

---

### Step 8: Basic Testing (4-6 hours)

**Priority:** HIGH (Quality assurance)

**Critical Path Playthrough:**
1. Opening briefing plays correctly
2. Victoria conversation works (RFID cloning triggers)
3. Nighttime transition occurs
4. All 7 rooms accessible with correct exits
5. VM terminal challenges solvable
6. All 4 VM flags validate correctly
7. M2 revelation triggers after distcc flag
8. James choice presents correctly
9. Victoria confrontation offers all options
10. Closing debrief reflects player choices

**Target Time:** 45-60 minutes for complete playthrough

**Test Variations:**
- Victoria recruitment ending
- Victoria arrest ending
- James protected vs. exposed
- Perfect stealth achievement

---

## Asset Placeholder Strategy

**Character Portraits:**
```
victoria_neutral.png → Colored square with "V" text
james_guilty.png → Colored square with "J" text
agent_0x99_concerned.png → Colored square with "A" text
```

**Room Backgrounds:**
```
reception_bg.png → Solid color (#3A6B8C) with "RECEPTION" text
server_room_bg.png → Solid color (#2C3E50) with "SERVER ROOM" text
```

**Interactive Objects:**
```
computer_sprite.png → Simple rectangle with "COMPUTER" label
safe_sprite.png → Rectangle with "SAFE" label
```

**Benefits:**
- Implementation can proceed immediately
- Art team works in parallel
- Swap placeholders for final assets later

---

## Time Estimate (Minimum Viable)

**Critical Path Only:**
- Step 1 (Ink): 4-6 hours
- Step 2 (VM): 6-8 hours
- Step 3 (Rooms): 10-12 hours
- Step 4 (NPCs): 6-8 hours
- Step 5 (Challenges): 8-10 hours
- Step 6 (Objectives): 4-6 hours
- Step 7 (M2 Event): 2-4 hours
- Step 8 (Testing): 4-6 hours

**Total:** 44-60 hours (6-8 working days)

**With Polish:** 68-102 hours (9-13 working days)

---

## Common Pitfalls

**Ink Integration:**
- ❌ Forgetting to handle `#speaker:<name>` tags
- ❌ Missing `#complete_task:<task_id>` tags
- ❌ Variable persistence across conversation knots
- ✅ Test each Ink script individually before full integration

**VM Network:**
- ❌ Containers not on same Docker network
- ❌ Game VM can't reach 192.168.100.x subnet
- ❌ Services not starting (check logs: `docker-compose logs`)
- ✅ Follow VM infrastructure guide exactly (line-by-line)

**M2 Revelation:**
- ❌ Phone call triggers too early/late
- ❌ Music cue doesn't play
- ❌ Portrait doesn't change
- ✅ Test distcc flag → phone call sequence repeatedly

**Objectives System:**
- ❌ Tasks don't unlock progressively
- ❌ Flag submission doesn't complete tasks
- ❌ Optional objectives not tracked
- ✅ Verify objectives.json structure matches game's system

---

## Success Checklist

**Minimum Viable Mission:**
- [ ] All 9 Ink scripts compiled and integrated
- [ ] VM network functional (all 4 flags validate)
- [ ] All 7 rooms accessible with correct exits
- [ ] Victoria conversation (RFID cloning works)
- [ ] M2 revelation triggers correctly
- [ ] James choice presents
- [ ] Victoria confrontation offers 3 options
- [ ] Closing debrief plays
- [ ] Player can complete mission start-to-finish (45-60 min)

**When Above Complete:** Mission 3 is playable and testable.

---

## Next Steps After MVP

**Polish Phase:**
1. Replace placeholder assets with final art
2. Add sound effects (flag submission, RFID clone, lockpicking)
3. Add music tracks (4-5 tracks)
4. Implement stealth system (guard patrol)
5. Add LORE fragments (3 documents)
6. Implement accessibility features
7. Playtesting and iteration

**Future Enhancements:**
1. Post-mission knowledge check
2. Additional LORE fragments (5-6 total)
3. New Game Plus mode
4. Advanced moral choice branches

---

## Support Documents

**Full Implementation Guide:** `/stages/stage_9_prep/IMPLEMENTATION_ROADMAP.md` (437 lines)
**Asset Requirements:** `/stages/stage_9_prep/asset_manifest.md` (421 lines)
**VM Setup:** `/stages/stage_9_prep/vm_infrastructure_setup.md` (549 lines)
**Validation Report:** `/stages/stage_8/validation_report.md` (1,909 lines)

---

**Quick Start Version:** 1.0
**Last Updated:** 2025-12-27
**Status:** Ready for immediate use

Begin with Step 1 (Ink Compilation) and work sequentially through Steps 1-8 for fastest path to playable mission.
