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
    this.load.tilemapTiledJSON('room_reception', 'assets/rooms/room_reception2.json');
    this.load.tilemapTiledJSON('room_office', 'assets/rooms/room_office2.json');
    this.load.tilemapTiledJSON('room_ceo', 'assets/rooms/room_ceo2.json');
    this.load.tilemapTiledJSON('room_closet', 'assets/rooms/room_closet2.json');
    this.load.tilemapTiledJSON('room_servers', 'assets/rooms/room_servers2.json');

    // Load new variable-sized rooms for grid system
    this.load.tilemapTiledJSON('small_room_1x1gu', 'assets/rooms/small_room_1x1gu.json');
    this.load.tilemapTiledJSON('hall_1x2gu', 'assets/rooms/hall_1x2gu.json');

    // Load room images (now using smaller 32px scale images)
    this.load.image('room_reception', 'assets/tiles/rooms/room1.png');
    this.load.image('room18', 'assets/tiles/rooms/room18.png');
    this.load.image('room6', 'assets/tiles/rooms/room6.png');
    this.load.image('room14', 'assets/tiles/rooms/room14.png');
    this.load.image('room19', 'assets/tiles/rooms/room19.png');
    this.load.image('door_32', 'assets/tiles/door_32.png');
    this.load.spritesheet('door_sheet', 'assets/tiles/door_sheet_32.png', {
        frameWidth: 32,
        frameHeight: 64
    });

    // Load tileset images referenced by the new Tiled map
    this.load.image('office-updated', 'assets/tiles/rooms/room1.png');
    this.load.image('door_sheet_32', 'assets/tiles/door_sheet_32.png');

    // Load side door spritesheet for east/west doors (6 frames: closed, opening, open, etc.)
    this.load.spritesheet('door_side_sheet_32', 'assets/tiles/door_side_sheet_32.png', {
        frameWidth: 32,
        frameHeight: 32
    });
    
    // Load table tileset images
    this.load.image('desk-ceo1', 'assets/tables/desk-ceo1.png');
    this.load.image('desk-ceo2', 'assets/tables/desk-ceo2.png');
    this.load.image('desk1', 'assets/tables/desk1.png');
    this.load.image('smalldesk1', 'assets/tables/smalldesk1.png');
    this.load.image('smalldesk2', 'assets/tables/smalldesk2.png');
    this.load.image('reception_table1', 'assets/tables/reception_table1.png');

    // Load object sprites - keeping existing ones for backward compatibility
    this.load.image('pc', 'assets/objects/pc1.png');
    this.load.image('key', 'assets/objects/key.png');
    this.load.image('notes', 'assets/objects/notes1.png');
    this.load.image('phone', 'assets/objects/phone1.png');
    this.load.image('suitcase', 'assets/objects/suitcase-1.png');
    this.load.image('smartscreen', 'assets/objects/smartscreen.png');
    this.load.image('photo', 'assets/objects/picture1.png');
    this.load.image('safe', 'assets/objects/safe1.png');
    this.load.image('book', 'assets/objects/book1.png');
    this.load.image('workstation', 'assets/objects/workstation.png');
    this.load.image('bluetooth_scanner', 'assets/objects/bluetooth_scanner.png');
    this.load.image('bluetooth', 'assets/objects/bluetooth.png');
    this.load.image('tablet', 'assets/objects/tablet.png');
    this.load.image('fingerprint', 'assets/objects/fingerprint_small.png');
    this.load.image('lockpick', 'assets/objects/lockpick.png');
    this.load.image('spoofing_kit', 'assets/objects/office-misc-headphones.png');
    this.load.image('keyway', 'assets/icons/keyway.png');
    this.load.image('password', 'assets/icons/password.png');
    this.load.image('pin', 'assets/icons/pin.png');
    this.load.image('talk', 'assets/icons/talk.png');

    // Load RFID keycard and cloner assets
    this.load.image('keycard', 'assets/objects/keycard.png');
    this.load.image('keycard-ceo', 'assets/objects/keycard-ceo.png');
    this.load.image('keycard-security', 'assets/objects/keycard-security.png');
    this.load.image('keycard-maintenance', 'assets/objects/keycard-maintenance.png');
    this.load.image('rfid_cloner', 'assets/objects/rfid_cloner.png');
    this.load.image('rfid-icon', 'assets/icons/rfid-icon.png');
    this.load.image('nfc-waves', 'assets/icons/nfc-waves.png');

    // Load new object sprites from Tiled map tileset
    // These are the key objects that appear in the new room_reception2.json
    this.load.image('fingerprint_kit', 'assets/objects/fingerprint_kit.png');
    this.load.image('pin-cracker', 'assets/objects/pin-cracker.png');
    this.load.image('bin11', 'assets/objects/bin11.png');
    this.load.image('bin10', 'assets/objects/bin10.png');
    this.load.image('bin9', 'assets/objects/bin9.png');
    this.load.image('bin8', 'assets/objects/bin8.png');
    this.load.image('bin7', 'assets/objects/bin7.png');
    this.load.image('bin6', 'assets/objects/bin6.png');
    this.load.image('bin5', 'assets/objects/bin5.png');
    this.load.image('bin4', 'assets/objects/bin4.png');
    this.load.image('bin3', 'assets/objects/bin3.png');
    this.load.image('bin2', 'assets/objects/bin2.png');
    this.load.image('bin1', 'assets/objects/bin1.png');
    
    // Suitcases
    this.load.image('suitcase21', 'assets/objects/suitcase21.png');
    this.load.image('suitcase20', 'assets/objects/suitcase20.png');
    this.load.image('suitcase19', 'assets/objects/suitcase19.png');
    this.load.image('suitcase18', 'assets/objects/suitcase18.png');
    this.load.image('suitcase17', 'assets/objects/suitcase17.png');
    this.load.image('suitcase16', 'assets/objects/suitcase16.png');
    this.load.image('suitcase15', 'assets/objects/suitcase15.png');
    this.load.image('suitcase14', 'assets/objects/suitcase14.png');
    this.load.image('suitcase13', 'assets/objects/suitcase13.png');
    this.load.image('suitcase12', 'assets/objects/suitcase12.png');
    this.load.image('suitcase11', 'assets/objects/suitcase11.png');
    this.load.image('suitcase10', 'assets/objects/suitcase10.png');
    this.load.image('suitcase9', 'assets/objects/suitcase9.png');
    this.load.image('suitcase8', 'assets/objects/suitcase8.png');
    this.load.image('suitcase7', 'assets/objects/suitcase7.png');
    this.load.image('suitcase6', 'assets/objects/suitcase6.png');
    this.load.image('suitcase5', 'assets/objects/suitcase5.png');
    this.load.image('suitcase4', 'assets/objects/suitcase4.png');
    this.load.image('suitcase3', 'assets/objects/suitcase3.png');
    this.load.image('suitcase2', 'assets/objects/suitcase2.png');
    this.load.image('suitcase-1', 'assets/objects/suitcase-1.png');
    
    // Plants
    this.load.image('plant-flat-pot7', 'assets/objects/plant-flat-pot7.png');
    this.load.image('plant-flat-pot6', 'assets/objects/plant-flat-pot6.png');
    this.load.image('plant-flat-pot5', 'assets/objects/plant-flat-pot5.png');
    this.load.image('plant-flat-pot4', 'assets/objects/plant-flat-pot4.png');
    this.load.image('plant-flat-pot3', 'assets/objects/plant-flat-pot3.png');
    this.load.image('plant-flat-pot2', 'assets/objects/plant-flat-pot2.png');
    this.load.image('plant-flat-pot1', 'assets/objects/plant-flat-pot1.png');
    
    // Office furniture
    this.load.image('outdoor-lamp4', 'assets/objects/outdoor-lamp4.png');
    this.load.image('outdoor-lamp3', 'assets/objects/outdoor-lamp3.png');
    this.load.image('outdoor-lamp2', 'assets/objects/outdoor-lamp2.png');
    this.load.image('outdoor-lamp1', 'assets/objects/outdoor-lamp1.png');
    this.load.image('plant-large10', 'assets/objects/plant-large10.png');
    this.load.image('lamp-stand5', 'assets/objects/lamp-stand5.png');
    this.load.image('plant-large9', 'assets/objects/plant-large9.png');
    this.load.image('plant-large8', 'assets/objects/plant-large8.png');
    this.load.image('plant-large7', 'assets/objects/plant-large7.png');
    this.load.image('plant-large6', 'assets/objects/plant-large6.png');
    this.load.image('lamp-stand4', 'assets/objects/lamp-stand4.png');
    this.load.image('plant-large5', 'assets/objects/plant-large5.png');
    this.load.image('plant-large4', 'assets/objects/plant-large4.png');
    this.load.image('plant-large3', 'assets/objects/plant-large3.png');
    this.load.image('plant-large2', 'assets/objects/plant-large2.png');
    this.load.image('lamp-stand3', 'assets/objects/lamp-stand3.png');
    this.load.image('plant-large1', 'assets/objects/plant-large1.png');
    this.load.image('lamp-stand2', 'assets/objects/lamp-stand2.png');
    this.load.image('lamp-stand1', 'assets/objects/lamp-stand1.png');
    
    // Pictures
    this.load.image('picture14', 'assets/objects/picture14.png');
    this.load.image('picture13', 'assets/objects/picture13.png');
    this.load.image('picture12', 'assets/objects/picture12.png');
    this.load.image('picture11', 'assets/objects/picture11.png');
    this.load.image('picture10', 'assets/objects/picture10.png');
    this.load.image('picture9', 'assets/objects/picture9.png');
    this.load.image('picture8', 'assets/objects/picture8.png');
    this.load.image('picture7', 'assets/objects/picture7.png');
    this.load.image('picture6', 'assets/objects/picture6.png');
    this.load.image('picture5', 'assets/objects/picture5.png');
    this.load.image('picture4', 'assets/objects/picture4.png');
    this.load.image('picture3', 'assets/objects/picture3.png');
    this.load.image('picture2', 'assets/objects/picture2.png');
    this.load.image('picture1', 'assets/objects/picture1.png');
    
    // Office misc items
    this.load.image('office-misc-smallplant2', 'assets/objects/office-misc-smallplant2.png');
    this.load.image('office-misc-smallplant3', 'assets/objects/office-misc-smallplant3.png');
    this.load.image('office-misc-smallplant4', 'assets/objects/office-misc-smallplant4.png');
    this.load.image('office-misc-smallplant5', 'assets/objects/office-misc-smallplant5.png');
    this.load.image('office-misc-box1', 'assets/objects/office-misc-box1.png');
    this.load.image('office-misc-container', 'assets/objects/office-misc-container.png');
    this.load.image('office-misc-lamp3', 'assets/objects/office-misc-lamp3.png');
    this.load.image('office-misc-hdd6', 'assets/objects/office-misc-hdd6.png');
    this.load.image('office-misc-speakers6', 'assets/objects/office-misc-speakers6.png');
    this.load.image('office-misc-pencils6', 'assets/objects/office-misc-pencils6.png');
    this.load.image('office-misc-fan2', 'assets/objects/office-misc-fan2.png');
    this.load.image('office-misc-cup5', 'assets/objects/office-misc-cup5.png');
    this.load.image('office-misc-hdd5', 'assets/objects/office-misc-hdd5.png');
    this.load.image('office-misc-speakers5', 'assets/objects/office-misc-speakers5.png');
    this.load.image('office-misc-cup4', 'assets/objects/office-misc-cup4.png');
    this.load.image('office-misc-speakers4', 'assets/objects/office-misc-speakers4.png');
    this.load.image('office-misc-pencils5', 'assets/objects/office-misc-pencils5.png');

    this.load.image('office-misc-clock', 'assets/objects/office-misc-clock.png');
    this.load.image('office-misc-fan', 'assets/objects/office-misc-fan.png');
    this.load.image('office-misc-speakers3', 'assets/objects/office-misc-speakers3.png');
    this.load.image('office-misc-camera', 'assets/objects/office-misc-camera.png');
    this.load.image('office-misc-headphones', 'assets/objects/office-misc-headphones.png');
    this.load.image('office-misc-hdd4', 'assets/objects/office-misc-hdd4.png');
    this.load.image('office-misc-pencils4', 'assets/objects/office-misc-pencils4.png');
    this.load.image('office-misc-cup3', 'assets/objects/office-misc-cup3.png');
    this.load.image('office-misc-cup2', 'assets/objects/office-misc-cup2.png');
    this.load.image('office-misc-speakers2', 'assets/objects/office-misc-speakers2.png');
    this.load.image('office-misc-stapler', 'assets/objects/office-misc-stapler.png');
    this.load.image('office-misc-hdd3', 'assets/objects/office-misc-hdd3.png');
    this.load.image('office-misc-hdd2', 'assets/objects/office-misc-hdd2.png');
    this.load.image('office-misc-pencils3', 'assets/objects/office-misc-pencils3.png');
    this.load.image('office-misc-pencils2', 'assets/objects/office-misc-pencils2.png');
    this.load.image('office-misc-pens', 'assets/objects/office-misc-pens.png');
    this.load.image('office-misc-lamp2', 'assets/objects/office-misc-lamp2.png');
    this.load.image('office-misc-hdd', 'assets/objects/office-misc-hdd.png');
    this.load.image('office-misc-smallplant', 'assets/objects/office-misc-smallplant.png');
    this.load.image('office-misc-pencils', 'assets/objects/office-misc-pencils.png');
    this.load.image('office-misc-speakers', 'assets/objects/office-misc-speakers.png');
    this.load.image('office-misc-cup', 'assets/objects/office-misc-cup.png');
    this.load.image('office-misc-lamp', 'assets/objects/office-misc-lamp.png');
    this.load.image('phone5', 'assets/objects/phone5.png');
    this.load.image('phone4', 'assets/objects/phone4.png');
    this.load.image('phone3', 'assets/objects/phone3.png');
    this.load.image('phone2', 'assets/objects/phone2.png');
    this.load.image('phone1', 'assets/objects/phone1.png');
    
    // Bags and briefcases
    this.load.image('bag25', 'assets/objects/bag25.png');
    this.load.image('bag24', 'assets/objects/bag24.png');
    this.load.image('bag23', 'assets/objects/bag23.png');
    this.load.image('bag22', 'assets/objects/bag22.png');
    this.load.image('bag21', 'assets/objects/bag21.png');
    this.load.image('bag20', 'assets/objects/bag20.png');
    this.load.image('bag19', 'assets/objects/bag19.png');
    this.load.image('bag18', 'assets/objects/bag18.png');
    this.load.image('bag17', 'assets/objects/bag17.png');
    this.load.image('bag16', 'assets/objects/bag16.png');
    this.load.image('bag15', 'assets/objects/bag15.png');
    this.load.image('bag14', 'assets/objects/bag14.png');
    this.load.image('bag13', 'assets/objects/bag13.png');
    this.load.image('bag12', 'assets/objects/bag12.png');
    this.load.image('bag11', 'assets/objects/bag11.png');
    this.load.image('bag10', 'assets/objects/bag10.png');
    this.load.image('bag9', 'assets/objects/bag9.png');
    this.load.image('bag8', 'assets/objects/bag8.png');
    this.load.image('bag7', 'assets/objects/bag7.png');
    this.load.image('bag6', 'assets/objects/bag6.png');
    this.load.image('bag5', 'assets/objects/bag5.png');
    this.load.image('bag4', 'assets/objects/bag4.png');
    this.load.image('bag3', 'assets/objects/bag3.png');
    this.load.image('bag2', 'assets/objects/bag2.png');
    this.load.image('bag1', 'assets/objects/bag1.png');
    
    // Briefcases
    this.load.image('briefcase-orange-1', 'assets/objects/briefcase-orange-1.png');
    this.load.image('briefcase-yellow-1', 'assets/objects/briefcase-yellow-1.png');
    this.load.image('briefcase13', 'assets/objects/briefcase13.png');
    this.load.image('briefcase-purple-1', 'assets/objects/briefcase-purple-1.png');
    this.load.image('briefcase-green-1', 'assets/objects/briefcase-green-1.png');
    this.load.image('briefcase-blue-1', 'assets/objects/briefcase-blue-1.png');
    this.load.image('briefcase-red-1', 'assets/objects/briefcase-red-1.png');
    this.load.image('briefcase12', 'assets/objects/briefcase12.png');
    this.load.image('briefcase11', 'assets/objects/briefcase11.png');
    this.load.image('briefcase10', 'assets/objects/briefcase10.png');
    this.load.image('briefcase9', 'assets/objects/briefcase9.png');
    this.load.image('briefcase8', 'assets/objects/briefcase8.png');
    this.load.image('briefcase7', 'assets/objects/briefcase7.png');
    this.load.image('briefcase6', 'assets/objects/briefcase6.png');
    this.load.image('briefcase5', 'assets/objects/briefcase5.png');
    this.load.image('briefcase4', 'assets/objects/briefcase4.png');
    this.load.image('briefcase3', 'assets/objects/briefcase3.png');
    this.load.image('briefcase2', 'assets/objects/briefcase2.png');
    this.load.image('briefcase1', 'assets/objects/briefcase1.png');
    
    // Chairs
    this.load.image('chair-grey-4', 'assets/objects/chair-grey-4.png');
    this.load.image('chair-grey-3', 'assets/objects/chair-grey-3.png');
    this.load.image('chair-darkgreen-3', 'assets/objects/chair-darkgreen-3.png');
    this.load.image('chair-grey-2', 'assets/objects/chair-grey-2.png');
    this.load.image('chair-darkgray-1', 'assets/objects/chair-darkgray-1.png');
    this.load.image('chair-darkgreen-2', 'assets/objects/chair-darkgreen-2.png');
    this.load.image('chair-darkgreen-1', 'assets/objects/chair-darkgreen-1.png');
    this.load.image('chair-grey-1', 'assets/objects/chair-grey-1.png');
    this.load.image('chair-red-4', 'assets/objects/chair-red-4.png');
    this.load.image('chair-red-3', 'assets/objects/chair-red-3.png');
    this.load.image('chair-green-2', 'assets/objects/chair-green-2.png');
    this.load.image('chair-green-1', 'assets/objects/chair-green-1.png');
    this.load.image('chair-red-2', 'assets/objects/chair-red-2.png');
    this.load.image('chair-red-1', 'assets/objects/chair-red-1.png');
    this.load.image('chair-white-2', 'assets/objects/chair-white-2.png');
    this.load.image('chair-white-1', 'assets/objects/chair-white-1.png');
    
    // Keyboards
    this.load.image('keyboard8', 'assets/objects/keyboard8.png');
    this.load.image('keyboard7', 'assets/objects/keyboard7.png');
    this.load.image('keyboard6', 'assets/objects/keyboard6.png');
    this.load.image('keyboard5', 'assets/objects/keyboard5.png');
    this.load.image('keyboard4', 'assets/objects/keyboard4.png');
    this.load.image('keyboard3', 'assets/objects/keyboard3.png');
    this.load.image('keyboard2', 'assets/objects/keyboard2.png');
    this.load.image('keyboard1', 'assets/objects/keyboard1.png');
    
    // Safes
    this.load.image('safe5', 'assets/objects/safe5.png');
    this.load.image('safe4', 'assets/objects/safe4.png');
    this.load.image('safe3', 'assets/objects/safe3.png');
    this.load.image('safe2', 'assets/objects/safe2.png');
    this.load.image('safe1', 'assets/objects/safe1.png');
    
    // Notes
    this.load.image('notes1', 'assets/objects/notes1.png');
    this.load.image('notes2', 'assets/objects/notes2.png');
    this.load.image('notes3', 'assets/objects/notes3.png');
    this.load.image('notes4', 'assets/objects/notes4.png');

    
    // Servers and tech
    this.load.image('servers', 'assets/objects/servers.png');
    this.load.image('servers3', 'assets/objects/servers3.png');
    this.load.image('servers2', 'assets/objects/servers2.png');
    this.load.image('sofa1', 'assets/objects/sofa1.png');
    this.load.image('plant-large13', 'assets/objects/plant-large13.png');
    this.load.image('office-misc-lamp4', 'assets/objects/office-misc-lamp4.png');
    this.load.image('chair-waiting-right-1', 'assets/objects/chair-waiting-right-1.png');
    this.load.image('chair-waiting-left-1', 'assets/objects/chair-waiting-left-1.png');
    this.load.image('plant-large12', 'assets/objects/plant-large12.png');
    this.load.image('plant-large11', 'assets/objects/plant-large11.png');
    
    // Load animated plant frames
    this.load.image('plant-large11-top-ani1', 'assets/objects/plant-large11-top-ani1.png');
    this.load.image('plant-large11-top-ani2', 'assets/objects/plant-large11-top-ani2.png');
    this.load.image('plant-large11-top-ani3', 'assets/objects/plant-large11-top-ani3.png');
    this.load.image('plant-large11-top-ani4', 'assets/objects/plant-large11-top-ani4.png');
    
    this.load.image('plant-large12-top-ani1', 'assets/objects/plant-large12-top-ani1.png');
    this.load.image('plant-large12-top-ani2', 'assets/objects/plant-large12-top-ani2.png');
    this.load.image('plant-large12-top-ani3', 'assets/objects/plant-large12-top-ani3.png');
    this.load.image('plant-large12-top-ani4', 'assets/objects/plant-large12-top-ani4.png');
    this.load.image('plant-large12-top-ani5', 'assets/objects/plant-large12-top-ani5.png');
    
    this.load.image('plant-large13-top-ani1', 'assets/objects/plant-large13-top-ani1.png');
    this.load.image('plant-large13-top-ani2', 'assets/objects/plant-large13-top-ani2.png');
    this.load.image('plant-large13-top-ani3', 'assets/objects/plant-large13-top-ani3.png');
    this.load.image('plant-large13-top-ani4', 'assets/objects/plant-large13-top-ani4.png');
    this.load.image('pc1', 'assets/objects/pc1.png');
    this.load.image('pc3', 'assets/objects/pc3.png');
    this.load.image('pc4', 'assets/objects/pc4.png');
    this.load.image('pc5', 'assets/objects/pc5.png');
    this.load.image('pc6', 'assets/objects/pc6.png');
    this.load.image('pc7', 'assets/objects/pc7.png');
    this.load.image('pc8', 'assets/objects/pc8.png');
    this.load.image('pc9', 'assets/objects/pc9.png');
    this.load.image('pc10', 'assets/objects/pc10.png');
    this.load.image('pc11', 'assets/objects/pc11.png');
    this.load.image('pc12', 'assets/objects/pc12.png');

    
    // Laptops
    this.load.image('laptop7', 'assets/objects/laptop7.png');
    this.load.image('laptop6', 'assets/objects/laptop6.png');
    this.load.image('laptop5', 'assets/objects/laptop5.png');
    this.load.image('laptop4', 'assets/objects/laptop4.png');
    this.load.image('laptop3', 'assets/objects/laptop3.png');
    this.load.image('laptop2', 'assets/objects/laptop2.png');
    this.load.image('laptop1', 'assets/objects/laptop1.png');
    
    // Chalkboards and bookcases
    this.load.image('chalkboard3', 'assets/objects/chalkboard3.png');
    this.load.image('chalkboard2', 'assets/objects/chalkboard2.png');
    this.load.image('chalkboard', 'assets/objects/chalkboard.png');
    this.load.image('bookcase', 'assets/objects/bookcase.png');
    
    // Spooky basement items
    this.load.image('spooky-splatter', 'assets/objects/spooky-splatter.png');
    this.load.image('spooky-candles2', 'assets/objects/spooky-candles2.png');
    this.load.image('spooky-candles', 'assets/objects/spooky-candles.png');
    this.load.image('torch-left', 'assets/objects/torch-left.png');
    this.load.image('torch-right', 'assets/objects/torch-right.png');
    this.load.image('torch-1', 'assets/objects/torch-1.png');

    // Load character sprite sheet instead of single image
    this.load.spritesheet('hacker', 'assets/characters/hacker.png', {
        frameWidth: 64,
        frameHeight: 64
    });

    // Load character sprite sheet instead of single image
    this.load.spritesheet('hacker-red', 'assets/characters/hacker-red.png', {
        frameWidth: 64,
        frameHeight: 64
    });

    // Animated plant textures are loaded above
    
    // Load swivel chair rotation images
    this.load.image('chair-exec-rotate1', 'assets/objects/chair-exec-rotate1.png');
    this.load.image('chair-exec-rotate2', 'assets/objects/chair-exec-rotate2.png');
    this.load.image('chair-exec-rotate3', 'assets/objects/chair-exec-rotate3.png');
    this.load.image('chair-exec-rotate4', 'assets/objects/chair-exec-rotate4.png');
    this.load.image('chair-exec-rotate5', 'assets/objects/chair-exec-rotate5.png');
    this.load.image('chair-exec-rotate6', 'assets/objects/chair-exec-rotate6.png');
    this.load.image('chair-exec-rotate7', 'assets/objects/chair-exec-rotate7.png');
    this.load.image('chair-exec-rotate8', 'assets/objects/chair-exec-rotate8.png');
    
    // Load white chair rotation images
    this.load.image('chair-white-1-rotate1', 'assets/objects/chair-white-1-rotate1.png');
    this.load.image('chair-white-1-rotate2', 'assets/objects/chair-white-1-rotate2.png');
    this.load.image('chair-white-1-rotate3', 'assets/objects/chair-white-1-rotate3.png');
    this.load.image('chair-white-1-rotate4', 'assets/objects/chair-white-1-rotate4.png');
    this.load.image('chair-white-1-rotate5', 'assets/objects/chair-white-1-rotate5.png');
    this.load.image('chair-white-1-rotate6', 'assets/objects/chair-white-1-rotate6.png');
    this.load.image('chair-white-1-rotate7', 'assets/objects/chair-white-1-rotate7.png');
    this.load.image('chair-white-1-rotate8', 'assets/objects/chair-white-1-rotate8.png');
    
    this.load.image('chair-white-2-rotate1', 'assets/objects/chair-white-2-rotate1.png');
    this.load.image('chair-white-2-rotate2', 'assets/objects/chair-white-2-rotate2.png');
    this.load.image('chair-white-2-rotate3', 'assets/objects/chair-white-2-rotate3.png');
    this.load.image('chair-white-2-rotate4', 'assets/objects/chair-white-2-rotate4.png');
    this.load.image('chair-white-2-rotate5', 'assets/objects/chair-white-2-rotate5.png');
    this.load.image('chair-white-2-rotate6', 'assets/objects/chair-white-2-rotate6.png');
    this.load.image('chair-white-2-rotate7', 'assets/objects/chair-white-2-rotate7.png');
    this.load.image('chair-white-2-rotate8', 'assets/objects/chair-white-2-rotate8.png');

    // Load audio files
    // NPC system sounds
    this.load.audio('message_received', 'assets/sounds/message_received.mp3');
    
    // Initialize sound manager and preload all sounds
    // Store as window property so we can access it later in create()
    window.soundManagerPreload = new SoundManager(this);
    window.soundManagerPreload.preloadSounds();

    // Get scenario from URL parameter or use default
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

 