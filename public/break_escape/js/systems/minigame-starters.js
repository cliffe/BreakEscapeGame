/**
 * MINIGAME STARTERS
 * =================
 * 
 * Functions to initialize and start various minigames (lockpicking, key selection).
 * These are wrappers around the MinigameFramework that handle setup and callbacks.
 */

import { generateKeyCutsForLock, doesKeyMatchLock, PREDEFINED_LOCK_CONFIGS } from './key-lock-system.js';

export function startLockpickingMinigame(lockable, scene, difficulty = 'medium', callback, keyPins = null) {
    console.log('🎮 startLockpickingMinigame called with:', {
        keyPinsParam: keyPins,
        difficulty: difficulty,
        lockable: lockable?.name || lockable?.scenarioData?.name || 'unknown',
        hasDoorProperties: !!lockable?.doorProperties,
        hasScenarioData: !!lockable?.scenarioData
    });
    
    // If keyPins not provided as parameter, try to extract from lockable object
    if (!keyPins) {
        if (lockable?.doorProperties?.keyPins || lockable?.doorProperties?.key_pins) {
            keyPins = lockable.doorProperties.keyPins || lockable.doorProperties.key_pins;
            console.log('✓ Extracted keyPins from door properties:', keyPins);
        } else if (lockable?.scenarioData?.keyPins || lockable?.scenarioData?.key_pins) {
            keyPins = lockable.scenarioData.keyPins || lockable.scenarioData.key_pins;
            console.log('✓ Extracted keyPins from scenarioData:', keyPins);
        } else if (lockable?.keyPins || lockable?.key_pins) {
            keyPins = lockable.keyPins || lockable.key_pins;
            console.log('✓ Extracted keyPins from lockable property:', keyPins);
        } else {
            console.warn('⚠ No keyPins found in lockable object - will use random pins');
        }
    } else {
        console.log('✓ Using keyPins passed as parameter:', keyPins);
    }
    
    console.log('🎮 Starting lockpicking minigame with difficulty:', difficulty, 'keyPins:', keyPins);

    
    // Initialize the minigame framework if not already done
    if (!window.MinigameFramework) {
        console.error('MinigameFramework not available');
        // Fallback to simple version
        window.gameAlert('Advanced lockpicking unavailable. Using simple pick attempt.', 'warning', 'Lockpicking', 2000);
        
        const success = Math.random() < 0.6; // 60% chance
        setTimeout(() => {
            if (success) {
                window.gameAlert('Successfully picked the lock!', 'success', 'Lock Picked', 2000);
                callback(true);
            } else {
                window.gameAlert('Failed to pick the lock.', 'error', 'Pick Failed', 2000);
                callback(false);
            }
        }, 1000);
        return;
    }
    
    // Use the advanced minigame framework
    if (!window.MinigameFramework.mainGameScene) {
        window.MinigameFramework.init(scene);
    }
    
    // Extract item information from lockable object (handles both items and doors)
    let itemName, itemImage, itemObservations;
    
    // Check if this is a door (has doorProperties) or an item
    if (lockable?.doorProperties) {
        // This is a door - get the connected room name
        const connectedRoomId = lockable.doorProperties.connectedRoom;
        const currentRoomId = lockable.doorProperties.roomId;
        const gameScenario = window.gameScenario;
        const connectedRoom = gameScenario?.rooms?.[connectedRoomId];
        const currentRoom = gameScenario?.rooms?.[currentRoomId];
        const isLocked = lockable.doorProperties.locked;
        
        // Use door_sign if available (player-visible sign on the door)
        const doorSignOrName = connectedRoom?.door_sign || connectedRoom?.name;
        
        // Format item name with locked status
        if (doorSignOrName) {
            // Has door_sign or room name - show it
            itemName = isLocked ? `Locked ${doorSignOrName}` : doorSignOrName;
            itemObservations = `Door to ${doorSignOrName}`;
        } else {
            // No door_sign and undiscovered room - use generic names
            itemName = 'Locked door';
            const currentRoomName = currentRoom?.name || currentRoomId;
            itemObservations = `A door leading out of ${currentRoomName}`;
        }
        
        itemImage = 'tiles/door.png'; // Use default door image
    } else {
        // This is a regular item - use scenarioData
        itemName = lockable?.scenarioData?.name || lockable?.name || 'Locked Item';
        itemImage = lockable?.texture?.key ? `/break_escape/assets/objects/${lockable.texture.key}.png` : null;
        itemObservations = lockable?.scenarioData?.observations || '';
    }
    
    // Start the lockpicking minigame (Phaser version)
    window.MinigameFramework.startMinigame('lockpicking', null, {
        lockable: lockable,
        difficulty: difficulty,
        predefinedPinHeights: keyPins,  // Pass scenario keyPins as predefinedPinHeights
        itemName: itemName,
        itemImage: itemImage,
        itemObservations: itemObservations,
        cancelText: 'Close',
        canSwitchToKeyMode: window.inventory.items.some(item => 
            item && item.scenarioData && 
            item.scenarioData.type === 'key'
        ),
        availableKeys: (() => {
            // Collect all available keys for mode switching
            const keys = [];
            
            // Individual keys
            const individualKeys = window.inventory.items.filter(item => 
                item && item.scenarioData && 
                item.scenarioData.type === 'key'
            );
            individualKeys.forEach(key => {
                let cuts = key.scenarioData.cuts;
                
                // KEYPIN TO CUT CONVERSION (for available keys):
                // If no cuts but keyPins exists, generate cuts from the lock configuration.
                // keyPins on a key = the lock configuration this key opens (already normalized to 25-65)
                if (!cuts && (key.scenarioData.keyPins || key.keyPins)) {
                    const lockKeyPins = key.scenarioData.keyPins || key.keyPins;
                    console.log(`Generating cuts from lock keyPins for available key "${key.scenarioData.name}":`, lockKeyPins);
                    
                    // Convert lock pin lengths to key cut depths
                    cuts = lockKeyPins.map(keyPinLength => {
                        const keyBladeTop_world = 175;                        // Key blade top when inserted
                        const shearLine_world = 155;                          // Shear line position
                        const gapFromKeyBladeTopToShearLine = 20;            // Distance between them
                        const cutDepth_needed = keyPinLength - gapFromKeyBladeTopToShearLine;  // Cut depth formula
                        const clampedCutDepth = Math.max(0, Math.min(110, cutDepth_needed));  // Clamp to blade height
                        return Math.round(clampedCutDepth);
                    });
                    
                    console.log(`Generated cuts for key "${key.scenarioData.name}":`, cuts);
                }
                
                keys.push({
                    id: key.scenarioData.key_id,
                    name: key.scenarioData.name,
                    cuts: cuts || []
                });
            });
            
            // Keys from key ring
            const keyRingItem = window.inventory.items.find(item => 
                item && item.scenarioData && 
                item.scenarioData.type === 'key_ring'
            );
            if (keyRingItem && keyRingItem.scenarioData.allKeys) {
                keyRingItem.scenarioData.allKeys.forEach(keyData => {
                    let cuts = keyData.cuts;
                    
                    // KEYPIN TO CUT CONVERSION (for key ring keys):
                    // Same conversion as above - keyPins → cuts using the formula
                    if (!cuts && keyData.keyPins) {
                        const lockKeyPins = keyData.keyPins;
                        console.log(`Generating cuts from lock keyPins for key ring key "${keyData.name}":`, lockKeyPins);
                        
                        cuts = lockKeyPins.map(keyPinLength => {
                            const keyBladeTop_world = 175;                        // Key blade top when inserted
                            const shearLine_world = 155;                          // Shear line position
                            const gapFromKeyBladeTopToShearLine = 20;            // Distance between them
                            const cutDepth_needed = keyPinLength - gapFromKeyBladeTopToShearLine;  // Cut depth formula
                            const clampedCutDepth = Math.max(0, Math.min(110, cutDepth_needed));  // Clamp to blade height
                            return Math.round(clampedCutDepth);
                        });
                        
                        console.log(`Generated cuts for key ring key "${keyData.name}":`, cuts);
                    }
                    
                    keys.push({
                        id: keyData.key_id,
                        name: keyData.name,
                        cuts: cuts || []
                    });
                });
            }
            
            return keys.length > 0 ? keys : null;
        })(),
        onComplete: (success, result) => {
            if (success) {
                console.log('LOCKPICK SUCCESS');
                window.gameAlert('Successfully picked the lock!', 'success', 'Lockpicking', 4000);
                callback(true);
            } else {
                console.log('LOCKPICK FAILED');
                window.gameAlert('Failed to pick the lock.', 'error', 'Lockpicking', 4000);
                callback(false);
            }
        }
    });
}

export function startKeySelectionMinigame(lockable, type, playerKeys, requiredKeyId, unlockTargetCallback) {
    console.log('Starting key selection minigame', { playerKeys, requiredKeyId });
    
    // Initialize the minigame framework if not already done
    if (!window.MinigameFramework) {
        console.error('MinigameFramework not available');
        // Fallback to simple key selection
        const correctKey = playerKeys.find(key => key.scenarioData.key_id === requiredKeyId);
        if (correctKey) {
            window.gameAlert(`You used the ${correctKey.scenarioData.name} to unlock the ${type}.`, 'success', 'Unlock Successful', 4000);
            if (unlockTargetCallback) {
                unlockTargetCallback(lockable, type, lockable.layer);
            }
        } else {
            window.gameAlert('None of your keys work with this lock.', 'error', 'Wrong Keys', 4000);
        }
        return;
    }
    
    // Use the advanced minigame framework
    if (!window.MinigameFramework.mainGameScene) {
        window.MinigameFramework.init(window.game);
    }
    
    // Determine the lock ID for this lockable based on scenario data
    let lockId = null;
    
    // Try to find the lock ID from the scenario data
    if (lockable.scenarioData?.requires) {
        // This is a key lock, find which key it requires
        const requiredKeyId = lockable.scenarioData.requires;
        
        // Find the mapping for this key to get the lock ID
        if (window.keyLockMappings && window.keyLockMappings[requiredKeyId]) {
            lockId = window.keyLockMappings[requiredKeyId].lockId;
            console.log(`Found lock ID "${lockId}" for key "${requiredKeyId}"`);
        }
    }
    
    // Fallback to default lock ID
    if (!lockId) {
        lockId = lockable.scenarioData?.lockId || lockable.id || 'default_lock';
        console.log(`Using fallback lock ID "${lockId}"`);
    }
    
    // Find the key that matches this lock
    const matchingKey = playerKeys.find(key => doesKeyMatchLock(key.scenarioData.key_id, lockId));
    
    let keysToShow = playerKeys;
    if (matchingKey) {
        console.log(`Found matching key "${matchingKey.scenarioData.name}" for lock "${lockId}"`);
        // For now, show all keys so player has to figure out which one works
        // In the future, you could show only the matching key or give hints
    } else {
        console.log(`No matching key found for lock "${lockId}", showing all keys`);
    }
    
    // Convert inventory keys to the format expected by the minigame
    const inventoryKeys = keysToShow.map(key => {
        // Generate cuts data if not present
        let cuts = key.scenarioData.cuts;
        
        // KEYPIN TO CUT CONVERSION:
        // ==========================
        // If no cuts but keyPins exists, we need to generate cuts from the lock configuration.
        // 
        // Remember: keyPins on a KEY represent the LOCK configuration this key is designed to open.
        // The keyPins values have already been normalized from 0-100 to 25-65 pixel range.
        // 
        // We convert keyPins (lock pin lengths) to cuts (key blade notch depths) using the formula:
        // cutDepth = keyPinLength - gapFromKeyBladeTopToShearLine
        // 
        // This ensures when the key is inserted, each pin rests on its corresponding cut,
        // lifting the pin so its top aligns exactly with the shear line.
        if (!cuts && (key.scenarioData.keyPins || key.keyPins)) {
            const lockKeyPins = key.scenarioData.keyPins || key.keyPins;
            console.log(`Generating cuts from lock keyPins for key "${key.scenarioData.name}":`, lockKeyPins);
            
            // Generate cuts that match this lock configuration
            cuts = lockKeyPins.map(keyPinLength => {
                // Key blade geometry (in world coordinates):
                const keyBladeTop_world = 175;    // Top surface of key blade when inserted
                const shearLine_world = 155;      // Where lock plug meets housing
                const gapFromKeyBladeTopToShearLine = keyBladeTop_world - shearLine_world; // 20 pixels
                
                // Formula: cutDepth = keyPinLength - gap
                // Example: If keyPin is 65 pixels long, cut must be 45 pixels deep (65 - 20)
                // This ensures the pin's bottom rests on the cut, lifting its top to the shear line
                const cutDepth_needed = keyPinLength - gapFromKeyBladeTopToShearLine;
                
                // Clamp to valid range (0 to 110, which is key blade height)
                // This prevents negative cuts or cuts deeper than the blade itself
                const clampedCutDepth = Math.max(0, Math.min(110, cutDepth_needed));
                return Math.round(clampedCutDepth);
            });
            
            console.log(`Generated cuts for key "${key.scenarioData.name}":`, cuts);
        }
        
        // If still no cuts, generate from lock configuration
        if (!cuts) {
            // Generate cuts that match the lock's pin configuration
            cuts = generateKeyCutsForLock(key, lockable);
        }
        
        return {
            id: key.scenarioData.key_id,
            name: key.scenarioData.name,
            cuts: cuts,
            pinCount: cuts.length || key.scenarioData.pinCount || 4, // Use cuts length or default to 4 pins
            matchesLock: doesKeyMatchLock(key.scenarioData.key_id, lockId) // Add flag for matching
        };
    });
    
    // Determine which lock configuration to use for this lockable
    // CHANGED: Now get keyPins from scenario instead of predefined configurations
    let lockConfig = null;
    let scenarioKeyPins = null;
    let scenarioDifficulty = null;
    
    // First, try to get keyPins from the lockable's scenario data
    if (lockable?.doorProperties?.keyPins) {
        // This is a door - get keyPins from door properties
        scenarioKeyPins = lockable.doorProperties.keyPins;
        scenarioDifficulty = lockable.doorProperties.difficulty;
        console.log(`✓ Using keyPins from door properties:`, scenarioKeyPins);
    } else if (lockable?.scenarioData?.keyPins) {
        // This is an item - get keyPins from scenario data
        scenarioKeyPins = lockable.scenarioData.keyPins;
        scenarioDifficulty = lockable.scenarioData.difficulty;
        console.log(`✓ Using keyPins from item scenarioData:`, scenarioKeyPins);
    } else if (lockable?.keyPins) {
        // Fallback: keyPins might be stored directly on the object
        scenarioKeyPins = lockable.keyPins;
        scenarioDifficulty = lockable.difficulty;
        console.log(`✓ Using keyPins from lockable object:`, scenarioKeyPins);
    }
    
    // If we have scenario keyPins, use them to build the lock config
    if (scenarioKeyPins && Array.isArray(scenarioKeyPins)) {
        lockConfig = {
            id: lockId,
            pinCount: scenarioKeyPins.length,
            pinHeights: scenarioKeyPins,
            difficulty: scenarioDifficulty || 'medium'
        };
        console.log(`Created lock configuration from scenario keyPins:`, lockConfig);
    } else {
        // Fallback to predefined configurations if no scenario keyPins found
        if (PREDEFINED_LOCK_CONFIGS[lockId]) {
            lockConfig = PREDEFINED_LOCK_CONFIGS[lockId];
            console.log(`Falling back to predefined lock configuration for ${lockId}:`, lockConfig);
        } else {
            // Final fallback to default configuration
            lockConfig = {
                id: lockId,
                pinCount: 4,
                pinHeights: [30, 28, 32, 29],
                difficulty: 'medium'
            };
            console.log(`Using default lock configuration for ${lockId}:`, lockConfig);
        }
    }
    
    // Extract item information from lockable object (handles both items and doors)
    let itemName, itemImage, itemObservations;
    
    // Check if this is a door (has doorProperties) or an item
    if (lockable?.doorProperties) {
        // This is a door - get the connected room name
        const connectedRoomId = lockable.doorProperties.connectedRoom;
        const currentRoomId = lockable.doorProperties.roomId;
        const gameScenario = window.gameScenario;
        const connectedRoom = gameScenario?.rooms?.[connectedRoomId];
        const currentRoom = gameScenario?.rooms?.[currentRoomId];
        const isLocked = lockable.doorProperties.locked;
        
        // Use door_sign if available (player-visible sign on the door)
        const doorSignOrName = connectedRoom?.door_sign || connectedRoom?.name;
        
        // Format item name with locked status
        if (doorSignOrName) {
            // Has door_sign or room name - show it
            itemName = isLocked ? `${doorSignOrName}` : doorSignOrName;
            itemObservations = `Door to ${doorSignOrName}`;
        } else {
            // No door_sign and undiscovered room - use generic names
            itemName = 'Locked door';
            const currentRoomName = currentRoom?.name || currentRoomId;
            itemObservations = `A door leading out of ${currentRoomName}`;
        }
        
        itemImage = 'tiles/door.png'; // Use default door image
    } else {
        // This is a regular item - use scenarioData
        itemName = lockable?.scenarioData?.name || lockable?.name || 'Locked Item';
        itemImage = lockable?.texture?.key ? `/break_escape/assets/objects/${lockable.texture.key}.png` : null;
        itemObservations = lockable?.scenarioData?.observations || '';
    }
    
    // Start the key selection minigame
    window.MinigameFramework.startMinigame('lockpicking', null, {
        keyMode: true,
        skipStartingKey: true,
        lockable: lockable,
        lockId: lockId,
        pinCount: lockConfig.pinCount,
        predefinedPinHeights: lockConfig.pinHeights, // Pass the predefined pin heights
        difficulty: lockConfig.difficulty,
        itemName: itemName,
        itemImage: itemImage,
        itemObservations: itemObservations,
        cancelText: 'Close',
        canSwitchToPickMode: window.inventory.items.some(item => 
            item && item.scenarioData && 
            item.scenarioData.type === 'lockpick'
        ),
        inventoryKeys: keysToShow,
        requiredKeyId: requiredKeyId,
        onComplete: (success, result) => {
            if (success) {
                console.log('KEY SELECTION SUCCESS');
                window.gameAlert('Successfully unlocked with the correct key!', 'success', 'Unlock Successful', 4000);
                // Small delay to ensure minigame cleanup completes before room loading
                if (unlockTargetCallback) {
                    setTimeout(() => {
                        unlockTargetCallback(lockable, type, lockable.layer);
                    }, 100);
                }
            } else {
                console.log('KEY SELECTION FAILED');
                window.gameAlert('The selected key doesn\'t work with this lock.', 'error', 'Wrong Key', 4000);
            }
        }
    });
    
    // Start with key selection using inventory keys
    // Wait for the minigame to be fully initialized and lock configuration to be saved
    setTimeout(() => {
        if (window.MinigameFramework.currentMinigame && window.MinigameFramework.currentMinigame.startWithKeySelection) {
            // DEFERRED KEY PREPARATION:
            // Regenerate keys after minigame initialization to ensure lock config is saved
            const updatedInventoryKeys = playerKeys.map(key => {
                let cuts = key.scenarioData.cuts;
                
                // KEYPIN TO CUT CONVERSION (deferred update):
                // Same as above - convert normalized keyPins (25-65) to cuts for visualization
                // This ensures each key displays its actual unique cut pattern
                if (!cuts && (key.scenarioData.keyPins || key.keyPins)) {
                    const lockKeyPins = key.scenarioData.keyPins || key.keyPins;
                    console.log(`Generating cuts from lock keyPins for key "${key.scenarioData.name}":`, lockKeyPins);
                    
                    // Generate cuts that match this lock configuration
                    cuts = lockKeyPins.map(keyPinLength => {
                        const keyBladeTop_world = 175; // Key blade top position
                        const shearLine_world = 155; // Shear line position  
                        const gapFromKeyBladeTopToShearLine = keyBladeTop_world - shearLine_world; // 20
                        
                        // Calculate the required cut depth
                        const cutDepth_needed = keyPinLength - gapFromKeyBladeTopToShearLine;
                        
                        // Clamp to valid range (0 to 110, which is key blade height)
                        const clampedCutDepth = Math.max(0, Math.min(110, cutDepth_needed));
                        return Math.round(clampedCutDepth);
                    });
                    
                    console.log(`Generated cuts for key "${key.scenarioData.name}":`, cuts);
                }
                
                // If still no cuts, generate from lock configuration
                if (!cuts) {
                    cuts = generateKeyCutsForLock(key, lockable);
                }
                
                return {
                    id: key.scenarioData.key_id,
                    name: key.scenarioData.name,
                    cuts: cuts,
                    pinCount: cuts.length || key.scenarioData.pinCount || 4
                };
            });
            
            window.MinigameFramework.currentMinigame.startWithKeySelection(updatedInventoryKeys, requiredKeyId);
        }
    }, 500);
}

export function startPinMinigame(lockable, type, correctPin, callback) {
    console.log('Starting PIN minigame for', type, 'with PIN:', correctPin);
    
    // Initialize the minigame framework if not already done
    if (!window.MinigameFramework) {
        console.error('MinigameFramework not available');
        // Fallback to simple prompt
        const pinInput = prompt(`Enter PIN code:`);
        if (pinInput === correctPin) {
            console.log('PIN SUCCESS (fallback)');
            window.gameAlert(`Correct PIN! The ${type} is now unlocked.`, 'success', 'PIN Accepted', 4000);
            callback(true);
        } else if (pinInput !== null) {
            console.log('PIN FAIL (fallback)');
            window.gameAlert("Incorrect PIN code.", 'error', 'PIN Rejected', 3000);
            callback(false);
        }
        return;
    }
    
    // Use the advanced minigame framework
    if (!window.MinigameFramework.mainGameScene) {
        window.MinigameFramework.init(window.game);
    }
    
    // Check if we have a pin-cracker in inventory
    const hasPinCracker = window.inventory.items.some(item => 
        item && item.scenarioData && 
        item.scenarioData.type === 'pin-cracker'
    );
    
    console.log('PIN-CRACKER CHECK:', hasPinCracker);
    
    // Start the PIN minigame
    window.MinigameFramework.startMinigame('pin', null, {
        title: `Enter PIN for ${type}`,
        correctPin: correctPin,
        maxAttempts: 3,
        pinLength: correctPin.length,
        hasPinCracker: hasPinCracker,
        allowBackspace: true,
        onComplete: (success, result) => {
            if (success) {
                console.log('PIN MINIGAME SUCCESS');
                window.gameAlert(`Correct PIN! The ${type} is now unlocked.`, 'success', 'PIN Accepted', 4000);
                callback(true);
            } else {
                console.log('PIN MINIGAME FAILED');
                window.gameAlert("Failed to enter correct PIN.", 'error', 'PIN Rejected', 3000);
                callback(false);
            }
        }
    });
}

export function startPasswordMinigame(lockable, type, correctPassword, callback, options = {}) {
    console.log('Starting password minigame for', type, 'with password:', correctPassword);
    
    // Initialize the minigame framework if not already done
    if (!window.MinigameFramework) {
        console.error('MinigameFramework not available');
        // Fallback to simple prompt
        const passwordInput = prompt(`Enter password:`);
        if (passwordInput === correctPassword) {
            console.log('PASSWORD SUCCESS (fallback)');
            window.gameAlert(`Correct password! The ${type} is now unlocked.`, 'success', 'Password Accepted', 4000);
            callback(true);
        } else if (passwordInput !== null) {
            console.log('PASSWORD FAIL (fallback)');
            window.gameAlert("Incorrect password.", 'error', 'Password Rejected', 3000);
            callback(false);
        }
        return;
    }
    
    // Use the advanced minigame framework
    if (!window.MinigameFramework.mainGameScene) {
        window.MinigameFramework.init(window.game);
    }
    
    // Start the password minigame
    window.MinigameFramework.startMinigame('password', null, {
        title: `Enter password for ${type}`,
        password: correctPassword,
        passwordHint: options.passwordHint || '',
        showHint: options.showHint || false,
        showKeyboard: options.showKeyboard || false,
        maxAttempts: options.maxAttempts || 3,
        postitNote: options.postitNote || '',
        showPostit: options.showPostit || false,
        lockable: lockable,
        requiresKeyboardInput: true, // Password minigame needs keyboard for text input
        onComplete: (success, result) => {
            if (success) {
                console.log('PASSWORD MINIGAME SUCCESS');
                window.gameAlert(`Correct password! The ${type} is now unlocked.`, 'success', 'Password Accepted', 4000);
                callback(true);
            } else {
                console.log('PASSWORD MINIGAME FAILED');
                window.gameAlert("Failed to enter correct password.", 'error', 'Password Rejected', 3000);
                callback(false);
            }
        }
    });
}

// Export for global access
window.startLockpickingMinigame = startLockpickingMinigame;
window.startKeySelectionMinigame = startKeySelectionMinigame;
window.startPinMinigame = startPinMinigame;
window.startPasswordMinigame = startPasswordMinigame;

