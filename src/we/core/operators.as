// SteamID operators — always on when we_enabled is 1 (no we_feature_*).

String weOperatorsCache = "";
String weOperatorsNormalized = ",";

void WE_Operators_RefreshCache()
{
    String list = we_operators.string;
    if ( list == weOperatorsCache )
        return;

    weOperatorsCache = list;
    weOperatorsNormalized = ",";

    String token = "";
    uint n = list.len();
    for ( uint i = 0; i <= n; i++ )
    {
        String ch = ( i < n ) ? list.substr( i, 1 ) : ",";
        if ( ch == "," || ch == " " || ch == "\t" || i == n )
        {
            if ( token.len() > 0 )
            {
                weOperatorsNormalized += token + ",";
                token = "";
            }
            continue;
        }
        token += ch;
    }
}

bool WE_IsListedOperator( Client @client )
{
    if ( @client == null )
        return false;

    WE_Operators_RefreshCache();
    // Empty list is "," only.
    if ( weOperatorsNormalized.len() <= 1 )
        return false;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return false;

    String target = "," + steamid + ",";
    uint targetLen = target.len();
    uint hayLen = weOperatorsNormalized.len();
    if ( hayLen < targetLen )
        return false;

    for ( uint i = 0; i + targetLen <= hayLen; i++ )
    {
        if ( weOperatorsNormalized.substr( i, targetLen ) == target )
            return true;
    }
    return false;
}

void WE_Operators_Apply( Client @client )
{
    if ( @client == null )
        return;
    if ( client.isOperator )
        return;
    if ( !WE_IsListedOperator( client ) )
        return;
    client.isOperator = true;
}

void WE_Operators_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( @client == null )
        return;
    if ( score_event != "enterGame" && score_event != "userinfochanged" )
        return;
    WE_Operators_Apply( client );
}

void WE_Operators_Register()
{
    WE_Hooks_AddScoreEventAfter( @WE_Operators_OnScoreEvent );
}
