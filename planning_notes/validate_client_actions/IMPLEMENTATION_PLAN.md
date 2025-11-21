# Client Action Validation & Data Filtering Implementation Plan

**Date:** November 21, 2025  
**Status:** Planning  
**Priority:** High - Security & Data Integrity

---

## Overview

This plan implements server-side validation and filtering to prevent client-side cheating while maintaining clean data separation. Key principles:

1. **Filter at controller level** - Keep scenario_data raw in model, filter in responses
2. **Hide `requires` field** - Server validates, client doesn't see answers
3. **Hide `contents`** - Locked container contents loaded via separate endpoint
4. **Validate all inventory operations** - Check items exist and are collectible
5. **Track player state** - Unlock history and NPC encounters drive permissions
6. **Lazy-load containers** - `/games/:id/container/:container_id` endpoint

---

## Phase 1: Data Model & Initialization

### 1.1 Update Game Model Default player_state
**File:** `app/models/break_escape/game.rb`

**Current:**
```ruby
t.jsonb :player_state, null: false, default: {
  currentRoom: nil,
  unlockedRooms: [],
  unlockedObjects: [],
  inventory: [],
  encounteredNPCs: [],
  globalVariables: {},
  biometricSamples: [],
  biometricUnlocks: [],
  bluetoothDevices: [],
  notes: [],
  health: 100
}
```

**Changes needed:**
- Verify default structure exists
- Add initialization method to populate `unlockedRooms` and `inventory` on game creation

### 1.2 Verify Initialization Method
**File:** `app/models/break_escape/game.rb`

**Current implementation (lines 189-203):** ✅ Already exists via `before_create :initialize_player_state`

**REQUIRED UPDATE:** Add starting items initialization:

```ruby
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

## Phase 2: Data Filtering at Controller Level

### 2.1 Fix `filtered_room_data` Method
**File:** `app/models/break_escape/game.rb`

**Current implementation (lines 134-147) removes lockType incorrectly. Replace with:**

```ruby
def filtered_room_data(room_id)
  room = room_data(room_id)&.deep_dup
  return nil unless room

  # Remove ONLY the 'requires' field (the solution)
  # Keep lockType, locked, observations visible to client
  filter_requires_and_contents_recursive(room)
  
  room
end

private

def filter_requires_and_contents_recursive(obj)
  case obj
  when Hash
    # Remove 'requires' (the answer/solution)
    obj.delete('requires')
    
    # Remove 'contents' if locked (lazy-loaded via separate endpoint)
    obj.delete('contents') if obj['locked']
    
    # Keep lockType - client needs it to show correct UI
    # Keep locked - client needs it to show lock status
    
    # Recursively filter nested objects and NPCs
    obj['objects']&.each { |o| filter_requires_and_contents_recursive(o) }
    obj['npcs']&.each { |n| filter_requires_and_contents_recursive(n) }
    
  when Array
    obj.each { |item| filter_requires_and_contents_recursive(item) }
  end
end
```

### 2.2 Update Room Endpoint with Access Control
**File:** `app/controllers/break_escape/games_controller.rb`

**Replace current room method (lines 20-34) with:**

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

  # Track NPC encounters BEFORE sending response
  track_npc_encounters(room_id, room_data)

  Rails.logger.debug "[BreakEscape] Serving room data for: #{room_id}"

  render json: { room_id: room_id, room: room_data }
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

**Note:** The `filter_requires_and_contents_recursive` method already handles removing locked contents, so no separate `filter_contents_field` helper is needed.

### 2.3 Rename Existing Scenario Endpoint to scenario_map
**File:** `app/controllers/break_escape/games_controller.rb`

**Current scenario method (lines 13-17) serves full unfiltered data. This should be renamed and filtered.**

**Replace with:**
```ruby
# GET /games/:id/scenario_map
# Returns minimal scenario metadata for navigation (no room contents)
def scenario_map
  authorize @game if defined?(Pundit)
  
  # Return minimal room/connection metadata without contents
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

**Update routes (config/routes.rb):**
```ruby
# Change 'scenario' to 'scenario_map'
get 'scenario_map'  # Minimal layout metadata for navigation
```

**BREAKING CHANGE:** This renames the endpoint. Client code calling `/games/:id/scenario` will need to be updated to call `/games/:id/scenario_map` instead.

---

## Phase 3: Locked Container Lazy-Loading

### 3.1 Create Container Endpoint
**File:** `app/controllers/break_escape/games_controller.rb`

**New method (add after room endpoint):**
```ruby
# GET /games/:id/container/:container_id
# Returns container contents after unlock (lazy-loaded)
def container
  authorize @game if defined?(Pundit)

  container_id = params[:container_id]
  return render_error('Missing container_id parameter', :bad_request) unless container_id.present?

  # Find container in scenario data
  container_data = find_container_in_scenario(container_id)
  return render_error("Container not found: #{container_id}", :not_found) unless container_data

  # Check if container is unlocked (check multiple possible identifiers)
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

private

def find_container_in_scenario(container_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    # Search objects for container
    container = find_container_recursive(room_data['objects'], container_id)
    return container if container
    
    # Search nested contents
    room_data['objects']&.each do |obj|
      container = search_nested_contents(obj['contents'], container_id)
      return container if container
    end
  end
  nil
end

def find_container_recursive(objects, container_id)
  return nil unless objects
  
  objects.each do |obj|
    # Check if this object matches
    if obj['id'] == container_id || (obj['name'] && obj['name'] == container_id)
      return obj if obj['contents'].present?
    end
    
    # Recursively search nested contents
    nested = find_container_recursive(obj['contents'], container_id)
    return nested if nested
  end
  nil
end

def search_nested_contents(contents, container_id)
  return nil unless contents
  
  contents.each do |item|
    return item if (item['id'] == container_id || item['name'] == container_id) && item['contents'].present?
    nested = search_nested_contents(item['contents'], container_id)
    return nested if nested
  end
  nil
end
```

**Add to routes:**
```ruby
get 'container/:container_id', to: 'games#container'  # Load locked container contents
```

---

## Phase 4: Inventory Validation

### 4.1 Update Inventory Endpoint
**File:** `app/controllers/break_escape/games_controller.rb`

**Update inventory method:**
```ruby
def inventory
  authorize @game if defined?(Pundit)

  action_type = params[:action_type] || params[:actionType]
  item = params[:item]

  case action_type
  when 'add'
    # Validate item exists and is collectible
    validation_error = validate_item_collectible(item)
    if validation_error
      return render json: { success: false, message: validation_error }, 
                     status: :unprocessable_entity
    end
    
    @game.add_inventory_item!(item.to_unsafe_h)
    render json: { success: true, inventory: @game.player_state['inventory'] }
    
  when 'remove'
    @game.remove_inventory_item!(item['id'])
    render json: { success: true, inventory: @game.player_state['inventory'] }
    
  else
    render json: { success: false, message: 'Invalid action' }, status: :bad_request
  end
end

private

def validate_item_collectible(item)
  item_type = item['type']
  item_id = item['id']
  
  # Search scenario for this item
  found_item = find_item_in_scenario(item_type, item_id)
  return "Item not found in scenario: #{item_type}" unless found_item
  
  # Check if item is takeable
  unless found_item['takeable']
    return "Item is not takeable: #{found_item['name']}"
  end
  
  # If item is in locked container, check if container is unlocked
  container_info = find_item_container(item_type, item_id)
  if container_info.present?
    container_id = container_info[:id]
    unless @game.player_state['unlockedObjects'].include?(container_id)
      return "Container not unlocked: #{container_id}"
    end
  end
  
  # If item is in locked room, check if room is unlocked
  room_info = find_item_room(item_type, item_id)
  if room_info.present?
    room_id = room_info[:id]
    if room_info[:locked] && !@game.player_state['unlockedRooms'].include?(room_id)
      return "Room not unlocked: #{room_id}"
    end
  end
  
  # Check if NPC holds this item and if NPC encountered
  npc_info = find_npc_holding_item(item_type, item_id)
  if npc_info.present?
    npc_id = npc_info[:id]
    unless @game.player_state['encounteredNPCs'].include?(npc_id)
      return "NPC not encountered: #{npc_id}"
    end
  end
  
  nil # No error
end

def find_item_in_scenario(item_type, item_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    # Search room objects
    room_data['objects']&.each do |obj|
      return obj if obj['type'] == item_type && (obj['id'] == item_id || obj['name'] == item_id)
      
      # Search nested contents
      obj['contents']&.each do |content|
        return content if content['type'] == item_type && (content['id'] == item_id || content['name'] == item_id)
      end
    end
  end
  nil
end

def find_item_container(item_type, item_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    room_data['objects']&.each do |obj|
      obj['contents']&.each do |content|
        if content['type'] == item_type && (content['id'] == item_id || content['name'] == item_id)
          return { id: obj['id'] || obj['name'], locked: obj['locked'] }
        end
      end
    end
  end
  nil
end

def find_item_room(item_type, item_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    room_data['objects']&.each do |obj|
      if obj['type'] == item_type && (obj['id'] == item_id || obj['name'] == item_id)
        return { id: room_id, locked: room_data['locked'] }
      end
    end
  end
  nil
end

def find_npc_holding_item(item_type, item_id)
  @game.scenario_data['rooms'].each do |room_id, room_data|
    room_data['npcs']&.each do |npc|
      next unless npc['itemsHeld'].present?
      
      # itemsHeld is array of full item objects (same structure as room objects)
      npc['itemsHeld'].each do |held_item|
        # Match by type (required) and optionally by id/name
        if held_item['type'] == item_type
          # If item_id provided, verify it matches
          if item_id.present?
            item_matches = (held_item['id'] == item_id) || 
                          (held_item['name'] == item_id) ||
                          (item_id == item_type) # Fallback if no id field
            next unless item_matches
          end
          
          return { 
            id: npc['id'],
            npc: npc,
            item: held_item,
            type: 'npc'
          }
        end
      end
    end
  end
  nil
end
```

---

## Phase 5: Track NPC Encounters

### 5.1 Update Room Endpoint to Track NPCs
**File:** `app/controllers/break_escape/games_controller.rb`

**Modify room method (after room_data returned):**
```ruby
def room
  # ... existing code ...
  
  # Track NPC encounters
  if room_data['npcs'].present?
    npc_ids = room_data['npcs'].map { |npc| npc['id'] }
    @game.player_state['encounteredNPCs'] ||= []
    @game.player_state['encounteredNPCs'].concat(npc_ids)
    @game.player_state['encounteredNPCs'].uniq!
    @game.save!
  end
  
  # Filter out 'contents' field - lazy-loaded via separate endpoint
  filter_contents_field(room_data)

  Rails.logger.debug "[BreakEscape] Serving room data for: #{room_id}"

  render json: { room_id: room_id, room: room_data }
end
```

---

## Phase 6: Unlock Validation & Tracking

### 6.1 Update Unlock Endpoint with Transaction Safety
**File:** `app/controllers/break_escape/games_controller.rb`

**Replace unlock method (lines 95-130) with:**
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

      render json: {
        success: true,
        type: 'door',
        roomData: room_data
      }
    else
      # Object/container unlock
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

**Note:** The `unlock_room!` and `unlock_object!` methods in the Game model already handle adding to `unlockedRooms`/`unlockedObjects` and saving, so we don't need to duplicate that logic here.

---

## Phase 7: Sync State with Room Tracking

### 7.1 Update Sync State Endpoint
**File:** `app/controllers/break_escape/games_controller.rb`

**Modify sync_state method:**
```ruby
def sync_state
  authorize @game if defined?(Pundit)

  # Update allowed fields
  if params[:currentRoom]
    # Verify room is accessible
    if @game.player_state['unlockedRooms'].include?(params[:currentRoom])
      @game.player_state['currentRoom'] = params[:currentRoom]
    else
      return render json: { 
        success: false, 
        message: "Cannot enter locked room: #{params[:currentRoom]}" 
      }, status: :forbidden
    end
  end

  if params[:globalVariables]
    @game.update_global_variables!(params[:globalVariables].to_unsafe_h)
  end

  @game.save!

  render json: { success: true }
end
```

---

## Phase 8: Update Routes

### 8.1 Add New Routes
**File:** `config/routes.rb`

```ruby
resources :games, only: [:show, :create] do
  member do
    # Scenario and NPC data
    get 'scenario'           # Full scenario (kept for compatibility)
    get 'scenario_map'       # Minimal layout metadata
    get 'ink'                # Returns NPC script (JIT compiled)
    get 'room/:room_id', to: 'games#room'  # Returns room data for lazy-loading
    get 'container/:container_id', to: 'games#container'  # Returns locked container contents

    # Game state and actions
    put 'sync_state'         # Periodic state sync
    post 'unlock'            # Validate unlock attempt
    post 'inventory'         # Update inventory
  end
end
```

---

## Implementation TODO List

### ✅ PHASE 1: Data Model & Initialization
- [x] 1.1 Verify Game model has correct player_state default structure ✅ Done (db/migrate)
- [x] 1.2 `initialize_player_state` method ✅ Exists (model callback)
- [ ] 1.3 **UPDATE** `initialize_player_state` to add starting items to inventory
- [ ] 1.4 Test: Create game and verify player_state populated correctly with starting items

### ✅ PHASE 2: Data Filtering
- [ ] 2.1 Create `filter_requires_and_contents_recursive` method (replaces current filter logic)
- [ ] 2.2 Update `filtered_room_data` to use new recursive filter (keep lockType visible)
- [ ] 2.3 Rename `scenario` endpoint to `scenario_map` and filter response
- [ ] 2.4 Update room endpoint with access control and NPC tracking
- [ ] 2.5 Update routes: rename `scenario` to `scenario_map`
- [ ] 2.6 Test: Room endpoint preserves `lockType`, removes `requires` and locked `contents`

### ✅ PHASE 3: Container Lazy-Loading
- [ ] 3.1 Create `find_container_in_scenario` method
- [ ] 3.2 Create `find_container_recursive` method  
- [ ] 3.3 Create `search_nested_contents` helper
- [ ] 3.4 Create `check_container_unlocked` helper (checks multiple ID types)
- [ ] 3.5 Create `filter_container_contents` helper
- [ ] 3.6 Implement `container` endpoint with proper ID resolution
- [ ] 3.7 Add `container/:container_id` route with `to:` parameter
- [ ] 3.8 Test: Container endpoint returns filtered contents only if unlocked

### ✅ PHASE 4: Inventory Validation
- [ ] 4.1 Create `validate_item_collectible` method
- [ ] 4.2 Create `find_item_in_scenario` helper
- [ ] 4.3 Create `find_item_container` helper
- [ ] 4.4 Create `find_item_room` helper
- [ ] 4.5 **UPDATE** `find_npc_holding_item` helper (fix itemsHeld structure handling)
- [ ] 4.6 Update `inventory` endpoint with validation
- [ ] 4.7 Test: Items can't be collected from locked rooms/containers
- [ ] 4.8 Test: Items from NPCs can't be collected before encounter
- [ ] 4.9 Test: NPC itemsHeld validation works correctly

### ✅ PHASE 5: NPC Encounter Tracking
- [x] 5.1 NPC encounter tracking added to room endpoint (Phase 2.4) ✅ Done
- [ ] 5.2 Test: encounteredNPCs populated when room loaded

### ✅ PHASE 6: Unlock Tracking
- [ ] 6.1 **UPDATE** `unlock` endpoint with transaction safety
- [ ] 6.2 Test: Unlock operations are atomic
- [ ] 6.3 Test: Unlocked rooms accessible, locked rooms forbidden
- [ ] 6.4 Test: Unlocked containers' contents available via container endpoint

### ✅ PHASE 7: Sync State Validation
- [ ] 7.1 Update `sync_state` to verify room accessibility
- [ ] 7.2 Test: Client can't sync to locked rooms

### ✅ PHASE 8: Routing
- [ ] 8.1 Update routes in config/routes.rb
  - Rename `get 'scenario'` to `get 'scenario_map'`
  - Add `get 'container/:container_id', to: 'games#container'`
- [ ] 8.2 Verify all routes work: `rails routes | grep games#`

### ✅ PHASE 9: Client Integration (CRITICAL)
- [ ] 9.1 Update `addToInventory()` to validate with server
  - **File:** `public/break_escape/js/systems/inventory.js`
  - Make async, add server validation before local inventory update
  - Handle 403/422 responses with user-friendly error messages
  - Add retry logic for network errors (3 retries with exponential backoff)
- [ ] 9.2 Update container minigame to lazy-load contents
  - **File:** `public/break_escape/js/minigames/container/container-minigame.js`
  - Add `loadContainerContents()` method to fetch from `/games/:id/container/:container_id`
  - Handle 403 Forbidden for locked containers
  - Show loading state while fetching
- [ ] 9.3 Update scenario loading to use `scenario_map`
  - **File:** `public/break_escape/js/core/game.js`
  - Change fetch URL from `/games/:id/scenario` to `/games/:id/scenario_map`
  - Update expected response structure
- [ ] 9.4 Add error handling for room access
  - Handle 403 Forbidden responses when trying to access locked rooms
  - Show appropriate UI feedback
- [ ] 9.5 Test: Client-server validation flow
  - Verify inventory adds are validated
  - Verify containers load contents on-demand
  - Verify locked rooms return 403

### ✅ PHASE 10: Testing & Validation
- [ ] 10.1 Create integration tests for filtering
- [ ] 10.2 Create integration tests for container endpoint
- [ ] 10.3 Create integration tests for inventory validation
- [ ] 10.4 Create integration tests for NPC encounter tracking
- [ ] 10.5 Create integration tests for unlock tracking
- [ ] 10.6 Create integration tests for NPC itemsHeld validation
- [ ] 10.7 Create integration tests for nested container validation
- [ ] 10.8 Create integration tests for sync_state validation
- [ ] 10.9 Test end-to-end: Complete puzzle with validation

---

## Data Structures Reference

### Player State After Initialization
```json
{
  "currentRoom": "reception",
  "unlockedRooms": ["reception"],
  "unlockedObjects": [],
  "inventory": [
    { "type": "phone", "name": "Your Phone", "takeable": true },
    { "type": "workstation", "name": "Crypto Analysis Station", "takeable": true },
    { "type": "lockpick", "name": "Lock Pick Kit", "takeable": true }
  ],
  "encounteredNPCs": [],
  "globalVariables": {},
  "biometricSamples": [],
  "biometricUnlocks": [],
  "bluetoothDevices": [],
  "health": 100,
  "initializedAt": "2025-11-21T12:00:00Z"
}
```

### Room Response (After Filtering)
```json
{
  "room_id": "reception",
  "room": {
    "type": "room_reception",
    "connections": { "north": "office1" },
    "npcs": [
      {
        "id": "neye_eve",
        "displayName": "Neye Eve",
        "storyPath": "scenarios/ink/neye-eve.json",
        "npcType": "phone"
      }
    ],
    "objects": [
      {
        "type": "phone",
        "name": "Reception Phone",
        "takeable": false,
        "readable": true,
        "lockType": "password",
        "locked": true,
        "observations": "...",
        "postitNote": "Password: secret123",
        "showPostit": true
        // NOTE: 'requires' field REMOVED
        // NOTE: 'contents' field REMOVED
      }
    ]
  }
}
```

### Container Response (After Unlock)
```json
{
  "container_id": "reception_safe",
  "contents": [
    {
      "type": "notes",
      "name": "IT Access Credentials",
      "takeable": true,
      "readable": true,
      "text": "Emergency IT Admin Credentials...",
      "observations": "Sensitive IT credentials..."
      // NOTE: 'requires' field REMOVED
    }
  ]
}
```

### Scenario Map Response
```json
{
  "startRoom": "reception",
  "rooms": {
    "reception": {
      "type": "room_reception",
      "connections": { "north": "office1" },
      "locked": false,
      "lockType": null,
      "hasNPCs": 3,
      "accessible": true
    },
    "office1": {
      "type": "room_office",
      "connections": { "north": ["office2", "office3"], "south": "reception" },
      "locked": true,
      "lockType": "key",
      "hasNPCs": 0,
      "accessible": false
    }
  }
}
```

---

## Error Handling

### Common Validation Errors

**Container Not Unlocked:**
```json
{
  "success": false,
  "message": "Container not unlocked: reception_safe"
}
```

**Item Not Collectible:**
```json
{
  "success": false,
  "message": "Room not unlocked: ceo_office"
}
```

**Room Access Denied:**
```json
{
  "success": false,
  "message": "Room not accessible: ceo_office"
}
```

**NPC Not Encountered:**
```json
{
  "success": false,
  "message": "NPC not encountered: helper_npc"
}
```

---

## Client Integration Details (Phase 9)

### 9.1 Update Inventory System to Validate with Server

**File:** `public/break_escape/js/systems/inventory.js`

**Find the `addToInventory` function (around line 183) and update:**

```javascript
export async function addToInventory(sprite) {
    if (!sprite || !sprite.scenarioData) {
        console.warn('Invalid sprite for inventory');
        return false;
    }
    
    try {
        console.log("Adding to inventory:", {
            objectId: sprite.objectId,
            name: sprite.name,
            type: sprite.scenarioData?.type,
            currentRoom: window.currentPlayerRoom
        });
        
        // Check if the item is already in the inventory (local check first)
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
                    headers: { 
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        action_type: 'add',
                        item: sprite.scenarioData
                    })
                });
                
                const result = await response.json();
                
                if (!result.success) {
                    // Server rejected - show error to player
                    console.warn('Server rejected inventory add:', result.message);
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
        
        // ... rest of existing addToInventory logic continues unchanged ...
        
        // Remove from room if it exists
        if (window.currentPlayerRoom && rooms[window.currentPlayerRoom] && rooms[window.currentPlayerRoom].objects) {
            if (rooms[window.currentPlayerRoom].objects[sprite.objectId]) {
                const roomObj = rooms[window.currentPlayerRoom].objects[sprite.objectId];
                if (roomObj.setVisible) {
                    roomObj.setVisible(false);
                }
                roomObj.active = false;
                console.log(`Removed object ${sprite.objectId} from room`);
            }
        }
        
        // Continue with rest of function...
        
    } catch (error) {
        console.error('Error in addToInventory:', error);
        return false;
    }
}
```

### 9.2 Update Container Minigame to Lazy-Load Contents

**File:** `public/break_escape/js/minigames/container/container-minigame.js`

**Add new method to ContainerMinigame class:**

```javascript
async loadContainerContents() {
    const gameId = window.gameId;
    const containerId = this.containerItem.scenarioData.id || 
                       this.containerItem.scenarioData.name || 
                       this.containerItem.objectId;
    
    if (!gameId) {
        console.error('No gameId available for container loading');
        return [];
    }
    
    console.log(`Loading contents for container: ${containerId}`);
    
    try {
        const response = await fetch(`/break_escape/games/${gameId}/container/${containerId}`, {
            headers: { 'Accept': 'application/json' }
        });
        
        if (!response.ok) {
            if (response.status === 403) {
                window.gameAlert('Container is locked', 'error', 'Locked', 2000);
                this.complete(false);
                return [];
            }
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log(`Loaded ${data.contents?.length || 0} items from container`);
        return data.contents || [];
    } catch (error) {
        console.error('Failed to load container contents:', error);
        window.gameAlert('Could not load container contents', 'error', 'Error', 3000);
        return [];
    }
}
```

**Update the `init()` method to load contents asynchronously:**

```javascript
async init() {
    console.log('Container minigame init', {
        containerItem: this.containerItem,
        desktopMode: this.desktopMode,
        mode: this.mode
    });
    
    // Show loading state
    this.gameContainer.innerHTML = '<div class="loading">Loading contents...</div>';
    
    // Load contents from server (if gameId exists)
    if (window.gameId && this.containerItem.scenarioData.locked === false) {
        this.contents = await this.loadContainerContents();
    }
    // Otherwise use contents passed in (for unlocked containers in local game)
    
    // Create the UI
    this.createContainerUI();
}
```

### 9.3 Update Scenario Loading

**File:** `public/break_escape/js/core/game.js`

**Find the scenario loading code and update endpoint:**

```javascript
// Around line 650 or wherever scenario is loaded
async function loadScenario(gameId) {
    try {
        // Changed from '/scenario' to '/scenario_map'
        const response = await fetch(`/break_escape/games/${gameId}/scenario_map`);
        
        if (!response.ok) {
            throw new Error(`Failed to load scenario: ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('Loaded scenario map:', data);
        
        // Store the scenario map
        window.gameScenarioMap = data;
        
        return data;
    } catch (error) {
        console.error('Error loading scenario:', error);
        throw error;
    }
}
```

---

## Testing Strategy

### Unit Tests
- Test `filter_requires_and_contents_recursive` removes only `requires` and locked `contents`
- Test `find_item_in_scenario` locates items correctly
- Test validation helpers work with nested structures

### Integration Tests
- Test room endpoint filtering (lockType preserved, requires removed)
- Test container endpoint access control (403 for locked, 200 for unlocked)
- Test inventory validation (rejects items from locked rooms/containers)
- Test NPC encounter tracking (auto-added when entering room)
- Test unlock tracking (persists across requests)
- Test sync_state room validation (rejects locked rooms)

### End-to-End Tests
- Complete scenario: start → collect items → unlock doors → get contents

---

## Future Enhancements (Deferred)

1. **Rate limiting** - Can be added later via Rack::Attack at API gateway level
2. **Attempt logging** - Store failed unlock attempts for audit and analytics
3. **Item expiry** - Items might become unavailable after certain events
4. **NPC state tracking** - Track conversation progress with NPCs beyond encounters
5. **Biometric/Bluetooth tracking** - Auto-populate collections when items scanned/detected
6. **Performance optimizations** - Add caching for filtered room data (deferred - rooms not re-requested)
7. **Item index caching** - In-memory index of all items for faster validation (deferred - premature optimization)

---

## Notes & Design Decisions

### Security Model
- All `requires` fields (passwords, PINs, keys) hidden from client at controller level
- All `contents` fields hidden until explicit container endpoint call (lazy-loading)
- `lockType` and `locked` fields **visible** to client (needed for UI)
- Player state tracks all permissions (unlockedRooms, unlockedObjects, encounteredNPCs)

### Validation Flow
- Inventory operations validate against scenario data AND player state
- NPC encounters tracked automatically when room loaded (no separate API call)
- No unlock attempt tracking in Phase 1 (validates but doesn't log failures)
- Transaction safety ensures atomic state updates

### Breaking Changes
- `/games/:id/scenario` renamed to `/games/:id/scenario_map`
- Client code must be updated to call new endpoint names
- `scenario_map` returns minimal metadata, not full scenario with objects

### Out of Scope (Scenario Design Issues)
- Starting inventory duplication prevention (scenario author responsibility)
- Nested container cascade unlocking (intentional - each lock requires separate action)
