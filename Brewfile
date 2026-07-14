# Homebrew baseline for macOS setup.
#
# Apply with:  ./scripts/brew_install_all.sh
# Audit with:  ./scripts/audit-brew.sh
#
# This file is the single source of truth for everything Homebrew installs.
# Generated from this machine's on-request install receipts, then curated.
#
# NOTE: `brew bundle dump` silently omits every third-party-tap formula, so do
# not regenerate this file with it. audit-brew.sh reads Cellar receipts instead.

# ============================================================================
# Taps
# ============================================================================

tap "datadog-labs/pack"      # pup
tap "derailed/k9s"           # k9s
tap "hashicorp/tap"          # terraform
tap "ibigio/tap"             # shell-ai
tap "infisical/get-cli"      # infisical
tap "jurplel/tap"            # instant-space-switcher
tap "ngrok/ngrok"            # ngrok
tap "supabase/tap"           # supabase
tap "withgraphite/tap"       # graphite (gt)

# ============================================================================
# Shell & core CLI
# ============================================================================

brew "bash"
brew "zsh"
brew "coreutils"             # .zshrc aliases `timeout` -> gtimeout
brew "tmux"
brew "fzf"
brew "bat"
brew "fd"
brew "ripgrep"
brew "jq"                    # required by claude/notify-end.sh
brew "yq"
brew "csvkit"
brew "hyperfine"
brew "just"
brew "terminal-notifier"     # used by claude/notify-end.sh
brew "neovim"                # .zshrc aliases vim/vi -> nvim

# ============================================================================
# Git & GitHub
# ============================================================================

brew "git"
brew "gh"
brew "git-lfs"
brew "git-spice"
brew "gitleaks"
brew "withgraphite/tap/graphite"

# ============================================================================
# Languages & runtimes
# ============================================================================

brew "node"
brew "nvm"
brew "pnpm"
brew "yarn"
brew "python@3.12"
brew "python@3.13"
brew "python-tk@3.12"
brew "tcl-tk"
brew "pipx"
brew "rye"
brew "uv"
brew "ruby"
brew "rustup"
brew "rust"                  # NOTE: overlaps rustup; see audit notes
brew "libgit2"
brew "cocoapods"
brew "fastlane"

# ============================================================================
# Cloud & infra
# ============================================================================

brew "awscli"
brew "aws-sam-cli"
brew "hashicorp/tap/terraform"
brew "helm"
brew "derailed/k9s/k9s"
brew "cloudflared"
brew "caddy"
brew "dnsmasq"
brew "sops"
brew "infisical/get-cli/infisical"
brew "supabase/tap/supabase"
brew "temporal"

# ============================================================================
# Data
# ============================================================================

brew "duckdb"
brew "postgresql@14"
brew "postgresql@17"

# ============================================================================
# Dev tools
# ============================================================================

brew "act"
brew "actionlint"
brew "biome"
brew "neonctl"
brew "gmailctl"
brew "tmuxai"
brew "ibigio/tap/shell-ai"
brew "datadog-labs/pack/pup"

# ============================================================================
# Media
# ============================================================================

brew "ffmpeg"                # .zshrc *-convert-mp3 aliases
brew "imagemagick"           # .zshrc webp-convert-downloads

# ============================================================================
# macOS utilities
# ============================================================================

brew "blueutil"
brew "ddcctl"
brew "mas"                   # required for the App Store apps below

# ============================================================================
# Casks — terminal & editors
# ============================================================================

cask "iterm2"
cask "ghostty"
cask "visual-studio-code"
cask "cursor"
cask "zed"
cask "font-fira-code"

# ============================================================================
# Casks — window management & input (see README for the Karabiner wiring)
# ============================================================================

cask "karabiner-elements"
cask "rectangle"
cask "contexts"
cask "hammerspoon"
cask "thaw"
cask "keyboard-maestro"
cask "raycast"
cask "jurplel/tap/instant-space-switcher"
cask "logi-options+"
cask "hazeover"

# ============================================================================
# Casks — dev
# ============================================================================

cask "docker-desktop"
cask "tableplus"
cask "clickhouse"
cask "gcloud-cli"
cask "ngrok/ngrok/ngrok"
cask "1password-cli"
cask "superset"
cask "conductor"
cask "xquartz"

# ============================================================================
# Casks — browsers & comms
# ============================================================================

cask "google-chrome"
cask "firefox"
cask "slack"
cask "discord"
cask "zoom"
cask "microsoft-teams"

# ============================================================================
# Casks — AI
# ============================================================================

cask "claude"
cask "chatgpt"
cask "codex"                 # CLI binary only (.zshrc aliases it). Codex.app is
                             # a separate direct download, not reproduced here.
cask "lm-studio"
cask "superwhisper"

# ============================================================================
# Casks — productivity
# ============================================================================

cask "notion"
cask "obsidian"
cask "linear"
cask "figma"
cask "granola"
cask "ticktick"
cask "cleanshot"
cask "google-drive"
cask "onedrive"
cask "microsoft-word"
cask "microsoft-excel"
cask "microsoft-powerpoint"
cask "microsoft-onenote"
cask "tuple"

# ============================================================================
# Casks — media & DJ
# ============================================================================

cask "spotify"
# cask "rekordbox"           # DELIBERATELY COMMENTED: this machine runs rekordbox 6,
                             # but the cask now ships 7.x. Installing 7 migrates the
                             # library irreversibly. Uncomment only if you intend to
                             # move to 7 on the new machine.
cask "audacity"
cask "iina"
cask "soulseek"
cask "qbittorrent"

# ============================================================================
# Casks — utilities & security
# ============================================================================

cask "1password"
cask "malwarebytes"
cask "mullvad-vpn"
cask "surfshark"

# ============================================================================
# Casks — work (usually MDM-pushed; safe to drop on a personal machine)
# ============================================================================

cask "okta-verify"
cask "drata-agent"

# ============================================================================
# Mac App Store
# ============================================================================
#
# Velja is App Store-only — there is no `cask "velja"`. Declaring one made
# `brew bundle install` fail outright.

mas "Velja", id: 1607635845
mas "Bitwarden", id: 1352778147
mas "Tailscale", id: 1475387142
mas "WhatsApp", id: 310633997
mas "MeetingBar", id: 1532419400
mas "Jomo", id: 1609960918
mas "AmorphousDiskMark", id: 1168254295
mas "Xcode", id: 497799835
