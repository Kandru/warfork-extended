// WE_Menu — stock Warfork client choice menus (mecu) and QuickMenu item lists.
//
// What it is:
//   Builder for modal "mecu" popups (title + label/command buttons) and the same
//   quoted "label" "command" pairs for Client.setQuickMenuItems (bind-key menu).
//
// What it is not:
//   HTML / pseudo-HTML overlays, free-form widgets, positioning, or image layouts.
//   Those are not exposed in the AngelScript API; restoring them needs a client/engine
//   change, not a serverside util.
//
// Protocol (mecu):
//   Client.execGameCommand( 'mecu "Title" "Label" "command" "Label2" "command2"' );
//   Each token is double-quoted. Embedded " characters are stripped so the client
//   parser does not split items.
//
// Commands:
//   Button actions are opaque client-command strings (e.g. "class grunt",
//   "weapselect rl; gametypemenu2", "we_ban"). Register them yourself with
//   G_RegisterCommand (custom GT) or WE_Cmds_Add (WE features). This util does
//   not register commands.
//
// Example:
//   WE_Menu menu( "Pick option" );
//   menu.Add( "Yes", "we_confirm yes" );
//   menu.Add( "No", "we_confirm no" );
//   menu.Show( client );

String WE_Menu_Quote( const String &in text )
{
    String cleaned = "";
    for ( uint i = 0; i < text.len(); i++ )
    {
        String ch = text.substr( i, 1 );
        if ( ch == "\"" )
            continue;
        cleaned += ch;
    }
    return "\"" + cleaned + "\"";
}

class WE_Menu
{
    String title;
    String items;

    WE_Menu()
    {
        this.title = "";
        this.items = "";
    }

    WE_Menu( const String &in title )
    {
        this.title = title;
        this.items = "";
    }

    void Clear()
    {
        this.title = "";
        this.items = "";
    }

    void SetTitle( const String &in title )
    {
        this.title = title;
    }

    void Add( const String &in label, const String &in command )
    {
        if ( label.len() == 0 || command.len() == 0 )
            return;

        if ( this.items.len() > 0 )
            this.items += " ";
        this.items += WE_Menu_Quote( label ) + " " + WE_Menu_Quote( command );
    }

    String ToMecuCommand()
    {
        String cmd = "mecu " + WE_Menu_Quote( this.title );
        if ( this.items.len() > 0 )
            cmd += " " + this.items;
        return cmd;
    }

    String ToQuickMenuItems()
    {
        return this.items;
    }

    void Show( Client @client )
    {
        if ( @client == null )
            return;
        client.execGameCommand( this.ToMecuCommand() );
    }

    void SetQuickMenu( Client @client )
    {
        if ( @client == null )
            return;
        client.setQuickMenuItems( this.ToQuickMenuItems() );
    }
}
