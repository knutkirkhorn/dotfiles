#!/usr/bin/env bash

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Homebrew packages
# jwt-cli (https://github.com/mike-engel/jwt-cli)
brew install mike-engel/jwt-cli/jwt-cli
brew install scrcpy

# Install Homebrew GUI apps
brew install --cask firefox docker visual-studio-code cursor raycast spotify tableplus postman ghostty proxyman git-credential-manager mockoon obsidian

# TODO: install node.js

# Install Bun
curl -fsSL https://bun.sh/install | bash
