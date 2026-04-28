#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE='@lavamoat/preinstall-always-fail@3.0.0'

TMP_ROOT="$(mktemp -d "$REPO_ROOT/.tmp-npm-security-hardening.XXXXXX")"
HARDENED_HOME="$TMP_ROOT/home"
WORK_ROOT="$TMP_ROOT/work"
CACHE_ROOT="$TMP_ROOT/cache"

cleanup() {
	rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

run_with_home() {
	local home="$1"
	shift

	HOME="$home" XDG_CONFIG_HOME="$home/.config" "$@"
}

setup_hardened_home() {
	mkdir -p "$HARDENED_HOME" "$WORK_ROOT" "$CACHE_ROOT"
	run_with_home "$HARDENED_HOME" bash "$REPO_ROOT/npm/npm-security-hardening.sh"
}

setup_project() {
	local manager="$1"
	local name="$2"
	local project="$WORK_ROOT/$name"

	mkdir -p "$project"
	if [ "$manager" = "bun" ]; then
		printf '{"private":true,"trustedDependencies":["@lavamoat/preinstall-always-fail"],"dependencies":{}}\n' >"$project/package.json"
	else
		printf '{"private":true,"dependencies":{}}\n' >"$project/package.json"
	fi
	printf '%s\n' "$project"
}

install_with_manager() {
	local manager="$1"
	local project="$2"
	local home="$3"
	local cache_name="$4"
	local allow_scripts="${5:-false}"

	case "$manager" in
		npm)
			(
				cd "$project"
				run_with_home "$home" npm install "$PACKAGE" --package-lock=false --no-audit --no-fund --cache "$CACHE_ROOT/$cache_name"
			)
			;;
		pnpm)
			if [ "$allow_scripts" = "true" ]; then
				run_with_home "$home" pnpm add "$PACKAGE" --dir "$project" --store-dir "$CACHE_ROOT/$cache_name-store" --dangerously-allow-all-builds
			else
				run_with_home "$home" pnpm add "$PACKAGE" --dir "$project" --store-dir "$CACHE_ROOT/$cache_name-store"
			fi
			;;
		yarn)
			(
				cd "$project"
				run_with_home "$home" yarn add "$PACKAGE" --non-interactive --cache-folder "$CACHE_ROOT/$cache_name"
			)
			;;
		bun)
			(
				cd "$project"
				run_with_home "$home" bun add "$PACKAGE"
			)
			;;
		*)
			echo "Unknown package manager: $manager" >&2
			return 1
			;;
	esac
}

run_ignore_scripts_test() {
	local manager="$1"
	local control_home="$TMP_ROOT/$manager-control-home"
	local control_output="$TMP_ROOT/$manager-control.log"
	local hardened_output="$TMP_ROOT/$manager-hardened.log"
	local control_project
	local hardened_project

	echo -e "${BOLD}Test: $manager ignores lifecycle scripts${NC}"

	if ! command -v "$manager" >/dev/null 2>&1; then
		echo -e "  ${YELLOW}SKIP${NC}: $manager is not installed"
		SKIP=$((SKIP + 1))
		return
	fi

	mkdir -p "$control_home"
	control_project="$(setup_project "$manager" "$manager-control")"
	hardened_project="$(setup_project "$manager" "$manager-hardened")"

	if install_with_manager "$manager" "$control_project" "$control_home" "$manager-control" true >"$control_output" 2>&1; then
		echo -e "  ${RED}FAIL${NC}: $manager did not fail when lifecycle scripts were enabled"
		sed 's/^/    /' "$control_output"
		FAIL=$((FAIL + 1))
		return
	else
		echo -e "  ${GREEN}PASS${NC}: $manager fails when the canary lifecycle script runs"
		PASS=$((PASS + 1))
	fi

	if install_with_manager "$manager" "$hardened_project" "$HARDENED_HOME" "$manager-hardened" >"$hardened_output" 2>&1; then
		echo -e "  ${GREEN}PASS${NC}: $manager did not run the failing postinstall"
		PASS=$((PASS + 1))
	else
		echo -e "  ${RED}FAIL${NC}: $manager ran the failing postinstall or install failed"
		sed 's/^/    /' "$hardened_output"
		FAIL=$((FAIL + 1))
	fi
}

setup_hardened_home

run_ignore_scripts_test npm
run_ignore_scripts_test pnpm
run_ignore_scripts_test yarn
run_ignore_scripts_test bun

echo ""
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$SKIP skipped${NC}"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi
