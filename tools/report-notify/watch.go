package main

import (
	"path/filepath"

	"github.com/fsnotify/fsnotify"
)

// Event op bits mirrored so main does not import fsnotify directly for constants.
const (
	Write  = fsnotify.Write
	Create = fsnotify.Create
	Rename = fsnotify.Rename
)

// fileWatcher wraps fsnotify and exposes Events/Errors channels.
type fileWatcher struct {
	w *fsnotify.Watcher
}

func (f *fileWatcher) Events() <-chan fsnotify.Event { return f.w.Events }
func (f *fileWatcher) Errors() <-chan error          { return f.w.Errors }
func (f *fileWatcher) Close() error                  { return f.w.Close() }

// newFileWatcher watches parent dirs of all configured report.txt paths.
func newFileWatcher(cfg *Config) (*fileWatcher, error) {
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	for _, srv := range cfg.Servers {
		dir := filepath.Dir(srv.Path)
		if seen[dir] {
			continue
		}
		if err := w.Add(dir); err != nil {
			_ = w.Close()
			return nil, err
		}
		seen[dir] = true
	}
	return &fileWatcher{w: w}, nil
}
