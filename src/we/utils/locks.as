// Soft locks — one file, 1s TTL, owner = ip:port.
// Line: name=unix_sec@ip:port
// Timed-out locks may be taken by any server (old line replaced).

const String WE_LOCKS_PATH = "warfork-extended/locks.txt";
const uint WE_LOCK_TTL_SEC = 1;

Cvar we_net_ip( "net_ip", "", 0 );
Cvar we_net_port( "net_port", "44400", 0 );

String WE_Locks_OwnerId()
{
    String ip = we_net_ip.string;
    if ( ip.len() == 0 )
        ip = "0.0.0.0";
    return ip + ":" + we_net_port.string;
}

// Parse "unix@owner" → unix out via return, owner via &out.
uint WE_Locks_ParseValue( const String &in value, String &out owner )
{
    owner = "";
    String v = WE_Trim( value );
    int at = -1;
    for ( uint i = 0; i < v.len(); i++ )
    {
        if ( v.substr( i, 1 ) != "@" )
            continue;
        at = int( i );
        break;
    }
    if ( at <= 0 )
        return 0;

    String sec = v.substr( 0, at );
    owner = v.substr( at + 1, v.len() - ( at + 1 ) );
    if ( sec.len() == 0 || !sec.isNumerical() )
        return 0;
    return uint( sec.toInt() );
}

bool WE_Locks_IsActive( uint lockedAt, uint nowSec )
{
    if ( lockedAt == 0 )
        return false;
    if ( nowSec < lockedAt )
        return true;
    return ( nowSec - lockedAt ) < WE_LOCK_TTL_SEC;
}

// Rebuild file: drop timed-out lines; optionally drop one name; optionally force-drop our owner lines.
String WE_Locks_Rebuild( const String &in data, const String &in dropName, bool dropOurOwned, uint nowSec )
{
    String us = WE_Locks_OwnerId();
    String result = "";
    String line;
    uint pos = 0;

    while ( WE_NextLine( data, pos, line ) )
    {
        if ( line.len() == 0 )
            continue;

        String key;
        String val;
        if ( !WE_SplitKeyValue( line, key, val ) )
            continue;

        if ( dropName.len() > 0 && key == dropName )
            continue;

        String owner;
        uint lockedAt = WE_Locks_ParseValue( val, owner );
        if ( !WE_Locks_IsActive( lockedAt, nowSec ) )
            continue;
        if ( dropOurOwned && owner == us )
            continue;

        result += key + "=" + lockedAt + "@" + owner + "\n";
    }
    return result;
}

bool WE_Locks_Find( const String &in data, const String &in name, uint &out lockedAt, String &out owner )
{
    lockedAt = 0;
    owner = "";
    String line;
    uint pos = 0;

    while ( WE_NextLine( data, pos, line ) )
    {
        if ( line.len() == 0 )
            continue;

        String key;
        String val;
        if ( !WE_SplitKeyValue( line, key, val ) )
            continue;
        if ( key != name )
            continue;

        lockedAt = WE_Locks_ParseValue( val, owner );
        return lockedAt > 0;
    }
    return false;
}

bool WE_TryLock( const String &in name )
{
    if ( name.len() == 0 )
        return false;

    uint nowSec = WE_UnixSeconds();
    String us = WE_Locks_OwnerId();
    String data;
    WE_LoadFile( WE_LOCKS_PATH, data );

    uint lockedAt = 0;
    String owner;
    if ( WE_Locks_Find( data, name, lockedAt, owner ) && WE_Locks_IsActive( lockedAt, nowSec ) )
    {
        if ( owner != us )
            return false;
    }

    data = WE_Locks_Rebuild( data, name, false, nowSec );
    data += name + "=" + nowSec + "@" + us + "\n";
    WE_WriteFile( WE_LOCKS_PATH, data );
    return true;
}

void WE_Unlock( const String &in name )
{
    if ( name.len() == 0 )
        return;

    uint nowSec = WE_UnixSeconds();
    String data;
    WE_LoadFile( WE_LOCKS_PATH, data );
    data = WE_Locks_Rebuild( data, name, false, nowSec );
    WE_WriteFile( WE_LOCKS_PATH, data );
}

// Reads (WE_LoadFile) never lock. Use this for all shared data writes.
bool WE_WriteFileLocked( const String &in path, const String &in lockName, const String &in content )
{
    if ( lockName.len() == 0 )
        return false;
    if ( !WE_TryLock( lockName ) )
        return false;
    WE_WriteFile( path, content );
    WE_Unlock( lockName );
    return true;
}

void WE_Locks_ReleaseAll()
{
    uint nowSec = WE_UnixSeconds();
    String data;
    if ( !WE_LoadFile( WE_LOCKS_PATH, data ) )
        return;
    data = WE_Locks_Rebuild( data, "", true, nowSec );
    WE_WriteFile( WE_LOCKS_PATH, data );
}

void WE_Locks_Register()
{
    WE_Hooks_AddShutdown( @WE_Locks_ReleaseAll );
}
