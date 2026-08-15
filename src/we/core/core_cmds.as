void WE_Cmd_Help_AddRows( WE_Reply @reply, bool operatorOnly )
{
    if ( @reply == null )
        return;

    String who = operatorOnly ? "operator" : "everyone";
    for ( int i = 0; i < weCmdCount; i++ )
    {
        if ( weCmdNames[i].len() == 0 )
            continue;
        if ( weCmdDescs[i].len() == 0 )
            continue;
        if ( weCmdOperatorOnly[i] != operatorOnly )
            continue;
        String cmdName = weCmdNames[i];
        if ( weCmdAliases[i].len() > 0 )
            cmdName += " / " + weCmdAliases[i];
        reply.TableAddRow();
        reply.TableSet( 0, WE_Theme_Color( "accent" ) + cmdName );
        reply.TableSet( 1, weCmdParams[i] );
        reply.TableSet( 2, weCmdDescs[i] );
        reply.TableSet( 3, who );
    }
}

bool WE_Cmd_Help( Client @client, const String &argsString, int argc )
{
    WE_Reply reply;
    reply.AddTitle( WE_MSG_TITLE_COMMANDS );
    reply.TableHeader4( "Command", "Parameters", "Description", "Permission" );
    WE_Cmd_Help_AddRows( reply, false );
    WE_Cmd_Help_AddRows( reply, true );
    reply.Send( client );
    return true;
}

bool WE_Cmd_Users( Client @client, const String &argsString, int argc )
{
    if ( !WE_RequireOperator( client ) )
        return true;
    WE_Reply reply;
    WE_Reply_AddPlayers( reply, true, true );
    reply.Send( client );
    return true;
}

void WE_CoreCmds_Register()
{
    WE_Cmds_Add( "we_help", "", "List commands", false, @WE_Cmd_Help );
    WE_Cmds_Add( "we_users", "", "List connected players", true, @WE_Cmd_Users );
}
