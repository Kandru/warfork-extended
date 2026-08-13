# warfork-extended

Modular operator framework for [Warfork](https://warfork.com) gameservers. It wraps stock (and your custom) gametype scripts at **build time** to allow additional features to be added. The build produces a pk3 with `we_`-prefixed default gametype files (no collision with stock pk3 paths).

## What it does

- Injects hooks around engine `GT_*` callbacks
- Stores data in `basewf/warfork-extended/*`
- SteamID-based player identity
- Operator tools: kick, ban/unban, give/remove/strip weapons, respawn, change team
- Player reports (`we_report` / `report` → `report.txt`)
- Custom awards (`award_*` counters with every/map/round/once frequency, `we_awards` / `we_awardGive` / `we_awardRemove`)
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
| `we_report <userid> [reason]` | everyone | File a player report (`report` alias; writes `report.txt`; announces in chat). On death, victims see a hint to report the killer. |

- `reason` is optional
- `userid` is a player slot or a unique case-insensitive name fragment (`WE_ClientFromArg` / `WE_FindClient` in `src/we/utils/clients.as`)
- `we_ban` with no/unknown arg lists online players and up to 25 recently disconnected users (IDs **900+**). Targets: player slot, recent id (`900`…), unique name fragment (online or recently disconnected), or unique steam_id fragment; a full steam_id still works for anyone with a user file
- `weaponid` is an item tag, or a unique fragment of the item name / short name
- `team` is a team id (`0`–`3`), or a unique fragment of the team name / defaultName (e.g. `spec`)
- Console chrome colors: `basewf/warfork-extended/theme.txt` (see [`configs/theme.txt.example`](configs/theme.txt.example); seeded on first run)

## Requirements

- Linux
- `python3`, `zip`, `make` (and `mv`/`cp` via coreutils)
- `go` 1.22+ (only to build the optional report webhook notifier)

## Build

```bash
# optional: copy config for make dev install path
cp config.mk.example config.mk
# edit WARFORK_BASEWF=/path/to/basewf

make          # help
make prod     # dist/prod/gt_warfork_extended_<VERSION>.pk3 (stock GTs + WE only)
make dev      # debug inject + copy pk3 into WARFORK_BASEWF
make go       # dist/go/we-report-notify (report Discord webhooks)
make go-install  # install binary + example config to /opt/we-report-notify
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
set we_awards_center_message "1"
set we_awards_chat_message "1"
set we_feature_report "1"
```

Award definitions live in `basewf/warfork-extended/awards.txt` (seeded from defaults on first run; see [`configs/awards.txt.example`](configs/awards.txt.example)). Loaded once per map / gametype init. Counts are stored on the user file as `award_<id>`.

`we_awards_center_message` (default `1`) shows the grant on the HUD award position (`addAward`). `we_awards_chat_message` (default `1`) announces in chat: the recipient sees the same award text prefixed with `[WE]`; everyone else sees `[WE] <name> got the award: <title>`.

Full kind / filter / limitation reference: [`awards.md`](awards.md).

Line format: `id|enabled|kind|freq|p1|p2|title|description`

| `freq` | Meaning |
|--------|---------|
| `every` | Grant whenever the trigger fires (after the kind’s own re-arm) |
| `map` | At most once per gametype init / map |
| `round` | At most once per **match playtime** (reset when playtime starts). CA/bomb intra-match rounds share one playtime, so this is once per match there |
| `once` | Lifetime — skip if `award_<id>` is already &gt; 0 |

`we_awardGive` ignores frequency. All duration parameters are **seconds** (including `fast_death` / `kill_then_die`). If you still have an older seeded `awards.txt`, add the `freq` column and convert former millisecond values (`5000` → `5`, `3000` → `3`).

Player reports append to `basewf/warfork-extended/report.txt` (CSV: unix, reporter steam/name/clan, reported steam/name/clan, score/frags/deaths/suicides, reason). 60s cooldown per reporter.

## Report webhooks

Optional sidecar [`tools/report-notify/`](tools/report-notify/) watches one or more `report.txt` files and posts Discord webhook embeds when players file reports. It is **not** inside the pk3; run it on the host (or any machine that can read the report files).

### Config

Copy [`tools/report-notify/config.yaml.example`](tools/report-notify/config.yaml.example) to `config.yaml` next to the binary (or pass `-config`). Map server display names to paths; set a global webhook list and/or per-server webhooks:

```yaml
webhooks:
  - "https://discord.com/api/webhooks/ID/TOKEN"

poll_interval: 1m

servers:
  eu-dm:
    path: /path/to/basewf/warfork-extended/report.txt
  na-ca:
    path: /path/to/other/basewf/warfork-extended/report.txt
    webhooks:
      - "https://discord.com/api/webhooks/OTHER/TOKEN"
```

If a server has its own `webhooks` list, that list is used instead of the global one. Offset state is stored in `report-notify.state.json` next to the config (first sighting of a file seeks to EOF so history is not flooded).

### Install (cron every minute)

Recommended production setup:

```bash
make go-install                    # PREFIX=/opt/we-report-notify
sudo $EDITOR /opt/we-report-notify/config.yaml
sudo crontab -e                    # paste tools/report-notify/crontab.example
```

Crontab line:

```
* * * * * /opt/we-report-notify/we-report-notify -once
```

`-once` scans, posts any new lines, then exits (safe for cron; no stacked daemons).

Alternatively run long-lived for near-instant pings (`/opt/we-report-notify/we-report-notify`, uses fsnotify with poll fallback). GitHub Releases also ship `we-report-notify-linux-amd64` next to the pk3.

## Extending (features)

Add AngelScript under `src/we/features/<name>/`, then register in that feature's `*_Register()`:

```
WE_Hooks_AddThinkAfter( @My_Think );
WE_Cmds_Add( "we_foo", "<userid>", "Do the foo", @My_Cmd );
```

Call your `*_Register()` from `WE_Init()` in `src/we/core/main.as`. Hook API uses AngelScript `funcdef` handles (`core/hook_types.as`).

Custom gamemodes: persistent player data via `WE_GetPlayerData` / `WE_SetPlayerData` (keys stored as `cust_*`) — see [development.md](development.md).

1. In a **separate** repo, use the stock layout: `progs/gametypes/<name>.gt` + `.as` extras
2. Add this repo as a submodule (or CI checkout), then:
   `make -C path/to/warfork-extended custom CUSTOM_ROOT=$PWD PK3=$PWD/dist/gt_<name>.pk3`
3. Install **both** `gt_warfork_extended_*.pk3` and your custom pk3 into `basewf`, then restart

## Version / releases

- Bump [`VERSION`](VERSION) (semver).
- Pushing a change to `VERSION` on `main` runs GitHub Actions: build prod pk3 + Linux `we-report-notify` binary, then a GitHub Release with both assets and commits since the previous tag.

## Layout

```
gamemodes/default/     # upstream scripts (never edit for WE)
gamemodes/custom/      # optional local overlay (INCLUDE_CUSTOM=1 only)
src/we/                # framework AngelScript (core/, utils/, player/, features/)
scripts/inject/        # Python inject package
scripts/inject.py      # thin CLI entry
tools/report-notify/   # Discord webhook sidecar for report.txt
dist/debug|prod/       # WE pk3 output
dist/go/               # we-report-notify binaries
dist/custom/           # scratch for make custom
```

## License

See [LICENSE](LICENSE).
