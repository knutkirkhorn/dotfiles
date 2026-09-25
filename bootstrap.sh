#!/usr/bin/env bash

git pull --quiet

BOOTSTRAP_PATH="${BASH_SOURCE[0]:-}"
if [ -n "${ZSH_VERSION:-}" ]; then
	BOOTSTRAP_PATH="$(eval 'printf "%s\n" "${(%):-%x}"')"
fi
DOTFILES_DIR="$(cd "$(dirname "$BOOTSTRAP_PATH")" && pwd)"

# Read only AGENT_EXTRAS_SOURCE from .env so other secrets are not loaded into the shell
DOTFILES_ENV_FILE="$DOTFILES_DIR/.env"
if [ -z "${AGENT_EXTRAS_SOURCE:-}" ] && [ -f "$DOTFILES_ENV_FILE" ]; then
	AGENT_EXTRAS_SOURCE="$(sed -n 's/^AGENT_EXTRAS_SOURCE=//p' "$DOTFILES_ENV_FILE" | tail -n 1 | tr -d "\"'")"
fi

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

# Copy agent configuration so local and external files can coexist
if [ -L "$HOME/.agents" ]; then
	AGENTS_LINK_TARGET="$(readlink "$HOME/.agents")"
	if [ "$AGENTS_LINK_TARGET" != "$DOTFILES_DIR/.agents" ]; then
		echo "Cannot replace .agents symlink: $HOME/.agents points to $AGENTS_LINK_TARGET"
		return 1 2>/dev/null || exit 1
	fi
	rm "$HOME/.agents"
fi
mkdir -p "$HOME/.agents"
cp -R "$DOTFILES_DIR/.agents/." "$HOME/.agents/"

# Copy Cursor rules to home directory
CURSOR_RULES_DIR="$HOME/.cursor/rules"
mkdir -p "$CURSOR_RULES_DIR"
cp "$DOTFILES_DIR/.cursor/rules/general-coding-practices.mdc" "$CURSOR_RULES_DIR/general-coding-practices.mdc"
cp "$DOTFILES_DIR/.cursor/rules/docker-compose.mdc" "$CURSOR_RULES_DIR/docker-compose.mdc"
cp "$DOTFILES_DIR/.cursor/rules/javascript-typescript.mdc" "$CURSOR_RULES_DIR/javascript-typescript.mdc"
cp "$DOTFILES_DIR/.cursor/rules/prefer-uv-over-pip.mdc" "$CURSOR_RULES_DIR/prefer-uv-over-pip.mdc"
cp "$DOTFILES_DIR/.cursor/rules/prefer-zb-over-brew.mdc" "$CURSOR_RULES_DIR/prefer-zb-over-brew.mdc"

# Copy Cursor skills to home directory
CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
mkdir -p "$CURSOR_SKILLS_DIR/iso-compliance-review"
cp "$DOTFILES_DIR/.cursor/skills/iso-compliance-review/SKILL.md" "$CURSOR_SKILLS_DIR/iso-compliance-review/SKILL.md"

# Symlink optional agent configuration stored outside this repository
AGENT_EXTRAS_DIR="$HOME/.config/dotfiles/agent-extras"
if [ -z "${AGENT_EXTRAS_SOURCE:-}" ] && [ ! -e "$AGENT_EXTRAS_DIR" ] && [ -t 0 ]; then
	printf "Path to agent extras source directory (leave empty to skip): "
	read -r AGENT_EXTRAS_SOURCE
	if [ -n "$AGENT_EXTRAS_SOURCE" ]; then
		echo "AGENT_EXTRAS_SOURCE=\"$AGENT_EXTRAS_SOURCE\"" >>"$DOTFILES_ENV_FILE"
	fi
fi
if [ -n "${AGENT_EXTRAS_SOURCE:-}" ]; then
	AGENT_EXTRAS_SOURCE="${AGENT_EXTRAS_SOURCE/#\~/$HOME}"
	if [ ! -d "$AGENT_EXTRAS_SOURCE" ]; then
		echo "Skipping agent extras: $AGENT_EXTRAS_SOURCE is not a directory"
	elif [ -e "$AGENT_EXTRAS_DIR" ] && [ ! -L "$AGENT_EXTRAS_DIR" ]; then
		echo "Skipping agent extras: $AGENT_EXTRAS_DIR exists and is not a symlink"
	else
		mkdir -p "$(dirname "$AGENT_EXTRAS_DIR")"
		ln -sfn "$AGENT_EXTRAS_SOURCE" "$AGENT_EXTRAS_DIR"
	fi
fi

# Overlay agent extras on top of the repository-managed files
if [ -d "$AGENT_EXTRAS_DIR/.cursor" ]; then
	mkdir -p "$HOME/.cursor"
	cp -R "$AGENT_EXTRAS_DIR/.cursor/." "$HOME/.cursor/"
fi
if [ -d "$AGENT_EXTRAS_DIR/.agents" ]; then
	mkdir -p "$HOME/.agents"
	cp -R "$AGENT_EXTRAS_DIR/.agents/." "$HOME/.agents/"
fi

# Symlink launchd jobs
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"
ln -sfn "$DOTFILES_DIR/scripts/launchd/com.knutkirkhorn.clickup-weekly-meetings.plist" "$LAUNCH_AGENTS_DIR/com.knutkirkhorn.clickup-weekly-meetings.plist"
ln -sfn "$DOTFILES_DIR/scripts/launchd/com.knutkirkhorn.macos-storage-check.plist" "$LAUNCH_AGENTS_DIR/com.knutkirkhorn.macos-storage-check.plist"
# Reload launchd jobs
launchctl unload "$LAUNCH_AGENTS_DIR/com.knutkirkhorn.clickup-weekly-meetings.plist" 2>/dev/null
launchctl load "$LAUNCH_AGENTS_DIR/com.knutkirkhorn.clickup-weekly-meetings.plist"
launchctl start com.knutkirkhorn.clickup-weekly-meetings
launchctl unload "$LAUNCH_AGENTS_DIR/com.knutkirkhorn.macos-storage-check.plist" 2>/dev/null
launchctl load "$LAUNCH_AGENTS_DIR/com.knutkirkhorn.macos-storage-check.plist"

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
