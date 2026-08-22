#!/bin/bash
#
# install.sh — bootstrap a macOS machine.
#
# Order matters: Xcode CLT -> Rosetta -> Homebrew -> shellenv -> tap trust -> Brewfile -> defaults.
# Safe to re-run (idempotent).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Brewfile.lock.json is noise for a repo that tracks intent, not pinned versions.
# The old `--no-lock` flag is gone in Homebrew 6; this env var replaces it.
export HOMEBREW_BUNDLE_NO_LOCK=1

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}==>${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "${YELLOW}!${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

# Collected non-fatal problems, printed together at the end so a warning that
# scrolled past mid-run still reaches the user.
WARNINGS=()
warn() { WARNINGS+=("$1"); log_warn "$1"; }

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# ---------------------------------------------------------------------------
# `xcode-select -p` only proves a developer directory is set, not that the CLT
# package is actually installed, so check the receipt instead.
if pkgutil --pkg-info com.apple.pkg.CLTools_Executables >/dev/null 2>&1; then
  log_success "Xcode Command Line Tools already installed."
else
  log_info "Installing Xcode Command Line Tools..."
  xcode-select --install 2>/dev/null || true
  log_warn "Finish the CLT installer dialog, then re-run this script."
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Rosetta 2 (Apple Silicon only)
# ---------------------------------------------------------------------------
if [ "$(uname -m)" = "arm64" ]; then
  # The oahd daemon only runs once something x86 has launched, so its absence
  # does not mean Rosetta is missing. The runtime directory is the real proof.
  if [ -d /Library/Apple/usr/share/rosetta ] || /usr/bin/pgrep -q oahd; then
    log_success "Rosetta 2 already installed."
  else
    log_info "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license || warn "Rosetta install skipped/failed."
  fi
fi

# ---------------------------------------------------------------------------
# 3. Homebrew
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log_info "Installing Homebrew..."
  log_warn "Homebrew will ask for your password."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log_success "Homebrew already installed."
fi

# Load brew into this shell (Apple Silicon uses /opt/homebrew).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  # Without this branch the script would sail on and fail confusingly at the
  # first brew command instead of here, where the cause is obvious.
  log_error "Homebrew is not available at /opt/homebrew or /usr/local. Install it manually and re-run."
  exit 1
fi

# A stale index is survivable; a network blip should not abort the whole bootstrap.
log_info "Updating Homebrew..."
brew update || warn "brew update failed (offline?); continuing with the current package index."

# ---------------------------------------------------------------------------
# 4. Trust the third-party taps the Brewfile needs
# ---------------------------------------------------------------------------
# Homebrew 6 refuses to load formulae from untrusted taps. `brew bundle` treats
# that as a skip, not an error, so without this step those packages silently
# never install. Only taps declared in the Brewfile are trusted here.
if brew help trust >/dev/null 2>&1; then
  while read -r tap_name; do
    [ -n "${tap_name}" ] || continue
    if brew trust --tap "${tap_name}" >/dev/null 2>&1; then
      log_success "Trusted tap: ${tap_name}"
    else
      warn "Could not trust tap ${tap_name}; its packages may be skipped."
    fi
  done < <(grep -oE '^tap "[^"]+"' "${SCRIPT_DIR}/Brewfile" | sed 's/tap "//;s/"//')
fi

# ---------------------------------------------------------------------------
# 5. Install everything from the Brewfile
# ---------------------------------------------------------------------------
if [ -f "${SCRIPT_DIR}/Brewfile" ]; then
  log_info "Installing packages from Brewfile..."
  brew bundle install --file="${SCRIPT_DIR}/Brewfile" || warn "Some Brewfile entries failed; continuing."
  log_success "Brewfile processed."
else
  log_error "Brewfile not found next to install.sh."
  exit 1
fi

# ---------------------------------------------------------------------------
# 6. macOS defaults
# ---------------------------------------------------------------------------
if [ -f "${SCRIPT_DIR}/defaults.sh" ]; then
  log_info "Applying macOS defaults..."
  bash "${SCRIPT_DIR}/defaults.sh" || warn "Some defaults failed to apply."
fi

# ---------------------------------------------------------------------------
# 7. Report what is still missing
# ---------------------------------------------------------------------------
# `brew bundle install` exits 0 even when it skipped entries, so ask explicitly
# rather than trusting the exit code.
log_info "Verifying the Brewfile..."
if brew bundle check --file="${SCRIPT_DIR}/Brewfile" >/dev/null 2>&1; then
  log_success "Every Brewfile entry is installed."
else
  warn "Some Brewfile entries are still missing:"
  brew bundle check --file="${SCRIPT_DIR}/Brewfile" --verbose 2>&1 | grep '^→' || true
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo
if [ ${#WARNINGS[@]} -eq 0 ]; then
  log_success "Bootstrap complete with no warnings."
else
  log_warn "Bootstrap complete with ${#WARNINGS[@]} warning(s):"
  # macOS ships bash 3.2, where "${arr[@]}" on an empty array trips `set -u`.
  # Guarded by the count check above, but keep the fallback for safety.
  for w in "${WARNINGS[@]:-}"; do echo "    - ${w}"; done
fi

echo
log_info "Manual follow-ups:"
echo "  • Sign in to the Mac App Store, then re-run: mas only installs apps already tied to your Apple ID."
echo "  • Set Powerlevel10k: add 'source \$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme' to ~/.zshrc, then run 'p10k configure'."
echo "  • Set the MesloLGS NF font in your terminal."
echo "  • Configure Raycast, iTerm2 and JetBrains Toolbox sign-in manually."
