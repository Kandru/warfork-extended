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
    WE_Print( client, WE_MSG_KICK_DONE );
    return true;
}

void WE_Cmd_Ban_PrintTargets( Client @client )
{
    WE_Print( client, WE_MSG_BAN_USAGE );
    WE_PrintPlayers( client, true );
    WE_RecentDisconnects_Print( client );
}

bool WE_Cmd_Ban_ApplySteam( Client @client, const String &in steamid, const String &in reason )
{
    String actorSteam = WE_SteamId( client );
    if ( actorSteam.len() > 0 && actorSteam == steamid )
    {
        WE_Print( client, WE_MSG_NO_SELF );
        return true;
    }

    String name = "";
    String clan = "";
    String data;
    if ( WE_UserLoad( steamid, data ) )
    {
        name = WE_KvGet( data, "name" );
        clan = WE_KvGet( data, "clan" );
    }

    WE_Ban_Reload();
    if ( !WE_Ban_AddSteam( client, steamid, name, clan, reason ) )
    {
        WE_Print( client, WE_MSG_BAN_FULL );
        return true;
    }

    Client @online = @WE_FindClientBySteamId( steamid );
    if ( @online != null )
    {
        WE_Print( online, WE_MSG_BAN_NOTIFY_PREFIX + reason + "\n" );
        WE_KickClient( online, reason );
    }

    WE_Print( client, WE_MSG_BAN_DONE );
    return true;
}

bool WE_Cmd_Ban_ApplyClient( Client @client, Client @target, const String &in reason )
{
    if ( !WE_RequireNotSelf( client, target ) )
        return true;
    if ( WE_SteamId( target ).len() == 0 )
    {
        WE_Print( client, WE_MSG_BAN_NO_STEAM );
        return true;
    }

    WE_Ban_Reload();
    if ( !WE_Ban_Add( client, target, reason ) )
    {
        WE_Print( client, WE_MSG_BAN_FULL );
        return true;
    }

    WE_Print( target, WE_MSG_BAN_NOTIFY_PREFIX + reason + "\n" );
    WE_KickClient( target, reason );
    WE_Print( client, WE_MSG_BAN_DONE );
    return true;
}

bool WE_Cmd_Ban( Client @client, const String &argsString, int argc )
{
    if ( we_feature_ban.integer != 1 )
    {
        WE_Print( client, WE_MSG_BAN_DISABLED );
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

    String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
    if ( reason.len() == 0 )
        reason = WE_MSG_NO_REASON;

    Client @target = @WE_FindClient( query, true );
    if ( @target != null )
        return WE_Cmd_Ban_ApplyClient( client, target, reason );

    if ( WE_ClientQueryAmbiguous( query, true ) )
    {
        WE_Print( client, WE_MSG_PLAYER_AMBIGUOUS );
        WE_PrintClientMatches( client, query, true );
        return true;
    }

    Client @bySteam = @WE_FindClientBySteamIdFragment( query, true );
    String recentSteam = WE_RecentDisconnects_FindSteam( query );
    bool steamAmbiguous = WE_ClientSteamQueryAmbiguous( query, true )
        || WE_RecentDisconnects_QueryAmbiguousBy( query, false );
    if ( @bySteam != null && recentSteam.len() > 0 && WE_SteamId( bySteam ) != recentSteam )
        steamAmbiguous = true;

    if ( steamAmbiguous )
    {
        WE_Print( client, WE_MSG_PLAYER_AMBIGUOUS );
        WE_PrintClientSteamMatches( client, query, true );
        WE_RecentDisconnects_PrintMatchesBy( client, query, false );
        return true;
    }

    if ( @bySteam != null )
        return WE_Cmd_Ban_ApplyClient( client, bySteam, reason );
    if ( recentSteam.len() > 0 )
        return WE_Cmd_Ban_ApplySteam( client, recentSteam, reason );

    String recentName = WE_RecentDisconnects_FindName( query );
    if ( recentName.len() > 0 )
        return WE_Cmd_Ban_ApplySteam( client, recentName, reason );

    if ( WE_RecentDisconnects_QueryAmbiguousBy( query, true ) )
    {
        WE_Print( client, WE_MSG_PLAYER_AMBIGUOUS );
        WE_RecentDisconnects_PrintMatchesBy( client, query, true );
        return true;
    }

    // Offline ban by full steam_id (user file or recent list).
    if ( WE_RecentDisconnects_IsKnown( query ) )
        return WE_Cmd_Ban_ApplySteam( client, query, reason );

    WE_Cmd_Ban_PrintTargets( client );
    return true;
}

bool WE_Cmd_Unban( Client @client, const String &argsString, int argc )
{
    if ( we_feature_ban.integer != 1 )
    {
        WE_Print( client, WE_MSG_BAN_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    WE_Ban_Reload();
    if ( argsString == "" || !argsString.getToken( 0 ).isNumerical() )
    {
        WE_Print( client, WE_MSG_UNBAN_USAGE );
        WE_Ban_PrintList( client );
        return true;
    }

    int index = argsString.getToken( 0 ).toInt();
    if ( index < 0 || index >= weBanCount || weBanSteamId[index].len() == 0 )
    {
        WE_Print( client, WE_MSG_UNBAN_BAD_INDEX );
        return true;
    }

    WE_Ban_RemoveIndex( index );
    WE_Print( client, WE_MSG_UNBAN_DONE );
    return true;
}
