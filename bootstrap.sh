#!/usr/bin/env bash

git pull

# Copy files to ~
cp .aliases ~/.aliases
cp .bash_profile ~/.bash_profile

source ~/.bash_profile
