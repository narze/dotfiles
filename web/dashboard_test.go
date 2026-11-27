package main

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

type fakeUpdater struct {
	review  proposal
	applies int
}

func (f *fakeUpdater) check(context.Context) (inventory, error) { return f.review.Inventory, nil }
func (f *fakeUpdater) preview(context.Context, *packageTarget) (proposal, error) {
	return f.review, nil
}
func (f *fakeUpdater) apply(context.Context, proposal) error { f.applies++; return nil }

func TestApplyRequiresUnchangedPreview(t *testing.T) {
	backend := &fakeUpdater{review: proposal{Inventory: inventory{CanApply: true}, Fingerprint: "before"}}
	d := newDashboard(map[string]updater{"brew": backend})
	ctx := context.Background()

	if err := d.apply(ctx, "brew", "unknown"); !errors.Is(err, errPreviewRequired) {
		t.Fatalf("unpreviewed apply: %v", err)
	}
	first, err := d.preview(ctx, "brew", nil)
	if err != nil {
		t.Fatal(err)
	}
	backend.review.Fingerprint = "after"
	if err := d.apply(ctx, "brew", first.Token); !errors.Is(err, errPreviewChanged) {
		t.Fatalf("stale apply: %v", err)
	}
	if backend.applies != 0 {
		t.Fatal("applied stale plan")
	}

	fresh, err := d.preview(ctx, "brew", nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := d.apply(ctx, "brew", fresh.Token); err != nil {
		t.Fatal(err)
	}
	if err := d.apply(ctx, "brew", fresh.Token); !errors.Is(err, errPreviewRequired) {
		t.Fatalf("replayed apply: %v", err)
	}
	if backend.applies != 1 {
		t.Fatalf("applied %d times", backend.applies)
	}
}

func TestBrowserWritesRejectCrossOrigin(t *testing.T) {
	handler := protect(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}), "http://127.0.0.1:8780", "")
	for _, tc := range []struct {
		origin, header string
		status         int
	}{
		{"https://elsewhere.test", "1", http.StatusForbidden},
		{"http://127.0.0.1:8780", "", http.StatusForbidden},
		{"http://127.0.0.1:8780", "1", http.StatusNoContent},
	} {
		req := httptest.NewRequest("POST", "http://127.0.0.1:8780/api/check", strings.NewReader("{}"))
		req.Header.Set("Origin", tc.origin)
		req.Header.Set("X-Update-Request", tc.header)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		if rec.Code != tc.status {
			t.Errorf("origin %q header %q: got %d want %d", tc.origin, tc.header, rec.Code, tc.status)
		}
	}
}

func TestPreviewExpires(t *testing.T) {
	backend := &fakeUpdater{review: proposal{Inventory: inventory{CanApply: true}, Fingerprint: "same"}}
	d := newDashboard(map[string]updater{"brew": backend})
	now := time.Now()
	d.now = func() time.Time { return now }
	p, err := d.preview(context.Background(), "brew", nil)
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(16 * time.Minute)
	if err := d.apply(context.Background(), "brew", p.Token); !errors.Is(err, errPreviewRequired) {
		t.Fatalf("expired apply: %v", err)
	}
}
