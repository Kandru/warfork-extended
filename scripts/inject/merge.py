from __future__ import annotations

import re
import shutil
from pathlib import Path

from .constants import SKIP_NAMES

INCLUDE_RE = re.compile(r"^\s*([^;]+?)\s*;\s*$")


def read_version(root: Path) -> str:
    return (root / "VERSION").read_text(encoding="utf-8").strip()


def copy_tree(src: Path, dst: Path) -> None:
    if not src.is_dir():
        return
    for path in src.rglob("*"):
        if path.is_dir() or path.name in SKIP_NAMES:
            continue
        target = dst / path.relative_to(src)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)


def merge_sources(root: Path, out: Path) -> Path:
    """Copy default then overlay custom into out/progs."""
    progs = out / "progs"
    if out.exists():
        shutil.rmtree(out)
    progs.mkdir(parents=True)

    default_progs = root / "gamemodes" / "default" / "progs"
    if not default_progs.is_dir():
        raise SystemExit(f"missing {default_progs}")

    copy_tree(default_progs, progs)
    copy_tree(root / "gamemodes" / "custom" / "progs", progs)
    return progs


def parse_gt_includes(gt_path: Path) -> list[str]:
    lines: list[str] = []
    for raw in gt_path.read_text(encoding="utf-8", errors="replace").splitlines():
        s = raw.strip()
        if not s or s.startswith("//"):
            continue
        m = INCLUDE_RE.match(s)
        if m is None:
            continue
        lines.append(m.group(1).strip())
    return lines


def resolve_as_path(gt_dir: Path, include: str) -> Path | None:
    if not include.endswith(".as"):
        return None
    inc = include.lstrip("/")
    progs = gt_dir.parent
    cand = (progs / inc) if inc.startswith("shared/") else (gt_dir / inc)
    return cand if cand.is_file() else None


def is_under(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False
