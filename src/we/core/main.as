void WE_Init()
{
    if ( !WE_FileExists( WE_BANLIST_PATH ) )
        WE_WriteFileLocked( WE_BANLIST_PATH, "banlist", "" );

    WE_Locks_Register();
    WE_CoreCmds_Register();
    WE_Users_Register();
    WE_Ban_Register();
    WE_Weapon_Register();
}

void WE_Init_After()
{
    WE_Cmds_RegisterEngine();
    WE_Ban_Init();
    G_Print( WE_MSG_INIT_PREFIX + WE_VERSION + WE_MSG_INIT_SUFFIX );
}
