# Developing with warfork-extended

This document is for authors of **custom gamemodes** (and WE features) that need persistent per-player data.

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
- Patches the `.gt` list: shared → stubs → WE modules → your scripts → wrappers

### Server

Install **both** pk3s in `basewf`:

1. `gt_warfork_extended_<VERSION>.pk3` (stock wrapped GTs + WE sources)
2. Your thin custom pk3

Rebuild the custom pk3 when you bump WE if inject hooks (`ENGINE_HOOKS`) or include order change. Feature-only WE updates that keep the same paths usually work without a custom rebuild.

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

## Related WE helpers (optional)

| Function | Notes |
|----------|--------|
| `WE_SteamId( client )` | SteamID64 string, or "" |
| `WE_StripColors( text )` | Name without color codes |
| `WE_FindClient( query, includeSpectators )` | Resolve slot or unique name fragment; null if missing/ambiguous |
| `WE_ClientFromArg( actor, argsString, usage, includeSpectators )` | Same, first token; prints usage / player list / matches |
| `WE_Menu` | Build mecu / QuickMenu choice lists (`src/we/utils/menu.as`) |
| `WE_Hooks_Add*` / `WE_Cmds_Add` | For framework features under `src/we/` |

## Files on disk (operators)

```
basewf/warfork-extended/
  banlist.txt
  report.txt               # player reports (append-only CSV)
  awards.txt               # award catalog (load once per gametype init)
  locks.txt
  recent_disconnects.txt   # shared last-25 steam_ids (lock-merge-write, no TTL)
  users/
    <steamid>.txt    # WE keys (incl. award_*) + cust_* keys
```

`report.txt` lines are CSV: `unix, reporterSteam, reporterName, reporterClan, reportedSteam, reportedName, reportedClan, score, frags, deaths, suicides, reason`. Written via locked append (`we_report` / `report`).

`recent_disconnects.txt` is shared across servers on the same `basewf`. Writers lock (`recent_disconnects`), reload, merge, sort by leave unix, keep 25 unique ids, then write. No time expiry — only the max-user cap. Updated on disconnect, init, and shutdown.
