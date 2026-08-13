// English UI strings

const String WE_MSG_ADMIN_REQUIRED = S_COLOR_RED + "Operator privileges required.\n";
const String WE_MSG_NO_SELF = S_COLOR_RED + "You cannot do that to yourself.\n";
const String WE_MSG_DISABLED = S_COLOR_YELLOW + "warfork-extended is disabled (we_enabled 0).\n";
const String WE_MSG_USERS_DISABLED = S_COLOR_YELLOW + "Users feature disabled (we_feature_users 0).\n";
const String WE_MSG_BAN_DISABLED = S_COLOR_YELLOW + "Ban feature disabled (we_feature_ban 0).\n";
const String WE_MSG_WEAPON_DISABLED = S_COLOR_YELLOW + "Weapon feature disabled (we_feature_weapon 0).\n";

const String WE_MSG_PLAYERS_HEADER = "\nPlayers:\n";
const String WE_MSG_ITEMS_HEADER = "\nItems:\n";
const String WE_MSG_NO_REASON = "no reason given";
const String WE_MSG_PLAYER_AMBIGUOUS = S_COLOR_RED + "Ambiguous player (matches more than one). Be more specific.\n";
const String WE_MSG_ITEM_AMBIGUOUS = S_COLOR_RED + "Ambiguous item (matches more than one). Be more specific.\n";
const String WE_MSG_ITEM_NOT_FOUND = S_COLOR_RED + "Unknown item.\n";

const String WE_MSG_KICK_USAGE = "usage: we_kick <userid> [reason]\n";
const String WE_MSG_KICK_DONE = S_COLOR_GREEN + "Kicked.\n";
const String WE_MSG_KICK_NOTIFY_PREFIX = S_COLOR_RED + "You were kicked. Reason: " + S_COLOR_WHITE;

const String WE_MSG_BAN_USAGE = "usage: we_ban <userid> [reason]\n";
const String WE_MSG_BAN_DONE = S_COLOR_GREEN + "Banned.\n";
const String WE_MSG_BAN_FULL = S_COLOR_RED + "Ban list is full.\n";
const String WE_MSG_BAN_NO_STEAM = S_COLOR_RED + "Target has no steam_id (ignored).\n";
const String WE_MSG_BAN_NOTIFY_PREFIX = S_COLOR_RED + "You were banned. Reason: " + S_COLOR_WHITE;

const String WE_MSG_UNBAN_USAGE = "usage: we_unban <index>\n\nBanned players:\n";
const String WE_MSG_UNBAN_NONE = "No players banned.\n";
const String WE_MSG_UNBAN_DONE = S_COLOR_GREEN + "Unbanned.\n";
const String WE_MSG_UNBAN_BAD_INDEX = S_COLOR_RED + "Invalid ban index.\n";

const String WE_MSG_WEAPON_GIVE_USAGE = "usage: we_weaponGive <userid> <weaponid>\n";
const String WE_MSG_WEAPON_REMOVE_USAGE = "usage: we_weaponRemove <userid> <weaponid>\n";
const String WE_MSG_WEAPON_STRIP_USAGE = "usage: we_weaponStrip <userid>\n";
const String WE_MSG_WEAPON_GIVE_DONE = S_COLOR_GREEN + "Gave item.\n";
const String WE_MSG_WEAPON_REMOVE_DONE = S_COLOR_GREEN + "Removed item.\n";
const String WE_MSG_WEAPON_STRIP_DONE = S_COLOR_GREEN + "Stripped weapons.\n";

const String WE_MSG_HELP =
    S_COLOR_CYAN + "warfork-extended commands:\n"
    + "  we_help\n"
    + "  we_users\n"
    + "  we_kick <userid> [reason]\n"
    + "  we_ban <userid> [reason]\n"
    + "  we_unban [index]\n"
    + "  we_weaponGive <userid> <weaponid>\n"
    + "  we_weaponRemove <userid> <weaponid>\n"
    + "  we_weaponStrip <userid>\n";

const String WE_MSG_INIT_PREFIX = "warfork-extended ";
const String WE_MSG_INIT_SUFFIX = " initialized\n";
