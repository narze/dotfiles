---
name: upgrade
description: Update this machine's Collie installation and verify the running bridge.
disable-model-invocation: true
---

# Upgrade Collie

Use this procedure when the user invokes `/upgrade` in this dotfiles project to update Collie. Read the installed CLI's `collie help` and `collie docs upgrading` when its commands or install type differ from the steps below. Use the CLI as the source of truth for the available release and recovery commands.

1. **Record the starting state.** Run `command -v collie`, `collie version`, `collie status --plain`, and `collie update --status --plain`. Note the current version and any update already in progress. Record `git status --short` if working in this repository; leave existing changes alone.

2. **Run the read-only gate.** Run `collie update --check --plain`. A red gate blocks the update. If network or local service checks fail with `ENOTFOUND`, `EPERM`, or an unreachable bridge under a restricted shell, repeat the check with the access needed for GitHub, the local bridge, and the Herdr socket before diagnosing the service. Use `collie doctor --plain` to inspect a real red `doctor` result.

3. **Clear an `agent-sessions` gate only if it occurs.** Read the pane IDs from `collie doctor`. If Herdr control is needed, check `HERDR_ENV=1`, read `herdr --skill`, then inspect the named panes with `herdr agent list` and `herdr agent read`. Restart only the named sessions that lack IDs. Get the user's approval before interrupting another active pane unless they already authorized it. For an idle Codex pane, exit with `/exit`, wait until `herdr pane process-info --pane <pane-id>` shows the shell, and capture the printed `codex resume <session-id>` command. If `/exit` is still visible at the Codex prompt, submit Enter again and verify the process changed. Start it in the same pane with `herdr agent start <unique-name> --kind codex --pane <pane-id> -- resume <session-id>`. Confirm Herdr reports an `agent_session` ID. Preserve the user's worktree and resume the same session. For other agents, follow that agent's supported resume flow rather than guessing.

4. **Update.** Repeat `collie update --check --plain` until it is green. Run `collie update --plain` for the offered release in the current major. A major upgrade needs the user's explicit request and the installed release notes. If Collie reports a package-managed or Herdr-managed install, follow `collie docs upgrading` for that install instead of replacing its files directly.

5. **Wait for the handoff and verify.** `collie update` may return after staging while a child process swaps and restarts the service. Poll `collie update --status --plain` until it reports a terminal result. Then run `collie version`, `collie status --plain`, and `collie doctor --plain`. Completion requires the intended version to be served, a running bridge, and no red doctor checks. If the run rolls back, gets stuck, or is interrupted, report the recorded state and use the recovery command printed by Collie. Check `git status --short` again if step 1 recorded it.

Report the old and new versions, update result, bridge health, and any remaining issue.
