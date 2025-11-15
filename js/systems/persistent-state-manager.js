/**
 * Persistent State Manager
 *
 * Manages cross-scenario variable persistence, allowing narrative state
 * to carry over between different game scenarios.
 *
 * This is NOT a "save game" feature - it's a cross-scenario narrative
 * persistence layer that tracks things like:
 * - NPC trust levels
 * - Discussion topics covered
 * - Narrative decisions made
 *
 * @module persistent-state-manager
 */

// Error codes for structured logging
const PersistentStateErrors = {
    INVALID_JSON: 'PSM_001',
    TYPE_MISMATCH: 'PSM_002',
    MISSING_METADATA: 'PSM_003',
    LOAD_FAILED: 'PSM_004',
    INVALID_STRUCTURE: 'PSM_005'
};

/**
 * Persistent State Manager Class
 *
 * @class
 * @example
 * const manager = new PersistentStateManager();
 * manager.extractCarryOverMetadata(scenario.globalVariables);
 * const merged = manager.mergeWithScenarioDefaults(persistentState, scenario.globalVariables);
 */
export class PersistentStateManager {
    constructor() {
        this.version = 1;
        this.loadedState = null;
        this.carryOverMetadata = new Map(); // varName → { default, type, description, carryOver }
        this.debugMode = false;

        console.log('💾 Persistent State Manager initialized (v' + this.version + ')');
    }

    /**
     * Deep clone a value (supports primitives, arrays, objects)
     * Uses structuredClone if available, otherwise manual deep clone
     *
     * @private
     * @param {*} obj - Value to clone
     * @returns {*} Deep cloned value
     */
    _deepClone(obj) {
        // Use browser's structuredClone if available (modern browsers)
        if (typeof structuredClone === 'function') {
            try {
                return structuredClone(obj);
            } catch (e) {
                // Fall back to manual clone if structuredClone fails
                console.warn('⚠️ structuredClone failed, using manual clone:', e.message);
            }
        }

        // Manual deep clone fallback
        if (obj === null || typeof obj !== 'object') return obj;
        if (Array.isArray(obj)) return obj.map(item => this._deepClone(item));

        const cloned = {};
        for (const [key, value] of Object.entries(obj)) {
            cloned[key] = this._deepClone(value);
        }
        return cloned;
    }

    /**
     * Extract carry-over metadata from scenario's globalVariables definition
     *
     * Parses both simple and metadata formats:
     * - Simple: { "var": value } → carryOver: false
     * - Metadata: { "var": { default, carryOver, type } } → uses flags
     *
     * @param {Object} scenarioGlobalVariables - globalVariables from scenario.json
     * @returns {void}
     * @throws {Error} If scenarioGlobalVariables is not an object
     */
    extractCarryOverMetadata(scenarioGlobalVariables) {
        if (!scenarioGlobalVariables || typeof scenarioGlobalVariables !== 'object') {
            console.warn('⚠️ No globalVariables defined in scenario');
            return;
        }

        this.carryOverMetadata.clear();

        for (const [varName, value] of Object.entries(scenarioGlobalVariables)) {
            // Check if this looks like metadata object format
            if (typeof value === 'object' &&
                value !== null &&
                !Array.isArray(value) &&
                'default' in value) {

                // Metadata format: { default, carryOver, type, description }
                const metadata = {
                    default: value.default,
                    carryOver: value.carryOver ?? false,
                    type: value.type || (Array.isArray(value.default) ? 'array' : typeof value.default),
                    description: value.description || null
                };

                this.carryOverMetadata.set(varName, metadata);

                if (this.debugMode) {
                    console.log(`🔍 [DEBUG] Extracted metadata for ${varName}:`, metadata);
                }
            } else {
                // Simple value format - not a carry-over variable by default
                const metadata = {
                    default: value,
                    carryOver: false,
                    type: Array.isArray(value) ? 'array' : typeof value,
                    description: null
                };

                this.carryOverMetadata.set(varName, metadata);

                if (this.debugMode) {
                    console.log(`🔍 [DEBUG] Extracted simple format for ${varName}:`, metadata);
                }
            }
        }

        const carryOverCount = Array.from(this.carryOverMetadata.values())
            .filter(m => m.carryOver).length;
        const sessionOnlyCount = this.carryOverMetadata.size - carryOverCount;

        console.log(`📋 Extracted ${this.carryOverMetadata.size} variable definitions:`);
        console.log(`   Carry-over: ${carryOverCount}`);
        console.log(`   Session-only: ${sessionOnlyCount}`);
    }

    /**
     * Merge persistent state with scenario defaults
     *
     * Strategy:
     * - For carry-over variables: use persistent value if exists, else use default
     * - For session-only variables: always use scenario default
     * - Validate types before applying persistent values
     *
     * @param {Object|null} persistentVariables - Variables from persistent state JSON
     * @param {Object} scenarioGlobalVariables - globalVariables from scenario.json
     * @returns {Object} Merged global variables object
     */
    mergeWithScenarioDefaults(persistentVariables, scenarioGlobalVariables) {
        const merged = {};

        // First extract metadata if not already done
        if (this.carryOverMetadata.size === 0) {
            this.extractCarryOverMetadata(scenarioGlobalVariables);
        }

        let loadedCount = 0;
        let defaultCount = 0;
        let typeMismatchCount = 0;

        this.carryOverMetadata.forEach((metadata, varName) => {
            let value = this._deepClone(metadata.default);

            // Only override with persistent state if this is a carry-over variable
            if (metadata.carryOver && persistentVariables && varName in persistentVariables) {
                const persistentValue = persistentVariables[varName];

                // Type validation
                const expectedType = Array.isArray(metadata.default) ? 'array' : typeof metadata.default;
                const actualType = Array.isArray(persistentValue) ? 'array' : typeof persistentValue;

                if (expectedType !== actualType) {
                    console.warn(`⚠️ [${PersistentStateErrors.TYPE_MISMATCH}] Type mismatch for ${varName}:`);
                    console.warn(`   Expected: ${expectedType}, Got: ${actualType}`);
                    console.warn(`   Using default value:`, metadata.default);
                    typeMismatchCount++;
                } else {
                    value = this._deepClone(persistentValue);
                    loadedCount++;

                    if (this.debugMode) {
                        console.log(`🔍 [DEBUG] Loaded ${varName} from persistent state:`, value);
                    } else {
                        console.log(`✅ Loaded ${varName} from persistent state`);
                    }
                }
            } else if (metadata.carryOver && !persistentVariables) {
                defaultCount++;
                if (this.debugMode) {
                    console.log(`ℹ️ No persistent state - using default for ${varName}:`, value);
                }
            } else if (metadata.carryOver && !(varName in persistentVariables)) {
                defaultCount++;
                if (this.debugMode) {
                    console.log(`ℹ️ No persistent value for ${varName} - using default:`, value);
                }
            }

            merged[varName] = value;
        });

        // Summary
        console.log(`📊 Merge Summary:`);
        console.log(`   Loaded from persistent state: ${loadedCount}`);
        console.log(`   Using scenario defaults: ${defaultCount}`);
        if (typeMismatchCount > 0) {
            console.warn(`   Type mismatches: ${typeMismatchCount}`);
        }

        return merged;
    }

    /**
     * Export current carry-over variables as JSON object
     *
     * @param {string} lastScenarioId - ID of current scenario
     * @returns {Object} Persistent state object with version, timestamp, variables
     */
    exportPersistentState(lastScenarioId = 'unknown') {
        const exported = {
            version: this.version,
            timestamp: new Date().toISOString(),
            lastScenario: lastScenarioId,
            variables: {},
            metadata: {
                exportedCount: 0,
                sessionOnlyCount: 0
            }
        };

        let exportedCount = 0;
        let sessionOnlyCount = 0;

        this.carryOverMetadata.forEach((metadata, varName) => {
            if (metadata.carryOver) {
                if (window.gameState?.globalVariables?.hasOwnProperty(varName)) {
                    exported.variables[varName] = this._deepClone(
                        window.gameState.globalVariables[varName]
                    );
                    exportedCount++;
                }
            } else {
                sessionOnlyCount++;
            }
        });

        exported.metadata.exportedCount = exportedCount;
        exported.metadata.sessionOnlyCount = sessionOnlyCount;

        console.log(`📤 Exported persistent state:`);
        console.log(`   Scenario: ${lastScenarioId}`);
        console.log(`   Carried over: ${exportedCount} variables`);
        console.log(`   Session-only: ${sessionOnlyCount} variables (not exported)`);

        return exported;
    }

    /**
     * Download persistent state as JSON file (triggers browser download)
     *
     * @param {string} filename - Output filename (default: persistent-state.json)
     */
    downloadAsJSON(filename = 'persistent-state.json') {
        const scenarioId = window.gameScenario?.scenario_id || 'game';
        const state = this.exportPersistentState(scenarioId);

        const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);

        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        console.log('✅ Downloaded persistent state as:', filename);
    }

    /**
     * Console command to view current persistent state
     * Shows carry-over variables, current values, defaults, and export preview
     */
    viewPersistentState() {
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📊 PERSISTENT STATE VIEWER');
        console.log('═══════════════════════════════════════════════════════════');

        console.log('\n🔍 Carry-Over Variables:');
        const carryOverVars = Array.from(this.carryOverMetadata.entries())
            .filter(([_, metadata]) => metadata.carryOver);

        if (carryOverVars.length === 0) {
            console.log('   (No carry-over variables defined)');
        } else {
            carryOverVars.forEach(([varName, metadata]) => {
                const currentValue = window.gameState?.globalVariables?.[varName];
                const changed = currentValue !== metadata.default ? '📝' : '';
                console.log(`   ${changed} ${varName}:`, currentValue, `(default: ${JSON.stringify(metadata.default)})`);
            });
        }

        console.log('\n📦 Full Export Preview:');
        const exported = this.exportPersistentState();
        console.log(JSON.stringify(exported, null, 2));

        console.log('\n💡 Available Commands:');
        console.log('  window.exportPersistentState() - Export as JSON object');
        console.log('  window.downloadPersistentState(filename) - Download JSON file');
        console.log('  window.viewPersistentState() - Show this viewer');
        console.log('═══════════════════════════════════════════════════════════');
    }

    /**
     * Log diff between defaults and loaded values (helpful for debugging)
     *
     * @param {Object} merged - Merged global variables
     */
    logStateDiff(merged) {
        console.log('📊 Persistent State Diff:');

        const diffData = {};
        this.carryOverMetadata.forEach((metadata, varName) => {
            if (metadata.carryOver) {
                const currentValue = merged[varName];
                const isChanged = JSON.stringify(currentValue) !== JSON.stringify(metadata.default);

                diffData[varName] = {
                    default: JSON.stringify(metadata.default),
                    loaded: JSON.stringify(currentValue),
                    changed: isChanged ? '✅' : ''
                };
            }
        });

        console.table(diffData);
    }

    /**
     * Future: POST persistent state to server endpoint
     *
     * Expected server endpoint:
     * POST /api/persistent-state
     * Headers: Authorization: Bearer {token}
     * Body: { version, timestamp, lastScenario, variables }
     *
     * Response:
     * { success: true, savedAt: timestamp, stateId: uuid }
     *
     * @param {string} endpoint - Server API endpoint
     * @param {string} authToken - JWT or API key
     * @returns {Promise<Object>} Server response
     */
    async postToServer(endpoint, authToken) {
        const scenarioId = window.gameScenario?.scenario_id || 'unknown';
        const state = this.exportPersistentState(scenarioId);

        try {
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${authToken}`
                },
                body: JSON.stringify(state)
            });

            if (!response.ok) {
                throw new Error(`Server returned ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();
            console.log('✅ Persistent state saved to server:', result);
            return result;

        } catch (error) {
            console.error('❌ Failed to save persistent state to server:', error.message);
            throw error;
        }
    }
}
