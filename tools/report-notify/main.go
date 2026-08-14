package main

import (
	"flag"
	"fmt"
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

	statePath := statePathForConfig(cfgPath)
	st, existed, err := loadState(statePath)
	if err != nil {
		log.Fatalf("state: %v", err)
	}

	app := &App{
		cfg:       cfg,
		state:     st,
		statePath: statePath,
		client:    newHTTPClient(),
	}

	if !existed {
		log.Printf("no state file %s; ignoring and resetting report.txt", statePath)
		if err := app.resetAllReports(); err != nil {
			log.Fatalf("reset reports: %v", err)
		}
		for name := range cfg.Servers {
			st.setLastUnix(name, 0)
		}
		if err := st.save(statePath); err != nil {
			log.Fatalf("write state: %v", err)
		}
	}

	if err := app.scanAll(); err != nil {
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

// App holds runtime config and last-notified timestamps.
type App struct {
	cfg       *Config
	state     *State
	statePath string
	client    *httpClient
}

func (a *App) resetAllReports() error {
	var first error
	for name, srv := range a.cfg.Servers {
		if err := os.Truncate(srv.Path, 0); err != nil {
			if os.IsNotExist(err) {
				continue
			}
			log.Printf("[%s] reset %s: %v", name, srv.Path, err)
			if first == nil {
				first = err
			}
			continue
		}
		log.Printf("[%s] cleared %s", name, srv.Path)
	}
	return first
}

func (a *App) scanAll() error {
	var first error
	for name, srv := range a.cfg.Servers {
		if err := a.scanServer(name, srv); err != nil {
			log.Printf("[%s] scan: %v", name, err)
			if first == nil {
				first = err
			}
		}
	}
	return first
}

func (a *App) scanServer(name string, srv ServerConfig) error {
	path := srv.Path
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}

	last, known := a.state.lastUnix(name)
	hooks := srv.Webhooks
	if len(hooks) == 0 {
		hooks = a.cfg.Webhooks
	}

	maxUnix := last
	for _, line := range strings.Split(string(data), "\n") {
		trimmed := strings.TrimRight(line, "\r")
		if strings.TrimSpace(trimmed) == "" {
			continue
		}
		rep, err := parseReportLine(trimmed)
		if err != nil {
			log.Printf("[%s] skip bad line: %v (%q)", name, err, trimmed)
			continue
		}
		if !known {
			if rep.Unix > maxUnix {
				maxUnix = rep.Unix
			}
			continue
		}
		if rep.Unix <= last {
			continue
		}
		if err := a.client.postReport(hooks, name, rep); err != nil {
			log.Printf("[%s] webhook: %v", name, err)
			return err
		}
		log.Printf("[%s] notified report: %s -> %s", name, rep.ReporterName, rep.ReportedName)
		last = rep.Unix
		a.state.setLastUnix(name, last)
		if err := a.state.save(a.statePath); err != nil {
			return err
		}
	}

	if !known {
		a.state.setLastUnix(name, maxUnix)
		return a.state.save(a.statePath)
	}
	return nil
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
				_ = a.scanAll()
			}
		case err, ok := <-watcher.Errors():
			if !ok {
				return a.pollLoop(pollEvery)
			}
			log.Printf("watch error: %v", err)
		case <-ticker.C:
			// Safety net for missed events / NFS.
			_ = a.scanAll()
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
			_ = a.scanAll()
		}
	}
}
