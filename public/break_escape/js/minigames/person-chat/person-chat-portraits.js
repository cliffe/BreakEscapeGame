/**
 * PersonChatPortraits - Portrait Rendering System
 * 
 * Renders character portraits using Phaser sprite frames at 4x zoom.
 * - Player portraits face right
 * - NPC portraits face left
 * 
 * @module person-chat-portraits
 */

import { ASSETS_PATH } from '../../config.js';

export default class PersonChatPortraits {
    /**
     * Create portrait renderer
     * @param {Phaser.Game} game - Phaser game instance
     * @param {Object} npc - NPC data with sprite information
     * @param {HTMLElement} portraitContainer - Container for portrait canvas
     * @param {string} background - Optional background image path
     */
    constructor(game, npc, portraitContainer, background = null) {
        this.game = game;
        this.npc = npc;
        this.portraitContainer = portraitContainer;
        this.backgroundPath = background; // Optional background image path
        
        // Portrait settings
        this.spriteSize = 64; // Base sprite size
        this.zoomLevel = 4; // 4x zoom
        this.portraitWidth = this.spriteSize * this.zoomLevel; // 256px
        this.portraitHeight = this.spriteSize * this.zoomLevel; // 256px
        
        // Canvas and context
        this.canvas = null;
        this.ctx = null;
        
        // Background image
        this.backgroundImage = null; // Loaded background image
        this.parallaxStartTime = Date.now(); // Track time for parallax animation
        this.animationFrameId = null; // Track animation frame for cleanup
        
        // Sprite info
        this.spriteSheet = null;
        this.frameIndex = null;
        this.spriteTalkImage = null; // Single frame talk image (alternative to spriteSheet)
        this.useSpriteTalk = false; // Whether to use spriteTalk instead of spriteSheet
        this.flipped = false; // Whether to flip the sprite horizontally
        this.facingDirection = npc.id === 'player' ? 'right' : 'left';
        
        console.log(`🖼️ Portrait renderer created for NPC: ${npc.id}${background ? ` with background: ${background}` : ''}`);
    }
    
    /**
     * Initialize portrait display in container
     * Creates canvas and renders sprite frame
     */
    init() {
        if (!this.portraitContainer) {
            console.warn('❌ Portrait container not found');
            return false;
        }
        
        try {
            // Create canvas
            this.canvas = document.createElement('canvas');
            
            this.canvas.className = 'person-chat-portrait';
            this.canvas.id = `portrait-${this.npc.id}`;
            this.ctx = this.canvas.getContext('2d');
            
            // Style canvas for pixel-art rendering
            this.canvas.style.imageRendering = 'pixelated';
            this.canvas.style.imageRendering = '-moz-crisp-edges';
            this.canvas.style.imageRendering = 'crisp-edges';
            this.canvas.style.display = 'block';
            this.canvas.style.width = '100%';
            this.canvas.style.height = '100%';
            
            // Add to container first so it has dimensions
            this.portraitContainer.innerHTML = '';
            this.portraitContainer.appendChild(this.canvas);
            
            // Get sprite sheet and frame
            this.setupSpriteInfo();
            
            // Load background image if provided
            if (this.backgroundPath) {
                this.loadBackgroundImage();
            }
            
            // Set canvas size after it's in the DOM (container now has dimensions)
            // Use a small delay to ensure container is fully laid out
            setTimeout(() => {
                this.updateCanvasSize();
                this.render();
            }, 0);
            
            // Also set initial size immediately (in case container is already sized)
            this.updateCanvasSize();
            this.render();
            
            // Handle window resize
            window.addEventListener('resize', () => this.handleResize());
            
            // Parallax animation will start automatically when background image loads
            
            console.log(`✅ Portrait initialized for ${this.npc.id} (${this.canvas.width}x${this.canvas.height})`);
            return true;
        } catch (error) {
            console.error('❌ Error initializing portrait:', error);
            return false;
        }
    }
    
    /**
     * Calculate optimal integer scale factor for current container
     * Uses 16:9 aspect ratio (640x360) for landscape, 4:3 (640x480) for portrait
     * @returns {Object} Object with scale, baseWidth, and baseHeight
     */
    calculateOptimalScale() {
        // Try to get the game-container (same as main game uses)
        const gameContainer = document.getElementById('game-container');
        const container = gameContainer || this.portraitContainer;
        
        if (!container) {
            return { scale: 2, baseWidth: 640, baseHeight: 360 }; // Default fallback (landscape)
        }
        
        const containerWidth = container.clientWidth;
        const containerHeight = container.clientHeight;
        
        // Determine orientation: landscape (width > height) or portrait (height > width)
        const isLandscape = containerWidth > containerHeight;
        
        // Base resolution based on orientation
        // 16:9 for landscape (HD widescreen), 4:3 for portrait
        const baseWidth = 640;
        const baseHeight = isLandscape ? 360 : 480; // 16:9 for landscape, 4:3 for portrait
        
        // Calculate scale factors for both dimensions
        const scaleX = containerWidth / baseWidth;
        const scaleY = containerHeight / baseHeight;
        
        // Use the smaller scale to maintain aspect ratio
        const maxScale = Math.min(scaleX, scaleY);
        
        // Find the best integer scale factor (prefer 2x or higher for pixel art)
        let bestScale = 2; // Minimum for good pixel art
        
        // Check integer scales from 2x up to the maximum that fits
        for (let scale = 2; scale <= Math.floor(maxScale); scale++) {
            const scaledWidth = baseWidth * scale;
            const scaledHeight = baseHeight * scale;
            
            // If this scale fits within the container, use it
            if (scaledWidth <= containerWidth && scaledHeight <= containerHeight) {
                bestScale = scale;
            } else {
                break; // Stop at the largest scale that fits
            }
        }
        
        return { scale: bestScale, baseWidth, baseHeight };
    }
    
    /**
     * Update canvas size to match available container space with pixel-perfect scaling
     * Uses 16:9 aspect ratio for landscape, 4:3 for portrait
     */
    updateCanvasSize() {
        if (!this.canvas) return;
        
        // Calculate optimal scale and base resolution based on orientation
        const { scale: optimalScale, baseWidth, baseHeight } = this.calculateOptimalScale();
        
        // Set canvas internal resolution to scaled resolution for pixel-perfect rendering
        this.canvas.width = baseWidth * optimalScale;
        this.canvas.height = baseHeight * optimalScale;
        
        // CSS handles the display sizing (width/height 100% with object-fit: contain)
        // The canvas internal resolution is set above for pixel-perfect rendering
        
        const aspectRatio = baseWidth / baseHeight;
        const orientation = baseHeight === 360 ? 'landscape (16:9)' : 'portrait (4:3)';
        console.log(`🎨 Canvas scaled to ${optimalScale}x (${this.canvas.width}x${this.canvas.height}px internal, ${orientation}, fits container)`);
    }
    
    /**
     * Handle canvas resize on window resize
     */
    handleResize() {
        if (!this.canvas) return;
        
        try {
            this.updateCanvasSize();
            this.render();
        } catch (error) {
            console.error('❌ Error resizing portrait:', error);
        }
    }
    
    /**
     * Start parallax animation loop (stops after movement completes)
     */
    startParallaxAnimation() {
        if (this.animationFrameId) {
            return; // Already animating
        }
        
        const parallaxDuration = 2.0; // Duration of movement in seconds
        
        const animate = () => {
            if (!this.canvas || !this.backgroundImage) {
                this.animationFrameId = null;
                return;
            }
            
            const elapsed = (Date.now() - this.parallaxStartTime) / 1000; // Time in seconds
            
            // Re-render to update parallax position
            // This will redraw both background (with parallax) and sprite
            this.render();
            
            // Continue animation until movement is complete
            if (elapsed < parallaxDuration) {
                this.animationFrameId = requestAnimationFrame(animate);
            } else {
                // Movement complete, stop animation loop
                this.animationFrameId = null;
            }
        };
        
        // Start animation loop
        this.animationFrameId = requestAnimationFrame(animate);
    }
    
    /**
     * Stop parallax animation loop
     */
    stopParallaxAnimation() {
        if (this.animationFrameId) {
            cancelAnimationFrame(this.animationFrameId);
            this.animationFrameId = null;
        }
    }
    
    /**
     * Reset and restart parallax animation (called when speaker changes)
     */
    resetParallaxAnimation() {
        // Stop current animation if running
        this.stopParallaxAnimation();
        
        // Reset start time to begin new animation
        this.parallaxStartTime = Date.now();
        
        // Restart animation if background is loaded
        if (this.backgroundImage) {
            this.startParallaxAnimation();
        }
    }
    
    /**
     * Set up sprite sheet and frame information
     */
    setupSpriteInfo() {
        console.log(`🔍 setupSpriteInfo - this.npc.id: ${this.npc.id}, this.npc.spriteTalk: ${this.npc.spriteTalk}`);
        console.log(`🔍 setupSpriteInfo - full NPC object:`, this.npc);
        
        // Check if NPC has a spriteTalk image (single frame portrait)
        if (this.npc.spriteTalk) {
            console.log(`📸 Using spriteTalk image: ${this.npc.spriteTalk}`);
            this.useSpriteTalk = true;
            // Clear spriteTalkImage on speaker change to ensure correct dimensions are calculated
            // This ensures background scale is recalculated for each speaker's sprite size
            this.spriteTalkImage = null; // Will be loaded in render with correct dimensions
            // For NPCs with spriteTalk, flip the image to face right
            this.flipped = this.npc.id !== 'player';
            return;
        }
        
        // Otherwise use spriteSheet with frame
        console.log(`🔍 No spriteTalk found, using spriteSheet`);
        this.useSpriteTalk = false;
        // Clear spriteTalkImage when switching to spriteSheet
        this.spriteTalkImage = null;
        
        if (this.npc.id === 'player') {
            // Player uses their sprite
            this.spriteSheet = 'hacker'; // Default player sprite
            // Use diagonal down-right frame (facing right/down)
            this.frameIndex = 20; // Diagonal down-right idle frame
            this.flipped = false; // Player not flipped
        } else {
            // NPC uses their configured sprite
            this.spriteSheet = this.npc.spriteSheet || 'hacker';
            // Use diagonal down-left frame (same frame as player's down-right, but flipped)
            this.frameIndex = 20; // Diagonal down idle frame
            this.flipped = true; // NPC is flipped to face left
        }
    }
    
    /**
     * Load background image if path is provided
     */
    loadBackgroundImage() {
        if (!this.backgroundPath) return;
        
        const img = new Image();
        img.crossOrigin = 'anonymous';
        
        img.onload = () => {
            this.backgroundImage = img;
            console.log(`✅ Background image loaded: ${this.backgroundPath}`);
            // Re-render when background loads
            this.render();
            // Start parallax animation now that background is loaded
            this.startParallexAnimation();
        };
        
        img.onerror = () => {
            console.error(`❌ Failed to load background image: ${this.backgroundPath}`);
            this.backgroundImage = null;
        };
        
        // Resolve path to full URL if relative
        let bgSrc = this.backgroundPath;
        if (!bgSrc.startsWith('/') && !bgSrc.startsWith('http')) {
            // Relative path - prepend appropriate base
            if (bgSrc.startsWith('assets/')) {
                bgSrc = `/break_escape/${bgSrc}`;
            } else {
                bgSrc = `${ASSETS_PATH}/${bgSrc}`;
            }
        }
        img.src = bgSrc;
    }
    
    /**
     * Draw background image at same pixel scale as character sprite
     * Fills the canvas while maintaining sprite's pixel scale (may extend beyond canvas if larger)
     * Aligns based on speaker position: right edge for NPCs (flipped), left edge for player (not flipped)
     * @param {number} spriteScale - The scale factor used for the sprite (must match sprite scale exactly)
     */
    drawBackground(spriteScale) {
        if (!this.backgroundImage || !this.ctx || !this.canvas || !spriteScale) return;
        
        const canvasWidth = this.canvas.width;
        const canvasHeight = this.canvas.height;
        const imgWidth = this.backgroundImage.width;
        const imgHeight = this.backgroundImage.height;
        
        // Use the exact same scale as the sprite
        let scale = spriteScale;
        
        // Calculate scaled dimensions using the sprite's scale
        let scaledWidth = imgWidth * scale;
        let scaledHeight = imgHeight * scale;
        
        // If background is smaller than canvas, scale it up to fill (cover style)
        // This ensures the background always fills the canvas while maintaining aspect ratio
        if (scaledWidth < canvasWidth || scaledHeight < canvasHeight) {
            const fillScaleX = canvasWidth / imgWidth;
            const fillScaleY = canvasHeight / imgHeight;
            const fillScale = Math.max(fillScaleX, fillScaleY); // Cover style to fill canvas
            scale = fillScale;
            scaledWidth = imgWidth * scale;
            scaledHeight = imgHeight * scale;
        }
        
        // Position based on speaker alignment to fill canvas:
        // - NPC (flipped, appears on right): align right edge to canvas right edge
        // - Player (not flipped, appears on left): align left edge to canvas left edge
        let x;
        if (this.flipped) {
            // NPC on right: align background's right edge to canvas right edge
            x = canvasWidth - scaledWidth;
        } else {
            // Player on left: align background's left edge to canvas left edge
            x = 0;
        }
        
        // Fill canvas vertically - center if larger, align to top if exactly filling
        let y;
        if (scaledHeight > canvasHeight) {
            // Background larger than canvas: center vertically (will extend above/below)
            y = (canvasHeight - scaledHeight) / 2;
        } else {
            // Background fills or is exactly canvas height: align to top
            y = 0;
        }
        
        // Calculate subtle parallax effect - move background towards sprite once and stop
        const elapsed = (Date.now() - this.parallaxStartTime) / 1000; // Time in seconds
        const parallaxDuration = 1.0; // Duration of movement in seconds
        const maxParallaxAmount = 10; // Maximum parallax offset in pixels
        
        // Calculate parallax amount: moves from 0 to maxParallaxAmount over duration, then stops
        let parallaxAmount = 0;
        if (elapsed < parallaxDuration) {
            // Ease-out animation: starts fast, slows down as it approaches target
            const progress = elapsed / parallaxDuration; // 0 to 1
            const easedProgress = 1 - Math.pow(1 - progress, 3); // Ease-out cubic
            parallaxAmount = easedProgress * maxParallaxAmount;
        } else {
            // Movement complete, stay at max position
            parallaxAmount = maxParallaxAmount;
        }
        
        // Move background towards sprite (towards center)
        // NPC on right: move left (negative), Player on left: move right (positive)
        const parallaxOffset = this.flipped ? parallaxAmount : -parallaxAmount;
        x += parallaxOffset;
        
        // Draw background image at same pixel scale as sprite
        // Note: Canvas will clip anything outside its bounds, but background may extend beyond
        this.ctx.imageSmoothingEnabled = false; // Pixel-perfect rendering
        this.ctx.drawImage(
            this.backgroundImage,
            x, y, // Destination position (with parallax offset)
            scaledWidth, scaledHeight // Destination size (scaled to match sprite scale exactly)
        );
    }
    
    /**
     * Render the portrait using Phaser texture or spriteTalk image, scaled to fill canvas
     */
    render() {
        if (!this.canvas || !this.ctx) return;
        
        try {
            // console.log(`🎨 render() called - useSpriteTalk: ${this.useSpriteTalk}, spriteSheet: ${this.spriteSheet}`);
            
            // Clear canvas
            this.ctx.fillStyle = '#000';
            this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
            
            // If using spriteTalk image, render that instead
            if (this.useSpriteTalk) {
                // console.log(`🎨 Rendering spriteTalk image path`);
                // Calculate sprite scale for spriteTalk
                const spriteTalkScale = this.calculateSpriteTalkScale();
                // Draw background with sprite scale if loaded
                if (this.backgroundImage && spriteTalkScale) {
                    this.drawBackground(spriteTalkScale);
                }
                this.renderSpriteTalkImage();
                return;
            }
            
            console.log(`🎨 Rendering spriteSheet path - spriteSheet: ${this.spriteSheet}, frame: ${this.frameIndex}`);
            
            // Get Phaser texture
            const texture = this.game.textures.get(this.spriteSheet);
            if (!texture || texture.key === '__MISSING') {
                console.warn(`⚠️ Texture not found: ${this.spriteSheet}`);
                this.renderPlaceholder();
                return;
            }
            
            // Get the frame
            const frame = texture.get(this.frameIndex);
            if (!frame) {
                console.warn(`⚠️ Frame ${this.frameIndex} not found in ${this.spriteSheet}`);
                this.renderPlaceholder();
                return;
            }
            
            // Get the source image
            const source = frame.source.image;
            
            // Calculate scaling to fit sprite within canvas while maintaining aspect ratio
            // Use Math.min to ensure full sprite is visible (contain style, not cover)
            const spriteWidth = frame.cutWidth;
            const spriteHeight = frame.cutHeight;
            const canvasWidth = this.canvas.width;
            const canvasHeight = this.canvas.height;
            
            let scaleX = canvasWidth / spriteWidth;
            let scaleY = canvasHeight / spriteHeight;
            let scale = Math.min(scaleX, scaleY); // Fit contain style - ensures full sprite visible
            
            // Draw background with sprite scale if loaded
            if (this.backgroundImage) {
                this.drawBackground(scale);
            }
            
            // Calculate position to center the sprite
            const scaledWidth = spriteWidth * scale;
            const scaledHeight = spriteHeight * scale;
            let x = (canvasWidth - scaledWidth) / 2;
            const y = (canvasHeight - scaledHeight) / 2;
            
            // Shift sprite 20% away from the direction they're facing
            // Shifting left works for both flipped and non-flipped due to coordinate transform
            // NPCs (flipped) appear on right, Player (not flipped) appears on left
            const shiftAmount = canvasWidth * 0.2;
            x -= shiftAmount;
            
            // Draw the sprite frame scaled to fill canvas with optional flip
            this.ctx.imageSmoothingEnabled = false;
            
            if (this.flipped) {
                // Save current state, flip horizontally, draw, restore
                this.ctx.save();
                this.ctx.translate(canvasWidth / 2, 0);
                this.ctx.scale(-1, 1);
                this.ctx.drawImage(
                    source,
                    frame.cutX, frame.cutY, // Source position
                    frame.cutWidth, frame.cutHeight, // Source size
                    x - canvasWidth / 2, y, // Destination position
                    scaledWidth, scaledHeight // Destination size (scaled)
                );
                this.ctx.restore();
            } else {
                // Draw normally
                this.ctx.drawImage(
                    source,
                    frame.cutX, frame.cutY, // Source position
                    frame.cutWidth, frame.cutHeight, // Source size
                    x, y, // Destination position
                    scaledWidth, scaledHeight // Destination size (scaled)
                );
            }
            
        } catch (error) {
            console.error('❌ Error rendering portrait:', error);
            this.renderPlaceholder();
        }
    }
    
    /**
     * Render the spriteTalk image (single frame portrait)
     * Loads the image from the NPC's spriteTalk property
     */
    renderSpriteTalkImage() {
        if (!this.ctx || !this.canvas) return;
        
        try {
            // Load image if not already loaded
            if (!this.spriteTalkImage) {
                const img = new Image();
                img.crossOrigin = 'anonymous';
                
                img.onload = () => {
                    // Store loaded image
                    this.spriteTalkImage = img;
                    // Recalculate scale now that image is loaded and redraw background
                    const spriteTalkScale = this.calculateSpriteTalkScale();
                    if (this.backgroundImage && spriteTalkScale) {
                        // Clear and redraw background with correct scale
                        this.ctx.fillStyle = '#000';
                        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
                        this.drawBackground(spriteTalkScale);
                    }
                    this.drawSpriteTalkImage(img);
                };
                
                img.onerror = () => {
                    console.error(`❌ Failed to load spriteTalk image: ${this.npc.spriteTalk}`);
                    this.renderPlaceholder();
                };
                
                // Start loading image - resolve relative path to full URL
                let imageSrc = this.npc.spriteTalk;
                if (!imageSrc.startsWith('/') && !imageSrc.startsWith('http')) {
                    // Relative path - prepend base path
                    // If path starts with 'assets/', prepend /break_escape/
                    // Otherwise, prepend ASSETS_PATH
                    if (imageSrc.startsWith('assets/')) {
                        imageSrc = `/break_escape/${imageSrc}`;
                    } else {
                        imageSrc = `${ASSETS_PATH}/${imageSrc}`;
                    }
                }
                img.src = imageSrc;
            } else {
                // Already loaded, draw it
                this.drawSpriteTalkImage(this.spriteTalkImage);
            }
        } catch (error) {
            console.error('❌ Error rendering spriteTalk image:', error);
            this.renderPlaceholder();
        }
    }
    
    /**
     * Calculate the scale for spriteTalk image (same calculation used in drawSpriteTalkImage)
     * @returns {number|null} The scale factor, or null if spriteTalk image not loaded
     */
    calculateSpriteTalkScale() {
        if (!this.spriteTalkImage || !this.canvas) return null;
        
        const canvasWidth = this.canvas.width;
        const canvasHeight = this.canvas.height;
        const imgWidth = this.spriteTalkImage.width;
        const imgHeight = this.spriteTalkImage.height;
        
        // Calculate scaling to fit image within canvas while maintaining aspect ratio
        // Use Math.min to ensure full sprite is visible (contain style, not cover)
        let scaleX = canvasWidth / imgWidth;
        let scaleY = canvasHeight / imgHeight;
        return Math.min(scaleX, scaleY); // Fit contain style - ensures full sprite visible
    }
    
    /**
     * Draw the spriteTalk image scaled to fill canvas
     * @param {Image} img - The loaded image element
     */
    drawSpriteTalkImage(img) {
        if (!this.ctx || !this.canvas) return;
        
        try {
            const canvasWidth = this.canvas.width;
            const canvasHeight = this.canvas.height;
            const imgWidth = img.width;
            const imgHeight = img.height;
            
            // Calculate scaling to fit image within canvas while maintaining aspect ratio
            // Use Math.min to ensure full sprite is visible (contain style, not cover)
            let scaleX = canvasWidth / imgWidth;
            let scaleY = canvasHeight / imgHeight;
            let scale = Math.min(scaleX, scaleY); // Fit contain style - ensures full sprite visible
            
            // Calculate position to center the image
            const scaledWidth = imgWidth * scale;
            const scaledHeight = imgHeight * scale;
            let x = (canvasWidth - scaledWidth) / 2;
            const y = (canvasHeight - scaledHeight) / 2;
            
            // Shift sprite 20% away from the direction they're facing
            // Shifting left works for both flipped and non-flipped due to coordinate transform
            // NPCs (flipped) appear on right, Player (not flipped) appears on left
            const shiftAmount = canvasWidth * 0.2;
            x -= shiftAmount;
            
            // Draw image scaled to fill canvas with optional flip
            this.ctx.imageSmoothingEnabled = false;
            
            if (this.flipped) {
                // Save current state, flip horizontally, draw, restore
                this.ctx.save();
                this.ctx.translate(canvasWidth / 2, 0);
                this.ctx.scale(-1, 1);
                this.ctx.drawImage(
                    img,
                    x - canvasWidth / 2, y, // Destination position
                    scaledWidth, scaledHeight // Destination size (scaled)
                );
                this.ctx.restore();
            } else {
                // Draw normally
                this.ctx.drawImage(
                    img,
                    x, y, // Destination position
                    scaledWidth, scaledHeight // Destination size (scaled)
                );
            }
        } catch (error) {
            console.error('❌ Error drawing spriteTalk image:', error);
            this.renderPlaceholder();
        }
    }
    
    /**
     * Render a placeholder when sprite unavailable
     */
    renderPlaceholder() {
        if (!this.ctx || !this.canvas) return;
        
        // Draw colored rectangle
        this.ctx.fillStyle = this.npc.id === 'player' ? '#2d5a8f' : '#8f2d2d';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Draw label
        this.ctx.fillStyle = '#ffffff';
        this.ctx.font = 'bold 48px monospace';
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillText(
            this.npc.displayName || this.npc.id,
            this.canvas.width / 2,
            this.canvas.height / 2
        );
    }
    
    /**
     * Destroy portrait and cleanup
     */
    destroy() {
        // Stop parallax animation
        this.stopParallaxAnimation();
        
        if (this.canvas && this.canvas.parentNode) {
            this.canvas.parentNode.removeChild(this.canvas);
        }
        this.canvas = null;
        this.ctx = null;
        console.log(`✅ Portrait destroyed for ${this.npc.id}`);
    }
}
