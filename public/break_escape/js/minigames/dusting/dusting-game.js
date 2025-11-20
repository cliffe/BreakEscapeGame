import { MinigameScene } from '../framework/base-minigame.js';

// Load dusting-specific CSS
const dustingCSS = document.createElement('link');
dustingCSS.rel = 'stylesheet';
dustingCSS.href = 'css/dusting.css';
dustingCSS.id = 'dusting-css';
if (!document.getElementById('dusting-css')) {
    document.head.appendChild(dustingCSS);
}

// Dusting Minigame Scene implementation
export class DustingMinigame extends MinigameScene {
    constructor(container, params) {
        super(container, params);
        
        this.item = params.item;
        
        // Game state variables - using framework's gameState as base
        this.difficultySettings = {
            easy: {
                requiredCoverage: 0.3, // 30% of prints
                maxOverDusted: 50, // Increased due to more cells
                fingerprints: 60, // Increased proportionally
                pattern: 'simple'
            },
            medium: {
                requiredCoverage: 0.4, // 40% of prints
                maxOverDusted: 40, // Increased due to more cells
                fingerprints: 75, // Increased proportionally
                pattern: 'medium'
            },
            hard: {
                requiredCoverage: 0.5, // 50% of prints
                maxOverDusted: 25, // Increased due to more cells
                fingerprints: 90, // Increased proportionally
                pattern: 'complex'
            }
        };
        
        this.currentDifficulty = this.item.scenarioData.fingerprintDifficulty || 'medium';
        this.gridSize = 30;
        this.fingerprintCells = new Set();
        this.revealedPrints = 0;
        this.overDusted = 0;
        this.lastDustTime = {};
        
        // Tools configuration
        this.tools = [
            { name: 'Fine', size: 1, color: '#3498db', radius: 0 }, // Only affects current cell
            { name: 'Medium', size: 2, color: '#2ecc71', radius: 1 }, // Affects current cell and adjacent
            { name: 'Wide', size: 3, color: '#e67e22', radius: 2 }  // Affects current cell and 2 cells around
        ];
        this.currentTool = this.tools[1]; // Start with medium brush
    }
    
    init() {
        // Call parent init to set up common components
        super.init();
        
        console.log("Dusting minigame initializing");
        
        // Set container dimensions
        this.container.style.width = '75%';
        this.container.style.height = '75%';
        this.container.style.padding = '20px';
        
        // Add close button
        const closeButton = document.createElement('button');
        closeButton.className = 'minigame-close-button';
        closeButton.innerHTML = '&times;';
        closeButton.onclick = () => this.complete(false);
        this.container.appendChild(closeButton);
        
        // Set up header content
        this.headerElement.innerHTML = `
            <h3>Fingerprint Dusting</h3>
            <p>Drag to dust the surface and reveal fingerprints. Avoid over-dusting!</p>
        `;
        
        // Configure game container
        this.gameContainer.style.cssText = `
            width: 80%;
            height: 80%;
            max-width: 600px;
            max-height: 600px;
            display: grid;
            grid-template-columns: repeat(30, 1fr);
            grid-template-rows: repeat(30, 1fr);
            gap: 1px;
            background: #1a1a1a;
            padding: 5px;
            margin: 70px auto 20px auto;
            border-radius: 5px;
            box-shadow: 0 0 15px rgba(0, 0, 0, 0.5) inset;
            position: relative;
            overflow: hidden;
            cursor: crosshair;
        `;
        
        // Add background texture/pattern for a more realistic surface
        const gridBackground = document.createElement('div');
        gridBackground.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0.3;
            pointer-events: none;
            z-index: 0;
        `;
        
        // Create the grid pattern using encoded SVG
        const svgGrid = `data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100' viewBox='0 0 100 100'%3E%3Crect width='100' height='100' fill='%23111'/%3E%3Cpath d='M0 50h100M50 0v100' stroke='%23222' stroke-width='0.5'/%3E%3Cpath d='M25 0v100M75 0v100M0 25h100M0 75h100' stroke='%23191919' stroke-width='0.3'/%3E%3C/svg%3E`;
        
        gridBackground.style.backgroundImage = `url('${svgGrid}')`;
        this.gameContainer.appendChild(gridBackground);
        
        // Add tool selection
        const toolsContainer = document.createElement('div');
        toolsContainer.style.cssText = `
            position: absolute;
            bottom: 15px;
            left: 15px;
            display: flex;
            gap: 10px;
            z-index: 10;
            flex-wrap: wrap;
            max-width: 30%;
        `;
        
        this.tools.forEach(tool => {
            const toolButton = document.createElement('button');
            toolButton.className = `minigame-tool-button ${tool.name === this.currentTool.name ? 'active' : ''}`;
            toolButton.textContent = tool.name;
            toolButton.style.backgroundColor = tool.color;
            
            toolButton.addEventListener('click', () => {
                document.querySelectorAll('.minigame-tool-button').forEach(btn => {
                    btn.classList.remove('active');
                });
                toolButton.classList.add('active');
                this.currentTool = tool;
            });
            
            toolsContainer.appendChild(toolButton);
        });
        this.container.appendChild(toolsContainer);
        
        // Create particle container for dust effects
        this.particleContainer = document.createElement('div');
        this.particleContainer.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: 5;
            overflow: hidden;
        `;
        this.container.appendChild(this.particleContainer);
        
        // Create progress container for displaying dusting progress
        this.progressContainer = document.createElement('div');
        this.progressContainer.style.cssText = `
            position: absolute;
            top: 15px;
            right: 15px;
            background: rgba(0, 0, 0, 0.8);
            padding: 10px;
            border-radius: 5px;
            color: white;
            font-family: 'VT323', monospace;
            font-size: 14px;
            z-index: 10;
            min-width: 200px;
        `;
        this.container.appendChild(this.progressContainer);
        
        // Generate fingerprint pattern and set up cells
        this.fingerprintCells = this.generateFingerprint(this.currentDifficulty);
        this.setupGrid();
        
        // Total prints and required prints calculations
        this.totalPrints = this.fingerprintCells.size;
        this.requiredPrints = Math.ceil(this.totalPrints * this.difficultySettings[this.currentDifficulty].requiredCoverage);
        
        // Set up mouse event handlers for the grid
        this.setupMouseEvents();
        
        // Check initial progress
        this.checkProgress();
    }
    
    setupMouseEvents() {
        // Set up mouse event handlers
        this.gameState.isDragging = false;
        
        this.gameContainer.addEventListener('mousedown', (e) => {
            e.preventDefault();
            this.gameState.isDragging = true;
            this.handleMouseDown(e);
        });
        
        this.gameContainer.addEventListener('mousemove', (e) => {
            e.preventDefault();
            this.handleMouseMove(e);
        });
        
        this.gameContainer.addEventListener('mouseup', (e) => {
            e.preventDefault();
            this.gameState.isDragging = false;
        });
        
        this.gameContainer.addEventListener('mouseleave', (e) => {
            e.preventDefault();
            this.gameState.isDragging = false;
        });
        
        // Touch events for mobile
        this.gameContainer.addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.gameState.isDragging = true;
            const touch = e.touches[0];
            const mouseEvent = new MouseEvent('mousedown', {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            this.handleMouseDown(mouseEvent);
        });
        
        this.gameContainer.addEventListener('touchmove', (e) => {
            e.preventDefault();
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                const mouseEvent = new MouseEvent('mousemove', {
                    clientX: touch.clientX,
                    clientY: touch.clientY
                });
                this.handleMouseMove(mouseEvent);
            }
        });
        
        this.gameContainer.addEventListener('touchend', (e) => {
            e.preventDefault();
            this.gameState.isDragging = false;
        });
    }
    
    // Set up the grid of cells
    setupGrid() {
        console.log('Setting up dusting grid...', this.gridSize);
        
        // Clear any existing grid cells but preserve background
        const existingCells = this.gameContainer.querySelectorAll('[data-x]');
        existingCells.forEach(cell => cell.remove());
        
        console.log(`Creating ${this.gridSize * this.gridSize} grid cells...`);
        
        // Create grid cells
        for (let y = 0; y < this.gridSize; y++) {
            for (let x = 0; x < this.gridSize; x++) {
                const cell = document.createElement('div');
                cell.className = 'dust-cell';
                cell.style.cssText = `
                    width: 100%;
                    height: 100%;
                    background: #000;
                    position: relative;
                    transition: background-color 0.2s ease;
                    cursor: crosshair;
                    border: 1px solid #333;
                    box-sizing: border-box;
                    z-index: 1;
                `;
                cell.dataset.x = x;
                cell.dataset.y = y;
                cell.dataset.dustLevel = '0';
                cell.dataset.hasFingerprint = this.fingerprintCells.has(`${x},${y}`) ? 'true' : 'false';
                
                this.gameContainer.appendChild(cell);
            }
        }
        
        console.log(`Grid setup complete. Total cells created: ${this.gameContainer.querySelectorAll('[data-x]').length}`);
        console.log('Game container dimensions:', this.gameContainer.offsetWidth, 'x', this.gameContainer.offsetHeight);
    }
    
    // Override the framework's mouse event handlers
    handleMouseMove(e) {
        if (!this.gameState.isDragging) return;
        
        // Get the cell element under the cursor
        const cell = document.elementFromPoint(e.clientX, e.clientY);
        if (!cell || !cell.dataset || cell.dataset.dustLevel === undefined) return;
        
        // Get current cell coordinates
        const centerX = parseInt(cell.dataset.x);
        const centerY = parseInt(cell.dataset.y);
        
        // Get a list of cells to dust based on the brush radius
        const cellsToDust = [];
        const radius = this.currentTool.radius;
        
        // Add the current cell and cells within radius
        for (let y = centerY - radius; y <= centerY + radius; y++) {
            for (let x = centerX - radius; x <= centerX + radius; x++) {
                // Skip cells outside the grid
                if (x < 0 || x >= this.gridSize || y < 0 || y >= this.gridSize) continue;
                
                // For medium brush, use a diamond pattern (taxicab distance)
                if (this.currentTool.size === 2) {
                    // Manhattan distance: |x1-x2| + |y1-y2|
                    const distance = Math.abs(x - centerX) + Math.abs(y - centerY);
                    if (distance > radius) continue; // Skip if too far away
                } 
                // For wide brush, use a circle pattern (Euclidean distance)
                else if (this.currentTool.size === 3) {
                    // Euclidean distance: √[(x1-x2)² + (y1-y2)²]
                    const distance = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
                    if (distance > radius) continue; // Skip if too far away
                }
                
                // Find this cell in the DOM
                const targetCell = this.gameContainer.querySelector(`[data-x="${x}"][data-y="${y}"]`);
                if (targetCell) {
                    cellsToDust.push(targetCell);
                }
            }
        }
        
        // Get cell position for particles (center cell)
        const cellRect = cell.getBoundingClientRect();
        const particleContainerRect = this.particleContainer.getBoundingClientRect();
        const cellCenterX = (cellRect.left + cellRect.width / 2) - particleContainerRect.left;
        const cellCenterY = (cellRect.top + cellRect.height / 2) - particleContainerRect.top;
        
        // Process all cells to dust
        cellsToDust.forEach(targetCell => {
            const cellId = `${targetCell.dataset.x},${targetCell.dataset.y}`;
            const currentTime = Date.now();
            const dustLevel = parseInt(targetCell.dataset.dustLevel);
            
            // Tool intensity affects dusting rate and particle effects
            const toolIntensity = this.currentTool.size / 3; // 0.33 to 1
            
            // Only allow dusting every 50-150ms for each cell (based on tool size)
            const cooldown = 150 - (toolIntensity * 100); // 50ms for wide brush, 150ms for fine
            
            if (!this.lastDustTime[cellId] || currentTime - this.lastDustTime[cellId] > cooldown) {
                if (dustLevel < 3) {
                    // Increment dust level with a probability based on tool intensity
                    const dustProbability = toolIntensity * 0.5 + 0.1; // 0.1-0.6 chance based on tool
                    
                    if (dustLevel < 1 || Math.random() < dustProbability) {
                        targetCell.dataset.dustLevel = (dustLevel + 1).toString();
                        this.updateCellColor(targetCell);
                        
                        // Create dust particles for the current cell or at a position calculated for surrounding cells
                        if (targetCell === cell) {
                            // Center cell - use the already calculated position
                            const hasFingerprint = targetCell.dataset.hasFingerprint === 'true';
                            let particleColor = dustLevel === 1 ? '#666' : (hasFingerprint ? '#1aff1a' : '#aaa');
                            this.createDustParticles(cellCenterX, cellCenterY, toolIntensity, particleColor);
                        } else {
                            // For surrounding cells, calculate their relative position from the center cell
                            const targetCellRect = targetCell.getBoundingClientRect();
                            const targetCellX = (targetCellRect.left + targetCellRect.width / 2) - particleContainerRect.left;
                            const targetCellY = (targetCellRect.top + targetCellRect.height / 2) - particleContainerRect.top;
                            
                            const hasFingerprint = targetCell.dataset.hasFingerprint === 'true';
                            let particleColor = dustLevel === 1 ? '#666' : (hasFingerprint ? '#1aff1a' : '#aaa');
                            
                            // Create fewer particles for surrounding cells
                            const reducedIntensity = toolIntensity * 0.6;
                            this.createDustParticles(targetCellX, targetCellY, reducedIntensity, particleColor);
                        }
                    }
                    this.lastDustTime[cellId] = currentTime;
                }
            }
        });
        
        // Update progress after dusting
        this.checkProgress();
    }
    
    // Use the framework's mouseDown handler directly
    handleMouseDown(e) {
        // Just start dusting immediately
        this.handleMouseMove(e);
    }

    createDustParticles(x, y, intensity, color) {
        const numParticles = Math.floor(5 + intensity * 5); // 5-10 particles based on intensity
        
        for (let i = 0; i < numParticles; i++) {
            const particle = document.createElement('div');
            const size = Math.random() * 3 + 1; // 1-4px
            const angle = Math.random() * Math.PI * 2;
            const distance = Math.random() * 20 * intensity;
            const duration = Math.random() * 1000 + 500; // 500-1500ms
            
            particle.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                background: ${color};
                border-radius: 50%;
                opacity: ${Math.random() * 0.3 + 0.3};
                top: ${y}px;
                left: ${x}px;
                transform: translate(-50%, -50%);
                pointer-events: none;
                z-index: 6;
            `;
            
            this.particleContainer.appendChild(particle);
            
            // Animate the particle
            const animation = particle.animate([
                { 
                    transform: 'translate(-50%, -50%)',
                    opacity: particle.style.opacity
                },
                {
                    transform: `translate(
                        calc(-50% + ${Math.cos(angle) * distance}px), 
                        calc(-50% + ${Math.sin(angle) * distance}px)
                    )`,
                    opacity: 0
                }
            ], {
                duration: duration,
                easing: 'cubic-bezier(0.25, 1, 0.5, 1)'
            });
            
            animation.onfinish = () => {
                particle.remove();
            };
        }
    }
    
    updateCellColor(cell) {
        const dustLevel = parseInt(cell.dataset.dustLevel);
        const hasFingerprint = cell.dataset.hasFingerprint === 'true';
        
        if (dustLevel === 0) {
            cell.style.background = 'black';
            cell.style.boxShadow = 'none';
        }
        else if (dustLevel === 1) {
            cell.style.background = '#444';
            cell.style.boxShadow = 'inset 0 0 3px rgba(255,255,255,0.2)';
        }
        else if (dustLevel === 2) {
            if (hasFingerprint) {
                cell.style.background = '#0f0';
                cell.style.boxShadow = 'inset 0 0 5px rgba(0,255,0,0.5), 0 0 5px rgba(0,255,0,0.3)';
            } else {
                cell.style.background = '#888';
                cell.style.boxShadow = 'inset 0 0 4px rgba(255,255,255,0.3)';
            }
        }
        else {
            cell.style.background = '#ccc';
            cell.style.boxShadow = 'inset 0 0 5px rgba(255,255,255,0.5)';
        }
    }
    
    checkProgress() {
        this.revealedPrints = 0;
        this.overDusted = 0;
        
        this.gameContainer.childNodes.forEach(cell => {
            if (cell.dataset) { // Check if it's a cell element
                const dustLevel = parseInt(cell.dataset.dustLevel || '0');
                const hasFingerprint = cell.dataset.hasFingerprint === 'true';
                
                if (hasFingerprint && dustLevel === 2) this.revealedPrints++;
                if (dustLevel === 3) this.overDusted++;
            }
        });
        
        // Update progress display
        this.progressContainer.innerHTML = `
            <div style="margin-bottom: 5px;">
                <span style="color: #2ecc71;">Found: ${this.revealedPrints}/${this.requiredPrints} required prints</span>
                <span style="margin-left: 15px; color: ${this.overDusted > this.difficultySettings[this.currentDifficulty].maxOverDusted * 0.7 ? '#e74c3c' : '#fff'};">
                    Over-dusted: ${this.overDusted}/${this.difficultySettings[this.currentDifficulty].maxOverDusted} max
                </span>
            </div>
            <div class="minigame-progress-container">
                <div class="minigame-progress-bar" style="width: ${(this.revealedPrints/this.requiredPrints)*100}%;"></div>
            </div>
        `;
        
        // Check fail condition first
        if (this.overDusted >= this.difficultySettings[this.currentDifficulty].maxOverDusted) {
            this.showFinalFailure("Too many over-dusted areas!");
            return;
        }
        
        // Check win condition
        if (this.revealedPrints >= this.requiredPrints) {
            this.showFinalSuccess();
        }
    }
    
    showFinalSuccess() {
        // Calculate quality based on dusting precision
        const dustPenalty = this.overDusted / this.difficultySettings[this.currentDifficulty].maxOverDusted; // 0-1
        const coverageBonus = this.revealedPrints / this.totalPrints; // 0-1
        
        // Higher quality for more coverage and less over-dusting
        const quality = 0.7 + (coverageBonus * 0.25) - (dustPenalty * 0.15);
        const qualityPercentage = Math.round(quality * 100);
        const qualityRating = qualityPercentage >= 95 ? 'Perfect' : 
                              qualityPercentage >= 85 ? 'Excellent' : 
                              qualityPercentage >= 75 ? 'Good' : 'Acceptable';
        
        // Build success message with detailed stats
        const successHTML = `
            <div style="font-weight: bold; font-size: 24px; margin-bottom: 10px;">Fingerprint successfully collected!</div>
            <div style="font-size: 18px; margin-bottom: 15px;">Quality: ${qualityRating} (${qualityPercentage}%)</div>
            <div style="font-size: 14px; color: #aaa;">
                Prints revealed: ${this.revealedPrints}/${this.totalPrints}<br>
                Over-dusted areas: ${this.overDusted}<br>
                Difficulty: ${this.currentDifficulty.charAt(0).toUpperCase() + this.currentDifficulty.slice(1)}
            </div>
        `;
        
        // Use the framework's success message system
        this.showSuccess(successHTML, true, 2000);
        
        // Disable further interaction
        this.gameContainer.style.pointerEvents = 'none';
        
        // Store result for onComplete callback
        this.gameResult = {
            quality: quality,
            rating: qualityRating
        };
    }
    
    showFinalFailure(reason) {
        // Build failure message
        const failureHTML = `
            <div style="font-weight: bold; margin-bottom: 10px;">${reason}</div>
            <div style="font-size: 16px; margin-top: 5px;">Try again with more careful dusting.</div>
        `;
        
        // Use the framework's failure message system
        this.showFailure(failureHTML, true, 2000);
        
        // Disable further interaction
        this.gameContainer.style.pointerEvents = 'none';
    }
    
    start() {
        super.start();
        console.log("Dusting minigame started");
        
        // Disable game movement in the main scene
        if (this.params.scene) {
            this.params.scene.input.mouse.enabled = false;
        }
    }
    
    complete(success) {
        // Call parent complete with result
        super.complete(success, this.gameResult);
    }
    
    generateFingerprint(difficulty) {
        // Existing fingerprint generation logic
        const pattern = this.difficultySettings[difficulty].pattern;
        const numPrints = this.difficultySettings[difficulty].fingerprints;
        const newFingerprintCells = new Set();
        const centerX = Math.floor(this.gridSize / 2);
        const centerY = Math.floor(this.gridSize / 2);
        
        if (pattern === 'simple') {
            // Simple oval-like pattern
            for (let i = 0; i < numPrints; i++) {
                const angle = (i / numPrints) * Math.PI * 2;
                const distance = 5 + Math.random() * 3;
                const x = Math.floor(centerX + Math.cos(angle) * distance);
                const y = Math.floor(centerY + Math.sin(angle) * distance);
                
                if (x >= 0 && x < this.gridSize && y >= 0 && y < this.gridSize) {
                    newFingerprintCells.add(`${x},${y}`);
                    
                    // Add a few adjacent cells to make it less sparse
                    for (let j = 0; j < 2; j++) {
                        const nx = x + Math.floor(Math.random() * 3) - 1;
                        const ny = y + Math.floor(Math.random() * 3) - 1;
                        if (nx >= 0 && nx < this.gridSize && ny >= 0 && ny < this.gridSize) {
                            newFingerprintCells.add(`${nx},${ny}`);
                        }
                    }
                }
            }
        } else if (pattern === 'medium') {
            // Medium complexity - spiral pattern with variations
            for (let i = 0; i < numPrints; i++) {
                const t = i / numPrints * 5;
                const distance = 2 + t * 0.8;
                const noise = Math.random() * 2 - 1;
                const x = Math.floor(centerX + Math.cos(t * Math.PI * 2) * (distance + noise));
                const y = Math.floor(centerY + Math.sin(t * Math.PI * 2) * (distance + noise));
                
                if (x >= 0 && x < this.gridSize && y >= 0 && y < this.gridSize) {
                    newFingerprintCells.add(`${x},${y}`);
                }
            }
            
            // Add whorls and arches
            for (let i = 0; i < 20; i++) {
                const angle = (i / 20) * Math.PI * 2;
                const distance = 7;
                const x = Math.floor(centerX + Math.cos(angle) * distance);
                const y = Math.floor(centerY + Math.sin(angle) * distance);
                
                if (x >= 0 && x < this.gridSize && y >= 0 && y < this.gridSize) {
                    newFingerprintCells.add(`${x},${y}`);
                }
            }
        } else {
            // Complex pattern - detailed whorls and ridge patterns
            for (let i = 0; i < numPrints; i++) {
                // Main loop - create a complex whorl pattern
                const t = i / numPrints * 8;
                const distance = 2 + t * 0.6;
                const noise = Math.sin(t * 5) * 1.5;
                const x = Math.floor(centerX + Math.cos(t * Math.PI * 2) * (distance + noise));
                const y = Math.floor(centerY + Math.sin(t * Math.PI * 2) * (distance + noise));
                
                if (x >= 0 && x < this.gridSize && y >= 0 && y < this.gridSize) {
                    newFingerprintCells.add(`${x},${y}`);
                }
                
                // Add bifurcations and ridge endings
                if (i % 5 === 0) {
                    const bifAngle = t * Math.PI * 2 + Math.PI/4;
                    const bx = Math.floor(x + Math.cos(bifAngle) * 1);
                    const by = Math.floor(y + Math.sin(bifAngle) * 1);
                    if (bx >= 0 && bx < this.gridSize && by >= 0 && by < this.gridSize) {
                        newFingerprintCells.add(`${bx},${by}`);
                    }
                }
            }
            
            // Add delta patterns
            for (let d = 0; d < 3; d++) {
                const deltaAngle = (d / 3) * Math.PI * 2;
                const deltaX = Math.floor(centerX + Math.cos(deltaAngle) * 8);
                const deltaY = Math.floor(centerY + Math.sin(deltaAngle) * 8);
                
                for (let r = 0; r < 5; r++) {
                    for (let a = 0; a < 3; a++) {
                        const rayAngle = deltaAngle + (a - 1) * Math.PI/4;
                        const rx = Math.floor(deltaX + Math.cos(rayAngle) * r);
                        const ry = Math.floor(deltaY + Math.sin(rayAngle) * r);
                        if (rx >= 0 && rx < this.gridSize && ry >= 0 && ry < this.gridSize) {
                            newFingerprintCells.add(`${rx},${ry}`);
                        }
                    }
                }
            }
        }
        
        // Ensure we have at least the minimum number of cells
        while (newFingerprintCells.size < numPrints) {
            const x = centerX + Math.floor(Math.random() * 12 - 6);
            const y = centerY + Math.floor(Math.random() * 12 - 6);
            if (x >= 0 && x < this.gridSize && y >= 0 && y < this.gridSize) {
                newFingerprintCells.add(`${x},${y}`);
            }
        }
        
        return newFingerprintCells;
    }
    
    cleanup() {
        super.cleanup();
        
        // Re-enable game movement
        if (this.params.scene) {
            this.params.scene.input.mouse.enabled = true;
        }
    }
}

// Export the minigame for the framework to register
// The registration is now handled in the main minigames/index.js file

// Replacement for the startDustingMinigame function
function startDustingMinigame(item) {
    // Make sure the minigame is registered
    if (window.MinigameFramework && !window.MinigameFramework.scenes['dusting']) {
        window.MinigameFramework.registerScene('dusting', DustingMinigame);
        console.log('Dusting minigame registered on demand');
    }
    
    // Initialize the framework if not already done
    if (!window.MinigameFramework.mainGameScene) {
        window.MinigameFramework.init(item.scene);
    }
    
    // Start the dusting minigame
    window.MinigameFramework.startMinigame('dusting', {
        item: item,
        scene: item.scene,
        onComplete: (success, result) => {
            if (success) {
                console.log('DUSTING SUCCESS', result);
                
                // Create biometric sample using the proper biometrics system
                const sample = {
                    owner: item.scenarioData.fingerprintOwner || 'Unknown',
                    type: 'fingerprint',
                    quality: result.quality, // Quality between 0.7 and ~1.0
                    rating: result.rating,
                    data: generateFingerprintData(item)
                };
                
                // Use the biometrics system to add the sample
                if (window.addBiometricSample) {
                    window.addBiometricSample(sample);
                } else {
                    // Fallback to manual addition
                    if (!window.gameState) {
                        window.gameState = { biometricSamples: [] };
                    }
                    if (!window.gameState.biometricSamples) {
                        window.gameState.biometricSamples = [];
                    }
                    window.gameState.biometricSamples.push(sample);
                }
                
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
                if (window.showNotification) {
                    window.showNotification(`Collected ${sample.owner}'s fingerprint sample (${result.rating} quality)`, 'success');
                } else {
                    window.gameAlert(`Collected ${sample.owner}'s fingerprint sample (${result.rating} quality)`, 'success', 'Sample Acquired', 4000);
                }
            } else {
                console.log('DUSTING FAILED');
                if (window.showNotification) {
                    window.showNotification(`Failed to collect the fingerprint sample.`, 'error');
                } else {
                    window.gameAlert(`Failed to collect the fingerprint sample.`, 'error', 'Dusting Failed', 4000);
                }
            }
        }
    });
}

// Helper function to generate fingerprint data
function generateFingerprintData(item) {
    // Generate a unique fingerprint ID based on the item and scenario
    const baseData = item.scenarioData.fingerprintOwner || 'unknown';
    const hash = baseData.split('').reduce((a, b) => {
        a = ((a << 5) - a) + b.charCodeAt(0);
        return a & a;
    }, 0);
    return `FP${Math.abs(hash).toString(16).toUpperCase().padStart(8, '0')}`;
} 