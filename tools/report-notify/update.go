package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const githubRepo = "kandru/warfork-extended"

type githubRelease struct {
	TagName string        `json:"tag_name"`
	Assets  []githubAsset `json:"assets"`
}

type githubAsset struct {
	Name               string `json:"name"`
	BrowserDownloadURL string `json:"browser_download_url"`
}

func normalizeVersion(v string) string {
	v = strings.TrimSpace(v)
	return strings.TrimPrefix(v, "v")
}

// versionNeedsUpdate reports whether local should be replaced by remote.
// "dev" always updates. Equal versions do not. Any other local version updates
// when it differs from remote (release tags are the source of truth).
func versionNeedsUpdate(local, remote string) bool {
	local = normalizeVersion(local)
	remote = normalizeVersion(remote)
	if remote == "" {
		return false
	}
	if local == "dev" || local == "" {
		return true
	}
	return local != remote
}

func assetNameFor(goos, goarch string) string {
	return fmt.Sprintf("we-report-notify-%s-%s", goos, goarch)
}

func findAsset(assets []githubAsset, name string) (githubAsset, bool) {
	for _, a := range assets {
		if a.Name == name {
			return a, true
		}
	}
	return githubAsset{}, false
}

func newUpdateHTTPClient() *http.Client {
	return &http.Client{Timeout: 2 * time.Minute}
}

func fetchLatestReleaseFrom(client *http.Client, apiBase, userAgent string) (*githubRelease, error) {
	url := strings.TrimRight(apiBase, "/") + "/repos/" + githubRepo + "/releases/latest"
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("User-Agent", userAgent)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub releases/latest: HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	var rel githubRelease
	if err := json.Unmarshal(body, &rel); err != nil {
		return nil, fmt.Errorf("parse release JSON: %w", err)
	}
	if rel.TagName == "" {
		return nil, fmt.Errorf("release has empty tag_name")
	}
	return &rel, nil
}

func downloadToFile(client *http.Client, url, dest, userAgent string) error {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", userAgent)
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return fmt.Errorf("download: HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	f, err := os.OpenFile(dest, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o755)
	if err != nil {
		return err
	}
	_, copyErr := io.Copy(f, resp.Body)
	closeErr := f.Close()
	if copyErr != nil {
		return copyErr
	}
	return closeErr
}

func replaceExecutable(exePath, newPath string) error {
	info, err := os.Stat(exePath)
	if err != nil {
		return err
	}
	mode := info.Mode().Perm()
	if err := os.Chmod(newPath, mode); err != nil {
		return err
	}
	return os.Rename(newPath, exePath)
}

func resolveExecutable() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	return filepath.EvalSymlinks(exe)
}

// runSelfUpdate fetches the latest release from kandru/warfork-extended and
// replaces the current binary when a newer (or different) version is available.
// client/apiBase/exePath are optional overrides for tests (nil / "" = production).
func runSelfUpdate(localVersion string, client *http.Client, apiBase, exePath string) error {
	if client == nil {
		client = newUpdateHTTPClient()
	}
	ua := "we-report-notify/" + localVersion
	if apiBase == "" {
		apiBase = "https://api.github.com"
	}

	rel, err := fetchLatestReleaseFrom(client, apiBase, ua)
	if err != nil {
		return err
	}

	remote := normalizeVersion(rel.TagName)
	local := normalizeVersion(localVersion)
	if !versionNeedsUpdate(local, remote) {
		fmt.Printf("already up to date (%s)\n", local)
		return nil
	}

	name := assetNameFor(runtime.GOOS, runtime.GOARCH)
	asset, ok := findAsset(rel.Assets, name)
	if !ok {
		return fmt.Errorf("release %s has no asset %q (this platform may not be published)", rel.TagName, name)
	}
	if asset.BrowserDownloadURL == "" {
		return fmt.Errorf("asset %q has empty download URL", name)
	}

	if exePath == "" {
		exePath, err = resolveExecutable()
		if err != nil {
			return fmt.Errorf("resolve executable: %w", err)
		}
	}
	dir := filepath.Dir(exePath)
	tmp, err := os.CreateTemp(dir, ".we-report-notify-update-*")
	if err != nil {
		return fmt.Errorf("temp file in %s: %w (is the install dir writable?)", dir, err)
	}
	tmpPath := tmp.Name()
	_ = tmp.Close()
	defer os.Remove(tmpPath)

	fmt.Printf("updating %s -> %s\n", local, remote)
	if err := downloadToFile(client, asset.BrowserDownloadURL, tmpPath, ua); err != nil {
		return err
	}
	if err := replaceExecutable(exePath, tmpPath); err != nil {
		return fmt.Errorf("replace %s: %w", exePath, err)
	}
	fmt.Printf("updated to %s (%s)\n", remote, exePath)
	return nil
}
