#!/usr/bin/env bash
# Checks bin/quickshell-runtime-cleanup against a fake quickshell runtime dir.
# No Hyprland session needed. Run: tests/quickshell-runtime-cleanup.sh
set -u
cd "$(dirname "$0")/.." || exit 1
script=chezmoi/bin/executable_quickshell-runtime-cleanup
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }

tmp=$(mktemp -d)
holder=
cleanup() { [[ -n $holder ]] && kill "$holder" 2>/dev/null; rm -rf "$tmp"; }
trap cleanup EXIT

qs=$tmp/quickshell
mkdir -p "$qs/by-id" "$qs/by-pid"
old=$(date -d '-1 hour' '+%Y%m%d%H%M.%S')

# Live instance: its instance.lock is held open by a running process,
# and both logs are above the 64 KiB limit used below.
mkdir "$qs/by-id/live"
touch "$qs/by-id/live/instance.lock"
head -c 200000 /dev/zero > "$qs/by-id/live/log.qslog"
head -c 200000 /dev/zero > "$qs/by-id/live/log.log"
tail -f /dev/null 3< "$qs/by-id/live/instance.lock" &
holder=$!
ln -s "$qs/by-id/live" "$qs/by-pid/$holder"

# Live instance with a small log: must not be touched.
mkdir "$qs/by-id/small"
touch "$qs/by-id/small/instance.lock"
head -c 1000 /dev/zero > "$qs/by-id/small/log.qslog"
exec 4< "$qs/by-id/small/instance.lock"

# Dead instance: nothing holds its lock, and it is old.
mkdir "$qs/by-id/dead"
touch "$qs/by-id/dead/instance.lock"
head -c 200000 /dev/zero > "$qs/by-id/dead/log.qslog"
touch -t "$old" "$qs/by-id/dead"
ln -s "$qs/by-id/dead" "$qs/by-pid/999999"

# Instance that is starting now: no lock holder yet, but too new to reap.
mkdir "$qs/by-id/new"
touch "$qs/by-id/new/instance.lock"

t "script exists and is executable" test -x "$script"
QS_RUNTIME_DIR=$qs QS_LOG_MAX_KB=64 "$script" > "$tmp/out" 2>&1
t "script exits 0" test $? -eq 0

t "dead instance dir is removed" test ! -e "$qs/by-id/dead"
t "dangling by-pid link is removed" test ! -L "$qs/by-pid/999999"
t "new instance dir is kept" test -d "$qs/by-id/new"
t "live instance dir is kept" test -d "$qs/by-id/live"
t "live by-pid link is kept" test -L "$qs/by-pid/$holder"
t "large live log.qslog is truncated" test ! -s "$qs/by-id/live/log.qslog"
t "large live log.log is truncated" test ! -s "$qs/by-id/live/log.log"
t "small live log is kept" test "$(stat -c %s "$qs/by-id/small/log.qslog")" -eq 1000
t "live lock file is kept" test -e "$qs/by-id/live/instance.lock"
t "actions are reported" grep -q "removed dead instance" "$tmp/out"

exec 4<&-
t "missing runtime dir is not an error" env QS_RUNTIME_DIR="$tmp/none" "$script"
exit $fail
