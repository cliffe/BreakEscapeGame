---
title: "SAFETYNET Field Guide Style Guide"
description: "Format and approach for creating contextual field guide documents"
author: "SAFETYNET Documentation"
---

# SAFETYNET Field Guide Style Guide

## Overview

Field guides are **contextual training documents** delivered by Agent 0x99 when players discover key intelligence or reach decision points. They provide tactical knowledge without spoiling the mission.

**Design Principle**: Agent 0x99 observes your discovery, explains why the information matters for *this* operation, then provides a focused field guide extract with just enough knowledge to succeed.

---

## Document Structure

Every field guide follows this three-part structure:

### Part 1: Handler Note from Agent 0x99

**Purpose**: Mission-specific context that explains why this information is relevant right now.

**What to include**:
- What the player just discovered or is about to attempt
- Why it matters for the current objective
- How it connects to the broader operation
- Encouragement to use the guide without spoiling outcomes

**What NOT to include**:
- Exact usernames/passwords for this operation
- Specific IP addresses or system names from the scenario
- The exact steps the player will take
- Outcomes or results they can expect

**Tone**: Direct, urgent, mentor-like. Agent 0x99 is watching and providing support.

**Format**: 
```
# Handler Note — Agent 0x99

You've found [what they discovered]. This is your way into [the objective].

[Explain why it matters]

I've attached a field guide on [topic]. It covers the fundamentals and common patterns 
you'll encounter. The specific details of your target will vary, but the principles 
are universal. Once you've reviewed it, you'll know exactly what to do.

— 0x99
```

---

### Part 2: SAFETYNET Field Guide Extract

**Purpose**: Transferable tactical knowledge applicable across many scenarios.

**What to include**:
- Generic examples (user1, server1, target.local — NOT scenario-specific names)
- Common vulnerability patterns
- Step-by-step procedures
- Troubleshooting tips
- Quick reference tables
- Concepts explained in plain language

**What NOT to include**:
- This operation's specific details
- Exact commands tailored to this scenario
- Assumptions about what the player will find
- Spoilers about what to expect

**Tone**: Professional, educational, practical. Written as general SAFETYNET training material.

**Format**:
```
# SAFETYNET Field Guide Extract: [Topic]

## Quick Reference

[1-2 paragraphs explaining the concept]

[Table or command summary]

## Detailed Procedures

### Step 1: [Concept]
[Explanation and examples]

### Step 2: [Concept]
[Explanation and examples]

## Common Patterns

[What typically happens, vulnerabilities commonly found]

## Troubleshooting

[Common issues and solutions]
```

---

### Part 3: Context Bridge (Optional)

**Purpose**: Light connective tissue between the handler note and field guide.

**When to use**: If the field guide is long or complex, add a brief "Reading Guide" explaining what sections are most relevant to the current objective.

**Format**:
```
## For This Operation, Focus On:

- **Section: Step 1** — This will tell you how to identify the vulnerability
- **Section: Common Patterns** — Expect to see these patterns in your target
- **Section: Troubleshooting** — If X happens, go here

The rest is useful context, but focus on these sections first.
```

---

## Content Sourcing

Field guides **must be adapted from existing training materials** in the codebase:

1. **Identify relevant source material**
   - Check `scenarios/[mission]/lab_sheet/` for training docs
   - Pull from `1_intro_linux.md`, `docs/`, or training materials

2. **Extract key sections**
   - Don't copy wholesale; extract the most relevant material
   - Simplify jargon where needed
   - Adapt examples to be generic

3. **Reference the source**
   - Include a footnote: "Adapted from [source document]"
   - Respect original author attribution

---

## Information Balance: What to Give vs. Hold Back

### ✅ Provide

- **Concepts**: What is SSH? How does Hydra work?
- **Generic procedures**: How to run commands, general syntax
- **Common vulnerabilities**: Typical patterns (weak passwords, sudo misconfig, etc.)
- **Troubleshooting**: What to do when something fails
- **Reference materials**: Tables, syntax examples, command flags

### ❌ Don't Provide

- **This operation's targets**: Don't name derek, shatter, or specific systems
- **Exact credentials**: Don't give passwords or usernames from the scenario
- **System-specific paths**: Don't mention /home/shatter or operation_shatter/
- **Expected outcomes**: Don't tell them "you'll find a file called..."
- **Exact command templates**: Don't give: `hydra -l derek -P [file] 172.22.1.100 ssh`
  - Instead give: `hydra -l [username] -P [wordlist] [target-ip] ssh`

### 🤔 Use Judgment

- **Vulnerability types**: OK to mention ("SSH services often have weak passwords")
- **Attack vectors**: OK to explain (how Hydra works, what it does)
- **Specific attack**: Not OK (don't describe THIS attack's exact path)

---

## Writing Guidelines

### Language & Tone

- **Audience**: Operatives with basic Linux knowledge who need tactical guidance
- **Voice**: Direct, professional, matter-of-fact
- **Pace**: Concise. Get to the point quickly.
- **Structure**: Progressive (basics before advanced)

### Length Guidelines

- **Handler note**: 4-6 sentences
- **Quick reference**: 1 paragraph + command table
- **Detailed procedures**: 2-4 sections, each 3-5 paragraphs
- **Total guide**: 2-4 pages maximum (it's a reference, not a textbook)

### Format Standards

```
# Main Title

## Section Header (concept level)

### Subsection (procedure or detail)

[Body text]

```code examples```

| Table | Headers |
|-------|---------|
| Data  | Row     |
```

### Code Examples

- Use **generic placeholders**: `[username]`, `[target-ip]`, `[wordlist-file]`
- Show **typical output**: Include what success/failure looks like
- Highlight **key parameters**: What changes vs. what stays the same
- Example:
  ```bash
  hydra -l [username] -P [wordlist] [target-ip] -t 4 ssh
  ```
  Where:
  - `[username]` = The account to target
  - `[wordlist]` = File with password attempts
  - `[target-ip]` = Remote system IP
  - `-t 4` = Use 4 parallel connections

---

## Structure for Common Topics

### Topic: Remote Access (SSH)

```
# Handler Note
[What they discovered that requires SSH knowledge]

# SAFETYNET Field Guide Extract: Secure Remote Access

## What is SSH?
[Brief explanation]

## Quick Reference
[Common SSH commands table]

## Connecting to a Remote System
[Step-by-step]

## Verifying Server Identity
[Fingerprint checking explanation]

## Troubleshooting Connection Issues
[Common problems]
```

### Topic: Credential Attacks (Hydra/Bruteforce)

```
# Handler Note
[Why they need to crack credentials]

# SAFETYNET Field Guide Extract: Online Credential Testing

## What is Hydra?
[Explanation]

## Basic Syntax & Options
[Command table]

## Testing Passwords
[Step-by-step procedure]

## Selecting & Creating Wordlists
[How to choose wordlists]

## Common Patterns in Target Environments
[What weak passwords typically look like]

## Timing & Performance
[How long attacks take, optimization]

## Troubleshooting
[What to do if it's too slow, hangs, etc.]
```

### Topic: Privilege Escalation (Sudo)

```
# Handler Note
[Why escalation is needed]

# SAFETYNET Field Guide Extract: Privilege Escalation via Sudo

## Understanding Sudo
[What it is, why it matters]

## Checking Your Permissions
[sudo -l explanation]

## Running Commands as Another User
[Syntax and examples]

## Common Misconfiguration Patterns
[What to look for]

## Switching User Shells
[How to become another user]

## Troubleshooting Access Issues
[Permission denied solutions]
```

---

## Workflow: Creating a New Field Guide

1. **Identify the trigger**
   - What mission moment calls for this guide?
   - What has the player just discovered?

2. **Write the handler note**
   - Explain what they found and why it matters
   - Keep it under 6 sentences
   - Don't spoil the solution

3. **Find source material**
   - Search existing lab sheets and docs
   - Identify relevant sections to adapt

4. **Create the extract**
   - Pull key concepts and procedures
   - Genericize examples
   - Simplify if needed
   - Add tables/references for quick lookup

5. **Balance information**
   - Could they solve the mission with just this guide? (Yes)
   - Does it spoil the specific solution? (No)

6. **Review**
   - Does it make narrative sense?
   - Is the tone consistent?
   - Are examples generic but realistic?
   - Did you credit the source material?

---

## Integration with Ink & Scenario

### Delivery Mechanism

Field guides are delivered when:
1. Player discovers key intel (via event mapping)
2. Agent 0x99 sends handler note (timed message)
3. Player requests guide via dialogue
4. Guide item is delivered to inventory

### Ink Integration

In `m01_phone_agent0x99.ink`:

```ink
=== request_[guide_name] ===
~ [guide]_hint_given = true
#set_variable:[guide]_requested:true
#give_item:[guide_item_id]

[Handler note text — 2-3 sentences explaining delivery]

+ [Thanks]
    Good luck.
    -> support_hub
```

### Scenario Integration

In `scenario.json.erb`:

```json
{
  "eventPattern": "item_picked_up:some_item",
  "condition": "data.itemName === 'Some Key Intel'",
  "onceOnly": true,
  "setGlobal": { "[guide]_offered": true },
  "sendTimedMessage": {
    "delay": 3000,
    "message": "[Handler note from Agent 0x99]"
  }
}
```

---

## Quality Checklist

Before marking a field guide complete:

- [ ] Handler note is under 6 sentences and explains the "why"
- [ ] Handler note doesn't give away the specific solution
- [ ] Field guide uses only generic examples (no scenario-specific details)
- [ ] Guide teaches the concept thoroughly enough to complete the mission
- [ ] Code examples use placeholders (`[username]`, `[target]`, etc.)
- [ ] Troubleshooting section covers likely failure points
- [ ] Source material is credited
- [ ] Total length is 2-4 pages (reference, not textbook)
- [ ] Tone is consistent (professional, direct, helpful)
- [ ] Information flow is progressive (basic → advanced)
- [ ] The guide makes narrative sense in context

---

## Example: SSH Field Guide

See: `scenarios/m01_first_contact/lab_sheet/SAFETYNET_FIELD_GUIDE_[topic].md`

This document follows the structure outlined above and serves as a reference implementation.

---

## Future Guidelines

As more field guides are created:

1. **Establish templates** for common mission types (recon, access, escalation, etc.)
2. **Build a library** of reusable content sections
3. **Create variation points** — Handler notes specific to each mission type
4. **Document patterns** — What works well for teaching tactics without spoiling missions

---

**Document Version**: 1.0  
**Last Updated**: 2026-05-26  
**Author**: SAFETYNET Operations  
**For**: Mission Designers & Content Creators
