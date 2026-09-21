package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func writeTempConfig(t *testing.T, body string) string {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, "config.yaml")
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestLoadConfigList(t *testing.T) {
	path := writeTempConfig(t, `
webhooks:
  - "https://discord.com/api/webhooks/1/token"
poll_interval: 30s
servers:
  - path: /tmp/report.txt
`)
	cfg, err := loadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.PollInterval != 30*time.Second {
		t.Fatalf("poll %s", cfg.PollInterval)
	}
	if len(cfg.Servers) != 1 || cfg.Servers[0].Path != "/tmp/report.txt" {
		t.Fatalf("servers %+v", cfg.Servers)
	}
}

func TestLoadConfigRequiresWebhook(t *testing.T) {
	path := writeTempConfig(t, `
servers:
  - path: /tmp/report.txt
`)
	if _, err := loadConfig(path); err == nil {
		t.Fatal("expected error")
	}
}

func TestLoadConfigPerServerWebhook(t *testing.T) {
	path := writeTempConfig(t, `
servers:
  - path: /tmp/a.txt
    webhooks:
      - "https://discord.com/api/webhooks/2/token"
`)
	cfg, err := loadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Servers[0].Webhooks) != 1 {
		t.Fatalf("hooks %+v", cfg.Servers[0].Webhooks)
	}
}

func TestLoadConfigMapRejected(t *testing.T) {
	path := writeTempConfig(t, `
webhooks: ["https://discord.com/api/webhooks/1/token"]
servers:
  oldname:
    path: /tmp/report.txt
`)
	if _, err := loadConfig(path); err == nil {
		t.Fatal("expected error for mapping servers")
	}
}

func TestLoadConfigEmptyServers(t *testing.T) {
	path := writeTempConfig(t, `webhooks: ["https://x"]
servers: []
`)
	if _, err := loadConfig(path); err == nil {
		t.Fatal("expected error")
	}
}
