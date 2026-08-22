#!/bin/bash
#
# defaults.sh — opinionated macOS system preferences.
# All commands are user-level (no sudo). Safe to re-run.
#
set -euo pipefail

echo "Applying macOS defaults..."

# ---------------------------------------------------------------------------
# Keyboard
# ---------------------------------------------------------------------------
# Fast key repeat and short delay (great for coding; lower = faster).
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold accent popup so key repeat works everywhere.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Turn off the "smart" substitutions that corrupt code and terminal input.
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# ---------------------------------------------------------------------------
# Finder
# ---------------------------------------------------------------------------
# Show hidden files, all extensions, path bar and status bar.
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Search the current folder by default (not the whole Mac).
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Keep folders on top and skip the warning when changing a file extension.
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Don't write .DS_Store files on network or USB volumes.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ---------------------------------------------------------------------------
# Dock
# ---------------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false

# ---------------------------------------------------------------------------
# Screenshots
# ---------------------------------------------------------------------------
# Save screenshots to ~/Screenshots as PNG without the drop shadow, so they stop
# piling up in ~/Downloads next to real downloads.
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ---------------------------------------------------------------------------
# Apply changes
# ---------------------------------------------------------------------------
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Some changes may require a logout/restart."
