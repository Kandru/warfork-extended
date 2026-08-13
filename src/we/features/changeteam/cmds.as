void WE_ChangeTeam_PrintTeams( Client @client )
{
    client.printMessage( WE_MSG_TEAMS_HEADER );
    for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
    {
        Team @team = @G_GetTeam( t );
        if ( @team == null )
            continue;

        String line = t + ": ";
        if ( @team.name != null && team.name.len() > 0 )
            line += team.name;
        else
            line += "?";
        if ( @team.defaultName != null && team.defaultName.len() > 0 )
            line += " (" + team.defaultName + ")";
        client.printMessage( line + "\n" );
    }
}

void WE_ChangeTeam_PrintUsage( Client @client )
{
    client.printMessage( WE_MSG_CHANGETEAM_USAGE );
    WE_PrintPlayers( client, true );
    WE_ChangeTeam_PrintTeams( client );
}

bool WE_ChangeTeam_TextMatches( Team @team, const String &in query )
{
    if ( @team == null )
        return false;
    if ( @team.name != null && WE_ContainsIgnoreCase( WE_StripColors( team.name ), query ) )
        return true;
    if ( @team.defaultName != null && WE_ContainsIgnoreCase( team.defaultName, query ) )
        return true;
    return false;
}

bool WE_ChangeTeam_TextEquals( Team @team, const String &in query )
{
    if ( @team == null )
        return false;
    if ( @team.name != null && WE_EqualsIgnoreCase( WE_StripColors( team.name ), query ) )
        return true;
    if ( @team.defaultName != null && WE_EqualsIgnoreCase( team.defaultName, query ) )
        return true;
    return false;
}

void WE_ChangeTeam_PrintTeamLine( Client @to, int teamId, Team @team )
{
    if ( @to == null || @team == null )
        return;
    String line = teamId + ": ";
    if ( @team.name != null && team.name.len() > 0 )
        line += team.name;
    else
        line += "?";
    if ( @team.defaultName != null && team.defaultName.len() > 0 )
        line += " (" + team.defaultName + ")";
    to.printMessage( line + "\n" );
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
        if ( id >= TEAM_SPECTATOR && id < GS_MAX_TEAMS && @G_GetTeam( id ) != null )
            return id;
    }

    int matchCount = 0;
    int exactCount = 0;
    int foundId = -1;
    int exactId = -1;

    for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
    {
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

    if ( matchCount == 1 )
        return foundId;
    if ( exactCount == 1 )
        return exactId;

    if ( matchCount > 1 )
    {
        client.printMessage( WE_MSG_TEAM_AMBIGUOUS );
        for ( int t = TEAM_SPECTATOR; t < GS_MAX_TEAMS; t++ )
        {
            Team @team = @G_GetTeam( t );
            if ( @team == null )
                continue;
            if ( !WE_ChangeTeam_TextMatches( team, query ) )
                continue;
            WE_ChangeTeam_PrintTeamLine( client, t, team );
        }
        return -1;
    }

    client.printMessage( WE_MSG_TEAM_NOT_FOUND );
    WE_ChangeTeam_PrintTeams( client );
    return -1;
}

bool WE_Cmd_ChangeTeam( Client @client, const String &argsString, int argc )
{
    if ( we_feature_changeteam.integer != 1 )
    {
        client.printMessage( WE_MSG_CHANGETEAM_DISABLED );
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

    int teamId = WE_ChangeTeam_TeamFromQuery( client, teamTok );
    if ( teamId < 0 )
        return true;

    if ( target.team == teamId )
    {
        client.printMessage( WE_MSG_CHANGETEAM_SAME );
        return true;
    }

    target.team = teamId;
    target.printMessage( WE_MSG_CHANGETEAM_NOTIFY );
    client.printMessage( WE_MSG_CHANGETEAM_DONE );
    return true;
}

void WE_ChangeTeam_Register()
{
    WE_Cmds_Add( "we_changeteam", @WE_Cmd_ChangeTeam );
}
