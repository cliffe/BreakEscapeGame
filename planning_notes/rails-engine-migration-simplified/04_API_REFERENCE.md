# API Reference

Complete API documentation for BreakEscape Rails Engine.

---

## Base URL

When mounted in Hacktivity:
```
https://hacktivity.com/break_escape
```

When running standalone:
```
http://localhost:3000/break_escape
```

---

## Authentication

All API endpoints use **session-based authentication** via Rails cookies.

### Headers Required

```http
Cookie: _session_id=...           # Rails session cookie (set by Devise)
X-CSRF-Token: <token>             # CSRF token (from form_authenticity_token)
Content-Type: application/json    # For POST/PUT requests
Accept: application/json          # For JSON responses
```

### Getting CSRF Token

The token is available in the game view:

```javascript
const csrfToken = window.breakEscapeConfig.csrfToken;
// or
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
```

---

## Endpoints

### 1. GET /missions

Get list of available missions (scenarios).

**URL:** `/break_escape/missions`

**Method:** `GET`

**Auth:** None required

**Query Parameters:** None

**Response:**

```json
HTTP/1.1 200 OK
Content-Type: text/html

<!-- Renders missions/index.html.erb -->
```

**HTML Response includes:**
- List of published missions
- Mission cards with title, description, difficulty

**Usage:**

```bash
curl https://hacktivity.com/break_escape/missions
```

---

### 2. GET /missions/:id

Select a mission and create/find game instance.

**URL:** `/break_escape/missions/:id`

**Method:** `GET`

**Auth:** Required (current_user or current_player)

**Parameters:**
- `id` (path) - Mission ID

**Response:**

```json
HTTP/1.1 302 Found
Location: /break_escape/games/123
```

**Behavior:**
- Finds or creates game instance for current player
- Redirects to game show page

**Usage:**

```bash
curl -X GET https://hacktivity.com/break_escape/missions/1 \
  -H "Cookie: _session_id=..."
```

---

### 3. GET /games/:id

Show game view (HTML page with Phaser game).

**URL:** `/break_escape/games/:id`

**Method:** `GET`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID

**Response:**

```html
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
  <head>
    <title>Mission Name - BreakEscape</title>
    <!-- Game CSS -->
  </head>
  <body>
    <div id="break-escape-game"></div>
    <script nonce="...">
      window.breakEscapeConfig = {
        gameId: 123,
        apiBasePath: '/break_escape/games/123',
        csrfToken: '...'
      };
    </script>
    <!-- Game JS -->
  </body>
</html>
```

**Usage:**

```bash
curl https://hacktivity.com/break_escape/games/123 \
  -H "Cookie: _session_id=..."
```

---

### 4. GET /games/:id/scenario

Get scenario JSON for this game instance.

**URL:** `/break_escape/games/:id/scenario`

**Method:** `GET`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID

**Response:**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "scenarioName": "CEO Exfiltration",
  "scenarioBrief": "Gather evidence of insider trading",
  "startRoom": "reception",
  "rooms": {
    "reception": {
      "type": "room_reception",
      "connections": {
        "north": "office"
      },
      "locked": false,
      "objects": [
        {
          "type": "desk",
          "name": "Reception Desk",
          "observations": "A tidy desk with a computer monitor"
        }
      ]
    },
    "office": {
      "type": "room_office",
      "connections": {
        "south": "reception"
      },
      "locked": true,
      "objects": []
    }
  },
  "npcs": [
    {
      "id": "security_guard",
      "displayName": "Security Guard",
      "storyPath": "scenarios/ink/security-guard.json",
      "npcType": "person"
    }
  ]
}
```

**Important Notes:**
- Scenario is **ERB-generated** when game instance was created
- Each game has **unique passwords/pins**
- Solutions are **included** (server-side only, not sent to client via filtered endpoints)
- This endpoint returns the **complete** scenario (use with care)

**Usage:**

```javascript
const scenario = await ApiClient.getScenario();
```

```bash
curl https://hacktivity.com/break_escape/games/123/scenario \
  -H "Cookie: _session_id=..." \
  -H "Accept: application/json"
```

---

### 5. GET /games/:id/ink

Get NPC Ink script (JIT compiled if needed).

**URL:** `/break_escape/games/:id/ink?npc=<npc_id>`

**Method:** `GET`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID
- `npc` (query) - NPC identifier

**Response:**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "inkVersion": 21,
  "root": [
    ["^Hello there! I'm the security guard.", "\n"],
    ["^What brings you here?", "\n"],
    ["ev", "str", "^Ask about access", "/str", "/ev", {"->": ".^.c", "c": true}],
    ["ev", "str", "^Goodbye", "/str", "/ev", {"->": ".^.c", "c": true}]
  ],
  "listDefs": {}
}
```

**Behavior:**
- Checks if NPC exists in game's scenario_data
- Looks for .ink source file
- Compiles .ink → .json if:
  - .json doesn't exist, OR
  - .ink is newer than .json
- Compilation takes ~300ms (cached thereafter)
- Returns compiled Ink JSON

**Error Responses:**

```json
// Missing npc parameter
HTTP/1.1 400 Bad Request
{"error": "Missing npc parameter"}

// NPC not in scenario
HTTP/1.1 404 Not Found
{"error": "NPC not found in scenario"}

// Ink file not found
HTTP/1.1 404 Not Found
{"error": "Ink script not found"}

// Compilation failed
HTTP/1.1 500 Internal Server Error
{"error": "Invalid JSON in compiled ink: ..."}
```

**Usage:**

```javascript
const inkScript = await ApiClient.getNPCScript('security_guard');
```

```bash
curl "https://hacktivity.com/break_escape/games/123/ink?npc=security_guard" \
  -H "Cookie: _session_id=..." \
  -H "Accept: application/json"
```

---

### 6. GET /games/:id/bootstrap

Get initial game data for client.

**URL:** `/break_escape/games/:id/bootstrap`

**Method:** `GET`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID

**Response:**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "gameId": 123,
  "missionName": "CEO Exfiltration",
  "startRoom": "reception",
  "playerState": {
    "currentRoom": "reception",
    "unlockedRooms": ["reception"],
    "unlockedObjects": [],
    "inventory": [],
    "encounteredNPCs": [],
    "globalVariables": {},
    "biometricSamples": [],
    "biometricUnlocks": [],
    "bluetoothDevices": [],
    "notes": [],
    "health": 100
  },
  "roomLayout": {
    "reception": {
      "connections": {"north": "office"},
      "locked": false
    },
    "office": {
      "connections": {"south": "reception"},
      "locked": true
    }
  }
}
```

**Important:**
- `roomLayout` includes connections and locked status
- `roomLayout` does **NOT** include lockType or requires (solutions hidden)
- `playerState` includes all current progress
- Use this to initialize client game state

**Usage:**

```javascript
const gameData = await ApiClient.bootstrap();
```

```bash
curl https://hacktivity.com/break_escape/games/123/bootstrap \
  -H "Cookie: _session_id=..." \
  -H "Accept: application/json"
```

---

### 7. PUT /games/:id/sync_state

Sync player state to server.

**URL:** `/break_escape/games/:id/sync_state`

**Method:** `PUT`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID

**Request Body:**

```json
{
  "currentRoom": "office",
  "globalVariables": {
    "alarm_triggered": false,
    "player_favor": 5
  }
}
```

**Response:**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true
}
```

**Behavior:**
- Updates `player_state.currentRoom` if provided
- Merges `globalVariables` into `player_state.globalVariables`
- Does NOT validate - trusts client for these fields
- Saves to database

**Usage:**

```javascript
await ApiClient.syncState('office', {
  alarm_triggered: false,
  player_favor: 5
});
```

```bash
curl -X PUT https://hacktivity.com/break_escape/games/123/sync_state \
  -H "Cookie: _session_id=..." \
  -H "X-CSRF-Token: ..." \
  -H "Content-Type: application/json" \
  -d '{
    "currentRoom": "office",
    "globalVariables": {
      "alarm_triggered": false
    }
  }'
```

---

### 8. POST /games/:id/unlock

Validate unlock attempt (server-side).

**URL:** `/break_escape/games/:id/unlock`

**Method:** `POST`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID

**Request Body:**

```json
{
  "targetType": "door",
  "targetId": "office",
  "attempt": "password123",
  "method": "password"
}
```

**Parameters:**
- `targetType` (string) - "door" or "object"
- `targetId` (string) - Room ID or object ID
- `attempt` (string) - Password, PIN, or key ID
- `method` (string) - "password", "pin", "key", or "lockpick"

**Response (Success - Door):**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "type": "door",
  "roomData": {
    "type": "room_office",
    "connections": {"south": "reception"},
    "objects": [...]
  }
}
```

**Response (Success - Object):**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "type": "object"
}
```

**Response (Failure):**

```json
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "success": false,
  "message": "Invalid attempt"
}
```

**Behavior:**
- Validates attempt against scenario_data (solutions)
- For passwords/pins: Compares string match
- For keys: Compares key ID
- For lockpick: Always succeeds (client minigame already validated)
- If valid:
  - Updates player_state (adds to unlockedRooms or unlockedObjects)
  - Returns filtered room/object data (no solutions)
- If invalid:
  - Returns error, no state change

**Usage:**

```javascript
const result = await ApiClient.unlock('door', 'office', 'admin123', 'password');
if (result.success) {
  // Unlock succeeded
  console.log('Room unlocked!', result.roomData);
} else {
  // Invalid password
  console.log('Failed:', result.message);
}
```

```bash
curl -X POST https://hacktivity.com/break_escape/games/123/unlock \
  -H "Cookie: _session_id=..." \
  -H "X-CSRF-Token: ..." \
  -H "Content-Type: application/json" \
  -d '{
    "targetType": "door",
    "targetId": "office",
    "attempt": "admin123",
    "method": "password"
  }'
```

---

### 9. POST /games/:id/inventory

Update player inventory.

**URL:** `/break_escape/games/:id/inventory`

**Method:** `POST`

**Auth:** Required (must be game owner or admin)

**Parameters:**
- `id` (path) - Game instance ID

**Request Body (Add Item):**

```json
{
  "action": "add",
  "item": {
    "type": "key",
    "name": "Office Key",
    "key_id": "office_key_1",
    "takeable": true
  }
}
```

**Request Body (Remove Item):**

```json
{
  "action": "remove",
  "item": {
    "id": "office_key_1"
  }
}
```

**Response:**

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "inventory": [
    {
      "type": "key",
      "name": "Office Key",
      "key_id": "office_key_1",
      "takeable": true
    }
  ]
}
```

**Error Response:**

```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "success": false,
  "message": "Invalid action"
}
```

**Behavior:**
- `add`: Appends item to player_state.inventory
- `remove`: Removes item with matching ID from inventory
- No validation (trusts client)
- Returns updated inventory array

**Usage:**

```javascript
// Add item
await ApiClient.updateInventory('add', {
  type: 'key',
  name: 'Office Key',
  key_id: 'office_key_1'
});

// Remove item
await ApiClient.updateInventory('remove', { id: 'office_key_1' });
```

```bash
curl -X POST https://hacktivity.com/break_escape/games/123/inventory \
  -H "Cookie: _session_id=..." \
  -H "X-CSRF-Token: ..." \
  -H "Content-Type: application/json" \
  -d '{
    "action": "add",
    "item": {
      "type": "key",
      "name": "Office Key"
    }
  }'
```

---

## Error Responses

### Standard Error Format

```json
{
  "error": "Error message here"
}
```

### HTTP Status Codes

| Code | Meaning | When |
|------|---------|------|
| 200 | OK | Successful request |
| 302 | Found | Redirect (e.g., mission → game) |
| 400 | Bad Request | Missing required parameters |
| 401 | Unauthorized | Not logged in |
| 403 | Forbidden | Not authorized (Pundit) |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable Entity | Validation failed (e.g., invalid password) |
| 500 | Internal Server Error | Server error (e.g., compilation failed) |

---

## Rate Limiting

Currently **no rate limiting** is implemented. Consider adding in production:

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/break_escape/games/')
end
```

---

## API Client (JavaScript)

### Installation

The API client is provided in `public/break_escape/js/api-client.js`.

### Usage

```javascript
import { ApiClient } from './api-client.js';

// Bootstrap
const gameData = await ApiClient.bootstrap();

// Get scenario
const scenario = await ApiClient.getScenario();

// Get NPC script
const inkScript = await ApiClient.getNPCScript('security_guard');

// Unlock
const result = await ApiClient.unlock('door', 'office', 'password123', 'password');

// Update inventory
await ApiClient.updateInventory('add', { type: 'key', name: 'Office Key' });

// Sync state
await ApiClient.syncState('office', { alarm_triggered: false });
```

### Error Handling

```javascript
try {
  const result = await ApiClient.unlock('door', 'office', 'wrong', 'password');
  if (!result.success) {
    console.log('Invalid password');
  }
} catch (error) {
  console.error('API error:', error);
  // Network error, server error, etc.
}
```

---

## Security Considerations

### Authentication
- All endpoints require valid Rails session
- Uses Devise for authentication
- Session cookies are HTTPOnly and Secure

### Authorization
- Pundit policies enforce ownership
- Players can only access their own games
- Admins can access all games

### CSRF Protection
- All POST/PUT/DELETE requests require CSRF token
- Token embedded in game view
- Verified by Rails on each request

### Data Validation
- Unlock attempts validated server-side
- Solutions never sent to client
- Room data filtered before sending

### What's NOT Validated
- Player position (client-side only)
- Global variables (trusted)
- Inventory additions (trusted)

**Rationale:** Balance security with simplicity. Critical game-breaking actions (unlocks) are validated. Non-critical state (position, variables) is trusted for performance.

---

## Debugging

### Enable Detailed Logging

```ruby
# config/environments/development.rb
config.log_level = :debug

# View logs
tail -f log/development.log | grep BreakEscape
```

### Common Debug Points

```ruby
# In controllers
Rails.logger.debug "[BreakEscape] Game: #{@game.inspect}"

# In models
Rails.logger.debug "[BreakEscape] Unlocking: #{room_id}"

# JIT compilation
Rails.logger.info "[BreakEscape] Compiling #{ink_file}"
```

### Test API with curl

```bash
# Get CSRF token first
TOKEN=$(curl -c cookies.txt http://localhost:3000/break_escape/games/1 | grep csrf-token | sed 's/.*content="\([^"]*\)".*/\1/')

# Use token in POST
curl -X POST http://localhost:3000/break_escape/games/1/unlock \
  -b cookies.txt \
  -H "X-CSRF-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"targetType":"door","targetId":"office","attempt":"test","method":"password"}'
```

---

## API Changelog

### v1.0.0 (Initial Release)
- All endpoints implemented
- JIT Ink compilation
- ERB scenario generation
- Polymorphic player support
- Session-based authentication

---

## Support

For issues or questions:
- Check implementation plan
- Review controller code
- Check Rails logs
- Refer to this API reference

---

**Complete API documentation for BreakEscape Rails Engine**
