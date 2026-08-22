# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal macOS bootstrap. Three files, no build system, no tests, no dependencies beyond
Homebrew itself. `install.sh` (orchestrator), `Brewfile` (declarative package manifest),
`defaults.sh` (macOS system preferences).

## Commands

```bash
./install.sh                                          # full bootstrap
./defaults.sh                                         # macOS preferences only
brew bundle install --file=Brewfile                   # packages only
brew bundle check --file=Brewfile --verbose           # what's missing, installs nothing
brew bundle dump --file=Brewfile --force --describe   # re-capture current system (destroys the section layout; diff, don't accept blindly)
bash -n install.sh && bash -n defaults.sh             # syntax check
shellcheck install.sh defaults.sh                     # lint (shellcheck is not in the Brewfile; brew install it if needed)
```

There is no test suite. Verification is running the scripts on a real machine, or `bash -n` /
`shellcheck` for a static check. `brew bundle check` is the closest thing to a dry run for the
Brewfile.

## Constraints these scripts are written against

- **Idempotency is a hard requirement.** Every step guards on "already installed" and re-running
  the whole bootstrap must be a no-op. Any new step needs the same guard.
- **`set -euo pipefail` is on in both scripts**, so a failing command aborts everything. Steps that
  are allowed to fail partially are explicitly suffixed with `|| log_warn ...` (Brewfile install,
  defaults) or `|| true` (the `killall` calls). Keep that pattern rather than removing the trap.
- **`defaults.sh` must stay sudo-free.** Everything in it is user-level `defaults write`. A
  preference that needs `sudo` doesn't belong there without changing the script's contract, which
  the README states as well.
- **Step order in `install.sh` is load-bearing:** Xcode CLT, Rosetta (arm64 only), Homebrew,
  `brew shellenv`, Brewfile, defaults. `brew shellenv` is evaluated inline because `brew` is not
  yet on `PATH` in the same shell right after a fresh install; the Apple Silicon
  (`/opt/homebrew`) and Intel (`/usr/local`) prefixes are both handled.
- **Missing CLT exits 1 on purpose.** `xcode-select --install` opens a GUI dialog the script cannot
  wait on, so the run stops and asks the user to re-run.

## Brewfile conventions

- Organized into commented sections (taps, dev CLIs, languages, databases, media, shell, casks,
  fonts, personal casks, `mas` apps) with a trailing `#` comment on each entry explaining what it
  is. New entries go in the matching section and carry a comment.
- Commented-out entries are intentional, not dead code. The "recommended modern CLI tools" block
  and `rtk` are opt-in. Don't uncomment or delete them without being asked.
- `mas` entries only work when the user is already signed into the Mac App Store; failures there
  are expected on a fresh machine and are why the Brewfile step tolerates partial failure.

## Repo conventions

- `Brewfile.lock.json` is gitignored and `install.sh` deliberately avoids writing one. This repo
  tracks intent, not pinned versions.
- README is the user-facing doc and mirrors the Brewfile contents. When adding or removing a
  notable package or a `defaults.sh` setting, update the corresponding README section in the same
  change.
- Commit messages here are lowercase, single-line, English (`remove ollama`,
  `docs: change package links`).
