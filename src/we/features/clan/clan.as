// Cached clan display / reserved match (refreshed when cvars change).
String weClanCvarKey = "";
String weClanOpDisplay = ""; // color + tag; empty = no op override
String weClanReservedLower = "";

void WE_Clan_RefreshCache()
{
    String key = we_clan_tag.string + "\n" + we_clan_color.string + "\n" + we_clan_reserved.string;
    if ( key == weClanCvarKey )
        return;
    weClanCvarKey = key;

    weClanOpDisplay = "";
    String tag = WE_Trim( we_clan_tag.string );
    if ( tag.len() > 0 )
    {
        String clean = "";
        for ( uint i = 0; i < tag.len(); i++ )
        {
            String ch = tag.substr( i, 1 );
            if ( ch != " " && ch != "\t" )
                clean += ch;
        }
        if ( clean.len() > 0 )
            weClanOpDisplay = WE_Theme_NameToColor( WE_Trim( we_clan_color.string ) ) + clean;
    }

    weClanReservedLower = WE_Trim( we_clan_reserved.string ).tolower();
}

// Assumes WE_Clan_RefreshCache() already ran this frame/message.
String WE_ScoreboardClan_Cached( Client @client )
{
    if ( @client == null )
        return "-";

    if ( weClanOpDisplay.len() > 0 && WE_IsOperator( client ) )
        return weClanOpDisplay;

    String clan = client.clanName;
    if ( weClanReservedLower.len() > 0
        && clan.removeColorTokens().tolower() == weClanReservedLower )
        return "-";
    return clan.len() > 0 ? clan : "-";
}

String WE_ScoreboardClan( Client @client )
{
    WE_Clan_RefreshCache();
    return WE_ScoreboardClan_Cached( client );
}

String @WE_Clan_OnScoreboardMessage( String @msg, uint maxlen )
{
    if ( we_feature_clan.integer != 1 || @msg == null )
        return msg;

    String src = msg;
    uint len = src.len();
    if ( len < 4 || maxlen < 1 )
        return msg;

    WE_Clan_RefreshCache();

    String result = "";
    uint pos = 0;
    bool wrote = false;

    while ( pos < len )
    {
        // Find next "&p " by scanning for '&' only.
        uint found = len;
        for ( uint i = pos; i + 3 <= len; i++ )
        {
            if ( src.substr( i, 1 ) != "&" )
                continue;
            if ( src.substr( i, 3 ) == "&p " )
            {
                found = i;
                break;
            }
        }
        if ( found >= len )
        {
            if ( !wrote )
                return msg;
            result += src.substr( pos, len - pos );
            break;
        }

        if ( found > pos )
            result += src.substr( pos, found - pos );
        wrote = true;

        uint i = found + 3;

        // id1
        uint a = i;
        while ( a < len && src.substr( a, 1 ) != " " )
            a++;
        if ( a == i || a >= len )
        {
            result += src.substr( found, len - found );
            break;
        }
        String id1 = src.substr( i, a - i );
        i = a + 1;

        // id2
        uint b = i;
        while ( b < len && src.substr( b, 1 ) != " " )
            b++;
        if ( b == i || b >= len )
        {
            result += src.substr( found, len - found );
            break;
        }
        String id2 = src.substr( i, b - i );
        i = b + 1;

        // Skip old clan (may be empty).
        while ( i < len && src.substr( i, 1 ) != " " )
            i++;
        if ( i < len )
            i++;

        int playerId = id1.toInt();
        int playerNum = ( playerId < 0 ) ? ( -( playerId ) - 1 ) : playerId;
        String newClan = "-";
        if ( playerNum >= 0 && playerNum < maxClients )
        {
            Client @client = @G_GetClient( playerNum );
            if ( @client != null )
                newClan = WE_ScoreboardClan_Cached( client );
        }

        result += "&p " + id1 + " " + id2 + " " + newClan + " ";
        pos = i;
    }

    return result;
}

void WE_Clan_Register()
{
    WE_Hooks_AddScoreboardMessageAfter( @WE_Clan_OnScoreboardMessage );
}
