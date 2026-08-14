package main

import (
	"os"
	"path/filepath"
	"strings"
	"sync"

	"gopkg.in/yaml.v3"
)

// State tracks the last report unix pushed to Discord, per server name.
type State struct {
	mu      sync.Mutex
	Servers map[string]ServerState `yaml:"servers"`
}

// ServerState is the last notified report for one configured server.
type ServerState struct {
	LastUnix int64 `yaml:"last_unix"`
}

func statePathForConfig(cfgPath string) string {
	ext := filepath.Ext(cfgPath)
	return strings.TrimSuffix(cfgPath, ext) + ".state.yaml"
}

func loadState(path string) (st *State, existed bool, err error) {
	st = &State{Servers: map[string]ServerState{}}
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return st, false, nil
		}
		return nil, false, err
	}
	if len(data) == 0 {
		return st, true, nil
	}
	if err := yaml.Unmarshal(data, st); err != nil {
		return nil, true, err
	}
	if st.Servers == nil {
		st.Servers = map[string]ServerState{}
	}
	return st, true, nil
}

func (s *State) lastUnix(name string) (unix int64, known bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ss, ok := s.Servers[name]
	if !ok {
		return 0, false
	}
	return ss.LastUnix, true
}

func (s *State) setLastUnix(name string, unix int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.Servers == nil {
		s.Servers = map[string]ServerState{}
	}
	s.Servers[name] = ServerState{LastUnix: unix}
}

func (s *State) save(path string) error {
	s.mu.Lock()
	out := struct {
		Servers map[string]ServerState `yaml:"servers"`
	}{Servers: make(map[string]ServerState, len(s.Servers))}
	for k, v := range s.Servers {
		out.Servers[k] = v
	}
	s.mu.Unlock()
	data, err := yaml.Marshal(out)
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}
