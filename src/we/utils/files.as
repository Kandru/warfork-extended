const String WE_ROOT = "warfork-extended/";
const String WE_LOCKS = "warfork-extended/locks/";
const uint WE_LOCK_TTL_SEC = 5;

bool WE_FileExists( const String &in path )
{
    return ( G_FileLength( path ) > -1 );
}

bool WE_LoadFile( const String &in path, String &out data )
{
    data = "";
    if ( !WE_FileExists( path ) )
        return false;
    data = G_LoadFile( path );
    return true;
}

void WE_WriteFile( const String &in path, const String &in content )
{
    G_WriteFile( path, content );
}

void WE_AppendFile( const String &in path, const String &in content )
{
    G_AppendToFile( path, content );
}

bool WE_TryLock( const String &in name )
{
    String path = WE_LOCKS + name + ".txt";
    String data;
    uint nowSec = WE_UnixSeconds();

    if ( WE_LoadFile( path, data ) && data.len() > 0 )
    {
        uint lockedAt = 0;
        for ( uint i = 0; i < data.len(); i++ )
        {
            if ( data.substr( i, 1 ) != "=" )
                continue;

            String v = data.substr( i + 1, data.len() - ( i + 1 ) );
            while ( v.len() > 0 )
            {
                String last = v.substr( v.len() - 1, 1 );
                if ( last != "\n" && last != "\r" )
                    break;
                v = v.substr( 0, v.len() - 1 );
            }
            if ( v.len() > 0 && v.isNumerical() )
                lockedAt = uint( v.toInt() );
            break;
        }

        if ( lockedAt > 0 && nowSec >= lockedAt && ( nowSec - lockedAt ) < WE_LOCK_TTL_SEC )
            return false;
    }

    WE_WriteFile( path, "unix_sec=" + nowSec + "\n" );
    return true;
}

void WE_Unlock( const String &in name )
{
    WE_WriteFile( WE_LOCKS + name + ".txt", "" );
}
