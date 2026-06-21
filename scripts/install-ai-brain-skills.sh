#!/bin/bash
# install-ai-brain-skills.sh
# Expose every ai-brain vault skill GLOBALLY by symlinking each skill directory under
# $AI_BRAIN_ROOT/.claude/skills/ into ~/.claude/skills/. After this runs, the vault's
# skills (/capture, /query, /task, /believe, /decide, ...) are invocable from ANY cwd.
#
# Single source of truth = the vault. Nothing is copied; we only create symlinks, so a
# skill edited or added in the vault is reflected globally on the next run (or immediately
# for existing links). The vault is a private repo, so no skill logic ever lands in this
# (public) dotfiles-shared repo.
#
# SAFE + IDEMPOTENT: we only ever remove entries in ~/.claude/skills/ that are symlinks
# pointing back into $AI_BRAIN_ROOT. Real directories (e.g. work-overlay skills like
# whats-next / close-group) are never touched.
set -uo pipefail

AI_BRAIN_ROOT="${AI_BRAIN_ROOT:-$HOME/workspaces/ai-brain}"
SRC="$AI_BRAIN_ROOT/.claude/skills"
DEST="$HOME/.claude/skills"

if [ ! -d "$SRC" ]; then
  echo "FATAL: vault skills dir not found: $SRC" >&2
  echo "       Set AI_BRAIN_ROOT correctly, or clone the ai-brain vault first." >&2
  exit 1
fi

mkdir -p "$DEST"

# 1) Prune stale symlinks that point into the vault but no longer resolve
#    (a skill was deleted/renamed in the vault). Only ever touch symlinks
#    whose target is under $AI_BRAIN_ROOT — never real dirs.
if [ -d "$DEST" ]; then
  for link in "$DEST"/* "$DEST"/.[!.]*; do
    [ -L "$link" ] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$AI_BRAIN_ROOT"/*)
        if [ ! -e "$link" ]; then
          echo "prune stale: $(basename "$link")"
          rm -f "$link"
        fi
        ;;
    esac
  done
fi

# 2) (Re)link every skill directory in the vault.
count=0
for dir in "$SRC"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  dest="$DEST/$name"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "skip (real dir, not ours): $name"   # protects overlay/work skills of the same name
    continue
  fi
  ln -sfn "$dir" "$dest"
  echo "link: $name"
  count=$((count + 1))
done

echo "Linked $count ai-brain skill(s) into $DEST"
