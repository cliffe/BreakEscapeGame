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
    if (!window.player) {
      return;
    }

    const playerX = window.player.x;
    const playerY = window.player.y;
    const punchRange = COMBAT_CONFIG.player.punchRange;
    const punchDamage = COMBAT_CONFIG.player.punchDamage;

    // Get player facing direction
    const direction = window.player.lastDirection || 'down';

    // Get all NPCs from rooms
    let hitCount = 0;
    
    if (window.rooms) {
      for (const roomId in window.rooms) {
        const room = window.rooms[roomId];
        if (!room.npcSprites) continue;

        room.npcSprites.forEach(npcSprite => {
          if (!npcSprite || !npcSprite.npcId) return;

          const npcId = npcSprite.npcId;

          // Only damage hostile NPCs
          if (!window.npcHostileSystem.isNPCHostile(npcId)) {
            return;
          }

          // Don't damage NPCs that are already KO
          if (window.npcHostileSystem.isNPCKO(npcId)) {
            return;
          }

          const npcX = npcSprite.x;
          const npcY = npcSprite.y;
          const distance = Phaser.Math.Distance.Between(playerX, playerY, npcX, npcY);

          if (distance > punchRange) {
            return; // Too far
          }

          // Check if NPC is in the facing direction
          if (!this.isInDirection(playerX, playerY, npcX, npcY, direction)) {
            return; // Not in facing direction
          }

          // Hit landed!
          this.applyDamage(npcId, punchDamage);
          hitCount++;
        });
      }
    }

    // Check for chairs in range and direction
    let chairsHit = 0;
    if (window.chairs && window.chairs.length > 0) {
      window.chairs.forEach(chair => {
        // Only kick swivel chairs with physics bodies
        if (!chair.isSwivelChair || !chair.body) {
          return;
        }

        const chairX = chair.x;
        const chairY = chair.y;
        const distance = Phaser.Math.Distance.Between(playerX, playerY, chairX, chairY);

        if (distance > punchRange) {
          return; // Too far
        }

        // Check if chair is in the facing direction
        if (!this.isInDirection(playerX, playerY, chairX, chairY, direction)) {
          return; // Not in facing direction
        }

        // Hit landed! Kick the chair
        this.kickChair(chair);
        chairsHit++;
      });
    }

    if (hitCount > 0) {
      console.log(`Player punch hit ${hitCount} NPC(s)`);
    }
    if (chairsHit > 0) {
      console.log(`Player punch hit ${chairsHit} chair(s)`);
    }
    if (hitCount === 0 && chairsHit === 0) {
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
   * @param {string|Object} npcIdOrNPC - NPC ID string or NPC object
   * @param {number} damage - Damage amount
   */
  applyDamage(npcIdOrNPC, damage) {
    if (!window.npcHostileSystem) return;

    // Get npcId
    let npcId;
    let npcSprite = null;
    
    if (typeof npcIdOrNPC === 'string') {
      npcId = npcIdOrNPC;
      // Find the sprite for this NPC
      if (window.rooms) {
        for (const roomId in window.rooms) {
          const room = window.rooms[roomId];
          if (!room.npcSprites) continue;
          for (const sprite of room.npcSprites) {
            if (sprite.npcId === npcId) {
              npcSprite = sprite;
              break;
            }
          }
          if (npcSprite) break;
        }
      }
    } else {
      npcId = npcIdOrNPC.id;
      npcSprite = npcIdOrNPC.sprite;
    }

    // Apply damage
    window.npcHostileSystem.damageNPC(npcId, damage);

    // Visual feedback
    if (npcSprite && window.spriteEffects) {
      window.spriteEffects.flashDamage(npcSprite);
    }

    // Damage numbers
    if (npcSprite && window.damageNumbers) {
      window.damageNumbers.show(npcSprite.x, npcSprite.y - 30, damage, 'damage');
    }

    // Screen shake (light)
    if (window.screenEffects) {
      window.screenEffects.shakeNPCHit();
    }

    console.log(`Dealt ${damage} damage to ${npcId}`);
  }

  /**
   * Apply kick velocity to chair
   * @param {Phaser.GameObjects.Sprite} chair - Chair sprite
   */
  kickChair(chair) {
    if (!chair || !chair.body || !window.player) {
      return;
    }

    // Calculate direction from player to chair
    const dx = chair.x - window.player.x;
    const dy = chair.y - window.player.y;
    const distance = Math.sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      // Normalize the direction vector
      const dirX = dx / distance;
      const dirY = dy / distance;

      // Apply a strong kick velocity
      const kickForce = 1200; // Pixels per second
      chair.body.setVelocity(dirX * kickForce, dirY * kickForce);

      // Trigger spin direction calculation for visual rotation
      if (window.calculateChairSpinDirection) {
        window.calculateChairSpinDirection(window.player, chair);
      }

      // Visual feedback - flash the chair
      if (window.spriteEffects) {
        window.spriteEffects.flashHit(chair);
      }

      // Light screen shake
      if (window.screenEffects) {
        window.screenEffects.shake(2, 150);
      }

      console.log('CHAIR KICKED', {
        chairName: chair.name,
        velocity: { x: dirX * kickForce, y: dirY * kickForce }
      });
    }
  }
}
