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
CLICKUP_TASK_IDENTIFIER=ENET-1149
```

For multiple tasks, use a comma-separated list in `CLICKUP_TASK_IDENTIFIERS`, or the same format in `CLICKUP_TASK_IDENTIFIER` (or pass multiple arguments when running manually):

```sh
CLICKUP_TASK_IDENTIFIERS=ENET-1149,ENET-2001
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
bun run scripts/init-clickup-week.ts ENET-1149 ENET-2001
```

### Automation

The launchd job is stored in [`scripts/launchd/com.knut.clickup-init-week.plist`](scripts/launchd/com.knut.clickup-init-week.plist) and symlinked to `~/Library/LaunchAgents` by `bootstrap.sh`.

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
