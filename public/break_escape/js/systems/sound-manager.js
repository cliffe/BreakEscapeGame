/**
 * Sound Manager
 * Centralized system for managing audio playback in Break Escape
 * 
 * Uses Phaser's sound system for playback, caching, and effects.
 * Provides convenient methods for playing common game sounds.
 */

class SoundManager {
    constructor(phaserScene) {
        this.scene = phaserScene;
        this.sounds = {};
        this.enabled = true;
        this.masterVolume = 1.0;
        
        // Sound volume categories (0-1)
        this.volumeSettings = {
            ui: 0.7,
            interactions: 0.8,
            notifications: 0.6,
            effects: 0.85,
            music: 0.5
        };
    }

    /**
     * Load all sound assets into Phaser
     * Called during the preload phase
     */
    preloadSounds() {
        // Lockpicking mini-game sounds
        this.scene.load.audio('lockpick_binding', 'sounds/lockpick_binding.mp3');
        this.scene.load.audio('lockpick_click', 'sounds/lockpick_click.mp3');
        this.scene.load.audio('lockpick_overtension', 'sounds/lockpick_overtension.mp3');
        this.scene.load.audio('lockpick_reset', 'sounds/lockpick_reset.mp3');
        this.scene.load.audio('lockpick_set', 'sounds/lockpick_set.mp3');
        this.scene.load.audio('lockpick_success', 'sounds/lockpick_success.mp3');
        this.scene.load.audio('lockpick_tension', 'sounds/lockpick_tension.mp3');
        this.scene.load.audio('lockpick_wrong', 'sounds/lockpick_wrong.mp3');

        // GASP door sounds
        this.scene.load.audio('door_knock', 'sounds/GASP_Door Knock.mp3');

        // GASP interaction sounds
        this.scene.load.audio('item_interact_1', 'sounds/GASP_Item Interact_1.mp3');
        this.scene.load.audio('item_interact_2', 'sounds/GASP_Item Interact_2.mp3');
        this.scene.load.audio('item_interact_3', 'sounds/GASP_Item Interact_3.mp3');

        // GASP lock interaction sounds
        this.scene.load.audio('lock_interact_1', 'sounds/GASP_Lock Interact_1.mp3');
        this.scene.load.audio('lock_interact_2', 'sounds/GASP_Lock Interact_2.mp3');
        this.scene.load.audio('lock_interact_3', 'sounds/GASP_Lock Interact_3.mp3');
        this.scene.load.audio('lock_interact_4', 'sounds/GASP_Lock Interact_4.mp3');
        this.scene.load.audio('lock_and_load', 'sounds/GASP_Lock and Load.mp3');

        // GASP UI click sounds
        this.scene.load.audio('ui_click_1', 'sounds/GASP_UI_Clicks_1.mp3');
        this.scene.load.audio('ui_click_2', 'sounds/GASP_UI_Clicks_2.mp3');
        this.scene.load.audio('ui_click_3', 'sounds/GASP_UI_Clicks_3.mp3');
        this.scene.load.audio('ui_click_4', 'sounds/GASP_UI_Clicks_4.mp3');
        this.scene.load.audio('ui_click_6', 'sounds/GASP_UI_Clicks_6.mp3');

        // GASP UI alert sounds
        this.scene.load.audio('ui_alert_1', 'sounds/GASP_UI_Alert_1.mp3');
        this.scene.load.audio('ui_alert_2', 'sounds/GASP_UI_Alert_2.mp3');

        // GASP UI confirm sound
        this.scene.load.audio('ui_confirm', 'sounds/GASP_UI_Confirm.mp3');

        // GASP UI notification sounds
        this.scene.load.audio('ui_notification_1', 'sounds/GASP_UI_Notification_1.mp3');
        this.scene.load.audio('ui_notification_2', 'sounds/GASP_UI_Notification_2.mp3');
        this.scene.load.audio('ui_notification_3', 'sounds/GASP_UI_Notification_3.mp3');
        this.scene.load.audio('ui_notification_4', 'sounds/GASP_UI_Notification_4.mp3');
        this.scene.load.audio('ui_notification_5', 'sounds/GASP_UI_Notification_5.mp3');
        this.scene.load.audio('ui_notification_6', 'sounds/GASP_UI_Notification_6.mp3');

        // GASP UI reject sound
        this.scene.load.audio('ui_reject', 'sounds/GASP_UI_Reject.mp3');

        // Game-specific sounds
        this.scene.load.audio('chair_roll', 'sounds/chair_roll.mp3');
        this.scene.load.audio('message_received', 'sounds/message_received.mp3');

        // Combat / KO sounds (CC0 public domain, source: bigsoundbank.com)
        this.scene.load.audio('wilhelm_scream', 'sounds/wilhelm_scream.mp3');
        this.scene.load.audio('body_fall', 'sounds/body_fall.mp3');

        // Interaction sounds (CC0 public domain, source: bigsoundbank.com)
        this.scene.load.audio('keypad_beep', 'sounds/keypad_beep.mp3');
        this.scene.load.audio('hit_impact', 'sounds/hit_impact.mp3');
        this.scene.load.audio('card_scan', 'sounds/card_scan.mp3');

        // Punch swipe sounds (CC0 public domain, source: bigsoundbank.com)
        this.scene.load.audio('punch_swipe_jab', 'sounds/punch_swipe_jab.mp3');
        this.scene.load.audio('punch_swipe_cross', 'sounds/punch_swipe_cross.mp3');

        // Hit grunt sounds (CC0 public domain, source: kenney.nl/assets/voiceover-pack-fighter)
        this.scene.load.audio('grunt_male', 'sounds/grunt_male.ogg');
        this.scene.load.audio('grunt_female', 'sounds/grunt_female.ogg');
    }

    /**
     * Initialize sound objects after preload
     * Called during scene creation
     */
    initializeSounds() {
        // Create all sound objects
        const soundNames = [
            // Lockpicking
            'lockpick_binding', 'lockpick_click', 'lockpick_overtension',
            'lockpick_reset', 'lockpick_set', 'lockpick_success',
            'lockpick_tension', 'lockpick_wrong',
            // Door
            'door_knock',
            // Interactions
            'item_interact_1', 'item_interact_2', 'item_interact_3',
            'lock_interact_1', 'lock_interact_2', 'lock_interact_3', 'lock_interact_4', 'lock_and_load',
            // UI clicks
            'ui_click_1', 'ui_click_2', 'ui_click_3', 'ui_click_4', 'ui_click_6',
            // UI alerts
            'ui_alert_1', 'ui_alert_2',
            // UI confirm
            'ui_confirm',
            // UI notifications
            'ui_notification_1', 'ui_notification_2', 'ui_notification_3',
            'ui_notification_4', 'ui_notification_5', 'ui_notification_6',
            // UI reject
            'ui_reject',
            // Game sounds
            'chair_roll', 'message_received',
            // Combat / KO sounds
            'wilhelm_scream', 'body_fall',
            // Interaction sounds
            'keypad_beep', 'hit_impact', 'card_scan',
            // Punch swipe sounds
            'punch_swipe_jab', 'punch_swipe_cross',
            // Hit grunt sounds
            'grunt_male', 'grunt_female'
        ];

        for (const soundName of soundNames) {
            try {
                this.sounds[soundName] = this.scene.sound.add(soundName, {
                    volume: this.getVolumeForSound(soundName)
                });
            } catch (error) {
                console.warn(`Failed to initialize sound: ${soundName}`, error);
            }
        }
    }

    /**
     * Determine volume level based on sound category
     */
    getVolumeForSound(soundName) {
        let category = 'effects';
        if (soundName.includes('ui_click') || soundName.includes('ui_confirm')) category = 'ui';
        else if (soundName.includes('ui_alert') || soundName.includes('ui_notification') || soundName.includes('ui_reject')) category = 'notifications';
        else if (soundName.includes('lockpick') || soundName.includes('chair') || soundName.includes('wilhelm') || soundName.includes('body_fall') || soundName.includes('hit_impact') || soundName.includes('punch_swipe') || soundName.includes('grunt_')) category = 'effects';
        else if (soundName.includes('keypad_beep') || soundName.includes('card_scan')) category = 'interactions';
        else if (soundName.includes('item_interact') || soundName.includes('lock_interact') || soundName.includes('door_knock')) category = 'interactions';
        else if (soundName.includes('message_received')) category = 'notifications';

        return this.volumeSettings[category] * this.masterVolume;
    }

    /**
     * Play a sound by name
     * @param {string} soundName - Name of the sound to play
     * @param {Object} options - Optional: { volume, loop, delay }
     */
    play(soundName, options = {}) {
        if (!this.enabled) return;

        // console log
        console.log(`🔊 Playing sound: ${soundName}`);

        const sound = this.sounds[soundName];
        if (!sound) {
            console.warn(`Sound not found: ${soundName}`);
            return;
        }

        // Set volume if specified
        if (options.volume !== undefined) {
            sound.setVolume(options.volume * this.masterVolume);
        } else {
            sound.setVolume(this.getVolumeForSound(soundName));
        }

        // Set loop if specified
        if (options.loop !== undefined) {
            sound.setLoop(options.loop);
        }

        // Set delay if specified
        if (options.delay !== undefined) {
            this.scene.time.delayedCall(options.delay, () => {
                if (sound && !sound.isPlaying) {
                    sound.play();
                }
            });
        } else {
            sound.play();
        }
    }

    /**
     * Stop a sound by name
     */
    stop(soundName) {
        const sound = this.sounds[soundName];
        if (sound) {
            sound.stop();
        }
    }

    /**
     * Stop all sounds
     */
    stopAll() {
        for (const sound of Object.values(this.sounds)) {
            if (sound && sound.isPlaying) {
                sound.stop();
            }
        }
    }

    /**
     * Play a random UI click sound
     */
    playUIClick() {
        const clicks = ['ui_click_1', 'ui_click_2', 'ui_click_3', 'ui_click_4', 'ui_click_6'];
        const randomClick = clicks[Math.floor(Math.random() * clicks.length)];
        this.play(randomClick);
    }

    /**
     * Play a random UI notification sound
     */
    playUINotification() {
        const notifications = ['ui_notification_1', 'ui_notification_2', 'ui_notification_3', 'ui_notification_4', 'ui_notification_5', 'ui_notification_6'];
        const randomNotification = notifications[Math.floor(Math.random() * notifications.length)];
        this.play(randomNotification);
    }

    /**
     * Play a random item interaction sound
     */
    playItemInteract() {
        const sounds = ['item_interact_1', 'item_interact_2', 'item_interact_3'];
        const randomSound = sounds[Math.floor(Math.random() * sounds.length)];
        this.play(randomSound);
    }

    /**
     * Play a random lock interaction sound
     */
    playLockInteract() {
        const sounds = ['lock_interact_1', 'lock_interact_2', 'lock_interact_3', 'lock_interact_4'];
        const randomSound = sounds[Math.floor(Math.random() * sounds.length)];
        this.play(randomSound);
    }

    /**
     * Set master volume (0-1)
     */
    setMasterVolume(volume) {
        this.masterVolume = Math.max(0, Math.min(1, volume));
        // Update all active sounds
        for (const sound of Object.values(this.sounds)) {
            if (sound) {
                sound.setVolume(this.getVolumeForSound(sound.key));
            }
        }
    }

    /**
     * Set category volume
     */
    setCategoryVolume(category, volume) {
        if (this.volumeSettings[category] !== undefined) {
            this.volumeSettings[category] = Math.max(0, Math.min(1, volume));
        }
    }

    /**
     * Toggle sound on/off
     */
    toggle() {
        this.enabled = !this.enabled;
        return this.enabled;
    }

    /**
     * Set enabled/disabled
     */
    setEnabled(enabled) {
        this.enabled = enabled;
    }

    /**
     * Check if sounds are enabled
     */
    isEnabled() {
        return this.enabled;
    }
}

export default SoundManager;
