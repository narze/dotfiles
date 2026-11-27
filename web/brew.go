package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"regexp"
	"slices"
	"strings"
)

type homebrew struct{}

type brewItem struct {
	Name      string   `json:"name"`
	Installed []string `json:"installed_versions"`
	Available string   `json:"current_version"`
	Pinned    bool     `json:"pinned"`
}

func parseBrew(output string) (inventory, error) {
	var result struct {
		Formulae []brewItem `json:"formulae"`
		Casks    []brewItem `json:"casks"`
	}
	if err := json.Unmarshal([]byte(output), &result); err != nil || result.Formulae == nil || result.Casks == nil {
		return inventory{}, errors.New("Homebrew returned an unexpected package list.")
	}
	var inv inventory
	for _, group := range []struct {
		kind  string
		items []brewItem
	}{
		{"Formula", result.Formulae}, {"Cask", result.Casks},
	} {
		for _, item := range group.items {
			inv.Changes = append(inv.Changes, change{
				Name: item.Name, Current: strings.Join(item.Installed, ", "), Available: item.Available, Kind: group.kind, Pinned: item.Pinned,
			})
			inv.CanApply = inv.CanApply || !item.Pinned
		}
	}
	slices.SortFunc(inv.Changes, func(a, b change) int {
		if a.Kind != b.Kind {
			return strings.Compare(b.Kind, a.Kind)
		}
		return strings.Compare(a.Name, b.Name)
	})
	return inv, nil
}

func brew(ctx context.Context, args ...string) (string, string, error) {
	env := append(os.Environ(), "HOMEBREW_NO_AUTO_UPDATE=1", "NONINTERACTIVE=1", "SUDO_ASKPASS=/usr/bin/false", "NO_COLOR=1")
	out, diagnostic, err := run(ctx, env, "brew", args...)
	if err != nil {
		return out, diagnostic, fmt.Errorf("Homebrew %s failed. Check Homebrew in Terminal for details.", args[0])
	}
	return out, diagnostic, nil
}

func (homebrew) outdated(ctx context.Context) (inventory, error) {
	out, _, err := brew(ctx, "outdated", "--json=v2")
	if err != nil {
		return inventory{}, err
	}
	return parseBrew(out)
}

func (b homebrew) check(ctx context.Context) (inventory, error) {
	if _, _, err := brew(ctx, "update", "--quiet"); err != nil {
		return inventory{}, err
	}
	return b.outdated(ctx)
}

var packageName = regexp.MustCompile(`^[[:alnum:]][[:alnum:]_.@+/-]*$`)

func brewUpgrade(ctx context.Context, inv inventory, dry bool) (string, error) {
	var output strings.Builder
	for _, group := range []struct{ kind, flag string }{{"Formula", "--formula"}, {"Cask", "--cask"}} {
		var names []string
		for _, item := range inv.Changes {
			if item.Kind == group.kind && !item.Pinned {
				if !packageName.MatchString(item.Name) {
					return "", errors.New("Homebrew returned an unexpected package name.")
				}
				names = append(names, item.Name)
			}
		}
		if len(names) == 0 {
			continue
		}
		args := []string{"upgrade", "--no-ask", group.flag}
		if dry {
			args = append(args, "--dry-run")
		}
		out, diagnostic, err := brew(ctx, append(append(args, "--"), names...)...)
		if err != nil {
			return "", err
		}
		output.WriteString(strings.TrimSpace(out + "\n" + diagnostic))
		output.WriteByte('\n')
	}
	return strings.TrimSpace(output.String()), nil
}

func (b homebrew) preview(ctx context.Context, target *packageTarget) (proposal, error) {
	inv, err := b.outdated(ctx)
	if err != nil {
		return proposal{}, err
	}
	if target != nil {
		index := slices.IndexFunc(inv.Changes, func(item change) bool {
			return item.Name == target.Name && item.Kind == target.Kind && !item.Pinned
		})
		if index == -1 {
			return proposal{}, errors.New("This package is no longer eligible for an update. Check again.")
		}
		inv = inventory{Changes: []change{inv.Changes[index]}, CanApply: true}
	}
	detail, err := brewUpgrade(ctx, inv, true)
	if err != nil {
		return proposal{}, err
	}
	return proposal{Inventory: inv, Detail: detail, Fingerprint: fingerprint([]any{inv, detail})}, nil
}

func (homebrew) apply(ctx context.Context, p proposal) error {
	if _, err := brewUpgrade(ctx, p.Inventory, false); err != nil {
		return errors.New("Homebrew did not finish the upgrade. Some packages may have changed. Check Homebrew in Terminal.")
	}
	return nil
}
