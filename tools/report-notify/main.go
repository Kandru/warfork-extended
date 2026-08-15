package main

import (
	"bytes"
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
	log.SetOutput(os.Stdout)
	log.SetFlags(log.LstdFlags)

	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage: %s [flags] [self-update]\n\n", os.Args[0])
		fmt.Fprintf(flag.CommandLine.Output(), "Commands:\n")
		fmt.Fprintf(flag.CommandLine.Output(), "  self-update   Download latest release binary from GitHub and replace this executable\n\n")
		fmt.Fprintf(flag.CommandLine.Output(), "Flags:\n")
		flag.PrintDefaults()
	}

	configPath := flag.String("config", "", "path to config.yaml (default: next to binary)")
	cron := flag.Bool("cron", false, "read report files once, post, truncate, exit (no file watch)")
	once := flag.Bool("once", false, "alias for -cron")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		return
	}

	args := flag.Args()
	if len(args) > 0 {
		switch args[0] {
		case "self-update":
			if len(args) > 1 {
				log.Fatalf("self-update takes no arguments")
			}
			if err := runSelfUpdate(version, nil, "", ""); err != nil {
				log.Fatalf("self-update: %v", err)
			}
			return
		default:
			log.Fatalf("unknown command %q (try -h)", args[0])
		}
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

	app := &App{
		cfg:    cfg,
		client: newHTTPClient(),
	}

	if err := app.scanAll(); err != nil {
		if *cron || *once {
			log.Fatalf("scan: %v", err)
		}
		log.Printf("initial scan: %v", err)
	}

	if *cron || *once {
		return
	}

	log.Printf("we-report-notify %s watching %d server(s)", version, len(cfg.Servers))
	if err := app.runWatch(); err != nil {
		log.Fatalf("watch: %v", err)
	}
}

type App struct {
	cfg    *Config
	client *httpClient
}

func (a *App) scanAll() error {
	var first error
	for _, srv := range a.cfg.Servers {
		if err := a.scanServer(srv); err != nil {
			log.Printf("[%s] scan: %v", srv.Path, err)
			if first == nil {
				first = err
			}
		}
	}
	return first
}

func (a *App) scanServer(srv ServerConfig) error {
	path := srv.Path
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if len(bytes.TrimSpace(data)) == 0 {
		return nil
	}

	hooks := srv.Webhooks
	if len(hooks) == 0 {
		hooks = a.cfg.Webhooks
	}

	var reports []*Report
	for _, line := range strings.Split(string(data), "\n") {
		trimmed := strings.TrimRight(line, "\r")
		if strings.TrimSpace(trimmed) == "" {
			continue
		}
		rep, err := parseReportLine(trimmed)
		if err != nil {
			log.Printf("[%s] skip bad line: %v (%q)", path, err, trimmed)
			continue
		}
		reports = append(reports, rep)
	}

	for _, rep := range reports {
		if err := a.client.postReport(hooks, rep); err != nil {
			log.Printf("[%s] webhook: %v", path, err)
			return err
		}
		log.Println(formatSentLine(rep))
	}

	if err := os.Truncate(path, 0); err != nil {
		return fmt.Errorf("clear %s: %w", path, err)
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
