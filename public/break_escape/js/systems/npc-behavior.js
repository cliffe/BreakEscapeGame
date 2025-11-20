/**
 * NPC Behavior System - Core Behavior Management
 *
 * Manages all NPC behaviors including:
 * - Face Player: Turn to face player when nearby
 * - Patrol: Random movement within area (using EasyStar.js pathfinding)
 * - Personal Space: Back away if player too close
 * - Hostile: Red tint, future chase/flee behaviors
 *
 * Architecture:
 * - NPCBehaviorManager: Singleton manager for all NPC behaviors
 * - NPCBehavior: Individual behavior instance per NPC
 * - NPCPathfindingManager: Manages EasyStar pathfinding per room
 *
 * Lifecycle:
 * - Manager initialized once in game.js create()
 * - Behaviors registered per-room when sprites created
 * - Updated every frame (throttled to 50ms)
 * - Rooms never unload, so no cleanup needed
 *
 * @module npc-behavior
 */

import { TILE_SIZE } from '../utils/constants.js?v=8';
import { NPCPathfindingManager } from './npc-pathfinding.js?v=2';

/**
 * NPCBehaviorManager - Manages all NPC behaviors
 *
 * Initialized once in game.js create() phase
 * Updated every frame in game.js update() phase
 *
 * IMPORTANT: Rooms never unload, so no lifecycle management needed.
 * Behaviors persist for entire game session once registered.
 */
export class NPCBehaviorManager {
    constructor(scene, npcManager) {
        this.scene = scene;              // Phaser scene reference
        this.npcManager = npcManager;    // NPC Manager reference
        this.behaviors = new Map();      // Map<npcId, NPCBehavior>
        this.updateInterval = 50;        // Update behaviors every 50ms
        this.lastUpdate = 0;
        
        // Use the pathfinding manager created by initializeRooms()
        // It's already been initialized in rooms.js and should be available on window
        this.pathfindingManager = window.pathfindingManager;
        
        if (!this.pathfindingManager) {
            console.warn(`⚠️ Pathfinding manager not yet available, will use window.pathfindingManager when needed`);
        }

        console.log('✅ NPCBehaviorManager initialized');
    }
    
    /**
     * Get pathfinding manager (used by NPCBehavior instances)
     * Retrieves from window.pathfindingManager to ensure latest reference
     */
    getPathfindingManager() {
        return window.pathfindingManager || this.pathfindingManager;
    }

    /**
     * Register a behavior instance for an NPC sprite
     * Called when NPC sprite is created in createNPCSpritesForRoom()
     *
     * No unregister needed - rooms never unload, sprites persist
     */
    registerBehavior(npcId, sprite, config) {
        try {
            // Get latest pathfinding manager reference
            const pathfindingManager = window.pathfindingManager || this.pathfindingManager;
            const behavior = new NPCBehavior(npcId, sprite, config, this.scene, pathfindingManager);
            this.behaviors.set(npcId, behavior);
            console.log(`🤖 Behavior registered for ${npcId}`);
        } catch (error) {
            console.error(`❌ Failed to register behavior for ${npcId}:`, error);
        }
    }

    /**
     * Main update loop (called from game.js update())
     */
    update(time, delta) {
        // Throttle updates to every 50ms for performance
        if (time - this.lastUpdate < this.updateInterval) {
            return;
        }
        this.lastUpdate = time;

        // Get player position once for all behaviors
        const player = window.player;
        if (!player) {
            return; // No player yet
        }
        const playerPos = { x: player.x, y: player.y };

        for (const [npcId, behavior] of this.behaviors) {
            behavior.update(time, delta, playerPos);
        }
    }

    /**
     * Update behavior config (called from Ink tag handlers)
     */
    setBehaviorState(npcId, property, value) {
        const behavior = this.behaviors.get(npcId);
        if (behavior) {
            behavior.setState(property, value);
        }
    }

    /**
     * Get behavior instance for an NPC
     */
    getBehavior(npcId) {
        return this.behaviors.get(npcId) || null;
    }
}

/**
 * NPCBehavior - Individual NPC behavior instance
 */
class NPCBehavior {
    constructor(npcId, sprite, config, scene, pathfindingManager) {
        this.npcId = npcId;
        this.sprite = sprite;
        this.scene = scene;
        // Store pathfinding manager, but prefer window.pathfindingManager if available
        this.pathfindingManager = pathfindingManager || window.pathfindingManager;

        // Validate sprite reference
        if (!this.sprite || !this.sprite.body) {
            throw new Error(`❌ Invalid sprite provided for NPC ${npcId}`);
        }

        // Get NPC data and validate room ID
        const npcData = window.npcManager?.npcs?.get(npcId);
        if (!npcData || !npcData.roomId) {
            console.warn(`⚠️ NPC ${npcId} has no room assignment, using default`);
            this.roomId = 'unknown';
        } else {
            this.roomId = npcData.roomId;
        }

        // Verify sprite reference matches stored sprite
        if (npcData && npcData._sprite && npcData._sprite !== this.sprite) {
            console.warn(`⚠️ Sprite reference mismatch for ${npcId}`);
        }

        this.config = this.parseConfig(config || {});

        // State
        this.currentState = 'idle';
        this.direction = 'down';          // Current facing direction
        this.hostile = this.config.hostile.defaultState;
        this.influence = 0;

        // Patrol state
        this.patrolTarget = null;
        this.currentPath = [];           // Current path from EasyStar pathfinding
        this.pathIndex = 0;              // Current position in path
        this.lastPatrolChange = 0;
        this.lastPosition = { x: this.sprite.x, y: this.sprite.y };
        this.collisionRotationAngle = 0;  // Clockwise rotation angle when blocked (0-360)
        this.wasBlockedLastFrame = false; // Track block state for smooth transitions

        // Personal space state
        this.backingAway = false;

        // Animation tracking
        this.lastAnimationKey = null;
        this.isMoving = false;

        // Apply initial hostile visual if needed
        if (this.hostile) {
            this.setHostile(true);
        }

        console.log(`✅ Behavior initialized for ${npcId} in room ${this.roomId}`);
    }

    parseConfig(config) {
        // Parse and apply defaults to config
        const merged = {
            facePlayer: config.facePlayer !== undefined ? config.facePlayer : true,
            facePlayerDistance: config.facePlayerDistance || 96,
            patrol: {
                enabled: config.patrol?.enabled || false,
                speed: config.patrol?.speed || 100,
                changeDirectionInterval: config.patrol?.changeDirectionInterval || 3000,
                bounds: config.patrol?.bounds || null,
                waypoints: config.patrol?.waypoints || null,        // List of waypoints
                waypointMode: config.patrol?.waypointMode || 'sequential',  // sequential or random
                waypointIndex: 0,  // Current waypoint index for sequential mode
                // Multi-room route support
                multiRoom: config.patrol?.multiRoom || false,        // Enable multi-room patrolling
                route: config.patrol?.route || null,                 // Array of {room, waypoints} segments
                currentSegmentIndex: 0                               // Current segment in route
            },
            personalSpace: {
                enabled: config.personalSpace?.enabled || false,
                distance: config.personalSpace?.distance || 48,
                backAwaySpeed: config.personalSpace?.backAwaySpeed || 30,
                backAwayDistance: config.personalSpace?.backAwayDistance || 5
            },
            hostile: {
                defaultState: config.hostile?.defaultState || false,
                influenceThreshold: config.hostile?.influenceThreshold || -50,
                chaseSpeed: config.hostile?.chaseSpeed || 200,
                fleeSpeed: config.hostile?.fleeSpeed || 180,
                aggroDistance: config.hostile?.aggroDistance || 160
            }
        };

        // Pre-calculate squared distances for performance
        merged.facePlayerDistanceSq = merged.facePlayerDistance ** 2;
        merged.personalSpace.distanceSq = merged.personalSpace.distance ** 2;
        merged.hostile.aggroDistanceSq = merged.hostile.aggroDistance ** 2;

        // Validate multi-room route if provided
        if (merged.patrol.enabled && merged.patrol.multiRoom && merged.patrol.route && merged.patrol.route.length > 0) {
            this.validateMultiRoomRoute(merged);
        }

        // Validate and process waypoints if provided (single-room or first room of multi-room)
        if (merged.patrol.enabled && merged.patrol.waypoints && merged.patrol.waypoints.length > 0) {
            this.validateWaypoints(merged);
        }

        // Validate patrol bounds include starting position (only if no waypoints)
        if (merged.patrol.enabled && merged.patrol.bounds && (!merged.patrol.waypoints || merged.patrol.waypoints.length === 0)) {
            const bounds = merged.patrol.bounds;
            const spriteX = this.sprite.x;
            const spriteY = this.sprite.y;

            // Get room offset for bounds calculation
            const roomData = window.rooms ? window.rooms[this.roomId] : null;
            const roomWorldX = roomData?.worldX || 0;
            const roomWorldY = roomData?.worldY || 0;

            // Convert bounds to world coordinates
            const worldBounds = {
                x: roomWorldX + bounds.x,
                y: roomWorldY + bounds.y,
                width: bounds.width,
                height: bounds.height
            };

            const inBoundsX = spriteX >= worldBounds.x && spriteX <= (worldBounds.x + worldBounds.width);
            const inBoundsY = spriteY >= worldBounds.y && spriteY <= (worldBounds.y + worldBounds.height);

            if (!inBoundsX || !inBoundsY) {
                console.warn(`⚠️ NPC ${this.npcId} starting position (${spriteX}, ${spriteY}) is outside patrol bounds. Expanding bounds...`);

                // Auto-expand bounds to include starting position
                const newX = Math.min(worldBounds.x, spriteX);
                const newY = Math.min(worldBounds.y, spriteY);
                const newMaxX = Math.max(worldBounds.x + worldBounds.width, spriteX);
                const newMaxY = Math.max(worldBounds.y + worldBounds.height, spriteY);

                // Store bounds in world coordinates for easier calculation
                merged.patrol.worldBounds = {
                    x: newX,
                    y: newY,
                    width: newMaxX - newX,
                    height: newMaxY - newY
                };

                console.log(`✅ Patrol bounds expanded to include starting position`);
            } else {
                // Store bounds in world coordinates
                merged.patrol.worldBounds = worldBounds;
            }
        }

        return merged;
    }

    /**
     * Validate and process waypoints from scenario config
     * Converts tile coordinates to world coordinates
     * Validates waypoints are walkable
     */
    validateWaypoints(merged) {
        try {
            const roomData = window.rooms ? window.rooms[this.roomId] : null;
            if (!roomData) {
                console.warn(`⚠️ Cannot validate waypoints: room ${this.roomId} not found`);
                merged.patrol.waypoints = null;
                return;
            }

            const roomWorldX = roomData.worldX || 0;
            const roomWorldY = roomData.worldY || 0;

            const validWaypoints = [];

            for (const wp of merged.patrol.waypoints) {
                // Validate waypoint has x, y
                if (wp.x === undefined || wp.y === undefined) {
                    console.warn(`⚠️ Waypoint missing x or y coordinate`);
                    continue;
                }

                // Convert tile coordinates to world coordinates
                const worldX = roomWorldX + (wp.x * TILE_SIZE);
                const worldY = roomWorldY + (wp.y * TILE_SIZE);

                // Basic bounds check
                const roomBounds = window.pathfindingManager?.getBounds(this.roomId);
                if (roomBounds) {
                    // Convert tile bounds to world coordinates for comparison
                    const minWorldX = roomWorldX + (roomBounds.x * TILE_SIZE);
                    const minWorldY = roomWorldY + (roomBounds.y * TILE_SIZE);
                    const maxWorldX = minWorldX + (roomBounds.width * TILE_SIZE);
                    const maxWorldY = minWorldY + (roomBounds.height * TILE_SIZE);

                    if (worldX < minWorldX || worldX > maxWorldX || worldY < minWorldY || worldY > maxWorldY) {
                        console.warn(`⚠️ Waypoint (${wp.x}, ${wp.y}) at world (${worldX}, ${worldY}) outside patrol bounds`);
                        continue;
                    }
                }

                // Store validated waypoint with world coordinates
                validWaypoints.push({
                    tileX: wp.x,
                    tileY: wp.y,
                    worldX: worldX,
                    worldY: worldY,
                    dwellTime: wp.dwellTime || 0
                });
            }

            if (validWaypoints.length > 0) {
                merged.patrol.waypoints = validWaypoints;
                merged.patrol.waypointIndex = 0;
                console.log(`✅ Validated ${validWaypoints.length} waypoints for ${this.npcId}`);
            } else {
                console.warn(`⚠️ No valid waypoints for ${this.npcId}, using random patrol`);
                merged.patrol.waypoints = null;
            }
        } catch (error) {
            console.error(`❌ Error validating waypoints for ${this.npcId}:`, error);
            merged.patrol.waypoints = null;
        }
    }

    /**
     * Validate multi-room route configuration
     * Checks that all rooms exist and are properly connected
     * Pre-loads all route rooms for immediate access
     */
    validateMultiRoomRoute(merged) {
        try {
            const gameScenario = window.gameScenario;
            if (!gameScenario || !gameScenario.rooms) {
                console.warn(`⚠️ No scenario rooms available, disabling multi-room route for ${this.npcId}`);
                merged.patrol.multiRoom = false;
                return;
            }

            const route = merged.patrol.route;
            if (!Array.isArray(route) || route.length === 0) {
                console.warn(`⚠️ Invalid route for ${this.npcId}, disabling multi-room`);
                merged.patrol.multiRoom = false;
                return;
            }

            // Validate all rooms in route exist
            for (let i = 0; i < route.length; i++) {
                const segment = route[i];
                if (!segment.room) {
                    console.warn(`⚠️ Route segment ${i} missing room ID for ${this.npcId}`);
                    merged.patrol.multiRoom = false;
                    return;
                }

                if (!gameScenario.rooms[segment.room]) {
                    console.warn(`⚠️ Route room "${segment.room}" not found in scenario for ${this.npcId}`);
                    merged.patrol.multiRoom = false;
                    return;
                }

                // Validate waypoints in this segment
                if (segment.waypoints && Array.isArray(segment.waypoints)) {
                    for (const wp of segment.waypoints) {
                        if (wp.x === undefined || wp.y === undefined) {
                            console.warn(`⚠️ Route segment ${i} (room: ${segment.room}) has invalid waypoint`);
                            merged.patrol.multiRoom = false;
                            return;
                        }
                    }
                }
            }

            // Validate connections between consecutive rooms
            for (let i = 0; i < route.length; i++) {
                const currentRoom = route[i].room;
                const nextRoomIndex = (i + 1) % route.length; // Loop back to first room
                const nextRoom = route[nextRoomIndex].room;

                const currentRoomData = gameScenario.rooms[currentRoom];
                const connections = currentRoomData.connections || {};

                // Check if there's a door connecting current room to next room
                let isConnected = false;
                for (const [direction, connectedRooms] of Object.entries(connections)) {
                    const roomList = Array.isArray(connectedRooms) ? connectedRooms : [connectedRooms];
                    if (roomList.includes(nextRoom)) {
                        isConnected = true;
                        break;
                    }
                }

                if (!isConnected) {
                    console.warn(`⚠️ Route rooms not connected: ${currentRoom} ↔ ${nextRoom} for ${this.npcId}`);
                    merged.patrol.multiRoom = false;
                    return;
                }
            }

            // Pre-load all route rooms
            console.log(`🚪 Pre-loading ${route.length} rooms for multi-room route: ${route.map(r => r.room).join(' → ')}`);
            for (const segment of route) {
                const roomId = segment.room;
                if (window.rooms && !window.rooms[roomId]) {
                    // Pre-load the room if not already loaded
                    window.loadRoom(roomId).catch(err => {
                        console.warn(`⚠️ Failed to pre-load room ${roomId}:`, err);
                    });
                }
            }

            console.log(`✅ Multi-room route validated for ${this.npcId} with ${route.length} segments`);
        } catch (error) {
            console.error(`❌ Error validating multi-room route for ${this.npcId}:`, error);
            merged.patrol.multiRoom = false;
        }
    }

    update(time, delta, playerPos) {
        try {
            // Validate sprite
            if (!this.sprite || !this.sprite.body || this.sprite.destroyed) {
                console.warn(`⚠️ Invalid sprite for ${this.npcId}, skipping update`);
                return;
            }

            // Main behavior update logic
            // 1. Determine highest priority state
            const state = this.determineState(playerPos);

            // 2. Execute state behavior
            this.executeState(state, time, delta, playerPos);

            // 3. CRITICAL: Update depth after any movement
            // This ensures correct Y-sorting with player and other NPCs
            this.updateDepth();

        } catch (error) {
            console.error(`❌ Behavior update error for ${this.npcId}:`, error);
        }
    }

    determineState(playerPos) {
        if (!playerPos) {
            return 'idle';
        }

        // Calculate distance to player
        const dx = playerPos.x - this.sprite.x;
        const dy = playerPos.y - this.sprite.y;
        const distanceSq = dx * dx + dy * dy;

        // Check hostile state from hostile system (overrides config)
        const isHostile = window.npcHostileSystem && window.npcHostileSystem.isNPCHostile(this.npcId);
        const isKO = window.npcHostileSystem && window.npcHostileSystem.isNPCKO(this.npcId);

        // If KO, always idle
        if (isKO) {
            return 'idle';
        }

        // Priority 5: Chase (hostile + in range)
        if (isHostile && distanceSq < this.config.hostile.aggroDistanceSq) {
            return 'chase';
        }

        // Priority 3: Maintain Personal Space
        if (this.config.personalSpace.enabled && distanceSq < this.config.personalSpace.distanceSq) {
            return 'maintain_space';
        }

        // Priority 2: Patrol
        if (this.config.patrol.enabled) {
            // Check if player is in interaction range - if so, face player instead
            if (distanceSq < this.config.facePlayerDistanceSq && this.config.facePlayer) {
                return 'face_player';
            }
            return 'patrol';
        }

        // Priority 1: Face Player
        if (this.config.facePlayer && distanceSq < this.config.facePlayerDistanceSq) {
            return 'face_player';
        }

        // Priority 0: Idle
        return 'idle';
    }

    executeState(state, time, delta, playerPos) {
        this.currentState = state;

        switch (state) {
            case 'idle':
                this.sprite.body.setVelocity(0, 0);
                this.playAnimation('idle', this.direction);
                this.isMoving = false;
                break;

            case 'face_player':
                this.facePlayer(playerPos);
                this.sprite.body.setVelocity(0, 0);
                this.isMoving = false;
                break;

            case 'patrol':
                this.updatePatrol(time, delta);
                break;

            case 'maintain_space':
                this.maintainPersonalSpace(playerPos, delta);
                break;

            case 'chase':
                // Stub for future implementation
                this.updateHostileBehavior(playerPos, delta);
                break;

            case 'flee':
                // Stub for future implementation
                this.updateHostileBehavior(playerPos, delta);
                break;
        }
    }

    facePlayer(playerPos) {
        if (!this.config.facePlayer || !playerPos) return;

        const dx = playerPos.x - this.sprite.x;
        const dy = playerPos.y - this.sprite.y;

        // Calculate direction (8-way)
        this.direction = this.calculateDirection(dx, dy);

        // Play idle animation facing player
        this.playAnimation('idle', this.direction);
    }
    updatePatrol(time, delta) {
        if (!this.config.patrol.enabled) return;

        // Check if path needs recalculation (e.g., after NPC-to-NPC collision avoidance)
        if (this._needsPathRecalc && this.patrolTarget) {
            this._needsPathRecalc = false;
            console.log(`🔄 [${this.npcId}] Recalculating path to waypoint after collision avoidance`);
            
            // Clear current path and recalculate
            this.currentPath = [];
            this.pathIndex = 0;
            
            const pathfindingManager = this.pathfindingManager || window.pathfindingManager;
            if (pathfindingManager) {
                pathfindingManager.findPath(
                    this.roomId,
                    this.sprite.x,
                    this.sprite.y,
                    this.patrolTarget.x,
                    this.patrolTarget.y,
                    (path) => {
                        if (path && path.length > 0) {
                            this.currentPath = path;
                            this.pathIndex = 0;
                            console.log(`✅ [${this.npcId}] Recalculated path with ${path.length} waypoints after collision`);
                        } else {
                            console.warn(`⚠️ [${this.npcId}] Path recalculation failed after collision`);
                        }
                    }
                );
            }
            return;
        }

        // Handle dwell time at waypoint
        if (this.patrolTarget && this.patrolTarget.dwellTime && this.patrolTarget.dwellTime > 0) {
            if (this.patrolReachedTime === 0) {
                // Just reached waypoint, start dwell timer
                this.patrolReachedTime = time;
                this.sprite.body.setVelocity(0, 0);
                this.playAnimation('idle', this.direction);
                this.isMoving = false;
                console.log(`⏸️ [${this.npcId}] Dwelling at waypoint for ${this.patrolTarget.dwellTime}ms`);
                return;
            }

            // Check if dwell time expired
            const dwellElapsed = time - this.patrolReachedTime;
            if (dwellElapsed < this.patrolTarget.dwellTime) {
                // Still dwelling - face player if configured and in range
                const playerPos = window.player?.sprite ? { x: window.player.sprite.x, y: window.player.sprite.y } : null;
                if (playerPos) {
                    const distSq = (this.sprite.x - playerPos.x) ** 2 + (this.sprite.y - playerPos.y) ** 2;
                    if (distSq < this.config.facePlayerDistanceSq && this.config.facePlayer) {
                        this.facePlayer(playerPos);
                    }
                }
                return;
            }

            // Dwell time expired, reset and choose next target
            this.patrolReachedTime = 0;
            this.chooseNewPatrolTarget(time);
            return;
        }

        // Time to choose a new patrol target?
        if (!this.patrolTarget ||
            this.currentPath.length === 0 ||
            time - this.lastPatrolChange > this.config.patrol.changeDirectionInterval) {
            this.chooseNewPatrolTarget(time);
            return;
        }

        // Follow current path
        if (this.currentPath.length > 0 && this.pathIndex < this.currentPath.length) {
            const nextWaypoint = this.currentPath[this.pathIndex];
            const dx = nextWaypoint.x - this.sprite.x;
            const dy = nextWaypoint.y - this.sprite.y;
            const distance = Math.sqrt(dx * dx + dy * dy);

            // Reached waypoint? Move to next
            if (distance < 8) {
                this.pathIndex++;

                // Reached end of path? Choose new target
                if (this.pathIndex >= this.currentPath.length) {
                    this.patrolReachedTime = time; // Mark when we reached the final waypoint
                    this.chooseNewPatrolTarget(time);
                    return;
                }
                return; // Let next frame handle the new waypoint
            }

            // Move toward current waypoint
            const velocityX = (dx / distance) * this.config.patrol.speed;
            const velocityY = (dy / distance) * this.config.patrol.speed;
            this.sprite.body.setVelocity(velocityX, velocityY);

            // Update direction and animation
            this.direction = this.calculateDirection(dx, dy);
            this.playAnimation('walk', this.direction);
            this.isMoving = true;

            // console.log(`🚶 [${this.npcId}] Patrol waypoint ${this.pathIndex + 1}/${this.currentPath.length} - velocity: (${velocityX.toFixed(0)}, ${velocityY.toFixed(0)})`);
        } else {
            // No path found, choose new target
            this.chooseNewPatrolTarget(time);
        }
    }

    chooseNewPatrolTarget(time) {
        // Check if using waypoint patrol
        if (this.config.patrol.waypoints && this.config.patrol.waypoints.length > 0) {
            this.chooseWaypointTarget(time);
        } else {
            // Fall back to random patrol
            this.chooseRandomPatrolTarget(time);
        }
    }

    /**
     * Choose target from waypoint list (single-room or multi-room)
     */
    chooseWaypointTarget(time) {
        // Handle multi-room routes
        if (this.config.patrol.multiRoom && this.config.patrol.route && this.config.patrol.route.length > 0) {
            this.chooseWaypointTargetMultiRoom(time);
            return;
        }

        // Single-room waypoint patrol
        let nextWaypoint;

        if (this.config.patrol.waypointMode === 'sequential') {
            // Sequential: follow waypoints in order
            nextWaypoint = this.config.patrol.waypoints[this.config.patrol.waypointIndex];
            this.config.patrol.waypointIndex = (this.config.patrol.waypointIndex + 1) % this.config.patrol.waypoints.length;
        } else {
            // Random: pick random waypoint
            const randomIndex = Math.floor(Math.random() * this.config.patrol.waypoints.length);
            nextWaypoint = this.config.patrol.waypoints[randomIndex];
        }

        if (!nextWaypoint) {
            console.warn(`⚠️ [${this.npcId}] No valid waypoint, falling back to random patrol`);
            this.chooseRandomPatrolTarget(time);
            return;
        }

        this.patrolTarget = {
            x: nextWaypoint.worldX,
            y: nextWaypoint.worldY,
            dwellTime: nextWaypoint.dwellTime || 0
        };

        this.lastPatrolChange = time;
        this.pathIndex = 0;
        this.currentPath = [];
        this.patrolReachedTime = 0;

        // Request pathfinding to waypoint
        const pathfindingManager = this.pathfindingManager || window.pathfindingManager;
        if (!pathfindingManager) {
            console.warn(`⚠️ No pathfinding manager for ${this.npcId}`);
            return;
        }

        pathfindingManager.findPath(
            this.roomId,
            this.sprite.x,
            this.sprite.y,
            nextWaypoint.worldX,
            nextWaypoint.worldY,
            (path) => {
                if (path && path.length > 0) {
                    this.currentPath = path;
                    this.pathIndex = 0;
                    // console.log(`✅ [${this.npcId}] New waypoint path with ${path.length} waypoints to (${nextWaypoint.tileX}, ${nextWaypoint.tileY})`);
                } else {
                    // Waypoint is unreachable, NPC will choose a different target next update
                    this.currentPath = [];
                    this.patrolTarget = null;
                }
            }
        );
    }

    /**
     * Choose waypoint target for multi-room route
     * Handles transitioning between rooms when waypoints in current room are exhausted
     */
    chooseWaypointTargetMultiRoom(time) {
        const route = this.config.patrol.route;
        const currentSegmentIndex = this.config.patrol.currentSegmentIndex;
        const currentSegment = route[currentSegmentIndex];

        // Get current room's waypoints
        let currentRoomWaypoints = currentSegment.waypoints;
        if (!currentRoomWaypoints || !Array.isArray(currentRoomWaypoints) || currentRoomWaypoints.length === 0) {
            // No waypoints in this segment, move to next room
            console.log(`⏭️ [${this.npcId}] No waypoints in current segment, moving to next room`);
            this.transitionToNextRoom(time);
            return;
        }

        // Get next waypoint in current room
        let nextWaypoint;
        if (this.config.patrol.waypointMode === 'sequential') {
            nextWaypoint = currentRoomWaypoints[this.config.patrol.waypointIndex];
            this.config.patrol.waypointIndex = (this.config.patrol.waypointIndex + 1) % currentRoomWaypoints.length;

            // Check if we've completed all waypoints in this room
            if (this.config.patrol.waypointIndex === 0) {
                // Just wrapped around - all waypoints done, move to next room
                console.log(`🔄 [${this.npcId}] Completed all waypoints in room ${currentSegment.room}, transitioning...`);
                this.transitionToNextRoom(time);
                return;
            }
        } else {
            // Random: pick random waypoint
            const randomIndex = Math.floor(Math.random() * currentRoomWaypoints.length);
            nextWaypoint = currentRoomWaypoints[randomIndex];
        }

        if (!nextWaypoint) {
            console.warn(`⚠️ [${this.npcId}] No valid waypoint in multi-room route`);
            this.chooseRandomPatrolTarget(time);
            return;
        }

        // Convert tile coordinates to world coordinates for current room
        const roomData = window.rooms?.[currentSegment.room];
        if (!roomData) {
            console.warn(`⚠️ Room ${currentSegment.room} not loaded for multi-room navigation`);
            this.chooseRandomPatrolTarget(time);
            return;
        }

        const roomWorldX = roomData.position?.x || 0;
        const roomWorldY = roomData.position?.y || 0;
        const worldX = roomWorldX + (nextWaypoint.x * TILE_SIZE);
        const worldY = roomWorldY + (nextWaypoint.y * TILE_SIZE);

        this.patrolTarget = {
            x: worldX,
            y: worldY,
            dwellTime: nextWaypoint.dwellTime || 0
        };

        this.lastPatrolChange = time;
        this.pathIndex = 0;
        this.currentPath = [];
        this.patrolReachedTime = 0;

        // Request pathfinding to waypoint in current room
        const pathfindingManager = this.pathfindingManager || window.pathfindingManager;
        if (!pathfindingManager) {
            console.warn(`⚠️ No pathfinding manager for ${this.npcId}`);
            return;
        }

        pathfindingManager.findPath(
            currentSegment.room,
            this.sprite.x,
            this.sprite.y,
            worldX,
            worldY,
            (path) => {
                if (path && path.length > 0) {
                    this.currentPath = path;
                    this.pathIndex = 0;
                    console.log(`✅ [${this.npcId}] Route path with ${path.length} waypoints to (${nextWaypoint.x}, ${nextWaypoint.y}) in ${currentSegment.room}`);
                } else {
                    // Waypoint unreachable, try next room
                    console.warn(`⚠️ [${this.npcId}] Waypoint unreachable in ${currentSegment.room}, trying next room...`);
                    this.transitionToNextRoom(time);
                }
            }
        );
    }

    /**
     * Transition NPC to the next room in the multi-room route
     * Finds connecting door and relocates sprite
     */
    transitionToNextRoom(time) {
        const route = this.config.patrol.route;
        if (!route || route.length === 0) {
            console.warn(`⚠️ [${this.npcId}] No route available for room transition`);
            return;
        }

        // Move to next room in route
        const nextSegmentIndex = (this.config.patrol.currentSegmentIndex + 1) % route.length;
        const currentSegment = route[this.config.patrol.currentSegmentIndex];
        const nextSegment = route[nextSegmentIndex];

        console.log(`🚪 [${this.npcId}] Transitioning: ${currentSegment.room} → ${nextSegment.room}`);

        // Update NPC's roomId in npcManager
        const npcData = window.npcManager?.npcs?.get(this.npcId);
        if (npcData) {
            npcData.roomId = nextSegment.room;
        }

        // Update behavior's room tracking
        this.roomId = nextSegment.room;
        this.config.patrol.currentSegmentIndex = nextSegmentIndex;
        this.config.patrol.waypointIndex = 0;

        // Relocate sprite to next room
        if (window.relocateNPCSprite) {
            window.relocateNPCSprite(
                this.sprite,
                currentSegment.room,
                nextSegment.room,
                this.npcId
            );
        } else {
            console.warn(`⚠️ relocateNPCSprite not available for ${this.npcId}`);
        }

        // Choose waypoint in new room
        this.chooseNewPatrolTarget(time);
    }

    /**
     * Choose random patrol target (original behavior)
     */
    chooseRandomPatrolTarget(time) {
        // Ensure we have the latest pathfinding manager reference
        const pathfindingManager = this.pathfindingManager || window.pathfindingManager;
        
        if (!pathfindingManager) {
            console.warn(`⚠️ No pathfinding manager for ${this.npcId}`);
            return;
        }

        // Get random target position using pathfinding manager
        const targetPos = pathfindingManager.getRandomPatrolTarget(this.roomId);
        if (!targetPos) {
            console.warn(`⚠️ Could not find random patrol target for ${this.npcId}`);
            // Fall back to idle if can't find a target
            this.sprite.body.setVelocity(0, 0);
            this.playAnimation('idle', this.direction);
            this.isMoving = false;
            return;
        }

        this.patrolTarget = targetPos;
        this.lastPatrolChange = time;
        this.pathIndex = 0;
        this.currentPath = [];

        // Request pathfinding from current position to target
        pathfindingManager.findPath(
            this.roomId,
            this.sprite.x,
            this.sprite.y,
            targetPos.x,
            targetPos.y,
            (path) => {
                if (path && path.length > 0) {
                    this.currentPath = path;
                    this.pathIndex = 0;
                    console.log(`✅ [${this.npcId}] New patrol path with ${path.length} waypoints`);
                } else {
                    console.warn(`⚠️ [${this.npcId}] Pathfinding failed, target unreachable`);
                    this.currentPath = [];
                    this.patrolTarget = null;
                }
            }
        );
    }

    maintainPersonalSpace(playerPos, delta) {
        if (!this.config.personalSpace.enabled || !playerPos) {
            return false;
        }

        const dx = this.sprite.x - playerPos.x;  // Away from player
        const dy = this.sprite.y - playerPos.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance === 0) return false; // Avoid division by zero

        // Back away using velocity (physics-safe movement)
        // Normalize direction and apply velocity push
        const backAwaySpeed = this.config.personalSpace.backAwaySpeed || 30;
        const velocityX = (dx / distance) * backAwaySpeed;
        const velocityY = (dy / distance) * backAwaySpeed;
        
        if (this.sprite.body) {
            this.sprite.body.setVelocity(velocityX, velocityY);
        }

        // Face player while backing away
        this.direction = this.calculateDirection(-dx, -dy);  // Negative = face player
        this.playAnimation('idle', this.direction);  // Use idle, not walk

        this.isMoving = false;  // Not "walking", just adjusting position
        this.backingAway = true;

        return true; // Personal space behavior active
    }

    updateHostileBehavior(playerPos, delta) {
        if (!playerPos) return false;

        // Calculate distance to player
        const dx = playerPos.x - this.sprite.x;
        const dy = playerPos.y - this.sprite.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        // Get attack range from hostile system
        const attackRange = window.npcHostileSystem ?
            window.npcHostileSystem.getState(this.npcId)?.attackRange || 50 : 50;

        // If in attack range, try to attack
        if (distance <= attackRange) {
            // Stop moving
            this.sprite.body.setVelocity(0, 0);
            this.isMoving = false;

            // Face player
            this.direction = this.calculateDirection(dx, dy);
            this.playAnimation('idle', this.direction);

            // Attempt attack
            if (window.npcCombat) {
                window.npcCombat.attemptAttack(this.npcId, this.sprite);
            }

            return true;
        }

        // Chase player - move towards them
        const chaseSpeed = this.config.hostile.chaseSpeed || 120;

        // Calculate normalized direction
        const normalizedDx = dx / distance;
        const normalizedDy = dy / distance;

        // Set velocity towards player
        this.sprite.body.setVelocity(
            normalizedDx * chaseSpeed,
            normalizedDy * chaseSpeed
        );

        // Calculate and update direction
        this.direction = this.calculateDirection(dx, dy);
        this.playAnimation('walk', this.direction);
        this.isMoving = true;

        return true;
    }

    calculateDirection(dx, dy) {
        const absVX = Math.abs(dx);
        const absVY = Math.abs(dy);

        // Threshold: if one axis is > 2x the other, consider it pure cardinal
        if (absVX > absVY * 2) {
            return dx > 0 ? 'right' : 'left';
        }

        if (absVY > absVX * 2) {
            return dy > 0 ? 'down' : 'up';
        }

        // Diagonal
        if (dy > 0) {
            return dx > 0 ? 'down-right' : 'down-left';
        } else {
            return dx > 0 ? 'up-right' : 'up-left';
        }
    }

    playAnimation(state, direction) {
        // Map left directions to right with flipX
        let animDirection = direction;
        let flipX = false;

        if (direction.includes('left')) {
            animDirection = direction.replace('left', 'right');
            flipX = true;
        }

        const animKey = `npc-${this.npcId}-${state}-${animDirection}`;

        // Only change animation if different
        if (this.lastAnimationKey !== animKey) {
            // Use scene.anims to check if animation exists in the global animation manager
            if (this.scene?.anims?.exists(animKey)) {
                this.sprite.play(animKey, true);
                this.lastAnimationKey = animKey;
            } else {
                // Fallback: use idle animation if walk doesn't exist
                if (state === 'walk') {
                    const idleKey = `npc-${this.npcId}-idle-${animDirection}`;
                    if (this.scene?.anims?.exists(idleKey)) {
                        this.sprite.play(idleKey, true);
                        this.lastAnimationKey = idleKey;
                        console.warn(`⚠️ [${this.npcId}] Walk animation missing, using idle: ${idleKey}`);
                    } else {
                        console.error(`❌ [${this.npcId}] BOTH animations missing! Walk: ${animKey}, Idle: ${idleKey}`);
                    }
                }
            }
        }

        // Set flipX for left-facing directions
        this.sprite.setFlipX(flipX);
    }

    updateDepth() {
        if (!this.sprite || !this.sprite.body) return;

        // Calculate depth based on bottom Y position (same as player)
        const spriteBottomY = this.sprite.y + (this.sprite.displayHeight / 2);
        const depth = spriteBottomY + 0.5; // World Y + sprite layer offset

        // Always update depth - no caching
        // Depth determines Y-sorting, must update every frame for moving NPCs
        this.sprite.setDepth(depth);
    }

    setState(property, value) {
        switch (property) {
            case 'hostile':
                this.setHostile(value);
                break;

            case 'influence':
                this.setInfluence(value);
                break;

            case 'patrol':
                this.config.patrol.enabled = value;
                console.log(`🚶 ${this.npcId} patrol ${value ? 'enabled' : 'disabled'}`);
                break;

            case 'personalSpaceDistance':
                this.config.personalSpace.distance = value;
                this.config.personalSpace.distanceSq = value ** 2;
                console.log(`↔️ ${this.npcId} personal space: ${value}px`);
                break;

            default:
                console.warn(`⚠️ Unknown behavior property: ${property}`);
        }
    }

    setHostile(hostile) {
        if (this.hostile === hostile) return; // No change

        this.hostile = hostile;

        // Emit event for other systems to react
        if (window.eventDispatcher) {
            window.eventDispatcher.emit('npc_hostile_changed', {
                npcId: this.npcId,
                hostile: hostile
            });
        }

        if (hostile) {
            // Red tint (0xff0000 with 50% strength)
            this.sprite.setTint(0xff6666);
            console.log(`🔴 ${this.npcId} is now hostile`);
        } else {
            // Clear tint
            this.sprite.clearTint();
            console.log(`✅ ${this.npcId} is no longer hostile`);
        }
    }

    setInfluence(influence) {
        this.influence = influence;

        // Check if influence change should trigger hostile state
        const threshold = this.config.hostile.influenceThreshold;

        // Auto-trigger hostile if influence drops below threshold
        if (influence < threshold && !this.hostile) {
            this.setHostile(true);
            console.log(`⚠️ ${this.npcId} became hostile due to low influence (${influence} < ${threshold})`);
        }
        // Auto-disable hostile if influence recovers
        else if (influence >= threshold && this.hostile) {
            this.setHostile(false);
            console.log(`✅ ${this.npcId} no longer hostile (influence: ${influence})`);
        }

        console.log(`💯 ${this.npcId} influence: ${influence}`);
    }
}

// Export for module imports
export default {
    NPCBehaviorManager,
    NPCBehavior
};
