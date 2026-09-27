from __future__ import annotations

import unittest

from spec import (
    we_ban_parse_line,
    we_is_ident_name,
    we_kv_file_name,
    we_kv_get,
    we_kv_set,
    we_locks_is_active,
    we_locks_parse_value,
    we_player_data_key,
    we_sanitize_field,
    we_sanitize_key,
    we_sanitize_reason,
    we_startmap_filter_list,
    we_valid_steam_id,
)


class TestSteamId(unittest.TestCase):
    def test_accepts_17_digits(self):
        self.assertTrue(we_valid_steam_id("76561198000000000"))

    def test_rejects_traversal_and_junk(self):
        for bad in (
            "",
            "7656119800000000",
            "765611980000000000",
            "../theme",
            "76561198/00000000",
            "76561198\\0000000",
            "76561198=00000000",
            " 7656119800000000",
            "abcdefghijklmnopq",
        ):
            self.assertFalse(we_valid_steam_id(bad), bad)


class TestSanitize(unittest.TestCase):
    def test_field_strips_csv_breaks(self):
        self.assertEqual(we_sanitize_field("a,b\nc\r\td"), "a b c  d")

    def test_key_strips_eq_and_path(self):
        self.assertEqual(we_sanitize_key("foo=bar/../x"), "foobarx")
        self.assertEqual(we_sanitize_key("award_lag_lord"), "award_lag_lord")

    def test_reason_alnum_space(self):
        self.assertEqual(we_sanitize_reason("wall hacks!"), "wall hacks")

    def test_player_data_prefix(self):
        self.assertEqual(we_player_data_key("score"), "cust_score")
        self.assertEqual(we_player_data_key("cust_score"), "cust_score")
        self.assertEqual(we_player_data_key("../x"), "cust_x")
        self.assertEqual(we_player_data_key(""), "")

    def test_kv_file_name(self):
        self.assertEqual(we_kv_file_name("clan-stats.txt"), "clan-stats")
        self.assertEqual(we_kv_file_name("../etc"), "")
        self.assertEqual(we_kv_file_name("ok_name"), "ok_name")

    def test_ident_name(self):
        self.assertTrue(we_is_ident_name("user_76561198000000000"))
        self.assertTrue(we_is_ident_name("kv_clan-stats"))
        self.assertFalse(we_is_ident_name("user_../locks"))
        self.assertFalse(we_is_ident_name(""))


class TestKv(unittest.TestCase):
    def test_get_set_roundtrip(self):
        data = we_kv_set("", "a", "1")
        data = we_kv_set(data, "b", "2")
        self.assertEqual(we_kv_get(data, "a"), "1")
        data = we_kv_set(data, "a", "9")
        self.assertEqual(we_kv_get(data, "a"), "9")
        self.assertEqual(we_kv_get(data, "b"), "2")

    def test_value_may_contain_eq(self):
        data = we_kv_set("", "k", "x=y")
        self.assertEqual(we_kv_get(data, "k"), "x=y")


class TestLocks(unittest.TestCase):
    def test_parse_value(self):
        ts, owner = we_locks_parse_value("1700000000@127.0.0.1:44400")
        self.assertEqual(ts, 1700000000)
        self.assertEqual(owner, "127.0.0.1:44400")
        self.assertEqual(we_locks_parse_value("nope"), (0, ""))

    def test_ttl_and_future_stamp(self):
        self.assertTrue(we_locks_is_active(100, 100))
        self.assertFalse(we_locks_is_active(100, 101))
        self.assertTrue(we_locks_is_active(102, 100))
        self.assertFalse(we_locks_is_active(200, 100))
        self.assertFalse(we_locks_is_active(0, 100))


class TestBanCsv(unittest.TestCase):
    def test_parse_valid(self):
        row = we_ban_parse_line(
            "1700000000, 76561198000000000, n, c, by, 76561198000000001, cheat"
        )
        self.assertIsNotNone(row)
        assert row is not None
        self.assertEqual(row[1], "76561198000000000")

    def test_drops_kv_garbage_and_bad_id(self):
        self.assertIsNone(we_ban_parse_line("name=unix@ip:port"))
        self.assertIsNone(we_ban_parse_line("1, ../theme, n, c, by, bys, r"))
        self.assertIsNone(we_ban_parse_line(""))


class TestStartmapFilter(unittest.TestCase):
    def test_filter(self):
        installed = {"wfdm1", "wfdm2", "wfdm3"}
        self.assertEqual(
            we_startmap_filter_list("wfdm1 ../x wfdm2 wfdm1 WFDM3 missing", installed),
            ["wfdm1", "wfdm2", "WFDM3"],
        )
        self.assertEqual(we_startmap_filter_list("wfdm1 wfdm2", installed), ["wfdm1", "wfdm2"])
        self.assertEqual(we_startmap_filter_list("", installed), [])
        self.assertEqual(we_startmap_filter_list("a/b foo=bar", {"a/b", "foo=bar"}), [])


if __name__ == "__main__":
    unittest.main()
