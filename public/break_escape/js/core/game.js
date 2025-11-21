import { initializeRooms, calculateWorldBounds, calculateRoomPositions, createRoom, revealRoom, updatePlayerRoom, rooms } from './rooms.js?v=16';
import { createPlayer, updatePlayerMovement, movePlayerToPoint, player } from './player.js?v=7';
import { initializePathfinder } from './pathfinding.js?v=7';
import { initializeInventory, processInitialInventoryItems } from '../systems/inventory.js?v=8';
import { checkObjectInteractions, setGameInstance } from '../systems/interactions.js?v=26';
import { introduceScenario } from '../utils/helpers.js?v=19';
import '../minigames/index.js?v=2';
import SoundManager from '../systems/sound-manager.js?v=1';
import { initPlayerHealth } from '../systems/player-health.js';
import { initNPCHostileSystem } from '../systems/npc-hostile.js';
import { COMBAT_CONFIG } from '../config/combat-config.js';
import { initCombatDebug } from '../utils/combat-debug.js';
import { DamageNumbersSystem } from '../systems/damage-numbers.js';
import { ScreenEffectsSystem } from '../systems/screen-effects.js';
import { SpriteEffectsSystem } from '../systems/sprite-effects.js';
import { AttackTelegraphSystem } from '../systems/attack-telegraph.js';
import { HealthUI } from '../ui/health-ui.js';
import { NPCHealthBars } from '../ui/npc-health-bars.js';
import { GameOverScreen } from '../ui/game-over-screen.js';
import { PlayerCombat } from '../systems/player-combat.js';
import { NPCCombat } from '../systems/npc-combat.js';

// Global variables that will be set by main.js
let gameScenario;

// Preload function - loads all game assets
export function preload() {
    // Show loading text
    document.getElementById('loading').style.display = 'block';

    // Load tilemap files and regular tilesets first
    this.load.tilemapTiledJSON('room_reception', 'rooms/room_reception2.json');
    this.load.tilemapTiledJSON('room_office', 'rooms/room_office2.json');
    this.load.tilemapTiledJSON('room_ceo', 'rooms/room_ceo2.json');
    this.load.tilemapTiledJSON('room_closet', 'rooms/room_closet2.json');
    this.load.tilemapTiledJSON('room_servers', 'rooms/room_servers2.json');

    // Load new variable-sized rooms for grid system
    this.load.tilemapTiledJSON('small_room_1x1gu', 'rooms/small_room_1x1gu.json');
    this.load.tilemapTiledJSON('hall_1x2gu', 'rooms/hall_1x2gu.json');

    // Load room images (now using smaller 32px scale images)
    this.load.image('room_reception', 'tiles/rooms/room1.png');
    this.load.image('room18', 'tiles/rooms/room18.png');
    this.load.image('room6', 'tiles/rooms/room6.png');
    this.load.image('room14', 'tiles/rooms/room14.png');
    this.load.image('room19', 'tiles/rooms/room19.png');
    this.load.image('door_32', 'tiles/door_32.png');
    this.load.spritesheet('door_sheet', 'tiles/door_sheet_32.png', {
        frameWidth: 32,
        frameHeight: 64
    });

    // Load tileset images referenced by the new Tiled map
    this.load.image('office-updated', 'tiles/rooms/room1.png');
    this.load.image('door_sheet_32', 'tiles/door_sheet_32.png');

    // Load side door spritesheet for east/west doors (6 frames: closed, opening, open, etc.)
    this.load.spritesheet('door_side_sheet_32', 'tiles/door_side_sheet_32.png', {
        frameWidth: 32,
        frameHeight: 32
    });
    
    // Load table tileset images
    this.load.image('desk-ceo1', 'tables/desk-ceo1.png');
    this.load.image('desk-ceo2', 'tables/desk-ceo2.png');
    this.load.image('desk1', 'tables/desk1.png');
    this.load.image('smalldesk1', 'tables/smalldesk1.png');
    this.load.image('smalldesk2', 'tables/smalldesk2.png');
    this.load.image('reception_table1', 'tables/reception_table1.png');

    // Load object sprites - keeping existing ones for backward compatibility
    this.load.image('pc', 'objects/pc1.png');
    this.load.image('key', 'objects/key.png');
    this.load.image('notes', 'objects/notes1.png');
    this.load.image('phone', 'objects/phone1.png');
    this.load.image('suitcase', 'objects/suitcase-1.png');
    this.load.image('smartscreen', 'objects/smartscreen.png');
    this.load.image('photo', 'objects/picture1.png');
    this.load.image('safe', 'objects/safe1.png');
    this.load.image('book', 'objects/book1.png');
    this.load.image('workstation', 'objects/workstation.png');
    this.load.image('bluetooth_scanner', 'objects/bluetooth_scanner.png');
    this.load.image('bluetooth', 'objects/bluetooth.png');
    this.load.image('tablet', 'objects/tablet.png');
    this.load.image('fingerprint', 'objects/fingerprint_small.png');
    this.load.image('lockpick', 'objects/lockpick.png');
    this.load.image('spoofing_kit', 'objects/office-misc-headphones.png');
    this.load.image('keyway', 'icons/keyway.png');
    this.load.image('password', 'icons/password.png');
    this.load.image('pin', 'icons/pin.png');
    this.load.image('talk', 'icons/talk.png');

    // Load RFID keycard and cloner assets
    this.load.image('keycard', 'objects/keycard.png');
    this.load.image('keycard-ceo', 'objects/keycard-ceo.png');
    this.load.image('keycard-security', 'objects/keycard-security.png');
    this.load.image('keycard-maintenance', 'objects/keycard-maintenance.png');
    this.load.image('rfid_cloner', 'objects/rfid_cloner.png');
    this.load.image('rfid-icon', 'icons/rfid-icon.png');
    this.load.image('nfc-waves', 'icons/nfc-waves.png');

    // Load new object sprites from Tiled map tileset
    // These are the key objects that appear in the new room_reception2.json
    this.load.image('fingerprint_kit', 'objects/fingerprint_kit.png');
    this.load.image('pin-cracker', 'objects/pin-cracker.png');
    this.load.image('bin11', 'objects/bin11.png');
    this.load.image('bin10', 'objects/bin10.png');
    this.load.image('bin9', 'objects/bin9.png');
    this.load.image('bin8', 'objects/bin8.png');
    this.load.image('bin7', 'objects/bin7.png');
    this.load.image('bin6', 'objects/bin6.png');
    this.load.image('bin5', 'objects/bin5.png');
    this.load.image('bin4', 'objects/bin4.png');
    this.load.image('bin3', 'objects/bin3.png');
    this.load.image('bin2', 'objects/bin2.png');
    this.load.image('bin1', 'objects/bin1.png');
    
    // Suitcases
    this.load.image('suitcase21', 'objects/suitcase21.png');
    this.load.image('suitcase20', 'objects/suitcase20.png');
    this.load.image('suitcase19', 'objects/suitcase19.png');
    this.load.image('suitcase18', 'objects/suitcase18.png');
    this.load.image('suitcase17', 'objects/suitcase17.png');
    this.load.image('suitcase16', 'objects/suitcase16.png');
    this.load.image('suitcase15', 'objects/suitcase15.png');
    this.load.image('suitcase14', 'objects/suitcase14.png');
    this.load.image('suitcase13', 'objects/suitcase13.png');
    this.load.image('suitcase12', 'objects/suitcase12.png');
    this.load.image('suitcase11', 'objects/suitcase11.png');
    this.load.image('suitcase10', 'objects/suitcase10.png');
    this.load.image('suitcase9', 'objects/suitcase9.png');
    this.load.image('suitcase8', 'objects/suitcase8.png');
    this.load.image('suitcase7', 'objects/suitcase7.png');
    this.load.image('suitcase6', 'objects/suitcase6.png');
    this.load.image('suitcase5', 'objects/suitcase5.png');
    this.load.image('suitcase4', 'objects/suitcase4.png');
    this.load.image('suitcase3', 'objects/suitcase3.png');
    this.load.image('suitcase2', 'objects/suitcase2.png');
    this.load.image('suitcase-1', 'objects/suitcase-1.png');
    
    // Plants
    this.load.image('plant-flat-pot7', 'objects/plant-flat-pot7.png');
    this.load.image('plant-flat-pot6', 'objects/plant-flat-pot6.png');
    this.load.image('plant-flat-pot5', 'objects/plant-flat-pot5.png');
    this.load.image('plant-flat-pot4', 'objects/plant-flat-pot4.png');
    this.load.image('plant-flat-pot3', 'objects/plant-flat-pot3.png');
    this.load.image('plant-flat-pot2', 'objects/plant-flat-pot2.png');
    this.load.image('plant-flat-pot1', 'objects/plant-flat-pot1.png');
    
    // Office furniture
    this.load.image('outdoor-lamp4', 'objects/outdoor-lamp4.png');
    this.load.image('outdoor-lamp3', 'objects/outdoor-lamp3.png');
    this.load.image('outdoor-lamp2', 'objects/outdoor-lamp2.png');
    this.load.image('outdoor-lamp1', 'objects/outdoor-lamp1.png');
    this.load.image('plant-large10', 'objects/plant-large10.png');
    this.load.image('lamp-stand5', 'objects/lamp-stand5.png');
    this.load.image('plant-large9', 'objects/plant-large9.png');
    this.load.image('plant-large8', 'objects/plant-large8.png');
    this.load.image('plant-large7', 'objects/plant-large7.png');
    this.load.image('plant-large6', 'objects/plant-large6.png');
    this.load.image('lamp-stand4', 'objects/lamp-stand4.png');
    this.load.image('plant-large5', 'objects/plant-large5.png');
    this.load.image('plant-large4', 'objects/plant-large4.png');
    this.load.image('plant-large3', 'objects/plant-large3.png');
    this.load.image('plant-large2', 'objects/plant-large2.png');
    this.load.image('lamp-stand3', 'objects/lamp-stand3.png');
    this.load.image('plant-large1', 'objects/plant-large1.png');
    this.load.image('lamp-stand2', 'objects/lamp-stand2.png');
    this.load.image('lamp-stand1', 'objects/lamp-stand1.png');
    
    // Pictures
    this.load.image('picture14', 'objects/picture14.png');
    this.load.image('picture13', 'objects/picture13.png');
    this.load.image('picture12', 'objects/picture12.png');
    this.load.image('picture11', 'objects/picture11.png');
    this.load.image('picture10', 'objects/picture10.png');
    this.load.image('picture9', 'objects/picture9.png');
    this.load.image('picture8', 'objects/picture8.png');
    this.load.image('picture7', 'objects/picture7.png');
    this.load.image('picture6', 'objects/picture6.png');
    this.load.image('picture5', 'objects/picture5.png');
    this.load.image('picture4', 'objects/picture4.png');
    this.load.image('picture3', 'objects/picture3.png');
    this.load.image('picture2', 'objects/picture2.png');
    this.load.image('picture1', 'objects/picture1.png');
    
    // Office misc items
    this.load.image('office-misc-smallplant2', 'objects/office-misc-smallplant2.png');
    this.load.image('office-misc-smallplant3', 'objects/office-misc-smallplant3.png');
    this.load.image('office-misc-smallplant4', 'objects/office-misc-smallplant4.png');
    this.load.image('office-misc-smallplant5', 'objects/office-misc-smallplant5.png');
    this.load.image('office-misc-box1', 'objects/office-misc-box1.png');
    this.load.image('office-misc-container', 'objects/office-misc-container.png');
    this.load.image('office-misc-lamp3', 'objects/office-misc-lamp3.png');
    this.load.image('office-misc-hdd6', 'objects/office-misc-hdd6.png');
    this.load.image('office-misc-speakers6', 'objects/office-misc-speakers6.png');
    this.load.image('office-misc-pencils6', 'objects/office-misc-pencils6.png');
    this.load.image('office-misc-fan2', 'objects/office-misc-fan2.png');
    this.load.image('office-misc-cup5', 'objects/office-misc-cup5.png');
    this.load.image('office-misc-hdd5', 'objects/office-misc-hdd5.png');
    this.load.image('office-misc-speakers5', 'objects/office-misc-speakers5.png');
    this.load.image('office-misc-cup4', 'objects/office-misc-cup4.png');
    this.load.image('office-misc-speakers4', 'objects/office-misc-speakers4.png');
    this.load.image('office-misc-pencils5', 'objects/office-misc-pencils5.png');

    this.load.image('office-misc-clock', 'objects/office-misc-clock.png');
    this.load.image('office-misc-fan', 'objects/office-misc-fan.png');
    this.load.image('office-misc-speakers3', 'objects/office-misc-speakers3.png');
    this.load.image('office-misc-camera', 'objects/office-misc-camera.png');
    this.load.image('office-misc-headphones', 'objects/office-misc-headphones.png');
    this.load.image('office-misc-hdd4', 'objects/office-misc-hdd4.png');
    this.load.image('office-misc-pencils4', 'objects/office-misc-pencils4.png');
    this.load.image('office-misc-cup3', 'objects/office-misc-cup3.png');
    this.load.image('office-misc-cup2', 'objects/office-misc-cup2.png');
    this.load.image('office-misc-speakers2', 'objects/office-misc-speakers2.png');
    this.load.image('office-misc-stapler', 'objects/office-misc-stapler.png');
    this.load.image('office-misc-hdd3', 'objects/office-misc-hdd3.png');
    this.load.image('office-misc-hdd2', 'objects/office-misc-hdd2.png');
    this.load.image('office-misc-pencils3', 'objects/office-misc-pencils3.png');
    this.load.image('office-misc-pencils2', 'objects/office-misc-pencils2.png');
    this.load.image('office-misc-pens', 'objects/office-misc-pens.png');
    this.load.image('office-misc-lamp2', 'objects/office-misc-lamp2.png');
    this.load.image('office-misc-hdd', 'objects/office-misc-hdd.png');
    this.load.image('office-misc-smallplant', 'objects/office-misc-smallplant.png');
    this.load.image('office-misc-pencils', 'objects/office-misc-pencils.png');
    this.load.image('office-misc-speakers', 'objects/office-misc-speakers.png');
    this.load.image('office-misc-cup', 'objects/office-misc-cup.png');
    this.load.image('office-misc-lamp', 'objects/office-misc-lamp.png');
    this.load.image('phone5', 'objects/phone5.png');
    this.load.image('phone4', 'objects/phone4.png');
    this.load.image('phone3', 'objects/phone3.png');
    this.load.image('phone2', 'objects/phone2.png');
    this.load.image('phone1', 'objects/phone1.png');
    
    // Bags and briefcases
    this.load.image('bag25', 'objects/bag25.png');
    this.load.image('bag24', 'objects/bag24.png');
    this.load.image('bag23', 'objects/bag23.png');
    this.load.image('bag22', 'objects/bag22.png');
    this.load.image('bag21', 'objects/bag21.png');
    this.load.image('bag20', 'objects/bag20.png');
    this.load.image('bag19', 'objects/bag19.png');
    this.load.image('bag18', 'objects/bag18.png');
    this.load.image('bag17', 'objects/bag17.png');
    this.load.image('bag16', 'objects/bag16.png');
    this.load.image('bag15', 'objects/bag15.png');
    this.load.image('bag14', 'objects/bag14.png');
    this.load.image('bag13', 'objects/bag13.png');
    this.load.image('bag12', 'objects/bag12.png');
    this.load.image('bag11', 'objects/bag11.png');
    this.load.image('bag10', 'objects/bag10.png');
    this.load.image('bag9', 'objects/bag9.png');
    this.load.image('bag8', 'objects/bag8.png');
    this.load.image('bag7', 'objects/bag7.png');
    this.load.image('bag6', 'objects/bag6.png');
    this.load.image('bag5', 'objects/bag5.png');
    this.load.image('bag4', 'objects/bag4.png');
    this.load.image('bag3', 'objects/bag3.png');
    this.load.image('bag2', 'objects/bag2.png');
    this.load.image('bag1', 'objects/bag1.png');
    
    // Briefcases
    this.load.image('briefcase-orange-1', 'objects/briefcase-orange-1.png');
    this.load.image('briefcase-yellow-1', 'objects/briefcase-yellow-1.png');
    this.load.image('briefcase13', 'objects/briefcase13.png');
    this.load.image('briefcase-purple-1', 'objects/briefcase-purple-1.png');
    this.load.image('briefcase-green-1', 'objects/briefcase-green-1.png');
    this.load.image('briefcase-blue-1', 'objects/briefcase-blue-1.png');
    this.load.image('briefcase-red-1', 'objects/briefcase-red-1.png');
    this.load.image('briefcase12', 'objects/briefcase12.png');
    this.load.image('briefcase11', 'objects/briefcase11.png');
    this.load.image('briefcase10', 'objects/briefcase10.png');
    this.load.image('briefcase9', 'objects/briefcase9.png');
    this.load.image('briefcase8', 'objects/briefcase8.png');
    this.load.image('briefcase7', 'objects/briefcase7.png');
    this.load.image('briefcase6', 'objects/briefcase6.png');
    this.load.image('briefcase5', 'objects/briefcase5.png');
    this.load.image('briefcase4', 'objects/briefcase4.png');
    this.load.image('briefcase3', 'objects/briefcase3.png');
    this.load.image('briefcase2', 'objects/briefcase2.png');
    this.load.image('briefcase1', 'objects/briefcase1.png');
    
    // Chairs
    this.load.image('chair-grey-4', 'objects/chair-grey-4.png');
    this.load.image('chair-grey-3', 'objects/chair-grey-3.png');
    this.load.image('chair-darkgreen-3', 'objects/chair-darkgreen-3.png');
    this.load.image('chair-grey-2', 'objects/chair-grey-2.png');
    this.load.image('chair-darkgray-1', 'objects/chair-darkgray-1.png');
    this.load.image('chair-darkgreen-2', 'objects/chair-darkgreen-2.png');
    this.load.image('chair-darkgreen-1', 'objects/chair-darkgreen-1.png');
    this.load.image('chair-grey-1', 'objects/chair-grey-1.png');
    this.load.image('chair-red-4', 'objects/chair-red-4.png');
    this.load.image('chair-red-3', 'objects/chair-red-3.png');
    this.load.image('chair-green-2', 'objects/chair-green-2.png');
    this.load.image('chair-green-1', 'objects/chair-green-1.png');
    this.load.image('chair-red-2', 'objects/chair-red-2.png');
    this.load.image('chair-red-1', 'objects/chair-red-1.png');
    this.load.image('chair-white-2', 'objects/chair-white-2.png');
    this.load.image('chair-white-1', 'objects/chair-white-1.png');
    
    // Keyboards
    this.load.image('keyboard8', 'objects/keyboard8.png');
    this.load.image('keyboard7', 'objects/keyboard7.png');
    this.load.image('keyboard6', 'objects/keyboard6.png');
    this.load.image('keyboard5', 'objects/keyboard5.png');
    this.load.image('keyboard4', 'objects/keyboard4.png');
    this.load.image('keyboard3', 'objects/keyboard3.png');
    this.load.image('keyboard2', 'objects/keyboard2.png');
    this.load.image('keyboard1', 'objects/keyboard1.png');
    
    // Safes
    this.load.image('safe5', 'objects/safe5.png');
    this.load.image('safe4', 'objects/safe4.png');
    this.load.image('safe3', 'objects/safe3.png');
    this.load.image('safe2', 'objects/safe2.png');
    this.load.image('safe1', 'objects/safe1.png');
    
    // Notes
    this.load.image('notes1', 'objects/notes1.png');
    this.load.image('notes2', 'objects/notes2.png');
    this.load.image('notes3', 'objects/notes3.png');
    this.load.image('notes4', 'objects/notes4.png');

    
    // Servers and tech
    this.load.image('servers', 'objects/servers.png');
    this.load.image('servers3', 'objects/servers3.png');
    this.load.image('servers2', 'objects/servers2.png');
    this.load.image('sofa1', 'objects/sofa1.png');
    this.load.image('plant-large13', 'objects/plant-large13.png');
    this.load.image('office-misc-lamp4', 'objects/office-misc-lamp4.png');
    this.load.image('chair-waiting-right-1', 'objects/chair-waiting-right-1.png');
    this.load.image('chair-waiting-left-1', 'objects/chair-waiting-left-1.png');
    this.load.image('plant-large12', 'objects/plant-large12.png');
    this.load.image('plant-large11', 'objects/plant-large11.png');
    
    // Load animated plant frames
    this.load.image('plant-large11-top-ani1', 'objects/plant-large11-top-ani1.png');
    this.load.image('plant-large11-top-ani2', 'objects/plant-large11-top-ani2.png');
    this.load.image('plant-large11-top-ani3', 'objects/plant-large11-top-ani3.png');
    this.load.image('plant-large11-top-ani4', 'objects/plant-large11-top-ani4.png');
    
    this.load.image('plant-large12-top-ani1', 'objects/plant-large12-top-ani1.png');
    this.load.image('plant-large12-top-ani2', 'objects/plant-large12-top-ani2.png');
    this.load.image('plant-large12-top-ani3', 'objects/plant-large12-top-ani3.png');
    this.load.image('plant-large12-top-ani4', 'objects/plant-large12-top-ani4.png');
    this.load.image('plant-large12-top-ani5', 'objects/plant-large12-top-ani5.png');
    
    this.load.image('plant-large13-top-ani1', 'objects/plant-large13-top-ani1.png');
    this.load.image('plant-large13-top-ani2', 'objects/plant-large13-top-ani2.png');
    this.load.image('plant-large13-top-ani3', 'objects/plant-large13-top-ani3.png');
    this.load.image('plant-large13-top-ani4', 'objects/plant-large13-top-ani4.png');
    this.load.image('pc1', 'objects/pc1.png');
    this.load.image('pc3', 'objects/pc3.png');
    this.load.image('pc4', 'objects/pc4.png');
    this.load.image('pc5', 'objects/pc5.png');
    this.load.image('pc6', 'objects/pc6.png');
    this.load.image('pc7', 'objects/pc7.png');
    this.load.image('pc8', 'objects/pc8.png');
    this.load.image('pc9', 'objects/pc9.png');
    this.load.image('pc10', 'objects/pc10.png');
    this.load.image('pc11', 'objects/pc11.png');
    this.load.image('pc12', 'objects/pc12.png');

    
    // Laptops
    this.load.image('laptop7', 'objects/laptop7.png');
    this.load.image('laptop6', 'objects/laptop6.png');
    this.load.image('laptop5', 'objects/laptop5.png');
    this.load.image('laptop4', 'objects/laptop4.png');
    this.load.image('laptop3', 'objects/laptop3.png');
    this.load.image('laptop2', 'objects/laptop2.png');
    this.load.image('laptop1', 'objects/laptop1.png');
    
    // Chalkboards and bookcases
    this.load.image('chalkboard3', 'objects/chalkboard3.png');
    this.load.image('chalkboard2', 'objects/chalkboard2.png');
    this.load.image('chalkboard', 'objects/chalkboard.png');
    this.load.image('bookcase', 'objects/bookcase.png');
    
    // Spooky basement items
    this.load.image('spooky-splatter', 'objects/spooky-splatter.png');
    this.load.image('spooky-candles2', 'objects/spooky-candles2.png');
    this.load.image('spooky-candles', 'objects/spooky-candles.png');
    this.load.image('torch-left', 'objects/torch-left.png');
    this.load.image('torch-right', 'objects/torch-right.png');
    this.load.image('torch-1', 'objects/torch-1.png');

    // Load character sprite sheet instead of single image
    this.load.spritesheet('hacker', 'characters/hacker.png', {
        frameWidth: 64,
        frameHeight: 64
    });

    // Load character sprite sheet instead of single image
    this.load.spritesheet('hacker-red', 'characters/hacker-red.png', {
        frameWidth: 64,
        frameHeight: 64
    });

    // Animated plant textures are loaded above
    
    // Load swivel chair rotation images
    this.load.image('chair-exec-rotate1', 'objects/chair-exec-rotate1.png');
    this.load.image('chair-exec-rotate2', 'objects/chair-exec-rotate2.png');
    this.load.image('chair-exec-rotate3', 'objects/chair-exec-rotate3.png');
    this.load.image('chair-exec-rotate4', 'objects/chair-exec-rotate4.png');
    this.load.image('chair-exec-rotate5', 'objects/chair-exec-rotate5.png');
    this.load.image('chair-exec-rotate6', 'objects/chair-exec-rotate6.png');
    this.load.image('chair-exec-rotate7', 'objects/chair-exec-rotate7.png');
    this.load.image('chair-exec-rotate8', 'objects/chair-exec-rotate8.png');
    
    // Load white chair rotation images
    this.load.image('chair-white-1-rotate1', 'objects/chair-white-1-rotate1.png');
    this.load.image('chair-white-1-rotate2', 'objects/chair-white-1-rotate2.png');
    this.load.image('chair-white-1-rotate3', 'objects/chair-white-1-rotate3.png');
    this.load.image('chair-white-1-rotate4', 'objects/chair-white-1-rotate4.png');
    this.load.image('chair-white-1-rotate5', 'objects/chair-white-1-rotate5.png');
    this.load.image('chair-white-1-rotate6', 'objects/chair-white-1-rotate6.png');
    this.load.image('chair-white-1-rotate7', 'objects/chair-white-1-rotate7.png');
    this.load.image('chair-white-1-rotate8', 'objects/chair-white-1-rotate8.png');
    
    this.load.image('chair-white-2-rotate1', 'objects/chair-white-2-rotate1.png');
    this.load.image('chair-white-2-rotate2', 'objects/chair-white-2-rotate2.png');
    this.load.image('chair-white-2-rotate3', 'objects/chair-white-2-rotate3.png');
    this.load.image('chair-white-2-rotate4', 'objects/chair-white-2-rotate4.png');
    this.load.image('chair-white-2-rotate5', 'objects/chair-white-2-rotate5.png');
    this.load.image('chair-white-2-rotate6', 'objects/chair-white-2-rotate6.png');
    this.load.image('chair-white-2-rotate7', 'objects/chair-white-2-rotate7.png');
    this.load.image('chair-white-2-rotate8', 'objects/chair-white-2-rotate8.png');

    // Load audio files
    // NPC system sounds
    this.load.audio('message_received', 'sounds/message_received.mp3');
    
    // Initialize sound manager and preload all sounds
    // Store as window property so we can access it later in create()
    window.soundManagerPreload = new SoundManager(this);
    window.soundManagerPreload.preloadSounds();

    // Load scenario from Rails API endpoint if available, otherwise try URL parameter
    if (window.breakEscapeConfig?.apiBasePath) {
        // Load scenario from Rails API endpoint
        // Use absolute URL with origin to prevent Phaser baseURL from interfering
        const scenarioUrl = `${window.location.origin}${window.breakEscapeConfig.apiBasePath}/scenario`;
        this.load.json('gameScenarioJSON', scenarioUrl);
    } else {
        // Fallback to old behavior for standalone HTML files
        const urlParams = new URLSearchParams(window.location.search);
        let scenarioFile = urlParams.get('scenario') || 'scenarios/ceo_exfil.json';
        
        // Ensure scenario file has proper path prefix
        if (!scenarioFile.startsWith('scenarios/')) {
            scenarioFile = `scenarios/${scenarioFile}`;
        }
        
        // Ensure .json extension
        if (!scenarioFile.endsWith('.json')) {
            scenarioFile = `${scenarioFile}.json`;
        }
        
        // Add cache buster query parameter to prevent browser caching
        scenarioFile = `${scenarioFile}${scenarioFile.includes('?') ? '&' : '?'}v=${Date.now()}`;
        
        // Load the specified scenario
        this.load.json('gameScenarioJSON', scenarioFile);
    }
}


// Create function - sets up the game world and initializes all systems
export async function create() {
    // Hide loading text
    document.getElementById('loading').style.display = 'none';

    // Set game instance for interactions module early
    setGameInstance(this);

    // Ensure gameScenario is loaded before proceeding
    if (!window.gameScenario) {
        window.gameScenario = this.cache.json.get('gameScenarioJSON');
    }
    gameScenario = window.gameScenario;
    
    console.log('🔍 Raw gameScenario loaded from cache:', gameScenario);
    if (gameScenario?.npcs && gameScenario.npcs.length > 0) {
        console.log('🔍 First NPC in loaded scenario:', gameScenario.npcs[0]);
        console.log('🔍 First NPC spriteTalk property:', gameScenario.npcs[0].spriteTalk);
    }
    
    // Safety check: if gameScenario is still not loaded, log error
    if (!gameScenario) {
        console.error('❌ ERROR: gameScenario failed to load. Check scenario file path.');
        console.error('   Scenario URL parameter may be incorrect.');
        console.error('   Use: scenario_select.html or direct scenario path');
        return;
    }
    
    // Initialize global narrative variables from scenario
    if (gameScenario.globalVariables) {
        window.gameState.globalVariables = { ...gameScenario.globalVariables };
        console.log('🌐 Initialized global variables:', window.gameState.globalVariables);
    } else {
        window.gameState.globalVariables = {};
    }
    
    // Normalize keyPins in all rooms and objects from 0-100 scale to 25-65 scale
    normalizeScenarioKeyPins(gameScenario);
    
    // Debug: log what we loaded
    console.log('🎮 Loaded gameScenario with rooms:', Object.keys(gameScenario?.rooms || {}));
    if (gameScenario?.rooms?.office1) {
        console.log('office1 room data:', gameScenario.rooms.office1);
    }

    // Calculate world bounds after scenario is loaded
    const worldBounds = calculateWorldBounds(this);
    
    // Set the physics world bounds
    this.physics.world.setBounds(
        worldBounds.x, 
        worldBounds.y, 
        worldBounds.width, 
        worldBounds.height
    );

    // Create player first like in original
    createPlayer(this);
    
    // Store player globally for access from other modules
    window.player = player;
    
    // Create door opening animation (for N/S doors)
    this.anims.create({
        key: 'door_open',
        frames: this.anims.generateFrameNumbers('door_sheet', { start: 0, end: 4 }),
        frameRate: 8,
        repeat: 0
    });

    // Create door top animation (6th frame)
    this.anims.create({
        key: 'door_top',
        frames: [{ key: 'door_sheet', frame: 5 }],
        frameRate: 1,
        repeat: 0
    });

    // Create side door opening animation (for E/W doors) - frames 2-5 (1-indexed) = frames 1-4 (0-indexed)
    this.anims.create({
        key: 'door_side_open',
        frames: this.anims.generateFrameNumbers('door_side_sheet_32', { start: 1, end: 4 }),
        frameRate: 8,
        repeat: 0
    });
    
    // Create plant bump animations
    this.anims.create({
        key: 'plant-large11-bump',
        frames: [
            { key: 'plant-large11-top-ani1' },
            { key: 'plant-large11-top-ani2' },
            { key: 'plant-large11-top-ani3' },
            { key: 'plant-large11-top-ani4' }
        ],
        frameRate: 8,
        repeat: 0
    });
    
    this.anims.create({
        key: 'plant-large12-bump',
        frames: [
            { key: 'plant-large12-top-ani1' },
            { key: 'plant-large12-top-ani2' },
            { key: 'plant-large12-top-ani3' },
            { key: 'plant-large12-top-ani4' },
            { key: 'plant-large12-top-ani5' }
        ],
        frameRate: 8,
        repeat: 0
    });
    
    this.anims.create({
        key: 'plant-large13-bump',
        frames: [
            { key: 'plant-large13-top-ani1' },
            { key: 'plant-large13-top-ani2' },
            { key: 'plant-large13-top-ani3' },
            { key: 'plant-large13-top-ani4' }
        ],
        frameRate: 8,
        repeat: 0
    });
    
    // Initialize rooms system after player exists
    initializeRooms(this);

    // Initialize NPC Behavior Manager (async lazy loading)
    if (window.npcManager) {
        import('../systems/npc-behavior.js?v=1')
            .then(module => {
                window.npcBehaviorManager = new module.NPCBehaviorManager(this, window.npcManager);
                console.log('✅ NPC Behavior Manager initialized');
                // NOTE: Individual behaviors registered per-room in rooms.js createNPCSpritesForRoom()
            })
            .catch(error => {
                console.error('❌ Failed to initialize NPC Behavior Manager:', error);
            });
    }

    // Initialize combat systems
    COMBAT_CONFIG.validate();
    window.playerHealth = initPlayerHealth();
    window.npcHostileSystem = initNPCHostileSystem();
    window.playerCombat = new PlayerCombat(this);
    window.npcCombat = new NPCCombat(this);

    // Initialize feedback systems
    window.damageNumbers = new DamageNumbersSystem(this);
    window.screenEffects = new ScreenEffectsSystem(this);
    window.spriteEffects = new SpriteEffectsSystem(this);
    window.attackTelegraph = new AttackTelegraphSystem(this);

    // Initialize UI systems
    window.healthUI = new HealthUI();
    window.npcHealthBars = new NPCHealthBars(this);
    window.gameOverScreen = new GameOverScreen();

    initCombatDebug();
    console.log('✅ Combat systems ready');

    // Create only the starting room initially
    const roomPositions = calculateRoomPositions(this);
    const startingRoomData = gameScenario.rooms[gameScenario.startRoom];
    const startingRoomPosition = roomPositions[gameScenario.startRoom];
    
    if (startingRoomData && startingRoomPosition) {
        // Load NPCs for starting room BEFORE creating room visuals
        // This ensures phone NPCs are registered before processInitialInventoryItems() is called
        if (window.npcLazyLoader && startingRoomData) {
            try {
                await window.npcLazyLoader.loadNPCsForRoom(
                    gameScenario.startRoom, 
                    startingRoomData
                );
                console.log(`✅ Loaded NPCs for starting room: ${gameScenario.startRoom}`);
            } catch (error) {
                console.error(`Failed to load NPCs for starting room ${gameScenario.startRoom}:`, error);
                // Continue with room creation even if NPC loading fails
            }
        }
        
        createRoom(gameScenario.startRoom, startingRoomData, startingRoomPosition);
        revealRoom(gameScenario.startRoom);
    } else {
        console.error('Failed to create starting room');
    }
    
    // Position player in the starting room
    const startingRoom = rooms[gameScenario.startRoom];
    if (startingRoom) {
        const roomCenterX = startingRoom.position.x + 160; // Room width / 2 (320/2)
        const roomCenterY = startingRoom.position.y + 144; // Room height / 2 (288/2)
        player.setPosition(roomCenterX, roomCenterY);
        console.log(`Player positioned at (${roomCenterX}, ${roomCenterY}) in starting room ${gameScenario.startRoom}`);
    }
    
    // Set up camera to follow player
    this.cameras.main.startFollow(player);
    
    // Check if scenario specifies a title screen should be shown
    if (gameScenario.showTitleScreen !== false) {
        // Start title screen minigame as overlay (canvas stays visible)
        if (window.startTitleScreenMinigame) {
            window.startTitleScreenMinigame();
            console.log('🎬 Title screen minigame started as overlay');
        }
    }
    
    // Door interactions are now handled by the door sprites themselves
    
    // Initialize pathfinder
    initializePathfinder(this);
    
    // Set up input handling
    this.input.on('pointerdown', (pointer) => {
        // Check if a minigame is currently running - if so, don't process main game clicks
        if (window.MinigameFramework && window.MinigameFramework.currentMinigame) {
            console.log('Minigame is running, ignoring main game click', {
                currentMinigame: window.MinigameFramework.currentMinigame,
                minigameType: window.MinigameFramework.currentMinigame.constructor.name
            });
            return;
        }
        
        // Convert screen coordinates to world coordinates
        const worldX = this.cameras.main.scrollX + pointer.x;
        const worldY = this.cameras.main.scrollY + pointer.y;
        
        // Check for NPC sprites at the clicked position first
        const npcAtPosition = findNPCAtPosition(worldX, worldY);
        if (npcAtPosition) {
            // Try to interact with the NPC
            if (window.tryInteractWithNPC) {
                const interactionSuccessful = window.tryInteractWithNPC(npcAtPosition);
                
                if (interactionSuccessful) {
                    // Interaction was successful (NPC was in range)
                    return; // Exit early after handling the interaction
                } else {
                    // NPC was out of range - treat click as a movement request
                    movePlayerToPoint(npcAtPosition.x, npcAtPosition.y);
                    return;
                }
            }
        }
        
        // Check for objects at the clicked position
        const objectsAtPosition = findObjectsAtPosition(worldX, worldY);
        
        if (objectsAtPosition.length > 0) {
            // Check if any of the objects are interactable
            const player = window.player;
            if (player) {
                // Try to interact with objects in order of appearance
                for (const obj of objectsAtPosition) {
                    if (obj.interactable) {
                        // Try to interact using the interaction system's distance calculation
                        // which takes into account the player's facing direction
                        if (window.handleObjectInteraction) {
                            // Prevent movement while we check
                            window.preventPlayerMovement = true;
                            const previousX = player.x;
                            const previousY = player.y;
                            
                            // Try the interaction
                            window.handleObjectInteraction(obj);
                            
                            // If the interaction didn't move the player (it was out of range),
                            // treat this as a movement request to that object instead
                            if (player.x === previousX && player.y === previousY) {
                                // Reset the flag and allow movement to the object
                                window.preventPlayerMovement = false;
                                movePlayerToPoint(worldX, worldY);
                                return;
                            }
                            
                            // Interaction was successful
                            setTimeout(() => {
                                window.preventPlayerMovement = false;
                            }, 100);
                            return; // Exit early after handling the first valid interaction
                        }
                    }
                }
            }
        }
        
        // Check if player movement should be prevented (e.g., clicking on interactable items)
        if (window.preventPlayerMovement) {
            return;
        }
        
        // No interactable objects found or player out of range - allow movement
        movePlayerToPoint(worldX, worldY);
    });
    
    // Initialize inventory
    initializeInventory();
    
    // Process initial inventory items
    processInitialInventoryItems();
    
    // Initialize sound manager - reuse the instance created in preload()
    if (window.soundManagerPreload) {
        // Reuse the sound manager that was created in preload
        window.soundManagerPreload.initializeSounds();
        window.soundManager = window.soundManagerPreload;
        delete window.soundManagerPreload; // Clean up temporary reference
    } else {
        // Fallback in case preload didn't run properly
        const soundManager = new SoundManager(this);
        soundManager.preloadSounds();
        soundManager.initializeSounds();
        window.soundManager = soundManager;
    }
    console.log('🔊 Sound Manager initialized');
    
    // Show introduction
    introduceScenario();
    
    // Initialize physics debug display (visual debug off by default)
    if (window.initializePhysicsDebugDisplay) {
        window.initializePhysicsDebugDisplay();
    }
    
    // Store game reference globally
    window.game = this;
}

// Update function - main game loop
export function update() {
    // Safety check: ensure player exists before running updates
    if (!window.player) {
        return;
    }
    
    // Update player movement
    updatePlayerMovement();
    
    // Update player room (check for room transitions)
    updatePlayerRoom();

    // Update NPC behaviors
    if (window.npcBehaviorManager) {
        window.npcBehaviorManager.update(this.time.now, this.time.delta);
    }

    // Update NPC LOS visualizations if enabled
    if (window.npcManager && window.npcManager.losVisualizationEnabled) {
        window.npcManager.updateLOSVisualizations(this);
    }

    // Check for object interactions
    checkObjectInteractions.call(this);

    // Update combat feedback systems
    if (window.damageNumbers) {
        window.damageNumbers.update();
    }
    if (window.attackTelegraph) {
        window.attackTelegraph.update();
    }
    if (window.npcHealthBars) {
        window.npcHealthBars.update();
    }

    // Check for player bump effect when walking over floor items
    if (window.createPlayerBumpEffect) {
        window.createPlayerBumpEffect();
    }
    
    // Check for plant bump effect when player walks near animated plants
    if (window.createPlantBumpEffect) {
        window.createPlantBumpEffect();
    }
    
    // Update swivel chair rotation based on movement
    if (window.updateSwivelChairRotation) {
        window.updateSwivelChairRotation();
    }
    
    // Bluetooth device scanning is now handled by the minigame when active
}

// Bluetooth scanning is now handled by the minigame

// Helper functions

// Find all objects at a given world position
function findObjectsAtPosition(worldX, worldY) {
    const objectsAtPosition = [];
    
    // Check all rooms for objects at the given position
    Object.entries(window.rooms).forEach(([roomId, room]) => {
        if (room.objects) {
            Object.values(room.objects).forEach(obj => {
                if (obj && obj.active && obj.visible) {
                    // Check if the click is within the object's bounds
                    const objLeft = obj.x - obj.width * obj.originX;
                    const objRight = obj.x + obj.width * (1 - obj.originX);
                    const objTop = obj.y - obj.height * obj.originY;
                    const objBottom = obj.y + obj.height * (1 - obj.originY);
                    
                    if (worldX >= objLeft && worldX <= objRight && 
                        worldY >= objTop && worldY <= objBottom) {
                        objectsAtPosition.push(obj);
                    }
                }
            });
        }
    });
    
    // Sort by depth (highest depth first, so topmost objects are checked first)
    objectsAtPosition.sort((a, b) => (b.depth || 0) - (a.depth || 0));
    
    return objectsAtPosition;
}

/**
 * Find an NPC sprite at the clicked position
 * @param {number} worldX - World X coordinate
 * @param {number} worldY - World Y coordinate
 * @returns {Object|null} NPC sprite if found, null otherwise
 */
function findNPCAtPosition(worldX, worldY) {
    let closestNPC = null;
    let closestDistance = Infinity;
    
    // Check all rooms for NPC sprites at the given position
    Object.entries(window.rooms).forEach(([roomId, room]) => {
        if (room.npcSprites && Array.isArray(room.npcSprites)) {
            room.npcSprites.forEach(npcSprite => {
                if (npcSprite && !npcSprite.destroyed && npcSprite.visible) {
                    // Get NPC bounds
                    const bounds = npcSprite.getBounds();
                    
                    // Check if click is within bounds
                    if (worldX >= bounds.left && worldX <= bounds.right && 
                        worldY >= bounds.top && worldY <= bounds.bottom) {
                        // Calculate distance from click to NPC center
                        const dx = worldX - npcSprite.x;
                        const dy = worldY - npcSprite.y;
                        const distance = Math.sqrt(dx * dx + dy * dy);
                        
                        // Keep the closest NPC
                        if (distance < closestDistance) {
                            closestDistance = distance;
                            closestNPC = npcSprite;
                        }
                    }
                }
            });
        }
    });
    
    return closestNPC;
}

/**
 * Normalize keyPins from 0-100 scale to 25-65 scale in entire scenario
 * 
 * KEYPIN TERMINOLOGY AND RELATIONSHIPS:
 * =====================================
 * 
 * Lock Pin Anatomy:
 * - Each lock chamber contains TWO pins stacked vertically:
 *   1. DRIVER PIN (top, spring-loaded, blocks rotation)
 *   2. KEY PIN (bottom, rests on key when inserted)
 * 
 * - The SHEAR LINE is the boundary between the plug and housing
 * - Lock opens when ALL key pins' tops align exactly at the shear line
 * 
 * KeyPins Property:
 * - "keyPins" represents the LENGTH of the key pins (bottom pins) in the lock
 * - In scenarios: Defined on a 0-100 authoring scale for ease of design
 * - In game: Converted to 25-65 pixel range for actual rendering
 * - Example: [100, 0, 100, 0] → [65, 25, 65, 25] pixels
 * 
 * KeyPins on LOCKS vs KEYS:
 * - On a LOCK/DOOR: The actual pin lengths in that lock
 * - On a KEY: The lock configuration this key is designed to open
 *   (i.e., a key with keyPins: [65, 25, 65, 25] opens locks with those pin lengths)
 * 
 * Relationship: KeyPins → Cuts:
 * - CUTS are the depths of notches carved into the key blade
 * - Formula: cutDepth = keyPinLength - gapFromKeyBladeTopToShearLine
 * - Where gap = 20 pixels (175 - 155)
 * - Example: keyPin 65 → cut 45, keyPin 25 → cut 5
 * - When key is inserted, pin rests on cut surface, lifting to shear line
 * 
 * Why Normalization is Critical:
 * - Scenarios use 0-100 for easy authoring (percentages)
 * - Game needs 25-65 pixel range for proper physics/rendering
 * - Normalization must happen EXACTLY ONCE to avoid double-conversion
 * - This function runs during scenario load before any sprites are created
 */
function normalizeScenarioKeyPins(scenario) {
    
    // Helper function to convert a single keyPins value
    function convertKeyPin(value) {
        // Convert from 0-100 scale to 25-65 scale
        // Formula: 25 + (value / 100) * 40
        // This gives us a 40-pixel range centered in the lock chamber
        return Math.round(25 + (value / 100) * 40);
    }
    
    // IMPORTANT: Normalize keyPins in ALL places they appear in the scenario!
    // KeyPins must be normalized exactly once at scenario load time, BEFORE any items are dropped or used.
    // If keyPins appear in multiple places (startItemsInInventory, room objects, NPC itemsHeld, etc.),
    // they ALL need normalization or keys/locks won't match when used.
    // For example:
    // - A key in an NPC's itemsHeld must be normalized the same way as a room object key
    // - The door's room-level keyPins must be normalized the same way
    // - Otherwise when the NPC drops the key, it won't open the door!
    
    // Normalize keyPins in startItemsInInventory (for starting keys)
    if (scenario.startItemsInInventory && Array.isArray(scenario.startItemsInInventory)) {
        scenario.startItemsInInventory.forEach((item, index) => {
            if (item.keyPins && Array.isArray(item.keyPins)) {
                item.keyPins = item.keyPins.map(convertKeyPin);
                console.log(`🔄 Normalized startItem keyPins [${index}] (${item.type} "${item.name}"):`, item.keyPins);
            }
        });
    }
    
    // Iterate through all rooms
    Object.entries(scenario.rooms).forEach(([roomId, roomData]) => {
        if (!roomData) return;
        
        // Convert room-level keyPins (for door locks)
        if (roomData.keyPins && Array.isArray(roomData.keyPins)) {
            roomData.keyPins = roomData.keyPins.map(convertKeyPin);
            console.log(`🔄 Normalized room keyPins for ${roomId}:`, roomData.keyPins);
        }
        
        // Normalize NPC itemsHeld keyPins (items NPCs start with/carry)
        // CRITICAL: This ensures keys dropped by NPCs match the door's keyPins
        if (roomData.npcs && Array.isArray(roomData.npcs)) {
            roomData.npcs.forEach((npc, npcIndex) => {
                if (npc.itemsHeld && Array.isArray(npc.itemsHeld)) {
                    npc.itemsHeld.forEach((item, itemIndex) => {
                        if (item.keyPins && Array.isArray(item.keyPins)) {
                            item.keyPins = item.keyPins.map(convertKeyPin);
                            console.log(`🔄 Normalized NPC itemsHeld keyPins for ${roomId}.npcs[${npcIndex}].itemsHeld[${itemIndex}] (${item.type}):`, item.keyPins);
                        }
                    });
                }
            });
        }
        
        // Convert keyPins for all objects in the room
        if (roomData.objects && Array.isArray(roomData.objects)) {
            roomData.objects.forEach((obj, index) => {
                if (obj.keyPins && Array.isArray(obj.keyPins)) {
                    obj.keyPins = obj.keyPins.map(convertKeyPin);
                    console.log(`🔄 Normalized object keyPins for ${roomId}[${index}] (${obj.type}):`, obj.keyPins);
                }
                
                // Also check contents of objects (for keys in briefcases, etc.)
                if (obj.contents && Array.isArray(obj.contents)) {
                    obj.contents.forEach((content, contentIndex) => {
                        if (content.keyPins && Array.isArray(content.keyPins)) {
                            content.keyPins = content.keyPins.map(convertKeyPin);
                            console.log(`🔄 Normalized content keyPins for ${roomId}[${index}].contents[${contentIndex}] (${content.type}):`, content.keyPins);
                        }
                    });
                }
            });
        }
    });
    
    console.log('✓ All keyPins normalized to 25-65 range');
}

// Hide a room
function hideRoom(roomId) {
    if (window.rooms[roomId]) {
        const room = window.rooms[roomId];
        
        // Hide all layers
        Object.values(room.layers).forEach(layer => {
            if (layer && layer.setVisible) {
                layer.setVisible(false);
                layer.setAlpha(0);
            }
        });

        // Hide all objects (both active and inactive)
        if (room.objects) {
            Object.values(room.objects).forEach(obj => {
                if (obj && obj.setVisible) {
                    obj.setVisible(false);
                }
            });
        }
    }
}

 