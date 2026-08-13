# warfork-extended

Modular operator framework for [Warfork](https://warfork.com) gameservers. It wraps stock (and your custom) gametype scripts at **build time** to allow additional features to be added. The build produces a pk3 that overrides `progs/gametypes/*` when placed in `basewf`.

## What it does

- Injects hooks around engine `GT_*` callbacks
- Stores data in `basewf/warfork-extended/*`
- SteamID-based player identity
- Operator tools: kick, ban/unban
- Per-player key/value files with userinfo snapshot + `last_connected`

## Features (out of the box)

| Command | Who | Description |
|---------|-----|-------------|
| `we_help` | everyone | List commands |
| `we_users` | everyone | List connected players + steam_id |
| `we_kick <playerNum> [reason]` | operator | Kick a player |
| `we_ban <playerNum> [reason]` | operator | Ban by steam_id + kick |
| `we_unban [index]` | operator | List bans / remove by index |

## Requirements

- Linux
- `python3`, `zip`, `make` (and `mv`/`cp` via coreutils)

## Build

```bash
# optional: copy config for make dev install path
cp config.mk.example config.mk
# edit WARFORK_BASEWF=/path/to/basewf

make          # help
make prod     # dist/prod/gt_warfork_extended_<VERSION>.pk3
make dev      # debug inject + copy pk3 into WARFORK_BASEWF
```

Drop the pk3 into your server `basewf` folder (remove older `gt_warfork_extended_*.pk3` first if not using `make dev`).

## Server config

Paste cvars into your `server.cfg` (see [`configs/warfork-extended.cfg.example`](configs/warfork-extended.cfg.example)). Warfork-Extended does not create a configuration file on its own:

```
set we_enabled "1"
set we_debug "0"
set we_feature_users "1"
set we_feature_ban "1"
```

## Extending (features)

Add AngelScript under `src/we/features/<name>/`, then register in that feature's `*_Register()`:

```
WE_Hooks_AddThinkAfter( @My_Think );
WE_Cmds_Add( "we_foo", @My_Cmd );
```

Call your `*_Register()` from `WE_Init()` in `src/we/core/main.as`. Hook API uses AngelScript `funcdef` handles (`core/hook_types.as`).

1. Create the same layout as stock:
   `gamemodes/custom/progs/gametypes/<name>.gt`  
   `gamemodes/custom/progs/gametypes/<name>.as` (and extras)
2. Run `make prod` or `make dev`. The injector renames engine `GT_*` entry points to `GT_*__orig` and wraps them
3. Upload to your Warfork server and restart

## Version / releases

- Bump [`VERSION`](VERSION) (semver).
- Pushing a change to `VERSION` on `main` runs GitHub Actions: build prod pk3 + GitHub Release with commits since the previous tag.

## Layout

```
gamemodes/default/     # upstream scripts (never edit for WE)
gamemodes/custom/      # your gametypes (local)
src/we/                # framework AngelScript (core/, utils/, player/, features/)
scripts/inject/        # Python inject package
scripts/inject.py      # thin CLI entry
dist/debug|prod/       # build output + pk3
```

## License

See [LICENSE](LICENSE).
