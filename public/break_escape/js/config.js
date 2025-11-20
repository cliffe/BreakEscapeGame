// API configuration from server
export const GAME_ID = window.breakEscapeConfig?.gameId;
export const API_BASE = window.breakEscapeConfig?.apiBasePath || '';
export const ASSETS_PATH = window.breakEscapeConfig?.assetsPath || '/break_escape/assets';

// CSRF Token - Try multiple sources (in order of preference)
export const CSRF_TOKEN =
  window.breakEscapeConfig?.csrfToken ||  // From config object (if set in view)
  document.querySelector('meta[name="csrf-token"]')?.content;  // From meta tag (Hacktivity layout)

// Verify critical config loaded
if (!GAME_ID) {
  console.error('❌ CRITICAL: Game ID not configured! Check window.breakEscapeConfig');
  console.error('Expected window.breakEscapeConfig.gameId to be set by server');
}

if (!CSRF_TOKEN) {
  console.error('❌ CRITICAL: CSRF token not found!');
  console.error('This will cause all POST/PUT requests to fail with 422 status');
  console.error('Checked:');
  console.error('  1. window.breakEscapeConfig.csrfToken');
  console.error('  2. meta[name="csrf-token"] tag');
  console.error('');
  console.error('Solutions:');
  console.error('  - If using Hacktivity layout: Ensure layout has <%= csrf_meta_tags %>');
  console.error('  - If standalone: Add <%= csrf_meta_tags %> to layout OR');
  console.error('  - Set window.breakEscapeConfig.csrfToken in view');
}

// Log config for debugging
if (window.breakEscapeConfig?.debug || !CSRF_TOKEN) {
  console.log('✓ BreakEscape config validated:', {
    gameId: GAME_ID,
    apiBasePath: API_BASE,
    assetsPath: ASSETS_PATH,
    csrfToken: CSRF_TOKEN ? `${CSRF_TOKEN.substring(0, 10)}...` : '❌ MISSING',
    csrfTokenSource: window.breakEscapeConfig?.csrfToken ? 'config object' :
                     (document.querySelector('meta[name="csrf-token"]') ? 'meta tag' : 'NOT FOUND'),
    debug: window.breakEscapeConfig?.debug || false
  });
}
