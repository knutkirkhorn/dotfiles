#!/usr/bin/env bash

git pull

# Copy files to ~
cp .aliases ~/.aliases
cp .functions ~/.functions
cp .bash_profile ~/.bash_profile

source ~/.bash_profile
