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

String WE_TrimLeftSpaces( const String &in text )
{
    String cur = text;
    while ( cur.len() > 0 && cur.substr( 0, 1 ) == " " )
        cur = cur.substr( 1, cur.len() - 1 );
    return cur;
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
