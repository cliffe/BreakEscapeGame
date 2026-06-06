import { MinigameScene } from '../framework/base-minigame.js';

// Load title screen CSS
const titleScreenCSS = document.createElement('link');
titleScreenCSS.rel = 'stylesheet';
titleScreenCSS.href = '/break_escape/css/title-screen.css';
titleScreenCSS.id = 'title-screen-css';
if (!document.getElementById('title-screen-css')) {
    document.head.appendChild(titleScreenCSS);
}

/**
 * Title Screen Minigame
 * Phase 1: Hacktivity logo fades in, zooms to 200%, fades out.
 * Phase 2: Mission display_name typed out terminal-style with blinking cursor.
 * Cursor keeps blinking while the game world finishes loading.
 */
export class TitleScreenMinigame extends MinigameScene {
    constructor(container, params) {
        super(container, params);
        this.autoCloseTimeout = params?.autoCloseTimeout ?? 3000;
    }

    init() {
        this.container.innerHTML = `
            <div class="title-screen-container">
                <img src="/break_escape/assets/logos/hacktivity-logo.svg" alt="Hacktivity Logo" class="title-screen-logo">
                <div class="title-screen-title" style="visibility: hidden;">
                    <span class="title-screen-typed-text"></span><span class="title-screen-cursor">█</span>
                </div>
            </div>
        `;

        this.container.style.cssText = `
            width: 100%;
            height: 100%;
            position: fixed;
            top: 0;
            left: 0;
            z-index: 10000;
            display: flex;
            justify-content: center;
            align-items: center;
            background: #1a1a1a;
            margin: 0;
            padding: 0;
        `;

        this.titleScreenContainer = this.container.querySelector('.title-screen-container');
        this._typingStarted = false;
        this._typingTimer = null;
    }

    start() {
        super.start();
        console.log('🎬 Title Screen started');

        const logo = this.container.querySelector('.title-screen-logo');
        const titleEl = this.container.querySelector('.title-screen-title');
        const typedTextEl = this.container.querySelector('.title-screen-typed-text');

        // Phase 1 → 2 transition: fixed timer matches the CSS animation duration.
        // animationend is unreliable when the CSS loads asynchronously after the element
        // is already in the DOM (the animation may never have started).
        setTimeout(() => {
            logo.style.visibility = 'hidden';
            titleEl.style.visibility = 'visible'; // cursor blinks immediately
            this._startTyping(typedTextEl);
        }, 2500);

        // game_loaded fires after the world finishes building — use it only for the
        // safety-close timer (typing may already be done by then).
        this._onGameLoaded = () => {
            window.eventDispatcher?.off('game_loaded', this._onGameLoaded);
            this._onGameLoaded = null;
            console.log('🎬 Title screen: game_loaded received, arming safety timer');
            if (!this.autoCloseTimeout) {
                this.autoCloseTimer = setTimeout(() => {
                    if (window.MinigameFramework?.currentMinigame === this) {
                        console.log('⏱️ Title screen: no opening minigame, closing via safety timer');
                        this.complete(true);
                    }
                }, 3000);
            }
        };

        if (window.eventDispatcher) {
            window.eventDispatcher.on('game_loaded', this._onGameLoaded);
        } else {
            console.warn('🎬 Title screen: eventDispatcher not ready, closing will be handled by game.js');
        }

        if (this.autoCloseTimeout) {
            this.autoCloseTimer = setTimeout(() => {
                console.log('⏱️ Title screen auto-closing after timeout');
                this.complete(true);
            }, this.autoCloseTimeout);
        }
    }

    // missionDisplayName is embedded by the Rails view into breakEscapeConfig before
    // the page script runs, so it is available immediately — no polling needed.
    _startTyping(typedTextEl) {
        if (this._typingStarted) return;
        this._typingStarted = true;

        const name = window.breakEscapeConfig?.missionDisplayName ?? '';
        // Same character set as the matrix visualiser in bond-visualiser.js
        const SCRAMBLE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*<>{}[]|/\\';
        const SCRAMBLE_STEPS = 5;  // random frames shown before each character locks in
        const FRAME_MS = 38;       // ms per scramble frame
        const LOCK_PAUSE = 90;     // ms pause after each character locks before moving on

        let i = 0;

        const typeNext = () => {
            if (i >= name.length) return; // done — cursor keeps blinking

            let step = 0;
            const scramble = () => {
                if (step < SCRAMBLE_STEPS) {
                    const rand = SCRAMBLE_CHARS[Math.floor(Math.random() * SCRAMBLE_CHARS.length)];
                    typedTextEl.textContent = name.slice(0, i) + rand;
                    step++;
                    this._typingTimer = setTimeout(scramble, FRAME_MS);
                } else {
                    typedTextEl.textContent = name.slice(0, ++i);
                    this._typingTimer = setTimeout(typeNext, LOCK_PAUSE);
                }
            };
            this._typingTimer = setTimeout(scramble, FRAME_MS);
        };

        typeNext();
    }

    complete(success) {
        console.log('🎬 Title screen closing');
        if (this.autoCloseTimer) clearTimeout(this.autoCloseTimer);
        super.complete(success);
    }

    cleanup() {
        if (this.autoCloseTimer) clearTimeout(this.autoCloseTimer);
        if (this._typingTimer) clearTimeout(this._typingTimer);
        if (this._onGameLoaded) {
            window.eventDispatcher?.off('game_loaded', this._onGameLoaded);
            this._onGameLoaded = null;
        }
        super.cleanup();
    }
}

/**
 * Helper function to start the title screen minigame
 */
export function startTitleScreenMinigame(params = {}) {
    if (!window.MinigameFramework) {
        console.error('MinigameFramework not initialized');
        return;
    }

    const container = document.createElement('div');
    container.className = 'minigame-container';
    container.style.cssText = `
        width: 100%;
        height: 100%;
        position: fixed;
        top: 0;
        left: 0;
        z-index: 10000;
        display: flex;
        justify-content: center;
        align-items: center;
        background: rgba(26, 26, 26, 0.95);
    `;
    document.body.appendChild(container);

    return window.MinigameFramework.startMinigame('title-screen', container, {
        title: 'BreakEscape',
        hideGameDuringMinigame: false,
        showCancel: false,
        headerElement: null,
        disableGameInput: true,
        ...params
    });
}
