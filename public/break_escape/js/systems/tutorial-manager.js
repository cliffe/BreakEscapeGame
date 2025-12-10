/**
 * Tutorial Manager
 * Handles the basic actions tutorial for new players
 */

const TUTORIAL_STORAGE_KEY = 'tutorial_completed';
const TUTORIAL_DECLINED_KEY = 'tutorial_declined';

export class TutorialManager {
    constructor() {
        this.active = false;
        this.currentStep = 0;
        this.steps = [];
        this.isMobile = this.detectMobile();
        this.tutorialOverlay = null;
        this.onComplete = null;

        // Track player actions for tutorial progression
        this.playerMoved = false;
        this.playerInteracted = false;
        this.playerRan = false;
    }

    /**
     * Detect if the user is on a mobile device
     */
    detectMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
            || window.innerWidth < 768;
    }

    /**
     * Check if tutorial has been completed before
     */
    hasCompletedTutorial() {
        return localStorage.getItem(TUTORIAL_STORAGE_KEY) === 'true';
    }

    /**
     * Check if tutorial was declined
     */
    hasDeclinedTutorial() {
        return localStorage.getItem(TUTORIAL_DECLINED_KEY) === 'true';
    }

    /**
     * Mark tutorial as completed
     */
    markCompleted() {
        localStorage.setItem(TUTORIAL_STORAGE_KEY, 'true');
    }

    /**
     * Mark tutorial as declined
     */
    markDeclined() {
        localStorage.setItem(TUTORIAL_DECLINED_KEY, 'true');
    }

    /**
     * Show prompt asking if player wants to do tutorial
     */
    showTutorialPrompt() {
        return new Promise((resolve) => {
            // Create modal overlay
            const overlay = document.createElement('div');
            overlay.className = 'tutorial-prompt-overlay';
            overlay.innerHTML = `
                <div class="tutorial-prompt-modal">
                    <h2>Welcome to BreakEscape!</h2>
                    <p>Would you like to go through a quick tutorial to learn the basic controls?</p>
                    <div class="tutorial-prompt-buttons">
                        <button id="tutorial-yes" class="tutorial-btn tutorial-btn-primary">Yes, show me</button>
                        <button id="tutorial-no" class="tutorial-btn tutorial-btn-secondary">No, I'll figure it out</button>
                    </div>
                </div>
            `;

            document.body.appendChild(overlay);

            document.getElementById('tutorial-yes').addEventListener('click', () => {
                document.body.removeChild(overlay);
                resolve(true);
            });

            document.getElementById('tutorial-no').addEventListener('click', () => {
                this.markDeclined();
                document.body.removeChild(overlay);
                resolve(false);
            });
        });
    }

    /**
     * Start the tutorial
     */
    async start(onComplete) {
        this.active = true;
        this.onComplete = onComplete;
        this.currentStep = 0;

        // Define tutorial steps based on device type
        if (this.isMobile) {
            this.steps = [
                {
                    title: 'Movement',
                    instruction: 'Click or tap on the ground where you want to move. Your character will walk to that position.',
                    objective: 'Try moving around by clicking different locations',
                    checkComplete: () => this.playerMoved
                },
                {
                    title: 'Interaction',
                    instruction: 'Click or tap on objects, items, or characters to interact with them.',
                    objective: 'Look for highlighted objects you can interact with',
                    checkComplete: () => this.playerInteracted
                },
                {
                    title: 'Objectives',
                    instruction: 'Check the objectives panel in the top-right corner to see your current tasks.',
                    objective: 'Complete objectives to progress through the game',
                    checkComplete: () => true, // Auto-complete this step
                    autoAdvanceDelay: 3000
                }
            ];
        } else {
            this.steps = [
                {
                    title: 'Movement',
                    instruction: 'Use W, A, S, D keys to move your character around.',
                    objective: 'Try moving in different directions',
                    checkComplete: () => this.playerMoved
                },
                {
                    title: 'Running',
                    instruction: 'Hold Shift while moving to run faster.',
                    objective: 'Hold Shift and move with WASD',
                    checkComplete: () => this.playerRan
                },
                {
                    title: 'Interaction',
                    instruction: 'Press E to interact with nearby objects, pick up items, or talk to characters.',
                    objective: 'Look for highlighted objects and press E to interact',
                    checkComplete: () => this.playerInteracted
                },
                {
                    title: 'Alternative Movement',
                    instruction: 'You can also click on the ground to move to that location.',
                    objective: 'Try clicking where you want to go',
                    checkComplete: () => true, // Auto-complete
                    autoAdvanceDelay: 3000
                },
                {
                    title: 'Objectives',
                    instruction: 'Check the objectives panel in the top-right corner to see your current tasks.',
                    objective: 'Complete objectives to progress through the game',
                    checkComplete: () => true, // Auto-complete
                    autoAdvanceDelay: 3000
                }
            ];
        }

        this.createTutorialOverlay();
        this.showStep(0);
    }

    /**
     * Create the tutorial overlay UI
     */
    createTutorialOverlay() {
        this.tutorialOverlay = document.createElement('div');
        this.tutorialOverlay.className = 'tutorial-overlay';
        this.tutorialOverlay.innerHTML = `
            <div class="tutorial-panel">
                <div class="tutorial-header">
                    <span class="tutorial-progress"></span>
                    <button class="tutorial-skip" title="Skip Tutorial">Skip Tutorial</button>
                </div>
                <h3 class="tutorial-title"></h3>
                <p class="tutorial-instruction"></p>
                <div class="tutorial-objective">
                    <strong>Objective:</strong>
                    <span class="tutorial-objective-text"></span>
                </div>
                <div class="tutorial-actions">
                    <button class="tutorial-next" style="display: none;">Continue</button>
                </div>
            </div>
        `;

        document.body.appendChild(this.tutorialOverlay);

        // Skip button
        this.tutorialOverlay.querySelector('.tutorial-skip').addEventListener('click', () => {
            this.skip();
        });

        // Next button
        this.tutorialOverlay.querySelector('.tutorial-next').addEventListener('click', () => {
            this.nextStep();
        });
    }

    /**
     * Show a specific tutorial step
     */
    showStep(stepIndex) {
        if (stepIndex >= this.steps.length) {
            this.complete();
            return;
        }

        this.currentStep = stepIndex;
        const step = this.steps[stepIndex];

        // Update UI
        const overlay = this.tutorialOverlay;
        overlay.querySelector('.tutorial-progress').textContent = `Step ${stepIndex + 1} of ${this.steps.length}`;
        overlay.querySelector('.tutorial-title').textContent = step.title;
        overlay.querySelector('.tutorial-instruction').textContent = step.instruction;
        overlay.querySelector('.tutorial-objective-text').textContent = step.objective;

        // Hide next button initially
        const nextButton = overlay.querySelector('.tutorial-next');
        nextButton.style.display = 'none';

        // Check if step has auto-advance
        if (step.autoAdvanceDelay) {
            setTimeout(() => {
                if (this.active && this.currentStep === stepIndex) {
                    this.nextStep();
                }
            }, step.autoAdvanceDelay);
        } else {
            // Start checking for completion
            this.checkStepCompletion(step, nextButton);
        }
    }

    /**
     * Check if current step is completed
     */
    checkStepCompletion(step, nextButton) {
        const interval = setInterval(() => {
            if (!this.active || this.currentStep !== this.steps.indexOf(step)) {
                clearInterval(interval);
                return;
            }

            if (step.checkComplete()) {
                // Step completed!
                nextButton.style.display = 'inline-block';
                nextButton.textContent = 'Continue →';
                clearInterval(interval);

                // Auto-advance after showing success
                setTimeout(() => {
                    if (this.active && nextButton.style.display === 'inline-block') {
                        this.nextStep();
                    }
                }, 1500);
            }
        }, 100);
    }

    /**
     * Advance to next step
     */
    nextStep() {
        this.showStep(this.currentStep + 1);
    }

    /**
     * Complete the tutorial
     */
    complete() {
        this.active = false;
        this.markCompleted();

        if (this.tutorialOverlay) {
            document.body.removeChild(this.tutorialOverlay);
            this.tutorialOverlay = null;
        }

        // Show completion message
        if (window.showNotification) {
            window.showNotification(
                'You can now explore the facility. Check your objectives in the top-right corner!',
                'success',
                'Tutorial Complete!',
                5000
            );
        }

        if (this.onComplete) {
            this.onComplete();
        }
    }

    /**
     * Skip the tutorial
     */
    skip() {
        if (confirm('Are you sure you want to skip the tutorial?')) {
            this.active = false;
            this.markCompleted();

            if (this.tutorialOverlay) {
                document.body.removeChild(this.tutorialOverlay);
                this.tutorialOverlay = null;
            }

            if (this.onComplete) {
                this.onComplete();
            }
        }
    }

    /**
     * Notify tutorial of player movement
     */
    notifyPlayerMoved() {
        if (this.active) {
            this.playerMoved = true;
        }
    }

    /**
     * Notify tutorial of player interaction
     */
    notifyPlayerInteracted() {
        if (this.active) {
            this.playerInteracted = true;
        }
    }

    /**
     * Notify tutorial of player running
     */
    notifyPlayerRan() {
        if (this.active) {
            this.playerRan = true;
        }
    }

    /**
     * Reset tutorial progress (for testing)
     */
    static resetTutorial() {
        localStorage.removeItem(TUTORIAL_STORAGE_KEY);
        localStorage.removeItem(TUTORIAL_DECLINED_KEY);
    }
}

// Create singleton instance
let tutorialManagerInstance = null;

export function getTutorialManager() {
    if (!tutorialManagerInstance) {
        tutorialManagerInstance = new TutorialManager();
    }
    return tutorialManagerInstance;
}

// Expose to window for easy access
if (typeof window !== 'undefined') {
    window.getTutorialManager = getTutorialManager;
    window.resetTutorial = TutorialManager.resetTutorial;
}
