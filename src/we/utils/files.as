const String WE_ROOT = "warfork-extended/";

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
