# warfork-extended

Modular operator framework for [Warfork](https://warfork.com) gameservers. It wraps stock (and your custom) gametype scripts at **build time** to allow additional features to be added. The build produces a pk3 with `we_`-prefixed default gametype files (no collision with stock pk3 paths).

## What it does

- Injects hooks around engine `GT_*` callbacks
- Stores data in `basewf/warfork-extended/*`
- SteamID-based player identity
- Operator tools: kick, ban/unban, give/remove/strip weapons, respawn, change team
- Custom awards (`award_*` counters, `we_awards` / `we_awardGive` / `we_awardRemove`)
- Per-player key/value files with userinfo snapshot + `last_connected` / `last_disconnected`

## Features (out of the box)

| Command | Who | Description |
|---------|-----|-------------|
| `we_help` | everyone | List commands |
| `we_users` | operator | List connected players + steam_id |
| `we_kick <userid> [reason]` | operator | Kick a player (list if no arg) |
| `we_ban <userid|name|steam_id> [reason]` | operator | Ban player (list if no arg) |
| `we_unban [index]` | operator | Unban player (list if no arg) |
| `we_weaponGive <userid> <weaponid>` | operator | Give an item (id or unique name fragment) |
| `we_weaponRemove <userid> <weaponid>` | operator | Remove an item (id or unique name fragment) |
| `we_weaponStrip <userid>` | operator | Remove all weapons and ammo |
| `we_respawn <userid>` | operator | Force-respawn a player (list if no arg) |
| `we_changeteam <userid> <team>` | operator | Move player to a team (id or name fragment) |
| `we_awards` | everyone | List your earned awards |
| `we_awardGive <userid> <award_id>` | operator | Grant a catalog award |
| `we_awardRemove <userid> <award_id>` | operator | Remove one count of a catalog award |

- `reason` is optional
- `userid` is a player slot or a unique case-insensitive name fragment (`WE_ClientFromArg` / `WE_FindClient` in `src/we/utils/clients.as`)
- `we_ban` with no/unknown arg lists online players and up to 25 recently disconnected users (human UTC time). Targets: player slot, unique name fragment (online or recently disconnected), or unique steam_id fragment; a full steam_id still works for anyone with a user file
- `weaponid` is an item tag, or a unique fragment of the item name / short name
- `team` is a team id (`0`–`3`), or a unique fragment of the team name / defaultName (e.g. `spec`)

## Requirements

- Linux
- `python3`, `zip`, `make` (and `mv`/`cp` via coreutils)

## Build

```bash
# optional: copy config for make dev install path
cp config.mk.example config.mk
# edit WARFORK_BASEWF=/path/to/basewf

make          # help
make prod     # dist/prod/gt_warfork_extended_<VERSION>.pk3 (stock GTs + WE only)
make dev      # debug inject + copy pk3 into WARFORK_BASEWF
```

Drop the pk3 into your server `basewf` folder (remove older `gt_warfork_extended_*.pk3` first if not using `make dev`).

### Custom gametypes (separate pk3)

Custom GTs live in **their own repos** and ship as a **thin pk3** that still needs this WE pk3 on the server (AngelScript includes resolve via the VFS). Build from this repo:

```bash
make custom CUSTOM_ROOT=/path/to/my-gt-repo PK3=/path/to/gt_mygt.pk3
# optional: MODE=debug
```

`CUSTOM_ROOT` must contain `progs/gametypes/<name>.gt` (+ `.as` extras). Filenames stay unprefixed. Put both pk3s in `basewf`.

Rebuild the custom pk3 when you bump WE if inject hooks / include order change. Feature-only WE updates that keep the same paths usually do not need a custom rebuild.

Local one-pk3 debug (overlay into the WE zip): `make prod INCLUDE_CUSTOM=1` (uses `gamemodes/custom/`, or `CUSTOM_ROOT=…`).
## Server config

Paste cvars into your `server.cfg` (see [`configs/warfork-extended.cfg.example`](configs/warfork-extended.cfg.example)). Warfork-Extended does not create a configuration file on its own:

```
set we_enabled "1"
set we_debug "0"
set we_feature_ban "1"
set we_feature_weapon "1"
set we_feature_respawn "1"
set we_feature_changeteam "1"
set we_feature_awards "1"
```

Award definitions live in `basewf/warfork-extended/awards.txt` (seeded from defaults on first run; see [`configs/awards.txt.example`](configs/awards.txt.example)). Loaded once per map / gametype init. Counts are stored on the user file as `award_<id>`.

## Extending (features)

Add AngelScript under `src/we/features/<name>/`, then register in that feature's `*_Register()`:

```
WE_Hooks_AddThinkAfter( @My_Think );
WE_Cmds_Add( "we_foo", @My_Cmd );
```

Call your `*_Register()` from `WE_Init()` in `src/we/core/main.as`. Hook API uses AngelScript `funcdef` handles (`core/hook_types.as`).

Custom gamemodes: persistent player data via `WE_GetPlayerData` / `WE_SetPlayerData` (keys stored as `cust_*`) — see [development.md](development.md).

1. In a **separate** repo, use the stock layout: `progs/gametypes/<name>.gt` + `.as` extras
2. Add this repo as a submodule (or CI checkout), then:
   `make -C path/to/warfork-extended custom CUSTOM_ROOT=$PWD PK3=$PWD/dist/gt_<name>.pk3`
3. Install **both** `gt_warfork_extended_*.pk3` and your custom pk3 into `basewf`, then restart

## Version / releases

- Bump [`VERSION`](VERSION) (semver).
- Pushing a change to `VERSION` on `main` runs GitHub Actions: build prod pk3 + GitHub Release with commits since the previous tag.

## Layout

```
gamemodes/default/     # upstream scripts (never edit for WE)
gamemodes/custom/      # optional local overlay (INCLUDE_CUSTOM=1 only)
src/we/                # framework AngelScript (core/, utils/, player/, features/)
scripts/inject/        # Python inject package
scripts/inject.py      # thin CLI entry
dist/debug|prod/       # WE pk3 output
dist/custom/           # scratch for make custom
```

## License

See [LICENSE](LICENSE).
