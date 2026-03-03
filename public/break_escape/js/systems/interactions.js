// Object interaction system
import { INTERACTION_RANGE, INTERACTION_RANGE_SQ, INTERACTION_CHECK_INTERVAL } from '../utils/constants.js?v=8';
// IMPORTANT: version must match all other imports of rooms.js — mismatched ?v= strings
// create separate module instances with separate rooms objects, causing state to diverge.
import { rooms } from '../core/rooms.js?v=17';
import { handleUnlock } from './unlock-system.js';
import { handleDoorInteraction } from './doors.js?v=4';
import { collectFingerprint, handleBiometricScan } from './biometrics.js';
import { addToInventory, removeFromInventory, createItemIdentifier } from './inventory.js?v=9';
import { playUISound, playGameSound } from './ui-sounds.js?v=1';

let gameRef = null;

export function setGameInstance(gameInstance) {
    gameRef = gameInstance;

    // Immediately destroy any proximity ghost when an item is collected,
    // regardless of whether the interaction check interval has fired yet.
    if (window.eventDispatcher) {
        window.eventDispatcher.on('item_removed_from_scene', ({ sprite }) => {
            if (sprite) removeProximityGhost(sprite);
        });
    }
}

// Helper function to calculate interaction distance with direction-based offset
// Extends reach from the edge of the player sprite in the direction the player is facing
function getInteractionDistance(playerSprite, targetX, targetY) {
    const playerDirection = playerSprite.direction || 'down';
    const SPRITE_HALF_WIDTH = 32; // 64px sprite / 2
    const SPRITE_HALF_HEIGHT = 32; // 64px sprite / 2
    const SPRITE_QUARTER_WIDTH = 16; // 64px sprite / 4 (for right/left)
    const SPRITE_QUARTER_HEIGHT = 16; // 64px sprite / 4 (for down)
    
    // Calculate offset point based on player direction
    let offsetX = 0;
    let offsetY = 0;
    
    switch(playerDirection) {
        case 'up':
            offsetY = -SPRITE_HALF_HEIGHT;
            break;
        case 'down':
            offsetY = SPRITE_QUARTER_HEIGHT;
            break;
        case 'left':
            offsetX = -SPRITE_QUARTER_WIDTH;
            break;
        case 'right':
            offsetX = SPRITE_QUARTER_WIDTH;
            break;
        case 'up-left':
            offsetX = -SPRITE_HALF_WIDTH;
            offsetY = -SPRITE_HALF_HEIGHT;
            break;
        case 'up-right':
            offsetX = SPRITE_HALF_WIDTH;
            offsetY = -SPRITE_HALF_HEIGHT;
            break;
        case 'down-left':
            offsetX = -SPRITE_QUARTER_WIDTH;
            offsetY = SPRITE_QUARTER_HEIGHT;
            break;
        case 'down-right':
            offsetX = SPRITE_QUARTER_WIDTH;
            offsetY = SPRITE_QUARTER_HEIGHT;
            break;
    }
    
    // Measure from the offset point (edge of player sprite in facing direction)
    const measureX = playerSprite.x + offsetX;
    const measureY = playerSprite.y + offsetY;
    
    const dx = targetX - measureX;
    const dy = targetY - measureY;
    return dx * dx + dy * dy; // Return squared distance for performance
}

// Update NPC talk icon positions every frame (even when not checking interactions)
function updateNPCTalkIcons() {
    // Iterate through all rooms and update icon positions for visible icons
    Object.values(rooms).forEach(room => {
        if (room.npcSprites) {
            room.npcSprites.forEach(sprite => {
                if (sprite.interactionIndicator && sprite.interactionIndicator.visible) {
                    const iconX = Math.round(sprite.x + 5);
                    const iconY = Math.round(sprite.y - 38);
                    sprite.interactionIndicator.setPosition(iconX, iconY);
                }
            });
        }
    });
}

export function checkObjectInteractions() {
    // Update NPC talk icons every frame to follow moving NPCs
    updateNPCTalkIcons();
    
    // Skip if not enough time has passed since last check
    const currentTime = performance.now();
    if (this.lastInteractionCheck && 
        currentTime - this.lastInteractionCheck < INTERACTION_CHECK_INTERVAL) {
        return;
    }
    this.lastInteractionCheck = currentTime;

    const player = window.player;
    if (!player) {
        return; // Player not created yet
    }

    // We'll measure distance from the closest edge of the player sprite
    const px = player.x;
    const py = player.y;
    
    // Get viewport bounds for performance optimization
    const camera = gameRef ? gameRef.cameras.main : null;
    const margin = INTERACTION_RANGE * 2; // Larger margin to catch more objects
    const viewBounds = camera ? {
        left: camera.scrollX - margin,
        right: camera.scrollX + camera.width + margin,
        top: camera.scrollY - margin,
        bottom: camera.scrollY + camera.height + margin
    } : null;

    // Check ALL objects in ALL rooms, not just current room
    Object.entries(rooms).forEach(([roomId, room]) => {
        if (!room.objects) return;
        
        Object.values(room.objects).forEach(obj => {
            // Skip inactive objects (e.g. collected into inventory)
            if (!obj.active) {
                // Clean up any lingering ghost left from when the item was in range
                removeProximityGhost(obj);
                return;
            }
            
            // Skip non-interactable objects (only highlight scenario items)
            if (!obj.interactable) {
                // Clear highlight if object was previously highlighted
                if (obj.isHighlighted) {
                    obj.isHighlighted = false;
                    obj.clearTint();
                    removeProximityGhost(obj);
                    // Clean up interaction sprite if exists
                    if (obj.interactionIndicator) {
                        obj.interactionIndicator.destroy();
                        delete obj.interactionIndicator;
                    }
                }
                return;
            }
            
            // Skip highlighting for objects marked with noInteractionHighlight (like swivel chairs)
            if (obj.noInteractionHighlight) {
                return;
            }
            
            // Skip objects outside viewport for performance (if viewport bounds available)
            if (viewBounds && (
                obj.x < viewBounds.left || 
                obj.x > viewBounds.right || 
                obj.y < viewBounds.top || 
                obj.y > viewBounds.bottom)) {
                // Clear highlight if object is outside viewport
                if (obj.isHighlighted) {
                    obj.isHighlighted = false;
                    obj.clearTint();
                    removeProximityGhost(obj);
                    // Clean up interaction sprite if exists
                    if (obj.interactionIndicator) {
                        obj.interactionIndicator.destroy();
                        delete obj.interactionIndicator;
                    }
                }
                return;
            }

            // Use squared distance for performance
            const distanceSq = getInteractionDistance(player, obj.x, obj.y);

            if (distanceSq <= INTERACTION_RANGE_SQ) {
                if (!obj.isHighlighted) {
                    obj.isHighlighted = true;
                    // Only apply tint if this is a sprite (has setTint method)
                    if (obj.setTint && typeof obj.setTint === 'function') {
                        obj.setTint(0x4da6ff);  // Blue tint for interactable objects
                    }
                    // Ghost at extreme depth so item silhouette shows through walls
                    addProximityGhost(obj);
                    // Add interaction indicator sprite
                    addInteractionIndicator(obj);
                }
            } else if (obj.isHighlighted) {
                obj.isHighlighted = false;
                // Only clear tint if this is a sprite
                if (obj.clearTint && typeof obj.clearTint === 'function') {
                    obj.clearTint();
                }
                removeProximityGhost(obj);
                // Clean up interaction sprite if exists
                if (obj.interactionIndicator) {
                    obj.interactionIndicator.destroy();
                    delete obj.interactionIndicator;
                }
            }
        });
        
        // Also check door sprites
        if (room.doorSprites) {
            Object.values(room.doorSprites).forEach(door => {
                // Skip if door is destroyed, inactive, or not a valid door sprite
                if (!door || door.scene === null || !door.active || !door.doorProperties || !door.doorProperties.locked) {
                    // Clear highlight if door was previously highlighted
                    if (door && door.isHighlighted) {
                        door.isHighlighted = false;
                        if (door.clearTint && typeof door.clearTint === 'function') {
                            door.clearTint();
                        }
                        // Clean up interaction sprite if exists
                        if (door.interactionIndicator) {
                            door.interactionIndicator.destroy();
                            delete door.interactionIndicator;
                        }
                    }
                    return;
                }
                
                // Skip doors outside viewport for performance (if viewport bounds available)
                if (viewBounds && (
                    door.x < viewBounds.left || 
                    door.x > viewBounds.right || 
                    door.y < viewBounds.top || 
                    door.y > viewBounds.bottom)) {
                    // Clear highlight if door is outside viewport
                    if (door.isHighlighted) {
                        door.isHighlighted = false;
                        door.clearTint();
                        // Clean up interaction sprite if exists
                        if (door.interactionIndicator) {
                            door.interactionIndicator.destroy();
                            delete door.interactionIndicator;
                        }
                    }
                    return;
                }

                // Use squared distance for performance
                const distanceSq = getInteractionDistance(player, door.x, door.y);

                if (distanceSq <= INTERACTION_RANGE_SQ) {
                    if (!door.isHighlighted) {
                        door.isHighlighted = true;
                        door.setTint(0x4da6ff);  // Blue tint for locked doors
                        // Add interaction indicator sprite for doors
                        addInteractionIndicator(door);
                    }
                } else if (door.isHighlighted) {
                    door.isHighlighted = false;
                    door.clearTint();
                    // Clean up interaction sprite if exists
                    if (door.interactionIndicator) {
                        door.interactionIndicator.destroy();
                        delete door.interactionIndicator;
                    }
                }
            });
        }

        // Also check NPC sprites
        if (room.npcSprites) {
            room.npcSprites.forEach(sprite => {
                // NPCs should always be interactable when present
                if (!sprite.active) {
                    // Clear highlight if sprite was previously highlighted
                    if (sprite.isHighlighted) {
                        sprite.isHighlighted = false;
                        sprite.clearTint();
                        // Clean up interaction sprite if exists
                        if (sprite.interactionIndicator) {
                            sprite.interactionIndicator.destroy();
                            delete sprite.interactionIndicator;
                        }
                    }
                    return;
                }
                
                // Skip NPCs outside viewport for performance (if viewport bounds available)
                if (viewBounds && (
                    sprite.x < viewBounds.left || 
                    sprite.x > viewBounds.right || 
                    sprite.y < viewBounds.top || 
                    sprite.y > viewBounds.bottom)) {
                    // Clear highlight if NPC is outside viewport
                    if (sprite.isHighlighted) {
                        sprite.isHighlighted = false;
                        sprite.clearTint();
                        // Clean up interaction sprite if exists
                        if (sprite.interactionIndicator) {
                            sprite.interactionIndicator.destroy();
                            delete sprite.interactionIndicator;
                        }
                    }
                    return;
                }

                // Check if NPC is hostile - don't show talk icon if so
                const isNPCHostile = sprite.npcId && window.npcHostileSystem && window.npcHostileSystem.isNPCHostile(sprite.npcId);

                // Use squared distance for performance
                const distanceSq = getInteractionDistance(player, sprite.x, sprite.y);

                if (distanceSq <= INTERACTION_RANGE_SQ) {
                    if (!sprite.isHighlighted) {
                        sprite.isHighlighted = true;
                        // Add talk icon indicator for NPC (created on first highlight)
                        if (!sprite.interactionIndicator) {
                            addInteractionIndicator(sprite);
                        }
                        // Show talk icon only if NPC is NOT hostile
                        if (sprite.interactionIndicator && !isNPCHostile) {
                            sprite.interactionIndicator.setVisible(true);
                            sprite.talkIconVisible = true;
                        } else if (sprite.interactionIndicator && isNPCHostile) {
                            sprite.interactionIndicator.setVisible(false);
                            sprite.talkIconVisible = false;
                        }
                    } else if (sprite.interactionIndicator && !sprite.talkIconVisible && !isNPCHostile) {
                        // Update position of talk icon to stay pixel-perfect on NPC
                        const iconX = Math.round(sprite.x + 5);
                        const iconY = Math.round(sprite.y - 38);
                        sprite.interactionIndicator.setPosition(iconX, iconY);
                        sprite.interactionIndicator.setVisible(true);
                        sprite.talkIconVisible = true;
                    } else if (isNPCHostile && sprite.interactionIndicator && sprite.talkIconVisible) {
                        // Hide icon if NPC became hostile
                        sprite.interactionIndicator.setVisible(false);
                        sprite.talkIconVisible = false;
                    }
                } else if (sprite.isHighlighted) {
                    sprite.isHighlighted = false;
                    sprite.clearTint();
                    // Hide talk icon when out of range
                    if (sprite.interactionIndicator) {
                        sprite.interactionIndicator.setVisible(false);
                        sprite.talkIconVisible = false;
                    }
                } else if (sprite.interactionIndicator && sprite.talkIconVisible) {
                    // Update position every frame when icon is visible (smooth following)
                    const iconX = Math.round(sprite.x + 5);
                    const iconY = Math.round(sprite.y - 38);
                    sprite.interactionIndicator.setPosition(iconX, iconY);
                }
            });
        }
    });
}

function getInteractionSpriteKey(obj) {
    // Determine which sprite to show based on the object's interaction type
    
    // Check for NPCs first
    if (obj._isNPC) {
        return 'interact'; // Use generic interact sprite for NPCs
    }
    
    // Check for doors (they may not have scenarioData)
    if (obj.doorProperties) {
        if (obj.doorProperties.locked) {
            // Check door lock type
            const lockType = obj.doorProperties.lockType;
            if (lockType === 'password') return 'password';
            if (lockType === 'pin') return 'pin';
            if (lockType === 'rfid') return 'rfid-icon';
            return 'keyway'; // Default to keyway for key locks or unknown types
        }
        return null; // Unlocked doors don't need overlay
    }
    
    if (!obj || !obj.scenarioData) {
        return null;
    }
    
    const data = obj.scenarioData;
    
    // Check for locked containers and items
    if (data.locked === true) {
        // Check specific lock type
        const lockType = data.lockType;
        if (lockType === 'password') return 'password';
        if (lockType === 'pin') return 'pin';
        if (lockType === 'biometric') return 'fingerprint';
        if (lockType === 'rfid') return 'rfid-icon';
        // Default to keyway for key locks or unknown types
        return 'keyway';
    }
    
    // Unlocked containers don't need an overlay
    // (they'll be opened via the container minigame when interacted with)
    if (data.contents) {
        return null; // No overlay for unlocked containers
    }
    
    // Check for fingerprint collection
    if (data.hasFingerprint === true) {
        return 'fingerprint';
    }
    
    return null;
}

// Creates a ghost copy of a static object's sprite at depth 9000, tinted blue at
// 20% alpha, so it bleeds through walls/tables to hint the player of a nearby item.
function addProximityGhost(obj) {
    if (!obj.scene || !obj.scene.add) return;
    if (obj.proximityGhost) return; // Already exists
    if (obj._isNPC) return;         // NPCs use the talk-icon system instead
    if (obj.doorProperties) return; // Doors are always visible; their lock icon is the interactionIndicator

    try {
        const textureKey = obj.texture && obj.texture.key;
        const frameName  = obj.frame  && obj.frame.name  !== undefined ? obj.frame.name  : undefined;

        if (!textureKey || textureKey === '__MISSING') return;

        const ghost = obj.scene.add.image(obj.x, obj.y, textureKey, frameName);
        ghost.setOrigin(obj.originX !== undefined ? obj.originX : 0.5,
                        obj.originY !== undefined ? obj.originY : 0.5);
        ghost.setScale(obj.scaleX, obj.scaleY);
        ghost.setAngle(obj.angle || 0);
        ghost.setDepth(9000);      // Above all world geometry (walls, tables, etc.)
        ghost.setTint(0x4da6ff);   // Full-saturation blue tint
        ghost.setAlpha(0.2);       // 20% - shape is visible, reads as a glow not a copy

        obj.scene.tweens.add({
            targets:  ghost,
            alpha:    { from: 0.15, to: 0.3 },
            duration: 800,
            yoyo:     true,
            repeat:   -1,
            ease:     'Sine.easeInOut'
        });

        obj.proximityGhost = ghost;

        // Self-cleaning: patch setVisible so the ghost is destroyed the instant
        // the sprite is hidden (collection, any code path, async or not).
        // We store the original so removeProximityGhost can restore it.
        if (obj.setVisible && !obj._preGhostSetVisible) {
            obj._preGhostSetVisible = obj.setVisible.bind(obj);
            obj.setVisible = function(visible) {
                obj._preGhostSetVisible(visible);
                if (!visible) removeProximityGhost(obj);
            };
        }
    } catch (error) {
        console.warn('Failed to add proximity ghost:', error);
    }
}

function removeProximityGhost(obj) {
    if (obj.proximityGhost) {
        obj.proximityGhost.destroy();
        delete obj.proximityGhost;
    }
    // Restore the original setVisible so the patch doesn't linger
    if (obj._preGhostSetVisible) {
        obj.setVisible = obj._preGhostSetVisible;
        delete obj._preGhostSetVisible;
    }
}

function addInteractionIndicator(obj) {
    // Only add indicator if we have a game instance and the object has a scene
    if (!gameRef || !obj.scene || !obj.scene.add) {
        return;
    }
    
    // NPCs get the talk icon above their heads with pixel-perfect positioning
    if (obj._isNPC) {
        try {
            // Talk icon positioned above NPC with pixel-perfect coordinates
            const talkIconX = Math.round(obj.x + 5); // Centered above
            const talkIconY = Math.round(obj.y - 38); // 32 pixels above
            
            const indicator = obj.scene.add.image(talkIconX, talkIconY, 'talk');
            indicator.setDepth(obj.depth + 1);
            indicator.setVisible(false); // Hidden until player is in range
            
            // Store reference for cleanup and visibility management
            obj.interactionIndicator = indicator;
            obj.talkIconVisible = false;
        } catch (error) {
            console.warn('Failed to add talk icon for NPC:', error);
        }
        return;
    }
    
    // Non-NPC objects use the standard interaction indicator sprite
    const spriteKey = getInteractionSpriteKey(obj);
    if (!spriteKey) return;
    
    // Create indicator sprite centered over the object
    try {
        // Get the center of the parent sprite, accounting for its origin
        const center = obj.getCenter();
        
        // Position indicator above the object (accounting for parent's display height)
        const indicatorX = center.x;
        const indicatorY = center.y; // Position above with 10px offset
        
        const indicator = obj.scene.add.image(indicatorX, indicatorY, spriteKey);
        indicator.setDepth(999); // High depth to appear on top
        indicator.setOrigin(0.5, 0.5); // Center the sprite
        // indicator.setScale(0.5); // Scale down to be less intrusive
        
        // Add pulsing animation
        obj.scene.tweens.add({
            targets: indicator,
            alpha: { from: 1, to: 0.5 },
            duration: 800,
            yoyo: true,
            repeat: -1
        });
        
        // Store reference for cleanup
        obj.interactionIndicator = indicator;
    } catch (error) {
        console.warn('Failed to add interaction indicator:', error);
    }
}

export function handleObjectInteraction(sprite) {
    console.log('OBJECT INTERACTION', { 
        name: sprite.name, 
        id: sprite.objectId,
        scenarioData: sprite.scenarioData
    });
    
    if (!sprite) {
        console.warn('Invalid sprite');
        return;
    }
    
    // Emit object interaction event (for NPCs to react)
    if (window.eventDispatcher && sprite.scenarioData) {
        window.eventDispatcher.emit('object_interacted', {
            objectType: sprite.scenarioData.type,
            objectName: sprite.scenarioData.name,
            roomId: window.currentPlayerRoom
        });
    }
    
    // Handle swivel chair interaction - trigger punch to kick it!
    if (sprite.isSwivelChair && sprite.body) {
        const player = window.player;
        if (player && window.playerCombat) {
            // In interact mode, auto-switch to jab for chairs
            const currentMode = window.playerCombat.getInteractionMode();
            const wasInteractMode = currentMode === 'interact';
            
            if (wasInteractMode) {
                console.log('🪑 Chair in interact mode - auto-jabbing');
                window.playerCombat.setInteractionMode('jab');
            }
            
            // Trigger punch to kick the chair
            window.playerCombat.punch();
            
            // Restore interact mode if we switched
            if (wasInteractMode) {
                setTimeout(() => {
                    window.playerCombat.setInteractionMode('interact');
                }, 100);
            }
        }
        return;
    }
    
    // Handle NPC sprite interaction
    if (sprite._isNPC && sprite.npcId) {
        console.log('NPC INTERACTION', { npcId: sprite.npcId });
        
        // Check if NPC is hostile
        const isHostile = window.npcHostileSystem && window.npcHostileSystem.isNPCHostile(sprite.npcId);
        
        // If hostile and in interact mode, auto-jab instead of talking
        if (isHostile && window.playerCombat) {
            const currentMode = window.playerCombat.getInteractionMode();
            const wasInteractMode = currentMode === 'interact';
            
            if (wasInteractMode) {
                console.log('👊 Hostile NPC in interact mode - auto-jabbing');
                window.playerCombat.setInteractionMode('jab');
            }
            
            // Punch the hostile NPC
            window.playerCombat.punch();
            
            // Restore interact mode if we switched
            if (wasInteractMode) {
                setTimeout(() => {
                    window.playerCombat.setInteractionMode('interact');
                }, 100);
            }
            return;
        }
        
        // Non-hostile NPCs - start chat minigame
        if (window.MinigameFramework && window.npcManager) {
            const npc = window.npcManager.getNPC(sprite.npcId);
            if (npc) {
                // Start person-chat minigame with this NPC
                window.MinigameFramework.startMinigame('person-chat', null, {
                    npcId: sprite.npcId,
                    title: npc.displayName || sprite.npcId
                });
                return;
            } else {
                console.warn('NPC not found in manager:', sprite.npcId);
            }
        } else {
            console.warn('MinigameFramework or npcManager not available');
        }
        return;
    }

    if (!sprite.scenarioData) {
        console.warn('Invalid sprite or missing scenario data');
        return;
    }

    // Notify tutorial when inventory item is clicked
    // Items in inventory have takeable set to false
    if (sprite.scenarioData.takeable === false && window.getTutorialManager) {
        const tutorialManager = window.getTutorialManager();
        tutorialManager.notifyPlayerClickedInventoryItem();
    }

    // Handle keycard cloning (when clicked from inventory)
    // Only intercept if the card is already in inventory (takeable === false).
    // If takeable is true the card is still in the world and should be picked up normally.
    if (sprite.scenarioData.type === 'keycard' && sprite.scenarioData.takeable === false) {
        console.log('KEYCARD INTERACTION (inventory) - checking for cloner');

        // Check if player has RFID cloner
        const hasCloner = window.inventory.items.some(item =>
            item && item.scenarioData &&
            item.scenarioData.type === 'rfid_cloner'
        );

        if (hasCloner) {
            // Start RFID minigame in clone mode
            console.log('Starting RFID clone for keycard:', sprite.scenarioData.name);
            if (window.startRFIDMinigame) {
                window.startRFIDMinigame(null, null, {
                    mode: 'clone',
                    cardToClone: sprite.scenarioData
                });
            } else {
                window.gameAlert('RFID minigame not available', 'error', 'Error', 3000);
            }
        } else {
            window.gameAlert('You need an RFID cloner to clone this card', 'info', 'No Cloner', 3000);
        }
        return; // Early return
    }

    // Handle the Crypto Workstation - pick it up if takeable, or use it if in inventory
    if (sprite.scenarioData.type === "workstation") {
        // If it's in inventory (marked as non-takeable), open it
        if (!sprite.scenarioData.takeable) {
            console.log('OPENING WORKSTATION FROM INVENTORY');
            if (window.openCryptoWorkstation) {
                window.openCryptoWorkstation();
            } else {
                window.gameAlert('Crypto workstation not available', 'error', 'Error', 3000);
            }
            return;
        }
        
        // Otherwise, try to pick it up and add to inventory
        console.log('WORKSTATION ADDED TO INVENTORY');
        playUISound('item');
        addToInventory(sprite);
        window.gameAlert(`${sprite.scenarioData.name} added to inventory. You can now use it for cryptographic analysis.`, 'success', 'Item Acquired', 5000);
        return;
    }
    
    // Handle the Lab Workstation - opens lab sheets in iframe
    if (sprite.scenarioData.type === "lab-workstation") {
        // If it's in inventory (marked as non-takeable), open it
        if (!sprite.scenarioData.takeable) {
            console.log('OPENING LAB WORKSTATION FROM INVENTORY');
            const labUrl = sprite.scenarioData.labUrl || sprite.scenarioData.url;
            if (labUrl && window.openLabWorkstation) {
                window.openLabWorkstation(labUrl);
            } else {
                window.gameAlert('Lab workstation not available', 'error', 'Error', 3000);
            }
            return;
        }
        
        // Otherwise, try to pick it up and add to inventory
        console.log('LAB WORKSTATION ADDED TO INVENTORY');
        playUISound('item');
        addToInventory(sprite);
        window.gameAlert(`${sprite.scenarioData.name} added to inventory. You can now use it to access lab sheets.`, 'success', 'Item Acquired', 5000);
        return;
    }
    
    // Handle the Notepad - open notes minigame
    if (sprite.scenarioData.type === "notepad") {
        if (window.startNotesMinigame) {
            // Check if notes minigame is specifically already running
            if (window.MinigameFramework && window.MinigameFramework.currentMinigame && 
                window.MinigameFramework.currentMinigame.navigateToNoteIndex) {
                console.log('Notes minigame already running, navigating to notepad note instead');
                // If notes minigame is already running, just navigate to the notepad note
                if (window.MinigameFramework.currentMinigame.navigateToNoteIndex) {
                    window.MinigameFramework.currentMinigame.navigateToNoteIndex(0);
                }
                return;
            }
            
            // Navigate to the notepad note (index 0) when clicking the notepad
            // Create a minimal item just for navigation - no auto-add needed
            const notepadItem = {
                scenarioData: {
                    type: 'notepad',
                    name: 'Notepad'
                }
            };
            window.startNotesMinigame(notepadItem, '', '', 0, false, false);
            return;
        }
    }
    
    // Handle the Bluetooth Scanner - only open minigame if it's already in inventory
    if (sprite.scenarioData.type === "bluetooth_scanner") {
        // Check if this is an inventory item (clicked from inventory)
        const isInventoryItem = sprite.objectId && sprite.objectId.startsWith('inventory_');
        
        if (isInventoryItem && window.startBluetoothScannerMinigame) {
            console.log('Starting bluetooth scanner minigame from inventory');
            window.startBluetoothScannerMinigame(sprite);
            return;
        }
        // If it's not in inventory, let it fall through to the takeable logic below
    }
    
    // Handle the Fingerprint Kit - only open minigame if it's already in inventory
    if (sprite.scenarioData.type === "fingerprint_kit") {
        // Check if this is an inventory item (clicked from inventory)
        const isInventoryItem = sprite.objectId && sprite.objectId.startsWith('inventory_');
        
        if (isInventoryItem && window.startBiometricsMinigame) {
            console.log('Starting biometrics minigame from inventory');
            window.startBiometricsMinigame(sprite);
            return;
        }
        // If it's not in inventory, let it fall through to the takeable logic below
    }

    // Handle the RFID Cloner (RFID Flipper) - only open minigame if it's already in inventory
    if (sprite.scenarioData.type === "rfid_cloner") {
        // Check if this is an inventory item (clicked from inventory)
        const isInventoryItem = sprite.objectId && sprite.objectId.startsWith('inventory_');
        
        if (isInventoryItem && window.startRFIDMinigame) {
            console.log('Starting RFID minigame from inventory (unlock mode)');
            window.startRFIDMinigame(null, null, {
                mode: 'unlock',
                availableCards: [],
                hasCloner: true
            });
            return;
        }
        // If it's not in inventory, let it fall through to the takeable logic below
    }
    
    // Handle VM Launcher interaction
    if (sprite.scenarioData.type === "vm-launcher" || sprite.scenarioData.type === "vm_launcher") {
        console.log('VM Launcher interaction:', sprite.scenarioData);
        if (window.MinigameFramework) {
            // Get VM data from scenario
            const vm = sprite.scenarioData.vm || null;
            const hacktivityMode = sprite.scenarioData.hacktivityMode || window.breakEscapeConfig?.hacktivityMode || false;
            
            window.MinigameFramework.startMinigame('vm-launcher', null, {
                title: sprite.scenarioData.name || 'VM Console Access',
                vm: vm,
                hacktivityMode: hacktivityMode,
                stationId: sprite.scenarioData.id || sprite.objectId
            });
            return;
        }
    }
    
    // Handle Flag Station interaction
    if (sprite.scenarioData.type === "flag-station" || sprite.scenarioData.type === "flag_station") {
        console.log('Flag Station interaction:', sprite.scenarioData);
        if (window.MinigameFramework) {
            window.MinigameFramework.startMinigame('flag-station', null, {
                title: sprite.scenarioData.name || 'Flag Submission Terminal',
                stationId: sprite.scenarioData.id || sprite.objectId,
                stationName: sprite.scenarioData.name,
                flags: sprite.scenarioData.flags || [],
                acceptsVms: sprite.scenarioData.acceptsVms || [],
                submittedFlags: window.gameState?.submittedFlags || [],
                gameId: window.breakEscapeConfig?.gameId || window.gameConfig?.gameId
            });
            return;
        }
    }
    
    // Handle the Lockpick Set - pick it up if takeable, or use it if in inventory
    if (sprite.scenarioData.type === "lockpick" || sprite.scenarioData.type === "lockpickset") {
        // If it's in inventory (marked as non-takeable), just acknowledge it
        if (!sprite.scenarioData.takeable) {
            console.log('LOCKPICK ALREADY IN INVENTORY');
            window.gameAlert(`Used to pick pin tumbler locks.`, 'info', `${sprite.scenarioData.name}.`, 3000);
            return;
        }
        
        // Otherwise, try to pick it up and add to inventory
        console.log('LOCKPICK SET ADDED TO INVENTORY');
        playUISound('item');
        addToInventory(sprite);
        window.gameAlert(`${sprite.scenarioData.name} added to inventory. You can now use it to pick locks.`, 'success', 'Item Acquired', 5000);
        return;
    }
    
    // Handle biometric scanner interaction
    if (sprite.scenarioData.biometricType === 'fingerprint') {
        handleBiometricScan(sprite);
        return;
    }
    
    // Check for fingerprint collection possibility
    if (sprite.scenarioData.hasFingerprint) {
        // Check if player has fingerprint kit
        const hasKit = window.inventory.items.some(item => 
            item && item.scenarioData && 
            item.scenarioData.type === 'fingerprint_kit'
        );
        
        if (hasKit) {
            const sample = collectFingerprint(sprite);
            if (sample) {
                return; // Exit after collecting fingerprint
            }
        } else {
            window.gameAlert("You need a fingerprint kit to collect samples from this surface!", 'warning', 'Missing Equipment', 4000);
            return;
        }
    }
    
    // Skip range check for inventory items
    const isInventoryItem = window.inventory && window.inventory.items.includes(sprite);
    if (!isInventoryItem) {
        // Check if player is in range
        const player = window.player;
        if (!player) return;
        
        // Measure distance with direction-based offset
        const distanceSq = getInteractionDistance(player, sprite.x, sprite.y);
        
        if (distanceSq > INTERACTION_RANGE_SQ) {
            console.log('INTERACTION_OUT_OF_RANGE', { 
                objectName: sprite.name,
                objectId: sprite.objectId,
                distance: Math.sqrt(distanceSq),
                maxRange: Math.sqrt(INTERACTION_RANGE_SQ)
            });
            return;
        }
    }
    
    const data = sprite.scenarioData;
    
    // Handle container items (suitcase, briefcase, bags, bins, etc.) - check BEFORE lock check
    if (data.type === 'suitcase' || data.type === 'briefcase' || data.type === 'bag1' || data.type === 'bin1' || data.contents) {
        console.log('CONTAINER ITEM INTERACTION', data);

        // SECURITY: Always validate with server
        // Client cannot be trusted to determine lock state
        // The unlock system will handle both locked and unlocked containers via server validation
        console.log('Validating container access with server...');
        handleUnlock(sprite, 'item');
        return;
    }
    
    // Check if item is locked (non-container items)
    if (data.locked === true) {
        console.log('ITEM LOCKED', data);
        handleUnlock(sprite, 'item');
        return;
    }
    
    let message = `${data.name} `;
    if (data.observations) {
        message += `Observations: ${data.observations}\n`;
    }
    
    // For phone type objects, use phone-chat with runtime conversion or direct NPC access
    if (data.type === 'phone' && (data.text || data.voice || data.npcIds)) {
        console.log('Phone object detected:', { type: data.type, text: data.text, voice: data.voice, npcIds: data.npcIds });
        
        // Check if phone-chat system is available
        if (window.MinigameFramework && window.npcManager) {
            const phoneId = data.phoneId || 'default_phone';
            
            // Check if phone has already been converted or has npcIds
            if (data.npcIds && data.npcIds.length > 0) {
                console.log('Phone has npcIds, opening phone-chat directly', { npcIds: data.npcIds });
                // Phone already has NPCs, open directly
                window.MinigameFramework.startMinigame('phone-chat', null, {
                    phoneId: phoneId,
                    npcIds: data.npcIds,
                    title: data.name || 'Phone'
                });
                return;
            }
            
            // Need to convert simple message - import the converter
            import('../utils/phone-message-converter.js').then(module => {
                const PhoneMessageConverter = module.default;
                
                // Convert simple message to virtual NPC
                const npcId = PhoneMessageConverter.convertAndRegister(data, window.npcManager);
                
                if (npcId) {
                    // Update phone object to reference the NPC
                    data.phoneId = phoneId;
                    data.npcIds = [npcId];
                    
                    // Open phone-chat with converted NPC
                    window.MinigameFramework.startMinigame('phone-chat', null, {
                        phoneId: phoneId,
                        title: data.name || 'Phone'
                    });
                } else {
                    console.error('Failed to convert phone object to virtual NPC');
                }
            }).catch(error => {
                console.error('Failed to load PhoneMessageConverter:', error);
            });
            
            return; // Exit early
        } else {
            console.warn('Phone-chat system not available (MinigameFramework or npcManager missing)');
        }
    }
    
    // For text_file type objects, use the text file minigame
    if (data.type === 'text_file' && data.text) {
        console.log('Text file object detected:', { type: data.type, name: data.name, text: data.text });
        // Start the text file minigame
        if (window.MinigameFramework) {
            // Initialize the framework if not already done
            if (!window.MinigameFramework.mainGameScene && window.game) {
                window.MinigameFramework.init(window.game);
            }
            
            const minigameParams = {
                title: `Text File - ${data.name || 'Unknown File'}`,
                fileName: data.name || 'Unknown File',
                fileContent: data.text,
                fileType: data.fileType || 'text',
                observations: data.observations,
                lockable: sprite,
                source: data.source || 'Unknown Source',
                onComplete: (success, result) => {
                    console.log('Text file minigame completed:', success, result);
                }
            };
            
            window.MinigameFramework.startMinigame('text-file', null, minigameParams);
            return; // Exit early since minigame handles the interaction
        }
    }
    
    if (data.readable && data.text) {
        message += `Text: ${data.text}\n`;
        
        // For notes type objects, use the notes minigame
        if (data.type === 'notes' && data.text) {
            // Start the notes minigame
            if (window.startNotesMinigame) {
                window.startNotesMinigame(sprite, data.text, data.observations);
                return; // Exit early since minigame handles the interaction
            }
        }
        
        // Add readable text as a note (fallback for other readable objects)
        // Skip notepad items since they're handled specially
        if (data.text.trim().length > 0 && data.type !== 'notepad') {
            const addedNote = window.addNote(data.name, data.text, data.important || false);
            
            if (addedNote) {
                window.gameAlert(`Added "${data.name}" to your notes.`, 'info', 'Note Added', 3000);
                
                // If this is a note in the inventory, remove it after adding to notes list
                if (isInventoryItem && data.type === 'notes') {
                    setTimeout(() => {
                        if (removeFromInventory(sprite)) {
                            window.gameAlert(`Removed "${data.name}" from inventory after recording in notes.`, 'success', 'Inventory Updated', 3000);
                        }
                    }, 1000);
                }
            }
        }
    }
    
    if (data.takeable) {
        // Always attempt to add to inventory - addToInventory() handles duplicates
        // and will remove from environment + show notification even if already in inventory
        console.log('ATTEMPTING TO ADD TAKEABLE ITEM', { 
            type: data.type, 
            name: data.name,
            identifier: createItemIdentifier(sprite.scenarioData)
        });
        playUISound('item');
        const added = addToInventory(sprite);
        
        // Only show the observation notification if item was NOT added (duplicate)
        // because addToInventory() already shows its own notification
        if (!added) {
            // Item was already in inventory, notification was shown by addToInventory
            return;
        }
    }
    
    // Show observation notification for non-takeable items or items with extra info
    if (!data.takeable || (data.observations && !data.takeable)) {
        window.gameAlert(message, 'info', data.name, 5000);
    }
}

// Handle container item interactions
function handleContainerInteraction(sprite) {
    const data = sprite.scenarioData;
    console.log('Handling container interaction:', data);
    
    // Check if container has contents
    if (!data.contents || data.contents.length === 0) {
        window.gameAlert(`${data.name} is empty.`, 'info', 'Empty Container', 3000);
        return;
    }
    
    // Start the container minigame
    if (window.startContainerMinigame) {
        window.startContainerMinigame(sprite, data.contents, data.takeable);
    } else {
        console.error('Container minigame not available');
        window.gameAlert('Container minigame not available', 'error', 'Error', 3000);
    }
}

// Try to interact with the nearest interactable object within range
export function tryInteractWithNearest() {
    const player = window.player;
    if (!player) {
        return;
    }

    const px = player.x;
    const py = player.y;
    
    let nearestObject = null;
    let nearestDistance = INTERACTION_RANGE; // Only consider objects within interaction range
    
    // Get player's facing direction and convert to angle for direction filtering
    const playerDirection = player.direction || 'down';
    let facingAngle = 0;
    let angleTolerance = 70; // degrees - how wide the cone in front of player is
    
    // Determine facing angle based on direction
    // In canvas/Phaser: right=0°, down=90°, left=180°, up=270°
    switch(playerDirection) {
        case 'right':
            facingAngle = 0;
            break;
        case 'down-right':
            facingAngle = 45;
            break;
        case 'down':
            facingAngle = 90;
            break;
        case 'down-left':
            facingAngle = 135;
            break;
        case 'left':
            facingAngle = 180;
            break;
        case 'up-left':
            facingAngle = 225;
            break;
        case 'up':
            facingAngle = 270; // Use 270 instead of -90
            break;
        case 'up-right':
            facingAngle = 315; // Use 315 instead of -45
            break;
        default: // Fallback for any unknown directions
            facingAngle = 90; // Default to down
    }
    
    // Helper function to check if an object is in front of the player
    function isInFrontOfPlayer(objX, objY) {
        const dx = objX - px;
        const dy = objY - py;
        
        // Calculate angle to object (in canvas coordinates where Y increases downward)
        let angleToObject = Math.atan2(dy, dx) * 180 / Math.PI;
        
        // Normalize to 0-360
        angleToObject = (angleToObject + 360) % 360;
        
        // Calculate angular difference
        let angleDiff = Math.abs(facingAngle - angleToObject);
        if (angleDiff > 180) {
            angleDiff = 360 - angleDiff;
        }
        
        return angleDiff <= angleTolerance;
    }
    
    // Check all objects in all rooms
    Object.entries(rooms).forEach(([roomId, room]) => {
        if (!room.objects) return;
        
        Object.values(room.objects).forEach(obj => {
            // Only consider interactable, active, and visible objects
            if (!obj.active || !obj.interactable || !obj.visible) {
                return;
            }
            
            // Calculate distance with direction-based offset
            const distanceSq = getInteractionDistance(player, obj.x, obj.y);
            const distance = Math.sqrt(distanceSq);
            
            // Check if within range and in front of player
            if (distance <= INTERACTION_RANGE && isInFrontOfPlayer(obj.x, obj.y)) {
                if (distance < nearestDistance) {
                    nearestDistance = distance;
                    nearestObject = obj;
                }
            }
        });
        
        // Also check door sprites (including all doors, not just locked ones)
        if (room.doorSprites) {
            Object.values(room.doorSprites).forEach(door => {
                // Only consider active doors (check all doors, not just locked)
                if (!door.active || !door.doorProperties) {
                    return;
                }
                
                // Calculate distance with direction-based offset
                const distanceSq = getInteractionDistance(player, door.x, door.y);
                const distance = Math.sqrt(distanceSq);
                
                // Check if within range and in front of player
                if (distance <= INTERACTION_RANGE && isInFrontOfPlayer(door.x, door.y)) {
                    if (distance < nearestDistance) {
                        nearestDistance = distance;
                        nearestObject = door;
                    }
                }
            });
        }

        // Also check NPC sprites
        if (room.npcSprites) {
            room.npcSprites.forEach(sprite => {
                // Only consider active NPCs
                if (!sprite.active || !sprite._isNPC) {
                    return;
                }
                
                // Calculate distance with direction-based offset
                const distanceSq = getInteractionDistance(player, sprite.x, sprite.y);
                const distance = Math.sqrt(distanceSq);
                
                // Check if within range and in front of player
                if (distance <= INTERACTION_RANGE && isInFrontOfPlayer(sprite.x, sprite.y)) {
                    if (distance < nearestDistance) {
                        nearestDistance = distance;
                        nearestObject = sprite;
                    }
                }
            });
        }
    });
    
    // Interact with the nearest object if one was found
    if (nearestObject) {
        // Notify tutorial of interaction
        if (window.getTutorialManager) {
            const tutorialManager = window.getTutorialManager();
            tutorialManager.notifyPlayerInteracted();
        }

        // Check if this is a door (doors have doorProperties instead of scenarioData)
        if (nearestObject.doorProperties) {
            // Handle door interaction - triggers unlock/open sequence based on lock state
            handleDoorInteraction(nearestObject);
        } else if (nearestObject._isNPC) {
            // Handle NPC interaction with hostile check
            tryInteractWithNPC(nearestObject);
        } else {
            // Handle regular object interaction
            handleObjectInteraction(nearestObject);
        }
    }
}

// Handle NPC interaction by sprite reference
export function tryInteractWithNPC(npcSprite) {
    if (!npcSprite || !npcSprite._isNPC) {
        return false;
    }

    const player = window.player;
    if (!player) {
        return false;
    }

    // Check if NPC is within interaction range of the player
    const distanceSq = getInteractionDistance(player, npcSprite.x, npcSprite.y);
    const distance = Math.sqrt(distanceSq);

    // Only interact if within range
    if (distance <= INTERACTION_RANGE) {
        // Check if NPC is hostile - if so, trigger punch instead of conversation
        const npcId = npcSprite.npcId;
        if (npcId && window.npcHostileSystem && window.npcHostileSystem.isNPCHostile(npcId)) {
            // Hostile NPC - punch instead of talk
            if (window.playerCombat) {
                window.playerCombat.punch();
            }
            return true;
        }

        // Normal NPC interaction (conversation)
        handleObjectInteraction(npcSprite);
        return true; // Interaction successful
    }

    // Out of range - caller should handle movement
    return false;
}

// Simple range check for click-based interactions (no direction offset).
// Returns true if the given sprite is within INTERACTION_RANGE of the player centre.
export function isObjectInInteractionRange(sprite) {
    const player = window.player;
    if (!player || !sprite) return false;
    const dx = sprite.x - player.x;
    const dy = sprite.y - player.y;
    return (dx * dx + dy * dy) <= INTERACTION_RANGE_SQ;
}

// Export for global access
window.checkObjectInteractions = checkObjectInteractions;
window.handleObjectInteraction = handleObjectInteraction;
window.handleContainerInteraction = handleContainerInteraction;
window.tryInteractWithNearest = tryInteractWithNearest;
window.tryInteractWithNPC = tryInteractWithNPC;
window.isObjectInInteractionRange = isObjectInInteractionRange;
