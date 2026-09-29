#!/usr/bin/env bash

set -euo pipefail

# TODO: remove, when tested the brew version of this, still needs to go through settings and allow untrusted app to make it work
# cd ~/dev
# git clone https://github.com/jurplel/InstantSpaceSwitcher
# cd InstantSpaceSwitcher
# ./dist/build.sh
# open ./build/InstantSpaceSwitcher.app

usage() {
	cat <<'EOF'
Usage: macos-fromsource.sh [all|mouser|launchmanager]

  all             Build Mouser and LaunchManager (default)
  mouser          Build only Mouser
  launchmanager   Build only LaunchManager

Environment:
  MOUSER_INSTALL_FROM_RELEASE=1  Install Mouser from GitHub release instead of source
  MOUSER_SOURCE_DIR              Override Mouser clone path (default: ~/dev/Mouser)
  LAUNCHMANAGER_SOURCE_DIR       Override LaunchManager clone path (default: ~/dev/LaunchManager)
EOF
}

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
		# shellcheck source=/dev/null
		source .venv/bin/activate
		./build_macos_app.sh
	)

	rm -rf /Applications/Mouser.app
	ditto "$source_dir/dist/Mouser.app" /Applications/Mouser.app
}

install_mouser() {
	# Use MOUSER_INSTALL_FROM_RELEASE=1 as a fallback
	if [[ "${MOUSER_INSTALL_FROM_RELEASE:-0}" == "1" ]]; then
		install_mouser_release
	else
		build_mouser_from_source
	fi
}

# LaunchManager (https://github.com/Sean10000/LaunchManager)
build_launchmanager_from_source() {
	local source_dir="${LAUNCHMANAGER_SOURCE_DIR:-$HOME/dev/LaunchManager}"
	local archive_path="$source_dir/build/LaunchManager.xcarchive"
	local app_path

	if [[ -d "$source_dir/.git" ]]; then
		git -C "$source_dir" pull --ff-only
	else
		git clone https://github.com/Sean10000/LaunchManager.git "$source_dir"
	fi

	mkdir -p "$source_dir/build"
	rm -rf "$archive_path"

	(
		cd "$source_dir"
		xcodebuild archive \
			-project LaunchManager.xcodeproj \
			-scheme LaunchManager \
			-configuration Release \
			-archivePath "$archive_path" \
			ARCHS="arm64 x86_64" \
			ONLY_ACTIVE_ARCH=NO \
			CODE_SIGN_IDENTITY="-" \
			CODE_SIGNING_REQUIRED=NO \
			AD_HOC_CODE_SIGNING_ALLOWED=YES \
			DEVELOPMENT_TEAM=""
	)

	app_path="$(find "$archive_path" -name "LaunchManager.app" -maxdepth 5 | head -1)"
	if [[ -z "$app_path" || ! -d "$app_path" ]]; then
		echo "LaunchManager archive did not produce LaunchManager.app" >&2
		exit 1
	fi

	rm -rf /Applications/LaunchManager.app
	ditto "$app_path" /Applications/LaunchManager.app
}

target="${1:-all}"

case "$target" in
	all)
		install_mouser
		build_launchmanager_from_source
		;;
	mouser)
		install_mouser
		;;
	launchmanager)
		build_launchmanager_from_source
		;;
	-h | --help | help)
		usage
		;;
	*)
		echo "Unknown target: $target" >&2
		usage >&2
		exit 1
		;;
esac
