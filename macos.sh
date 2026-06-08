#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Zerobrew
curl -sSL https://zerobrew.rs/install | bash

# Install Homebrew packages
# Specific taps
# jwt-cli (https://github.com/mike-engel/jwt-cli)
brew install mike-engel/jwt-cli/jwt-cli
# Install Bun (bun.com / https://github.com/oven-sh/homebrew-bun)
brew install oven-sh/bun/bun
# Instant Space Switcher (https://github.com/jurplel/InstantSpaceSwitcher)
brew install --cask jurplel/tap/instant-space-switcher

# Install Homebrew packages using Zerobrew
zb bundle

# Install Homebrew packages using Brewfile
brew bundle --file brew.Brewfile

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
	android-platform-tools \
	crystalfetch \
	stats \
	thaw

# Install mysql, did not work through zerobrew (test again later):
brew install mysql-client

# Install Node using Fast Node Manager (fnm)
fnm install 24

# Cleanup
brew cleanup

# macOS preferences
defaults write com.apple.finder ShowPathbar -bool true

echo "✔︎ Completed macOS setup"
