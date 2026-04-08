#!/usr/bin/env bash

# Minimum age before a registry version is considered installable (supply-chain hardening).
# - npm: days (min-release-age)
# - pnpm: minutes (minimum-release-age in ~/.npmrc)
# - Yarn: minutes (npmMinimalAgeGate in ~/.yarnrc)
# - Bun: seconds (minimumReleaseAge in bunfig)
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

setup_bun_minimum_release_age() {
	# Check if bun is installed
	command -v bun >/dev/null 2>&1 || return 0

	python3 -c "
import pathlib
import sys

age = int(sys.argv[1])
path = pathlib.Path.home() / '.bunfig.toml'
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
	new_lines.extend(['[install]', f'minimumReleaseAge = {age}'])
else:
	replaced = False
	for j in range(start + 1, end):
		if new_lines[j].strip().startswith('minimumReleaseAge'):
			new_lines[j] = f'minimumReleaseAge = {age}'
			replaced = True
			break
	if not replaced:
		new_lines.insert(start + 1, f'minimumReleaseAge = {age}')

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text('\n'.join(new_lines) + '\n', encoding='utf-8')
" "$MIN_RELEASE_AGE_SECONDS"
}

npm config set min-release-age "$MIN_RELEASE_AGE_DAYS"
setup_pnpm_min_release_age
setup_yarn_min_release_age
setup_bun_minimum_release_age
