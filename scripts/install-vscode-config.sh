#!/bin/bash
# install-vscode-config.sh
# Apply the shared VS Code config to this machine's live VS Code user dir:
#   - keybindings.json  -> symlink  (fully generic; same on every machine)
#   - settings.json      -> jq merge of the shared generic base × this machine's
#                           overlay/editors/vscode/settings.local.json  (machine keys win)
#
# The live settings.json is GENERATED from (shared base) × (machine local). Put machine-specific
# settings (extensions, account paths, per-machine tweaks) in the overlay's settings.local.json — NOT
# in the live file, which is overwritten on each run (a timestamped backup is made first, so nothing
# is lost). Idempotent.
#
# Target dir: $VSCODE_USER_DIR if set, else stable VS Code (~/Library/Application Support/Code/User).
# (For VS Code Insiders, pass VSCODE_USER_DIR=".../Code - Insiders/User".)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SHARED="$DOTFILES_DIR/shared/editors/vscode"
LOCAL="$DOTFILES_DIR/overlay/editors/vscode/settings.local.json"
DEST="${VSCODE_USER_DIR:-$HOME/Library/Application Support/Code/User}"

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not found (needed to merge settings)"; exit 1; }
[ -f "$SHARED/settings.json" ] || { echo "FATAL: missing $SHARED/settings.json"; exit 1; }

if [ ! -d "$DEST" ]; then
  echo "VS Code user dir not found: $DEST — skipping (is VS Code installed?)."
  exit 0
fi

stamp="$(date +%Y%m%d-%H%M%S)"

# --- keybindings.json: symlink shared -> live (back up a real file first) ---
kb_dest="$DEST/keybindings.json"
if [ -e "$kb_dest" ] && [ ! -L "$kb_dest" ]; then
  cp "$kb_dest" "$kb_dest.backup-$stamp" && echo "backed up keybindings.json -> keybindings.json.backup-$stamp"
fi
ln -sfn "$SHARED/keybindings.json" "$kb_dest" && echo "linked keybindings.json -> shared"

# --- settings.json: regenerate from shared base × machine local (back up first) ---
set_dest="$DEST/settings.json"
[ -e "$set_dest" ] && [ ! -L "$set_dest" ] && cp "$set_dest" "$set_dest.backup-$stamp" && echo "backed up settings.json -> settings.json.backup-$stamp"

local_tmp="$(mktemp)"
if [ -f "$LOCAL" ]; then cp "$LOCAL" "$local_tmp"; else echo '{}' > "$local_tmp"; fi
if ! jq -e . "$local_tmp" >/dev/null 2>&1; then echo "FATAL: $LOCAL is not valid JSON"; rm -f "$local_tmp"; exit 1; fi

if jq -s '.[0] * .[1]' "$SHARED/settings.json" "$local_tmp" > "$set_dest.new"; then
  mv "$set_dest.new" "$set_dest"
  echo "wrote settings.json = shared base × $( [ -f "$LOCAL" ] && echo "overlay local" || echo "(no local overrides)" )"
else
  echo "FATAL: jq merge failed; left settings.json untouched"; rm -f "$set_dest.new" "$local_tmp"; exit 1
fi
rm -f "$local_tmp"
echo "VS Code config applied to: $DEST"
