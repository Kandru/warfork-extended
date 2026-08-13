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

String WE_UserGet( const String &in steamid, const String &in key )
{
    String path = WE_UserPath( steamid );
    if ( path.len() == 0 )
        return "";

    String data;
    if ( !WE_LoadFile( path, data ) )
        return "";
    return WE_KvGet( data, key );
}

void WE_UserSet( const String &in steamid, const String &in key, const String &in value )
{
    String path = WE_UserPath( steamid );
    if ( path.len() == 0 )
        return;

    String data;
    WE_LoadFile( path, data ); // read unlocked
    data = WE_KvSet( data, key, WE_SanitizeField( value ) );
    WE_WriteFileLocked( path, "user_" + steamid, data );
}

uint WE_UserLeaveUnix( const String &in steamid )
{
    String disc = WE_UserGet( steamid, "last_disconnected_unix" );
    if ( disc.len() > 0 && disc.isNumerical() )
        return uint( disc.toInt() );

    String conn = WE_UserGet( steamid, "last_connected_unix" );
    if ( conn.len() > 0 && conn.isNumerical() )
        return uint( conn.toInt() );
    return 0;
}

String WE_UserLeaveHuman( const String &in steamid )
{
    String disc = WE_UserGet( steamid, "last_disconnected" );
    if ( disc.len() > 0 )
        return disc;
    return WE_UserGet( steamid, "last_connected" );
}

void WE_UserTouchConnected( Client @client )
{
    if ( @client == null )
        return;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return;

    String path = WE_UserPath( steamid );
    String data;
    WE_LoadFile( path, data ); // read unlocked

    String snapshot;
    WE_SnapshotUserInfo( client, snapshot );
    data = WE_KvMergeBlob( data, snapshot );
    data = WE_KvSet( data, "last_connected", WE_HumanTimeNow() );
    data = WE_KvSet( data, "last_connected_unix", WE_UnixTimestamp() );
    WE_WriteFileLocked( path, "user_" + steamid, data );
}

// Stamp user file only (no recency merge).
void WE_UserStampDisconnected( Client @client )
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
    data = WE_KvSet( data, "last_disconnected", WE_HumanTimeNow() );
    data = WE_KvSet( data, "last_disconnected_unix", WE_UnixTimestamp() );
    WE_WriteFileLocked( path, "user_" + steamid, data );
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
    String line = "";
    for ( uint i = 0; i <= data.len(); i++ )
    {
        String ch = ( i < data.len() ) ? data.substr( i, 1 ) : "\n";
        if ( ch != "\n" && ch != "\r" && i != data.len() )
        {
            line += ch;
            continue;
        }
        if ( line.len() > 0 && weRecentCount < WE_RECENT_WORK_MAX )
        {
            weRecentIds[weRecentCount] = line;
            weRecentCount++;
        }
        line = "";
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

// Lock, reload, upsert weRecentAddIds[0..weRecentAddCount), sort, cap, write.
bool WE_RecentDisconnects_MergeAddBuffer()
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

    for ( int i = 0; i < weRecentCount; i++ )
        weRecentUnix[i] = WE_UserLeaveUnix( weRecentIds[i] );

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
    return WE_RecentDisconnects_MergeAddBuffer();
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

bool WE_ClientIsOnlineBySteamId( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return false;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( @other == null )
            continue;
        if ( other.state() < CS_SPAWNED )
            continue;
        if ( WE_SteamId( other ) == steamid )
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
        if ( @other == null )
            continue;
        if ( @other.getEnt() == null )
            continue;
        if ( WE_SteamId( other ) == steamid )
            return other;
    }
    return null;
}

void WE_RecentDisconnects_Print( Client @client )
{
    if ( @client == null )
        return;

    client.printMessage( WE_MSG_RECENT_DISCONNECTS_HEADER );

    String data;
    if ( !WE_LoadFile( WE_RECENT_DISCONNECTS_PATH, data ) || data.len() == 0 )
    {
        client.printMessage( WE_MSG_RECENT_DISCONNECTS_NONE );
        return;
    }

    WE_RecentDisconnects_ParseIntoWork( data );
    for ( int i = 0; i < weRecentCount; i++ )
        weRecentUnix[i] = WE_UserLeaveUnix( weRecentIds[i] );
    WE_RecentDisconnects_SortWorkDesc();

    int shown = 0;
    for ( int i = 0; i < weRecentCount && shown < WE_MAX_RECENT_DISCONNECTS; i++ )
    {
        String steamid = weRecentIds[i];
        if ( steamid.len() == 0 )
            continue;
        if ( WE_ClientIsOnlineBySteamId( steamid ) )
            continue;

        String name = WE_UserGet( steamid, "name" );
        if ( name.len() == 0 )
            name = "(unknown)";
        String when = WE_UserLeaveHuman( steamid );
        if ( when.len() == 0 )
            when = "?";

        client.printMessage( name + " [" + steamid + "] " + when + "\n" );
        shown++;
    }

    if ( shown == 0 )
        client.printMessage( WE_MSG_RECENT_DISCONNECTS_NONE );
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
        WE_RecentDisconnects_MergeAddBuffer();
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
        WE_RecentDisconnects_MergeAddBuffer();
}

void WE_Users_Init()
{
    if ( !WE_FileExists( WE_RECENT_DISCONNECTS_PATH ) )
        WE_WriteFileLocked( WE_RECENT_DISCONNECTS_PATH, WE_RECENT_DISCONNECTS_LOCK, "" );
    WE_RecentDisconnects_MergeConnected();
}
