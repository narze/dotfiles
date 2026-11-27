package main

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestIncomingDotfilePreviewAndApply(t *testing.T) {
	binary := os.Getenv("TEST_CHEZMOI")
	if binary == "" {
		binary, _ = exec.LookPath("chezmoi")
	}
	help, err := exec.Command(binary, "diff", "--help").Output()
	if err != nil || !strings.Contains(string(help), "--skip-secrets") {
		t.Skip("set TEST_CHEZMOI to a chezmoi binary with --skip-secrets")
	}

	ctx := context.Background()
	temp := t.TempDir()
	home := filepath.Join(temp, "home")
	if err := os.Mkdir(home, 0700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))
	t.Setenv("XDG_CACHE_HOME", filepath.Join(home, ".cache"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(home, ".state"))

	git := func(path string, args ...string) {
		t.Helper()
		if out, err := exec.Command("git", append([]string{"-C", path}, args...)...).CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, out)
		}
	}
	write := func(path, value string) {
		t.Helper()
		if err := os.WriteFile(path, []byte(value), 0600); err != nil {
			t.Fatal(err)
		}
	}
	assertFile := func(path, want string) {
		t.Helper()
		data, err := os.ReadFile(path)
		if err != nil || string(data) != want {
			t.Fatalf("%s: got %q (%v), want %q", path, data, err, want)
		}
	}

	origin := filepath.Join(temp, "origin")
	if err := os.MkdirAll(filepath.Join(origin, "chezmoi"), 0700); err != nil {
		t.Fatal(err)
	}
	write(filepath.Join(origin, ".chezmoiroot"), "chezmoi\n")
	item := filepath.Join(origin, "chezmoi", "dot_example")
	write(item, "before\n")
	write(filepath.Join(origin, "chezmoi", "run_after_example.sh"), "touch \"$HOME/script-ran\"\n")
	git(origin, "init", "-q", "-b", "master")
	git(origin, "add", ".")
	git(origin, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "baseline", "--no-gpg-sign")
	repo := filepath.Join(temp, "checkout")
	git(temp, "clone", "-q", origin, repo)

	d := dotfiles{repo: repo, binary: binary}
	if _, err := d.chezmoi(ctx, repo, "apply", "--error-on-conflict"); err != nil {
		t.Fatal(err)
	}
	write(item, "incoming\n")
	git(origin, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qam", "update", "--no-gpg-sign")
	status, err := d.check(ctx)
	if err != nil || status.Behind != 1 {
		t.Fatalf("check: %+v, %v", status, err)
	}
	plan, err := d.preview(ctx, nil)
	if err != nil || !plan.Inventory.CanApply || len(plan.Inventory.Changes) != 1 {
		t.Fatalf("preview: %+v, %v", plan, err)
	}
	target := filepath.Join(home, ".example")
	assertFile(target, "before\n")
	before, err := d.revisions(ctx)
	if err != nil || before.Revision != status.Revision {
		t.Fatalf("preview changed checkout: %+v, %v", before, err)
	}
	if err := d.apply(ctx, plan); err != nil {
		t.Fatal(err)
	}
	assertFile(target, "incoming\n")
	if _, err := os.Stat(filepath.Join(home, "script-ran")); !os.IsNotExist(err) {
		t.Fatalf("unexpected run script result: %v", err)
	}
}
