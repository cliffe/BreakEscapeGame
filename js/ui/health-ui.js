/**
 * Health UI System
 * Displays player health as hearts above the inventory
 */

import { COMBAT_CONFIG } from '../config/combat-config.js';
import { CombatEvents } from '../events/combat-events.js';

export class HealthUI {
  constructor() {
    this.container = null;
    this.hearts = [];
    this.currentHP = COMBAT_CONFIG.player.maxHP;
    this.maxHP = COMBAT_CONFIG.player.maxHP;
    this.isVisible = false;

    this.createUI();
    this.setupEventListeners();

    console.log('✅ Health UI initialized');
  }

  createUI() {
    // Create container div
    this.container = document.createElement('div');
    this.container.id = 'health-ui';
    this.container.style.cssText = `
      position: fixed;
      top: 60px;
      left: 50%;
      transform: translateX(-50%);
      display: none;
      z-index: 100;
      padding: 10px;
      background: rgba(0, 0, 0, 0.7);
      border-radius: 8px;
      border: 2px solid #444;
    `;

    // Create hearts container
    const heartsContainer = document.createElement('div');
    heartsContainer.style.cssText = `
      display: flex;
      gap: 5px;
      align-items: center;
    `;

    // Create 5 heart slots
    for (let i = 0; i < COMBAT_CONFIG.ui.maxHearts; i++) {
      const heart = document.createElement('div');
      heart.className = 'heart';
      heart.style.cssText = `
        width: 24px;
        height: 24px;
        font-size: 24px;
        line-height: 24px;
      `;
      heart.textContent = '❤️';
      heartsContainer.appendChild(heart);
      this.hearts.push(heart);
    }

    this.container.appendChild(heartsContainer);
    document.body.appendChild(this.container);

    // Initially hide (only show when damaged)
    this.hide();
  }

  setupEventListeners() {
    if (!window.eventDispatcher) {
      console.warn('Event dispatcher not found, health UI will not update automatically');
      return;
    }

    // Listen for HP changes
    window.eventDispatcher.on(CombatEvents.PLAYER_HP_CHANGED, (data) => {
      this.updateHP(data.hp, data.maxHP);
    });

    // Listen for player KO
    window.eventDispatcher.on(CombatEvents.PLAYER_KO, () => {
      this.show(); // Always show when KO
    });
  }

  updateHP(hp, maxHP) {
    this.currentHP = hp;
    this.maxHP = maxHP;

    // Show UI if damaged
    if (hp < maxHP) {
      this.show();
    } else {
      this.hide();
    }

    // Update heart visuals
    const heartsPerHP = maxHP / COMBAT_CONFIG.ui.maxHearts; // 20 HP per heart (100 / 5)
    const fullHearts = Math.floor(hp / heartsPerHP);
    const remainder = hp % heartsPerHP;
    const halfHeart = remainder >= (heartsPerHP / 2);

    this.hearts.forEach((heart, index) => {
      if (index < fullHearts) {
        // Full heart
        heart.textContent = '❤️';
        heart.style.opacity = '1';
      } else if (index === fullHearts && halfHeart) {
        // Half heart - use broken heart emoji
        heart.textContent = '💔';
        heart.style.opacity = '1';
      } else {
        // Empty heart
        heart.textContent = '🖤';
        heart.style.opacity = '0.3';
      }
    });
  }

  show() {
    if (!this.isVisible) {
      this.container.style.display = 'block';
      this.isVisible = true;
    }
  }

  hide() {
    if (this.isVisible) {
      this.container.style.display = 'none';
      this.isVisible = false;
    }
  }

  destroy() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
  }
}
