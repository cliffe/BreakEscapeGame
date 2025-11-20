// Base class for minigame scenes
export class MinigameScene {
    constructor(container, params) {
        this.container = container;
        this.params = params;
        this.gameState = {
            isActive: false,
            mouseDown: false,
            currentTool: null
        };
        this.gameResult = null;
        this._eventListeners = [];
    }
    
    init() {
        // Check if cancel button should be shown (default: true)
        const showCancel = this.params.showCancel !== false;
        
        this.container.innerHTML = `
            <button class="minigame-close-button" id="minigame-close">&times;</button>
            <div class="minigame-header">
                <h3>${this.params.title || 'Minigame'}</h3>
            </div>
            <div class="minigame-game-container"></div>
            <div class="minigame-message-container"></div>
            ${showCancel ? `<div class="minigame-controls"><button class="minigame-button" id="minigame-cancel">${this.params.cancelText || 'Cancel'}</button></div>` : ''}
        `;
        
        this.headerElement = this.container.querySelector('.minigame-header');
        this.gameContainer = this.container.querySelector('.minigame-game-container');
        this.messageContainer = this.container.querySelector('.minigame-message-container');
        this.controlsElement = this.container.querySelector('.minigame-controls');
        
        // Set up close button
        const closeBtn = document.getElementById('minigame-close');
        this.addEventListener(closeBtn, 'click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('Close button clicked');
            this.complete(false);
        });
        
        // Set up cancel button only if it exists
        const cancelBtn = document.getElementById('minigame-cancel');
        if (cancelBtn) {
            console.log('Cancel button found, setting up event listener');
            this.addEventListener(cancelBtn, 'click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                console.log('Cancel button clicked');
                this.complete(false);
            });
        } else {
            console.log('Cancel button not found');
        }

        // hide the header if the params.headerElement is empty
        if (!this.params.headerElement) {
            this.headerElement.style.display = 'none';
        }
    }
    
    start() {
        this.gameState.isActive = true;
        console.log("Minigame started");
        
        // Add a fallback mechanism to ensure minigame can be closed
        // This helps if there are issues with button event listeners
        this._fallbackCloseHandler = (e) => {
            if (e.key === 'Escape') {
                console.log('Escape key pressed, closing minigame');
                this.complete(false);
            }
        };
        document.addEventListener('keydown', this._fallbackCloseHandler);
    }
    
    complete(success) {
        console.log('Minigame complete called with success:', success);
        this.gameState.isActive = false;
        
        // Emit minigame completion event
        console.log('🎮 Checking for eventDispatcher:', !!window.eventDispatcher);
        if (window.eventDispatcher) {
            const eventName = success ? 'minigame_completed' : 'minigame_failed';
            console.log(`🎮 Emitting ${eventName} event for minigame:`, this.constructor.name);
            window.eventDispatcher.emit(eventName, {
                minigameName: this.constructor.name,
                success: success,
                result: this.gameResult
            });
        } else {
            console.warn('🎮 eventDispatcher not available - minigame event not emitted');
        }
        
        if (window.MinigameFramework) {
            window.MinigameFramework.endMinigame(success, this.gameResult);
        } else {
            console.error('MinigameFramework not available');
        }
    }
    
    addEventListener(element, eventType, handler) {
        element.addEventListener(eventType, handler);
        this._eventListeners.push({ element, eventType, handler });
    }
    
    showSuccess(message, autoClose = true, duration = 2000) {
        const messageElement = document.createElement('div');
        messageElement.className = 'minigame-success-message';
        messageElement.innerHTML = message;
        
        this.messageContainer.appendChild(messageElement);
        
        if (autoClose) {
            setTimeout(() => {
                this.complete(true);
            }, duration);
        }
    }
    
    showFailure(message, autoClose = true, duration = 2000) {
        const messageElement = document.createElement('div');
        messageElement.className = 'minigame-failure-message';
        messageElement.innerHTML = message;
        
        this.messageContainer.appendChild(messageElement);
        
        if (autoClose) {
            setTimeout(() => {
                this.complete(false);
            }, duration);
        }
    }
    
    updateProgress(current, total) {
        const progressBar = this.container.querySelector('.minigame-progress-bar');
        if (progressBar) {
            const percentage = (current / total) * 100;
            progressBar.style.width = `${percentage}%`;
        }
    }
    
    cleanup() {
        this._eventListeners.forEach(({ element, eventType, handler }) => {
            element.removeEventListener(eventType, handler);
        });
        this._eventListeners = [];
        
        // Clean up fallback close handler
        if (this._fallbackCloseHandler) {
            document.removeEventListener('keydown', this._fallbackCloseHandler);
            this._fallbackCloseHandler = null;
        }
    }
} 