package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type httpClient struct {
	hc *http.Client
}

func newHTTPClient() *httpClient {
	return &httpClient{
		hc: &http.Client{Timeout: 15 * time.Second},
	}
}

type discordEmbed struct {
	Title       string         `json:"title"`
	Description string         `json:"description,omitempty"`
	Color       int            `json:"color"`
	Fields      []discordField `json:"fields"`
	Timestamp   string         `json:"timestamp,omitempty"`
	Footer      *discordFooter `json:"footer,omitempty"`
}

type discordField struct {
	Name   string `json:"name"`
	Value  string `json:"value"`
	Inline bool   `json:"inline,omitempty"`
}

type discordFooter struct {
	Text string `json:"text"`
}

type discordPayload struct {
	Content string         `json:"content,omitempty"`
	Embeds  []discordEmbed `json:"embeds"`
}

func (c *httpClient) postReport(urls []string, server string, r *Report) error {
	payload := buildPayload(server, r)
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	var first error
	for _, u := range urls {
		if err := c.postWithRetry(u, body); err != nil {
			if first == nil {
				first = err
			}
		}
	}
	return first
}

func buildPayload(server string, r *Report) discordPayload {
	reporter := formatPlayer(r.ReporterName, r.ReporterClan, r.ReporterSteam)
	reported := formatPlayer(r.ReportedName, r.ReportedClan, r.ReportedSteam)
	reason := r.Reason
	if reason == "" {
		reason = "(none)"
	}
	ts := r.timeUTC()
	return discordPayload{
		Content: fmt.Sprintf("**Player report** on `%s`", server),
		Embeds: []discordEmbed{{
			Title:     "Report filed",
			Color:     0xE74C3C,
			Timestamp: ts.Format(time.RFC3339),
			Fields: []discordField{
				{Name: "Server", Value: server, Inline: true},
				{Name: "Time (UTC)", Value: ts.Format("2006-01-02 15:04:05"), Inline: true},
				{Name: "Reporter", Value: reporter, Inline: false},
				{Name: "Reported", Value: reported, Inline: false},
				{Name: "Score", Value: r.Score, Inline: true},
				{Name: "Frags", Value: r.Frags, Inline: true},
				{Name: "Deaths", Value: r.Deaths, Inline: true},
				{Name: "Suicides", Value: r.Suicides, Inline: true},
				{Name: "Reason", Value: reason, Inline: false},
			},
			Footer: &discordFooter{Text: "warfork-extended report-notify"},
		}},
	}
}

func formatPlayer(name, clan, steam string) string {
	var b strings.Builder
	if name == "" {
		name = "?"
	}
	b.WriteString(name)
	if clan != "" {
		b.WriteString(" [")
		b.WriteString(clan)
		b.WriteString("]")
	}
	if steam != "" {
		b.WriteString("\n`")
		b.WriteString(steam)
		b.WriteString("`")
	}
	return b.String()
}

func (c *httpClient) postWithRetry(url string, body []byte) error {
	var last error
	for attempt := 0; attempt < 3; attempt++ {
		if attempt > 0 {
			time.Sleep(time.Duration(attempt) * time.Second)
		}
		req, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(body))
		if err != nil {
			return err
		}
		req.Header.Set("Content-Type", "application/json")
		resp, err := c.hc.Do(req)
		if err != nil {
			last = err
			continue
		}
		_, _ = io.Copy(io.Discard, resp.Body)
		resp.Body.Close()
		if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
			last = fmt.Errorf("webhook HTTP %d", resp.StatusCode)
			continue
		}
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			return fmt.Errorf("webhook HTTP %d", resp.StatusCode)
		}
		return nil
	}
	return last
}
