#!/usr/bin/env bash

git pull

# Copy files to ~
cp .aliases ~/.aliases
cp .functions ~/.functions
cp .bash_profile ~/.bash_profile
cp global.gitignore ~/.gitignore
# Used to hide the login message
cp .hushlogin ~/.hushlogin

# Set global gitignore
git config --global core.excludesfile ~/.gitignore

# Check if .extra exists and create it if it doesn't
if [ ! -f ~/.extra ]; then
	touch ~/.extra
fi

source ~/.bash_profile

echo "Refreshed dotfiles!"
