/**
 * Flag Station Minigame
 * 
 * CTF flag submission interface.
 * Players can submit flags they've found and receive in-game rewards.
 */

import { MinigameScene } from '../framework/base-minigame.js';

export class FlagStationMinigame extends MinigameScene {
    constructor(container, params) {
        super(container, params);
        this.stationId = params.stationId || 'flag-station';
        this.stationName = params.stationName || 'Flag Submission Terminal';
        this.expectedFlags = params.flags || [];
        this.acceptsVms = params.acceptsVms || []; // List of VM names whose flags are accepted
        this.submittedFlags = params.submittedFlags || window.gameState?.submittedFlags || [];
        this.gameId = params.gameId || window.breakEscapeConfig?.gameId || window.gameConfig?.gameId;
        this.isSubmitting = false;
    }
    
    init() {
        this.params.title = this.stationName;
        this.params.cancelText = 'Close';
        super.init();
        this.buildUI();
    }
    
    buildUI() {
        // Add custom styles
        const style = document.createElement('style');
        style.textContent = `
            .flag-station {
                padding: 20px;
                font-family: 'VT323', 'Courier New', monospace;
            }
            
            .flag-station-header {
                text-align: center;
                margin-bottom: 20px;
            }
            
            .flag-station-icon {
                font-size: 48px;
                margin-bottom: 10px;
            }
            
            .flag-station-description {
                color: #888;
                font-size: 14px;
                line-height: 1.4;
            }
            
            .flag-input-container {
                margin: 20px 0;
            }
            
            .flag-input-label {
                display: block;
                color: #00ff00;
                margin-bottom: 8px;
                font-size: 14px;
            }
            
            .flag-input-wrapper {
                display: flex;
                gap: 10px;
            }
            
            .flag-input {
                flex: 1;
                background: #000;
                border: 2px solid #333;
                color: #00ff00;
                padding: 12px 15px;
                font-family: 'Courier New', monospace;
                font-size: 16px;
                outline: none;
            }
            
            .flag-input:focus {
                border-color: #00ff00;
            }
            
            .flag-input::placeholder {
                color: #444;
            }
            
            .flag-submit-btn {
                background: #00aa00;
                color: #fff;
                border: 2px solid #000;
                padding: 12px 20px;
                font-family: 'Press Start 2P', monospace;
                font-size: 11px;
                cursor: pointer;
                white-space: nowrap;
            }
            
            .flag-submit-btn:hover:not(:disabled) {
                background: #00cc00;
            }
            
            .flag-submit-btn:disabled {
                background: #333;
                color: #666;
                cursor: not-allowed;
            }
            
            .flag-result {
                margin-top: 15px;
                padding: 15px;
                text-align: center;
                font-size: 14px;
                display: none;
            }
            
            .flag-result.success {
                display: block;
                background: rgba(0, 170, 0, 0.2);
                border: 2px solid #00aa00;
                color: #00ff00;
            }
            
            .flag-result.error {
                display: block;
                background: rgba(170, 0, 0, 0.2);
                border: 2px solid #aa0000;
                color: #ff4444;
            }
            
            .flag-result.loading {
                display: block;
                background: rgba(255, 170, 0, 0.2);
                border: 2px solid #ffaa00;
                color: #ffaa00;
            }
            
            .flag-history {
                margin-top: 30px;
                border-top: 1px solid #333;
                padding-top: 20px;
            }
            
            .flag-history-title {
                color: #888;
                font-size: 12px;
                margin-bottom: 10px;
                text-transform: uppercase;
            }
            
            .flag-history-list {
                list-style: none;
                padding: 0;
                margin: 0;
                max-height: 150px;
                overflow-y: auto;
            }
            
            .flag-history-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 8px 12px;
                margin: 5px 0;
                background: rgba(0, 255, 0, 0.05);
                border-left: 3px solid #00aa00;
            }
            
            .flag-value {
                font-family: 'Courier New', monospace;
                color: #00ff00;
                font-size: 13px;
            }
            
            .flag-check {
                color: #00aa00;
            }
            
            .reward-notification {
                margin-top: 15px;
                padding: 15px;
                background: rgba(0, 136, 255, 0.1);
                border: 2px solid #0088ff;
                border-radius: 0;
            }
            
            .reward-notification h4 {
                color: #0088ff;
                margin: 0 0 10px 0;
                font-size: 14px;
            }
            
            .reward-item {
                display: flex;
                align-items: center;
                gap: 10px;
                color: #ccc;
                font-size: 13px;
                margin: 5px 0;
            }
            
            .reward-icon {
                font-size: 18px;
            }
            
            .no-flags-yet {
                color: #666;
                font-style: italic;
                font-size: 13px;
            }
            
            .accepts-vms {
                margin-top: 15px;
                display: flex;
                align-items: center;
                gap: 10px;
                flex-wrap: wrap;
                justify-content: center;
            }
            
            .accepts-label {
                color: #888;
                font-size: 12px;
            }
            
            .vm-badge {
                background: #00aa00;
                color: #000;
                padding: 4px 12px;
                font-size: 14px;
                font-weight: bold;
                font-family: 'Courier New', monospace;
            }
        `;
        this.gameContainer.appendChild(style);
        
        // Build main container
        const station = document.createElement('div');
        station.className = 'flag-station';
        station.innerHTML = this.buildStationContent();
        
        this.gameContainer.appendChild(station);
        this.attachEventHandlers();
    }
    
    buildStationContent() {
        const submittedCount = this.submittedFlags.length;
        const totalCount = this.expectedFlags.length;
        const progressText = totalCount > 0 
            ? `${submittedCount}/${totalCount} flags submitted` 
            : '';
        
        // Show which VMs' flags are accepted at this station
        const vmBadges = this.acceptsVms.length > 0
            ? `<div class="accepts-vms">
                <span class="accepts-label">Accepts flags from:</span>
                ${this.acceptsVms.map(vm => `<span class="vm-badge">${this.escapeHtml(vm)}</span>`).join('')}
               </div>`
            : '';
        
        return `
            <div class="flag-station-header">
                <div class="flag-station-icon">🏁</div>
                <p class="flag-station-description">
                    Enter captured CTF flags below to validate your findings.
                    ${progressText}
                </p>
                ${vmBadges}
            </div>
            
            <div class="flag-input-container">
                <label class="flag-input-label">Enter Flag:</label>
                <div class="flag-input-wrapper">
                    <input type="text" 
                           class="flag-input" 
                           id="flag-input" 
                           placeholder="flag{...}" 
                           autocomplete="off"
                           spellcheck="false">
                    <button class="flag-submit-btn" id="flag-submit-btn">SUBMIT</button>
                </div>
            </div>
            
            <div class="flag-result" id="flag-result"></div>
            <div class="reward-notification" id="reward-notification" style="display: none;"></div>
            
            <div class="flag-history">
                <div class="flag-history-title">Submitted Flags</div>
                <ul class="flag-history-list" id="flag-history-list">
                    ${this.buildFlagHistory()}
                </ul>
            </div>
        `;
    }
    
    buildFlagHistory() {
        if (this.submittedFlags.length === 0) {
            return '<li class="no-flags-yet">No flags submitted yet</li>';
        }
        
        return this.submittedFlags.map(flag => `
            <li class="flag-history-item">
                <span class="flag-value">${this.escapeHtml(flag)}</span>
                <span class="flag-check">✓</span>
            </li>
        `).join('');
    }
    
    attachEventHandlers() {
        const input = this.gameContainer.querySelector('#flag-input');
        const submitBtn = this.gameContainer.querySelector('#flag-submit-btn');
        
        // Submit on button click
        this.addEventListener(submitBtn, 'click', () => this.submitFlag());
        
        // Submit on Enter key
        this.addEventListener(input, 'keypress', (e) => {
            if (e.key === 'Enter') {
                this.submitFlag();
            }
        });
        
        // Focus input on start
        setTimeout(() => input.focus(), 100);
    }
    
    async submitFlag() {
        if (this.isSubmitting) return;
        
        const input = this.gameContainer.querySelector('#flag-input');
        const submitBtn = this.gameContainer.querySelector('#flag-submit-btn');
        const resultEl = this.gameContainer.querySelector('#flag-result');
        const rewardEl = this.gameContainer.querySelector('#reward-notification');
        
        const flagValue = input.value.trim();
        
        if (!flagValue) {
            this.showResult(resultEl, 'error', 'Please enter a flag');
            return;
        }
        
        // Check if already submitted
        if (this.submittedFlags.some(f => f.toLowerCase() === flagValue.toLowerCase())) {
            this.showResult(resultEl, 'error', 'This flag has already been submitted');
            return;
        }
        
        this.isSubmitting = true;
        submitBtn.disabled = true;
        submitBtn.textContent = '...';
        this.showResult(resultEl, 'loading', 'Validating flag...');
        rewardEl.style.display = 'none';
        
        try {
            const response = await fetch(`/break_escape/games/${this.gameId}/flags`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': this.getCsrfToken()
                },
                body: JSON.stringify({ flag: flagValue })
            });
            
            const data = await response.json();
            
            if (response.ok && data.success) {
                // Success!
                if (window.playUISound) window.playUISound('confirm');
                this.showResult(resultEl, 'success', `✓ ${data.message || 'Flag accepted!'}`);
                
                // Add to history
                this.submittedFlags.push(flagValue);
                this.updateFlagHistory();
                
                // Update global state
                if (window.gameState) {
                    window.gameState.submittedFlags = this.submittedFlags;
                }
                
                // Emit generic flag_submitted event with identifier for objectives tracking
                if (data.flagId) {
                    const eventData = {
                        flagKey: flagValue,
                        flagId: data.flagId,     // e.g., "desktop-flag1"
                        vmId: data.vmId,         // e.g., "desktop"
                        stationId: this.stationId
                    };
                    
                    if (window.eventDispatcher) {
                        window.eventDispatcher.emit('flag_submitted', eventData);
                        console.log('[FlagStation] Emitted flag_submitted event:', data.flagId, eventData);
                    } else {
                        console.warn('[FlagStation] eventDispatcher not available, cannot emit flag_submitted event');
                    }
                } else {
                    console.warn('[FlagStation] No flagId in response, cannot track flag submission:', data);
                }
                
                // Show rewards if any
                if (data.rewards && data.rewards.length > 0) {
                    this.showRewards(rewardEl, data.rewards);
                    
                    // Emit events for rewards
                    this.processRewardEvents(data.rewards);
                }
                
                // Clear input
                input.value = '';
                
            } else {
                if (window.playUISound) window.playUISound('reject');
                this.showResult(resultEl, 'error', `✗ ${data.message || 'Invalid flag'}`);
            }
            
        } catch (error) {
            console.error('[FlagStation] Submit error:', error);
            this.showResult(resultEl, 'error', '✗ Failed to submit flag. Please try again.');
        } finally {
            this.isSubmitting = false;
            submitBtn.disabled = false;
            submitBtn.textContent = 'SUBMIT';
        }
    }
    
    showResult(element, type, message) {
        element.className = `flag-result ${type}`;
        element.textContent = message;
        element.style.display = 'block';
    }
    
    showRewards(element, rewards) {
        const rewardHtml = rewards.map(reward => {
            switch (reward.type) {
                case 'give_item':
                    return `
                        <div class="reward-item">
                            <span class="reward-icon">📦</span>
                            <span>Received: ${reward.item?.name || 'Item'}</span>
                        </div>
                    `;
                case 'unlock_door':
                    return `
                        <div class="reward-item">
                            <span class="reward-icon">🔓</span>
                            <span>Door unlocked: ${reward.room_id}</span>
                        </div>
                    `;
                case 'emit_event':
                    return `
                        <div class="reward-item">
                            <span class="reward-icon">⚡</span>
                            <span>Event triggered</span>
                        </div>
                    `;
                default:
                    return '';
            }
        }).filter(h => h).join('');
        
        if (rewardHtml) {
            element.innerHTML = `<h4>🎁 Rewards Unlocked!</h4>${rewardHtml}`;
            element.style.display = 'block';
        }
    }
    
    processRewardEvents(rewards) {
        for (const reward of rewards) {
            if (reward.type === 'give_item' && reward.item) {
                // Use the standard inventory system to add the item
                // Server validates flag-station itemsHeld as a valid source
                if (window.addToInventory) {
                    const itemSprite = {
                        name: reward.item.type,
                        objectId: `flag_reward_${reward.item.name}_${Date.now()}`,
                        scenarioData: reward.item,
                        texture: {
                            key: reward.item.type
                        },
                        // Copy critical properties for keys
                        keyPins: reward.item.keyPins,
                        key_id: reward.item.key_id || reward.item.keyId,
                        setVisible: function() { return this; }
                    };
                    
                    console.log('[FlagStation] Adding reward item to inventory:', reward.item.name);
                    window.addToInventory(itemSprite);
                } else {
                    console.warn('[FlagStation] addToInventory not available');
                }
            }
            
            if (reward.type === 'unlock_door' && reward.room_id) {
                // Unlock the room in client-side state
                if (window.gameState && window.gameState.unlockedRooms) {
                    if (!window.gameState.unlockedRooms.includes(reward.room_id)) {
                        window.gameState.unlockedRooms.push(reward.room_id);
                        console.log('[FlagStation] Unlocked room:', reward.room_id);
                    }
                }
                
                // Emit door unlocked event
                if (window.eventDispatcher) {
                    window.eventDispatcher.emit('door_unlocked', {
                        roomId: reward.room_id,
                        source: 'flag_reward'
                    });
                }
            }
            
            if (reward.type === 'emit_event' && reward.event_name) {
                // Emit the custom event
                if (window.eventDispatcher) {
                    window.eventDispatcher.emit(reward.event_name, {
                        source: 'flag_reward'
                    });
                }
            }
            
            if (reward.type === 'complete_task' && reward.taskId) {
                // Complete the specified task via objectives manager
                if (window.objectivesManager) {
                    window.objectivesManager.completeTask(reward.taskId);
                    console.log('[FlagStation] Completed task:', reward.taskId);
                } else {
                    console.warn('[FlagStation] ObjectivesManager not available');
                }
            }
        }
    }
    
    updateFlagHistory() {
        const list = this.gameContainer.querySelector('#flag-history-list');
        list.innerHTML = this.buildFlagHistory();
    }
    
    getCsrfToken() {
        const meta = document.querySelector('meta[name="csrf-token"]');
        return meta ? meta.getAttribute('content') : '';
    }
    
    escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }
    
    start() {
        super.start();
        console.log('[FlagStation] Started with', this.expectedFlags.length, 'expected flags');
        
        // Disable WASD key capture from main game so text input works properly
        if (window.pauseKeyboardInput) {
            window.pauseKeyboardInput();
            console.log('[FlagStation] Paused keyboard input for text entry');
        } else {
            // Fallback to dynamic import if not available on window
            import('../../../js/core/player.js').then(module => {
                if (module.pauseKeyboardInput) {
                    module.pauseKeyboardInput();
                    console.log('[FlagStation] Paused keyboard input for text entry (via import)');
                }
            });
        }
    }
}

// Register with MinigameFramework
if (window.MinigameFramework) {
    window.MinigameFramework.registerMinigame('flag-station', FlagStationMinigame);
}

export default FlagStationMinigame;

