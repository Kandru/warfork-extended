bool WE_Cmd_Report( Client @client, const String &argsString, int argc )
{
    if ( we_feature_report.integer != 1 )
    {
        WE_Print( client, WE_MSG_REPORT_DISABLED );
        return true;
    }

    if ( argsString.getToken( 1 ).len() == 0 )
    {
        WE_Print( client, WE_MSG_REPORT_USAGE );
        return true;
    }

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_REPORT_USAGE, true, true );
    if ( @target == null )
        return true;
    if ( !WE_RequireNotSelf( client, target ) )
        return true;

    if ( WE_Report_OnCooldown( client ) )
    {
        WE_Print( client, WE_MSG_REPORT_COOLDOWN );
        return true;
    }

    String reason = WE_Trim( WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) ) );
    if ( reason.len() == 0 )
    {
        WE_Print( client, WE_MSG_REPORT_USAGE );
        return true;
    }
    if ( reason.len() < WE_REPORT_REASON_MIN_LEN )
    {
        WE_Print( client, WE_MSG_REPORT_REASON_SHORT );
        return true;
    }

    if ( !WE_Report_Add( client, target, reason ) )
    {
        WE_Print( client, WE_MSG_REPORT_FAILED );
        return true;
    }

    WE_Reply reply;
    reply.AddLine( WE_MSG_REPORT_FILED_PREFIX + WE_ClientDisplayName( target ) + WE_MSG_REPORT_FILED_SUFFIX );
    reply.AddLine( WE_MSG_REPORT_REASON_PREFIX + reason );
    reply.AddLine( WE_MSG_REPORT_REVIEW );
    reply.Send( client );

    WE_PrintMsg( null,
        WE_MSG_REPORT_CHAT_PREFIX
        + client.name
        + WE_MSG_REPORT_CHAT_REPORTED
        + WE_ClientDisplayName( target )
        + WE_MSG_REPORT_CHAT_FOR
        + reason
        + "\n" );
    return true;
}

void WE_Report_OnKill( Client @attackerClient, const String &args )
{
    if ( @attackerClient == null )
        return;

    int victimEntNum = args.getToken( 0 ).toInt();
    Entity @victimEnt = @G_GetEntity( victimEntNum );
    if ( @victimEnt == null || @victimEnt.client == null )
        return;

    Client @victim = @victimEnt.client;
    if ( attackerClient.playerNum == victim.playerNum )
        return;

    String body = WE_Theme_Color( "body" );
    String accent = WE_Theme_Color( "accent" );
    WE_Print( victim,
        WE_MSG_REPORT_DEATH_HINT_PREFIX
        + accent
        + WE_MSG_REPORT_DEATH_HINT_CMD
        + attackerClient.playerNum
        + WE_MSG_REPORT_DEATH_HINT_REASON
        + body
        + WE_MSG_REPORT_DEATH_HINT_SUFFIX
        + attackerClient.name
        + "\n" );
}

void WE_Report_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( we_feature_report.integer != 1 )
        return;
    if ( score_event != "kill" )
        return;

    WE_Report_OnKill( client, args );
}

void WE_Report_Register()
{
    WE_Hooks_AddScoreEventAfter( @WE_Report_OnScoreEvent );
    WE_Cmds_AddEx( "we_report", "<userid> <reason>", "File a player report", false, @WE_Cmd_Report, "report" );
    WE_Cmds_AddAlias( "report", @WE_Cmd_Report );
}
