package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestNormalizeVersion(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"v1.2.3", "1.2.3"},
		{"1.2.3", "1.2.3"},
		{"  v0.1.0 ", "0.1.0"},
		{"dev", "dev"},
	}
	for _, c := range cases {
		if got := normalizeVersion(c.in); got != c.want {
			t.Errorf("normalizeVersion(%q)=%q want %q", c.in, got, c.want)
		}
	}
}

func TestVersionNeedsUpdate(t *testing.T) {
	cases := []struct {
		local, remote string
		want          bool
	}{
		{"0.1.0", "v0.1.0", false},
		{"v0.1.0", "0.1.0", false},
		{"0.1.0", "0.2.0", true},
		{"dev", "0.1.0", true},
		{"", "0.1.0", true},
		{"0.1.0", "", false},
	}
	for _, c := range cases {
		if got := versionNeedsUpdate(c.local, c.remote); got != c.want {
			t.Errorf("versionNeedsUpdate(%q, %q)=%v want %v", c.local, c.remote, got, c.want)
		}
	}
}

func TestAssetNameFor(t *testing.T) {
	got := assetNameFor("linux", "amd64")
	if got != "we-report-notify-linux-amd64" {
		t.Fatalf("got %q", got)
	}
}

func TestRunSelfUpdateAlreadyLatest(t *testing.T) {
	mux := http.NewServeMux()
	mux.HandleFunc("/repos/"+githubRepo+"/releases/latest", func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("User-Agent") == "" {
			t.Error("missing User-Agent")
		}
		_ = json.NewEncoder(w).Encode(githubRelease{
			TagName: "v0.1.0",
			Assets: []githubAsset{{
				Name:               assetNameFor(runtime.GOOS, runtime.GOARCH),
				BrowserDownloadURL: "http://example.invalid/should-not-download",
			}},
		})
	})
	srv := httptest.NewServer(mux)
	defer srv.Close()

	if err := runSelfUpdate("0.1.0", srv.Client(), srv.URL, ""); err != nil {
		t.Fatal(err)
	}
}

func TestRunSelfUpdateDownloadReplace(t *testing.T) {
	dir := t.TempDir()
	exePath := filepath.Join(dir, "we-report-notify")
	if err := os.WriteFile(exePath, []byte("old-binary"), 0o755); err != nil {
		t.Fatal(err)
	}

	const newPayload = "new-binary-contents"
	var downloadURL string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case strings.HasSuffix(r.URL.Path, "/releases/latest"):
			_ = json.NewEncoder(w).Encode(githubRelease{
				TagName: "v0.2.0",
				Assets: []githubAsset{{
					Name:               assetNameFor(runtime.GOOS, runtime.GOARCH),
					BrowserDownloadURL: downloadURL,
				}},
			})
		case r.URL.Path == "/download":
			_, _ = w.Write([]byte(newPayload))
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()
	downloadURL = srv.URL + "/download"

	if err := runSelfUpdate("0.1.0", srv.Client(), srv.URL, exePath); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(exePath)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != newPayload {
		t.Fatalf("binary contents %q want %q", data, newPayload)
	}
	info, err := os.Stat(exePath)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm()&0o111 == 0 {
		t.Fatalf("executable bit lost: %v", info.Mode())
	}
}

func TestRunSelfUpdateMissingAsset(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(githubRelease{
			TagName: "v0.2.0",
			Assets:  []githubAsset{{Name: "we-report-notify-other-arch", BrowserDownloadURL: "http://x"}},
		})
	}))
	defer srv.Close()

	err := runSelfUpdate("0.1.0", srv.Client(), srv.URL, filepath.Join(t.TempDir(), "bin"))
	if err == nil {
		t.Fatal("expected error for missing asset")
	}
	if !strings.Contains(err.Error(), "no asset") {
		t.Fatalf("unexpected error: %v", err)
	}
}
