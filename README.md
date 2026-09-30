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
git clone https://github.com/kadirermantr/macos-setup.git
cd macos-setup
./install.sh
```

On a brand-new Mac the first `git` command opens the Command Line Tools installer; let it finish, then run the clone again. The HTTPS URL needs no SSH key, which a fresh machine does not have yet.

| Command | What it does |
|---------|--------------|
| `./install.sh` | Installs whatever the Brewfile declares but is missing, then applies `defaults.sh` |
| `./install.sh --check` | Changes nothing: lists what a real run would install and which defaults differ |
| `./install.sh --upgrade` | Also upgrades outdated Brewfile entries (formulae, casks, App Store apps) |

Re-running is safe. Installed packages stay at their current version, because `brew bundle install` on its own upgrades every outdated entry, including database servers whose data directory cannot be downgraded. Upgrades happen only when you pass `--upgrade`.

> Sign in to the **Mac App Store** first. `brew bundle` installs the apps already tied to your Apple ID and fetches free ones with `mas get`; paid apps have to be bought once in the App Store.

The Brewfile step can ask for your password more than once (casks that ship a `.pkg` and App Store installs escalate through `sudo`), so stay near the terminal. The Mac is kept awake with `caffeinate` until the script exits.

At the end the script prints every warning it collected and runs `brew bundle check`, so anything that silently failed shows up in the summary instead of scrolling past.

## What gets installed

Everything is declared in `Brewfile`. Open it to see (and comment out) anything you don't want. Highlights:

- **Dev CLIs:** git, gh, git-lfs, svn, bfg, gnupg, jq, ripgrep, mas, shellcheck
- **Languages/runtimes:** node, php@8.2 (linked as the default `php`), composer, openjdk
- **Databases:** mysql, mongosh, mongodb-community, mongodb-database-tools, supabase
- **Media/content:** hugo, pandoc, ffmpeg, poppler, librsvg, pngquant, oxipng
- **Modern CLIs:** eza, bat, fd, fzf, zoxide, lazygit, btop, tlrc
- **Shell:** powerlevel10k, sleepwatcher, MesloLGS Nerd Font
- **GUI (dev):** Raycast, iTerm2, VS Code, JetBrains Toolbox, Docker Desktop, Postman, TablePlus, MongoDB Compass, Obsidian, Shottr, .NET SDK, Claude
- **GUI (personal):** Chrome, Slack, Spotify, WhatsApp, AnyDesk, OpenVPN
- **App Store:** Keynote, Numbers, Pages, Excel, Outlook, MorningPages, Hidden Bar

Commented-out entries are opt-in: `rtk`, XAMPP and Microsoft's SQL Server ODBC tap. XAMPP is off because it ships its own MySQL on port 3306 and collides with the `mysql` formula; uncomment it only if you need the Apache/PHP stack.

## Third-party taps and `brew trust`

Homebrew 6 refuses to load formulae from taps you have not explicitly trusted. `brew bundle` treats an untrusted tap as a **skip, not an error**, which means packages like `mongodb-community` quietly never install and the bundle still reports success.

`install.sh` handles this: it reads the `tap` lines out of the Brewfile and runs `brew trust --tap` on each one that is not trusted yet, before bundling. There is no Brewfile syntax for this (a `trusted: true` option on the tap line does not work).

Trusting a tap means trusting its maintainers to run code on your machine, so keep the tap list short and deliberate. That is why the Microsoft tap is commented out: nothing in the Brewfile installs from it.

## macOS defaults

`defaults.sh` applies user-level (no `sudo`) preferences: fast key repeat, press-and-hold disabled, no autocorrect/smart quotes/smart dashes (they corrupt code), Finder showing hidden files / extensions / path bar with folders sorted first, no `.DS_Store` on network/USB, an always-visible Dock at icon size 62 without recent apps, and screenshots saved to `~/Screenshots` as PNG.

A value is written only when it differs from the current one, and only the apps whose settings changed (Dock, Finder, SystemUIServer) are restarted, so a second run changes nothing. Preview before applying:

```bash
./defaults.sh --dry-run
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
brew bundle check --file=Brewfile --verbose --no-upgrade
```

Without `--no-upgrade`, outdated entries are reported as missing too. `./install.sh --check` runs the same check plus the defaults preview.

## Linting

Before committing a change to either script:

```bash
/bin/bash -n install.sh && /bin/bash -n defaults.sh
shellcheck install.sh defaults.sh
brew bundle list --file=Brewfile >/dev/null
```

Use `/bin/bash` explicitly: macOS ships bash 3.2, and a Homebrew bash 5 on `PATH` would hide 3.2-only failures. `brew bundle list` catches Brewfile syntax errors, not misspelled package names.

## Post-install

- Add Powerlevel10k to `~/.zshrc`:
  `source "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"` then run `p10k configure`.
  Use `$(brew --prefix)` rather than a hardcoded `/opt/homebrew`, or the line breaks on Intel Macs.
- Select the **MesloLGS NF** font in iTerm2 / your terminal.
- Turn on zoxide and fzf by adding `eval "$(zoxide init zsh)"` (the `z` command) and `source <(fzf --zsh)` (key bindings and completion) to `~/.zshrc`.
- PHP: `php@8.2` stays the default `php` even though composer pulls in the latest `php` as a dependency. To switch to the newest version, drop `link: :overwrite` from the `php@8.2` entry, then run `brew unlink php@8.2 && brew link --overwrite php`.
- Java: `openjdk` is keg-only, so macOS's `java` wrappers cannot see it until you run `sudo ln -sfn "$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk`.
- Sign in to JetBrains Toolbox and install the IDEs you use (PhpStorm, PyCharm, Rider, Fleet).
- Configure Raycast hotkeys and extensions.
