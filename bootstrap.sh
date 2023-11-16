#!/usr/bin/env bash

git pull

# Copy files to ~
cp .aliases ~/.aliases
cp .functions ~/.functions
cp .bash_profile ~/.bash_profile

# Check if .extra exists and create it if it doesn't
if [ ! -f ~/.extra ]; then
	touch ~/.extra
fi

source ~/.bash_profile
