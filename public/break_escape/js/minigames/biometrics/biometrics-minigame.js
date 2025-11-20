import { MinigameScene } from '../framework/base-minigame.js';

// Biometrics Minigame Scene implementation
export class BiometricsMinigame extends MinigameScene {
    constructor(container, params) {
        // Ensure params is defined before calling parent constructor
        params = params || {};
        
        // Set default title if not provided
        params.title = 'Biometric Scanner';
        
        // Enable cancel button for biometrics minigame with custom text
        params.showCancel = true;
        params.cancelText = 'Close Scanner';
        
        super(container, params);
        
        this.item = params.item;
        this.biometricSamples = [];
        this.searchingMode = false;
        this.highlightedObjects = [];
        
        // Scanner state management
        this.scannerState = {
            failedAttempts: {},
            lockoutTimers: {}
        };
        
        // Constants
        this.MAX_FAILED_ATTEMPTS = 3;
        this.SCANNER_LOCKOUT_TIME = 30000; // 30 seconds
        this.BIOMETRIC_QUALITY_THRESHOLD = 0.7;
    }
    
    init() {
        // Call parent init to set up common components
        super.init();
        
        console.log("Biometrics minigame initializing");
        
        // Set container dimensions to be compact like the Bluetooth scanner
        this.container.className += ' biometrics-minigame-container';
        
        // Clear header content
        this.headerElement.innerHTML = '';
        
        // Configure game container with scanner background
        this.gameContainer.className += ' biometrics-minigame-game-container';
        
        // Create scanner interface
        this.createScannerInterface();
        
        // Initialize biometric samples from global state
        this.initializeBiometricSamples();
    }
    
    createScannerInterface() {
        // Create expand/collapse toggle button
        const expandToggle = document.createElement('div');
        expandToggle.className = 'biometrics-expand-toggle';
        expandToggle.innerHTML = '▼';
        expandToggle.title = 'Expand/Collapse';
        
        // Create scanner header
        const scannerHeader = document.createElement('div');
        scannerHeader.className = 'biometrics-scanner-header';
        scannerHeader.innerHTML = `
            <div class="biometrics-scanner-title">
                <img src="assets/objects/fingerprint.png" alt="Biometric Samples" class="scanner-icon">
                <span>Biometric Samples</span>
                <span class="samples-count-header">0 samples</span>
            </div>
            <div class="biometrics-scanner-status">
                <div class="scanner-indicator active"></div>
                <span>Ready</span>
            </div>
        `;
        
        // Create search room button (above samples list)
        const searchRoomContainer = document.createElement('div');
        searchRoomContainer.className = 'biometrics-search-room-container';
        searchRoomContainer.innerHTML = `
            <button id="search-room-btn" class="biometrics-action-btn">
                <span class="btn-icon"><img src="assets/icons/search.png" alt="Search" class="icon"></span>
                <span class="btn-text">Search Room for Fingerprints</span>
            </button>
        `;
        
        // Create controls container (for expanded view)
        const controlsContainer = document.createElement('div');
        controlsContainer.className = 'biometrics-scanner-controls';
        controlsContainer.innerHTML = `
            <div class="biometrics-search-container">
                <input type="text" id="biometrics-search" placeholder="Search samples..." class="biometrics-search-input">
            </div>
            <div class="biometrics-categories">
                <div class="biometrics-category active" data-category="all">All</div>
                <div class="biometrics-category" data-category="fingerprint">Fingerprints</div>
            </div>
        `;
        
        // Create samples list container
        const samplesListContainer = document.createElement('div');
        samplesListContainer.className = 'biometrics-samples-list-container';
        samplesListContainer.innerHTML = `
            <div class="biometrics-samples-list-header">
                <span>Collected Samples</span>
                <div class="samples-count">0 samples</div>
            </div>
            <div class="biometrics-samples-list" id="biometrics-samples-list"></div>
        `;
        
        // Create instructions
        const instructionsContainer = document.createElement('div');
        instructionsContainer.className = 'biometrics-scanner-instructions';
        instructionsContainer.innerHTML = `
            <div class="instruction-text">
                <strong>Instructions:</strong><br>
                • Use "Search Room" to highlight objects with fingerprints<br>
                • Click highlighted objects to collect fingerprint samples<br>
                • Collected samples can be used to unlock biometric scanners<br>
                • Higher quality samples have better success rates
            </div>
        `;
        
        // Assemble the interface
        this.gameContainer.appendChild(expandToggle);
        this.gameContainer.appendChild(searchRoomContainer);
        this.gameContainer.appendChild(scannerHeader);
        this.gameContainer.appendChild(controlsContainer);
        this.gameContainer.appendChild(samplesListContainer);
        this.gameContainer.appendChild(instructionsContainer);
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Set up expand/collapse functionality
        this.setupExpandToggle(expandToggle);
    }
    
    setupEventListeners() {
        // Search functionality
        const biometricsSearch = document.getElementById('biometrics-search');
        if (biometricsSearch) {
            this.addEventListener(biometricsSearch, 'input', () => this.updateBiometricsPanel());
        }
        
        // Category filters
        const categories = this.gameContainer.querySelectorAll('.biometrics-category');
        categories.forEach(category => {
            this.addEventListener(category, 'click', () => {
                // Remove active class from all categories
                categories.forEach(c => c.classList.remove('active'));
                // Add active class to clicked category
                category.classList.add('active');
                // Update biometrics panel
                this.updateBiometricsPanel();
            });
        });
        
        // Search room button
        const searchRoomBtn = document.getElementById('search-room-btn');
        if (searchRoomBtn) {
            this.addEventListener(searchRoomBtn, 'click', () => this.toggleRoomSearching());
        }
    }
    
    setupExpandToggle(expandToggle) {
        this.addEventListener(expandToggle, 'click', () => {
            const isExpanded = this.container.classList.contains('expanded');
            
            if (isExpanded) {
                // Collapse
                this.container.classList.remove('expanded');
                expandToggle.innerHTML = '▼';
                expandToggle.title = 'Expand';
            } else {
                // Expand
                this.container.classList.add('expanded');
                expandToggle.innerHTML = '▲';
                expandToggle.title = 'Collapse';
            }
        });
    }
    
    initializeBiometricSamples() {
        // Initialize from global state if available
        if (window.gameState && window.gameState.biometricSamples) {
            this.biometricSamples = [...window.gameState.biometricSamples];
        } else {
            this.biometricSamples = [];
        }
        
        // Update the panel
        this.updateBiometricsPanel();
    }
    
    toggleRoomSearching() {
        this.searchingMode = !this.searchingMode;
        const searchBtn = document.getElementById('search-room-btn');
        
        if (this.searchingMode) {
            // Start searching mode
            searchBtn.classList.add('active');
            searchBtn.querySelector('.btn-text').textContent = 'Stop Searching';
            this.highlightFingerprintObjects();
            console.log('Room searching started');
        } else {
            // Stop searching mode
            searchBtn.classList.remove('active');
            searchBtn.querySelector('.btn-text').textContent = 'Search Room for Fingerprints';
            this.clearHighlights();
            console.log('Room searching stopped');
        }
    }
    
    highlightFingerprintObjects() {
        // Clear existing highlights
        this.clearHighlights();
        
        // Find all objects in the current room that have fingerprints
        if (!window.currentPlayerRoom || !window.rooms[window.currentPlayerRoom] || !window.rooms[window.currentPlayerRoom].objects) {
            return;
        }
        
        const room = window.rooms[window.currentPlayerRoom];
        this.highlightedObjects = [];
        
        Object.values(room.objects).forEach(obj => {
            if (obj.scenarioData?.hasFingerprint === true) {
                // Add red highlight effect to the object
                if (obj.setTint) {
                    obj.setTint(0xff0000); // Red tint for fingerprint objects
                    this.highlightedObjects.push(obj);
                }
                
                // Add a visual indicator
                this.addFingerprintIndicator(obj);
            }
        });
        
        if (this.highlightedObjects.length > 0) {
            console.log(`Highlighted ${this.highlightedObjects.length} objects with fingerprints`);
        } else {
            console.log('No objects with fingerprints found in this room');
        }
    }
    
    addFingerprintIndicator(obj) {
        // Create a fingerprint image indicator directly over the object
        if (obj.scene && obj.scene.add) {
            const indicator = obj.scene.add.image(obj.x, obj.y, 'fingerprint');
            indicator.setDepth(1000); // High depth to appear on top
            indicator.setOrigin(-0.25, 0);
            // indicator.setScale(0.5); // Make it smaller
            indicator.setTint(0xff0000); // Red tint
            
            // Add pulsing animation
            obj.scene.tweens.add({
                targets: indicator,
                alpha: { from: 1, to: 0.3 },
                duration: 1000,
                yoyo: true,
                repeat: -1
            });
            
            // Store reference for cleanup
            obj.fingerprintIndicator = indicator;
        }
    }
    
    clearHighlights() {
        // Remove highlights from all objects
        this.highlightedObjects.forEach(obj => {
            if (obj.clearTint) {
                obj.clearTint();
            }
            if (obj.fingerprintIndicator) {
                obj.fingerprintIndicator.destroy();
                delete obj.fingerprintIndicator;
            }
        });
        this.highlightedObjects = [];
    }
    
    collectFingerprintFromObject(obj) {
        if (!obj.scenarioData) return;
        
        // Use the fingerprint owner if specified, otherwise use the object's name
        const owner = obj.scenarioData.fingerprintOwner || obj.scenarioData.name || obj.scenarioData.owner || 'Unknown';
        
        // Generate fingerprint sample with quality based on difficulty
        let quality = obj.scenarioData.fingerprintQuality;
        if (!quality) {
            // Generate quality based on difficulty
            const difficulty = obj.scenarioData.fingerprintDifficulty;
            if (difficulty === 'easy') {
                quality = 0.8 + Math.random() * 0.2; // 80-100%
            } else if (difficulty === 'medium') {
                quality = 0.6 + Math.random() * 0.3; // 60-90%
            } else if (difficulty === 'hard') {
                quality = 0.4 + Math.random() * 0.3; // 40-70%
            } else {
                quality = 0.6 + Math.random() * 0.4; // 60-100% default
            }
        }
        
        const sample = this.generateFingerprintSample(owner, quality);
        
        // Add to collection
        this.addBiometricSample(sample);
        
        // Remove highlight from this object
        if (obj.clearTint) {
            obj.clearTint();
        }
        if (obj.fingerprintIndicator) {
            obj.fingerprintIndicator.destroy();
            delete obj.fingerprintIndicator;
        }
        
        // Remove from highlighted objects
        const index = this.highlightedObjects.indexOf(obj);
        if (index > -1) {
            this.highlightedObjects.splice(index, 1);
        }
        
        // Show success message
        if (window.gameAlert) {
            window.gameAlert(`Fingerprint collected from ${owner} (${sample.rating})`, 'success', 'Sample Collected', 3000);
        }
        
        console.log('Fingerprint collected:', sample);
    }
    
    generateFingerprintSample(owner, quality = null) {
        // If no quality provided, generate based on random factors
        if (quality === null) {
            quality = 0.6 + (Math.random() * 0.4); // 60-100% quality range
        }
        
        const rating = this.getRatingFromQuality(quality);
        
        return {
            owner: owner || 'Unknown',
            type: 'fingerprint',
            quality: quality,
            rating: rating,
            id: this.generateSampleId(),
            collectedAt: new Date().toISOString()
        };
    }
    
    getRatingFromQuality(quality) {
        const qualityPercentage = Math.round(quality * 100);
        if (qualityPercentage >= 95) return 'Perfect';
        if (qualityPercentage >= 85) return 'Excellent';
        if (qualityPercentage >= 75) return 'Good';
        if (qualityPercentage >= 60) return 'Fair';
        if (qualityPercentage >= 40) return 'Acceptable';
        return 'Poor';
    }
    
    generateSampleId() {
        return 'sample_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }
    
    addBiometricSample(sample) {
        // Check if sample already exists
        const existingSample = this.biometricSamples.find(s => 
            s.owner === sample.owner && s.type === sample.type
        );
        
        if (existingSample) {
            // Update existing sample with better quality if applicable
            if (sample.quality > existingSample.quality) {
                existingSample.quality = sample.quality;
                existingSample.rating = sample.rating;
                existingSample.collectedAt = sample.collectedAt;
            }
        } else {
            // Add new sample
            this.biometricSamples.push(sample);
        }
        
        this.updateBiometricsPanel();
        this.syncBiometricSamples();
        console.log('Biometric sample added:', sample);
    }
    
    updateBiometricsPanel() {
        const biometricsContent = document.getElementById('biometrics-samples-list');
        if (!biometricsContent) return;
        
        const searchTerm = document.getElementById('biometrics-search')?.value?.toLowerCase() || '';
        const activeCategory = this.gameContainer.querySelector('.biometrics-category.active')?.dataset.category || 'all';
        
        // Filter samples based on search and category
        let filteredSamples = [...this.biometricSamples];
        
        // Apply category filter
        if (activeCategory === 'fingerprint') {
            filteredSamples = filteredSamples.filter(sample => sample.type === 'fingerprint');
        }
        
        // Apply search filter
        if (searchTerm) {
            filteredSamples = filteredSamples.filter(sample => 
                sample.owner.toLowerCase().includes(searchTerm) || 
                sample.type.toLowerCase().includes(searchTerm)
            );
        }
        
        // Sort samples by quality (highest first)
        filteredSamples.sort((a, b) => b.quality - a.quality);
        
        // Update samples count in both header and list
        const samplesCount = this.gameContainer.querySelector('.samples-count');
        const samplesCountHeader = this.gameContainer.querySelector('.samples-count-header');
        const totalSamples = this.biometricSamples.length;
        
        if (samplesCount) {
            samplesCount.textContent = `${filteredSamples.length} sample${filteredSamples.length !== 1 ? 's' : ''}`;
        }
        
        if (samplesCountHeader) {
            samplesCountHeader.textContent = `${totalSamples} sample${totalSamples !== 1 ? 's' : ''}`;
        }
        
        // Clear current content
        biometricsContent.innerHTML = '';
        
        // Add samples
        if (filteredSamples.length === 0) {
            if (searchTerm) {
                biometricsContent.innerHTML = '<div class="sample-item">No samples match your search.</div>';
            } else if (activeCategory !== 'all') {
                biometricsContent.innerHTML = `<div class="sample-item">No ${activeCategory} samples found.</div>`;
            } else {
                biometricsContent.innerHTML = '<div class="sample-item">No samples collected yet. Use "Search Room" to find fingerprint objects.</div>';
            }
        } else {
            filteredSamples.forEach(sample => {
                const sampleElement = document.createElement('div');
                sampleElement.className = 'sample-item';
                sampleElement.dataset.id = sample.id || 'unknown';
                
                const owner = sample.owner || 'Unknown';
                const type = sample.type || 'fingerprint';
                const quality = sample.quality || 0;
                const rating = sample.rating || this.getRatingFromQuality(quality);
                const collectedAt = sample.collectedAt || new Date().toISOString();
                
                const qualityPercentage = Math.round(quality * 100);
                const timestamp = new Date(collectedAt);
                const formattedTime = timestamp.toLocaleDateString() + ' ' + timestamp.toLocaleTimeString();
                
                sampleElement.innerHTML = `
                    <div class="sample-header">
                        <strong>${owner}</strong>
                        <span class="sample-type">${type}</span>
                    </div>
                    <div class="sample-details">
                        <span class="sample-quality quality-${rating.toLowerCase()}">${rating} (${qualityPercentage}%)</span>
                        <span class="sample-date">${formattedTime}</span>
                    </div>
                `;
                
                biometricsContent.appendChild(sampleElement);
            });
        }
    }
    
    syncBiometricSamples() {
        if (!window.gameState) {
            window.gameState = {};
        }
        window.gameState.biometricSamples = this.biometricSamples;
    }
    
    // Handle biometric scanner interaction (for unlocking doors, etc.)
    handleBiometricScan(scannerId, requiredOwner) {
        console.log('Biometric scan requested:', { scannerId, requiredOwner });
        
        // Check if scanner is locked out
        if (this.scannerState.lockoutTimers[scannerId]) {
            const lockoutEnd = this.scannerState.lockoutTimers[scannerId];
            const now = Date.now();
            
            if (now < lockoutEnd) {
                const remainingTime = Math.ceil((lockoutEnd - now) / 1000);
                if (window.gameAlert) {
                    window.gameAlert(`Scanner locked out. Try again in ${remainingTime} seconds.`, 'error', 'Scanner Locked', 3000);
                }
                return false;
            } else {
                // Lockout expired, clear it
                delete this.scannerState.lockoutTimers[scannerId];
                delete this.scannerState.failedAttempts[scannerId];
            }
        }
        
        // Check if we have a matching biometric sample
        const matchingSample = this.biometricSamples.find(sample => 
            sample.owner === requiredOwner && sample.quality >= this.BIOMETRIC_QUALITY_THRESHOLD
        );
        
        if (matchingSample) {
            console.log('Biometric scan successful:', matchingSample);
            
            if (window.gameAlert) {
                window.gameAlert(`Biometric scan successful! Authenticated as ${requiredOwner}.`, 'success', 'Scan Successful', 4000);
            }
            
            // Reset failed attempts on success
            delete this.scannerState.failedAttempts[scannerId];
            
            return true;
        } else {
            console.log('Biometric scan failed');
            this.handleScannerFailure(scannerId);
            return false;
        }
    }
    
    handleScannerFailure(scannerId) {
        // Initialize failed attempts if not exists
        if (!this.scannerState.failedAttempts[scannerId]) {
            this.scannerState.failedAttempts[scannerId] = 0;
        }
        
        // Increment failed attempts
        this.scannerState.failedAttempts[scannerId]++;
        
        // Check if we should lockout
        if (this.scannerState.failedAttempts[scannerId] >= this.MAX_FAILED_ATTEMPTS) {
            this.scannerState.lockoutTimers[scannerId] = Date.now() + this.SCANNER_LOCKOUT_TIME;
            if (window.gameAlert) {
                window.gameAlert(`Too many failed attempts. Scanner locked for ${this.SCANNER_LOCKOUT_TIME/1000} seconds.`, 'error', 'Scanner Locked', 5000);
            }
        } else {
            const remainingAttempts = this.MAX_FAILED_ATTEMPTS - this.scannerState.failedAttempts[scannerId];
            if (window.gameAlert) {
                window.gameAlert(`Scan failed. ${remainingAttempts} attempts remaining before lockout.`, 'warning', 'Scan Failed', 4000);
            }
        }
    }
    
    start() {
        super.start();
        console.log("Biometrics minigame started");
        
        // Set up global interaction handler for fingerprint objects
        this.setupFingerprintInteractionHandler();
    }
    
    setupFingerprintInteractionHandler() {
        // Store the original interaction handler
        this.originalInteractionHandler = window.handleObjectInteraction;
        
        // Override the interaction handler to handle fingerprint collection
        window.handleObjectInteraction = (sprite) => {
            // Check if we're in searching mode and this object has fingerprints
            if (this.searchingMode && sprite.scenarioData && sprite.scenarioData.hasFingerprint === true) {
                
                console.log('Collecting fingerprint from object:', sprite);
                this.collectFingerprintFromObject(sprite);
                return; // Don't call the original handler
            }
            
            // Call the original handler for all other interactions
            if (this.originalInteractionHandler) {
                this.originalInteractionHandler(sprite);
            }
        };
    }
    
    complete(success) {
        // Stop searching mode and clear highlights
        if (this.searchingMode) {
            this.toggleRoomSearching();
        }
        
        // Sync final state
        this.syncBiometricSamples();
        
        // Call parent complete with result
        super.complete(success, this.gameResult);
    }
    
    cleanup() {
        // Restore original interaction handler
        if (this.originalInteractionHandler) {
            window.handleObjectInteraction = this.originalInteractionHandler;
        }
        
        // Clear highlights
        this.clearHighlights();
        
        // Call parent cleanup
        super.cleanup();
    }
}

// Function to start the biometrics minigame
export function startBiometricsMinigame(item) {
    console.log('Starting biometrics minigame with:', { item });
    
    // Make sure the minigame is registered
    if (window.MinigameFramework && !window.MinigameFramework.registeredScenes['biometrics']) {
        window.MinigameFramework.registerScene('biometrics', BiometricsMinigame);
        console.log('Biometrics minigame registered on demand');
    }
    
    // Initialize the framework if not already done
    if (!window.MinigameFramework.mainGameScene && item && item.scene) {
        window.MinigameFramework.init(item.scene);
    }
    
    // Start the biometrics minigame with proper parameters
    const params = {
        title: 'Biometric Scanner',
        item: item,
        disableGameInput: false, // Allow player to move while scanner is open
        onComplete: (success, result) => {
            console.log('Biometrics minigame completed with success:', success);
        }
    };
    
    console.log('Starting biometrics minigame with params:', params);
    window.MinigameFramework.startMinigame('biometrics', null, params);
}
