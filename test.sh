#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$DOTFILES_DIR/tests/test-open-gitlab-pr.sh"
bash "$DOTFILES_DIR/tests/test-base64decode.sh"
bash "$DOTFILES_DIR/tests/test-npm-security-hardening-ignore-scripts.sh"
