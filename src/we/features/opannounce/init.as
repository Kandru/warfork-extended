void WE_OpAnnounce_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( we_feature_opannounce.integer != 1 )
        return;
    if ( score_event != "enterGame" || @client == null )
        return;
    if ( !WE_IsOperator( client ) )
        return;

    WE_PrintMsg( null,
        WE_Theme_Prefix()
        + client.name
        + WE_Theme_Color( "accent" )
        + WE_MSG_OPANNOUNCE_SUFFIX );
}

void WE_OpAnnounce_Register()
{
    WE_Hooks_AddScoreEventAfter( @WE_OpAnnounce_OnScoreEvent );
}
