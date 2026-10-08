#!/usr/bin/env bash

# List GUI apps not installed via Homebrew Cask
#
# Usage:
#   ./macos/check-apps-homebrew.sh
#   ./macos/check-apps-homebrew.sh --strict-mas
#
# Environment:
#   APPS_HOMEBREW_ALLOWLIST  Override allowlist file path

set -euo pipefail

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALLOWLIST_FILE="${APPS_HOMEBREW_ALLOWLIST:-$SCRIPT_DIR/apps-homebrew-allowlist.txt}"
STRICT_MAS=0

usage() {
	cat <<'EOF'
Usage: check-apps-homebrew.sh [--strict-mas] [-h|--help]

Compare .app bundles in /Applications and ~/Applications against apps
managed by installed Homebrew casks (via Caskroom).

By default, Mac App Store apps (receipt present) and Apple system apps
(com.apple.*) are treated as managed. Use --strict-mas to also fail on
App Store apps.

Exit 1 when any unmanaged app remains after allowlisting.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--strict-mas)
		STRICT_MAS=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This check only runs on macOS" >&2
	exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
	echo "Homebrew (brew) is required" >&2
	exit 1
fi

CASKROOM="$(brew --prefix)/Caskroom"
if [[ ! -d "$CASKROOM" ]]; then
	echo "Homebrew Caskroom not found at $CASKROOM" >&2
	exit 1
fi

echo -e "${BOLD}Check: applications installed via Homebrew Cask${NC}"

# Collect .app basenames owned by installed casks
managed_file="$(mktemp)"
allowlist_file="$(mktemp)"
installed_file="$(mktemp)"
unmanaged_file="$(mktemp)"
mas_file="$(mktemp)"
apple_file="$(mktemp)"
trap 'rm -f "$managed_file" "$allowlist_file" "$installed_file" "$unmanaged_file" "$mas_file" "$apple_file"' EXIT

find "$CASKROOM" -maxdepth 4 -name "*.app" 2>/dev/null \
	| sed 's|.*/||' \
	| sort -u >"$managed_file"

# Allowlist (optional file)
if [[ -f "$ALLOWLIST_FILE" ]]; then
	grep -v '^[[:space:]]*#' "$ALLOWLIST_FILE" \
		| grep -v '^[[:space:]]*$' \
		| sed 's/[[:space:]]*$//' \
		| sort -u >"$allowlist_file"
else
	: >"$allowlist_file"
fi

# Installed apps (user + system Applications folders)
: >"$installed_file"
for apps_dir in /Applications "$HOME/Applications"; do
	if [[ -d "$apps_dir" ]]; then
		# shellcheck disable=SC2010
		ls "$apps_dir" | grep '\.app$' | sort -u >>"$installed_file" || true
	fi
done
sort -u -o "$installed_file" "$installed_file"

bundle_id_for_app() {
	local app_name="$1"
	local app_path=""
	local plist=""

	if [[ -d "/Applications/$app_name" ]]; then
		app_path="/Applications/$app_name"
	elif [[ -d "$HOME/Applications/$app_name" ]]; then
		app_path="$HOME/Applications/$app_name"
	else
		return 1
	fi

	plist="$app_path/Contents/Info.plist"
	if [[ ! -f "$plist" ]]; then
		return 1
	fi

	defaults read "$plist" CFBundleIdentifier 2>/dev/null || true
}

is_mas_app() {
	local app_name="$1"
	local app_path=""

	if [[ -d "/Applications/$app_name" ]]; then
		app_path="/Applications/$app_name"
	elif [[ -d "$HOME/Applications/$app_name" ]]; then
		app_path="$HOME/Applications/$app_name"
	else
		return 1
	fi

	[[ -f "$app_path/Contents/_MASReceipt/receipt" ]]
}

: >"$unmanaged_file"
: >"$mas_file"
: >"$apple_file"

while IFS= read -r app; do
	[[ -z "$app" ]] && continue

	if grep -Fxq "$app" "$managed_file"; then
		continue
	fi

	if grep -Fxq "$app" "$allowlist_file"; then
		continue
	fi

	bundle_id="$(bundle_id_for_app "$app" || true)"
	if [[ "$bundle_id" == com.apple.* ]]; then
		echo "$app" >>"$apple_file"
		continue
	fi

	if is_mas_app "$app"; then
		echo "$app" >>"$mas_file"
		if [[ "$STRICT_MAS" -eq 0 ]]; then
			continue
		fi
	fi

	echo "$app" >>"$unmanaged_file"
done <"$installed_file"

managed_count="$(wc -l <"$managed_file" | tr -d ' ')"
installed_count="$(wc -l <"$installed_file" | tr -d ' ')"
unmanaged_count="$(wc -l <"$unmanaged_file" | tr -d ' ')"
mas_count="$(wc -l <"$mas_file" | tr -d ' ')"
apple_count="$(wc -l <"$apple_file" | tr -d ' ')"
allowlist_count="$(wc -l <"$allowlist_file" | tr -d ' ')"

echo "  Scanned $installed_count app(s) in /Applications and ~/Applications"
echo "  Homebrew Cask manages $managed_count app bundle(s)"
echo "  Allowlisted: $allowlist_count"

if [[ "$apple_count" -gt 0 ]]; then
	echo -e "  ${YELLOW}Skipped $apple_count Apple system app(s) (com.apple.*)${NC}"
fi

if [[ "$mas_count" -gt 0 ]]; then
	if [[ "$STRICT_MAS" -eq 0 ]]; then
		echo -e "  ${YELLOW}Accepted $mas_count Mac App Store app(s) (use --strict-mas to fail these)${NC}"
		while IFS= read -r app; do
			[[ -n "$app" ]] && echo "    - $app"
		done <"$mas_file"
	else
		echo -e "  ${YELLOW}Mac App Store app(s) counted as unmanaged (--strict-mas)${NC}"
	fi
fi

if [[ "$unmanaged_count" -eq 0 ]]; then
	echo -e "  ${GREEN}PASS${NC}: all non-allowlisted apps are Homebrew Cask or App Store managed"
	PASS=$((PASS + 1))
else
	echo -e "  ${RED}FAIL${NC}: $unmanaged_count app(s) installed outside Homebrew Cask:"
	while IFS= read -r app; do
		[[ -n "$app" ]] && echo "    - $app"
	done <"$unmanaged_file"
	FAIL=$((FAIL + 1))
fi

echo ""
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ "$FAIL" -gt 0 ]]; then
	exit 1
fi
