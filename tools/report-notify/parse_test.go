package main

import "testing"

func TestParseReportLineNew(t *testing.T) {
	line := "1710000000, EU DM, 76561198000000001, Alice, clanA, 76561198000000002, Bob, clanB, 10, 8, 3, 1, wallhacks"
	r, err := parseReportLine(line)
	if err != nil {
		t.Fatal(err)
	}
	if r.Hostname != "EU DM" || r.ReporterSteam != "76561198000000001" || r.ReportedSteam != "76561198000000002" {
		t.Fatalf("fields: %+v", r)
	}
	if r.ReporterClan != "clanA" || r.ReportedClan != "clanB" || r.Reason != "wallhacks" {
		t.Fatalf("clan/reason: %+v", r)
	}
}

func TestParseReportLineLegacy(t *testing.T) {
	line := "1710000000, 76561198000000001, Alice, clanA, 76561198000000002, Bob, clanB, 10, 8, 3, 1, wallhacks"
	r, err := parseReportLine(line)
	if err != nil {
		t.Fatal(err)
	}
	if r.Hostname != "" || r.ReporterSteam != "76561198000000001" || r.ReportedName != "Bob" {
		t.Fatalf("legacy: %+v", r)
	}
}

func TestStripColors(t *testing.T) {
	got := stripColors("^1foo^7[^2x^7]")
	if got != "foo[x]" {
		t.Fatalf("got %q", got)
	}
}

func TestSteamLink(t *testing.T) {
	got := steamLink("76561198000000001")
	want := "[76561198000000001](https://steamcommunity.com/profiles/76561198000000001)"
	if got != want {
		t.Fatalf("got %q", got)
	}
}

func TestBuildPayloadTitle(t *testing.T) {
	p := buildPayload(&Report{
		Unix:          1710000000,
		Hostname:      "EU DM",
		ReporterSteam: "76561198000000001",
		ReporterName:  "Alice",
		ReporterClan:  "TAG",
		ReportedSteam: "76561198000000002",
		ReportedName:  "Bob",
		Score:         "1",
		Frags:         "1",
		Deaths:        "0",
		Suicides:      "0",
		Reason:        "cheat",
	})
	if p.Embeds[0].Title != "Alice reported Bob in Warfork" {
		t.Fatalf("title %q", p.Embeds[0].Title)
	}
	if p.Embeds[0].Fields[0].Value != "EU DM" {
		t.Fatalf("server %q", p.Embeds[0].Fields[0].Value)
	}
}

func TestFormatSentLine(t *testing.T) {
	got := formatSentLine(&Report{
		Hostname:      "EU DM",
		ReporterSteam: "76561198000000001",
		ReporterName:  "Alice",
		ReporterClan:  "TAG",
		ReportedSteam: "76561198000000002",
		ReportedName:  "Bob",
		ReportedClan:  "CLAN",
		Score:         "10",
		Frags:         "8",
		Deaths:        "3",
		Suicides:      "1",
		Reason:        "wallhacks",
	})
	want := "sent EU DM | Alice [TAG] reported Bob [CLAN] | 76561198000000001 -> 76561198000000002 | score=10 frags=8 deaths=3 suicides=1 | wallhacks"
	if got != want {
		t.Fatalf("got %q", got)
	}
}
