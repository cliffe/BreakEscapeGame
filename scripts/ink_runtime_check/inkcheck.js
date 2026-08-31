#!/usr/bin/env node
// Runtime health check for Break Escape ink scripts.
// DFS over the choice tree from a declared entry knot; reports runtime errors,
// runaways, and unreachable content. Usage: node inkcheck.js <file.json> [knot]

const fs = require('fs');
const path = require('path');
const REPO = '/home/cliffe/Files/Projects/Code/BreakEscape/BreakEscape';
const inkjs = require(path.join(REPO, 'public/break_escape/assets/vendor/ink.js'));
const Story = inkjs.Story || (inkjs.default && inkjs.default.Story);

// The six externals the engine actually binds (person-chat-conversation.js:96-129,
// phone-chat-conversation.js:124-158)
const EXTERNALS = {
  player_name: () => 'Alex',
  current_mission_id: () => 'm04_critical_failure',
  npc_location: () => 'battery_hall_1',
  mission_phase: () => 'infiltration',
  operational_stress_level: () => 'normal',
  equipment_status: () => 'nominal',
};

const MAX_CONTINUES = 400;   // beyond this we call it a runaway
const MAX_PATHS = 800;       // cap the DFS
const MAX_DEPTH = 60;

function newStory(json, knot) {
  const s = new Story(json);
  const errors = [];
  s.onError = (msg, type) => errors.push(`${type}: ${msg}`);
  for (const [name, fn] of Object.entries(EXTERNALS)) {
    try { s.BindExternalFunction(name, fn); } catch (e) { /* not declared: fine */ }
  }
  // Simulate the engine's sync-in of globalVariables (npc-conversation-state.js:239)
  for (const [k, v] of Object.entries(VARS)) {
    if (s.variablesState.GlobalVariableExistsWithName(k)) s.variablesState[k] = v;
  }
  if (knot) {
    try { s.ChoosePathString(knot); }
    catch (e) { return { fatal: `ChoosePathString('${knot}'): ${e.message}`, story: s, errors }; }
  }
  return { story: s, errors };
}

function runPath(json, knot, choices) {
  const { story, errors, fatal } = newStory(json, knot);
  if (fatal) return { fatal, errors };
  let continues = 0;
  let idx = 0;
  const knotsSeen = new Set();
  try {
    while (true) {
      while (story.canContinue) {
        story.Continue();
        if (++continues > MAX_CONTINUES) return { runaway: true, continues, errors };
      }
      const cp = story.state.currentPathString;
      if (cp) knotsSeen.add(cp.split('.')[0]);
      if (errors.length) return { errors, continues, knotsSeen };
      if (story.currentChoices.length === 0) return { clean: true, continues, knotsSeen, errors };
      if (idx >= choices.length) return { open: story.currentChoices.length, continues, knotsSeen, errors };
      story.ChooseChoiceIndex(choices[idx++]);
    }
  } catch (e) {
    return { thrown: e.message, continues, errors, knotsSeen };
  }
}

function enumerate(file, knot) {
  const json = fs.readFileSync(file, 'utf8');
  const stack = [[]];
  let paths = 0, clean = 0, runaway = 0;
  const failures = new Map();
  const knotsSeen = new Set();
  let fatal = null;

  while (stack.length && paths < MAX_PATHS) {
    const choices = stack.pop();
    const r = runPath(json, knot, choices);
    if (r.fatal) { fatal = r.fatal; break; }
    (r.knotsSeen || []).forEach(k => knotsSeen.add(k));
    if (r.runaway) { runaway++; paths++; continue; }
    if (r.errors && r.errors.length) {
      paths++;
      const key = r.errors[0].slice(0, 140);
      failures.set(key, (failures.get(key) || 0) + 1);
      continue;
    }
    if (r.thrown) {
      paths++;
      const key = 'THROWN: ' + r.thrown.slice(0, 140);
      failures.set(key, (failures.get(key) || 0) + 1);
      continue;
    }
    if (r.clean) { paths++; clean++; continue; }
    if (r.open !== undefined) {
      if (choices.length >= MAX_DEPTH) { paths++; clean++; continue; }
      for (let i = r.open - 1; i >= 0; i--) stack.push([...choices, i]);
    }
  }
  return { paths, clean, runaway, failures, knotsSeen, fatal };
}

// Var overrides: KEY=VALUE after the knot arg (true/false/int/string)
const VARS = {};
for (const arg of process.argv.slice(4)) {
  const i = arg.indexOf('=');
  if (i < 0) continue;
  const k = arg.slice(0, i), raw = arg.slice(i + 1);
  VARS[k] = raw === 'true' ? true : raw === 'false' ? false
          : /^-?\d+$/.test(raw) ? parseInt(raw, 10) : raw;
}

const [, , file, knot] = process.argv;
const res = enumerate(file, knot);
const name = path.basename(file);
if (res.fatal) {
  console.log(`❌ ${name} @ ${knot || '(start)'}  FATAL  ${res.fatal}`);
  process.exit(1);
}
const bad = res.paths - res.clean;
const status = bad === 0 && res.runaway === 0 ? '✅' : '❌';
console.log(`${status} ${name} @ ${knot || '(start)'}  paths=${res.paths} clean=${res.clean} runaway=${res.runaway} failing=${bad - res.runaway}`);
for (const [msg, n] of res.failures) console.log(`     ×${n}  ${msg}`);
process.exit(bad === 0 && res.runaway === 0 ? 0 : 1);
