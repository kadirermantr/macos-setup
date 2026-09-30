#!/bin/bash
#
# defaults.sh: opinionated macOS system preferences.
# All commands are user-level (no sudo). Safe to re-run: a value is written only
# when it differs from the current one, and only the apps whose settings changed
# are restarted, so a second run changes nothing.
#
# Usage: ./defaults.sh [--dry-run]
#
set -euo pipefail

DRY_RUN=0
case "${1:-}" in
  "") ;;
  -n|--dry-run) DRY_RUN=1 ;;
  -h|--help)
    echo "Usage: ./defaults.sh [--dry-run]"
    echo "  --dry-run  List the settings that differ from this script; write nothing."
    exit 0
    ;;
  *)
    echo "Unknown option: $1 (try --help)" >&2
    exit 2
    ;;
esac

CHANGED=0
UNCHANGED=0
# Apps to restart, space-separated (bash 3.2 has no associative arrays).
RESTART=""

# set_default <domain> <key> <-bool|-int|-float|-string> <value> [app to restart]
set_default() {
  local domain="$1" key="$2" type="$3" value="$4" app="${5:-}"
  local current shown expected="$4"

  # `defaults read` prints booleans as 1/0.
  if [ "${type}" = "-bool" ]; then
    if [ "${value}" = "true" ]; then expected=1; else expected=0; fi
  fi

  current="$(defaults read "${domain}" "${key}" 2>/dev/null)" || current="(unset)"

  if [ "${current}" = "${expected}" ]; then
    UNCHANGED=$((UNCHANGED + 1))
    return 0
  fi

  shown="${current}"
  if [ "${type}" = "-bool" ]; then
    case "${current}" in
      1) shown="true" ;;
      0) shown="false" ;;
    esac
  fi

  CHANGED=$((CHANGED + 1))

  if [ "${DRY_RUN}" -eq 1 ]; then
    echo "  would set ${domain} ${key}: ${shown} -> ${value}"
    return 0
  fi

  defaults write "${domain}" "${key}" "${type}" "${value}"
  echo "  set ${domain} ${key}: ${shown} -> ${value}"

  if [ -n "${app}" ]; then
    case " ${RESTART} " in
      *" ${app} "*) ;;
      *) RESTART="${RESTART} ${app}" ;;
    esac
  fi
}

if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Checking macOS defaults (dry run, nothing is written)..."
else
  echo "Applying macOS defaults..."
fi

# ---------------------------------------------------------------------------
# Keyboard
# ---------------------------------------------------------------------------
# Fast key repeat and short delay (great for coding; lower = faster).
set_default NSGlobalDomain KeyRepeat -int 2
set_default NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold accent popup so key repeat works everywhere.
set_default NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Turn off the "smart" substitutions that corrupt code and terminal input.
set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
set_default NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# ---------------------------------------------------------------------------
# Finder
# ---------------------------------------------------------------------------
# Show hidden files, all extensions, path bar and status bar.
set_default com.apple.finder AppleShowAllFiles -bool true Finder
set_default NSGlobalDomain AppleShowAllExtensions -bool true Finder
set_default com.apple.finder ShowPathbar -bool true Finder
set_default com.apple.finder ShowStatusBar -bool true Finder
# Search the current folder by default (not the whole Mac).
set_default com.apple.finder FXDefaultSearchScope -string "SCcf" Finder
# Keep folders on top and skip the warning when changing a file extension.
set_default com.apple.finder _FXSortFoldersFirst -bool true Finder
set_default com.apple.finder FXEnableExtensionChangeWarning -bool false Finder
# Don't write .DS_Store files on network or USB volumes.
set_default com.apple.desktopservices DSDontWriteNetworkStores -bool true Finder
set_default com.apple.desktopservices DSDontWriteUSBStores -bool true Finder

# ---------------------------------------------------------------------------
# Dock
# ---------------------------------------------------------------------------
# Always visible; the delay only matters if autohide is turned back on.
set_default com.apple.dock autohide -bool false Dock
set_default com.apple.dock autohide-delay -float 0 Dock
set_default com.apple.dock tilesize -int 62 Dock
set_default com.apple.dock show-recents -bool false Dock

# ---------------------------------------------------------------------------
# Screenshots
# ---------------------------------------------------------------------------
# Save screenshots to ~/Screenshots as PNG without the drop shadow, so they stop
# piling up in ~/Downloads next to real downloads.
if [ "${DRY_RUN}" -eq 0 ]; then
  mkdir -p "${HOME}/Screenshots"
fi
set_default com.apple.screencapture location -string "${HOME}/Screenshots" SystemUIServer
set_default com.apple.screencapture type -string "png" SystemUIServer
set_default com.apple.screencapture disable-shadow -bool true SystemUIServer

# ---------------------------------------------------------------------------
# Apply changes
# ---------------------------------------------------------------------------
if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Dry run: ${CHANGED} setting(s) would change, ${UNCHANGED} already set."
  exit 0
fi

# Word splitting is intended: RESTART is a space-separated list of app names.
for app in ${RESTART}; do
  killall "${app}" 2>/dev/null || true
done

if [ "${CHANGED}" -eq 0 ]; then
  echo "macOS defaults already applied (${UNCHANGED} settings); nothing changed."
else
  echo "macOS defaults: ${CHANGED} changed, ${UNCHANGED} already set.${RESTART:+ Restarted:${RESTART}.}"
  echo "Some changes may require a logout/restart."
fi
