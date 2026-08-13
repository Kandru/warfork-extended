bool WE_IsOperator( Client @client )
{
    if ( @client == null )
        return false;
    return client.isOperator;
}

bool WE_RequireOperator( Client @client )
{
    if ( WE_IsOperator( client ) )
        return true;
    client.printMessage( WE_MSG_ADMIN_REQUIRED );
    return false;
}

bool WE_RequireNotSelf( Client @actor, Client @target )
{
    if ( @actor == null || @target == null )
        return true;
    if ( actor.playerNum != target.playerNum )
        return true;
    actor.printMessage( WE_MSG_NO_SELF );
    return false;
}

void WE_ExecServer( const String &in cmd )
{
    G_CmdExecute( cmd );
}

void WE_ExecClient( Client @client, const String &in cmd )
{
    if ( @client == null )
        return;
    client.execGameCommand( cmd );
}

void WE_KickClient( Client @client, const String &in reason )
{
    if ( @client == null )
        return;
    if ( reason.len() > 0 )
        client.printMessage( WE_MSG_KICK_NOTIFY_PREFIX + reason + "\n" );
    WE_ExecServer( "kick " + client.playerNum + "\n" );
}
