const int WE_USERINFO_KEY_COUNT = 12;

String WE_SteamId( Client @client )
{
    if ( @client == null )
        return "";

    String steamid = client.getUserInfoKey( "steam_id" );
    if ( steamid.len() == 0 )
        steamid = client.getUserInfoKey( "steamid" );
    return steamid;
}

String WE_UserInfoKeyName( int index )
{
    switch ( index )
    {
    case 0: return "cg_movementStyle";
    case 1: return "cg_noAutohop";
    case 2: return "cl_mm_session";
    case 3: return "clan";
    case 4: return "color";
    case 5: return "hand";
    case 6: return "handicap";
    case 7: return "model";
    case 8: return "name";
    case 9: return "password";
    case 10: return "skin";
    case 11: return "steam_id";
    }
    return "";
}

String WE_GetUserInfoKey( Client @client, const String &in key )
{
    if ( @client == null )
        return "";
    if ( key == "clan" )
        return client.clanName;
    if ( key == "name" )
        return client.name;
    if ( key == "steam_id" )
        return WE_SteamId( client );
    return client.getUserInfoKey( key );
}

void WE_SnapshotUserInfo( Client @client, String &out blob )
{
    blob = "";
    if ( @client == null )
        return;

    for ( int i = 0; i < WE_USERINFO_KEY_COUNT; i++ )
    {
        String key = WE_UserInfoKeyName( i );
        String value = WE_SanitizeField( WE_GetUserInfoKey( client, key ) );
        blob += key + "=" + value + "\n";
    }
}
