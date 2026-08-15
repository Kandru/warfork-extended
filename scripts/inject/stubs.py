from __future__ import annotations

from pathlib import Path

from .constants import ENGINE_HOOKS, HOOK_SIGS, WE_GT_DIR, we_include


def stub_orig(name: str) -> str:
    rettype, params, _ = HOOK_SIGS[name]
    if rettype == "Entity @":
        prefix = "Entity @"
    elif rettype == "String @":
        prefix = "String @"
    else:
        prefix = f"{rettype} "

    param_part = params.strip()
    if rettype == "void":
        body = "{\n}"
    elif rettype == "bool":
        body = "{\n    return false;\n}"
    elif rettype == "Entity @":
        body = "{\n    return null;\n}"
    elif rettype == "String @":
        body = '{\n    return "";\n}'
    else:
        body = "{\n}"
    return f"{prefix}{name}__orig({param_part})\n{body}\n"


def write_stubs(progs: Path, per_gt: dict[str, set[str]]) -> dict[str, str]:
    """Per-gametype stubs under gen/. Return include path per stem."""
    gen = progs / "gametypes" / WE_GT_DIR / "gen"
    gen.mkdir(parents=True, exist_ok=True)
    stub_includes: dict[str, str] = {}

    for stem, found in per_gt.items():
        missing = [n for n in ENGINE_HOOKS if n not in found]
        stub_name = f"stubs_{stem}.as"
        stub_path = gen / stub_name
        if missing:
            stub_path.write_text(
                f"// AUTO-GENERATED stubs for {stem}\n\n"
                + "\n".join(stub_orig(n) for n in missing)
                + "\n",
                encoding="utf-8",
            )
        else:
            stub_path.write_text(
                f"// AUTO-GENERATED — {stem} defines all engine hooks\n",
                encoding="utf-8",
            )
        stub_includes[stem] = we_include(f"gen/{stub_name}")
    return stub_includes
