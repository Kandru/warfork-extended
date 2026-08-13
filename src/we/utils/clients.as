// Online-client lookup: slot number, unique case-insensitive name fragment,
// or unique steam_id fragment (WE_FindClientBySteamIdFragment, used by we_ban).

void WE_PrintPlayers( Client @client, bool includeSpectators )
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

bool WE_ClientListed( Client @other, bool includeSpectators )
{
    if ( @other == null )
        return false;
    if ( other.state() < CS_SPAWNED )
        return false;
    if ( @other.getEnt() == null )
        return false;
    if ( !includeSpectators && other.getEnt().team == TEAM_SPECTATOR )
        return false;
    return true;
}

void WE_PrintPlayerLine( Client @to, Client @other )
{
    if ( @to == null || @other == null )
        return;
    to.printMessage( other.playerNum + ": " + other.name + "\n" );
}

void WE_PrintPlayerLineWithSteam( Client @to, Client @other )
{
    if ( @to == null || @other == null )
        return;

    String steamid = WE_SteamId( other );
    String line = other.playerNum + ": " + other.name;
    if ( steamid.len() > 0 )
        line += " [" + steamid + "]";
    else
        line += " [no steam_id]";
    to.printMessage( line + "\n" );
}

bool WE_ClientSteamMatches( Client @other, const String &in query )
{
    if ( @other == null )
        return false;
    String steamid = WE_SteamId( other );
    if ( steamid.len() == 0 )
        return false;
    return WE_ContainsIgnoreCase( steamid, query );
}

bool WE_ClientNameMatches( Client @other, const String &in query )
{
    if ( @other == null )
        return false;
    return WE_ContainsIgnoreCase( WE_StripColors( other.name ), query );
}

bool WE_ClientNameEquals( Client @other, const String &in query )
{
    if ( @other == null )
        return false;
    return WE_EqualsIgnoreCase( WE_StripColors( other.name ), query );
}

// Silent resolve. null if missing or not unique. Numeric slot wins when that client exists.
Client @WE_FindClient( const String &in query, bool includeSpectators )
{
    if ( query.len() == 0 )
        return null;

    if ( query.isNumerical() )
    {
        Client @byNum = @G_GetClient( query.toInt() );
        if ( @byNum != null && @byNum.getEnt() != null )
            return byNum;
    }

    int matchCount = 0;
    int exactCount = 0;
    Client @found = null;
    Client @exact = null;

    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientNameMatches( other, query ) )
            continue;

        matchCount++;
        @found = @other;
        if ( WE_ClientNameEquals( other, query ) )
        {
            exactCount++;
            @exact = @other;
        }
    }

    if ( matchCount == 1 )
        return found;
    if ( exactCount == 1 )
        return exact;
    return null;
}

bool WE_ClientQueryAmbiguous( const String &in query, bool includeSpectators )
{
    if ( query.len() == 0 )
        return false;
    if ( @WE_FindClient( query, includeSpectators ) != null )
        return false;

    int matchCount = 0;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientNameMatches( other, query ) )
            continue;
        matchCount++;
        if ( matchCount > 1 )
            return true;
    }
    return false;
}

void WE_PrintClientMatches( Client @to, const String &in query, bool includeSpectators )
{
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientNameMatches( other, query ) )
            continue;
        WE_PrintPlayerLine( to, other );
    }
}

// Silent resolve by unique steam_id fragment. null if missing or not unique.
Client @WE_FindClientBySteamIdFragment( const String &in query, bool includeSpectators )
{
    if ( query.len() == 0 )
        return null;

    int matchCount = 0;
    Client @found = null;

    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientSteamMatches( other, query ) )
            continue;

        matchCount++;
        @found = @other;
    }

    if ( matchCount == 1 )
        return found;
    return null;
}

bool WE_ClientSteamQueryAmbiguous( const String &in query, bool includeSpectators )
{
    if ( query.len() == 0 )
        return false;
    if ( @WE_FindClientBySteamIdFragment( query, includeSpectators ) != null )
        return false;

    int matchCount = 0;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientSteamMatches( other, query ) )
            continue;
        matchCount++;
        if ( matchCount > 1 )
            return true;
    }
    return false;
}

void WE_PrintClientSteamMatches( Client @to, const String &in query, bool includeSpectators )
{
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientSteamMatches( other, query ) )
            continue;
        WE_PrintPlayerLineWithSteam( to, other );
    }
}

// Resolve query; print usage + player list, or the ambiguous matches.
Client @WE_ClientFromQuery( Client @actor, const String &in query, const String &in usage, bool includeSpectators )
{
    if ( query.len() == 0 )
    {
        actor.printMessage( usage );
        WE_PrintPlayers( actor, includeSpectators );
        return null;
    }

    Client @target = @WE_FindClient( query, includeSpectators );
    if ( @target != null )
        return target;

    if ( WE_ClientQueryAmbiguous( query, includeSpectators ) )
    {
        actor.printMessage( WE_MSG_PLAYER_AMBIGUOUS );
        WE_PrintClientMatches( actor, query, includeSpectators );
        return null;
    }

    actor.printMessage( usage );
    WE_PrintPlayers( actor, includeSpectators );
    return null;
}

// First args token as userid.
Client @WE_ClientFromArg( Client @actor, const String &in argsString, const String &in usage, bool includeSpectators )
{
    return WE_ClientFromQuery( actor, argsString.getToken( 0 ), usage, includeSpectators );
}
