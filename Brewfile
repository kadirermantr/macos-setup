# Brewfile — declarative macOS package manifest.
# Run with:  brew bundle install --file=Brewfile
# Re-capture current system with:  brew bundle dump --file=Brewfile --force --describe
#
# Edit freely: comment out anything you don't want on a fresh machine.

# ---------------------------------------------------------------------------
# Taps
# ---------------------------------------------------------------------------
tap "homebrew/bundle"
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

# Languages & runtimes
brew "node@20"             # Node.js
brew "php@8.1"             # PHP 8.1
brew "php@8.2"             # PHP 8.2
brew "composer"            # PHP dependency manager

# Databases
brew "mysql"               # MySQL server + client
brew "mongosh"             # MongoDB shell
brew "mongodb-community", restart_service: false  # MongoDB server (via mongodb/brew tap)

# Content / media tooling
brew "hugo"                # static site generator
brew "pandoc"             # document converter
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

# Personal / custom
brew "mole"                # mac cleanup/optimization utility
# brew "rtk"               # custom LLM token-optimization proxy (private tap — add tap before enabling)

# ---------------------------------------------------------------------------
# Recommended modern CLI tools (not yet installed — uncomment to adopt)
# ---------------------------------------------------------------------------
# brew "eza"               # modern ls (icons, git, tree)
# brew "bat"               # modern cat (syntax highlighting)
# brew "fd"                # modern find
# brew "fzf"               # fuzzy finder
# brew "zoxide"            # smarter cd (z)
# brew "lazygit"           # git TUI
# brew "btop"              # modern top/htop
# brew "tldr"              # simplified man pages

# ---------------------------------------------------------------------------
# GUI apps (casks) — development & work
# ---------------------------------------------------------------------------
cask "raycast"             # launcher / productivity
cask "iterm2"              # terminal emulator
cask "visual-studio-code"  # editor
cask "jetbrains-toolbox"   # manages PhpStorm / PyCharm / Rider / Fleet
cask "docker"              # containers
cask "postman"             # API client
cask "tableplus"           # database GUI
cask "mongodb-compass"     # MongoDB GUI
cask "obsidian"            # notes / knowledge base
cask "shottr"              # screenshot + annotation
cask "xampp"               # local Apache/MySQL/PHP stack
cask "dotnet-sdk"          # .NET SDK
cask "claude"              # Claude desktop

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
# ---------------------------------------------------------------------------
mas "Keynote", id: 361285480
mas "Numbers", id: 361304891
mas "Pages", id: 361309726
mas "iMovie", id: 408981434
mas "GarageBand", id: 682658836
mas "Microsoft Excel", id: 462058435
mas "Microsoft Outlook", id: 985367838
mas "MorningPages", id: 1223874080
mas "Windows App", id: 1295203466
mas "Hidden Bar", id: 1452453066
