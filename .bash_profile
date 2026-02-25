#!/usr/bin/env bash

source ~/.aliases
source ~/.functions
source ~/.extra

# Terminal styling
# TODO: might move this back to .zshrc or move that to git later
# Stuff to enable pure prompt (https://github.com/sindresorhus/pure)

fpath+=("/opt/zerobrew/prefix/share/zsh/site-functions")

autoload -U promptinit; promptinit
prompt pure
