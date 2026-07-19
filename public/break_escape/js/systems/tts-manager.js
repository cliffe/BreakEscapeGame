/**
 * TTS Manager - Text-to-Speech audio playback for person-chat conversations
 *
 * Fetches server-generated MP3 audio for NPC dialog lines and plays via HTML5 Audio.
 * Supports preloading next line while current plays. Gracefully degrades if TTS
 * is unavailable (no API key, network error, etc.).
 *
 * Audio is routed through MusicController (shared AudioContext): the HTMLMediaElement
 * feeds an AnalyserNode (mouth animation) then MusicController.voiceGain so the
 * Voice / Master sliders in the music widget affect TTS level.
 */

import { ApiClient } from '../api-client.js';
import MusicController from '../music/music-controller.js';

class TTSManager {
    constructor() {
        this.audio = new Audio();
        this.enabled = true;
        this.volume = 0.8;
        this.preloadCache = new Map(); // "npcId|text" -> objectURL
        this.onEndedCallback = null;
        this.playing = false;
        this._hasSrc = false; // Whether audio.src has been set to a real URL

        // Web Audio: one MediaElementSource per <audio> element, shared context
        this._mediaElementSource = null;
        this._analyser = null;
        this._amplitudeBuffer = null;
        this._ttsAudioRouted = false;

        this.audio.volume = 1;
        this.audio.addEventListener('ended', () => {
            this.playing = false;
            if (this.onEndedCallback) {
                this.onEndedCallback();
            }
        });

        this.audio.addEventListener('error', () => {
            this.playing = false;
        });
    }

    /**
     * Play TTS audio for a dialogue line
     * @param {string} npcId - NPC identifier
     * @param {string} text - Clean dialogue text (no "Speaker: " prefix)
     * @returns {Promise<number|null>} Audio duration in ms, or null if unavailable
     */
    async play(npcId, text) {
        if (!this.enabled || !text || !text.trim()) return null;

        // Stop any current playback
        this.stop();

        // Shared graph: MediaElement → analyser → voiceGain (requires user gesture for ctx)
        this._ensureAudioContext();

        try {
            const key = this._cacheKey(npcId, text);

            // Check preload cache first
            let audioUrl = this.preloadCache.get(key);

            if (audioUrl) {
                // Consume from preload cache
                this.preloadCache.delete(key);
            } else {
                // Fetch from server
                const blob = await ApiClient.getTTS(npcId, text);
                if (!blob) return null;
                audioUrl = URL.createObjectURL(blob);
            }

            this.audio.src = audioUrl;
            this._hasSrc = true;

            // Wait for metadata to get duration
            const duration = await new Promise((resolve, reject) => {
                const onLoaded = () => {
                    cleanup();
                    resolve(Math.ceil(this.audio.duration * 1000));
                };
                const onError = () => {
                    cleanup();
                    reject(new Error('Audio load failed'));
                };
                const timeout = setTimeout(() => {
                    cleanup();
                    reject(new Error('Audio load timeout'));
                }, 10000);

                const cleanup = () => {
                    this.audio.removeEventListener('loadedmetadata', onLoaded);
                    this.audio.removeEventListener('error', onError);
                    clearTimeout(timeout);
                };

                this.audio.addEventListener('loadedmetadata', onLoaded);
                this.audio.addEventListener('error', onError);
            });

            this.playing = true;

            // Resume shared context if suspended (autoplay policy)
            if (MusicController.context?.state === 'suspended') {
                MusicController.context.resume().catch(() => {});
            }

            await this.audio.play();

            console.log(`[TTS] Playing for ${npcId}: "${text.substring(0, 40)}..." (${duration}ms)`);
            return duration;
        } catch (error) {
            this.playing = false;
            console.warn('[TTS] Play failed:', error.message);
            return null;
        }
    }

    /**
     * Preload audio for an upcoming line (fetch but don't play)
     * @param {string} npcId - NPC identifier
     * @param {string} text - Dialogue text
     */
    async preload(npcId, text) {
        if (!this.enabled || !text || !text.trim()) return;

        const key = this._cacheKey(npcId, text);
        if (this.preloadCache.has(key)) return;

        try {
            const blob = await ApiClient.getTTS(npcId, text);
            if (blob) {
                this.preloadCache.set(key, URL.createObjectURL(blob));
                console.log(`[TTS] Preloaded: "${text.substring(0, 40)}..."`);
            }
        } catch (error) {
            // Silently fail — preloading is best-effort
        }
    }

    /**
     * Stop current playback
     */
    stop() {
        if (this.playing) {
            this.audio.pause();
            this.audio.currentTime = 0;
            this.playing = false;
        }
        // Use removeAttribute instead of src = '' to avoid the
        // "Invalid URI. Load of media resource failed." browser error
        // that fires whenever an empty string is assigned to audio.src.
        if (this._hasSrc) {
            if (this.audio.src.startsWith('blob:')) {
                URL.revokeObjectURL(this.audio.src);
            }
            this.audio.removeAttribute('src');
            this._hasSrc = false;
        }
    }

    /**
     * Check if audio is currently playing
     * @returns {boolean}
     */
    isPlaying() {
        return this.playing;
    }

    /**
     * Set callback for when audio finishes playing
     * @param {Function} callback
     */
    onEnded(callback) {
        this.onEndedCallback = callback;
    }

    /**
     * Set volume (0.0 - 1.0) — drives MusicController voice bus (same as music widget Voice slider).
     * @param {number} vol
     */
    setVolume(vol) {
        this.volume = Math.max(0, Math.min(1, vol));
        MusicController.setVoiceVolume(this.volume);
        this.audio.volume = 1;
    }

    /**
     * Enable/disable TTS
     * @param {boolean} enabled
     */
    setEnabled(enabled) {
        this.enabled = enabled;
        if (!enabled) this.stop();
    }

    /**
     * Clean up resources
     */
    destroy() {
        this.stop();
        for (const url of this.preloadCache.values()) {
            URL.revokeObjectURL(url);
        }
        this.preloadCache.clear();
        this.onEndedCallback = null;

        try { this._mediaElementSource?.disconnect(); } catch (_) {}
        try { this._analyser?.disconnect(); } catch (_) {}
        this._mediaElementSource = null;
        this._analyser = null;
        this._amplitudeBuffer = null;
        this._ttsAudioRouted = false;
    }

    /**
     * Get current RMS amplitude of TTS audio (0.0 – 1.0).
     * Returns 0 when not playing or Web Audio API is unavailable.
     */
    getAmplitude() {
        if (!this._analyser || !this.playing) return 0;
        this._analyser.getByteTimeDomainData(this._amplitudeBuffer);
        let sum = 0;
        const len = this._amplitudeBuffer.length;
        for (let i = 0; i < len; i++) {
            const v = (this._amplitudeBuffer[i] - 128) / 128;
            sum += v * v;
        }
        return Math.sqrt(sum / len); // RMS amplitude
    }

    /**
     * Returns true when TTS audio is above the noise-gate threshold.
     * Only reflects TTS audio – game SFX routed through Phaser are unaffected.
     * @param {number} threshold - Amplitude threshold (default 0.02)
     */
    isSpeaking(threshold = 0.02) {
        return this.getAmplitude() > threshold;
    }

    /** @private */
    _ensureAudioContext() {
        if (this._ttsAudioRouted) return;
        const ctx = MusicController?.context;
        if (!ctx) {
            console.warn('[TTS] MusicController.context unavailable; TTS uses element volume only');
            this.audio.volume = this.volume;
            return;
        }
        try {
            if (!this._mediaElementSource) {
                this._mediaElementSource = ctx.createMediaElementSource(this.audio);
            }
            if (!this._analyser) {
                this._analyser = ctx.createAnalyser();
                this._analyser.fftSize = 256;
                this._analyser.smoothingTimeConstant = 0.2;
                this._amplitudeBuffer = new Uint8Array(this._analyser.frequencyBinCount);
            }
            try { this._mediaElementSource.disconnect(); } catch (_) {}
            try { this._analyser.disconnect(); } catch (_) {}
            this._mediaElementSource.connect(this._analyser);
            this._analyser.connect(MusicController.voiceGain);
            this.audio.volume = 1;
            this._ttsAudioRouted = true;
        } catch (e) {
            console.warn('[TTS] Web Audio routing unavailable, mouth animation may be disabled:', e.message);
            this._mediaElementSource = null;
            this._analyser = null;
            this._amplitudeBuffer = null;
            this.audio.volume = this.volume;
        }
    }

    /** @private */
    _cacheKey(npcId, text) {
        return `${npcId}|${text}`;
    }
}

export default TTSManager;
