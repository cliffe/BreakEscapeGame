/**
 * NPCLazyLoader - Loads NPCs per-room on demand
 * Future-proofed for server-based NPC loading
 * Uses in-memory caching only (no persistent storage between sessions)
 */
export default class NPCLazyLoader {
  constructor(npcManager) {
    this.npcManager = npcManager;
    this.loadedRooms = new Set();
    this.storyCache = new Map(); // In-memory cache for current session only
  }

  /**
   * Load all NPCs for a specific room
   * @param {string} roomId - Room identifier
   * @param {object} roomData - Room data containing npcs array
   * @returns {Promise<void>}
   */
  async loadNPCsForRoom(roomId, roomData) {
    // Skip if already loaded or no NPCs
    if (this.loadedRooms.has(roomId) || !roomData?.npcs?.length) {
      return;
    }
    
    console.log(`📦 Loading ${roomData.npcs.length} NPCs for room ${roomId}`);
    
    // Load all Ink stories in parallel (optimization)
    const storyPromises = roomData.npcs
      .filter(npc => npc.storyPath && !this.storyCache.has(npc.storyPath))
      .map(npc => this._loadStory(npc.storyPath));
    
    if (storyPromises.length > 0) {
      console.log(`📖 Loading ${storyPromises.length} Ink stories for room ${roomId}`);
      await Promise.all(storyPromises);
    }
    
    // Register NPCs (synchronous now that stories are cached)
    for (const npcDef of roomData.npcs) {
      npcDef.roomId = roomId;  // Add roomId for compatibility
      
      // registerNPC accepts either registerNPC(id, opts) or registerNPC({ id, ...opts })
      // We use the second form - passing the full object
      this.npcManager.registerNPC(npcDef);
      console.log(`✅ Registered NPC: ${npcDef.id} (${npcDef.npcType}) in room ${roomId}`);
    }
    
    this.loadedRooms.add(roomId);
  }

  /**
   * Load an Ink story file from server (or local file in dev)
   * Caches in memory for current session only
   * @private
   */
  async _loadStory(storyPath) {
    try {
      const response = await fetch(storyPath);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      const story = await response.json();
      
      // Store in memory for this session only
      this.storyCache.set(storyPath, story);
      console.log(`✅ Loaded story: ${storyPath}`);
    } catch (error) {
      console.error(`❌ Failed to load story: ${storyPath}`, error);
      throw error; // Re-throw to allow caller to handle
    }
  }

  /**
   * Get cached story (used by NPCManager if needed)
   * @param {string} storyPath - Path to story file
   * @returns {object|null} Story JSON or null if not cached
   */
  getCachedStory(storyPath) {
    return this.storyCache.get(storyPath) || null;
  }
}

