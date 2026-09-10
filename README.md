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

## ClickUp weekly init

`scripts/init-clickup-week.ts` creates weekday (Mon-Fri) 30m time entries at 09:00 for the configured ClickUp task(s) in the current week.

### Required env vars

Set these in `.env`:

```sh
CLICKUP_API_KEY=...
CLICKUP_TASK_IDENTIFIER=TASKID-1234
```

For multiple tasks, use a comma-separated list in `CLICKUP_TASK_IDENTIFIERS`, or the same format in `CLICKUP_TASK_IDENTIFIER` (or pass multiple arguments when running manually):

```sh
CLICKUP_TASK_IDENTIFIERS=TASKID-1234,TASKID-5678
```

Optional:

```sh
CLICKUP_TEAM_ID=...
```

### Run manually

```sh
bun run scripts/init-clickup-week.ts
```

Override task(s) from CLI (one or more):

```sh
bun run scripts/init-clickup-week.ts TASKID-1234 TASKID-5678
```

Preview what would be created without writing time entries:

```sh
bun run scripts/init-clickup-week.ts --dry-run
```

## ClickUp weekly meeting sync

`scripts/sync-clickup-weekly-meetings.ts` logs the configured recurring
meetings for the full current week, including meetings later in the week. It
uses `CLICKUP_API_KEY` and the optional `CLICKUP_TEAM_ID` from the weekly init
script.

Configure meetings in
[`scripts/clickup-weekly-meetings.json`](scripts/clickup-weekly-meetings.json):

```json
{
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

Preview changes:

```sh
bun run clickup:meetings --dry-run
```

Apply changes:

```sh
bun run clickup:meetings
```

The script leaves time-entry descriptions empty and finds existing entries by
their ClickUp task and scheduled weekday. Removing a meeting from the mapping
does not delete an existing entry.

Use a different mapping file:

```sh
bun run clickup:meetings --dry-run --config path/to/meetings.json
```

### Automation

The launchd job is stored in [`scripts/launchd/com.knutkirkhorn.clickup-init-week.plist`](scripts/launchd/com.knutkirkhorn.clickup-init-week.plist) and symlinked to `~/Library/LaunchAgents` by `bootstrap.sh`.

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
