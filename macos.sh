#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Homebrew packages, taps, GUI apps and Mac App Store apps using Brewfile
brew bundle

# Install Node using Fast Node Manager (fnm)
fnm install 24

# Cleanup
brew cleanup

# macOS preferences
defaults write com.apple.finder ShowPathbar -bool true

echo "✔︎ Completed macOS setup"
