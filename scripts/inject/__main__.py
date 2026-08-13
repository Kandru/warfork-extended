from __future__ import annotations

import argparse
from pathlib import Path

from .pipeline import run, run_custom


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Inject warfork-extended into gametypes")
    ap.add_argument("--mode", choices=("debug", "prod"), required=True)
    ap.add_argument("--root", type=Path, required=True, help="warfork-extended repo root")
    ap.add_argument("--out", type=Path, required=True, help="build output directory")
    ap.add_argument(
        "--custom-root",
        type=Path,
        default=None,
        help="Custom GT repo root containing progs/gametypes/ "
        "(with --include-custom: overlay into WE pk3; alone: thin custom pk3)",
    )
    ap.add_argument(
        "--include-custom",
        action="store_true",
        help="Overlay custom GTs into the default WE pk3 "
        "(from --custom-root or gamemodes/custom/)",
    )
    args = ap.parse_args(argv)

    if args.custom_root is not None and not args.include_custom:
        return run_custom(
            mode=args.mode,
            root=args.root,
            custom_root=args.custom_root,
            out=args.out,
        )

    return run(
        mode=args.mode,
        root=args.root,
        out=args.out,
        include_custom=args.include_custom,
        custom_root=args.custom_root,
    )
