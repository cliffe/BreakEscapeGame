/**
 * WalkthroughRunner — Break Escape Scenario Automation Framework
 *
 * Automates player interactions for scenario testing. Designed to be either:
 *   1. Pasted into the browser console while the game is running, or
 *   2. Loaded via a <script> tag after the game initialises.
 *
 * Usage (browser console):
 *   // After the game has loaded the scenario, paste this entire file, then:
 *   window.walkthroughRunner.run();
 *
 * Extending for a new scenario:
 *   window.walkthroughRunner.loadSteps(mySteps);
 *   window.walkthroughRunner.run();
 *
 * ── API ──────────────────────────────────────────────────────────────────────
 *
 *   setGlobal(key, value)
 *     Sets a global variable AND fires global_variable_changed:<key>.
 *     This is the primary way to simulate in-game events without replaying
 *     full interaction chains.
 *
 *   emitEvent(eventName, data)
 *     Fires an event through the game's eventDispatcher.
 *
 *   completeTask(taskId)
 *     Directly marks a task as complete via objectivesManager.
 *
 *   assertGlobal(key, expectedValue)
 *     Returns true/false. Logs a PASS/FAIL line with the actual value.
 *
 * ── Step format ──────────────────────────────────────────────────────────────
 *
 *   Each step is an object:
 *   {
 *     label:       String — shown in the console log
 *     delayMs:     Number — milliseconds to wait BEFORE running this step (default: 300)
 *     run:         async function(api) — the step body; receives the api object
 *     assert:      optional function(api) — called after run(); return true to pass
 *   }
 */

(function (global) {
  'use strict';

  // ── helpers ─────────────────────────────────────────────────────────────────

  function logStep(index, total, label) {
    console.log(
      `%c[Walkthrough] Step ${index}/${total}: ${label}`,
      'color: #4fc3f7; font-weight: bold;'
    );
  }

  function logPass(msg) {
    console.log(`%c  ✅ ${msg}`, 'color: #81c784;');
  }

  function logFail(msg) {
    console.log(`%c  ❌ ${msg}`, 'color: #e57373; font-weight: bold;');
  }

  function logInfo(msg) {
    console.log(`%c  ℹ  ${msg}`, 'color: #90a4ae;');
  }

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // ── API surface exposed to step functions ───────────────────────────────────

  const api = {
    /**
     * Set a global variable and fire global_variable_changed:<key>.
     * This is what minigames and the Ink engine do; NPC eventMappings
     * listening for those events will react as they would in real play.
     */
    setGlobal(key, value) {
      if (!window.gameState?.globalVariables) {
        logFail(`setGlobal(${key}): gameState.globalVariables not ready`);
        return false;
      }
      window.gameState.globalVariables[key] = value;
      window.eventDispatcher?.emit(`global_variable_changed:${key}`, {
        name: key,
        value
      });
      logInfo(`setGlobal: ${key} = ${JSON.stringify(value)}`);
      return true;
    },

    /**
     * Emit an arbitrary event through the game's eventDispatcher.
     */
    emitEvent(eventName, data = {}) {
      if (!window.eventDispatcher) {
        logFail(`emitEvent(${eventName}): eventDispatcher not ready`);
        return false;
      }
      window.eventDispatcher.emit(eventName, data);
      logInfo(`emitEvent: ${eventName}`);
      return true;
    },

    /**
     * Directly complete a task through objectivesManager.
     * Use when the task's normal event chain is not being replayed.
     */
    completeTask(taskId) {
      if (!window.objectivesManager) {
        logFail(`completeTask(${taskId}): objectivesManager not ready`);
        return false;
      }
      window.objectivesManager.completeTask(taskId);
      logInfo(`completeTask: ${taskId}`);
      return true;
    },

    /**
     * Assert that a global variable has the expected value.
     * Returns true on pass; logs PASS or FAIL.
     */
    assertGlobal(key, expectedValue) {
      const actual = window.gameState?.globalVariables?.[key];
      const pass = actual === expectedValue;
      if (pass) {
        logPass(`${key} === ${JSON.stringify(expectedValue)}`);
      } else {
        logFail(`${key}: expected ${JSON.stringify(expectedValue)}, got ${JSON.stringify(actual)}`);
      }
      return pass;
    },

    /**
     * Assert that a task has a specific status.
     * Returns true on pass; logs PASS or FAIL.
     */
    assertTaskStatus(taskId, expectedStatus) {
      const task = window.objectivesManager?.taskIndex?.[taskId];
      if (!task) {
        logFail(`assertTaskStatus(${taskId}): task not found in taskIndex`);
        return false;
      }
      const pass = task.status === expectedStatus;
      if (pass) {
        logPass(`task ${taskId} status === '${expectedStatus}'`);
      } else {
        logFail(`task ${taskId}: expected status '${expectedStatus}', got '${task.status}'`);
      }
      return pass;
    },

    /**
     * Print a summary of all global variable values.
     */
    dumpGlobals() {
      console.table(window.gameState?.globalVariables ?? {});
    },

    /**
     * Print a summary of all task statuses.
     */
    dumpTasks() {
      const index = window.objectivesManager?.taskIndex ?? {};
      const rows = {};
      for (const [id, task] of Object.entries(index)) {
        rows[id] = { status: task.status, title: task.title };
      }
      console.table(rows);
    }
  };

  // ── Runner class ─────────────────────────────────────────────────────────────

  class WalkthroughRunner {
    constructor() {
      this._steps = [];
      this._running = false;
      this._aborted = false;
    }

    /**
     * Replace the current step list with a new array of step objects.
     * @param {Array} steps
     */
    loadSteps(steps) {
      this._steps = steps;
      console.log(
        `%c[Walkthrough] Loaded ${steps.length} step(s). Call .run() to begin.`,
        'color: #4fc3f7;'
      );
    }

    /**
     * Append additional steps to the existing list.
     * @param {Array} steps
     */
    appendSteps(steps) {
      this._steps = this._steps.concat(steps);
    }

    /**
     * Run all loaded steps sequentially.
     * Each step waits step.delayMs (default 300 ms) before executing.
     */
    async run() {
      if (this._running) {
        console.warn('[Walkthrough] Already running — call .abort() first.');
        return;
      }
      if (!this._steps.length) {
        console.warn('[Walkthrough] No steps loaded. Call loadSteps() first.');
        return;
      }

      // Verify game is ready
      if (!window.gameState || !window.eventDispatcher) {
        console.error(
          '[Walkthrough] Game not ready. Wait for the scenario to fully load before running.'
        );
        return;
      }

      this._running = true;
      this._aborted = false;
      const total = this._steps.length;
      let passed = 0;
      let failed = 0;

      console.log(
        `%c[Walkthrough] ── Starting ${total}-step walkthrough ──`,
        'color: #4fc3f7; font-weight: bold; font-size: 1.1em;'
      );

      for (let i = 0; i < total; i++) {
        if (this._aborted) {
          console.warn('[Walkthrough] Aborted.');
          break;
        }

        const step = this._steps[i];
        const delay = step.delayMs ?? 300;

        await sleep(delay);

        logStep(i + 1, total, step.label ?? `Step ${i + 1}`);

        try {
          await step.run(api);
        } catch (err) {
          logFail(`Step threw an error: ${err.message}`);
          console.error(err);
          failed++;
          continue;
        }

        // Give the event system a tick to process reactions
        await sleep(100);

        // Run assertion if provided
        if (typeof step.assert === 'function') {
          const ok = step.assert(api);
          if (ok) passed++;
          else failed++;
        } else {
          // No assertion — count as informational
        }
      }

      this._running = false;

      console.log(
        `%c[Walkthrough] ── Complete — ${passed} passed, ${failed} failed ──`,
        failed > 0
          ? 'color: #e57373; font-weight: bold;'
          : 'color: #81c784; font-weight: bold;'
      );

      api.dumpTasks();
    }

    /** Stop a running walkthrough after the current step. */
    abort() {
      this._aborted = true;
    }

    /** Expose the api object for ad-hoc use from the console. */
    get api() {
      return api;
    }
  }

  // ── Expose globally ──────────────────────────────────────────────────────────

  global.WalkthroughRunner = WalkthroughRunner;
  global.walkthroughRunner = new WalkthroughRunner();

  console.log(
    '%c[Walkthrough] WalkthroughRunner loaded. Use window.walkthroughRunner.',
    'color: #4fc3f7;'
  );
})(window);
