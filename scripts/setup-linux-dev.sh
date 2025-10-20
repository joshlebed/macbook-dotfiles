#!/bin/bash

# Setup script for Linux development containers
# This script installs zsh, oh-my-zsh, fzf and configures dotfiles
# Run with: curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if running as root (for package installations)
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        exit 1
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

# Install packages based on distribution
install_packages() {
    log_info "Installing required packages..."

    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
        apt-get update
        apt-get install -y \
            git \
            curl \
            wget \
            zsh \
            fzf \
            fonts-powerline \
            build-essential \
            locales
        log_success "Packages installed via apt"
    elif [[ "$ID" == "fedora" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]] || [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID_LIKE" == *"rhel"* ]]; then
        dnf install -y \
            git \
            curl \
            wget \
            zsh \
            fzf \
            powerline-fonts \
            gcc \
            make \
            glibc-locale-source \
            glibc-langpack-en
        log_success "Packages installed via dnf"
    elif [[ "$ID" == "alpine" ]]; then
        apk update
        apk add --no-cache \
            git \
            curl \
            wget \
            zsh \
            fzf \
            build-base \
            musl-locales
        # Note: Powerline fonts may need manual installation on Alpine
        log_warning "Powerline fonts may need manual installation on Alpine Linux"
        log_success "Packages installed via apk"
    elif [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == *"arch"* ]]; then
        pacman -Sy --noconfirm \
            git \
            curl \
            wget \
            zsh \
            fzf \
            powerline-fonts \
            base-devel
        log_success "Packages installed via pacman"
    else
        log_error "Unsupported distribution: $ID"
        log_info "Please manually install: git, curl, wget, zsh, fzf, powerline-fonts"
        exit 1
    fi
}

# Setup locale (needed for some containers)
setup_locale() {
    log_info "Setting up locale..."
    if [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8
    elif [[ "$ID" == "fedora" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]] || [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID_LIKE" == *"rhel"* ]]; then
        localedef -i en_US -f UTF-8 en_US.UTF-8
    fi
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
}

# Get the actual user (not root if using sudo)
get_actual_user() {
    if [[ -n "$SUDO_USER" ]]; then
        ACTUAL_USER=$SUDO_USER
    else
        # If no SUDO_USER, try to find the user who owns the home directory
        if [[ -d /home ]]; then
            # Get the first non-root user
            ACTUAL_USER=$(ls /home | head -n 1)
        fi
    fi

    if [[ -z "$ACTUAL_USER" ]] || [[ "$ACTUAL_USER" == "root" ]]; then
        log_warning "Could not determine non-root user, using root"
        ACTUAL_USER="root"
        USER_HOME="/root"
    else
        USER_HOME="/home/$ACTUAL_USER"
    fi

    log_info "Setting up for user: $ACTUAL_USER (home: $USER_HOME)"
}

# Clone the config repository
clone_config_repo() {
    log_info "Cloning configuration repository..."

    CONFIG_DIR="$USER_HOME/.config"

    # Backup existing .config if it exists and is not a git repo
    if [[ -d "$CONFIG_DIR" ]] && [[ ! -d "$CONFIG_DIR/.git" ]]; then
        log_warning "Backing up existing .config directory..."
        mv "$CONFIG_DIR" "$CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Clone the repository if it doesn't exist
    if [[ ! -d "$CONFIG_DIR/.git" ]]; then
        su - "$ACTUAL_USER" -c "git clone https://github.com/joshlebed/macbook-dotfiles.git $CONFIG_DIR"
        log_success "Configuration repository cloned"
    else
        log_info "Configuration repository already exists, pulling latest..."
        su - "$ACTUAL_USER" -c "cd $CONFIG_DIR && git pull"
    fi

    # Ensure proper ownership
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    OMZ_DIR="$USER_HOME/.oh-my-zsh"

    if [[ -d "$OMZ_DIR" ]]; then
        log_info "Oh My Zsh already installed"
    else
        # Download and run the installer as the actual user
        su - "$ACTUAL_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
        log_success "Oh My Zsh installed"
    fi
}

# Create symlinks for configuration files
create_symlinks() {
    log_info "Creating configuration symlinks..."

    # Function to create a symlink with backup
    create_link() {
        local source="$1"
        local target="$2"
        local target_dir=$(dirname "$target")

        # Create target directory if it doesn't exist
        if [[ ! -d "$target_dir" ]]; then
            su - "$ACTUAL_USER" -c "mkdir -p $target_dir"
        fi

        # Backup existing file if it's not a symlink
        if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
            log_warning "Backing up existing $(basename $target)..."
            su - "$ACTUAL_USER" -c "mv $target $target.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        # Remove existing symlink if it exists
        if [[ -L "$target" ]]; then
            su - "$ACTUAL_USER" -c "rm $target"
        fi

        # Create new symlink
        su - "$ACTUAL_USER" -c "ln -sf $source $target"
        log_success "Linked: $(basename $target)"
    }

    # Essential symlinks
    create_link "$USER_HOME/.config/.zshrc" "$USER_HOME/.zshrc"

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

        # Also link for VS Code Insiders and Cursor if they might be used
        create_link "$USER_HOME/.config/vscode/settings.json" "$USER_HOME/.config/Code - Insiders/User/settings.json"
        create_link "$USER_HOME/.config/vscode/keybindings.json" "$USER_HOME/.config/Code - Insiders/User/keybindings.json"

        # For Cursor
        create_link "$USER_HOME/.config/vscode/settings.json" "$USER_HOME/.config/Cursor/User/settings.json"
        create_link "$USER_HOME/.config/vscode/keybindings.json" "$USER_HOME/.config/Cursor/User/keybindings.json"
    fi

    # Claude config (if exists)
    if [[ -d "$USER_HOME/.config/claude" ]]; then
        create_link "$USER_HOME/.config/claude/settings.json" "$USER_HOME/.config/claude-code/settings.json"
    fi
}

# Set zsh as default shell
set_default_shell() {
    log_info "Setting zsh as default shell for $ACTUAL_USER..."

    # Check if zsh is in /etc/shells
    if ! grep -q "/bin/zsh\|/usr/bin/zsh" /etc/shells; then
        echo "/bin/zsh" >> /etc/shells
        echo "/usr/bin/zsh" >> /etc/shells
    fi

    # Change default shell
    if command -v chsh >/dev/null 2>&1; then
        chsh -s $(which zsh) "$ACTUAL_USER"
        log_success "Default shell set to zsh"
    else
        log_warning "chsh not available, please manually set default shell to zsh"
    fi
}

# Install additional development tools (optional)
install_dev_tools() {
    log_info "Installing additional development tools..."

    # Install Node Version Manager (nvm)
    if [[ ! -d "$USER_HOME/.nvm" ]]; then
        log_info "Installing NVM..."
        su - "$ACTUAL_USER" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
        log_success "NVM installed"
    fi

    # Install shell-ai if pip is available
    if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
        log_info "Installing shell-ai..."
        pip3 install shell-ai || pip install shell-ai || log_warning "Could not install shell-ai"
    fi
}

# Final setup and instructions
final_setup() {
    log_info "Running final setup..."

    # Source the new configuration
    su - "$ACTUAL_USER" -c "source $USER_HOME/.zshrc" || true

    # Print success message
    echo ""
    log_success "==================================="
    log_success "Linux Dev Container Setup Complete!"
    log_success "==================================="
    echo ""
    log_info "Configuration Details:"
    echo "  • User: $ACTUAL_USER"
    echo "  • Home: $USER_HOME"
    echo "  • Shell: $(which zsh)"
    echo "  • Config: $USER_HOME/.config"
    echo ""
    log_info "Next Steps:"
    echo "  1. Exit and re-enter the container (or run: exec zsh)"
    echo "  2. Your zsh configuration with Oh My Zsh is ready"
    echo "  3. FZF key bindings are configured (CTRL-R for history, CTRL-T for files)"
    echo "  4. Custom aliases are available (type 'alias' to see them)"
    echo ""

    if [[ "$ACTUAL_USER" == "root" ]]; then
        log_warning "Setup was done for root user. Consider creating a non-root user for development."
    fi

    log_info "Repository: https://github.com/joshlebed/macbook-dotfiles"
    echo ""
}

# Main execution
main() {
    log_info "Starting Linux Dev Container Setup..."

    check_root
    detect_distro
    install_packages
    setup_locale
    get_actual_user
    clone_config_repo
    install_oh_my_zsh
    create_symlinks
    set_default_shell
    install_dev_tools
    final_setup
}

# Run main function
main "$@"