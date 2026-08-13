bool WE_Cmd_Help( Client @client, const String &argsString, int argc )
{
    client.printMessage( WE_MSG_HELP );
    return true;
}

bool WE_Cmd_Users( Client @client, const String &argsString, int argc )
{
    if ( !WE_RequireOperator( client ) )
        return true;
    if ( we_feature_users.integer != 1 )
    {
        client.printMessage( WE_MSG_USERS_DISABLED );
        return true;
    }
    WE_PrintPlayers( client, true );
    return true;
}

void WE_CoreCmds_Register()
{
    WE_Cmds_Add( "we_help", @WE_Cmd_Help );
    WE_Cmds_Add( "we_users", @WE_Cmd_Users );
}
