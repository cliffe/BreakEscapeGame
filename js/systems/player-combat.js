/**
 * Player Combat System
 * Handles player punch attacks on hostile NPCs
 */

import { COMBAT_CONFIG } from '../config/combat-config.js';

export class PlayerCombat {
  constructor(scene) {
    this.scene = scene;
    this.lastPunchTime = 0;
    this.isPunching = false;

    console.log('✅ Player combat system initialized');
  }

  /**
   * Check if player can punch (cooldown check)
   * @returns {boolean}
   */
  canPunch() {
    const now = Date.now();
    const timeSinceLast = now - this.lastPunchTime;
    return timeSinceLast >= COMBAT_CONFIG.player.punchCooldown;
  }

  /**
   * Perform punch attack
   * This is called when player interacts with a hostile NPC
   * Damage applies to ALL NPCs in punch range and facing direction
   */
  punch() {
    if (this.isPunching || !this.canPunch()) {
      console.log('Punch on cooldown');
      return false;
    }

    if (!window.player) {
      console.error('Player not found');
      return false;
    }

    this.isPunching = true;
    this.lastPunchTime = Date.now();

    // Play punch animation (placeholder: walk animation with red tint)
    this.playPunchAnimation();

    // After animation duration, check for hits
    this.scene.time.delayedCall(COMBAT_CONFIG.player.punchAnimationDuration, () => {
      this.checkForHits();
      this.isPunching = false;
    });

    return true;
  }

  /**
   * Play punch animation (placeholder)
   */
  playPunchAnimation() {
    if (!window.player) return;

    // Apply red tint
    if (window.spriteEffects) {
      window.spriteEffects.applyAttackTint(window.player);
    }

    // Play walk animation if not already playing
    if (!window.player.anims.isPlaying) {
      const direction = window.player.lastDirection || 'down';
      window.player.play(`walk_${direction}`, true);
    }

    // Remove tint after animation
    this.scene.time.delayedCall(COMBAT_CONFIG.player.punchAnimationDuration, () => {
      if (window.spriteEffects) {
        window.spriteEffects.clearAttackTint(window.player);
      }
      // Stop animation
      window.player.anims.stop();
    });
  }

  /**
   * Check for hits on NPCs in range and direction
   * Applies AOE damage to all NPCs in punch range AND facing direction
   */
  checkForHits() {
    if (!window.player || !window.npcManager || !window.npcHostileSystem) {
      return;
    }

    const playerX = window.player.x;
    const playerY = window.player.y;
    const punchRange = COMBAT_CONFIG.player.punchRange;
    const punchDamage = COMBAT_CONFIG.player.punchDamage;

    // Get player facing direction
    const direction = window.player.lastDirection || 'down';

    // Get all NPCs
    const npcs = window.npcManager.getAllNPCs();
    let hitCount = 0;

    npcs.forEach(npc => {
      // Only damage hostile NPCs
      if (!window.npcHostileSystem.isNPCHostile(npc.id)) {
        return;
      }

      // Check if NPC is in range
      if (!npc.sprite) return;

      const npcX = npc.sprite.x;
      const npcY = npc.sprite.y;
      const distance = Phaser.Math.Distance.Between(playerX, playerY, npcX, npcY);

      if (distance > punchRange) {
        return; // Too far
      }

      // Check if NPC is in the facing direction
      if (!this.isInDirection(playerX, playerY, npcX, npcY, direction)) {
        return; // Not in facing direction
      }

      // Hit landed!
      this.applyDamage(npc, punchDamage);
      hitCount++;
    });

    if (hitCount > 0) {
      console.log(`Player punch hit ${hitCount} NPC(s)`);
    } else {
      console.log('Player punch missed');
    }
  }

  /**
   * Check if target is in the player's facing direction
   * @param {number} playerX
   * @param {number} playerY
   * @param {number} targetX
   * @param {number} targetY
   * @param {string} direction - 'up', 'down', 'left', 'right'
   * @returns {boolean}
   */
  isInDirection(playerX, playerY, targetX, targetY, direction) {
    const dx = targetX - playerX;
    const dy = targetY - playerY;

    switch (direction) {
      case 'up':
        return dy < 0 && Math.abs(dy) > Math.abs(dx);
      case 'down':
        return dy > 0 && Math.abs(dy) > Math.abs(dx);
      case 'left':
        return dx < 0 && Math.abs(dx) > Math.abs(dy);
      case 'right':
        return dx > 0 && Math.abs(dx) > Math.abs(dy);
      default:
        return false;
    }
  }

  /**
   * Apply damage to NPC
   * @param {Object} npc - NPC object
   * @param {number} damage - Damage amount
   */
  applyDamage(npc, damage) {
    if (!window.npcHostileSystem) return;

    // Apply damage
    window.npcHostileSystem.damageNPC(npc.id, damage);

    // Visual feedback
    if (npc.sprite && window.spriteEffects) {
      window.spriteEffects.flashDamage(npc.sprite);
    }

    // Damage numbers
    if (npc.sprite && window.damageNumbers) {
      window.damageNumbers.show(npc.sprite.x, npc.sprite.y - 30, damage, 'damage');
    }

    // Screen shake (light)
    if (window.screenEffects) {
      window.screenEffects.shakeNPCHit();
    }

    console.log(`Dealt ${damage} damage to ${npc.id}`);
  }
}
