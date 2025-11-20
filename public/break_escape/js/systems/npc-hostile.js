import { COMBAT_CONFIG } from '../config/combat-config.js';
import { CombatEvents } from '../events/combat-events.js';

const npcHostileStates = new Map();

function createHostileState(npcId, config = {}) {
  return {
    isHostile: false,
    currentHP: config.maxHP || COMBAT_CONFIG.npc.defaultMaxHP,
    maxHP: config.maxHP || COMBAT_CONFIG.npc.defaultMaxHP,
    isKO: false,
    attackDamage: config.attackDamage || COMBAT_CONFIG.npc.defaultPunchDamage,
    attackRange: config.attackRange || COMBAT_CONFIG.npc.defaultPunchRange,
    attackCooldown: config.attackCooldown || COMBAT_CONFIG.npc.defaultAttackCooldown,
    lastAttackTime: 0
  };
}

export function initNPCHostileSystem() {
  console.log('✅ NPC hostile system initialized');

  return {
    setNPCHostile: (npcId, isHostile) => setNPCHostile(npcId, isHostile),
    isNPCHostile: (npcId) => isNPCHostile(npcId),
    getState: (npcId) => getNPCHostileState(npcId),
    damageNPC: (npcId, amount) => damageNPC(npcId, amount),
    isNPCKO: (npcId) => isNPCKO(npcId)
  };
}

function setNPCHostile(npcId, isHostile) {
  if (!npcId) {
    console.error('setNPCHostile: Invalid NPC ID');
    return false;
  }

  // Get or create state
  let state = npcHostileStates.get(npcId);
  if (!state) {
    state = createHostileState(npcId);
    npcHostileStates.set(npcId, state);
  }

  const wasHostile = state.isHostile;
  state.isHostile = isHostile;

  console.log(`⚔️ NPC ${npcId} hostile: ${wasHostile} → ${isHostile}`);

  // Emit event if state changed
  if (wasHostile !== isHostile && window.eventDispatcher) {
    console.log(`⚔️ Emitting NPC_HOSTILE_CHANGED for ${npcId} (isHostile=${isHostile})`);
    window.eventDispatcher.emit(CombatEvents.NPC_HOSTILE_CHANGED, {
      npcId,
      isHostile
    });
  } else if (wasHostile === isHostile) {
    console.log(`⚔️ State unchanged for ${npcId} (already ${wasHostile}), skipping event`);
  } else {
    console.warn(`⚔️ Event dispatcher not found, cannot emit NPC_HOSTILE_CHANGED`);
  }

  return true;
}

function isNPCHostile(npcId) {
  const state = npcHostileStates.get(npcId);
  return state ? state.isHostile : false;
}

function getNPCHostileState(npcId) {
  let state = npcHostileStates.get(npcId);
  if (!state) {
    state = createHostileState(npcId);
    npcHostileStates.set(npcId, state);
  }
  return state;
}

function damageNPC(npcId, amount) {
  const state = getNPCHostileState(npcId);
  if (!state) return false;

  if (state.isKO) {
    console.log(`NPC ${npcId} already KO`);
    return false;
  }

  const oldHP = state.currentHP;
  state.currentHP = Math.max(0, state.currentHP - amount);

  console.log(`NPC ${npcId} HP: ${oldHP} → ${state.currentHP}`);

  // Check for KO
  if (state.currentHP <= 0) {
    state.isKO = true;

    // Apply KO visual effect to sprite
    const npc = window.npcManager?.getNPC(npcId);
    if (npc && npc.sprite && window.spriteEffects) {
      window.spriteEffects.setKOAlpha(npc.sprite, 0.5);
    }

    // Drop any items the NPC was holding
    dropNPCItems(npcId);

    if (window.eventDispatcher) {
      window.eventDispatcher.emit(CombatEvents.NPC_KO, { npcId });
    }
  }

  return true;
}

/**
 * Drop items around a defeated NPC
 * Items spawn at NPC location and are launched outward with physics
 * They collide with walls, doors, and chairs so they stay in reach
 * @param {string} npcId - The NPC that was defeated
 */
function dropNPCItems(npcId) {
  const npc = window.npcManager?.getNPC(npcId);
  if (!npc || !npc.itemsHeld || npc.itemsHeld.length === 0) {
    return;
  }

  // Find the NPC sprite and room to get its position
  let npcSprite = null;
  let npcRoomId = null;
  if (window.rooms) {
    for (const roomId in window.rooms) {
      const room = window.rooms[roomId];
      if (!room.npcSprites) continue;
      for (const sprite of room.npcSprites) {
        if (sprite.npcId === npcId) {
          npcSprite = sprite;
          npcRoomId = roomId;
          break;
        }
      }
      if (npcSprite) break;
    }
  }

  if (!npcSprite || !npcRoomId) {
    console.warn(`Could not find NPC sprite to drop items for ${npcId}`);
    return;
  }

  const room = window.rooms[npcRoomId];
  const gameRef = window.game;
  const itemCount = npc.itemsHeld.length;
  const launchSpeed = 200; // pixels per second
  
  npc.itemsHeld.forEach((item, index) => {
    // Calculate angle around the NPC for each item
    const angle = (index / itemCount) * Math.PI * 2;
    
    // All items spawn at NPC center location
    const spawnX = Math.round(npcSprite.x);
    const spawnY = Math.round(npcSprite.y);

    // Create actual Phaser sprite for the dropped item
    const texture = item.texture || item.type || 'key';
    const spriteObj = gameRef.add.sprite(spawnX, spawnY, texture);
    
    // Set origin to match standard object creation
    spriteObj.setOrigin(0, 0);
    
    // Create scenario data from the dropped item
    const droppedItemData = {
      ...item,
      type: item.type || 'dropped_item',
      name: item.name || 'Item',
      takeable: true,
      active: true,
      visible: true,
      interactable: true
    };
    
    // DEBUG: Log key properties if this is a key
    if (item.type === 'key') {
      console.log(`🔑 Dropped key "${item.name}":`, {
        source: 'npc-hostile.js dropNPCItems',
        item_key_id: item.key_id,
        item_keyPins: item.keyPins,
        droppedItemData_key_id: droppedItemData.key_id,
        droppedItemData_keyPins: droppedItemData.keyPins
      });
    }
    
    // Apply scenario properties to sprite
    spriteObj.scenarioData = droppedItemData;
    spriteObj.interactable = true;
    spriteObj.name = droppedItemData.name;
    spriteObj.objectId = `dropped_${npcId}_${index}_${Date.now()}`;
    spriteObj.takeable = true;
    spriteObj.type = droppedItemData.type;
    
    // Copy over all properties from the item
    Object.keys(droppedItemData).forEach(key => {
      spriteObj[key] = droppedItemData[key];
    });
    
    // Make the sprite interactive
    spriteObj.setInteractive({ useHandCursor: true });
    
    // Set up physics body for collision
    gameRef.physics.add.existing(spriteObj);
    spriteObj.body.setSize(24, 24);
    spriteObj.body.setOffset(4, 4);
    spriteObj.body.setBounce(0.3); // Reduced bounce
    spriteObj.body.setFriction(0.99, 0.99); // High friction to stop movement
    spriteObj.body.setDrag(0.99); // Drag coefficient to slow velocity
    
    // Launch item outward in the calculated angle
    const velocityX = Math.cos(angle) * launchSpeed;
    const velocityY = Math.sin(angle) * launchSpeed;
    spriteObj.body.setVelocity(velocityX, velocityY);
    
    // Set a timer to completely stop the item after a short time
    const stopDelay = 800; // Stop after 0.8 seconds
    gameRef.time.delayedCall(stopDelay, () => {
      if (spriteObj && spriteObj.body) {
        spriteObj.body.setVelocity(0, 0);
        spriteObj.body.setAcceleration(0, 0);
      }
    });
    
    // Set up collisions with walls
    if (room.wallCollisionBoxes) {
      room.wallCollisionBoxes.forEach(wallBox => {
        if (wallBox.body) {
          gameRef.physics.add.collider(spriteObj, wallBox);
        }
      });
    }
    
    // Set up collisions with closed doors
    if (room.doorSprites) {
      room.doorSprites.forEach(doorSprite => {
        if (doorSprite.body && doorSprite.body.immovable) {
          gameRef.physics.add.collider(spriteObj, doorSprite);
        }
      });
    }
    
    // Set up collisions with chairs and other immovable objects
    if (room.objects) {
      Object.values(room.objects).forEach(obj => {
        if (obj !== spriteObj && obj.body && obj.body.immovable) {
          gameRef.physics.add.collider(spriteObj, obj);
        }
      });
    }
    
    // Set depth using the existing depth calculation method
    // depth = objectBottomY + 0.5
    const objectBottomY = spriteObj.y + (spriteObj.height || 0);
    const objectDepth = objectBottomY + 0.5;
    spriteObj.setDepth(objectDepth);
    
    // Update depth each frame to follow Y position
    const originalUpdate = spriteObj.update?.bind(spriteObj);
    spriteObj.update = function() {
      if (originalUpdate) originalUpdate();
      const newDepth = this.y + (this.height || 0) + 0.5;
      this.setDepth(newDepth);
    };
    
    // Store in room.objects
    room.objects[spriteObj.objectId] = spriteObj;
    
    console.log(`💧 Dropped item ${droppedItemData.type} from ${npcId} at (${spawnX}, ${spawnY}), launching at angle ${(angle * 180 / Math.PI).toFixed(1)}°`);
  });

  // Clear the NPC's inventory
  npc.itemsHeld = [];
}

function isNPCKO(npcId) {
  const state = npcHostileStates.get(npcId);
  return state ? state.isKO : false;
}
