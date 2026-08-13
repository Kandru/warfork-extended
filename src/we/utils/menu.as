void WE_Menu_PrintPlayers( Client @client, bool includeSpectators )
{
    client.printMessage( WE_MSG_PLAYERS_HEADER );
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( @other == null )
            continue;
        if ( other.state() < CS_SPAWNED )
            continue;
        if ( !includeSpectators && other.getEnt().team == TEAM_SPECTATOR )
            continue;

        String steamid = WE_SteamId( other );
        String line = other.playerNum + ": " + other.name;
        if ( steamid.len() > 0 )
            line += " [" + steamid + "]";
        else
            line += " [no steam_id]";
        client.printMessage( line + "\n" );
    }
}

Client @WE_Menu_ClientFromArg( Client @client, const String &in argsString, const String &in usage, bool includeSpectators )
{
    if ( argsString == "" || !argsString.getToken( 0 ).isNumerical() )
    {
        client.printMessage( usage );
        WE_Menu_PrintPlayers( client, includeSpectators );
        return null;
    }

    Client @target = @G_GetClient( argsString.getToken( 0 ).toInt() );
    if ( @target == null || @target.getEnt() == null )
    {
        client.printMessage( usage );
        WE_Menu_PrintPlayers( client, includeSpectators );
        return null;
    }
    return target;
}
