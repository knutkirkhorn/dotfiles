#!/usr/bin/env bash

set -euo pipefail

DOMAIN="com.interversehq.InstantSpaceSwitcher"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACKED_PLIST="$SCRIPT_DIR/${DOMAIN}.plist"

usage() {
  cat <<EOF
Usage: $(basename "$0") <export|import|print>

Commands:
  export  Export current InstantSpaceSwitcher preferences into dotfiles
  import  Import tracked InstantSpaceSwitcher preferences from dotfiles
  print   Print the tracked plist for quick inspection
EOF
}

command="${1:-}"

case "$command" in
  export)
    mkdir -p "$SCRIPT_DIR"
    defaults export "$DOMAIN" "$TRACKED_PLIST"
    plutil -convert xml1 "$TRACKED_PLIST"
    echo "Exported $DOMAIN to $TRACKED_PLIST"
    ;;
  import)
    if [ ! -f "$TRACKED_PLIST" ]; then
      echo "Tracked plist not found: $TRACKED_PLIST" >&2
      exit 1
    fi

    defaults delete "$DOMAIN" >/dev/null 2>&1 || true
    defaults import "$DOMAIN" "$TRACKED_PLIST"
    killall cfprefsd >/dev/null 2>&1 || true

    echo "Imported $DOMAIN from $TRACKED_PLIST"
    echo "Restart InstantSpaceSwitcher if it is already running"
    ;;
  print)
    if [ ! -f "$TRACKED_PLIST" ]; then
      echo "Tracked plist not found: $TRACKED_PLIST" >&2
      echo "Run '$(basename "$0") export' to create it from current preferences" >&2
      exit 1
    fi
    python3 - "$TRACKED_PLIST" <<'PY'
import json
import plistlib
import sys

plist_path = sys.argv[1]

modifier_bits = [
    (256, "cmd"),
    (2048, "alt"),
    (4096, "ctrl"),
    (512, "shift"),
]

with open(plist_path, "rb") as fh:
    data = plistlib.load(fh)

pretty = {}
for key in sorted(data):
    value = data[key]
    if isinstance(value, bytes):
        try:
            decoded = value.decode("utf-8")
            parsed = json.loads(decoded)
            modifiers = parsed.get("modifiers")
            if isinstance(modifiers, int):
                parsed["modifiersLabel"] = "+".join(
                    label for bit, label in modifier_bits if modifiers & bit
                ) or "none"
            pretty[key] = parsed
        except (UnicodeDecodeError, json.JSONDecodeError):
            pretty[key] = value.hex()
    else:
        pretty[key] = value

print(json.dumps(pretty, indent=2, ensure_ascii=False, sort_keys=True))
PY
    ;;
  *)
    usage
    exit 1
    ;;
esac
