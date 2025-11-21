# Implementation Review #2: Server-Side Validation & Data Filtering
**Date:** November 21, 2025  
**Status:** Pre-Implementation Review  
**Scope:** Critical analysis of implementation plan with actionable recommendations

---

## Executive Summary

The implementation plan for server-side validation is **architecturally sound** but has several **critical gaps** that will cause failures during implementation. This review identifies 25+ specific issues and provides concrete solutions for each.

**Overall Assessment:** 🟡 **Needs Refinement Before Implementation**

**Key Concerns:**
1. ✅ **Strengths:** Good separation of concerns, clear validation logic, proper filtering approach
2. ⚠️ **Gaps:** Missing client-side API integration, incomplete NPC itemsHeld handling, no container endpoint client code
3. 🔴 **Risks:** No transaction/rollback strategy, missing error recovery, client-server sync issues

---

## Critical Issues & Solutions

### 🔴 CRITICAL #1: No Client-Side API Integration Plan

**Problem:**  
The implementation plan focuses entirely on server changes but provides **zero guidance** on updating the client to call the new endpoints. Client code currently:
- Calls `addToInventory()` locally without server validation
- Never checks with server if items are collectible
- Has no code to call the new `/container/:container_id` endpoint
- Doesn't handle 403 Forbidden responses for locked rooms

**Impact:** Even after server implementation, the game won't actually validate anything because the client bypasses the server.

**Solution:**

#### Phase 11: Client-Side Integration (ADD TO PLAN)

**File:** `public/break_escape/js/systems/inventory.js`

Update `addToInventory()` to validate with server:

```javascript
export async function addToInventory(sprite) {
    if (!sprite || !sprite.scenarioData) {
        console.warn('Invalid sprite for inventory');
        return false;
    }
    
    // Check if already in inventory (local check first)
    const itemIdentifier = createItemIdentifier(sprite.scenarioData);
    const isAlreadyInInventory = window.inventory.items.some(item => 
        item && createItemIdentifier(item.scenarioData) === itemIdentifier
    );
    
    if (isAlreadyInInventory) {
        console.log(`Item ${itemIdentifier} is already in inventory`);
        return false;
    }
    
    // NEW: Validate with server before adding
    const gameId = window.gameId;
    if (gameId) {
        try {
            const response = await fetch(`/break_escape/games/${gameId}/inventory`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    action_type: 'add',
                    item: sprite.scenarioData
                })
            });
            
            const result = await response.json();
            
            if (!result.success) {
                // Server rejected - show error to player
                window.gameAlert(result.message || 'Cannot collect this item', 'error', 'Invalid Action', 3000);
                return false;
            }
            
            // Server accepted - continue with local inventory update
            console.log('Server validated item collection:', result);
        } catch (error) {
            console.error('Failed to validate inventory with server:', error);
            // Fail closed - don't add if server can't validate
            window.gameAlert('Network error - please try again', 'error', 'Error', 3000);
            return false;
        }
    }
    
    // ... rest of existing addToInventory logic ...
}
```

**File:** `public/break_escape/js/minigames/container/container-minigame.js`

Update container opening to fetch contents from server:

```javascript
// In ContainerMinigame.init() or wherever contents are loaded
async loadContainerContents() {
    const gameId = window.gameId;
    const containerId = this.containerItem.scenarioData.id || this.containerItem.objectId;
    
    if (!gameId) {
        console.error('No gameId available for container loading');
        return [];
    }
    
    try {
        const response = await fetch(`/break_escape/games/${gameId}/container/${containerId}`);
        
        if (!response.ok) {
            if (response.status === 403) {
                window.gameAlert('Container is locked', 'error', 'Locked', 2000);
                this.complete(false);
                return [];
            }
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        return data.contents || [];
    } catch (error) {
        console.error('Failed to load container contents:', error);
        window.gameAlert('Could not load container contents', 'error', 'Error', 3000);
        return [];
    }
}
```

---

### 🔴 CRITICAL #2: Missing Player State Initialization on Game Creation

**Problem:**  
The plan says "call `initialize_player_state!` in GamesController#create" but **doesn't show the actual implementation** in the controller. The `before_create` callback in the model already handles this, so adding it to the controller would **duplicate** the initialization.

**Current State:**  
```ruby
# app/models/break_escape/game.rb (lines 19-20)
before_create :generate_scenario_data
before_create :initialize_player_state  # ✅ Already exists!
```

**Solution:**

The model callback **already handles initialization correctly**. Remove this from the TODO list:
- ~~1.3 Call initialization in GamesController#create~~ ✅ Already done via callback

However, we should **verify** that starting items are added correctly:

```ruby
# app/models/break_escape/game.rb
def initialize_player_state
  self.player_state ||= {}
  self.player_state['currentRoom'] ||= scenario_data['startRoom']
  self.player_state['unlockedRooms'] ||= [scenario_data['startRoom']]
  self.player_state['unlockedObjects'] ||= []
  self.player_state['inventory'] ||= []
  
  # ADD THIS: Initialize starting items from scenario
  if scenario_data['startItemsInInventory'].present?
    scenario_data['startItemsInInventory'].each do |item|
      self.player_state['inventory'] << item.deep_dup
    end
  end
  
  self.player_state['encounteredNPCs'] ||= []
  self.player_state['globalVariables'] ||= {}
  self.player_state['biometricSamples'] ||= []
  self.player_state['biometricUnlocks'] ||= []
  self.player_state['bluetoothDevices'] ||= []
  self.player_state['notes'] ||= []
  self.player_state['health'] ||= 100
end
```

---

### 🔴 CRITICAL #3: NPC itemsHeld Structure Unclear

**Problem:**  
The plan mentions checking `npc['itemsHeld']` but the actual structure in scenario files is unclear. Looking at the codebase:

```javascript
// public/break_escape/js/minigames/container/container-minigame.js (line 512)
if (npc && npc.itemsHeld) {
    const npcItemIndex = npc.itemsHeld.findIndex(i => i === item);
```

This suggests `itemsHeld` is an **array of item objects**, not IDs. But the validation code treats it like items with `type` and `id` fields.

**Current Implementation Issue:**
```ruby
# IMPLEMENTATION_PLAN.md (lines 427-431) - WRONG
npc['itemsHeld'].each do |held_item|
  if held_item['type'] == item_type && 
     (held_item['id'] == item_id || held_item['name'] == item_id)
    return { id: npc['id'] }
  end
end
```

**Actual Structure (from client code):**
- NPCs have `itemsHeld: Array` where each item is a **full item object** (same structure as room objects)
- Items are compared by **object reference equality** (`i === item`)
- No consistent `id` field - items use `type` as primary identifier

**Solution:**

Update `find_npc_holding_item` helper:

```ruby
def find_npc_holding_item(item_type, item_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    room_data['npcs']&.each do |npc|
      next unless npc['itemsHeld'].present?
      
      # itemsHeld is array of full item objects
      npc['itemsHeld'].each do |held_item|
        # Match by type (required) and optionally by id/name
        if held_item['type'] == item_type
          # If item_id provided, verify it matches
          if item_id.present?
            item_matches = (held_item['id'] == item_id) || 
                          (held_item['name'] == item_id) ||
                          (item_id == item_type) # Fallback if no id
            next unless item_matches
          end
          
          return { 
            id: npc['id'],
            npc: npc,
            item: held_item 
          }
        end
      end
    end
  end
  nil
end
```

---

### ⚠️ WARNING #4: Filtered Room Data Removes Too Much

**Problem:**  
The current `filtered_room_data` implementation removes `lockType` and `contents`:

```ruby
# app/models/break_escape/game.rb (lines 134-147)
def filtered_room_data(room_id)
  room = room_data(room_id)&.deep_dup
  return nil unless room

  # Remove solutions
  room.delete('requires')
  room.delete('lockType') if room['locked']  # ❌ Client needs this!

  # Remove solutions from objects
  room['objects']&.each do |obj|
    obj.delete('requires')
    obj.delete('lockType') if obj['locked']  # ❌ Client needs this!
    obj.delete('contents') if obj['locked']  # ✅ Correct
  end

  room
end
```

**Issue:** The GOALS_AND_DECISIONS document explicitly states:

> **Decision 2:** Hide Only `requires` and `contents` (Not `lockType`)
> - SHOW: Everything else (`lockType`, `locked`, `observations`, etc.)

But the current code **deletes lockType**, breaking the client's ability to show the correct unlock UI.

**Solution:**

Update `filtered_room_data`:

```ruby
def filtered_room_data(room_id)
  room = room_data(room_id)&.deep_dup
  return nil unless room

  # Remove ONLY the 'requires' field (the solution)
  # Keep lockType, locked, observations visible
  filter_requires_and_contents_recursive(room)
  
  room
end

private

def filter_requires_and_contents_recursive(obj)
  case obj
  when Hash
    # Remove 'requires' (the answer)
    obj.delete('requires')
    
    # Remove 'contents' if locked (lazy-loaded separately)
    obj.delete('contents') if obj['locked']
    
    # Keep lockType - client needs it to show correct UI
    # Keep locked - client needs it to show lock status
    
    # Recursively filter nested objects
    obj['objects']&.each { |o| filter_requires_and_contents_recursive(o) }
    obj['npcs']&.each { |n| filter_requires_and_contents_recursive(n) }
    
  when Array
    obj.each { |item| filter_requires_and_contents_recursive(item) }
  end
end
```

---

### ⚠️ WARNING #5: Room Access Check Uses Wrong Logic

**Problem:**  
The room endpoint checks:

```ruby
# IMPLEMENTATION_PLAN.md suggests:
unless @game.player_state['unlockedRooms']&.include?(room_id)
  return render_error("Room not accessible: #{room_id}", :forbidden)
end
```

But this **breaks the starting room** on first access if initialization fails or the client requests the room before the model callback runs.

**Root Cause:**  
Race condition:
1. Client requests `/games/:id/room/reception`
2. `player_state['unlockedRooms']` might still be `[]` if callback hasn't saved yet
3. Request denied even though it's the starting room

**Solution:**

Add defensive check in room endpoint:

```ruby
def room
  authorize @game if defined?(Pundit)

  room_id = params[:room_id]
  return render_error('Missing room_id parameter', :bad_request) unless room_id.present?

  # Check if room is accessible (starting room OR in unlockedRooms)
  is_start_room = @game.scenario_data['startRoom'] == room_id
  is_unlocked = @game.player_state['unlockedRooms']&.include?(room_id)
  
  unless is_start_room || is_unlocked
    return render_error("Room not accessible: #{room_id}", :forbidden)
  end

  # Auto-add start room if missing (defensive programming)
  if is_start_room && !is_unlocked
    @game.player_state['unlockedRooms'] ||= []
    @game.player_state['unlockedRooms'] << room_id
    @game.save!
  end

  # Get and filter room data
  room_data = @game.filtered_room_data(room_id)
  return render_error("Room not found: #{room_id}", :not_found) unless room_data

  # Track NPC encounters
  track_npc_encounters(room_id, room_data)

  # Filter out 'contents' field - lazy-loaded via separate endpoint
  filter_contents_field(room_data)

  Rails.logger.debug "[BreakEscape] Serving room data for: #{room_id}"

  render json: { room_id: room_id, room: room_data }
end
```

---

### ⚠️ WARNING #6: Container Endpoint Has Wrong ID Resolution

**Problem:**  
The plan uses `params[:container_id]` but doesn't clarify:
- Is this the object's `id` field?
- Is this the object's `name` field?
- Is this the `objectId` (e.g., `safe_1`)?

From the client code, containers are identified by **objectId** (generated dynamically), not scenario `id`.

**Evidence:**
```javascript
// public/break_escape/js/minigames/container/container-minigame.js (line 193)
itemImg.objectId = `container_${index}`;
```

**Solution:**

The container endpoint needs to search by **multiple identifiers**:

```ruby
def container
  authorize @game if defined?(Pundit)

  container_id = params[:container_id]
  return render_error('Missing container_id parameter', :bad_request) unless container_id.present?

  # Find container in scenario data
  container_data = find_container_in_scenario(container_id)
  return render_error("Container not found: #{container_id}", :not_found) unless container_data

  # Check if container is unlocked
  # Container might be identified by id, name, or type
  is_unlocked = check_container_unlocked(container_id, container_data)
  
  unless is_unlocked
    return render_error("Container not unlocked: #{container_id}", :forbidden)
  end

  # Return filtered contents
  contents = filter_container_contents(container_data)

  Rails.logger.debug "[BreakEscape] Serving container contents for: #{container_id}"

  render json: {
    container_id: container_id,
    contents: contents
  }
end

private

def check_container_unlocked(container_id, container_data)
  unlocked_list = @game.player_state['unlockedObjects'] || []
  
  # Check multiple possible identifiers
  unlocked_list.include?(container_id) ||
  unlocked_list.include?(container_data['id']) ||
  unlocked_list.include?(container_data['name']) ||
  unlocked_list.include?(container_data['type'])
end

def filter_container_contents(container_data)
  contents = container_data['contents']&.map do |item|
    item_copy = item.deep_dup
    filter_requires_and_contents_recursive(item_copy)
    item_copy
  end || []
  
  contents
end
```

---

### ⚠️ WARNING #7: No Transaction Safety

**Problem:**  
When unlocking doors/objects, the code modifies `player_state` and saves:

```ruby
@game.player_state['unlockedRooms'] << target_id
@game.save!
```

But if `@game.save!` fails (validation error, DB connection lost, etc.), the in-memory state is corrupted but not persisted. The client receives success but the server has no record.

**Solution:**

Wrap unlock operations in transactions:

```ruby
def unlock
  authorize @game if defined?(Pundit)

  target_type = params[:targetType]
  target_id = params[:targetId]
  attempt = params[:attempt]
  method = params[:method]

  is_valid = @game.validate_unlock(target_type, target_id, attempt, method)

  unless is_valid
    return render json: {
      success: false,
      message: 'Invalid attempt'
    }, status: :unprocessable_entity
  end

  # Use transaction to ensure atomic update
  ActiveRecord::Base.transaction do
    if target_type == 'door'
      @game.unlock_room!(target_id)
      
      room_data = @game.filtered_room_data(target_id)
      filter_contents_field(room_data)

      render json: {
        success: true,
        type: 'door',
        roomData: room_data
      }
    else
      @game.unlock_object!(target_id)
      
      render json: {
        success: true,
        type: 'object'
      }
    end
  end
rescue ActiveRecord::RecordInvalid => e
  render json: {
    success: false,
    message: "Failed to save unlock: #{e.message}"
  }, status: :unprocessable_entity
end
```

---

### ⚠️ WARNING #8: NPC Encounter Tracking Mutates State Without Saving

**Problem:**  
```ruby
# IMPLEMENTATION_PLAN.md suggests:
if room_data['npcs'].present?
  npc_ids = room_data['npcs'].map { |npc| npc['id'] }
  @game.player_state['encounteredNPCs'] ||= []
  @game.player_state['encounteredNPCs'].concat(npc_ids)
  @game.player_state['encounteredNPCs'].uniq!
  @game.save!  # ✅ Saves to DB
end
```

But what if `@game.save!` fails? The response already sent `room_data` to the client, so client thinks it succeeded, but server has no record of the encounter.

**Solution:**

Track encounters in a transaction **before** sending response:

```ruby
def room
  authorize @game if defined?(Pundit)

  room_id = params[:room_id]
  # ... validation ...

  # Track NPC encounters BEFORE sending response
  ActiveRecord::Base.transaction do
    track_npc_encounters(room_id, room_data)
  end

  # Filter and send response
  filter_contents_field(room_data)
  render json: { room_id: room_id, room: room_data }
rescue ActiveRecord::RecordInvalid => e
  render_error("Failed to track NPC encounters: #{e.message}", :internal_server_error)
end

private

def track_npc_encounters(room_id, room_data)
  return unless room_data['npcs'].present?
  
  npc_ids = room_data['npcs'].map { |npc| npc['id'] }
  @game.player_state['encounteredNPCs'] ||= []
  
  new_npcs = npc_ids - @game.player_state['encounteredNPCs']
  return if new_npcs.empty?
  
  @game.player_state['encounteredNPCs'].concat(new_npcs)
  @game.save!
  
  Rails.logger.debug "[BreakEscape] Tracked NPC encounters: #{new_npcs.join(', ')}"
end
```

---

### ⚠️ WARNING #9: Inventory Validation Performance Issue

**Problem:**  
The `validate_item_collectible` method searches **every room, every object, every NPC** on every inventory add:

```ruby
def find_item_in_scenario(item_type, item_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    room_data['objects']&.each do |obj|
      return obj if obj['type'] == item_type && ...
      obj['contents']&.each do |content|
        return content if content['type'] == item_type && ...
      end
    end
  end
  nil
end
```

For a scenario with 20 rooms × 10 objects × 5 contents = **1000 iterations per inventory add**.

**Solution:**

Cache scenario item locations in memory:

```ruby
# app/models/break_escape/game.rb

def item_index
  @item_index ||= build_item_index
end

private

def build_item_index
  index = {}
  
  scenario_data['rooms'].each do |room_id, room_data|
    room_data['objects']&.each_with_index do |obj, obj_idx|
      key = item_key(obj)
      index[key] = {
        room_id: room_id,
        object_path: ['objects', obj_idx],
        object: obj,
        container_id: nil,
        npc_id: nil
      }
      
      # Index nested contents
      obj['contents']&.each_with_index do |content, content_idx|
        content_key = item_key(content)
        index[content_key] = {
          room_id: room_id,
          object_path: ['objects', obj_idx, 'contents', content_idx],
          object: content,
          container_id: obj['id'] || obj['name'],
          npc_id: nil
        }
      end
    end
    
    # Index NPC items
    room_data['npcs']&.each do |npc|
      npc['itemsHeld']&.each do |item|
        item_key_str = item_key(item)
        index[item_key_str] = {
          room_id: room_id,
          object: item,
          npc_id: npc['id'],
          container_id: nil
        }
      end
    end
  end
  
  index
end

def item_key(item)
  "#{item['type']}:#{item['id'] || item['name'] || 'unnamed'}"
end

# Then use it:
def validate_item_collectible(item)
  key = item_key(item.to_h)
  location = item_index[key]
  
  return "Item not found in scenario" unless location
  return "Item is not takeable" unless location[:object]['takeable']
  
  # Check container unlock
  if location[:container_id].present?
    unless @game.player_state['unlockedObjects'].include?(location[:container_id])
      return "Container not unlocked: #{location[:container_id]}"
    end
  end
  
  # ... rest of validation ...
end
```

---

### ⚠️ WARNING #10: Missing Route for Container Endpoint

**Problem:**  
The routes file has:

```ruby
get 'room/:room_id', to: 'games#room'
```

But the plan adds:

```ruby
get 'container/:container_id'  # Missing 'to:' parameter!
```

**Solution:**

Add proper route:

```ruby
# config/routes.rb
resources :games, only: [:show, :create] do
  member do
    get 'scenario'
    get 'ink'
    get 'room/:room_id', to: 'games#room'
    get 'container/:container_id', to: 'games#container'  # ✅ Fixed
    
    put 'sync_state'
    post 'unlock'
    post 'inventory'
  end
end
```

---

## Architecture Improvements

### Improvement #1: Add Scenario Map Endpoint for Client Navigation

**Current Gap:**  
Client has no way to get room connectivity without loading full room data.

**Solution:**

```ruby
def scenario_map
  authorize @game if defined?(Pundit)
  
  layout = {}
  @game.scenario_data['rooms'].each do |room_id, room_data|
    layout[room_id] = {
      type: room_data['type'],
      connections: room_data['connections'] || {},
      locked: room_data['locked'] || false,
      lockType: room_data['lockType'],
      hasNPCs: (room_data['npcs']&.length || 0) > 0,
      accessible: @game.room_unlocked?(room_id)
    }
  end
  
  render json: {
    startRoom: @game.scenario_data['startRoom'],
    currentRoom: @game.player_state['currentRoom'],
    rooms: layout
  }
end
```

Add route:
```ruby
get 'scenario_map', to: 'games#scenario_map'
```

---

### Improvement #2: Add Bulk Inventory Sync Endpoint

**Problem:**  
Client might get out of sync with server (page refresh, network error, etc.).

**Solution:**

```ruby
# GET /games/:id/inventory
def get_inventory
  authorize @game if defined?(Pundit)
  
  render json: {
    inventory: @game.player_state['inventory'] || []
  }
end
```

---

### Improvement #3: Add Health Check Endpoint

**Problem:**  
No way to verify game state is valid or recover from corruption.

**Solution:**

```ruby
def validate_state
  authorize @game if defined?(Pundit)
  
  issues = []
  
  # Check if current room is unlocked
  current_room = @game.player_state['currentRoom']
  if current_room && !@game.room_unlocked?(current_room)
    issues << "Current room #{current_room} is not unlocked"
  end
  
  # Check if inventory items exist in scenario
  @game.player_state['inventory']&.each do |item|
    key = item_key(item)
    unless @game.item_index[key]
      issues << "Inventory item #{key} not found in scenario"
    end
  end
  
  render json: {
    valid: issues.empty?,
    issues: issues,
    player_state: @game.player_state
  }
end
```

---

## Testing Gaps

### Gap #1: No Integration Tests for NPC Item Validation

**Missing Test:**
```ruby
# test/integration/npc_item_validation_test.rb
test "cannot collect item from unencountered NPC" do
  # Setup: NPC in room_b holds key_1
  # Player in room_a tries to add key_1 to inventory
  # Expected: 403 Forbidden with "NPC not encountered"
end

test "can collect item after entering NPC room" do
  # Player enters room_b (encounters NPC automatically)
  # Player collects key_1
  # Expected: 200 OK, item in inventory
end
```

---

### Gap #2: No Test for Container Unlock Race Condition

**Missing Test:**
```ruby
test "cannot access container contents before unlock completes" do
  # Client unlocks safe_1 (async)
  # Client immediately requests /container/safe_1 (before save completes)
  # Expected: 403 Forbidden (not in unlockedObjects yet)
end
```

---

### Gap #3: No Test for Nested Container Contents

**Missing Test:**
```ruby
test "cannot collect item from nested locked container" do
  # safe_1 contains briefcase_1 (locked)
  # briefcase_1 contains key_2
  # Player unlocks safe_1, tries to collect key_2
  # Expected: Forbidden (briefcase_1 not unlocked)
end
```

---

## Data Consistency Concerns

### Concern #1: Starting Inventory Duplication

**Problem:**  
If `startItemsInInventory` contains item references that also exist in rooms, the item might be duplicated.

**Example:**
```json
{
  "startItemsInInventory": [
    { "type": "phone", "name": "Your Phone" }
  ],
  "rooms": {
    "reception": {
      "objects": [
        { "type": "phone", "name": "Your Phone", "takeable": true }
      ]
    }
  }
}
```

Player starts with phone AND can collect phone from room → 2 phones.

**Solution:**

Document in scenario design guide:
> **IMPORTANT:** Items in `startItemsInInventory` should NOT also appear as takeable objects in rooms. Use `takeable: false` if you need a visual placeholder.

---

### Concern #2: Container Unlock Doesn't Cascade

**Problem:**  
If `safe_1` contains `briefcase_1` (locked), unlocking `safe_1` doesn't auto-unlock `briefcase_1`. But client might expect access to all contents.

**Current Behavior:** Correct - nested containers require separate unlock.

**Documentation Needed:**  
Add to scenario design docs: "Locked containers within containers require separate unlock actions."

---

## Error Handling Improvements

### Missing: Rate Limiting

**Problem:**  
Client can spam unlock attempts to brute-force passwords.

**Solution (Phase 2):**

```ruby
# app/models/break_escape/game.rb
def record_unlock_attempt(target_id)
  @game.player_state['unlockAttempts'] ||= {}
  @game.player_state['unlockAttempts'][target_id] ||= []
  @game.player_state['unlockAttempts'][target_id] << Time.current.to_i
  
  # Keep only last 10 minutes of attempts
  cutoff = 10.minutes.ago.to_i
  @game.player_state['unlockAttempts'][target_id].reject! { |t| t < cutoff }
  
  @game.save!
end

def too_many_unlock_attempts?(target_id)
  attempts = @game.player_state.dig('unlockAttempts', target_id) || []
  attempts.length > 10 # Max 10 attempts per 10 minutes
end
```

Use in unlock endpoint:
```ruby
if too_many_unlock_attempts?(target_id)
  return render json: {
    success: false,
    message: 'Too many attempts. Please wait.'
  }, status: :too_many_requests
end
```

---

### Missing: Graceful Degradation for Network Errors

**Problem:**  
If server is down, client has no fallback behavior.

**Solution (Client-Side):**

```javascript
// public/break_escape/js/systems/inventory.js

const MAX_RETRIES = 3;
const RETRY_DELAY = 1000;

async function addToInventoryWithRetry(sprite, retries = 0) {
    try {
        return await addToInventory(sprite);
    } catch (error) {
        if (retries < MAX_RETRIES) {
            console.log(`Retry ${retries + 1}/${MAX_RETRIES} after ${RETRY_DELAY}ms`);
            await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
            return addToInventoryWithRetry(sprite, retries + 1);
        }
        
        // All retries failed - show persistent error
        window.gameAlert(
            'Network error - your progress may not be saved. Please refresh the page.',
            'error',
            'Connection Lost',
            10000
        );
        return false;
    }
}
```

---

## Performance Optimizations

### Optimization #1: Cache Filtered Room Data

**Problem:**  
Every room request re-filters the entire room data structure.

**Solution:**

```ruby
# app/models/break_escape/game.rb

def filtered_room_data(room_id)
  cache_key = "filtered_room_#{room_id}_#{updated_at.to_i}"
  
  Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
    room = room_data(room_id)&.deep_dup
    return nil unless room
    
    filter_requires_and_contents_recursive(room)
    room
  end
end
```

---

### Optimization #2: Use JSON Schema Validation

**Problem:**  
Manual validation of item structure is brittle.

**Solution:**

```ruby
# Gemfile
gem 'json-schema'

# app/models/break_escape/game.rb
ITEM_SCHEMA = {
  "type" => "object",
  "required" => ["type", "name"],
  "properties" => {
    "type" => { "type" => "string" },
    "name" => { "type" => "string" },
    "takeable" => { "type" => "boolean" }
  }
}.freeze

def validate_item_structure(item)
  JSON::Validator.validate!(ITEM_SCHEMA, item)
rescue JSON::Schema::ValidationError => e
  Rails.logger.error "Invalid item structure: #{e.message}"
  false
end
```

---

## Implementation Priority

### Phase 1: Core Validation (Week 1)
- ✅ Model: `filter_requires_and_contents_recursive`
- ✅ Model: `initialize_player_state` (verify starting items)
- ✅ Controller: Update `room` endpoint filtering
- ✅ Controller: Update `unlock` endpoint tracking
- ⚠️ **ADD:** Controller: Transaction safety for unlock
- ⚠️ **ADD:** Controller: Defensive start room check

### Phase 2: Inventory Validation (Week 1-2)
- ✅ Controller: `validate_item_collectible`
- ✅ Controller: NPC encounter tracking in room endpoint
- ⚠️ **ADD:** Model: Item index caching
- ⚠️ **ADD:** Controller: NPC itemsHeld structure fix
- ⚠️ **ADD:** Tests: NPC item validation

### Phase 3: Container Lazy-Loading (Week 2)
- ✅ Controller: `container` endpoint
- ✅ Routes: Add container route
- ⚠️ **ADD:** Controller: Container ID resolution logic
- ⚠️ **ADD:** Client: `loadContainerContents()` method
- ⚠️ **ADD:** Tests: Container access control

### Phase 4: Client Integration (Week 2-3) **← CRITICAL, CURRENTLY MISSING**
- ⚠️ **ADD:** Client: Update `addToInventory()` to validate with server
- ⚠️ **ADD:** Client: Update container minigame to lazy-load contents
- ⚠️ **ADD:** Client: Handle 403 Forbidden responses
- ⚠️ **ADD:** Client: Retry logic for network errors
- ⚠️ **ADD:** Tests: End-to-end validation flow

### Phase 5: Error Handling & Recovery (Week 3)
- ⚠️ **ADD:** Controller: Rate limiting for unlock attempts
- ⚠️ **ADD:** Controller: State validation endpoint
- ⚠️ **ADD:** Client: Graceful degradation
- ⚠️ **ADD:** Tests: Error scenarios

---

## Revised TODO Checklist

### ✅ PHASE 1: Data Model (ALREADY COMPLETE)
- [x] 1.1 Verify player_state default structure ✅ Done (db/migrate)
- [x] 1.2 `initialize_player_state!` method ✅ Done (model callback)
- [x] ~~1.3 Call in controller~~ (Not needed - callback handles it)
- [ ] 1.4 **ADD:** Verify starting items added correctly

### ✅ PHASE 2: Data Filtering
- [ ] 2.1 Create `filter_requires_and_contents_recursive` ⚠️ Fix to keep lockType
- [ ] 2.2 Update `filtered_room_data` ⚠️ Fix to use new filter method
- [ ] 2.3 **REMOVE:** `filter_contents_field` is replaced by recursive filter
- [ ] 2.4 Update room endpoint ⚠️ Add defensive start room check
- [ ] 2.5 Create `scenario_map` endpoint
- [ ] 2.6 Add `scenario_map` route
- [ ] 2.7 Test: Room endpoint filtering

### ✅ PHASE 3: Container Lazy-Loading
- [ ] 3.1-3.3 Container search methods ⚠️ Fix ID resolution
- [ ] 3.4 Implement `container` endpoint ⚠️ Add unlocked check logic
- [ ] 3.5 Add route ⚠️ Add `to: 'games#container'`
- [ ] 3.6 Test: Container access control

### ✅ PHASE 4: Inventory Validation
- [ ] 4.1 Create `validate_item_collectible`
- [ ] 4.2 Create `find_item_in_scenario` ⚠️ Add caching via item_index
- [ ] 4.3-4.5 Item search helpers ⚠️ Fix NPC itemsHeld structure
- [ ] 4.6 Update `inventory` endpoint with validation
- [ ] 4.7 **ADD:** Transaction safety for inventory add
- [ ] 4.8 Test: Item validation scenarios

### ✅ PHASE 5: NPC Tracking
- [ ] 5.1 Update `room` endpoint NPC tracking ⚠️ Add transaction
- [ ] 5.2 Test: NPC encounter tracking

### ✅ PHASE 6: Unlock Tracking
- [ ] 6.1 Update `unlock` endpoint ⚠️ Add transaction
- [ ] 6.2 Test: Unlock persistence
- [ ] 6.3 Test: Container unlock integration

### ✅ PHASE 7: Sync State
- [ ] 7.1 Update `sync_state` ⚠️ Add room access check
- [ ] 7.2 Test: Sync validation

### ✅ PHASE 8: Routes
- [ ] 8.1 Add new routes
- [ ] 8.2 Verify routes work

### ⚠️ **PHASE 9: CLIENT INTEGRATION (MISSING FROM PLAN)**
- [ ] 9.1 Update `addToInventory()` to call server
- [ ] 9.2 Update container minigame to call `/container/:id`
- [ ] 9.3 Add error handling for 403 responses
- [ ] 9.4 Add retry logic for network errors
- [ ] 9.5 Test: Client-server validation flow
- [ ] 9.6 Test: Network error scenarios

### ✅ PHASE 10: Testing
- [ ] 10.1 Integration tests for filtering
- [ ] 10.2 Integration tests for container endpoint
- [ ] 10.3 Integration tests for inventory validation
- [ ] 10.4 Integration tests for NPC tracking
- [ ] 10.5 Integration tests for unlock tracking
- [ ] 10.6 **ADD:** Tests for NPC itemsHeld validation
- [ ] 10.7 **ADD:** Tests for nested container validation
- [ ] 10.8 End-to-end: Complete puzzle flow

---

## Risk Assessment

### High Risk ⚠️
1. **Client integration missing** - Plan doesn't update client code (CRITICAL)
2. **NPC itemsHeld structure unclear** - Might break item collection (HIGH)
3. **No transaction safety** - State corruption risk (HIGH)
4. **Container ID resolution ambiguous** - Wrong items might unlock (MEDIUM-HIGH)

### Medium Risk ⚠️
5. **Performance not addressed** - Linear search per validation (MEDIUM)
6. **No error recovery** - Network issues will break game (MEDIUM)
7. **Race conditions** - Start room access might fail (MEDIUM)

### Low Risk ℹ️
8. **Rate limiting missing** - Brute force possible but unlikely (LOW)
9. **No state validation endpoint** - Debugging harder (LOW)

---

## Recommendations

### Immediate Actions (Before Implementation)
1. ✅ Add Phase 9 (Client Integration) to implementation plan with detailed code changes
2. ✅ Clarify NPC `itemsHeld` structure with examples from actual scenarios
3. ✅ Add transaction wrappers to all state-mutating endpoints
4. ✅ Fix `filtered_room_data` to keep `lockType` visible
5. ✅ Add defensive start room check to room endpoint

### Nice to Have (Phase 2)
6. Add item index caching for performance
7. Add rate limiting for unlock attempts
8. Add state validation endpoint
9. Add graceful degradation for network errors
10. Add comprehensive integration tests for all validation paths

---

## Conclusion

The implementation plan is **architecturally sound** but has **significant gaps** in:
1. **Client-side integration** (missing entirely)
2. **Transaction safety** (state corruption risk)
3. **Error handling** (no recovery strategies)
4. **NPC itemsHeld structure** (unclear spec)

**Recommendation:** ⚠️ **Do NOT start implementation** until Phase 9 (Client Integration) is added to the plan with specific file changes and code examples.

**Estimated Additional Work:**
- Phase 9: 2-3 days (client updates + integration testing)
- Transaction safety: 1 day (add to existing endpoints)
- NPC structure fixes: 1 day (clarify + update validation)

**Total:** ~4-5 additional days of work beyond the original plan.
