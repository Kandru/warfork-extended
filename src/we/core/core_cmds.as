bool WE_Cmd_Help( Client @client, const String &argsString, int argc )
{
    WE_Reply reply;
    reply.TableHeader3( "Command", "Parameters", "Description" );
    for ( int i = 0; i < weCmdCount; i++ )
    {
        if ( weCmdNames[i].len() == 0 )
            continue;
        if ( weCmdDescs[i].len() == 0 )
            continue;
        reply.TableAddRow();
        reply.TableSet( 0, WE_Theme_Color( "accent" ) + weCmdNames[i] );
        reply.TableSet( 1, weCmdParams[i] );
        reply.TableSet( 2, weCmdDescs[i] );
    }
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
    WE_Cmds_Add( "we_help", "", "List commands", @WE_Cmd_Help );
    WE_Cmds_Add( "we_users", "", "List connected players", @WE_Cmd_Users );
}
