#!/usr/bin/env bash
# Install repo sudo_local PAM snippet for Touch ID sudo (macOS)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/pam.d/sudo_local"
DEST="/etc/pam.d/sudo_local"
SUDO_PAM="/etc/pam.d/sudo"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Skipping: not macOS"
	exit 0
fi

if [[ ! -f "$SRC" ]]; then
	echo "Missing source file: $SRC" >&2
	exit 1
fi

if [[ ! -f "$SUDO_PAM" ]]; then
	echo "Missing $SUDO_PAM (unexpected on macOS)" >&2
	exit 1
fi

if ! grep -qE '^[[:space:]]*auth[[:space:]]+include[[:space:]]+sudo_local[[:space:]]*$' "$SUDO_PAM"; then
	echo "Warning: $SUDO_PAM has no 'auth include sudo_local' line." >&2
	echo "Touch ID will not apply until Apple-style sudo PAM includes sudo_local (check macOS version)." >&2
fi

echo "Installing $DEST from dotfiles (sudo required)..."
sudo install -o root -g wheel -m 444 "$SRC" "$DEST"
echo "Done. Open a new terminal and run: sudo -v"
