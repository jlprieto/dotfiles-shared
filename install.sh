#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKER="# dotfiles-shared-managed"

BLOCK="${MARKER}
export DOTFILES_SHARED_DIR=\"$DOTFILES_DIR\"
[ -f \"\$DOTFILES_SHARED_DIR/shell/aliases.sh\" ] && source \"\$DOTFILES_SHARED_DIR/shell/aliases.sh\"
${MARKER}"

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ ! -f "$RC" ]; then
    touch "$RC"
  fi

  # Remove any previously managed block
  sed -i '' "/${MARKER}/,/${MARKER}/d" "$RC"

  # Append fresh block
  printf '\n%s\n' "$BLOCK" >> "$RC"
done

