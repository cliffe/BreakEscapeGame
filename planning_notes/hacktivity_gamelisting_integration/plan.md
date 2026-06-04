# GameSlot Integration Plan
## BreakEscape × Hacktivity
### Revision 7 — VmSetActivationService extraction

**Changes from Revision 6:** Extracted `VmSetsController#activate` private method to `VmSetActivationService` (Phase 2.6–2.9). `GameSlotsController#extend_vms` now delegates to the same service — all activation guards (`build_status`, concurrent quota, Proxmox node selection, timer logic) are shared and cannot drift between the two controllers. Updated `extend_vms` code block (removes inline guards and the generic `"activate"` command; handles oVirt `start_vms: true` path explicitly). Updated file change summary. Removed the "must replicate verbatim" note from Phase 4.4.1 — it is no longer needed.

**Changes from Revision 5 (carried forward):** Eager VM activation deferred to Phase 2; MVP is lazy-only (resolves IMPL-v4-1 double-render). Added `@game.reload.status == 'in_progress'` guard in `vm_panel` before `enable_console` unlock to prevent stale unlocks after a concurrent restart (ARCH-v4-4). Added nil-guard for `sec_gen_batch.event` in `vm_panel` and `vm_set_panel` (IMPL-v4-4). Added `vmActivationMode` injection to `window.breakEscapeConfig` (IMPL-v4-6). Changed Phaser HUD CSRF token source to `window.breakEscapeConfig.csrfToken` (IMPL-v4-7). Added `get :vm_set_panel` route to Phase 1.6 to avoid ERB `NoMethodError` before Phase 4.4.3 (IMPL-v4-9). Moved all `vm_panel`/`vm_set_panel` controller tests to Hacktivity suite (TEST-v4-1). Added `BreakEscape::GamePolicy#vm_panel?`/`vm_set_panel?` unit tests and policy methods (ARCH-v4-5, TEST-v4-3). Specified `enable_console: true` fixture baseline for reset tests (TEST-v4-4). Added embedded relinquish warning to `VmSetsController#show` partial (ARCH-v4-2). Added explicit `X-Frame-Options` `before_action` to `VmsController` and `VmSetsController` (ARCH-v4-6). Noted `extend_vms` must replicate all existing activation guards from `VmSetsController#activate` verbatim (ARCH-v4-3). Added `ActiveJob::EnqueueError` rescue to `finish` action with log-and-continue semantics (IMPL-v4-3). Added nil-guards to `GameCompletionScoringJob` to handle scoring-relinquish race (ARCH-v4-8). Deferred configurable `vm_panel_url_for` callbacks to Phase 2; noted in Known Limitations (ARCH-v4-1).

**Changes from Revision 4 (carried forward):** Both iframe surfaces use **existing** Hacktivity pages with `?embedded` — no new Hacktivity views or routes needed. vm-launcher embeds `VmsController#show`; VM HUD panel embeds `VmSetsController#show`. Gating is via `enable_console` (not URL params): game start locks all VMs to `enable_console: false`; hitting `vm_panel` in-game unlocks the specific VM; restart re-locks. Updated `finish` to call `RelinquishVmSetJob.perform_later` outside the transaction. Corrected `extend_vms` to replicate `activated_until` logic from `VmSetsController#activate`. Moved `Outcome` struct to class scope. Added CSRF header requirement for Phaser fetch calls. Fixed Hacktivity route URL format in Phase 4.4.2. Added `vmSetPanelUrl` alongside `vmPanelUrl` in `breakEscapeConfig`. Lazy activation UX handled natively by ActionCable in the VM page iframe. Route helper corrected: `sec_gen_batches` uses `path: "challenges"` alias.

**Changes from Revision 3 (carried forward):** Added per-mission `vm_activation_mode` enum (`eager`/`lazy`) on `BreakEscape::Mission`. Added VM lifecycle endpoints in Hacktivity (`vm_status`, `extend_vms`, `shutdown_vms`, `finish`). Added in-game Phaser VM HUD button specification. Updated `start` action to honour activation mode. Updated routes, policy, controller, file change summary, and smoke test checklist.

**Changes from Revision 2 (carried forward):** Targeted fixes for issues surfaced in v2 reviews. All original 31 findings resolved. This revision addresses: transaction control flow refactor (NF-1), `Result.find_or_create_by` placement (NF-3), `GameCompletionScoringJob` nil-guard + lock (NF-4), VM powered-down pre-condition in `restart` (Impl NF-1), `saved_change_to_status?` idiom (NF-2), `ownership_error` message format (Impl NF-3), GA4 `team_assignment` value (Impl NF-2), and test coverage gaps from the testing v2 review.

---

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Model name | `GameSlot` | Describes "a mission listed within an event" without clashing with `BreakEscape::Mission` |
| New event type | Add `game` to `type_of_hacktivity` enum | Clean separation; enables type-specific rendering |
| VM-free missions | Supported (`sec_gen_batch` optional on GameSlot) | `sec_gen_batch` nil = Game created without VmSet |
| Team support | Individual players only (initial scope) | Shared game state complexity deferred |
| Scoring | Game completion updates Result via vm_set.score (VM-backed only) | Reuses existing `Result#calculate`; VM-free scoring deferred |
| Batch visibility | `hidden_from_players` boolean on SecGenBatch | Allows same batch to be hidden VM pool or exposed challenge — UI only, not scoring |
| Restart scope | `in_progress` games only for initial release | Restarting `completed` games is out of scope; document as limitation |
| VM activation mode | Per-mission `vm_activation_mode` enum on `BreakEscape::Mission` (`eager`/`lazy`) | Eager = auto-activate all VMs on game start; Lazy = activate on first in-game VM interaction. Default: `eager` |
| Eager activation MVP scope | Deferred to Phase 2 | Both `eager` and `lazy` missions use lazy activation in MVP — VMs are activated on the player's first `requiresVM` interaction. The column and enum exist; true eager auto-start at game creation is Phase 2 work. |
| VM HUD | In-game Phaser button alongside music button; colour-coded icon; on-click panel with per-VM state, countdown, and lifecycle controls | Gives player VM visibility without leaving the game; avoids Hacktivity page re-visits during play |
| Cross-engine test strategy | Full integration (engine tables present in Hacktivity test DB) | Consistent with how both suites already work internally |

---

## Architecture

```
Hacktivity
  Event (type_of_hacktivity: game)
    has_many :game_slots
      GameSlot
        belongs_to :event
        belongs_to :break_escape_mission  → BreakEscape::Mission (FK enforced in Hacktivity migration)
        belongs_to :sec_gen_batch         → SecGenBatch (optional, nil = VM-free)
        position:   integer               (manual ordering; no acts_as_list gem)
        release_at: datetime              (optional; overrides event start for sequenced unlocks)

    has_many :sec_gen_batches             (hidden_from_players: true by default for game events)
      SecGenBatch
        has_one :game_slot
        hidden_from_players: boolean      (UI visibility only — does NOT affect Result scoring)
        has_many :vm_sets
          VmSet (flags loaded by ReadSecgenFlagsJob before assignment)

BreakEscape (engine, mounted at /break_escape)
  Mission (scenario definition)
    has_many :games
    has_many :game_slots (via defined?(::GameSlot) guard — dependent: :nullify)
    vm_activation_mode: string   ('eager' | 'lazy', default: 'eager')
                                 eager = auto-activate all VMs on game start
                                 lazy  = activate on first requiresVM interaction
  Game (player instance)
    belongs_to :mission
    belongs_to :player (polymorphic → Hacktivity User)
    vm_set_id: bigint column              (authoritative — set directly at creation)
    player_state JSONB incl. vm_set_id   (set at creation only; required by generate_scenario_data)
    UNIQUE partial index: (player_type, player_id, mission_id) WHERE status = 'in_progress'
```

### Starting a VM-Backed Mission (corrected flow)

```
User: "Start Mission"
  → POST /hacktivities/:event_id/missions/:id/start
  → GameSlotsController#start
      1. Authorize (signed up to event, listing available, org not revoked)
      2. Find existing active game via GameSlot#active_game_for (corrected query)
         → redirect to break_escape.game_path(existing_game) if found
      3. ApplicationRecord.transaction do
           a. VmSetAssignmentService.assign_to_user(sec_gen_batch:, user:, event:)
                → returns Struct{success, vm_set, error_message, redirect_key}
           b. On error: raise to abort transaction, flash error, redirect
           c. BreakEscape::Game.create!(player: user, mission: listing.mission,
                                        player_state: { 'vm_set_id' => vm_set.id })
                → before_create :sync_vm_set_id_column populates vm_set_id column
                → before_create :generate_scenario_data reads flags via vm_set_id
                → DB unique index prevents duplicate if race condition — rescue RecordNotUnique
         end
      4. Result.find_or_create_by(user: current_user, event: @event)  # enrol
      5. If mission.vm_activation_mode == 'eager':
           POST /game_slots/:id/extend_vms (inline call from start action)
           → activates VmSet immediately; sets activated_until
         If mission.vm_activation_mode == 'lazy':
           No activation here. The Phaser client detects the first requiresVM
           interaction and POSTs /game_slots/:id/extend_vms at that point.
      6. Ga4Service.track_event('mission_started', ...)
      7. redirect_to break_escape.game_path(game)
```

### Starting a VM-Free Mission

Same flow, step 3a–b skipped. `BreakEscape::Game.create!` called without `player_state` vm_set_id.

### Restarting a Mission (`in_progress` games only)

```
User: "Restart"
  → POST /hacktivities/:event_id/missions/:id/restart
  → GameSlotsController#restart
      1. Find active game via active_game_for (status: in_progress only)
         → flash error if none found
      2. If VM-backed:
           vm_set_id = game.vm_set_id || game.player_state&.dig('vm_set_id')
           vm_set = VmSet.find_by(id: vm_set_id)
           if vm_set
             vm_set.vms.each { |vm| DispatchVmCtrlService.ctrl_vm_async(vm, "revert_snapshot", "original") }
             flash[:notice] = "VM revert in progress. Please wait before reconnecting."
           end
      3. game.reset_player_state!   (preserves vm_set_id; status stays in_progress)
      4. redirect_to break_escape.game_path(game)
```

**Note:** Restarting a `completed` game is out of scope. `active_game_for` filters `status: 'in_progress'` only. Attempting to restart a completed game will hit the "no active game" error branch.

### Scoring Flow (VM-Backed)

- Flag solving in-game → `FlagService.process_flag` (already implemented in BreakEscape) → updates `vm.flags` → existing Result path
- Game completion (status → 'completed') → `on_game_complete` hook fires → enqueues `GameCompletionScoringJob` → Job sets `vm_set.score = 100.0` if not already scored → calls `result.calculate`
- `hidden_from_players` batches are included in `Result#calculate` (iterates all `event.sec_gen_batches`); this is correct and intentional — visibility does not affect scoring weight

---

## Pre-requisite: Mount the Engine

**Repo: Hacktivity** — This must be done before Phase 1 if not already done.

**`config/routes.rb`:**
```ruby
mount BreakEscape::Engine => "/break_escape"
```

All references to game paths in Hacktivity use the **mounted proxy form**: `break_escape.game_path(game)`. Do NOT use `break_escape_game_path(game)` (that form requires `include BreakEscape::Engine.routes.url_helpers` and risks collisions with host helpers).

---

## Phase 0 — Baseline Tests

**Both repos.** Run before any changes. Record any pre-existing failures.

```bash
# Hacktivity
cd /path/to/Hacktivity && rails test

# BreakEscape
cd /path/to/BreakEscape && rails test
```

---

## Phase 1 — BreakEscape Engine Changes

**Repo: BreakEscape**

### 1.1 — Add `vm_set_id` Column + Partial Unique Index + Backfill

**Migration** (`db/migrate/TIMESTAMP_add_vm_set_id_to_break_escape_games.rb`):
```ruby
class AddVmSetIdToBreakEscapeGames < ActiveRecord::Migration[7.0]
  def change
    add_column :break_escape_games, :vm_set_id, :bigint
    add_index  :break_escape_games, :vm_set_id

    # Race-condition guard: only one in_progress game per player+mission
    add_index :break_escape_games,
              [:player_type, :player_id, :mission_id],
              unique: true,
              where: "status = 'in_progress'",
              name: 'idx_break_escape_games_one_active_per_player_mission'

    # Backfill existing rows from JSONB player_state
    # Safety: update_columns bypasses callbacks and validations
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE break_escape_games
          SET vm_set_id = (player_state->>'vm_set_id')::bigint
          WHERE vm_set_id IS NULL
            AND player_state->>'vm_set_id' IS NOT NULL
        SQL
      end
    end
  end
end
```

**Model update** (`app/models/break_escape/game.rb`):
```ruby
before_create :sync_vm_set_id_column

def sync_vm_set_id_column
  self.vm_set_id ||= player_state&.dig('vm_set_id')&.to_i
end
```

`player_state['vm_set_id']` must still be set at game creation time because `generate_scenario_data` (a `before_create` callback in the engine) reads it to build the VM/flag context for the scenario ERB template. After creation, all code reads from the `vm_set_id` column directly — no JSONB fallback.

### 1.2 — Game Completion Callback Hook

Add a configurable `on_game_complete` hook. The engine fires it; Hacktivity configures it.

**`lib/break_escape.rb`:**
```ruby
module BreakEscape
  class Configuration
    attr_accessor :on_game_complete   # callable: ->(game) { ... }, or nil
  end
end
```

**`app/models/break_escape/game.rb`:**
```ruby
after_commit :fire_completion_callback, if: :status_previously_changed_to_completed?

private

def status_previously_changed_to_completed?
  # Use the `to:` form — immune to attribute mutation between save and commit.
  # `saved_change_to_status? && status == 'completed'` is fragile if anything
  # touches `status` between the save and the after_commit firing.
  saved_change_to_status?(to: 'completed')
end

def fire_completion_callback
  return unless BreakEscape.config.on_game_complete
  BreakEscape.config.on_game_complete.call(self)
rescue => e
  # Scoring failure must never roll back or suppress game completion.
  Rails.logger.error "[BreakEscape] on_game_complete hook raised: #{e.class}: #{e.message}"
end
```

Key points:
- Uses `after_commit` (not `after_save`) so the game record is fully persisted before the hook fires — prevents the hook from running inside an open transaction and allows enqueuing jobs safely
- `rescue` guard ensures a scoring failure cannot affect the game's completed status
- `return` (not `next`) as control flow exit

### 1.3 — `BreakEscape::Mission` Guard for `GameSlot` Association

**`app/models/break_escape/mission.rb`:**
```ruby
if defined?(::GameSlot)
  has_many :game_slots,
           class_name: '::GameSlot',
           foreign_key: :break_escape_mission_id,
           dependent: :nullify
end
```

This prevents orphaned `GameSlot` rows if a Mission is deleted. The guard keeps the engine deployable standalone without Hacktivity's tables.

### 1.4 — Add `vm_activation_mode` to `BreakEscape::Mission`

**Migration** (`db/migrate/TIMESTAMP_add_vm_activation_mode_to_break_escape_missions.rb`):
```ruby
class AddVmActivationModeToBreakEscapeMissions < ActiveRecord::Migration[7.0]
  def change
    add_column :break_escape_missions, :vm_activation_mode, :string,
               default: 'eager', null: false
  end
end
```

**Model update** (`app/models/break_escape/mission.rb`):
```ruby
VM_ACTIVATION_MODES = %w[eager lazy].freeze

validates :vm_activation_mode, inclusion: { in: VM_ACTIVATION_MODES }
```

`eager` (default): `GameSlotsController#start` activates VMs immediately after game creation by calling the `extend_vms` service inline.

`lazy`: VMs are assigned and built, but NOT activated at game start. The Phaser client fires `extend_vms` when the player first touches an interaction tagged `requiresVM`. This defers the clock until the player is ready.

### 1.5 — Tests (BreakEscape)

**`test/models/break_escape/game_test.rb`** — add:
- `vm_set_id` column populated from player_state on `before_create`
- `vm_set_id` column not overwritten if already set
- `fire_completion_callback` called on `after_commit` when status changes to 'completed'
- `fire_completion_callback` NOT called when status changes to non-completed values
- `fire_completion_callback` NOT called when other attributes change
- A callback that raises does NOT prevent game from being saved (rescue guard test)
- Nil config (`on_game_complete = nil`) does not raise

### 1.7 — Tests: `vm_panel` and `vm_set_panel`

**Note (TEST-v4-1):** All `vm_panel` and `vm_set_panel` controller tests live in the **Hacktivity suite** (`test/controllers/game_slots_controller_test.rb` and a new `test/controllers/break_escape/games_controller_test.rb` within Hacktivity). They are not placed in the BreakEscape engine's own test suite because the engine's `test/dummy/` app does not include `VmSet` or `Vm` models — the happy-path logic in both actions cannot be exercised there.

**Policy unit tests** (engine suite — these have no model dependencies):

**`test/policies/break_escape/game_policy_test.rb`** — add:

- `vm_panel?` — owner with `status: 'in_progress'` → `true`
- `vm_panel?` — non-owner (different user, same game id) → `false`
- `vm_panel?` — admin → `true`
- `vm_panel?` — owner with `status: 'completed'` → `false`
- `vm_set_panel?` — owner with `status: 'in_progress'` → `true`
- `vm_set_panel?` — non-owner → `false`
- `vm_set_panel?` — admin → `true`
- `vm_set_panel?` — owner with `status: 'completed'` → `false`

**Engine `games_controller_test.rb` — engine-safe assertions only (assert_response :redirect or :not_found):**

In standalone mode (`hacktivity_mode? = false`), both actions should return 404 — this is testable in the engine without Hacktivity models.

- `vm_panel` in standalone mode (`hacktivity_mode?` returns false) → 404
- `vm_set_panel` in standalone mode → 404

Full functional, authentication, authorisation, and redirect URL assertions are in Phase 4.6 (Hacktivity suite).

**Run tests** after Phase 1 before proceeding.

### 1.6 — vm-launcher Minigame: Hacktivity Mode Integration

**Repo: BreakEscape**

When a game is played inside Hacktivity (i.e. `BreakEscape::Mission.hacktivity_mode?` is true), the vm-launcher minigame should load Hacktivity's **individual VM page** in an iframe rather than showing its own inline message or building a custom panel. This page (rendered via Hacktivity's existing `VmsController#show`) provides everything the player needs for that specific VM: VNC browser console, SPICE console download, power controls, and flag submission. Crucially, it includes ActionCable subscriptions that push live VM state updates — so when the player first touches a terminal on a lazy-activation mission and VMs begin spinning up, the iframe updates in real time without any extra plumbing.

**Two-surface split:** The vm-launcher minigame shows the *individual* VM endpoint. The *VM HUD panel* (Phase 4.4.3) shows a separate Hacktivity vm_set controls partial for higher-level set management (activate, extend, relinquish). These are two distinct iframes serving different purposes.

#### 1.6.1 — `GET /break_escape/games/:id/vm_panel` route (engine)

Add a new member route on `games`:

```ruby
get 'vm_panel'
```

Add `vm_panel` to the `set_game` before_action filter. The action:

```ruby
# GET /games/:id/vm_panel?vm_title=:title
# Redirects to the Hacktivity individual VM show page for the named VM in this game's VmSet,
# with ?embedded=1 so Hacktivity's application layout hides navigation and footer.
# The minigame loads this in an iframe — Bootstrap/jQuery/ActionCable (VNC, live state updates)
# are all present natively. ActionCable pushes VM state changes in real time, so the player
# sees the VM spinning up on lazy-activation missions without any extra client-side work.
def vm_panel
  authorize @game if defined?(Pundit)
  return head :not_found unless BreakEscape::Mission.hacktivity_mode? && @game.vm_set_id

  vm_set = defined?(::VmSet) ? ::VmSet.find_by(id: @game.vm_set_id) : nil
  return head :not_found unless vm_set

  # Nil-guard sec_gen_batch in case it was deleted by an admin after assignment.
  return head :not_found unless vm_set.sec_gen_batch
  batch = vm_set.sec_gen_batch
  event = batch.event
  # Nil-guard event — Event may have been hard-deleted by an admin.
  return head :not_found unless event

  vm = params[:vm_title].present? ? vm_set.vms.find_by(title: params[:vm_title])
                                  : vm_set.vms.first
  return head :not_found unless vm

  # Race guard: only unlock console if the game is still in_progress.
  # A stale vm_panel request arriving after a concurrent restart (which re-locks all VMs)
  # would otherwise win the write race and leave a VM unlocked in a reset game.
  return head :not_found unless @game.reload.status == 'in_progress'

  # Player has reached this VM terminal legitimately in-game. Unlock console access.
  # enable_console was set to false at game start; this is the first valid access point.
  vm.update_column(:enable_console, true)

  redirect_to Rails.application.routes.url_helpers.event_sec_gen_batch_vm_set_vm_path(
    event,
    batch,
    vm_set,
    vm,
    embedded: 1
  )
end
```

Key points:
- Redirects to the **individual VM page** (`VmsController#show`) — VNC/console/flag view for one VM
- `vm_title` param scopes to the specific VM (e.g. `kali`); falls back to `vms.first` if not provided
- `vm.update_column(:enable_console, true)` is the access gate — see Phase 4.4.4 for the full gating strategy
- `embedded: 1` hides navigation and footer via the existing `params.has_key?(:embedded)` check in `application.html.erb`
- Nil-guards on `sec_gen_batch` and `sec_gen_batch.event` return 404 cleanly rather than raising `NoMethodError` or `ActionController::UrlGenerationError`
- The `@game.reload.status == 'in_progress'` guard prevents a stale request from unlocking a VM after a concurrent restart has re-locked it
- Add `vm_panel` and `vm_set_panel` to the `set_game` before_action list

**`app/policies/break_escape/game_policy.rb`** — add policy methods for both panel actions:

```ruby
def vm_panel?
  record.player == user && record.status == 'in_progress'
end

def vm_set_panel?
  record.player == user && record.status == 'in_progress'
end
```

Both methods check ownership (the player must be the game owner) and that the game is still active. The `record.status == 'in_progress'` check provides a secondary line of defence against the enable_console race (ARCH-v4-4) at the policy layer. Admins bypass via the existing `admin?` check in `ApplicationPolicy`.

#### 1.6.2 — `vmPanelUrl` and `vmSetPanelUrl` in `window.breakEscapeConfig`

**`app/views/break_escape/games/show.html.erb`** — add to `window.breakEscapeConfig`:

```javascript
vmPanelUrl:       '<%= BreakEscape::Mission.hacktivity_mode? ? vm_panel_game_path(@game) : '' %>',
vmSetPanelUrl:    '<%= BreakEscape::Mission.hacktivity_mode? ? vm_set_panel_game_path(@game) : '' %>',
vmActivationMode: '<%= BreakEscape::Mission.hacktivity_mode? ? @game.mission.vm_activation_mode.to_s : '' %>',
```

- `vmPanelUrl` — used by the vm-launcher minigame; redirects to the individual VM show page
- `vmSetPanelUrl` — used by the Phaser VM HUD panel; redirects to the new Hacktivity vm_set controls endpoint (Phase 4.4.3)
- `vmActivationMode` — string `'eager'` or `'lazy'`; used by the Phaser HUD to decide whether to trigger activation on first `requiresVM` interaction. Empty string in standalone mode (HUD treats blank as a no-op).
- All three are empty strings in standalone mode; each consumer checks for a non-empty value before using it

#### 1.6.3 — vm-launcher minigame: iframe in Hacktivity mode

**`public/break_escape/js/minigames/vm-launcher/vm-launcher-minigame.js`**

Read `vmPanelUrl` from config in the constructor:

```javascript
this.vmPanelUrl = window.breakEscapeConfig?.vmPanelUrl || null;
```

At the top of `buildUI()`, before the existing style injection, add:

```javascript
// In Hacktivity mode, load Hacktivity's VM page in an iframe.
// The engine's vm_panel endpoint redirects to the correct Hacktivity VM URL,
// so Bootstrap, jQuery, and ActionCable (including VNC) all work natively.
if (this.hacktivityMode && this.vmPanelUrl) {
    const iframeSrc = this.vm?.title
        ? `${this.vmPanelUrl}?vm_title=${encodeURIComponent(this.vm.title)}`
        : this.vmPanelUrl;

    const launcher = document.createElement('div');
    launcher.className = 'vm-launcher vm-launcher-iframe';
    const iframe = document.createElement('iframe');
    iframe.src = iframeSrc;
    iframe.title = 'VM Controls';
    launcher.appendChild(iframe);
    this.gameContainer.appendChild(launcher);
    return;
}
```

The rest of `buildUI()` (standalone instructions and Hacktivity inline card) is only reached when `vmPanelUrl` is not set — i.e. standalone mode. **Standalone behaviour is completely unchanged.**

#### 1.6.4 — iframe CSS

**`public/break_escape/css/vm-launcher-minigame.css`** — add:

```css
/* Hacktivity mode: iframe fills the panel with no extra padding */
.vm-launcher.vm-launcher-iframe {
    padding: 0;
    max-height: none;
    overflow: hidden;
}

.vm-launcher-iframe iframe {
    display: block;
    width: 100%;
    height: 100vh;
    border: none;
}
```

560px gives enough vertical space for VNC browser controls and the power/console buttons. The VNC floating overlay created by Hacktivity's `file_push.js` is `position: fixed` within the iframe viewport, so VNC displays within the minigame panel. The overlay includes a "New tab" button if the player wants a full-screen VNC experience.

#### 1.6.5 — File changes (Phase 1.6)

| File | Change |
|---|---|
| `config/routes.rb` | Add `get 'vm_panel'` **and `get 'vm_set_panel'`** to games member block (both declared here to avoid `NoMethodError` in `show.html.erb` ERB before Phase 4.4.3 is deployed) |
| `app/controllers/break_escape/games_controller.rb` | Add `vm_panel` action + both actions to before_action list; add `vm_panel?`/`vm_set_panel?` to `BreakEscape::GamePolicy` |
| `app/views/break_escape/games/show.html.erb` | Add `vmPanelUrl`, `vmSetPanelUrl`, and `vmActivationMode` to `window.breakEscapeConfig` |
| `public/break_escape/js/minigames/vm-launcher/vm-launcher-minigame.js` | Read `vmPanelUrl`; iframe branch at top of `buildUI()` |
| `public/break_escape/css/vm-launcher-minigame.css` | Add `.vm-launcher-iframe` styles |

No Hacktivity changes required for the vm-launcher — the individual VM show page at the nested URL already exists and Hacktivity's `application.html.erb` already hides navigation/footer when `?embedded` is present. The `vm_set_panel` action body is added in Phase 4.4.3; declaring the route here is a forward-declaration that prevents ERB breakage. The vm_set controls endpoint (for the HUD panel) is a separate addition covered in Phase 4.4.3.

---

## Phase 2 — Hacktivity: `VmSetAssignmentService` Extraction

**Repo: Hacktivity** — Highest-risk phase. Test gates are mandatory.

### 2.1 — Run Existing Tests (Gate 1)

```bash
rails test test/controllers/sec_gen_batches_controller_test.rb
```

All tests must be green before any code changes.

### 2.2 — Write Characterization Tests BEFORE Extraction (Gate 2)

Write unit tests for `VmSetAssignmentService` **before creating the service file**, treating the existing controller code as the specification. These tests will initially fail (the service doesn't exist yet). They provide a fast feedback loop during extraction.

**`test/services/vm_set_assignment_service_test.rb`** — cover every guard clause in `SecGenBatchesController#assign_vm_set` (individual-user path, lines 220–302):

| Test case | Expected result |
|---|---|
| Challenge not started, regular user | Error: start time message |
| Challenge not started, admin | Proceeds (admin bypass) |
| Challenge not started, scoped VIP | Proceeds (VIP bypass) |
| Wait quota: user has NO prior allocation (nil most_recent) | Proceeds — nil short-circuit, no error |
| Wait quota exceeded, guest (most_recent within limit) | Error + redirect key `:event` |
| Wait quota exceeded, premium (most_recent within limit) | Error + redirect key `:plans` |
| Wait quota: most_recent allocated exactly AT the boundary (`allocated_date == limit.ago`) | Error — boundary is inclusive (`>=`), do not change to `>` |
| Wait quota: admin (has premium_quota? true) | Proceeds — admin bypass on wait quota |
| Global ownership quota exceeded | Error |
| Batch quota (`count > (max_vm_set_requests \|\| 1)`) | Error — `>` not `>=`: allows one-over, do not "fix" |
| Batch quota: count == max_vm_set_requests (not exceeded) | Proceeds |
| No available vm_set, no parent pool | Error |
| No available vm_set, parent pool has one | Success, vm_set reassigned to batch |
| Available vm_set in batch | Success, vm_set assigned to user + allocated_date set |
| `Ga4Service.track_event` called on success | Called once with `team_assignment: false` |
| `Ga4Service.track_event` NOT called on error | Not called |

### 2.3 — Create `VmSetAssignmentService`

**`app/services/vm_set_assignment_service.rb`:**

```ruby
# frozen_string_literal: true

class VmSetAssignmentService
  # Use Struct (not Data.define — Hacktivity runs Ruby 2.7; Data.define requires Ruby 3.2)
  Result = Struct.new(:success, :vm_set, :error_message, :redirect_key, keyword_init: true)

  def self.assign_to_user(sec_gen_batch:, user:, event:)
    new(sec_gen_batch: sec_gen_batch, user: user, event: event).call
  end

  def initialize(sec_gen_batch:, user:, event:)
    @sec_gen_batch = sec_gen_batch
    @user = user
    @event = event
  end

  def call
    return start_time_error   if challenge_not_started?
    return wait_quota_error   if wait_quota_exceeded?
    return ownership_error    if ownership_quota_exceeded?
    return batch_quota_error  if batch_quota_exceeded?

    vm_set = find_available_vm_set
    return no_vm_error if vm_set.nil?

    assign!(vm_set)
    Result.new(success: true, vm_set: vm_set, error_message: nil, redirect_key: nil)
  end

  private

  def challenge_not_started?
    # Admins and scoped VIPs bypass the start-time gate (mirrors controller line 171)
    @sec_gen_batch.start_time > Time.current &&
      !(@user.admin? || @user.scoped_vip_by_event?(@event))
  end

  def wait_quota_exceeded?
    return false if @user.admin?
    limit = @user.has_premium_quota? ? Rails.configuration.xp_claim_wait_time_premium
                                     : Rails.configuration.xp_claim_wait_time_guest
    most_recent = @user.vm_sets
                       .joins(:sec_gen_batch)
                       .where("sec_gen_batches.event_id = ?", @event.id)
                       .order("allocated_date DESC")
                       .first
    most_recent&.allocated_date&.>= limit.ago
  end

  def ownership_quota_exceeded?
    return false if @user.admin?
    max = @user.has_premium_quota? ? Rails.application.config.max_vm_set_owned_premium
                                   : Rails.application.config.max_vm_set_owned_guest
    count = @user.vm_sets
                 .joins(:cluster)
                 .where(build_status: "success", custom_end_time: nil)
                 .where(clusters: { cluster_type: Cluster.cluster_types[:proxmox] })
                 .count
    count >= max
  end

  def batch_quota_exceeded?
    count = VmSet.where(sec_gen_batch: @sec_gen_batch, user: @user, build_status: "success").count
    # NOTE: this uses `>` not `>=` — this is the existing controller behaviour.
    # The check fires when count exceeds max_vm_set_requests, allowing one-over.
    # Do not change this to `>=` without understanding the intent.
    count > (@sec_gen_batch.max_vm_set_requests || 1)
  end

  def find_available_vm_set
    VmSet.find_by(sec_gen_batch: @sec_gen_batch, user: nil, team: nil, build_status: "success") ||
      (@sec_gen_batch.parent_pool &&
        VmSet.find_by(sec_gen_batch: @sec_gen_batch.parent_pool, user: nil, team: nil, build_status: "success"))
  end

  def assign!(vm_set)
    # IMPORTANT: reassign to @sec_gen_batch before saving.
    # When sourced from the parent pool, this permanently moves the VmSet out of the pool
    # and into the current batch. Without this, scoring, redirects, and the completion
    # callback will all resolve to the wrong event/batch.
    vm_set.user           = @user
    vm_set.allocated_date = Time.current
    vm_set.sec_gen_batch  = @sec_gen_batch
    vm_set.save!

    # team_assignment uses the actual batch setting (not hardcoded false) to preserve
    # analytics continuity with the existing controller flow. In practice this service
    # is only called for individual-user assignment, so this will always be false/nil,
    # but using the real value avoids silently wrong analytics if that changes.
    Ga4Service.track_event(
      name: 'vm_set_assigned',
      user: @user,
      params: { vm_set_id: vm_set.id, batch_id: @sec_gen_batch.id,
                team_assignment: @sec_gen_batch.vm_sets_shared_by_team }
    )
  end

  # Error helpers — redirect_key is resolved to a path in the controller
  def start_time_error
    Result.new(success: false, vm_set: nil, redirect_key: :event,
               error_message: "This challenge has not started yet.")
  end

  def wait_quota_error
    # NOTE: premium users are redirected to plans (upgrade prompt); guests to event.
    # This matches the existing controller behaviour exactly (counterintuitive but correct).
    if @user.has_premium_quota?
      Result.new(success: false, vm_set: nil, redirect_key: :plans,
                 error_message: "Wait before claiming another set of VMs. You can upgrade your plan to remove this wait.")
    else
      Result.new(success: false, vm_set: nil, redirect_key: :event,
                 error_message: "Wait before claiming another set of VMs for this event.")
    end
  end

  def ownership_error
    max = @user.has_premium_quota? ? Rails.application.config.max_vm_set_owned_premium
                                   : Rails.application.config.max_vm_set_owned_guest
    count = @user.vm_sets
                 .joins(:cluster)
                 .where(build_status: "success", custom_end_time: nil)
                 .where(clusters: { cluster_type: Cluster.cluster_types[:proxmox] })
                 .count
    over_by_amount = count - max + 1
    # Message format must match the existing controller test assertion (line 422-423)
    Result.new(success: false, vm_set: nil, redirect_key: :event,
               error_message: "You cannot own more than #{max} VM sets. Please relinquish #{over_by_amount} VM sets (click the Relinquish button on VMs you are finished with), then try again.")
  end

  def batch_quota_error
    count = VmSet.where(sec_gen_batch: @sec_gen_batch, user: @user, build_status: "success").count
    Result.new(success: false, vm_set: nil, redirect_key: :event,
               error_message: "Sorry, you already have #{count} VM sets. If you are experiencing technical issues, please let us know.")
  end

  def no_vm_error
    Result.new(success: false, vm_set: nil, redirect_key: :event,
               error_message: "Sorry, could not assign VM set (none available at the moment).")
  end
end
```

### 2.4 — Update `SecGenBatchesController#assign_vm_set`

Replace only the individual-user block (team path is unchanged). The controller resolves `redirect_key` to actual path helpers:

```ruby
result = VmSetAssignmentService.assign_to_user(
  sec_gen_batch: @sec_gen_batch,
  user: current_user,
  event: @event
)

if result.success
  redirect_to event_sec_gen_batch_path(
    result.vm_set.sec_gen_batch.event,
    result.vm_set.sec_gen_batch
  ), status: :see_other
else
  flash[:error] = result.error_message
  path = result.redirect_key == :plans ? plans_path : event_path(@event)
  redirect_to path, status: :see_other
end
```

### 2.5 — Run Tests After Extraction (Gate 3)

```bash
rails test test/controllers/sec_gen_batches_controller_test.rb
rails test test/services/vm_set_assignment_service_test.rb
```

All characterization tests (written in 2.2) and all existing controller tests must pass. Fix any regressions before proceeding to Phase 2.6.

---

### 2.6 — Write Characterization Tests BEFORE Creating `VmSetActivationService` (Gate 4)

Write unit tests for `VmSetActivationService` **before creating the service file**, treating the existing `VmSetsController#activate` private method (lines 110–213) as the specification. These tests will initially fail (the service doesn't exist yet).

**`test/services/vm_set_activation_service_test.rb`:**

| Test case | Expected result |
|---|---|
| Already activated, `custom_end_time` nil, premium user | Extends `activated_until` by premium extend timer; returns `start_vms: false` |
| Already activated, `custom_end_time` nil, guest user | Extends by guest extend timer; message differs ("upgrade your plan…") |
| Already activated, `custom_end_time` set | Error: "Shutdown timer cannot be extended." |
| Not activated, `build_status != "success"` | Error: "can't activate…" |
| Not activated, scenario password enabled, not unlocked | Error: password message |
| Not activated, scenario password enabled, `password_unlocked_until` expired | Error: password message |
| Not activated, scenario password enabled, valid unlock | Proceeds past password guard |
| Not activated, `sec_gen_batch` nil (BreakEscape context) | Proceeds (no password guard without batch) |
| Quota: admin | Bypasses concurrent check, proceeds |
| Quota: premium user at `max_vm_set_sessions_active_premium` | Error with active list; `redirect_key: :event` |
| Quota: guest user at `max_vm_set_sessions_active_guest` | Error with upgrade prompt appended |
| Quota: user below quota | Proceeds |
| Proxmox cluster, node available, VM on different node | Dispatches `migrate`; `start_vms: false`; `target_node` saved |
| Proxmox cluster, node available, VM on same node | Dispatches `start`; `start_vms: false` |
| Proxmox cluster, no node available, `user?` tier | Error; `redirect_key: :plans` |
| Proxmox cluster, no node available, other tier | Error; `redirect_key: :event` |
| oVirt (no cluster or ovirt cluster) | Sets activation timestamps; `start_vms: true` (caller must dispatch start) |
| `Ga4Service`/analytics not called | Service has no analytics side-effects |

### 2.7 — Create `VmSetActivationService`

**`app/services/vm_set_activation_service.rb`:**

```ruby
# frozen_string_literal: true

# Encapsulates VmSet activation and timer-extension logic shared between
# VmSetsController#activate (traditional Hacktivity UI) and
# GameSlotsController#extend_vms (BreakEscape in-game activation).
#
# Result fields:
#   success:      Boolean — true if activation or extension succeeded.
#   start_vms:    Boolean — true when caller must still dispatch "start" commands
#                 (oVirt path, initial activation). Proxmox dispatches internally;
#                 extend path always returns false (VMs already running).
#   message:      String  — human-readable message for flash or JSON error.
#   message_type: Symbol  — :notice or :error.
#   redirect_key: Symbol  — :plans (upgrade prompt) or :event (default). nil on success.
class VmSetActivationService
  Result = Struct.new(:success, :start_vms, :message, :message_type, :redirect_key,
                      keyword_init: true) do
    def error? = !success
  end

  def self.call(vm_set:, user:, sec_gen_batch: nil)
    new(vm_set: vm_set, user: user, sec_gen_batch: sec_gen_batch).call
  end

  def initialize(vm_set:, user:, sec_gen_batch: nil)
    @vm_set = vm_set
    @user = user
    # Accept explicit sec_gen_batch to avoid a redundant DB round-trip for callers
    # that already have it loaded. Falls back to the association if nil.
    @sec_gen_batch = sec_gen_batch || vm_set.sec_gen_batch
  end

  def call
    # Already activated: extend the shutdown timer and return early.
    return extend_timer if @vm_set.activated

    return error("Sorry, you can't activate a vm set that hasn't successfully built.") unless build_ready?
    return error("You need to enter a password to unlock this scenario first. Unlock, then try again.") if password_locked?
    return quota_error if concurrent_quota_exceeded?

    perform_initial_activation
  end

  private

  # Already-activated path: extend the shutdown timer.
  # VMs are already running; returns start_vms: false.
  def extend_timer
    if @vm_set.custom_end_time.nil?
      timer = @user.has_premium_quota? ? Rails.configuration.vm_set_activation_timer_extend_premium
                                       : Rails.configuration.vm_set_activation_timer_extend_guest
      @vm_set.activated_until = Time.current + timer
      @vm_set.save
      msg = if @user.has_premium_quota?
              "Shutdown timer extended."
            else
              "Shutdown timer extended. You can extend this again later by requesting more time, or upgrade your plan to increase your timer."
            end
      Result.new(success: true, start_vms: false, message: msg,
                 message_type: :notice, redirect_key: nil)
    else
      error("Shutdown timer cannot be extended.")
    end
  end

  def build_ready?
    @vm_set.build_status == "success"
  end

  def password_locked?
    @sec_gen_batch&.enable_scenario_password &&
      (!@vm_set.password_unlocked_until || @vm_set.password_unlocked_until < Time.current)
  end

  def concurrent_quota_exceeded?
    return false if @user.try(:admin?)

    max_active = @user.has_premium_quota? ? Rails.configuration.max_vm_set_sessions_active_premium
                                          : Rails.configuration.max_vm_set_sessions_active_guest
    VmSet.where(user: @user, activated: true).size >= max_active
  end

  # Builds the quota error message. Separated from #concurrent_quota_exceeded? to
  # avoid a second DB query when the check is false (loading active vm_sets only on error).
  def quota_error
    users_active_vm_sets = VmSet.where(user: @user, activated: true)
    max_active = @user.has_premium_quota? ? Rails.configuration.max_vm_set_sessions_active_premium
                                          : Rails.configuration.max_vm_set_sessions_active_guest
    active_list = users_active_vm_sets.map { |vs| vs.sec_gen_batch.title }
    msg = "You already have #{users_active_vm_sets.size} activated challenges #{active_list}, " \
          "deactivate one and try again. " \
          "(Deactivating a challenge simply causes VMs to shutdown, you can reactivate it later)."
    msg += " You can upgrade your plan to increase your quota." unless @user.has_premium_quota?
    error(msg)
  end

  def perform_initial_activation
    start_vms = dispatch_and_select_node
    # Return early if dispatch_and_select_node produced an error Result
    # (e.g. Proxmox cluster at capacity).
    return start_vms if start_vms.is_a?(Result)

    set_activation_timestamps
    msg = start_vms ? "Activated challenge. Your VMs will start shortly. (Deployed to oVirt.)"
                    : "Activated challenge. Your VMs will start shortly. (Deploying...)"
    Result.new(success: true, start_vms: start_vms, message: msg,
               message_type: :notice, redirect_key: nil)
  end

  # Proxmox: selects a node, dispatches migrate/start commands, returns false.
  # oVirt:   returns true so the caller dispatches start commands.
  # Proxmox capacity failure: returns an error Result directly.
  def dispatch_and_select_node
    if @vm_set&.cluster&.proxmox_cluster?
      node_selected = @vm_set.cluster&.prepare_to_activate(@vm_set, @user.has_premium_quota?)
      if node_selected.nil?
        # NOTE: the "Upgrade now." link is added by the controller (view_context is not
        # available in a service). redirect_key: :plans signals the controller to do so.
        msg, rk = if @user.try(:user?)
                    ["Upgrade your account for priority access to servers, tier is currently at capacity.",
                     :plans]
                  else
                    ["Please try again later, servers are currently at capacity.", :event]
                  end
        return error(msg, redirect_key: rk)
      end

      @vm_set.target_node = node_selected
      @vm_set.save
      @vm_set.vms.each do |vm|
        if vm.node&.id != node_selected.id
          vm.state = "migrate_start"
          DispatchVmCtrlService.ctrl_vm_async(vm, "migrate", node_selected.id)
        else
          vm.state = "command_sent"
          DispatchVmCtrlService.ctrl_vm_async(vm, "start", "")
        end
        vm.save
      end
      false # start_vms = false; Proxmox dispatch already handled
    else
      # oVirt — VM start is dispatched by the caller after this returns.
      true # start_vms = true
    end
  end

  # Mirrors VmSetsController#activate lines 200-211.
  # reload is called first to ensure intermediate saves (target_node, vm state) are reflected.
  def set_activation_timestamps
    timer = @user.has_premium_quota? ? Rails.configuration.vm_set_activation_timer_start_premium
                                     : Rails.configuration.vm_set_activation_timer_start_guest
    @vm_set.reload
    @vm_set.activated       = true
    @vm_set.activated_since = Time.current
    @vm_set.activated_until = Time.current + timer
    @vm_set.save
  end

  def error(message, redirect_key: :event)
    Result.new(success: false, start_vms: false, message: message,
               message_type: :error, redirect_key: redirect_key)
  end
end
```

### 2.8 — Update `VmSetsController#activate` to Delegate to Service

Replace the `activate` private method body with a call to the service. The method's return value contract (`true`/`false` for `start_vms`) is preserved so `activate_and_start` continues to work unchanged.

**`app/controllers/vm_sets_controller.rb`** — replace the `activate` private method body:

```ruby
def activate
  authorize(@vm_set)
  result = VmSetActivationService.call(
    vm_set: @vm_set, user: current_user, sec_gen_batch: @sec_gen_batch
  )
  if result.error? && result.redirect_key == :plans
    # Add the upgrade link here — view_context is only available in controllers.
    flash[:error] = result.message + " #{view_context.link_to 'Upgrade now.', plans_path}"
  else
    flash[result.message_type] = result.message
  end
  result.start_vms
end
```

`activate_and_start` is **unchanged** — it still calls `if activate` and dispatches start commands when the result is truthy.

### 2.9 — Run Tests After Extraction (Gate 5)

```bash
rails test test/controllers/vm_sets_controller_test.rb
rails test test/services/vm_set_activation_service_test.rb
```

All existing `vm_sets_controller` tests must pass without modification. The new service tests written in Phase 2.6 must also be green. Fix any regressions before proceeding to Phase 3.

---

## Phase 3 — Hacktivity: Core Model Changes

**Repo: Hacktivity**

### 3.1 — Add `game` to Event Enum (Model-only, no migration)

`type_of_hacktivity` is a string column (`t.string "type_of_hacktivity"` in schema). Adding a new string enum value requires **only a model change** — no migration file.

**`app/models/event.rb`:**
```ruby
enum(
  type_of_hacktivity: {
    event:      "Event",
    course:     "Course",
    experience: "Experience",
    pool:       "Pool",
    game:       "Game",   # NEW
  },
  _prefix: :hacktivity_type,
)
```

No migration file for this change.

### 3.2 — Add `hidden_from_players` to SecGenBatch

**Migration** (`db/migrate/TIMESTAMP_add_hidden_from_players_to_sec_gen_batches.rb`):
```ruby
class AddHiddenFromPlayersToSecGenBatches < ActiveRecord::Migration[7.0]
  def change
    # This column controls UI visibility only. It does NOT affect Result#calculate,
    # which iterates all event.sec_gen_batches regardless of this flag.
    add_column :sec_gen_batches, :hidden_from_players, :boolean, default: false, null: false
  end
end
```

### 3.3 — Create `game_slots` Table + Model

**Migration** (`db/migrate/TIMESTAMP_create_game_slots.rb`):
```ruby
class CreateGameSlots < ActiveRecord::Migration[7.0]
  def change
    create_table :game_slots do |t|
      t.references :event,         null: false, foreign_key: true
      t.references :sec_gen_batch, null: true,  foreign_key: true
      t.bigint     :break_escape_mission_id, null: false
      t.integer    :position,      null: false, default: 0
      t.datetime   :release_at
      t.timestamps
    end

    add_index :game_slots, :break_escape_mission_id
    add_index :game_slots, [:event_id, :position]

    # Enforce FK to BreakEscape::Mission. Both tables live in the same database
    # when Hacktivity is the host, so the constraint is safe to add here.
    # If validate: false is needed for a large-table migration, validate separately.
    add_foreign_key :game_slots, :break_escape_missions,
                    column: :break_escape_mission_id
  end
end
```

**Model** (`app/models/game_slot.rb`):
```ruby
# frozen_string_literal: true

class GameSlot < ApplicationRecord
  belongs_to :event
  belongs_to :sec_gen_batch, optional: true
  belongs_to :break_escape_mission,
             class_name: 'BreakEscape::Mission',
             foreign_key: :break_escape_mission_id

  validates :event,               presence: true
  validates :break_escape_mission, presence: true
  validates :position,            presence: true,
                                  numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :sec_gen_batch_belongs_to_event, if: :sec_gen_batch

  scope :available, ->(now = Time.current) { where('release_at IS NULL OR release_at <= ?', now) }
  scope :ordered,   -> { order(:position) }

  before_create :set_default_position

  # Correct implementation (see architecture review Finding 2).
  # For VM-backed missions, scopes to games associated with this listing's VmSets
  # so stale games from other events or relinquished sets are never returned.
  def active_game_for(user)
    scope = BreakEscape::Game.where(
      player: user,
      mission: break_escape_mission,
      status: 'in_progress'
    )

    if vm_backed?
      valid_vm_set_ids = sec_gen_batch.vm_sets
                                      .where(user: user, relinquished: false)
                                      .where.not(build_status: %w[pending error])
                                      .pluck(:id)
      return nil if valid_vm_set_ids.empty?
      scope = scope.where(vm_set_id: valid_vm_set_ids)
    end

    scope.order(created_at: :desc).first
  end

  def vm_backed?
    sec_gen_batch.present?
  end

  def available?(now = Time.current)
    (release_at || event.start_time) <= now
  end

  private

  def sec_gen_batch_belongs_to_event
    return if sec_gen_batch.event_id == event_id
    errors.add(:sec_gen_batch, "must belong to the same event")
  end

  # Manual position management (acts_as_list is not in Hacktivity's Gemfile).
  # Appends after the last existing listing for this event.
  def set_default_position
    self.position ||= (event.game_slots.maximum(:position) || -1) + 1
  end
end
```

**`app/models/event.rb`:**
```ruby
has_many :game_slots, dependent: :destroy
```

**`app/models/sec_gen_batch.rb`:**
```ruby
has_one :game_slot
```

### 3.4 — Tests (Hacktivity — Models)

**`test/models/game_slot_test.rb`:**
- Valid with event + mission, no sec_gen_batch (VM-free)
- Valid with event + mission + sec_gen_batch (same event)
- Invalid if sec_gen_batch belongs to different event
- `vm_backed?` true/false
- `available?` with nil `release_at` (uses event start)
- `available?` with future `release_at` → false
- `available?` with past `release_at` → true
- `position` auto-set on create; sequential for multiple listings
- `active_game_for` — VM-backed: returns in_progress game with valid vm_set_id
- `active_game_for` — VM-backed: returns nil if game's vm_set_id is relinquished
- `active_game_for` — VM-backed: returns nil if game's vm_set_id belongs to a different batch
- `active_game_for` — VM-free: returns in_progress game
- `active_game_for` — status 'completed': returns nil
- `active_game_for` — status 'abandoned': returns nil
- `active_game_for` — multiple in_progress games: returns most recent

---

## Phase 4 — Hacktivity: Controller, Routes, Policy

**Repo: Hacktivity**

### 4.1 — Routes

**`config/routes.rb`** inside the `events` resource block:
```ruby
resources :game_slots, path: "missions", only: [] do
  post "start",        on: :member
  post "restart",      on: :member
  # VM lifecycle — called by the in-game HUD (and by start action for eager missions)
  get  "vm_status",    on: :member   # JSON; polled by Phaser HUD
  post "extend_vms",   on: :member   # activate / extend quota timer
  post "shutdown_vms", on: :member   # power down VMs early
  post "finish",       on: :member   # mark game done + relinquish VmSet
end
```

No `index` or `show` routes for players — the event show page is the mission list.

### 4.2 — Policy

**`app/policies/game_slot_policy.rb`:**
```ruby
# frozen_string_literal: true

class GameSlotPolicy < ApplicationPolicy
  def start?
    return true if admin?
    signed_up_to_event? && listing_available? && !access_revoked_by_org?
  end

  def restart?
    start?
  end

  # VM lifecycle actions: same authorization as start (must be signed-up + available)
  def vm_status?;    start?; end
  def extend_vms?;   start?; end
  def shutdown_vms?; start?; end
  def finish?;       start?; end

  def create?; admin?; end
  def update?; admin?; end
  def destroy?; admin?; end

  private

  def signed_up_to_event?
    # Memoize to avoid N+1 when policy is checked per-listing on event show page
    @signed_up ||= record.event.users.exists?(user.id)
  end

  def listing_available?
    record.available? || admin?
  end

  def access_revoked_by_org?
    event = record.event
    event.org.present? &&
      (user.role == "user" || (!admin? && user.org_id != event.org_id))
  end
end
```

### 4.3 — Controller

**`app/controllers/game_slots_controller.rb`:**
```ruby
# frozen_string_literal: true

class GameSlotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_game_slot

  def start
    authorize(@game_slot)

    existing_game = @game_slot.active_game_for(current_user)
    return redirect_to break_escape.game_path(existing_game), status: :see_other if existing_game

    outcome = create_game_for_listing(@game_slot, current_user)

    if outcome.error?
      flash[:error] = outcome.error_message
      path = outcome.redirect_key == :plans ? plans_path : event_path(@event)
      return redirect_to path, status: :see_other
    end

    Ga4Service.track_event(
      name: 'mission_started',
      user: current_user,
      params: { game_slot_id: @game_slot.id, game_id: outcome.game.id }
    )

    redirect_to break_escape.game_path(outcome.game), status: :see_other
  end

  def restart
    authorize(@game_slot)

    # Only in_progress games are restartable (completed games are out of scope).
    game = @game_slot.active_game_for(current_user)
    unless game
      flash[:error] = "No active mission found to restart. Completed missions cannot be restarted."
      return redirect_to event_path(@event), status: :see_other
    end

    if @game_slot.vm_backed?
      vm_set_id = game.vm_set_id
      vm_set = ::VmSet.find_by(id: vm_set_id)
      if vm_set
        # VMs must be powered down before a snapshot revert can be dispatched.
        # DispatchVmCtrlService does NOT perform this check internally —
        # VmSetsController#ovirt_revert_snapshot_vm_set does it explicitly.
        running_vms = vm_set.vms.reject { |vm| vm.state == "down" }
        if running_vms.any?
          flash[:error] = "Please shut down your VMs before restarting the mission (#{running_vms.map(&:title).join(', ')} must be powered off first)."
          return redirect_to event_path(@event), status: :see_other
        end

        vm_set.vms.each do |vm|
          DispatchVmCtrlService.ctrl_vm_async(vm, "revert_snapshot", "original")
        end
        flash[:notice] = "VM revert in progress. Please wait a few minutes before reconnecting."
      end
    end

    game.reset_player_state!
    redirect_to break_escape.game_path(game), status: :see_other
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_game_slot
    @game_slot = @event.game_slots.find(params[:id])
  end

  # Defined at class scope to avoid Ruby constant-reassignment warnings
  # (defining Struct inside a method body creates a new constant on every call).
  Outcome = Struct.new(:game, :error_message, :redirect_key, keyword_init: true) do
    def error? = error_message.present?
  end

  # Extracted transaction method — keeps all redirect_to calls outside any
  # transaction boundary, eliminating the fragile redirect+Rollback+performed? pattern.
  # Returns a value object; the action reads it and redirects accordingly.
  def create_game_for_listing(game_slot, user)
    game = nil

    ApplicationRecord.transaction do
      if game_slot.vm_backed?
        result = VmSetAssignmentService.assign_to_user(
          sec_gen_batch: game_slot.sec_gen_batch,
          user: user,
          event: @event
        )
        return Outcome.new(error_message: result.error_message, redirect_key: result.redirect_key) unless result.success

        game = BreakEscape::Game.new(player: user, mission: game_slot.break_escape_mission)
        # vm_set_id must also be in player_state because generate_scenario_data
        # (before_create in the engine) reads it there to build the flag/VM context.
        # After creation, game.vm_set_id (the column) is the authoritative source.
        game.vm_set_id    = result.vm_set.id
        game.player_state = { 'vm_set_id' => result.vm_set.id }
        game.save!
      else
        game = BreakEscape::Game.create!(player: user, mission: game_slot.break_escape_mission)
      end

      # Enrol the user in the event inside the same transaction so a failed game
      # creation does not leave an orphaned Result row.
      # Note: Result here is the Hacktivity Result model, not VmSetAssignmentService::Result.
      Result.find_or_create_by(user: user, event: @event)
    end

    Outcome.new(game: game)

  rescue ActiveRecord::RecordNotUnique
    # Race condition: concurrent request committed a game first.
    # Find the winning game and surface it; if somehow still not found, surface an error.
    existing = game_slot.active_game_for(user)
    existing ? Outcome.new(game: existing) : Outcome.new(error_message: "Could not start mission. Please try again.", redirect_key: :event)
  end
end
```

### 4.4 — VM Lifecycle Endpoints + Phaser HUD Specification

#### 4.4.1 — Controller Additions (`app/controllers/game_slots_controller.rb`)

Add the following actions alongside `start` and `restart`. All share the same `before_action` chain (`authenticate_user!`, `set_event`, `set_game_slot`).

```ruby
# GET /events/:event_id/missions/:id/vm_status
# Polled by the Phaser HUD. Returns JSON; no redirect.
def vm_status
  authorize(@game_slot, :vm_status?)
  game = @game_slot.active_game_for(current_user)
  unless game
    return render json: { error: "No active game found" }, status: :not_found
  end

  vm_set = game.vm_set_id ? ::VmSet.find_by(id: game.vm_set_id) : nil
  unless vm_set
    return render json: {
      vm_activation_mode: @game_slot.break_escape_mission.vm_activation_mode,
      activated: false,
      activated_until: nil,
      vms: []
    }
  end

  render json: {
    vm_activation_mode: @game_slot.break_escape_mission.vm_activation_mode,
    activated:       vm_set.activated,
    activated_until: vm_set.activated_until&.iso8601,
    vms: vm_set.vms.map { |vm| { title: vm.title, state: vm.state } }
  }
end

# POST /events/:event_id/missions/:id/extend_vms
# Activates VMs (first call) or extends the quota timer (subsequent calls).
# Called by: Phaser HUD (lazy first-touch + extend button).
# All activation guards (build_status, concurrent quota, Proxmox node selection)
# are enforced by VmSetActivationService — the same service used by VmSetsController#activate.
def extend_vms
  authorize(@game_slot, :extend_vms?)
  game = @game_slot.active_game_for(current_user)
  return render json: { error: "No active game found" }, status: :unprocessable_entity unless game

  vm_set = game.vm_set_id ? ::VmSet.find_by(id: game.vm_set_id) : nil
  return render json: { error: "No VmSet found for this game" }, status: :unprocessable_entity unless vm_set

  result = VmSetActivationService.call(vm_set: vm_set, user: current_user)
  return render json: { error: result.message }, status: :unprocessable_entity unless result.success

  # For oVirt clusters: the service sets activated_until but defers VM start dispatch
  # to the caller (mirrors VmSetsController#activate_and_start behaviour).
  if result.start_vms
    vm_set.reload.vms.each do |vm|
      vm.state = "sent_command"
      vm.save
      DispatchVmCtrlService.ctrl_vm_async(vm, "start", "")
    end
  end

  # Track BreakEscape allocation timestamp. Not part of VmSetActivationService's scope —
  # used by VmSetAssignmentService#wait_quota_exceeded? on the next assignment attempt.
  # Updated on both initial activation and every timer extension.
  vm_set.reload
  vm_set.allocated_date = Time.current
  vm_set.save!

  render json: { ok: true, activated_until: vm_set.activated_until.iso8601 }
end

# POST /events/:event_id/missions/:id/shutdown_vms
# Powers down all VMs for the player's current game (does not relinquish).
def shutdown_vms
  authorize(@game_slot, :shutdown_vms?)
  game = @game_slot.active_game_for(current_user)
  return render json: { error: "No active game found" }, status: :unprocessable_entity unless game

  vm_set = game.vm_set_id ? ::VmSet.find_by(id: game.vm_set_id) : nil
  return render json: { error: "No VmSet found" }, status: :unprocessable_entity unless vm_set

  vm_set.vms.each do |vm|
    DispatchVmCtrlService.ctrl_vm_async(vm, "stop", nil)
  end

  render json: { ok: true }
end

# POST /events/:event_id/missions/:id/finish
# Player-initiated game completion: marks Game completed and relinquishes VmSet.
# Mirrors VmSetsController#relinquish: calls RelinquishVmSetJob which handles
# VM power-down, snapshot revert queuing, and freeing the set back to the pool.
# The on_game_complete hook fires via after_commit, enqueuing GameCompletionScoringJob.
def finish
  authorize(@game_slot, :finish?)
  game = @game_slot.active_game_for(current_user)
  return render json: { error: "No active game found" }, status: :unprocessable_entity unless game

  # Mark game completed inside a transaction so scoring callback fires on commit.
  game.update!(status: 'completed')

  # Relinquish VmSet outside the transaction — RelinquishVmSetJob must not be
  # enqueued inside a transaction (job may be picked up before the transaction
  # commits, leaving it unable to find the updated vm_set record).
  vm_set = game.vm_set_id ? ::VmSet.find_by(id: game.vm_set_id) : nil
  RelinquishVmSetJob.perform_later(vm_set.id) if vm_set

  render json: { ok: true, redirect_url: event_path(@event) }
end
```

**Notes on `extend_vms`:**
- On lazy missions (all missions in MVP) this is the first call from the Phaser client when a `requiresVM` interaction is triggered; subsequent calls from the HUD panel's Extend button extend the timer.
- All activation guards (`build_status`, concurrent-session quota, Proxmox node selection, scenario password) are enforced by `VmSetActivationService` — the same service extracted in Phase 2.7. There is no inline guard logic here; do not add any. If a guard needs to change, change `VmSetActivationService`.
- `sec_gen_batch` is not passed to the service here. BreakEscape VmSets do not use scenario passwords, so the password guard in the service short-circuits safely when `sec_gen_batch` is nil.
- For oVirt clusters, `result.start_vms == true` signals that the service has set `activated_until` but not dispatched start commands; `extend_vms` dispatches them in the same pattern as `activate_and_start`. The Proxmox path has the deferred `prepare_to_activate` limitation noted in Known Limitations.
- `allocated_date` is updated after the service call — this is BreakEscape-specific tracking not handled by the service (it is used by `VmSetAssignmentService#wait_quota_exceeded?` on the next assignment attempt).
- The response returns `activated_until` so the Phaser HUD icon can colour-code correctly.
- **Eager activation (auto-activate at game start) is deferred to Phase 2.** The `vm_activation_mode == 'eager'` value is stored and returned in `vm_status` JSON, but `start` does not call `extend_vms` or activate VMs automatically in this revision.

**Notes on `finish`:**
- Marks the game `completed`, which fires `fire_completion_callback` → enqueues `GameCompletionScoringJob`.
- Calls `RelinquishVmSetJob.perform_later` **outside** the `game.update!` call — enqueueing a job inside an open transaction risks the worker picking it up before the transaction commits. `RelinquishVmSetJob` handles VM power-down, snapshot revert queuing, and freeing the set back to the pool (same behaviour as `VmSetsController#relinquish`).
- `ActiveJob::EnqueueError` is rescued so a job-backend failure (e.g. Redis down) does not surface as a 500 to the player. The game completion is real and irreversible; the VmSet will require manual relinquishment or sweeper cleanup if the job fails to enqueue.
- Returns `redirect_url` so the Phaser client can navigate the browser to the event page.

Update the `finish` action to rescue `EnqueueError`:

```ruby
def finish
  authorize(@game_slot, :finish?)
  game = @game_slot.active_game_for(current_user)
  return render json: { error: "No active game found" }, status: :unprocessable_entity unless game

  game.update!(status: 'completed')

  vm_set = game.vm_set_id ? ::VmSet.find_by(id: game.vm_set_id) : nil
  if vm_set
    begin
      RelinquishVmSetJob.perform_later(vm_set.id)
    rescue ActiveJob::EnqueueError => e
      # Game is already marked completed — relinquishment failed to queue.
      # VmSet requires manual cleanup or sweeper job. Do not return 500 to player.
      Rails.logger.error "[finish] Failed to enqueue RelinquishVmSetJob for vm_set #{vm_set.id}: #{e.message}"
    end
  end

  render json: { ok: true, redirect_url: event_path(@event) }
end
```

**Eager activation (auto-activate VMs at game start) is deferred to Phase 2.** In MVP, `start` does not call `extend_vms` and does not activate VMs — activation happens on the player's first `requiresVM` interaction regardless of `vm_activation_mode`. The `vm_activation_mode` column exists and is stored; eager behaviour will be wired up in Phase 2 by extracting a shared private method and calling it from `start`.

#### 4.4.2 — Phaser VM HUD Specification

**Repo: BreakEscape**

This section specifies the in-game VM status HUD that the Phaser client renders. It sits alongside the music button (bottom-right of the game canvas or wherever the music button is positioned).

**Button appearance:**

| VM state | Icon colour | Description |
|---|---|---|
| No VmSet (VM-free mission) | Hidden | Button not rendered |
| `lazy` mode, not yet activated | Grey | VMs not yet started; first interaction will activate |
| `activated: true`, `activated_until` in future | Green | VMs running; time remaining |
| `activated_until` within 10 min | Amber | Low time warning |
| `activated: false` or VMs all `state == "down"` | Red | VMs powered off |
| VmSet `build_status: "error"` | Red + pulse | Error state |

**HUD panel (opens on click):**

- Title: "Your VMs"
- Per-VM rows: `vm.title` + status badge (Running / Stopped / Building / Error)
- Timer: countdown from `activated_until` (e.g. "Time remaining: 1h 23m"). Hidden if not activated.
- **Extend** button: POST `<extendVmsUrl>` (injected at boot). Refreshes countdown.
- **Shutdown** button: POST `<shutdownVmsUrl>`. Confirms before dispatch.
- **Finish Mission** button: POST `<finishUrl>`. Separated visually from Shutdown with a divider or spacing to prevent accidental clicks. Prompts confirmation dialog: "This will end your session and free your VMs. Are you sure?". On success, navigates to `redirect_url` from response.
- Close / dismiss: click button again or press Escape.
- All Phaser `fetch` calls to lifecycle endpoints must include the Rails CSRF token: `headers: { 'X-CSRF-Token': window.breakEscapeConfig?.csrfToken }`. Use `window.breakEscapeConfig.csrfToken` — this is the established CSRF pattern for the engine and is injected at render time. Do not use `document.querySelector('meta[name="csrf-token"]')` — the meta tag may be absent in some engine layouts, which silently sends tokenless requests (422 from Rails).

**Lazy activation trigger:**

The Phaser client maintains a boolean `vmsActivated` (initialised from `vm_activation_mode == 'lazy' ? false : true`). Before any interaction tagged `requiresVM: true` is processed, check `vmsActivated`. If false:
1. Set a `vmsActivating` flag immediately to prevent double-POSTs from rapid interactions (e.g. the player clicks the terminal twice before the first response returns).
2. POST `<extendVmsUrl>` with `headers: { 'X-CSRF-Token': window.breakEscapeConfig?.csrfToken }`.
3. On success: set `vmsActivated = true`, clear `vmsActivating`, update HUD icon to green, proceed with the interaction.
4. On error: clear `vmsActivating`, show in-game notification ("Could not start VMs — please try again or use the VM button").

Once `vmsActivated` is true, the vm-launcher iframe's ActionCable subscription handles live VM state updates as VMs finish booting — the player sees the terminal VM spinning up without needing separate client-side polling.

**Mid-session re-entry:** `vmsActivated` is in JS memory only. On page reload, re-initialise from `vm_status` poll result: if `activated: true` returned, set `vmsActivated = true` immediately.

The `event_id` and `game_slot_id` needed for endpoint URLs are injected into the Phaser game config at boot time (via the existing `ScenarioBinding`/`scenario_data` mechanism or as separate data attributes on the canvas element).

**Polling:**

The Phaser client polls `GET <vmStatusUrl>` (the full Hacktivity route `/events/:event_id/missions/:id/vm_status`, injected via `window.breakEscapeConfig`) every 30 seconds while the HUD panel is open, and once per 5 minutes while closed. The poll interval is configurable via the Phaser game config.

**File locations (BreakEscape engine repo):**

| File | Change |
|---|---|
| `app/javascript/break_escape/hud/vm_hud.js` (or `.ts`) | New Phaser HUD component |
| `app/javascript/break_escape/hud/index.js` | Export `VmHud` |
| `app/javascript/break_escape/scenes/game_scene.js` | Instantiate `VmHud` alongside music button |
| `app/javascript/break_escape/config.js` | Accept `vmStatusUrl`, `extendVmsUrl`, `shutdownVmsUrl`, `finishUrl`, `vmSetPanelUrl` from scenario data |

#### 4.4.3 — Two iframe surfaces using existing Hacktivity pages

**Both surfaces use existing Hacktivity pages with `?embedded` — no new views or routes in Hacktivity.**

Hacktivity's `application.html.erb` already suppresses navigation and footer when `params.has_key?(:embedded)` (lines 59 and 66).

| Surface | Iframe destination | Hacktivity page | What the player sees |
|---|---|---|---|
| **vm-launcher minigame** | `vm_panel` engine route → redirect | `VmsController#show` (`?embedded=1`) | VNC console, power controls, flag submission for one VM |
| **VM HUD panel** | `vm_set_panel` engine route → redirect | `VmSetsController#show` (`?embedded=1`) | vm_set-level controls: activate, extend timer, deactivate, relinquish |

Both pages carry ActionCable subscriptions that push live VM state. The vm_set show page also includes a countdown timer and all lifecycle controls that would otherwise need reimplementing in Phaser.

**Engine `vm_set_panel` action** (`app/controllers/break_escape/games_controller.rb`):

```ruby
# GET /games/:id/vm_set_panel
# Redirects to the Hacktivity vm_set show page with ?embedded=1.
# Loaded in an iframe by the Phaser VM HUD panel.
def vm_set_panel
  authorize @game if defined?(Pundit)
  return head :not_found unless BreakEscape::Mission.hacktivity_mode? && @game.vm_set_id

  vm_set = defined?(::VmSet) ? ::VmSet.find_by(id: @game.vm_set_id) : nil
  return head :not_found unless vm_set

  # Nil-guard sec_gen_batch in case it was deleted by an admin after assignment.
  return head :not_found unless vm_set.sec_gen_batch
  batch = vm_set.sec_gen_batch
  event = batch.event
  # Nil-guard event — Event may have been hard-deleted by an admin.
  return head :not_found unless event

  redirect_to Rails.application.routes.url_helpers.event_sec_gen_batch_vm_set_path(
    event,
    batch,
    vm_set,
    embedded: 1
  )
end
```

Note: `sec_gen_batches` uses `path: "challenges"` in Hacktivity's routes, so the generated URL will contain `/challenges/` — this is correct and matches the live URLs. The helper name `event_sec_gen_batch_vm_set_path` remains unchanged.

**HUD panel behaviour:**
1. If `vmSetPanelUrl` is present: Phaser opens an iframe pointing to `vmSetPanelUrl`. All vm_set controls (including the countdown and relinquish button) are handled by the Hacktivity page.
2. If `vmSetPanelUrl` is absent (standalone / VM-free mission): HUD button is hidden.
3. The `vm_status` JSON endpoint (Phase 4.4.1) is still polled for HUD **icon** colour-coding, since the icon is visible when the panel is closed.

**Relinquish warning when embedded:** The `VmSetsController#show` partial renders a Relinquish button. Relinquishing is permanent and will leave `BreakEscape::Game#vm_set_id` pointing at a relinquished (now-freed) VmSet, making the game unrecoverable. When `?embedded` is present, display a prominent warning above the Relinquish button explaining that relinquishing will end the game session. Do not hide the button — players may legitimately want to relinquish to manage their quota.

**`app/views/vm_sets/_vm_set.html.erb`** (or the relevant partial) — add around the relinquish button:

```erb
<% if params.has_key?(:embedded) %>
  <div class="alert alert-warning">
    <strong>Warning:</strong> Relinquishing your VMs will permanently end your game session.
    Your progress may not be saved.
  </div>
<% end %>
```

**X-Frame-Options headers (Hacktivity):** Both `VmsController` and `VmSetsController` must explicitly set `X-Frame-Options: SAMEORIGIN` when `?embedded` is present. This makes the iframe intent explicit and safe regardless of global header configuration.

**`app/controllers/vms_controller.rb`** and **`app/controllers/vm_sets_controller.rb`** — add:

```ruby
before_action :allow_iframe_embedding, only: :show

private

def allow_iframe_embedding
  return unless params.has_key?(:embedded)
  response.headers['X-Frame-Options'] = 'SAMEORIGIN'
end
```

#### 4.4.4 — Gating VM console access via `enable_console`

**Repos: Hacktivity (start/restart) + BreakEscape engine (vm_panel)**

`VmsController#show` is not currently used within Hacktivity itself. The `enable_console` field on `Vm` already controls whether the VNC/console button is rendered — VMs whose title contains "server" have it set to `false` by SecGen at creation; others default to `true`. For BreakEscape games we repurpose this field as a game-state gate: console access is locked until the player has legitimately reached the vm_launcher object in the game.

**The mechanism:**

| Event | Action |
|---|---|
| Game starts (`GameSlotsController#start`) | Set `enable_console = false` on all VMs in the assigned VmSet |
| Player hits `vm_panel` engine action (i.e. they've reached the terminal in-game) | Set `enable_console = true` for the specific VM being accessed |
| Game restarts (`GameSlotsController#restart`) | Reset `enable_console = false` on all VMs (player must re-navigate to the terminal) |

**`enable_console` is a UI gate only.** It is checked during authorisation and in `VmsController#show` to decide whether to render the VNC/console controls. It is not synced to a hypervisor console permission via any `after_save`/`after_commit` callback. Using `update_all` and `update_column` (which bypass callbacks) is therefore correct and intentional — the column controls what the Hacktivity view renders, not what the hypervisor allows.

**No change to `VmsController#show`.** If the player navigates to the VM URL directly before reaching the terminal, they can see the VM page but the VNC/console controls won't render (`enable_console: false`). After they've accessed it through the game, direct access is fine.

**In `GameSlotsController#start`** — after `create_game_for_listing` returns successfully (before or alongside eager activation):

```ruby
# Lock console access until player reaches the vm_launcher in-game.
if outcome.game.vm_set_id && defined?(::VmSet)
  ::VmSet.find_by(id: outcome.game.vm_set_id)&.vms&.update_all(enable_console: false)
end
```

**In `GameSlotsController#restart`** — alongside the existing VM revert dispatch:

```ruby
# Re-lock console access on restart so the player must re-navigate to the terminal.
vm_set&.vms&.update_all(enable_console: false)
```

**In the engine's `vm_panel` action** — immediately before the redirect:

```ruby
# Player has legitimately reached this VM terminal in-game. Enable console access.
vm.update_column(:enable_console, true)
```

**Behaviour summary:**
- Player starts a BreakEscape game → all VMs locked (`enable_console: false`)
- Player navigates directly to the VM URL → sees VM page, but no VNC button
- Player reaches the vm_launcher terminal in-game → `vm_panel` action fires, `enable_console` set to `true`, iframe loads with full console access
- Player revisits the VM URL directly afterwards → fine, `enable_console` is already `true`
- Player restarts → all VMs locked again

**File changes (Phase 4.4.3–4.4.4):**

| File | Repo | Change |
|---|---|---|
| `config/routes.rb` | BreakEscape | `get 'vm_set_panel'` already declared in Phase 1.6; action body added here |
| `app/controllers/break_escape/games_controller.rb` | BreakEscape | Add `vm_set_panel` action; `enable_console` unlock and status/event nil-guards in `vm_panel` |
| `app/controllers/game_slots_controller.rb` | Hacktivity | `start`: lock all VMs on game creation; `restart`: re-lock on reset |
| `app/controllers/vms_controller.rb` | Hacktivity | Add `allow_iframe_embedding` before_action on `show` |
| `app/controllers/vm_sets_controller.rb` | Hacktivity | Add `allow_iframe_embedding` before_action on `show` |
| `app/views/vm_sets/_vm_set.html.erb` (or relevant partial) | Hacktivity | Add embedded relinquish warning above the Relinquish button |

---

### 4.5 — Policy Tests

**`test/policies/break_escape/game_policy_test.rb`** (engine, within Hacktivity's cross-engine suite) — add for `vm_panel?` and `vm_set_panel?` (these are pure unit tests with no model dependency beyond `BreakEscape::Game`):

- `vm_panel?` — owner with `status: 'in_progress'` → `true`
- `vm_panel?` — non-owner → `false`
- `vm_panel?` — admin → `true`
- `vm_panel?` — owner with `status: 'completed'` → `false`
- `vm_set_panel?` — same four cases

These mirror the Phase 1.7 engine policy tests but are specified here for completeness in the Hacktivity test pass.

---

**`test/policies/game_slot_policy_test.rb`** — follow the pattern in `event_policy_test.rb`:

**`start?`:**
- Signed-up user + available listing → permit
- Signed-up user + `release_at` in future → deny
- Non-signed-up user → deny
- User with org access revoked → deny
- Admin + unreleased listing → permit (admin bypass)

**`restart?`:**
- Signed-up user, listing owner → permit
- Non-signed-up user → deny
- User enrolled in event but for a different game slot → deny (cannot restart someone else's slot)

**`vm_status?`, `extend_vms?`, `shutdown_vms?`, `finish?`** (all delegate to `start?`):
- Signed-up user → permit
- Non-signed-up user → deny
- User enrolled in a *different* event → deny
- Admin → permit

**Cross-player isolation (all actions):**
- User A calls any action scoped to User B's game slot (same event, different slot owner) → deny
  - Verify each of: `start?`, `restart?`, `vm_status?`, `extend_vms?`, `shutdown_vms?`, `finish?`

**Admin CRUD permissions** (index, show, create, update, destroy on GameSlot):
- Admin → permit all
- Regular user → deny all

### 4.6 — Controller Tests

**Cross-engine test strategy:** Treat BreakEscape as a fully mounted engine. The engine's migrations must run in the test database (`rails db:test:prepare` after adding the gem dependency). Add `break_escape_missions` and `break_escape_games` to Hacktivity's `test/fixtures/` directory. This is consistent with how the engine's own test suite works.

**`test/controllers/game_slots_controller_test.rb`:**

**`start` — functional:**
- Enrolled user, VM-backed: assigns VmSet, creates Game, enrolls Result, redirects to game
- Enrolled user, VM-free: creates Game (no VmSet), redirects to game
- Enrolled user: existing in_progress game → redirects without creating new game
- VmSet not available: flash error, no Game created, no Result created
- Race condition (happy path): `RecordNotUnique` rescued, redirects to existing game
- Race condition (fallback): `RecordNotUnique` rescued, `active_game_for` also nil → flash error
- VM-backed mission (any `vm_activation_mode`): VMs NOT activated at start (eager activation deferred to Phase 2); all VMs have `enable_console = false`

**`start` — security:**
- Unauthenticated → redirect (not 404)
- Authenticated, not enrolled in event → denied (Pundit)
- `release_at` in future → denied
- User A cannot start a slot that belongs to a different event → denied (slot scoped to event)

**`restart` — functional:**
- Resets game state; triggers DispatchVmCtrlService (VM revert) for VM-backed missions
- VM revert: all VMs in set reset to `enable_console = false`. **Setup: VMs must start with `enable_console: true` in fixtures to verify the reset actually fires.** Add `enable_console: true` to the relevant `vms` fixture entries before this test.
- VMs not powered down → flash error, no revert, no state reset, no `enable_console` change
- No active game → flash error (completed game case)
- VM-free → resets state, no DispatchVmCtrlService call

**`restart` — security:**
- Unauthenticated → redirect
- User B cannot restart User A's active game on the same slot → denied

**`vm_status` — functional:**
- Returns JSON: `vm_activation_mode`, `activated`, `activated_until`, `vms` array
- No active game → 404 JSON
- VM-free mission (no VmSet) → `activated: false`, `vms: []`

**`vm_status` — security:**
- Unauthenticated → redirect/denied (not JSON 200)
- User B cannot poll User A's VM status on the same slot → denied

**`extend_vms` — functional:**
- First call (not yet activated): dispatches activate to each VM; sets `activated = true`, `activated_until` (timer start for user's tier)
- Second call (already activated): extends `activated_until` (extend timer for user's tier); does NOT redispatch activate. **Stub `DispatchVmCtrlService.ctrl_vm_async` and assert it is not called on the second request.**
- No active game → 422

**`extend_vms` — security:**
- Unauthenticated → redirect/denied
- User B cannot activate User A's VMs → denied

**`shutdown_vms` — functional:**
- Dispatches stop to each VM; returns `{ ok: true }`
- No active game → 422

**`shutdown_vms` — security:**
- Unauthenticated → redirect/denied
- User B cannot shut down User A's VMs → denied

**`finish` — functional:**
- Marks game `completed`; enqueues `RelinquishVmSetJob` with correct `vm_set_id` (asserted with `assert_enqueued_with`)
- `RelinquishVmSetJob` enqueued OUTSIDE transaction (assert job is in queue after action, not inline)
- Game already completed (no active in_progress game) → 422
- VM-free mission → marks game completed; no `RelinquishVmSetJob` enqueued
- Returns `{ ok: true, redirect_url: event_path }` JSON

**`finish` — security:**
- Unauthenticated → redirect/denied
- User B cannot finish User A's game → denied

**`vm_panel` (engine action, tested in Hacktivity suite) — authentication:**
- Unauthenticated request → 401/redirect (not 404 — must not leak game existence)

**`vm_panel` — authorisation:**
- Player who owns the game (status: `in_progress`) → proceeds normally
- Player who does NOT own the game → Pundit denied (403 or redirect to root)
- Admin → allowed
- Owner whose game has `status: 'completed'` → denied (policy check; returns 404 from status guard)

**`vm_panel` — functional:**
- Valid request (game with vm_set, matching vm_title) → sets `vm.enable_console = true`, `assert_response :redirect`
- `vm_title` param matches VM → only that VM's `enable_console` is `true`; other VMs in the set remain `false`
- `vm_title` param does not match any VM → 404, no `enable_console` change
- No `vm_title` param → falls back to `vms.first`, sets its `enable_console = true`
- Game has no `vm_set_id` → 404
- `vm_set.sec_gen_batch` is nil → 404, no `enable_console` change
- `vm_set.sec_gen_batch.event` is nil → 404, no `enable_console` change
- `hacktivity_mode? = false` (standalone) → 404, no `enable_console` change
- Redirect URL contains `embedded=1`
- Redirect URL contains correct event/batch/vm_set/vm ids (not another player's)
- `vm_panel` called when game `status == 'completed'` → 404/denied, no `enable_console` change

**`vm_set_panel` — authentication:**
- Unauthenticated → 401/redirect

**`vm_set_panel` — authorisation:**
- Owner with `status: 'in_progress'` → allowed
- Non-owner → denied
- Admin → allowed
- Owner with `status: 'completed'` → denied

**`vm_set_panel` — functional:**
- Valid request → `assert_response :redirect`; redirect URL contains `embedded=1` and correct event/batch/vm_set ids
- Game has no `vm_set_id` → 404
- `vm_set.sec_gen_batch` is nil → 404
- `vm_set.sec_gen_batch.event` is nil → 404
- `hacktivity_mode? = false` → 404

**`enable_console` locking via `vm_panel` — integration:**
- Player hits `vm_panel` for VM "kali" while VMs are locked → `kali.enable_console` becomes `true`; other VMs (e.g. "server-web") remain `false`
- `vm_panel` called twice for the same VM → idempotent (no error, `enable_console` stays `true`)
- `vm_panel` called after `restart` with game still `in_progress` → succeeds, VM unlocked
- `vm_panel` called after game `completed` → denied/404, `enable_console` unchanged

**`enable_console` locking — integration:**
- After `start` (VM-backed): all VMs in the assigned VmSet have `enable_console = false` (regardless of their original SecGen value). **Setup: fixtures must have `enable_console: true` before the action fires, so the assertion proves the reset path ran.**
- After `restart`: all VMs in the VmSet reset to `enable_console = false`. Same fixture requirement.

**`hidden_from_players`:**
- Batch with `hidden_from_players: true` does NOT appear in regular event show view
- Batch with `hidden_from_players: true` DOES appear in admin event show view

### 4.7 — VmsController Security Tests (Hacktivity)

**`test/controllers/vms_controller_test.rb`** — add cases covering BreakEscape game context:

**`show` — authentication:**
- Unauthenticated request → redirect to sign-in (not 200)

**`show` — authorisation:**
- Player who owns the VmSet → 200
- Player who does NOT own the VmSet → denied (Pundit/redirect)
- Admin → 200 regardless

**`show` — `enable_console` display:**
- VM with `enable_console: true` → VNC/console controls are rendered in the response body
- VM with `enable_console: false` → VNC/console controls are NOT rendered

**Selector note (TEST-v4-5):** Before writing these tests, inspect `app/views/vms/show.html.erb` (and any partials it renders) to find the exact HTML element that represents the VNC/console button. Identify a stable selector — a CSS class, `data-*` attribute, or link text — and use `assert_select` or `assert_no_match` on that selector. If no stable identifier exists, add `data-testid="vnc-button"` (or equivalent) to the view as a prerequisite step in this phase before writing the tests.

**`show` — BreakEscape game context (cross-engine):**
- Player's VM with `enable_console: false` (game not yet reached terminal) → can load the page (200), but VNC button absent. State: set `vm.enable_console = false` directly in the fixture or test setup.
- After vm_panel fires (simulate: call `vm.update_column(:enable_console, true)` directly in test setup — this is a state assertion test, not a `vm_panel` action test) → VNC button present on next `VmsController#show` load
- Player cannot load a VM that belongs to another player's VmSet → denied

**Note on fixture strategy:** These tests require `break_escape_games` and `break_escape_missions` fixtures in Hacktivity. Ensure `break_escape_games.yml` includes `vm_set_id` pointing to a valid `vm_sets` fixture entry. See Phase 4.6 cross-engine fixture notes.

---

## Phase 5 — Hacktivity: Event Show View

**Repo: Hacktivity**

### 5.1 — EventsController

**`app/controllers/events_controller.rb`** — in `show`:
```ruby
if @event.hacktivity_type_game?
  @game_slots = @event.game_slots
                            .includes(:break_escape_mission, :sec_gen_batch)
                            .ordered
  if current_user
    mission_ids = @game_slots.map(&:break_escape_mission_id)
    # Order by created_at DESC before index_by so the most recent game wins
    # when a user has multiple games for the same mission.
    @user_games = BreakEscape::Game.where(player: current_user, mission_id: mission_ids)
                                   .order(created_at: :desc)
                                   .index_by(&:mission_id)
  end
else
  # existing non-hidden batch loading for non-game events
  @sec_gen_batches = @event.sec_gen_batches
  @sec_gen_batches = @sec_gen_batches.where(hidden_from_players: false) unless current_user&.admin?
end
```

### 5.2 — Event Show Page

**`app/views/events/show.html.erb`:**
```erb
<% if @event.hacktivity_type_game? %>
  <%= render 'events/game_slots', event: @event,
                                        game_slots: @game_slots,
                                        user_games: @user_games %>
<% else %>
  <%# existing sec_gen_batches rendering %>
<% end %>
```

### 5.3 — Mission Listings Partial

**`app/views/events/_game_slots.html.erb`** — render each listing as a card:
- Mission `display_name`, `description`, difficulty badge
- Release status: "Coming soon" if `release_at` is in the future
- User's game status (in_progress / completed / not started) from `user_games[listing.break_escape_mission_id]`
- "Start Mission" / "Continue" button → `start_event_game_slot_path`
- "Restart" button (if game in_progress) → `restart_event_game_slot_path`

---

## Phase 6 — Hacktivity: Admin UI

**Repo: Hacktivity**

### 6.1 — SecGenBatch Form

Add `hidden_from_players` checkbox to `app/views/sec_gen_batches/_form.html.erb` and `_update_form.html.erb`. Add label note: "Hidden batches are excluded from the event challenge list but still count toward scoring."

Update strong params in `SecGenBatchesController` to permit `:hidden_from_players`.

### 6.2 — GameSlot Admin

New controller and views nested under events in the admin namespace:

**Routes:**
```ruby
namespace :admin do
  resources :events do
    resources :game_slots
  end
end
```

Form fields: event (pre-filled), BreakEscape::Mission picker (`BreakEscape::Mission.published.order(:display_name)`), SecGenBatch picker (event's batches, blank = VM-free), position, release_at.

### 6.3 — Event Form

Add `game` option to the `type_of_hacktivity` select.

### 6.4 — Event Copy: Handle GameSlots

The `copy_event` workflow must copy `GameSlot` rows. **This is not deferrable** — copying a game-type event without GameSlots produces a silently empty event.

In the event copy logic (wherever `copy_event_form` / `copy_event` is handled):
- Detect if source event has `game_slots`
- For each listing, create a new `GameSlot` with the same `break_escape_mission_id`, `position`, and `release_at` (adjusted by `weeks_offset_for_dates` if the copy form provides it)
- Set `sec_gen_batch_id: nil` on copied listings — the new event will get new batches built, which the admin then links manually (or automatically if the batch was also copied)
- Surface a notice in the copy confirmation: "This event has N mission listings. They have been copied with VM assignments cleared. Please create new SecGenBatches and link them to the copied listings."

**Tests for event copy** (`test/controllers/events_controller_test.rb` or dedicated copy test):
- Copying a game-type event: GameSlot rows are created on the new event (one per listing)
- Copied listings have the same `break_escape_mission_id` as the originals
- Copied listings have `sec_gen_batch_id: nil`
- Copied listings with non-nil `release_at` have it shifted by `weeks_offset_for_dates`
- Copying a non-game event: no GameSlot rows created (no regression)

---

## Phase 7 — Scoring Integration

**Repo: Hacktivity** (initializer + new job) and **BreakEscape** (hook from Phase 1.2 already in place)

### 7.1 — `GameCompletionScoringJob`

**`app/jobs/game_completion_scoring_job.rb`:**
```ruby
class GameCompletionScoringJob < ApplicationJob
  queue_as :default

  def perform(game_id, vm_set_id)
    return unless vm_set_id

    vm_set = VmSet.find_by(id: vm_set_id)
    return unless vm_set

    # nil-guard sec_gen_batch: admin may have deleted the batch after event close.
    # If the batch is gone, scoring is meaningless — exit cleanly rather than raise.
    sec_gen_batch = vm_set.sec_gen_batch
    return unless sec_gen_batch

    # Lock the VmSet row to prevent a race between a concurrent job run and
    # a simultaneous flag submission that also updates score.
    vm_set.with_lock do
      # Only set completion score if not already scored by FlagService during gameplay.
      # This is intentionally a nil-OR-zero check: both nil and 0.0 mean "unscored".
      # result.calculate is called unconditionally — it must run even when the score
      # was already set (e.g. by flags) so the Result total stays correct.
      if vm_set.score.nil? || vm_set.score.zero?
        vm_set.update_column(:score, 100.0)
      end
    end

    # result.calculate is outside the vm_set lock — it reads multiple rows and
    # locking a single vm_set is not sufficient to guard the whole calculation.
    # This is acceptable: Result#calculate is additive and idempotent.
    result = Result.find_by(user_id: vm_set.user_id, event: sec_gen_batch.event)
    result&.calculate
  end
end
```

### 7.2 — Configure Hook in Hacktivity

**`config/initializers/break_escape.rb`:**
```ruby
BreakEscape.configure do |config|
  config.standalone_mode = false

  config.on_game_complete = lambda do |game|
    return unless game.vm_set_id
    GameCompletionScoringJob.perform_later(game.id, game.vm_set_id)
  end
end
```

Key: the lambda does nothing for VM-free games (no `vm_set_id`). The actual scoring work happens asynchronously in the job.

### 7.3 — Write `Result#calculate` Test

`ResultTest` currently skips this test. Write it now — the scoring integration depends on it:

**`test/models/result_test.rb`** — remove skip, add:
- Single vm_set with score → result total correct
- Multiple batches, best score used per batch
- vm_set with nil score → treated as 0
- `hidden_from_players` batch still included in calculation

### 7.4 — Scoring Hook Tests (Hacktivity)

**`test/jobs/game_completion_scoring_job_test.rb`:**
- Success: finds vm_set, sets score to 100.0, calls result.calculate
- vm_set score is `nil`: sets to 100.0 (nil branch tested explicitly)
- vm_set score is `0.0`: sets to 100.0 (zero branch tested explicitly)
- vm_set score already > 0 (e.g. 60.0 from flags): does NOT overwrite score
- vm_set score already > 0: result.calculate IS still called (unconditional)
- vm_set_id nil: exits cleanly without error (VM-free game path)
- vm_set not found: exits cleanly without error
- sec_gen_batch nil (batch deleted): exits cleanly without error
- No Result for user+event: exits cleanly without error (`result&.calculate` nil guard)

**`test/initializers/break_escape_initializer_test.rb`** (or integrate into job tests):
- Lambda enqueues `GameCompletionScoringJob` with correct args on game completion
- Lambda does not enqueue for VM-free game (nil vm_set_id)

---

## Phase 8 — Final Test Pass + Smoke Test

**Both repos.**

### 8.1 — Full Test Suites

```bash
# BreakEscape
rails test

# Hacktivity
rails test
```

Phase 8 is a gate — no new tests are written here. All tests should already exist from their respective phases.

### 8.2 — Manual Smoke Test

1. Create a game-type event in admin
2. Create a SecGenBatch (`hidden_from_players: true`) linked to the event; confirm it does NOT appear in the event challenge list for a regular user but DOES appear for an admin
3. Create a GameSlot linking the batch + a BreakEscape::Mission with `release_at` in the future; visit the event and confirm "Coming soon" state
4. Set `release_at` to now; confirm "Start Mission" button appears
5. Sign up as a test user; click "Start Mission" on an **eager** mission — confirm VmSet assigned, Game created, VMs activated (`vm_set.activated: true`, `activated_until` set), redirected to game UI
6. Verify VM HUD button appears in-game (green icon if VMs are up, with a tooltip/label). Click it — confirm the vm_set controls partial loads in the iframe panel showing per-VM state and controls
7. Click **Activate/Extend** in the HUD panel iframe — verify `activated_until` is pushed forward in the database
8. Click **Deactivate** in the HUD panel iframe — verify VMs receive stop dispatch; HUD icon turns red
9. Click **Relinquish** in the HUD panel iframe — confirm dialog; verify `RelinquishVmSetJob` is enqueued and VmSet eventually `relinquished: true`; verify Game marked `completed` (check via finish endpoint separately)
10. Interact with a vm-launcher terminal object — confirm the individual VM iframe loads (VNC/console visible); confirm ActionCable subscription is active
11. Create a second GameSlot with `vm_activation_mode: 'lazy'`; start it — verify VMs assigned but NOT activated (no `extend_vms` call at start). Enter game; trigger a `requiresVM` interaction — verify HUD fires `extend_vms`, VMs activate; verify `activated_until` is now set; vm-launcher iframe shows VM spinning up via ActionCable
12. Solve a CTF flag challenge in-game — verify FlagService updates `vm_set.score` and `Result` is updated
13. Complete the game narrative via status update (not HUD finish) — verify `GameCompletionScoringJob` is enqueued; verify `Result.find_by(user:, event:).score` updates (check console)
14. Click "Restart" — verify VMs revert is triggered (DispatchVmCtrlService called), game state resets, `vm_set_id` preserved
15. Create a VM-free GameSlot (no SecGenBatch); start it — verify Game created, no VmSet assigned, HUD button NOT rendered, vm-launcher terminal shows standalone instructions
16. Complete the VM-free game; verify `on_game_complete` lambda exits cleanly without error (check logs for no exception)
17. Copy the game-type event; verify GameSlots are copied with `sec_gen_batch_id: nil` and a notice is shown
18. Double-submit "Start Mission" (two rapid POSTs); verify only one Game and one VmSet assignment exist

---

## File Change Summary

### BreakEscape (engine repo)

| File | Change |
|---|---|
| `db/migrate/TIMESTAMP_add_vm_set_id_to_break_escape_games.rb` | Column, partial unique index, backfill |
| `db/migrate/TIMESTAMP_add_vm_activation_mode_to_break_escape_missions.rb` | `vm_activation_mode` string column, default `'eager'` |
| `app/models/break_escape/game.rb` | `sync_vm_set_id_column`, `fire_completion_callback`, `after_commit` |
| `app/models/break_escape/mission.rb` | `vm_activation_mode` validation, `has_many :game_slots` behind `defined?` guard |
| `lib/break_escape.rb` | Add `on_game_complete` config option |
| `config/routes.rb` | Add `get 'vm_panel'` and `get 'vm_set_panel'` to games member block |
| `app/controllers/break_escape/games_controller.rb` | Add `vm_panel` (unlocks `enable_console`, event nil-guard, status race-guard, redirects to VM page) and `vm_set_panel` (event nil-guard, redirects to vm_set page) actions; both on before_action list |
| `app/policies/break_escape/game_policy.rb` | Add `vm_panel?` and `vm_set_panel?` methods (owner + `status == 'in_progress'` guard) |
| `app/views/break_escape/games/show.html.erb` | Add `vmPanelUrl`, `vmSetPanelUrl`, and `vmActivationMode` to `window.breakEscapeConfig` |
| `public/break_escape/js/minigames/vm-launcher/vm-launcher-minigame.js` | Iframe branch for Hacktivity mode in `buildUI()` |
| `public/break_escape/css/vm-launcher-minigame.css` | `.vm-launcher-iframe` styles |
| `app/javascript/break_escape/hud/vm_hud.js` | **New** — Phaser VM HUD component (icon + iframe panel) |
| `app/javascript/break_escape/hud/index.js` | Export `VmHud` |
| `app/javascript/break_escape/scenes/game_scene.js` | Instantiate `VmHud` alongside music button |
| `app/javascript/break_escape/config.js` | Accept VM endpoint URLs from scenario data |
| `test/models/break_escape/game_test.rb` | New tests for above |
| `test/models/break_escape/mission_test.rb` | Tests for `vm_activation_mode` validation |
| `test/policies/break_escape/game_policy_test.rb` | **New tests** — `vm_panel?` and `vm_set_panel?` policy unit tests (standalone-mode 404 only in engine suite; full auth/ownership/functional tests in Hacktivity suite) |
| `test/controllers/break_escape/games_controller_test.rb` | Standalone-mode 404 tests for `vm_panel` and `vm_set_panel` only (full tests in Hacktivity suite) |

### Hacktivity (host repo)

| File | Change |
|---|---|
| `config/routes.rb` | Mount engine + add `game_slots` routes |
| `db/migrate/TIMESTAMP_add_hidden_from_players_to_sec_gen_batches.rb` | New column |
| `db/migrate/TIMESTAMP_create_game_slots.rb` | New table + FK |
| `app/models/event.rb` | Add `game` enum value (model only), `has_many :game_slots` |
| `app/models/sec_gen_batch.rb` | `has_one :game_slot` |
| `app/models/game_slot.rb` | **New model** |
| `app/services/vm_set_assignment_service.rb` | **New service** (extracted from `SecGenBatchesController`) |
| `app/services/vm_set_activation_service.rb` | **New service** (extracted from `VmSetsController#activate` private method; shared by `VmSetsController` and `GameSlotsController#extend_vms`) |
| `app/controllers/sec_gen_batches_controller.rb` | Use `VmSetAssignmentService` for individual path |
| `app/controllers/game_slots_controller.rb` | **New controller** — start (locks `enable_console = false`; no eager activation in MVP), restart (re-locks), vm_status, extend_vms (delegates all activation logic to `VmSetActivationService`), shutdown_vms, finish (rescues `EnqueueError`); `Outcome` at class scope |
| `app/controllers/vms_controller.rb` | Add `allow_iframe_embedding` before_action on `show` (sets `X-Frame-Options: SAMEORIGIN` when `?embedded`) |
| `app/controllers/vm_sets_controller.rb` | `activate` private method delegates to `VmSetActivationService`; add `allow_iframe_embedding` before_action on `show` |
| `app/views/vm_sets/_vm_set.html.erb` (or relevant partial) | Add embedded relinquish warning when `params.has_key?(:embedded)` |
| `app/controllers/events_controller.rb` | Load game_slots for game type, @user_games |
| `app/jobs/game_completion_scoring_job.rb` | **New job** (with sec_gen_batch nil-guard, with_lock, unconditional calculate) |
| `app/policies/game_slot_policy.rb` | **New policy** |
| `config/initializers/break_escape.rb` | Configure `on_game_complete` hook |
| `app/views/events/show.html.erb` | Branch for game type |
| `app/views/events/_game_slots.html.erb` | **New partial** |
| `app/views/sec_gen_batches/_form.html.erb` | `hidden_from_players` field |
| `app/views/admin/game_slots/` | **New admin views** |
| `test/fixtures/break_escape_missions.yml` | **New fixture** (cross-engine test support) |
| `test/fixtures/break_escape_games.yml` | **New fixture** (cross-engine test support) |
| `test/services/vm_set_assignment_service_test.rb` | **New tests** (written BEFORE extraction in Phase 2.2) |
| `test/services/vm_set_activation_service_test.rb` | **New tests** (written BEFORE extraction in Phase 2.6) |
| `test/models/game_slot_test.rb` | **New tests** |
| `test/models/result_test.rb` | Remove skip, implement `calculate` test |
| `test/controllers/game_slots_controller_test.rb` | **New tests** (functional + security for all actions; includes full `vm_panel`/`vm_set_panel` auth/ownership/functional tests moved from engine Phase 1.7) |
| `test/controllers/vms_controller_test.rb` | Extend with `enable_console` display + BreakEscape cross-player cases; add VNC selector assertions (inspect `vms/show.html.erb` for selector) |
| `test/policies/game_slot_policy_test.rb` | **New tests** (all policy methods + cross-player isolation) |
| `test/jobs/game_completion_scoring_job_test.rb` | **New tests** |

---

## Known Limitations / Deferred

| Item | Notes |
|---|---|
| VM-free Result scoring | VM-free games have no VmSet; `Result#calculate` returns 0 for those listings. Acceptable for MVP; track as known gap. |
| Restarting completed games | `active_game_for` filters `in_progress` only; completed games cannot be restarted. Document in UI. |
| Team-shared VM sets | `vm_sets_shared_by_team` not supported for game missions; only individual assignment. |
| Admin re-hiding a linked SecGenBatch | Toggling `hidden_from_players` back to false on a batch that has a GameSlot will expose the raw batch. Add an admin warning if `game_slot.present?`. |
| Copied listings without SecGenBatch | Listings copied with `sec_gen_batch_id: nil` can be accidentally started as VM-free games if the admin publishes before linking new batches. Add a draft/unpublished state to GameSlot, or add an admin warning on publish if any listing has no batch and the mission requires VMs. |
| Drag-and-drop mission ordering | Manual integer `position` is sufficient for now; `acts_as_list` can be added if needed. |
| Eager VM activation at game start | `vm_activation_mode == 'eager'` is stored but not acted on in MVP. Both eager and lazy missions activate VMs on the player's first `requiresVM` interaction. True eager activation (VMs started at game start) is Phase 2 work. |
| Configurable `vm_panel_url_for` callbacks | `vm_panel` and `vm_set_panel` hard-code Hacktivity's nested route structure (`event_sec_gen_batch_vm_set_vm_path`). If Hacktivity's routes are ever refactored, these engine actions will break. A configurable-callback pattern (`BreakEscape.config.vm_panel_url_for`) is the correct long-term fix; deferred to Phase 2 (ARCH-v4-1 TODO). |
| Relinquish during active game | Player can relinquish their VmSet from the HUD panel iframe mid-game. A warning is shown when embedded, but the action is not blocked — players may legitimately want to relinquish to manage quota. After relinquish, `vm_set_id` points to a freed VmSet; `vm_panel` and `vm_status` will return 404 for the rest of that session. |
| VM HUD heartbeat auto-extension | Automatic timer extension (extend before expiry without user clicking) is deferred to a second sprint. Requires a client-side timer and a pre-expiry POST to `extend_vms`. |
| VM HUD mobile / small canvas | HUD layout assumes desktop canvas dimensions. Mobile responsiveness is deferred. |
| `extend_vms` — Proxmox `prepare_to_activate` | `VmSetsController#activate` calls `prepare_to_activate` for Proxmox VmSets (node selection). `extend_vms` does not replicate this call; BreakEscape VmSets must be pre-prepared or the Proxmox path may fail silently. Deferred; document in operational runbook. |
| vm_set show page admin rows | `_vm_set.html.erb` includes admin-only debug rows already guarded by `current_user.try(:admin?)`. Players see only player-facing controls; verify in smoke test. |
| `enable_console` and server VMs | SecGen sets `enable_console: false` for VMs whose title contains "server". The game-start lock (`update_all enable_console: false`) overwrites this for all VMs. On restart the same lock re-applies. This is correct — server VMs should never expose a console to the player regardless of game state. |
| `enable_console` persistence after relinquish | `RelinquishVmSetJob` duplicates the vm_set and resets field values. The `enable_console` values on the duplicated (released) vm_set are copied from the original at relinquish time. If the job runs after the player has unlocked console access, the released vm_set may have `enable_console: true` for non-server VMs. This is acceptable — the released vm_set is reassigned to another pool user and will be reset through normal SecGen processing. |
