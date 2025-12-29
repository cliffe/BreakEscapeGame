// ===========================================
// SCADA MONITORING TERMINAL
// Mission 4: Critical Failure
// Break Escape - SCADA Display Interface and Anomaly Detection
// ===========================================

// Variables for tracking investigation
VAR scada_anomalies_identified = false
VAR parameter_readings_reviewed = false

// Game state variables
VAR urgency_stage = 0
VAR attack_vectors_disabled = 0
VAR chen_is_ally = false

// ===========================================
// SCADA TERMINAL ACCESS
// Location: Control Room
// Task 1.4: Identify SCADA Anomalies
// ===========================================

=== start ===
-> scada_terminal_start

=== scada_terminal_start ===
#speaker:system

// SCADA monitoring terminal interface

╔════════════════════════════════════════════════╗
║  PACIFIC NORTHWEST WATER TREATMENT FACILITY   ║
║  SCADA MONITORING SYSTEM v4.2.1               ║
╚════════════════════════════════════════════════╝

[SYSTEM STATUS: {attack_vectors_disabled >= 3: SECURE | MONITORING}]
{urgency_stage >= 4:
    [URGENCY LEVEL: CRITICAL]
}
{urgency_stage == 3:
    [URGENCY LEVEL: HIGH]
}
{urgency_stage == 2:
    [URGENCY LEVEL: ELEVATED]
}
{urgency_stage < 2:
    [URGENCY LEVEL: NORMAL]
}

* [View Chemical Dosing Parameters]
    -> view_dosing_parameters

* [View System Alerts]
    -> view_system_alerts

* [View Network Status]
    -> view_network_status

* {scada_anomalies_identified} [Review Identified Anomalies]
    -> review_anomalies

* [Exit Terminal]
    -> terminal_exit

=== view_dosing_parameters ===
#speaker:system

~ parameter_readings_reviewed = true

═══════════════════════════════════════
CHEMICAL DOSING PARAMETERS
═══════════════════════════════════════

{attack_vectors_disabled >= 3:
    [ALL SYSTEMS NORMAL]

    Chlorine: 0.8 ppm (SAFE)
    Fluoride: 0.7 ppm (SAFE)
    pH Level: 7.2 (SAFE)

    All parameters within safe operational ranges.
    Automated control restored.
}
{attack_vectors_disabled < 3 and urgency_stage >= 4:
    [CRITICAL WARNING]

    Chlorine: 3.2 ppm → 4.1 ppm (DANGEROUS TREND)
    Fluoride: 1.8 ppm (ELEVATED)
    pH Level: 6.3 → 6.1 (DECLINING)

    ⚠ PARAMETERS APPROACHING TOXIC LEVELS
    ⚠ IMMEDIATE INTERVENTION REQUIRED
}
{attack_vectors_disabled < 3 and urgency_stage == 3:
    [HIGH ALERT]

    Chlorine: 1.8 ppm → 2.3 ppm (ELEVATED)
    Fluoride: 1.4 ppm (ELEVATED)
    pH Level: 6.7 (DECLINING)

    ⚠ ABNORMAL PARAMETER DRIFT DETECTED
    ⚠ TRENDING TOWARD UNSAFE LEVELS
}
{attack_vectors_disabled < 3 and urgency_stage == 2:
    [ELEVATED MONITORING]

    Chlorine: 1.1 ppm → 1.4 ppm (RISING)
    Fluoride: 0.9 ppm (NORMAL)
    pH Level: 6.9 (SLIGHTLY LOW)

    ⚠ CHLORINE DOSING ANOMALY DETECTED
    ⚠ PARAMETERS DRIFTING FROM BASELINE
}
{attack_vectors_disabled < 3 and urgency_stage < 2:
    [MONITORING]

    Chlorine: 0.8 ppm → 0.9 ppm (SLIGHT INCREASE)
    Fluoride: 0.7 ppm (NORMAL)
    pH Level: 7.1 (NORMAL)

    ⚠ MINOR CHLORINE PARAMETER ANOMALY
}

Last Manual Adjustment: 72 hours ago
Current Control Mode: {attack_vectors_disabled >= 3: MANUAL OVERRIDE | AUTOMATED (ANOMALOUS)}

+ [Return to main menu]
    -> scada_terminal_start

=== view_system_alerts ===
#speaker:system

═══════════════════════════════════════
SYSTEM ALERTS
═══════════════════════════════════════

{attack_vectors_disabled >= 3:
    [00:00] - ALERT CLEARED: Manual override successful
    [00:00] - SYSTEM SECURE: All attack vectors neutralized
    [00:00] - NORMAL OPERATIONS RESTORED

    No active alerts.
}
{attack_vectors_disabled < 3 and urgency_stage >= 4:
    [ACTIVE] - CRITICAL: Chemical dosing exceeding safe thresholds
    [ACTIVE] - WARNING: Automated control anomaly
    [ACTIVE] - WARNING: Unusual network traffic patterns
    [ACTIVE] - WARNING: Unauthorized SCADA script detected

    4 CRITICAL ALERTS REQUIRE IMMEDIATE ATTENTION
}
{attack_vectors_disabled < 3 and urgency_stage == 3:
    [ACTIVE] - WARNING: Chemical dosing parameter drift
    [ACTIVE] - WARNING: Automated control anomaly
    [ACTIVE] - INFO: Network connection to 192.168.100.10 active

    3 ALERTS REQUIRE ATTENTION
}
{attack_vectors_disabled < 3 and urgency_stage == 2:
    [ACTIVE] - INFO: Chlorine dosing trend anomaly
    [ACTIVE] - INFO: Automated adjustments not logged in manual log
    [ACTIVE] - INFO: Unusual SCADA backup server activity

    3 INFORMATIONAL ALERTS
}
{attack_vectors_disabled < 3 and urgency_stage < 2:
    [ACTIVE] - INFO: Minor chlorine parameter variation
    [ACTIVE] - INFO: SCADA backup server connectivity check

    2 INFORMATIONAL ALERTS
}

+ [Investigate Alerts]
    -> investigate_alerts

+ [Return to main menu]
    -> scada_terminal_start

=== investigate_alerts ===
#speaker:system

~ scada_anomalies_identified = true

Investigating alert details...

{not chen_is_ally:
    // Player discovering anomalies independently

    ALERT ANALYSIS:
    • Chlorine dosing parameters changing WITHOUT manual input
    • Changes NOT reflected in facility operator logs
    • Network traffic to SCADA backup server (192.168.100.10)
    • Automated control behavior INCONSISTENT with normal patterns

    CONCLUSION: SCADA network may be compromised.
    External control mechanism suspected.

    [RECOMMENDATION: Investigate server room and SCADA backup server]

    // TRIGGERS: Task 1.4 completion hint
- else:
    // Chen already explained - player reviewing

    ALERT ANALYSIS:
    • Confirmed: ENTROPY operatives installed attack infrastructure
    • Malicious SCADA script on backup server
    • Physical bypass devices on dosing stations
    • Remote trigger mechanism active

    [RECOMMENDATION: Disable all three attack vectors]
}

+ [Return to main menu]
    -> scada_terminal_start

=== view_network_status ===
#speaker:system

═══════════════════════════════════════
NETWORK STATUS
═══════════════════════════════════════

SCADA Network Topology:
- Control Room Terminal: 192.168.100.1
- Dosing Station 1: 192.168.100.11
- Dosing Station 2: 192.168.100.12
- Dosing Station 3: 192.168.100.13
- Backup Server: 192.168.100.10

{attack_vectors_disabled >= 3:
    Active Connections: 5/5 (NORMAL)
    Suspicious Activity: NONE
    Firewall Status: ACTIVE

    Network secured.

- else:
    Active Connections: 6/5 (ANOMALOUS)
    Suspicious Activity: DETECTED
    Unknown Connection: 192.168.100.10 → Unknown External

    ⚠ UNAUTHORIZED NETWORK CONNECTION DETECTED
}

+ [Return to main menu]
    -> scada_terminal_start

=== review_anomalies ===
#speaker:system

IDENTIFIED ANOMALIES SUMMARY:

1. Automated chemical dosing changes without manual input
2. Network traffic to/from SCADA backup server (suspicious)
3. Parameter drift toward dangerous contamination levels
4. External control mechanism suspected

ATTACK MECHANISM:
- Physical bypass devices on dosing stations
- Malicious SCADA script on backup server
- Remote trigger for coordinated attack

{attack_vectors_disabled >= 3:
    STATUS: ALL VECTORS NEUTRALIZED
- else:
    STATUS: ATTACK ACTIVE - IMMEDIATE INTERVENTION REQUIRED
}

+ [Return to main menu]
    -> scada_terminal_start

=== terminal_exit ===
#speaker:system

Terminal session ended.

{urgency_stage >= 4:
    ⚠ CRITICAL ALERT: Immediate action required
}
{urgency_stage >= 3 and urgency_stage < 4:
    ⚠ WARNING: Time-sensitive threat
}

#exit_conversation
-> start
