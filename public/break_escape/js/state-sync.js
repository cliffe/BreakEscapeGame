import { ApiClient } from './api-client.js';

/**
 * Periodic state synchronization with server
 */
export class StateSync {
  constructor(interval = 30000) { // 30 seconds
    this.interval = interval;
    this.timer = null;
  }

  start() {
    this.timer = setInterval(() => this.sync(), this.interval);
    console.log('State sync started (every 30s)');
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async sync() {
    try {
      // Get current game state
      const currentRoom = window.currentRoom?.name;
      const globalVariables = window.gameState?.globalVariables || {};
      // Include notes so observations survive page reloads.
      // Strip any Phaser sprite references — only persist plain data.
      const notes = (window.gameState?.notes || []).map(n => ({
        id: n.id,
        title: n.title,
        text: n.text,
        timestamp: n.timestamp,
        read: n.read,
        important: n.important
      }));

      // Sync to server
      await ApiClient.syncState(currentRoom, globalVariables, notes);
      console.log('✓ State synced to server');
    } catch (error) {
      console.error('State sync failed:', error);
    }
  }
}
