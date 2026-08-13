const int WE_MAX_BANS = 256;
const String WE_BANLIST_PATH = "warfork-extended/banlist.txt";

String[] weBanUnix( WE_MAX_BANS );
String[] weBanSteamId( WE_MAX_BANS );
String[] weBanUsername( WE_MAX_BANS );
String[] weBanClan( WE_MAX_BANS );
String[] weBanByUsername( WE_MAX_BANS );
String[] weBanBySteamId( WE_MAX_BANS );
String[] weBanReason( WE_MAX_BANS );
int weBanCount = 0;

void WE_Ban_Clear()
{
    weBanCount = 0;
    for ( int i = 0; i < WE_MAX_BANS; i++ )
    {
        weBanUnix[i] = "";
        weBanSteamId[i] = "";
        weBanUsername[i] = "";
        weBanClan[i] = "";
        weBanByUsername[i] = "";
        weBanBySteamId[i] = "";
        weBanReason[i] = "";
    }
}

bool WE_Ban_LooksLikeKvGarbage( const String &in line )
{
    for ( uint i = 0; i < line.len(); i++ )
    {
        String ch = line.substr( i, 1 );
        if ( ch == "=" )
            return true;
        if ( ch == "," )
            return false;
    }
    return false;
}

bool WE_Ban_ParseLine( const String &in line )
{
    if ( line.len() == 0 )
        return true;
    if ( WE_Ban_LooksLikeKvGarbage( line ) )
        return false;
    if ( weBanCount >= WE_MAX_BANS )
        return false;

    String f0 = "";
    String f1 = "";
    String f2 = "";
    String f3 = "";
    String f4 = "";
    String f5 = "";
    String f6 = "";
    int field = 0;
    String cur = "";

    for ( uint i = 0; i <= line.len(); i++ )
    {
        String ch = ( i < line.len() ) ? line.substr( i, 1 ) : ",";
        if ( ch != "," && i != line.len() )
        {
            cur += ch;
            continue;
        }

        cur = WE_TrimLeftSpaces( cur );
        if ( field == 0 ) f0 = cur;
        else if ( field == 1 ) f1 = cur;
        else if ( field == 2 ) f2 = cur;
        else if ( field == 3 ) f3 = cur;
        else if ( field == 4 ) f4 = cur;
        else if ( field == 5 ) f5 = cur;
        else if ( field == 6 ) f6 = cur;
        field++;
        cur = "";
    }

    if ( f1.len() == 0 )
        return false;

    weBanUnix[weBanCount] = f0;
    weBanSteamId[weBanCount] = f1;
    weBanUsername[weBanCount] = f2;
    weBanClan[weBanCount] = f3;
    weBanByUsername[weBanCount] = f4;
    weBanBySteamId[weBanCount] = f5;
    weBanReason[weBanCount] = f6;
    weBanCount++;
    return true;
}

void WE_Ban_Reload()
{
    WE_Ban_Clear();
    if ( !WE_FileExists( WE_BANLIST_PATH ) )
        return; // read-only path — file is created on write

    String data;
    if ( !WE_LoadFile( WE_BANLIST_PATH, data ) )
        return;

    String line = "";
    for ( uint i = 0; i <= data.len(); i++ )
    {
        String ch = ( i < data.len() ) ? data.substr( i, 1 ) : "\n";
        if ( ch != "\n" && ch != "\r" && i != data.len() )
        {
            line += ch;
            continue;
        }
        if ( line.len() > 0 )
            WE_Ban_ParseLine( line );
        line = "";
    }
}

void WE_Ban_Write()
{
    String content = "";
    for ( int i = 0; i < weBanCount; i++ )
    {
        if ( weBanSteamId[i].len() == 0 )
            continue;
        content += weBanUnix[i]
                 + ", " + weBanSteamId[i]
                 + ", " + weBanUsername[i]
                 + ", " + weBanClan[i]
                 + ", " + weBanByUsername[i]
                 + ", " + weBanBySteamId[i]
                 + ", " + weBanReason[i]
                 + "\n";
    }
    WE_WriteFileLocked( WE_BANLIST_PATH, "banlist", content );
}

bool WE_Ban_IsSteamBanned( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return false;

    for ( int i = 0; i < weBanCount; i++ )
    {
        if ( weBanSteamId[i] == steamid )
            return true;
    }
    return false;
}

bool WE_Ban_AddSteam( Client @actor, const String &in steamid, const String &in username, const String &in clan, const String &in reason )
{
    if ( steamid.len() == 0 )
        return false;
    if ( WE_Ban_IsSteamBanned( steamid ) )
        return true;
    if ( weBanCount >= WE_MAX_BANS )
        return false;

    String byName = "";
    String bySteam = "";
    if ( @actor != null )
    {
        byName = WE_SanitizeField( actor.name );
        bySteam = WE_SteamId( actor );
    }

    weBanUnix[weBanCount] = WE_UnixTimestamp();
    weBanSteamId[weBanCount] = steamid;
    weBanUsername[weBanCount] = WE_SanitizeField( username );
    weBanClan[weBanCount] = WE_SanitizeField( clan );
    weBanByUsername[weBanCount] = byName;
    weBanBySteamId[weBanCount] = bySteam;
    weBanReason[weBanCount] = WE_SanitizeField( reason );
    weBanCount++;
    WE_Ban_Write();
    return true;
}

bool WE_Ban_Add( Client @actor, Client @target, const String &in reason )
{
    if ( @target == null )
        return false;

    String steamid = WE_SteamId( target );
    if ( steamid.len() == 0 )
        return false;

    return WE_Ban_AddSteam( actor, steamid, target.name, target.clanName, reason );
}

void WE_Ban_RemoveIndex( int index )
{
    if ( index < 0 || index >= weBanCount )
        return;

    for ( int i = index; i < weBanCount - 1; i++ )
    {
        weBanUnix[i] = weBanUnix[i + 1];
        weBanSteamId[i] = weBanSteamId[i + 1];
        weBanUsername[i] = weBanUsername[i + 1];
        weBanClan[i] = weBanClan[i + 1];
        weBanByUsername[i] = weBanByUsername[i + 1];
        weBanBySteamId[i] = weBanBySteamId[i + 1];
        weBanReason[i] = weBanReason[i + 1];
    }
    weBanCount--;
    weBanUnix[weBanCount] = "";
    weBanSteamId[weBanCount] = "";
    weBanUsername[weBanCount] = "";
    weBanClan[weBanCount] = "";
    weBanByUsername[weBanCount] = "";
    weBanBySteamId[weBanCount] = "";
    weBanReason[weBanCount] = "";
    WE_Ban_Write();
}

void WE_Ban_PrintList( Client @client )
{
    int shown = 0;
    for ( int i = 0; i < weBanCount; i++ )
    {
        if ( weBanSteamId[i].len() == 0 )
            continue;
        String entry = i + ": " + weBanSteamId[i] + " " + weBanUsername[i];
        if ( weBanReason[i].len() > 0 )
            entry += " (" + weBanReason[i] + ")";
        client.printMessage( entry + "\n" );
        shown++;
    }
    if ( shown == 0 )
        client.printMessage( WE_MSG_UNBAN_NONE );
}
