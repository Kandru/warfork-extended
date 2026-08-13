bool WE_Cmd_Awards( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        WE_Print( client, WE_MSG_AWARDS_DISABLED );
        return true;
    }

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
    {
        WE_Print( client, WE_MSG_AWARDS_NO_STEAM );
        return true;
    }

    String data;
    if ( !WE_UserLoad( steamid, data ) )
    {
        WE_Print( client, WE_MSG_AWARDS_NONE );
        return true;
    }

    const uint prefixLen = WE_AWARD_KEY_PREFIX.len();
    String[] titles( WE_MAX_AWARDS );
    int[] counts( WE_MAX_AWARDS );
    int found = 0;

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
        if ( found >= WE_MAX_AWARDS )
            break;

        String id = key.substr( prefixLen, key.len() - prefixLen );
        titles[found] = WE_Awards_TitleForId( id );
        counts[found] = value.toInt();
        found++;
    }

    if ( found == 0 )
    {
        WE_Print( client, WE_MSG_AWARDS_NONE );
        return true;
    }

    // Sort high to low by count.
    for ( int i = 0; i < found - 1; i++ )
    {
        for ( int j = 0; j < found - 1 - i; j++ )
        {
            if ( counts[j] >= counts[j + 1] )
                continue;
            int tmpCount = counts[j];
            counts[j] = counts[j + 1];
            counts[j + 1] = tmpCount;
            String tmpTitle = titles[j];
            titles[j] = titles[j + 1];
            titles[j + 1] = tmpTitle;
        }
    }

    WE_Reply reply;
    WE_Reply_AddAwardsTable( reply );
    for ( int i = 0; i < found; i++ )
    {
        reply.TableAddRow();
        reply.TableSet( 0, "" + counts[i] );
        reply.TableSet( 1, titles[i] );
    }
    reply.Send( client );
    return true;
}

bool WE_Cmd_AwardGive( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        WE_Print( client, WE_MSG_AWARDS_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_AWARD_GIVE_USAGE, true, true );
    if ( @target == null )
        return true;

    String id = argsString.getToken( 1 );
    if ( id.len() == 0 )
    {
        WE_Print( client, WE_MSG_AWARD_GIVE_USAGE );
        return true;
    }

    int index = WE_Awards_FindIndex( id );
    if ( index < 0 )
    {
        WE_Print( client, WE_MSG_AWARD_UNKNOWN );
        return true;
    }

    if ( WE_SteamId( target ).len() == 0 )
    {
        WE_Print( client, WE_MSG_AWARDS_NO_STEAM );
        return true;
    }

    WE_Awards_GrantIndex( target, index );
    WE_Print( client, WE_MSG_AWARD_GIVE_DONE );
    return true;
}

bool WE_Cmd_AwardRemove( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        WE_Print( client, WE_MSG_AWARDS_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_AWARD_REMOVE_USAGE, true, true );
    if ( @target == null )
        return true;

    String id = argsString.getToken( 1 );
    if ( id.len() == 0 )
    {
        WE_Print( client, WE_MSG_AWARD_REMOVE_USAGE );
        return true;
    }

    int index = WE_Awards_FindIndex( id );
    if ( index < 0 )
    {
        WE_Print( client, WE_MSG_AWARD_UNKNOWN );
        return true;
    }

    if ( WE_SteamId( target ).len() == 0 )
    {
        WE_Print( client, WE_MSG_AWARDS_NO_STEAM );
        return true;
    }

    if ( !WE_Awards_RemoveIndex( target, index ) )
    {
        WE_Print( client, WE_MSG_AWARD_REMOVE_NONE );
        return true;
    }

    WE_Print( client, WE_MSG_AWARD_REMOVE_DONE );
    return true;
}

void WE_Awards_RegisterCmds()
{
    WE_Cmds_Add( "we_awards", "", "List your earned awards", @WE_Cmd_Awards );
    WE_Cmds_Add( "we_awardGive", "<userid> <award_id>", "Grant a catalog award", @WE_Cmd_AwardGive );
    WE_Cmds_Add( "we_awardRemove", "<userid> <award_id>", "Remove one award count", @WE_Cmd_AwardRemove );
}
