#!/usr/bin/env bash

git pull

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink files to ~
ln -sf "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
ln -sf "$DOTFILES_DIR/.functions" "$HOME/.functions"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/global.gitignore" "$HOME/.gitignore"
# Used to hide the login message
ln -sf "$DOTFILES_DIR/.hushlogin" "$HOME/.hushlogin"

# Copy Cursor rules to home directory
CURSOR_RULES_DIR="$HOME/.cursor/rules"
mkdir -p "$CURSOR_RULES_DIR"
cp "$DOTFILES_DIR/.cursor/rules/general-coding-practices.mdc" "$CURSOR_RULES_DIR/general-coding-practices.mdc"

# Set global gitignore
git config --global core.excludesfile ~/.gitignore

# Check if .extra exists and create it if it doesn't
if [ ! -f ~/.extra ]; then
	touch ~/.extra
fi

source ~/.bash_profile

echo "Refreshed dotfiles!"
