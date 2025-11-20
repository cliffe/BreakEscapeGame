import { GAME_CONFIG } from './utils/constants.js?v=8';
import { preload, create, update } from './core/game.js?v=40';
import { initializeNotifications } from './systems/notifications.js?v=7';
// Bluetooth scanner is now handled as a minigame
// Biometrics is now handled as a minigame
import { startLockpickingMinigame } from './systems/minigame-starters.js?v=1';
import { initializeDebugSystem } from './systems/debug.js?v=7';
import { initializeUI } from './ui/panels.js?v=9';
import { initializeModals } from './ui/modals.js?v=7';

// Import minigame framework
import './minigames/index.js';

// Import NPC systems
import './systems/ink/ink-engine.js?v=1';
import NPCEventDispatcher from './systems/npc-events.js?v=1';
import NPCManager from './systems/npc-manager.js?v=2';
import NPCBarkSystem from './systems/npc-barks.js?v=1';
import NPCLazyLoader from './systems/npc-lazy-loader.js?v=1';
import './systems/npc-game-bridge.js'; // Bridge for NPCs to influence game state

// Global game variables
window.game = null;
window.gameScenario = null;
window.player = null;
window.cursors = null;
window.rooms = {};
window.currentRoom = null;
window.inventory = {
    items: [],
    container: null
};
window.objectsGroup = null;
window.wallsLayer = null;
window.discoveredRooms = new Set();
window.pathfinder = null;
window.currentPath = [];
window.isMoving = false;
window.targetPoint = null;
window.lastPathUpdateTime = 0;
window.stuckTimer = 0;
window.lastPosition = null;
window.stuckTime = 0;
window.currentPlayerRoom = null;
window.lastPlayerPosition = { x: 0, y: 0 };
window.gameState = {
    biometricSamples: [],
    biometricUnlocks: [],
    bluetoothDevices: [],
    notes: [],
    startTime: null
};
window.lastBluetoothScan = 0;

// Initialize the game
function initializeGame() {
    // Set up game configuration with scene functions
    const config = {
        ...GAME_CONFIG,
        scene: {
            preload: preload,
            create: create,
            update: update
        },
        inventory: {
            items: [],
            display: null
        }
    };

    // Create the Phaser game instance
    window.game = new Phaser.Game(config);

    // Initialize all systems
    initializeNotifications();
    // Bluetooth scanner and biometrics are now handled as minigames
    
    // Initialize NPC systems
    console.log('🎭 Initializing NPC systems...');
    window.eventDispatcher = new NPCEventDispatcher();
    window.barkSystem = new NPCBarkSystem();
    window.npcManager = new NPCManager(window.eventDispatcher, window.barkSystem);
    window.npcLazyLoader = new NPCLazyLoader(window.npcManager);
    console.log('✅ NPC lazy loader initialized');
    
    // Start timed message system
    window.npcManager.startTimedMessages();
    
    console.log('✅ NPC systems initialized');
    
    if (window.npcBarkSystem) {
        window.npcBarkSystem.init();
    }
    
    // Make lockpicking function available globally
    window.startLockpickingMinigame = startLockpickingMinigame;
    
    initializeDebugSystem();
    initializeUI();
    initializeModals();

    // Calculate optimal integer scale factor for current browser window
    const calculateOptimalScale = () => {
        const container = document.getElementById('game-container');
        if (!container) return 2; // Default fallback
        
        const containerWidth = container.clientWidth;
        const containerHeight = container.clientHeight;
        
        // Base resolution
        const baseWidth = 640;
        const baseHeight = 480;
        
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
        
        return bestScale;
    };
    
    // Setup pixel-perfect rendering with optimal scaling
    const setupPixelArt = () => {
        if (game && game.canvas && game.scale) {
            const canvas = game.canvas;
            
            // Set pixel-perfect rendering
            canvas.style.imageRendering = 'pixelated';
            canvas.style.imageRendering = '-moz-crisp-edges';
            canvas.style.imageRendering = 'crisp-edges';
            
            // Calculate and apply optimal scale
            const optimalScale = calculateOptimalScale();
            game.scale.setZoom(optimalScale);
            
            console.log(`Applied ${optimalScale}x scaling for pixel art`);
        }
    };
    
    // Handle orientation changes and fullscreen
    const handleOrientationChange = () => {
        if (game && game.scale) {
            setTimeout(() => {
                game.scale.refresh();
                const optimalScale = calculateOptimalScale();
                game.scale.setZoom(optimalScale);
                console.log(`Orientation change: Applied ${optimalScale}x scaling`);
            }, 100);
        }
    };
    
    // Handle window resize
    const handleResize = () => {
        if (game && game.scale) {
            setTimeout(() => {
                game.scale.refresh();
                const optimalScale = calculateOptimalScale();
                game.scale.setZoom(optimalScale);
                console.log(`Resize: Applied ${optimalScale}x scaling`);
            }, 16);
        }
    };
    
    // Add event listeners
    window.addEventListener('resize', handleResize);
    window.addEventListener('orientationchange', handleOrientationChange);
    document.addEventListener('fullscreenchange', handleOrientationChange);
    
    // Check for LOS visualization debug flag
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('debug-los') || urlParams.has('los')) {
        // Delay to ensure scene is ready
        setTimeout(() => {
            const mainScene = window.game?.scene?.scenes?.[0];
            if (mainScene && window.npcManager) {
                console.log('🔍 Enabling LOS visualization (from URL parameter)');
                window.npcManager.setLOSVisualization(true, mainScene);
            }
        }, 1000);
    }
    
    // Add console helper
    window.enableLOS = function() {
        console.log('🔍 enableLOS() called');
        console.log('   game:', !!window.game);
        console.log('   game.scene:', !!window.game?.scene);
        console.log('   scenes:', window.game?.scene?.scenes?.length ?? 0);
        
        const mainScene = window.game?.scene?.scenes?.[0];
        console.log('   mainScene:', !!mainScene, mainScene?.key);
        console.log('   npcManager:', !!window.npcManager);
        
        if (!mainScene) {
            console.error('❌ Could not get main scene');
            // Try to find any active scene
            if (window.game?.scene?.scenes) {
                for (let i = 0; i < window.game.scene.scenes.length; i++) {
                    console.log(`   Available scene[${i}]:`, window.game.scene.scenes[i].key, 'isActive:', window.game.scene.scenes[i].isActive());
                }
            }
            return;
        }
        
        if (!window.npcManager) {
            console.error('❌ npcManager not available');
            return;
        }
        
        console.log('🎯 Setting LOS visualization with scene:', mainScene.key);
        window.npcManager.setLOSVisualization(true, mainScene);
        console.log('✅ LOS visualization enabled');
    };
    
    window.disableLOS = function() {
        if (window.npcManager) {
            window.npcManager.setLOSVisualization(false);
            console.log('✅ LOS visualization disabled');
        } else {
            console.error('❌ npcManager not available');
        }
    };
    
    // Test graphics rendering
    window.testGraphics = function() {
        console.log('🧪 Testing graphics rendering...');
        const scene = window.game?.scene?.scenes?.[0];
        if (!scene) {
            console.error('❌ No scene found');
            return;
        }
        
        console.log('📊 Scene:', scene.key, 'Active:', scene.isActive());
        
        const test = scene.add.graphics();
        console.log('✅ Created graphics object:', {
            exists: !!test,
            hasScene: !!test.scene,
            depth: test.depth,
            alpha: test.alpha,
            visible: test.visible
        });
        
        test.fillStyle(0xff0000, 0.5);
        test.fillRect(100, 100, 50, 50);
        console.log('✅ Drew red square at (100, 100)');
        console.log('   If you see a RED SQUARE on screen, graphics rendering is working!');
        console.log('   If NOT, check browser console for errors');
        
        // Clean up after 5 seconds
        setTimeout(() => {
            test.destroy();
            console.log('🧹 Test graphics cleaned up');
        }, 5000);
    };
    
    // Get detailed LOS status
    window.losStatus = function() {
        console.log('📡 LOS System Status:');
        console.log('   Enabled:', window.npcManager?.losVisualizationEnabled ?? 'N/A');
        console.log('   NPCs loaded:', window.npcManager?.npcs?.size ?? 0);
        console.log('   Graphics objects:', window.npcManager?.losVisualizations?.size ?? 0);
        
        if (window.npcManager?.npcs?.size > 0) {
            for (const npc of window.npcManager.npcs.values()) {
                console.log(`   NPC: "${npc.id}"`);
                console.log(`      LOS enabled: ${npc.los?.enabled ?? false}`);
                console.log(`      Position: (${npc.sprite?.x.toFixed(0) ?? 'N/A'}, ${npc.sprite?.y.toFixed(0) ?? 'N/A'})`);
                console.log(`      Facing: ${npc.facingDirection ?? npc.direction ?? 'N/A'}°`);
            }
        }
    };
    
    // Initial setup
    setTimeout(setupPixelArt, 100);
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initializeGame);

// Export for global access
window.initializeGame = initializeGame; 