#!/usr/bin/env bash

# Sourced files live in the home directory, where ShellCheck cannot follow them
# shellcheck disable=SC1090
source ~/.aliases
source ~/.functions
source ~/.extra

# Terminal styling
# TODO: might move this back to .zshrc or move that to git later
# Stuff to enable pure prompt (https://github.com/sindresorhus/pure)

fpath+=("/opt/homebrew/share/zsh/site-functions")

autoload -U promptinit; promptinit
prompt pure

# Fast Node Manager (fnm)
eval "$(fnm env --use-on-cd --shell zsh)"
