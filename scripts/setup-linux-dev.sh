#!/bin/bash
# ============================================================================
# Linux Development Environment Setup Script
# ============================================================================
#
# Description:
#   Automated setup script for Linux development environments.
#   Installs and configures: zsh, oh-my-zsh, tmux, fzf, NVM, Node.js,
#   Claude Code CLI, shell-ai, and dotfiles from GitHub.
#
# Usage:
#   With sudo (full installation):
#     curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash
#
#   Without sudo (limited installation):
#     curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | bash
#
# Supported Distributions:
#   - Debian/Ubuntu (apt)
#   - Fedora/RHEL/CentOS (dnf)
#   - Alpine (apk)
#   - Arch (pacman)
#
# Repository: https://github.com/joshlebed/macbook-dotfiles
# ============================================================================

set -e  # Exit on error

# ============================================================================
# LOGGING AND OUTPUT FUNCTIONS
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Global variables
HAS_SUDO=false
IS_ROOT=false
SKIPPED_OPERATIONS=()
USER_HOME=""
ACTUAL_USER=""

# ============================================================================
# SYSTEM DETECTION AND SETUP
# ============================================================================

# Check sudo availability
check_sudo_availability() {
    if [[ $EUID -eq 0 ]]; then
        IS_ROOT=true
        HAS_SUDO=true
        log_info "Running as root user"
    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        HAS_SUDO=true
        log_info "Sudo is available and configured"
    else
        HAS_SUDO=false
        log_warning "Running without sudo privileges"
        echo ""
        log_warning "The following operations will be SKIPPED:"
        echo "  • System package installation (git, zsh, tmux, fzf, etc.)"
        echo "  • Setting zsh as default shell"
        echo "  • System locale configuration"
        echo ""
        log_info "To get full functionality, either:"
        echo "  1. Re-run with sudo: curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash"
        echo "  2. Ask your system administrator to install: git, zsh, fzf, tmux, curl, wget"
        echo ""

        # Check if we're running through a pipe or non-interactive shell
        if [[ -t 0 ]] && [[ -t 1 ]]; then
            # Interactive terminal - can ask for user input
            read -p "Continue with limited installation? (y/N): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
        else
            # Non-interactive (piped from curl) - auto-continue
            log_info "Running in non-interactive mode - continuing with limited installation..."
            log_info "The script will install what it can without sudo privileges."
            echo ""
        fi
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        # ID_LIKE is already set by sourcing /etc/os-release
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi
    log_info "Detected: $OS $VER"
}

# Install packages based on distribution (REQUIRES SUDO)
install_packages() {
    if [[ "$HAS_SUDO" != true ]]; then
        SKIPPED_OPERATIONS+=("System package installation")
        log_warning "Skipping package installation (requires sudo)"
        log_info "Please ensure these packages are installed: git, curl, wget, zsh, fzf, tmux"
        return 0
    fi

    log_info "Installing required packages..."

    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            apt-get update
            apt-get install -y git curl wget zsh fzf tmux fonts-powerline build-essential locales

            # Install GitHub CLI (gh)
            log_info "Adding GitHub CLI repository..."
            (type -p wget >/dev/null || (apt-get update && apt-get install -y wget)) \
            && mkdir -p -m 755 /etc/apt/keyrings \
            && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && apt-get update \
            && apt-get install -y gh
        else
            sudo apt-get update
            sudo apt-get install -y git curl wget zsh fzf tmux fonts-powerline build-essential locales

            # Install GitHub CLI (gh)
            log_info "Adding GitHub CLI repository..."
            (type -p wget >/dev/null || (sudo apt-get update && sudo apt-get install -y wget)) \
            && sudo mkdir -p -m 755 /etc/apt/keyrings \
            && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && sudo apt-get update \
            && sudo apt-get install -y gh
        fi
        log_success "Packages installed via apt"
    elif [[ "$ID" == "fedora" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]] || [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID_LIKE" == *"rhel"* ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            dnf install -y git curl wget zsh fzf tmux powerline-fonts gcc make glibc-locale-source glibc-langpack-en
        else
            sudo dnf install -y git curl wget zsh fzf tmux powerline-fonts gcc make glibc-locale-source glibc-langpack-en
        fi
        log_success "Packages installed via dnf"
    elif [[ "$ID" == "alpine" ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            apk update
            apk add --no-cache git curl wget zsh fzf tmux build-base musl-locales
        else
            sudo apk update
            sudo apk add --no-cache git curl wget zsh fzf tmux build-base musl-locales
        fi
        log_warning "Powerline fonts may need manual installation on Alpine Linux"
        log_success "Packages installed via apk"
    elif [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == *"arch"* ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            pacman -Sy --noconfirm git curl wget zsh fzf tmux powerline-fonts base-devel
        else
            sudo pacman -Sy --noconfirm git curl wget zsh fzf tmux powerline-fonts base-devel
        fi
        log_success "Packages installed via pacman"
    else
        log_warning "Unsupported distribution: $ID"
        log_info "Please manually install: git, curl, wget, zsh, fzf, tmux, powerline-fonts"
        SKIPPED_OPERATIONS+=("Package installation for unknown distro")
    fi
}

# Setup locale (REQUIRES SUDO for some operations)
setup_locale() {
    if [[ "$HAS_SUDO" != true ]]; then
        log_warning "Skipping system locale setup (requires sudo)"
        log_info "Setting locale environment variables for current session only"
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
        SKIPPED_OPERATIONS+=("System locale configuration")
        return 0
    fi

    log_info "Setting up locale..."

    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            locale-gen en_US.UTF-8
            update-locale LANG=en_US.UTF-8
        else
            sudo locale-gen en_US.UTF-8
            sudo update-locale LANG=en_US.UTF-8
        fi
    elif [[ "$ID" == "fedora" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]] || [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID_LIKE" == *"rhel"* ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            localedef -i en_US -f UTF-8 en_US.UTF-8
        else
            sudo localedef -i en_US -f UTF-8 en_US.UTF-8
        fi
    fi
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    log_success "Locale configured"
}

# Get the actual user (not root if using sudo)
get_actual_user() {
    if [[ -n "$SUDO_USER" ]]; then
        # Running with sudo, get the original user
        ACTUAL_USER=$SUDO_USER
    elif [[ "$IS_ROOT" == true ]]; then
        # Running as root without sudo, try to find a non-root user
        if [[ -d /home ]]; then
            # Get the first non-root user (using find for better handling)
            ACTUAL_USER=$(find /home -maxdepth 1 -type d -printf "%f\n" | grep -v "^home$" | head -n 1)
        fi

        if [[ -z "$ACTUAL_USER" ]]; then
            log_warning "Running as root, could not determine target user"
            ACTUAL_USER="root"
        fi
    else
        # Running as regular user without sudo
        ACTUAL_USER=$(whoami)
    fi

    # Set the home directory
    if [[ "$ACTUAL_USER" == "root" ]]; then
        USER_HOME="/root"
    else
        USER_HOME="/home/$ACTUAL_USER"
    fi

    log_info "Setting up for user: $ACTUAL_USER (home: $USER_HOME)"
}

# ============================================================================
# REPOSITORY AND CONFIGURATION
# ============================================================================

# Clone the config repository (NO SUDO REQUIRED)
clone_config_repo() {
    log_info "Cloning configuration repository..."

    CONFIG_DIR="$USER_HOME/.config"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git is not installed. Please install git and run this script again."
        SKIPPED_OPERATIONS+=("Configuration repository clone (git not available)")
        return 1
    fi

    # Set git to non-interactive mode
    export GIT_EDITOR=true
    export GIT_MERGE_AUTOEDIT=no

    # Backup existing .config if it exists and is not a git repo
    if [[ -d "$CONFIG_DIR" ]] && [[ ! -d "$CONFIG_DIR/.git" ]]; then
        log_warning "Backing up existing .config directory..."
        mv "$CONFIG_DIR" "$CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Clone the repository if it doesn't exist
    if [[ ! -d "$CONFIG_DIR/.git" ]]; then
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c "GIT_EDITOR=true git clone https://github.com/joshlebed/macbook-dotfiles.git \"$CONFIG_DIR\"" </dev/null
        else
            git clone https://github.com/joshlebed/macbook-dotfiles.git "$CONFIG_DIR" </dev/null
        fi
        log_success "Configuration repository cloned"
    else
        log_info "Configuration repository already exists, pulling latest..."
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            # Use fetch and reset to avoid merge conflicts and editor prompts
            su - "$ACTUAL_USER" -c "cd \"$CONFIG_DIR\" && GIT_EDITOR=true git fetch origin && git reset --hard origin/\$(git symbolic-ref --short HEAD 2>/dev/null || echo main)" </dev/null 2>&1 || \
            su - "$ACTUAL_USER" -c "cd \"$CONFIG_DIR\" && GIT_EDITOR=true git fetch origin && git reset --hard origin/main" </dev/null 2>&1
        else
            # Use fetch and reset to avoid merge conflicts and editor prompts
            (cd "$CONFIG_DIR" && git fetch origin && git reset --hard origin/$(git symbolic-ref --short HEAD 2>/dev/null || echo main)) </dev/null 2>&1 || \
            (cd "$CONFIG_DIR" && git fetch origin && git reset --hard origin/main) </dev/null 2>&1
        fi
        log_success "Configuration repository updated"
    fi

    # Ensure proper ownership if running as root
    if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
        if command -v chown >/dev/null 2>&1; then
            chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
        fi
    fi
}

# Install Oh My Zsh (NO SUDO REQUIRED)
install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        log_error "Curl is not installed. Trying with wget..."
        if ! command -v wget >/dev/null 2>&1; then
            log_error "Neither curl nor wget is available. Cannot install Oh My Zsh."
            SKIPPED_OPERATIONS+=("Oh My Zsh installation (curl/wget not available)")
            return 1
        fi
    fi

    OMZ_DIR="$USER_HOME/.oh-my-zsh"

    if [[ -d "$OMZ_DIR" ]]; then
        log_info "Oh My Zsh already installed"
    else
        # Set environment variables to ensure non-interactive installation
        export RUNZSH=no
        export CHSH=no
        export KEEP_ZSHRC=yes

        # Download and run the installer as the actual user
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            if command -v curl >/dev/null 2>&1; then
                su - "$ACTUAL_USER" -c 'export RUNZSH=no CHSH=no KEEP_ZSHRC=yes; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' </dev/null
            else
                su - "$ACTUAL_USER" -c 'export RUNZSH=no CHSH=no KEEP_ZSHRC=yes; sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' </dev/null
            fi
        else
            if command -v curl >/dev/null 2>&1; then
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended </dev/null
            else
                sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended </dev/null
            fi
        fi
        log_success "Oh My Zsh installed"
    fi
}

# Create symlinks for configuration files (NO SUDO REQUIRED)
create_symlinks() {
    log_info "Creating configuration symlinks..."

    # Function to create a symlink with backup
    create_link() {
        local source="$1"
        local target="$2"
        local target_dir
        target_dir=$(dirname "$target")

        # Check if source exists
        if [[ ! -e "$source" ]]; then
            log_warning "Source file doesn't exist: $source"
            return 1
        fi

        # Create target directory if it doesn't exist
        if [[ ! -d "$target_dir" ]]; then
            if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
                su - "$ACTUAL_USER" -c "mkdir -p \"$target_dir\""
            else
                mkdir -p "$target_dir"
            fi
        fi

        # Backup existing file if it's not a symlink
        if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
            log_warning "Backing up existing $(basename "$target")..."
            if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
                su - "$ACTUAL_USER" -c "mv \"$target\" \"$target.backup.$(date +%Y%m%d_%H%M%S)\""
            else
                mv "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
            fi
        fi

        # Remove existing symlink if it exists
        if [[ -L "$target" ]]; then
            if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
                su - "$ACTUAL_USER" -c "rm \"$target\""
            else
                rm "$target"
            fi
        fi

        # Create new symlink
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c "ln -sf \"$source\" \"$target\""
        else
            ln -sf "$source" "$target"
        fi
        log_success "Linked: $(basename "$target")"
    }

    # Essential symlinks
    create_link "$USER_HOME/.config/.zshrc" "$USER_HOME/.zshrc"
    create_link "$USER_HOME/.config/.tmux.conf" "$USER_HOME/.tmux.conf"

    # Oh My Zsh theme
    create_link "$USER_HOME/.config/zsh-themes/agnoster.zsh-theme" "$USER_HOME/.oh-my-zsh/themes/agnoster.zsh-theme"

    # Shell-AI config (if directory exists or create it)
    if [[ -d "$USER_HOME/.config/shell-ai" ]]; then
        create_link "$USER_HOME/.config/shell-ai/config.yaml" "$USER_HOME/.shell-ai/config.yaml"
    fi

    # VS Code settings (for Linux path)
    if [[ -d "$USER_HOME/.config/vscode" ]]; then
        create_link "$USER_HOME/.config/vscode/settings.json" "$USER_HOME/.config/Code/User/settings.json"
        create_link "$USER_HOME/.config/vscode/keybindings.json" "$USER_HOME/.config/Code/User/keybindings.json"

        # For Cursor
        create_link "$USER_HOME/.config/vscode/settings.json" "$USER_HOME/.config/Cursor/User/settings.json"
        create_link "$USER_HOME/.config/vscode/keybindings.json" "$USER_HOME/.config/Cursor/User/keybindings.json"
    fi

    # Claude config (if exists)
    if [[ -d "$USER_HOME/.config/claude" ]]; then
        create_link "$USER_HOME/.config/claude/settings.json" "$USER_HOME/.config/claude-code/settings.json"
    fi
}

# ============================================================================
# SHELL CONFIGURATION
# ============================================================================

# Set zsh as default shell (REQUIRES SUDO)
set_default_shell() {
    if [[ "$HAS_SUDO" != true ]]; then
        log_warning "Cannot set default shell without sudo privileges"
        log_info "To set zsh as your default shell, ask your administrator to run:"
        echo "    chsh -s $(which zsh 2>/dev/null || echo /bin/zsh) $ACTUAL_USER"
        SKIPPED_OPERATIONS+=("Setting zsh as default shell")
        return 0
    fi

    log_info "Setting zsh as default shell for $ACTUAL_USER..."

    # Check if zsh is available
    if ! command -v zsh >/dev/null 2>&1; then
        log_error "Zsh is not installed. Cannot set as default shell."
        SKIPPED_OPERATIONS+=("Setting zsh as default shell (zsh not installed)")
        return 1
    fi

    # Check if zsh is in /etc/shells
    if ! grep -q "/bin/zsh\|/usr/bin/zsh" /etc/shells; then
        if [[ "$IS_ROOT" == true ]]; then
            echo "/bin/zsh" >> /etc/shells
            echo "/usr/bin/zsh" >> /etc/shells
        else
            sudo sh -c 'echo "/bin/zsh" >> /etc/shells'
            sudo sh -c 'echo "/usr/bin/zsh" >> /etc/shells'
        fi
    fi

    # Change default shell
    if command -v chsh >/dev/null 2>&1; then
        local zsh_path
        zsh_path=$(which zsh)
        if [[ "$IS_ROOT" == true ]]; then
            chsh -s "$zsh_path" "$ACTUAL_USER"
        else
            sudo chsh -s "$zsh_path" "$ACTUAL_USER"
        fi
        log_success "Default shell set to zsh"
    else
        log_warning "chsh not available, please manually set default shell to zsh"
        SKIPPED_OPERATIONS+=("Setting zsh as default shell (chsh not available)")
    fi
}

# ============================================================================
# DEVELOPMENT TOOLS INSTALLATION
# ============================================================================

# Helper function to install shell-ai binary
install_shell_ai_for_user() {
    local TARGET_DIR="$1/.local/bin"
    local REPO_OWNER="ibigio"
    local REPO_NAME="shell-ai"
    local TOOL_NAME="shell-ai"
    local TOOL_SYMLINK="q"

    # Create target directory
    mkdir -p "$TARGET_DIR" || return 1

    # Detect architecture and OS
    local ARCH OS
    ARCH="$(uname -m)"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

    case "$ARCH" in
        x86_64|amd64) ARCH="x86_64";;
        aarch64|arm64) ARCH="aarch64";;
        *)
            log_warning "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac

    # Get latest release tag
    local LATEST_TAG
    LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" 2>/dev/null | \
                 sed -nE 's/.*"tag_name": *"([^"]+)".*/\1/p')

    if [[ -z "$LATEST_TAG" ]]; then
        log_warning "Failed to get latest shell-ai release tag"
        return 1
    fi

    # Build download URL
    local URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$LATEST_TAG/${TOOL_NAME}_${OS}_${ARCH}.tar.gz"
    log_info "Downloading shell-ai from $URL"

    # Create temp directory for download
    local tmp
    tmp=$(mktemp -d) || return 1
    trap 'rm -rf "$tmp"' RETURN

    # Download and extract
    if ! curl -fsSL "$URL" -o "$tmp/$TOOL_NAME.tgz" 2>/dev/null; then
        log_warning "Failed to download shell-ai"
        return 1
    fi

    if ! tar xzf "$tmp/$TOOL_NAME.tgz" -C "$tmp" 2>/dev/null; then
        log_warning "Failed to extract shell-ai"
        return 1
    fi

    # Install binary
    if command -v install >/dev/null 2>&1; then
        install -m 0755 "$tmp/$TOOL_NAME" "$TARGET_DIR/$TOOL_SYMLINK" || return 1
    else
        cp "$tmp/$TOOL_NAME" "$TARGET_DIR/$TOOL_SYMLINK" || return 1
        chmod 0755 "$TARGET_DIR/$TOOL_SYMLINK" || return 1
    fi

    log_success "shell-ai $LATEST_TAG installed to $TARGET_DIR/$TOOL_SYMLINK"
    return 0
}

# Install shell-ai (q command) binary
install_shell_ai() {
    log_info "Installing shell-ai (q command)..."

    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        log_warning "Cannot install shell-ai (curl not available)"
        SKIPPED_OPERATIONS+=("shell-ai installation (curl not available)")
        return 0
    fi

    # Check if already installed
    if command -v q >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/q" ]]; then
        log_info "shell-ai (q) is already installed"
        return 0
    fi

    # Install based on user context
    if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
        # Running as root for a different user
        if su - "$ACTUAL_USER" -c "$(declare -f log_info log_success log_warning); $(declare -f install_shell_ai_for_user); install_shell_ai_for_user \"$USER_HOME\"" </dev/null 2>&1; then
            log_info "Make sure ~/.local/bin is in your PATH to use 'q' command"
        else
            log_warning "Failed to install shell-ai"
            SKIPPED_OPERATIONS+=("shell-ai installation")
        fi
    else
        # Running as regular user
        if install_shell_ai_for_user "$USER_HOME"; then
            log_info "Make sure ~/.local/bin is in your PATH to use 'q' command"
        else
            log_warning "Failed to install shell-ai"
            SKIPPED_OPERATIONS+=("shell-ai installation")
        fi
    fi
}

# Install Node Version Manager
install_nvm() {
    log_info "Installing NVM..."

    # Check if already installed
    if [[ -d "$USER_HOME/.nvm" ]]; then
        log_info "NVM already installed"
        return 0
    fi

    # Check for curl or wget
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        log_warning "Cannot install NVM (curl/wget not available)"
        SKIPPED_OPERATIONS+=("NVM installation")
        return 1
    fi

    # Set PROFILE to prevent interactive prompt
    export PROFILE=/dev/null
    local NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh"

    # Run installation based on context
    local install_success=false

    if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
        if command -v curl >/dev/null 2>&1; then
            su - "$ACTUAL_USER" -c "export PROFILE=/dev/null; curl -o- $NVM_INSTALL_URL | bash" </dev/null && install_success=true
        else
            su - "$ACTUAL_USER" -c "export PROFILE=/dev/null; wget -qO- $NVM_INSTALL_URL | bash" </dev/null && install_success=true
        fi
    else
        if command -v curl >/dev/null 2>&1; then
            curl -o- "$NVM_INSTALL_URL" 2>/dev/null | bash && install_success=true
        else
            wget -qO- "$NVM_INSTALL_URL" 2>/dev/null | bash && install_success=true
        fi
    fi

    if [[ "$install_success" == true ]]; then
        log_success "NVM installed"
        return 0
    else
        log_warning "Failed to install NVM"
        SKIPPED_OPERATIONS+=("NVM installation")
        return 1
    fi
}

# Setup Node.js via NVM
setup_nodejs_via_nvm() {
    if [[ ! -f "$USER_HOME/.nvm/nvm.sh" ]]; then
        return 1
    fi

    log_info "Setting up Node.js via NVM..."

    if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
        if su - "$ACTUAL_USER" -c "source \"$USER_HOME/.nvm/nvm.sh\" && (nvm current || nvm install --lts) && nvm use --lts && npm --version" </dev/null 2>&1; then
            log_success "Node.js is ready via NVM"
            return 0
        fi
    else
        # shellcheck source=/dev/null
        if (source "$USER_HOME/.nvm/nvm.sh" && (nvm current || nvm install --lts) && nvm use --lts && npm --version) </dev/null 2>&1; then
            log_success "Node.js is ready via NVM"
            # shellcheck source=/dev/null
            source "$USER_HOME/.nvm/nvm.sh" 2>/dev/null && nvm use --lts 2>/dev/null || true
            return 0
        fi
    fi

    log_warning "Failed to setup Node.js via NVM"
    return 1
}

# Install Claude Code CLI
install_claude_code() {
    log_info "Installing Claude Code..."

    # Check if already installed
    if command -v claude-code >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/claude-code" ]] || [[ -f "$USER_HOME/.claude/bin/claude" ]]; then
        log_info "Claude Code is already installed"
        return 0
    fi

    # Try to setup Node.js via NVM first
    setup_nodejs_via_nvm

    # Method 1: Install via npm if available
    if command -v npm >/dev/null 2>&1; then
        log_info "Installing Claude Code via npm..."

        if [[ "$HAS_SUDO" == true ]]; then
            # With sudo: install globally
            if [[ "$IS_ROOT" == true ]]; then
                if npm install -g @anthropic-ai/claude-code </dev/null 2>&1; then
                    log_success "Claude Code installed globally via npm"
                    return 0
                fi
            else
                if sudo npm install -g @anthropic-ai/claude-code </dev/null 2>&1; then
                    log_success "Claude Code installed globally via npm"
                    return 0
                fi
            fi
        else
            # Without sudo: install to user directory
            log_info "Installing Claude Code to user directory..."

            if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
                if su - "$ACTUAL_USER" -c "npm config set prefix \"$USER_HOME/.local\" && npm install -g @anthropic-ai/claude-code" </dev/null 2>&1; then
                    log_success "Claude Code installed to ~/.local via npm"
                    log_info "Make sure ~/.local/bin is in your PATH"
                    return 0
                fi
            else
                npm config set prefix "$USER_HOME/.local" </dev/null 2>&1
                if npm install -g @anthropic-ai/claude-code </dev/null 2>&1; then
                    log_success "Claude Code installed to ~/.local via npm"
                    log_info "Make sure ~/.local/bin is in your PATH"
                    return 0
                fi
            fi
        fi

        log_warning "Failed to install Claude Code via npm"
        SKIPPED_OPERATIONS+=("Claude Code installation (npm error)")
    fi

    # Method 2: Use install script if curl is available
    if command -v curl >/dev/null 2>&1; then
        log_info "Installing Claude Code via install script..."

        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            if su - "$ACTUAL_USER" -c 'curl -fsSL https://claude.ai/install.sh | bash' </dev/null 2>&1; then
                log_success "Claude Code installed via install script"
                return 0
            fi
        else
            if curl -fsSL https://claude.ai/install.sh | bash </dev/null 2>&1; then
                log_success "Claude Code installed via install script"
                return 0
            fi
        fi

        log_warning "Failed to install Claude Code via install script"
        SKIPPED_OPERATIONS+=("Claude Code installation (install script error)")
        return 1
    fi

    log_warning "Cannot install Claude Code (no npm or curl available)"
    SKIPPED_OPERATIONS+=("Claude Code installation (missing dependencies)")
    return 1
}

# Helper function to install GitHub CLI binary
install_gh_for_user() {
    local TARGET_DIR="$1/.local/bin"
    local TOOL_NAME="gh"

    # Create target directory
    mkdir -p "$TARGET_DIR" || return 1

    # Detect architecture and OS
    local ARCH OS
    ARCH="$(uname -m)"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

    case "$ARCH" in
        x86_64|amd64) ARCH="amd64";;
        aarch64|arm64) ARCH="arm64";;
        armv7l|armv7) ARCH="armv6";;
        *)
            log_warning "Unsupported architecture for gh: $ARCH"
            return 1
            ;;
    esac

    # Get latest release version
    local LATEST_VERSION
    LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/cli/cli/releases/latest" 2>/dev/null | \
                     sed -nE 's/.*"tag_name": *"v([^"]+)".*/\1/p')

    if [[ -z "$LATEST_VERSION" ]]; then
        log_warning "Failed to get latest gh release version"
        return 1
    fi

    # Build download URL
    local URL="https://github.com/cli/cli/releases/download/v${LATEST_VERSION}/gh_${LATEST_VERSION}_${OS}_${ARCH}.tar.gz"
    log_info "Downloading GitHub CLI from $URL"

    # Create temp directory for download
    local tmp
    tmp=$(mktemp -d) || return 1
    trap 'rm -rf "$tmp"' RETURN

    # Download and extract
    if ! curl -fsSL "$URL" -o "$tmp/$TOOL_NAME.tgz" 2>/dev/null; then
        log_warning "Failed to download GitHub CLI"
        return 1
    fi

    if ! tar xzf "$tmp/$TOOL_NAME.tgz" -C "$tmp" 2>/dev/null; then
        log_warning "Failed to extract GitHub CLI"
        return 1
    fi

    # Install binary
    local extracted_dir="gh_${LATEST_VERSION}_${OS}_${ARCH}"
    if command -v install >/dev/null 2>&1; then
        install -m 0755 "$tmp/$extracted_dir/bin/gh" "$TARGET_DIR/gh" || return 1
    else
        cp "$tmp/$extracted_dir/bin/gh" "$TARGET_DIR/gh" || return 1
        chmod 0755 "$TARGET_DIR/gh" || return 1
    fi

    log_success "GitHub CLI $LATEST_VERSION installed to $TARGET_DIR/gh"
    return 0
}

# Install GitHub CLI (gh)
install_github_cli() {
    log_info "Installing GitHub CLI (gh)..."

    # Check if already installed
    if command -v gh >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/gh" ]]; then
        log_info "GitHub CLI is already installed"
        return 0
    fi

    # If we have sudo and are on a system with package manager support, it should be installed already
    # via the install_packages function. This function is mainly for the fallback case.

    # Check if curl is available for fallback installation
    if ! command -v curl >/dev/null 2>&1; then
        log_warning "Cannot install GitHub CLI (curl not available)"
        SKIPPED_OPERATIONS+=("GitHub CLI installation (curl not available)")
        return 0
    fi

    # Install based on user context
    if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
        # Running as root for a different user
        if su - "$ACTUAL_USER" -c "$(declare -f log_info log_success log_warning); $(declare -f install_gh_for_user); install_gh_for_user \"$USER_HOME\"" </dev/null 2>&1; then
            log_info "Make sure ~/.local/bin is in your PATH to use 'gh' command"
        else
            log_warning "Failed to install GitHub CLI"
            SKIPPED_OPERATIONS+=("GitHub CLI installation")
        fi
    else
        # Running as regular user
        if install_gh_for_user "$USER_HOME"; then
            log_info "Make sure ~/.local/bin is in your PATH to use 'gh' command"
        else
            log_warning "Failed to install GitHub CLI"
            SKIPPED_OPERATIONS+=("GitHub CLI installation")
        fi
    fi
}

# Install Graphite CLI
install_graphite_cli() {
    log_info "Installing Graphite CLI..."

    # Check if already installed
    if command -v gt >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/gt" ]]; then
        log_info "Graphite CLI is already installed"
        return 0
    fi

    # Try to setup Node.js via NVM first if not already available
    if ! command -v npm >/dev/null 2>&1; then
        setup_nodejs_via_nvm
    fi

    # Check if npm is available
    if ! command -v npm >/dev/null 2>&1; then
        log_warning "Cannot install Graphite CLI (npm not available)"
        SKIPPED_OPERATIONS+=("Graphite CLI installation (npm not available)")
        return 1
    fi

    log_info "Installing Graphite CLI to user directory..."

    # Install to user directory using npm with prefix
    if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
        if su - "$ACTUAL_USER" -c "npm install -g @withgraphite/graphite-cli@stable --prefix \"$USER_HOME/.local\"" </dev/null 2>&1; then
            log_success "Graphite CLI installed to ~/.local"
            log_info "Make sure ~/.local/bin is in your PATH to use 'gt' command"
            return 0
        fi
    else
        if npm install -g @withgraphite/graphite-cli@stable --prefix "$USER_HOME/.local" </dev/null 2>&1; then
            log_success "Graphite CLI installed to ~/.local"
            log_info "Make sure ~/.local/bin is in your PATH to use 'gt' command"
            return 0
        fi
    fi

    log_warning "Failed to install Graphite CLI"
    SKIPPED_OPERATIONS+=("Graphite CLI installation")
    return 1
}

# Install additional development tools (NO SUDO REQUIRED for user installs)
install_dev_tools() {
    log_info "Installing additional development tools..."

    # Install NVM
    install_nvm

    # Install Claude Code
    install_claude_code

    # Install shell-ai
    install_shell_ai

    # Install GitHub CLI
    install_github_cli

    # Install Graphite CLI
    install_graphite_cli
}

# ============================================================================
# FINAL SETUP AND SUMMARY
# ============================================================================

# Final setup and instructions
final_setup() {
    log_section "SETUP SUMMARY"

    # Try to source the new configuration if zsh is available (non-interactive)
    if command -v zsh >/dev/null 2>&1 && [[ -f "$USER_HOME/.zshrc" ]]; then
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c "source \"$USER_HOME/.zshrc\" </dev/null" 2>/dev/null || true
        else
            # shellcheck source=/dev/null
            source "$USER_HOME/.zshrc" </dev/null 2>/dev/null || true
        fi
    fi

    # Print success message
    echo ""
    if [[ ${#SKIPPED_OPERATIONS[@]} -eq 0 ]]; then
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_success "  Linux Dev Setup COMPLETED Successfully!"
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_warning "  Linux Dev Setup PARTIALLY Complete (Limited Mode)"
        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
    echo ""

    log_info "Configuration Details:"
    echo "  • User: $ACTUAL_USER"
    echo "  • Home: $USER_HOME"
    echo "  • Config: $USER_HOME/.config"

    if command -v zsh >/dev/null 2>&1; then
        echo "  • Zsh: $(which zsh)"
    else
        echo "  • Zsh: NOT INSTALLED"
    fi
    echo ""

    # Show skipped operations if any
    if [[ ${#SKIPPED_OPERATIONS[@]} -gt 0 ]]; then
        log_warning "Operations SKIPPED (no sudo):"
        for op in "${SKIPPED_OPERATIONS[@]}"; do
            echo "  ⚠ $op"
        done
        echo ""

        log_info "To complete full setup, either:"
        echo "  1. Re-run with sudo: curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash"
        echo "  2. Ask your administrator to install missing packages"
        echo ""
    fi

    log_info "Next Steps:"
    if command -v zsh >/dev/null 2>&1; then
        echo "  ✓ Start a new zsh session: exec zsh"
        echo "  ✓ Your Oh My Zsh configuration is ready"
    else
        echo "  ⚠ Install zsh and run: exec zsh"
    fi

    if command -v fzf >/dev/null 2>&1; then
        echo "  ✓ FZF key bindings ready (CTRL-R for history, CTRL-T for files)"
    else
        echo "  ⚠ Install fzf for fuzzy search capabilities"
    fi

    if command -v claude-code >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/claude-code" ]] || [[ -f "$USER_HOME/.claude/bin/claude" ]]; then
        echo "  ✓ Claude Code CLI is ready to use"
    else
        echo "  ⚠ Claude Code installation may require PATH update or re-login"
    fi

    if command -v q >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/q" ]]; then
        echo "  ✓ shell-ai (q command) is ready for AI-powered shell assistance"
    else
        echo "  ⚠ shell-ai may require adding ~/.local/bin to PATH"
    fi

    if command -v gh >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/gh" ]]; then
        echo "  ✓ GitHub CLI (gh command) is ready for GitHub operations"
    else
        echo "  ⚠ GitHub CLI may require adding ~/.local/bin to PATH"
    fi

    if command -v gt >/dev/null 2>&1 || [[ -f "$USER_HOME/.local/bin/gt" ]]; then
        echo "  ✓ Graphite CLI (gt command) is ready for stacked pull requests"
    else
        echo "  ⚠ Graphite CLI may require adding ~/.local/bin to PATH"
    fi

    echo "  ✓ Custom aliases available (type 'alias' to see them)"
    echo ""

    if [[ "$ACTUAL_USER" == "root" ]]; then
        log_warning "Setup was done for root user. Consider creating a non-root user for development."
        echo ""
    fi

    log_info "Repository: https://github.com/joshlebed/macbook-dotfiles"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Main execution
main() {
    log_section "Linux Development Environment Setup"
    log_info "This script sets up a complete development environment with dotfiles"
    echo ""

    # Step 1: Check sudo availability FIRST
    check_sudo_availability

    # Step 2: Detect the distribution
    detect_distro

    # Step 3: Determine the target user
    get_actual_user

    # Step 4: Operations that require sudo (only if available)
    if [[ "$HAS_SUDO" == true ]]; then
        log_section "System Configuration (Requires Sudo)"
        install_packages
        setup_locale
    else
        log_section "Skipping System Configuration (No Sudo)"
    fi

    # Step 5: User-level operations (no sudo required)
    log_section "User Configuration"

    # Clone config repository
    clone_config_repo || {
        log_error "Failed to clone configuration repository. Cannot continue."
        exit 1
    }

    # Install Oh My Zsh
    install_oh_my_zsh || log_warning "Oh My Zsh installation failed, continuing..."

    # Create symlinks
    create_symlinks || log_warning "Some symlinks could not be created, continuing..."

    # Install development tools
    install_dev_tools || log_warning "Some dev tools could not be installed, continuing..."

    # Step 6: Operations that require sudo (only if available)
    if [[ "$HAS_SUDO" == true ]]; then
        set_default_shell
    fi

    # Step 7: Final summary
    final_setup
}

# Trap to ensure we show errors even if script fails
trap 'log_error "Script failed! Check the errors above."' ERR

# Run main function
main "$@"