// Command registry — features WE_Cmds_Add(); wrappers dispatch via WE_Cmds_Dispatch.

String[] weCmdNames( WE_MAX_CMDS );
String[] weCmdParams( WE_MAX_CMDS );
String[] weCmdDescs( WE_MAX_CMDS );
String[] weCmdAliases( WE_MAX_CMDS );
bool[] weCmdOperatorOnly( WE_MAX_CMDS );
WE_CmdHandlerFn@[] weCmdHandlers( WE_MAX_CMDS );
int weCmdCount = 0;

void WE_Cmds_AddEx( const String &in name, const String &in params, const String &in description,
    bool requiresOperator, WE_CmdHandlerFn @handler, const String &in aliases )
{
    if ( name.len() == 0 )
        return;
    if ( @handler == null )
        return;
    if ( weCmdCount >= WE_MAX_CMDS )
        return;

    weCmdNames[weCmdCount] = name;
    weCmdParams[weCmdCount] = params;
    weCmdDescs[weCmdCount] = description;
    weCmdAliases[weCmdCount] = aliases;
    weCmdOperatorOnly[weCmdCount] = requiresOperator;
    @weCmdHandlers[weCmdCount] = handler;
    weCmdCount++;
}

void WE_Cmds_Add( const String &in name, const String &in params, const String &in description,
    bool requiresOperator, WE_CmdHandlerFn @handler )
{
    WE_Cmds_AddEx( name, params, description, requiresOperator, handler, "" );
}

// Dispatch-only alias (omitted from we_help).
void WE_Cmds_AddAlias( const String &in name, WE_CmdHandlerFn @handler )
{
    WE_Cmds_AddEx( name, "", "", false, handler, "" );
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
