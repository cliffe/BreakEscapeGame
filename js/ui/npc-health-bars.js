/**
 * NPC Health Bars System
 * Displays health bars above hostile NPCs
 */

import { COMBAT_CONFIG } from '../config/combat-config.js';
import { CombatEvents } from '../events/combat-events.js';

export class NPCHealthBars {
  constructor(scene) {
    this.scene = scene;
    this.healthBars = new Map(); // npcId -> { background, bar, npcSprite }

    this.setupEventListeners();

    console.log('✅ NPC health bars initialized');
  }

  setupEventListeners() {
    if (!window.eventDispatcher) {
      console.warn('Event dispatcher not found');
      return;
    }

    // Listen for NPC becoming hostile
    window.eventDispatcher.on(CombatEvents.NPC_BECAME_HOSTILE, (data) => {
      this.createHealthBar(data.npcId);
    });

    // Listen for NPC hostile state changes
    window.eventDispatcher.on(CombatEvents.NPC_HOSTILE_CHANGED, (data) => {
      if (data.isHostile) {
        this.createHealthBar(data.npcId);
      } else {
        this.removeHealthBar(data.npcId);
      }
    });

    // Listen for NPC KO
    window.eventDispatcher.on(CombatEvents.NPC_KO, (data) => {
      this.removeHealthBar(data.npcId);
    });
  }

  createHealthBar(npcId) {
    // Don't create duplicate
    if (this.healthBars.has(npcId)) {
      return;
    }

    // Get NPC sprite
    const npcSprite = this.getNPCSprite(npcId);
    if (!npcSprite) {
      console.warn(`Cannot create health bar for ${npcId}: sprite not found`);
      return;
    }

    const width = COMBAT_CONFIG.ui.healthBarWidth;
    const height = COMBAT_CONFIG.ui.healthBarHeight;
    const offsetY = COMBAT_CONFIG.ui.healthBarOffsetY;

    // Create background (dark gray)
    const background = this.scene.add.rectangle(
      npcSprite.x,
      npcSprite.y + offsetY,
      width,
      height,
      0x333333
    );
    background.setDepth(850);
    background.setStrokeStyle(1, 0x000000);

    // Create health bar (red to green gradient based on HP)
    const bar = this.scene.add.rectangle(
      npcSprite.x,
      npcSprite.y + offsetY,
      width,
      height,
      0x00ff00
    );
    bar.setDepth(851);

    this.healthBars.set(npcId, {
      background,
      bar,
      npcSprite
    });

    // Initial update
    this.updateHealthBar(npcId);
  }

  updateHealthBar(npcId) {
    const healthBar = this.healthBars.get(npcId);
    if (!healthBar) return;

    // Get NPC health state
    if (!window.npcHostileSystem) return;
    const state = window.npcHostileSystem.getState(npcId);
    if (!state) return;

    // Calculate HP percentage
    const hpPercent = state.currentHP / state.maxHP;

    // Update bar width
    const maxWidth = COMBAT_CONFIG.ui.healthBarWidth;
    const currentWidth = maxWidth * hpPercent;
    healthBar.bar.setSize(currentWidth, COMBAT_CONFIG.ui.healthBarHeight);

    // Shift bar position to keep it left-aligned
    const offsetX = (maxWidth - currentWidth) / 2;
    healthBar.bar.setX(healthBar.background.x - offsetX);

    // Update color based on HP (green -> yellow -> red)
    let color;
    if (hpPercent > 0.5) {
      color = 0x00ff00; // Green
    } else if (hpPercent > 0.25) {
      color = 0xffff00; // Yellow
    } else {
      color = 0xff0000; // Red
    }
    healthBar.bar.setFillStyle(color);
  }

  removeHealthBar(npcId) {
    const healthBar = this.healthBars.get(npcId);
    if (!healthBar) return;

    // Destroy graphics
    if (healthBar.background) healthBar.background.destroy();
    if (healthBar.bar) healthBar.bar.destroy();

    this.healthBars.delete(npcId);
  }

  update() {
    // Update positions to follow NPCs
    this.healthBars.forEach((healthBar, npcId) => {
      if (!healthBar.npcSprite || !healthBar.npcSprite.active) {
        // NPC sprite is gone, clean up
        this.removeHealthBar(npcId);
        return;
      }

      const offsetY = COMBAT_CONFIG.ui.healthBarOffsetY;

      // Update positions
      healthBar.background.setPosition(
        healthBar.npcSprite.x,
        healthBar.npcSprite.y + offsetY
      );

      // Update health bar (it will recalculate position)
      this.updateHealthBar(npcId);
    });
  }

  getNPCSprite(npcId) {
    // Try to get sprite from NPC manager
    if (window.npcManager) {
      const npc = window.npcManager.getNPC(npcId);
      if (npc && npc.sprite) {
        return npc.sprite;
      }
    }

    return null;
  }

  destroy() {
    // Remove all health bars
    this.healthBars.forEach((_, npcId) => {
      this.removeHealthBar(npcId);
    });
    this.healthBars.clear();
  }
}
