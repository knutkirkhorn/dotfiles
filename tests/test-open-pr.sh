#!/usr/bin/env bash

# Test script for the "open-pr" function from .functions
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

# Source the functions file to get open-pr
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../.functions"

setup_repo() {
	local remote_url="$1"

	TMPDIR_REPO=$(mktemp -d)
	cd "$TMPDIR_REPO"
	git init -b main --quiet
	git config user.email "test@test.com"
	git config user.name "Test"
	git remote add origin "$remote_url"
	git commit --allow-empty -m "Initial commit" --quiet
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

	if open-pr >/dev/null 2>&1; then
		echo -e "  ${RED}FAIL${NC}: $test_name"
		echo "    Expected open-pr to fail"
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

git checkout -b feature/my-cool-feature --quiet

OPENED_URL=""
open-pr

expected="https://github.com/user/my-project/pulls?q=is%3Apr%20is%3Aopen%20head%3Auser%3Afeature%2Fmy-cool-feature"
assert_url "URL opens GitHub pull requests filtered by current branch" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 2: GitHub SSH remote
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 2: GitHub SSH remote${NC}"
setup_repo "git@github.com:org/repo.git"

git checkout -b bugfix/fix-header --quiet

OPENED_URL=""
open-pr

expected="https://github.com/org/repo/pulls?q=is%3Apr%20is%3Aopen%20head%3Aorg%3Abugfix%2Ffix-header"
assert_url "URL normalized from GitHub SSH remote" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 3: GitLab SSH remote with subgroup
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 3: GitLab SSH remote with subgroup${NC}"
setup_repo "git@gitlab.com:group/subgroup/my-project.git"

git checkout -b feature/my-cool-feature --quiet

OPENED_URL=""
open-pr

expected="https://gitlab.com/group/subgroup/my-project/-/merge_requests?scope=all&state=opened&source_branch=feature%2Fmy-cool-feature"
assert_url "URL opens GitLab merge requests filtered by current branch" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 4: GitLab ssh:// remote with port
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 4: GitLab ssh:// remote with port${NC}"
setup_repo "ssh://git@gitlab.example.com:2222/group/my-project.git"

git checkout -b update-readme --quiet

OPENED_URL=""
open-pr

expected="https://gitlab.example.com/group/my-project/-/merge_requests?scope=all&state=opened&source_branch=update-readme"
assert_url "URL normalized from GitLab ssh:// remote with port" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 5: Unsupported host
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 5: Unsupported host${NC}"
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
