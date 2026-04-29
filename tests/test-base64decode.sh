#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../.functions"

encoded='aGVsbG8gd29ybGQ='
expected='hello world'

actual="$(base64decode "$encoded")"

echo -e "${BOLD}Test: base64decode decodes input${NC}"

if [ "$actual" != "$expected" ]; then
	echo -e "  ${RED}FAIL${NC}: decoded output did not match expected value"
	echo "    Expected: $expected"
	echo "    Actual:   $actual"
	FAIL=$((FAIL + 1))
else
	echo -e "  ${GREEN}PASS${NC}: base64decode decoded the input correctly"
	PASS=$((PASS + 1))
fi

echo ""
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi
