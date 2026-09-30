# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal macOS bootstrap. Three files, no build system, no tests, no dependencies beyond
Homebrew itself. `install.sh` (orchestrator), `Brewfile` (declarative package manifest),
`defaults.sh` (macOS system preferences).

## Commands

```bash
./install.sh                                          # full bootstrap: installs what is missing, never upgrades
./install.sh --check                                  # read-only preview: missing packages + differing defaults
./install.sh --upgrade                                # bootstrap and also upgrade outdated Brewfile entries
./defaults.sh                                         # macOS preferences only
./defaults.sh --dry-run                               # list the preferences that differ, write nothing
brew bundle check --file=Brewfile --verbose --no-upgrade  # what's missing, installs nothing
brew bundle dump --file=Brewfile --force --describe   # re-capture current system (destroys the section layout; diff, don't accept blindly)
/bin/bash -n install.sh && /bin/bash -n defaults.sh   # syntax check under the stock bash 3.2
shellcheck install.sh defaults.sh                     # lint (shellcheck is in the Brewfile)
brew bundle list --file=Brewfile >/dev/null           # Brewfile syntax check (does not validate package names)
```

There is no test suite. `./install.sh --check` is the dry run: it touches nothing and prints what
a real run would install and which preferences it would change. `/bin/bash -n` and `shellcheck`
are the static checks. A bare `brew bundle install` upgrades every outdated entry, so run
packages through `install.sh` (or set `HOMEBREW_BUNDLE_NO_UPGRADE=1`) on a machine with data.

## Constraints these scripts are written against

- **Idempotency is a hard requirement.** Every step guards on "already installed" and re-running
  the whole bootstrap must be a no-op. Any new step needs the same guard.
- **Upgrades are opt-in.** `brew bundle install` upgrades every outdated entry by default (App
  Store apps included), so a plain re-run would carry `mysql` across a major version together with
  its data directory. `install.sh` exports `HOMEBREW_BUNDLE_NO_UPGRADE=1` unless `--upgrade` is
  passed; `brew bundle check` honors the same variable and otherwise reports outdated entries as
  missing.
- **`--check` must stay read-only.** No `brew update`, no tap trust, no `brew bundle install`,
  defaults only through `defaults.sh --dry-run`, and `HOMEBREW_NO_AUTO_UPDATE=1` so not even
  Homebrew's index changes. Any new step that writes needs a check-mode branch.
- **`defaults.sh` writes only through `set_default`**, which compares the current value first and
  records which app has to restart. Add new settings the same way, with that app as the fifth
  argument, so a second run still writes nothing and restarts nothing.
- **`set -euo pipefail` is on in both scripts**, so a failing command aborts everything. Steps that
  are allowed to fail partially are explicitly suffixed with `|| log_warn ...` (Brewfile install,
  defaults) or `|| true` (the `killall` calls). Keep that pattern rather than removing the trap.
- **`defaults.sh` must stay sudo-free.** Everything in it is user-level `defaults write`. A
  preference that needs `sudo` doesn't belong there without changing the script's contract, which
  the README states as well.
- **Step order in `install.sh` is load-bearing:** Xcode CLT, Rosetta (arm64 only), Homebrew,
  `brew shellenv`, tap trust, Brewfile, defaults. `brew shellenv` is evaluated inline because
  `brew` is not yet on `PATH` in the same shell right after a fresh install. `find_brew` looks in
  the Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) prefixes before `PATH`, so a shell
  without shellenv never re-runs the installer over a working install, and the script aborts
  loudly if brew is still missing after the installer, rather than letting every later `brew`
  call fail one by one.
- **Third-party taps must be trusted before bundling.** Homebrew 6 refuses to load formulae from
  untrusted taps, and `brew bundle` counts that as a skip rather than an error, so packages
  silently never install while the run still reports success. `install.sh` parses the `tap` lines
  out of the Brewfile and runs `brew trust --tap` on each. There is no Brewfile syntax for this:
  a `trusted: true` option on the tap line does **not** work (verified 2026-08-22).
- **`brew bundle install` exits 0 even when it skipped entries**, which is why the script ends with
  an explicit `brew bundle check` and a collected-warnings summary instead of trusting exit codes.
- **Missing CLT exits 1 on purpose.** `xcode-select --install` opens a GUI dialog the script cannot
  wait on, so the run stops and asks the user to re-run. Detection uses `pkgutil --pkg-info
  com.apple.pkg.CLTools_Executables`, not `xcode-select -p`, which only proves a developer
  directory is set.
- **macOS ships bash 3.2.** `"${arr[@]}"` on an empty array is an unbound-variable fatal under
  `set -u` there, so array expansions need a `:-` fallback. Test any new bash construct with
  `/bin/bash`, not a Homebrew bash 5.

## Brewfile conventions

- Organized into commented sections (taps, dev CLIs, languages, databases, media, shell, casks,
  fonts, personal casks, `mas` apps) with a trailing `#` comment on each entry explaining what it
  is. New entries go in the matching section and carry a comment.
- Commented-out entries are intentional, not dead code. `rtk`, `xampp` and the
  `microsoft/mssql-release` tap are opt-in. Don't uncomment or delete them without being asked.
- **Keg-only formulae need an explicit `link:`.** Without one, `brew bundle install` unlinks a
  keg-only formula even when it was linked by hand. Entries that carry options also run after
  the batched install of plain entries, so `php@8.2` uses `link: :overwrite`: composer has already
  pulled in and linked the latest `php` by then, and a plain `link: true` would hit that conflict.
- `brew bundle` already passes `--adopt` to cask installs (auto-updating apps installed by hand
  are adopted, not reinstalled) and falls back from `mas install` to `mas get` for free App Store
  apps. Neither needs a flag in the Brewfile.
- `mas` entries only work when the user is already signed into the Mac App Store, and paid apps
  must have been bought once; failures there are expected on a fresh machine and are why the
  Brewfile step tolerates partial failure.

## Repo conventions

- `Brewfile.lock.json` is gitignored and `install.sh` suppresses it via
  `HOMEBREW_BUNDLE_NO_LOCK=1`. The old `--no-lock` flag no longer exists in Homebrew 6. This repo
  tracks intent, not pinned versions.
- **Deprecated formulae get disabled on a date, so pinned major versions rot.** `node@20`
  (disabled 2026-10-28) and `php@8.1` (disabled 2026-12-31) were both live in the Brewfile until
  2026-08-22. Check `brew info <formula> | grep -i deprecat` before pinning a versioned formula.
- README is the user-facing doc and mirrors the Brewfile contents. When adding or removing a
  notable package or a `defaults.sh` setting, update the corresponding README section in the same
  change.
- Commit messages here are lowercase, single-line, English (`remove ollama`,
  `docs: change package links`).
