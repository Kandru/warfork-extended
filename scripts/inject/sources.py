from __future__ import annotations

import shutil
from pathlib import Path

from .constants import MAX_SCRIPT_SECTION, WE_GT_DIR, WE_MODULES, is_we_include, we_include
from .merge import parse_gt_includes


def copy_we_sources(root: Path, progs: Path, version: str) -> None:
    src = root / "src" / "we"
    dst = progs / "gametypes" / WE_GT_DIR
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


def script_section_path(include: str) -> str:
    body = include.replace("\\", "/").lstrip("/")
    if body.startswith("shared/"):
        return f"progs/{body}"
    return f"progs/gametypes/{body}"


def assert_script_section_paths(progs: Path) -> None:
    """Fail inject if any .gt include exceeds the engine QPATH (63 chars)."""
    too_long: list[str] = []
    for gt_path in sorted((progs / "gametypes").glob("*.gt")):
        for inc in parse_gt_includes(gt_path):
            full = script_section_path(inc)
            if len(full) > MAX_SCRIPT_SECTION:
                too_long.append(f"  {gt_path.name}: {full} ({len(full)})")
    if too_long:
        raise SystemExit(
            f"script section path exceeds {MAX_SCRIPT_SECTION} chars "
            f"(engine truncates .as):\n" + "\n".join(too_long)
        )


def patch_gt_files(
    progs: Path,
    stub_includes: dict[str, str],
    *,
    wrapper_includes: dict[str, str] | None = None,
    default_wrapper: str | None = None,
) -> None:
    if default_wrapper is None:
        default_wrapper = we_include("gen/wrappers.as")
    gametypes = progs / "gametypes"
    we_includes = [we_include(m) for m in WE_MODULES]

    for gt_path in sorted(gametypes.glob("*.gt")):
        includes = [i for i in parse_gt_includes(gt_path) if not is_we_include(i)]
        shared = [i for i in includes if i.lstrip("/").startswith("shared/")]
        rest = [i for i in includes if not i.lstrip("/").startswith("shared/")]
        stub = stub_includes.get(gt_path.stem, we_include("gen/stubs_we_ffa.as"))
        if wrapper_includes is not None:
            wrapper = wrapper_includes.get(gt_path.stem, default_wrapper)
        else:
            wrapper = default_wrapper
        new_list = shared + [stub] + we_includes + rest + [wrapper]
        gt_path.write_text("\n".join(f"{inc};" for inc in new_list) + "\n", encoding="utf-8")

    assert_script_section_paths(progs)
