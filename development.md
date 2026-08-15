# Developing with warfork-extended

This document is for authors of **custom gamemodes** (and WE features) that need persistent per-player data.

Award catalog kinds, filters (`WEAP_*` / `AMMO_*` / `KEYICON_*`), frequency, and engine limitations: see [`awards.md`](awards.md).

## Build & layout reminder

Custom gametypes ship as a **separate thin pk3**. They must be inject-built so their `.gt` include list pulls in WE + wrappers; Warfork compiles one AngelScript module per `.gt` (no cross-pk3 function calls).

### Layout (your GT repo)

```
progs/gametypes/<name>.gt
progs/gametypes/<name>.as
progs/gametypes/…          # extras
```

Filenames stay unprefixed (they are not in the stock game).

### Build (from warfork-extended)

```bash
make custom CUSTOM_ROOT=/path/to/your-gt-repo PK3=/path/to/gt_mygt.pk3
# optional: MODE=debug
```

From a submodule checkout:

```bash
make -C vendor/warfork-extended custom \
  CUSTOM_ROOT=$(PWD) \
  PK3=$(PWD)/dist/gt_mygt.pk3
```

What the injector does:

- Copies only your `progs/` (does **not** embed `src/we/`)
- Rewrites stock includes (`shared/`, `generic/`, …) to `we_*` names expected from the WE pk3
- Renames engine `GT_*` → `GT_*__orig`, writes per-GT stubs + `wrappers_<stem>.as`
- Patches the `.gt` list: shared → stubs → WE modules (`we/…`) → your scripts → wrappers
- Rejects includes whose full VFS path (`progs/gametypes/<path>`) exceeds 63 chars (engine QPATH; `.as` gets truncated)

### Server

Install **both** pk3s in `basewf`:

1. `gt_warfork_extended_<VERSION>.pk3` (stock wrapped GTs + WE sources)
2. Your thin custom pk3

Rebuild the custom pk3 when you bump WE if inject hooks (`ENGINE_HOOKS`) / wrapper dispatches or include order change. Feature-only WE updates that keep the same paths usually work without a custom rebuild. After WE adds new wrapper dispatches (e.g. `GT_MatchStateStarted` / `GT_PlayerRespawn` / `GT_ScoreboardMessage` after-hooks), rebuild custom thin pk3s.

### Local debug (optional one-pk3 overlay)

```bash
# inside warfork-extended, with sources under gamemodes/custom/
make prod INCLUDE_CUSTOM=1
# or: make prod INCLUDE_CUSTOM=1 CUSTOM_ROOT=/path/to/my-gt-repo
```

WE AngelScript is listed **before** your gametype scripts in the `.gt` include list, so you can call WE APIs from your `.as` files directly.
Identity is always **SteamID**. Clients without `steam_id` (e.g. bots) are ignored by user APIs.

## Per-player key/value storage

Each human player gets a file:

`basewf/warfork-extended/users/<steamid>.txt`

Lines are `key=value`. WE owns framework keys (userinfo snapshot, `last_connected` / `last_connected_unix`, `last_disconnected` / `last_disconnected_unix`, `award_<id>` award counters, …).

### Custom gamemode API

Use these helpers so you never clash with WE keys. Your key is stored as `cust_<name>`.

| Function | Purpose |
|----------|---------|
| `WE_GetPlayerData( client, key )` | Read a value for a connected player ("" if missing) |
| `WE_SetPlayerData( client, key, value )` | Write a value for a connected player |
| `WE_GetPlayerDataBySteamId( steamid, key )` | Read by SteamID (offline / not on server) |
| `WE_SetPlayerDataBySteamId( steamid, key, value )` | Write by SteamID |

Examples: key `bestScore` → file key `cust_bestScore`. Passing `cust_bestScore` is left unchanged.

Requires `we_enabled 1` (player/users storage is always available when WE is on).

### Example — save / load a high score

```angelscript
const String KEY_BEST_SCORE = "bestScore"; // stored as cust_bestScore

void MyGT_LoadPlayer( Client @client )
{
    if ( @client == null )
        return;

    String raw = WE_GetPlayerData( client, KEY_BEST_SCORE );
    int best = 0;
    if ( raw.len() > 0 && raw.isNumerical() )
        best = raw.toInt();

    // ... keep `best` in your gametype state ...
}

void MyGT_SaveBest( Client @client, int score )
{
    if ( @client == null )
        return;

    String prev = WE_GetPlayerData( client, KEY_BEST_SCORE );
    int best = 0;
    if ( prev.len() > 0 && prev.isNumerical() )
        best = prev.toInt();
    if ( score <= best )
        return;

    WE_SetPlayerData( client, KEY_BEST_SCORE, "" + score );
}
```

Call load from `GT_ScoreEvent` when `score_event == "enterGame"`, and save on kill / match end as needed.

### Example — by SteamID

```angelscript
String steamid = WE_SteamId( client );
if ( steamid.len() == 0 )
    return; // bot / no auth

WE_SetPlayerDataBySteamId( steamid, "visits", "1" );
String visits = WE_GetPlayerDataBySteamId( steamid, "visits" );
```

### Rules of thumb

- Prefer short keys: `bestScore`, `wins`, `lastMap`.
- Values are sanitized (commas/newlines stripped) for safe single-line storage.
- **Reads** do not lock; **writes** use a short soft-lock.
- Do not call internal `WE_UserSet` with bare keys from a custom GT — use `WE_GetPlayerData` / `WE_SetPlayerData`.
- Bots have no steamid; skip them.

## Named key/value files

For non-player data (server-wide scores, GT settings, feature stores), use named files under:

`basewf/warfork-extended/kv/<name>.txt`

Same `key=value` format as user files. One API for **WE features and custom gamemodes**.

| Function | Purpose |
|----------|---------|
| `WE_KvFileGet( name, key )` | Read a value (`""` if missing / disabled) |
| `WE_KvFileSet( name, key, value )` | Write a value (creates the file) |

- `name` is a stem only: `[A-Za-z0-9_-]+`. Optional trailing `.txt` is stripped. No slashes.
- File path: `warfork-extended/kv/<name>.txt`. Lock name: `kv_<name>`.
- **Reads** do not lock; **writes** use `WE_WriteFileLocked` (same soft-lock as users / theme / banlist).
- Keys and values are sanitized (`WE_SanitizeField`). Requires `we_enabled 1`.
- Pick distinct names so features and GTs do not share a file by accident (e.g. `highscores`, `mygt_state`).

### Example

```angelscript
const String KV_HIGHSCORES = "highscores";

void MyGT_LoadBest()
{
    String raw = WE_KvFileGet( KV_HIGHSCORES, "best" );
    int best = 0;
    if ( raw.len() > 0 && raw.isNumerical() )
        best = raw.toInt();
    // ...
}

void MyGT_SaveBest( int score )
{
    String prev = WE_KvFileGet( KV_HIGHSCORES, "best" );
    int best = 0;
    if ( prev.len() > 0 && prev.isNumerical() )
        best = prev.toInt();
    if ( score <= best )
        return;
    WE_KvFileSet( KV_HIGHSCORES, "best", "" + score );
}
```

## In-game choice menus (`WE_Menu`)

Stock Warfork clients can show a **modal choice list** (`mecu`) and a **bind-key QuickMenu**. `WE_Menu` builds both from the same label/command pairs. It is **not** HTML / pseudo-HTML overlays (those need a client/engine fork; vanilla clients only get this list UI).

| Method | Purpose |
|--------|---------|
| `WE_Menu()` / `WE_Menu( title )` | Construct empty or titled menu |
| `SetTitle( title )` / `Clear()` | Change title / reset title + items |
| `Add( label, command )` | Append a button (skips empty label or command) |
| `Show( client )` | `execGameCommand( mecu … )` popup |
| `SetQuickMenu( client )` | `setQuickMenuItems( … )` for the quick-menu bind |
| `ToMecuCommand()` / `ToQuickMenuItems()` | Raw strings if you need them |

Every token is double-quoted; embedded `"` characters are stripped so the client parser does not split items.

Button `command` strings are opaque client commands. Register them yourself (`G_RegisterCommand` in a custom GT, or `WE_Cmds_Add` for WE features). The util does not register commands.

### Example — modal picker in a custom GT

```angelscript
void MyGT_ShowConfirm( Client @client )
{
    if ( @client == null )
        return;

    WE_Menu menu( "Confirm" );
    menu.Add( "Yes", "myconfirm yes" );
    menu.Add( "No", "myconfirm no" );
    menu.Show( client );
}

// In GT_InitGametype:
//   G_RegisterCommand( "myconfirm" );

// In GT_Command, handle cmdString == "myconfirm" and argsString.
```

For the bind-key menu instead of a popup, call `menu.SetQuickMenu( client )` (same `Add` pairs).

## Console replies (`WE_Reply`)

Operator/player command output should be **one** themed reply per command (prefix only on the first line).

| API | Purpose |
|-----|---------|
| `WE_Reply` / `AddLine` / `AddItem` / `Send` | Buffer lines; `AddItem` prefixes a grey `- ` |
| `TableHeader*` / `TableAddRow` / `TableSet` | Padded columns with grey ` \| ` separators |
| `WE_Reply_AddPlayers( reply, includeSpectators, withTeam )` | Player table (Team column optional) |
| `WE_Reply_AddRecentDisconnects( reply )` | Offline targets with IDs **900+** |
| `WE_Reply_AddItems` / `WE_Reply_AddTeams` | Item / joinable-team tables |
| `WE_ClientFromArg( …, includeSpectators, withTeam )` | Resolve first token; on failure prints usage + player table |
| `WE_Cmds_Add( name, params, description, @handler )` | Register command for dispatch + `we_help` |
| `WE_Theme_Color( role )` / `WE_Theme_Prefix()` | Colors from `theme.txt` (`S_COLOR_*` only) |

Example:

```angelscript
bool WE_Cmd_Foo( Client @client, const String &argsString, int argc )
{
    WE_Reply reply;
    reply.AddLine( "usage: we_foo <userid>" );
    WE_Reply_AddPlayers( reply, true, true );
    reply.Send( client );
    return true;
}
```

Theme file `basewf/warfork-extended/theme.txt` (see `configs/theme.txt.example`): roles `accent`, `header`, `sep`, `marker`, `body`, `success`, `error`, `warn` map to color **names** (`orange`, `grey`, …), never `^` codes. Defaults: orange labels, grey separators, white body. Seeded on first run if missing.

## Related WE helpers (optional)

| Function | Notes |
|----------|--------|
| `WE_SteamId( client )` | SteamID64 string, or "" |
| `WE_IsOperator( client )` | Engine `op` / `client.isOperator`, or SteamID in `we_operators` |
| `WE_RequireOperator( client )` | Gate + deny message; prefer over raw `client.isOperator` |
| `WE_ScoreboardClan( client )` | Clan column when `we_feature_clan` is on (ops / reserved tag) |
| `WE_StripColors( text )` | Name without color codes |
| `WE_FindClient( query, includeSpectators )` | Resolve slot or unique name fragment; null if missing/ambiguous |
| `WE_ClientFromArg( actor, argsString, usage, includeSpectators, withTeam )` | First token; prints usage / player table / matches |
| `WE_Menu` | Build mecu / QuickMenu choice lists (`src/we/utils/menu.as`) |
| `WE_KvFileGet` / `WE_KvFileSet` | Named `key=value` files under `kv/<name>.txt` |
| `WE_Hooks_Add*` / `WE_Cmds_Add` | For framework features under `src/we/` |
| `WE_Reply` | Console lists/tables (`src/we/utils/console.as`) |

## Files on disk (operators)

```
basewf/warfork-extended/
  banlist.txt
  report.txt               # player reports (append-only CSV)
  theme.txt                # console colors (role=colorname); seeded if missing
  awards.txt               # award catalog: id|enabled|kind|freq|p1|p2|title|description
                           # (load once per gametype init; freq=every|map|round|once)
                           # kinds/filters/limits: see awards.md in the repo root
  locks.txt
  recent_disconnects.txt   # shared last-25 steam_ids (lock-merge-write, no TTL)
  kv/
    <name>.txt       # named key=value files (WE_KvFileGet/Set)
  users/
    <steamid>.txt    # WE keys (incl. award_*) + cust_* keys
```

`report.txt` lines are CSV: `unix, hostname, reporterSteam, reporterName, reporterClan, reportedSteam, reportedName, reportedClan, score, frags, deaths, suicides, reason`. Hostname is `sv_hostname` with color tokens stripped. Names and clan tags are color-stripped. Appended by `we_report` / `report`; the notify sidecar truncates the file after posting.

`recent_disconnects.txt` is shared across servers on the same `basewf`. Writers lock (`recent_disconnects`), reload, merge, sort by leave unix, keep 25 unique ids, then write. No time expiry — only the max-user cap. Updated on disconnect, init, and shutdown. Offline ban list IDs start at **900**.
