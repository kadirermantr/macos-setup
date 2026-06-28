#!/bin/bash
#
# install.sh — bootstrap a macOS machine.
#
# Order matters: Xcode CLT -> Rosetta -> Homebrew -> shellenv -> Brewfile -> defaults.
# Safe to re-run (idempotent).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}==>${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "${YELLOW}!${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# ---------------------------------------------------------------------------
if xcode-select -p >/dev/null 2>&1; then
  log_success "Xcode Command Line Tools already installed."
else
  log_info "Installing Xcode Command Line Tools..."
  xcode-select --install
  log_warn "Finish the CLT installer dialog, then re-run this script."
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Rosetta 2 (Apple Silicon only)
# ---------------------------------------------------------------------------
if [ "$(uname -m)" = "arm64" ]; then
  if /usr/bin/pgrep -q oahd; then
    log_success "Rosetta 2 already installed."
  else
    log_info "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license || log_warn "Rosetta install skipped/failed."
  fi
fi

# ---------------------------------------------------------------------------
# 3. Homebrew
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log_success "Homebrew already installed."
fi

# Load brew into this shell (Apple Silicon uses /opt/homebrew).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

log_info "Updating Homebrew..."
brew update

# ---------------------------------------------------------------------------
# 4. Install everything from the Brewfile
# ---------------------------------------------------------------------------
if [ -f "${SCRIPT_DIR}/Brewfile" ]; then
  log_info "Installing packages from Brewfile..."
  # --no-lock avoids writing a Brewfile.lock.json; remove if you want a lockfile.
  brew bundle install --file="${SCRIPT_DIR}/Brewfile" || log_warn "Some Brewfile entries failed; continuing."
  log_success "Brewfile processed."
else
  log_error "Brewfile not found next to install.sh."
  exit 1
fi

# ---------------------------------------------------------------------------
# 5. macOS defaults
# ---------------------------------------------------------------------------
if [ -f "${SCRIPT_DIR}/defaults.sh" ]; then
  log_info "Applying macOS defaults..."
  bash "${SCRIPT_DIR}/defaults.sh" || log_warn "Some defaults failed to apply."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
log_success "Bootstrap complete."
echo
log_info "Manual follow-ups:"
echo "  • Sign in to the Mac App Store before re-running for 'mas' apps."
echo "  • Set Powerlevel10k: add 'source \$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme' to ~/.zshrc, then run 'p10k configure'."
echo "  • Set the MesloLGS NF font in your terminal."
echo "  • Configure Raycast, iTerm2 and JetBrains Toolbox sign-in manually."
