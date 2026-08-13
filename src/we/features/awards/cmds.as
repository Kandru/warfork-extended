void WE_Awards_AddCatalogTable( WE_Reply @reply )
{
    if ( @reply == null )
        return;

    reply.AddTitle( WE_MSG_TITLE_AWARDS_AVAILABLE );
    if ( weAwardCount <= 0 )
    {
        reply.AddLine( WE_MSG_AWARDS_CATALOG_NONE );
        reply.AddLine( "" );
        return;
    }

    reply.TableHeader6( "#Id", "Title", "Kind", "Freq", "P1", "P2" );
    for ( int i = 0; i < weAwardCount; i++ )
    {
        reply.TableAddRow();
        reply.TableSet( 0, weAwardId[i] );
        reply.TableSet( 1, weAwardTitle[i] );
        reply.TableSet( 2, WE_Awards_KindName( weAwardKind[i] ) );
        reply.TableSet( 3, WE_Awards_FreqName( weAwardFreq[i] ) );
        reply.TableSet( 4, "" + weAwardP1[i] );
        reply.TableSet( 5, WE_Awards_P2Label( weAwardKind[i], weAwardP2[i] ) );
    }
}

bool WE_Cmd_Awards( Client @client, const String &argsString, int argc )
{
    if ( we_feature_awards.integer != 1 )
    {
        WE_Print( client, WE_MSG_AWARDS_DISABLED );
        return true;
    }

    WE_Reply reply;
    WE_Awards_AddCatalogTable( reply );

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
    {
        reply.AddTitle( WE_MSG_TITLE_AWARDS );
        reply.AddLine( WE_MSG_AWARDS_NO_STEAM );
        reply.Send( client );
        return true;
    }

    String data;
    const uint prefixLen = WE_AWARD_KEY_PREFIX.len();
    String[] titles( WE_MAX_AWARDS );
    String[] descs( WE_MAX_AWARDS );
    int[] counts( WE_MAX_AWARDS );
    int found = 0;

    if ( WE_UserLoad( steamid, data ) )
    {
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
            descs[found] = WE_Awards_DescForId( id );
            counts[found] = value.toInt();
            found++;
        }
    }

    if ( found == 0 )
    {
        reply.AddTitle( WE_MSG_TITLE_AWARDS );
        reply.AddLine( WE_MSG_AWARDS_NONE );
        reply.Send( client );
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
            String tmpDesc = descs[j];
            descs[j] = descs[j + 1];
            descs[j + 1] = tmpDesc;
        }
    }

    WE_Reply_AddAwardsTable( reply );
    for ( int i = 0; i < found; i++ )
    {
        reply.TableAddRow();
        reply.TableSet( 0, "" + counts[i] );
        reply.TableSet( 1, titles[i] );
        reply.TableSet( 2, descs[i] );
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
    WE_Cmds_Add( "we_awards", "", "List available awards and your counts", @WE_Cmd_Awards );
    WE_Cmds_Add( "we_awardGive", "<userid> <award_id>", "Grant a catalog award", @WE_Cmd_AwardGive );
    WE_Cmds_Add( "we_awardRemove", "<userid> <award_id>", "Remove one award count", @WE_Cmd_AwardRemove );
}
