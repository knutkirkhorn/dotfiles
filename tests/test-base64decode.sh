#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../.functions"

encoded='aGVsbG8gd29ybGQ='
expected='hello world'

actual="$(base64decode "$encoded")"

if [ "$actual" != "$expected" ]; then
	echo "FAIL: decoded output did not match expected value"
	echo "Expected: $expected"
	echo "Actual:   $actual"
	exit 1
fi

echo "PASS: base64decode decoded the input correctly"
