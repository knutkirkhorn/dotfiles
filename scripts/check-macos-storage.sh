#!/usr/bin/env bash
set -euo pipefail

THRESHOLD_PERCENT="${MACOS_STORAGE_ALERT_THRESHOLD_PERCENT:-30}"
VOLUME="${MACOS_STORAGE_ALERT_VOLUME:-/}"

read -r total_kib available_kib <<<"$(df -Pk "$VOLUME" | awk 'NR == 2 {print $2, $4}')"

available_percent="$(awk -v available="$available_kib" -v total="$total_kib" 'BEGIN {printf "%.1f", (available / total) * 100}')"
available_gib="$(awk -v available="$available_kib" 'BEGIN {printf "%.1f", available / 1024 / 1024}')"

echo "Storage check for $VOLUME: ${available_percent}% available (${available_gib} GiB)"

if awk -v available="$available_percent" -v threshold="$THRESHOLD_PERCENT" 'BEGIN {exit !(available < threshold)}'; then
	if osascript - "$available_percent" "$available_gib" "$VOLUME" "$THRESHOLD_PERCENT" <<'APPLESCRIPT'
on run argv
	set availablePercent to item 1 of argv
	set availableGib to item 2 of argv
	set checkedVolume to item 3 of argv
	set thresholdPercent to item 4 of argv
	display alert "Mac storage is low" message "Only " & availablePercent & "% (" & availableGib & " GiB) is available on " & checkedVolume & ". The alert threshold is " & thresholdPercent & "%." as critical buttons {"OK"} default button "OK"
end run
APPLESCRIPT
	then
		afplay /System/Library/Sounds/Basso.aiff
	else
		echo "Storage alert could not be displayed" >&2
	fi
fi
