// Online-client lookup: slot number, unique case-insensitive name fragment,
// or unique steam_id fragment (WE_FindClientBySteamIdFragment, used by we_ban).

void WE_PrintPlayers( Client @client, bool includeSpectators )
{
    client.printMessage( WE_MSG_PLAYERS_HEADER );
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        WE_PrintPlayerLineWithSteam( client, other );
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

// Silent resolve. null if missing or not unique. Numeric slot wins when that client is listed.
Client @WE_FindClient( const String &in query, bool includeSpectators )
{
    if ( query.len() == 0 )
        return null;

    if ( query.isNumerical() )
    {
        Client @byNum = @G_GetClient( query.toInt() );
        if ( WE_ClientListed( byNum, includeSpectators ) )
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

    int kind = WE_UniqueMatchKind( matchCount, exactCount );
    if ( kind == WE_MATCH_UNIQUE )
        return found;
    if ( kind == WE_MATCH_EXACT )
        return exact;
    return null;
}

bool WE_ClientQueryAmbiguous( const String &in query, bool includeSpectators )
{
    if ( query.len() == 0 )
        return false;

    int matchCount = 0;
    int exactCount = 0;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientNameMatches( other, query ) )
            continue;
        matchCount++;
        if ( WE_ClientNameEquals( other, query ) )
            exactCount++;
    }
    return WE_UniqueMatchKind( matchCount, exactCount ) == WE_MATCH_AMBIGUOUS;
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

    if ( query.isNumerical() )
    {
        Client @byNum = @G_GetClient( query.toInt() );
        if ( WE_ClientListed( byNum, includeSpectators ) )
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

    int kind = WE_UniqueMatchKind( matchCount, exactCount );
    if ( kind == WE_MATCH_UNIQUE )
        return found;
    if ( kind == WE_MATCH_EXACT )
        return exact;

    if ( kind == WE_MATCH_AMBIGUOUS )
    {
        actor.printMessage( WE_MSG_PLAYER_AMBIGUOUS );
        for ( int i = 0; i < maxClients; i++ )
        {
            Client @other = @G_GetClient( i );
            if ( !WE_ClientListed( other, includeSpectators ) )
                continue;
            if ( !WE_ClientNameMatches( other, query ) )
                continue;
            WE_PrintPlayerLine( actor, other );
        }
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
