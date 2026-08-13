String WE_UserPath( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return "";
    return WE_ROOT + "users/" + steamid + ".txt";
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

void WE_UserTouchConnected( Client @client )
{
    if ( we_feature_users.integer != 1 )
        return;
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
