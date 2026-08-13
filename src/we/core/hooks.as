// Funcdef hook registry — features register; wrappers only dispatch.

WE_HookThinkBeforeFn@[] weHookThinkBefore( WE_MAX_HOOKS );
WE_HookThinkAfterFn@[] weHookThinkAfter( WE_MAX_HOOKS );
WE_HookScoreEventBeforeFn@[] weHookScoreBefore( WE_MAX_HOOKS );
WE_HookScoreEventAfterFn@[] weHookScoreAfter( WE_MAX_HOOKS );
WE_HookShutdownFn@[] weHookShutdown( WE_MAX_HOOKS );
WE_HookMatchStateStartedAfterFn@[] weHookMatchStateStartedAfter( WE_MAX_HOOKS );
WE_HookPlayerRespawnAfterFn@[] weHookPlayerRespawnAfter( WE_MAX_HOOKS );

int weHookThinkBeforeCount = 0;
int weHookThinkAfterCount = 0;
int weHookScoreBeforeCount = 0;
int weHookScoreAfterCount = 0;
int weHookShutdownCount = 0;
int weHookMatchStateStartedAfterCount = 0;
int weHookPlayerRespawnAfterCount = 0;

void WE_Hooks_AddThinkBefore( WE_HookThinkBeforeFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookThinkBeforeCount >= WE_MAX_HOOKS )
        return;
    @weHookThinkBefore[weHookThinkBeforeCount] = fn;
    weHookThinkBeforeCount++;
}

void WE_Hooks_AddThinkAfter( WE_HookThinkAfterFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookThinkAfterCount >= WE_MAX_HOOKS )
        return;
    @weHookThinkAfter[weHookThinkAfterCount] = fn;
    weHookThinkAfterCount++;
}

void WE_Hooks_AddScoreEventBefore( WE_HookScoreEventBeforeFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookScoreBeforeCount >= WE_MAX_HOOKS )
        return;
    @weHookScoreBefore[weHookScoreBeforeCount] = fn;
    weHookScoreBeforeCount++;
}

void WE_Hooks_AddScoreEventAfter( WE_HookScoreEventAfterFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookScoreAfterCount >= WE_MAX_HOOKS )
        return;
    @weHookScoreAfter[weHookScoreAfterCount] = fn;
    weHookScoreAfterCount++;
}

void WE_Hooks_AddShutdown( WE_HookShutdownFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookShutdownCount >= WE_MAX_HOOKS )
        return;
    @weHookShutdown[weHookShutdownCount] = fn;
    weHookShutdownCount++;
}

void WE_Hooks_AddMatchStateStartedAfter( WE_HookMatchStateStartedAfterFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookMatchStateStartedAfterCount >= WE_MAX_HOOKS )
        return;
    @weHookMatchStateStartedAfter[weHookMatchStateStartedAfterCount] = fn;
    weHookMatchStateStartedAfterCount++;
}

void WE_Hooks_AddPlayerRespawnAfter( WE_HookPlayerRespawnAfterFn @fn )
{
    if ( @fn == null )
        return;
    if ( weHookPlayerRespawnAfterCount >= WE_MAX_HOOKS )
        return;
    @weHookPlayerRespawnAfter[weHookPlayerRespawnAfterCount] = fn;
    weHookPlayerRespawnAfterCount++;
}

// true => skip GT_ThinkRules__orig
bool WE_Hooks_DispatchThinkBefore()
{
    for ( int i = 0; i < weHookThinkBeforeCount; i++ )
    {
        if ( @weHookThinkBefore[i] == null )
            continue;
        if ( weHookThinkBefore[i]() == WE_HOOK_SKIP )
            return true;
    }
    return false;
}

void WE_Hooks_DispatchThinkAfter()
{
    for ( int i = 0; i < weHookThinkAfterCount; i++ )
    {
        if ( @weHookThinkAfter[i] == null )
            continue;
        weHookThinkAfter[i]();
    }
}

bool WE_Hooks_DispatchScoreEventBefore( Client @client, const String &score_event, const String &args )
{
    for ( int i = 0; i < weHookScoreBeforeCount; i++ )
    {
        if ( @weHookScoreBefore[i] == null )
            continue;
        if ( weHookScoreBefore[i]( client, score_event, args ) == WE_HOOK_SKIP )
            return true;
    }
    return false;
}

void WE_Hooks_DispatchScoreEventAfter( Client @client, const String &score_event, const String &args )
{
    for ( int i = 0; i < weHookScoreAfterCount; i++ )
    {
        if ( @weHookScoreAfter[i] == null )
            continue;
        weHookScoreAfter[i]( client, score_event, args );
    }
}

void WE_Hooks_DispatchShutdown()
{
    for ( int i = 0; i < weHookShutdownCount; i++ )
    {
        if ( @weHookShutdown[i] == null )
            continue;
        weHookShutdown[i]();
    }
}

void WE_Hooks_DispatchMatchStateStartedAfter()
{
    for ( int i = 0; i < weHookMatchStateStartedAfterCount; i++ )
    {
        if ( @weHookMatchStateStartedAfter[i] == null )
            continue;
        weHookMatchStateStartedAfter[i]();
    }
}

void WE_Hooks_DispatchPlayerRespawnAfter( Entity @ent, int old_team, int new_team )
{
    for ( int i = 0; i < weHookPlayerRespawnAfterCount; i++ )
    {
        if ( @weHookPlayerRespawnAfter[i] == null )
            continue;
        weHookPlayerRespawnAfter[i]( ent, old_team, new_team );
    }
}
