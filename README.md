# dotfiles

> My personal dotfiles

## Install

Run this command when installing or refreshing the dotfiles

```sh
source bootstrap.sh
```

### npm

Run this script to install some CLIs.

```sh
./npm.sh
```

### macOS

Run this script to install some apps for macOS.

```sh
./macos.sh
```

## ClickUp weekly init

`scripts/init-clickup-week.ts` creates weekday (Mon-Fri) 30m time entries at 09:00 for the configured ClickUp task in the current week.

### Required env vars

Set these in `.env`:

```sh
CLICKUP_API_KEY=...
CLICKUP_TASK_IDENTIFIER=ENET-1149
```

Optional:

```sh
CLICKUP_TEAM_ID=...
```

### Run manually

```sh
bun run scripts/init-clickup-week.ts
```

Override task from CLI:

```sh
bun run scripts/init-clickup-week.ts ENET-1149
```

### Automation

The launchd job is stored in [`scripts/launchd/com.knut.clickup-init-week.plist`](scripts/launchd/com.knut.clickup-init-week.plist) and symlinked to `~/Library/LaunchAgents` by `bootstrap.sh`.

## Inspiration and thanks

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Kent C. Dodds](https://github.com/kentcdodds/dotfiles)

## Related

- My [Windows aliases](https://github.com/knutkirkhorn/windows-aliases)
