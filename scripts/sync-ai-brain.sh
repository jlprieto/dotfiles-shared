#!/bin/bash
# sync-ai-brain.sh
# Reconcile the ai-brain vault across machines. Account-neutral and PULL-FIRST so it is
# safe to run unattended (LaunchAgent) on BOTH machines.
#
# This supersedes the old overlay night.sh, which used `git pull --ff-only origin main`
# and ABORTED whenever main had diverged (i.e. the other machine pushed since this one
# last ran) — a real failure mode for a timer. Here we fetch + merge instead of ff-only,
# commit local work BEFORE pulling, and never let one benign non-ff abort the whole run.
#
# Per-machine config is auto-derived: the "work branch" is the vault's currently checked-out
# branch (home-changes on HOME, work-changes on WORK), so no per-machine env is required.
# Override with AI_BRAIN_WORK_BRANCH / AI_BRAIN_MAIN_BRANCH / AI_BRAIN_ROOT if needed.
set -uo pipefail   # intentionally NO -e: we handle failures explicitly and keep going

AI_BRAIN_ROOT="${AI_BRAIN_ROOT:-$HOME/workspaces/ai-brain}"
MAIN_BRANCH="${AI_BRAIN_MAIN_BRANCH:-main}"

log() { printf '%s  %s\n' "$(date '+%F %T')" "$*"; }

cd "$AI_BRAIN_ROOT" 2>/dev/null || { log "FATAL: cannot cd to $AI_BRAIN_ROOT"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log "FATAL: $AI_BRAIN_ROOT is not a git repo"; exit 1; }

WORK_BRANCH="${AI_BRAIN_WORK_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
if [ "$WORK_BRANCH" = "$MAIN_BRANCH" ] || [ "$WORK_BRANCH" = "HEAD" ]; then
  log "FATAL: work branch resolves to '$WORK_BRANCH' (on main or detached). Check out this machine's work branch first."
  exit 1
fi

log "=== ai-brain sync: work=$WORK_BRANCH main=$MAIN_BRANCH root=$AI_BRAIN_ROOT ==="

git checkout "$WORK_BRANCH" || { log "FATAL: cannot checkout $WORK_BRANCH"; exit 1; }

# [1/5] Commit local changes first so nothing is lost before we integrate remote work.
git add -A
if git diff --cached --quiet; then
  log "[1/5] nothing to commit"
else
  git commit -m "vault sync $(date '+%F %T')" >/dev/null && log "[1/5] committed local changes"
fi

# [2/5] Bring main up to date from origin (fetch; ff if possible, tolerate divergence/offline).
git fetch origin || log "WARN: fetch failed (offline?) — continuing with local state"
git checkout "$MAIN_BRANCH" || { log "FATAL: cannot checkout $MAIN_BRANCH"; exit 1; }
if git merge --ff-only "origin/$MAIN_BRANCH" >/dev/null 2>&1; then
  log "[2/5] main fast-forwarded to origin"
else
  log "[2/5] main not ff from origin (diverged or no remote change) — reconciling via merge"
  git merge --no-edit "origin/$MAIN_BRANCH" >/dev/null 2>&1 || log "WARN: merge origin/main skipped (nothing to merge or conflict)"
fi

# [3/5] Merge this machine's work branch into main.
if ! git merge --no-edit "$WORK_BRANCH" >/dev/null 2>&1; then
  log "FATAL: merge $WORK_BRANCH -> $MAIN_BRANCH conflicted; aborting, manual fix needed"
  git merge --abort 2>/dev/null
  git checkout "$WORK_BRANCH" 2>/dev/null
  exit 1
fi

# [4/5] Push main, retrying once if the remote moved underneath us.
if ! git push origin "$MAIN_BRANCH" >/dev/null 2>&1; then
  log "[4/5] push main rejected; re-fetching and retrying"
  git fetch origin && git merge --no-edit "origin/$MAIN_BRANCH" >/dev/null 2>&1
  git push origin "$MAIN_BRANCH" >/dev/null 2>&1 || { log "FATAL: could not push main after retry"; git checkout "$WORK_BRANCH" 2>/dev/null; exit 1; }
fi
log "[4/5] main pushed"

# [5/5] Fast-forward the work branch back to main and push it.
git checkout "$WORK_BRANCH" || { log "FATAL: cannot return to $WORK_BRANCH"; exit 1; }
git merge --ff-only "$MAIN_BRANCH" >/dev/null 2>&1 || log "WARN: could not ff $WORK_BRANCH to $MAIN_BRANCH"
git push origin "$WORK_BRANCH" >/dev/null 2>&1 || log "WARN: could not push $WORK_BRANCH"
log "[5/5] $WORK_BRANCH synced"

log "=== ai-brain sync done ==="
