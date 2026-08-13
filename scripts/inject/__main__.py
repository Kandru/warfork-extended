from __future__ import annotations

import argparse
from pathlib import Path

from .pipeline import run


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Inject warfork-extended into gametypes")
    ap.add_argument("--mode", choices=("debug", "prod"), required=True)
    ap.add_argument("--root", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args(argv)
    return run(mode=args.mode, root=args.root, out=args.out)
