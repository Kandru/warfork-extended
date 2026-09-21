from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from inject.constants import MAX_SCRIPT_SECTION  # noqa: E402
from inject.pipeline import run, run_custom  # noqa: E402
from inject.prefix import _we_name  # noqa: E402
from inject.rename import rename_hook_definitions  # noqa: E402
from inject.sources import assert_script_section_paths, script_section_path  # noqa: E402
from inject.stubs import stub_orig  # noqa: E402
from inject.wrappers import generate_wrappers  # noqa: E402


class TestRename(unittest.TestCase):
    def test_renames_engine_hooks_only(self):
        src = (
            "void GT_InitGametype()\n{\n}\n"
            "void GT_updateScore()\n{\n}\n"
            "bool GT_Command( Client @c, const String &a, const String &b, int n )\n"
            "{\n    return false;\n}\n"
        )
        found: set[str] = set()
        out = rename_hook_definitions(src, found)
        self.assertIn("GT_InitGametype__orig", out)
        self.assertIn("GT_Command__orig", out)
        self.assertIn("void GT_updateScore()", out)
        self.assertNotIn("GT_updateScore__orig", out)
        self.assertEqual(found, {"GT_InitGametype", "GT_Command"})


class TestStubsAndWrappers(unittest.TestCase):
    def test_stub_void_and_bool(self):
        think = stub_orig("GT_ThinkRules")
        self.assertIn("GT_ThinkRules__orig()", think)
        cmd = stub_orig("GT_Command")
        self.assertIn("return false;", cmd)
        self.assertIn("GT_Command__orig(", cmd)

    def test_prod_vs_debug_wrappers(self):
        prod = generate_wrappers("prod", debug=False)
        dbg = generate_wrappers("debug", debug=True)
        self.assertIn("void GT_InitGametype()", prod)
        self.assertIn("WE_Init();", prod)
        self.assertIn("WE_Cmds_Dispatch", prod)
        self.assertIn("WE_Hooks_DispatchThinkAfter", prod)
        self.assertNotIn("WE GT_InitGametype", prod)
        self.assertIn("WE GT_InitGametype", dbg)
        self.assertNotIn("WE GT_ThinkRules", dbg)

    def test_we_name_prefix(self):
        self.assertEqual(_we_name("ffa.as"), "we_ffa.as")
        self.assertEqual(_we_name("we_ffa.as"), "we_ffa.as")


class TestQpath(unittest.TestCase):
    def test_section_path_shared_vs_gt(self):
        self.assertEqual(script_section_path("shared/foo.as"), "progs/shared/foo.as")
        self.assertEqual(script_section_path("we/core/main.as"), "progs/gametypes/we/core/main.as")

    def test_too_long_include_fails(self):
        with tempfile.TemporaryDirectory() as td:
            progs = Path(td) / "progs"
            gt = progs / "gametypes"
            gt.mkdir(parents=True)
            long_inc = "x" * (MAX_SCRIPT_SECTION) + ".as"
            (gt / "x.gt").write_text(f"{long_inc};\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                assert_script_section_paths(progs)


class TestPipeline(unittest.TestCase):
    def test_prod_inject_layout(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td)
            rc = run(mode="prod", root=ROOT, out=out)
            self.assertEqual(rc, 0)
            wrappers = out / "progs/gametypes/we/gen/wrappers.as"
            self.assertTrue(wrappers.is_file())
            self.assertFalse((out / "progs/gametypes/warfork-extended").exists())
            text = wrappers.read_text(encoding="utf-8")
            self.assertIn("WE_Init();", text)
            self.assertTrue(list((out / "progs/gametypes").glob("we_*.gt")))
            ver = (out / "progs/gametypes/we/core/version.as").read_text(encoding="utf-8")
            self.assertIn("WE_VERSION", ver)

    def test_custom_does_not_copy_we_sources(self):
        fixture = ROOT / "tests/fixtures/gt_minimal"
        with tempfile.TemporaryDirectory() as td:
            out = Path(td)
            rc = run_custom(mode="prod", root=ROOT, custom_root=fixture, out=out)
            self.assertEqual(rc, 0)
            we = out / "progs/gametypes/we"
            self.assertFalse((we / "core/main.as").is_file())
            self.assertTrue((we / "gen/wrappers_mini.as").is_file())
            self.assertTrue((out / "progs/gametypes/mini.as").is_file())
            gt = (out / "progs/gametypes/mini.gt").read_text(encoding="utf-8")
            self.assertIn("we/core/main.as", gt)
            self.assertIn("we/gen/wrappers_mini.as", gt)
            self.assertIn("GT_InitGametype__orig", (out / "progs/gametypes/mini.as").read_text())


if __name__ == "__main__":
    unittest.main()
