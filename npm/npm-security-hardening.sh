#!/usr/bin/env bash

# Minimum age before a registry version is considered installable (supply-chain hardening).
# - npm: days (min-release-age)
# - pnpm: minutes (minimum-release-age in ~/.npmrc)
# - Yarn: minutes (npmMinimalAgeGate in ~/.yarnrc)
# - Bun: seconds (minimumReleaseAge in bunfig)
#
# Lifecycle scripts: `npm config set ignore-scripts true` writes ~/.npmrc; Bun honors that (bun.com/docs/install/npmrc)
# Bun still gates dependency scripts via trustedDependencies and can also read ignoreScripts from bunfig
# One-off npm install with scripts: npm install --ignore-scripts=false
readonly MIN_RELEASE_AGE_DAYS=7
readonly MIN_RELEASE_AGE_MINUTES=$((MIN_RELEASE_AGE_DAYS * 24 * 60))
readonly MIN_RELEASE_AGE_SECONDS=$((MIN_RELEASE_AGE_MINUTES * 60))

# pnpm reads minimum-release-age from ~/.npmrc (minutes)
setup_pnpm_min_release_age() {
	# Check if pnpm is installed
	command -v pnpm >/dev/null 2>&1 || return 0

	pnpm config set minimum-release-age "$MIN_RELEASE_AGE_MINUTES"
}

setup_yarn_min_release_age() {
	# Check if yarn is installed
	command -v yarn >/dev/null 2>&1 || return 0

	yarn config set npmMinimalAgeGate "$MIN_RELEASE_AGE_MINUTES" -H
}

setup_yarn_ignore_scripts() {
	# Check if yarn is installed
	command -v yarn >/dev/null 2>&1 || return 0

	local yarn_version
	yarn_version="$(yarn --version 2>/dev/null || true)"

	if [[ "$yarn_version" == 1.* ]]; then
		yarn config set ignore-scripts true -H
	else
		yarn config set enableScripts false -H
	fi
}

setup_bun_security_config() {
	# Check if bun is installed
	command -v bun >/dev/null 2>&1 || return 0

	python3 -c "
import os
import pathlib
import sys

age = int(sys.argv[1])
settings = {
	'minimumReleaseAge': str(age),
	'ignoreScripts': 'true',
}

home = pathlib.Path.home()
xdg_config_home = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', home / '.config'))
paths = {home / '.bunfig.toml', xdg_config_home / '.bunfig.toml'}

for path in paths:
	lines = path.read_text(encoding='utf-8').splitlines() if path.exists() else []

	start = None
	end = None
	for i, line in enumerate(lines):
		s = line.strip()
		if s == '[install]':
			start = i
			continue
		if start is not None and end is None and s.startswith('[') and s.endswith(']'):
			end = i
			break
	if start is not None and end is None:
		end = len(lines)

	new_lines = list(lines)
	if start is None:
		if new_lines and new_lines[-1].strip():
			new_lines.append('')
		new_lines.append('[install]')
		for key, value in settings.items():
			new_lines.append(f'{key} = {value}')
	else:
		for key, value in reversed(settings.items()):
			replaced = False
			for j in range(start + 1, end):
				if new_lines[j].strip().startswith(key):
					new_lines[j] = f'{key} = {value}'
					replaced = True
					break
			if not replaced:
				new_lines.insert(start + 1, f'{key} = {value}')

	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_text('\n'.join(new_lines) + '\n', encoding='utf-8')
" "$MIN_RELEASE_AGE_SECONDS"
}

npm config set min-release-age "$MIN_RELEASE_AGE_DAYS"
npm config set ignore-scripts true
setup_pnpm_min_release_age
setup_yarn_min_release_age
setup_yarn_ignore_scripts
setup_bun_security_config
