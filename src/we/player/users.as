const int WE_MAX_RECENT_DISCONNECTS = 25;
const int WE_RECENT_WORK_MAX = 128;
const String WE_RECENT_DISCONNECTS_PATH = "warfork-extended/recent_disconnects.txt";
const String WE_RECENT_DISCONNECTS_LOCK = "recent_disconnects";

String[] weRecentIds( WE_RECENT_WORK_MAX );
uint[] weRecentUnix( WE_RECENT_WORK_MAX );
int weRecentCount = 0;

String[] weRecentAddIds( WE_RECENT_WORK_MAX );
int weRecentAddCount = 0;

String WE_UserPath( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return "";
    return WE_ROOT + "users/" + steamid + ".txt";
}

bool WE_UserExists( const String &in steamid )
{
    String path = WE_UserPath( steamid );
    if ( path.len() == 0 )
        return false;
    return WE_FileExists( path );
}

bool WE_UserLoad( const String &in steamid, String &out data )
{
    data = "";
    String path = WE_UserPath( steamid );
    if ( path.len() == 0 )
        return false;
    return WE_LoadFile( path, data );
}

String WE_UserGet( const String &in steamid, const String &in key )
{
    String data;
    if ( !WE_UserLoad( steamid, data ) )
        return "";
    return WE_KvGet( data, key );
}

void WE_UserSet( const String &in steamid, const String &in key, const String &in value )
{
    String path = WE_UserPath( steamid );
    if ( path.len() == 0 )
        return;

    String data;
    WE_LoadFile( path, data );
    data = WE_KvSet( data, key, WE_SanitizeField( value ) );
    WE_WriteFileLocked( path, "user_" + steamid, data );
}

uint WE_UserLeaveUnixFromData( const String &in data )
{
    String disc = WE_KvGet( data, "last_disconnected_unix" );
    if ( disc.len() > 0 && disc.isNumerical() )
        return uint( disc.toInt() );

    String conn = WE_KvGet( data, "last_connected_unix" );
    if ( conn.len() > 0 && conn.isNumerical() )
        return uint( conn.toInt() );
    return 0;
}

String WE_UserLeaveHumanFromData( const String &in data )
{
    String disc = WE_KvGet( data, "last_disconnected" );
    if ( disc.len() > 0 )
        return disc;
    return WE_KvGet( data, "last_connected" );
}

uint WE_UserLeaveUnix( const String &in steamid )
{
    String data;
    if ( !WE_UserLoad( steamid, data ) )
        return 0;
    return WE_UserLeaveUnixFromData( data );
}

String WE_UserLeaveHuman( const String &in steamid )
{
    String data;
    if ( !WE_UserLoad( steamid, data ) )
        return "";
    return WE_UserLeaveHumanFromData( data );
}

void WE_UserStamp( Client @client, bool connected )
{
    if ( @client == null )
        return;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return;

    String path = WE_UserPath( steamid );
    String data;
    WE_LoadFile( path, data );

    String snapshot;
    WE_SnapshotUserInfo( client, snapshot );
    data = WE_KvMergeBlob( data, snapshot );
    data = WE_KvDelete( data, "password" );
    if ( connected )
    {
        data = WE_KvSet( data, "last_connected", WE_HumanTimeNow() );
        data = WE_KvSet( data, "last_connected_unix", WE_UnixTimestamp() );
    }
    else
    {
        data = WE_KvSet( data, "last_disconnected", WE_HumanTimeNow() );
        data = WE_KvSet( data, "last_disconnected_unix", WE_UnixTimestamp() );
    }
    WE_WriteFileLocked( path, "user_" + steamid, data );
}

void WE_UserTouchConnected( Client @client )
{
    WE_UserStamp( client, true );
}

void WE_UserStampDisconnected( Client @client )
{
    WE_UserStamp( client, false );
}

void WE_RecentDisconnects_ClearWork()
{
    weRecentCount = 0;
    for ( int i = 0; i < WE_RECENT_WORK_MAX; i++ )
    {
        weRecentIds[i] = "";
        weRecentUnix[i] = 0;
    }
}

void WE_RecentDisconnects_ParseIntoWork( const String &in data )
{
    WE_RecentDisconnects_ClearWork();
    String line;
    uint pos = 0;
    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;
        if ( weRecentCount >= WE_RECENT_WORK_MAX )
            break;
        weRecentIds[weRecentCount] = line;
        weRecentCount++;
    }
}

bool WE_RecentDisconnects_WorkContains( const String &in steamid )
{
    for ( int i = 0; i < weRecentCount; i++ )
    {
        if ( weRecentIds[i] == steamid )
            return true;
    }
    return false;
}

void WE_RecentDisconnects_SortWorkDesc()
{
    for ( int i = 0; i < weRecentCount - 1; i++ )
    {
        for ( int j = 0; j < weRecentCount - 1 - i; j++ )
        {
            if ( weRecentUnix[j] >= weRecentUnix[j + 1] )
                continue;

            String tmpId = weRecentIds[j];
            weRecentIds[j] = weRecentIds[j + 1];
            weRecentIds[j + 1] = tmpId;

            uint tmpUnix = weRecentUnix[j];
            weRecentUnix[j] = weRecentUnix[j + 1];
            weRecentUnix[j + 1] = tmpUnix;
        }
    }
}

bool WE_RecentDisconnects_AddBufferContains( const String &in steamid )
{
    for ( int a = 0; a < weRecentAddCount; a++ )
    {
        if ( weRecentAddIds[a] == steamid )
            return true;
    }
    return false;
}

// Lock, reload, upsert weRecentAddIds[0..weRecentAddCount), sort, cap, write.
// If stampedNow, add-buffer ids use WE_UnixSeconds() (caller just wrote leave stamps).
bool WE_RecentDisconnects_MergeAddBuffer( bool stampedNow )
{
    if ( weRecentAddCount <= 0 )
        return false;
    if ( !WE_TryLock( WE_RECENT_DISCONNECTS_LOCK ) )
        return false;

    String data;
    WE_LoadFile( WE_RECENT_DISCONNECTS_PATH, data );
    WE_RecentDisconnects_ParseIntoWork( data );

    for ( int i = 0; i < weRecentAddCount; i++ )
    {
        String steamid = weRecentAddIds[i];
        if ( steamid.len() == 0 )
            continue;
        if ( WE_RecentDisconnects_WorkContains( steamid ) )
            continue;
        if ( weRecentCount >= WE_RECENT_WORK_MAX )
            break;
        weRecentIds[weRecentCount] = steamid;
        weRecentCount++;
    }

    uint nowSec = stampedNow ? WE_UnixSeconds() : 0;
    for ( int i = 0; i < weRecentCount; i++ )
    {
        if ( stampedNow && WE_RecentDisconnects_AddBufferContains( weRecentIds[i] ) )
            weRecentUnix[i] = nowSec;
        else
            weRecentUnix[i] = WE_UserLeaveUnix( weRecentIds[i] );
    }

    WE_RecentDisconnects_SortWorkDesc();

    int keep = weRecentCount;
    if ( keep > WE_MAX_RECENT_DISCONNECTS )
        keep = WE_MAX_RECENT_DISCONNECTS;

    String content = "";
    for ( int i = 0; i < keep; i++ )
    {
        if ( weRecentIds[i].len() == 0 )
            continue;
        content += weRecentIds[i] + "\n";
    }
    WE_WriteFile( WE_RECENT_DISCONNECTS_PATH, content );
    WE_Unlock( WE_RECENT_DISCONNECTS_LOCK );
    return true;
}

bool WE_RecentDisconnects_MergeOne( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return false;
    weRecentAddCount = 1;
    weRecentAddIds[0] = steamid;
    return WE_RecentDisconnects_MergeAddBuffer( true );
}

void WE_UserTouchDisconnected( Client @client )
{
    if ( @client == null )
        return;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return;

    WE_UserStampDisconnected( client );
    WE_RecentDisconnects_MergeOne( steamid );
}

bool WE_RecentDisconnects_IsKnown( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return false;
    if ( WE_UserExists( steamid ) )
        return true;

    String data;
    if ( !WE_LoadFile( WE_RECENT_DISCONNECTS_PATH, data ) )
        return false;

    WE_RecentDisconnects_ParseIntoWork( data );
    return WE_RecentDisconnects_WorkContains( steamid );
}

bool WE_RecentDisconnects_NameMatchesData( const String &in data, const String &in query )
{
    String name = WE_KvGet( data, "name" );
    if ( name.len() == 0 )
        return false;
    return WE_ContainsIgnoreCase( WE_StripColors( name ), query );
}

bool WE_RecentDisconnects_NameEqualsData( const String &in data, const String &in query )
{
    String name = WE_KvGet( data, "name" );
    if ( name.len() == 0 )
        return false;
    return WE_EqualsIgnoreCase( WE_StripColors( name ), query );
}

bool WE_RecentDisconnects_NameMatches( const String &in steamid, const String &in query )
{
    String data;
    if ( !WE_UserLoad( steamid, data ) )
        return false;
    return WE_RecentDisconnects_NameMatchesData( data, query );
}

bool WE_RecentDisconnects_NameEquals( const String &in steamid, const String &in query )
{
    String data;
    if ( !WE_UserLoad( steamid, data ) )
        return false;
    return WE_RecentDisconnects_NameEqualsData( data, query );
}

bool WE_RecentDisconnects_SteamMatches( const String &in steamid, const String &in query )
{
    if ( steamid.len() == 0 || query.len() == 0 )
        return false;
    return WE_ContainsIgnoreCase( steamid, query );
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

bool WE_ClientIsOnlineBySteamId( const String &in steamid )
{
    return @WE_FindClientBySteamId( steamid ) != null;
}

// Listed recents: newest first, skip empty / currently online, cap at WE_MAX_RECENT_DISCONNECTS.
int WE_RecentDisconnects_LoadListed()
{
    String data;
    if ( !WE_LoadFile( WE_RECENT_DISCONNECTS_PATH, data ) || data.len() == 0 )
    {
        WE_RecentDisconnects_ClearWork();
        return 0;
    }

    WE_RecentDisconnects_ParseIntoWork( data );
    for ( int i = 0; i < weRecentCount; i++ )
        weRecentUnix[i] = WE_UserLeaveUnix( weRecentIds[i] );
    WE_RecentDisconnects_SortWorkDesc();

    int write = 0;
    for ( int i = 0; i < weRecentCount; i++ )
    {
        String steamid = weRecentIds[i];
        if ( steamid.len() == 0 )
            continue;
        if ( WE_ClientIsOnlineBySteamId( steamid ) )
            continue;
        if ( write >= WE_MAX_RECENT_DISCONNECTS )
            break;
        if ( write != i )
        {
            weRecentIds[write] = steamid;
            weRecentUnix[write] = weRecentUnix[i];
        }
        write++;
    }
    weRecentCount = write;
    return weRecentCount;
}

void WE_RecentDisconnects_PrintLineFromData( Client @to, const String &in steamid, const String &in data )
{
    if ( @to == null || steamid.len() == 0 )
        return;

    String name = WE_KvGet( data, "name" );
    if ( name.len() == 0 )
        name = "(unknown)";
    String when = WE_UserLeaveHumanFromData( data );
    if ( when.len() == 0 )
        when = "?";

    WE_Print( to, name + " [" + steamid + "] " + when + "\n" );
}

void WE_RecentDisconnects_PrintLine( Client @to, const String &in steamid )
{
    String data;
    WE_UserLoad( steamid, data );
    WE_RecentDisconnects_PrintLineFromData( to, steamid, data );
}

String WE_RecentDisconnects_FindBy( const String &in query, bool byName )
{
    if ( query.len() == 0 )
        return "";

    WE_RecentDisconnects_LoadListed();

    int matchCount = 0;
    int exactCount = 0;
    String found = "";
    String exact = "";

    for ( int i = 0; i < weRecentCount; i++ )
    {
        String steamid = weRecentIds[i];
        bool matches = false;
        bool isExact = false;

        if ( byName )
        {
            String data;
            WE_UserLoad( steamid, data );
            matches = WE_RecentDisconnects_NameMatchesData( data, query );
            if ( !matches )
                continue;
            isExact = WE_RecentDisconnects_NameEqualsData( data, query );
        }
        else
        {
            matches = WE_RecentDisconnects_SteamMatches( steamid, query );
            if ( !matches )
                continue;
            isExact = WE_EqualsIgnoreCase( steamid, query );
        }

        matchCount++;
        found = steamid;
        if ( isExact )
        {
            exactCount++;
            exact = steamid;
        }
    }

    int kind = WE_UniqueMatchKind( matchCount, exactCount );
    if ( kind == WE_MATCH_UNIQUE )
        return found;
    if ( kind == WE_MATCH_EXACT )
        return exact;
    return "";
}

String WE_RecentDisconnects_FindName( const String &in query )
{
    return WE_RecentDisconnects_FindBy( query, true );
}

String WE_RecentDisconnects_FindSteam( const String &in query )
{
    return WE_RecentDisconnects_FindBy( query, false );
}

bool WE_RecentDisconnects_QueryAmbiguousBy( const String &in query, bool byName )
{
    if ( query.len() == 0 )
        return false;

    WE_RecentDisconnects_LoadListed();

    int matchCount = 0;
    int exactCount = 0;
    for ( int i = 0; i < weRecentCount; i++ )
    {
        String steamid = weRecentIds[i];
        bool matches = false;
        bool isExact = false;

        if ( byName )
        {
            String data;
            WE_UserLoad( steamid, data );
            matches = WE_RecentDisconnects_NameMatchesData( data, query );
            if ( !matches )
                continue;
            isExact = WE_RecentDisconnects_NameEqualsData( data, query );
        }
        else
        {
            matches = WE_RecentDisconnects_SteamMatches( steamid, query );
            if ( !matches )
                continue;
            isExact = WE_EqualsIgnoreCase( steamid, query );
        }

        matchCount++;
        if ( isExact )
            exactCount++;
    }
    return WE_UniqueMatchKind( matchCount, exactCount ) == WE_MATCH_AMBIGUOUS;
}

void WE_RecentDisconnects_PrintMatchesBy( Client @to, const String &in query, bool byName )
{
    if ( @to == null )
        return;

    WE_RecentDisconnects_LoadListed();
    for ( int i = 0; i < weRecentCount; i++ )
    {
        String steamid = weRecentIds[i];
        String data;
        WE_UserLoad( steamid, data );

        bool matches = byName
            ? WE_RecentDisconnects_NameMatchesData( data, query )
            : WE_RecentDisconnects_SteamMatches( steamid, query );
        if ( !matches )
            continue;
        WE_RecentDisconnects_PrintLineFromData( to, steamid, data );
    }
}

void WE_RecentDisconnects_Print( Client @client )
{
    if ( @client == null )
        return;

    WE_Print( client, WE_MSG_RECENT_DISCONNECTS_HEADER );

    if ( WE_RecentDisconnects_LoadListed() <= 0 )
    {
        WE_Print( client, WE_MSG_RECENT_DISCONNECTS_NONE );
        return;
    }

    for ( int i = 0; i < weRecentCount; i++ )
        WE_RecentDisconnects_PrintLine( client, weRecentIds[i] );
}

void WE_RecentDisconnects_MergeConnected()
{
    weRecentAddCount = 0;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @client = @G_GetClient( i );
        if ( @client == null )
            continue;
        String steamid = WE_SteamId( client );
        if ( steamid.len() == 0 )
            continue;
        if ( weRecentAddCount >= WE_RECENT_WORK_MAX )
            break;
        weRecentAddIds[weRecentAddCount] = steamid;
        weRecentAddCount++;
    }
    if ( weRecentAddCount > 0 )
        WE_RecentDisconnects_MergeAddBuffer( false );
}

void WE_Users_OnShutdown()
{
    weRecentAddCount = 0;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @client = @G_GetClient( i );
        if ( @client == null )
            continue;
        String steamid = WE_SteamId( client );
        if ( steamid.len() == 0 )
            continue;

        WE_UserStampDisconnected( client );
        if ( weRecentAddCount < WE_RECENT_WORK_MAX )
        {
            weRecentAddIds[weRecentAddCount] = steamid;
            weRecentAddCount++;
        }
    }
    if ( weRecentAddCount > 0 )
        WE_RecentDisconnects_MergeAddBuffer( true );
}

void WE_Users_Init()
{
    if ( !WE_FileExists( WE_RECENT_DISCONNECTS_PATH ) )
        WE_WriteFileLocked( WE_RECENT_DISCONNECTS_PATH, WE_RECENT_DISCONNECTS_LOCK, "" );
    WE_RecentDisconnects_MergeConnected();
}
