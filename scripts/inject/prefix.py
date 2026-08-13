"""Prefix default gamemode files with we_ so they do not collide with stock pk3 paths."""

from __future__ import annotations

from pathlib import Path

from .constants import SKIP_NAMES


def _we_name(filename: str) -> str:
    if filename.startswith("we_"):
        return filename
    return f"we_{filename}"


def _progs_rel(path: Path, progs: Path) -> str:
    return path.relative_to(progs).as_posix()


def build_default_prefix_map(progs: Path) -> dict[str, str]:
    """Map old progs-relative paths → we_-prefixed paths for every file under progs."""
    path_map: dict[str, str] = {}
    for path in progs.rglob("*"):
        if path.is_dir() or path.name in SKIP_NAMES:
            continue
        old_rel = _progs_rel(path, progs)
        new_name = _we_name(path.name)
        if new_name == path.name:
            continue
        new_rel = (path.parent.relative_to(progs) / new_name).as_posix()
        path_map[old_rel] = new_rel
    return path_map


def apply_prefix_renames(progs: Path, path_map: dict[str, str]) -> int:
    """Rename files on disk according to path_map. Returns count renamed."""
    # Rename deepest paths first so parent dirs stay stable.
    items = sorted(path_map.items(), key=lambda kv: kv[0].count("/"), reverse=True)
    count = 0
    for old_rel, new_rel in items:
        src = progs / old_rel
        dst = progs / new_rel
        if not src.is_file():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            dst.unlink()
        src.rename(dst)
        count += 1
    return count


def _rewrite_include(include: str, path_map: dict[str, str]) -> str:
    body = include.lstrip("/")
    if body.startswith("shared/"):
        old_key = body
    else:
        old_key = f"gametypes/{body}"

    new_key = path_map.get(old_key)
    if new_key is None:
        return include

    if new_key.startswith("gametypes/"):
        return new_key[len("gametypes/") :]
    # shared/*
    return "/" + new_key


def rewrite_gt_includes_with_map(progs: Path, path_map: dict[str, str]) -> None:
    """Update .gt include lines using an old→new progs-relative path map."""
    if not path_map:
        return
    gametypes = progs / "gametypes"
    for gt_path in sorted(gametypes.glob("*.gt")):
        lines_out: list[str] = []
        for raw in gt_path.read_text(encoding="utf-8", errors="replace").splitlines():
            s = raw.strip()
            if not s or s.startswith("//") or not s.endswith(";"):
                lines_out.append(raw)
                continue
            inc = s[:-1].strip()
            lines_out.append(f"{_rewrite_include(inc, path_map)};")
        gt_path.write_text("\n".join(lines_out) + "\n", encoding="utf-8")


def prefer_existing_we_include(progs: Path, include: str) -> str:
    """If a we_-prefixed sibling file exists, point the include at it."""
    body = include.lstrip("/")
    if body.startswith("shared/"):
        parent, name = body.rsplit("/", 1)
        we = _we_name(name)
        if (progs / parent / we).is_file():
            return f"/{parent}/{we}"
        return include

    parts = body.split("/")
    parts[-1] = _we_name(parts[-1])
    cand = "/".join(parts)
    if (progs / "gametypes" / cand).is_file():
        return cand
    return include


def rewrite_gt_includes_prefer_we(progs: Path) -> None:
    """After custom overlay: retarget includes to we_ files when those exist.

    Custom gametype files keep their own names; only references into renamed
    default assets (shared/, generic/, …) are updated.
    """
    gametypes = progs / "gametypes"
    for gt_path in sorted(gametypes.glob("*.gt")):
        lines_out: list[str] = []
        for raw in gt_path.read_text(encoding="utf-8", errors="replace").splitlines():
            s = raw.strip()
            if not s or s.startswith("//") or not s.endswith(";"):
                lines_out.append(raw)
                continue
            inc = s[:-1].strip()
            # Never rewrite WE framework includes
            if inc.replace("\\", "/").startswith("warfork-extended/"):
                lines_out.append(f"{inc};")
                continue
            lines_out.append(f"{prefer_existing_we_include(progs, inc)};")
        gt_path.write_text("\n".join(lines_out) + "\n", encoding="utf-8")


def prefix_default_sources(progs: Path) -> dict[str, str]:
    """Rename all files currently in progs with we_ prefix; fix .gt includes.

    Call while progs contains only default (before custom overlay).
    """
    path_map = build_default_prefix_map(progs)
    apply_prefix_renames(progs, path_map)
    rewrite_gt_includes_with_map(progs, path_map)
    return path_map
