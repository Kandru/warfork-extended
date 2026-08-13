const int WE_MATCH_NONE = 0;
const int WE_MATCH_UNIQUE = 1;
const int WE_MATCH_EXACT = 2;
const int WE_MATCH_AMBIGUOUS = 3;

// printMessage / G_PrintMsg truncate around MAX_STRING_CHARS (1024).
const uint WE_PRINT_MAX = 1000;

uint WE_Print_Take( const String &in msg, uint pos, uint room )
{
    if ( room < 1 )
        room = 1;
    if ( pos >= msg.len() )
        return 0;
    uint left = msg.len() - pos;
    if ( left <= room )
        return left;
    uint split = 0;
    for ( uint i = 0; i < room; i++ )
    {
        if ( msg.substr( pos + i, 1 ) == "\n" )
            split = i + 1;
    }
    if ( split > 0 )
        return split;
    return room;
}

void WE_Print( Client @client, const String &in msg )
{
    if ( @client == null )
        return;
    if ( msg.len() == 0 )
        return;

    String prefix = WE_Theme_Prefix();
    uint prefixLen = prefix.len();
    uint pos = 0;
    bool first = true;
    while ( pos < msg.len() )
    {
        uint room = WE_PRINT_MAX;
        if ( first && room > prefixLen )
            room -= prefixLen;
        uint take = WE_Print_Take( msg, pos, room );
        if ( take == 0 )
            break;
        String chunk = msg.substr( pos, take );
        if ( first )
            client.printMessage( prefix + chunk );
        else
            client.printMessage( chunk );
        first = false;
        pos += take;
    }
}

void WE_PrintMsg( Entity @ent, const String &in msg )
{
    if ( msg.len() == 0 )
        return;
    uint pos = 0;
    while ( pos < msg.len() )
    {
        uint take = WE_Print_Take( msg, pos, WE_PRINT_MAX );
        if ( take == 0 )
            break;
        G_PrintMsg( ent, msg.substr( pos, take ) );
        pos += take;
    }
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
