export const COMBAT_CONFIG = {
  player: {
    maxHP: 100,
    punchDamage: 20,
    punchRange: 60,
    punchCooldown: 1000,
    punchAnimationDuration: 500
  },
  npc: {
    defaultMaxHP: 100,
    defaultPunchDamage: 10,
    defaultPunchRange: 50,
    defaultAttackCooldown: 2000,
    attackWindupDuration: 500,
    chaseSpeed: 120,
    chaseRange: 400,
    attackStopDistance: 45
  },
  ui: {
    maxHearts: 5,
    healthBarWidth: 60,
    healthBarHeight: 6,
    healthBarOffsetY: -40,
    damageNumberDuration: 1000,
    damageNumberRise: 50
  },
  feedback: {
    enableScreenFlash: true,
    enableScreenShake: true,
    enableDamageNumbers: true,
    enableSounds: true
  },

  validate() {
    console.log('✅ Combat config loaded');
    return true;
  }
};
