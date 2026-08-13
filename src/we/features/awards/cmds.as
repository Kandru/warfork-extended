bool WE_Cmd_Awards( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        client.printMessage( WE_MSG_AWARDS_DISABLED );
        return true;
    }

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
    {
        client.printMessage( WE_MSG_AWARDS_NO_STEAM );
        return true;
    }

    String data;
    if ( !WE_UserLoad( steamid, data ) )
    {
        client.printMessage( WE_MSG_AWARDS_NONE );
        return true;
    }

    const uint prefixLen = WE_AWARD_KEY_PREFIX.len();
    bool any = false;
    String line;
    uint pos = 0;
    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;
        String key;
        String value;
        if ( !WE_SplitKeyValue( line, key, value ) )
            continue;
        if ( key.len() < prefixLen || key.substr( 0, prefixLen ) != WE_AWARD_KEY_PREFIX )
            continue;
        if ( value.len() == 0 || !value.isNumerical() || value.toInt() <= 0 )
            continue;

        String id = key.substr( prefixLen, key.len() - prefixLen );
        String title = WE_Awards_TitleForId( id );
        if ( !any )
        {
            client.printMessage( WE_MSG_AWARDS_HEADER );
            any = true;
        }
        client.printMessage( "  " + title + ": " + value + "\n" );
    }

    if ( !any )
        client.printMessage( WE_MSG_AWARDS_NONE );
    return true;
}

bool WE_Cmd_AwardGive( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        client.printMessage( WE_MSG_AWARDS_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_AWARD_GIVE_USAGE, true );
    if ( @target == null )
        return true;

    String id = argsString.getToken( 1 );
    if ( id.len() == 0 )
    {
        client.printMessage( WE_MSG_AWARD_GIVE_USAGE );
        return true;
    }

    int index = WE_Awards_FindIndex( id );
    if ( index < 0 )
    {
        client.printMessage( WE_MSG_AWARD_UNKNOWN );
        return true;
    }

    if ( WE_SteamId( target ).len() == 0 )
    {
        client.printMessage( WE_MSG_AWARDS_NO_STEAM );
        return true;
    }

    WE_Awards_GrantIndex( target, index );
    client.printMessage( WE_MSG_AWARD_GIVE_DONE );
    return true;
}

bool WE_Cmd_AwardRemove( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        client.printMessage( WE_MSG_AWARDS_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_AWARD_REMOVE_USAGE, true );
    if ( @target == null )
        return true;

    String id = argsString.getToken( 1 );
    if ( id.len() == 0 )
    {
        client.printMessage( WE_MSG_AWARD_REMOVE_USAGE );
        return true;
    }

    int index = WE_Awards_FindIndex( id );
    if ( index < 0 )
    {
        client.printMessage( WE_MSG_AWARD_UNKNOWN );
        return true;
    }

    if ( WE_SteamId( target ).len() == 0 )
    {
        client.printMessage( WE_MSG_AWARDS_NO_STEAM );
        return true;
    }

    if ( !WE_Awards_RemoveIndex( target, index ) )
    {
        client.printMessage( WE_MSG_AWARD_REMOVE_NONE );
        return true;
    }

    client.printMessage( WE_MSG_AWARD_REMOVE_DONE );
    return true;
}

void WE_Awards_RegisterCmds()
{
    WE_Cmds_Add( "we_awards", @WE_Cmd_Awards );
    WE_Cmds_Add( "we_awardGive", @WE_Cmd_AwardGive );
    WE_Cmds_Add( "we_awardRemove", @WE_Cmd_AwardRemove );
}
