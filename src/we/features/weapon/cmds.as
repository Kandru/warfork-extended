const int WE_ITEM_TAG_MAX = 64;

void WE_Weapon_PrintItemLine( Client @to, Item @item )
{
    if ( @to == null || @item == null )
        return;
    String line = item.tag + ": " + item.name;
    String shortN = item.shortName;
    if ( shortN.len() > 0 )
        line += " (" + shortN + ")";
    WE_Print( to, line + "\n" );
}

void WE_Weapon_PrintItems( Client @client )
{
    WE_Print( client, WE_MSG_ITEMS_HEADER );
    for ( int i = 1; i < WE_ITEM_TAG_MAX; i++ )
    {
        Item @item = @G_GetItem( i );
        if ( @item == null )
            continue;
        if ( item.name.len() == 0 )
            continue;
        WE_Weapon_PrintItemLine( client, item );
    }
}

void WE_Weapon_PrintUsage( Client @client, const String &in usage )
{
    WE_Print( client, usage );
    WE_PrintPlayers( client, true );
    WE_Weapon_PrintItems( client );
}

bool WE_Weapon_ItemTextMatches( Item @item, const String &in query )
{
    if ( @item == null )
        return false;
    if ( WE_ContainsIgnoreCase( item.name, query ) )
        return true;
    if ( WE_ContainsIgnoreCase( item.shortName, query ) )
        return true;
    if ( WE_ContainsIgnoreCase( item.classname, query ) )
        return true;
    return false;
}

bool WE_Weapon_ItemTextEquals( Item @item, const String &in query )
{
    if ( @item == null )
        return false;
    if ( WE_EqualsIgnoreCase( item.name, query ) )
        return true;
    if ( WE_EqualsIgnoreCase( item.shortName, query ) )
        return true;
    if ( WE_EqualsIgnoreCase( item.classname, query ) )
        return true;
    return false;
}

Item @WE_Weapon_ItemFromQuery( Client @client, const String &in query )
{
    if ( query.len() == 0 )
        return null;

    if ( query.isNumerical() )
    {
        int tag = query.toInt();
        if ( tag >= 1 )
        {
            Item @byTag = @G_GetItem( tag );
            if ( @byTag != null && byTag.name.len() > 0 )
                return byTag;
        }
    }

    int matchCount = 0;
    int exactCount = 0;
    Item @found = null;
    Item @exact = null;

    for ( int i = 1; i < WE_ITEM_TAG_MAX; i++ )
    {
        Item @item = @G_GetItem( i );
        if ( @item == null )
            continue;
        if ( !WE_Weapon_ItemTextMatches( item, query ) )
            continue;

        matchCount++;
        @found = @item;
        if ( WE_Weapon_ItemTextEquals( item, query ) )
        {
            exactCount++;
            @exact = @item;
        }
    }

    int kind = WE_UniqueMatchKind( matchCount, exactCount );
    if ( kind == WE_MATCH_UNIQUE )
        return found;
    if ( kind == WE_MATCH_EXACT )
        return exact;

    if ( kind == WE_MATCH_AMBIGUOUS )
    {
        WE_Print( client, WE_MSG_ITEM_AMBIGUOUS );
        for ( int i = 1; i < WE_ITEM_TAG_MAX; i++ )
        {
            Item @item = @G_GetItem( i );
            if ( @item == null )
                continue;
            if ( !WE_Weapon_ItemTextMatches( item, query ) )
                continue;
            WE_Weapon_PrintItemLine( client, item );
        }
        return null;
    }

    WE_Print( client, WE_MSG_ITEM_NOT_FOUND );
    WE_Weapon_PrintItems( client );
    return null;
}

void WE_Weapon_GiveAmmo( Client @target, Item @item )
{
    if ( @target == null || @item == null )
        return;
    if ( ( item.type & IT_WEAPON ) == 0 )
        return;

    if ( item.ammoTag != AMMO_NONE )
    {
        Item @ammoItem = @G_GetItem( item.ammoTag );
        if ( @ammoItem != null )
            target.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );
    }
    if ( item.weakAmmoTag != AMMO_NONE )
    {
        Item @weakAmmo = @G_GetItem( item.weakAmmoTag );
        if ( @weakAmmo != null )
            target.inventorySetCount( weakAmmo.tag, weakAmmo.inventoryMax );
    }
}

void WE_Weapon_SelectFallback( Client @target, int removedTag )
{
    if ( @target == null )
        return;
    if ( target.weapon != removedTag && target.pendingWeapon != removedTag )
        return;

    for ( int w = WEAP_GUNBLADE; w < WEAP_TOTAL; w++ )
    {
        if ( w == removedTag )
            continue;
        if ( target.canSelectWeapon( w ) )
        {
            target.selectWeapon( w );
            return;
        }
    }
}

bool WE_Weapon_ParseArgs( Client @client, const String &argsString, int argc, const String &in usage, Client @ &out target, Item @ &out item )
{
    @target = null;
    @item = null;

    String userTok = argsString.getToken( 0 );
    String itemTok = WE_JoinArgs( argsString, 1, argc );
    if ( userTok.len() == 0 || itemTok.len() == 0 )
    {
        WE_Weapon_PrintUsage( client, usage );
        return false;
    }

    @target = @WE_ClientFromArg( client, argsString, usage, true );
    if ( @target == null )
    {
        WE_Weapon_PrintItems( client );
        return false;
    }

    @item = @WE_Weapon_ItemFromQuery( client, itemTok );
    if ( @item == null )
        return false;
    return true;
}

bool WE_Cmd_WeaponGive( Client @client, const String &argsString, int argc )
{
    if ( we_feature_weapon.integer != 1 )
    {
        WE_Print( client, WE_MSG_WEAPON_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = null;
    Item @item = null;
    if ( !WE_Weapon_ParseArgs( client, argsString, argc, WE_MSG_WEAPON_GIVE_USAGE, target, item ) )
        return true;

    target.inventoryGiveItem( item.tag );
    WE_Weapon_GiveAmmo( target, item );
    if ( ( item.type & IT_WEAPON ) != 0 )
        target.selectWeapon( item.tag );

    WE_Print( client, WE_MSG_WEAPON_GIVE_DONE );
    return true;
}

bool WE_Cmd_WeaponRemove( Client @client, const String &argsString, int argc )
{
    if ( we_feature_weapon.integer != 1 )
    {
        WE_Print( client, WE_MSG_WEAPON_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = null;
    Item @item = null;
    if ( !WE_Weapon_ParseArgs( client, argsString, argc, WE_MSG_WEAPON_REMOVE_USAGE, target, item ) )
        return true;

    int tag = item.tag;
    target.inventorySetCount( tag, 0 );
    if ( ( item.type & IT_WEAPON ) != 0 )
        WE_Weapon_SelectFallback( target, tag );

    WE_Print( client, WE_MSG_WEAPON_REMOVE_DONE );
    return true;
}

void WE_Weapon_Strip( Client @target )
{
    if ( @target == null )
        return;

    for ( int w = WEAP_GUNBLADE; w < WEAP_TOTAL; w++ )
    {
        Item @item = @G_GetItem( w );
        target.inventorySetCount( w, 0 );
        if ( @item == null )
            continue;
        if ( item.ammoTag != AMMO_NONE )
            target.inventorySetCount( item.ammoTag, 0 );
        if ( item.weakAmmoTag != AMMO_NONE )
            target.inventorySetCount( item.weakAmmoTag, 0 );
    }

    WE_Weapon_SelectFallback( target, target.weapon );
}

bool WE_Cmd_WeaponStrip( Client @client, const String &argsString, int argc )
{
    if ( we_feature_weapon.integer != 1 )
    {
        WE_Print( client, WE_MSG_WEAPON_DISABLED );
        return true;
    }
    if ( !WE_RequireOperator( client ) )
        return true;

    Client @target = @WE_ClientFromArg( client, argsString, WE_MSG_WEAPON_STRIP_USAGE, true );
    if ( @target == null )
        return true;

    WE_Weapon_Strip( target );
    WE_Print( client, WE_MSG_WEAPON_STRIP_DONE );
    return true;
}

void WE_Weapon_Register()
{
    WE_Cmds_Add( "we_weaponGive", @WE_Cmd_WeaponGive );
    WE_Cmds_Add( "we_weaponRemove", @WE_Cmd_WeaponRemove );
    WE_Cmds_Add( "we_weaponStrip", @WE_Cmd_WeaponStrip );
}
