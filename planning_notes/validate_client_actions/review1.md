# Implementation Plan Review: Client Action Validation & Data Filtering

**Date:** November 21, 2025  
**Reviewer:** GitHub Copilot  
**Status:** Recommendations for Success  
**Confidence Level:** High

---

## Executive Summary

The implementation plan is **well-structured and security-focused**, with clear phasing and good separation of concerns. However, there are **9 critical areas** where improvements would significantly increase chances of successful execution and reduce technical debt. This review provides actionable recommendations organized by priority and implementation impact.

---

## 1. CRITICAL ISSUES (Must Fix Before Starting)

### Issue 1.1: Race Condition in Player State Initialization

**Location:** Phase 1.2, Method `initialize_player_state!`

**Problem:**
The current approach initializes player state on `before_create` callback, but:
- Multiple requests might create games simultaneously
- `initializedAt` check only prevents re-initialization within Rails, not across requests
- No transaction-level guarantee that state isn't initialized twice

**Impact:** 
- Duplicate inventory items
- Starting items collected twice on concurrent requests
- Inventory inconsistency

**Recommendation:**
```ruby
# Instead of initializedAt flag, use database uniqueness constraint
# and idempotent initialization pattern:

def initialize_player_state!
  # Use safe navigation and merge pattern
  base_state = {
    'currentRoom' => scenario_data['startRoom'],
    'unlockedRooms' => [scenario_data['startRoom']].uniq,
    'unlockedObjects' => [],
    'inventory' => scenario_data['startItemsInInventory']&.dup || [],
    'encounteredNPCs' => [],
    'globalVariables' => {},
    'biometricSamples' => [],
    'biometricUnlocks' => [],
    'bluetoothDevices' => [],
    'notes' => [],
    'health' => 100,
    'initializedAt' => Time.current.iso8601
  }
  
  # Only set if completely empty (first time)
  self.player_state = base_state if player_state.blank? || player_state.empty?
end
```

**Action Items:**
- [ ] Create migration to backfill player_state for existing games
- [ ] Add database index on `(id, player_state)` for quick state checks
- [ ] Test concurrent game creation with `AB` testing tool
- [ ] Document idempotent initialization in code comments

---

### Issue 1.2: No Validation of Scenario Data Integrity

**Location:** Phase 1, Entire initialization flow

**Problem:**
- Plan assumes `scenario_data['startRoom']` exists, but doesn't validate
- Plan assumes `startItemsInInventory` is well-formed array, but doesn't validate
- No checks for circular room connections
- No checks for orphaned items (items in rooms that don't exist)

**Impact:**
- Silent failures if scenario JSON is malformed
- Players stuck in non-existent rooms
- Items unreachable

**Recommendation:**
Add validation layer before initialization:

```ruby
class Game < ApplicationRecord
  validates :scenario_data, presence: true
  validate :scenario_data_integrity
  
  private
  
  def scenario_data_integrity
    return if scenario_data.blank?
    
    errors.add(:scenario_data, 'missing startRoom') unless scenario_data['startRoom'].present?
    errors.add(:scenario_data, 'startRoom not found') unless scenario_data['rooms']&.key?(scenario_data['startRoom'])
    
    # Validate startItemsInInventory structure
    if scenario_data['startItemsInInventory'].present?
      unless scenario_data['startItemsInInventory'].is_a?(Array)
        errors.add(:scenario_data, 'startItemsInInventory must be an array')
      end
    end
    
    # Validate all rooms exist (connection integrity)
    scenario_data['rooms']&.each do |room_id, room_data|
      next unless room_data['connections'].present?
      room_data['connections'].values.flatten.each do |connected_room|
        unless scenario_data['rooms'].key?(connected_room)
          errors.add(:scenario_data, "room #{room_id} connects to non-existent room #{connected_room}")
        end
      end
    end
  end
end
```

**Action Items:**
- [ ] Add scenario integrity validator before game creation
- [ ] Create integration tests with malformed scenarios
- [ ] Document expected scenario format as comments in validator
- [ ] Add error messages to help developers debug scenario issues

---

### Issue 1.3: Incomplete Specification of `scenario_data` Structure

**Location:** Phase 2-4, All filtering methods

**Problem:**
- Plan doesn't define what fields exist at each level (rooms, objects, NPCs, items)
- Example shows `lockType`, `locked`, `requires`, but no complete list
- Plan mentions `itemsHeld` on NPCs but structure unclear
- No guidance on optional vs required fields

**Impact:**
- Developers guess at field names
- Filtering logic breaks if fields are named differently
- Tests fail because mock data doesn't match real data structure

**Recommendation:**
Create a formal scenario schema document before implementation:

```ruby
# lib/break_escape/scenario_schema.rb
module BreakEscape
  SCENARIO_SCHEMA = {
    rooms: {
      room_id: {
        type: String,                    # e.g., "room_office"
        connections: Hash,               # { "north" => "office_2", "south" => "reception" }
        locked: Boolean,                 # optional
        lockType: String,                # "key", "password", "pin", "biometric", optional
        requires: String,                # HIDDEN FROM CLIENT - answer/key_id
        objects: Array,                  # Array of object definitions
        npcs: Array                      # Array of NPC definitions
      },
      objects: {
        id: String,                      # unique within room
        name: String,                    # display name
        type: String,                    # "door", "container", "key", "notes", etc.
        takeable: Boolean,
        interactable: Boolean,           # optional
        locked: Boolean,                 # optional
        lockType: String,                # optional
        requires: String,                # HIDDEN - answer/solution
        observations: String,            # description shown to player
        contents: Array,                 # HIDDEN UNTIL UNLOCKED - nested items
        itemsHeld: Array                 # for NPC objects
      },
      npcs: {
        id: String,                      # unique NPC identifier
        displayName: String,             # shown to player
        storyPath: String,               # path to .ink or .json
        npcType: String,                 # optional: "phone", "person", etc.
        itemsHeld: Array                 # items NPC holds { type, id, name, ... }
      }
    }
  }
end
```

**Action Items:**
- [ ] Create `lib/break_escape/scenario_schema.rb` with complete field definitions
- [ ] Add JSON Schema validator to verify scenarios match spec
- [ ] Document which fields are client-visible in inline comments
- [ ] Generate test fixture scenarios from schema definition

---

## 2. DESIGN ISSUES (High Impact on Success)

### Issue 2.1: `filter_contents_field` Method is Inefficient

**Location:** Phase 2.3, controller filtering

**Problem:**
- Recursively walks entire object tree for each filter operation
- Modifies objects in-place (using `.delete()`), which mutates original in memory
- No memoization of filtered results
- Same room data might be filtered multiple times per request

**Impact:**
- Performance degrades with large scenarios (many rooms/objects)
- Memory pressure from deep copies
- Defensive copying needed to prevent mutations

**Recommendation:**
Create dedicated filtering service class:

```ruby
# app/services/break_escape/data_filter_service.rb
module BreakEscape
  class DataFilterService
    # Hide sensitive fields during room data exposure
    SENSITIVE_FIELDS = ['requires', 'contents'].freeze
    
    def initialize(scenario_data)
      @scenario_data = scenario_data
      @filter_cache = {}
    end
    
    # Filter object recursively, returning new object (immutable)
    def filter_object(obj, hide_fields: SENSITIVE_FIELDS)
      cache_key = "#{obj.object_id}_#{hide_fields.join(',')}"
      return @filter_cache[cache_key] if @filter_cache.key?(cache_key)
      
      result = case obj
      when Hash
        obj.each_with_object({}) do |(key, value), acc|
          next if hide_fields.include?(key)
          acc[key] = filter_object(value, hide_fields: hide_fields)
        end
      when Array
        obj.map { |item| filter_object(item, hide_fields: hide_fields) }
      else
        obj
      end
      
      @filter_cache[cache_key] = result
    end
    
    # Filter room data (remove 'requires' but keep 'lockType', 'locked')
    def filtered_room_data(room_id)
      room = @scenario_data['rooms']&.[](room_id)
      return nil unless room
      
      filter_object(room, hide_fields: ['requires', 'contents'])
    end
    
    # Filter contents of a specific container (remove nested 'requires')
    def filtered_container_contents(container_id)
      container = find_container_in_scenario(container_id)
      return nil unless container
      
      (container['contents'] || []).map do |item|
        filter_object(item, hide_fields: ['requires', 'contents'])
      end
    end
  end
end
```

**Action Items:**
- [ ] Create `app/services/break_escape/data_filter_service.rb`
- [ ] Add caching strategy for repeated filters
- [ ] Add unit tests for filter performance
- [ ] Update controller to use service instead of inline filtering
- [ ] Add instrumentation to measure filter overhead

---

### Issue 2.2: Validation Helper Methods Are Complex and Scattered

**Location:** Phase 4, Inventory validation, multiple helper methods

**Problem:**
- `find_item_in_scenario`, `find_item_container`, `find_item_room`, `find_npc_holding_item` all do similar traversals
- Each method might have different traversal logic (depth-first vs breadth-first)
- No shared traversal pattern
- Code duplication increases bug surface area

**Impact:**
- Bugs in one finder don't get fixed in others
- Hard to maintain consistency
- Performance suffers from repeated traversals

**Recommendation:**
Create a scenario traversal service:

```ruby
# app/services/break_escape/scenario_traverser.rb
module BreakEscape
  class ScenarioTraverser
    def initialize(scenario_data)
      @scenario_data = scenario_data
      @index = {} # Cache of item/container/NPC lookups
      build_index
    end
    
    # Find item by type and ID anywhere in scenario
    def find_item(item_type, item_id)
      @index[:items]["#{item_type}:#{item_id}"]
    end
    
    # Find which container holds an item
    def find_containing_container(item_type, item_id)
      item = find_item(item_type, item_id)
      return nil unless item
      @index[:container_map]["#{item_type}:#{item_id}"]
    end
    
    # Find which room contains an item
    def find_containing_room(item_type, item_id)
      item = find_item(item_type, item_id)
      return nil unless item
      @index[:room_map]["#{item_type}:#{item_id}"]
    end
    
    # Find NPC holding an item
    def find_npc_holding(item_type, item_id)
      @index[:npc_holdings]["#{item_type}:#{item_id}"]
    end
    
    # Find container by ID
    def find_container(container_id)
      @index[:containers][container_id]
    end
    
    # Find NPC by ID
    def find_npc(npc_id)
      @index[:npcs][npc_id]
    end
    
    private
    
    def build_index
      @index = {
        items: {},           # "type:id" => item_data
        containers: {},      # "container_id" => container_data
        npcs: {},           # "npc_id" => npc_data
        container_map: {},  # "type:id" => container_id (what container holds this item)
        room_map: {},       # "type:id" => room_id (what room contains this item)
        npc_holdings: {}    # "type:id" => npc_id (what NPC holds this)
      }
      
      @scenario_data['rooms']&.each do |room_id, room_data|
        index_room_objects(room_id, room_data['objects'], container_id: nil)
        index_npcs(room_id, room_data['npcs'])
      end
    end
    
    def index_room_objects(room_id, objects, container_id: nil)
      return unless objects
      
      objects.each do |obj|
        # Index the object itself
        key = "#{obj['type']}:#{obj['id']}"
        @index[:items][key] = obj
        @index[:room_map][key] = room_id
        
        # If inside a container, record that relationship
        @index[:container_map][key] = container_id if container_id
        
        # If this object is a container, index it
        if obj['contents'].present?
          @index[:containers][obj['id']] = obj
          # Recursively index nested contents
          index_room_objects(room_id, obj['contents'], container_id: obj['id'])
        end
      end
    end
    
    def index_npcs(room_id, npcs)
      return unless npcs
      
      npcs.each do |npc|
        @index[:npcs][npc['id']] = npc
        
        # Index items held by NPC
        next unless npc['itemsHeld'].present?
        npc['itemsHeld'].each do |item|
          key = "#{item['type']}:#{item['id']}"
          @index[:npc_holdings][key] = npc['id']
        end
      end
    end
  end
end
```

**Action Items:**
- [ ] Create `app/services/break_escape/scenario_traverser.rb`
- [ ] Add unit tests for each finder method
- [ ] Update inventory validation to use traverser
- [ ] Benchmark performance improvement (should eliminate duplicate traversals)
- [ ] Add memoization for scenario_traverser instances per game

---

### Issue 2.3: Missing Container Nested Contents Handling

**Location:** Phase 3, Container endpoint

**Problem:**
- Plan says "containers can be nested" (containers inside containers)
- But `filter_contents_field` method is incomplete (pseudocode)
- No handling for deeply nested containers
- Unclear: Can items inside nested containers be collected?

**Impact:**
- Nested container structure breaks at runtime
- Items in nested containers unreachable
- Filtering logic incomplete

**Recommendation:**
Extend container traversal to handle nesting:

```ruby
# In ScenarioTraverser class:
def container_chain(container_id)
  # Returns all containers in nesting order
  # e.g., [safe_id, inner_box_id, final_container_id]
  chain = []
  current_id = container_id
  
  while current_id
    container = @index[:containers][current_id]
    return nil unless container # Safety check: container not found
    chain.unshift(current_id)
    current_id = @index[:container_map]["#{container['type']}:#{current_id}"]
  end
  
  chain
end

def is_container_accessible?(container_id, unlocked_objects)
  # Container only accessible if ALL parent containers in chain are unlocked
  chain = container_chain(container_id)
  return false unless chain
  
  chain.all? { |cid| unlocked_objects.include?(cid) }
end
```

**Action Items:**
- [ ] Add container chain tracking to traverser
- [ ] Add accessibility check for nested containers
- [ ] Update container endpoint to validate entire chain is unlocked
- [ ] Add tests for nested container scenarios
- [ ] Document nesting rules in scenario schema

---

## 3. TESTING & VALIDATION ISSUES

### Issue 3.1: Insufficient Test Coverage Specification

**Location:** Phase 9, Testing & Validation (very high level)

**Problem:**
- Phase 9 lists test names but no test cases/assertions
- No coverage requirements specified
- No "happy path" vs "unhappy path" breakdown
- No edge case identification

**Impact:**
- Tests will be incomplete or miss critical paths
- Integration test failure doesn't help developers debug
- No regression test foundation for future features

**Recommendation:**
Create detailed test matrix:

```ruby
# test/integration/client_action_validation_test.rb

describe "Client Action Validation" do
  
  describe "Room Access Control" do
    test "player can access starting room without unlock" do
      # Game created, player_state['unlockedRooms'] contains start room
      # Request room endpoint for startRoom → 200 OK
    end
    
    test "player cannot access locked room without unlock" do
      # Request room endpoint for locked room → 403 Forbidden
    end
    
    test "player can access room after unlock" do
      # Unlock room → Update unlockedRooms
      # Request room endpoint → 200 OK
    end
  end
  
  describe "Data Filtering" do
    test "room response does not include 'requires' field" do
      # Check all objects in room response
      # Assert no 'requires' key exists at any level
    end
    
    test "room response does not include 'contents' of locked containers" do
      # Check all containers in room response
      # Assert 'contents' key does not exist if locked
    end
    
    test "room response includes 'lockType' and 'locked' status" do
      # Verify these fields present for client UI
    end
  end
  
  describe "Container Lazy Loading" do
    test "container contents not accessible before unlock" do
      # GET /container/safe_1 before unlock → 403 Forbidden
    end
    
    test "container contents accessible after unlock" do
      # Unlock container → 200 OK with contents
    end
    
    test "nested containers require full chain unlock" do
      # Scenario with: safe → inner_box → item
      # Each must be unlocked separately
    end
  end
  
  describe "Inventory Validation" do
    test "item cannot be collected from locked room" do
      # POST /inventory { add, item } for item in locked room
      # → Error: "Room not unlocked"
    end
    
    test "item cannot be collected from locked container" do
      # Item in locked container
      # → Error: "Container not unlocked"
    end
    
    test "NPC-held item cannot be collected before encounter" do
      # NPC in room not visited yet
      # → Error: "NPC not encountered"
    end
    
    test "item can be collected from accessible location" do
      # Room unlocked, container unlocked or not in container, NPC encountered
      # → Success, inventory updated
    end
  end
  
  describe "NPC Encounter Tracking" do
    test "NPC added to encounteredNPCs when room loaded" do
      # Load room with NPC
      # Check player_state['encounteredNPCs'] includes NPC
    end
    
    test "NPC not in encounteredNPCs if room never visited" do
      # Scenario with NPC in locked room
      # encounteredNPCs should not include that NPC
    end
  end
  
  describe "Unlock Tracking" do
    test "room added to unlockedRooms after successful unlock" do
      # Valid unlock attempt
      # unlockedRooms includes the room
    end
    
    test "container added to unlockedObjects after unlock" do
      # Valid container unlock
      # unlockedObjects includes the container
    end
  end
  
  describe "Edge Cases" do
    test "simultaneous unlock attempts don't duplicate" do
      # Two concurrent unlock requests for same door
      # unlockedRooms includes room only once
    end
    
    test "inventory doesn't accept duplicates" do
      # Collect item, remove it, collect again
      # Inventory correctly updated each time
    end
    
    test "player state persists across requests" do
      # Create game, unlock room, fetch game
      # player_state still contains unlock
    end
  end
end
```

**Action Items:**
- [ ] Create comprehensive test matrix before implementation
- [ ] Assign each test to specific phase where it should pass
- [ ] Define acceptance criteria for each test
- [ ] Create fixtures (scenarios) for each test case
- [ ] Add performance benchmarks (response time, memory usage)

---

### Issue 3.2: Missing Rollback & Recovery Strategy

**Location:** All phases, implicit assumption things work

**Problem:**
- Plan doesn't mention what happens if a phase fails
- No specification of backwards compatibility
- No plan for debugging failed unlocks
- No admin tools for resetting game state

**Impact:**
- If implementation partially succeeds, hard to debug
- Players can't recover from bugs
- No way to fix inconsistent state in production

**Recommendation:**
Add Phase 11: Rollback & Recovery Tools

```ruby
# app/services/break_escape/game_state_manager.rb
module BreakEscape
  class GameStateManager
    def initialize(game)
      @game = game
    end
    
    # Snapshot current state for rollback
    def create_snapshot
      {
        timestamp: Time.current,
        snapshot_id: SecureRandom.uuid,
        player_state: @game.player_state.deep_dup
      }
    end
    
    # Restore from snapshot
    def restore_snapshot(snapshot_id)
      # Find and restore snapshot
      snapshot = @game.snapshots.find_by(snapshot_id: snapshot_id)
      raise "Snapshot not found: #{snapshot_id}" unless snapshot
      
      @game.player_state = snapshot.data['player_state']
      @game.save!
    end
    
    # Reset game to initial state
    def reset_to_start
      @game.initialize_player_state!
    end
    
    # Validate state consistency
    def validate_consistency
      errors = []
      
      # Check all unlockedRooms exist in scenario
      @game.player_state['unlockedRooms'].each do |room_id|
        unless @game.scenario_data['rooms'].key?(room_id)
          errors << "Room #{room_id} in unlockedRooms but not in scenario"
        end
      end
      
      # Check all inventory items exist in scenario or are starting items
      @game.player_state['inventory'].each do |item|
        # Item should be findable in scenario
        # OR be a starting item
      end
      
      # Check NPC encounters are in scenario
      # Check container unlocks are in scenario
      
      errors
    end
  end
end
```

**Action Items:**
- [ ] Add Phase 11: Recovery & Debugging Tools to plan
- [ ] Create `app/services/break_escape/game_state_manager.rb`
- [ ] Add state validation checks before responding to client requests
- [ ] Create admin endpoint to inspect game state
- [ ] Create admin endpoint to reset specific games
- [ ] Add logging for state changes

---

## 4. IMPLEMENTATION SEQUENCING ISSUES

### Issue 4.1: Wrong Phase Dependencies

**Location:** Implementation TODO List, Phase ordering

**Problem:**
- Phase 6 (Unlock Tracking) depends on Phase 4 (Inventory Validation)
- But plan lists them in sequence as if Phase 6 is independent
- Phase 7 (Sync State Validation) depends on Phase 1 (Initialization)
- No explicit dependency graph

**Impact:**
- Developer might implement phases out of order and get stuck
- Unclear which tests should pass after each phase

**Recommendation:**
Create explicit dependency diagram:

```
Phase 1: Data Model & Initialization
├─ Phase 2: Data Filtering
│  ├─ Phase 3: Container Lazy-Loading
│  └─ Phase 6: Unlock Validation & Tracking
├─ Phase 4: Inventory Validation
│  └─ Phase 5: NPC Encounter Tracking
└─ Phase 7: Sync State Validation

Phase 8: Routing (can start once controllers exist)
Phase 9: Testing (runs continuously after each phase)
Phase 10: Client Updates (after server complete)
Phase 11: Recovery Tools (after Phase 1-7 complete)
```

**Recommended Implementation Order:**
1. Phase 1 ✓ (prerequisite for everything)
2. Phase 2 ✓ (data filtering needed by Phase 6)
3. Phase 8 ✓ (add routes as you go)
4. Phase 3 ✓ (container endpoint)
5. Phase 6 ✓ (unlock tracking)
6. Phase 5 ✓ (NPC encounter tracking)
7. Phase 4 ✓ (inventory validation)
8. Phase 7 ✓ (sync state validation)
9. Phase 11 ✓ (recovery tools)
10. Phase 9 ✓ (comprehensive testing)
11. Phase 10 (client updates)

**Action Items:**
- [ ] Create dependency graph in planning document
- [ ] Identify any additional dependencies not listed
- [ ] Reorder phases based on dependencies
- [ ] Create "ready to start" checklist for each phase

---

### Issue 4.2: Client Updates Are Last (Should Be Earlier for Testing)

**Location:** Phase 10, Client Updates

**Problem:**
- Client updates are Phase 10, last
- But without client changes, server endpoints can't be tested
- Manual integration testing required with curl/Postman before client ready
- Creates bottleneck: server done but can't validate until client updated

**Impact:**
- Hard to find bugs (can't end-to-end test without client)
- Delay in finding integration issues
- Client developers blocked waiting for server

**Recommendation:**
Split client updates into two phases:

```markdown
## Phase 8B: Client Integration (After Phase 3, Before Phase 4)
- Create stub client endpoints that call new server endpoints
- Add error handling for new response format
- Test with curl/Postman until working
- Update game.js to use scenario_map instead of full scenario
- Update room endpoint calls with filtering awareness

## Phase 10: Client Polish (After Phase 9)
- Add UI for error states
- Add loading indicators
- Optimize performance
- Add user feedback for validation errors
```

**Action Items:**
- [ ] Create Phase 8B: Client Integration
- [ ] Add stub client implementation before server complete
- [ ] Create curl/Postman test suite for each endpoint
- [ ] Parallel development: Server Phase 4-7 while Client Phase 8B ongoing
- [ ] Move UI polish to Phase 10 (after all features working)

---

## 5. DOCUMENTATION & COMMUNICATION GAPS

### Issue 5.1: No Specification of Error Response Formats

**Location:** Error Handling section, incomplete examples

**Problem:**
- Plan shows a few error examples but inconsistent format
- "Missing room_id parameter" vs "Container not unlocked" use different patterns
- No specification of HTTP status codes for different error types
- No error code system for client to handle programmatically

**Impact:**
- Client code might not correctly handle errors
- Hard to test all error paths
- Developers guess at response format

**Recommendation:**
Formalize error response schema:

```ruby
# Error Response Format:
{
  success: false,
  error: {
    code: "ERROR_CODE",           # Machine-readable error classification
    message: "Human readable",    # User-facing message
    details: {}                   # Additional context (optional)
  }
}

# HTTP Status Codes:
# 400 - Bad Request: Missing/invalid parameters (developer error)
# 403 - Forbidden: Permission denied (gameplay state issue)
# 404 - Not Found: Resource not found
# 422 - Unprocessable Entity: Validation failed (gameplay logic)
# 500 - Internal Server Error: Unexpected error (bug)

# Error Codes:
MISSING_PARAMETER = "MISSING_PARAMETER"
ROOM_NOT_FOUND = "ROOM_NOT_FOUND"
ROOM_NOT_ACCESSIBLE = "ROOM_NOT_ACCESSIBLE"
CONTAINER_NOT_FOUND = "CONTAINER_NOT_FOUND"
CONTAINER_NOT_UNLOCKED = "CONTAINER_NOT_UNLOCKED"
ITEM_NOT_FOUND = "ITEM_NOT_FOUND"
ITEM_NOT_TAKEABLE = "ITEM_NOT_TAKEABLE"
ITEM_LOCATION_LOCKED = "ITEM_LOCATION_LOCKED"  # Room or container
NPC_NOT_ENCOUNTERED = "NPC_NOT_ENCOUNTERED"
INVALID_UNLOCK_ATTEMPT = "INVALID_UNLOCK_ATTEMPT"
```

**Action Items:**
- [ ] Create error code constants in `lib/break_escape/error_codes.rb`
- [ ] Create error response builder method in ApplicationController
- [ ] Update all error responses to use consistent format
- [ ] Document error codes in API documentation
- [ ] Create error handling guide for client developers

---

### Issue 5.2: No API Documentation or Examples

**Location:** Implementation plan, missing entirely

**Problem:**
- Plan doesn't specify HTTP verbs, parameter names exactly as they'll be
- Plan shows pseudocode but not exact API contracts
- Client developers won't know what to call
- No spec for developers following later

**Impact:**
- Integration painful and error-prone
- Clients might call endpoints incorrectly
- Hard to onboard new developers

**Recommendation:**
Create OpenAPI/Swagger spec:

```yaml
# Break Escape API - Validation & Filtering Endpoints

/games/{id}/room/{room_id}:
  get:
    summary: Load room data with filtering
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
      - name: room_id
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: Room data (requires and contents fields hidden)
        content:
          application/json:
            schema:
              type: object
              properties:
                room_id: { type: string }
                room: { type: object }
      403:
        description: Room not accessible
      404:
        description: Room not found

/games/{id}/container/{container_id}:
  get:
    summary: Load locked container contents
    parameters:
      - name: id
        in: path
        required: true
      - name: container_id
        in: path
        required: true
    responses:
      200:
        description: Container contents with filtering applied
      403:
        description: Container not unlocked
      404:
        description: Container not found

/games/{id}/scenario_map:
  get:
    summary: Get minimal scenario layout (no secrets exposed)
    responses:
      200:
        description: Room connections and accessibility

/games/{id}/unlock:
  post:
    parameters:
      - name: targetType
        in: body
        required: true
        schema:
          enum: [door, object]
      - name: targetId
        in: body
        required: true
      - name: attempt
        in: body
        required: true
      - name: method
        in: body
        required: true
    responses:
      200:
        description: Unlock successful
      422:
        description: Invalid attempt

/games/{id}/inventory:
  post:
    parameters:
      - name: actionType
        in: body
        enum: [add, remove]
      - name: item
        in: body
        schema:
          type: object
          required: [type, id]
    responses:
      200:
        description: Inventory updated
      422:
        description: Item not collectible
```

**Action Items:**
- [ ] Create OpenAPI/Swagger spec in `docs/api.openapi.yaml`
- [ ] Generate interactive API docs from spec
- [ ] Add code examples for each endpoint in Ruby/JavaScript
- [ ] Create API testing guide (curl examples)
- [ ] Update README with API overview

---

## 6. PERFORMANCE & SCALABILITY ISSUES

### Issue 6.1: No Consideration of Large Scenarios

**Location:** All phases, implicit assumption scenarios are small

**Problem:**
- Plan uses linear search through all rooms/objects
- No pagination or lazy-loading of scenario data
- Scenarios could have thousands of objects
- Every room request triggers full traversal

**Impact:**
- Slow response times for large scenarios
- High CPU/memory on server
- Client perceived as sluggish

**Recommendation:**
Add performance considerations to Phase 2:

```ruby
# app/services/break_escape/scenario_cache.rb
module BreakEscape
  class ScenarioCache
    # Cache filtered room data for performance
    def initialize(game)
      @game = game
      @room_cache = {}
      @filter_service = DataFilterService.new(game.scenario_data)
    end
    
    def filtered_room(room_id)
      @room_cache[room_id] ||= begin
        @filter_service.filtered_room_data(room_id)
      end
    end
    
    def clear_cache
      @room_cache.clear
    end
    
    def invalidate_room(room_id)
      @room_cache.delete(room_id)
    end
  end
end

# Measure and optimize:
# - Response time: Room endpoint should respond < 100ms
# - Scenario size: Support scenarios up to 100 rooms, 1000 objects
# - Memory: Scenario data should fit in memory (not stream from disk)
```

**Action Items:**
- [ ] Add caching layer for filtered room data
- [ ] Profile room endpoint response time with large scenario
- [ ] Set performance targets: < 100ms per room request
- [ ] Add N+1 query detection for database calls
- [ ] Test with scenarios of varying sizes (10, 100, 1000 objects)

---

### Issue 6.2: Inventory Validation Performance

**Location:** Phase 4, multiple find operations

**Problem:**
- Current approach does 4+ full scenario traversals per inventory add
- `find_item_in_scenario`, `find_item_container`, `find_item_room`, `find_npc_holding_item`
- Each traversal walks entire object tree

**Impact:**
- Inventory operations slow (multiple seconds for large scenario)
- Scales poorly: inventory add time grows linearly with scenario size

**Recommendation:**
Use ScenarioTraverser index (Issue 2.2 already addresses this)

```ruby
# Measurement:
# Current: O(n * m) where n = scenarios traversals, m = objects
# With index: O(1) lookup after O(m) index build
# Improvement: Build index once per game, reuse for all operations
```

**Action Items:**
- [ ] Implement ScenarioTraverser index (see Issue 2.2)
- [ ] Benchmark inventory add: before/after
- [ ] Target: Inventory add < 50ms
- [ ] Add index build time to game initialization
- [ ] Cache traverser instance in @game object

---

## 7. SECURITY REVIEW

### Issue 7.1: Missing Authorization Checks

**Location:** All controller actions

**Problem:**
- Plan shows `authorize @game if defined?(Pundit)` but conditional
- Not all endpoints might have this
- No specification of what authorization means
- Could allow one player to access another player's game

**Impact:**
- Player A could unlock rooms in Player B's game
- Data leak between players
- Game state modification by unauthorized user

**Recommendation:**
Strengthen authorization:

```ruby
# app/policies/break_escape/game_policy.rb
module BreakEscape
  class GamePolicy
    attr_reader :user, :game
    
    def initialize(user, game)
      @user = user
      @game = game
    end
    
    def show?
      game.player == user  # Only owner can access
    end
    
    def room?
      show?  # Same auth as show
    end
    
    def container?
      show?
    end
    
    def unlock?
      show?
    end
    
    def inventory?
      show?
    end
    
    def sync_state?
      show?
    end
  end
end

# In controller, always authorize:
module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :scenario, :ink, :room, :container, :sync_state, :unlock, :inventory, :scenario_map]
    before_action :authorize_game
    
    private
    
    def authorize_game
      authorize @game
    end
  end
end
```

**Action Items:**
- [ ] Create `app/policies/break_escape/game_policy.rb`
- [ ] Make authorization non-conditional (always required)
- [ ] Test authorization on each endpoint
- [ ] Add integration tests for authorization failures
- [ ] Document who can perform each action

---

### Issue 7.2: Data Filtering Completeness Not Verified

**Location:** All filtering methods

**Problem:**
- Plan assumes filter methods catch all instances of hidden fields
- But what if scenario has new field type added later?
- What if nested structure is deeper than expected?
- No way to verify filtering is complete

**Impact:**
- Accidentally expose "requires" field if code changes
- Security regression from future maintenance

**Recommendation:**
Add verification layer:

```ruby
# app/services/break_escape/data_verifier.rb
module BreakEscape
  class DataVerifier
    FORBIDDEN_FIELDS = ['requires'].freeze
    
    def self.verify_filtered_data(data)
      errors = []
      verify_recursive(data, errors)
      errors
    end
    
    private
    
    def self.verify_recursive(obj, errors, path = "root")
      case obj
      when Hash
        obj.each do |key, value|
          if FORBIDDEN_FIELDS.include?(key)
            errors << "Found forbidden field '#{key}' at #{path}"
          end
          verify_recursive(value, errors, "#{path}.#{key}")
        end
      when Array
        obj.each_with_index do |item, idx|
          verify_recursive(item, errors, "#{path}[#{idx}]")
        end
      end
    end
  end
end

# Use in tests:
test "room data never exposes requires field" do
  response = get "/games/#{game.id}/room/office"
  room_data = JSON.parse(response.body)['room']
  
  errors = DataVerifier.verify_filtered_data(room_data)
  assert errors.empty?, "Found forbidden fields: #{errors.join(', ')}"
end
```

**Action Items:**
- [ ] Create `app/services/break_escape/data_verifier.rb`
- [ ] Add verification to all filtered data responses
- [ ] Create test helper to assert no forbidden fields
- [ ] Run verification in tests automatically
- [ ] Add flag to log warnings in development if forbidden fields found

---

## 8. MINOR ISSUES (Nice-to-Have Improvements)

### Issue 8.1: Debugging Visibility

**Problem:**
- No logging of filtering/validation operations
- Hard to debug "why can't player access room?"
- Hard to trace validation decisions

**Recommendation:**
```ruby
class DataFilterService
  def filter_object(obj, hide_fields: SENSITIVE_FIELDS)
    Rails.logger.debug "[BreakEscape] Filtering object #{obj['id']} with fields: #{hide_fields}"
    # ... rest of method
  end
end

class Game < ApplicationRecord
  def validate_unlock(...)
    Rails.logger.info "[BreakEscape] Validating unlock for #{target_id}"
    # ... rest of method
  end
end
```

**Action Items:**
- [ ] Add structured logging using `Rails.logger.tagged`
- [ ] Create log format consistent with other endpoints
- [ ] Add instrumentation gem for performance monitoring
- [ ] Document logging format for debugging guide

---

### Issue 8.2: Consistency Between Endpoints

**Problem:**
- Room endpoint might filter differently than container endpoint
- Scenario map might expose different fields than room
- No specification that all are consistent

**Recommendation:**
```ruby
# Create shared constants
module BreakEscape
  module DataFiltering
    # Fields always hidden from client (solutions)
    ALWAYS_HIDDEN = ['requires'].freeze
    
    # Fields hidden until unlocked (contents)
    HIDDEN_UNTIL_UNLOCKED = ['contents'].freeze
    
    # Fields always visible to client (needed for UI)
    ALWAYS_VISIBLE = ['lockType', 'locked', 'observations', 'id', 'name', 'type'].freeze
  end
end
```

**Action Items:**
- [ ] Create `lib/break_escape/data_filtering.rb` with shared constants
- [ ] Use constants in all filtering methods
- [ ] Document field visibility policy in comments
- [ ] Add assertions to tests that verify consistency

---

## SUMMARY: Risk & Mitigation Matrix

| Risk | Probability | Impact | Mitigation | Priority |
|------|-------------|--------|-----------|----------|
| Race condition in initialization | High | Medium | Add idempotent pattern (Issue 1.1) | CRITICAL |
| Malformed scenario breaks game | Medium | High | Add validation (Issue 1.2) | CRITICAL |
| Incomplete scenario schema | High | Medium | Create formal schema (Issue 1.3) | CRITICAL |
| Performance degrades with large scenarios | Medium | High | Add caching + traverser index (Issues 6.1, 6.2, 2.1) | HIGH |
| Authorization bypass | Low | Critical | Strengthen auth checks (Issue 7.1) | HIGH |
| Accidentally expose secrets in future | Low | Critical | Add verification layer (Issue 7.2) | HIGH |
| Nested containers break | Medium | Medium | Extend traversal (Issue 2.3) | HIGH |
| Incomplete test coverage | High | Medium | Create test matrix (Issue 3.1) | HIGH |
| Player stuck in failed state | Medium | Medium | Add recovery tools (Issue 3.2) | MEDIUM |
| Wrong phase dependencies | Low | Medium | Create dependency graph (Issue 4.1) | MEDIUM |
| Client blocked on server | Low | Medium | Parallel Phase 8B (Issue 4.2) | MEDIUM |
| Integration testing difficult | Medium | Low | Create curl/Postman suite (Issue 4.2) | MEDIUM |
| API unclear to developers | Low | Low | Create OpenAPI spec (Issue 5.2) | LOW |
| Debugging difficult | Low | Low | Add logging (Issue 8.1) | LOW |

---

## RECOMMENDED PRIORITY: Critical Path First

**Must Fix Before Starting:**
1. Issue 1.1: Race condition handling
2. Issue 1.2: Scenario validation
3. Issue 1.3: Scenario schema documentation

**Must Fix During Design Phase:**
4. Issue 2.1: Efficient filtering service
5. Issue 2.2: Scenario traverser with index
6. Issue 3.1: Comprehensive test matrix
7. Issue 4.1: Dependency graph

**Can Parallelize:**
8. Issue 2.3: Nested container handling (parallel with Phase 3)
9. Issue 4.2: Phase 8B client integration (parallel with server)
10. Issue 7.1: Authorization policy (parallel with controller work)

**Add After MVP:**
11. Issue 3.2: Recovery tools (Phase 11)
12. Issue 6.1: Performance optimization
13. Issue 7.2: Data verification
14. Issue 5.2: OpenAPI documentation
15. Issue 8.1: Enhanced logging

---

## Next Steps

1. **Review with team** - Present this review to development team
2. **Prioritize** - Decide which issues to address immediately vs. defer
3. **Update plan** - Incorporate recommendations into IMPLEMENTATION_PLAN.md
4. **Create PR** - Implement high-priority fixes to game.rb and add data_filter_service.rb
5. **Begin Phase 1** - Start with data model improvements and validation

---

## Appendix: Quick Reference Checklist

### Before Any Code Changes:
- [ ] Create scenario schema document
- [ ] Add scenario data validation
- [ ] Make authorization non-conditional
- [ ] Create dependency graph

### During Implementation:
- [ ] Use DataFilterService for filtering
- [ ] Use ScenarioTraverser for lookups
- [ ] Create test matrix before phase
- [ ] Run DataVerifier on all responses
- [ ] Add error code constants and consistent response format

### Before Calling Complete:
- [ ] Zero authorization bypasses
- [ ] No forbidden fields in any response
- [ ] Performance < 100ms per room request
- [ ] All test matrix items passing
- [ ] Recovery tools available for admins
- [ ] API documentation complete

---

**End of Review**
