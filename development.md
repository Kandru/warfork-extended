# Developing with warfork-extended

This document is for authors of **custom gamemodes** (and WE features) that need persistent per-player data.

## Build & layout reminder

- Put custom gametypes in `gamemodes/custom/progs/gametypes/` (same layout as stock).
- Run `make prod` or `make dev`. Custom files keep their original names.
- WE AngelScript is injected **before** your gametype scripts in the `.gt` include list, so you can call WE APIs from your `.as` files directly.
- Identity is always **SteamID**. Clients without `steam_id` (e.g. bots) are ignored by user APIs.

## Per-player key/value storage

Each human player gets a file:

`basewf/warfork-extended/users/<steamid>.txt`

Lines are `key=value`. WE owns framework keys (userinfo snapshot, `last_connected`, …).

### Custom gamemode API

Use these helpers so you never clash with WE keys. Your key is stored as `cust_<name>`.

| Function | Purpose |
|----------|---------|
| `WE_GetPlayerData( client, key )` | Read a value for a connected player ("" if missing) |
| `WE_SetPlayerData( client, key, value )` | Write a value for a connected player |
| `WE_GetPlayerDataBySteamId( steamid, key )` | Read by SteamID (offline / not on server) |
| `WE_SetPlayerDataBySteamId( steamid, key, value )` | Write by SteamID |

Examples: key `bestScore` → file key `cust_bestScore`. Passing `cust_bestScore` is left unchanged.

Requires `we_enabled 1` and `we_feature_users 1`.

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

## Related WE helpers (optional)

| Function | Notes |
|----------|--------|
| `WE_SteamId( client )` | SteamID64 string, or "" |
| `WE_StripColors( text )` | Name without color codes |
| `WE_Hooks_Add*` / `WE_Cmds_Add` | For framework features under `src/we/` |

## Files on disk (operators)

```
basewf/warfork-extended/
  banlist.txt
  locks.txt
  users/
    <steamid>.txt    # WE keys + cust_* keys
```
