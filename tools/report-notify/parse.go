package main

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Report is one CSV line from report.txt.
type Report struct {
	Unix          int64
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
	parts := strings.SplitN(line, ", ", 12)
	if len(parts) < 12 {
		// Fall back to plain comma split if spacing differs.
		parts = strings.SplitN(line, ",", 12)
		for i := range parts {
			parts[i] = strings.TrimSpace(parts[i])
		}
	}
	if len(parts) < 12 {
		return nil, fmt.Errorf("want 12 fields, got %d", len(parts))
	}
	unix, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return nil, fmt.Errorf("unix: %w", err)
	}
	return &Report{
		Unix:          unix,
		ReporterSteam: parts[1],
		ReporterName:  parts[2],
		ReporterClan:  parts[3],
		ReportedSteam: parts[4],
		ReportedName:  parts[5],
		ReportedClan:  parts[6],
		Score:         parts[7],
		Frags:         parts[8],
		Deaths:        parts[9],
		Suicides:      parts[10],
		Reason:        parts[11],
	}, nil
}

func (r *Report) timeUTC() time.Time {
	return time.Unix(r.Unix, 0).UTC()
}
