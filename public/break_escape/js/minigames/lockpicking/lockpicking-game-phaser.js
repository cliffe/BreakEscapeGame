import { MinigameScene } from '../framework/base-minigame.js';
import { LockConfiguration } from './lock-configuration.js';
import { LockGraphics } from './lock-graphics.js';
import { KeyDataGenerator } from './key-data-generator.js';
import { KeySelection } from './key-selection.js';
import { KeyOperations } from './key-operations.js';
import { PinManagement } from './pin-management.js';
import { ToolManager } from './tool-manager.js';
import { KeyAnimation } from './key-animation.js';
import { HookMechanics } from './hook-mechanics.js';
import { PinVisuals } from './pin-visuals.js';
import { KeyInsertion } from './key-insertion.js';
import { KeyDrawing } from './key-drawing.js';
import { KeyPathDrawing } from './key-path-drawing.js';
import { KeyGeometry } from './key-geometry.js';
import { GameUtilities } from './game-utilities.js';

// Phaser Lockpicking Minigame Scene implementation
export class LockpickingMinigamePhaser extends MinigameScene {
    constructor(container, params) {
        super(container, params);
        
        // Ensure params is an object
        params = params || {};
        
        console.log('🎮 Lockpicking minigame constructor received params:', {
            predefinedPinHeights: params.predefinedPinHeights,
            difficulty: params.difficulty,
            pinCount: params.pinCount,
            lockableType: params.lockable?.doorProperties ? 'door' : params.lockable?.scenarioData ? 'item' : 'unknown'
        });
        
        this.lockable = params.lockable || 'default-lock';
        this.lockId = params.lockId || 'default_lock';
        this.difficulty = params.difficulty || 'medium';
        
        // Determine pin count: prioritize based on keyPins array length from scenario
        let pinCount = params.pinCount;
        let predefinedPinHeights = params.predefinedPinHeights;
        
        console.log('🔍 pinCount determination started:', {
            explicitPinCount: pinCount,
            predefinedPinHeights: predefinedPinHeights,
            difficulty: this.difficulty
        });
        
        // If predefinedPinHeights not in params, try to extract from lockable object
        if (!predefinedPinHeights && this.lockable) {
            console.log('🔍 Attempting to extract predefinedPinHeights from lockable object');
            if (this.lockable.doorProperties?.keyPins) {
                predefinedPinHeights = this.lockable.doorProperties.keyPins;
                console.log(`✓ Extracted predefinedPinHeights from lockable.doorProperties:`, predefinedPinHeights);
            } else if (this.lockable.scenarioData?.keyPins) {
                predefinedPinHeights = this.lockable.scenarioData.keyPins;
                console.log(`✓ Extracted predefinedPinHeights from lockable.scenarioData:`, predefinedPinHeights);
            } else if (this.lockable.keyPins) {
                predefinedPinHeights = this.lockable.keyPins;
                console.log(`✓ Extracted predefinedPinHeights from lockable.keyPins:`, predefinedPinHeights);
            } else {
                console.warn('⚠ Could not extract predefinedPinHeights from lockable object');
            }
        }
        
        // Store for use in pin management
        this.params = params;
        this.params.predefinedPinHeights = predefinedPinHeights;
        
        // If pinCount not explicitly provided, derive from predefinedPinHeights (keyPins from scenario)
        if (!pinCount && predefinedPinHeights && Array.isArray(predefinedPinHeights)) {
            pinCount = predefinedPinHeights.length;
            console.log(`✓ Determined pinCount ${pinCount} from predefinedPinHeights array length: [${predefinedPinHeights.join(', ')}]`);
        }
        
        // Fall back to difficulty-based pin count if still not set
        if (!pinCount) {
            pinCount = this.difficulty === 'easy' ? 3 : this.difficulty === 'medium' ? 4 : 5;
            console.log(`⚠ Using difficulty-based pinCount: ${pinCount} (difficulty: ${this.difficulty})`);
        }

        
        this.pinCount = pinCount;
        
        // Initialize global lock storage if it doesn't exist
        if (!window.lockConfigurations) {
            window.lockConfigurations = {};
        }
        
        // Initialize KeyDataGenerator module
        this.keyDataGen = new KeyDataGenerator(this);
        
        // Initialize KeySelection module
        this.keySelection = new KeySelection(this);
        
        // Initialize KeyOperations module
        this.keyOps = new KeyOperations(this);
        
        // Initialize PinManagement module
        this.pinMgmt = new PinManagement(this);
        
        // Initialize ToolManager module
        this.toolMgr = new ToolManager(this);
        
        // Initialize KeyAnimation module
        this.keyAnim = new KeyAnimation(this);
        
        // Initialize HookMechanics module
        this.hookMech = new HookMechanics(this);
        
        // Initialize PinVisuals module
        this.pinVisuals = new PinVisuals(this);
        
        // Initialize KeyInsertion module
        this.keyInsertion = new KeyInsertion(this);
        
        // Initialize KeyDrawing module
        this.keyDraw = new KeyDrawing(this);
        
        // Initialize KeyPathDrawing module
        this.keyPathDraw = new KeyPathDrawing(this);
        
        // Initialize KeyGeometry module
        this.keyGeom = new KeyGeometry(this);
        
        // Initialize GameUtilities module
        this.gameUtil = new GameUtilities(this);
        
        // Also try to load from localStorage for persistence across sessions
        if (!window.lockConfigurations[this.lockId]) {
            try {
                const savedConfigs = localStorage.getItem('lockConfigurations');
                if (savedConfigs) {
                    const parsed = JSON.parse(savedConfigs);
                    window.lockConfigurations = { ...window.lockConfigurations, ...parsed };
                }
            } catch (error) {
                console.warn('Failed to load lock configurations from localStorage:', error);
            }
        }
        
        // Threshold sensitivity for pin setting (1-10, higher = more sensitive)
        this.thresholdSensitivity = params.thresholdSensitivity || 5;
        
        // Whether to highlight binding order
        this.highlightBindingOrder = params.highlightBindingOrder !== undefined ? params.highlightBindingOrder : true;
        
        // Whether to highlight pin alignment (shear line proximity)
        this.highlightPinAlignment = params.highlightPinAlignment !== undefined ? params.highlightPinAlignment : true;
        
        // Lift speed parameter (can be set to fast values, but reasonable default for hard)
        this.liftSpeed = params.liftSpeed || (this.difficulty === 'hard' ? 1.2 : 1);
        
        // Close button customization
        this.closeButtonText = params.cancelText || 'Cancel';
        this.closeButtonAction = params.closeButtonAction || 'close';
        
        // Key mode settings
        this.keyMode = params.keyMode || false;
        this.keyData = params.keyData || null; // Key data with cuts/ridges
        this.keyInsertionProgress = 0; // 0 = not inserted, 1 = fully inserted
        this.keyInserting = false;
        this.skipStartingKey = params.skipStartingKey || false; // Skip creating initial key if true
        this.keySelectionMode = false; // Track if we're in key selection mode
        
        // Mode switching settings
        this.canSwitchToPickMode = params.canSwitchToPickMode || false; // Allow switching from key to pick mode
        this.inventoryKeys = params.inventoryKeys || null; // Stored for mode switching
        this.requirefKeyId = params.requiredKeyId || null; // Track required key ID
        this.canSwitchToKeyMode = params.canSwitchToKeyMode || false; // Allow switching from lockpick to key mode
        this.availableKeys = params.availableKeys || null; // Keys available for mode switching
        
        // Sound effects
        this.sounds = {};
        
        // Track if any pin has been clicked (for hiding labels)
        this.pinClicked = false;
        
        // Log the configuration for debugging
        console.log('Lockpicking minigame config:', {
            lockable: this.lockable,
            difficulty: this.difficulty,
            pinCount: this.pinCount,
            passedPinCount: params.pinCount,
            thresholdSensitivity: this.thresholdSensitivity,
            highlightBindingOrder: this.highlightBindingOrder,
            highlightPinAlignment: this.highlightPinAlignment,
            liftSpeed: this.liftSpeed,
            canSwitchToPickMode: this.canSwitchToPickMode,
            canSwitchToKeyMode: this.canSwitchToKeyMode
        });
        
        this.pins = [];
        this.lockState = {
            tensionApplied: false,
            pinsSet: 0,
            currentPin: null
        };
        
        this.game = null;
        this.scene = null;
        
        // Initialize lock configuration module
        this.lockConfig = new LockConfiguration(this);
        
        // Initialize lock graphics module
        this.lockGraphics = new LockGraphics(this);
    }
    
    // Method to get the lock's pin configuration for key generation
    init() {
        super.init();
        
        // Customize the close button
        const closeBtn = document.getElementById('minigame-close');
        if (closeBtn) {
            closeBtn.textContent = '×';
            
            // Remove the default close action
            this._eventListeners = this._eventListeners.filter(listener => 
                !(listener.element === closeBtn && listener.eventType === 'click')
            );
            
            // Add custom action based on closeButtonAction parameter
            if (this.closeButtonAction === 'reset') {
                this.addEventListener(closeBtn, 'click', () => {
                    this.pinMgmt.resetAllPins();
                    this.keyInsertion.updateFeedback("Lock reset - try again");
                });
            } else {
                // Default close action
                this.addEventListener(closeBtn, 'click', () => {
                    this.complete(false);
                });
            }
        }
        
        // Customize the cancel button
        const cancelBtn = document.getElementById('minigame-cancel');
        if (cancelBtn) {
            cancelBtn.textContent = this.closeButtonText;
            
            // Remove the default cancel action
            this._eventListeners = this._eventListeners.filter(listener => 
                !(listener.element === cancelBtn && listener.eventType === 'click')
            );
            
            // Add custom action based on closeButtonAction parameter
            if (this.closeButtonAction === 'reset') {
                this.addEventListener(cancelBtn, 'click', () => {
                    this.pinMgmt.resetAllPins();
                    this.keyInsertion.updateFeedback("Lock reset - try again");
                });
            } else {
                // Default cancel action
                this.addEventListener(cancelBtn, 'click', () => {
                    this.complete(false);
                });
            }
        }
        
        this.headerElement.innerHTML = `
            <h3>Lockpicking</h3>
            <p>Apply tension and hold click on pins to lift them to the shear line</p>
        `;
        
        // Create the lockable item display section if item info is provided
        this.createLockableItemDisplay();
        
        this.setupPhaserGame();
    }
    
    createLockableItemDisplay() {
        // Create display for the locked item (door, chest, etc.)
        const itemName = this.params?.itemName || this.lockable || 'Locked Item';
        const itemImage = this.params?.itemImage || null;
        const itemObservations = this.params?.itemObservations || '';
        
        if (!itemImage) return; // Only create if image is provided
        
        // Create container for the item display
        const itemDisplayDiv = document.createElement('div');
        itemDisplayDiv.className = 'lockpicking-item-section';
        itemDisplayDiv.innerHTML = `
            <img src="${itemImage}" 
                 alt="${itemName}" 
                 class="lockpicking-item-image">
            <div class="lockpicking-item-info">
                <h4>${itemName}</h4>
                <p>${itemObservations}</p>
            </div>
        `;
        
        // Add mode switch button if applicable
        if (this.canSwitchToPickMode && this.keyMode) {
            const buttonContainer = document.createElement('div');
            buttonContainer.style.cssText = `
                display: flex;
                gap: 10px;
                margin-top: 10px;
                justify-content: center;
            `;
            
            const switchModeBtn = document.createElement('button');
            switchModeBtn.className = 'minigame-button';
            switchModeBtn.id = 'lockpicking-switch-mode-btn';
            switchModeBtn.innerHTML = '<img src="assets/objects/lockpick.png" alt="Lockpick" class="icon-large"> Switch to Lockpicking';
            switchModeBtn.onclick = () => this.toolMgr.switchToPickMode();
            
            buttonContainer.appendChild(switchModeBtn);
            itemDisplayDiv.appendChild(buttonContainer);
        } else if (this.canSwitchToKeyMode && !this.keyMode) {
            // Show switch to key mode button when in lockpicking mode
            const buttonContainer = document.createElement('div');
            buttonContainer.style.cssText = `
                display: flex;
                gap: 10px;
                margin-top: 10px;
                justify-content: center;
            `;
            
            const switchModeBtn = document.createElement('button');
            switchModeBtn.className = 'minigame-button';
            switchModeBtn.id = 'lockpicking-switch-to-keys-btn';
            switchModeBtn.innerHTML = '<img src="assets/objects/key.png" alt="Key" class="icon-large"> Switch to Key Mode';
            switchModeBtn.onclick = () => this.toolMgr.switchToKeyMode();
            
            buttonContainer.appendChild(switchModeBtn);
            itemDisplayDiv.appendChild(buttonContainer);
        }
        
        // Insert before the game container
        this.gameContainer.parentElement.insertBefore(itemDisplayDiv, this.gameContainer);
    }
    
    setupPhaserGame() {
        // Create a container for the Phaser game
        this.gameContainer.innerHTML = `
            <div class="phaser-game-container" id="phaser-game-container"></div>
        `;
        
        // Create feedback element in the minigame container
        this.feedback = document.createElement('div');
        this.feedback.className = 'lockpick-feedback';
        this.gameContainer.appendChild(this.feedback);
        
        console.log('Setting up Phaser game...');
        
        // Create a custom Phaser scene
        const self = this;
        class LockpickingScene extends Phaser.Scene {
            constructor() {
                super({ key: 'LockpickingScene' });
            }
            
            preload() {
                // Load sound effects
                this.load.audio('lockpick_binding', 'assets/sounds/lockpick_binding.mp3');
                this.load.audio('lockpick_click', 'assets/sounds/lockpick_click.mp3');
                this.load.audio('lockpick_overtension', 'assets/sounds/lockpick_overtension.mp3');
                this.load.audio('lockpick_reset', 'assets/sounds/lockpick_reset.mp3');
                this.load.audio('lockpick_set', 'assets/sounds/lockpick_set.mp3');
                this.load.audio('lockpick_success', 'assets/sounds/lockpick_success.mp3');
                this.load.audio('lockpick_tension', 'assets/sounds/lockpick_tension.mp3');
                this.load.audio('lockpick_wrong', 'assets/sounds/lockpick_wrong.mp3');
            }
            
            create() {
                console.log('Phaser scene create() called');
                // Store reference to the scene
                self.scene = this;
                
                // Initialize sound effects
                self.sounds.binding = this.sound.add('lockpick_binding');
                self.sounds.click = this.sound.add('lockpick_click');
                self.sounds.overtension = this.sound.add('lockpick_overtension');
                self.sounds.reset = this.sound.add('lockpick_reset');
                self.sounds.set = this.sound.add('lockpick_set');
                self.sounds.success = this.sound.add('lockpick_success');
                self.sounds.tension = this.sound.add('lockpick_tension');
                self.sounds.wrong = this.sound.add('lockpick_wrong');
                
                // Create game elements
                self.lockGraphics.createLockBackground();
                self.lockGraphics.createTensionWrench();
                self.pinMgmt.createPins();
                self.lockGraphics.createHookPick();
                self.pinMgmt.createShearLine();
                
                // Create key if in key mode and not skipping starting key
                if (self.keyMode && !self.skipStartingKey) {
                    self.keyOps.createKey();
                    self.toolMgr.hideLockpickingTools();
                    self.keyInsertion.updateFeedback("Click the key to insert it into the lock");
                } else if (self.keyMode && self.skipStartingKey) {
                    // Skip creating initial key, will show key selection instead
                    // But we still need to initialize keyData for the correct key
                    if (!self.keyData) {
                        self.keyDataGen.generateKeyDataFromPins();
                    }
                    self.toolMgr.hideLockpickingTools();
                    self.keyInsertion.updateFeedback("Select a key to begin");
                } else {
                    self.keyInsertion.updateFeedback("Apply tension first, then lift pins in binding order - only the binding pin can be set");
                }
                
                self.pinMgmt.setupInputHandlers();
                console.log('Phaser scene setup complete');
            }
            
            update() {
                if (self.update) {
                    self.update();
                }
            }
        }
        
        // Initialize Phaser game
        const config = {
            type: Phaser.AUTO,
            parent: 'phaser-game-container',
            width: 600,
            height: 400,
            backgroundColor: '#1a1a1a',
            scene: LockpickingScene
        };
        
        // Adjust canvas size for mobile to crop empty space
        if (window.innerWidth <= 768) {
            // Crop the viewport to focus on the lock area
            // Lock is positioned from x=100 to x=500, y=50 to y=350
            // So we can crop to roughly x=80 to x=520, y=30 to y=370
            const cropWidth = 510; // 520 - 80
            const cropHeight = 300; // 370 - 30
            
            // Calculate scale to fit the cropped area
            const containerWidth = document.getElementById('phaser-game-container').offsetWidth;
            const containerHeight = document.getElementById('phaser-game-container').offsetHeight;
            
            // Scale to fit the cropped area within the container
            const scaleX = containerWidth / cropWidth;
            const scaleY = containerHeight / cropHeight;
            const scale = Math.min(scaleX, scaleY);
            
            config.width = cropWidth;
            config.height = cropHeight;
            config.scale = {
                mode: Phaser.Scale.FIT,
                autoCenter: Phaser.Scale.CENTER_BOTH
            };
        }
        
        try {
            this.game = new Phaser.Game(config);
            this.scene = this.game.scene.getScene('LockpickingScene');
            console.log('Phaser game created, scene:', this.scene);
        } catch (error) {
            console.error('Error creating Phaser game:', error);
            this.keyInsertion.updateFeedback('Error loading Phaser game: ' + error.message);
        }
    }
    
    
    startWithKeySelection(inventoryKeys = null, correctKeyId = null) {
        // Start the minigame with key selection instead of a default key
        // inventoryKeys: array of keys from inventory (optional)
        // correctKeyId: ID of the correct key (optional)
        
        this.keySelectionMode = true; // Mark that we're in key selection mode
        
        if (inventoryKeys && inventoryKeys.length > 0) {
            // Use provided inventory keys
            this.keySelection.createKeysFromInventory(inventoryKeys, correctKeyId);
        } else {
            // Generate random keys for challenge
            this.keySelection.createKeysForChallenge(correctKeyId || 'challenge_key');
        }
    }
    
    createKeyBladeCollision() {
        // Method moved to KeyOperations module - call via this.keyOps.createKeyBladeCollision()
        this.keyOps.createKeyBladeCollision();
    }
    
    update() {
        // Skip normal lockpicking logic if in key mode
        if (this.keyMode) {
            return;
        }
        
        if (this.lockState.currentPin && this.gameState.mouseDown) {
            this.pinMgmt.liftPin();
        }
        
        // Apply gravity when tension is not applied (but not when actively lifting)
        if (!this.lockState.tensionApplied && !this.gameState.mouseDown) {
            this.pinMgmt.applyGravity();
        }
        
        // Apply gravity to non-binding pins even with tension
        if (this.lockState.tensionApplied && !this.gameState.mouseDown) {
            this.pinMgmt.applyGravity();
        }
        
        // Check if all pins are correctly positioned when tension is applied
        if (this.lockState.tensionApplied) {
            this.pinMgmt.checkAllPinsCorrect();
        }
        
        // Hook return is now handled directly in pointerup event
    }
    
    complete(success) {
        if (this.game) {
            this.game.destroy(true);
            this.game = null;
        }
        super.complete(success, this.gameResult);
    }
    
} 