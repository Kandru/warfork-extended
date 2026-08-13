void WE_Init()
{
    if ( !WE_FileExists( WE_ROOT + "users/.keep.txt" ) )
        WE_WriteFile( WE_ROOT + "users/.keep.txt", "" );
    if ( !WE_FileExists( WE_LOCKS + ".keep.txt" ) )
        WE_WriteFile( WE_LOCKS + ".keep.txt", "" );
    if ( !WE_FileExists( WE_BANLIST_PATH ) )
        WE_WriteFile( WE_BANLIST_PATH, "" );

    // Features attach via funcdef registries (no hard-coded calls in dispatch).
    WE_CoreCmds_Register();
    WE_Users_Register();
    WE_Ban_Register();
}

void WE_Init_After()
{
    WE_Cmds_RegisterEngine();
    WE_Ban_Init();
    G_Print( WE_MSG_INIT_PREFIX + WE_VERSION + WE_MSG_INIT_SUFFIX );
}
