# macOS Setup

Personal macOS bootstrap: one command to set up a fresh Mac with my tools, apps, and system preferences. Declarative (Brewfile) and idempotent (safe to re-run).

## What's inside

| File | Purpose |
|------|---------|
| `install.sh` | Orchestrator: Xcode CLT → Rosetta → Homebrew → tap trust → `brew bundle` → defaults |
| `Brewfile` | Declarative list of formulae, casks, taps, fonts and Mac App Store apps |
| `defaults.sh` | Opinionated macOS system preferences (keyboard, Finder, Dock, screenshots) |

## Installation

```bash
git clone git@github.com:kadirermantr/macos-setup.git
cd macos-setup
chmod +x install.sh
./install.sh
```

Re-running is safe. Already-installed items are skipped.

> Sign in to the **Mac App Store** first so the `mas` apps install. `mas` can only install apps already tied to your Apple ID, so anything you have never downloaded has to be fetched from the App Store GUI once.

At the end the script prints every warning it collected and runs `brew bundle check`, so anything that silently failed shows up in the summary instead of scrolling past.

## What gets installed

Everything is declared in `Brewfile`. Open it to see (and comment out) anything you don't want. Highlights:

- **Dev CLIs:** git, gh, git-lfs, svn, bfg, gnupg, jq, ripgrep, mas, shellcheck
- **Languages/runtimes:** node, php@8.2, composer, openjdk
- **Databases:** mysql, mongosh, mongodb-community, mongodb-database-tools, supabase
- **Media/content:** hugo, pandoc, ffmpeg, poppler, librsvg, pngquant, oxipng
- **Modern CLIs:** eza, bat, fd, fzf, zoxide, lazygit, btop, tlrc
- **Shell:** powerlevel10k, sleepwatcher, MesloLGS Nerd Font
- **GUI (dev):** Raycast, iTerm2, VS Code, JetBrains Toolbox, Docker Desktop, Postman, TablePlus, MongoDB Compass, Obsidian, Shottr, .NET SDK, Claude
- **GUI (personal):** Chrome, Slack, Spotify, WhatsApp, AnyDesk, OpenVPN
- **App Store:** Keynote, Numbers, Pages, Excel, Outlook, MorningPages, Hidden Bar

XAMPP is commented out because it ships its own MySQL on port 3306 and collides with the `mysql` formula. Uncomment it only if you need the Apache/PHP stack.

## Third-party taps and `brew trust`

Homebrew 6 refuses to load formulae from taps you have not explicitly trusted. `brew bundle` treats an untrusted tap as a **skip, not an error**, which means packages like `mongodb-community` quietly never install and the bundle still reports success.

`install.sh` handles this: it reads the `tap` lines out of the Brewfile and runs `brew trust --tap` on each one before bundling. There is no Brewfile syntax for this (a `trusted: true` option on the tap line does not work).

Trusting a tap means trusting its maintainers to run code on your machine, so keep the tap list short and deliberate.

## macOS defaults

`defaults.sh` applies user-level (no `sudo`) preferences: fast key repeat, press-and-hold disabled, no autocorrect/smart quotes/smart dashes (they corrupt code), Finder showing hidden files / extensions / path bar with folders sorted first, no `.DS_Store` on network/USB, Dock autohide, and screenshots saved to `~/Screenshots` as PNG. Dock/Finder restart automatically.

Run it standalone any time:

```bash
./defaults.sh
```

## Keeping the Brewfile in sync

After installing or removing things by hand, re-capture the current system:

```bash
brew bundle dump --file=Brewfile --force --describe
```

A raw dump is flat and loses the section layout and comments, so diff it and port over only the entries you want rather than committing it wholesale.

To see what is declared but missing without installing anything:

```bash
brew bundle check --file=Brewfile --verbose
```

## Linting

Before committing a change to either script:

```bash
bash -n install.sh && bash -n defaults.sh
shellcheck install.sh defaults.sh
brew bundle list --file=Brewfile >/dev/null
```

## Post-install

- Add Powerlevel10k to `~/.zshrc`:
  `source "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"` then run `p10k configure`.
  Use `$(brew --prefix)` rather than a hardcoded `/opt/homebrew`, or the line breaks on Intel Macs.
- Select the **MesloLGS NF** font in iTerm2 / your terminal.
- Sign in to JetBrains Toolbox and install the IDEs you use (PhpStorm, PyCharm, Rider, Fleet).
- Configure Raycast hotkeys and extensions.
