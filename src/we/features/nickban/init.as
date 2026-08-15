const uint WE_NICKBAN_INTERVAL = 11000;

String[] weNickBanLastNick( maxClients );
int[] weNickBanStrikes( maxClients );
uint weNickBanNextCheck = 0;

void WE_NickBan_Think()
{
    if ( we_feature_nickban.integer != 1 )
        return;
    if ( weNickBanNextCheck > levelTime )
        return;
    weNickBanNextCheck = levelTime + WE_NICKBAN_INTERVAL;

    for ( int i = 0; i < maxClients; i++ )
    {
        Client @client = @G_GetClient( i );
        if ( @client == null )
            continue;

        Entity @ent = @client.getEnt();
        if ( @ent == null )
            continue;

        String name = client.name;

        if ( client.state() < CS_SPAWNED || ent.team == TEAM_SPECTATOR )
        {
            weNickBanLastNick[i] = name;
            weNickBanStrikes[i] = 0;
            continue;
        }

        // Bots / no auth — ignore (empty steam_id).
        if ( WE_SteamId( client ).len() == 0 )
            continue;

        String last = weNickBanLastNick[i];
        if ( last.len() == 0 )
        {
            weNickBanLastNick[i] = name;
            weNickBanStrikes[i] = 0;
            continue;
        }

        if ( last == name )
        {
            weNickBanStrikes[i] = 0;
            continue;
        }

        weNickBanLastNick[i] = name;
        int strikes = weNickBanStrikes[i] + 1;
        weNickBanStrikes[i] = strikes;

        if ( strikes == 1 )
        {
            WE_PrintMsg( ent, WE_Theme_Prefix() + WE_MSG_NICKBAN_WARN1 );
            continue;
        }
        if ( strikes == 2 )
        {
            WE_PrintMsg( ent, WE_Theme_Prefix() + WE_MSG_NICKBAN_WARN2 );
            continue;
        }
        if ( strikes < 3 )
            continue;

        WE_PrintMsg( null, WE_Theme_Prefix() + name + WE_MSG_NICKBAN_PUBLIC_MID );
        WE_Ban_Add( null, client, WE_MSG_NICKBAN_REASON );
        WE_KickClient( client, WE_MSG_NICKBAN_REASON );
        weNickBanStrikes[i] = 0;
    }
}

void WE_NickBan_Register()
{
    WE_Hooks_AddThinkAfter( @WE_NickBan_Think );
}
