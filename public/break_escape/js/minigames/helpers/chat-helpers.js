/**
 * Shared Chat Minigame Helpers
 * 
 * Common utilities for phone-chat and person-chat minigames:
 * - Game action tag processing (give_item, unlock_door, etc.)
 * - UI notification handling
 * 
 * @module chat-helpers
 */

/**
 * Process game action tags from Ink story
 * Tags format: # unlock_door:ceo, # give_item:keycard|CEO Keycard, etc.
 * Filters out speaker tags (player, npc, speaker:player, speaker:npc)
 * 
 * @param {Array<string>} tags - Array of tag strings from Ink story
 * @param {Object} ui - UI controller with showNotification method
 * @returns {Array<Object>} Array of processing results for each tag
 */
export function processGameActionTags(tags, ui) {
    if (!window.NPCGameBridge) {
        console.warn('⚠️ NPCGameBridge not available, skipping tag processing');
        return [];
    }
    
    if (!tags || tags.length === 0) {
        return [];
    }
    
    // Filter out speaker tags - only process action tags
    const actionTags = tags.filter(tag => {
        const action = tag.split(':')[0].trim().toLowerCase();
        return action !== 'player' && 
               action !== 'npc' && 
               action !== 'speaker' &&
               !tag.includes('speaker:');
    });
    
    if (actionTags.length === 0) {
        // No action tags to process (all were speaker tags)
        return [];
    }
    
    console.log('🏷️ Processing game action tags:', actionTags);
    
    const results = [];
    
    actionTags.forEach(tag => {
        const trimmedTag = tag.trim();
        
        // Skip empty tags
        if (!trimmedTag) return;
        
        // Parse action and parameter (format: "action:param" or "action")
        const [action, param] = trimmedTag.split(':').map(s => s.trim());
        
        let result = { action, param, success: false, message: '' };
        
        try {
            switch (action) {
                case 'unlock_door':
                    if (param) {
                        const unlockResult = window.NPCGameBridge.unlockDoor(param);
                        if (unlockResult.success) {
                            result.success = true;
                            result.message = `🔓 Door unlocked: ${param}`;
                            if (ui) ui.showNotification(result.message, 'success');
                            console.log('✅ Door unlock successful:', unlockResult);
                        } else {
                            result.message = `⚠️ Failed to unlock: ${param}`;
                            if (ui) ui.showNotification(result.message, 'warning');
                            console.warn('⚠️ Door unlock failed:', unlockResult);
                        }
                    } else {
                        result.message = '⚠️ unlock_door tag missing room parameter';
                        console.warn(result.message);
                    }
                    break;
                    
                case 'give_item':
                    if (param) {
                        const [itemType] = param.split('|').map(s => s.trim());
                        const npcId = window.currentConversationNPCId;
                        
                        if (!npcId) {
                            result.message = '⚠️ No NPC context available';
                            console.warn(result.message);
                            break;
                        }
                        
                        const giveResult = window.NPCGameBridge.giveItem(npcId, itemType);
                        if (giveResult.success) {
                            result.success = true;
                            result.message = `📦 Received: ${giveResult.item.name}`;
                            if (ui) ui.showNotification(result.message, 'success');
                            console.log('✅ Item given successfully:', giveResult);
                        } else {
                            result.message = `⚠️ ${giveResult.error}`;
                            if (ui) ui.showNotification(result.message, 'warning');
                            console.warn('⚠️ Item give failed:', giveResult);
                        }
                    } else {
                        result.message = '⚠️ give_item requires item type parameter';
                        console.warn(result.message);
                    }
                    break;
                    
                case 'give_npc_inventory_items':
                    const npcId = window.currentConversationNPCId;
                    
                    if (!npcId) {
                        result.message = '⚠️ No NPC context available';
                        console.warn(result.message);
                        break;
                    }
                    
                    // Parse filter types (comma-separated)
                    const filterTypes = param ? param.split(',').map(s => s.trim()).filter(s => s) : null;
                    
                    const showResult = window.NPCGameBridge.showNPCInventory(npcId, filterTypes);
                    if (showResult.success) {
                        result.success = true;
                        result.message = `📦 Opening inventory with ${showResult.itemCount} items`;
                        console.log('✅ NPC inventory opened:', showResult);
                    } else {
                        result.message = `⚠️ ${showResult.error}`;
                        if (ui) ui.showNotification(result.message, 'warning');
                        console.warn('⚠️ Show inventory failed:', showResult);
                    }
                    break;
                    
                case 'set_objective':
                    if (param) {
                        window.NPCGameBridge.setObjective(param);
                        result.success = true;
                        result.message = `🎯 New objective: ${param}`;
                        if (ui) ui.showNotification(result.message, 'info');
                    } else {
                        result.message = '⚠️ set_objective tag missing text parameter';
                        console.warn(result.message);
                    }
                    break;
                    
                case 'reveal_secret':
                    if (param) {
                        const [secretId, secretData] = param.split('|').map(s => s.trim());
                        window.NPCGameBridge.revealSecret(secretId, secretData);
                        result.success = true;
                        result.message = `🔍 Secret revealed: ${secretId}`;
                        if (ui) ui.showNotification(result.message, 'info');
                    } else {
                        result.message = '⚠️ reveal_secret tag missing parameter';
                        console.warn(result.message);
                    }
                    break;
                    
                case 'add_note':
                    if (param) {
                        const [title, content] = param.split('|').map(s => s.trim());
                        window.NPCGameBridge.addNote(title, content || '');
                        result.success = true;
                        result.message = `📝 Note added: ${title}`;
                        if (ui) ui.showNotification(result.message, 'info');
                    } else {
                        result.message = '⚠️ add_note tag missing parameter';
                        console.warn(result.message);
                    }
                    break;
                    
                case 'trigger_minigame':
                    if (param) {
                        const minigameName = param;
                        result.success = true;
                        result.message = `🎮 Triggering minigame: ${minigameName}`;
                        if (ui) ui.showNotification(result.message, 'info');
                        // Note: Actual minigame triggering would be game-specific
                        console.log('🎮 Minigame trigger tag:', minigameName);
                    } else {
                        result.message = '⚠️ trigger_minigame tag missing minigame name';
                        console.warn(result.message);
                    }
                    break;
                    
                case 'influence_increased':
                    {
                        const npcId = window.currentConversationNPCId;
                        if (npcId && window.npcManager) {
                            const npc = window.npcManager.getNPC(npcId);
                            const displayName = npc?.displayName || npc?.name || npcId;
                            result.success = true;
                            result.message = `+ Influence: ${displayName}`;
                            showInfluencePopup(displayName, 'increased');
                            console.log(`✨ Influence increased with ${displayName}`);
                        }
                    }
                    break;
                    
                case 'influence_decreased':
                    {
                        const npcId = window.currentConversationNPCId;
                        if (npcId && window.npcManager) {
                            const npc = window.npcManager.getNPC(npcId);
                            const displayName = npc?.displayName || npc?.name || npcId;
                            result.success = true;
                            result.message = `- Influence: ${displayName}`;
                            showInfluencePopup(displayName, 'decreased');
                            console.log(`⚠️ Influence decreased with ${displayName}`);
                        }
                    }
                    break;

                case 'hostile':
                    {
                        const npcId = param || window.currentConversationNPCId;

                        if (!npcId) {
                            result.message = '⚠️ hostile tag missing NPC ID';
                            console.warn(result.message);
                            break;
                        }

                        console.log(`🔴 Processing hostile tag for NPC: ${npcId}`);

                        // Set NPC to hostile state
                        if (window.npcHostileSystem) {
                            window.npcHostileSystem.setNPCHostile(npcId, true);
                            result.success = true;
                            result.message = `⚠️ ${npcId} is now hostile!`;
                            if (ui) ui.showNotification(result.message, 'warning');
                        } else {
                            result.message = '⚠️ Hostile system not initialized';
                            console.warn(result.message);
                        }

                        // Emit event for other systems
                        if (window.eventDispatcher) {
                            window.eventDispatcher.emit('npc_became_hostile', { npcId });
                        }
                    }
                    break;
                case 'clone_keycard':
                    // Parameter is the card_id to clone
                    // Look up card data from NPC's rfidCard property
                    const cardId = param;
                    
                    if (!cardId) {
                        result.message = '⚠️ clone_keycard tag missing card ID parameter';
                        console.warn(result.message);
                        break;
                    }

                    // Check if player has RFID cloner
                    const hasCloner = window.inventory.items.some(item =>
                        item && item.scenarioData &&
                        item.scenarioData.type === 'rfid_cloner'
                    );

                    if (!hasCloner) {
                        result.message = '⚠️ You need an RFID cloner to clone cards';
                        if (ui) ui.showNotification(result.message, 'warning');
                        break;
                    }

                    // Get NPC and their card data
                    const cloneNpcId = window.currentConversationNPCId;
                    let cardData = null;
                    
                    if (cloneNpcId && window.npcManager) {
                        const npc = window.npcManager.getNPC(cloneNpcId);
                        if (npc?.rfidCard && npc.rfidCard.card_id === cardId) {
                            // Use NPC's rfidCard data
                            cardData = {
                                name: npc.rfidCard.name || cardId,
                                card_id: npc.rfidCard.card_id,
                                rfid_protocol: npc.rfidCard.rfid_protocol || 'EM4100',
                                type: 'keycard'
                            };
                        }
                    }
                    
                    // Fallback if NPC card not found
                    if (!cardData) {
                        cardData = {
                            name: cardId,
                            card_id: cardId,
                            rfid_protocol: 'EM4100',
                            type: 'keycard'
                        };
                    }

                    // Set pending conversation return (MINIMAL CONTEXT!)
                    // Conversation state automatically managed by npcConversationStateManager
                    window.pendingConversationReturn = {
                        npcId: window.currentConversationNPCId,
                        type: window.currentConversationMinigameType || 'person-chat'
                    };

                    // Start RFID minigame in clone mode
                    if (window.startRFIDMinigame) {
                        window.startRFIDMinigame(null, null, {
                            mode: 'clone',
                            cardToClone: cardData
                        });

                        result.success = true;
                        result.message = `📡 Starting card clone: ${cardData.name}`;
                        console.log('🔐 Started RFID clone minigame for:', cardData.name);
                    } else {
                        result.message = '⚠️ RFID minigame not available';
                        console.warn('startRFIDMinigame not found');
                    }
                    break;

                default:
                    // Unknown tag, log but don't fail
                    console.log(`ℹ️ Unknown game action tag: ${action}`);
                    result.message = `ℹ️ Unknown action: ${action}`;
                    break;
            }
        } catch (error) {
            result.success = false;
            result.message = `❌ Error processing tag ${action}: ${error.message}`;
            console.error(result.message, error);
        }
        
        results.push(result);
    });
    
    return results;
}

/**
 * Extract and filter game action tags from a tag array
 * Game action tags are those that trigger game mechanics (not speaker tags)
 * 
 * @param {Array<string>} tags - All tags from story
 * @returns {Array<string>} Only the action tags
 */
export function getActionTags(tags) {
    if (!tags) return [];
    
    // Filter out speaker tags and keep only action tags
    return tags.filter(tag => {
        const action = tag.split(':')[0].trim().toLowerCase();
        return action !== 'player' && 
               action !== 'npc' && 
               action !== 'speaker' &&
               !action.startsWith('speaker:');
    });
}

/**
 * Determine speaker from tags
 * Finds the LAST speaker tag (most recent/current speaker)
 * 
 * @param {Array<string>} tags - Tags from story
 * @param {string} defaultSpeaker - Default speaker if not found in tags
 * @returns {string} Speaker ('npc' or 'player')
 */
export function determineSpeaker(tags, defaultSpeaker = 'npc') {
    if (!tags || tags.length === 0) return defaultSpeaker;
    
    // Check tags in REVERSE order to find the last speaker tag (current speaker)
    for (let i = tags.length - 1; i >= 0; i--) {
        const trimmed = tags[i].trim().toLowerCase();
        if (trimmed === 'player' || trimmed === 'speaker:player') {
            return 'player';
        }
        if (trimmed === 'npc' || trimmed === 'speaker:npc') {
            return 'npc';
        }
    }
    
    return defaultSpeaker;
}

/**
 * Show NPC influence change popup
 * Displays a brief notification when player's relationship with an NPC changes
 * 
 * @param {string} npcName - Display name of the NPC
 * @param {string} direction - 'increased' or 'decreased'
 */
export function showInfluencePopup(npcName, direction) {
    const popup = document.createElement('div');
    popup.className = `influence-popup influence-${direction}`;
    
    const symbol = direction === 'increased' ? '+' : '-';
    const color = direction === 'increased' ? '#27ae60' : '#e74c3c';
    
    popup.textContent = `${symbol} Influence: ${npcName}`;
    popup.style.cssText = `
        position: fixed;
        top: 100px;
        left: 50%;
        transform: translateX(-50%) translateY(-20px);
        padding: 15px 30px;
        background: rgba(0, 0, 0, 0.9);
        color: ${color};
        border: 2px solid ${color};
        font-family: 'VT323', monospace;
        font-size: 24px;
        font-weight: bold;
        z-index: 10001;
        opacity: 0;
        transition: all 0.3s ease-out;
        pointer-events: none;
        text-align: center;
    `;
    
    document.body.appendChild(popup);
    
    // Animate in
    setTimeout(() => {
        popup.style.opacity = '1';
        popup.style.transform = 'translateX(-50%) translateY(0)';
    }, 10);
    
    // Animate out and remove
    setTimeout(() => {
        popup.style.opacity = '0';
        popup.style.transform = 'translateX(-50%) translateY(-20px)';
        setTimeout(() => {
            popup.remove();
        }, 300);
    }, 2000);
}
