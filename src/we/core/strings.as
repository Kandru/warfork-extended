// English UI strings

const String WE_MSG_ADMIN_REQUIRED = S_COLOR_RED + "Operator privileges required.\n";
const String WE_MSG_NO_SELF = S_COLOR_RED + "You cannot do that to yourself.\n";
const String WE_MSG_BAN_DISABLED = S_COLOR_YELLOW + "Ban feature disabled (we_feature_ban 0).\n";
const String WE_MSG_WEAPON_DISABLED = S_COLOR_YELLOW + "Weapon feature disabled (we_feature_weapon 0).\n";
const String WE_MSG_RESPAWN_DISABLED = S_COLOR_YELLOW + "Respawn feature disabled (we_feature_respawn 0).\n";
const String WE_MSG_CHANGETEAM_DISABLED = S_COLOR_YELLOW + "Changeteam feature disabled (we_feature_changeteam 0).\n";

const String WE_MSG_NO_REASON = "no reason given";
const String WE_MSG_PLAYER_AMBIGUOUS = S_COLOR_RED + "Ambiguous player (matches more than one). Be more specific.\n";
const String WE_MSG_ITEM_AMBIGUOUS = S_COLOR_RED + "Ambiguous item (matches more than one). Be more specific.\n";
const String WE_MSG_ITEM_NOT_FOUND = S_COLOR_RED + "Unknown item.\n";
const String WE_MSG_TEAM_AMBIGUOUS = S_COLOR_RED + "Ambiguous team (matches more than one). Be more specific.\n";
const String WE_MSG_TEAM_NOT_FOUND = S_COLOR_RED + "Unknown team.\n";

const String WE_MSG_KICK_USAGE = "usage: we_kick <userid> [reason]\n";
const String WE_MSG_KICK_DONE = S_COLOR_GREEN + "Kicked.\n";
const String WE_MSG_KICK_NOTIFY_PREFIX = S_COLOR_RED + "You were kicked. Reason: " + S_COLOR_WHITE;

const String WE_MSG_BAN_USAGE = "usage: we_ban <userid|name|steam_id> [reason]\n";
const String WE_MSG_BAN_DONE = S_COLOR_GREEN + "Banned.\n";
const String WE_MSG_BAN_FULL = S_COLOR_RED + "Ban list is full.\n";
const String WE_MSG_BAN_NO_STEAM = S_COLOR_RED + "Target has no steam_id (ignored).\n";
const String WE_MSG_BAN_NOTIFY_PREFIX = S_COLOR_RED + "You were banned. Reason: " + S_COLOR_WHITE;
const String WE_MSG_RECENT_DISCONNECTS_NONE = "No recent disconnects.\n";

const String WE_MSG_UNBAN_USAGE = "usage: we_unban <index>\n";
const String WE_MSG_UNBAN_NONE = "No players banned.\n";
const String WE_MSG_UNBAN_DONE = S_COLOR_GREEN + "Unbanned.\n";
const String WE_MSG_UNBAN_BAD_INDEX = S_COLOR_RED + "Invalid ban index.\n";

const String WE_MSG_WEAPON_GIVE_USAGE = "usage: we_weaponGive <userid> <weaponid>\n";
const String WE_MSG_WEAPON_REMOVE_USAGE = "usage: we_weaponRemove <userid> <weaponid>\n";
const String WE_MSG_WEAPON_STRIP_USAGE = "usage: we_weaponStrip <userid>\n";
const String WE_MSG_WEAPON_GIVE_DONE = S_COLOR_GREEN + "Gave item.\n";
const String WE_MSG_WEAPON_REMOVE_DONE = S_COLOR_GREEN + "Removed item.\n";
const String WE_MSG_WEAPON_STRIP_DONE = S_COLOR_GREEN + "Stripped weapons.\n";

const String WE_MSG_RESPAWN_USAGE = "usage: we_respawn <userid>\n";
const String WE_MSG_RESPAWN_DONE = S_COLOR_GREEN + "Respawned.\n";
const String WE_MSG_RESPAWN_NOTIFY = S_COLOR_YELLOW + "You were respawned by an operator.\n";
const String WE_MSG_RESPAWN_SPECTATOR = S_COLOR_RED + "Cannot respawn a spectator.\n";

const String WE_MSG_CHANGETEAM_USAGE = "usage: we_changeteam <userid> <team>\n";
const String WE_MSG_CHANGETEAM_DONE = S_COLOR_GREEN + "Team changed.\n";
const String WE_MSG_CHANGETEAM_NOTIFY = S_COLOR_YELLOW + "Your team was changed by an operator.\n";
const String WE_MSG_CHANGETEAM_SAME = S_COLOR_YELLOW + "Player is already on that team.\n";
const String WE_MSG_CHANGETEAM_INVALID = S_COLOR_RED + "Cannot join that team in this gametype.\n";

const String WE_MSG_AWARDS_DISABLED = S_COLOR_YELLOW + "Awards feature disabled (we_feature_awards 0).\n";
const String WE_MSG_AWARDS_NONE = S_COLOR_YELLOW + "No awards yet.\n";
const String WE_MSG_AWARDS_NO_STEAM = S_COLOR_RED + "No steam_id (ignored).\n";
const String WE_MSG_AWARD_GIVE_USAGE = "usage: we_awardGive <userid> <award_id>\n";
const String WE_MSG_AWARD_GIVE_DONE = S_COLOR_GREEN + "Award granted.\n";
const String WE_MSG_AWARD_REMOVE_USAGE = "usage: we_awardRemove <userid> <award_id>\n";
const String WE_MSG_AWARD_REMOVE_DONE = S_COLOR_GREEN + "Award removed.\n";
const String WE_MSG_AWARD_REMOVE_NONE = S_COLOR_YELLOW + "Player does not have that award.\n";
const String WE_MSG_AWARD_UNKNOWN = S_COLOR_RED + "Unknown award id.\n";
const String WE_MSG_AWARD_CHAT_GOT = S_COLOR_WHITE + " got the award: ";

const String WE_MSG_REPORT_DISABLED = S_COLOR_YELLOW + "Report feature disabled (we_feature_report 0).\n";
const String WE_MSG_REPORT_USAGE = "usage: report <userid> [reason]\n";
const String WE_MSG_REPORT_COOLDOWN = S_COLOR_YELLOW + "Please wait before filing another report.\n";
const String WE_MSG_REPORT_FAILED = S_COLOR_RED + "Could not write report (try again).\n";
const String WE_MSG_REPORT_FILED_PREFIX = S_COLOR_GREEN + "Report filed against ";
const String WE_MSG_REPORT_FILED_SUFFIX = ".\n";
const String WE_MSG_REPORT_REASON_PREFIX = "Reason: ";
const String WE_MSG_REPORT_REVIEW = "An admin will review it.\n";
const String WE_MSG_REPORT_DEATH_HINT_PREFIX = S_COLOR_YELLOW + "Type " + S_COLOR_WHITE + "report ";
const String WE_MSG_REPORT_DEATH_HINT_MID = S_COLOR_YELLOW + " to report ";
const String WE_MSG_REPORT_CHAT_PREFIX = S_COLOR_YELLOW + "[WE] ";
const String WE_MSG_REPORT_CHAT_REPORTED = S_COLOR_WHITE + " reported ";
const String WE_MSG_REPORT_CHAT_FOR = S_COLOR_WHITE + " for " + S_COLOR_CYAN;

const String WE_MSG_INIT_PREFIX = "warfork-extended ";
const String WE_MSG_INIT_SUFFIX = " initialized\n";
