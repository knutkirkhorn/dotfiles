#!/usr/bin/env bash

# Interactively open Raycast extensions from `extensions.txt` using the
# `raycast://` deeplink so the Raycast app takes over instead of the browser.
#
# Controls per extension:
#   y / <enter>  open this extension (default)
#   n            skip this extension
#   q            quit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_FILE="${1:-$SCRIPT_DIR/extensions.txt}"

if [ ! -f "$INPUT_FILE" ]; then
	echo "Extensions file not found: $INPUT_FILE" >&2
	exit 1
fi

# Only emit ANSI colors when stdout is a terminal.
if [ -t 1 ]; then
	GREEN=$'\033[32m'
	ORANGE=$'\033[38;5;208m'
	RESET=$'\033[0m'
else
	GREEN=""
	ORANGE=""
	RESET=""
fi

OK_MARK="${GREEN}✔${RESET}"
SKIP_MARK="${ORANGE}!${RESET}"

urls=()
titles=()
last_title=""

while IFS= read -r line || [ -n "$line" ]; do
	case "$line" in
		"") continue ;;
		\#*)
			# Capture the "# Title (name)" comment that precedes each URL.
			last_title="${line#\# }"
			;;
		https://www.raycast.com/*)
			path="${line#https://www.raycast.com/}"
			urls+=("raycast://extensions/${path}")
			titles+=("${last_title:-$path}")
			last_title=""
			;;
		raycast://*)
			urls+=("$line")
			titles+=("${last_title:-$line}")
			last_title=""
			;;
	esac
done <"$INPUT_FILE"

total=${#urls[@]}
if [ "$total" -eq 0 ]; then
	echo "No extensions found in $INPUT_FILE" >&2
	exit 1
fi

echo "Found $total Raycast extensions in $INPUT_FILE"
echo

opened=0
skipped=0

for i in "${!urls[@]}"; do
	url="${urls[$i]}"
	title="${titles[$i]}"
	idx=$((i + 1))

	printf '[%d/%d] %s\n      %s\n' "$idx" "$total" "$title" "$url"

	# Read from the controlling terminal so piping doesn't break the prompt.
	read -r -p "      open? [Y/n/q] " choice </dev/tty || choice="q"

	case "${choice:-y}" in
		y|Y|"")
			open "$url"
			opened=$((opened + 1))
			printf '      %s opened\n' "$OK_MARK"
			;;
		n|N)
			skipped=$((skipped + 1))
			printf '      %s skipped\n' "$SKIP_MARK"
			continue
			;;
		q|Q)
			echo "      quit"
			break
			;;
		*)
			skipped=$((skipped + 1))
			printf '      %s unknown choice, skipping\n' "$SKIP_MARK"
			continue
			;;
	esac
done

echo
echo "Done. Opened: $opened, skipped: $skipped, total: $total"
