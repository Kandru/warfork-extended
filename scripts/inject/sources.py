from __future__ import annotations

import shutil
from pathlib import Path

from .constants import WE_MODULES
from .merge import parse_gt_includes


def copy_we_sources(root: Path, progs: Path, version: str) -> None:
    src = root / "src" / "we"
    dst = progs / "gametypes" / "warfork-extended"
    dst.mkdir(parents=True, exist_ok=True)

    if src.is_dir():
        for path in src.rglob("*.as"):
            if path.name == "version.as":
                continue
            rel = path.relative_to(src)
            target = dst / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)

    version_path = dst / "core" / "version.as"
    version_path.parent.mkdir(parents=True, exist_ok=True)
    version_path.write_text(
        f'// AUTO-GENERATED from VERSION\nconst String WE_VERSION = "{version}";\n',
        encoding="utf-8",
    )


def patch_gt_files(progs: Path, stub_includes: dict[str, str]) -> None:
    gametypes = progs / "gametypes"
    we_includes = [f"warfork-extended/{m}" for m in WE_MODULES]
    wrapper = "warfork-extended/gen/wrappers.as"

    for gt_path in sorted(gametypes.glob("*.gt")):
        includes = [
            i
            for i in parse_gt_includes(gt_path)
            if not i.replace("\\", "/").startswith("warfork-extended/")
        ]
        shared = [i for i in includes if i.lstrip("/").startswith("shared/")]
        rest = [i for i in includes if not i.lstrip("/").startswith("shared/")]
        stub = stub_includes.get(gt_path.stem, "warfork-extended/gen/stubs_ffa.as")
        new_list = shared + [stub] + we_includes + rest + [wrapper]
        gt_path.write_text("\n".join(f"{inc};" for inc in new_list) + "\n", encoding="utf-8")
