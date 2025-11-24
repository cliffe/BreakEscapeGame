// NPCManager with event → knot auto-mapping and conversation history
// OPTIMIZED: InkEngine caching, event listener cleanup, debug logging
// default export NPCManager
import { isInLineOfSight, drawLOSCone, clearLOSCone, getNPCFacingDirection } from './npc-los.js';

export default class NPCManager {
  constructor(eventDispatcher, barkSystem = null) {
    this.eventDispatcher = eventDispatcher;
    this.barkSystem = barkSystem;
    this.npcs = new Map();
    this.eventListeners = new Map(); // Track registered listeners for cleanup
    this.triggeredEvents = new Map(); // Track which events have been triggered per NPC
    this.conversationHistory = new Map(); // Track conversation history per NPC: { npcId: [ {type, text, timestamp, choiceText} ] }
    this.timedMessages = []; // Scheduled messages: { npcId, text, triggerTime, delivered, phoneId }
    this.timedConversations = []; // Scheduled conversations: { npcId, targetKnot, triggerTime, delivered }
    this.gameStartTime = Date.now(); // Track when game started for timed messages
    this.timerInterval = null; // Timer for checking timed messages
    
    // OPTIMIZATION: Cache InkEngine instances and fetched stories
    this.inkEngineCache = new Map(); // { npcId: inkEngine }
    this.storyCache = new Map(); // { storyPath: storyJson }
    
    // LOS Visualization
    this.losVisualizations = new Map(); // { npcId: graphicsObject }
    this.losVisualizationEnabled = false; // Toggle LOS cone rendering
    
    // OPTIMIZATION: Debug mode (set via window.NPC_DEBUG = true)
    this.debug = false;
  }

  /**
   * OPTIMIZATION: Log helper with debug mode
   */
  _log(level, message, data = null) {
    if (!this.debug && level !== 'error' && level !== 'warn') return;
    
    const prefix = {
      error: '❌',
      warn: '⚠️',
      info: 'ℹ️',
      debug: '🔍'
    }[level] || '📍';
    
    if (data) {
      console[level](`${prefix} ${message}`, data);
    } else {
      console[level](`${prefix} ${message}`);
    }
  }

  // registerNPC(id, opts) or registerNPC({ id, ...opts })
  // opts: { 
  //   displayName, storyPath, avatar, currentKnot, 
  //   phoneId: 'player_phone' | 'office_phone' | null,  // Which phone this NPC uses
  //   npcType: 'phone' | 'sprite',  // Text-only phone NPC or in-world sprite
  //   eventMappings: { 'event_pattern': { knot, bark, once, cooldown } } 
  // }
  registerNPC(id, opts = {}) {
    // Accept either registerNPC(id, opts) or registerNPC({ id, ...opts })
    let realId = id;
    let realOpts = opts;
    if (typeof id === 'object' && id !== null) {
      realOpts = id;
      realId = id.id;
    }
    if (!realId) throw new Error('registerNPC requires an id');
    
    const entry = Object.assign({ 
      id: realId, 
      displayName: realId, 
      metadata: {},
      eventMappings: {},
      phoneId: 'player_phone',  // Default to player's phone
      npcType: 'phone',  // Default to phone-based NPC
      itemsHeld: []  // Initialize empty inventory for NPC item giving
    }, realOpts);
    
    this.npcs.set(realId, entry);
    
    // Register in global character registry for speaker resolution
    if (window.characterRegistry) {
      window.characterRegistry.registerNPC(realId, entry);
    }
    
    // Initialize conversation history for this NPC
    if (!this.conversationHistory.has(realId)) {
      this.conversationHistory.set(realId, []);
    }
    
    // Set up event listeners for auto-mapping
    if (entry.eventMappings && this.eventDispatcher) {
      this._setupEventMappings(realId, entry.eventMappings);
    }
    
    // Schedule timed messages if any are defined
    if (entry.timedMessages && Array.isArray(entry.timedMessages)) {
      entry.timedMessages.forEach(msg => {
        this.scheduleTimedMessage({
          npcId: realId,
          text: msg.message,
          delay: msg.delay,
          phoneId: entry.phoneId
        });
      });
      console.log(`[NPCManager] Scheduled ${entry.timedMessages.length} timed messages for ${realId}`);
    }
    
    // Schedule timed conversations if any are defined
    if (entry.timedConversation) {
      this.scheduleTimedConversation({
        npcId: realId,
        targetKnot: entry.timedConversation.targetKnot,
        delay: entry.timedConversation.delay,
        background: entry.timedConversation.background // Optional background image
      });
      console.log(`[NPCManager] Scheduled timed conversation for ${realId} to knot: ${entry.timedConversation.targetKnot}`);
    }
    
    return entry;
  }

  getNPC(id) {
    return this.npcs.get(id) || null;
  }

  /**
   * Check if any NPC in a room should trigger person-chat instead of lockpicking
   * Considers NPC line-of-sight and facing direction
   * Returns the NPC if one should handle lockpick_used_in_view with person-chat
   * Otherwise returns null
   */
  shouldInterruptLockpickingWithPersonChat(roomId, playerPosition = null) {
    if (!roomId) return null;
    
    console.log(`👁️ [LOS CHECK] shouldInterruptLockpickingWithPersonChat: roomId="${roomId}", playerPos=${playerPosition ? `(${playerPosition.x.toFixed(0)}, ${playerPosition.y.toFixed(0)})` : 'null'}`);
    
    for (const npc of this.npcs.values()) {
      // NPC must be in the specified room and be a 'person' type NPC
      if (npc.roomId !== roomId || npc.npcType !== 'person') continue;
      
      console.log(`👁️ [LOS CHECK] Checking NPC: "${npc.id}" (room: ${npc.roomId}, type: ${npc.npcType})`);
      
      // Check if NPC has lockpick_used_in_view event mapping with person-chat
      if (npc.eventMappings && Array.isArray(npc.eventMappings)) {
        const lockpickMapping = npc.eventMappings.find(mapping => 
          mapping.eventPattern === 'lockpick_used_in_view' && 
          mapping.conversationMode === 'person-chat'
        );
        
        if (!lockpickMapping) {
          console.log(`👁️ [LOS CHECK]   ✗ NPC has no lockpick_used_in_view mapping`);
          continue;
        }
        
        console.log(`👁️ [LOS CHECK]   ✓ NPC has lockpick_used_in_view→person-chat mapping`);
        
        // Check LOS configuration
        const losConfig = npc.los || {
          enabled: true,
          range: 300,    // Default detection range
          angle: 120     // Default 120° field of view
        };
        
        // If player position provided, check if player is in LOS
        if (playerPosition) {
          // Get detailed information for debugging
          // Try to get sprite from npc._sprite (how it's stored), then npc.sprite, then npc position
          const sprite = npc._sprite || npc.sprite;
          const npcPos = (sprite && typeof sprite.getCenter === 'function') ? 
            sprite.getCenter() : 
            { x: npc.x ?? 0, y: npc.y ?? 0 };
          
          console.log(`👁️ [LOS CHECK]   npcPos: ${npcPos ? `(${npcPos.x}, ${npcPos.y})` : 'NULL'}, losConfig: range=${losConfig.range}, angle=${losConfig.angle}`);
          
          // Ensure npcPos is valid before using
          if (npcPos && npcPos.x !== undefined && npcPos.y !== undefined && 
              !Number.isNaN(npcPos.x) && !Number.isNaN(npcPos.y)) {
            const distance = Math.sqrt(
              Math.pow(playerPosition.x - npcPos.x, 2) + 
              Math.pow(playerPosition.y - npcPos.y, 2)
            );
            
            // Calculate angle to player
            const angleRad = Math.atan2(playerPosition.y - npcPos.y, playerPosition.x - npcPos.x);
            const angleToPlayer = (angleRad * 180 / Math.PI + 360) % 360;
            
            // Get NPC facing direction for debugging
            const npcFacing = getNPCFacingDirection(npc);
            
            const inLOS = isInLineOfSight(npc, playerPosition, losConfig);
            console.log(`👁️ [LOS CHECK]   NPC Facing: ${npcFacing.toFixed(1)}°, Distance: ${distance.toFixed(1)}px (range: ${losConfig.range}), Angle: ${angleToPlayer.toFixed(1)}° (FOV: ${losConfig.angle}°), LOS: ${inLOS}`);
            
            if (!inLOS) {
              console.log(
                `👁️ NPC "${npc.id}" CANNOT see player\n` +
                `   Position: NPC(${npcPos.x.toFixed(0)}, ${npcPos.y.toFixed(0)}) → Player(${playerPosition.x.toFixed(0)}, ${playerPosition.y.toFixed(0)})\n` +
                `   Distance: ${distance.toFixed(1)}px (range: ${losConfig.range}px) ${distance > losConfig.range ? '❌ TOO FAR' : '✅ in range'}\n` +
                `   Angle to Player: ${angleToPlayer.toFixed(1)}° (FOV: ${losConfig.angle}°)`
              );
              continue;
            }
          } else {
            console.log(`👁️ [LOS CHECK]   Position invalid, checking LOS anyway...`);
            if (!isInLineOfSight(npc, playerPosition, losConfig)) {
              // Position unavailable but still check LOS detection
              continue;
            }
          }
        }
        
        console.log(`�🚫 INTERRUPTING LOCKPICKING: NPC "${npc.id}" in room "${roomId}" can see player and has person-chat mapped to lockpick event`);
        return npc;
      }
    }
    
    return null;
  }

  // Set bark system (can be set after construction)
  setBarkSystem(barkSystem) {
    this.barkSystem = barkSystem;
  }

  // Add a message to conversation history (internal method)
  addMessageToHistory(npcId, type, text) {
    if (!this.conversationHistory.has(npcId)) {
      this.conversationHistory.set(npcId, []);
    }
    this.conversationHistory.get(npcId).push({
      type,
      text,
      timestamp: Date.now(),
      choiceText: null
    });
    this._log('debug', `Added ${type} message to ${npcId} history:`, text);
  }

  // Public API: Add a message with full metadata (used by external systems)
  addMessage(npcId, type, text, metadata = {}) {
    if (!this.conversationHistory.has(npcId)) {
      this.conversationHistory.set(npcId, []);
    }
    this.conversationHistory.get(npcId).push({
      type,
      text,
      timestamp: Date.now(),
      read: type === 'player', // Player messages are automatically marked as read
      ...metadata
    });
    this._log('debug', `Added ${type} message to ${npcId}:`, text);
  }

  // Get conversation history for an NPC
  getConversationHistory(npcId) {
    return this.conversationHistory.get(npcId) || [];
  }

  // Clear conversation history for an NPC
  clearConversationHistory(npcId) {
    this.conversationHistory.set(npcId, []);
  }

  // Get all NPCs for a specific phone
  getNPCsByPhone(phoneId) {
    return Array.from(this.npcs.values()).filter(npc => npc.phoneId === phoneId);
  }

  // Get total unread message count for a phone
  getTotalUnreadCount(phoneId, allowedNpcIds = null) {
    let npcs = this.getNPCsByPhone(phoneId);
    
    // Filter to only allowed NPCs if specified
    if (allowedNpcIds && allowedNpcIds.length > 0) {
      npcs = npcs.filter(npc => allowedNpcIds.includes(npc.id));
    }
    
    let totalUnread = 0;
    
    for (const npc of npcs) {
      const history = this.getConversationHistory(npc.id);
      const unreadCount = history.filter(msg => !msg.read && msg.type === 'npc').length;
      totalUnread += unreadCount;
    }
    
    return totalUnread;
  }

  // Set up event listeners for an NPC's event mappings
  _setupEventMappings(npcId, eventMappings) {
    if (!this.eventDispatcher) return;
    
    console.log(`📋 Setting up event mappings for ${npcId}:`, eventMappings);
    
    // Handle both array format (from JSON) and object format
    const mappingsArray = Array.isArray(eventMappings) 
      ? eventMappings 
      : Object.entries(eventMappings).map(([pattern, config]) => ({
          eventPattern: pattern,
          ...(typeof config === 'string' ? { targetKnot: config } : config)
        }));
    
    for (const mapping of mappingsArray) {
      const eventPattern = mapping.eventPattern;
      const config = {
        knot: mapping.targetKnot || mapping.knot,
        bark: mapping.bark,
        once: mapping.onceOnly || mapping.once,
        cooldown: mapping.cooldown,
        condition: mapping.condition,
        maxTriggers: mapping.maxTriggers,  // Add max trigger limit
        conversationMode: mapping.conversationMode  // Add conversation mode (e.g., 'person-chat')
      };
      
      console.log(`  📌 Registering listener for event: ${eventPattern} → ${config.knot}`);
      
      const listener = (eventData) => {
        this._handleEventMapping(npcId, eventPattern, config, eventData);
      };
      
      // Register listener with event dispatcher
      this.eventDispatcher.on(eventPattern, listener);
      
      // Track listener for cleanup
      if (!this.eventListeners.has(npcId)) {
        this.eventListeners.set(npcId, []);
      }
      this.eventListeners.get(npcId).push({ pattern: eventPattern, listener });
    }
    
    console.log(`✅ Registered ${mappingsArray.length} event mappings for ${npcId}`);
  }

  // Handle when a mapped event fires
  _handleEventMapping(npcId, eventPattern, config, eventData) {
    console.log(`🎯 Event triggered: ${eventPattern} for NPC: ${npcId}`, eventData);
    
    const npc = this.getNPC(npcId);
    if (!npc) {
      console.warn(`⚠️ NPC ${npcId} not found`);
      return;
    }
    
    // Check if event should be handled
    const eventKey = `${npcId}:${eventPattern}`;
    const triggered = this.triggeredEvents.get(eventKey) || { count: 0, lastTime: 0 };
    
    // Check if this is a once-only event that's already triggered
    if (config.once && triggered.count > 0) {
      console.log(`⏭️ Skipping once-only event ${eventPattern} (already triggered)`);
      return;
    }
    
    // Check if max triggers reached
    if (config.maxTriggers && triggered.count >= config.maxTriggers) {
      console.log(`🚫 Event ${eventPattern} has reached max triggers (${config.maxTriggers})`);
      return;
    }
    
    // Check cooldown (in milliseconds, default 5000ms = 5s)
    // IMPORTANT: Use ?? instead of || to properly handle cooldown: 0
    const cooldown = config.cooldown !== undefined && config.cooldown !== null ? config.cooldown : 5000;
    const now = Date.now();
    if (triggered.lastTime && (now - triggered.lastTime < cooldown)) {
      const remainingMs = cooldown - (now - triggered.lastTime);
      console.log(`⏸️ Event ${eventPattern} on cooldown (${remainingMs}ms remaining)`);
      return;
    }
    
    // Check condition if provided (can be string or function)
    if (config.condition) {
      let conditionMet = false;
      
      if (typeof config.condition === 'function') {
        conditionMet = config.condition(eventData, npc);
      } else if (typeof config.condition === 'string') {
        // Evaluate condition string as JavaScript
        try {
          const data = eventData; // Make 'data' available in eval scope
          conditionMet = eval(config.condition);
        } catch (error) {
          console.error(`❌ Error evaluating condition: ${config.condition}`, error);
          return;
        }
      }
      
      if (!conditionMet) {
        console.log(`🚫 Event ${eventPattern} condition not met:`, config.condition);
        return;
      }
    }
    
    console.log(`✅ Event ${eventPattern} conditions passed, triggering NPC reaction`);
    
    // Update triggered tracking
    triggered.count++;
    triggered.lastTime = now;
    this.triggeredEvents.set(eventKey, triggered);
    
    // Update NPC's current knot if specified
    if (config.knot) {
      npc.currentKnot = config.knot;
      console.log(`📍 Updated ${npcId} current knot to: ${config.knot}`);
    }
    
    // Debug: Log the full config to see what we're working with
    console.log(`🔍 Event config for ${eventPattern}:`, {
      conversationMode: config.conversationMode,
      npcType: npc.npcType,
      knot: config.knot,
      fullConfig: config
    });
    
    // Check if this event should trigger a full person-chat conversation
    // instead of just a bark (indicated by conversationMode: 'person-chat')
    if (config.conversationMode === 'person-chat' && npc.npcType === 'person') {
      console.log(`👤 Handling person-chat for event on NPC ${npcId}`);
      
      // CHECK: Is a conversation already active with this NPC?
      const currentConvNPCId = window.currentConversationNPCId;
      const activeMinigame = window.MinigameFramework?.currentMinigame;
      const isPersonChatActive = activeMinigame?.constructor?.name === 'PersonChatMinigame';
      const isConversationActive = currentConvNPCId === npcId;
      
      console.log(`🔍 Event jump check:`, {
        targetNpcId: npcId,
        currentConvNPCId: currentConvNPCId,
        isConversationActive: isConversationActive,
        activeMinigame: activeMinigame?.constructor?.name || 'none',
        isPersonChatActive: isPersonChatActive,
        hasJumpToKnot: typeof activeMinigame?.jumpToKnot === 'function'
      });
      
      if (isConversationActive && isPersonChatActive) {
        // JUMP TO KNOT in the active conversation instead of starting a new one
        console.log(`⚡ Active conversation detected with ${npcId}, attempting jump to knot: ${config.knot}`);
        
        if (typeof activeMinigame.jumpToKnot === 'function') {
          try {
            const jumpSuccess = activeMinigame.jumpToKnot(config.knot);
            if (jumpSuccess) {
              console.log(`✅ Successfully jumped to knot ${config.knot} in active conversation`);
              return;  // Success - exit early
            } else {
              console.warn(`⚠️ Failed to jump to knot, falling back to new conversation`);
            }
          } catch (error) {
            console.error(`❌ Error during jumpToKnot: ${error.message}`);
          }
        } else {
          console.warn(`⚠️ jumpToKnot method not available on minigame`);
        }
      } else {
        console.log(`ℹ️ Not jumping: isConversationActive=${isConversationActive}, isPersonChatActive=${isPersonChatActive}`);
      }
      
      // Not in an active conversation OR jump failed - start a new person-chat minigame
      console.log(`👤 Starting new person-chat conversation for NPC ${npcId}`);
      
      // Close any currently running minigame (like lockpicking) first
      if (window.MinigameFramework && window.MinigameFramework.currentMinigame) {
        console.log(`🛑 Closing currently running minigame before starting person-chat`);
        window.MinigameFramework.endMinigame(false, null);
        console.log(`✅ Closed current minigame`);
      }
      
      // Start the person-chat minigame
      if (window.MinigameFramework) {
        console.log(`✅ Starting person-chat minigame for ${npcId}`);
        window.MinigameFramework.startMinigame('person-chat', null, {
          npcId: npc.id,
          startKnot: config.knot || npc.currentKnot,
          scenario: window.gameScenario
        });
        console.log(`[NPCManager] Event '${eventPattern}' triggered for NPC '${npcId}' → person-chat conversation`);
        return;  // Exit early - person-chat is handling it
      } else {
        console.warn(`⚠️ MinigameFramework not available for person-chat`);
      }
    }
    // If bark text is provided, show it directly
    if (this.barkSystem && (config.bark || config.message)) {
      const barkText = config.bark || config.message;
      
      // Add bark message to conversation history (marked as bark)
      this.addMessage(npcId, 'npc', barkText, { 
        eventPattern,
        knot: config.knot,
        isBark: true  // Flag this as a bark, not full conversation
      });
      
      console.log(`💬 Showing bark with direct message: ${barkText}`);
      
      this.barkSystem.showBark({
        npcId: npc.id,
        npcName: npc.displayName,
        message: barkText,
        avatar: npc.avatar,
        inkStoryPath: npc.storyPath,
        startKnot: config.knot || npc.currentKnot,
        phoneId: npc.phoneId
      });
    } 
    // Otherwise, if we have a knot, load the Ink story and get the text
    else if (this.barkSystem && config.knot && npc.storyPath) {
      console.log(`📖 Loading Ink story from knot: ${config.knot}`);
      
      // Load the Ink story and navigate to the knot
      this._showBarkFromKnot(npcId, npc, config.knot, eventPattern);
    }
    
    console.log(`[NPCManager] Event '${eventPattern}' triggered for NPC '${npcId}' → knot '${config.knot}'`);
  }
  
  // Load Ink story, navigate to knot, and show the text as a bark
  async _showBarkFromKnot(npcId, npc, knotName, eventPattern) {
    try {
      // OPTIMIZATION: Fetch story from cache or network
      let storyJson = this.storyCache.get(npc.storyPath);
      if (!storyJson) {
        // Use Rails API endpoint instead of direct file fetch
        const gameId = window.breakEscapeConfig?.gameId;
        const endpoint = gameId 
          ? `/break_escape/games/${gameId}/ink?npc=${encodeURIComponent(npcId)}`
          : npc.storyPath;  // Fallback to storyPath if no gameId
        
        const response = await fetch(endpoint);
        if (!response.ok) {
          throw new Error(`Failed to load story: ${response.statusText}`);
        }
        storyJson = await response.json();
        // Cache for future use
        this.storyCache.set(npc.storyPath, storyJson);
      }
      
      // OPTIMIZATION: Reuse cached InkEngine or create new one
      let inkEngine = this.inkEngineCache.get(npcId);
      if (!inkEngine) {
        const { default: InkEngine } = await import('./ink/ink-engine.js?v=1');
        inkEngine = new InkEngine(npcId);
        inkEngine.loadStory(storyJson);
        this.inkEngineCache.set(npcId, inkEngine);
      }
      
      // Navigate to the knot
      inkEngine.goToKnot(knotName);
      
      // Get the text from the knot
      const result = inkEngine.continue();
      
      if (result.text) {
        
        // Add to conversation history (marked as bark)
        this.addMessage(npcId, 'npc', result.text, { 
          eventPattern,
          knot: knotName,
          isBark: true  // Flag this as a bark, not full conversation
        });
        
        // Show the bark
        this.barkSystem.showBark({
          npcId: npc.id,
          npcName: npc.displayName,
          message: result.text,
          avatar: npc.avatar,
          inkStoryPath: npc.storyPath,
          startKnot: knotName,
          phoneId: npc.phoneId
        });
      } else {
        console.warn(`⚠️ No text found in knot: ${knotName}`);
      }
    } catch (error) {
      console.error(`❌ Error loading bark from knot ${knotName}:`, error);
    }
  }

  // Helper to emit events about an NPC
  emit(npcId, type, payload = {}) {
    const ev = Object.assign({ npcId, type }, payload);
    this.eventDispatcher && this.eventDispatcher.emit(type, ev);
  }

  // Get all NPCs
  getAllNPCs() {
    return Array.from(this.npcs.values());
  }

  // Check if an event has been triggered for an NPC
  hasTriggered(npcId, eventPattern) {
    const eventKey = `${npcId}:${eventPattern}`;
    const triggered = this.triggeredEvents.get(eventKey);
    return triggered ? triggered.count > 0 : false;
  }

  // Schedule a timed message to be delivered after a delay
  // opts: { npcId, text, triggerTime (ms from game start) OR delay (ms from now), phoneId }
  scheduleTimedMessage(opts) {
    const { npcId, text, triggerTime, delay, phoneId } = opts;
    
    if (!npcId || !text) {
      console.error('[NPCManager] scheduleTimedMessage requires npcId and text');
      return;
    }
    
    // Use triggerTime if provided, otherwise use delay (defaults to 0)
    const actualTriggerTime = triggerTime !== undefined ? triggerTime : (delay || 0);
    
    this.timedMessages.push({
      npcId,
      text,
      triggerTime: actualTriggerTime, // milliseconds from game start
      phoneId: phoneId || 'player_phone',
      delivered: false
    });
    
    console.log(`[NPCManager] Scheduled timed message from ${npcId} at ${actualTriggerTime}ms:`, text);
  }

  // Schedule a timed conversation to start after a delay
  // Similar to timedMessages but for person NPCs (opens person-chat minigame)
  // 
  // opts: { npcId, targetKnot, triggerTime (ms from game start) OR delay (ms from now) }
  // 
  // Example: After 3 seconds, automatically open a conversation with test_npc_back at the "group_meeting" knot
  //   scheduleTimedConversation({
  //     npcId: 'test_npc_back',
  //     targetKnot: 'group_meeting',
  //     delay: 3000
  //   })
  //
  // USAGE IN SCENARIO JSON:
  //   {
  //     "id": "test_npc_back",
  //     "displayName": "Back NPC",
  //     "npcType": "person",
  //     "storyPath": "scenarios/ink/test2.json",
  //     "currentKnot": "hub",
  //     "timedConversation": {
  //       "delay": 3000,          // 3 seconds
  //       "targetKnot": "group_meeting"
  //     }
  //   }
  scheduleTimedConversation(opts) {
    const { npcId, targetKnot, triggerTime, delay, background } = opts;
    
    if (!npcId || !targetKnot) {
      console.error('[NPCManager] scheduleTimedConversation requires npcId and targetKnot');
      return;
    }
    
    // Use triggerTime if provided, otherwise use delay (defaults to 0)
    const actualTriggerTime = triggerTime !== undefined ? triggerTime : (delay || 0);
    
    this.timedConversations.push({
      npcId,
      targetKnot,
      triggerTime: actualTriggerTime, // milliseconds from game start
      background: background, // Optional background image path
      delivered: false
    });
    
    console.log(`[NPCManager] Scheduled timed conversation from ${npcId} at ${actualTriggerTime}ms to knot: ${targetKnot}`);
  }

  // Start checking for timed messages (call this when game starts)
  startTimedMessages() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
    
    this.gameStartTime = Date.now();
    
    // Check every second for messages that need to be delivered
    this.timerInterval = setInterval(() => {
      this._checkTimedMessages();
    }, 1000);
    
    console.log('[NPCManager] Started timed messages system');
  }

  // Stop checking for timed messages (cleanup)
  stopTimedMessages() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
  }

  // Check if any timed messages need to be delivered
  _checkTimedMessages() {
    const now = Date.now();
    const elapsed = now - this.gameStartTime;
    
    for (const message of this.timedMessages) {
      if (!message.delivered && elapsed >= message.triggerTime) {
        this._deliverTimedMessage(message);
        message.delivered = true;
      }
    }
    
    // Also check timed conversations
    for (const conversation of this.timedConversations) {
      if (!conversation.delivered && elapsed >= conversation.triggerTime) {
        this._deliverTimedConversation(conversation);
        conversation.delivered = true;
      }
    }
  }

  // Deliver a timed message (add to history and show bark)
  _deliverTimedMessage(message) {
    const npc = this.getNPC(message.npcId);
    if (!npc) {
      console.warn(`[NPCManager] Cannot deliver timed message: NPC ${message.npcId} not found`);
      return;
    }
    
    // Add message to conversation history
    this.addMessage(message.npcId, 'npc', message.text, { 
      timed: true,
      phoneId: message.phoneId
    });
    
    // Update phone badge if updatePhoneBadge function exists
    if (window.updatePhoneBadge && message.phoneId) {
      window.updatePhoneBadge(message.phoneId);
    }
    
    // Show bark notification
    if (this.barkSystem) {
      this.barkSystem.showBark({
        npcId: npc.id,
        npcName: npc.displayName,
        message: message.text,
        avatar: npc.avatar,
        inkStoryPath: npc.storyPath,
        startKnot: npc.currentKnot,
        phoneId: message.phoneId
      });
    }
    
    console.log(`[NPCManager] Delivered timed message from ${message.npcId}:`, message.text);
  }

  // Deliver a timed conversation (start person-chat minigame at specified knot)
  _deliverTimedConversation(conversation) {
    const npc = this.getNPC(conversation.npcId);
    if (!npc) {
      console.warn(`[NPCManager] Cannot deliver timed conversation: NPC ${conversation.npcId} not found`);
      return;
    }
    
    // Update NPC's current knot to the target knot
    npc.currentKnot = conversation.targetKnot;
    
    // Check if MinigameFramework is available to start the person-chat minigame
    if (window.MinigameFramework && typeof window.MinigameFramework.startMinigame === 'function') {
      console.log(`🎭 Starting timed conversation for ${conversation.npcId} at knot: ${conversation.targetKnot}`);
      
      window.MinigameFramework.startMinigame('person-chat', null, {
        npcId: conversation.npcId,
        title: npc.displayName || conversation.npcId,
        background: conversation.background // Optional background image path
      });
    } else {
      console.warn(`[NPCManager] MinigameFramework not available to start person-chat for timed conversation`);
    }
    
    console.log(`[NPCManager] Delivered timed conversation from ${conversation.npcId} to knot: ${conversation.targetKnot}`);
  }

  // Load timed messages from scenario data
  // timedMessages: [ { npcId, text, triggerTime, phoneId } ]
  loadTimedMessages(timedMessages) {
    if (!Array.isArray(timedMessages)) return;
    
    timedMessages.forEach(msg => {
      this.scheduleTimedMessage(msg);
    });
    
    console.log(`[NPCManager] Loaded ${timedMessages.length} timed messages`);
  }

  /**
   * Clear conversation history for an NPC (useful for testing/debugging)
   * @param {string} npcId - The NPC to reset
   */
  clearNPCHistory(npcId) {
    if (!npcId) {
      console.warn('[NPCManager] clearNPCHistory requires npcId');
      return;
    }
    
    // Clear conversation history
    if (this.conversationHistory.has(npcId)) {
      this.conversationHistory.set(npcId, []);
      console.log(`[NPCManager] Cleared conversation history for ${npcId}`);
    }
    
    // Clear story state from localStorage
    const storyStateKey = `npc_story_state_${npcId}`;
    if (localStorage.getItem(storyStateKey)) {
      localStorage.removeItem(storyStateKey);
      console.log(`[NPCManager] Cleared saved story state for ${npcId}`);
    }
    
    console.log(`✅ Reset NPC: ${npcId}. Start a new conversation to see fresh state.`);
  }

  /**
   * OPTIMIZATION: Clean up event listeners for an NPC
   * Call this when removing an NPC or changing scenes
   */
  unregisterNPC(npcId) {
    if (!this.eventDispatcher) return;

    // Remove all event listeners for this NPC
    const listeners = this.eventListeners.get(npcId);
    if (listeners) {
      for (const { pattern, listener } of listeners) {
        this.eventDispatcher.off(pattern, listener);
      }
      this.eventListeners.delete(npcId);
      console.log(`[NPCManager] Cleaned up ${listeners.length} event listeners for ${npcId}`);
    }

    // Clear cached InkEngine
    if (this.inkEngineCache.has(npcId)) {
      this.inkEngineCache.delete(npcId);
      console.log(`[NPCManager] Cleared cached InkEngine for ${npcId}`);
    }

    // Remove NPC from registry
    this.npcs.delete(npcId);
    this.conversationHistory.delete(npcId);
    this.triggeredEvents.delete(npcId);

    console.log(`[NPCManager] Unregistered NPC: ${npcId}`);
  }

  /**
   * OPTIMIZATION: Clean up all NPCs (call on scene change)
   */
  unregisterAllNPCs() {
    const npcIds = Array.from(this.npcs.keys());
    for (const npcId of npcIds) {
      this.unregisterNPC(npcId);
    }
    console.log(`[NPCManager] Cleaned up all NPCs (${npcIds.length} total)`);
  }

  /**
   * Get or create Ink engine for an NPC
   * Fetches story from NPC data and initializes InkEngine
   * @param {string} npcId - NPC ID
   * @returns {Promise<InkEngine|null>} Ink engine instance or null
   */
  async getInkEngine(npcId) {
    try {
      const npc = this.getNPC(npcId);
      if (!npc) {
        console.error(`❌ NPC not found: ${npcId}`);
        return null;
      }

      // Check if already cached
      if (this.inkEngineCache.has(npcId)) {
        console.log(`📖 Using cached InkEngine for ${npcId}`);
        return this.inkEngineCache.get(npcId);
      }

      // Need to load story
      if (!npc.storyPath) {
        console.error(`❌ NPC ${npcId} has no storyPath`);
        return null;
      }

      // Fetch story from cache or network
      let storyJson = this.storyCache.get(npc.storyPath);
      if (!storyJson) {
        // Use Rails API endpoint instead of direct file fetch
        const gameId = window.breakEscapeConfig?.gameId;
        const endpoint = gameId 
          ? `/break_escape/games/${gameId}/ink?npc=${encodeURIComponent(npcId)}`
          : npc.storyPath;  // Fallback to storyPath if no gameId
        
        console.log(`📚 Fetching story from ${endpoint}`);
        const response = await fetch(endpoint);
        if (!response.ok) {
          throw new Error(`Failed to load story: ${response.statusText}`);
        }
        storyJson = await response.json();
        this.storyCache.set(npc.storyPath, storyJson);
      }

      // Create and cache InkEngine
      const { default: InkEngine } = await import('./ink/ink-engine.js?v=1');
      const inkEngine = new InkEngine(npcId);
      inkEngine.loadStory(storyJson);

      // Import npcConversationStateManager for global variable sync
      const { default: npcConversationStateManager } = await import('./npc-conversation-state.js?v=2');

      // Discover any global_* variables not in scenario JSON
      npcConversationStateManager.discoverGlobalVariables(inkEngine.story);

      // Sync global variables from window.gameState to story
      npcConversationStateManager.syncGlobalVariablesToStory(inkEngine.story);

      // Observe changes to sync back to window.gameState
      npcConversationStateManager.observeGlobalVariableChanges(inkEngine.story, npcId);

      this.inkEngineCache.set(npcId, inkEngine);

      console.log(`✅ InkEngine initialized for ${npcId}`);
      return inkEngine;
    } catch (error) {
      console.error(`❌ Error getting InkEngine for ${npcId}:`, error);
      return null;
    }
  }

  /**
   * OPTIMIZATION: Destroy InkEngine cache for a specific story
   * Useful when memory is tight or story changed
   */
  clearStoryCache(storyPath) {
    this.storyCache.delete(storyPath);
  }

  /**
   * OPTIMIZATION: Clear all caches
   */
  clearAllCaches() {
    this.inkEngineCache.clear();
    this.storyCache.clear();
    console.log(`[NPCManager] Cleared all caches`);
  }

  /**
   * Enable or disable LOS cone visualization for debugging
   * @param {boolean} enable - Whether to show LOS cones
   * @param {Phaser.Scene} scene - Phaser scene for drawing
   */
  setLOSVisualization(enable, scene = null) {
    this.losVisualizationEnabled = enable;
    
    if (enable && scene) {
      console.log('👁️ Enabling LOS visualization');
      this._updateLOSVisualizations(scene);
    } else if (!enable) {
      console.log('👁️ Disabling LOS visualization');
      this._clearLOSVisualizations();
    }
  }

  /**
   * Update LOS visualizations for all NPCs in a scene
   * Call this from the game loop (update method) if visualization is enabled
   * @param {Phaser.Scene} scene - Phaser scene for drawing
   */
  updateLOSVisualizations(scene) {
    if (!this.losVisualizationEnabled || !scene) return;
    
    this._updateLOSVisualizations(scene);
  }

  /**
   * Internal: Update or create LOS cone graphics
   */
  _updateLOSVisualizations(scene) {
    // console.log(`🎯 Updating LOS visualizations for ${this.npcs.size} NPCs`);
    let visualizedCount = 0;
    
    for (const npc of this.npcs.values()) {
      // Only visualize person-type NPCs with LOS config
      if (npc.npcType !== 'person') {
        // console.log(`   Skip "${npc.id}" - not person type (${npc.npcType})`);
        continue;
      }
      
      if (!npc.los || !npc.los.enabled) {
        // console.log(`   Skip "${npc.id}" - no LOS config or disabled`);
        continue;
      }
      
      // console.log(`   Processing "${npc.id}" - has LOS config`, npc.los);
      
      // Remove old visualization
      if (this.losVisualizations.has(npc.id)) {
        // console.log(`   Clearing old visualization for "${npc.id}"`);
        clearLOSCone(this.losVisualizations.get(npc.id));
      }
      
      // Draw new cone (depth is set inside drawLOSCone)
      const graphics = drawLOSCone(scene, npc, npc.los, 0x00ff00, 0.15);
      if (graphics) {
        this.losVisualizations.set(npc.id, graphics);
        // Graphics depth is already set inside drawLOSCone to -999
        // console.log(`   ✅ Created visualization for "${npc.id}"`);
        visualizedCount++;
      } else {
        console.log(`   ❌ Failed to create visualization for "${npc.id}"`);
      }
    }
    
    // console.log(`✅ LOS visualization update complete: ${visualizedCount}/${this.npcs.size} visualized`);
  }

  /**
   * Internal: Clear all LOS visualizations
   */
  _clearLOSVisualizations() {
    for (const graphics of this.losVisualizations.values()) {
      clearLOSCone(graphics);
    }
    this.losVisualizations.clear();
  }

  /**
   * Cleanup: destroy all LOS visualizations and event listeners
   */
  destroy() {
    this._clearLOSVisualizations();
    this.stopTimedMessages();
    
    // Clear all event listeners
    for (const listeners of this.eventListeners.values()) {
      listeners.forEach(({ listener }) => {
        if (this.eventDispatcher && typeof listener === 'function') {
          this.eventDispatcher.off('*', listener);
        }
      });
    }
    this.eventListeners.clear();
    
    console.log('[NPCManager] Destroyed');
  }
}

// Console helper for debugging
if (typeof window !== 'undefined') {
  window.clearNPCHistory = (npcId) => {
    if (!window.npcManager) {
      console.error('NPCManager not available');
      return;
    }
    window.npcManager.clearNPCHistory(npcId);
  };
}
