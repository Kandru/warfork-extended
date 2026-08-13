void WE_Welcome_OnEnterGame( Client @client )
{
    if ( we_feature_welcome.integer != 1 )
        return;
    if ( @client == null )
        return;
    if ( WE_SteamId( client ).len() == 0 )
        return;

    Entity @ent = @client.getEnt();
    if ( @ent == null )
        return;

    String body = WE_Theme_Color( "body" );
    String accent = WE_Theme_Color( "accent" );
    G_PrintMsg( ent,
        WE_Theme_Prefix()
        + WE_MSG_WELCOME_HEY
        + client.name
        + body
        + WE_MSG_WELCOME_TYPE
        + accent
        + WE_MSG_WELCOME_CMD
        + body
        + WE_MSG_WELCOME_SUFFIX );
}

void WE_Welcome_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( score_event != "enterGame" )
        return;
    WE_Welcome_OnEnterGame( client );
}

void WE_Welcome_Register()
{
    WE_Hooks_AddScoreEventAfter( @WE_Welcome_OnScoreEvent );
}
