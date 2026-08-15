bool WE_IsOperator( Client @client )
{
    if ( @client == null )
        return false;
    if ( client.isOperator )
        return true;
    return WE_IsListedOperator( client );
}

bool WE_RequireOperator( Client @client )
{
    if ( WE_IsOperator( client ) )
        return true;
    WE_Print( client, WE_MSG_ADMIN_REQUIRED );
    return false;
}

bool WE_RequireNotSelf( Client @actor, Client @target )
{
    if ( @actor == null || @target == null )
        return true;
    if ( actor.playerNum != target.playerNum )
        return true;
    WE_Print( actor, WE_MSG_NO_SELF );
    return false;
}

void WE_ExecServer( const String &in cmd )
{
    G_CmdExecute( cmd );
}

void WE_KickClient( Client @client, const String &in reason )
{
    if ( @client == null )
        return;
    if ( reason.len() > 0 )
        WE_Print( client, WE_MSG_KICK_NOTIFY_PREFIX + reason + "\n" );
    WE_ExecServer( "kick " + client.playerNum + "\n" );
}
