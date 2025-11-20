/**
 * BIOMETRICS SYSTEM
 * =================
 * 
 * Handles fingerprint collection and biometric scanning functionality.
 * Includes dusting minigame integration and biometric sample management.
 */

import { INTERACTION_RANGE_SQ } from '../utils/constants.js';

// Fingerprint collection function
export function collectFingerprint(item) {
    if (!item.scenarioData?.hasFingerprint) {
        window.gameAlert("No fingerprints found on this surface.", 'info', 'No Fingerprints', 3000);
        return null;
    }
    
    // Start the dusting minigame
    startDustingMinigame(item);
    return true;
}

// Handle biometric scanner interaction
export function handleBiometricScan(sprite) {
    const player = window.player;
    if (!player) return;
    
    // Check if player is in range
    const dx = player.x - sprite.x;
    const dy = player.y - sprite.y;
    const distanceSq = dx * dx + dy * dy;
    
    if (distanceSq > INTERACTION_RANGE_SQ) {
        window.gameAlert('You need to be closer to use the biometric scanner.', 'warning', 'Too Far', 3000);
        return;
    }
    
    // Show biometric authentication interface
    window.gameAlert('Place your finger on the scanner...', 'info', 'Biometric Scan', 2000);
    
    // Simulate biometric scan process
    setTimeout(() => {
        // For now, just show a message - can be enhanced with actual authentication logic
        window.gameAlert('Biometric scan complete.', 'success', 'Scan Complete', 3000);
    }, 2000);
}

// Start fingerprint dusting minigame
export function startDustingMinigame(item) {
    console.log('Starting dusting minigame for item:', item);
    
    // Check if MinigameFramework is available
    if (!window.MinigameFramework) {
        console.error('MinigameFramework not available - using fallback');
        // Fallback to simple collection
        window.gameAlert('Collecting fingerprint sample...', 'info', 'Dusting', 2000);
        
        setTimeout(() => {
            const quality = 0.7 + Math.random() * 0.3;
            const rating = quality >= 0.9 ? 'Excellent' : 
                          quality >= 0.8 ? 'Good' : 
                          quality >= 0.7 ? 'Fair' : 'Poor';
            
            if (!window.gameState) {
                window.gameState = { biometricSamples: [] };
            }
            if (!window.gameState.biometricSamples) {
                window.gameState.biometricSamples = [];
            }
            
            const sample = {
                id: `sample_${Date.now()}`,
                type: 'fingerprint',
                owner: item.scenarioData.fingerprintOwner || 'Unknown',
                quality: quality,
                data: generateFingerprintData(item),
                timestamp: Date.now()
            };
            
            window.gameState.biometricSamples.push(sample);
            
            if (item.scenarioData) {
                item.scenarioData.hasFingerprint = false;
            }
            
            if (window.updateBiometricsPanel) {
                window.updateBiometricsPanel();
            }
            if (window.updateBiometricsCount) {
                window.updateBiometricsCount();
            }
            
            window.gameAlert(`Collected ${sample.owner}'s fingerprint sample (${rating} quality)`, 'success', 'Sample Acquired', 4000);
        }, 2000);
        return;
    }
    
    // Initialize the framework if not already done
    if (!window.MinigameFramework.mainGameScene) {
        window.MinigameFramework.init(window.game);
    }
    
    // Add scene reference to item for the minigame  
    item.scene = window.game;
    
    // Start the dusting minigame
    window.MinigameFramework.startMinigame('dusting', null, {
        item: item,
        scene: item.scene,
        onComplete: (success, result) => {
            if (success) {
                console.log('DUSTING SUCCESS', result);
                
                // Add fingerprint to gameState
                if (!window.gameState) {
                    window.gameState = { biometricSamples: [] };
                }
                if (!window.gameState.biometricSamples) {
                    window.gameState.biometricSamples = [];
                }
                
                const sample = {
                    id: generateFingerprintData(item),
                    type: 'fingerprint',
                    owner: item.scenarioData.fingerprintOwner || 'Unknown',
                    quality: result.quality, // Quality between 0.7 and ~1.0
                    data: generateFingerprintData(item),
                    timestamp: Date.now()
                };
                
                window.gameState.biometricSamples.push(sample);
                
                // Mark item as collected
                if (item.scenarioData) {
                    item.scenarioData.hasFingerprint = false;
                }
                
                // Update the biometrics panel and count
                if (window.updateBiometricsPanel) {
                    window.updateBiometricsPanel();
                }
                if (window.updateBiometricsCount) {
                    window.updateBiometricsCount();
                }
                
                // Show notification
                window.gameAlert(`Collected ${sample.owner}'s fingerprint sample (${result.rating} quality)`, 'success', 'Sample Acquired', 4000);
            } else {
                console.log('DUSTING FAILED');
                window.gameAlert(`Failed to collect the fingerprint sample.`, 'error', 'Dusting Failed', 4000);
            }
        }
    });
}

// Generate fingerprint data
export function generateFingerprintData(item) {
    const owner = item.scenarioData?.fingerprintOwner || 'Unknown';
    const timestamp = Date.now();
    return `${owner}_${timestamp}_${Math.random().toString(36).substr(2, 9)}`;
}

// Export for global access
window.collectFingerprint = collectFingerprint;
window.handleBiometricScan = handleBiometricScan;
window.startDustingMinigame = startDustingMinigame;
window.generateFingerprintData = generateFingerprintData;

