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
shellcheck install.sh defaults.sh                     # lint (shellcheck is in the Brewfile)
brew bundle list --file=Brewfile >/dev/null           # Brewfile parse check
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
  `brew shellenv`, tap trust, Brewfile, defaults. `brew shellenv` is evaluated inline because
  `brew` is not yet on `PATH` in the same shell right after a fresh install; the Apple Silicon
  (`/opt/homebrew`) and Intel (`/usr/local`) prefixes are both handled, and a final `else`
  aborts loudly rather than letting every later `brew` call fail one by one.
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
- Commented-out entries are intentional, not dead code. The "recommended modern CLI tools" block
  and `rtk` are opt-in. Don't uncomment or delete them without being asked.
- `mas` entries only work when the user is already signed into the Mac App Store; failures there
  are expected on a fresh machine and are why the Brewfile step tolerates partial failure.

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
