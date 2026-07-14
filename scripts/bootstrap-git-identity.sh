#!/bin/bash
# ============================================================================
# Bootstrap Git Identity (SSH + GitHub auth)
# ============================================================================
#
# Day-1 setup for a new machine: an SSH key, registered with GitHub, and git
# talking to GitHub over SSH.
#
# NOT needed to clone this repo — it's public, so the README's HTTPS clone works
# with no auth at all. This is for pushing to it, and for everything else you do
# on day 1.
#
# Safe to re-run: every step checks before acting.
#
# Usage:
#   ./scripts/bootstrap-git-identity.sh
#   ./scripts/bootstrap-git-identity.sh --dry-run
#
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

DRY_RUN=false
SSH_KEY="$HOME/.ssh/id_ed25519"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_do() { echo -e "${GREEN}[DO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

for arg in "$@"; do
    case $arg in
        -n|--dry-run) DRY_RUN=true ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

echo ""
echo -e "${BLUE}Git identity bootstrap${NC}"
[[ "$DRY_RUN" == true ]] && log_warn "DRY RUN — nothing will be changed"
echo ""

# ----------------------------------------------------------------------------
# 1. gh CLI
# ----------------------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
    log_error "gh (GitHub CLI) not installed."
    echo "    Run ./scripts/brew_install_all.sh first — the Brewfile declares it."
    exit 1
fi
log_ok "gh installed ($(gh --version | head -1))"

# ----------------------------------------------------------------------------
# 2. Identity — comes from the tracked XDG config (git/config in this repo)
# ----------------------------------------------------------------------------
GIT_EMAIL="$(git config user.email 2>/dev/null || true)"
GIT_NAME="$(git config user.name 2>/dev/null || true)"
if [[ -z "$GIT_EMAIL" || -z "$GIT_NAME" ]]; then
    log_error "git user.name/user.email not set."
    echo "    Expected them from ~/.config/git/config (tracked in this repo)."
    echo "    If ~/.gitconfig exists it shadows that file — remove it."
    exit 1
fi
log_ok "identity: $GIT_NAME <$GIT_EMAIL>"

if [[ -f "$HOME/.gitconfig" ]]; then
    log_warn "~/.gitconfig exists and overrides the tracked ~/.config/git/config."
    echo -e "${DIM}    Remove it so the repo's config wins and 'git config --global' stays tracked.${NC}"
fi

# ----------------------------------------------------------------------------
# 3. GitHub auth
# ----------------------------------------------------------------------------
if gh auth status >/dev/null 2>&1; then
    log_ok "gh already authenticated ($(gh api user --jq .login 2>/dev/null || echo '?'))"
else
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would run: gh auth login --git-protocol ssh --web"
    else
        log_do "Authenticating with GitHub (browser will open)..."
        gh auth login --git-protocol ssh --web || {
            log_error "gh auth login failed"; exit 1; }
        log_ok "authenticated as $(gh api user --jq .login 2>/dev/null)"
    fi
fi

# ----------------------------------------------------------------------------
# 4. SSH key
# ----------------------------------------------------------------------------
if [[ -f "$SSH_KEY" ]]; then
    log_ok "SSH key exists: $SSH_KEY"
else
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would generate: ssh-keygen -t ed25519 -C \"$GIT_EMAIL\" -f $SSH_KEY"
    else
        log_do "Generating an ed25519 SSH key..."
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
        log_ok "generated $SSH_KEY"
    fi
fi

# ----------------------------------------------------------------------------
# 5. Keep the key loaded across reboots (macOS keychain)
# ----------------------------------------------------------------------------
SSH_CONFIG="$HOME/.ssh/config"
if [[ -f "$SSH_CONFIG" ]] && grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    log_ok "~/.ssh/config already has a github.com entry"
elif [[ "$DRY_RUN" == true ]]; then
    log_dry "Would add a github.com block to ~/.ssh/config (UseKeychain/AddKeysToAgent)"
else
    log_do "Adding github.com block to ~/.ssh/config..."
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    cat >> "$SSH_CONFIG" << EOF

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_KEY
EOF
    chmod 600 "$SSH_CONFIG"
    log_ok "updated ~/.ssh/config"
fi

if [[ "$DRY_RUN" != true && -f "$SSH_KEY" ]]; then
    ssh-add --apple-use-keychain "$SSH_KEY" >/dev/null 2>&1 && log_ok "key added to ssh-agent/keychain" || true
fi

# ----------------------------------------------------------------------------
# 6. Register the key with GitHub — but only if it isn't working already
# ----------------------------------------------------------------------------
#
# SSH connectivity is the ground truth, so test that first rather than asking
# gh whether the key is registered. `gh ssh-key list` needs the
# admin:public_key scope, which a default `gh auth login` does NOT grant — it
# 404s. Trusting it would make a perfectly working setup look broken and
# trigger a pointless re-upload.

# GitHub grants no shell access, so a *successful* auth still exits 1. Capture
# the output and match on it rather than piping: this script sets `pipefail`, so
# `ssh ... | grep` would inherit ssh's exit 1 and report a working key as broken.
github_ssh_works() {
    local out
    out="$(ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -T git@github.com 2>&1 || true)"
    [[ "$out" == *"successfully authenticated"* ]]
}

echo ""
if [[ "$DRY_RUN" == true ]]; then
    log_dry "Would test 'ssh -T git@github.com' and upload the key only if it fails"
else
    log_info "Verifying SSH to GitHub..."
    if github_ssh_works; then
        log_ok "SSH works — key is already registered with GitHub"
    else
        log_info "SSH not working yet; registering the public key..."
        if [[ ! -f "$SSH_KEY.pub" ]]; then
            log_error "no public key at $SSH_KEY.pub"
            exit 1
        fi
        # Needs a scope the default login doesn't grant; request it on demand.
        if ! gh ssh-key list >/dev/null 2>&1; then
            log_info "Requesting the admin:public_key scope (browser will open)..."
            gh auth refresh -h github.com -s admin:public_key || true
        fi

        LOCAL_KEY="$(awk '{print $2}' "$SSH_KEY.pub")"
        if gh ssh-key list 2>/dev/null | grep -q "$LOCAL_KEY"; then
            log_ok "key already registered (SSH may just need a moment)"
        else
            log_do "Uploading public key to GitHub..."
            gh ssh-key add "$SSH_KEY.pub" \
                --title "$(scutil --get ComputerName 2>/dev/null || hostname)" \
                && log_ok "key uploaded" \
                || log_warn "upload failed — add it manually: https://github.com/settings/keys"
        fi

        if github_ssh_works; then
            log_ok "SSH to GitHub now works"
        else
            log_warn "SSH still not authenticating. Public key:"
            echo -e "${DIM}    $(cat "$SSH_KEY.pub")${NC}"
            echo -e "${DIM}    Add it at https://github.com/settings/keys${NC}"
        fi
    fi
fi

# ----------------------------------------------------------------------------
# 8. Offer to move this repo's origin to SSH
# ----------------------------------------------------------------------------
echo ""
origin="$(git -C "$CONFIG_DIR" remote get-url origin 2>/dev/null || true)"
if [[ "$origin" == https://github.com/* ]]; then
    ssh_url="git@github.com:${origin#https://github.com/}"
    ssh_url="${ssh_url%.git}.git"
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would switch origin: $origin -> $ssh_url"
    else
        log_do "Switching this repo's origin to SSH so you can push..."
        git -C "$CONFIG_DIR" remote set-url origin "$ssh_url"
        log_ok "origin -> $ssh_url"
    fi
elif [[ -n "$origin" ]]; then
    log_ok "origin already uses SSH: $origin"
fi

echo ""
log_ok "Git identity ready."
echo ""
