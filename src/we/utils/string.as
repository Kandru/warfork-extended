const int WE_MATCH_NONE = 0;
const int WE_MATCH_UNIQUE = 1;
const int WE_MATCH_EXACT = 2;
const int WE_MATCH_AMBIGUOUS = 3;

void WE_Print( Client @client, const String &in msg )
{
    if ( @client == null )
        return;
    client.printMessage( WE_MSG_PREFIX + msg );
}

String WE_StripColors( const String &in text )
{
    return text.removeColorTokens();
}

String WE_SanitizeField( const String &in text )
{
    String result = "";
    for ( uint i = 0; i < text.len(); i++ )
    {
        String ch = text.substr( i, 1 );
        if ( ch == "," || ch == "\n" || ch == "\r" || ch == "\t" )
            result += " ";
        else
            result += ch;
    }
    return result;
}

String WE_JoinArgs( const String &in argsString, int startToken, int argc )
{
    String message;
    for ( int i = startToken; i <= argc; i++ )
    {
        String token = argsString.getToken( i );
        if ( token.len() == 0 )
            break;
        if ( message.len() > 0 )
            message += " ";
        message += token;
    }
    return message;
}

bool WE_IsAlnumOrSpace( const String &in ch )
{
    if ( ch.len() != 1 )
        return false;

    const String allowed = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ";
    for ( uint i = 0; i < allowed.len(); i++ )
    {
        if ( allowed.substr( i, 1 ) == ch )
            return true;
    }
    return false;
}

String WE_SanitizeReason( const String &in text )
{
    String result = "";
    for ( uint i = 0; i < text.len(); i++ )
    {
        String ch = text.substr( i, 1 );
        if ( WE_IsAlnumOrSpace( ch ) )
            result += ch;
    }
    return result;
}

String WE_Trim( const String &in text )
{
    String v = text;
    while ( v.len() > 0 && v.substr( 0, 1 ) == " " )
        v = v.substr( 1, v.len() - 1 );
    while ( v.len() > 0 )
    {
        String last = v.substr( v.len() - 1, 1 );
        if ( last != "\n" && last != "\r" && last != " " )
            break;
        v = v.substr( 0, v.len() - 1 );
    }
    return v;
}

bool WE_EqualsIgnoreCase( const String &in a, const String &in b )
{
    return a.tolower() == b.tolower();
}

bool WE_ContainsIgnoreCase( const String &in haystack, const String &in needle )
{
    String h = haystack.tolower();
    String n = needle.tolower();
    if ( n.len() == 0 )
        return false;
    if ( n.len() > h.len() )
        return false;

    uint maxStart = h.len() - n.len();
    for ( uint i = 0; i <= maxStart; i++ )
    {
        if ( h.substr( i, n.len() ) == n )
            return true;
    }
    return false;
}

// Advance pos through data; write next line (without newline). True until past EOF.
bool WE_NextLine( const String &in data, uint pos, String &out line, uint &out nextPos )
{
    line = "";
    nextPos = pos;
    if ( pos > data.len() )
        return false;

    while ( pos < data.len() )
    {
        String ch = data.substr( pos, 1 );
        pos++;
        if ( ch == "\n" || ch == "\r" )
        {
            nextPos = pos;
            return true;
        }
        line += ch;
    }

    nextPos = data.len() + 1;
    return true;
}

bool WE_SplitKeyValue( const String &in line, String &out key, String &out value )
{
    key = "";
    value = "";
    for ( uint j = 0; j < line.len(); j++ )
    {
        if ( line.substr( j, 1 ) != "=" )
            continue;
        if ( j == 0 )
            return false;
        key = line.substr( 0, j );
        value = line.substr( j + 1, line.len() - ( j + 1 ) );
        return true;
    }
    return false;
}

int WE_UniqueMatchKind( int matchCount, int exactCount )
{
    if ( matchCount == 1 )
        return WE_MATCH_UNIQUE;
    if ( exactCount == 1 )
        return WE_MATCH_EXACT;
    if ( matchCount > 1 )
        return WE_MATCH_AMBIGUOUS;
    return WE_MATCH_NONE;
}
