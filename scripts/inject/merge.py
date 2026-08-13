from __future__ import annotations

import re
import shutil
from pathlib import Path

from .constants import SKIP_NAMES
from .prefix import prefix_default_sources, rewrite_gt_includes_prefer_we

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


def merge_sources(
    root: Path,
    out: Path,
    *,
    include_custom: bool = False,
    custom_root: Path | None = None,
) -> Path:
    """Copy default, we_-prefix those files; optionally overlay custom (unprefixed).

    Custom overlay is off by default so the WE pk3 stays stock-only. Pass
    include_custom=True (local debug) or a custom_root to merge custom GTs.
    """
    progs = out / "progs"
    if out.exists():
        shutil.rmtree(out)
    progs.mkdir(parents=True)

    default_progs = root / "gamemodes" / "default" / "progs"
    if not default_progs.is_dir():
        raise SystemExit(f"missing {default_progs}")

    copy_tree(default_progs, progs)
    path_map = prefix_default_sources(progs)
    print(f"[inject] prefixed {len(path_map)} default files with we_")

    if include_custom or custom_root is not None:
        overlay = (custom_root or (root / "gamemodes" / "custom")).resolve()
        custom_progs = overlay / "progs"
        if not custom_progs.is_dir():
            raise SystemExit(f"missing custom progs: {custom_progs}")
        copy_tree(custom_progs, progs)
        # Custom .gt may still reference stock paths (shared/, generic/, …)
        rewrite_gt_includes_prefer_we(progs)
        print(f"[inject] overlaid custom from {overlay}")

    return progs


def merge_custom_only(custom_root: Path, out: Path) -> Path:
    """Copy only a custom GT tree into out/progs (no default, no WE sources)."""
    overlay = custom_root.resolve()
    custom_progs = overlay / "progs"
    if not custom_progs.is_dir():
        raise SystemExit(
            f"CUSTOM_ROOT must contain progs/gametypes/: missing {custom_progs}"
        )

    progs = out / "progs"
    if out.exists():
        shutil.rmtree(out)
    progs.mkdir(parents=True)

    copy_tree(custom_progs, progs)
    gt_dir = progs / "gametypes"
    if not gt_dir.is_dir() or not any(gt_dir.glob("*.gt")):
        raise SystemExit(f"no .gt files under {gt_dir}")

    # Retarget shared/generic includes to we_* names expected from the WE pk3 VFS.
    rewrite_gt_includes_prefer_we(progs, assume_we=True)
    print(f"[inject] custom-only from {overlay}")
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
