# Contributing

- Features go in `src/we/` (`core/`, `utils/`, `player/`, `features/`). Do not edit `gamemodes/default/**` for features.
- Host tools: `make`, `zip`, `docker`. Python and Go run in Docker via the Makefile.
- `make test` then `make prod` before a PR. `make test` also packs a prod pk3 and smokes it.
- New engine `GT_*` hook: add it to `ENGINE_HOOKS` and `HOOK_SIGS` in `scripts/inject/constants.py`.
- Release: bump `VERSION` (semver) on `main`. Actions builds the pk3 and `we-report-notify-linux-amd64`.

Command replies: `WE_Reply` + one `Send`. See `.cursor/rules/we-console.mdc` if you use Cursor.
