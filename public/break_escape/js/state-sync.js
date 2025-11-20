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

      // Sync to server
      await ApiClient.syncState(currentRoom, globalVariables);
      console.log('✓ State synced to server');
    } catch (error) {
      console.error('State sync failed:', error);
    }
  }
}

// Create global instance
window.stateSync = new StateSync();
