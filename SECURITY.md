# Security

## Reporting

Privately report vulnerabilities via GitHub Security Advisories on this repository. Do not open a public issue for a still-unpatched path, auth, or file-write bug.

## Operator model

A client is an operator if they used the engine `op <password>` command **or** their SteamID64 is listed in `we_operators`. Treat `op` password and webhook URLs as secrets. `we_operators` is a server cvar (not userinfo).

Identity on disk is **SteamID64 only** (17 digits). Anything else is ignored for user files, bans, reports, locks, and the operator list.

## Files

Runtime data is `basewf/warfork-extended/` (not the pk3). Writes use short-TTL soft locks. Run **one** Warfork process per `basewf` if you care about ban/report consistency. Sharing that directory across servers is best-effort only.

Do not commit `tools/report-notify/config.yaml` (Discord webhook URLs). Use the example file.

`we-report-notify self-update` pulls GitHub Release assets from `kandru/warfork-extended`.
