package main

import (
	"fmt"
	"os"
	"time"

	"gopkg.in/yaml.v3"
)

// Config is the on-disk YAML next to the binary.
type Config struct {
	Webhooks     []string       `yaml:"webhooks"`
	PollInterval time.Duration  `yaml:"poll_interval"`
	Servers      []ServerConfig `yaml:"servers"`
}

// ServerConfig is one report.txt path and optional webhooks.
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
		Webhooks     []string  `yaml:"webhooks"`
		PollInterval string    `yaml:"poll_interval"`
		Servers      yaml.Node `yaml:"servers"`
	}
	if err := yaml.Unmarshal(data, &raw); err != nil {
		return nil, err
	}

	servers, err := parseServers(&raw.Servers)
	if err != nil {
		return nil, err
	}
	if len(servers) == 0 {
		return nil, fmt.Errorf("no servers configured")
	}

	cfg := &Config{
		Webhooks: raw.Webhooks,
		Servers:  servers,
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

	for i, srv := range cfg.Servers {
		if srv.Path == "" {
			return nil, fmt.Errorf("server %d: path is required", i)
		}
		hooks := srv.Webhooks
		if len(hooks) == 0 {
			hooks = cfg.Webhooks
		}
		if len(hooks) == 0 {
			return nil, fmt.Errorf("server %q: no webhooks (set global webhooks or per-server webhooks)", srv.Path)
		}
	}
	return cfg, nil
}

func parseServers(n *yaml.Node) ([]ServerConfig, error) {
	if n == nil || n.Kind == 0 {
		return nil, fmt.Errorf("no servers configured")
	}
	switch n.Kind {
	case yaml.SequenceNode:
		var list []ServerConfig
		if err := n.Decode(&list); err != nil {
			return nil, err
		}
		return list, nil
	case yaml.MappingNode:
		// Legacy: map keyed by a display name. Names are ignored; hostname comes from report.txt.
		var m map[string]ServerConfig
		if err := n.Decode(&m); err != nil {
			return nil, err
		}
		out := make([]ServerConfig, 0, len(m))
		for _, srv := range m {
			out = append(out, srv)
		}
		return out, nil
	default:
		return nil, fmt.Errorf("servers: want a list of {path, webhooks}")
	}
}
