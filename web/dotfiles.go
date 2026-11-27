package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type dotfiles struct{ repo, binary string }

func (d dotfiles) git(ctx context.Context, args ...string) (string, error) {
	env := append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
	out, _, err := run(ctx, env, "git", append([]string{"-C", d.repo}, args...)...)
	if err != nil {
		return "", fmt.Errorf("Git %s failed. Check the chezmoi checkout in Terminal.", args[0])
	}
	return strings.TrimSpace(out), nil
}

func (d dotfiles) revisions(ctx context.Context) (inventory, error) {
	head, err := d.git(ctx, "rev-parse", "--verify", "HEAD")
	if err != nil {
		return inventory{}, err
	}
	upstream, err := d.git(ctx, "rev-parse", "--verify", "@{upstream}")
	if err != nil {
		return inventory{}, errors.New("Configure an upstream branch for the chezmoi checkout.")
	}
	raw, err := d.git(ctx, "rev-list", "--left-right", "--count", head+"..."+upstream)
	if err != nil {
		return inventory{}, err
	}
	counts := strings.Fields(raw)
	if len(counts) != 2 {
		return inventory{}, errors.New("Git returned an unexpected commit count.")
	}
	ahead, aheadErr := strconv.Atoi(counts[0])
	behind, behindErr := strconv.Atoi(counts[1])
	if aheadErr != nil || behindErr != nil {
		return inventory{}, errors.New("Git returned an invalid commit count.")
	}

	return inventory{Revision: head, Upstream: upstream, Ahead: ahead, Behind: behind}, nil
}

func (d dotfiles) chezmoi(ctx context.Context, source string, operation string, args ...string) (string, error) {
	base := []string{"--source", source, "--no-tty", "--no-pager", operation,
		"--include=files", "--exclude=encrypted,externals", "--skip-secrets"}
	out, diagnostic, err := run(ctx, nil, d.binary, append(base, args...)...)
	if err != nil {
		if strings.Contains(diagnostic, "unknown flag: --skip-secrets") {
			return "", errors.New("This chezmoi version lacks --skip-secrets. Start the dashboard with -chezmoi pointing to a newer binary.")
		}
		return "", fmt.Errorf("Chezmoi %s failed. Check local conflicts, templates, and the installed version in Terminal.", operation)
	}
	return out, nil
}

func dotfileChanges(output string) []change {
	var result []change
	for _, line := range strings.Split(output, "\n") {
		if len(line) < 4 {
			continue
		}
		result = append(result, change{Name: line[3:], Kind: strings.TrimSpace(line[:2])})
	}
	return result
}

func (d dotfiles) check(ctx context.Context) (inventory, error) {
	if _, err := d.git(ctx, "fetch", "--quiet", "--no-tags"); err != nil {
		return inventory{}, err
	}
	current, err := d.revisions(ctx)
	if err != nil {
		return inventory{}, err
	}
	out, err := d.chezmoi(ctx, d.repo, "status")
	if err != nil {
		return inventory{}, err
	}
	current.Changes = dotfileChanges(out)
	current.CanApply = current.Ahead == 0 && (current.Behind > 0 || len(current.Changes) > 0)
	return current, nil
}

func (d dotfiles) clean(ctx context.Context) error {
	tracked, err := d.git(ctx, "status", "--porcelain", "--untracked-files=no")
	if err != nil {
		return err
	}
	managed, err := d.git(ctx, "status", "--porcelain", "--untracked-files=normal", "--", "chezmoi")
	if err != nil {
		return err
	}
	if tracked != "" || managed != "" {
		return errors.New("The source checkout has local edits. Review them in Git before continuing.")
	}
	if _, err := d.git(ctx, "symbolic-ref", "--quiet", "HEAD"); err != nil {
		return errors.New("Switch the chezmoi checkout to its tracking branch.")
	}
	return nil
}

func (d dotfiles) preview(ctx context.Context, _ *packageTarget) (proposal, error) {
	if err := d.clean(ctx); err != nil {
		return proposal{}, err
	}
	plan, err := d.revisions(ctx)
	if err != nil {
		return proposal{}, err
	}
	if plan.Ahead > 0 {
		return proposal{}, errors.New("The source checkout has local commits. Reconcile it in Git first.")
	}

	source := d.repo
	if plan.Behind > 0 {
		temp, err := os.MkdirTemp("", "host-updates-preview-")
		if err != nil {
			return proposal{}, err
		}
		defer os.RemoveAll(temp)
		source = filepath.Join(temp, "source")
		if _, err := d.git(ctx, "worktree", "add", "--quiet", "--detach", source, plan.Upstream); err != nil {
			return proposal{}, err
		}
		defer func() {
			cleanup, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			_, _ = d.git(cleanup, "worktree", "remove", "--force", source)
		}()
	}

	out, err := d.chezmoi(ctx, source, "status")
	if err != nil {
		return proposal{}, err
	}
	patch, err := d.chezmoi(ctx, source, "diff", "--use-builtin-diff", "--color=false")
	if err != nil {
		return proposal{}, err
	}
	plan.Changes = dotfileChanges(out)
	plan.CanApply = len(plan.Changes) > 0 || plan.Behind > 0
	next := proposal{Inventory: plan, Fingerprint: fingerprint([]any{plan, patch})}
	if plan.CanApply {
		if _, err := d.chezmoi(ctx, source, "apply", "--dry-run", "--error-on-conflict"); err != nil {
			next.Inventory.CanApply = false
			next.Detail = "Preflight stopped. Resolve the conflict or template error in Terminal."
		}
	}
	return next, nil
}

func (d dotfiles) apply(ctx context.Context, p proposal) error {
	if err := d.clean(ctx); err != nil {
		return err
	}
	plan, err := d.revisions(ctx)
	if err != nil {
		return err
	}
	if plan.Revision != p.Inventory.Revision || plan.Upstream != p.Inventory.Upstream {
		return errPreviewChanged
	}
	if plan.Behind > 0 {
		if _, err := d.git(ctx, "merge", "--ff-only", "--quiet", plan.Upstream); err != nil {
			return err
		}
	}
	if _, err := d.chezmoi(ctx, d.repo, "apply", "--dry-run", "--error-on-conflict"); err != nil {
		return err
	}
	if _, err := d.chezmoi(ctx, d.repo, "apply", "--error-on-conflict"); err != nil {
		return errors.New("Dotfile apply was interrupted or failed. Check for changes before retrying.")
	}
	return nil
}
