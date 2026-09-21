"""Python 1:1 of tiny WE AngelScript helpers. Keep in lockstep with src/we/."""

from __future__ import annotations

STEAM_ID_LEN = 17
LOCK_TTL_SEC = 1
LOCK_FUTURE_SKEW_SEC = 2

_FIELD_STRIP = set(",\n\r\t")
_IDENT_CHARS = set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-")
_REASON_CHARS = set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ")


def we_valid_steam_id(steamid: str) -> bool:
    return len(steamid) == STEAM_ID_LEN and steamid.isdigit()


def we_sanitize_field(text: str) -> str:
    return "".join(" " if c in _FIELD_STRIP else c for c in text)


def we_sanitize_key(text: str) -> str:
    return "".join(c for c in text if c in _IDENT_CHARS)


def we_sanitize_reason(text: str) -> str:
    return "".join(c for c in text if c in _REASON_CHARS)


def we_is_ident_name(name: str) -> bool:
    return len(name) > 0 and all(c in _IDENT_CHARS for c in name)


def we_kv_file_name(name: str) -> str:
    n = name
    if len(n) >= 4 and n[-4:].lower() == ".txt":
        n = n[:-4]
    if not we_is_ident_name(n):
        return ""
    return n


def we_player_data_key(key: str) -> str:
    k = we_sanitize_key(key)
    if not k:
        return ""
    if k.startswith("cust_"):
        return k
    return "cust_" + k


def we_next_line(data: str, pos: int) -> tuple[bool, str, int]:
    if pos > len(data):
        return False, "", pos
    line = []
    while pos < len(data):
        ch = data[pos]
        pos += 1
        if ch in "\n\r":
            return True, "".join(line), pos
        line.append(ch)
    return True, "".join(line), len(data) + 1


def we_split_key_value(line: str) -> tuple[str, str] | None:
    for j, ch in enumerate(line):
        if ch != "=":
            continue
        if j == 0:
            return None
        return line[:j], line[j + 1 :]
    return None


def we_kv_get(data: str, key: str) -> str:
    pos = 0
    while True:
        ok, line, pos = we_next_line(data, pos)
        if not ok:
            return ""
        if not line:
            continue
        kv = we_split_key_value(line)
        if kv is None:
            continue
        k, v = kv
        if k == key:
            return v


def we_kv_set(data: str, key: str, value: str) -> str:
    result = []
    replaced = False
    pos = 0
    while True:
        ok, line, pos = we_next_line(data, pos)
        if not ok:
            break
        if not line:
            continue
        kv = we_split_key_value(line)
        if kv is not None and kv[0] == key:
            result.append(f"{key}={value}\n")
            replaced = True
        else:
            result.append(line + "\n")
    if not replaced:
        result.append(f"{key}={value}\n")
    return "".join(result)


def we_locks_parse_value(value: str) -> tuple[int, str]:
    v = value.strip()
    at = v.find("@")
    if at <= 0:
        return 0, ""
    sec = v[:at]
    owner = v[at + 1 :]
    if not sec or not sec.isdigit():
        return 0, ""
    return int(sec), owner


def we_locks_is_active(locked_at: int, now_sec: int) -> bool:
    if locked_at == 0:
        return False
    if now_sec < locked_at:
        if (locked_at - now_sec) > LOCK_FUTURE_SKEW_SEC:
            return False
        return True
    return (now_sec - locked_at) < LOCK_TTL_SEC


def we_ban_looks_like_kv_garbage(line: str) -> bool:
    for ch in line:
        if ch == "=":
            return True
        if ch == ",":
            return False
    return False


def we_ban_parse_line(line: str) -> list[str] | None:
    if not line:
        return None
    if we_ban_looks_like_kv_garbage(line):
        return None
    fields = [part.strip() for part in line.split(",")]
    while len(fields) < 7:
        fields.append("")
    fields = fields[:7]
    if not we_valid_steam_id(fields[1]):
        return None
    return fields
