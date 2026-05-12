#!/usr/bin/env bash

git pull --quiet

BOOTSTRAP_PATH="${BASH_SOURCE[0]:-}"
if [ -n "${ZSH_VERSION:-}" ]; then
	BOOTSTRAP_PATH="$(eval 'printf "%s\n" "${(%):-%x}"')"
fi
DOTFILES_DIR="$(cd "$(dirname "$BOOTSTRAP_PATH")" && pwd)"

# Symlink files to ~
ln -sf "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
ln -sf "$DOTFILES_DIR/.functions" "$HOME/.functions"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/global.gitignore" "$HOME/.gitignore"

# Make sure .zshrc imports .bash_profile
ZSHRC_FILE="$HOME/.zshrc"
touch "$ZSHRC_FILE"
if ! grep -Fq "source ~/.bash_profile" "$ZSHRC_FILE"; then
	{
		echo
		echo "# Include bash_profile"
		echo "if [ -f ~/.bash_profile ]; then"
		echo "    source ~/.bash_profile"
		echo "fi"
	} >>"$ZSHRC_FILE"
fi

# Used to hide the login message
ln -sf "$DOTFILES_DIR/.hushlogin" "$HOME/.hushlogin"

# Symlink ~/.agents to repo .agents when safe
if [ -e "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ]; then
	echo "Skipping .agents symlink: $HOME/.agents exists and is not a symlink"
	echo "Cleanup before continuing..."
	exit 1
else
	ln -sfn "$DOTFILES_DIR/.agents" "$HOME/.agents"
fi

# Copy Cursor rules to home directory
CURSOR_RULES_DIR="$HOME/.cursor/rules"
mkdir -p "$CURSOR_RULES_DIR"
cp "$DOTFILES_DIR/.cursor/rules/general-coding-practices.mdc" "$CURSOR_RULES_DIR/general-coding-practices.mdc"
cp "$DOTFILES_DIR/.cursor/rules/javascript-typescript.mdc" "$CURSOR_RULES_DIR/javascript-typescript.mdc"
cp "$DOTFILES_DIR/.cursor/rules/prefer-uv-over-pip.mdc" "$CURSOR_RULES_DIR/prefer-uv-over-pip.mdc"
cp "$DOTFILES_DIR/.cursor/rules/prefer-zb-over-brew.mdc" "$CURSOR_RULES_DIR/prefer-zb-over-brew.mdc"

# Symlink launchd jobs
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"
ln -sfn "$DOTFILES_DIR/scripts/launchd/com.knut.clickup-init-week.plist" "$LAUNCH_AGENTS_DIR/com.knut.clickup-init-week.plist"
# Reload launchd jobs
launchctl unload "$LAUNCH_AGENTS_DIR/com.knut.clickup-init-week.plist" 2>/dev/null
launchctl load "$LAUNCH_AGENTS_DIR/com.knut.clickup-init-week.plist"
launchctl start com.knut.clickup-init-week

# Set global gitignore
git config --global core.excludesfile ~/.gitignore

# Check if .extra exists and create it if it doesn't
if [ ! -f ~/.extra ]; then
	touch ~/.extra
fi

# Skip shellcheck for this file, we are already validating the one in the repo anyway
# shellcheck source=/dev/null
source ~/.bash_profile

echo "Refreshed dotfiles!"
