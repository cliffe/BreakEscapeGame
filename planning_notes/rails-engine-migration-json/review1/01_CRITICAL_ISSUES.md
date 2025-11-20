# Critical Issues - Detailed Analysis

This document provides in-depth analysis of critical issues that **MUST** be resolved before implementation.

---

## Issue #1: NPC Ink File Structure Mismatch

**Severity:** 🔴 CRITICAL - Will cause build failures
**Phase Impact:** Phase 3, Phase 5
**Effort to Fix:** 2-4 hours

### Problem Description

The migration plan makes incorrect assumptions about Ink file organization:

**Plan Assumes:**
```
app/assets/scenarios/ceo_exfil/ink/
├── security_guard.ink           ✓ EXISTS
├── security_guard.ink.json      ✗ DOES NOT EXIST
├── neye_eve.ink                 ✗ DOES NOT EXIST
├── neye_eve.ink.json            ✗ DOES NOT EXIST
```

**Actual Codebase:**
```
scenarios/ink/
├── security-guard.ink           ✓ EXISTS (hyphenated)
├── neye-eve.json                ✓ EXISTS (compiled, not .ink.json)
├── gossip-girl.json             ✓ EXISTS
├── helper-npc.json              ✓ EXISTS
├── alice-chat.ink               ✓ EXISTS
├── alice-chat.ink.json          ✓ EXISTS (only 3 files have .ink.json)
└── ... 30 total .ink files
```

**Scenarios Reference:**
```json
{
  "storyPath": "scenarios/ink/neye-eve.json"  // Not .ink.json!
}
```

### Evidence

From codebase analysis:
```bash
# Ink source files
$ find scenarios/ink -name "*.ink" | wc -l
30

# Compiled ink files (.ink.json format)
$ ls scenarios/ink/*.ink.json
alice-chat.ink.json
mixed-message-example.ink.json
voice-message-example.ink.json

# Regular JSON files (compiled ink without .ink extension)
$ ls scenarios/ink/*.json | wc -l
26
```

From scenario files:
```json
// scenarios/ceo_exfil.json
{
  "npcs": [
    {
      "id": "neye_eve",
      "storyPath": "scenarios/ink/neye-eve.json"  // ← .json, not .ink.json
    }
  ]
}
```

### Root Cause

The codebase uses **inconsistent naming conventions**:
- Some files: `name.ink.json` (Ink's default output)
- Most files: `name.json` (manually renamed for cleaner paths)
- Scenarios expect: `.json` extension

Additionally, **not all .ink files have been compiled**:
- 30 source `.ink` files exist
- Only 3-5 compiled files exist
- Missing compilation step in workflow

### Impact on Migration Plan

**Phase 3: Reorganize Scenarios (Week 1-2)**
```bash
# This command will FAIL:
mv "scenarios/ink/security_guard.ink.json" "app/assets/scenarios/${SCENARIO}/ink/"
# Error: No such file or directory
```

**Phase 5: Scenario Import (Week 2)**
```ruby
# This code will FAIL:
ink_json_path = Rails.root.join('app/assets/scenarios', scenario_name, 'ink', "#{npc_id}.ink.json")
# Error: File not found (looking for .ink.json, but files are .json)
```

### Required Fixes

#### Fix 1: Update File Movement Commands (Phase 3)

**Before:**
```bash
mv "scenarios/ink/security_guard.ink" "app/assets/scenarios/${SCENARIO}/ink/"
mv "scenarios/ink/security_guard.ink.json" "app/assets/scenarios/${SCENARIO}/ink/"
```

**After:**
```bash
# Move .ink source
mv "scenarios/ink/security-guard.ink" "app/assets/scenarios/${SCENARIO}/ink/"

# Move compiled .json (check both patterns)
if [ -f "scenarios/ink/security-guard.ink.json" ]; then
  mv "scenarios/ink/security-guard.ink.json" "app/assets/scenarios/${SCENARIO}/ink/"
elif [ -f "scenarios/ink/security-guard.json" ]; then
  mv "scenarios/ink/security-guard.json" "app/assets/scenarios/${SCENARIO}/ink/"
fi
```

#### Fix 2: Add Ink Compilation Step

**New Phase 2.5: Compile Ink Scripts**
```bash
# Install Inklecate (Ink compiler)
npm install -g inkjs

# Compile all .ink files to .json
for ink_file in scenarios/ink/*.ink; do
  base_name=$(basename "$ink_file" .ink)

  # Skip if already compiled as .json
  if [ ! -f "scenarios/ink/${base_name}.json" ] && [ ! -f "scenarios/ink/${base_name}.ink.json" ]; then
    echo "Compiling $ink_file..."
    inklecate -o "scenarios/ink/${base_name}.json" "$ink_file"
  fi
done
```

#### Fix 3: Update ScenarioLoader (Phase 5)

**Before:**
```ruby
ink_json_path = Rails.root.join('app/assets/scenarios', scenario_name, 'ink', "#{npc_id}.ink.json")
```

**After:**
```ruby
# Check both .json and .ink.json patterns
json_path = Rails.root.join('app/assets/scenarios', scenario_name, 'ink', "#{npc_id}.json")
ink_json_path = Rails.root.join('app/assets/scenarios', scenario_name, 'ink', "#{npc_id}.ink.json")

compiled_path = File.exist?(ink_json_path) ? ink_json_path : json_path
next unless File.exist?(compiled_path)

npc_script.ink_compiled = File.read(compiled_path)
```

---

## Issue #2: Scenario-NPC Relationship (Shared NPCs)

**Severity:** 🟠 HIGH - Will cause seed failures and data duplication
**Phase Impact:** Phase 4 (Database), Phase 5 (Seeds)
**Effort to Fix:** 3-5 hours

### Problem Description

The database schema assumes **1:1 relationship** between scenarios and NPCs:

**Current Schema:**
```ruby
create_table :break_escape_npc_scripts do |t|
  t.references :scenario, null: false
  t.string :npc_id, null: false
  t.index [:scenario_id, :npc_id], unique: true  # ← Assumes unique per scenario
end
```

**Actual Codebase:**
Many NPCs are **shared across scenarios**:

```
scenarios/ink/test-npc.json → Used in 10+ test scenarios
scenarios/ink/generic-npc.json → Reusable helper NPC
scenarios/ink/haxolottle_hub.json → Shared across hub scenarios
```

From grep analysis:
```
scenarios/test-npc-face-player.json: Uses test-npc.json (10 times)
scenarios/npc-hub-demo-ghost-protocol.json: Uses netherton_hub.json, chen_hub.json, haxolottle_hub.json
```

### Impact

**Database Constraint Violation:**
- Seed script will try to create same NPC for multiple scenarios
- Unique index will fail on second scenario
- OR: Wasteful duplication (same script stored 10+ times)

**Example Failure:**
```ruby
# Scenario 1: test-npc-face-player
NpcScript.create!(scenario_id: 1, npc_id: 'test_npc', ink_compiled: '...')  # ✓ Success

# Scenario 2: test-npc-pathfinding
NpcScript.create!(scenario_id: 2, npc_id: 'test_npc', ink_compiled: '...')  # ✓ Success (duplicate!)

# Result: Same script stored twice, 2x database usage
```

### Required Fixes

#### Option A: Allow Shared NPCs (Recommended)

**Update Schema:**
```ruby
create_table :break_escape_npc_scripts do |t|
  t.string :npc_id, null: false  # Remove scenario_id FK
  t.text :ink_source
  t.text :ink_compiled, null: false
  t.timestamps

  t.index :npc_id, unique: true  # Global NPC registry
end

# New join table for scenario-npc relationships
create_table :break_escape_scenario_npcs do |t|
  t.references :scenario, null: false, foreign_key: { to_table: :break_escape_scenarios }
  t.references :npc_script, null: false, foreign_key: { to_table: :break_escape_npc_scripts }
  t.timestamps

  t.index [:scenario_id, :npc_script_id], unique: true
end
```

**Pros:**
- Eliminates duplication
- Matches actual codebase usage
- Easier to update shared NPCs globally

**Cons:**
- Slightly more complex queries
- Migration plan needs updating

#### Option B: Namespace NPCs per Scenario

Keep current schema, but change seed logic:

```ruby
npc_script_id = "#{scenario_name}_#{npc_id}"  # e.g., "ceo_exfil_security_guard"
```

**Pros:**
- Minimal schema changes
- Simple implementation

**Cons:**
- Duplicates shared NPCs across scenarios
- Harder to update global NPCs
- Wastes database space

### Recommendation

**Use Option A** - The join table approach is more correct and matches the actual sharing patterns in the codebase.

---

## Issue #3: Missing Ink Compilation Pipeline

**Severity:** 🔴 CRITICAL - NPCs won't function without compiled scripts
**Phase Impact:** Phase 2-5
**Effort to Fix:** 4-6 hours

### Problem Description

The plan doesn't document:
1. How to compile `.ink` files to `.json`
2. Where compilation happens (local dev? CI? deployment?)
3. How to handle ERB + Ink compilation together
4. Version control for compiled files

### Current State

**What exists:**
- 30 `.ink` source files
- 3-5 compiled `.json` files
- No documented compilation process
- No Rakefile tasks for compilation

**What's missing:**
- Ink compiler installation instructions
- Automated compilation workflow
- Integration with Rails asset pipeline
- CI/CD compilation step

### Impact

**Without compilation:**
```ruby
# Phase 5 seed will fail:
npc_script.ink_compiled = File.read(ink_json_path)
# Error: File not found (never compiled)
```

**Runtime impact:**
```javascript
// Client tries to load NPC script
const script = await fetch('/api/games/123/npcs/security_guard/script');
// Returns empty/null - game breaks
```

### Required Fixes

#### Fix 1: Add Compilation Documentation

**New Section in 02_IMPLEMENTATION_PLAN.md:**

```markdown
## Phase 2.5: Compile Ink Scripts (Week 1)

### Prerequisites

Install Ink compiler:
```bash
# Option A: Via npm
npm install -g inkjs
npm install -g inklecate-cli

# Option B: Download binary
wget https://github.com/inkle/ink/releases/download/v1.1.1/inklecate_linux.zip
unzip inklecate_linux.zip
chmod +x inklecate
sudo mv inklecate /usr/local/bin/
```

### Compile All Scripts

```bash
# Create compilation script
cat > scripts/compile_ink.sh << 'EOF'
#!/bin/bash
for ink_file in scenarios/ink/*.ink; do
  base=$(basename "$ink_file" .ink)
  json_out="scenarios/ink/${base}.json"

  # Skip if up-to-date
  if [ -f "$json_out" ] && [ "$json_out" -nt "$ink_file" ]; then
    echo "✓ $base.json is up to date"
    continue
  fi

  echo "Compiling $base.ink..."
  inklecate -o "$json_out" "$ink_file"

  if [ $? -eq 0 ]; then
    echo "  ✓ Compiled to $base.json"
  else
    echo "  ✗ Compilation failed"
    exit 1
  fi
done
EOF

chmod +x scripts/compile_ink.sh
./scripts/compile_ink.sh
```

**Commit:**
```bash
git add scenarios/ink/*.json scripts/compile_ink.sh
git commit -m "feat: Add Ink compilation script and compile all NPCs"
```
```

#### Fix 2: Add Rake Task

```ruby
# lib/tasks/ink.rake
namespace :break_escape do
  namespace :ink do
    desc "Compile all .ink files to .json"
    task :compile do
      require 'open3'

      ink_dir = Rails.root.join('app/assets/scenarios')
      compiled = 0
      failed = 0

      Dir.glob(ink_dir.join('**/*.ink')).each do |ink_file|
        json_file = ink_file.gsub(/\.ink$/, '.json')

        # Skip if up-to-date
        next if File.exist?(json_file) && File.mtime(json_file) > File.mtime(ink_file)

        puts "Compiling #{File.basename(ink_file)}..."
        stdout, stderr, status = Open3.capture3("inklecate", "-o", json_file, ink_file)

        if status.success?
          compiled += 1
          puts "  ✓ Compiled"
        else
          failed += 1
          puts "  ✗ Failed: #{stderr}"
        end
      end

      puts "\n✓ Compiled #{compiled} files"
      puts "✗ Failed #{failed} files" if failed > 0
    end

    desc "Watch .ink files and auto-compile on changes"
    task :watch do
      require 'listen'

      puts "👀 Watching for .ink file changes..."

      listener = Listen.to(Rails.root.join('app/assets/scenarios'), only: /\.ink$/) do |modified, added, removed|
        (modified + added).each do |file|
          Rake::Task['break_escape:ink:compile'].execute
        end
      end

      listener.start
      sleep
    end
  end
end
```

#### Fix 3: Add to Deployment Pipeline

**Heroku/Production:**
```ruby
# config/initializers/break_escape.rb (after engine initialization)
if Rails.env.production? && !ENV['SKIP_INK_COMPILE']
  Rails.logger.info "Compiling Ink scripts for production..."
  Rake::Task['break_escape:ink:compile'].invoke
end
```

**CI/CD (.github/workflows/test.yml):**
```yaml
- name: Compile Ink scripts
  run: |
    npm install -g inklecate-cli
    bundle exec rake break_escape:ink:compile
```

---

## Issue #4: Incomplete Global State Tracking

**Severity:** 🟡 MEDIUM - State loss, potential bugs
**Phase Impact:** Phase 4 (Schema), Phase 9 (Client)
**Effort to Fix:** 1-2 hours

### Problem Description

The `player_state` JSONB schema doesn't include all fields from `window.gameState`:

**Plan Schema:**
```json
{
  "currentRoom": "...",
  "position": {"x": 0, "y": 0},
  "unlockedRooms": [],
  "unlockedObjects": [],
  "inventory": [],
  "encounteredNPCs": [],
  "globalVariables": {}
}
```

**Actual window.gameState (js/main.js:46):**
```javascript
window.gameState = {
  biometricSamples: [],        // ← MISSING
  biometricUnlocks: [],        // ← MISSING
  bluetoothDevices: [],        // ← MISSING
  notes: [],                   // ← MISSING
  startTime: null              // ← MISSING
};
```

### Impact

**Data Loss:**
- Player collects biometric samples → Lost on page reload
- Player scans Bluetooth devices → Lost on page reload
- Player reads notes → Lost on page reload

**Broken Minigames:**
- Biometrics minigame relies on `biometricSamples` array
- Bluetooth scanner relies on `bluetoothDevices` array
- Notes system relies on `notes` array

### Required Fix

**Update Migration (Phase 4):**
```ruby
t.jsonb :player_state, null: false, default: {
  currentRoom: nil,
  position: { x: 0, y: 0 },
  unlockedRooms: [],
  unlockedObjects: [],
  inventory: [],
  encounteredNPCs: [],
  globalVariables: {},

  # Add missing fields
  biometricSamples: [],    # { type: 'fingerprint', data: '...', source: '...' }
  biometricUnlocks: [],    # ['door_ceo', 'safe_123']
  bluetoothDevices: [],    # { name: '...', mac: '...', distance: ... }
  notes: [],               # { id: '...', title: '...', content: '...' }
  startTime: nil           # ISO8601 timestamp
}
```

**Update GameInstance Model:**
```ruby
def sync_minigame_state!(minigame_data)
  player_state['biometricSamples'] = minigame_data['biometricSamples'] if minigame_data['biometricSamples']
  player_state['bluetoothDevices'] = minigame_data['bluetoothDevices'] if minigame_data['bluetoothDevices']
  player_state['notes'] = minigame_data['notes'] if minigame_data['notes']
  save!
end
```

---

## Issue #5: Room Asset Loading Strategy Unclear

**Severity:** 🟡 MEDIUM - API design incomplete
**Phase Impact:** Phase 6 (API), Phase 9 (Client)
**Effort to Fix:** 2-3 hours

### Problem Description

The plan's API design doesn't clarify how Tiled map JSON files are served.

**Current Codebase (js/core/game.js:32):**
```javascript
// Phaser loads Tiled maps directly
this.load.tilemapTiledJSON('room_reception', 'assets/rooms/room_reception2.json');
this.load.tilemapTiledJSON('room_office', 'assets/rooms/room_office2.json');
```

**Plan's API (01_ARCHITECTURE.md:494):**
```
GET /api/games/:game_id/rooms/:room_id

Response:
{
  "roomId": "room_office",
  "type": "office",
  "connections": {...},
  "objects": [...]
}
```

**Confusion:**
- Does API return Tiled map JSON or filtered game data?
- Where do Tiled `.json` files live after migration?
- How does Phaser load Tiled maps (static assets vs API)?

### Current Structure

```
assets/rooms/
├── room_reception2.json    (Tiled map)
├── room_office2.json        (Tiled map)
├── room_ceo2.json           (Tiled map)
...

scenarios/ceo_exfil.json     (Game logic: objects, NPCs, locks)
```

**Two different data structures:**
1. **Tiled maps** (.json) - Visual layout, tiles, collision layers
2. **Scenario data** (.json) - Game objects, locks, NPCs, connections

### Required Clarification

**Recommended Approach:**

1. **Keep Tiled maps as static assets:**
```bash
# Move to public/break_escape/
mv assets/rooms public/break_escape/assets/
```

2. **API returns game logic only:**
```ruby
def show
  room_data = @game_instance.scenario.filtered_room_data(params[:room_id])

  render json: {
    roomId: params[:room_id],

    # Game logic (from scenario)
    connections: room_data['connections'],
    objects: room_data['objects'],
    npcs: room_data['npcs'],
    locked: room_data['locked'],

    # Tiled map reference (loaded separately by Phaser)
    tiledMap: room_data['type']  # e.g., 'room_reception'
  }
end
```

3. **Client loads both:**
```javascript
// 1. Load Tiled map (static asset)
this.load.tilemapTiledJSON(roomData.tiledMap, `/break_escape/assets/rooms/${roomData.tiledMap}.json`);

// 2. Load game logic (API)
const gameData = await apiGet(`/rooms/${roomId}`);
```

---

## Summary of Required Fixes

| Issue | Severity | Phase | Effort | Priority |
|-------|----------|-------|--------|----------|
| #1: Ink file structure | 🔴 Critical | 3, 5 | 2-4h | P0 |
| #2: Shared NPCs | 🟠 High | 4, 5 | 3-5h | P0 |
| #3: Ink compilation | 🔴 Critical | 2-5 | 4-6h | P0 |
| #4: Global state | 🟡 Medium | 4, 9 | 1-2h | P1 |
| #5: Room assets | 🟡 Medium | 6, 9 | 2-3h | P1 |

**Total Effort:** 12-20 hours (1.5-2.5 days)

**Risk if Not Fixed:** Implementation will fail at Phase 3 and require rework.

---

**Next Document:** [02_ARCHITECTURE_REVIEW.md](./02_ARCHITECTURE_REVIEW.md) - Validation of technical design decisions
