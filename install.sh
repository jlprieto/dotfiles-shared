#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_LINE="[ -f \"$DOTFILES_DIR/shell/aliases.sh\" ] && source \"$DOTFILES_DIR/shell/aliases.sh\""

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ ! -f "$RC" ]; then
    touch "$RC"
  fi

  if ! grep -Fq "$SOURCE_LINE" "$RC"; then
    printf '\n%s\n' "$SOURCE_LINE" >> "$RC"
  fi
done

