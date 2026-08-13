// key=value line helpers

String WE_KvGet( const String &in data, const String &in key )
{
    String line = "";
    for ( uint i = 0; i <= data.len(); i++ )
    {
        String ch = ( i < data.len() ) ? data.substr( i, 1 ) : "\n";
        if ( ch != "\n" && ch != "\r" && i != data.len() )
        {
            line += ch;
            continue;
        }
        if ( line.len() == 0 )
            continue;

        int eq = -1;
        for ( uint j = 0; j < line.len(); j++ )
        {
            if ( line.substr( j, 1 ) != "=" )
                continue;
            eq = int( j );
            break;
        }
        if ( eq > 0 && line.substr( 0, eq ) == key )
            return line.substr( eq + 1, line.len() - ( eq + 1 ) );
        line = "";
    }
    return "";
}

String WE_KvSet( const String &in data, const String &in key, const String &in value )
{
    String result = "";
    bool replaced = false;
    String line = "";

    for ( uint i = 0; i <= data.len(); i++ )
    {
        String ch = ( i < data.len() ) ? data.substr( i, 1 ) : "\n";
        if ( ch != "\n" && ch != "\r" && i != data.len() )
        {
            line += ch;
            continue;
        }
        if ( line.len() == 0 )
            continue;

        int eq = -1;
        for ( uint j = 0; j < line.len(); j++ )
        {
            if ( line.substr( j, 1 ) != "=" )
                continue;
            eq = int( j );
            break;
        }

        if ( eq > 0 && line.substr( 0, eq ) == key )
        {
            result += key + "=" + value + "\n";
            replaced = true;
        }
        else
        {
            result += line + "\n";
        }
        line = "";
    }

    if ( !replaced )
        result += key + "=" + value + "\n";
    return result;
}

String WE_KvMergeBlob( const String &in data, const String &in blob )
{
    String result = data;
    String line = "";
    for ( uint i = 0; i <= blob.len(); i++ )
    {
        String ch = ( i < blob.len() ) ? blob.substr( i, 1 ) : "\n";
        if ( ch != "\n" && ch != "\r" && i != blob.len() )
        {
            line += ch;
            continue;
        }
        if ( line.len() == 0 )
            continue;

        int eq = -1;
        for ( uint j = 0; j < line.len(); j++ )
        {
            if ( line.substr( j, 1 ) != "=" )
                continue;
            eq = int( j );
            break;
        }
        if ( eq > 0 )
        {
            String k = line.substr( 0, eq );
            String v = line.substr( eq + 1, line.len() - ( eq + 1 ) );
            result = WE_KvSet( result, k, v );
        }
        line = "";
    }
    return result;
}
