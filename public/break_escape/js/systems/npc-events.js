// Minimal event dispatcher for NPC events
// Exports default class NPCEventDispatcher with .on(pattern, cb) and .emit(type, data)
export default class NPCEventDispatcher {
  constructor(opts = {}) {
    this.debug = !!opts.debug;
    this.listeners = new Map(); // map eventType -> [callbacks]
  }

  on(eventType, cb) {
    if (!eventType || typeof cb !== 'function') return;
    if (!this.listeners.has(eventType)) this.listeners.set(eventType, []);
    this.listeners.get(eventType).push(cb);
  }

  off(eventType, cb) {
    if (!this.listeners.has(eventType)) return;
    if (!cb) { this.listeners.delete(eventType); return; }
    const arr = this.listeners.get(eventType).filter(f => f !== cb);
    this.listeners.set(eventType, arr);
  }

  emit(eventType, data) {
    if (this.debug) console.log('[NPCEventDispatcher] emit', eventType, data);
    // exact-match listeners
    const exact = this.listeners.get(eventType) || [];
    for (const fn of exact) try { fn(data); } catch (e) { console.error(e); }

    // wildcard-style listeners where eventType is a prefix (e.g. 'npc:')
    for (const [key, arr] of this.listeners.entries()) {
      if (key.endsWith('*')) {
        const prefix = key.slice(0, -1);
        if (eventType.startsWith(prefix)) for (const fn of arr) try { fn(data); } catch (e) { console.error(e); }
      }
    }
  }
}
