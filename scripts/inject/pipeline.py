from __future__ import annotations

from pathlib import Path

from .constants import ENGINE_HOOKS
from .merge import merge_sources, read_version
from .rename import inject_as_files
from .sources import copy_we_sources, patch_gt_files
from .stubs import write_stubs
from .wrappers import generate_wrappers


def run(*, mode: str, root: Path, out: Path) -> int:
    root = root.resolve()
    out = out.resolve()
    version = read_version(root)
    debug = mode == "debug"

    print(f"[inject] mode={mode} version={version}")
    print(f"[inject] out={out}")

    progs = merge_sources(root, out)
    per_gt = inject_as_files(progs)
    copy_we_sources(root, progs, version)
    stub_includes = write_stubs(progs, per_gt)

    wrappers = generate_wrappers(mode, debug=debug)
    gen = progs / "gametypes" / "warfork-extended" / "gen"
    gen.mkdir(parents=True, exist_ok=True)
    (gen / "wrappers.as").write_text(wrappers, encoding="utf-8")
    patch_gt_files(progs, stub_includes)

    for stem, found in sorted(per_gt.items()):
        missing = [n for n in ENGINE_HOOKS if n not in found]
        if missing:
            print(f"[inject] {stem}: stubs for {', '.join(missing)}")

    print(f"[inject] gametypes: {len(per_gt)}")
    print("[inject] done")
    return 0
