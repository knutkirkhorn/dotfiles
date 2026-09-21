# dotfiles

> My personal dotfiles

## Install

Run this command when installing or refreshing the dotfiles

```sh
source bootstrap.sh
```

### npm

Scripts live under [`npm/`](npm/).

Run [`npm/npm.sh`](npm/npm.sh) to install global npm CLIs.

```sh
./npm/npm.sh
```

[`npm/npm-security-hardening.sh`](npm/npm-security-hardening.sh) sets minimum release age for npm, pnpm, Yarn, and Bun (supply-chain hardening).

```sh
./npm/npm-security-hardening.sh
```

### macOS

Run this script to install some apps for macOS.

```sh
./macos.sh
```

Touch ID for `sudo`: the PAM snippet lives in [`macos/pam.d/sudo_local`](macos/pam.d/sudo_local). Install or refresh it on a Mac with:

```sh
./macos/sync-sudo-touchid.sh
```

This copies that file to `/etc/pam.d/sudo_local` (requires `sudo`). Your OS `/etc/pam.d/sudo` must include `sudo_local` (current macOS does by default).

### Windows

Windows setup scripts live under [`windows/`](windows/). Run [`windows/windows.ps1`](windows/windows.ps1) in PowerShell to install GUI and CLI apps via `winget` (run from the repo root, or adjust the path).

```powershell
.\windows\windows.ps1
```

## ClickUp weekly meeting sync

`scripts/sync-clickup-weekly-meetings.ts` is the single weekly ClickUp entry
point. It creates or updates time entries for the configured recurring meetings
in the current week (including later weekdays). Re-running it is safe: matching
entries stay unchanged, and only missing or outdated ones are created or updated.

### Required env vars

Set these in `.env`:

```sh
CLICKUP_API_KEY=...
```

Optional:

```sh
CLICKUP_TEAM_ID=...
```

### Meeting config

Configure meetings in
[`scripts/clickup-weekly-meetings.json`](scripts/clickup-weekly-meetings.json):

```json
{
	"dutyCalendarUrl": "https://calendar.url.localhost/duty-day-off.ics",
	"meetings": [
		{
			"name": "Weekly planning",
			"taskIdentifier": "TASKID-1234",
			"weekday": "monday",
			"durationMinutes": 60
		}
	]
}
```

Add one entry for each weekly meeting. Meetings mapped to the same task and
weekday are combined into one time entry. Times are stored at noon in the Mac's
local timezone because only the day and duration are relevant.

The script leaves time-entry descriptions empty and finds existing entries by
their ClickUp task and scheduled weekday. Removing a meeting from the mapping
does not delete an existing entry.

The optional `dutyCalendar` object configures the HTTPS subscription URL and
the ClickUp task and duration used for day-off entries. When the calendar
contains an event named `Day off due to duty last weekend` for Friday in the
current local week, the script replaces configured Friday meetings with that
day-off entry. Calendar request failures stop the sync so Friday entries are
not added when the duty status is unknown.

### Run manually

Preview changes:

```sh
bun run clickup:meetings --dry-run
```

Preview the week containing a specific date:

```sh
bun run clickup:meetings --dry-run --date 2026-09-14
```

`--date` accepts a local date in `YYYY-MM-DD` format and can only be used with
`--dry-run`. If the duty calendar has a Friday day-off event in the selected
week, the preview prints the event name and exact date.

Apply / resync:

```sh
bun run clickup:meetings
```

Use a different mapping file:

```sh
bun run clickup:meetings --dry-run --config path/to/meetings.json
```

### Automation

A launchd job runs the sync every Monday at 09:05 (and on load). The plist is
[`scripts/launchd/com.knutkirkhorn.clickup-weekly-meetings.plist`](scripts/launchd/com.knutkirkhorn.clickup-weekly-meetings.plist)
and is symlinked to `~/Library/LaunchAgents` by `bootstrap.sh`. Logs go to
`/tmp/clickup-weekly-meetings.out.log` and `/tmp/clickup-weekly-meetings.err.log`.

## macOS storage alert

`scripts/check-macos-storage.sh` checks available storage on `/` and shows an alert when less than 30% is available.

The launchd job is stored in [`scripts/launchd/com.knutkirkhorn.macos-storage-check.plist`](scripts/launchd/com.knutkirkhorn.macos-storage-check.plist), runs every Monday at 10:00, and is symlinked to `~/Library/LaunchAgents` by `bootstrap.sh`.

Override the defaults when running manually:

```sh
MACOS_STORAGE_ALERT_THRESHOLD_PERCENT=25 MACOS_STORAGE_ALERT_VOLUME=/ bash scripts/check-macos-storage.sh
```

## Teams Norwegian holiday Out of Office

`scripts/teams-norwegian-holidays-ics-generator.ts` finds Norwegian public holidays with `date-holidays` and writes an `.ics` calendar file with all-day out-of-office events.

Preview the events:

```sh
bun run teams:out-of-office --year 2026
```

Create an `.ics` file for Teams/Outlook import:

```sh
bun run teams:out-of-office --year 2026 --ics norwegian-holidays-2026.ics
```

Import it by dragging and dropping the `.ics` file into Teams, then select the regular calendar to import it into your calendar. The `.ics` file includes Outlook-specific `X-MICROSOFT-CDO-BUSYSTATUS:OOF`, but the final "show as" value depends on how Teams/Outlook imports the file.

## Inspiration and thanks

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Kent C. Dodds](https://github.com/kentcdodds/dotfiles)

## Related

- My [Windows aliases](https://github.com/knutkirkhorn/windows-aliases)
