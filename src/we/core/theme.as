// Console theme — role → S_COLOR_* via warfork-extended/theme.txt

const String WE_THEME_PATH = "warfork-extended/theme.txt";
const String WE_THEME_LOCK = "theme";

const String WE_THEME_DEFAULT =
    "# warfork-extended console theme (color names, not ^ codes)\n"
    + "accent=orange\n"
    + "header=orange\n"
    + "sep=grey\n"
    + "marker=grey\n"
    + "body=white\n"
    + "success=green\n"
    + "error=red\n"
    + "warn=yellow\n";

String weThemeAccent = S_COLOR_ORANGE;
String weThemeHeader = S_COLOR_ORANGE;
String weThemeSep = S_COLOR_GREY;
String weThemeMarker = S_COLOR_GREY;
String weThemeBody = S_COLOR_WHITE;
String weThemeSuccess = S_COLOR_GREEN;
String weThemeError = S_COLOR_RED;
String weThemeWarn = S_COLOR_YELLOW;

String WE_Theme_NameToColor( const String &in name )
{
    String n = name.tolower();
    if ( n == "black" )
        return S_COLOR_BLACK;
    if ( n == "red" )
        return S_COLOR_RED;
    if ( n == "green" )
        return S_COLOR_GREEN;
    if ( n == "yellow" )
        return S_COLOR_YELLOW;
    if ( n == "blue" )
        return S_COLOR_BLUE;
    if ( n == "cyan" )
        return S_COLOR_CYAN;
    if ( n == "purple" || n == "magenta" )
        return S_COLOR_MAGENTA;
    if ( n == "white" )
        return S_COLOR_WHITE;
    if ( n == "orange" )
        return S_COLOR_ORANGE;
    if ( n == "gray" || n == "grey" )
        return S_COLOR_GREY;
    return "";
}

void WE_Theme_ApplyDefaults()
{
    weThemeAccent = S_COLOR_ORANGE;
    weThemeHeader = S_COLOR_ORANGE;
    weThemeSep = S_COLOR_GREY;
    weThemeMarker = S_COLOR_GREY;
    weThemeBody = S_COLOR_WHITE;
    weThemeSuccess = S_COLOR_GREEN;
    weThemeError = S_COLOR_RED;
    weThemeWarn = S_COLOR_YELLOW;
}

void WE_Theme_SetRole( const String &in role, const String &in colorName )
{
    String token = WE_Theme_NameToColor( colorName );
    if ( token.len() == 0 )
        return;

    if ( role == "accent" )
        weThemeAccent = token;
    else if ( role == "header" )
        weThemeHeader = token;
    else if ( role == "sep" )
        weThemeSep = token;
    else if ( role == "marker" )
        weThemeMarker = token;
    else if ( role == "body" )
        weThemeBody = token;
    else if ( role == "success" )
        weThemeSuccess = token;
    else if ( role == "error" )
        weThemeError = token;
    else if ( role == "warn" )
        weThemeWarn = token;
}

String WE_Theme_Color( const String &in role )
{
    if ( role == "accent" )
        return weThemeAccent;
    if ( role == "header" )
        return weThemeHeader;
    if ( role == "sep" )
        return weThemeSep;
    if ( role == "marker" )
        return weThemeMarker;
    if ( role == "body" )
        return weThemeBody;
    if ( role == "success" )
        return weThemeSuccess;
    if ( role == "error" )
        return weThemeError;
    if ( role == "warn" )
        return weThemeWarn;
    return weThemeBody;
}

// Grey brackets, accent "WE", then body for following text.
String WE_Theme_Prefix()
{
    return weThemeSep + "[" + weThemeAccent + "WE" + weThemeSep + "] " + weThemeBody;
}

void WE_Theme_SeedIfMissing()
{
    if ( WE_FileExists( WE_THEME_PATH ) )
        return;
    WE_WriteFileLocked( WE_THEME_PATH, WE_THEME_LOCK, WE_THEME_DEFAULT );
}

void WE_Theme_Load()
{
    WE_Theme_ApplyDefaults();

    String data;
    if ( !WE_LoadFile( WE_THEME_PATH, data ) )
        return;

    bool found = false;
    String line;
    uint pos = 0;
    while ( WE_NextLine( data, pos, line, pos ) )
    {
        if ( line.len() == 0 )
            continue;
        if ( line.substr( 0, 1 ) == "#" )
            continue;

        String key;
        String value;
        if ( !WE_SplitKeyValue( line, key, value ) )
            continue;
        key = WE_Trim( key );
        value = WE_Trim( value );
        if ( key.len() == 0 || value.len() == 0 )
            continue;
        if ( WE_Theme_NameToColor( value ).len() == 0 )
            continue;

        WE_Theme_SetRole( key, value );
        found = true;
    }

    if ( !found )
    {
        WE_WriteFileLocked( WE_THEME_PATH, WE_THEME_LOCK, WE_THEME_DEFAULT );
        WE_Theme_ApplyDefaults();
    }
}

void WE_Theme_Init()
{
    WE_Theme_SeedIfMissing();
    WE_Theme_Load();
}
