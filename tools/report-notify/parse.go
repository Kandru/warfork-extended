package main

import (
	"fmt"
	"strconv"
	"strings"
	"time"
	"unicode"
)

// Report is one CSV line from report.txt.
type Report struct {
	Unix          int64
	Hostname      string
	ReporterSteam string
	ReporterName  string
	ReporterClan  string
	ReportedSteam string
	ReportedName  string
	ReportedClan  string
	Score         string
	Frags         string
	Deaths        string
	Suicides      string
	Reason        string
}

func parseReportLine(line string) (*Report, error) {
	line = strings.TrimSpace(line)
	if line == "" {
		return nil, fmt.Errorf("empty")
	}
	// AS writes: unix, field, field, ... with ", " separators; commas inside
	// fields are already replaced with spaces by WE_SanitizeField.
	// Current: unix, hostname, reporterSteam, reporterName, reporterClan,
	// reportedSteam, reportedName, reportedClan, score, frags, deaths, suicides, reason
	// Legacy (12 fields): no hostname column.
	parts := splitReportFields(line, 13)
	if len(parts) < 12 {
		return nil, fmt.Errorf("want 12 or 13 fields, got %d", len(parts))
	}
	unix, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return nil, fmt.Errorf("unix: %w", err)
	}

	off := 0
	hostname := ""
	if len(parts) >= 13 {
		hostname = stripColors(parts[1])
		off = 1
	}

	return &Report{
		Unix:          unix,
		Hostname:      hostname,
		ReporterSteam: parts[1+off],
		ReporterName:  stripColors(parts[2+off]),
		ReporterClan:  stripColors(parts[3+off]),
		ReportedSteam: parts[4+off],
		ReportedName:  stripColors(parts[5+off]),
		ReportedClan:  stripColors(parts[6+off]),
		Score:         parts[7+off],
		Frags:         parts[8+off],
		Deaths:        parts[9+off],
		Suicides:      parts[10+off],
		Reason:        parts[11+off],
	}, nil
}

func splitReportFields(line string, n int) []string {
	parts := strings.SplitN(line, ", ", n)
	if len(parts) >= 12 {
		return parts
	}
	parts = strings.SplitN(line, ",", n)
	for i := range parts {
		parts[i] = strings.TrimSpace(parts[i])
	}
	return parts
}

// stripColors removes Quake/Qfusion color tokens (^0-^9, ^xRRGGBB).
func stripColors(s string) string {
	if s == "" || !strings.Contains(s, "^") {
		return s
	}
	var b strings.Builder
	b.Grow(len(s))
	for i := 0; i < len(s); i++ {
		if s[i] != '^' || i+1 >= len(s) {
			b.WriteByte(s[i])
			continue
		}
		n := s[i+1]
		if n >= '0' && n <= '9' {
			i++
			continue
		}
		if n == 'x' || n == 'X' {
			if i+7 < len(s) && isHexRGB(s[i+2:i+8]) {
				i += 7
				continue
			}
		}
		b.WriteByte(s[i])
	}
	return b.String()
}

func isHexRGB(s string) bool {
	if len(s) != 6 {
		return false
	}
	for i := 0; i < 6; i++ {
		if !unicode.Is(unicode.Hex_Digit, rune(s[i])) {
			return false
		}
	}
	return true
}

func (r *Report) timeUTC() time.Time {
	return time.Unix(r.Unix, 0).UTC()
}

func (r *Report) serverLabel() string {
	if r.Hostname != "" {
		return r.Hostname
	}
	return "Warfork server"
}
