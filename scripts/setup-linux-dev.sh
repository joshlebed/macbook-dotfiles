#!/bin/bash

# Setup script for Linux development containers
# This script installs zsh, oh-my-zsh, fzf and configures dotfiles
# Run with:
#   With sudo:    curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash
#   Without sudo: curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | bash

set -e  # Exit on error

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

# Global variables for sudo availability
HAS_SUDO=false
IS_ROOT=false
SKIPPED_OPERATIONS=()

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
        read -p "Continue with limited installation? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        ID_LIKE=$ID_LIKE
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

    local INSTALL_CMD=""

    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
        if [[ "$IS_ROOT" == true ]]; then
            apt-get update
            apt-get install -y git curl wget zsh fzf tmux fonts-powerline build-essential locales
        else
            sudo apt-get update
            sudo apt-get install -y git curl wget zsh fzf tmux fonts-powerline build-essential locales
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

    # Backup existing .config if it exists and is not a git repo
    if [[ -d "$CONFIG_DIR" ]] && [[ ! -d "$CONFIG_DIR/.git" ]]; then
        log_warning "Backing up existing .config directory..."
        mv "$CONFIG_DIR" "$CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Clone the repository if it doesn't exist
    if [[ ! -d "$CONFIG_DIR/.git" ]]; then
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c "git clone https://github.com/joshlebed/macbook-dotfiles.git \"$CONFIG_DIR\""
        else
            git clone https://github.com/joshlebed/macbook-dotfiles.git "$CONFIG_DIR"
        fi
        log_success "Configuration repository cloned"
    else
        log_info "Configuration repository already exists, pulling latest..."
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c "cd \"$CONFIG_DIR\" && git pull"
        else
            (cd "$CONFIG_DIR" && git pull)
        fi
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
        # Download and run the installer as the actual user
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            if command -v curl >/dev/null 2>&1; then
                su - "$ACTUAL_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
            else
                su - "$ACTUAL_USER" -c 'sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
            fi
        else
            if command -v curl >/dev/null 2>&1; then
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            else
                sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
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

# Install additional development tools (NO SUDO REQUIRED for user installs)
install_dev_tools() {
    log_info "Installing additional development tools..."

    # Install Node Version Manager (nvm)
    if [[ ! -d "$USER_HOME/.nvm" ]]; then
        if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
            log_info "Installing NVM..."
            if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
                if command -v curl >/dev/null 2>&1; then
                    su - "$ACTUAL_USER" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
                else
                    su - "$ACTUAL_USER" -c 'wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
                fi
            else
                if command -v curl >/dev/null 2>&1; then
                    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                else
                    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                fi
            fi
            log_success "NVM installed"
        else
            log_warning "Cannot install NVM (curl/wget not available)"
            SKIPPED_OPERATIONS+=("NVM installation")
        fi
    else
        log_info "NVM already installed"
    fi

    # Install shell-ai if pip is available (user install)
    if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
        log_info "Installing shell-ai..."
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c 'pip3 install --user shell-ai 2>/dev/null || pip install --user shell-ai 2>/dev/null' || {
                log_warning "Could not install shell-ai"
                SKIPPED_OPERATIONS+=("shell-ai installation")
            }
        else
            pip3 install --user shell-ai 2>/dev/null || pip install --user shell-ai 2>/dev/null || {
                log_warning "Could not install shell-ai"
                SKIPPED_OPERATIONS+=("shell-ai installation")
            }
        fi
    else
        log_info "Pip not available, skipping shell-ai installation"
        SKIPPED_OPERATIONS+=("shell-ai installation (pip not available)")
    fi
}

# Final setup and instructions
final_setup() {
    log_section "SETUP SUMMARY"

    # Try to source the new configuration if zsh is available
    if command -v zsh >/dev/null 2>&1 && [[ -f "$USER_HOME/.zshrc" ]]; then
        if [[ "$IS_ROOT" == true ]] && [[ "$ACTUAL_USER" != "root" ]]; then
            su - "$ACTUAL_USER" -c "source \"$USER_HOME/.zshrc\"" 2>/dev/null || true
        else
            source "$USER_HOME/.zshrc" 2>/dev/null || true
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

    echo "  ✓ Custom aliases available (type 'alias' to see them)"
    echo ""

    if [[ "$ACTUAL_USER" == "root" ]]; then
        log_warning "Setup was done for root user. Consider creating a non-root user for development."
        echo ""
    fi

    log_info "Repository: https://github.com/joshlebed/macbook-dotfiles"
    echo ""
}

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