void WE_Startmap_Think()
{
    if ( we_startmap_done.integer != 0 )
        return;
    we_startmap_done.set( 1 );
    if ( we_feature_startmap.integer != 1 )
        return;

    String list = we_startmap_list.string;
    if ( list.getToken( 0 ).len() == 0 )
    {
        Cvar g_maplist( "g_maplist", "", 0 );
        list = g_maplist.string;
    }

    String[] pool;
    int i = 0;
    while ( true )
    {
        String name = list.getToken( i );
        if ( name.len() == 0 )
            break;
        i++;
        if ( !WE_IsIdentName( name ) || !ML_FilenameExists( name ) )
            continue;
        bool seen = false;
        for ( uint j = 0; j < pool.length(); j++ )
        {
            if ( WE_EqualsIgnoreCase( pool[j], name ) )
            {
                seen = true;
                break;
            }
        }
        if ( !seen )
            pool.insertLast( name );
    }

    if ( pool.length() == 0 )
    {
        G_Print( WE_MSG_STARTMAP_NONE );
        return;
    }

    String pick = pool[rand() % pool.length()];
    Cvar mapname( "mapname", "", 0 );
    bool same = WE_EqualsIgnoreCase( pick, mapname.string );
    G_Print( WE_MSG_STARTMAP_PREFIX + pick + ( same ? " (already loaded)\n" : "\n" ) );
    if ( !same )
        G_CmdExecute( "map " + pick );
}

void WE_Startmap_Register()
{
    WE_Hooks_AddThinkAfter( @WE_Startmap_Think );
}
