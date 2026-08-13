bool WE_Cmd_Kick( Client @client, const String &argsString, int argc )
{
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_Menu_ClientFromArg( client, argsString, WE_MSG_KICK_USAGE, true );
    if ( @target == null )
        return true;
    if ( !WE_RequireNotSelf( client, target ) )
        return true;

    String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
    if ( reason.len() == 0 )
        reason = WE_MSG_NO_REASON;

    WE_KickClient( target, reason );
    client.printMessage( WE_MSG_KICK_DONE );
    return true;
}

bool WE_Cmd_Ban( Client @client, const String &argsString, int argc )
{
    if ( we_feature_ban.integer != 1 )
    {
        client.printMessage( WE_MSG_BAN_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_Menu_ClientFromArg( client, argsString, WE_MSG_BAN_USAGE, true );
    if ( @target == null )
        return true;
    if ( !WE_RequireNotSelf( client, target ) )
        return true;
    if ( WE_SteamId( target ).len() == 0 )
    {
        client.printMessage( WE_MSG_BAN_NO_STEAM );
        return true;
    }

    String reason = WE_SanitizeReason( WE_JoinArgs( argsString, 1, argc ) );
    if ( reason.len() == 0 )
        reason = WE_MSG_NO_REASON;

    WE_Ban_Reload();
    if ( !WE_Ban_Add( client, target, reason ) )
    {
        client.printMessage( WE_MSG_BAN_FULL );
        return true;
    }

    target.printMessage( WE_MSG_BAN_NOTIFY_PREFIX + reason + "\n" );
    WE_KickClient( target, reason );
    client.printMessage( WE_MSG_BAN_DONE );
    return true;
}

bool WE_Cmd_Unban( Client @client, const String &argsString, int argc )
{
    if ( we_feature_ban.integer != 1 )
    {
        client.printMessage( WE_MSG_BAN_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    WE_Ban_Reload();
    if ( argsString == "" || !argsString.getToken( 0 ).isNumerical() )
    {
        client.printMessage( WE_MSG_UNBAN_USAGE );
        WE_Ban_PrintList( client );
        return true;
    }

    int index = argsString.getToken( 0 ).toInt();
    if ( index < 0 || index >= weBanCount || weBanSteamId[index].len() == 0 )
    {
        client.printMessage( WE_MSG_UNBAN_BAD_INDEX );
        return true;
    }

    WE_Ban_RemoveIndex( index );
    client.printMessage( WE_MSG_UNBAN_DONE );
    return true;
}
