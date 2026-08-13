// Hook results for "before" callbacks (AngelScript funcdef pattern).
const int WE_HOOK_CONTINUE = 0; // keep dispatching; call GT_*__orig
const int WE_HOOK_SKIP = 1;     // stop before-chain; skip GT_*__orig

const int WE_MAX_HOOKS = 32;
const int WE_MAX_CMDS = 32;

// Lifecycle / engine hook signatures
funcdef int WE_HookThinkBeforeFn();
funcdef void WE_HookThinkAfterFn();
funcdef int WE_HookScoreEventBeforeFn( Client @client, const String &score_event, const String &args );
funcdef void WE_HookScoreEventAfterFn( Client @client, const String &score_event, const String &args );
funcdef void WE_HookShutdownFn();
funcdef void WE_HookMatchStateStartedAfterFn();
funcdef void WE_HookPlayerRespawnAfterFn( Entity @ent, int old_team, int new_team );

// Console command: return true = handled (skip GT_Command__orig)
funcdef bool WE_CmdHandlerFn( Client @client, const String &argsString, int argc );
