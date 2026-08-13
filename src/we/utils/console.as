// Console reply builder — one WE_Print per command; themed lists/tables.

const int WE_REPLY_MAX_COLS = 8;
const int WE_REPLY_MAX_ROWS = 96;
const int WE_REPLY_MAX_CELLS = 768; // 8 * 96
const int WE_ITEM_TAG_MAX = 64;

String[] weReplyCells( WE_REPLY_MAX_CELLS );
int weReplyTableCols = 0;
int weReplyTableRows = 0;
bool weReplyTableOpen = false;

class WE_Reply
{
    String text;

    WE_Reply()
    {
        this.text = "";
    }

    void Clear()
    {
        this.text = "";
        weReplyTableCols = 0;
        weReplyTableRows = 0;
        weReplyTableOpen = false;
    }

    void AddLine( const String &in line )
    {
        this.FlushTable();
        this.text += line;
        if ( line.len() == 0 || line.substr( line.len() - 1, 1 ) != "\n" )
            this.text += "\n";
    }

    void AddItem( const String &in line )
    {
        this.FlushTable();
        this.text += WE_Theme_Color( "marker" ) + "- " + WE_Theme_Color( "body" ) + line;
        if ( line.len() == 0 || line.substr( line.len() - 1, 1 ) != "\n" )
            this.text += "\n";
    }

    void TableBegin( int cols )
    {
        this.FlushTable();
        if ( cols < 1 )
            cols = 1;
        if ( cols > WE_REPLY_MAX_COLS )
            cols = WE_REPLY_MAX_COLS;
        weReplyTableCols = cols;
        weReplyTableRows = 0;
        weReplyTableOpen = true;
        for ( int i = 0; i < WE_REPLY_MAX_CELLS; i++ )
            weReplyCells[i] = "";
    }

    void TableAddRow()
    {
        if ( !weReplyTableOpen )
            return;
        if ( weReplyTableRows >= WE_REPLY_MAX_ROWS )
            return;
        weReplyTableRows++;
    }

    void TableSet( int col, const String &in value )
    {
        if ( !weReplyTableOpen )
            return;
        if ( weReplyTableRows <= 0 )
            return;
        if ( col < 0 || col >= weReplyTableCols )
            return;
        int idx = ( weReplyTableRows - 1 ) * weReplyTableCols + col;
        if ( idx < 0 || idx >= WE_REPLY_MAX_CELLS )
            return;
        weReplyCells[idx] = value;
    }

    void TableHeader2( const String &in a, const String &in b )
    {
        this.TableBegin( 2 );
        this.TableAddRow();
        this.TableSet( 0, a );
        this.TableSet( 1, b );
    }

    void TableHeader3( const String &in a, const String &in b, const String &in c )
    {
        this.TableBegin( 3 );
        this.TableAddRow();
        this.TableSet( 0, a );
        this.TableSet( 1, b );
        this.TableSet( 2, c );
    }

    void TableHeader6( const String &in a, const String &in b, const String &in c,
        const String &in d, const String &in e, const String &in f )
    {
        this.TableBegin( 6 );
        this.TableAddRow();
        this.TableSet( 0, a );
        this.TableSet( 1, b );
        this.TableSet( 2, c );
        this.TableSet( 3, d );
        this.TableSet( 4, e );
        this.TableSet( 5, f );
    }

    void TableHeader7( const String &in a, const String &in b, const String &in c,
        const String &in d, const String &in e, const String &in f, const String &in g )
    {
        this.TableBegin( 7 );
        this.TableAddRow();
        this.TableSet( 0, a );
        this.TableSet( 1, b );
        this.TableSet( 2, c );
        this.TableSet( 3, d );
        this.TableSet( 4, e );
        this.TableSet( 5, f );
        this.TableSet( 6, g );
    }

    void FlushTable()
    {
        if ( !weReplyTableOpen )
            return;
        weReplyTableOpen = false;
        if ( weReplyTableRows <= 0 || weReplyTableCols <= 0 )
            return;

        int[] widths( WE_REPLY_MAX_COLS );
        for ( int c = 0; c < weReplyTableCols; c++ )
            widths[c] = 0;

        for ( int r = 0; r < weReplyTableRows; r++ )
        {
            for ( int c = 0; c < weReplyTableCols; c++ )
            {
                int idx = r * weReplyTableCols + c;
                uint vis = WE_StripColors( weReplyCells[idx] ).len();
                if ( int( vis ) > widths[c] )
                    widths[c] = int( vis );
            }
        }

        String sep = WE_Theme_Color( "sep" );
        String header = WE_Theme_Color( "header" );
        String body = WE_Theme_Color( "body" );
        String marker = WE_Theme_Color( "marker" );

        for ( int r = 0; r < weReplyTableRows; r++ )
        {
            bool isHeader = ( r == 0 );
            // Match visible width of data-row "- " so columns line up.
            if ( isHeader )
                this.text += "  " + header;
            else
                this.text += marker + "- " + body;

            for ( int c = 0; c < weReplyTableCols; c++ )
            {
                if ( c > 0 )
                {
                    this.text += sep + " | ";
                    if ( isHeader )
                        this.text += header;
                    else
                        this.text += body;
                }

                int idx = r * weReplyTableCols + c;
                String cell = weReplyCells[idx];
                this.text += cell;

                uint vis = WE_StripColors( cell ).len();
                int pad = widths[c] - int( vis );
                for ( int p = 0; p < pad; p++ )
                    this.text += " ";
            }
            this.text += "\n";
        }

        // Blank line before the next section / table.
        this.text += "\n";

        weReplyTableCols = 0;
        weReplyTableRows = 0;
    }

    void Send( Client @client )
    {
        this.FlushTable();
        if ( @client == null )
            return;
        if ( this.text.len() == 0 )
            return;

        // Drop trailing blank lines from the post-table spacer.
        while ( this.text.len() >= 2
            && this.text.substr( this.text.len() - 2, 2 ) == "\n\n" )
        {
            this.text = this.text.substr( 0, this.text.len() - 1 );
        }

        WE_Print( client, this.text );
    }
}

String WE_Console_TeamName( Client @client )
{
    if ( @client == null )
        return "-";
    Entity @ent = @client.getEnt();
    if ( @ent == null )
        return "-";
    Team @team = @G_GetTeam( ent.team );
    if ( @team == null )
        return "-";
    if ( team.name.len() > 0 )
        return team.name;
    if ( team.defaultName.len() > 0 )
        return team.defaultName;
    return "" + ent.team;
}

String WE_Console_SteamLabel( Client @client )
{
    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return "[no steam_id]";
    return steamid;
}

String WE_Console_SteamLabelFromId( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return "[no steam_id]";
    return steamid;
}

bool WE_Console_TeamIsJoinable( int teamId )
{
    if ( teamId == TEAM_SPECTATOR )
        return true;
    if ( gametype.isTeamBased )
        return teamId == TEAM_ALPHA || teamId == TEAM_BETA;
    return teamId == TEAM_PLAYERS;
}

void WE_Reply_AddPlayerRow( WE_Reply @reply, Client @other, bool withTeam )
{
    if ( @reply == null || @other == null )
        return;

    reply.TableAddRow();
    int col = 0;
    reply.TableSet( col++, "" + other.playerNum );
    reply.TableSet( col++, other.name );
    reply.TableSet( col++, other.clanName );
    if ( withTeam )
        reply.TableSet( col++, WE_Console_TeamName( other ) );
    reply.TableSet( col++, "" + other.stats.score );
    reply.TableSet( col++, "" + other.stats.frags );
    reply.TableSet( col++, WE_Console_SteamLabel( other ) );
}

void WE_Reply_BeginPlayersTable( WE_Reply @reply, bool withTeam )
{
    if ( @reply == null )
        return;
    if ( withTeam )
    {
        reply.TableHeader7( "#ID", "Name", "Clan", "Team", "Score", "Frags", "SteamID" );
    }
    else
    {
        reply.TableHeader6( "#ID", "Name", "Clan", "Score", "Frags", "SteamID" );
    }
}

void WE_Reply_AddPlayers( WE_Reply @reply, bool includeSpectators, bool withTeam )
{
    if ( @reply == null )
        return;

    WE_Reply_BeginPlayersTable( reply, withTeam );
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        WE_Reply_AddPlayerRow( reply, other, withTeam );
    }
}

void WE_Reply_AddPlayerMatches( WE_Reply @reply, const String &in query, bool includeSpectators, bool withTeam )
{
    if ( @reply == null )
        return;

    bool started = false;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientNameMatches( other, query ) )
            continue;
        if ( !started )
        {
            WE_Reply_BeginPlayersTable( reply, withTeam );
            started = true;
        }
        WE_Reply_AddPlayerRow( reply, other, withTeam );
    }
}

void WE_Reply_AddPlayerSteamMatches( WE_Reply @reply, const String &in query, bool includeSpectators, bool withTeam )
{
    if ( @reply == null )
        return;

    bool started = false;
    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientSteamMatches( other, query ) )
            continue;
        if ( !started )
        {
            WE_Reply_BeginPlayersTable( reply, withTeam );
            started = true;
        }
        WE_Reply_AddPlayerRow( reply, other, withTeam );
    }
}

void WE_Reply_AddOfflineRow( WE_Reply @reply, int id, const String &in name, const String &in clan,
    const String &in steamid, bool withTeam )
{
    if ( @reply == null )
        return;

    String displayName = name;
    if ( displayName.len() == 0 )
        displayName = "(unknown)";

    reply.TableAddRow();
    int col = 0;
    reply.TableSet( col++, "" + id );
    reply.TableSet( col++, displayName );
    reply.TableSet( col++, clan );
    if ( withTeam )
        reply.TableSet( col++, "-" );
    reply.TableSet( col++, "-" );
    reply.TableSet( col++, "-" );
    reply.TableSet( col++, WE_Console_SteamLabelFromId( steamid ) );
}

void WE_Reply_AddRecentDisconnects( WE_Reply @reply )
{
    if ( @reply == null )
        return;

    if ( WE_RecentDisconnects_LoadListed() <= 0 )
        return;

    WE_Reply_BeginPlayersTable( reply, false );
    for ( int i = 0; i < weRecentCount; i++ )
    {
        String steamid = weRecentIds[i];
        String data;
        WE_UserLoad( steamid, data );
        String name = WE_KvGet( data, "name" );
        String clan = WE_KvGet( data, "clan" );
        WE_Reply_AddOfflineRow( reply, WE_RECENT_ID_BASE + i, name, clan, steamid, false );
    }
}

void WE_Reply_AddRecentMatches( WE_Reply @reply, const String &in query, bool byName )
{
    if ( @reply == null )
        return;

    WE_RecentDisconnects_LoadListed();
    bool started = false;
    for ( int i = 0; i < weRecentCount; i++ )
    {
        String steamid = weRecentIds[i];
        String data;
        WE_UserLoad( steamid, data );

        bool matches = byName
            ? WE_RecentDisconnects_NameMatchesData( data, query )
            : WE_RecentDisconnects_SteamMatches( steamid, query );
        if ( !matches )
            continue;
        if ( !started )
        {
            WE_Reply_BeginPlayersTable( reply, false );
            started = true;
        }
        String name = WE_KvGet( data, "name" );
        String clan = WE_KvGet( data, "clan" );
        WE_Reply_AddOfflineRow( reply, WE_RECENT_ID_BASE + i, name, clan, steamid, false );
    }
}

void WE_Reply_AddItems( WE_Reply @reply )
{
    if ( @reply == null )
        return;

    reply.TableHeader3( "#ID", "Name", "Slug" );
    for ( int i = 1; i < WE_ITEM_TAG_MAX; i++ )
    {
        Item @item = @G_GetItem( i );
        if ( @item == null )
            continue;
        if ( item.name.len() == 0 )
            continue;
        reply.TableAddRow();
        reply.TableSet( 0, "" + item.tag );
        reply.TableSet( 1, item.name );
        reply.TableSet( 2, item.shortName );
    }
}

void WE_Reply_AddTeams( WE_Reply @reply )
{
    if ( @reply == null )
        return;

    reply.TableHeader3( "#ID", "Name", "Slug" );
    for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
    {
        if ( !WE_Console_TeamIsJoinable( t ) )
            continue;
        Team @team = @G_GetTeam( t );
        if ( @team == null )
            continue;
        reply.TableAddRow();
        reply.TableSet( 0, "" + t );
        String teamName = team.name;
        if ( teamName.len() == 0 )
            teamName = "?";
        reply.TableSet( 1, teamName );
        reply.TableSet( 2, team.defaultName );
    }
}

void WE_Reply_AddAwardsTable( WE_Reply @reply )
{
    if ( @reply == null )
        return;
    reply.TableHeader2( "#Count", "Award" );
}

void WE_Reply_AddUsagePlayers( WE_Reply @reply, const String &in usage, bool includeSpectators, bool withTeam )
{
    if ( @reply == null )
        return;
    reply.AddLine( usage );
    WE_Reply_AddPlayers( reply, includeSpectators, withTeam );
}

// Resolve query; print usage + player table, or the ambiguous matches.
Client @WE_ClientFromQuery( Client @actor, const String &in query, const String &in usage,
    bool includeSpectators, bool withTeam )
{
    if ( query.len() == 0 )
    {
        WE_Reply reply;
        WE_Reply_AddUsagePlayers( reply, usage, includeSpectators, withTeam );
        reply.Send( actor );
        return null;
    }

    if ( query.isNumerical() )
    {
        int num = query.toInt();
        if ( num >= 0 && num < WE_RECENT_ID_BASE )
        {
            Client @byNum = @G_GetClient( num );
            if ( WE_ClientListed( byNum, includeSpectators ) )
                return byNum;
        }
    }

    int matchCount = 0;
    int exactCount = 0;
    Client @found = null;
    Client @exact = null;

    for ( int i = 0; i < maxClients; i++ )
    {
        Client @other = @G_GetClient( i );
        if ( !WE_ClientListed( other, includeSpectators ) )
            continue;
        if ( !WE_ClientNameMatches( other, query ) )
            continue;

        matchCount++;
        @found = @other;
        if ( WE_ClientNameEquals( other, query ) )
        {
            exactCount++;
            @exact = @other;
        }
    }

    int kind = WE_UniqueMatchKind( matchCount, exactCount );
    if ( kind == WE_MATCH_UNIQUE )
        return found;
    if ( kind == WE_MATCH_EXACT )
        return exact;

    if ( kind == WE_MATCH_AMBIGUOUS )
    {
        WE_Reply reply;
        reply.AddLine( WE_MSG_PLAYER_AMBIGUOUS );
        WE_Reply_AddPlayerMatches( reply, query, includeSpectators, withTeam );
        reply.Send( actor );
        return null;
    }

    WE_Reply reply;
    WE_Reply_AddUsagePlayers( reply, usage, includeSpectators, withTeam );
    reply.Send( actor );
    return null;
}

// First args token as userid. withTeam=true for most cmds; false for kick/ban.
Client @WE_ClientFromArg( Client @actor, const String &in argsString, const String &in usage,
    bool includeSpectators, bool withTeam )
{
    return WE_ClientFromQuery( actor, argsString.getToken( 0 ), usage, includeSpectators, withTeam );
}
