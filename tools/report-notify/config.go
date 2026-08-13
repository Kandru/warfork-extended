package main

import (
	"fmt"
	"os"
	"time"

	"gopkg.in/yaml.v3"
)

// Config is the on-disk YAML next to the binary.
type Config struct {
	Webhooks     []string                `yaml:"webhooks"`
	PollInterval time.Duration           `yaml:"poll_interval"`
	Servers      map[string]ServerConfig `yaml:"servers"`
}

// ServerConfig maps a display name to a report.txt path and optional webhooks.
type ServerConfig struct {
	Path     string   `yaml:"path"`
	Webhooks []string `yaml:"webhooks"`
}

func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var raw struct {
		Webhooks     []string                `yaml:"webhooks"`
		PollInterval string                  `yaml:"poll_interval"`
		Servers      map[string]ServerConfig `yaml:"servers"`
	}
	if err := yaml.Unmarshal(data, &raw); err != nil {
		return nil, err
	}
	if len(raw.Servers) == 0 {
		return nil, fmt.Errorf("no servers configured")
	}

	cfg := &Config{
		Webhooks: raw.Webhooks,
		Servers:  raw.Servers,
	}
	if raw.PollInterval == "" {
		cfg.PollInterval = time.Minute
	} else {
		d, err := time.ParseDuration(raw.PollInterval)
		if err != nil {
			return nil, fmt.Errorf("poll_interval: %w", err)
		}
		cfg.PollInterval = d
	}

	for name, srv := range cfg.Servers {
		if srv.Path == "" {
			return nil, fmt.Errorf("server %q: path is required", name)
		}
		hooks := srv.Webhooks
		if len(hooks) == 0 {
			hooks = cfg.Webhooks
		}
		if len(hooks) == 0 {
			return nil, fmt.Errorf("server %q: no webhooks (set global webhooks or per-server webhooks)", name)
		}
	}
	return cfg, nil
}
