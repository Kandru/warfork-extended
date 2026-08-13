bool WE_Cmd_Respawn( Client @client, const String &argsString, int argc )
{
    if ( we_feature_respawn.integer != 1 )
    {
        WE_Print( client, WE_MSG_RESPAWN_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_RESPAWN_USAGE, true, true );
    if ( @target == null )
        return true;

    if ( @target.getEnt() == null || target.getEnt().team == TEAM_SPECTATOR )
    {
        WE_Print( client, WE_MSG_RESPAWN_SPECTATOR );
        return true;
    }

    target.respawn( false );
    WE_Print( target, WE_MSG_RESPAWN_NOTIFY );
    WE_Print( client, WE_MSG_RESPAWN_DONE );
    return true;
}

void WE_Respawn_Register()
{
    WE_Cmds_Add( "we_respawn", "<userid>", "Force-respawn a player", @WE_Cmd_Respawn );
}
