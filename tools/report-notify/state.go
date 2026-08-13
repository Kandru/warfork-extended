package main

import (
	"encoding/json"
	"os"
	"sync"
)

// State tracks read offsets per report.txt path.
type State struct {
	mu    sync.Mutex
	Files map[string]*FileState `json:"files"`
}

// FileState is the last known offset/size for one file.
type FileState struct {
	Offset int64 `json:"offset"`
	Size   int64 `json:"size"`
}

func loadState(path string) (*State, error) {
	st := &State{Files: map[string]*FileState{}}
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return st, nil
		}
		return nil, err
	}
	if len(data) == 0 {
		return st, nil
	}
	if err := json.Unmarshal(data, st); err != nil {
		return nil, err
	}
	if st.Files == nil {
		st.Files = map[string]*FileState{}
	}
	return st, nil
}

func (s *State) save(path string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}
