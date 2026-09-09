#!/usr/bin/env bash

set -euo pipefail

# TODO: remove, when tested the brew version of this, still needs to go through settings and allow untrusted app to make it work
# cd ~/dev
# git clone https://github.com/jurplel/InstantSpaceSwitcher
# cd InstantSpaceSwitcher
# ./dist/build.sh
# open ./build/InstantSpaceSwitcher.app

# Mouser (https://github.com/TomBadash/Mouser)
install_mouser_release() {
	local archive="Mouser-macOS.zip"
	if [[ "$(uname -m)" == "x86_64" ]]; then
		archive="Mouser-macOS-intel.zip"
	fi

	local tmp_dir
	tmp_dir="$(mktemp -d)"
	curl -fsSL \
		"https://github.com/TomBadash/Mouser/releases/latest/download/$archive" \
		-o "$tmp_dir/$archive"
	ditto -x -k "$tmp_dir/$archive" "$tmp_dir"
	rm -rf /Applications/Mouser.app
	mv "$tmp_dir/Mouser.app" /Applications/Mouser.app
	rm -rf "$tmp_dir"
}

build_mouser_from_source() {
	local source_dir="${MOUSER_SOURCE_DIR:-$HOME/dev/Mouser}"

	if [[ -d "$source_dir/.git" ]]; then
		git -C "$source_dir" pull --ff-only
	else
		git clone https://github.com/TomBadash/Mouser.git "$source_dir"
	fi

	(
		cd "$source_dir"
		uv venv
		uv pip install --python .venv/bin/python -r requirements.txt
		source .venv/bin/activate
		./build_macos_app.sh
	)

	rm -rf /Applications/Mouser.app
	ditto "$source_dir/dist/Mouser.app" /Applications/Mouser.app
}

# Use MOUSER_INSTALL_FROM_RELEASE=1 as a fallback
if [[ "${MOUSER_INSTALL_FROM_RELEASE:-0}" == "1" ]]; then
	install_mouser_release
else
	build_mouser_from_source
fi
