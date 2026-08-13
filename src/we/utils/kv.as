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
