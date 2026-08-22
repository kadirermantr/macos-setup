# Brewfile — declarative macOS package manifest.
# Run with:  brew bundle install --file=Brewfile
# Re-capture current system with:  brew bundle dump --file=Brewfile --force --describe
#
# Edit freely: comment out anything you don't want on a fresh machine.
#
# NOTE on third-party taps: Homebrew 6 refuses to load formulae from untrusted
# taps, so `brew bundle` SKIPS them with a warning instead of failing, and the
# packages silently never install. There is no Brewfile syntax that grants trust
# (a `trusted: true` option on the tap line does NOT work); it has to come from
# `brew trust --tap`, which install.sh runs for the taps below before bundling.
# Adding a tap here means trusting its maintainers with code execution.

# ---------------------------------------------------------------------------
# Taps
# ---------------------------------------------------------------------------
# `brew bundle` is built into Homebrew now; the old homebrew/bundle tap is gone.
tap "mongodb/brew"
tap "supabase/tap"
tap "microsoft/mssql-release"

# ---------------------------------------------------------------------------
# CLI tools (formulae) — development
# ---------------------------------------------------------------------------
brew "git"                 # version control
brew "git-lfs"             # large file storage for git
brew "gh"                  # GitHub CLI
brew "bfg"                 # fast git history cleaner (remove secrets/large files)
brew "subversion"          # svn (WordPress.org plugin SVN, etc.)
brew "mas"                 # Mac App Store CLI (needed for the `mas` entries below)
brew "gnupg"               # commit signing / encryption

# Languages & runtimes
brew "node"                # Node.js (current; node@20 is EOL and gets disabled 2026-10-28)
brew "php@8.2"             # PHP 8.2 (keg-only; php@8.1 is EOL and gets disabled 2026-12-31)
brew "composer"            # PHP dependency manager
brew "openjdk"             # JDK (bfg and other JVM tools need it)

# Databases
brew "mysql"               # MySQL server + client
brew "mongosh"             # MongoDB shell
brew "mongodb-community", restart_service: false  # MongoDB server (via mongodb/brew tap)
brew "mongodb-database-tools"  # mongodump / mongorestore / mongoexport
brew "supabase/tap/supabase"   # Supabase CLI

# Content / media tooling
brew "hugo"                # static site generator
brew "pandoc"              # document converter
brew "ffmpeg"              # audio/video processing
brew "poppler"             # PDF utilities
brew "librsvg"             # SVG rasterizer (rsvg-convert)
brew "pngquant"            # PNG lossy compression
brew "oxipng"              # PNG lossless optimization
brew "jq"                  # JSON processor
brew "ripgrep"             # fast recursive search (rg)

# Shell / system
brew "powerlevel10k"       # zsh prompt theme
brew "sleepwatcher"        # run scripts on sleep/wake
brew "shellcheck"          # shell linter (used to check this repo's own scripts)

# Personal / custom
brew "mole"                # mac cleanup/optimization utility
# brew "rtk"               # custom LLM token-optimization proxy (private tap — add tap before enabling)

# ---------------------------------------------------------------------------
# Modern CLI tools
# ---------------------------------------------------------------------------
brew "eza"                 # modern ls (icons, git, tree)
brew "bat"                 # modern cat (syntax highlighting)
brew "fd"                  # modern find
brew "fzf"                 # fuzzy finder
brew "zoxide"              # smarter cd (z)
brew "lazygit"             # git TUI
brew "btop"                # modern top/htop
brew "tlrc"                # tldr client (simplified man pages)

# ---------------------------------------------------------------------------
# GUI apps (casks) — development & work
# ---------------------------------------------------------------------------
cask "raycast"             # launcher / productivity
cask "iterm2"              # terminal emulator
cask "visual-studio-code"  # editor
cask "jetbrains-toolbox"   # manages PhpStorm / PyCharm / Rider / Fleet
cask "docker-desktop"      # containers (renamed from the old `docker` cask)
cask "postman"             # API client
cask "tableplus"           # database GUI
cask "mongodb-compass"     # MongoDB GUI
cask "obsidian"            # notes / knowledge base
cask "shottr"              # screenshot + annotation
cask "dotnet-sdk"          # .NET SDK
cask "claude"              # Claude desktop

# XAMPP ships its own MySQL and binds port 3306, which collides with the `mysql`
# formula above. Uncomment only if you actually need the Apache/PHP stack.
# cask "xampp"

# Fonts
cask "font-meslo-lg-nerd-font"  # Nerd Font for Powerlevel10k

# ---------------------------------------------------------------------------
# GUI apps (casks) — personal / everyday (comment out on work machines)
# ---------------------------------------------------------------------------
cask "google-chrome"
cask "slack"
cask "spotify"
cask "whatsapp"
cask "anydesk"             # remote desktop
cask "openvpn-connect"     # VPN client

# ---------------------------------------------------------------------------
# Mac App Store apps (require `mas` + being signed into the App Store)
#
# `mas install` only works for apps already attached to your Apple ID. A fresh
# machine signed into the same account is fine; a brand-new account is not.
# ---------------------------------------------------------------------------
mas "Keynote", id: 361285480
mas "Numbers", id: 361304891
mas "Pages", id: 361309726
mas "Microsoft Excel", id: 462058435
mas "Microsoft Outlook", id: 985367838
mas "MorningPages", id: 1223874080
mas "Hidden Bar", id: 1452453066
