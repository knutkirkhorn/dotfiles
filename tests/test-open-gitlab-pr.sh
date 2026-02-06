#!/usr/bin/env bash

# Test script for the "open-gitlab-pr" function from .functions
# Uses temporary git repos and mocks `open` to capture the URL.

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

# Source the functions file to get open-gitlab-pr
source "$SCRIPT_DIR/../.functions"

# Helper to set up a fresh temporary git repo with a remote
setup_repo() {
	local remote_url="$1"
	local default_branch="${2:-main}"

	TMPDIR_REPO=$(mktemp -d)
	cd "$TMPDIR_REPO"
	git init -b "$default_branch" --quiet
	git config user.email "test@test.com"
	git config user.name "Test"
	git remote add origin "$remote_url"
	# Set up the symbolic ref so the function can detect the default branch
	git symbolic-ref "refs/remotes/origin/HEAD" "refs/remotes/origin/$default_branch"
	# Create an initial commit on the default branch
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

# --------------------------------------------------------------------------
# Test 1: Multiple commits – PR title derived from branch name
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 1: Multiple commits - title from branch name${NC}"
setup_repo "https://gitlab.com/user/my-project.git"

git checkout -b feature/my-cool-feature --quiet
git commit --allow-empty -m "First feature commit" --quiet
git commit --allow-empty -m "Second feature commit" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/user/my-project/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature/my-cool-feature&merge_request%5Btitle%5D=My%20cool%20feature"
assert_url "URL with title from branch name" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 2: Single commit – PR title derived from commit message
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 2: Single commit - title from commit message${NC}"
setup_repo "https://gitlab.com/user/my-project.git"

git checkout -b feature/some-branch --quiet
git commit --allow-empty -m "Fix the login bug" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/user/my-project/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature/some-branch&merge_request%5Btitle%5D=Fix%20the%20login%20bug"
assert_url "URL with title from commit message" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 3: Remote URL without .git suffix
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 3: Remote URL without .git suffix${NC}"
setup_repo "https://gitlab.com/user/another-project"

git checkout -b bugfix/fix-header --quiet
git commit --allow-empty -m "Fix header styling" --quiet
git commit --allow-empty -m "Add tests for header" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/user/another-project/-/merge_requests/new?merge_request%5Bsource_branch%5D=bugfix/fix-header&merge_request%5Btitle%5D=Fix%20header"
assert_url "URL without .git suffix in remote" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 4: Branch name without prefix (no slash)
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 4: Branch name without prefix (no slash)${NC}"
setup_repo "https://gitlab.com/org/repo.git"

git checkout -b update-readme --quiet
git commit --allow-empty -m "First commit" --quiet
git commit --allow-empty -m "Second commit" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/org/repo/-/merge_requests/new?merge_request%5Bsource_branch%5D=update-readme&merge_request%5Btitle%5D=Update%20readme"
assert_url "URL with branch name without prefix" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 5: Single commit with special characters in message
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 5: Single commit - message with special characters${NC}"
setup_repo "https://gitlab.com/team/app.git"

git checkout -b fix/auth-flow --quiet
git commit --allow-empty -m "Hallå wårld" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/team/app/-/merge_requests/new?merge_request%5Bsource_branch%5D=fix/auth-flow&merge_request%5Btitle%5D=Hallå%20wårld"
assert_url "URL with commit message containing spaces" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 6: Default branch is "master" instead of "main"
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 6: Default branch is 'master'${NC}"
setup_repo "https://gitlab.com/org/legacy-repo.git" "master"

git checkout -b feature/new-thing --quiet
git commit --allow-empty -m "Add new thing" --quiet
git commit --allow-empty -m "Polish new thing" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/org/legacy-repo/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature/new-thing&merge_request%5Btitle%5D=New%20thing"
assert_url "URL with master as default branch" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Test 7: Single commit with slash in commit message
# --------------------------------------------------------------------------
echo -e "${BOLD}Test 7: Single commit - message with slash${NC}"
setup_repo "https://gitlab.com/org/repo.git"

git checkout -b feature/add-shadcn-ui-mcp-server --quiet
git commit --allow-empty -m "Add shadcn/ui MCP server" --quiet

OPENED_URL=""
open-gitlab-pr

expected="https://gitlab.com/org/repo/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature/add-shadcn-ui-mcp-server&merge_request%5Btitle%5D=Add%20shadcn/ui%20MCP%20server"
assert_url "URL with slash in commit message" "$expected"
cleanup_repo

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi
