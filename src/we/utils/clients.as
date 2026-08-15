// Online-client lookup: slot number, unique case-insensitive name fragment,
// or unique steam_id fragment (WE_FindClientBySteamIdFragment, used by we_ban).

const int WE_RECENT_ID_BASE = 900;

String WE_ClientDisplayName( Client @client )
{
    if ( @client == null )
        return "";
    String name = WE_StripColors( client.name );
    String clan = WE_Trim( WE_StripColors( client.clanName ) );
    if ( clan.len() == 0 )
        return name;
    return "[" + clan + "] " + name;
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
        int num = query.toInt();
        if ( num >= 0 && num < WE_RECENT_ID_BASE )
        {
            Client @byNum = @G_GetClient( num );
            if ( WE_ClientListed( byNum, includeSpectators ) )
                return byNum;
        }
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

Client @WE_FindClientBySteamId( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return null;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, true ) )
            continue;
        if ( WE_SteamId( other ) == steamid )
            return other;
    }
    return null;
}
