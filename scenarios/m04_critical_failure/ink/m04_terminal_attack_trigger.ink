// ===========================================
// ENTROPY COMMAND LAPTOP - ATTACK TRIGGER TERMINAL
// Mission 4: Critical Failure
// Break Escape - Remote Trigger Disabling Sequence
// ===========================================

// Variables for tracking disabling progress
VAR physical_bypasses_disabled = 0    // 0-3 dosing stations
VAR scada_malware_disabled = false    // Malicious script removed
VAR trigger_mechanism_disabled = false // Remote trigger neutralized
VAR attack_vectors_disabled = 0       // Total count (0-3)
VAR emergency_intervention = false    // Voltage triggered attack

// Game state variables
VAR voltage_captured = false
VAR attack_trigger_secured = false

// ===========================================
// TERMINAL ACCESS
// Location: Maintenance Wing, Voltage's Laptop
// Task 3.2: Disable Attack Mechanisms
// ===========================================

=== laptop_access_start ===
#speaker:system

// Terminal interface - ENTROPY command and control laptop

╔════════════════════════════════════════════════╗
║  OPTIGRID SOLUTIONS - REMOTE MAINTENANCE      ║
║  Critical Mass Operation: CHLORINE PROTOCOL   ║
╚════════════════════════════════════════════════╝

{voltage_captured:
    [OPERATOR: Voltage - SESSION TERMINATED]
    [SAFETYNET Override Active]
}
{not voltage_captured and attack_trigger_secured:
    [OPERATOR: Unknown - SESSION SECURED]
    [Manual Control Available]
}
{not voltage_captured and not attack_trigger_secured:
    [OPERATOR: Voltage - ACTIVE]
    [WARNING: Session In Progress]
}

* [Access Attack Status]
    -> attack_status_display

* [Disable Attack Mechanisms]
    -> disable_attack_menu

* {voltage_captured or attack_trigger_secured} [Review Operation Files]
    -> operation_files_access

=== attack_status_display ===
#speaker:system

// Display current attack vector status

═══════════════════════════════════════
ATTACK VECTOR STATUS
═══════════════════════════════════════

[VECTOR 1: PHYSICAL BYPASS DEVICES]
Status: {physical_bypasses_disabled >= 3: DISABLED | ACTIVE}
Dosing Station 1: {physical_bypasses_disabled >= 1: DISCONNECTED | ARMED}
Dosing Station 2: {physical_bypasses_disabled >= 2: DISCONNECTED | ARMED}
Dosing Station 3: {physical_bypasses_disabled >= 3: DISCONNECTED | ARMED}

[VECTOR 2: SCADA MALWARE]
Status: {scada_malware_disabled: NEUTRALIZED | ACTIVE}
Target: SCADA Backup Server (192.168.100.10)
Script: dosing_override.sh {scada_malware_disabled: [DELETED] | [ACTIVE]}

[VECTOR 3: REMOTE TRIGGER]
Status: {trigger_mechanism_disabled: DISABLED | READY}
Trigger Mode: {trigger_mechanism_disabled: SAFED | ARMED}

═══════════════════════════════════════
OVERALL THREAT STATUS: {attack_vectors_disabled >= 3: NEUTRALIZED | ACTIVE}
Attack Vectors Disabled: {attack_vectors_disabled}/3
═══════════════════════════════════════

+ [Return to main menu]
    -> laptop_access_start

=== disable_attack_menu ===
#speaker:system

{attack_vectors_disabled >= 3:
    All attack vectors have been successfully disabled.

    The threat has been neutralized.

    -> attack_fully_disabled
- else:

    ═══════════════════════════════════════
    DISABLE ATTACK MECHANISMS
    ═══════════════════════════════════════

    Select attack vector to disable:

    + [Vector 1: Physical Bypass Devices]
        -> disable_physical_bypasses

    + [Vector 2: SCADA Malware]
        -> disable_scada_malware

    + [Vector 3: Remote Trigger Mechanism]
        -> disable_remote_trigger

    + [Check status]
        -> attack_status_display
}

=== disable_physical_bypasses ===
#speaker:system

{physical_bypasses_disabled >= 3:
    Physical bypass devices have already been disconnected.

    All three dosing stations secured.

    + [Return]
        -> disable_attack_menu
- else:

    Physical bypass devices must be disabled manually at each dosing station.

    Location: Chemical Storage, Dosing Control Panels

    {physical_bypasses_disabled == 0:
        No dosing stations disconnected yet. Proceed to Chemical Storage.
    - physical_bypasses_disabled == 1:
        1 dosing station disconnected. 2 remaining.
    - physical_bypasses_disabled == 2:
        2 dosing stations disconnected. 1 remaining.
    }

    [NOTE: Use dosing station control panels to disconnect bypass hardware]

    + [Return to menu]
        -> disable_attack_menu
}

=== disable_scada_malware ===
#speaker:system

{scada_malware_disabled:
    SCADA malware has already been neutralized.

    Malicious script dosing_override.sh deleted from backup server.

    + [Return]
        -> disable_attack_menu
- else:

    Malicious SCADA control script detected on backup server.

    Target: 192.168.100.10 (SCADA Backup Server)
    File: /opt/scada/scripts/dosing_override.sh

    This script enables remote manipulation of chlorine dosing parameters.

    [REQUIRED: VM terminal access to delete malicious script]

    * [Delete malicious script via VM]
        You access the SCADA backup server through the VM terminal.
        -> scada_malware_deletion

    * [Return to menu]
        -> disable_attack_menu
}

=== scada_malware_deletion ===
#speaker:system

~ scada_malware_disabled = true
~ attack_vectors_disabled += 1

Accessing SCADA backup server...

$ rm /opt/scada/scripts/dosing_override.sh
[Malicious script deleted]

$ systemctl restart scada-control
[SCADA control service restarted]

[SUCCESS] SCADA malware neutralized.

Chlorine dosing automation returned to normal facility control.

+ [Return to disable menu]
    -> disable_attack_menu

=== disable_remote_trigger ===
#speaker:system

{trigger_mechanism_disabled:
    Remote trigger mechanism already disabled.

    Attack cannot be initiated remotely.

    + [Return]
        -> disable_attack_menu
- else:

    Remote trigger mechanism control interface.

    {voltage_captured:
        [VOLTAGE CAPTURED - Safe to disable trigger]
    - attack_trigger_secured:
        [TRIGGER SECURED - Proceeding with disabling]
    - emergency_intervention:
        [EMERGENCY MODE - Attack partially triggered, immediate intervention required]
    }

    WARNING: Trigger mechanism is complex. Incorrect disabling sequence may cause fail-safe activation.

    * [Carefully disable trigger mechanism]
        -> trigger_disabling_sequence

    * [Return to menu]
        -> disable_attack_menu
}

=== trigger_disabling_sequence ===
#speaker:system

Analyzing trigger mechanism structure...

Identified components:
- Encrypted command channel (TLS connection to dosing stations)
- Fail-safe timer (dormant)
- Manual trigger button (active)

Recommended disabling sequence:
1. Sever encrypted command channel
2. Neutralize fail-safe timer
3. Safe manual trigger

* [Execute disabling sequence]
    -> trigger_disable_step1

=== trigger_disable_step1 ===
#speaker:system

Step 1: Severing encrypted command channel...

$ iptables -A OUTPUT -d 192.168.100.0/24 -j DROP
[Firewall rule added - outbound connections blocked]

Command channel severed. Trigger cannot communicate with dosing stations.

+ [Continue to Step 2]
    -> trigger_disable_step2

=== trigger_disable_step2 ===
#speaker:system

Step 2: Neutralizing fail-safe timer...

$ systemctl stop trigger-failsafe.service
$ systemctl disable trigger-failsafe.service
[Fail-safe timer disabled]

Fail-safe mechanism neutralized.

+ [Continue to Step 3]
    -> trigger_disable_step3

=== trigger_disable_step3 ===
#speaker:system

Step 3: Safing manual trigger...

$ chmod 000 /opt/entropy/trigger_execute.sh
$ chown root:root /opt/entropy/trigger_execute.sh
[Manual trigger permissions revoked]

Manual trigger safed. Cannot be executed.

+ [Finalize disabling]
    -> trigger_disabled_success

=== trigger_disabled_success ===
#speaker:system

~ trigger_mechanism_disabled = true
~ attack_vectors_disabled += 1

╔════════════════════════════════════════════════╗
║  REMOTE TRIGGER MECHANISM DISABLED            ║
╚════════════════════════════════════════════════╝

[SUCCESS] Attack cannot be initiated remotely.

All trigger components neutralized:
✓ Command channel severed
✓ Fail-safe timer disabled
✓ Manual trigger safed

+ [Return to main menu]
    -> disable_attack_menu

=== attack_fully_disabled ===
#speaker:system

╔════════════════════════════════════════════════╗
║  ALL ATTACK VECTORS NEUTRALIZED               ║
║  THREAT ELIMINATED                            ║
╚════════════════════════════════════════════════╝

Attack Status: DISABLED

✓ Physical bypass devices disconnected (3/3)
✓ SCADA malware neutralized
✓ Remote trigger mechanism disabled

The water treatment facility is secure.

240,000 residents are safe.

// TRIGGERS: Task 3.2 complete (disable_attack_vectors)

+ [Exit terminal]
    -> terminal_exit

=== operation_files_access ===
#speaker:system

// Intelligence files on Voltage's laptop

═══════════════════════════════════════
OPERATION FILES
═══════════════════════════════════════

[CHLORINE_PROTOCOL_BRIEF.txt]
"Critical Mass Operation - Pacific Northwest Regional Water Treatment Facility
Objective: Demonstrate infrastructure vulnerability via chemical contamination
Target Population: 240,000 residents
Execution: 0800 local time
The Architect approved this operation as Phase 1 test run."

[OPTIGRID_CONTRACTS.xlsx]
"OptiGrid Solutions - Active Contracts (40 facilities nationwide)
[NOTE: 12 facilities marked with asterisk - likely compromised]"

[COORDINATION_LOG.txt]
"Social Fabric standing by for disinformation amplification.
The Architect expects SAFETYNET interference.
Contingency: Even if stopped, proves vulnerability.
Multi-city operations pending Phase 2 approval."

═══════════════════════════════════════

[Intelligence gathered - valuable for Task Force Null operations]

+ [Return to main menu]
    -> laptop_access_start

=== terminal_exit ===
#speaker:system

Terminal session ended.

Laptop secured for intelligence analysis.

#exit_conversation
-> start
