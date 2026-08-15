"""Inject warfork-extended hooks into gametype sources."""

from __future__ import annotations

# Engine-called gametype entry points only (not helpers like GT_updateScore).
ENGINE_HOOKS = (
    "GT_Command",
    "GT_UpdateBotStatus",
    "GT_SelectSpawnPoint",
    "GT_ScoreboardMessage",
    "GT_ScoreEvent",
    "GT_PlayerRespawn",
    "GT_ThinkRules",
    "GT_MatchStateFinished",
    "GT_MatchStateStarted",
    "GT_Shutdown",
    "GT_SpawnGametype",
    "GT_InitGametype",
)

# rettype, params, call-args
HOOK_SIGS: dict[str, tuple[str, str, str]] = {
    "GT_Command": (
        "bool",
        "Client @client, const String &cmdString, const String &argsString, int argc",
        "client, cmdString, argsString, argc",
    ),
    "GT_UpdateBotStatus": ("bool", "Entity @ent", "ent"),
    "GT_SelectSpawnPoint": ("Entity @", "Entity @self", "self"),
    "GT_ScoreboardMessage": ("String @", "uint maxlen", "maxlen"),
    "GT_ScoreEvent": (
        "void",
        "Client @client, const String &score_event, const String &args",
        "client, score_event, args",
    ),
    "GT_PlayerRespawn": (
        "void",
        "Entity @ent, int old_team, int new_team",
        "ent, old_team, new_team",
    ),
    "GT_ThinkRules": ("void", "", ""),
    "GT_MatchStateFinished": ("bool", "int incomingMatchState", "incomingMatchState"),
    "GT_MatchStateStarted": ("void", "", ""),
    "GT_Shutdown": ("void", "", ""),
    "GT_SpawnGametype": ("void", "", ""),
    "GT_InitGametype": ("void", "", ""),
}

# Relative to src/we/ — order matters (deps first).
WE_MODULES = (
    "core/version.as",
    "core/strings.as",
    "core/cvars.as",
    "core/hook_types.as",
    "core/hooks.as",
    "core/cmds.as",
    "utils/time.as",
    "utils/string.as",
    "utils/menu.as",
    "utils/files.as",
    "utils/locks.as",
    "utils/kv.as",
    "core/theme.as",
    "utils/clients.as",
    "player/userinfo.as",
    "core/operators.as",
    "utils/perms.as",
    "player/users.as",
    "utils/console.as",
    "player/player_data.as",
    "player/register.as",
    "features/ban/store.as",
    "features/ban/cmds.as",
    "features/ban/enforce.as",
    "features/weapon/cmds.as",
    "features/respawn/cmds.as",
    "features/changeteam/cmds.as",
    "features/awards/awards.as",
    "features/awards/cmds.as",
    "features/report/store.as",
    "features/report/cmds.as",
    "features/welcome/welcome.as",
    "features/opannounce/opannounce.as",
    "features/clan/clan.as",
    "features/nickban/nickban.as",
    "core/core_cmds.as",
    "core/main.as",
)

SKIP_NAMES = {".gitkeep", ".keep"}
