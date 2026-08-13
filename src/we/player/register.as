void WE_Users_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( @client == null )
        return;
    if ( score_event == "disconnect" )
    {
        WE_UserTouchDisconnected( client );
        return;
    }
    if ( score_event != "enterGame" && score_event != "userinfochanged" )
        return;
    WE_UserTouchConnected( client );
}

void WE_Users_Register()
{
    WE_Hooks_AddScoreEventAfter( @WE_Users_OnScoreEvent );
    WE_Hooks_AddShutdown( @WE_Users_OnShutdown );
}
