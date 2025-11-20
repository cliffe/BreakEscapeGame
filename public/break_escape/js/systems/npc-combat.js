/**
 * NPC Combat System
 * Handles NPC attacks on the player
 */

import { COMBAT_CONFIG } from '../config/combat-config.js';

export class NPCCombat {
  constructor(scene) {
    this.scene = scene;
    this.npcAttackTimers = new Map(); // npcId -> last attack time

    console.log('✅ NPC combat system initialized');
  }

  /**
   * Check if NPC can attack player
   * @param {string} npcId
   * @returns {boolean}
   */
  canAttack(npcId) {
    if (!window.npcHostileSystem) return false;

    const state = window.npcHostileSystem.getState(npcId);
    if (!state || !state.isHostile || state.isKO) {
      return false;
    }

    // Don't attack while a minigame is active (conversation, combat, etc.)
    if (window.MinigameFramework && window.MinigameFramework.currentMinigame) {
      return false;
    }

    // Check cooldown
    const lastAttackTime = this.npcAttackTimers.get(npcId) || 0;
    const now = Date.now();
    const timeSinceLast = now - lastAttackTime;

    return timeSinceLast >= state.attackCooldown;
  }

  /**
   * Attempt NPC attack on player
   * Called by hostile behavior when NPC is in range
   * @param {string} npcId
   * @param {Phaser.GameObjects.Sprite} npcSprite
   * @returns {boolean} - True if attack was initiated
   */
  attemptAttack(npcId, npcSprite) {
    if (!this.canAttack(npcId)) {
      return false;
    }

    if (!window.player) {
      return false;
    }

    const state = window.npcHostileSystem.getState(npcId);
    if (!state) return false;

    // Check if player is in range
    const distance = Phaser.Math.Distance.Between(
      npcSprite.x,
      npcSprite.y,
      window.player.x,
      window.player.y
    );

    if (distance > state.attackRange) {
      return false;
    }

    // Start attack sequence
    this.performAttack(npcId, npcSprite, state);
    return true;
  }

  /**
   * Perform attack sequence
   * @param {string} npcId
   * @param {Phaser.GameObjects.Sprite} npcSprite
   * @param {Object} state - NPC hostile state
   */
  performAttack(npcId, npcSprite, state) {
    // Update attack timer
    this.npcAttackTimers.set(npcId, Date.now());

    // Show telegraph
    if (window.attackTelegraph) {
      window.attackTelegraph.show(npcId, npcSprite, COMBAT_CONFIG.npc.attackWindupDuration);
    }

    // Play attack animation after windup
    this.scene.time.delayedCall(COMBAT_CONFIG.npc.attackWindupDuration, () => {
      this.executeAttack(npcId, npcSprite, state);
    });
  }

  /**
   * Execute the actual attack damage
   * @param {string} npcId
   * @param {Phaser.GameObjects.Sprite} npcSprite
   * @param {Object} state - NPC hostile state
   */
  executeAttack(npcId, npcSprite, state) {
    if (!window.player || !window.playerHealth) {
      return;
    }

    // Check if player is still in range
    const distance = Phaser.Math.Distance.Between(
      npcSprite.x,
      npcSprite.y,
      window.player.x,
      window.player.y
    );

    if (distance > state.attackRange) {
      console.log(`${npcId} attack missed - player moved out of range`);
      return;
    }

    // Play attack animation (placeholder: walk animation with red tint)
    this.playAttackAnimation(npcSprite);

    // Apply damage to player
    const damage = state.attackDamage;
    window.playerHealth.damage(damage);

    // Visual feedback
    if (window.spriteEffects) {
      window.spriteEffects.flashDamage(window.player);
    }

    // Damage numbers
    if (window.damageNumbers) {
      window.damageNumbers.show(window.player.x, window.player.y - 30, damage, 'damage');
    }

    // Screen effects
    if (window.screenEffects) {
      window.screenEffects.flashDamage();
      window.screenEffects.shakePlayerHit();
    }

    console.log(`${npcId} dealt ${damage} damage to player`);
  }

  /**
   * Play attack animation (placeholder)
   * @param {Phaser.GameObjects.Sprite} npcSprite
   */
  playAttackAnimation(npcSprite) {
    if (!npcSprite) return;

    // Apply red tint
    if (window.spriteEffects) {
      window.spriteEffects.applyAttackTint(npcSprite);
    }

    // Play walk animation if available
    if (npcSprite.anims && !npcSprite.anims.isPlaying) {
      const direction = npcSprite.lastDirection || 'down';
      const animKey = `${npcSprite.npcId}_walk_${direction}`;
      if (npcSprite.anims.exists(animKey)) {
        npcSprite.play(animKey, true);
      }
    }

    // Remove tint after animation
    this.scene.time.delayedCall(COMBAT_CONFIG.player.punchAnimationDuration, () => {
      if (window.spriteEffects) {
        window.spriteEffects.clearAttackTint(npcSprite);
      }
      // Stop animation
      if (npcSprite.anims) {
        npcSprite.anims.stop();
      }
    });
  }

  /**
   * Called from game update loop for NPCs in hostile behavior
   * @param {string} npcId
   * @param {Phaser.GameObjects.Sprite} npcSprite
   */
  update(npcId, npcSprite) {
    // Attempt attack if possible
    this.attemptAttack(npcId, npcSprite);
  }
}
