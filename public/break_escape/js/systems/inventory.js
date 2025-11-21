// Inventory System
// Handles inventory management and display

import { rooms } from '../core/rooms.js';
import InkEngine from './ink/ink-engine.js?v=1';

// Helper function to create a unique identifier for an item
export function createItemIdentifier(scenarioData) {
    if (!scenarioData) return 'unknown';
    return `${scenarioData.type}_${scenarioData.name || 'unnamed'}`;
}

// Initialize the inventory system
export function initializeInventory() {
    console.log('Inventory system initialized');
    
    // Initialize inventory state
    window.inventory = {
        items: [],
        container: null
    };
    
    // Get the HTML inventory container
    const inventoryContainer = document.getElementById('inventory-container');
    if (!inventoryContainer) {
        console.error('Inventory container not found');
        return;
    }
    
    inventoryContainer.innerHTML = '';
    
    // Store reference to container
    window.inventory.container = inventoryContainer;
    
    // Add notepad to inventory
    addNotepadToInventory();
    
    console.log('INVENTORY INITIALIZED', window.inventory);
}

// Helper function to preload intro messages for a phone
async function preloadPhoneIntroMessages(phoneId, allowedNpcIds = null) {
    console.log(`📱 preloadPhoneIntroMessages called for ${phoneId}`, { allowedNpcIds });
    
    if (!window.npcManager) {
        console.warn('❌ npcManager not available');
        return;
    }
    
    // Import PhoneChatConversation class (default export)
    const PhoneChatConversation = (await import('../minigames/phone-chat/phone-chat-conversation.js')).default;
    
    // Create a temporary ink engine for preloading
    const tempEngine = new InkEngine();
    
    let npcs = window.npcManager.getNPCsByPhone(phoneId);
    
    // Filter to only allowed NPCs if specified
    if (allowedNpcIds && allowedNpcIds.length > 0) {
        console.log(`🔍 Filtering NPCs: allowed = ${allowedNpcIds.join(', ')}`);
        npcs = npcs.filter(npc => allowedNpcIds.includes(npc.id));
    }
    
    console.log(`📱 Found ${npcs.length} NPCs on phone ${phoneId}:`, npcs.map(n => n.id));
    
    for (const npc of npcs) {
        const history = window.npcManager.getConversationHistory(npc.id);
        console.log(`📱 NPC ${npc.id}: history length = ${history.length}, has story = ${!!(npc.storyPath || npc.storyJSON)}`);
        
        // Only preload if no history exists and NPC has a story
        if (history.length === 0 && (npc.storyPath || npc.storyJSON)) {
            try {
                console.log(`📱 Preloading intro for ${npc.id}...`);
                const tempConversation = new PhoneChatConversation(npc.id, window.npcManager, tempEngine);
                const storySource = npc.storyJSON || npc.storyPath;
                const loaded = await tempConversation.loadStory(storySource);
                
                if (loaded) {
                    const startKnot = npc.currentKnot || 'start';
                    tempConversation.goToKnot(startKnot);
                    const result = tempConversation.continue();
                    
                    if (result.text && result.text.trim()) {
                        const messages = result.text.trim().split('\n').filter(line => line.trim());
                        console.log(`📱 Adding ${messages.length} preloaded messages for ${npc.id}`);
                        messages.forEach(message => {
                            if (message.trim()) {
                                window.npcManager.addMessage(npc.id, 'npc', message.trim(), { 
                                    preloaded: true,
                                    timestamp: Date.now() - 3600000 // 1 hour ago
                                });
                            }
                        });
                        
                        npc.storyState = tempConversation.saveState();
                        console.log(`✅ Preloaded intro for ${npc.id}`);
                    } else {
                        console.log(`⚠️ No intro text for ${npc.id}`);
                    }
                } else {
                    console.log(`⚠️ Failed to load story for ${npc.id}`);
                }
            } catch (error) {
                console.error(`❌ Error preloading intro for ${npc.id}:`, error);
            }
        } else {
            console.log(`⏭️ Skipping ${npc.id} - history=${history.length}, story=${!!(npc.storyPath || npc.storyJSON)}`);
        }
    }
    console.log(`📱 Finished preloading for phone ${phoneId}`);
}

// Process initial inventory items
export function processInitialInventoryItems() {
    console.log('Processing initial inventory items');
    
    if (!window.gameScenario) {
        console.error('Game scenario not loaded');
        return;
    }
    
    // Check for startItemsInInventory array in scenario
    if (window.gameScenario.startItemsInInventory && Array.isArray(window.gameScenario.startItemsInInventory)) {
        console.log(`Processing ${window.gameScenario.startItemsInInventory.length} starting inventory items`);
        
        window.gameScenario.startItemsInInventory.forEach(itemData => {
            console.log(`Adding ${itemData.name} to inventory from startItemsInInventory`);
            
            // Create inventory sprite for this object
            const inventoryItem = createInventorySprite(itemData);
            if (inventoryItem) {
                addToInventory(inventoryItem);
            }
        });
    } else {
        console.log('No startItemsInInventory defined in scenario');
    }
}

function createInventorySprite(itemData) {
    try {
        // Create a pseudo-sprite object that can be used in inventory
        const sprite = {
            name: itemData.type,
            objectId: `inventory_${itemData.type}_${Date.now()}`,
            scenarioData: itemData,
            texture: {
                key: itemData.type  // Use the type as the texture key for image lookup
            },
            // Copy critical properties for easy access
            keyPins: itemData.keyPins,  // Preserve keyPins for keys
            key_id: itemData.key_id,    // Preserve key_id for keys
            locked: itemData.locked,
            lockType: itemData.lockType,
            requires: itemData.requires,
            difficulty: itemData.difficulty,
            setVisible: function(visible) {
                // For inventory items, visibility is handled by DOM
                return this;
            }
        };
        
        console.log('Created inventory sprite:', {
            name: sprite.name,
            key_id: sprite.key_id,
            keyPins: sprite.keyPins,
            locked: sprite.locked,
            lockType: sprite.lockType
        });
        
        // Log if this is a key with keyPins
        if (sprite.keyPins) {
            console.log(`✓ Inventory key "${sprite.name}" has keyPins: [${sprite.keyPins.join(', ')}]`);
        }
        
        return sprite;
    } catch (error) {
        console.error('Error creating inventory sprite:', error);
        return null;
    }
}

export function addToInventory(sprite) {
    if (!sprite || !sprite.scenarioData) {
        console.warn('Invalid sprite for inventory');
        return false;
    }
    
    try {
        console.log("Adding to inventory:", {
            objectId: sprite.objectId,
            name: sprite.name,
            type: sprite.scenarioData?.type,
            currentRoom: window.currentPlayerRoom
        });
        
        // Check if the item is already in the inventory
        const itemIdentifier = createItemIdentifier(sprite.scenarioData);
        const isAlreadyInInventory = window.inventory.items.some(item => 
            item && createItemIdentifier(item.scenarioData) === itemIdentifier
        );
        
        if (isAlreadyInInventory) {
            console.log(`Item ${itemIdentifier} is already in inventory`);
            return false;
        }
        
        // Remove from room if it exists
        if (window.currentPlayerRoom && rooms[window.currentPlayerRoom] && rooms[window.currentPlayerRoom].objects) {
            if (rooms[window.currentPlayerRoom].objects[sprite.objectId]) {
                const roomObj = rooms[window.currentPlayerRoom].objects[sprite.objectId];
                if (roomObj.setVisible) {
                    roomObj.setVisible(false);
                }
                roomObj.active = false;
                console.log(`Removed object ${sprite.objectId} from room`);
            }
        }
        
        // Only call setVisible if it's a Phaser sprite with that method
        if (sprite.setVisible && typeof sprite.setVisible === 'function') {
            sprite.setVisible(false);
        }
        
        // Special handling for keys - group them together
        if (sprite.scenarioData.type === 'key') {
            return addKeyToInventory(sprite);
        }
        
        // Create a new slot for this item
        const inventoryContainer = document.getElementById('inventory-container');
        if (!inventoryContainer) {
            console.error('Inventory container not found');
            return false;
        }
        
        // Create a new slot
        const slot = document.createElement('div');
        slot.className = 'inventory-slot';
        inventoryContainer.appendChild(slot);
        
        // Create inventory item
        const itemImg = document.createElement('img');
        itemImg.className = 'inventory-item';
        itemImg.src = `/break_escape/assets/objects/${sprite.texture?.key || sprite.name || sprite.scenarioData?.type}.png`;
        itemImg.alt = sprite.scenarioData.name;
        
        // Create tooltip
        const tooltip = document.createElement('div');
        tooltip.className = 'inventory-tooltip';
        tooltip.textContent = sprite.scenarioData.name;
        
        // Add item data
        itemImg.scenarioData = sprite.scenarioData;
        itemImg.name = sprite.name;
        itemImg.objectId = 'inventory_' + sprite.objectId;
        
        // Explicitly preserve critical lock-related properties
        itemImg.keyPins = sprite.keyPins || sprite.scenarioData?.keyPins;
        itemImg.key_id = sprite.key_id || sprite.scenarioData?.key_id;
        itemImg.lockType = sprite.scenarioData?.lockType;
        itemImg.locked = sprite.scenarioData?.locked;
        itemImg.requires = sprite.scenarioData?.requires;
        itemImg.difficulty = sprite.scenarioData?.difficulty;
        
        // Add data-type attribute for CSS styling
        itemImg.setAttribute('data-type', sprite.scenarioData?.type);
        
        // For phones, add unread message count and badge
        if (sprite.scenarioData?.type === 'phone' && sprite.scenarioData?.phoneId) {
            const phoneId = sprite.scenarioData.phoneId;
            const npcIds = sprite.scenarioData.npcIds || null;  // Get allowed NPCs for this phone
            itemImg.setAttribute('data-phone-id', phoneId);
            
            if (window.npcManager) {
                // Preload intro messages for all NPCs on this phone
                preloadPhoneIntroMessages(phoneId, npcIds).then(() => {
                    const unreadCount = window.npcManager.getTotalUnreadCount(phoneId, npcIds);
                    console.log(`📱 Phone ${phoneId} added to inventory, unread count: ${unreadCount}`, { npcIds });
                    itemImg.setAttribute('data-unread-count', unreadCount);
                    
                    // Create badge element if there are unread messages
                    if (unreadCount > 0) {
                        console.log(`✅ Creating badge for phone ${phoneId}`);
                        const badge = document.createElement('span');
                        badge.className = 'phone-badge';
                        badge.textContent = unreadCount;
                        itemImg.parentElement.appendChild(badge);
                    } else {
                        console.log(`❌ Not creating badge, count is ${unreadCount}`);
                    }
                });
            } else {
                console.log('❌ npcManager not available when adding phone');
            }
        }
        
        // Mark as non-takeable once in inventory (so it won't try to be picked up again)
        itemImg.scenarioData.takeable = false;
        
        // Add click handler
        itemImg.addEventListener('click', function() {
            if (window.handleObjectInteraction) {
                window.handleObjectInteraction(this);
            }
        });
        
        // Add to slot
        slot.appendChild(itemImg);
        slot.appendChild(tooltip);
        
        // Add to inventory array
        window.inventory.items.push(itemImg);
        
        // Emit NPC event for item pickup
        if (window.eventDispatcher) {
            window.eventDispatcher.emit(`item_picked_up:${sprite.scenarioData.type}`, {
                itemType: sprite.scenarioData.type,
                itemName: sprite.scenarioData.name,
                roomId: window.currentPlayerRoom
            });
        }
        
        // Apply pulse animation to the slot instead of showing notification
        slot.classList.add('pulse');
        // Remove the pulse class after the animation completes
        setTimeout(() => {
            slot.classList.remove('pulse');
        }, 600);
        
        // If this is the Bluetooth scanner, automatically open the minigame after adding to inventory
        if (sprite.scenarioData.type === "bluetooth_scanner" && window.startBluetoothScannerMinigame) {
            // Small delay to ensure the item is fully added to inventory
            setTimeout(() => {
                console.log('Auto-opening bluetooth scanner minigame after adding to inventory');
                window.startBluetoothScannerMinigame(itemImg);
            }, 500);
        }
        
        
        // Fingerprint kit is now handled as a minigame when clicked from inventory
        
        // Handle crypto workstation - use the proper modal implementation from helpers.js
        if (sprite.scenarioData.type === "workstation") {
            // Don't override the openCryptoWorkstation function - it's already properly defined in helpers.js
            console.log('Crypto workstation added to inventory - modal function available');
        }
        
        return true;
    } catch (error) {
        console.error('Error adding to inventory:', error);
        return false;
    }
}

// Key management functions
function addKeyToInventory(sprite) {
    // Initialize key ring if it doesn't exist
    if (!window.inventory.keyRing) {
        window.inventory.keyRing = {
            keys: [],
            slot: null,
            itemImg: null
        };
    }
    
    // DEBUG: Check properties before adding
    const keyId = sprite.scenarioData?.key_id || sprite.key_id;
    const keyPins = sprite.scenarioData?.keyPins || sprite.keyPins;
    console.log(`🔑 BEFORE adding key to ring (sprite object):`, {
        sprite_key_id: sprite.key_id,
        sprite_keyPins: sprite.keyPins,
        scenarioData_key_id: sprite.scenarioData?.key_id,
        scenarioData_keyPins: sprite.scenarioData?.keyPins,
        resolved_key_id: keyId,
        resolved_keyPins: keyPins
    });
    
    // Add the key to the key ring
    window.inventory.keyRing.keys.push(sprite);
    
    // Log key storage with keyPins
    console.log(`✓ Key "${sprite.scenarioData?.name}" added to key ring:`, {
        key_id: keyId,
        keyPins: keyPins,
        locked: sprite.scenarioData?.locked,
        lockType: sprite.scenarioData?.lockType
    });
    
    // Update or create the key ring display
    updateKeyRingDisplay();
    
    // IMPORTANT: Reinitialize key-lock mappings now that we have a new key
    // This is critical for newly acquired keys (e.g., dropped by NPCs) to unlock doors
    if (window.initializeKeyLockMappings) {
        console.log('🔑 Reinitializing key-lock mappings after adding key to inventory');
        window.initializeKeyLockMappings();
    }
    
    // Apply pulse animation to the key ring slot instead of showing notification
    const keyRingSlot = window.inventory.keyRing.slot;
    if (keyRingSlot) {
        keyRingSlot.classList.add('pulse');
        setTimeout(() => {
            keyRingSlot.classList.remove('pulse');
        }, 600);
    }
    
    return true;
}

function updateKeyRingDisplay() {
    const keyRing = window.inventory.keyRing;
    if (!keyRing || keyRing.keys.length === 0) {
        // Remove key ring display if no keys
        if (keyRing && keyRing.slot) {
            keyRing.slot.remove();
            keyRing.slot = null;
            keyRing.itemImg = null;
        }
        return;
    }
    
    const inventoryContainer = document.getElementById('inventory-container');
    if (!inventoryContainer) {
        console.error('Inventory container not found');
        return;
    }
    
    // Remove existing key ring slot if it exists
    if (keyRing.slot) {
        keyRing.slot.remove();
    }
    
    // Create new slot for key ring
    const slot = document.createElement('div');
    slot.className = 'inventory-slot';
    inventoryContainer.appendChild(slot);
    
    // Create key ring item
    const itemImg = document.createElement('img');
    itemImg.className = 'inventory-item';
    itemImg.src = keyRing.keys.length === 1 ? `/break_escape/assets/objects/key.png` : `/break_escape/assets/objects/key-ring.png`;
    itemImg.alt = keyRing.keys.length === 1 ? keyRing.keys[0].scenarioData.name : 'Key Ring';
    
    // Add data attributes for styling
    itemImg.setAttribute('data-type', 'key_ring');
    itemImg.setAttribute('data-key-count', keyRing.keys.length);
    
    // Create tooltip
    const tooltip = document.createElement('div');
    tooltip.className = 'inventory-tooltip';
    tooltip.textContent = keyRing.keys.length === 1 ? keyRing.keys[0].scenarioData.name : 'Key Ring';
    
    // Add item data - use the first key's data as the primary data
    const allKeysData = keyRing.keys.map(k => k.scenarioData);
    console.log(`🔑 Building key ring scenarioData with ${keyRing.keys.length} keys:`, {
        firstKeyScenarioData: keyRing.keys[0].scenarioData,
        allKeysData: allKeysData
    });
    
    itemImg.scenarioData = {
        ...keyRing.keys[0].scenarioData,
        name: keyRing.keys.length === 1 ? keyRing.keys[0].scenarioData.name : 'Key Ring',
        type: 'key_ring',
        keyCount: keyRing.keys.length,
        allKeys: allKeysData
    };
    itemImg.name = 'key';
    itemImg.objectId = 'inventory_key_ring';
    
    // Add click handler for key ring
    itemImg.addEventListener('click', function() {
        if (window.handleKeyRingInteraction) {
            window.handleKeyRingInteraction(this);
        }
    });
    
    // Add to slot
    slot.appendChild(itemImg);
    slot.appendChild(tooltip);
    
    // Store references
    keyRing.slot = slot;
    keyRing.itemImg = itemImg;
    
    // Add to inventory array (replace any existing key ring item)
    const existingKeyRingIndex = window.inventory.items.findIndex(item => 
        item && item.scenarioData && item.scenarioData.type === 'key_ring'
    );
    
    if (existingKeyRingIndex !== -1) {
        window.inventory.items[existingKeyRingIndex] = itemImg;
    } else {
        window.inventory.items.push(itemImg);
    }
}

function handleKeyRingInteraction(keyRingItem) {
    const keyRing = window.inventory.keyRing;
    if (!keyRing || keyRing.keys.length === 0) {
        return;
    }
    
    if (keyRing.keys.length === 1) {
        // Single key - handle normally
        if (window.handleObjectInteraction) {
            window.handleObjectInteraction(keyRingItem);
        }
    } else {
        // Multiple keys - show list
        const keyNames = keyRing.keys.map(key => key.scenarioData.name).join('\n• ');
        const message = `Key Ring contains ${keyRing.keys.length} keys:\n• ${keyNames}`;
        
        if (window.gameAlert) {
            window.gameAlert(message, 'info', 'Key Ring', 0);
        }
    }
}

// Add notepad to inventory
function addNotepadToInventory() {
    // Check if notepad is already in inventory
    const notepadExists = window.inventory.items.some(item => 
        item && item.scenarioData && item.scenarioData.type === 'notepad'
    );
    
    if (notepadExists) {
        console.log('Notepad already in inventory');
        return;
    }
    
    // Create notepad item data
    const notepadData = {
        type: 'notepad',
        name: 'Notepad',
        takeable: true,
        readable: true,
        text: 'Use this notepad to review your collected notes and observations.',
        observations: 'A handy notepad for keeping track of important information.'
    };
    
    // Create a mock sprite object for the notepad
    const notepadSprite = {
        name: 'notes5',
        objectId: 'notepad_inventory',
        scenarioData: notepadData,
        setVisible: function(visible) {
            // For inventory items, visibility is handled by DOM
            return this;
        }
    };
    
    // Add to inventory
    addToInventory(notepadSprite);
    
    // Also add the notepad as a note at the beginning of the notes collection
    if (window.addNote) {
        const notepadText = 'Use this notepad to review your collected notes and observations.\n\nObservation: A handy notepad for keeping track of important information.';
        const notepadNote = window.addNote('Notepad', notepadText, false);
        if (notepadNote) {
            // Move the notepad note to the beginning of the notes array
            const notes = window.gameState.notes;
            const notepadIndex = notes.findIndex(note => note.id === notepadNote.id);
            if (notepadIndex !== -1) {
                const notepadNoteItem = notes.splice(notepadIndex, 1)[0];
                notes.unshift(notepadNoteItem); // Add to beginning
                console.log('Notepad note with observations added to beginning of notes collection during inventory setup');
            }
        }
    }
}

// Remove item from inventory
export function removeFromInventory(item) {
    try {
        // Find the item in the inventory array
        const itemIndex = window.inventory.items.indexOf(item);
        if (itemIndex === -1) return false;
        
        // Remove from array
        window.inventory.items.splice(itemIndex, 1);
        
        // Remove the entire slot from DOM
        const slot = item.parentElement;
        if (slot && slot.classList.contains('inventory-slot')) {
            slot.remove();
        }
        
        // Hide bluetooth toggle if we dropped the bluetooth scanner
        if (item.scenarioData.type === "bluetooth_scanner") {
            const bluetoothToggle = document.getElementById('bluetooth-toggle');
            if (bluetoothToggle) {
                bluetoothToggle.style.display = 'none';
            }
        }
        
        // Hide biometrics toggle if we dropped the fingerprint kit
        if (item.scenarioData.type === "fingerprint_kit") {
            const biometricsToggle = document.getElementById('biometrics-toggle');
            if (biometricsToggle) {
                biometricsToggle.style.display = 'none';
            }
        }
        
        return true;
    } catch (error) {
        console.error('Error removing from inventory:', error);
        return false;
    }
}

// Update phone badge with unread count
export function updatePhoneBadge(phoneId) {
    if (!window.npcManager) return;
    
    // Find phone items in inventory
    const phoneItems = window.inventory.items.filter(item => 
        item.scenarioData?.type === 'phone' && 
        item.getAttribute('data-phone-id') === phoneId
    );
    
    // Update badge for each phone with this ID
    phoneItems.forEach(phoneItem => {
        const npcIds = phoneItem.scenarioData?.npcIds || null;  // Get allowed NPCs for this phone
        const unreadCount = window.npcManager.getTotalUnreadCount(phoneId, npcIds);
        phoneItem.setAttribute('data-unread-count', unreadCount);
        
        // Get the inventory slot (parent element)
        const inventorySlot = phoneItem.parentElement;
        if (!inventorySlot) return;
        
        // Remove existing badge if present
        const existingBadge = inventorySlot.querySelector('.phone-badge');
        if (existingBadge) {
            existingBadge.remove();
        }
        
        // Create new badge if there are unread messages
        if (unreadCount > 0) {
            const badge = document.createElement('span');
            badge.className = 'phone-badge';
            badge.textContent = unreadCount;
            inventorySlot.appendChild(badge);
        }
    });
}

// Export for global access
window.initializeInventory = initializeInventory;
window.processInitialInventoryItems = processInitialInventoryItems;
window.addToInventory = addToInventory;
window.removeFromInventory = removeFromInventory;
window.addNotepadToInventory = addNotepadToInventory;
window.createItemIdentifier = createItemIdentifier;
window.handleKeyRingInteraction = handleKeyRingInteraction;
window.updatePhoneBadge = updatePhoneBadge; 