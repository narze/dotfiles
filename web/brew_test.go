package main

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestTargetedBrewUpgrade(t *testing.T) {
	dir := t.TempDir()
	log := filepath.Join(dir, "commands")
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	t.Setenv("BREW_TEST_LOG", log)
	script := `#!/bin/sh
if [ "$1" = outdated ]; then
  printf '%s\n' '{"formulae":[{"name":"example","installed_versions":["1"],"current_version":"2"},{"name":"other","installed_versions":["1"],"current_version":"2"},{"name":"pinned","pinned":true}],"casks":[{"name":"example","installed_versions":["3"],"current_version":"4"}]}'
  exit 0
fi
printf '%s\n' "$*" >> "$BREW_TEST_LOG"
printf 'Preview for %s\n' "$*"
`
	if err := os.WriteFile(filepath.Join(dir, "brew"), []byte(script), 0700); err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	d := newDashboard(map[string]updater{"brew": homebrew{}})
	p, err := d.preview(ctx, "brew", &packageTarget{Name: "example", Kind: "Cask"})
	if err != nil {
		t.Fatal(err)
	}
	if len(p.Inventory.Changes) != 1 || p.Inventory.Changes[0].Available != "4" {
		t.Fatalf("unexpected preview: %+v", p.Inventory.Changes)
	}
	if err := d.apply(ctx, "brew", p.Token); err != nil {
		t.Fatal(err)
	}
	if _, err := d.preview(ctx, "brew", &packageTarget{Name: "pinned", Kind: "Formula"}); err == nil {
		t.Fatal("pinned package was accepted")
	}
	if _, err := d.preview(ctx, "brew", &packageTarget{Name: "missing", Kind: "Formula"}); err == nil {
		t.Fatal("missing package was accepted")
	}
	data, err := os.ReadFile(log)
	if err != nil {
		t.Fatal(err)
	}
	want := "upgrade --no-ask --cask --dry-run -- example\n" +
		"upgrade --no-ask --cask --dry-run -- example\n" +
		"upgrade --no-ask --cask -- example"
	if strings.TrimSpace(string(data)) != want {
		t.Fatalf("unexpected brew commands:\n%s", data)
	}
}
