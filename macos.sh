#!/usr/bin/env bash

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Zerobrew
curl -sSL https://zerobrew.rs/install | bash

# Install Homebrew packages
# Specific taps
# jwt-cli (https://github.com/mike-engel/jwt-cli)
brew install mike-engel/jwt-cli/jwt-cli
# bun.com (https://github.com/oven-sh/homebrew-bun)
brew install oven-sh/bun/bun

# Install Homebrew packages using Zerobrew
zb bundle

# Install Homebrew GUI apps
brew install --cask \
	firefox \
	docker \
	visual-studio-code \
	cursor \
	raycast \
	spotify \
	tableplus \
	postman \
	ghostty \
	proxyman \
	git-credential-manager \
	mockoon \
	obsidian \
	android-platform-tools

# TODO: install node.js

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Cleanup
brew cleanup

# Install macOS apps from App Store
mas install 1611378436 # Pure Paste
mas install 6502579523 # Week Number
mas install 1632827132 # Camera Preview
mas install 1295203466 # Windows App (for remote desktop)
mas install 1604176982 # One Thing

# macOS preferences
defaults write com.apple.finder ShowPathbar -bool true
