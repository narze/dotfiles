package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"sync"
	"time"
)

const previewLifetime = 15 * time.Minute

var (
	errPreviewRequired = errors.New("Create a new preview before applying.")
	errPreviewChanged  = errors.New("The update plan changed. Review a new preview.")
)

type change struct {
	Name      string `json:"name"`
	Current   string `json:"current,omitempty"`
	Available string `json:"available,omitempty"`
	Kind      string `json:"kind,omitempty"`
	Pinned    bool   `json:"pinned,omitempty"`
}

type inventory struct {
	Changes  []change `json:"changes,omitempty"`
	Revision string   `json:"revision,omitempty"`
	Upstream string   `json:"upstream,omitempty"`
	Ahead    int      `json:"ahead,omitempty"`
	Behind   int      `json:"behind,omitempty"`
	CanApply bool     `json:"canApply"`
}

type packageTarget struct {
	Name string `json:"name"`
	Kind string `json:"kind"`
}

type proposal struct {
	Inventory   inventory      `json:"inventory"`
	Package     *packageTarget `json:"package,omitempty"`
	Detail      string         `json:"detail,omitempty"`
	Token       string         `json:"token"`
	Expires     time.Time      `json:"expires"`
	Fingerprint string         `json:"-"`
}

type updater interface {
	check(context.Context) (inventory, error)
	preview(context.Context, *packageTarget) (proposal, error)
	apply(context.Context, proposal) error
}

type section struct {
	Inventory inventory `json:"inventory"`
	Preview   *proposal `json:"preview,omitempty"`
	CheckedAt time.Time `json:"checkedAt,omitzero"`
	Error     string    `json:"error,omitempty"`
}

type activity struct {
	Message string    `json:"message"`
	Failed  bool      `json:"failed"`
	At      time.Time `json:"at"`
}

type dashboard struct {
	mu       sync.Mutex
	backends map[string]updater
	sections map[string]section
	busy     string
	last     *activity
	now      func() time.Time
}

func newDashboard(backends map[string]updater) *dashboard {
	d := &dashboard{backends: backends, sections: make(map[string]section), now: time.Now}
	for name := range backends {
		d.sections[name] = section{}
	}
	return d
}

func (d *dashboard) check(ctx context.Context, name string) error {
	next, err := d.backends[name].check(ctx)
	d.storeInventory(name, next, err)
	return err
}

func (d *dashboard) checkBrewInventory(ctx context.Context) error {
	next, err := (homebrew{}).outdated(ctx)
	d.storeInventory("brew", next, err)
	return err
}

func (d *dashboard) storeInventory(name string, next inventory, err error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	current := d.sections[name]
	current.Preview = nil
	if err == nil {
		current.Inventory = next
		current.CheckedAt = d.now()
		current.Error = ""
	} else {
		current.Error = err.Error()
	}
	d.sections[name] = current
}

func (d *dashboard) preview(ctx context.Context, name string, target *packageTarget) (proposal, error) {
	d.mu.Lock()
	current := d.sections[name]
	current.Preview = nil
	d.sections[name] = current
	d.mu.Unlock()

	next, err := d.backends[name].preview(ctx, target)
	if err != nil {
		return proposal{}, err
	}
	next.Package = target
	if next.Inventory.CanApply {
		var token [24]byte
		if _, err := rand.Read(token[:]); err != nil {
			return proposal{}, err
		}
		next.Token = hex.EncodeToString(token[:])
		next.Expires = d.now().Add(previewLifetime)
	}
	d.mu.Lock()
	current = d.sections[name]
	current.Preview = &next
	d.sections[name] = current
	d.mu.Unlock()
	return next, nil
}

func (d *dashboard) reviewedPlan(ctx context.Context, name, token string, singlePackage bool) (proposal, error) {
	d.mu.Lock()
	current := d.sections[name]
	saved := current.Preview
	if saved == nil || token == "" || saved.Token != token || !d.now().Before(saved.Expires) || (singlePackage && saved.Package == nil) {
		d.mu.Unlock()
		return proposal{}, errPreviewRequired
	}
	current.Preview = nil
	d.sections[name] = current
	d.mu.Unlock()

	next, err := d.backends[name].preview(ctx, saved.Package)
	if err != nil {
		return proposal{}, err
	}
	if saved.Fingerprint != next.Fingerprint || !next.Inventory.CanApply {
		return proposal{}, errPreviewChanged
	}
	return next, nil
}

func (d *dashboard) apply(ctx context.Context, name, token string) error {
	next, err := d.reviewedPlan(ctx, name, token, false)
	if err != nil {
		return err
	}
	return d.backends[name].apply(ctx, next)
}

func (d *dashboard) begin(label string) bool {
	d.mu.Lock()
	if d.busy != "" {
		d.mu.Unlock()
		return false
	}
	d.busy = label
	d.mu.Unlock()

	return true
}

func (d *dashboard) finish(message string, failed bool) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.last = &activity{Message: message, Failed: failed, At: d.now()}
	d.busy = ""
}

func (d *dashboard) start(operation, name, token string, target *packageTarget) bool {
	label := operation
	if name != "" {
		label += " " + name
	}
	if !d.begin(label) {
		return false
	}
	go func() {
		timeout := 10 * time.Minute
		if operation == "apply" {
			timeout = time.Hour
		}
		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()

		var err error
		message := "Checks finished."
		switch operation {
		case "check":
			for _, key := range []string{"dotfiles", "brew"} {
				err = errors.Join(err, d.check(ctx, key))
			}
		case "preview":
			_, err = d.preview(ctx, name, target)
			message = "Preview ready."
		case "apply":
			err = d.apply(ctx, name, token)
			message = "Update finished."
			if err == nil {
				if checkErr := d.check(ctx, name); checkErr != nil {
					message = "Update finished. The follow-up check failed."
				}
			}
		}

		if err != nil {
			message = err.Error()
			if operation == "check" {
				message = "A check failed. See the affected section."
			}
		}
		d.finish(message, err != nil)
	}()
	return true
}
