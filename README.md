# macOS Setup

Personal macOS bootstrap: one command to set up a fresh Mac with my tools, apps, and system preferences. Declarative (Brewfile) and idempotent (safe to re-run).

## What's inside

| File | Purpose |
|------|---------|
| `install.sh` | Orchestrator: Xcode CLT → Rosetta → Homebrew → `brew bundle` → defaults |
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

> Sign in to the **Mac App Store** first so the `mas` apps install.

## What gets installed

Everything is declared in `Brewfile` — open it to see (and comment out) anything you don't want. Highlights:

- **Dev CLIs:** git, gh, git-lfs, svn, bfg, jq, ripgrep, mas
- **Languages/runtimes:** node@20, php@8.1, php@8.2, composer
- **Databases:** mysql, mongosh, mongodb-community
- **Media/content:** hugo, pandoc, ffmpeg, poppler, librsvg, pngquant, oxipng
- **AI:** ollama
- **Shell:** powerlevel10k, sleepwatcher, MesloLGS Nerd Font
- **GUI (dev):** Raycast, iTerm2, VS Code, JetBrains Toolbox, Docker, Postman, TablePlus, MongoDB Compass, Obsidian, Shottr, XAMPP, .NET SDK, Claude
- **GUI (personal):** Chrome, Slack, Spotify, WhatsApp, AnyDesk, OpenVPN
- **App Store:** Keynote, Numbers, Pages, iMovie, GarageBand, Excel, Outlook, MorningPages, Windows App, Hidden Bar

A set of recommended-but-not-yet-installed modern CLIs (eza, bat, fd, fzf, zoxide, lazygit, btop, tldr) is included as commented lines — uncomment to adopt.

## macOS defaults

`defaults.sh` applies sensible, user-level (no `sudo`) preferences: fast key repeat, press-and-hold disabled, Finder showing hidden files / extensions / path bar, no `.DS_Store` on network/USB, Dock autohide, and screenshots saved to `~/Screenshots` as PNG. Dock/Finder restart automatically.

Run it standalone any time:

```bash
./defaults.sh
```

## Keeping the Brewfile in sync

After installing or removing things by hand, re-capture the current system:

```bash
brew bundle dump --file=Brewfile --force --describe
```

Then review the diff and keep what you want (the file is organized into sections; a raw dump is flat).

## Post-install

- Add Powerlevel10k to `~/.zshrc`:
  `source "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"` then run `p10k configure`.
- Select the **MesloLGS NF** font in iTerm2 / your terminal.
- Sign in to JetBrains Toolbox and install the IDEs you use (PhpStorm, PyCharm, Rider, Fleet).
- Configure Raycast hotkeys and extensions.
