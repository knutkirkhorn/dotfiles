#!/usr/bin/env bash

# List all installed Raycast extensions and save them to a txt file.
# Each line contains the store URL so another machine can reinstall them by
# opening each URL (or by scripting `open` against the file).

set -euo pipefail

EXTENSIONS_DIR="${RAYCAST_EXTENSIONS_DIR:-$HOME/.config/raycast/extensions}"
OUTPUT_FILE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/extensions.txt}"

if [ ! -d "$EXTENSIONS_DIR" ]; then
	echo "Raycast extensions directory not found: $EXTENSIONS_DIR" >&2
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "jq is required but not installed. Install with: brew install jq" >&2
	exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

count=0
for pkg in "$EXTENSIONS_DIR"/*/package.json; do
	[ -e "$pkg" ] || continue

	# Some extensions use `owner` (orgs), fall back to `author`.
	read -r name owner_or_author title <<<"$(
		jq -r '[.name, (.owner.name // .owner // .author), (.title // "")] | @tsv' "$pkg"
	)"

	if [ -z "$name" ] || [ "$name" = "null" ] || [ -z "$owner_or_author" ] || [ "$owner_or_author" = "null" ]; then
		continue
	fi

	printf '# %s (%s)\nhttps://www.raycast.com/%s/%s\n' \
		"$title" "$name" "$owner_or_author" "$name" >>"$tmp_file"
	count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
	echo "No Raycast extensions found in $EXTENSIONS_DIR" >&2
	exit 1
fi

{
	printf '# Raycast extensions (%d) exported %s\n' "$count" "$(date '+%Y-%m-%d %H:%M:%S')"
	printf '# Reinstall extensions by running `raycast/install-extensions.sh`.\n\n'
	cat "$tmp_file"
} >"$OUTPUT_FILE"

echo "Wrote $count Raycast extensions to $OUTPUT_FILE"
