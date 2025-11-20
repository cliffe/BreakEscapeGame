/**
 * NPC PATHFINDING SYSTEM - EasyStar.js Integration
 * ================================================
 *
 * Manages pathfinding for all NPCs using EasyStar.js.
 * Each room has its own pathfinder grid based on wall collision data.
 *
 * Key Concepts:
 * - One pathfinder per room (created when room is loaded)
 * - Patrol bounds: 2 tiles from room edges (walls are on edges)
 * - Paths converted from tile coordinates to world coordinates
 * - Random patrol targets selected from valid positions within bounds
 *
 * @module npc-pathfinding
 */

import { TILE_SIZE, GRID_SIZE } from '../utils/constants.js?v=8';

const PATROL_EDGE_OFFSET = 2; // Distance from room edge (2 tiles)

/**
 * NPCPathfindingManager - Manages pathfinding for all NPCs across all rooms
 */
export class NPCPathfindingManager {
    constructor(scene) {
        this.scene = scene;
        this.pathfinders = new Map();  // Map<roomId, pathfinder>
        this.grids = new Map();         // Map<roomId, grid>
        this.roomBounds = new Map();   // Map<roomId, {x, y, width, height, mapWidth, mapHeight}>
        
        console.log('✅ NPCPathfindingManager initialized');
    }

    /**
     * Initialize pathfinder for a room
     * Called when room is loaded (from rooms.js)
     *
     * @param {string} roomId - Room identifier
     * @param {Object} roomData - Room data from window.rooms[roomId]
     * @param {Object} roomPosition - {x, y} world position of room
     */
    initializeRoomPathfinding(roomId, roomData, roomPosition) {
        try {
            console.log(`📍 initializeRoomPathfinding called for room: ${roomId}`);
            
            if (!roomData) {
                console.warn(`⚠️ Room data is null/undefined for ${roomId}`);
                return;
            }
            
            if (!roomData.map) {
                console.warn(`⚠️ Room ${roomId} has no tilemap, skipping pathfinding init`);
                console.warn(`   roomData keys: ${Object.keys(roomData).join(', ')}`);
                return;
            }

            const mapWidth = roomData.map.width;
            const mapHeight = roomData.map.height;

            console.log(`🔧 Initializing pathfinding for room ${roomId}...`);
            console.log(`   Map dimensions: ${mapWidth}x${mapHeight}`);
            console.log(`   WallsLayers count: ${roomData.wallsLayers ? roomData.wallsLayers.length : 0}`);

            // Build grid from wall collision data
            const grid = this.buildGridFromWalls(roomId, roomData, mapWidth, mapHeight);

            // Create and configure pathfinder
            const pathfinder = new EasyStar.js();
            pathfinder.setGrid(grid);
            pathfinder.setAcceptableTiles([0]);  // 0 = walkable, 1 = wall
            pathfinder.enableDiagonals();

            // Store pathfinder and grid for this room
            this.pathfinders.set(roomId, pathfinder);
            this.grids.set(roomId, grid);

            // Calculate patrol bounds (2 tiles from edges)
            const bounds = {
                x: PATROL_EDGE_OFFSET,
                y: PATROL_EDGE_OFFSET,
                width: Math.max(1, mapWidth - PATROL_EDGE_OFFSET * 2),
                height: Math.max(1, mapHeight - PATROL_EDGE_OFFSET * 2),
                mapWidth: mapWidth,
                mapHeight: mapHeight,
                worldX: roomPosition.x,
                worldY: roomPosition.y
            };

            this.roomBounds.set(roomId, bounds);

            console.log(`✅ Pathfinding initialized for room ${roomId}`);
            console.log(`   Grid: ${mapWidth}x${mapHeight} tiles | Patrol bounds: (${bounds.x}, ${bounds.y}) to (${bounds.x + bounds.width}, ${bounds.y + bounds.height})`);

        } catch (error) {
            console.error(`❌ Failed to initialize pathfinding for room ${roomId}:`, error);
            console.error('Error stack:', error.stack);
        }
    }

    /**
     * Build collision grid from wall layer data AND table objects
     * 0 = walkable, 1 = wall/obstacle
     *
     * IMPORTANT: Walls are created as collision boxes based on wall tiles by createWallCollisionBoxes().
     * This method marks the same tiles as obstacles in the pathfinding grid so NPCs avoid them.
     * Table objects are also marked from the Tiled map.
     *
     * @private
     */
    buildGridFromWalls(roomId, roomData, mapWidth, mapHeight) {
        const grid = Array(mapHeight).fill().map(() => Array(mapWidth).fill(0));

        // PASS 1: Mark all wall tiles as impassable
        // (Wall collision boxes are created from these same tiles in collision.js)
        if (!roomData.wallsLayers || roomData.wallsLayers.length === 0) {
            console.warn(`⚠️ No wall layers found for room ${roomId}, creating open grid`);
        } else {
            let wallTilesMarked = 0;
            
            // Mark all wall tiles from the tilemap
            roomData.wallsLayers.forEach(wallLayer => {
                try {
                    // Get all non-empty tiles from the wall layer
                    const allWallTiles = wallLayer.getTilesWithin(0, 0, mapWidth, mapHeight, { isNotEmpty: true });

                    allWallTiles.forEach(tile => {
                        // Mark ALL wall tiles as impassable (not just ones with collision properties)
                        // because collision.js creates collision boxes for all wall tiles
                        const tileX = tile.x;
                        const tileY = tile.y;

                        if (tileX >= 0 && tileX < mapWidth && tileY >= 0 && tileY < mapHeight) {
                            grid[tileY][tileX] = 1; // Mark as impassable
                            wallTilesMarked++;
                        }
                    });

                    console.log(`✅ Processed wall layer with ${allWallTiles.length} tiles, marked ${wallTilesMarked} as impassable`);
                } catch (error) {
                    console.error(`❌ Error processing wall layer for room ${roomId}:`, error);
                }
            });
            
            if (wallTilesMarked > 0) {
                console.log(`✅ Total wall tiles marked as obstacles: ${wallTilesMarked}`);
            }
        }

        // NEW: Mark table objects as obstacles in pathfinding grid
        if (roomData.map) {
            // Get the tables object layer from the Phaser tilemap
            const tablesLayer = roomData.map.getObjectLayer('tables');
            
            console.log(`🔍 Looking for tables object layer: ${tablesLayer ? 'Found' : 'Not found'}`);
            
            if (tablesLayer && tablesLayer.objects && tablesLayer.objects.length > 0) {
                let tablesMarked = 0;
                console.log(`📦 Processing ${tablesLayer.objects.length} table objects...`);
                
                tablesLayer.objects.forEach((tableObj, idx) => {
                    try {
                        // Convert world coordinates to tile coordinates
                        const tableWorldX = tableObj.x;
                        const tableWorldY = tableObj.y;
                        const tableWidth = tableObj.width;
                        const tableHeight = tableObj.height;

                        console.log(`  Table ${idx}: (${tableWorldX}, ${tableWorldY}) size ${tableWidth}x${tableHeight}`);

                        // Convert to tile coordinates
                        const startTileX = Math.floor(tableWorldX / TILE_SIZE);
                        const startTileY = Math.floor(tableWorldY / TILE_SIZE);
                        const endTileX = Math.ceil((tableWorldX + tableWidth) / TILE_SIZE);
                        const endTileY = Math.ceil((tableWorldY + tableHeight) / TILE_SIZE);

                        console.log(`  -> Tiles: (${startTileX}, ${startTileY}) to (${endTileX}, ${endTileY})`);

                        // Mark all tiles covered by table as impassable
                        let tilesInTable = 0;
                        for (let tileY = startTileY; tileY < endTileY; tileY++) {
                            for (let tileX = startTileX; tileX < endTileX; tileX++) {
                                if (tileX >= 0 && tileX < mapWidth && tileY >= 0 && tileY < mapHeight) {
                                    grid[tileY][tileX] = 1; // Mark as impassable
                                    tablesMarked++;
                                    tilesInTable++;
                                }
                            }
                        }
                        console.log(`  -> Marked ${tilesInTable} grid cells`);
                    } catch (error) {
                        console.error(`❌ Error processing table object ${idx}:`, error);
                    }
                });

                console.log(`✅ Marked ${tablesMarked} total grid cells as obstacles from ${tablesLayer.objects.length} tables`);
            } else {
                console.warn(`⚠️ Tables object layer not found or empty`);
            }
        } else {
            console.warn(`⚠️ Room map not available for table processing`);
        }

        return grid;
    }

    /**
     * Find a path from start to end position
     * Positions should be world coordinates
     *
     * @param {string} roomId - Room identifier
     * @param {number} startX - Start world X
     * @param {number} startY - Start world Y
     * @param {number} endX - End world X
     * @param {number} endY - End world Y
     * @param {Function} callback - Callback(path) where path is array of world {x, y} or null
     */
    findPath(roomId, startX, startY, endX, endY, callback) {
        const pathfinder = this.pathfinders.get(roomId);
        const bounds = this.roomBounds.get(roomId);

        if (!pathfinder || !bounds) {
            console.warn(`⚠️ No pathfinder for room ${roomId}`);
            callback(null);
            return;
        }

        // Convert world coordinates to tile coordinates
        const startTileX = Math.floor((startX - bounds.worldX) / TILE_SIZE);
        const startTileY = Math.floor((startY - bounds.worldY) / TILE_SIZE);
        const endTileX = Math.floor((endX - bounds.worldX) / TILE_SIZE);
        const endTileY = Math.floor((endY - bounds.worldY) / TILE_SIZE);

        // Clamp to valid tile ranges
        const clampedStartX = Math.max(0, Math.min(bounds.mapWidth - 1, startTileX));
        const clampedStartY = Math.max(0, Math.min(bounds.mapHeight - 1, startTileY));
        const clampedEndX = Math.max(0, Math.min(bounds.mapWidth - 1, endTileX));
        const clampedEndY = Math.max(0, Math.min(bounds.mapHeight - 1, endTileY));

        // Find path
        pathfinder.findPath(clampedStartX, clampedStartY, clampedEndX, clampedEndY, (tilePath) => {
            if (tilePath && tilePath.length > 0) {
                // Convert tile path to world path
                const worldPath = tilePath.map(point => ({
                    x: bounds.worldX + point.x * TILE_SIZE + TILE_SIZE / 2,
                    y: bounds.worldY + point.y * TILE_SIZE + TILE_SIZE / 2
                }));

                callback(worldPath);
            } else {
                callback(null);
            }
        });

        pathfinder.calculate();
    }

    /**
     * Get random valid position within patrol bounds
     * Ensures position is walkable (not on a wall)
     *
     * @param {string} roomId - Room identifier
     * @returns {Object|null} - {x, y} world position or null if no valid position found
     */
    getRandomPatrolTarget(roomId) {
        const bounds = this.roomBounds.get(roomId);
        const grid = this.grids.get(roomId);

        if (!bounds || !grid) {
            console.warn(`⚠️ No bounds/grid for room ${roomId}`);
            console.warn(`   Bounds: ${bounds ? 'exists' : 'MISSING'} | Grid: ${grid ? `exists (${grid.length}x${grid[0]?.length})` : 'MISSING'}`);
            console.warn(`   Available rooms with pathfinding: ${Array.from(this.roomBounds.keys()).join(', ')}`);
            return null;
        }

        // Try up to 20 random positions
        const maxAttempts = 20;
        for (let attempt = 0; attempt < maxAttempts; attempt++) {
            const randTileX = bounds.x + Math.floor(Math.random() * bounds.width);
            const randTileY = bounds.y + Math.floor(Math.random() * bounds.height);

            // Validate indices
            if (randTileY < 0 || randTileY >= grid.length || randTileX < 0 || randTileX >= grid[0].length) {
                continue;
            }

            // Check if this tile is walkable
            if (grid[randTileY] && grid[randTileY][randTileX] === 0) {
                // Convert to world coordinates (center of tile)
                const worldX = bounds.worldX + randTileX * TILE_SIZE + TILE_SIZE / 2;
                const worldY = bounds.worldY + randTileY * TILE_SIZE + TILE_SIZE / 2;

                console.log(`✅ Random patrol target for ${roomId}: (${randTileX}, ${randTileY}) → (${worldX}, ${worldY})`);
                return { x: worldX, y: worldY };
            }
        }

        console.warn(`⚠️ Could not find valid random position in ${roomId} after ${maxAttempts} attempts`);
        console.warn(`   Bounds: x=${bounds.x}, y=${bounds.y}, width=${bounds.width}, height=${bounds.height}`);
        console.warn(`   Grid size: ${grid.length}x${grid[0]?.length}`);
        return null;
    }

    /**
     * Get pathfinder for a room (for debugging)
     */
    getPathfinder(roomId) {
        return this.pathfinders.get(roomId);
    }

    /**
     * Get grid for a room (for debugging)
     */
    getGrid(roomId) {
        return this.grids.get(roomId);
    }

    /**
     * Get bounds for a room (for debugging)
     */
    getBounds(roomId) {
        return this.roomBounds.get(roomId);
    }
}

// Export as global for easy access
window.NPCPathfindingManager = NPCPathfindingManager;
