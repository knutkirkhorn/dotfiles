#!/usr/bin/env bash

set -euo pipefail

cd ~/dev
git clone https://github.com/jurplel/InstantSpaceSwitcher
cd InstantSpaceSwitcher
./dist/build.sh
open ./build/InstantSpaceSwitcher.app
