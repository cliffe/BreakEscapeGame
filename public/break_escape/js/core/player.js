// Player System
// Handles player creation, movement, and animation

// Player management system
import { 
    MOVEMENT_SPEED, 
    RUN_SPEED_MULTIPLIER,
    RUN_ANIMATION_MULTIPLIER,
    ARRIVAL_THRESHOLD, 
    PLAYER_FEET_OFFSET_Y, 
    ROOM_CHECK_THRESHOLD, 
    CLICK_INDICATOR_SIZE,
    CLICK_INDICATOR_DURATION
} from '../utils/constants.js?v=8';

export let player = null;
export let targetPoint = null;
export let isMoving = false;
export let lastPlayerPosition = { x: 0, y: 0 };
let gameRef = null;

// Keyboard input state
const keyboardInput = {
    up: false,
    down: false,
    left: false,
    right: false,
    space: false,
    shift: false
};
let isKeyboardMoving = false;

// Keyboard pause state (for when minigames need keyboard input)
let keyboardPaused = false;

// Export functions to pause/resume keyboard interception
export function pauseKeyboardInput() {
    keyboardPaused = true;
    console.log('🔒 Keyboard input PAUSED for minigame (keyboardPaused = true)');
}

export function resumeKeyboardInput() {
    keyboardPaused = false;
    // Clear all keyboard state when resuming
    keyboardInput.up = false;
    keyboardInput.down = false;
    keyboardInput.left = false;
    keyboardInput.right = false;
    keyboardInput.space = false;
    keyboardInput.shift = false;
    isKeyboardMoving = false;
    console.log('🔓 Keyboard input RESUMED (keyboardPaused = false)');
}

// Create player sprite
export function createPlayer(gameInstance) {
    gameRef = gameInstance;
    console.log('Creating player');
    
    // Get starting room position and calculate center
    const scenario = window.gameScenario;
    const startRoomId = scenario ? scenario.startRoom : 'reception';
    const startRoomPosition = getStartingRoomCenter(startRoomId);
    
    // Create player sprite (using frame 20)
    player = gameInstance.add.sprite(startRoomPosition.x, startRoomPosition.y, 'hacker', 20);
    gameInstance.physics.add.existing(player);
    
    // Keep the character at original 64px size (2 tiles high)
    player.setScale(1);
    
    // Set smaller collision box at the feet
    player.body.setSize(15, 10);
    player.body.setOffset(25, 50); // Adjusted offset for 64px sprite
    
    player.body.setCollideWorldBounds(true);
    player.body.setBounce(0);
    player.body.setDrag(0);
    player.body.setFriction(0);
    
    // Set initial player depth (will be updated dynamically during movement)
    updatePlayerDepth(startRoomPosition.x, startRoomPosition.y);
    
    // Track player direction and movement state
    player.direction = 'down'; // Initial direction
    player.isMoving = false;
    player.lastDirection = 'down';
    
    // Create animations
    createPlayerAnimations();
    
    // Set initial animation
    player.anims.play('idle-down', true);
    
    // Initialize last position
    lastPlayerPosition = { x: player.x, y: player.y };
    
    // Store player globally immediately for safety
    window.player = player;
    
    // Setup keyboard input listeners
    setupKeyboardInput();
    
    return player;
}

function setupKeyboardInput() {
    // Handle keydown events
    document.addEventListener('keydown', (event) => {
        // Skip if keyboard input is paused (for minigames that need keyboard input)
        if (keyboardPaused) {
            console.log('⏸️ Keydown blocked (paused):', event.key);
            return;
        }
        
        const key = event.key.toLowerCase();
        
        // Shift key for running
        if (key === 'shift') {
            keyboardInput.shift = true;
            event.preventDefault();
            return;
        }
        
        // Spacebar for jump
        if (key === ' ') {
            keyboardInput.space = true;
            if (window.createPlayerJump) {
                window.createPlayerJump();
            }
            event.preventDefault();
            return;
        }
        
        // E key for interaction
        if (key === 'e') {
            if (window.tryInteractWithNearest) {
                window.tryInteractWithNearest();
            }
            event.preventDefault();
            return;
        }
        
        // Arrow keys
        if (key === 'arrowup') {
            keyboardInput.up = true;
            isKeyboardMoving = true;
            event.preventDefault();
        } else if (key === 'arrowdown') {
            keyboardInput.down = true;
            isKeyboardMoving = true;
            event.preventDefault();
        } else if (key === 'arrowleft') {
            keyboardInput.left = true;
            isKeyboardMoving = true;
            event.preventDefault();
        } else if (key === 'arrowright') {
            keyboardInput.right = true;
            isKeyboardMoving = true;
            event.preventDefault();
        }
        
        // WASD keys
        if (key === 'w') {
            keyboardInput.up = true;
            isKeyboardMoving = true;
            event.preventDefault();
        } else if (key === 's') {
            keyboardInput.down = true;
            isKeyboardMoving = true;
            event.preventDefault();
        } else if (key === 'a') {
            keyboardInput.left = true;
            isKeyboardMoving = true;
            event.preventDefault();
        } else if (key === 'd') {
            keyboardInput.right = true;
            isKeyboardMoving = true;
            event.preventDefault();
        }
    });
    
    // Handle keyup events
    document.addEventListener('keyup', (event) => {
        // Skip if keyboard input is paused (for minigames that need keyboard input)
        if (keyboardPaused) {
            return;
        }
        
        const key = event.key.toLowerCase();
        
        // Shift key
        if (key === 'shift') {
            keyboardInput.shift = false;
            event.preventDefault();
            return;
        }
        
        // Spacebar
        if (key === ' ') {
            keyboardInput.space = false;
            event.preventDefault();
            return;
        }
        
        // Arrow keys
        if (key === 'arrowup') {
            keyboardInput.up = false;
            event.preventDefault();
        } else if (key === 'arrowdown') {
            keyboardInput.down = false;
            event.preventDefault();
        } else if (key === 'arrowleft') {
            keyboardInput.left = false;
            event.preventDefault();
        } else if (key === 'arrowright') {
            keyboardInput.right = false;
            event.preventDefault();
        }
        
        // WASD keys
        if (key === 'w') {
            keyboardInput.up = false;
            event.preventDefault();
        } else if (key === 's') {
            keyboardInput.down = false;
            event.preventDefault();
        } else if (key === 'a') {
            keyboardInput.left = false;
            event.preventDefault();
        } else if (key === 'd') {
            keyboardInput.right = false;
            event.preventDefault();
        }
        
        // Check if any keys are still pressed
        isKeyboardMoving = keyboardInput.up || keyboardInput.down || keyboardInput.left || keyboardInput.right;
    });
}

function getAnimationKey(direction) {
    // Map left directions to their right counterparts (sprite is flipped)
    switch(direction) {
        case 'left':
            return 'right';
        case 'down-left':
            return 'down-right';
        case 'up-left':
            return 'up-right';
        default:
            return direction;
    }
}

function updateAnimationSpeed(isRunning) {
    // Update animation speed based on whether player is running
    if (!player || !player.anims) {
        return;
    }
    
    const frameRate = isRunning ? 8 * RUN_ANIMATION_MULTIPLIER : 8;
    
    // If there's a current animation playing, update its frameRate
    if (player.anims.currentAnim) {
        player.anims.currentAnim.frameRate = frameRate;
    }
}

function createPlayerAnimations() {
    // Create walking animations with correct frame numbers from original
    gameRef.anims.create({
        key: 'walk-right',
        frames: gameRef.anims.generateFrameNumbers('hacker', { start: 1, end: 4 }),
        frameRate: 8,
        repeat: -1
    });
    
    gameRef.anims.create({
        key: 'walk-down',
        frames: gameRef.anims.generateFrameNumbers('hacker', { start: 6, end: 9 }),
        frameRate: 8,
        repeat: -1
    });
    
    gameRef.anims.create({
        key: 'walk-up',
        frames: gameRef.anims.generateFrameNumbers('hacker', { start: 11, end: 14 }),
        frameRate: 8,
        repeat: -1
    });
    
    gameRef.anims.create({
        key: 'walk-up-right',
        frames: gameRef.anims.generateFrameNumbers('hacker', { start: 16, end: 19 }),
        frameRate: 8,
        repeat: -1
    });
    
    gameRef.anims.create({
        key: 'walk-down-right',
        frames: gameRef.anims.generateFrameNumbers('hacker', { start: 21, end: 24 }),
        frameRate: 8,
        repeat: -1
    });
    
    // Create idle frames (first frame of each row) with correct frame numbers
    gameRef.anims.create({
        key: 'idle-right',
        frames: [{ key: 'hacker', frame: 0 }],
        frameRate: 1
    });
    
    gameRef.anims.create({
        key: 'idle-down',
        frames: [{ key: 'hacker', frame: 5 }],
        frameRate: 1
    });
    
    gameRef.anims.create({
        key: 'idle-up',
        frames: [{ key: 'hacker', frame: 10 }],
        frameRate: 1
    });
    
    gameRef.anims.create({
        key: 'idle-up-right',
        frames: [{ key: 'hacker', frame: 15 }],
        frameRate: 1
    });
    
    gameRef.anims.create({
        key: 'idle-down-right',
        frames: [{ key: 'hacker', frame: 20 }],
        frameRate: 1
    });
    
    // Create left-facing idle animations (same frames as right, but sprite will be flipped)
    gameRef.anims.create({
        key: 'idle-left',
        frames: [{ key: 'hacker', frame: 0 }],
        frameRate: 1
    });
    
    gameRef.anims.create({
        key: 'idle-down-left',
        frames: [{ key: 'hacker', frame: 20 }],
        frameRate: 1
    });
    
    gameRef.anims.create({
        key: 'idle-up-left',
        frames: [{ key: 'hacker', frame: 15 }],
        frameRate: 1
    });
}

export function movePlayerToPoint(x, y) {
    const worldBounds = gameRef.physics.world.bounds;

    // Ensure coordinates are within bounds
    x = Phaser.Math.Clamp(x, worldBounds.x, worldBounds.x + worldBounds.width);
    y = Phaser.Math.Clamp(y, worldBounds.y, worldBounds.y + worldBounds.height);

    // Create click indicator
    createClickIndicator(x, y);

    targetPoint = { x, y };
    isMoving = true;

    // Notify tutorial of movement
    if (window.getTutorialManager) {
        const tutorialManager = window.getTutorialManager();
        tutorialManager.notifyPlayerMoved();
    }
}

function updatePlayerDepth(x, y) {
    // Get the bottom of the player sprite (feet position)
    const playerBottomY = y + (player.height * player.scaleY) / 2;
    
    // Simple depth calculation: world Y position + layer offset
    const playerDepth = playerBottomY + 0.5; // World Y + sprite layer offset
    
    // Set the player depth (always update, no threshold)
    if (player) {
        player.setDepth(playerDepth);
        
        // Debug logging - only show when depth actually changes significantly
        const lastDepth = player.lastDepth || 0;
        if (Math.abs(playerDepth - lastDepth) > 25) { // Reduced threshold for finer granularity
            console.log(`Player depth: ${playerDepth} (World Y: ${playerBottomY})`);
            console.log(`  Player layers: worldY(${playerBottomY}) + 0.5`);
            player.lastDepth = playerDepth;
        }
    }
}

function createClickIndicator(x, y) {
    // Create a circle at the click position
    const indicator = gameRef.add.circle(x, y, CLICK_INDICATOR_SIZE, 0xffffff, 0.7);
    indicator.setDepth(1000); // Above ground but below player
    
    // Add a pulsing animation
    gameRef.tweens.add({
        targets: indicator,
        scale: { from: 0.5, to: 1.5 },
        alpha: { from: 0.7, to: 0 },
        duration: CLICK_INDICATOR_DURATION,
        ease: 'Sine.easeOut',
        onComplete: () => {
            indicator.destroy();
        }
    });
}

export function updatePlayerMovement() {
    // Safety check: ensure player exists
    if (!player || !player.body) {
        return;
    }

    // Check if player is KO (knocked out) - disable movement
    if (window.playerHealth && window.playerHealth.isKO()) {
        player.body.setVelocity(0, 0);
        return;
    }

    // Check if movement is explicitly disabled
    if (player.disableMovement) {
        player.body.setVelocity(0, 0);
        return;
    }

    // Handle keyboard movement (takes priority over mouse movement)
    if (isKeyboardMoving) {
        updatePlayerKeyboardMovement();
    } else {
        // Handle mouse-based movement (original behavior)
        updatePlayerMouseMovement();
    }
    
    // Final check: if velocity is 0 and player is marked as moving, switch to idle
    if (player.body.velocity.x === 0 && player.body.velocity.y === 0 && player.isMoving) {
        player.isMoving = false;
        const animDir = getAnimationKey(player.direction);
        player.anims.play(`idle-${animDir}`, true);
    }
}

function updatePlayerKeyboardMovement() {
    // Cancel click-to-move when keyboard input is detected
    if (isMoving || targetPoint) {
        isMoving = false;
        targetPoint = null;
    }
    
    // Calculate movement direction based on keyboard input
    let dirX = 0;
    let dirY = 0;
    
    if (keyboardInput.right) dirX += 1;
    if (keyboardInput.left) dirX -= 1;
    if (keyboardInput.down) dirY += 1;
    if (keyboardInput.up) dirY -= 1;
    
    // Normalize diagonal movement to maintain consistent speed
    let velocityX = 0;
    let velocityY = 0;
    
    if (dirX !== 0 || dirY !== 0) {
        const magnitude = Math.sqrt(dirX * dirX + dirY * dirY);
        // Apply run speed multiplier if shift is held
        const speed = keyboardInput.shift ? MOVEMENT_SPEED * RUN_SPEED_MULTIPLIER : MOVEMENT_SPEED;
        velocityX = (dirX / magnitude) * speed;
        velocityY = (dirY / magnitude) * speed;

        // Notify tutorial of movement and running
        if (window.getTutorialManager) {
            const tutorialManager = window.getTutorialManager();
            tutorialManager.notifyPlayerMoved();
            if (keyboardInput.shift) {
                tutorialManager.notifyPlayerRan();
            }
        }
    }
    
    // Update animation speed every frame while moving
    if (player.isMoving) {
        updateAnimationSpeed(keyboardInput.shift);
    }
    
    // Check if movement is being blocked by collisions
    let isBlocked = false;
    if (velocityX !== 0 || velocityY !== 0) {
        // Check if blocked in the direction we want to move
        if (velocityX > 0 && player.body.blocked.right) isBlocked = true;
        if (velocityX < 0 && player.body.blocked.left) isBlocked = true;
        if (velocityY > 0 && player.body.blocked.down) isBlocked = true;
        if (velocityY < 0 && player.body.blocked.up) isBlocked = true;
    }
    
    // Apply velocity
    player.body.setVelocity(velocityX, velocityY);
    
    // Update player depth based on actual player position
    updatePlayerDepth(player.x, player.y);
    
    // Update last player position for depth calculations
    lastPlayerPosition.x = player.x;
    lastPlayerPosition.y = player.y;
    
    // Determine direction based on velocity
    const absVX = Math.abs(velocityX);
    const absVY = Math.abs(velocityY);
    
    // Set player direction and animation
    if (velocityX === 0 && velocityY === 0) {
        // No movement - stop
        if (player.isMoving) {
            player.isMoving = false;
            const animDir = getAnimationKey(player.direction);
            player.anims.stop(); // Stop current animation
            player.anims.play(`idle-${animDir}`, true);
        }
    } else if (isBlocked) {
        // Blocked by collision - play idle animation in the direction we're facing
        if (player.isMoving) {
            player.isMoving = false;
            const animDir = getAnimationKey(player.direction);
            player.anims.stop(); // Stop current animation
            player.anims.play(`idle-${animDir}`, true);
        }
    } else if (absVX > absVY * 2) {
        // Mostly horizontal movement
        player.direction = velocityX > 0 ? 'right' : 'left'; // Track both left and right directions
        player.setFlipX(velocityX < 0); // Flip sprite horizontally if moving left
        
        if (!player.isMoving || player.lastDirection !== player.direction) {
            // Use 'right' animation for both left and right (flip handled by setFlipX)
            player.anims.play(`walk-right`, true);
            player.isMoving = true;
            player.lastDirection = player.direction;
        }
    } else if (absVY > absVX * 2) {
        // Mostly vertical movement
        player.direction = velocityY > 0 ? 'down' : 'up';
        player.setFlipX(false);
        
        if (!player.isMoving || player.lastDirection !== player.direction) {
            player.anims.play(`walk-${player.direction}`, true);
            player.isMoving = true;
            player.lastDirection = player.direction;
        }
    } else {
        // Diagonal movement
        if (velocityY > 0) {
            player.direction = velocityX > 0 ? 'down-right' : 'down-left';
        } else {
            player.direction = velocityX > 0 ? 'up-right' : 'up-left';
        }
        player.setFlipX(velocityX < 0); // Flip sprite horizontally if moving left
        
        if (!player.isMoving || player.lastDirection !== player.direction) {
            // Use the base direction for animation (right or left for horizontal component)
            const baseDir = velocityY > 0 ? 'down-right' : 'up-right';
            player.anims.play(`walk-${baseDir}`, true);
            player.isMoving = true;
            player.lastDirection = player.direction;
        }
    }
}

function updatePlayerMouseMovement() {
    if (!isMoving || !targetPoint) {
        if (player.body.velocity.x !== 0 || player.body.velocity.y !== 0) {
            player.body.setVelocity(0, 0);
            player.isMoving = false;
            
            // Play idle animation based on last direction
            player.anims.play(`idle-${player.direction}`, true);
        }
        return;
    }

    // Cache player position - adjust for feet position
    const px = player.x;
    const py = player.y + PLAYER_FEET_OFFSET_Y; // Add offset to target the feet
    
    // Update player depth based on actual player position (not feet-adjusted)
    updatePlayerDepth(px, player.y);
    
    // Use squared distance for performance
    const dx = targetPoint.x - px;
    const dy = targetPoint.y - py; // Compare with feet position
    const distanceSq = dx * dx + dy * dy;

    // Reached target point
    if (distanceSq < ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD) {
        isMoving = false;
        player.body.setVelocity(0, 0);
        if (player.isMoving) {
            player.isMoving = false;
            const animDir = getAnimationKey(player.direction);
            player.anims.stop(); // Stop current animation
            player.anims.play(`idle-${animDir}`, true);
        }
        return;
    }

    // Update last player position for depth calculations
    lastPlayerPosition.x = px;
    lastPlayerPosition.y = py - PLAYER_FEET_OFFSET_Y; // Store actual player position

    // Normalize movement vector for consistent speed
    const distance = Math.sqrt(distanceSq);
    const velocityX = (dx / distance) * MOVEMENT_SPEED;
    const velocityY = (dy / distance) * MOVEMENT_SPEED;

    // Set velocity directly without checking for changes
    player.body.setVelocity(velocityX, velocityY);
    
    // Determine direction based on velocity
    const absVX = Math.abs(velocityX);
    const absVY = Math.abs(velocityY);
    
    // Set player direction and animation
    if (absVX > absVY * 2) {
        // Mostly horizontal movement
        player.direction = velocityX > 0 ? 'right' : 'right'; // Use right animation but flip
        player.setFlipX(velocityX < 0); // Flip sprite horizontally if moving left
    } else if (absVY > absVX * 2) {
        // Mostly vertical movement
        player.direction = velocityY > 0 ? 'down' : 'up';
        player.setFlipX(false);
    } else {
        // Diagonal movement
        if (velocityY > 0) {
            player.direction = 'down-right';
        } else {
            player.direction = 'up-right';
        }
        player.setFlipX(velocityX < 0); // Flip sprite horizontally if moving left
    }
    
    // Play appropriate animation if not already playing
    if (!player.isMoving || player.lastDirection !== player.direction) {
        player.anims.play(`walk-${player.direction}`, true);
        player.isMoving = true;
        player.lastDirection = player.direction;
    }

    // Stop if collision detected
    if (player.body.blocked.none === false) {
        isMoving = false;
        player.body.setVelocity(0, 0);
        if (player.isMoving) {
            player.isMoving = false;
            const animDir = getAnimationKey(player.direction);
            player.anims.stop(); // Stop current animation
            player.anims.play(`idle-${animDir}`, true);
        }
    }
}

function getStartingRoomCenter(startRoomId) {
    // Default position if rooms not initialized yet
    const defaultPos = { x: 160, y: 144 };
    
    // If rooms are available, get the actual room position
    if (window.rooms && window.rooms[startRoomId]) {
        const roomPos = window.rooms[startRoomId].position;
        // Center of 320x288 room
        return {
            x: roomPos.x + 160,
            y: roomPos.y + 144
        };
    }
    
    // Fallback to reasonable center position for reception room
    // Reception is typically at (0,0) so center would be (160, 144)
    return defaultPos;
}

// Export for global access
window.createPlayer = createPlayer;
window.pauseKeyboardInput = pauseKeyboardInput;
window.resumeKeyboardInput = resumeKeyboardInput;

console.log('✅ Player module loaded - keyboard control functions exported to window:', {
    createPlayer: typeof window.createPlayer,
    pauseKeyboardInput: typeof window.pauseKeyboardInput,
    resumeKeyboardInput: typeof window.resumeKeyboardInput
}); 