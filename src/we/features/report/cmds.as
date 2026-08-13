bool WE_Cmd_Report( Client @client, const String &argsString, int argc )
{
    if ( we_feature_report.integer != 1 )
    {
        WE_Print( client, WE_MSG_REPORT_DISABLED );
        return true;
    }

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_REPORT_USAGE, true );
    if ( @target == null )
        return true;
    if ( !WE_RequireNotSelf( client, target ) )
        return true;

    if ( WE_Report_OnCooldown( client ) )
    {
        WE_Print( client, WE_MSG_REPORT_COOLDOWN );
        return true;
    }

    String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
    if ( reason.len() == 0 )
        reason = WE_MSG_NO_REASON;

    if ( !WE_Report_Add( client, target, reason ) )
    {
        WE_Print( client, WE_MSG_REPORT_FAILED );
        return true;
    }

    WE_Print( client, WE_MSG_REPORT_FILED_PREFIX + target.name + WE_MSG_REPORT_FILED_SUFFIX );
    WE_Print( client, WE_MSG_REPORT_REASON_PREFIX + reason + "\n" );
    WE_Print( client, WE_MSG_REPORT_REVIEW );
    return true;
}

void WE_Report_Register()
{
    WE_Cmds_Add( "we_report", @WE_Cmd_Report );
    WE_Cmds_Add( "report", @WE_Cmd_Report );
}
