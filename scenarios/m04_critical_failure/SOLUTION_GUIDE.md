# Mission 4: "Critical Failure" - Solution Guide

**Mission ID:** m04_critical_failure
**Difficulty:** 2 (Intermediate)
**Playtime:** 60-80 minutes
**CyBOK Areas:** Network Security, System Security, Infrastructure Security, Attack & Defense, Human Factors, Incident Response

---

## Mission Overview

ENTROPY's Critical Mass cell has infiltrated a water treatment facility serving 240,000 residents. They've compromised the SCADA network controlling chlorine dosing systems and installed a remote-triggered attack that could cause mass casualties through acute chlorine poisoning.

**Your Mission:**
1. Infiltrate the facility using EPA auditor cover
2. Investigate the SCADA compromise
3. Disable all attack vectors (physical bypasses, SCADA malware, remote trigger)
4. Neutralize ENTROPY operatives and capture their leader, Voltage

---

## Critical Path Walkthrough

### Phase 1: Infiltration & Initial Discovery

**1.1 Opening Briefing**
- Location: Starting area
- NPC: Agent 0x99 (automatic phone call)
- Briefing covers:
  - Chemical threat (chlorine dosing attack)
  - Critical Mass cell (4 operatives: Cipher, Relay, Static, Voltage)
  - Cover identity (EPA auditor)
  - Combat authorization (first hostile mission)
- Completion: Triggers Task 1.1 "Receive mission briefing"

**1.2 Entry Checkpoint**
- Location: Main Entrance
- NPC: Security Guard
- Challenge: Social engineering to gain entry
- Options:
  - **Present EPA auditor credentials** (smooth path)
  - **Smooth talk** (requires persuasion)
  - **Find alternative entry** (explore perimeter)
- Recommended: Present credentials for fastest entry
- Completion: Triggers Task 1.2 "Infiltrate facility"

**1.3 Meet Robert Chen**
- Location: Control Room
- NPC: Robert Chen (facility manager)
- Initial State: Defensive, suspicious of surprise inspection
- CRITICAL DECISION: Reveal true mission or maintain cover?

  **Option A: Reveal Truth (Recommended)**
  - Increases `chen_trust_level` (0-100 scale)
  - Unlocks `chen_is_ally = true`
  - Benefits: SCADA technical support, phone access, task hints
  - Risk: If revealed too early, may compromise operational security

  **Option B: Maintain Cover**
  - Chen remains wary but compliant
  - Limited cooperation, no phone support
  - Must discover SCADA anomalies independently

- Recommended Approach: Engage in conversation, observe Chen's competence and safety concerns, then reveal truth when he shows alarm about SCADA anomalies
- Completion: Triggers Task 1.3 "Meet facility manager"

**1.4 SCADA Anomaly Discovery**
- Location: Control Room (SCADA terminal)
- Object: SCADA Monitoring Terminal
- Investigation reveals:
  - Chlorine parameters changing without manual input
  - Network traffic to backup server (192.168.100.10)
  - Automated control inconsistencies
  - CONCLUSION: SCADA network compromised

- If Chen is an ally: He explains the threat and urgency
- If Chen is not an ally: You discover anomalies independently
- Completion: Triggers Task 1.4 "Identify SCADA anomalies"
- **Objective 1 Complete:** "Investigate the Threat"

---

### Phase 2: Penetration Testing & Intelligence Gathering

**2.1 Server Room Access**
- Location: Server Room (through Treatment Floor)
- Access Requirements:
  - **Level 2 Keycard** (obtainable from defeating Operative Cipher or from Chen if ally)
  - Treatment Floor must be traversed (contains Operative Cipher)

**2.2 VM Investigation**
- Location: Server Room
- Object: VM Launcher Terminal
- VM Network: 192.168.100.10 (SCADA backup server)
- Required Skills: Nmap, service enumeration, vulnerability exploitation

**VM Attack Chain:**

```bash
# Step 1: Network Scanning
nmap -sV 192.168.100.10
# Discovers: FTP (21), HTTP (80), distcc (3632)

# Step 2: Service Enumeration
ftp 192.168.100.10
# Anonymous login enabled
# Download: operation_critical_mass.txt
# FLAG 1: Submit at drop-site terminal

# Step 3: HTTP Investigation
curl http://192.168.100.10
# Reveals: SCADA parameter logs
# FLAG 2: Submit at drop-site terminal

# Step 4: distcc Exploitation (CVE-2004-2687)
# Use Metasploit or manual exploit
msfconsole
use exploit/unix/misc/distcc_exec
set RHOST 192.168.100.10
exploit
# Gains low-privilege shell
# FLAG 3: Submit at drop-site terminal

# Step 5: Privilege Escalation (sudo Baron - CVE-2021-3156)
# Exploit sudo vulnerability for root access
# FLAG 4: Submit at drop-site terminal
```

**2.3 Intelligence Submission**
- Location: Server Room
- Object: Flag Drop-Site Terminal
- Submit all 4 flags obtained from VM
- Each flag submission:
  - Increases `handler_confidence` (tracked by Agent 0x99)
  - Provides attack intelligence
  - Completion: Task 2.1, 2.2, 2.3, 2.4 (one per flag)

**2.4 Event-Triggered Phone Call**
- Trigger: Entering Server Room OR submitting first flag
- NPC: Agent 0x99 (automatic call)
- Provides strategic guidance about attack mechanism
- Optional: Request navigation help, mission advice

- **Objective 2 Complete:** "Gather Intelligence"

---

### Phase 3: Neutralize Attack & Confront Operatives

**3.1 Combat Encounters (Optional but Recommended)**

Mission 4 introduces combat. Stealth is possible, but defeating operatives provides:
- Keycards for area access
- Intelligence about Voltage and The Architect
- Reduced threat during final confrontation

**Operative Cipher**
- Location: Treatment Floor (patrols near dosing stations)
- Threat Level: Moderate
- Combat: Tutorial-level difficulty
- Drops: Level 2 Keycard (server room access)
- Intelligence: Radio encryption keys, attack timeline
- Defeat triggers: Task 3.1a "Neutralize Operative Cipher"

**Operative Relay**
- Location: Chemical Storage
- Threat Level: Moderate
- Combat: Standard difficulty
- Drops: Master Keycard (maintenance wing access)
- Intelligence: Voltage's location, attack trigger mechanism
- Defeat triggers: Task 3.1b "Neutralize Operative Relay"

**Operative Static**
- Location: Maintenance Wing (supporting Voltage)
- Threat Level: High
- Combat: Appears during Voltage confrontation if Voltage not captured peacefully
- Intelligence: The Architect coordination details
- Defeat triggers: Task 3.1c "Neutralize Operative Static"

**3.2 Disable Attack Mechanisms**

Three attack vectors must be disabled:

**A. Physical Bypass Devices (Dosing Stations)**
- Location: Treatment Floor (3 dosing stations)
- Objects: "Bypass Device" on each station
- Action: Examine and disable each device
- Progress: `physical_bypasses_disabled` (0-3)
- Completion: Task 3.2a "Disable physical bypass devices"

**B. SCADA Malware**
- Location: Server Room (SCADA backup server)
- Object: SCADA Backup Server Terminal
- Action: Access server, remove malicious script
- Completion: Task 3.2b "Remove SCADA malware"

**C. Remote Trigger Mechanism**
- Location: Maintenance Wing (Voltage's laptop)
- Object: ENTROPY Command Laptop
- Access: Requires Master Keycard (from Relay or final confrontation)
- Action: Disable trigger via laptop interface
- Warning: Incorrect disabling sequence may cause fail-safe
- Recommended: Disable after capturing Voltage for safe access
- Completion: Task 3.2c "Disable remote trigger"

**3.3 Confront Voltage**
- Location: Maintenance Wing (final room)
- NPC: Voltage (Critical Mass leader)
- Access: Requires Master Keycard

**Confrontation Dynamics:**

Voltage's leverage depends on attack vector status:
- All 3 vectors disabled: Voltage has no leverage, easy capture
- 1-2 vectors disabled: Partial leverage, negotiation possible
- 0 vectors disabled: Full leverage, dangerous confrontation

**CRITICAL DECISION: Capture vs. Disable Priority**

**Option A: Capture Voltage (Intelligence Priority)**
- Approach peacefully if attack mostly disabled
- Negotiate using leverage (attack status, operative defeats)
- Voltage provides intelligence about The Architect
- Higher `handler_confidence` boost
- Better long-term ENTROPY network insight
- Risk: If attack not fully disabled, Voltage may trigger partial attack
- Completion: Task 3.3a "Capture Voltage"

**Option B: Neutralize Voltage (Safety Priority)**
- Attack Voltage immediately
- Prevents any trigger attempts
- Operative Static joins combat if present
- Guaranteed attack prevention
- No Architect intelligence gained
- Lower `handler_confidence` (missed opportunity)
- Completion: Task 3.3b "Neutralize Voltage"

**Recommended Approach:**
1. Disable all 3 attack vectors first (removes Voltage's leverage)
2. Defeat Cipher and Relay (prevents reinforcements)
3. Confront Voltage with full tactical advantage
4. Choose capture for maximum intelligence value
5. Secure laptop for safe trigger disabling

**3.4 Secure Attack Trigger**
- After Voltage confrontation, access ENTROPY Command Laptop
- Navigate disabling interface:
  - Physical bypasses status
  - SCADA malware status
  - Trigger mechanism controls
- Carefully disable trigger (guided if Voltage captured, risky if not)
- Completion: Task 3.4 "Secure attack trigger"

- **Objective 3 Complete:** "Neutralize the Threat"

---

### Phase 4: Mission Debrief

**4.1 Report to Agent 0x99**
- Trigger: Automatic when `mission_complete = true` (all objectives complete)
- NPC: Agent 0x99 (phone call - closing debrief)
- Mission Outcome Assessment:
  - Attack prevention success
  - Operative neutralization count (0-4)
  - Voltage capture status
  - Intelligence gathered

**4.2 Task Force Null Revelation**
- Agent 0x99 reveals existence of Task Force Null
- Multi-agency ENTROPY task force
- You're assigned to the team based on performance
- Sets up Mission 5 and beyond

**FINAL DECISION: Public Disclosure**

Agent 0x99 asks: How should the incident be disclosed?

**Option A: Full Public Disclosure**
- Public statement coordinated with local authorities
- Transparent about threat and prevention
- Builds public trust, educational value
- Increases public ENTROPY awareness
- Risk: May cause panic, copycat attacks

**Option B: Quiet Resolution**
- Incident remains classified
- Cover story: "Routine maintenance issue resolved"
- Minimizes panic and disruption
- Protects operational security
- Risk: Public remains unaware of infrastructure vulnerabilities

**Option C: Partial Disclosure**
- Limited statement: "Security incident prevented"
- Balanced approach
- Acknowledges threat without full details
- Moderate public awareness

Choice affects:
- `disclosure_choice` variable (tracked for future missions)
- Public perception of SAFETYNET in future missions
- Mission 5+ newspaper/media references

**4.3 Mission Complete**
- Final stats displayed
- Chen trust level outcome
- Handler confidence score
- Operatives defeated count
- VM flags submitted
- Transition to Mission 5 preview (if applicable)

---

## Optimal Solution Path (S-Rank)

For maximum performance and intelligence gathering:

1. **Infiltration:** Present EPA credentials → Clean entry (1 min)
2. **Chen Alliance:** Reveal truth early → SCADA support unlocked (5 min)
3. **VM Exploitation:** Complete all 4 flags → Maximum intelligence (20 min)
4. **Combat:** Defeat Cipher → Level 2 keycard (5 min)
5. **Attack Disabling:** Disable all 3 vectors methodically (15 min)
   - Physical bypasses (3 dosing stations)
   - SCADA malware (server room)
   - Wait on trigger (do after Voltage capture)
6. **Combat:** Defeat Relay → Master keycard (5 min)
7. **Voltage Confrontation:** Leverage attack disabled status → Peaceful capture (10 min)
8. **Final Disabling:** Secure trigger safely with Voltage cooperation (5 min)
9. **Debrief:** Report success, choose disclosure (5 min)

**Total Time:** ~70 minutes
**Operatives Defeated:** 2-3 (Cipher, Relay, optionally Static)
**Voltage:** Captured
**Attack:** Fully prevented
**Intelligence:** Maximum (4 flags + Voltage interrogation + The Architect intel)
**Chen:** Ally
**Disclosure:** Player choice (no wrong answer)

---

## Variable Tracking

### Global Variables (scenario.json.erb)

**Trust & Relationship:**
- `chen_is_ally` (boolean) - Chen alliance status
- `chen_trust_level` (0-100) - Chen trust score

**Mission Progress:**
- `urgency_stage` (0-5) - Escalation level (not time-based)
- `attack_vectors_disabled` (0-3) - Disabled attack mechanisms count
- `operatives_defeated` (0-4) - Neutralized hostiles count
- `flags_submitted` (0-4) - VM flags submitted count

**Attack Status:**
- `physical_bypasses_disabled` (0-3) - Dosing station bypasses disabled
- `scada_malware_disabled` (boolean) - SCADA malware removed
- `trigger_mechanism_disabled` (boolean) - Remote trigger secured
- `attack_trigger_secured` (boolean) - Trigger laptop accessed

**Operative Status:**
- `cipher_defeated` (boolean)
- `relay_defeated` (boolean)
- `static_defeated` (boolean)
- `voltage_captured` (boolean)
- `voltage_defeated` (boolean)

**Mission Outcomes:**
- `mission_complete` (boolean) - Triggers closing debrief
- `attack_prevented` (boolean)
- `voltage_escaped` (boolean)

### Dialogue Variables (Ink scripts)

**Agent 0x99 (Handler):**
- `handler_confidence` (0-100) - Handler's mission success assessment
- `handler_contacted` (count) - Phone call frequency

**Opening Briefing:**
- `combat_ready` (boolean) - Player acknowledged combat training
- `knows_full_threat` (boolean) - Chemical threat explained
- `player_approach` (string) - "confident", "tactical", "methodical"

**Voltage Confrontation:**
- `voltage_leverage` (boolean) - Does Voltage have trigger access?
- `player_priority` (string) - "capture" vs "disable"

**Closing Debrief:**
- `disclosure_choice` (string) - "full", "quiet", "partial"
- `task_force_null_assigned` (boolean) - Assigned to TF Null

---

## Common Issues & Troubleshooting

### "Can't access Server Room"
- **Solution:** Obtain Level 2 Keycard from Operative Cipher (Treatment Floor) or ask Chen (if ally)

### "Can't access Maintenance Wing"
- **Solution:** Obtain Master Keycard from Operative Relay (Chemical Storage) or defeat Voltage's guards

### "Voltage escaped before I could capture"
- **Cause:** Approached without disabling attack vectors
- **Prevention:** Disable all 3 vectors before confrontation

### "Attack partially triggered during Voltage fight"
- **Cause:** Voltage retained leverage (attack vectors not disabled)
- **Prevention:** Fully disable attack before confronting Voltage

### "Chen won't cooperate with SCADA investigation"
- **Cause:** Didn't reveal true mission (`chen_is_ally = false`)
- **Solution:** Reveal truth during early dialogue to build trust

### "Can't find all 4 VM flags"
- **Flag 1:** FTP server - operation_critical_mass.txt
- **Flag 2:** HTTP server - SCADA logs page
- **Flag 3:** distcc exploit - low-privilege shell access
- **Flag 4:** sudo Baron exploit - root escalation

### "Urgency stage not progressing"
- **Expected:** Urgency is event-based, not time-based
- **Triggers:** SCADA anomaly discovery, VM flags, attack vector discoveries
- **Does not require:** Waiting or real-time progression

---

## Educational Objectives

### CyBOK Knowledge Areas Demonstrated:

**Network Security (NS):**
- Network scanning with Nmap
- Service enumeration (FTP, HTTP, distcc)
- Network topology understanding

**System Security (SS):**
- Linux privilege escalation (sudo vulnerabilities)
- Remote code execution exploitation (distcc)
- SCADA/ICS system security principles

**Infrastructure Security (IS):**
- Critical infrastructure protection concepts
- SCADA network segregation
- Physical vs. cyber attack vectors

**Attack & Defense (AB):**
- Penetration testing methodology
- Vulnerability exploitation (CVE-2004-2687, CVE-2021-3156)
- Attack surface analysis

**Human Factors (HF):**
- Social engineering (entry checkpoint)
- Trust building (Chen relationship)
- Ethical decision-making (capture vs. neutralize, disclosure choice)

**Incident Response (IR):**
- Threat intelligence gathering
- Attack vector mitigation
- Post-incident disclosure decisions

---

## Speedrun Strategies

### Minimum Time Route (~45 minutes):

1. Skip all optional dialogue
2. Present credentials immediately at entry
3. Reveal truth to Chen in first conversation (SCADA support)
4. Defeat Cipher for Level 2 keycard (skip interrogation)
5. Complete VM flags 1-2 only (minimum intelligence)
6. Disable physical bypasses first (Treatment Floor)
7. Disable SCADA malware (Server Room)
8. Defeat Relay for Master Keycard (skip interrogation)
9. Confront Voltage immediately, choose neutralize (skip capture dialogue)
10. Secure trigger (safe with all vectors disabled)
11. Report to 0x99 (skip optional debrief questions)

**Trade-offs:**
- Minimal intelligence gathered (lower handler confidence)
- Voltage not captured (no Architect intel)
- Reduced story immersion
- Lower completionist score

---

## Completion Checklist

### Required Tasks (15/15):
- [ ] 1.1 - Opening briefing received
- [ ] 1.2 - Facility infiltration complete
- [ ] 1.3 - Facility manager contacted
- [ ] 1.4 - SCADA anomalies identified
- [ ] 2.1 - Flag 1 submitted (FTP)
- [ ] 2.2 - Flag 2 submitted (HTTP)
- [ ] 2.3 - Flag 3 submitted (distcc exploit)
- [ ] 2.4 - Flag 4 submitted (sudo escalation)
- [ ] 3.1 - Operatives neutralized (at least 2 recommended)
- [ ] 3.2a - Physical bypasses disabled (3/3)
- [ ] 3.2b - SCADA malware removed
- [ ] 3.2c - Remote trigger disabled
- [ ] 3.3 - Voltage confronted (captured or neutralized)
- [ ] 3.4 - Attack trigger secured
- [ ] 3.5 - Mission outcome reported

### Optional Tasks (2/2):
- [ ] Defeat all 4 operatives (Cipher, Relay, Static, Voltage)
- [ ] Capture Voltage alive for intelligence

### Hidden Achievements:
- [ ] S-Rank: Complete in under 60 minutes with all flags and Voltage captured
- [ ] Pacifist Route: Complete without defeating any operatives (stealth/Chen assistance)
- [ ] Combat Master: Defeat all 4 operatives
- [ ] Intelligence Analyst: Submit all 4 VM flags
- [ ] Chen's Trust: Achieve `chen_trust_level >= 80`
- [ ] Handler's Confidence: Achieve `handler_confidence >= 80`

---

## Story Continuity

**Connects to:**
- **Mission 3 (Ransomed Trust):** ENTROPY established as multi-cell organization
- **Mission 5 (Future):** Task Force Null assignment, The Architect investigation continues

**Intelligence Gathered:**
- Critical Mass cell structure
- Voltage's infrastructure expertise
- The Architect coordination evidence
- ENTROPY cell coordination methods
- Social Fabric cell connection (simultaneous attack planning)

**Character Development:**
- Agent 0x99: Handler relationship deepens based on performance
- Robert Chen: Potential recurring ally for future infrastructure missions
- Voltage: First high-value ENTROPY prisoner (if captured)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-29
**Status:** Ready for QA Testing
