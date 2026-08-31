/**
 * Walkthrough automation — sis01_healthcare (Northgate General Hospital)
 *
 * Full happy-path walkthrough: all 5 aims, best-case outcome.
 * Requires walkthrough-automation.js to be loaded first.
 *
 * ── How to load ──────────────────────────────────────────────────────────────
 *
 * Option A — Browser console (paste walkthrough-automation.js first, then this):
 *   window.walkthroughRunner.run();
 *
 * Option B — Run a single aim:
 *   window.walkthroughRunner.loadSteps(window.healthcareWalkthrough.aim1_assessWard);
 *   window.walkthroughRunner.run();
 *
 * Option C — Run from a specific aim onward:
 *   const { aim3_authoriseIsolation, aim4_restoreOperations, aim5_ncscDebrief } = window.healthcareWalkthrough;
 *   window.walkthroughRunner.loadSteps([...aim3_authoriseIsolation, ...aim4_restoreOperations, ...aim5_ncscDebrief]);
 *   window.walkthroughRunner.run();
 *
 * ── Reliability notes ────────────────────────────────────────────────────────
 *
 * HIGH RELIABILITY — driven by global_variable_changed eventMappings:
 *   talk_to_sarah, check_monitoring_station, collect_mar_charts, access_siem,
 *   brief_ravi, david_safety_case, authorise_isolation_panel, initiate_backup,
 *   helen_ico_advisory, pump_dose_check, attend_debrief
 *
 * USES api.completeTask() DIRECTLY — tasks completed via Ink tags or minigame completionActions:
 *   meet_ravi (Ink #complete_task tag; bypassed by direct call here)
 *   vpn_anomaly (minigame completionActions; bypassed by direct call + global set)
 *   verify_drug_library (minigame completionActions; bypassed by direct call + globals set)
 *
 * DUAL-AUTH BYPASS — PINs are per-session random; minigame is skipped entirely:
 *   Sets itsec_authorised, clinical_eng_authorised, network_isolation_authorised,
 *   network_isolated directly. All downstream NPC reactions still fire.
 *
 * UI CAVEAT — network_isolated=true triggers simultaneous person-chat conversations
 *   on Sarah, Ravi, David, and Helen. State will be correct; UI will be busy.
 *
 * ── How each task completes ───────────────────────────────────────────────────
 *
 * AIM 1 — assess_ward
 *   talk_to_sarah        briefing_played=true → Sarah eventMapping → completeTask
 *   check_monitoring     monitoring_station_viewed=true → Sarah eventMapping → completeTask
 *   collect_mar_charts   paper_charts_collected=true + item_picked_up:notes → ObjectivesManager
 *
 * AIM 2 — investigate_attack
 *   meet_ravi            api.completeTask() direct (Ink tag path bypassed in walkthrough)
 *                        also unlocks access_siem and vpn_anomaly via api.unlockTask()
 *   access_siem          siem_escalated=true → Ravi eventMapping → completeTask (either order vs vpn_anomaly)
 *   vpn_anomaly          vpn_anomaly_identified=true + api.completeTask() (either order vs access_siem)
 *   brief_ravi           vpn_anomaly_identified → ravi_vpn_briefed → Ravi eventMapping → completeTask
 *
 * AIM 3 — authorise_isolation
 *   david_safety_case    safety_claim_hc001_assessed=true → David eventMapping → completeTask
 *   authorise_isolation  network_isolated=true → Ravi eventMapping → completeTask
 *
 * AIM 4 — restore_operations
 *   initiate_backup      backup_restore_initiated=true → Helen eventMapping → completeTask
 *   verify_drug_library  drug_library_verified=true + flag_tasks_updated event
 *   helen_ico_advisory   ico_notified=true → Helen eventMapping → completeTask
 *   pump_dose_check      pump_dose_correct=true → bed2_patient eventMapping → completeTask
 *
 * AIM 5 — ncsc_debrief
 *   attend_debrief       debrief_complete=true → Dr Sharma eventMapping → completeTask
 */

(function (global) {
  'use strict';


  /**
   * Push a room ID into gameState.unlockedRooms and emit door_unlocked so the
   * objectives manager and door system both see the change.
   * @param {object} api
   * @param {string} roomId   — the room being unlocked
   * @param {string} fromRoom — the room the door sits in
   */
  function unlockRoom(api, roomId, fromRoom) {
    if (window.gameState?.unlockedRooms &&
        !window.gameState.unlockedRooms.includes(roomId)) {
      window.gameState.unlockedRooms.push(roomId);
    }
    api.emitEvent('door_unlocked', {
      roomId: fromRoom,
      connectedRoom: roomId,
      source: 'walkthrough'
    });
  }

  // ── AIM 1 — assess_ward ─────────────────────────────────────────────────────

  const aim1_assessWard = [

    {
      label: 'Task 1/3 — talk_to_sarah: Receive incident briefing from Charge Nurse Sarah Mitchell',
      delayMs: 500,
      run(api) {
        // Sarah's arrival_briefing timedConversation sets briefing_played=true
        // (setGlobalOnStart). Her eventMapping reacts and completes this task.
        api.setGlobal('briefing_played', true);
      },
      assert(api) {
        return api.assertGlobal('briefing_played', true);
      }
    },

    {
      label: 'Assert — talk_to_sarah task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('talk_to_sarah', 'completed');
      }
    },

    {
      label: 'Task 2/3 — check_monitoring_station: View the ransomware display on the ward monitoring station',
      delayMs: 500,
      run(api) {
        // unlock-system.js fires onRead.setVariable → monitoring_station_viewed=true
        // when the player opens the ransomware_display object. Sarah's eventMapping
        // listens for this and calls completeTask("check_monitoring_station").
        api.setGlobal('monitoring_station_viewed', true);
      },
      assert(api) {
        return api.assertGlobal('monitoring_station_viewed', true);
      }
    },

    {
      label: 'Assert — check_monitoring_station task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('check_monitoring_station', 'completed');
      }
    },

    {
      label: 'Task 3/3 — collect_mar_charts: Pick up the paper MAR charts from the nursing station drawer',
      delayMs: 500,
      run(api) {
        // inventory.js emits item_picked_up:<type> with collectionGroup on item pickup.
        // ObjectivesManager.handleItemPickup matches targetGroup:"mar_charts" → completeTask.
        // paper_charts_collected gates the infusion pump minigame in aim4.
        api.setGlobal('paper_charts_collected', true);
        api.emitEvent('item_picked_up:notes', {
          itemType:        'notes',
          itemId:          'mar_charts_stack',
          itemName:        'MAR Charts \u2014 Paper Backup',
          collectionGroup: 'mar_charts',
          roomId:          'ward_7'
        });
      },
      assert(api) {
        return api.assertGlobal('paper_charts_collected', true);
      }
    },

    {
      label: 'Assert — collect_mar_charts task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('collect_mar_charts', 'completed');
      }
    },

    // ── Aim 1 side-effects ────────────────────────────────────────────────────
    {
      label: 'Side-effects — escalate Bed 4 (prevent 22-min death timer) + unlock IT Security Office',
      delayMs: 300,
      run(api) {
        // Prevent the bed4 deterioration timer from running to DECEASED during the
        // rest of the walkthrough. bed4_escalated=true cancels the timer chain and
        // triggers the patrol nurse's patrolOverride (she rushes to Bed 4).
        api.setGlobal('bed4_escalated', true);

        // The IT Security Office door has lockType:"rfid", requires:"ravi_rfid_card".
        // Sarah gives that card in arrival_briefing via #give_item:keycard. We bypass
        // the RFID check by adding the room directly to unlockedRooms.
        unlockRoom(api, 'it_security_office', 'ward_7');
      },
      assert(api) {
        const escalated = api.assertGlobal('bed4_escalated', true);
        const unlocked  = (window.gameState?.unlockedRooms ?? []).includes('it_security_office');
        if (unlocked) {
          console.log('%c  ✅ it_security_office in unlockedRooms', 'color: #81c784;');
        } else {
          console.log('%c  ❌ it_security_office NOT in unlockedRooms', 'color: #e57373; font-weight: bold;');
        }
        return escalated && unlocked;
      }
    }

  ];

  // ── AIM 2 — investigate_attack ──────────────────────────────────────────────

  const aim2_investigateAttack = [

    {
      label: 'Task 1/4 — meet_ravi: Get briefing from Ravi Anand; unlock SIEM and VPN tasks',
      delayMs: 500,
      run(api) {
        // In normal play: player talks to Ravi → siem_briefing Ink knot fires
        // #complete_task:meet_ravi + #unlock_task:access_siem + #unlock_task:vpn_anomaly.
        // In the walkthrough we bypass Ink and drive it directly.
        api.completeTask('meet_ravi');
        // Unlock both investigation tasks so their completion events are accepted.
        if (window.objectivesManager?.unlockTask) {
          window.objectivesManager.unlockTask('access_siem');
          window.objectivesManager.unlockTask('vpn_anomaly');
        }
      },
      assert(api) {
        return api.assertTaskStatus('meet_ravi', 'completed');
      }
    },

    {
      label: 'Task 2/4 — access_siem: Complete SIEM alert triage on Ravi\'s laptop',
      delayMs: 500,
      run(api) {
        // The siem_dashboard minigame sets siem_escalated=true on success.
        // Ravi's eventMapping reacts: completeTask("access_siem") + setGlobal(ravi_siem_briefed=true).
        // Can be done in either order with vpn_anomaly.
        api.setGlobal('siem_escalated', true);
      },
      assert(api) {
        return api.assertGlobal('siem_escalated', true);
      }
    },

    {
      label: 'Assert — access_siem task status + ravi_siem_briefed side-effect',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        const task    = api.assertTaskStatus('access_siem', 'completed');
        const briefed = api.assertGlobal('ravi_siem_briefed', true);
        return task && briefed;
      }
    },

    {
      label: 'Task 3/4 — vpn_anomaly: Identify the VPN credential anomaly via log viewer',
      delayMs: 500,
      run(api) {
        // VPN log viewer minigame completionActions: vpn_anomaly_identified=true
        // + complete_task:vpn_anomaly. The global also triggers Ravi's eventMapping
        // → ravi_vpn_briefed=true → second eventMapping → completeTask("brief_ravi").
        // Can be done in either order with access_siem.
        api.setGlobal('vpn_anomaly_identified', true);
        api.completeTask('vpn_anomaly');
      },
      assert(api) {
        return api.assertGlobal('vpn_anomaly_identified', true);
      }
    },

    {
      label: 'Assert — vpn_anomaly task status + ravi_vpn_briefed side-effect',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        const task    = api.assertTaskStatus('vpn_anomaly', 'completed');
        const briefed = api.assertGlobal('ravi_vpn_briefed', true);
        return task && briefed;
      }
    },

    {
      label: 'Assert — brief_ravi completes via ravi_vpn_briefed chain',
      delayMs: 800,
      run(_api) {
        // brief_ravi is an npc_conversation task completed via two-hop eventMapping:
        //   vpn_anomaly_identified=true → setGlobal(ravi_vpn_briefed=true)
        //   ravi_vpn_briefed=true → completeTask("brief_ravi")
        // Both hops should have fired already. No extra action needed.
      },
      assert(api) {
        return api.assertTaskStatus('brief_ravi', 'completed');
      }
    },

    // ── Aim 2 side-effects ────────────────────────────────────────────────────
    {
      label: 'Side-effects — network_rules_reviewed=true (gates David\'s code) + unlock Major Incident Room',
      delayMs: 300,
      run(api) {
        // David's give_clinical_code knot is gated: "player must have reviewed
        // the NSM first" (network_rules_reviewed=true). In normal play this is
        // set when the player first toggles a rule on the network segmentation
        // map in the IT Security Office.
        api.setGlobal('network_rules_reviewed', true);

        // The Major Incident Room has no lock (connections only), but emit the
        // event for consistency and to record room discovery.
        unlockRoom(api, 'major_incident_room', 'it_security_office');
      },
      assert(api) {
        return api.assertGlobal('network_rules_reviewed', true);
      }
    }

  ];

  // ── AIM 3 — authorise_isolation ─────────────────────────────────────────────

  const aim3_authoriseIsolation = [

    {
      label: 'Task 1/2 — david_safety_case: Review CLAIM-HC-001 with David Osei (Clinical Engineering)',
      delayMs: 500,
      run(api) {
        // In normal play: player talks to David → he reviews CLAIM-HC-001 →
        // player commits to isolation → npc_david.ink sets safety_claim_hc001_assessed=true.
        // David's eventMapping reacts → completeTask("david_safety_case").
        api.setGlobal('safety_claim_hc001_assessed', true);
      },
      assert(api) {
        return api.assertGlobal('safety_claim_hc001_assessed', true);
      }
    },

    {
      label: 'Assert — david_safety_case task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('david_safety_case', 'completed');
      }
    },

    {
      label: 'Task 2/2 — authorise_isolation_panel: Dual-authorise network isolation (bypass minigame)',
      delayMs: 500,
      run(api) {
        // The dual_auth minigame requires PIN entry. PINs are per-session random
        // (ERB @random_pin). We bypass the minigame by setting all four output
        // globals directly. This produces the identical downstream state.
        //
        // Sequence matters: set the "authorised" flags first so that when
        // network_isolated fires, the conditional eventMappings that check
        // network_isolation_authorised===true see it as true.
        api.setGlobal('itsec_authorised', true);
        api.setGlobal('clinical_eng_authorised', true);
        api.setGlobal('network_isolation_authorised', true);
        // network_isolated fires the large NPC cascade:
        //   Ravi → completeTask("authorise_isolation_panel")
        //   Sarah, Ravi, David, Helen → person-chat post_isolation
        //   corridor warning light activates (UI side-effect)
        api.setGlobal('network_isolated', true);
      },
      assert(api) {
        const isolated   = api.assertGlobal('network_isolated', true);
        const authPanel  = api.assertGlobal('network_isolation_authorised', true);
        return isolated && authPanel;
      }
    },

    {
      label: 'Assert — authorise_isolation_panel task status',
      // Give the NPC cascade a moment to settle — multiple person-chats fire simultaneously
      delayMs: 1200,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('authorise_isolation_panel', 'completed');
      }
    }

  ];

  // ── AIM 4 — restore_operations ──────────────────────────────────────────────

  const aim4_restoreOperations = [

    {
      label: 'Task 1/4 — initiate_backup: Select vendor cloud backup (18-hour restore)',
      delayMs: 500,
      run(api) {
        // backup-recovery minigame sets these three globals on confirm.
        // Helen's eventMapping reacts to backup_restore_initiated → completeTask + person-chat.
        // Set source and eta first so they are readable in the eventMapping handler.
        api.setGlobal('backup_recovery_source', 'cloud_vendor');
        api.setGlobal('recovery_eta_hours', 18);
        api.setGlobal('backup_restore_initiated', true);
      },
      assert(api) {
        const source = api.assertGlobal('backup_recovery_source', 'cloud_vendor');
        const eta    = api.assertGlobal('recovery_eta_hours', 18);
        const init   = api.assertGlobal('backup_restore_initiated', true);
        return source && eta && init;
      }
    },

    {
      label: 'Assert — initiate_backup task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('initiate_backup', 'completed');
      }
    },

    {
      label: 'Task 2/4 — verify_drug_library: Drug Library Integrity Checker — morphine DOSE_MAX tampered 4→40',
      delayMs: 500,
      run(api) {
        // drug_library_terminal (MG-09) scanActions set drug_library_compromised=true;
        // completionActions set drug_library_verified=true + drug_library_restored=true
        // + complete_task:verify_drug_library.
        // Dr Sharma's eventMapping fires when BOTH drug_library_verified=true AND
        // backup_restore_initiated=true → sets debrief_started=true (Sharma appears).
        // drug_library_compromised triggers David (hc003 person-chat) and Helen
        // (pharmacist_on_ward=true → pharmacist appears on Ward 7).
        api.setGlobal('drug_library_compromised', true);
        api.setGlobal('drug_library_verified', true);
        api.setGlobal('drug_library_restored', true);
        api.completeTask('verify_drug_library');
      },
      assert(api) {
        const verified    = api.assertGlobal('drug_library_verified', true);
        const compromised = api.assertGlobal('drug_library_compromised', true);
        return verified && compromised;
      }
    },

    {
      label: 'Assert — verify_drug_library task status + debrief_started side-effect',
      // debrief_started fires when BOTH drug_library_verified AND backup_restore_initiated
      // are true. Both set by this point. Give the eventMapping chain time to resolve.
      delayMs: 1000,
      run(_api) {},
      assert(api) {
        const task    = api.assertTaskStatus('verify_drug_library', 'completed');
        const debrief = api.assertGlobal('debrief_started', true);
        return task && debrief;
      }
    },

    {
      label: 'Task 3/4 — helen_ico_advisory (optional): Notify the ICO within the 72-hour GDPR window',
      delayMs: 500,
      run(api) {
        // npc_helen.ink:ico_advisory sets ico_notified=true on player choice.
        // Helen's eventMapping reacts → completeTask("helen_ico_advisory").
        // Also stops the 45-minute ico_deadline timer from firing.
        // Dr Hartley's eventMapping fires: post_ico person-chat.
        api.setGlobal('ico_notified', true);
      },
      assert(api) {
        return api.assertGlobal('ico_notified', true);
      }
    },

    {
      label: 'Assert — helen_ico_advisory task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('helen_ico_advisory', 'completed');
      }
    },

    {
      label: 'Task 4/4 — pump_dose_check (optional): Administer correct morphine dose at Bed 2',
      delayMs: 500,
      run(api) {
        // infusion_pump minigame (MG-08) sets pump_dose_correct=true on correct entry.
        // bed2_patient's eventMapping reacts → completeTask("pump_dose_check").
        // Note: drug_library_compromised is already true from verify_drug_library above.
        // Entering pump_dose_correct (not pump_dose_error) takes the safe path —
        // the patient remains stable despite the compromised guardrails.
        api.setGlobal('pump_dose_correct', true);
      },
      assert(api) {
        return api.assertGlobal('pump_dose_correct', true);
      }
    },

    {
      label: 'Assert — pump_dose_check task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('pump_dose_check', 'completed');
      }
    },

    // ── Aim 4 safety-claim assessments (no tasks, but inform the debrief) ─────
    {
      label: 'Side-effects — assess safety claims HC-003 and HC-007 for debrief',
      delayMs: 300,
      run(api) {
        // These variables are set via Ink by David (HC-003) and Helen (HC-007).
        // They have no associated tasks but Dr Sharma reads them in the debrief
        // to branch her consequence dialogue. Set both for the best-case debrief.
        api.setGlobal('safety_claim_hc003_assessed', true);
        api.setGlobal('safety_claim_hc007_assessed', true);
      }
    }

  ];

  // ── AIM 5 — ncsc_debrief ────────────────────────────────────────────────────

  const aim5_ncscDebrief = [

    {
      label: 'Task 1/1 — attend_debrief: Complete Dr Sharma\'s five-topic NCSC debrief',
      delayMs: 500,
      run(api) {
        // Dr Sharma's Ink closing knot sets debrief_complete=true.
        // Her eventMapping on debrief_complete=true → completeTask("attend_debrief").
        // Setting this directly simulates the player completing the full debrief
        // conversation (patient outcomes → safety claims → regulatory → root cause → closing).
        api.setGlobal('debrief_complete', true);
      },
      assert(api) {
        return api.assertGlobal('debrief_complete', true);
      }
    },

    {
      label: 'Assert — attend_debrief task status',
      delayMs: 800,
      run(_api) {},
      assert(api) {
        return api.assertTaskStatus('attend_debrief', 'completed');
      }
    },

    // ── Final state summary ───────────────────────────────────────────────────
    {
      label: 'Final summary — full scenario state dump',
      delayMs: 300,
      run(api) {
        console.log('%c[Walkthrough] ── Final scenario state ──', 'color: #4fc3f7; font-weight: bold;');
        const vars = window.gameState?.globalVariables ?? {};

        const groups = {
          'Phase 1 — Ward 7': [
            'briefing_played', 'monitoring_station_viewed', 'paper_charts_collected',
            'bed4_escalated', 'patient_bed4_state', 'patient_bed4_deceased',
            'patient_bed2_state', 'patient_bed2_deceased', 'pump_dose_correct'
          ],
          'Phase 2 — IT Security': [
            'siem_escalated', 'siem_missed_alerts', 'vpn_anomaly_identified',
            'ravi_siem_briefed', 'ravi_vpn_briefed', 'network_rules_reviewed'
          ],
          'Phase 3 — Major Incident': [
            'itsec_authorised', 'clinical_eng_authorised',
            'network_isolation_authorised', 'network_isolated', 'dual_auth_failed',
            'safety_claim_hc001_assessed'
          ],
          'Phase 4 — Recovery': [
            'backup_recovery_source', 'recovery_eta_hours', 'backup_restore_initiated',
            'backup_reinfected', 'drug_library_verified', 'drug_library_compromised',
            'ico_notified', 'ico_deadline_missed',
            'safety_claim_hc003_assessed', 'safety_claim_hc007_assessed'
          ],
          'Phase 5 — Debrief': [
            'debrief_started', 'sharma_visible', 'debrief_complete'
          ]
        };

        for (const [group, keys] of Object.entries(groups)) {
          console.log(`%c  ${group}`, 'color: #90a4ae; font-style: italic;');
          keys.forEach(k => {
            const v = vars[k];
            const ok = v === true || (typeof v === 'string' && v !== '') || v === 18;
            const style = ok ? 'color: #81c784;' : 'color: #e57373;';
            console.log(`%c    ${k}: ${JSON.stringify(v)}`, style);
          });
        }

        api.dumpTasks();
      }
    }

  ];

  // ── Register with the global runner ─────────────────────────────────────────

  if (!global.walkthroughRunner) {
    console.error(
      '[Healthcare Walkthrough] walkthroughRunner not found. ' +
      'Load walkthrough-automation.js before this file.'
    );
    return;
  }

  // Expose step groups for selective use from the console
  global.healthcareWalkthrough = {
    aim1_assessWard,
    aim2_investigateAttack,
    aim3_authoriseIsolation,
    aim4_restoreOperations,
    aim5_ncscDebrief,

    // Convenience: full happy-path in one array
    get fullWalkthrough() {
      return [
        ...aim1_assessWard,
        ...aim2_investigateAttack,
        ...aim3_authoriseIsolation,
        ...aim4_restoreOperations,
        ...aim5_ncscDebrief
      ];
    }
  };

  // Load the full happy-path by default
  global.walkthroughRunner.loadSteps(global.healthcareWalkthrough.fullWalkthrough);

  console.log(
    '%c[Healthcare Walkthrough] Full happy-path loaded (' +
    global.healthcareWalkthrough.fullWalkthrough.length +
    ' steps).\n' +
    '  Run all:      window.walkthroughRunner.run()\n' +
    '  Run one aim:  window.walkthroughRunner.loadSteps(window.healthcareWalkthrough.aim1_assessWard); window.walkthroughRunner.run()\n' +
    '  Inspect aims: window.healthcareWalkthrough',
    'color: #4fc3f7;'
  );

})(window);
