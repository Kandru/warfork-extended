bool WE_ChangeTeam_IsJoinable( int teamId )
{
    if ( teamId == TEAM_SPECTATOR )
        return true;
    if ( gametype.isTeamBased )
        return teamId == TEAM_ALPHA || teamId == TEAM_BETA;
    return teamId == TEAM_PLAYERS;
}

void WE_ChangeTeam_PrintTeamLine( Client @to, int teamId, Team @team )
{
    if ( @to == null || @team == null )
        return;
    String line = teamId + ": ";
    if ( team.name.len() > 0 )
        line += team.name;
    else
        line += "?";
    if ( team.defaultName.len() > 0 )
        line += " (" + team.defaultName + ")";
    WE_Print( to, line + "\n" );
}

void WE_ChangeTeam_PrintTeams( Client @client )
{
    WE_Print( client, WE_MSG_TEAMS_HEADER );
    for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
    {
        if ( !WE_ChangeTeam_IsJoinable( t ) )
            continue;
        Team @team = @G_GetTeam( t );
        if ( @team == null )
            continue;
        WE_ChangeTeam_PrintTeamLine( client, t, team );
    }
}

void WE_ChangeTeam_PrintUsage( Client @client )
{
    WE_Print( client, WE_MSG_CHANGETEAM_USAGE );
    WE_PrintPlayers( client, true );
    WE_ChangeTeam_PrintTeams( client );
}

bool WE_ChangeTeam_TextMatches( Team @team, const String &in query )
{
    if ( @team == null )
        return false;
    if ( WE_ContainsIgnoreCase( WE_StripColors( team.name ), query ) )
        return true;
    if ( WE_ContainsIgnoreCase( team.defaultName, query ) )
        return true;
    return false;
}

bool WE_ChangeTeam_TextEquals( Team @team, const String &in query )
{
    if ( @team == null )
        return false;
    if ( WE_EqualsIgnoreCase( WE_StripColors( team.name ), query ) )
        return true;
    if ( WE_EqualsIgnoreCase( team.defaultName, query ) )
        return true;
    return false;
}

// Resolve team by id or unique name / defaultName fragment (e.g. "spec").
// Returns -1 on failure (messages already printed).
int WE_ChangeTeam_TeamFromQuery( Client @client, const String &in query )
{
    if ( query.len() == 0 )
        return -1;

    if ( query.isNumerical() )
    {
        int id = query.toInt();
        if ( WE_ChangeTeam_IsJoinable( id ) && @G_GetTeam( id ) != null )
            return id;
        WE_Print( client, WE_MSG_CHANGETEAM_INVALID );
        WE_ChangeTeam_PrintTeams( client );
        return -1;
    }

    int matchCount = 0;
    int exactCount = 0;
    int foundId = -1;
    int exactId = -1;

    for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
    {
        if ( !WE_ChangeTeam_IsJoinable( t ) )
            continue;
        Team @team = @G_GetTeam( t );
        if ( @team == null )
            continue;
        if ( !WE_ChangeTeam_TextMatches( team, query ) )
            continue;

        matchCount++;
        foundId = t;
        if ( WE_ChangeTeam_TextEquals( team, query ) )
        {
            exactCount++;
            exactId = t;
        }
    }

    int kind = WE_UniqueMatchKind( matchCount, exactCount );
    if ( kind == WE_MATCH_UNIQUE )
        return foundId;
    if ( kind == WE_MATCH_EXACT )
        return exactId;

    if ( kind == WE_MATCH_AMBIGUOUS )
    {
        WE_Print( client, WE_MSG_TEAM_AMBIGUOUS );
        for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
        {
            if ( !WE_ChangeTeam_IsJoinable( t ) )
                continue;
            Team @team = @G_GetTeam( t );
            if ( @team == null )
                continue;
            if ( !WE_ChangeTeam_TextMatches( team, query ) )
                continue;
            WE_ChangeTeam_PrintTeamLine( client, t, team );
        }
        return -1;
    }

    WE_Print( client, WE_MSG_TEAM_NOT_FOUND );
    WE_ChangeTeam_PrintTeams( client );
    return -1;
}

bool WE_Cmd_ChangeTeam( Client @client, const String &argsString, int argc )
{
    if ( we_feature_changeteam.integer != 1 )
    {
        WE_Print( client, WE_MSG_CHANGETEAM_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    String userTok = argsString.getToken( 0 );
    String teamTok = argsString.getToken( 1 );
    if ( userTok.len() == 0 || teamTok.len() == 0 )
    {
        WE_ChangeTeam_PrintUsage( client );
        return true;
    }

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_CHANGETEAM_USAGE, true );
    if ( @target == null )
    {
        WE_ChangeTeam_PrintTeams( client );
        return true;
    }
    if ( !WE_ClientListed( target, true ) )
    {
        WE_ChangeTeam_PrintUsage( client );
        return true;
    }

    int teamId = WE_ChangeTeam_TeamFromQuery( client, teamTok );
    if ( teamId < 0 )
        return true;

    Entity @ent = @target.getEnt();
    if ( @ent == null )
        return true;

    if ( target.team == teamId && ent.team == teamId )
    {
        WE_Print( client, WE_MSG_CHANGETEAM_SAME );
        return true;
    }

    // Client.team is a raw field write; G_Teams_SetTeam ghosts then queues spawn.
    target.team = teamId;
    target.respawn( true );
    @ent = @target.getEnt();
    if ( @ent != null )
        ent.spawnqueueAdd();

    WE_Print( target, WE_MSG_CHANGETEAM_NOTIFY );
    WE_Print( client, WE_MSG_CHANGETEAM_DONE );
    return true;
}

void WE_ChangeTeam_Register()
{
    WE_Cmds_Add( "we_changeteam", @WE_Cmd_ChangeTeam );
}
