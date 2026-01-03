# dotfiles

My `~/.config` directory for macOS and Linux.

## macOS Setup

```bash
git clone https://github.com/joshlebed/macbook-dotfiles ~/.config
~/.config/scripts/setup-macos.sh
```

That's it! The script handles everything:

- Xcode CLI tools
- Homebrew + all packages
- Zsh + Oh My Zsh
- All config file symlinks/hardlinks

**Options:**

```bash
./scripts/setup-macos.sh --dry-run   # Preview changes
./scripts/setup-macos.sh --skip-brew # Skip Homebrew
./scripts/verify-setup.sh            # Check setup status
```

### Manual App Configuration

Some apps need manual setup after running the script:

| App              | Setup                                                |
| ---------------- | ---------------------------------------------------- |
| Keyboard Maestro | File → Start Syncing Macros → `km_macros.kmsync`     |
| iTerm2           | Preferences → General → Load from `~/.config/iterm2` |
| Slate            | [Download DMG](https://github.com/jigish/slate)      |
| Google Drive     | Sign in                                              |

### Adding New Config Files

Edit `config/file-mappings.yaml`:

```yaml
symlinks:
  - source: myapp/config.json
    target: ~/.myapp/config.json

  - source: .myrc
    target: ~/.myrc
    os: macos
    reason: Only needed on macOS
```

Then run `./scripts/link-files.sh`.

### Syncing Preferences Between Machines

Some macOS apps (Contexts, Rectangle, Raycast, Bartender) store settings in
plist files that get copied (not symlinked) because the apps overwrite them.

**To sync settings from this machine to the repo:**

```bash
./scripts/export-preferences.sh   # Copies system plists to repo
git add -A && git commit -m "Update preferences" && git push
```

**On another machine:**

```bash
git pull
./scripts/link-files.sh           # Copies repo plists to system
# Restart the apps or log out/in
```

## Linux Setup

```bash
curl -fsSL https://raw.githubusercontent.com/joshlebed/macbook-dotfiles/main/scripts/setup-linux-dev.sh | sudo bash
```

Works on Debian/Ubuntu, Fedora/RHEL, Alpine, and Arch. Run without `sudo` for
limited install (skips system packages).

## Repository Structure

```
~/.config/
├── config/
│   └── file-mappings.yaml   # All symlink/hardlink/copy definitions
├── scripts/
│   ├── setup-macos.sh        # macOS setup (run this)
│   ├── setup-linux-dev.sh    # Linux setup
│   ├── link-files.sh         # Apply file mappings
│   ├── verify-setup.sh       # Check setup status
│   ├── export-preferences.sh # Export app prefs to repo
│   ├── brew_install_all.sh   # Homebrew packages
│   └── install_zsh_and_omz.sh
├── vscode/                  # VS Code / Cursor settings
├── karabiner/               # Keyboard remapping
├── claude/                  # Claude Code settings
├── iterm2/                  # iTerm preferences
└── ...
```

## Tools

### Shell

- [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) +
  [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)
- [tmux](https://github.com/tmux/tmux) - terminal multiplexer
- [fzf](https://github.com/junegunn/fzf) - fuzzy finder

### macOS Apps

- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) - keyboard
  remapping
- [Keyboard Maestro](https://www.keyboardmaestro.com/) - automation
- [Raycast](https://www.raycast.com/) - launcher (Spotlight replacement)
- [Rectangle](https://rectangleapp.com/) - window management
- [Contexts](https://contexts.co/) - window switcher (alt-tab replacement)
- [iTerm2](https://iterm2.com/) - terminal
- [Bartender](https://www.macbartender.com/) - menu bar management
- [Finicky](https://github.com/johnste/finicky) - browser routing

### Editors

- [VS Code](https://code.visualstudio.com/)
- [Cursor](https://www.cursor.com/) - VS Code with AI

### Chrome Extensions

- [uBlock Origin](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm)
- [Dark Reader](https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh)
- [Bitwarden](https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb)

## Git Multi-Account Setup

Seamlessly use both work and personal GitHub accounts with automatic SSH key and
email selection based on repo owner.

See [docs/git-multi-account-setup.md](docs/git-multi-account-setup.md) for full
setup instructions.
