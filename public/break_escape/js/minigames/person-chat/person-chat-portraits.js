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
        this.spriteTalkImage = null; // Loaded *_talk.png (single frame OR 2×2 spritesheet)
        this.useSpriteTalk = false; // Whether to use spriteTalk instead of spriteSheet
        this.flipped = false; // Whether to flip the sprite horizontally
        this.facingDirection = npc.id === 'player' ? 'right' : 'left';

        // TTS mouth animation
        this.ttsManager = null; // Set via setTTSManager() from the minigame
        this._loadingSpriteTalkImage = false; // Guard against duplicate loads
        this._lastRenderedTalkFrame = -1;  // Sentinel – forces first render
        
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
     * Start the animation loop (handles both parallax and TTS mouth animation).
     */
    startParallaxAnimation() {
        if (this.animationFrameId) {
            return; // Already running
        }
        this._runAnimationLoop();
    }

    /**
     * Unified animation loop handling both background parallax and TTS mouth animation.
     *
     * Parallax: re-renders for 2 s after speaker change.
     * Mouth:    re-renders only when the active talk-sheet frame index changes
     *           (~10 fps while speaking, one final render when speech stops).
     *
     * The loop polls cheaply at 60 fps while ttsManager is registered so it
     * reacts immediately when TTS starts, without requiring an external trigger.
     * @private
     */
    _runAnimationLoop() {
        const PARALLAX_DURATION = 2.0; // seconds

        const animate = () => {
            if (!this.canvas) {
                this.animationFrameId = null;
                return;
            }

            const elapsed = (Date.now() - this.parallaxStartTime) / 1000;
            const parallaxActive = !!this.backgroundImage && elapsed < PARALLAX_DURATION;

            // Mouth animation: only re-render when the frame index actually changes
            // (frame changes at ~10 fps while speaking; once to frame 0 when it stops)
            const currentFrame = this._getCurrentTalkFrame();
            const frameChanged = this._isTalkSheet() &&
                                 currentFrame !== this._lastRenderedTalkFrame;

            if (parallaxActive || frameChanged) {
                this.render();
                this._lastRenderedTalkFrame = currentFrame;
            }

            // Keep loop alive while ttsManager is set (cheap boolean poll) or parallax runs
            if (this.ttsManager || parallaxActive) {
                this.animationFrameId = requestAnimationFrame(animate);
            } else {
                this.animationFrameId = null;
            }
        };

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
            this.spriteTalkImage = null; // Will be loaded lazily on first render
            this._loadingSpriteTalkImage = false; // Reset lazy-load flag
            this._lastRenderedTalkFrame = -1;  // Force re-render after load
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
     * Register the TTSManager so mouth animation can be driven by real audio amplitude.
     * Call this after portrait initialisation from the parent minigame.
     * @param {TTSManager} manager
     */
    setTTSManager(manager) {
        this.ttsManager = manager;
        // Ensure the animation loop is running so it can pick up TTS starts
        if (this.canvas && !this.animationFrameId) {
            this._runAnimationLoop();
        }
    }

    /**
     * Returns true when the loaded spriteTalk image is a 2×2 spritesheet
     * (256×256 or any larger even-square image).  Single-frame images (128×128
     * or smaller) are treated as a static portrait without mouth animation.
     * @private
     */
    _isTalkSheet() {
        return !!this.spriteTalkImage &&
               this.spriteTalkImage.width >= 256 &&
               this.spriteTalkImage.width === this.spriteTalkImage.height &&
               this.spriteTalkImage.width % 2 === 0;
    }

    /**
     * Returns the logical frame size of the spriteTalk image.
     * For a 2×2 sheet this is half the image width; for a single frame it is the full width.
     * @private
     */
    _getTalkFrameSize() {
        if (!this.spriteTalkImage) return 0;
        return this._isTalkSheet()
            ? this.spriteTalkImage.width / 2
            : this.spriteTalkImage.width;
    }

    /**
     * Returns which frame of the 2×2 talk sheet to display this render cycle.
     *   Frame 0 – closed mouth  (top-left)     → shown when silent
     *   Frame 1 – open pose A   (top-right)     ┐
     *   Frame 2 – open pose B   (bottom-left)   ├ cycle while speaking (~10 fps)
     *   Frame 3 – open pose C   (bottom-right)  ┘
     * @private
     */
    _getCurrentTalkFrame() {
        if (!this._isTalkSheet()) return 0;
        if (this.ttsManager?.isSpeaking()) {
            return (Math.floor(Date.now() / 100) % 3) + 1; // 1 → 2 → 3 → 1 …
        }
        return 0; // closed mouth
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
            this.startParallaxAnimation();
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
     * PHASE 4.5: Change background to a new image
     * @param {string} newBackgroundPath - Path to new background image
     */
    setBackground(newBackgroundPath) {
        if (!newBackgroundPath) {
            console.warn('⚠️ setBackground: No background path provided');
            return;
        }
        
        this.backgroundPath = newBackgroundPath;
        this.backgroundImage = null; // Clear old image
        console.log(`🎨 Setting new background: ${newBackgroundPath}`);
        this.loadBackgroundImage();
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
     * Render the spriteTalk portrait, selecting the correct frame from the 2×2
     * spritesheet based on current TTS amplitude (noise-gate).
     *
     * If the loaded image is a 2×2 sheet (≥256×256 square):
     *   - Frame 0 (top-left)  → closed mouth  – shown when TTS is silent
     *   - Frames 1-3 cycle    → talking poses  – shown while TTS amplitude > threshold
     * If the image is a single frame (< 256px), it is rendered as before.
     */
    renderSpriteTalkImage() {
        if (!this.ctx || !this.canvas) return;

        if (!this.spriteTalkImage) {
            this._startLoadingSpriteTalkImage();
            return;
        }

        this.drawSpriteTalkImage(this.spriteTalkImage, this._getCurrentTalkFrame());
    }

    /**
     * Begin loading the mouth-closed spriteTalk image (idempotent).
     * Called lazily the first time it is needed.
     * @private
     */
    _startLoadingSpriteTalkImage() {
        if (this._loadingSpriteTalkImage) return; // already in flight
        this._loadingSpriteTalkImage = true;

        const img = new Image();
        img.crossOrigin = 'anonymous';

        img.onload = () => {
            this.spriteTalkImage = img;
            this._loadingSpriteTalkImage = false;
            this._lastRenderedTalkFrame = -1; // force next loop tick to re-render
            // Trigger an immediate render so the portrait appears without waiting
            // for the next animation loop tick
            this.render();
        };

        img.onerror = () => {
            this._loadingSpriteTalkImage = false;
            console.error(`❌ Failed to load spriteTalk image: ${this.npc.spriteTalk}`);
            this.renderPlaceholder();
        };

        let imageSrc = this.npc.spriteTalk;
        if (!imageSrc.startsWith('/') && !imageSrc.startsWith('http')) {
            imageSrc = imageSrc.startsWith('assets/')
                ? `/break_escape/${imageSrc}`
                : `${ASSETS_PATH}/${imageSrc}`;
        }
        img.src = imageSrc;
    }
    
    /**
     * Calculate contain-fit scale for the active talk frame against the canvas.
     * For a 2×2 spritesheet the scale is based on the per-frame size (half width/height),
     * keeping the rendered character the same size regardless of sheet dimensions.
     * @returns {number|null}
     */
    calculateSpriteTalkScale() {
        const frameSize = this._getTalkFrameSize();
        if (!frameSize || !this.canvas) return null;
        return Math.min(this.canvas.width / frameSize, this.canvas.height / frameSize);
    }

    /**
     * Draw one frame of the spriteTalk image (or the whole image for single-frame portraits).
     *
     * For a 2×2 spritesheet the frame layout is:
     *   col 0, row 0  →  frame 0 (top-left)
     *   col 1, row 0  →  frame 1 (top-right)
     *   col 0, row 1  →  frame 2 (bottom-left)
     *   col 1, row 1  →  frame 3 (bottom-right)
     *
     * @param {HTMLImageElement} img        - The loaded spriteTalk image
     * @param {number}           frameIndex - 0-3 for sheet; ignored for single-frame
     */
    drawSpriteTalkImage(img, frameIndex = 0) {
        if (!this.ctx || !this.canvas) return;

        try {
            const canvasWidth = this.canvas.width;
            const canvasHeight = this.canvas.height;

            // Determine source crop rectangle
            let srcX, srcY, srcW, srcH;
            if (this._isTalkSheet()) {
                srcW = img.width / 2;
                srcH = img.height / 2;
                srcX = (frameIndex % 2) * srcW;         // col 0 or 1
                srcY = Math.floor(frameIndex / 2) * srcH; // row 0 or 1
            } else {
                // Single-frame – use the whole image
                srcX = 0; srcY = 0; srcW = img.width; srcH = img.height;
            }

            // Scale the frame to fit the canvas (contain style)
            const scale = Math.min(canvasWidth / srcW, canvasHeight / srcH);
            const scaledWidth = srcW * scale;
            const scaledHeight = srcH * scale;

            // Center, then shift 20% away from the direction the character faces
            let x = (canvasWidth - scaledWidth) / 2 - canvasWidth * 0.2;
            const y = (canvasHeight - scaledHeight) / 2;

            this.ctx.imageSmoothingEnabled = false;

            if (this.flipped) {
                this.ctx.save();
                this.ctx.translate(canvasWidth / 2, 0);
                this.ctx.scale(-1, 1);
                this.ctx.drawImage(img,
                    srcX, srcY, srcW, srcH,                  // source crop
                    x - canvasWidth / 2, y, scaledWidth, scaledHeight); // dest
                this.ctx.restore();
            } else {
                this.ctx.drawImage(img,
                    srcX, srcY, srcW, srcH,                  // source crop
                    x, y, scaledWidth, scaledHeight);         // dest
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
     * PHASE 4: Clear the portrait canvas (for narrator mode without portrait)
     */
    clearPortrait() {
        if (!this.canvas || !this.ctx) return;
        
        // Clear canvas to black
        this.ctx.fillStyle = '#000';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Draw placeholder text
        this.ctx.fillStyle = '#666';
        this.ctx.font = '16px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillText(
            'Narrator',
            this.canvas.width / 2,
            this.canvas.height / 2
        );
        
        console.log('🖼️ Portrait cleared for narrator mode');
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
