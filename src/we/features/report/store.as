const String WE_REPORT_PATH = "warfork-extended/report.txt";
const uint WE_REPORT_COOLDOWN_SEC = 60;
const uint WE_REPORT_REASON_MIN_LEN = 3;
const int WE_MAX_REPORT_COOLDOWNS = 64;

String[] weReportCdKey( WE_MAX_REPORT_COOLDOWNS );
uint[] weReportCdUntil( WE_MAX_REPORT_COOLDOWNS );
int weReportCdCount = 0;

String WE_Report_CooldownKey( Client @client )
{
    if ( @client == null )
        return "";

    String steamid = WE_SteamId( client );
    if ( steamid.len() > 0 )
        return steamid;
    return "slot:" + client.playerNum;
}

bool WE_Report_OnCooldown( Client @client )
{
    String key = WE_Report_CooldownKey( client );
    if ( key.len() == 0 )
        return false;

    uint now = WE_UnixSeconds();
    for ( int i = 0; i < weReportCdCount; i++ )
    {
        if ( weReportCdKey[i] != key )
            continue;
        return weReportCdUntil[i] > now;
    }
    return false;
}

void WE_Report_MarkCooldown( Client @client )
{
    String key = WE_Report_CooldownKey( client );
    if ( key.len() == 0 )
        return;

    uint until = WE_UnixSeconds() + WE_REPORT_COOLDOWN_SEC;
    for ( int i = 0; i < weReportCdCount; i++ )
    {
        if ( weReportCdKey[i] != key )
            continue;
        weReportCdUntil[i] = until;
        return;
    }

    if ( weReportCdCount >= WE_MAX_REPORT_COOLDOWNS )
    {
        // Drop oldest slot when full.
        for ( int i = 1; i < weReportCdCount; i++ )
        {
            weReportCdKey[i - 1] = weReportCdKey[i];
            weReportCdUntil[i - 1] = weReportCdUntil[i];
        }
        weReportCdCount--;
    }

    weReportCdKey[weReportCdCount] = key;
    weReportCdUntil[weReportCdCount] = until;
    weReportCdCount++;
}

String WE_Report_StatInt( int value )
{
    return "" + value;
}

bool WE_Report_Add( Client @actor, Client @target, const String &in reason )
{
    if ( @actor == null || @target == null )
        return false;

    int score = target.stats.score;
    int frags = target.stats.frags;
    int deaths = target.stats.deaths;
    int suicides = target.stats.suicides;

    String line = WE_UnixTimestamp()
        + ", " + WE_SteamId( actor )
        + ", " + WE_SanitizeField( WE_StripColors( actor.name ) )
        + ", " + WE_SanitizeField( actor.clanName )
        + ", " + WE_SteamId( target )
        + ", " + WE_SanitizeField( WE_StripColors( target.name ) )
        + ", " + WE_SanitizeField( target.clanName )
        + ", " + WE_Report_StatInt( score )
        + ", " + WE_Report_StatInt( frags )
        + ", " + WE_Report_StatInt( deaths )
        + ", " + WE_Report_StatInt( suicides )
        + ", " + reason
        + "\n";

    if ( !WE_AppendFileLocked( WE_REPORT_PATH, "report", line ) )
        return false;

    WE_Report_MarkCooldown( actor );
    return true;
}
