/**
 * Game Over Screen
 * Displayed when player is knocked out (0 HP)
 */

import { CombatEvents } from '../events/combat-events.js';

export class GameOverScreen {
  constructor() {
    this.overlay = null;
    this.isShowing = false;

    this.createUI();
    this.setupEventListeners();

    console.log('✅ Game over screen initialized');
  }

  createUI() {
    // Create overlay
    this.overlay = document.createElement('div');
    this.overlay.id = 'game-over-screen';
    this.overlay.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.9);
      display: none;
      justify-content: center;
      align-items: center;
      z-index: 10000;
      flex-direction: column;
      gap: 30px;
    `;

    // Title
    const title = document.createElement('h1');
    title.textContent = 'KNOCKED OUT';
    title.style.cssText = `
      color: #ff0000;
      font-size: 64px;
      font-family: Arial, sans-serif;
      font-weight: bold;
      margin: 0;
      text-shadow: 4px 4px 8px rgba(0, 0, 0, 0.8);
      animation: pulse 2s infinite;
    `;

    // Message
    const message = document.createElement('p');
    message.textContent = 'You have been defeated';
    message.style.cssText = `
      color: #ffffff;
      font-size: 24px;
      font-family: Arial, sans-serif;
      margin: 0;
    `;

    // Buttons container
    const buttonsContainer = document.createElement('div');
    buttonsContainer.style.cssText = `
      display: flex;
      gap: 20px;
    `;

    // Restart button
    const restartBtn = document.createElement('button');
    restartBtn.textContent = 'Restart';
    restartBtn.style.cssText = `
      padding: 15px 40px;
      font-size: 20px;
      font-family: Arial, sans-serif;
      background: #4CAF50;
      color: white;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      transition: background 0.3s;
    `;
    restartBtn.onmouseover = () => restartBtn.style.background = '#45a049';
    restartBtn.onmouseout = () => restartBtn.style.background = '#4CAF50';
    restartBtn.onclick = () => this.restart();

    // Main menu button
    const menuBtn = document.createElement('button');
    menuBtn.textContent = 'Main Menu';
    menuBtn.style.cssText = `
      padding: 15px 40px;
      font-size: 20px;
      font-family: Arial, sans-serif;
      background: #555;
      color: white;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      transition: background 0.3s;
    `;
    menuBtn.onmouseover = () => menuBtn.style.background = '#666';
    menuBtn.onmouseout = () => menuBtn.style.background = '#555';
    menuBtn.onclick = () => this.mainMenu();

    buttonsContainer.appendChild(restartBtn);
    buttonsContainer.appendChild(menuBtn);

    this.overlay.appendChild(title);
    this.overlay.appendChild(message);
    this.overlay.appendChild(buttonsContainer);

    // Add CSS animation for pulse
    const style = document.createElement('style');
    style.textContent = `
      @keyframes pulse {
        0%, 100% { opacity: 1; transform: scale(1); }
        50% { opacity: 0.8; transform: scale(1.05); }
      }
    `;
    document.head.appendChild(style);

    document.body.appendChild(this.overlay);
  }

  setupEventListeners() {
    if (!window.eventDispatcher) {
      console.warn('Event dispatcher not found');
      return;
    }

    // Listen for player KO
    window.eventDispatcher.on(CombatEvents.PLAYER_KO, () => {
      this.show();
    });
  }

  show() {
    if (!this.isShowing) {
      this.overlay.style.display = 'flex';
      this.isShowing = true;

      // Disable player movement
      if (window.player) {
        window.player.disableMovement = true;
      }
    }
  }

  hide() {
    if (this.isShowing) {
      this.overlay.style.display = 'none';
      this.isShowing = false;
    }
  }

  restart() {
    // Reset player health
    if (window.playerHealth) {
      window.playerHealth.reset();
    }

    // Re-enable player movement
    if (window.player) {
      window.player.disableMovement = false;
    }

    // Hide game over screen
    this.hide();

    // Reload the page to restart
    window.location.reload();
  }

  mainMenu() {
    // Navigate to scenario select or main menu
    window.location.href = 'scenario_select.html';
  }

  destroy() {
    if (this.overlay && this.overlay.parentNode) {
      this.overlay.parentNode.removeChild(this.overlay);
    }
  }
}
