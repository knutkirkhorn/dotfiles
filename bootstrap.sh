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

# Set global gitignore
git config --global core.excludesfile ~/.gitignore

# Check if .extra exists and create it if it doesn't
if [ ! -f ~/.extra ]; then
	touch ~/.extra
fi

source ~/.bash_profile

echo "Refreshed dotfiles!"
