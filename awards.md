# Awards reference

Custom awards are defined in `basewf/warfork-extended/awards.txt` (seeded from [`configs/awards.txt.example`](configs/awards.txt.example) on first run). Loaded once per gametype init / map change. Persistent counts live on the user file as `award_<id>`.

Source: [`src/we/features/awards/awards.as`](src/we/features/awards/awards.as). Cap: **32** awards.

## Catalog format

```
id|enabled|kind|freq|p1|p2|title|description
```

| Field | Rules |
|-------|--------|
| `id` | `[0-9a-z_]`, unique; storage key suffix |
| `enabled` | Only `1` is loaded |
| `kind` | Trigger type (below) |
| `freq` | Grant frequency (below) |
| `p1` | Threshold (count, damage, speed, seconds — kind-specific) |
| `p2` | Filter tag or secondary param (`0` = any / unused where allowed). Accepts **numeric tag** or **name** |
| `title` | Display name (defaults to `id`) |
| `description` | Stored; not shown by `we_awards` today |

Legacy 7-field lines (no `freq`; 4th field empty or numeric) still load as `freq=every`.

`we_awardGive` **bypasses** frequency. Auto-grants use `TryGrant` (respects `freq`).

### Frequency

| `freq` | Meaning |
|--------|---------|
| `every` | Grant whenever the trigger fires (after the kind’s own re-arm / counter reset) |
| `map` | At most once per gametype init / map (in-memory mask by steam_id; survives reconnect) |
| `round` | At most once per **match playtime** (cleared when playtime starts). CA/bomb intra-match rounds share one playtime → once per match there |
| `once` | Lifetime — skip if `award_<id>` already &gt; 0 on the user file |

Duration parameters (`spec_time`, `stillness`, `alive_time`, `fast_death`, `kill_then_die`, `ping_high` duration) are **seconds**.

---

## Kinds

### Session / time / ping

| kind | p1 | p2 | Source | Notes |
|------|----|----|--------|-------|
| `ping_high` | ping threshold | seconds (`0` = spike) | Think ~500ms | Spike: grant once when ping exceeds p1, re-arm when below. Duration: held above p1 for p2 seconds |
| `spec_time` | seconds | unused | Think | Spectating for ≥ p1 seconds |
| `stillness` | seconds | unused | Think | Alive, origin unchanged ≥ p1 seconds |
| `alive_time` | seconds | unused | Think + respawn | Alive (not spec/ghost) for p1 seconds since last spawn; once per spawn for the trigger |
| `manual` | unused | unused | never auto | Only `we_awardGive` |

### Kill / death

| kind | p1 | p2 | Source | Notes |
|------|----|----|--------|-------|
| `victim_streak` | streak | unused | `kill` | Same attacker killed you exactly p1 times in a row |
| `revenge` | min death streak | unused | `kill` | You kill your last killer after ≥ p1 consecutive deaths to them |
| `suicide` | streak | unused | `kill` | Self-kills ≥ p1, then streak resets |
| `fast_death` | seconds | unused | `kill` | Died within p1 seconds of spawn |
| `kill_then_die` | seconds | unused | `kill` | Had a kill, then died within p1 seconds |
| `kill_streak` | consecutive frags | unused | `kill` | Attacker frags without dying; exact threshold |
| `first_blood` | unused | unused | `kill` | First non-suicide kill of this playtime |
| `frags` | frag count | unused | `kill` | Non-suicide kills this playtime; exact threshold |
| `speed_kill` | min horizontal speed | `WEAP_*` or `0` | `kill` | Attacker XY speed ≥ p1 (Meep Meep-style); optional weapon filter |
| `weapon_kill` | kill count | `WEAP_*` **required** | `kill` | Non-suicide kills while attacker’s current weapon is p2 |
| `weapon_death` | death count | attacker `WEAP_*` **required** | `kill` | Deaths to an attacker whose current weapon is p2 |

### Damage / hits

| kind | p1 | p2 | Source | Notes |
|------|----|----|--------|-------|
| `dmg_dealt` | damage sum | `WEAP_*` or `0` | `dmg` | Accumulated damage dealt (not self); optional weapon filter |
| `dmg_taken` | damage sum | attacker `WEAP_*` or `0` | `dmg` | Accumulated damage taken; optional attacker-weapon filter |
| `weapon_hit` | hit events | `WEAP_*` **required** | `dmg` | +1 per damage event from that weapon (not self) |

### Shots / accuracy (Stats)

| kind | p1 | p2 | Source | Notes |
|------|----|----|--------|-------|
| `shots` | shot count | `AMMO_*` **required** | Think ~500ms | Delta of `stats.accuracyShots(ammo)` |
| `hits` | hit count | `AMMO_*` **required** | Think ~500ms | Delta of `stats.accuracyHits(ammo)` |

Ammo tags are **strong or weak separately** (`rockets` vs `weak_rockets`). There is no automatic “both”.

### Input

| kind | p1 | p2 | Source | Notes |
|------|----|----|--------|-------|
| `key_press` | press count | `KEYICON_*` **required** | Think **every frame** | Rising edge on `client.pressedKeys` |

---

## Filter tags (`p2`)

Numeric tags and common names both work. Invalid / missing **required** filters skip the catalog line.

### Weapons (`WEAP_*`)

| Tag | Names (examples) |
|-----|------------------|
| `1` | `gunblade`, `gb` |
| `2` | `machinegun`, `mg` |
| `3` | `riotgun`, `rg` |
| `4` | `grenadelauncher`, `gl` |
| `5` | `rocketlauncher`, `rocket`, `rl` |
| `6` | `plasmagun`, `plasma`, `pg` |
| `7` | `lasergun`, `laser`, `lg` |
| `8` | `electrobolt`, `eb` |
| `9` | `instagun`, `insta` |

Unique item name / shortName / classname fragments also resolve (same idea as `we_weaponGive`).

### Ammo (`AMMO_*`) — for `shots` / `hits`

| Tag | Names (examples) |
|-----|------------------|
| `10` | `gunblade`, `gb` |
| `11` | `bullets`, `bullet`, `machinegun`, `mg` |
| `12` | `shells`, `shell`, `riotgun`, `rg` |
| `13` | `grenades`, `grenade`, `grenadelauncher`, `gl` |
| `14` | `rockets`, `rocket`, `rocketlauncher`, `rl` |
| `15` | `plasma`, `plasmagun`, `pg` |
| `16` | `lasers`, `laser`, `lasergun`, `lg` |
| `17` | `bolts`, `bolt`, `electrobolt`, `eb` |
| `18` | `instas`, `insta`, `instagun` |
| `19`–`27` | `weak_gunblade`, `weak_bullets`, `weak_shells`, `weak_grenades`, `weak_rockets`, `weak_plasma`, `weak_lasers`, `weak_bolts`, `weak_instas` |

### Keys (`KEYICON_*`) — for `key_press`

| Tag | Names |
|-----|--------|
| `0` | `forward` |
| `1` | `backward`, `back` |
| `2` | `left` |
| `3` | `right` |
| `4` | `fire`, `attack` |
| `5` | `jump`, `space` |
| `6` | `crouch`, `duck` |
| `7` | `special` |

---

## Attribution caveats

- Kill / hit / damage weapon filters use **`client.weapon` at event time** (same approach as stock HUD awards). Delayed splash, mid-flight rockets, or weapon switches can mismatch the true means of death. The engine score event does **not** expose `MOD_*`.
- `shots` / `hits` use engine accuracy counters for the chosen **ammo** tag — accurate for that ammo, not “weapon held”.
- Self-damage does not count toward `dmg_dealt` / `weapon_hit`.

---

## Unsupported (not portable score events)

These are **not** award kinds (GT scripts handle them locally; WE cannot see them as generic events):

- Bomb plant / defuse
- Flag capture / steal / return
- Race sector / finish times
- Exact means-of-death (`MOD_*`)
- Inventory pickup of a specific item (no generic score event)

---

## Performance

Evaluation is **bucketed** — empty buckets cost almost nothing:

| Bucket | When it runs |
|--------|----------------|
| `kill` | Only on `"kill"` if any kill-kind award is loaded |
| `dmg` | Only on `"dmg"` if any dmg/hit award is loaded |
| `keys` | Every Think frame **only if** a `key_press` award is loaded |
| ping / spec / still / alive / stats | Think throttled to ~500ms, skipped if those buckets are empty |

Do not load unused `key_press` awards on busy servers if you want to avoid per-frame key polling.

---

## Commands

| Command | Who | Effect |
|---------|-----|--------|
| `we_awards` | everyone | List your `award_*` counts |
| `we_awardGive <userid> <id>` | operator | Grant (ignores freq) |
| `we_awardRemove <userid> <id>` | operator | Decrement one / delete at 0 |

| Cvar | Default | Effect |
|------|---------|--------|
| `we_feature_awards` | `1` | Master awards feature toggle |
| `we_awards_center_message` | `1` | Show grant on the HUD award position (`client.addAward`) |
| `we_awards_chat_message` | `1` | Chat announce: recipient gets `[WE]` + award text; others get `[WE] <name> got the award: <title>` |

---

## Example lines

```
rocket_man|1|weapon_kill|round|3|rocketlauncher|Rocket Man|3 kills with the rocket launcher
bunny|1|key_press|round|1000|jump|Bunny|Pressed jump 1000 times
bullet_sponge|1|dmg_taken|map|500|0|Bullet Sponge|Took 500 damage
spray|1|shots|round|100|bullets|Spray and Pray|Fired 100 machinegun bullets
meep|1|speed_kill|every|750|0|Meep Meep|Frag while moving ≥ 750 ups
gb_hits|1|weapon_hit|round|50|gunblade|Blade Runner|50 gunblade damage events
```

See also [`configs/awards.txt.example`](configs/awards.txt.example).
