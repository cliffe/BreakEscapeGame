/**
 * NPCSpriteManager - NPC Sprite Creation and Management
 * 
 * Manages creation, positioning, animation, and lifecycle of NPC sprites
 * in the game world.
 * 
 * @module npc-sprites
 */

import { TILE_SIZE } from '../utils/constants.js?v=8';

/**
 * Create an NPC sprite in the game world
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Object} npc - NPC data from scenario
 * @param {Object} roomData - Room information (position, ID, etc.)
 * @returns {Phaser.Sprite|null} Created sprite instance or null if invalid
 */
export function createNPCSprite(scene, npc, roomData) {
    if (!npc || !npc.id) {
        console.warn('❌ Cannot create NPC sprite: invalid NPC data');
        return null;
    }
    
    try {
        // Extract sprite configuration
        const spriteSheet = npc.spriteSheet || 'hacker';
        const config = npc.spriteConfig || {};
        const idleFrame = config.idleFrame || 20;
        
        // Verify texture exists
        if (!scene.textures.exists(spriteSheet)) {
            console.warn(`❌ NPC ${npc.id}: sprite sheet "${spriteSheet}" not found`);
            return null;
        }
        
        // Calculate world position
        const worldPos = calculateNPCWorldPosition(npc, roomData);
        if (!worldPos) {
            console.warn(`❌ NPC ${npc.id}: invalid position configuration`);
            return null;
        }
        
        // Create sprite
        const sprite = scene.add.sprite(worldPos.x, worldPos.y, spriteSheet, idleFrame);
        sprite.npcId = npc.id; // Tag for identification
        sprite._isNPC = true; // Mark as NPC sprite
        
        // Enable physics
        scene.physics.add.existing(sprite);
        // Set smaller collision box at the feet (matching player collision: 18x10 with similar offset)
        sprite.body.setSize(18, 10); // Collision body size (wider for better hit detection)
        sprite.body.setOffset(23, 50); // Offset for feet position (64px sprite, adjusted for wider box)
        
        // Add friction to prevent NPCs from sliding far when pushed
        // High drag causes velocity to quickly decay (good for stationary NPCs)
        // High linear damping provides additional deceleration (complements drag)
        sprite.body.setDrag(0.95); // Drag: 0.95 = lose 95% of velocity per second
        
        // Set up animations
        setupNPCAnimations(scene, sprite, spriteSheet, config, npc.id);
        
        // Start idle animation (default facing down)
        const idleAnimKey = `npc-${npc.id}-idle`;
        if (sprite.anims.exists(idleAnimKey)) {
            sprite.play(idleAnimKey, true);
            console.log(`▶️ [${npc.id}] Playing initial idle animation: ${idleAnimKey}`);
        } else {
            console.warn(`⚠️ [${npc.id}] Idle animation not found: ${idleAnimKey}`);
        }
        
        // Set depth (same system as player: bottomY + 0.5)
        updateNPCDepth(sprite);
        
        // Store reference in NPC data for later access
        npc._sprite = sprite;
        
        console.log(`✅ NPC sprite created: ${npc.id} at (${worldPos.x}, ${worldPos.y})`);
        
        return sprite;
    } catch (error) {
        console.error(`❌ Error creating NPC sprite for ${npc.id}:`, error);
        return null;
    }
}

/**
 * Calculate NPC's world position from scenario data
 * 
 * Supports two position formats:
 * - Grid coordinates: { x: 5, y: 3 } (tiles from room origin)
 * - Pixel coordinates: { px: 640, py: 480 } (absolute world space)
 * 
 * @param {Object} npc - NPC data with position property
 * @param {Object} roomData - Room data for offset calculation
 * @returns {Object|null} {x, y} world coordinates or null if invalid
 */
export function calculateNPCWorldPosition(npc, roomData) {
    const position = npc.position;
    
    if (!position) {
        return null;
    }
    
    // Support pixel coordinates (absolute positioning)
    if (position.px !== undefined && position.py !== undefined) {
        return {
            x: position.px,
            y: position.py
        };
    }
    
    // Support grid coordinates (tile-based positioning)
    if (position.x !== undefined && position.y !== undefined) {
        const roomWorldX = roomData.worldX || 0;
        const roomWorldY = roomData.worldY || 0;
        
        return {
            x: roomWorldX + (position.x * TILE_SIZE),
            y: roomWorldY + (position.y * TILE_SIZE)
        };
    }
    
    return null;
}

/**
 * Set up animations for an NPC sprite
 *
 * Creates animation sequences based on sprite configuration.
 * Supports: idle (8 directions), walk (8 directions), greeting, and talking animations.
 *
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} sprite - NPC sprite
 * @param {string} spriteSheet - Texture key
 * @param {Object} config - Animation configuration
 * @param {string} npcId - NPC identifier for animation key naming
 */
export function setupNPCAnimations(scene, sprite, spriteSheet, config, npcId) {
    console.log(`\n🎨 Setting up animations for NPC: ${npcId} (spriteSheet: ${spriteSheet})`);
    const animPrefix = config.animPrefix || 'idle';

    // ===== IDLE ANIMATIONS (8 directions) =====
    // Idle animations for 5 base directions (left uses right with flipX)
    const idleAnimations = [
        { dir: 'right', frame: 0 },
        { dir: 'down', frame: 5 },
        { dir: 'up', frame: 10 },
        { dir: 'up-right', frame: 15 },
        { dir: 'down-right', frame: 20 }
    ];

    idleAnimations.forEach(anim => {
        const animKey = `npc-${npcId}-idle-${anim.dir}`;
        if (!scene.anims.exists(animKey)) {
            scene.anims.create({
                key: animKey,
                frames: [{ key: spriteSheet, frame: anim.frame }],
                frameRate: config.idleFrameRate || 4,
                repeat: -1
            });
        }
    });

    // Create mirrored idle animations for left directions
    // These use the same animation keys but will be flipped with sprite.setFlipX(true)
    const leftIdleAnimations = [
        { dir: 'left', mirrorDir: 'right' },
        { dir: 'up-left', mirrorDir: 'up-right' },
        { dir: 'down-left', mirrorDir: 'down-right' }
    ];

    leftIdleAnimations.forEach(anim => {
        const animKey = `npc-${npcId}-idle-${anim.dir}`;
        const mirrorKey = `npc-${npcId}-idle-${anim.mirrorDir}`;
        if (!scene.anims.exists(animKey) && scene.anims.exists(mirrorKey)) {
            // Create alias - left directions will use right animations with flipX
            const mirrorAnim = scene.anims.get(mirrorKey);
            scene.anims.create({
                key: animKey,
                frames: mirrorAnim.frames,
                frameRate: mirrorAnim.frameRate,
                repeat: mirrorAnim.repeat
            });
        }
    });

    // Legacy idle animation (default facing down) for backward compatibility
    const idleStart = config.idleFrameStart || 20;
    const idleEnd = config.idleFrameEnd || 23;

    if (!scene.anims.exists(`npc-${npcId}-idle`)) {
        scene.anims.create({
            key: `npc-${npcId}-idle`,
            frames: scene.anims.generateFrameNumbers(spriteSheet, {
                start: idleStart,
                end: idleEnd
            }),
            frameRate: config.idleFrameRate || 4,
            repeat: -1
        });
    }

    // ===== WALK ANIMATIONS (8 directions) =====
    // Walk animations for 5 base directions (left uses right with flipX)
    // Frame layout (standard hacker spritesheet 64x64):
    //   Row 0 (right): frames 0-4
    //   Row 1 (down): frames 5-9
    //   Row 2 (up): frames 10-14
    //   Row 3 (up-right): frames 15-19
    //   Row 4 (down-right): frames 20-24
    const walkAnimations = [
        { dir: 'right', start: 1, end: 4 },
        { dir: 'down', start: 6, end: 9 },
        { dir: 'up', start: 11, end: 14 },
        { dir: 'up-right', start: 16, end: 19 },
        { dir: 'down-right', start: 21, end: 24 }
    ];

    walkAnimations.forEach(anim => {
        const animKey = `npc-${npcId}-walk-${anim.dir}`;
        if (!scene.anims.exists(animKey)) {
            const frames = scene.anims.generateFrameNumbers(spriteSheet, {
                start: anim.start,
                end: anim.end
            });
            console.log(`  📋 Walk ${anim.dir}: frames ${anim.start}-${anim.end}, generated ${frames.length} frames`);
            scene.anims.create({
                key: animKey,
                frames: frames,
                frameRate: 8,
                repeat: -1
            });
            console.log(`✅ Created walk animation: ${animKey}`);
        } else {
            console.log(`⚠️ Walk animation already exists: ${animKey}`);
        }
    });

    // Create mirrored walk animations for left directions
    const leftWalkAnimations = [
        { dir: 'left', mirrorDir: 'right' },
        { dir: 'up-left', mirrorDir: 'up-right' },
        { dir: 'down-left', mirrorDir: 'down-right' }
    ];

    leftWalkAnimations.forEach(anim => {
        const animKey = `npc-${npcId}-walk-${anim.dir}`;
        const mirrorKey = `npc-${npcId}-walk-${anim.mirrorDir}`;
        if (!scene.anims.exists(animKey) && scene.anims.exists(mirrorKey)) {
            // Create alias - left directions will use right animations with flipX
            const mirrorAnim = scene.anims.get(mirrorKey);
            scene.anims.create({
                key: animKey,
                frames: mirrorAnim.frames,
                frameRate: mirrorAnim.frameRate,
                repeat: mirrorAnim.repeat
            });
        }
    });

    console.log(`📊 Walk animations summary for ${npcId}:`);
    ['right', 'down', 'up', 'up-right', 'down-right', 'left', 'up-left', 'down-left'].forEach(dir => {
        const key = `npc-${npcId}-walk-${dir}`;
        console.log(`   ${dir}: ${scene.anims.exists(key) ? '✅' : '❌'} ${key}`);
    });

    // ===== OPTIONAL ANIMATIONS =====
    // Optional: Greeting animation (wave or nod)
    if (config.greetFrameStart !== undefined && config.greetFrameEnd !== undefined) {
        if (!scene.anims.exists(`npc-${npcId}-greet`)) {
            scene.anims.create({
                key: `npc-${npcId}-greet`,
                frames: scene.anims.generateFrameNumbers(spriteSheet, {
                    start: config.greetFrameStart,
                    end: config.greetFrameEnd
                }),
                frameRate: 8,
                repeat: 0
            });
        }
    }

    // Optional: Talking animation (subtle movement)
    if (config.talkFrameStart !== undefined && config.talkFrameEnd !== undefined) {
        if (!scene.anims.exists(`npc-${npcId}-talk`)) {
            scene.anims.create({
                key: `npc-${npcId}-talk`,
                frames: scene.anims.generateFrameNumbers(spriteSheet, {
                    start: config.talkFrameStart,
                    end: config.talkFrameEnd
                }),
                frameRate: 6,
                repeat: -1
            });
        }
    }

    console.log(`✅ Animation setup complete for ${npcId}\n`);
}

/**
 * Update NPC sprite depth based on Y position
 * 
 * Uses same system as player (bottomY + 0.5) to ensure correct
 * perspective in top-down view.
 * 
 * @param {Phaser.Sprite} sprite - NPC sprite to update
 */
export function updateNPCDepth(sprite) {
    if (!sprite || !sprite.body) return;
    
    // Get the bottom of the sprite (feet position)
    const spriteBottomY = sprite.y + (sprite.displayHeight / 2);
    
    // Set depth using standard formula
    const depth = spriteBottomY + 0.5; // World Y + sprite layer offset
    sprite.setDepth(depth);
}

/**
 * Create collision between NPC sprite and player
 * 
 * Includes collision callback for patrolling NPCs to route around the player.
 * 
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} npcSprite - NPC sprite
 * @param {Phaser.Sprite} player - Player sprite
 */
export function createNPCCollision(scene, npcSprite, player) {
    if (!npcSprite || !player) {
        console.warn('❌ Cannot create NPC collision: missing sprites');
        return;
    }
    
    try {
        // Add collider with callback for NPC-player collision handling
        // Patrolling NPCs will route around the player using path recalculation
        scene.physics.add.collider(
            npcSprite, 
            player,
            () => {
                handleNPCPlayerCollision(npcSprite, player);
            }
        );
        console.log(`✅ NPC collision created for ${npcSprite.npcId} (with avoidance callback)`);
    } catch (error) {
        console.error('❌ Error creating NPC collision:', error);
    }
}

/**
 * Play animation on NPC sprite
 * 
 * @param {Phaser.Sprite} sprite - NPC sprite
 * @param {string} animKey - Animation key to play
 * @returns {boolean} True if animation played, false if not found
 */
export function playNPCAnimation(sprite, animKey) {
    if (!sprite || !sprite.anims) {
        return false;
    }
    
    if (sprite.anims.exists(animKey)) {
        sprite.play(animKey);
        return true;
    }
    
    return false;
}

/**
 * Return NPC to idle animation
 * 
 * @param {Phaser.Sprite} sprite - NPC sprite
 * @param {string} npcId - NPC identifier
 */
export function returnNPCToIdle(sprite, npcId) {
    if (!sprite) return;
    
    const idleKey = `npc-${npcId}-idle`;
    if (sprite.anims.exists(idleKey)) {
        sprite.play(idleKey, true);
    }
}

/**
 * Destroy NPC sprite
 * 
 * @param {Phaser.Sprite} sprite - NPC sprite to destroy
 */
export function destroyNPCSprite(sprite) {
    if (sprite && !sprite.destroyed) {
        sprite.destroy();
    }
}

/**
 * Update all NPC depths in a collection
 * 
 * Call this if NPCs move, or after player sorts.
 * 
 * @param {Array} sprites - Array of NPC sprites
 */
export function updateNPCDepths(sprites) {
    if (!sprites || !Array.isArray(sprites)) return;
    
    sprites.forEach(sprite => {
        if (sprite && !sprite.destroyed) {
            updateNPCDepth(sprite);
        }
    });
}

/**
 * Set up wall collisions for an NPC sprite
 * 
 * Applies all wall collision boxes in the room to the NPC, similar to player.
 * 
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} npcSprite - NPC sprite
 * @param {string} roomId - Room ID where NPC is located
 */
export function setupNPCWallCollisions(scene, npcSprite, roomId) {
    if (!npcSprite || !npcSprite.body) {
        return;
    }
    
    const game = scene || window.game;
    if (!game) {
        console.warn('❌ Cannot set up NPC wall collisions: no game reference');
        return;
    }
    
    const room = window.rooms ? window.rooms[roomId] : null;
    if (!room || !room.wallCollisionBoxes) {
        return;
    }
    
    // Add collision with all wall collision boxes in the room
    room.wallCollisionBoxes.forEach(wallBox => {
        if (wallBox.body) {
            game.physics.add.collider(npcSprite, wallBox);
        }
    });
    
    console.log(`✅ NPC wall collisions set up for ${npcSprite.npcId} in room ${roomId}`);
}

/**
 * Set up chair collisions for an NPC sprite
 * 
 * Applies all chair objects in the room to the NPC, similar to player.
 * Also includes chairs from all other rooms via window.chairs.
 * 
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} npcSprite - NPC sprite
 * @param {string} roomId - Room ID where NPC is located
 */
export function setupNPCChairCollisions(scene, npcSprite, roomId) {
    if (!npcSprite || !npcSprite.body) {
        return;
    }
    
    const game = scene || window.game;
    if (!game) {
        console.warn('❌ Cannot set up NPC chair collisions: no game reference');
        return;
    }
    
    let chairsAdded = 0;
    
    // Collision with chairs from the current room (stored in room.objects)
    const room = window.rooms ? window.rooms[roomId] : null;
    if (room && room.objects) {
        Object.values(room.objects).forEach(obj => {
            if (obj && obj.body && obj.hasWheels) {
                game.physics.add.collider(npcSprite, obj);
                chairsAdded++;
            }
        });
    }
    
    // Collision with all chairs from other rooms (global array includes chairs being initialized)
    if (window.chairs && Array.isArray(window.chairs)) {
        window.chairs.forEach(chair => {
            if (chair && chair.body && !chair._npcCollisionSetup) {
                // Avoid duplicate collisions - only collide if not already in current room
                if (!room || !room.objects || !room.objects[chair.objectId]) {
                    game.physics.add.collider(npcSprite, chair);
                    chairsAdded++;
                }
            }
        });
    }
    
    console.log(`✅ NPC chair collisions set up for ${npcSprite.npcId}: added collisions with ${chairsAdded} chairs`);
}

/**
 * Set up table collisions for an NPC sprite
 * 
 * Applies all table objects in the room to the NPC so they can't walk through tables.
 * 
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} npcSprite - NPC sprite
 * @param {string} roomId - Room ID where NPC is located
 */
export function setupNPCTableCollisions(scene, npcSprite, roomId) {
    if (!npcSprite || !npcSprite.body) {
        return;
    }
    
    const game = scene || window.game;
    if (!game) {
        console.warn('❌ Cannot set up NPC table collisions: no game reference');
        return;
    }
    
    const room = window.rooms ? window.rooms[roomId] : null;
    if (!room || !room.objects) {
        return;
    }
    
    let tablesAdded = 0;
    
    // Collision with all table objects in the room
    Object.values(room.objects).forEach(obj => {
        // Tables are identified by their object name or by checking if they're static bodies
        // Look for objects that came from the 'table' type in processObject
        if (obj && obj.body && obj.body.static) {
            // Check if this looks like a table (has scenarioData.type === 'table' or name includes 'desk')
            const isTable = (obj.scenarioData && obj.scenarioData.type === 'table') || 
                           (obj.name && obj.name.toLowerCase().includes('desk'));
            
            if (isTable) {
                game.physics.add.collider(npcSprite, obj);
                tablesAdded++;
            }
        }
    });
    
    if (tablesAdded > 0) {
        console.log(`✅ NPC table collisions set up for ${npcSprite.npcId}: added collisions with ${tablesAdded} tables`);
    }
}

/**
 * Set up all collisions for an NPC sprite (walls, tables, chairs, and other static objects)
 * 
 * Called when an NPC sprite is created to apply full collision setup.
 * 
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} npcSprite - NPC sprite
 * @param {string} roomId - Room ID where NPC is located
 */
export function setupNPCEnvironmentCollisions(scene, npcSprite, roomId) {
    setupNPCWallCollisions(scene, npcSprite, roomId);
    setupNPCTableCollisions(scene, npcSprite, roomId);
    setupNPCChairCollisions(scene, npcSprite, roomId);
}

/**
 * Set up collisions between an NPC sprite and all other NPCs in the room
 * 
 * Called after creating each NPC sprite to enable NPC-to-NPC collision detection.
 * 
 * @param {Phaser.Scene} scene - Phaser scene instance
 * @param {Phaser.Sprite} npcSprite - NPC sprite to collide with others
 * @param {string} roomId - Room ID where NPC is located
 * @param {Array} allNPCSprites - Array of all NPC sprites in the room
 */
export function setupNPCToNPCCollisions(scene, npcSprite, roomId, allNPCSprites) {
    if (!npcSprite || !npcSprite.body) {
        return;
    }
    
    if (!allNPCSprites || !Array.isArray(allNPCSprites)) {
        return;
    }
    
    const game = scene || window.game;
    if (!game) {
        console.warn('❌ Cannot set up NPC-to-NPC collisions: no game reference');
        return;
    }
    
    // Add collision with all other NPCs
    let collisionsAdded = 0;
    allNPCSprites.forEach(otherNPC => {
        if (otherNPC && otherNPC !== npcSprite && otherNPC.body) {
            // Add collider with collision callback for avoidance
            game.physics.add.collider(
                npcSprite, 
                otherNPC,
                () => {
                    // Collision detected - handle NPC-to-NPC avoidance
                    handleNPCCollision(npcSprite, otherNPC);
                }
            );
            collisionsAdded++;
        }
    });
    
    if (collisionsAdded > 0) {
        console.log(`👥 NPC ${npcSprite.npcId}: ${collisionsAdded} NPC-to-NPC collision(s) set up with avoidance`);
    }
}

/**
 * Check if a position is safe for NPC movement (not blocked by walls/tables)
 * 
 * Uses raycasting to detect collisions with environment obstacles.
 * 
 * @param {Phaser.Sprite} sprite - NPC sprite to check
 * @param {number} testX - X position to test
 * @param {number} testY - Y position to test
 * @param {string} roomId - Room ID for collision context
 * @returns {boolean} True if position is safe, false if blocked
 */
function isPositionSafe(sprite, testX, testY, roomId) {
    if (!sprite || !sprite.body) return false;
    
    const room = window.rooms ? window.rooms[roomId] : null;
    if (!room) return false;
    
    // Get collision boundaries for this sprite
    const spriteWidth = sprite.body.width;
    const spriteHeight = sprite.body.height;
    const spriteOffsetX = sprite.body.offset.x;
    const spriteOffsetY = sprite.body.offset.y;
    
    // Calculate sprite bounds at test position
    const testBounds = {
        left: testX + spriteOffsetX,
        right: testX + spriteOffsetX + spriteWidth,
        top: testY + spriteOffsetY,
        bottom: testY + spriteOffsetY + spriteHeight
    };
    
    // Check collision with walls
    if (room.wallCollisionBoxes && Array.isArray(room.wallCollisionBoxes)) {
        for (const wallBox of room.wallCollisionBoxes) {
            if (wallBox && wallBox.body) {
                try {
                    const wallBounds = wallBox.body.getBounds();
                    if (wallBounds && boundsOverlap(testBounds, wallBounds)) {
                        return false;
                    }
                } catch (e) {
                    console.warn(`⚠️ Error getting wallBox bounds:`, e);
                }
            }
        }
    }
    
    // Check collision with tables
    if (room.objects) {
        for (const obj of Object.values(room.objects)) {
            if (obj && obj.body && obj.body.static) {
                // Check if this is a table
                const isTable = (obj.scenarioData && obj.scenarioData.type === 'table') || 
                               (obj.name && obj.name.toLowerCase().includes('desk'));
                
                if (isTable) {
                    try {
                        const objBounds = obj.body.getBounds();
                        if (objBounds && boundsOverlap(testBounds, objBounds)) {
                            return false;
                        }
                    } catch (e) {
                        console.warn(`⚠️ Error getting table bounds for ${obj.name}:`, e);
                    }
                }
            }
        }
    }
    
    return true;
}

/**
 * Check if two bounding rectangles overlap
 * 
 * @param {Object} bounds1 - {left, right, top, bottom}
 * @param {Object} bounds2 - {left, right, top, bottom} or Phaser Bounds object
 * @returns {boolean} True if bounds overlap
 */
function boundsOverlap(bounds1, bounds2) {
    if (!bounds1 || !bounds2) {
        return false;
    }
    
    // Handle Phaser Bounds object format
    const b2 = {
        left: bounds2.x !== undefined ? bounds2.x : bounds2.left,
        right: bounds2.x !== undefined ? bounds2.x + bounds2.width : bounds2.right,
        top: bounds2.y !== undefined ? bounds2.y : bounds2.top,
        bottom: bounds2.y !== undefined ? bounds2.y + bounds2.height : bounds2.bottom
    };
    
    return !(
        bounds1.right < b2.left ||
        bounds1.left > b2.right ||
        bounds1.bottom < b2.top ||
        bounds1.top > b2.bottom
    );
}

/**
 * Find safe collision avoidance position when NPC bumps into obstacle
 * 
 * DEPRECATED: No longer used. Collision handlers now use velocity-based movement.
 * Kept for reference/potential future use.
 * 
 * Tries multiple directions (NE, N, E, SE, etc.) to find safe space.
 * Falls back to smaller movements if needed.
 * 
 * @param {Phaser.Sprite} npcSprite - NPC sprite
 * @param {number} targetDistance - Distance to try moving (7px nominal)
 * @param {string} roomId - Room ID for collision checking
 * @returns {Object} {x, y, moved} - Safe position and whether position changed
 */
function findSafeCollisionPosition(npcSprite, targetDistance, roomId) {
    if (!npcSprite) {
        console.error('❌ findSafeCollisionPosition: npcSprite is undefined');
        return { x: 0, y: 0, moved: false, direction: 'error', distance: 0 };
    }

    const startX = npcSprite.x;
    const startY = npcSprite.y;
    
    // Try multiple directions in priority order (NE first, then clockwise)
    const directions = [
        { name: 'NE', dx: -1, dy: -1 },  // North-East (primary avoidance direction)
        { name: 'N',  dx:  0, dy: -1 },  // North
        { name: 'E',  dx:  1, dy:  0 },  // East
        { name: 'SE', dx:  1, dy:  1 },  // South-East
        { name: 'S',  dx:  0, dy:  1 },  // South
        { name: 'W',  dx: -1, dy:  0 },  // West
        { name: 'NW', dx: -1, dy:  1 },  // North-West (corrected: -x, +y)
        { name: 'SW', dx:  1, dy:  1 }   // South-West
    ];
    
    // Try decreasing distances (7px, 6px, 5px, etc.) to find safe position
    for (let distance = targetDistance; distance >= 3; distance--) {
        for (const dir of directions) {
            // Calculate movement (normalized by sqrt(2) for diagonals)
            const magnitude = Math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
            const moveX = (dir.dx / magnitude) * distance;
            const moveY = (dir.dy / magnitude) * distance;
            
            const testX = startX + moveX;
            const testY = startY + moveY;
            
            if (isPositionSafe(npcSprite, testX, testY, roomId)) {
                console.log(`✅ Found safe ${dir.name} position at distance ${distance.toFixed(1)}px`);
                return { x: testX, y: testY, moved: true, direction: dir.name, distance };
            }
        }
    }
    
    // If no safe position found, return original position
    console.warn(`⚠️ Could not find safe collision avoidance position, staying in place`);
    return { x: startX, y: startY, moved: false, direction: 'blocked', distance: 0 };
}

/**
 * Check if an NPC can move in a given direction without hitting walls/tables
 * Uses raycasting in the direction of movement to detect obstacles
 * 
 * @param {Phaser.Sprite} npcSprite - NPC sprite to check
 * @param {number} velocityX - X component of velocity direction
 * @param {number} velocityY - Y component of velocity direction
 * @param {string} roomId - Room ID for collision checking
 * @param {boolean} ignoreNPCs - If true, only check walls/tables (ignore NPC blockers)
 * @returns {boolean} True if movement in this direction is safe
 */
function isDirectionSafe(npcSprite, velocityX, velocityY, roomId, ignoreNPCs) {
    if (!npcSprite || !roomId) return true; // Default to safe if can't validate
    
    const room = window.rooms?.[roomId];
    if (!room || !room.wallCollisionBoxes) return true;
    
    // Normalize velocity and calculate test position ahead
    const speed = Math.sqrt(velocityX * velocityX + velocityY * velocityY);
    if (speed === 0) return true;
    
    const normalizedX = velocityX / speed;
    const normalizedY = velocityY / speed;
    
    // Check position 10 pixels ahead in movement direction
    const testDistance = 10;
    const testX = npcSprite.x + normalizedX * testDistance;
    const testY = npcSprite.y + normalizedY * testDistance;
    
    // Check if test position collides with any walls/tables
    for (const wallBox of room.wallCollisionBoxes) {
        if (wallBox.body) {
            // Simple AABB overlap check
            const npcBounds = npcSprite.getBounds();
            const testBounds = new Phaser.Geom.Rectangle(
                testX - npcBounds.width / 2,
                testY - npcBounds.height / 2,
                npcBounds.width,
                npcBounds.height
            );
            const wallBounds = wallBox.getBounds();
            
            if (Phaser.Geom.Rectangle.Overlaps(testBounds, wallBounds)) {
                return false; // Direction blocked by wall/table
            }
        }
    }
    
    return true; // Direction is safe
}

/**
 * Handle NPC-to-NPC collision by inserting an avoidance waypoint
 * 
 * When two NPCs collide during wayfinding:
 * 1. Get NPC's current travel direction
 * 2. Create a temporary waypoint 10px to the right of that direction
 * 3. Insert it as the next waypoint (moving current target back)
 * 4. Recalculate path to new avoidance waypoint
 * 5. Physics handles separation naturally
 * 
 * This allows NPCs to intelligently route around each other rather than just bumping.
 * 
 * @param {Phaser.Sprite} npcSprite - NPC sprite that collided
 * @param {Phaser.Sprite} otherNPC - Other NPC sprite it collided with
 */
function handleNPCCollision(npcSprite, otherNPC) {
    if (!npcSprite || !otherNPC || npcSprite.destroyed || otherNPC.destroyed) {
        return;
    }

    // Get behavior instances for both NPCs
    const npcBehavior = window.npcBehaviorManager?.getBehavior(npcSprite.npcId);
    const otherBehavior = window.npcBehaviorManager?.getBehavior(otherNPC.npcId);

    if (!npcBehavior) {
        return;
    }

    // Only handle if NPC is in patrol or face_player mode with waypoints
    // (face_player is also a valid patrolling state, just with player-facing behavior)
    const isValidPatrolState = npcBehavior.currentState === 'patrol' || npcBehavior.currentState === 'face_player';
    if (!isValidPatrolState || !npcBehavior.patrolTarget || 
        !npcBehavior.config.patrol.waypoints || !Array.isArray(npcBehavior.config.patrol.waypoints) ||
        npcBehavior.config.patrol.waypoints.length === 0) {
        return;
    }

    // Get room context first - we need this for both collision checking and waypoint validation
    // Use npcBehavior's roomId which is always set, as fallback to window.player?.currentRoom
    const roomId = npcBehavior.roomId || window.player?.currentRoom;
    
    if (!roomId) {
        // Cannot validate collision safety without room context, skip this collision handling
        return;
    }

    // Apply velocity-based push for immediate separation
    // Note: We apply the push regardless of other NPCs (they're expected blockers),
    // but check against walls/tables only
    const pushDistance = 7; // pixels
    const neDiagonalX = -pushDistance / Math.sqrt(2); // NE direction: -x
    const neDiagonalY = -pushDistance / Math.sqrt(2); // NE direction: -y
    
    const velocityScale = 10;
    let safeVelX = neDiagonalX * velocityScale;
    let safeVelY = neDiagonalY * velocityScale;
    
    // Only check against walls/tables, not other NPCs
    // (NPCs pushing against NPCs is expected behavior for collision response)
    if (!isDirectionSafe(npcSprite, safeVelX, safeVelY, roomId, true)) {
        // Try X component only
        if (isDirectionSafe(npcSprite, safeVelX, 0, roomId, true)) {
            safeVelY = 0;
        }
        // Try Y component only
        else if (isDirectionSafe(npcSprite, 0, safeVelY, roomId, true)) {
            safeVelX = 0;
        }
        // If both X and Y are blocked by walls, reduce magnitude but still push
        // (we still need to separate from the other NPC)
        else {
            // Reduce velocity but don't zero it - we need NPC separation
            safeVelX = safeVelX * 0.5;
            safeVelY = safeVelY * 0.5;
        }
    }
    
    if (npcSprite.body) {
        npcSprite.body.setVelocity(safeVelX, safeVelY);
    }

    // When NPCs collide, insert a temporary avoidance waypoint to the side
    // Then restore the original target so they continue their patrol
    if (npcBehavior && npcBehavior.config && npcBehavior.config.patrol && 
        npcBehavior.config.patrol.waypoints && Array.isArray(npcBehavior.config.patrol.waypoints) &&
        npcBehavior.config.patrol.waypoints.length > 0) {
        
        // Get the current travel direction
        const direction = npcBehavior.direction || 'down';
        const TILE_SIZE = 32;
        
        // Map direction to perpendicular "right" vector (90° clockwise rotation)
        let rightVectorTilesX = 0, rightVectorTilesY = 0;
        switch (direction) {
            case 'right':   rightVectorTilesX = 0;    rightVectorTilesY = 1;   break;
            case 'down':    rightVectorTilesX = 1;    rightVectorTilesY = 0;   break;
            case 'left':    rightVectorTilesX = 0;    rightVectorTilesY = -1;  break;
            case 'up':      rightVectorTilesX = -1;   rightVectorTilesY = 0;   break;
            case 'down-right': rightVectorTilesX = 1; rightVectorTilesY = 1;   break;
            case 'down-left':  rightVectorTilesX = -1; rightVectorTilesY = 1;  break;
            case 'up-right':   rightVectorTilesX = 1;  rightVectorTilesY = -1; break;
            case 'up-left':    rightVectorTilesX = -1; rightVectorTilesY = -1; break;
            default:        rightVectorTilesX = 1;    rightVectorTilesY = 0;   break;
        }
        
        // Create temporary avoidance waypoint 1 tile to the right of travel direction
        const currentTileX = Math.round(npcSprite.x / TILE_SIZE);
        const currentTileY = Math.round(npcSprite.y / TILE_SIZE);
        const avoidTileX = currentTileX + rightVectorTilesX;
        const avoidTileY = currentTileY + rightVectorTilesY;
        
        // Validate coordinates
        if (typeof avoidTileX === 'number' && typeof avoidTileY === 'number' &&
            !isNaN(avoidTileX) && !isNaN(avoidTileY)) {
            
            const roomData = window.rooms?.[roomId];
            
            if (roomData) {
                const roomWorldX = roomData.worldX || 0;
                const roomWorldY = roomData.worldY || 0;
                
                // Check if avoidance waypoint is on walkable tile
                let isWalkable = true;
                if (window.npcPathfindingManager) {
                    const grid = window.npcPathfindingManager.getGrid(roomId);
                    if (grid && (avoidTileY < 0 || avoidTileY >= grid.length || 
                                 avoidTileX < 0 || avoidTileX >= grid[0].length ||
                                 grid[avoidTileY][avoidTileX] !== 0)) {
                        isWalkable = false;
                    }
                }
                
                if (isWalkable) {
                    const avoidanceWaypoint = {
                        tileX: avoidTileX,
                        tileY: avoidTileY,
                        worldX: roomWorldX + (avoidTileX * TILE_SIZE),
                        worldY: roomWorldY + (avoidTileY * TILE_SIZE),
                        isTemporary: true
                    };
                    
                    // Remove old temporary waypoint if exists
                    npcBehavior.config.patrol.waypoints = npcBehavior.config.patrol.waypoints.filter(wp => !wp.isTemporary);
                    
                    // Insert avoidance waypoint as next target (after current position in sequence)
                    const currentIndex = npcBehavior.waypointIndex || 0;
                    npcBehavior.config.patrol.waypoints.splice(currentIndex + 1, 0, avoidanceWaypoint);
                    
                    // Clear current path and force recalculation
                    npcBehavior.currentPath = [];
                    npcBehavior.patrolTarget = null;
                    npcBehavior._needsPathRecalc = true;
                    
                    console.log(`⬆️ [${npcSprite.npcId}] Bumped into ${otherNPC.npcId}, inserted avoidance waypoint at (${avoidTileX}, ${avoidTileY})`);
                    
                    // Immediately choose new waypoint (the avoidance waypoint)
                    if (typeof npcBehavior.chooseWaypointTarget === 'function') {
                        npcBehavior.chooseWaypointTarget(Date.now());
                    }
                }
            }
        }
    }
}

/**
 * Handle NPC-to-player collision by inserting an avoidance waypoint
 * 
 * When a patrolling NPC collides with the player:
 * 1. Get NPC's current travel direction
 * 2. Create a temporary waypoint 10px to the right of that direction
 * 3. Insert it as the next waypoint
 * 4. Recalculate path to new avoidance waypoint
 * 5. Physics handles separation naturally
 * 
 * Similar to NPC-to-NPC collision avoidance, allowing NPCs to navigate around the player.
 * 
 * @param {Phaser.Sprite} npcSprite - NPC sprite that collided with player
 * @param {Phaser.Sprite} player - Player sprite
 */
function handleNPCPlayerCollision(npcSprite, player) {
    if (!npcSprite || !player || npcSprite.destroyed || player.destroyed) {
        return;
    }

    // Get behavior instance for NPC
    const npcBehavior = window.npcBehaviorManager?.getBehavior(npcSprite.npcId);

    if (!npcBehavior) {
        return;
    }

    // Only handle if NPC is in patrol or face_player mode with waypoints
    const isValidPatrolState = npcBehavior.currentState === 'patrol' || npcBehavior.currentState === 'face_player';
    if (!isValidPatrolState || !npcBehavior.patrolTarget || 
        !npcBehavior.config.patrol.waypoints || !Array.isArray(npcBehavior.config.patrol.waypoints) ||
        npcBehavior.config.patrol.waypoints.length === 0) {
        return;
    }

    // Get room context first - we need this for both collision checking and waypoint validation
    const roomId = window.player?.currentRoom;
    
    if (!roomId) {
        // Cannot validate collision safety without room context, skip this collision handling
        return;
    }

    // Apply velocity-based push for immediate separation
    // Note: We apply the push regardless of the player (expected blocker),
    // but check against walls/tables only
    const pushDistance = 7; // pixels
    const neDiagonalX = -pushDistance / Math.sqrt(2); // NE direction: -x
    const neDiagonalY = -pushDistance / Math.sqrt(2); // NE direction: -y
    
    const velocityScale = 10;
    let safeVelX = neDiagonalX * velocityScale;
    let safeVelY = neDiagonalY * velocityScale;
    
    // Only check against walls/tables, not the player
    // (NPCs pushing against the player is expected behavior for collision response)
    if (!isDirectionSafe(npcSprite, safeVelX, safeVelY, roomId, true)) {
        // Try X component only
        if (isDirectionSafe(npcSprite, safeVelX, 0, roomId, true)) {
            safeVelY = 0;
        }
        // Try Y component only
        else if (isDirectionSafe(npcSprite, 0, safeVelY, roomId, true)) {
            safeVelX = 0;
        }
        // If both X and Y are blocked by walls, reduce magnitude but still push
        // (we still need to separate from the player)
        else {
            // Reduce velocity but don't zero it - we need player separation
            safeVelX = safeVelX * 0.5;
            safeVelY = safeVelY * 0.5;
        }
    }
    
    if (npcSprite.body) {
        npcSprite.body.setVelocity(safeVelX, safeVelY);
    }

    // When NPC collides with player, insert a temporary avoidance waypoint to the side
    // Then continue to original waypoint
    if (npcBehavior && npcBehavior.config && npcBehavior.config.patrol && 
        npcBehavior.config.patrol.waypoints && Array.isArray(npcBehavior.config.patrol.waypoints) &&
        npcBehavior.config.patrol.waypoints.length > 0) {
        
        // Get the current travel direction
        const direction = npcBehavior.direction || 'down';
        const TILE_SIZE = 32;
        
        // Map direction to perpendicular "right" vector (90° clockwise rotation)
        let rightVectorTilesX = 0, rightVectorTilesY = 0;
        switch (direction) {
            case 'right':   rightVectorTilesX = 0;    rightVectorTilesY = 1;   break;
            case 'down':    rightVectorTilesX = 1;    rightVectorTilesY = 0;   break;
            case 'left':    rightVectorTilesX = 0;    rightVectorTilesY = -1;  break;
            case 'up':      rightVectorTilesX = -1;   rightVectorTilesY = 0;   break;
            case 'down-right': rightVectorTilesX = 1; rightVectorTilesY = 1;   break;
            case 'down-left':  rightVectorTilesX = -1; rightVectorTilesY = 1;  break;
            case 'up-right':   rightVectorTilesX = 1;  rightVectorTilesY = -1; break;
            case 'up-left':    rightVectorTilesX = -1; rightVectorTilesY = -1; break;
            default:        rightVectorTilesX = 1;    rightVectorTilesY = 0;   break;
        }
        
        // Create temporary avoidance waypoint 1 tile to the right of travel direction
        const currentTileX = Math.round(npcSprite.x / TILE_SIZE);
        const currentTileY = Math.round(npcSprite.y / TILE_SIZE);
        const avoidTileX = currentTileX + rightVectorTilesX;
        const avoidTileY = currentTileY + rightVectorTilesY;
        
        // Validate coordinates
        if (typeof avoidTileX === 'number' && typeof avoidTileY === 'number' &&
            !isNaN(avoidTileX) && !isNaN(avoidTileY)) {
            
            const roomData = window.rooms?.[roomId];
            if (roomData) {
                const roomWorldX = roomData.worldX || 0;
                const roomWorldY = roomData.worldY || 0;
                
                // Check if avoidance waypoint is on walkable tile
                let isWalkable = true;
                if (window.npcPathfindingManager) {
                    const grid = window.npcPathfindingManager.getGrid(roomId);
                    if (grid && (avoidTileY < 0 || avoidTileY >= grid.length || 
                                 avoidTileX < 0 || avoidTileX >= grid[0].length ||
                                 grid[avoidTileY][avoidTileX] !== 0)) {
                        isWalkable = false;
                    }
                }
                
                if (isWalkable) {
                    const avoidanceWaypoint = {
                        tileX: avoidTileX,
                        tileY: avoidTileY,
                        worldX: roomWorldX + (avoidTileX * TILE_SIZE),
                        worldY: roomWorldY + (avoidTileY * TILE_SIZE),
                        isTemporary: true
                    };
                    
                    // Remove old temporary waypoint if exists
                    npcBehavior.config.patrol.waypoints = npcBehavior.config.patrol.waypoints.filter(wp => !wp.isTemporary);
                    
                    // Insert avoidance waypoint as next target (after current position in sequence)
                    const currentIndex = npcBehavior.waypointIndex || 0;
                    npcBehavior.config.patrol.waypoints.splice(currentIndex + 1, 0, avoidanceWaypoint);
                    
                    // Clear current path and force recalculation
                    npcBehavior.currentPath = [];
                    npcBehavior.patrolTarget = null;
                    npcBehavior._needsPathRecalc = true;
                    
                    console.log(`⬆️ [${npcSprite.npcId}] Bumped into player, inserted avoidance waypoint at (${avoidTileX}, ${avoidTileY})`);
                    
                    // Immediately choose new waypoint (the avoidance waypoint)
                    if (typeof npcBehavior.chooseWaypointTarget === 'function') {
                        npcBehavior.chooseWaypointTarget(Date.now());
                    }
                }
            }
        }
    }
}

/**
 * Relocate NPC sprite to a new room
 * Called during multi-room route transitions
 * 
 * @param {Phaser.Sprite} sprite - NPC sprite to relocate
 * @param {string} fromRoomId - Current room ID
 * @param {string} toRoomId - Destination room ID
 * @param {string} npcId - NPC identifier
 */
export function relocateNPCSprite(sprite, fromRoomId, toRoomId, npcId) {
    try {
        if (!sprite || sprite.destroyed) {
            console.warn(`⚠️ Cannot relocate ${npcId}: sprite is invalid`);
            return;
        }

        const toRoomData = window.rooms?.[toRoomId];
        if (!toRoomData) {
            console.warn(`⚠️ Cannot relocate ${npcId}: destination room ${toRoomId} not loaded`);
            return;
        }

        // Find door connecting the two rooms
        const doorPos = findDoorBetweenRooms(fromRoomId, toRoomId);
        if (!doorPos) {
            console.warn(`⚠️ Cannot find door between ${fromRoomId} and ${toRoomId} for ${npcId}`);
            return;
        }

        // Position NPC at the door in the new room
        const toRoomPosition = toRoomData.position;
        const roomLocalX = doorPos.x - (window.rooms[fromRoomId]?.position?.x || 0);
        const roomLocalY = doorPos.y - (window.rooms[fromRoomId]?.position?.y || 0);

        const newX = toRoomPosition.x + roomLocalX;
        const newY = toRoomPosition.y + roomLocalY;

        console.log(`🚶 [${npcId}] Relocating sprite: (${sprite.x}, ${sprite.y}) → (${newX}, ${newY})`);

        // Update sprite position
        sprite.x = newX;
        sprite.y = newY;

        // Update depth for new room
        updateNPCDepth(sprite);

        console.log(`✅ [${npcId}] Sprite relocated to ${toRoomId}`);
    } catch (error) {
        console.error(`❌ Error relocating NPC ${npcId}:`, error);
    }
}

/**
 * Find door connecting two rooms
 * Returns the world position of the door connecting fromRoom to toRoom
 *
 * @param {string} fromRoomId - Source room ID
 * @param {string} toRoomId - Destination room ID
 * @returns {Object|null} Door position {x, y} in world coordinates or null
 */
function findDoorBetweenRooms(fromRoomId, toRoomId) {
    const fromRoom = window.rooms?.[fromRoomId];
    if (!fromRoom || !fromRoom.doorSprites) {
        return null;
    }

    // Find door sprite that connects to toRoomId
    const door = fromRoom.doorSprites.find(doorSprite => {
        // Check if this door leads to the destination room
        const doorData = doorSprite.doorData || {};
        const connectsTo = doorData.connectsToRoom || doorData.leadsTo;
        return connectsTo === toRoomId;
    });

    if (door) {
        return { x: door.x, y: door.y };
    }

    return null;
}

export default {
    createNPCSprite,
    calculateNPCWorldPosition,
    setupNPCAnimations,
    updateNPCDepth,
    createNPCCollision,
    setupNPCWallCollisions,
    setupNPCChairCollisions,
    setupNPCEnvironmentCollisions,
    setupNPCToNPCCollisions,
    playNPCAnimation,
    returnNPCToIdle,
    destroyNPCSprite,
    updateNPCDepths,
    relocateNPCSprite
};
