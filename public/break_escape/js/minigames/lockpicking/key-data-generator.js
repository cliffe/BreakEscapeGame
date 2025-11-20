
/**
 * KeyDataGenerator
 * 
 * Extracted from lockpicking-game-phaser.js
 * Instantiate with: new KeyDataGenerator(this)
 * 
 * All 'this' references replaced with 'this.parent' to access parent instance state:
 * - this.parent.pins (array of pin objects)
 * - this.parent.scene (Phaser scene)
 * - this.parent.lockId (lock identifier)
 * - this.parent.lockState (lock state object)
 * etc.
 */
export class KeyDataGenerator {
    
    constructor(parent) {
        this.parent = parent;
    }

    generateKeyDataFromPins() {
        // Generate key cuts based on actual pin heights
        // Calculate cut depths so that when key is inserted, pins align at shear line
        const cuts = [];
        const shearLineY = -45; // Shear line position (in pin container coordinates)
        const keyBladeHeight = 110; // Key blade height (from keyConfig)
        const pinContainerY = 200; // Pin container Y position (world coordinates)
        
        for (let i = 0; i < this.parent.pinCount; i++) {
            const pin = this.parent.pins[i];
            const keyPinLength = pin.keyPinLength;
            
            // Simple key cut calculation:
            // The cut depth should be the key pin length minus the gap from key blade top to shear line
            
            // Key blade is centered in keyway: keywayStartY + keywayHeight/2 = 170 + 60 = 230
            // Key blade top is: 230 - keyBladeHeight/2 = 230 - 55 = 175
            // Shear line is at y=155 in world coordinates (200 - 45)
            const keyBladeTop_world = 175; // 170 + 60 - 55 (keywayStartY + keywayHeight/2 - keyBladeHeight/2)
            const shearLine_world = 155; // 200 - 45 (pin container Y - shear line Y)
            const gapFromKeyBladeTopToShearLine = keyBladeTop_world - shearLine_world; // 175 - 155 = 20
            
            // Cut depth = key pin length - gap from key blade top to shear line
            const cutDepth_needed = keyPinLength - gapFromKeyBladeTopToShearLine;
            
            // Clamp to valid range (0 to key blade height)
            const clampedCutDepth = Math.max(0, Math.min(keyBladeHeight, cutDepth_needed));
            
            console.log(`=== KEY CUT ${i} GENERATION ===`);
            console.log(`  Pin properties: keyPinLength=${keyPinLength}, driverPinLength=${pin.driverPinLength}`);
            console.log(`  Key blade top: ${keyBladeTop_world}, shear line: ${shearLine_world}`);
            console.log(`  Gap from key blade top to shear line: ${gapFromKeyBladeTopToShearLine}`);
            console.log(`  Cut calculation: cutDepth_needed=${cutDepth_needed} (${keyPinLength} - ${gapFromKeyBladeTopToShearLine})`);
            console.log(`  Final cut: cutDepth=${clampedCutDepth}px (max ${keyBladeHeight}px)`);
            console.log(`=====================================`);
            
            cuts.push(clampedCutDepth);
        }
        
        this.parent.keyData = { cuts: cuts };
        console.log('Generated key data from pins:', this.parent.keyData);
    }
    
}
