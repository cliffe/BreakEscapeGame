import { COMBAT_CONFIG } from '../config/combat-config.js';
import { CombatEvents } from '../events/combat-events.js';

const npcHostileStates = new Map();

function createHostileState(npcId, config = {}) {
  return {
    isHostile: false,
    currentHP: config.maxHP || COMBAT_CONFIG.npc.defaultMaxHP,
    maxHP: config.maxHP || COMBAT_CONFIG.npc.defaultMaxHP,
    isKO: false,
    attackDamage: config.attackDamage || COMBAT_CONFIG.npc.defaultPunchDamage,
    attackRange: config.attackRange || COMBAT_CONFIG.npc.defaultPunchRange,
    attackCooldown: config.attackCooldown || COMBAT_CONFIG.npc.defaultAttackCooldown,
    lastAttackTime: 0
  };
}

export function initNPCHostileSystem() {
  console.log('✅ NPC hostile system initialized');

  return {
    setNPCHostile: (npcId, isHostile) => setNPCHostile(npcId, isHostile),
    isNPCHostile: (npcId) => isNPCHostile(npcId),
    getState: (npcId) => getNPCHostileState(npcId),
    damageNPC: (npcId, amount) => damageNPC(npcId, amount),
    isNPCKO: (npcId) => isNPCKO(npcId)
  };
}

function setNPCHostile(npcId, isHostile) {
  if (!npcId) {
    console.error('setNPCHostile: Invalid NPC ID');
    return false;
  }

  // Get or create state
  let state = npcHostileStates.get(npcId);
  if (!state) {
    state = createHostileState(npcId);
    npcHostileStates.set(npcId, state);
  }

  const wasHostile = state.isHostile;
  state.isHostile = isHostile;

  console.log(`NPC ${npcId} hostile: ${wasHostile} → ${isHostile}`);

  // Emit event if state changed
  if (wasHostile !== isHostile && window.eventDispatcher) {
    window.eventDispatcher.emit(CombatEvents.NPC_HOSTILE_CHANGED, {
      npcId,
      isHostile
    });
  }

  return true;
}

function isNPCHostile(npcId) {
  const state = npcHostileStates.get(npcId);
  return state ? state.isHostile : false;
}

function getNPCHostileState(npcId) {
  let state = npcHostileStates.get(npcId);
  if (!state) {
    state = createHostileState(npcId);
    npcHostileStates.set(npcId, state);
  }
  return state;
}

function damageNPC(npcId, amount) {
  const state = getNPCHostileState(npcId);
  if (!state) return false;

  if (state.isKO) {
    console.log(`NPC ${npcId} already KO`);
    return false;
  }

  const oldHP = state.currentHP;
  state.currentHP = Math.max(0, state.currentHP - amount);

  console.log(`NPC ${npcId} HP: ${oldHP} → ${state.currentHP}`);

  // Check for KO
  if (state.currentHP <= 0) {
    state.isKO = true;
    if (window.eventDispatcher) {
      window.eventDispatcher.emit(CombatEvents.NPC_KO, { npcId });
    }
  }

  return true;
}

function isNPCKO(npcId) {
  const state = npcHostileStates.get(npcId);
  return state ? state.isKO : false;
}
