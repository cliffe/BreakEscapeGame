# Mission 7: The Architect's Gambit - Complete Solution Guide

## Mission Overview

**Location:** SAFETYNET Emergency Operations Center
**Duration:** 30 minutes (in-game timer)
**Difficulty:** Advanced
**Mission Type:** Single-location branching with 4 crisis paths

**Core Mechanic:** Player must choose ONE of four simultaneous cyber attacks to stop. The unchosen operations proceed with deterministic outcomes. There is no perfect choice - casualties are unavoidable.

---

## Mission Map Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   MISSION 7: THE ARCHITECT'S GAMBIT                         │
│                  SAFETYNET EMERGENCY OPERATIONS CENTER                      │
└─────────────────────────────────────────────────────────────────────────────┘

                              NORTH
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
    ┌────┴─────┐        ┌──────┴──────┐        ┌─────┴────┐
    │ ANALYST  │        │   LOCKER    │        │ DIRECTOR │
    │  ROOM    │        │    ROOM     │        │  OFFICE  │
    │          │        │             │        │          │
    └────┬─────┘        └──────┬──────┘        └─────┬────┘
         │                     │                     │
         └──────────────┬──────┴──────┬──────────────┘
                        │             │
                  ┌─────┴─────────────┴─────┐
                  │                         │
                  │  EMERGENCY BRIEFING     │◄── START HERE
                  │       ROOM              │
                  │  [Crisis Choice Made]   │
                  │                         │
                  └─────┬─────────────┬─────┘
                        │             │
         ┌──────────────┴─────┐   ┌──┴──────────────┐
         │                    │   │                 │
    ┌────┴─────┐       ┌──────┴───┴──┐       ┌─────┴────┐
    │ COMM     │       │   CRISIS    │       │ SERVER   │
    │ CENTER   │       │  TERMINAL   │       │  ROOM    │
    │          │       │ [BRANCHES]  │       │ [VM]     │
    └──────────┘       └─────────────┘       └──────────┘

                    CRISIS TERMINAL BRANCHES:
                    ═══════════════════════════
    Option A: Infrastructure  │  Marcus Chen confrontation
    Option B: Data            │  Specter & Rachel confrontation
    Option C: Supply Chain    │  Adrian Cross confrontation
    Option D: Corporate       │  Victoria & Marcus confrontation
```

---

## Room Connections Summary

| Room | North | South | East | West |
|------|-------|-------|------|------|
| Emergency Briefing | [analyst_room, locker_room, director_office] | - | server_room | comm_center |
| Analyst Room | - | briefing_room | - | - |
| Locker Room | - | briefing_room | - | - |
| Director Office | - | briefing_room | - | - |
| Comm Center | - | - | briefing_room | - |
| Server Room | - | - | - | briefing_room |
| Crisis Terminal | Appears after crisis choice | - | - | - |

---

## Step-by-Step Solution

### Phase 1: Mission Start & Briefing

| Step | Action | Result |
|------|--------|--------|
| 1 | Spawn in Emergency Briefing Room | Opening briefing begins automatically |
| 2 | Talk to Director Morgan | Learn about 4 simultaneous ENTROPY operations |
| 3 | Receive intelligence briefing | Understand each crisis scenario |
| 4 | **CRITICAL CHOICE:** Select crisis to stop | Sets `crisis_choice` variable |

**Crisis Options:**
- **A: Infrastructure Collapse** - Power grid attack, 240-385 deaths
- **B: Data Apocalypse** - Voter data + disinformation, dual timer
- **C: Supply Chain Infection** - 47M backdoors, long-term threat
- **D: Corporate Warfare** - 47 zero-days, $4.2T at risk

---

### Phase 2: Preparation & Intelligence Gathering

| Step | Action | Result |
|------|--------|--------|
| 5 | Explore facility rooms | Gather context and tools |
| 6 | Call Agent 0x99 (phone) | Get tactical briefing for chosen crisis |
| 7 | Access Server Room | Begin VM challenges |
| 8 | Complete VM exploitation | Obtain 4 flags for crisis neutralization |

**Required VM Flags:**
- `flag1` - Initial access
- `flag2` - Privilege escalation
- `flag3` - Data exfiltration
- `flag4` - Shutdown codes

---

### Phase 3: Crisis Confrontation (Path Dependent)

#### **OPTION A: Infrastructure Collapse**

| Step | Action | Result |
|------|--------|--------|
| 9a | Enter Crisis Terminal | Marcus "Blackout" Chen at SCADA terminal |
| 10a | Confront Marcus | Timer: T-30:00 and counting |
| 11a | Navigate dialogue tree | Choose approach: empathy, arrest, or recruitment |
| 12a | **Show ENTROPY casualties** (optional) | Marcus becomes hesitant |
| 13a | **Recruitment path** (if chosen) | Offer SAFETYNET position |
| 14a | Receive shutdown codes | Use VM flags + codes to stop attack |
| 15a | Crisis neutralized | Timer stops, grid secure |

**Recruitment Success Conditions:**
- Must show Marcus full ENTROPY casualty picture
- Choose empathy/technical respect dialogue
- Guarantee infrastructure fixes
- Result: `chen_fate = "recruited"`

---

#### **OPTION B: Data Apocalypse**

| Step | Action | Result |
|------|--------|--------|
| 9b | Enter Crisis Terminal | Specter (Ghost Protocol) + Rachel (Social Fabric) |
| 10b | **DUAL TIMER CHALLENGE** | Exfiltration: 89%, Deployment: T-28:47 |
| 11b | **Prioritization choice** | Stop exfiltration OR stop disinformation |
| 12b | Engage Specter | Ghost Protocol operative (cannot be recruited) |
| 13b | Engage Rachel | Social Fabric leader (CAN be recruited) |
| 14b | **Show Rachel casualties** | Rachel hesitates, questions The Architect |
| 15b | **Recruitment path** (if chosen) | Rachel helps stop disinformation |
| 16b | Use VM flags to neutralize threats | Stop chosen attack, partial success on other |

**Recruitment Success Conditions (Rachel):**
- Show her full ENTROPY casualty evidence
- Appeal to her moral principles
- Offer chance to fight corruption properly
- Result: `rachel_recruited = true`

**Note:** Specter always escapes (Ghost Protocol training)

---

#### **OPTION C: Supply Chain Infection**

| Step | Action | Result |
|------|--------|--------|
| 9c | Enter Crisis Terminal | Adrian Cross at code signing terminal |
| 10c | Confront Adrian | Timer: T-30:00, 47M infections pending |
| 11c | Navigate dialogue tree | Adrian is most sympathetic antagonist |
| 12c | **Show ENTROPY casualties** | Adrian expresses regret |
| 13c | **Technical discussion** | Adrian respects technical knowledge |
| 14c | **Recruitment offer** | High success probability |
| 15c | Receive deactivation codes | Use VM flags + codes to stop backdoors |
| 16c | Crisis neutralized | Backdoor deployment stopped |

**Recruitment Success Conditions (HIGHEST probability):**
- Acknowledge his legitimate research
- Show ENTROPY casualties
- Offer security research position
- Result: `adrian_recruited = true`

---

#### **OPTION D: Corporate Warfare**

| Step | Action | Result |
|------|--------|--------|
| 9d | Enter Crisis Terminal | Victoria Zhang (Digital Vanguard) + Marcus Chen |
| 10d | **Dual antagonist confrontation** | 47 zero-days deploying across 12 corporations |
| 11d | Engage Victoria | Armed, proficient, anti-corporate ideology |
| 12d | Engage Marcus | Zero Day Syndicate, will escape |
| 13d | **Show casualties** | 140,000 job losses, retirement accounts |
| 14d | **Economic argument** | Human cost vs corporate punishment |
| 15d | **Recruitment path** (Victoria) | Channel anti-corporate energy productively |
| 16d | Use VM flags to deploy countermeasures | Stop ransomware deployment |

**Recruitment Success Conditions (Victoria):**
- Show empathy for anti-corporate stance
- Demonstrate human cost of economic collapse
- Offer role fighting corporate exploitation properly
- Result: `victoria_recruited = true`

**Note:** Marcus always escapes (Zero Day Syndicate protocol)

---

### Phase 4: The Architect's Interference

**Throughout the mission, The Architect sends timed messages:**

| Timer | Message | Purpose |
|-------|---------|---------|
| T-30:00 | "Let's see which lives you value" | Establishes psychological warfare |
| T-20:00 | "Team Alpha failing at [other crisis]" | Updates on unchosen operations |
| T-10:00 | "So many deaths could have been prevented" | Guilt manipulation |
| T-05:00 | "Question your choice yet?" | Shake player confidence |
| T-01:00 | "Every second matters" | Final pressure |

**Note:** The Architect's messages are designed to make you second-guess your choice. Stay focused on your selected crisis.

---

### Phase 5: Mission Completion & Debrief

| Step | Action | Result |
|------|--------|--------|
| 17 | Crisis neutralized (timer stops) | Director Morgan confirms success |
| 18 | Search Crisis Terminal room | Find intelligence documents |
| 19 | **Collect Tomb Gamma coordinates** | 47.2382° N, 112.5156° W (Montana) |
| 20 | **Collect SAFETYNET mole evidence** | Email from internal agent |
| 21 | Return to Emergency Briefing Room | Closing debrief begins |
| 22 | Talk to Director Morgan | Receive outcome report for all 4 operations |
| 23 | **Debrief shows casualties** | See results of unchosen operations |
| 24 | Mission complete | Review final statistics |

---

## Deterministic Outcomes Matrix

**The operations you DON'T choose have predetermined outcomes:**

### If You Choose Option A (Infrastructure):

| Operation | Team | Outcome | Casualties |
|-----------|------|---------|------------|
| A: Infrastructure | **YOU** | ✅ Success | 0 deaths (attack stopped) |
| B: Data | Team Alpha | ⚠️ Partial | 187M records stolen, disinformation deploys |
| C: Supply Chain | Team Bravo | ✅ Success | Attack stopped, 0 infections |
| D: Corporate | Team Charlie | ❌ Failure | 80-140 healthcare deaths, $4.2T damage |

### If You Choose Option B (Data):

| Operation | Team | Outcome | Casualties |
|-----------|------|---------|------------|
| A: Infrastructure | Team Alpha | ❌ Failure | 240-385 deaths (blackout occurs) |
| B: Data | **YOU** | ✅ Success | Exfiltration stopped, disinformation stopped |
| C: Supply Chain | Team Bravo | ⚠️ Partial | Some backdoors deployed |
| D: Corporate | Team Charlie | ✅ Success | All zero-days neutralized |

### If You Choose Option C (Supply Chain):

| Operation | Team | Outcome | Casualties |
|-----------|------|---------|------------|
| A: Infrastructure | Team Alpha | ✅ Success | Blackout prevented, 0 deaths |
| B: Data | Team Bravo | ❌ Failure | 187M records stolen, disinformation succeeds |
| C: Supply Chain | **YOU** | ✅ Success | All backdoors stopped |
| D: Corporate | Team Charlie | ⚠️ Partial | Some economic damage |

### If You Choose Option D (Corporate):

| Operation | Team | Outcome | Casualties |
|-----------|------|---------|------------|
| A: Infrastructure | Team Alpha | ✅ Success | Blackout prevented |
| B: Data | Team Bravo | ❌ Failure | Both attacks succeed |
| C: Supply Chain | Team Charlie | ⚠️ Partial | Some infections occur |
| D: Corporate | **YOU** | ✅ Success | All ransomware stopped |

---

## Moral Choices & Consequences

### 1. Crisis Selection (Opening)

**The Impossible Choice:**
- No "right" answer - all choices accept casualties elsewhere
- Infrastructure: Immediate deaths vs long-term threats
- Data: Democratic institutions vs economic stability
- Supply Chain: Long-term national security vs immediate crises
- Corporate: Economic stability vs human lives elsewhere

**Consequence:** Determines which NPCs you meet, dialogue you experience, and which casualties you prevent.

---

### 2. Antagonist Recruitment (Per Path)

**Marcus Chen (Infrastructure):**
- **Recruit:** Gains infrastructure security expert, prevents future attacks
- **Arrest:** Removes threat but loses expertise
- **Variable:** `chen_fate = "recruited"/"arrested"/"escaped"/"killed"`

**Rachel Morrow (Data):**
- **Recruit:** Gains Social Fabric intelligence, 47 cell locations
- **Arrest:** Stops immediate threat but loses intel network
- **Variable:** `rachel_recruited = true/false`

**Adrian Cross (Supply Chain):**
- **Recruit:** Gains supply chain security researcher, highest value recruit
- **Arrest:** Stops attack but loses critical expertise
- **Variable:** `adrian_recruited = true/false`

**Victoria Zhang (Corporate):**
- **Recruit:** Gains Digital Vanguard operative, anti-corporate specialist
- **Arrest:** Removes threat but loses insider knowledge
- **Variable:** `victoria_recruited = true/false`

---

### 3. Listening to The Architect

**Choice:** Engage with The Architect's taunts or ignore them

- **Engage:** Provides context for ENTROPY philosophy, reveals manipulation
- **Ignore:** Stay focused on tactical objectives, avoid psychological warfare
- **No mechanical impact:** Dialogue is designed to test player psychology

---

## VM Challenge Solutions

**VM Scenario:** SecGen "putting_it_together" - Multi-stage Linux exploitation

### Flag 1: Initial Access

```bash
# SSH Brute Force
# Target: compromised server with weak credentials
# Tool: Hydra or manual attempts
# Solution: Common password in wordlist

hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://target_ip
# OR use provided credentials from intelligence briefing
ssh admin@target_ip
# Password found in briefing materials
```

**Flag Location:** `/home/admin/flag1.txt`

---

### Flag 2: Privilege Escalation

```bash
# Check for sudo permissions
sudo -l

# Exploit misconfigured sudo permissions
# OR find SUID binary
find / -perm -4000 2>/dev/null

# Common vectors:
# - sudo rights on specific binary
# - SUID binary with vulnerability
# - Kernel exploit (less likely)

# Example if sudo vim available:
sudo vim -c ':!/bin/bash'
```

**Flag Location:** `/root/flag2.txt`

---

### Flag 3: Data Exfiltration

```bash
# Access restricted network share
# NFS share with attack data

showmount -e target_ip
mkdir /tmp/mnt
mount -t nfs target_ip:/share /tmp/mnt

# Extract shutdown codes
cd /tmp/mnt
cat shutdown_codes.txt
cat flag3.txt
```

**Flag Location:** `/mnt/crisis_data/flag3.txt`

---

### Flag 4: Shutdown Sequence

```bash
# Combine flags 1-3 to access shutdown system
# Use credentials and codes found in previous steps

ssh crisis_admin@crisis_terminal
# Enter shutdown sequence using codes from flag 3
./shutdown_attack.sh --code [CODE_FROM_FLAG3]
cat flag4.txt
```

**Flag Location:** `/opt/crisis_control/flag4.txt`

---

## Intelligence Collection

**Required for 100% Completion:**

### Tomb Gamma Coordinates

**Location:** Crisis Terminal room (post-neutralization)
**File:** Encrypted communications from antagonist
**Content:**
- Location: Abandoned Cold War bunker, Montana
- Coordinates: 47.2382° N, 112.5156° W
- Message: "All operations report to Tomb Gamma if compromised"

**Importance:** Sets up future mission to The Architect's command center

---

### SAFETYNET Mole Evidence

**Location:** Crisis Terminal room (post-neutralization)
**File:** Intercepted email
**Content:**
- From: [REDACTED]@safetynet.gov
- To: architect@entropy.onion
- Subject: Target assignments confirmed
- Body: "0x00 to [chosen crisis]. Teams handle other targets"

**Importance:** Reveals internal betrayal, sets up future investigation

---

### ENTROPY Cell Structure

**Location:** Obtained if antagonist recruited
**Conditional:** Depends on recruitment success

- **Marcus (Infrastructure):** SCADA vulnerability documentation
- **Rachel (Data):** 47 Social Fabric cell locations nationwide
- **Adrian (Supply Chain):** Supply chain attack methodologies
- **Victoria (Corporate):** Digital Vanguard membership roster

---

## Completion Requirements

| Requirement | Mandatory? | Notes |
|-------------|------------|-------|
| Choose crisis to stop | ✅ Yes | No way to stop all 4 |
| Complete VM flag 1 | ✅ Yes | Initial access |
| Complete VM flag 2 | ✅ Yes | Privilege escalation |
| Complete VM flag 3 | ✅ Yes | Data exfiltration |
| Complete VM flag 4 | ✅ Yes | Shutdown codes |
| Confront antagonist(s) | ✅ Yes | Crisis-dependent |
| Neutralize chosen attack | ✅ Yes | Stop timer |
| Collect Tomb Gamma coordinates | ❌ Optional | Sets up future mission |
| Collect mole evidence | ❌ Optional | Bonus intelligence |
| Recruit antagonist | ❌ Optional | Bonus outcome |
| Call Agent 0x99 | ❌ Optional | Tactical support |
| Explore all rooms | ❌ Optional | Context and lore |

---

## Tips & Strategies

### Crisis Selection Guide

**Choose Infrastructure if:**
- You prioritize immediate civilian lives
- You want straightforward combat scenario
- You prefer pure timer pressure

**Choose Data if:**
- You value democratic institutions
- You want complex dual-timer challenge
- You prefer prioritization puzzles

**Choose Supply Chain if:**
- You prioritize long-term national security
- You want highest recruitment probability
- You prefer technical discussions

**Choose Corporate if:**
- You want most morally complex scenario
- You prefer dual antagonist confrontation
- You're interested in anti-corporate themes

---

### Recruitment Tips

**General Recruitment Strategy:**
1. Always show ENTROPY casualty evidence first
2. Acknowledge legitimate criticisms
3. Offer constructive alternatives
4. Emphasize shared values over ideology

**Highest Success Rates:**
1. Adrian Cross (Supply Chain) - ~80% success rate
2. Rachel Morrow (Data) - ~60% success rate
3. Victoria Zhang (Corporate) - ~50% success rate
4. Marcus Chen (Infrastructure) - ~40% success rate

---

### Time Management

**30-Minute Timer Breakdown:**
- **0-10 minutes:** VM exploitation (4 flags)
- **10-25 minutes:** Crisis confrontation & dialogue
- **25-30 minutes:** Final shutdown sequence

**Critical Timing:**
- The Architect sends taunts at: 30:00, 20:00, 10:00, 5:00, 1:00
- Recruitment requires time for dialogue tree
- Rushing dialogue reduces recruitment probability

---

### Agent 0x99 Support

**When to Call:**
- **Mission Overview:** Learn about crisis details
- **Other Teams Info:** See what other operations are doing
- **Combat Guidance:** Learn about hostile NPCs
- **Intel Locations:** Find Tomb Gamma and mole evidence
- **Intel Analysis:** Check flag submission status

**Pro Tip:** Call 0x99 before entering Crisis Terminal for tactical briefing

---

## Easter Eggs & Hidden Content

### 1. Director Morgan Dialogue Variations

**Based on performance:**
- All 4 flags submitted quickly → "Impressive speed"
- Recruited antagonist → "Outstanding diplomatic work"
- No casualties on your operation → "Perfect execution"

---

### 2. The Architect's Identity Hints

**Hidden throughout:**
- Communication patterns suggest military training
- References to "The Professor" in some documents
- Tomb Gamma coordinates lead to Cold War facility
- Mole evidence suggests high-level access

---

### 3. Facility Environmental Details

**Explore rooms for:**
- Emergency Operations protocols
- SAFETYNET organizational structure
- Previous mission references
- Team Alpha/Bravo/Charlie status boards

---

## Speedrun Route (Minimum Time)

**Optimal Path (Any Crisis):**

1. Skip opening briefing dialogue (if possible)
2. Immediately choose crisis (Infrastructure recommended for speed)
3. Go directly to Server Room
4. Complete all 4 VM flags (10-12 minutes)
5. Enter Crisis Terminal
6. Skip all optional dialogue
7. Go straight for shutdown sequence
8. Skip intelligence collection
9. Complete debrief

**Estimated Time:** 15-18 minutes

---

## FAQ

**Q: Can I stop all 4 attacks?**
A: No. This is a mission about impossible choices. You must accept casualties elsewhere.

**Q: What's the "best" crisis to choose?**
A: There is no best choice. Each has different casualties and moral weight.

**Q: Can I recruit all antagonists?**
A: No. You only encounter antagonists from your chosen crisis.

**Q: Does The Architect appear in this mission?**
A: No. The Architect only communicates via text messages (psychological warfare).

**Q: What happens if I fail to stop the timer?**
A: Mission fails. Your chosen operation succeeds, adding to total casualties.

**Q: Can Specter or Marcus (ZDS) be recruited?**
A: No. Specter (Ghost Protocol) and Marcus "Shadow" Chen (Zero Day Syndicate) always escape. This is their training.

**Q: Does recruitment affect future missions?**
A: Yes. Recruited antagonists provide intelligence and may appear in later missions.

**Q: Is the mole revealed in this mission?**
A: No. You find evidence of the mole, but identity is revealed in future missions.

---

## Achievement Checklist

- ✅ **Quick Draw:** Complete all 4 VM flags in under 10 minutes
- ✅ **Diplomat:** Successfully recruit your crisis antagonist
- ✅ **Perfect Execution:** Stop your chosen crisis with 0 casualties
- ✅ **Intelligence Gatherer:** Collect all 3 intelligence documents
- ✅ **Unwavering:** Complete mission without engaging The Architect's taunts
- ✅ **Speedrunner:** Complete mission in under 20 minutes
- ✅ **Completionist:** Explore all 7 rooms before crisis confrontation

---

**Mission 7 Complete. The Architect remains at large. Tomb Gamma awaits.**
