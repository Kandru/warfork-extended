// Custom gamemode player data — keys always stored as cust_*

const String WE_PLAYER_DATA_PREFIX = "cust_";

String WE_PlayerDataKey( const String &in key )
{
    if ( key.len() == 0 )
        return "";

    String k = WE_SanitizeField( key );
    if ( k.len() == 0 )
        return "";

    if ( k.len() >= WE_PLAYER_DATA_PREFIX.len()
         && k.substr( 0, WE_PLAYER_DATA_PREFIX.len() ) == WE_PLAYER_DATA_PREFIX )
        return k;
    return WE_PLAYER_DATA_PREFIX + k;
}

bool WE_PlayerDataEnabled()
{
    return ( we_enabled.integer == 1 );
}

String WE_GetPlayerDataBySteamId( const String &in steamid, const String &in key )
{
    if ( !WE_PlayerDataEnabled() )
        return "";
    if ( steamid.len() == 0 )
        return "";

    String k = WE_PlayerDataKey( key );
    if ( k.len() == 0 )
        return "";
    return WE_UserGet( steamid, k );
}

void WE_SetPlayerDataBySteamId( const String &in steamid, const String &in key, const String &in value )
{
    if ( !WE_PlayerDataEnabled() )
        return;
    if ( steamid.len() == 0 )
        return;

    String k = WE_PlayerDataKey( key );
    if ( k.len() == 0 )
        return;
    WE_UserSet( steamid, k, value );
}

String WE_GetPlayerData( Client @client, const String &in key )
{
    return WE_GetPlayerDataBySteamId( WE_SteamId( client ), key );
}

void WE_SetPlayerData( Client @client, const String &in key, const String &in value )
{
    WE_SetPlayerDataBySteamId( WE_SteamId( client ), key, value );
}
