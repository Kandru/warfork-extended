#!/usr/bin/env python3
"""Fail unless a prod pk3 has the WE layout (no warfork-extended/ under progs/gametypes)."""

from __future__ import annotations

import sys
import zipfile
from pathlib import Path

from inject.constants import MAX_SCRIPT_SECTION, WE_MODULES


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: pk3_smoke.py <pk3>", file=sys.stderr)
        return 2
    pk3 = Path(argv[1])
    if not pk3.is_file():
        print(f"missing pk3: {pk3}", file=sys.stderr)
        return 1

    with zipfile.ZipFile(pk3) as zf:
        names = zf.namelist()

    if "progs/gametypes/we/gen/wrappers.as" not in names:
        print("pk3 missing progs/gametypes/we/gen/wrappers.as", file=sys.stderr)
        return 1
    for n in names:
        norm = n.replace("\\", "/")
        if norm.startswith("progs/gametypes/warfork-extended/") or norm == "progs/gametypes/warfork-extended":
            print(f"pk3 contains forbidden path: {norm}", file=sys.stderr)
            return 1
    for rel in WE_MODULES:
        want = f"progs/gametypes/we/{rel}"
        if want not in names:
            print(f"pk3 missing {want}", file=sys.stderr)
            return 1

    gt_files = [n for n in names if n.startswith("progs/gametypes/") and n.endswith(".gt")]
    if not gt_files:
        print("pk3 has no .gt files", file=sys.stderr)
        return 1

    with zipfile.ZipFile(pk3) as zf:
        for gt in gt_files:
            body = zf.read(gt).decode("utf-8", errors="replace")
            for raw in body.splitlines():
                s = raw.strip()
                if not s.endswith(";"):
                    continue
                inc = s[:-1].strip().lstrip("/")
                if inc.startswith("shared/"):
                    full = f"progs/{inc}"
                else:
                    full = f"progs/gametypes/{inc}"
                if len(full) > MAX_SCRIPT_SECTION:
                    print(f"QPATH too long in {gt}: {full} ({len(full)})", file=sys.stderr)
                    return 1

    print(f"ok {pk3.name} ({len(names)} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
