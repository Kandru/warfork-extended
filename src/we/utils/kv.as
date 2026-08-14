// key=value line helpers

bool WE_KvHasKey( const String &in data, const String &in key )
{
    String line;
    uint pos = 0;
    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;
        String k;
        String v;
        if ( !WE_SplitKeyValue( line, k, v ) )
            continue;
        if ( k == key )
            return true;
    }
    return false;
}

String WE_KvGet( const String &in data, const String &in key )
{
    String line;
    uint pos = 0;
    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;
        String k;
        String v;
        if ( !WE_SplitKeyValue( line, k, v ) )
            continue;
        if ( k == key )
            return v;
    }
    return "";
}

String WE_KvSet( const String &in data, const String &in key, const String &in value )
{
    String result = "";
    bool replaced = false;
    String line;
    uint pos = 0;

    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;

        String k;
        String v;
        if ( WE_SplitKeyValue( line, k, v ) && k == key )
        {
            result += key + "=" + value + "\n";
            replaced = true;
        }
        else
        {
            result += line + "\n";
        }
    }

    if ( !replaced )
        result += key + "=" + value + "\n";
    return result;
}

String WE_KvDelete( const String &in data, const String &in key )
{
    String result = "";
    String line;
    uint pos = 0;

    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;

        String k;
        String v;
        if ( WE_SplitKeyValue( line, k, v ) && k == key )
            continue;
        result += line + "\n";
    }
    return result;
}

// Keep data lines whose keys are not in blob; append all blob pairs.
String WE_KvMergeBlob( const String &in data, const String &in blob )
{
    String result = "";
    String line;
    uint pos = 0;

    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;

        String k;
        String v;
        if ( WE_SplitKeyValue( line, k, v ) && WE_KvHasKey( blob, k ) )
            continue;
        result += line + "\n";
    }

    pos = 0;
    while ( WE_NextLine( blob, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;

        String k;
        String v;
        if ( !WE_SplitKeyValue( line, k, v ) )
            continue;
        result += k + "=" + v + "\n";
    }
    return result;
}

// Named key=value files under warfork-extended/kv/ (features + custom GTs)

String WE_KvFileName( const String &in name )
{
    if ( name.len() == 0 )
        return "";

    String n = name;
    if ( n.len() >= 4 && n.substr( n.len() - 4, 4 ).tolower() == ".txt" )
        n = n.substr( 0, n.len() - 4 );
    if ( n.len() == 0 )
        return "";

    const String allowed = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-";
    for ( uint i = 0; i < n.len(); i++ )
    {
        String ch = n.substr( i, 1 );
        bool ok = false;
        for ( uint j = 0; j < allowed.len(); j++ )
        {
            if ( allowed.substr( j, 1 ) == ch )
            {
                ok = true;
                break;
            }
        }
        if ( !ok )
            return "";
    }
    return n;
}

String WE_KvFilePath( const String &in name )
{
    String n = WE_KvFileName( name );
    if ( n.len() == 0 )
        return "";
    return WE_ROOT + "kv/" + n + ".txt";
}

String WE_KvFileGet( const String &in name, const String &in key )
{
    if ( we_enabled.integer != 1 )
        return "";

    String path = WE_KvFilePath( name );
    if ( path.len() == 0 )
        return "";

    String k = WE_SanitizeField( key );
    if ( k.len() == 0 )
        return "";

    String data;
    if ( !WE_LoadFile( path, data ) )
        return "";
    return WE_KvGet( data, k );
}

void WE_KvFileSet( const String &in name, const String &in key, const String &in value )
{
    if ( we_enabled.integer != 1 )
        return;

    String n = WE_KvFileName( name );
    if ( n.len() == 0 )
        return;

    String k = WE_SanitizeField( key );
    if ( k.len() == 0 )
        return;

    String path = WE_ROOT + "kv/" + n + ".txt";
    String data;
    WE_LoadFile( path, data );
    data = WE_KvSet( data, k, WE_SanitizeField( value ) );
    WE_WriteFileLocked( path, "kv_" + n, data );
}
