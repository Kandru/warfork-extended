package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

// Set via -ldflags "-X main.version=..."
var version = "dev"

func main() {
	configPath := flag.String("config", "", "path to config.yaml (default: next to binary)")
	once := flag.Bool("once", false, "scan once and exit (for cron)")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		return
	}

	cfgPath := *configPath
	if cfgPath == "" {
		exe, err := os.Executable()
		if err != nil {
			log.Fatalf("resolve executable: %v", err)
		}
		cfgPath = filepath.Join(filepath.Dir(exe), "config.yaml")
	}
	cfgPath, err := filepath.Abs(cfgPath)
	if err != nil {
		log.Fatalf("config path: %v", err)
	}

	cfg, err := loadConfig(cfgPath)
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	statePath := filepath.Join(filepath.Dir(cfgPath), "report-notify.state.json")
	st, err := loadState(statePath)
	if err != nil {
		log.Fatalf("state: %v", err)
	}

	app := &App{
		cfg:       cfg,
		state:     st,
		statePath: statePath,
		client:    newHTTPClient(),
	}

	// First sighting of a path seeks to EOF (no flood). Later lines notify.
	if err := app.scanAll(true); err != nil {
		if *once {
			log.Fatalf("scan: %v", err)
		}
		log.Printf("initial scan: %v", err)
	}

	if *once {
		return
	}

	log.Printf("we-report-notify %s watching %d server(s)", version, len(cfg.Servers))
	if err := app.runWatch(); err != nil {
		log.Fatalf("watch: %v", err)
	}
}

// App holds runtime config and offset state.
type App struct {
	cfg       *Config
	state     *State
	statePath string
	client    *httpClient
}

func (a *App) scanAll(notify bool) error {
	var first error
	for name, srv := range a.cfg.Servers {
		if err := a.scanServer(name, srv, notify); err != nil {
			log.Printf("[%s] scan: %v", name, err)
			if first == nil {
				first = err
			}
		}
	}
	return first
}

func (a *App) scanServer(name string, srv ServerConfig, notify bool) error {
	path := srv.Path
	fi, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	size := fi.Size()

	entry := a.state.Files[path]
	if entry == nil {
		// First sighting: seek to EOF so we do not flood history.
		a.state.Files[path] = &FileState{Offset: size, Size: size}
		return a.state.save(a.statePath)
	}

	offset := entry.Offset
	if size < offset {
		offset = 0
	}
	if size == offset {
		a.state.Files[path] = &FileState{Offset: offset, Size: size}
		return a.state.save(a.statePath)
	}

	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	if _, err := f.Seek(offset, 0); err != nil {
		return err
	}

	hooks := srv.Webhooks
	if len(hooks) == 0 {
		hooks = a.cfg.Webhooks
	}

	cur := offset
	br := bufio.NewReader(f)
	for {
		line, err := br.ReadString('\n')
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		next := cur + int64(len(line))
		trimmed := strings.TrimRight(line, "\r\n")
		if trimmed == "" {
			cur = next
			continue
		}
		rep, err := parseReportLine(trimmed)
		if err != nil {
			log.Printf("[%s] skip bad line: %v (%q)", name, err, trimmed)
			cur = next
			continue
		}
		if notify {
			if err := a.client.postReport(hooks, name, rep); err != nil {
				log.Printf("[%s] webhook: %v", name, err)
				a.state.Files[path] = &FileState{Offset: cur, Size: size}
				_ = a.state.save(a.statePath)
				return err
			}
			log.Printf("[%s] notified report: %s -> %s", name, rep.ReporterName, rep.ReportedName)
		}
		cur = next
	}

	a.state.Files[path] = &FileState{Offset: cur, Size: size}
	return a.state.save(a.statePath)
}

func (a *App) runWatch() error {
	pollEvery := a.cfg.PollInterval
	if pollEvery <= 0 {
		pollEvery = time.Minute
	}

	watcher, err := newFileWatcher(a.cfg)
	if err != nil {
		log.Printf("fsnotify unavailable (%v); polling every %s", err, pollEvery)
		return a.pollLoop(pollEvery)
	}
	defer watcher.Close()

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

	ticker := time.NewTicker(pollEvery)
	defer ticker.Stop()

	for {
		select {
		case <-sig:
			log.Printf("shutting down")
			return nil
		case ev, ok := <-watcher.Events():
			if !ok {
				return a.pollLoop(pollEvery)
			}
			if ev.Op&(Write|Create|Rename) != 0 {
				_ = a.scanAll(true)
			}
		case err, ok := <-watcher.Errors():
			if !ok {
				return a.pollLoop(pollEvery)
			}
			log.Printf("watch error: %v", err)
		case <-ticker.C:
			// Safety net for missed events / NFS.
			_ = a.scanAll(true)
		}
	}
}

func (a *App) pollLoop(every time.Duration) error {
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	ticker := time.NewTicker(every)
	defer ticker.Stop()

	for {
		select {
		case <-sig:
			log.Printf("shutting down")
			return nil
		case <-ticker.C:
			_ = a.scanAll(true)
		}
	}
}
