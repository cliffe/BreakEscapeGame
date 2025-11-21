/**
 * PersonChatMinigame - Main Person-Chat Minigame Controller (Single Speaker Layout)
 * 
 * Extends MinigameScene to provide cinematic in-person conversation interface.
 * Orchestrates:
 * - Portrait rendering (single speaker at a time)
 * - Dialogue display
 * - Continue button for story progression
 * - Choice selection
 * - Ink story progression
 * 
 * @module person-chat-minigame
 */

import { MinigameScene } from '../framework/base-minigame.js';
import PersonChatUI from './person-chat-ui.js';
import PhoneChatConversation from '../phone-chat/phone-chat-conversation.js'; // Reuse phone-chat conversation logic
import InkEngine from '../../systems/ink/ink-engine.js?v=1';
import { processGameActionTags, determineSpeaker as determineSpeakerFromTags } from '../helpers/chat-helpers.js';
import npcConversationStateManager from '../../systems/npc-conversation-state.js?v=2';

// Configuration constants for dialogue auto-advance timing
const DIALOGUE_AUTO_ADVANCE_DELAY = 5000; // Default delay in milliseconds for new dialogue text (5 seconds)
const DIALOGUE_END_DELAY = 1000; // Delay in milliseconds for ending conversations (1 second)

export class PersonChatMinigame extends MinigameScene {
    /**
     * Create a PersonChatMinigame instance
     * @param {HTMLElement} container - Container element
     * @param {Object} params - Configuration parameters
     */
    constructor(container, params) {
        super(container, params);
        
        // Get required globals
        if (!window.game || !window.npcManager) {
            throw new Error('PersonChatMinigame requires window.game and window.npcManager');
        }
        
        this.game = window.game;
        this.npcManager = window.npcManager;
        this.player = window.player;
        
        // Get scenario data for player and NPC sprites
        this.scenario = window.gameScenario || {};
        
        // Create InkEngine instance for this conversation
        this.inkEngine = new InkEngine(`person-chat-${params.npcId}`);
        
        // Parameters
        this.npcId = params.npcId;
        this.title = params.title || 'Conversation';
        this.background = params.background; // Optional background image path from timedConversation
        this.startKnot = params.startKnot; // Optional knot to jump to (used for event-triggered conversations)
        
        // Verify NPC exists
        const npc = this.npcManager.getNPC(this.npcId);
        if (!npc) {
            throw new Error(`NPC not found: ${this.npcId}`);
        }
        this.npc = npc;
        
        // Get player config from scenario
        this.playerData = this.scenario.player || {
            id: 'player',
            displayName: 'Agent 0x00',
            spriteSheet: 'hacker'
        };
        
        // Build character index for multi-character support
        this.characters = this.buildCharacterIndex();
        
        // Modules
        this.ui = null;
        this.conversation = null;
        
        // State
        this.isConversationActive = false;
        this.currentSpeaker = null; // Track current speaker ID ('player' or NPC id)
        this.lastResult = null; // Store last continue() result for choice handling
        this.isClickThroughMode = false; // If true, player must click to advance between dialogue lines (starts in AUTO mode)
        this.pendingContinueCallback = null; // Callback waiting for player click in click-through mode
        
        console.log(`🎭 PersonChatMinigame created for NPC: ${this.npcId}`);
    }
    
    /**
     * Build index of all available characters (player + NPCs)
     * @returns {Object} Map of character ID to character data
     */
    buildCharacterIndex() {
        const characters = {};
        
        // Add player
        characters['player'] = this.playerData;
        
        // Add main NPC
        characters[this.npc.id] = this.npc;
        
        // Add other NPCs from current room (NPCs are now per-room, not at scenario root)
        const currentRoom = window.currentRoom || this.npc.roomId;
        if (currentRoom && this.scenario.rooms && this.scenario.rooms[currentRoom]) {
            const roomNPCs = this.scenario.rooms[currentRoom].npcs || [];
            roomNPCs.forEach(npc => {
                if (npc.id !== this.npc.id) {
                    // Look up NPC data from npcManager for complete displayName
                    const npcData = window.npcManager?.getNPC(npc.id) || npc;
                    characters[npc.id] = npcData;
                }
            });
        }
        
        // Fallback to legacy root-level NPCs for backward compatibility
        if (!Object.keys(characters).length > 2 && this.scenario.npcs && Array.isArray(this.scenario.npcs)) {
            this.scenario.npcs.forEach(npc => {
                if (npc.id !== this.npc.id && !characters[npc.id]) {
                    characters[npc.id] = npc;
                }
            });
        }
        
        console.log(`👥 Built character index with ${Object.keys(characters).length} characters:`, Object.keys(characters));
        return characters;
    }
    
    /**
     * Get character data by ID
     * @param {string} characterId - Character ID (player, npc_id, etc.)
     * @returns {Object} Character data
     */
    getCharacterById(characterId) {
        if (!characterId) return this.npc; // Fallback to main NPC
        
        // Handle legacy speaker values
        if (characterId === 'npc') {
            return this.npc;
        }
        if (characterId === 'player') {
            return this.playerData;
        }
        
        // Look up by ID
        return this.characters[characterId] || this.npc;
    }
    
    /**
     * Initialize the minigame UI and components
     */
    init() {
        // Set up basic minigame structure (header, container, etc.)
        if (!this.params.cancelText) {
            this.params.cancelText = 'End Conversation';
        }
        super.init();
        
        // Initialize timer for auto-advance
        this.autoAdvanceTimer = null;
        
        // Customize header
        this.headerElement.innerHTML = `
            <h3>🎭 ${this.title}</h3>
            <p>Speaking with ${this.npc.displayName}</p>
        `;
        
        // Create UI, passing both NPC and player data
        this.ui = new PersonChatUI(this.gameContainer, {
            game: this.game,
            npc: this.npc,
            playerSprite: this.player,
            playerData: this.playerData,
            characters: this.characters,  // Pass multi-character support
            background: this.background   // Optional background image path
        }, this.npcManager);
        
        this.ui.render();
        
        // Set up event listeners
        this.setupEventListeners();
        
        console.log('✅ PersonChatMinigame initialized');
    }
    
    /**
     * Set up event listeners for UI interactions
     */
    setupEventListeners() {
        // Choice button clicks
        this.addEventListener(this.ui.elements.choicesContainer, 'click', (e) => {
            const choiceButton = e.target.closest('.person-chat-choice-button');
            if (choiceButton) {
                const choiceIndex = parseInt(choiceButton.dataset.index);
                this.handleChoice(choiceIndex);
            }
        });

        // Continue button click handler
        if (this.ui.elements.continueButton) {
            this.addEventListener(this.ui.elements.continueButton, 'click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                this.handleContinueButtonClick();
            });
        }

        // Listen for conversation end event from the conversation handler
        this.addEventListener(window, 'npc-conversation-ended', (e) => {
            console.log(`👋 Received npc-conversation-ended event for ${e.detail.npcId}`);

            // Verify this event is for our current conversation
            if (e.detail.npcId === this.npcId) {
                console.log(`✅ Ending minigame - conversation state preserved at mission_hub`);

                // Save state before exiting
                if (this.inkEngine && this.inkEngine.story) {
                    npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                }

                // End the minigame and return to game
                if (window.MinigameFramework) {
                    window.MinigameFramework.endMinigame(true, { conversationEnded: true });
                }
            }
        });
    }
    
    /**
     * Handle continue button click - behavior depends on mode
     */
    handleContinueButtonClick() {
        console.log(`🖱️ Button clicked! isClickThroughMode: ${this.isClickThroughMode}, pendingContinueCallback exists: ${!!this.pendingContinueCallback}`);
        if (this.isClickThroughMode) {
            // In click-through mode: execute the pending advancement callback
            if (this.pendingContinueCallback && typeof this.pendingContinueCallback === 'function') {
                console.log(`🖱️ Executing pending callback`);
                const callback = this.pendingContinueCallback;
                this.pendingContinueCallback = null;
                callback();
            } else {
                console.log(`🖱️ No pending callback to execute!`);
            }
        } else {
            // In auto mode: toggle to click-through mode
            console.log(`🖱️ In auto mode, toggling to click-through`);
            this.toggleClickThroughMode();
        }
    }    /**
     * Toggle between automatic timing and click-through mode
     */
    toggleClickThroughMode() {
        this.isClickThroughMode = !this.isClickThroughMode;
        
        if (this.isClickThroughMode) {
            console.log('📋 Switched to CLICK-THROUGH mode');
            this.ui.elements.continueButton.textContent = 'Continue';
            // Cancel any pending automatic advances (timer only, keep the callback!)
            if (this.autoAdvanceTimer) {
                clearTimeout(this.autoAdvanceTimer);
                this.autoAdvanceTimer = null;
            }
        } else {
            console.log('📋 Switched to AUTOMATIC mode');
            this.ui.elements.continueButton.textContent = 'Auto';
            // Resume automatic advancement
            this.showCurrentDialogue();
        }
    }
    
    /**
     * Schedule the next dialogue advancement, respecting click-through mode
     * @param {Function} callback - Function to call to advance dialogue
     * @param {number} delay - Delay in milliseconds (ignored in click-through mode)
     */
    scheduleDialogueAdvance(callback, delay = DIALOGUE_AUTO_ADVANCE_DELAY) {
        // Always store the callback function itself
        this.pendingContinueCallback = callback;
        
        if (this.isClickThroughMode) {
            // In click-through mode, wait for button click to execute callback
            console.log(`⏱️ scheduleDialogueAdvance: Stored callback for click-through mode`);
        } else {
            // In automatic mode, schedule execution after delay
            console.log(`⏱️ scheduleDialogueAdvance: Will auto-advance after ${delay}ms`);
            // Clear any existing timeout
            if (this.autoAdvanceTimer) {
                clearTimeout(this.autoAdvanceTimer);
            }
            // Set new timeout that will call handleContinueButtonClick
            this.autoAdvanceTimer = setTimeout(() => {
                if (this.pendingContinueCallback && typeof this.pendingContinueCallback === 'function') {
                    this.pendingContinueCallback();
                }
            }, delay);
        }
    }
    
    /**
     * Start the minigame
     * Initializes conversation flow
     */
    start() {
        super.start();
        
        console.log('🎭 PersonChatMinigame started');
        
        // Track NPC context for tag processing and minigame return flow
        window.currentConversationNPCId = this.npcId;
        window.currentConversationMinigameType = 'person-chat';
        
        // Start conversation with Ink
        this.startConversation();
    }
    
    /**
     * Start conversation with NPC
     * Loads Ink story and shows initial dialogue
     */
    async startConversation() {
        try {
            // Create conversation manager using PhoneChatConversation (reused logic)
            this.conversation = new PhoneChatConversation(this.npcId, this.npcManager, this.inkEngine);
            
            // Load story from NPC's storyJSON (pre-cached) or via Rails API
            let storySource = this.npc.storyJSON;
            
            // If no pre-cached JSON but storyPath exists, use Rails API endpoint
            if (!storySource && this.npc.storyPath) {
                const gameId = window.breakEscapeConfig?.gameId;
                if (gameId) {
                    storySource = `/break_escape/games/${gameId}/ink?npc=${this.npcId}`;
                    console.log(`📖 Using Rails API for story: ${storySource}`);
                } else {
                    console.warn('⚠️  No gameId available, story loading may fail');
                }
            }
            
            const loaded = await this.conversation.loadStory(storySource);
            
            if (!loaded) {
                console.error('❌ Failed to load conversation story');
                this.showError('Failed to load conversation');
                return;
            }
            
            // If a startKnot was provided (event-triggered conversation), jump directly to it
            // This skips state restoration and goes straight to the event response
            if (this.startKnot) {
                console.log(`⚡ Event-triggered conversation: jumping directly to knot: ${this.startKnot}`);
                this.conversation.goToKnot(this.startKnot);
            } else {
                // Otherwise, restore previous conversation state if it exists
                const stateRestored = npcConversationStateManager.restoreNPCState(
                    this.npcId, 
                    this.inkEngine.story
                );
                
                if (stateRestored) {
                    // If we restored state, reset the story ended flag in case it was marked as ended before
                    this.conversation.storyEnded = false;
                    console.log(`🔄 Continuing previous conversation with ${this.npcId}`);
                } else {
                    // First time conversation - navigate to start knot
                    const startKnot = this.npc.currentKnot || 'start';
                    this.conversation.goToKnot(startKnot);
                    console.log(`🆕 Starting new conversation with ${this.npcId}`);
                }
            }
            
            // Always sync global variables to ensure they're up to date
            // This is important because other NPCs may have changed global variables
            if (this.inkEngine && this.inkEngine.story) {
                npcConversationStateManager.syncGlobalVariablesToStory(this.inkEngine.story);
                // Also sync inventory-based variables on initial load
                npcConversationStateManager.syncInventoryVariablesToStory(this.inkEngine.story, this.npc);
            }

            
            // Re-sync global variables right before showing dialogue to ensure conditionals are evaluated with current values
            // This is critical because Ink evaluates conditionals when continue() is called
            if (this.inkEngine && this.inkEngine.story) {
                npcConversationStateManager.syncGlobalVariablesToStory(this.inkEngine.story);
                // Also sync inventory-based variables (has_keycard, has_rfid_cloner, card protocols, etc.)
                npcConversationStateManager.syncInventoryVariablesToStory(this.inkEngine.story, this.npc);
                console.log('🔄 Re-synced global and inventory variables before showing dialogue');
            }
            
            this.isConversationActive = true;
            
            // Show initial dialogue
            this.showCurrentDialogue();
            
            console.log('✅ Conversation started');
        } catch (error) {
            console.error('❌ Error starting conversation:', error);
            this.showError('An error occurred during conversation');
        }
    }
    
    /**
     * Display current dialogue (without advancing yet)
     */
    showCurrentDialogue() {
        if (!this.conversation) return;

        try {
            // Get current content without advancing
            const result = this.conversation.continue();

            // Store result for later use
            this.lastResult = result;

            // Check if story has ended
            if (result.hasEnded) {
                // Check if this is a graceful conversation end (with #end_conversation tag)
                const hasEndConversationTag = result.tags?.some(tag =>
                    tag.trim().toLowerCase() === 'end_conversation'
                );

                if (hasEndConversationTag) {
                    // Graceful end - the npc-conversation-ended event will handle closing
                    console.log('👋 Graceful conversation end detected - waiting for event handler');
                    return;
                }

                // Otherwise, it's an unexpected END - save state and show manual exit message
                // Player should press ESC to exit and return to hub
                if (this.inkEngine && this.inkEngine.story) {
                    npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                }
                this.ui.showDialogue('(End of conversation - press ESC to exit)', 'system');
                console.log('🏁 Story has reached an end point');
                return;
            }
            
            // Determine who is speaking based on tags
            const speaker = this.determineSpeaker(result);
            this.currentSpeaker = speaker;
            
            console.log(`🗣️ showCurrentDialogue - result.text: "${result.text?.substring(0, 50)}..." (${result.text?.length || 0} chars)`);
            console.log(`🗣️ showCurrentDialogue - result.canContinue: ${result.canContinue}`);
            console.log(`🗣️ showCurrentDialogue - result.hasEnded: ${result.hasEnded}`);
            console.log(`🗣️ showCurrentDialogue - result.choices.length: ${result.choices?.length || 0}`);
            console.log(`🗣️ showCurrentDialogue - this.ui exists:`, !!this.ui);
            console.log(`🗣️ showCurrentDialogue - this.ui.showDialogue exists:`, typeof this.ui?.showDialogue);
            
            // Display choices if available (check this first, before text)
            if (result.choices && result.choices.length > 0) {
                console.log(`📋 ${result.choices.length} choices available`);
                
                // Check if we have accompanying text
                if (result.text && result.text.trim()) {
                    // Check if we have multiple lines/speakers (accumulated dialogue)
                    const hasMultipleLines = result.text.includes('\n');
                    const hasMultipleSpeakers = result.tags && result.tags.filter(t => t.includes('speaker:')).length > 1;
                    
                    if (hasMultipleLines || hasMultipleSpeakers) {
                        // Multiple dialogue lines - display them sequentially, choices shown at end
                        console.log(`🗣️ Initial dialogue has multiple lines/speakers - using block display`);
                        this.displayAccumulatedDialogue(result);
                    } else {
                        // Single line - display immediately with choices
                        console.log(`🗣️ Single line dialogue - showing with choices immediately`);
                        this.ui.showChoices(result.choices);
                        this.ui.showDialogue(result.text, speaker, true); // preserveChoices=true
                    }
                } else {
                    // No text, just choices - show them immediately
                    this.ui.showChoices(result.choices);
                    console.log(`📋 No text, just showing choices`);
                }
            } else if (result.text && result.text.trim()) {
                // Have text but no choices - display and continue
                console.log(`🗣️ Calling showDialogue with speaker: ${speaker}`);
                this.ui.showDialogue(result.text, speaker);
                
                if (result.canContinue) {
                    // Can continue - schedule next advance
                    console.log(`📋 Setting pendingContinueCallback - canContinue: true, no choices`);
                    this.scheduleDialogueAdvance(() => this.showCurrentDialogue(), DIALOGUE_AUTO_ADVANCE_DELAY);
                } else {
                    // Can't continue but have text - story will end
                    console.log('✓ Waiting for story to end...');
                    this.scheduleDialogueAdvance(() => this.endConversation(), DIALOGUE_END_DELAY);
                }
            } else {
                // No text and no choices - story has ended
                console.log('🏁 No text and no choices - story ended');
                this.endConversation();
            }
        } catch (error) {
            console.error('❌ Error showing dialogue:', error);
            this.showError('An error occurred during conversation');
        }
    }
    
    /**
     * Determine who is speaking based on Ink tags
     * 
     * SPEAKER TAG FORMATS:
     * - # speaker:player          → Player is speaking
     * - # speaker:npc             → Main NPC being talked to
     * - # speaker:npc:sprite_id   → Specific character (multi-character conversations)
     * 
     * If no speaker tag is present, dialogue DEFAULTS to the main NPC
     * This allows simple single-NPC conversations to omit the tag
     * 
     * @param {Object} result - Result from conversation.continue()
     * @returns {string} Character ID of speaker (player, npc_id, or main NPC id)
     */
    determineSpeaker(result) {
        if (!result.tags || result.tags.length === 0) {
            return this.npc.id; // Default to main NPC
        }
        
        // Check tags in reverse order to find the last speaker tag (current speaker)
        for (let i = result.tags.length - 1; i >= 0; i--) {
            const tag = result.tags[i].trim().toLowerCase();
            
            // Handle multi-part speaker tags like "speaker:npc:test_npc_back"
            if (tag.startsWith('speaker:')) {
                const parts = tag.split(':');
                
                if (parts.length === 2) {
                    // Simple speaker tag: speaker:player or speaker:npc
                    const speaker = parts[1];
                    if (speaker === 'player') return 'player';
                    if (speaker === 'npc') return this.npc.id; // Default NPC
                } else if (parts.length === 3) {
                    // Specific character tag: speaker:npc:character_id
                    const characterId = parts[2];
                    return this.characters[characterId] ? characterId : this.npc.id;
                } else if (parts.length > 3) {
                    // Handle IDs with colons like speaker:npc:test_npc_back
                    const characterId = parts.slice(2).join(':');
                    return this.characters[characterId] ? characterId : this.npc.id;
                }
            }
            
            // Fallback for non-speaker: tags
            if (tag === 'player') return 'player';
            if (tag === 'npc') return this.npc.id;
        }
        
        // No speaker tag found - default to main NPC
        return this.npc.id;
    }
    
    /**
     * Handle choice selection
     * @param {number} choiceIndex - Index of selected choice
     */
    handleChoice(choiceIndex) {
        if (!this.conversation || !this.lastResult) return;
        
        try {
            console.log(`📝 Choice selected: ${choiceIndex}`);
            
            // Get the choice object to check for tags
            const choice = this.lastResult.choices[choiceIndex];
            const choiceText = choice?.text || '';
            
            // Clear choice buttons immediately
            this.ui.hideChoices();
            
            // Make choice in conversation (this also calls continue() internally)
            const result = this.conversation.makeChoice(choiceIndex);
            
            // Sync global variables from story to window.gameState after choice
            // This ensures variable changes (like player_joined_organization) are captured
            if (this.inkEngine && this.inkEngine.story) {
                const changed = npcConversationStateManager.syncGlobalVariablesFromStory(this.inkEngine.story);
                if (changed.length > 0) {
                    console.log(`🌐 Synced ${changed.length} global variable(s) after choice:`, changed);
                    // Broadcast changes to other loaded stories
                    changed.forEach(({ name, value }) => {
                        npcConversationStateManager.broadcastGlobalVariableChange(name, value, this.npcId);
                    });
                }
            }
            
            // Save state immediately after making a choice
            // This ensures variables (favour, items earned, etc.) are persisted
            if (this.inkEngine && this.inkEngine.story) {
                npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
            }
            
            // First, display the player's choice as dialogue
            if (choiceText) {
                this.ui.showDialogue(choiceText, 'player');
            }
            
            // Check if the story output contains the exit_conversation tag
            // This tag appears in the story response AFTER making the choice
            const shouldExit = result?.tags?.some(tag => tag.includes('exit_conversation'));
            
            // If this was an exit choice, show the NPC's response then close
            if (shouldExit) {
                console.log('🚪 Exit conversation tag detected - showing response then closing minigame');
                // Show the NPC's response after displaying player choice
                this.scheduleDialogueAdvance(() => {
                    // Display the NPC's final response
                    this.displayAccumulatedDialogue(result);
                    
                    // Then close the minigame after showing the response
                    this.scheduleDialogueAdvance(() => {
                        // Final state save before closing
                        if (this.inkEngine && this.inkEngine.story) {
                            npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                        }
                        this.complete(true);
                    }, 2500);
                }, 1500);
                return;
            }
            
            // Normal dialogue flow: display the result (dialogue blocks) after a small delay
            console.log(`🎯 After choice: scheduling displayAccumulatedDialogue with result.text length: ${result?.text?.length || 0}`);
            this.scheduleDialogueAdvance(() => {
                // Process accumulated dialogue by splitting into individual speaker blocks
                console.log(`🎯 Inside scheduled callback: calling displayAccumulatedDialogue`);
                this.displayAccumulatedDialogue(result);
            }, 1500);

        } catch (error) {
            console.error('❌ Error handling choice:', error);
            this.showError('An error occurred when processing your choice');
        }
    }
    
    /**
     * Display accumulated dialogue by splitting into individual speaker blocks
     * @param {Object} result - Result with potentially multiple lines and tags
     */
    displayAccumulatedDialogue(result) {
        if (!result.text || !result.tags) {
            // No content to display
            if (result.hasEnded) {
                // Story ended - save state and show message
                if (this.inkEngine && this.inkEngine.story) {
                    npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                }
                this.ui.showDialogue('(Conversation ended - press ESC to close)', 'system');
                console.log('🏁 Story has reached an end point');
            }
            return;
        }
        
        // Process any game action tags (give_item, unlock_door, etc.) BEFORE displaying dialogue
        if (result.tags && result.tags.length > 0) {
            console.log('🏷️ Processing action tags from accumulated dialogue:', result.tags);
            processGameActionTags(result.tags, this.ui);
        }
        
        // Split text into lines
        const lines = result.text.split('\n').filter(line => line.trim());
        
        // We have lines and tags - pair them up
        // Each tag corresponds to a line (or group of lines before the next tag)
        if (lines.length === 0) {
            if (result.hasEnded) {
                // Story ended - save state and show message
                if (this.inkEngine && this.inkEngine.story) {
                    npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                }
                this.ui.showDialogue('(Conversation ended - press ESC to close)', 'system');
                console.log('🏁 Story has reached an end point');
            }
            return;
        }
        
        // Create dialogue blocks: each block is one or more consecutive lines with the same speaker
        const dialogueBlocks = this.createDialogueBlocks(lines, result.tags);
        
        // Display blocks sequentially with delays
        this.displayDialogueBlocksSequentially(dialogueBlocks, result, 0);
    }
    
    /**
     * Create dialogue blocks from lines and speaker tags
     * When speaker tags are missing, dialogue defaults to the main NPC being talked to
     * 
     * @param {Array<string>} lines - Text lines
     * @param {Array<string>} tags - Speaker tags
     * @returns {Array<Object>} Array of {speaker, text} blocks
     */
    createDialogueBlocks(lines, tags) {
        const blocks = [];
        let blockIndex = 0;
        
        // Special case: NO tags at all - all lines belong to main NPC
        if (!tags || tags.length === 0) {
            if (lines.length > 0) {
                const allText = lines.join('\n').trim();
                if (allText) {
                    blocks.push({ speaker: this.npc.id, text: allText, tag: null });
                }
            }
            return blocks;
        }
        
        // Group lines by speaker based on tags
        for (let tagIdx = 0; tagIdx < tags.length; tagIdx++) {
            const tag = tags[tagIdx];
            
            // Determine speaker from tag - support multiple formats
            // Default to main NPC if no speaker tag found
            let speaker = this.npc.id;
            if (tag.includes('speaker:player')) {
                speaker = 'player';
            } else if (tag.includes('speaker:npc:')) {
                // Extract character ID from speaker:npc:character_id format
                const match = tag.match(/speaker:npc:(\S+)/);
                if (match && match[1]) {
                    speaker = match[1];
                }
            } else if (tag === 'player' || tag.includes('player')) {
                speaker = 'player';
            }
            
            // Find how many lines belong to this speaker (until next tag or end)
            const nextTagIdx = tagIdx + 1;
            const startLineIdx = blockIndex;
            
            // Count lines for this speaker - lines between this tag and the next
            let endLineIdx = lines.length;
            if (nextTagIdx < tags.length) {
                // There's another tag coming, but we need to figure out how many lines
                // For now, assume 1 line per tag (common case)
                endLineIdx = startLineIdx + 1;
            }
            
            // Collect the text for this speaker
            const blockText = lines.slice(startLineIdx, endLineIdx).join('\n').trim();
            if (blockText) {
                blocks.push({ speaker, text: blockText, tag });
            }
            
            blockIndex = endLineIdx;
        }
        
        return blocks;
    }
    
    /**
     * Display dialogue blocks sequentially
     * @param {Array<Object>} blocks - Array of dialogue blocks
     * @param {Object} originalResult - Original result from Ink
     * @param {number} blockIndex - Current block index
     * @param {number} lineIndex - Current line index within the block (default 0)
     * @param {string} accumulatedText - Text accumulated so far for current speaker
     */
    displayDialogueBlocksSequentially(blocks, originalResult, blockIndex, lineIndex = 0, accumulatedText = '') {
        if (blockIndex >= blocks.length) {
            // All blocks displayed, check if story has ended or if there are choices
            if (originalResult.hasEnded) {
                // Story ended - save state and show message
                this.scheduleDialogueAdvance(() => {
                    if (this.inkEngine && this.inkEngine.story) {
                        npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                    }
                    this.ui.showDialogue('(Conversation ended - press ESC to close)', 'system');
                    console.log('🏁 Story has reached an end point');
                }, 1000);
            } else if (originalResult.choices && originalResult.choices.length > 0) {
                // Choices available - show them directly without needing another click
                console.log(`📋 All dialogue blocks done, showing ${originalResult.choices.length} choices`);
                // Update lastResult so choice handler has the correct choices
                this.lastResult = originalResult;
                this.ui.showChoices(originalResult.choices);
            } else {
                // Try to continue for more dialogue
                console.log('⏸️ Blocks finished, checking for more dialogue...');
                this.scheduleDialogueAdvance(() => {
                    const nextLine = this.conversation.continue();
                    
                    // Store for choice handling
                    this.lastResult = nextLine;
                    
                    if (nextLine.text && nextLine.text.trim()) {
                        this.displayAccumulatedDialogue(nextLine);
                    } else if (nextLine.choices && nextLine.choices.length > 0) {
                        // Back to choices - display them
                        console.log(`📋 Back to choices: ${nextLine.choices.length} options available`);
                        this.ui.showChoices(nextLine.choices);
                    } else if (nextLine.hasEnded) {
                        // Story ended - save state and show message
                        if (this.inkEngine && this.inkEngine.story) {
                            npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                        }
                        this.ui.showDialogue('(Conversation ended - press ESC to close)', 'system');
                        console.log('🏁 Story has reached an end point');
                    }
                }, DIALOGUE_AUTO_ADVANCE_DELAY);
            }
            return;
        }
        
        // Display current block's lines one at a time with accumulation
        const block = blocks[blockIndex];
        const lines = block.text.split('\n').filter(line => line.trim());
        
        if (lineIndex >= lines.length) {
            // All lines in this block displayed, move to next block with reset accumulation
            this.displayDialogueBlocksSequentially(blocks, originalResult, blockIndex + 1, 0, '');
            return;
        }
        
        // Add current line to accumulated text
        const line = lines[lineIndex];
        const newAccumulatedText = accumulatedText ? accumulatedText + '\n' + line : line;
        
        console.log(`📋 Displaying line ${lineIndex + 1}/${lines.length} from block ${blockIndex + 1}/${blocks.length}: ${block.speaker}`);
        
        // Show accumulated text (all lines up to and including current line)
        this.ui.showDialogue(newAccumulatedText, block.speaker);
        
        // Display next line after delay
        this.scheduleDialogueAdvance(() => {
            this.displayDialogueBlocksSequentially(blocks, originalResult, blockIndex, lineIndex + 1, newAccumulatedText);
        }, DIALOGUE_AUTO_ADVANCE_DELAY);
    }
    
    /**
     * Display dialogue from a result object (without calling continue() again)
     * @param {Object} result - Story result from conversation.continue()
     */
    displayDialogueResult(result) {
        try {
            // Check if story has ended
            if (result.hasEnded) {
                // Story ended - save state and show message
                if (this.inkEngine && this.inkEngine.story) {
                    npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                }
                this.ui.showDialogue('(Conversation ended - press ESC to close)', 'system');
                console.log('🏁 Story has reached an end point');
                return;
            }
            
            // Process any game action tags (give_item, unlock_door, etc.)
            if (result.tags && result.tags.length > 0) {
                console.log('🏷️ Processing tags from story:', result.tags);
                processGameActionTags(result.tags, this.ui);
            }
            
            // Determine who is speaking based on tags
            const speaker = this.determineSpeaker(result);
            this.currentSpeaker = speaker;
            
            console.log(`🗣️ displayDialogueResult - result.text: "${result.text?.substring(0, 50)}..." (${result.text?.length || 0} chars)`);
            console.log(`🗣️ displayDialogueResult - result.canContinue: ${result.canContinue}`);
            console.log(`🗣️ displayDialogueResult - result.choices.length: ${result.choices?.length || 0}`);
            
            // Display dialogue text with speaker (only if there's actual text)
            if (result.text && result.text.trim()) {
                console.log(`🗣️ Calling showDialogue with speaker: ${speaker}`);
                this.ui.showDialogue(result.text, speaker);
            } else {
                console.log(`⚠️ Skipping showDialogue - no text or text is empty`);
            }
            
            // Display choices if available
            if (result.choices && result.choices.length > 0) {
                this.ui.showChoices(result.choices);
                console.log(`📋 ${result.choices.length} choices available`);
            } else if (result.canContinue) {
                // No choices but can continue - auto-advance after delay
                console.log(`⏳ Auto-continuing in ${DIALOGUE_AUTO_ADVANCE_DELAY / 1000} seconds...`);
                this.scheduleDialogueAdvance(() => this.showCurrentDialogue(), DIALOGUE_AUTO_ADVANCE_DELAY);
            } else {
                // No choices and can't continue - check if there's more content
                // Try to continue anyway (for linear scripted conversations)
                console.log('⏸️ No more choices, attempting to continue for next line...');
                this.scheduleDialogueAdvance(() => {
                    const nextLine = this.conversation.continue();
                    if (nextLine.text && nextLine.text.trim()) {
                        // There's more dialogue to show
                        this.displayDialogueResult(nextLine);
                    } else if (nextLine.hasEnded) {
                        // Story reached an end - save state and show message
                        if (this.inkEngine && this.inkEngine.story) {
                            npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                        }
                        this.ui.showDialogue('(Conversation ended - press ESC to close)', 'system');
                        console.log('🏁 Story has reached an end point');
                    } else {
                        // No text but story isn't ended - wait a bit and show message
                        console.log('✓ No more dialogue - conversation paused');
                        if (this.inkEngine && this.inkEngine.story) {
                            npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
                        }
                        this.ui.showDialogue('(No more dialogue available - press ESC to close)', 'system');
                    }
                }, DIALOGUE_AUTO_ADVANCE_DELAY);
            }
        } catch (error) {
            console.error('❌ Error displaying dialogue:', error);
            this.showError('An error occurred during conversation');
        }
    }
    
    /**
     * End conversation and clean up
     */
    endConversation() {
        console.log('🎭 Conversation ended');
        
        this.isConversationActive = false;
        
        // Save the conversation state before ending
        // The state manager intelligently saves:
        // - Full state if conversation is still active
        // - Variables only if story has ended (so next conversation restarts fresh)
        if (this.inkEngine && this.inkEngine.story) {
            npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
        }
        
        // Show completion message
        if (this.ui.elements.dialogueText) {
            this.ui.elements.dialogueText.textContent = 'Conversation ended.';
        }
        
        // Hide controls
        this.ui.reset();
        
        // Close minigame after a delay
        this.scheduleDialogueAdvance(() => {
            this.complete(true);
        }, 1000);
    }
    
    /**
     * Jump to a specific knot in the conversation while keeping the minigame active
     * Called when an event (like lockpicking) is detected during an active conversation
     * @param {string} knotName - Name of the knot to jump to
     */
    jumpToKnot(knotName) {
        if (!knotName) {
            console.warn('jumpToKnot: No knot name provided');
            return false;
        }
        
        if (!this.conversation || !this.conversation.engine || !this.conversation.engine.story) {
            console.warn('jumpToKnot: Conversation engine not initialized', {
                hasConversation: !!this.conversation,
                hasEngine: !!this.conversation?.engine,
                hasStory: !!this.conversation?.engine?.story
            });
            return false;
        }
        
        try {
            console.log(`🎯 PersonChatMinigame.jumpToKnot() - Starting jump to: ${knotName}`);
            console.log(`   Current NPC: ${this.npcId}`);
            console.log(`   Current knot before jump: ${this.conversation.engine.story.state?.currentPathString}`);
            
            // Use the conversation's goToKnot method instead of directly calling inkEngine
            // This ensures NPC state is updated properly
            const jumpSuccess = this.conversation.goToKnot(knotName);
            
            if (!jumpSuccess) {
                console.error(`❌ conversation.goToKnot() returned false for knot: ${knotName}`);
                return false;
            }
            
            console.log(`   Knot after jump: ${this.conversation.engine.story.state?.currentPathString}`);
            
            // Clear any pending callbacks since we're changing the story
            if (this.autoAdvanceTimer) {
                clearTimeout(this.autoAdvanceTimer);
                this.autoAdvanceTimer = null;
                console.log(`   Cleared auto-advance timer`);
            }
            this.pendingContinueCallback = null;
            
            // Clear the UI before showing new content
            this.ui.hideChoices();
            console.log(`   Hidden choice buttons`);
            
            console.log(`🎯 About to call showCurrentDialogue() to fetch new content...`);
            
            // Show the new dialogue at the target knot
            // This will call conversation.continue() to get the content at the new knot
            this.showCurrentDialogue();
            
            console.log(`✅ Successfully jumped to knot: ${knotName}`);
            return true;
        } catch (error) {
            console.error(`❌ Error jumping to knot ${knotName}:`, error);
            return false;
        }
    }
    
    /**
     * Override cleanup to ensure conversation state is saved
     * This is called by the base class before the minigame is removed
     */
    cleanup() {
        // Save conversation state before cleanup
        // The state manager intelligently handles:
        // - Saving full state for in-progress conversations
        // - Saving variables only for ended conversations
        if (this.isConversationActive && this.inkEngine && this.inkEngine.story) {
            console.log(`💾 Saving NPC state on cleanup for ${this.npcId}`);
            npcConversationStateManager.saveNPCState(this.npcId, this.inkEngine.story);
        }
        
        // Clear NPC context
        window.currentConversationNPCId = null;
        
        // Call parent cleanup
        super.cleanup();
    }
    
    /**
     * Show error message
     * @param {string} message - Error message to display
     */
    showError(message) {
        console.error(`❌ ${message}`);
        
        if (this.ui.elements.dialogueText) {
            this.ui.elements.dialogueText.innerHTML = `
                <span style="color: #ff6b6b;">⚠️ Error</span><br/>
                ${message}
            `;
        }
    }
}

// Register this minigame
if (window.MinigameFramework) {
    window.MinigameFramework.registerScene('person-chat-minigame', PersonChatMinigame);
    console.log('✅ PersonChatMinigame registered');
}

export default PersonChatMinigame;
