/**
 * Phone Message Converter
 * Converts simple text/voice phone messages to Ink JSON format at runtime
 * This allows backward compatibility with existing scenario phone objects
 */

export class PhoneMessageConverter {
    /**
     * Convert a simple phone object to Ink JSON story
     * @param {Object} phoneObject - Phone object from scenario JSON
     * @returns {Object} Ink JSON story
     */
    static toInkJSON(phoneObject) {
        // Extract the message text (prefer voice over text)
        let messageText = phoneObject.voice || phoneObject.text || '';
        
        if (!messageText) {
            console.warn('Phone object has no message text:', phoneObject);
            return null;
        }
        
        // Add "voice: " prefix if this is a voice message
        if (phoneObject.voice) {
            messageText = `voice: ${messageText}`;
        }
        
        // Create minimal Ink JSON structure
        // This is the compiled format that InkEngine can load
        const inkJSON = {
            "inkVersion": 21,
            "root": [
                [
                    ["done", {"#n": "g-0"}],
                    null
                ],
                "done",
                {
                    "start": [
                        `^${messageText}`,
                        "\n",
                        "end",
                        null
                    ],
                    "global decl": [
                        "ev",
                        "/ev",
                        "end",
                        null
                    ]
                }
            ],
            "listDefs": {}
        };
        
        return inkJSON;
    }
    
    /**
     * Check if a phone object needs conversion
     * @param {Object} phoneObject - Phone object from scenario JSON
     * @returns {boolean} True if object has simple message format
     */
    static needsConversion(phoneObject) {
        // Check if it's a phone object with voice/text but no NPC story
        return phoneObject.type === 'phone' && 
               (phoneObject.voice || phoneObject.text) &&
               !phoneObject.npcIds &&
               !phoneObject.storyPath;
    }
    
    /**
     * Create a virtual NPC for a simple phone message
     * @param {Object} phoneObject - Phone object from scenario JSON
     * @returns {Object} NPC configuration object
     */
    static createVirtualNPC(phoneObject) {
        // Generate unique NPC ID from phone name + timestamp to allow multiple messages
        const baseName = phoneObject.name.toLowerCase().replace(/[^a-z0-9]/g, '_');
        const timestamp = Date.now();
        const npcId = `phone_msg_${baseName}_${timestamp}`;
        
        // Convert to Ink JSON
        const inkJSON = this.toInkJSON(phoneObject);
        
        if (!inkJSON) {
            return null;
        }
        
        // Create NPC config
        const npc = {
            id: npcId,
            displayName: phoneObject.sender || phoneObject.name || 'Unknown',
            storyJSON: inkJSON, // Provide JSON directly instead of path
            avatar: phoneObject.avatar || null,
            phoneId: phoneObject.phoneId || 'default_phone',
            currentKnot: 'start',
            npcType: 'phone',
            metadata: {
                timestamp: phoneObject.timestamp,
                converted: true,
                originalPhone: phoneObject.name,
                isSimpleMessage: true // Mark as converted message
            }
        };
        
        return npc;
    }
    
    /**
     * Convert and register a simple phone message as a virtual NPC
     * @param {Object} phoneObject - Phone object from scenario JSON
     * @param {Object} npcManager - NPCManager instance
     * @returns {string|null} NPC ID if successful, null otherwise
     */
    static convertAndRegister(phoneObject, npcManager) {
        if (!this.needsConversion(phoneObject)) {
            return null;
        }
        
        const npc = this.createVirtualNPC(phoneObject);
        
        if (!npc) {
            console.error('Failed to create virtual NPC for phone:', phoneObject);
            return null;
        }
        
        // Register with NPC manager
        npcManager.registerNPC(npc);
        
        console.log(`✅ Converted phone message to virtual NPC: ${npc.id}`);
        
        return npc.id;
    }
}

export default PhoneMessageConverter;
