from __future__ import annotations

import re
from pathlib import Path

from .constants import ENGINE_HOOKS
from .merge import is_under, parse_gt_includes, resolve_as_path


def rename_hook_definitions(text: str, hooks_found: set[str]) -> str:
    for name in ENGINE_HOOKS:
        pattern = re.compile(
            rf"^([ \t]*(?:bool|void|Entity\s+@|String\s+@)\s*)({re.escape(name)})(\s*\()",
            re.MULTILINE,
        )

        def repl(m: re.Match[str], n: str = name) -> str:
            hooks_found.add(n)
            return f"{m.group(1)}{n}__orig{m.group(3)}"

        text = pattern.sub(repl, text)
    return text


def hooks_in_text(text: str) -> set[str]:
    found: set[str] = set()
    for name in ENGINE_HOOKS:
        if f"{name}__orig(" in text or f"{name}__orig (" in text:
            found.add(name)
    return found


def inject_as_files(progs: Path) -> dict[str, set[str]]:
    """Rename GT_* defs. Return hooks found per .gt stem."""
    gametypes = progs / "gametypes"
    we_dir = gametypes / "warfork-extended"

    for as_path in gametypes.rglob("*.as"):
        if is_under(as_path, we_dir):
            continue
        original = as_path.read_text(encoding="utf-8", errors="replace")
        found: set[str] = set()
        updated = rename_hook_definitions(original, found)
        if updated != original:
            as_path.write_text(updated, encoding="utf-8")

    per_gt: dict[str, set[str]] = {}
    for gt_path in sorted(gametypes.glob("*.gt")):
        found: set[str] = set()
        for inc in parse_gt_includes(gt_path):
            as_path = resolve_as_path(gametypes, inc)
            if as_path is None or is_under(as_path, we_dir):
                continue
            found |= hooks_in_text(as_path.read_text(encoding="utf-8", errors="replace"))
        per_gt[gt_path.stem] = found
    return per_gt
