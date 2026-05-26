#!/usr/bin/env bash

# Test script for the "open-repo" function from .functions
# Uses temporary git repos and mocks `open` to capture the URL

set -euo pipefail

PASS=0
FAIL=0

# Color constants
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Override `open` so we capture the URL instead of launching a browser
open() {
	OPENED_URL="$1"
}

# Source the functions file to get open-repo
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../.functions"

setup_repo() {
	local remote_url="$1"

	TMPDIR_REPO=$(mktemp -d)
	cd "$TMPDIR_REPO"
	git init -b main --quiet
	git remote add origin "$remote_url"
}

cleanup_repo() {
	cd "$SCRIPT_DIR"
	rm -rf "$TMPDIR_REPO"
}

assert_url() {
	local test_name="$1"
	local expected="$2"
	local actual="$OPENED_URL"

	if [ "$actual" = "$expected" ]; then
		echo -e "  ${GREEN}PASS${NC}: $test_name"
		PASS=$((PASS + 1))
	else
		echo -e "  ${RED}FAIL${NC}: $test_name"
		echo "    Expected: $expected"
		echo "    Actual:   $actual"
		FAIL=$((FAIL + 1))
	fi
}

assert_failure() {
	local test_name="$1"

	if open-repo >/dev/null 2>&1; then
		echo -e "  ${RED}FAIL${NC}: $test_name"
		echo "    Expected open-repo to fail"
		FAIL=$((FAIL + 1))
	else
		echo -e "  ${GREEN}PASS${NC}: $test_name"
		PASS=$((PASS + 1))
	fi
}

# --------------------------------------------------------------------------
# Test 1: GitHub HTTPS remote
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 1: GitHub HTTPS remote${NC}"
setup_repo "https://github.com/user/my-project.git"

OPENED_URL=""
open-repo

assert_url "URL normalized from GitHub HTTPS remote" "https://github.com/user/my-project"
cleanup_repo

# --------------------------------------------------------------------------
# Test 2: GitLab SSH remote
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 2: GitLab SSH remote${NC}"
setup_repo "git@gitlab.com:group/subgroup/my-project.git"

OPENED_URL=""
open-repo

assert_url "URL normalized from GitLab SSH remote" "https://gitlab.com/group/subgroup/my-project"
cleanup_repo

# --------------------------------------------------------------------------
# Test 3: GitLab ssh:// remote with port
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 3: GitLab ssh:// remote with port${NC}"
setup_repo "ssh://git@gitlab.example.com:2222/group/my-project.git"

OPENED_URL=""
open-repo

assert_url "URL normalized from GitLab ssh:// remote" "https://gitlab.example.com/group/my-project"
cleanup_repo

# --------------------------------------------------------------------------
# Test 4: Unsupported host
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 4: Unsupported host${NC}"
setup_repo "https://bitbucket.org/user/my-project.git"

OPENED_URL=""
assert_failure "Non-GitHub/GitLab remote fails"
cleanup_repo

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi
