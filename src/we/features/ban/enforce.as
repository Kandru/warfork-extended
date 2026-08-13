void WE_Ban_CheckClient( Client @client )
{
    if ( @client == null )
        return;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return;
    if ( !WE_Ban_IsSteamBanned( steamid ) )
        return;

    WE_KickClient( client, "banned" );
}

void WE_Ban_Think()
{
    if ( we_feature_ban.integer != 1 )
        return;

    if ( weBanNextReload < levelTime )
    {
        WE_Ban_Reload();
        weBanNextReload = levelTime + WE_BAN_RELOAD_INTERVAL_MS;
    }

    if ( weBanCount == 0 )
        return;

    for ( int i = 0; i < maxClients; i++ )
    {
        Client @client = @G_GetClient( i );
        if ( @client == null )
            continue;
        if ( client.state() <= CS_CONNECTING )
            continue;
        WE_Ban_CheckClient( client );
    }
}

void WE_Ban_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( we_feature_ban.integer != 1 )
        return;
    if ( score_event != "enterGame" )
        return;
    WE_Ban_CheckClient( client );
}

void WE_Ban_Init()
{
    if ( we_feature_ban.integer != 1 )
        return;
    WE_Ban_Reload();
    weBanNextReload = levelTime + WE_BAN_RELOAD_INTERVAL_MS;
}

void WE_Ban_Register()
{
    // we_kick stays available even when we_feature_ban is 0 (kick vs ban).
    WE_Hooks_AddThinkAfter( @WE_Ban_Think );
    WE_Hooks_AddScoreEventAfter( @WE_Ban_OnScoreEvent );
    WE_Cmds_Add( "we_kick", "<userid> [reason]", "Kick a player", @WE_Cmd_Kick );
    WE_Cmds_Add( "we_ban", "<userid|name|steam_id> [reason]", "Ban a player", @WE_Cmd_Ban );
    WE_Cmds_Add( "we_unban", "[index]", "Unban a player", @WE_Cmd_Unban );
}
