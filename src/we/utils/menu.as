void WE_Menu_PrintPlayers( Client @client, bool includeSpectators )
{
    WE_PrintPlayers( client, includeSpectators );
}

Client @WE_Menu_ClientFromArg( Client @client, const String &in argsString, const String &in usage, bool includeSpectators )
{
    return WE_ClientFromArg( client, argsString, usage, includeSpectators );
}
