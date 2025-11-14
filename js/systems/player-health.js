import { COMBAT_CONFIG } from '../config/combat-config.js';
import { CombatEvents } from '../events/combat-events.js';

let state = null;

function createInitialState() {
  return {
    currentHP: COMBAT_CONFIG.player.maxHP,
    maxHP: COMBAT_CONFIG.player.maxHP,
    isKO: false
  };
}

export function initPlayerHealth() {
  state = createInitialState();
  console.log('✅ Player health system initialized');

  return {
    getHP: () => state.currentHP,
    getMaxHP: () => state.maxHP,
    isKO: () => state.isKO,
    damage: (amount) => damagePlayer(amount),
    heal: (amount) => healPlayer(amount),
    reset: () => { state = createInitialState(); }
  };
}

function damagePlayer(amount) {
  if (!state) {
    console.error('Player health not initialized');
    return false;
  }

  if (typeof amount !== 'number' || amount < 0) {
    console.error('Invalid damage amount:', amount);
    return false;
  }

  const oldHP = state.currentHP;
  state.currentHP = Math.max(0, state.currentHP - amount);

  // Emit HP changed event
  if (window.eventDispatcher) {
    window.eventDispatcher.emit(CombatEvents.PLAYER_HP_CHANGED, {
      hp: state.currentHP,
      maxHP: state.maxHP,
      delta: -amount
    });
  }

  // Check for KO
  if (state.currentHP <= 0 && !state.isKO) {
    state.isKO = true;
    if (window.eventDispatcher) {
      window.eventDispatcher.emit(CombatEvents.PLAYER_KO, {});
    }
  }

  console.log(`Player HP: ${oldHP} → ${state.currentHP}`);
  return true;
}

function healPlayer(amount) {
  if (!state) return false;

  const oldHP = state.currentHP;
  state.currentHP = Math.min(state.maxHP, state.currentHP + amount);

  if (window.eventDispatcher) {
    window.eventDispatcher.emit(CombatEvents.PLAYER_HP_CHANGED, {
      hp: state.currentHP,
      maxHP: state.maxHP,
      delta: amount
    });
  }

  console.log(`Player HP: ${oldHP} → ${state.currentHP}`);
  return true;
}
