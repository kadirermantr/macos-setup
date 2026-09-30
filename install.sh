#!/bin/bash
#
# install.sh: bootstrap a macOS machine.
#
# Order matters: Xcode CLT -> Rosetta -> Homebrew -> shellenv -> tap trust -> Brewfile -> defaults.
# Safe to re-run (idempotent): missing items are installed, installed ones stay at
# their current version unless --upgrade is passed.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="${SCRIPT_DIR}/Brewfile"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--check] [--upgrade]

  (no option)  Install whatever the Brewfile declares but is missing, then apply
               defaults.sh. Installed packages stay at their current version.
  --upgrade    Also upgrade outdated Brewfile entries (formulae, casks, App Store apps).
  --check      Change nothing: report what is missing and which macOS defaults differ.
  -h, --help   Show this help.
EOF
}

CHECK_ONLY=0
UPGRADE=0
for arg in "$@"; do
  case "${arg}" in
    --check) CHECK_ONLY=1 ;;
    --upgrade) UPGRADE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: ${arg}" >&2; usage >&2; exit 2 ;;
  esac
done

# Brewfile.lock.json is noise for a repo that tracks intent, not pinned versions.
# The old `--no-lock` flag is gone in Homebrew 6; this env var replaces it.
export HOMEBREW_BUNDLE_NO_LOCK=1

# `brew bundle install` upgrades every outdated entry by default, so a plain re-run
# would move a database formula across major versions together with its data
# directory. Upgrading is opt-in; `brew bundle check` honors the same variable.
if [ "${UPGRADE}" -eq 1 ]; then
  unset HOMEBREW_BUNDLE_NO_UPGRADE
else
  export HOMEBREW_BUNDLE_NO_UPGRADE=1
fi

# Check mode must not even refresh Homebrew's own index.
if [ "${CHECK_ONLY}" -eq 1 ]; then
  export HOMEBREW_NO_AUTO_UPDATE=1
fi

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
# Colors only on a terminal, and never when NO_COLOR is set (https://no-color.org).
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
else
  BLUE=''; GREEN=''; YELLOW=''; RED=''; BOLD=''; NC=''
fi
log_info()    { echo -e "${BLUE}==>${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "${YELLOW}!${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

TOTAL_STEPS=7
STEP=0
step() { STEP=$((STEP + 1)); echo; echo -e "${BOLD}[${STEP}/${TOTAL_STEPS}] $1${NC}"; }

# Collected non-fatal problems, printed together at the end so a warning that
# scrolled past mid-run still reaches the user.
WARNINGS=()
warn() { WARNINGS+=("$1"); log_warn "$1"; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
# Homebrew refuses to run as root, and under sudo defaults.sh would write root's
# preferences instead of yours.
if [ "${EUID}" -eq 0 ]; then
  log_error "Run install.sh as your normal user, without sudo."
  exit 1
fi

if [ ! -f "${BREWFILE}" ]; then
  log_error "Brewfile not found next to install.sh."
  exit 1
fi

if [ "${CHECK_ONLY}" -eq 1 ]; then
  log_info "Check mode: nothing will be installed, trusted or written."
elif command -v caffeinate >/dev/null 2>&1; then
  # A full run downloads several GB; keep the Mac from idle-sleeping until this
  # script exits (`-w` makes caffeinate quit on its own when this PID does).
  caffeinate -i -w "$$" >/dev/null 2>&1 &
fi

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# ---------------------------------------------------------------------------
step "Xcode Command Line Tools"
# `xcode-select -p` only proves a developer directory is set, not that the CLT
# package is actually installed, so check the receipt instead.
if pkgutil --pkg-info com.apple.pkg.CLTools_Executables >/dev/null 2>&1; then
  log_success "Already installed."
elif [ "${CHECK_ONLY}" -eq 1 ]; then
  warn "Xcode Command Line Tools are not installed."
else
  log_info "Installing Xcode Command Line Tools..."
  xcode-select --install 2>/dev/null || true
  log_warn "Finish the CLT installer dialog, then re-run this script."
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Rosetta 2 (Apple Silicon only)
# ---------------------------------------------------------------------------
step "Rosetta 2"
# The oahd daemon only runs once something x86 has launched, so its absence
# does not mean Rosetta is missing. The runtime directory is the real proof.
if [ "$(uname -m)" != "arm64" ]; then
  log_success "Not needed on an Intel Mac."
elif [ -d /Library/Apple/usr/share/rosetta ] || /usr/bin/pgrep -q oahd; then
  log_success "Already installed."
elif [ "${CHECK_ONLY}" -eq 1 ]; then
  warn "Rosetta 2 is not installed."
else
  log_info "Installing Rosetta 2..."
  softwareupdate --install-rosetta --agree-to-license || warn "Rosetta install skipped/failed."
fi

# ---------------------------------------------------------------------------
# 3. Homebrew
# ---------------------------------------------------------------------------
step "Homebrew"
# Look in both default prefixes before PATH: a shell that has not loaded
# `brew shellenv` would otherwise re-run the installer over a working install.
find_brew() {
  if [ -x /opt/homebrew/bin/brew ]; then
    echo /opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then
    echo /usr/local/bin/brew
  else
    command -v brew || true
  fi
}
BREW_BIN="$(find_brew)"

if [ -n "${BREW_BIN}" ]; then
  log_success "Already installed."
elif [ "${CHECK_ONLY}" -eq 1 ]; then
  warn "Homebrew is not installed, so taps and the Brewfile cannot be checked."
else
  log_info "Installing Homebrew..."
  log_warn "Homebrew will ask for your password."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW_BIN="$(find_brew)"

  if [ -z "${BREW_BIN}" ]; then
    # Without this branch the script would sail on and fail confusingly at the
    # first brew command instead of here, where the cause is obvious.
    log_error "Homebrew is not available at /opt/homebrew or /usr/local. Install it manually and re-run."
    exit 1
  fi
fi

if [ -n "${BREW_BIN}" ]; then
  # Load brew into this shell; right after a fresh install it is not on PATH yet.
  eval "$("${BREW_BIN}" shellenv)"
fi

if [ -n "${BREW_BIN}" ] && [ "${CHECK_ONLY}" -eq 0 ]; then
  # A stale index is survivable; a network blip should not abort the whole bootstrap.
  log_info "Updating Homebrew..."
  brew update || warn "brew update failed (offline?); continuing with the current package index."
fi

# ---------------------------------------------------------------------------
# 4. Trust the third-party taps the Brewfile needs
# ---------------------------------------------------------------------------
# Homebrew 6 refuses to load formulae from untrusted taps. `brew bundle` treats
# that as a skip, not an error, so without this step those packages silently
# never install. Only taps declared in the Brewfile are trusted here.
step "Third-party taps"
if [ -z "${BREW_BIN}" ]; then
  log_warn "Skipped: Homebrew is not installed."
elif ! brew help trust >/dev/null 2>&1; then
  log_success "This Homebrew has no tap trust; nothing to do."
else
  TRUSTED_JSON="$(brew trust --json=v1 2>/dev/null || true)"
  while read -r tap_name; do
    [ -n "${tap_name}" ] || continue

    # Matched with the quotes so "f/textream" never hits "f/textream/textream".
    case "${TRUSTED_JSON}" in
      *"\"${tap_name}\""*)
        log_success "Already trusted: ${tap_name}"
        continue
        ;;
    esac

    if [ "${CHECK_ONLY}" -eq 1 ]; then
      warn "Tap not trusted yet: ${tap_name}"
    elif brew trust --tap "${tap_name}" >/dev/null 2>&1; then
      log_success "Trusted tap: ${tap_name}"
    else
      warn "Could not trust tap ${tap_name}; its packages may be skipped."
    fi
  done < <(grep -oE '^tap "[^"]+"' "${BREWFILE}" | sed 's/tap "//;s/"//')
fi

# ---------------------------------------------------------------------------
# 5. Install everything from the Brewfile
# ---------------------------------------------------------------------------
step "Brewfile packages"
if [ -z "${BREW_BIN}" ]; then
  log_warn "Skipped: Homebrew is not installed."
elif [ "${CHECK_ONLY}" -eq 1 ]; then
  log_info "Skipped in check mode; step ${TOTAL_STEPS} lists what a real run would install."
else
  if [ "${UPGRADE}" -eq 1 ]; then
    log_info "Installing missing packages and upgrading outdated ones..."
  else
    log_info "Installing missing packages (installed ones are left as they are; --upgrade upgrades them)..."
  fi
  # Casks that ship a .pkg and App Store installs escalate through sudo.
  log_warn "This step can ask for your password more than once; keep an eye on the terminal."
  brew bundle install --file="${BREWFILE}" || warn "Some Brewfile entries failed; continuing."
  log_success "Brewfile processed."
fi

# ---------------------------------------------------------------------------
# 6. macOS defaults
# ---------------------------------------------------------------------------
step "macOS defaults"
if [ ! -f "${SCRIPT_DIR}/defaults.sh" ]; then
  warn "defaults.sh not found next to install.sh; skipped."
elif [ "${CHECK_ONLY}" -eq 1 ]; then
  /bin/bash "${SCRIPT_DIR}/defaults.sh" --dry-run || warn "defaults.sh --dry-run failed."
else
  /bin/bash "${SCRIPT_DIR}/defaults.sh" || warn "Some defaults failed to apply."
fi

# ---------------------------------------------------------------------------
# 7. Report what is still missing
# ---------------------------------------------------------------------------
# `brew bundle install` exits 0 even when it skipped entries, so ask explicitly
# rather than trusting the exit code.
step "Verification"
if [ -z "${BREW_BIN}" ]; then
  log_warn "Skipped: Homebrew is not installed."
elif brew bundle check --file="${BREWFILE}" >/dev/null 2>&1; then
  log_success "Every Brewfile entry is installed."
else
  MISSING="$(brew bundle check --file="${BREWFILE}" --verbose 2>&1 | grep '^→' || true)"

  if [ -z "${MISSING}" ]; then
    warn "brew bundle check failed without naming an entry; run it with --verbose to see why."
  else
    # List first, so "listed above" holds both here and in the final summary.
    printf '%s\n' "${MISSING}"
    MISSING_COUNT="$(printf '%s\n' "${MISSING}" | wc -l | tr -d ' ')"

    if [ "${CHECK_ONLY}" -eq 1 ]; then
      warn "A real run would install or update ${MISSING_COUNT} Brewfile entries (listed above)."
    else
      warn "${MISSING_COUNT} Brewfile entries are still missing (listed above)."
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
ELAPSED="$((SECONDS / 60))m $((SECONDS % 60))s"
if [ "${CHECK_ONLY}" -eq 1 ]; then
  OUTCOME="Check finished"
else
  OUTCOME="Bootstrap complete"
fi

echo
if [ ${#WARNINGS[@]} -eq 0 ]; then
  log_success "${OUTCOME} in ${ELAPSED} with no warnings."
else
  log_warn "${OUTCOME} in ${ELAPSED} with ${#WARNINGS[@]} warning(s):"
  # macOS ships bash 3.2, where "${arr[@]}" on an empty array trips `set -u`.
  # Guarded by the count check above, but keep the fallback for safety.
  for w in "${WARNINGS[@]:-}"; do echo "    - ${w}"; done
fi

if [ "${CHECK_ONLY}" -eq 1 ]; then
  echo
  log_info "Nothing was changed. Run ./install.sh to apply."
  exit 0
fi

echo
log_info "Manual follow-ups (details in the README's Post-install section):"
echo "  • Sign in to the Mac App Store if the App Store apps above failed: free apps are fetched for you, paid ones must be bought once first."
echo "  • Set Powerlevel10k: add 'source \$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme' to ~/.zshrc, then run 'p10k configure'."
echo "  • Set the MesloLGS NF font in your terminal."
echo "  • Enable zoxide and fzf in ~/.zshrc, and symlink the JDK if macOS's java wrappers need it."
echo "  • Configure Raycast, iTerm2 and JetBrains Toolbox sign-in manually."
