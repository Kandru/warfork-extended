// English UI strings

const String WE_MSG_ADMIN_REQUIRED = S_COLOR_RED + "Operator privileges required.\n";
const String WE_MSG_DISABLED = S_COLOR_YELLOW + "warfork-extended is disabled (we_enabled 0).\n";
const String WE_MSG_USERS_DISABLED = S_COLOR_YELLOW + "Users feature disabled (we_feature_users 0).\n";
const String WE_MSG_BAN_DISABLED = S_COLOR_YELLOW + "Ban feature disabled (we_feature_ban 0).\n";

const String WE_MSG_PLAYERS_HEADER = "\nPlayers:\n";
const String WE_MSG_NO_REASON = "no reason given";

const String WE_MSG_KICK_USAGE = "usage: we_kick <playerNum> [reason]\n\nPlayers:\n";
const String WE_MSG_KICK_DONE = S_COLOR_GREEN + "Kicked.\n";
const String WE_MSG_KICK_NOTIFY_PREFIX = S_COLOR_RED + "You were kicked. Reason: " + S_COLOR_WHITE;

const String WE_MSG_BAN_USAGE = "usage: we_ban <playerNum> [reason]\n\nPlayers:\n";
const String WE_MSG_BAN_DONE = S_COLOR_GREEN + "Banned.\n";
const String WE_MSG_BAN_FULL = S_COLOR_RED + "Ban list is full.\n";
const String WE_MSG_BAN_NO_STEAM = S_COLOR_RED + "Target has no steam_id (ignored).\n";
const String WE_MSG_BAN_NOTIFY_PREFIX = S_COLOR_RED + "You were banned. Reason: " + S_COLOR_WHITE;

const String WE_MSG_UNBAN_USAGE = "usage: we_unban <index>\n\nBanned players:\n";
const String WE_MSG_UNBAN_NONE = "No players banned.\n";
const String WE_MSG_UNBAN_DONE = S_COLOR_GREEN + "Unbanned.\n";
const String WE_MSG_UNBAN_BAD_INDEX = S_COLOR_RED + "Invalid ban index.\n";

const String WE_MSG_HELP =
    S_COLOR_CYAN + "warfork-extended commands:\n"
    + "  we_help\n"
    + "  we_users\n"
    + "  we_kick <playerNum> [reason]\n"
    + "  we_ban <playerNum> [reason]\n"
    + "  we_unban [index]\n";

const String WE_MSG_INIT_PREFIX = "warfork-extended ";
const String WE_MSG_INIT_SUFFIX = " initialized\n";
