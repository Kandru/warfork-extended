// Command registry — features WE_Cmds_Add(); wrappers dispatch via WE_Cmds_Dispatch.

String[] weCmdNames( WE_MAX_CMDS );
WE_CmdHandlerFn@[] weCmdHandlers( WE_MAX_CMDS );
int weCmdCount = 0;

void WE_Cmds_Add( const String &in name, WE_CmdHandlerFn @handler )
{
    if ( name.len() == 0 )
        return;
    if ( @handler == null )
        return;
    if ( weCmdCount >= WE_MAX_CMDS )
        return;

    weCmdNames[weCmdCount] = name;
    @weCmdHandlers[weCmdCount] = handler;
    weCmdCount++;
}

void WE_Cmds_RegisterEngine()
{
    for ( int i = 0; i < weCmdCount; i++ )
    {
        if ( weCmdNames[i].len() == 0 )
            continue;
        G_RegisterCommand( weCmdNames[i] );
    }
}

// true => handled; skip GT_Command__orig
bool WE_Cmds_Dispatch( Client @client, const String &cmdString, const String &argsString, int argc )
{
    if ( we_enabled.integer != 1 )
        return false;

    for ( int i = 0; i < weCmdCount; i++ )
    {
        if ( weCmdNames[i] != cmdString )
            continue;
        if ( @weCmdHandlers[i] == null )
            return true;
        return weCmdHandlers[i]( client, argsString, argc );
    }
    return false;
}
