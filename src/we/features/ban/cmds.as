bool WE_Cmd_Kick( Client @client, const String &argsString, int argc )
{
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_KICK_USAGE, true );
    if ( @target == null )
        return true;
    if ( !WE_RequireNotSelf( client, target ) )
        return true;

    String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
    if ( reason.len() == 0 )
        reason = WE_MSG_NO_REASON;

    WE_KickClient( target, reason );
    client.printMessage( WE_MSG_KICK_DONE );
    return true;
}

void WE_Cmd_Ban_PrintTargets( Client @client )
{
    client.printMessage( WE_MSG_BAN_USAGE );
    WE_PrintPlayers( client, true );
    WE_RecentDisconnects_Print( client );
}

bool WE_Cmd_Ban( Client @client, const String &argsString, int argc )
{
    if ( we_feature_ban.integer != 1 )
    {
        client.printMessage( WE_MSG_BAN_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    String query = argsString.getToken( 0 );
    if ( query.len() == 0 )
    {
        WE_Cmd_Ban_PrintTargets( client );
        return true;
    }

    Client @target = @WE_FindClient( query, true );
    if ( @target != null )
    {
        if ( !WE_RequireNotSelf( client, target ) )
            return true;
        if ( WE_SteamId( target ).len() == 0 )
        {
            client.printMessage( WE_MSG_BAN_NO_STEAM );
            return true;
        }

        String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
        if ( reason.len() == 0 )
            reason = WE_MSG_NO_REASON;

        WE_Ban_Reload();
        if ( !WE_Ban_Add( client, target, reason ) )
        {
            client.printMessage( WE_MSG_BAN_FULL );
            return true;
        }

        target.printMessage( WE_MSG_BAN_NOTIFY_PREFIX + reason + "\n" );
        WE_KickClient( target, reason );
        client.printMessage( WE_MSG_BAN_DONE );
        return true;
    }

    if ( WE_ClientQueryAmbiguous( query, true ) )
    {
        client.printMessage( WE_MSG_PLAYER_AMBIGUOUS );
        WE_PrintClientMatches( client, query, true );
        return true;
    }

    // Offline ban by steam_id (must be known from user file or recent list).
    if ( WE_RecentDisconnects_IsKnown( query ) )
    {
        String actorSteam = WE_SteamId( client );
        if ( actorSteam.len() > 0 && actorSteam == query )
        {
            client.printMessage( WE_MSG_NO_SELF );
            return true;
        }

        String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
        if ( reason.len() == 0 )
            reason = WE_MSG_NO_REASON;

        String name = WE_UserGet( query, "name" );
        String clan = WE_UserGet( query, "clan" );

        WE_Ban_Reload();
        if ( !WE_Ban_AddSteam( client, query, name, clan, reason ) )
        {
            client.printMessage( WE_MSG_BAN_FULL );
            return true;
        }

        Client @online = @WE_FindClientBySteamId( query );
        if ( @online != null )
        {
            online.printMessage( WE_MSG_BAN_NOTIFY_PREFIX + reason + "\n" );
            WE_KickClient( online, reason );
        }

        client.printMessage( WE_MSG_BAN_DONE );
        return true;
    }

    WE_Cmd_Ban_PrintTargets( client );
    return true;
}

bool WE_Cmd_Unban( Client @client, const String &argsString, int argc )
{
    if ( we_feature_ban.integer != 1 )
    {
        client.printMessage( WE_MSG_BAN_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    WE_Ban_Reload();
    if ( argsString == "" || !argsString.getToken( 0 ).isNumerical() )
    {
        client.printMessage( WE_MSG_UNBAN_USAGE );
        WE_Ban_PrintList( client );
        return true;
    }

    int index = argsString.getToken( 0 ).toInt();
    if ( index < 0 || index >= weBanCount || weBanSteamId[index].len() == 0 )
    {
        client.printMessage( WE_MSG_UNBAN_BAD_INDEX );
        return true;
    }

    WE_Ban_RemoveIndex( index );
    client.printMessage( WE_MSG_UNBAN_DONE );
    return true;
}
