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
./scripts/setup-macos.sh --skip-apps # Install CLI tools, skip GUI apps
./scripts/verify-setup.sh            # Check setup status
./scripts/audit-brew.sh              # Compare installed Homebrew packages to Brewfile
```

### Manual App Configuration

Some apps need manual setup after running the script:

| App              | Setup                                                        |
| ---------------- | ------------------------------------------------------------ |
| Keyboard Maestro | File → Start Syncing Macros → `km_macros.kmsync`             |
| iTerm2           | Preferences → General → Load from `~/.config/iterm2`         |
| Hammerspoon      | Grant Accessibility permission; enable "Launch at login"     |
| Thaw             | Grant Accessibility/Screen Recording; enable launch at login |
| Google Drive     | Sign in                                                      |

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

### Local Environment Secrets

Local-only shell secrets live in `~/.environment-specifics.zshrc`, which is
ignored by git and sourced from `.zshrc`.

```bash
cp ~/.config/.environment-specifics.example.zshrc ~/.environment-specifics.zshrc
chmod 600 ~/.environment-specifics.zshrc
```

### Homebrew Packages

`Brewfile` is the curated Homebrew baseline used by the macOS setup script.

```bash
./scripts/brew_install_all.sh        # Install Brewfile packages
./scripts/brew_install_all.sh --skip-apps
./scripts/audit-brew.sh              # Report installed-vs-declared drift
```

If `audit-brew.sh` reports an installed package that should be part of the
baseline, add it to `Brewfile`. If it reports a stale package, uninstall it.

### Syncing Preferences Between Machines

Some macOS apps (Contexts, Rectangle, Raycast, Thaw, Velja) store settings in
plist files that can't be symlinked, because the apps rewrite them.

These go through `cfprefsd` rather than being copied, and are filtered and
normalized on the way in and out — see [How plist sync works](#how-plist-sync-works).

**To sync settings from this machine to the repo:**

```bash
./scripts/export-preferences.sh          # System -> repo
git diff                                 # Readable: shows the settings that changed
git add -A && git commit -m "Update preferences" && git push
```

**On another machine:**

```bash
git pull
./scripts/link-files.sh                  # Repo -> system
# Quit the affected apps first — a running app overwrites its plist on exit.
# link-files.sh warns you if it finds one running.
```

**To check for uncommitted setting changes:**

```bash
./scripts/export-preferences.sh --check  # Exits non-zero if a real setting drifted
./scripts/export-preferences.sh -v       # Also lists the churn keys it strips
```

#### How plist sync works

Plists are not `cp`'d in either direction, for four reasons:

1. **`cp` reads stale bytes.** `cfprefsd` caches preferences in memory and
   writes lazily, so the on-disk plist can lag the live state. Export goes
   through `defaults export`, which asks `cfprefsd` for the truth. Import goes
   through `defaults import`, so `cfprefsd` performs the write instead of having
   it done behind its back (and then reverted).
2. **Plists mix settings with churn.** Launch counters, window frames, update
   timestamps and analytics IDs change constantly.
   `config/preference-filters.yaml` strips them, so a drift report means a real
   setting actually changed. (Before this, `link-files.sh --verify` reported 7
   warnings permanently, which is how genuine changes — Thaw's
   `SectionDividerStyle`, Rectangle's whole config since 2024 — sat uncommitted.)
3. **Some values are byte-unstable.** Thaw serializes JSON blobs with unstable
   key order, so those keys could never compare equal. The exporter
   canonicalizes embedded JSON.
4. **Binary plists are unreviewable.** Exports are written as sorted XML, so
   `git diff` shows which setting changed instead of `Binary files differ`.

Because the committed plist is *filtered*, it describes only the tracked
settings — it is not a whole-domain replacement. `link-files.sh` therefore
merges it onto the live domain (tracked keys win, local churn is preserved)
rather than overwriting.

**Raycast caveat:** its real configuration (hotkeys, aliases, extensions,
quicklinks) lives in an encrypted SQLite store restored by Raycast Cloud Sync,
not in the plist. The tracked plist is mostly onboarding flags and window state,
and is a candidate for dropping from `file-mappings.yaml` entirely.

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
│   ├── file-mappings.yaml      # All symlink/copy/plist definitions
│   └── preference-filters.yaml # Churn keys stripped from exported plists
├── Brewfile                  # Declarative Homebrew baseline
├── scripts/
│   ├── setup-macos.sh        # macOS setup (run this)
│   ├── setup-linux-dev.sh    # Linux setup
│   ├── link-files.sh         # Apply file mappings
│   ├── verify-setup.sh       # Check setup status
│   ├── export-preferences.sh # Export app prefs to repo (--check for drift)
│   ├── lib/
│   │   ├── normalize-plist.py  # Strip churn, canonicalize JSON, emit XML
│   │   └── merge-plist.py      # Overlay tracked keys onto a live domain
│   ├── audit-brew.sh         # Report Homebrew drift from Brewfile
│   ├── brew_install_all.sh   # Homebrew packages
│   ├── install_zsh_and_omz.sh
│   └── clear-notifications.sh  # Clear all macOS notifications
├── vscode/                  # VS Code / Cursor settings
├── karabiner/               # Keyboard remapping (see [karabiner/README.md](karabiner/README.md))
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
- [Hammerspoon](https://www.hammerspoon.org/) - Lua-scripted automation; runs the directional window switcher (successor to [Slate](https://github.com/jigish/slate))
- [iTerm2](https://iterm2.com/) - terminal
- [Thaw](https://github.com/stonerl/Thaw/) - menu bar management
- [Velja](https://sindresorhus.com/velja) - browser routing (sandboxed plist; see [CLAUDE.md](CLAUDE.md#velja-config))
- [InstantSpaceSwitcher](https://github.com/joshlebed/InstantSpaceSwitcher) - instant Space switching + move-window-to-desktop (custom fork; see [below](#instantspaceswitcher))

### InstantSpaceSwitcher

A custom fork of [InstantSpaceSwitcher](https://github.com/joshlebed/InstantSpaceSwitcher)
(upstream: [jurplel/InstantSpaceSwitcher](https://github.com/jurplel/InstantSpaceSwitcher))
that does two things:

- **Instant Space switching** — no slide animation (synthetic high-velocity
  dock-swipe gesture). This is the upstream feature.
- **Move window & follow** (fork addition) — move the focused window to the
  adjacent desktop and switch there with it.

**Wiring.** The hotkeys don't go through macOS shortcuts; Karabiner's nav layer
(`karabiner/`) emits intermediate `F16` combos that the running app listens for:

| Keys (nav layer) | Karabiner emits | Action |
| --- | --- | --- |
| `caps+d` / `caps+f` | `ctrl+←` / `ctrl+→` | switch desktop left / right |
| `caps+cmd+d` / `caps+cmd+f` | `⌥⇧⌘F16` / `⌥⌘F16` | move focused window to desktop left / right |

**How the move works (macOS 26).** Apple gated the private "move window to a
Space by id" APIs, so the app replicates Raycast's technique: warp the real
cursor to the window's title bar, hold a zero-motion left-click, switch desktops
(carrying the held window), then release and restore the cursor. Works for
normal Cocoa windows and Spotify with zero drift. **Known limitation:** Electron
apps (Claude, ChatGPT) don't move yet — their in-app drag loop swallows the
Space-switch keystroke (even Raycast can't move them). Full design notes and the
plan for fixing it: [`docs/move-window-and-follow.md`](https://github.com/joshlebed/InstantSpaceSwitcher/blob/feature/move-window-and-follow/docs/move-window-and-follow.md).

**Source / install.** Source is at `~/code/InstantSpaceSwitcher` (not built by
the dotfiles setup scripts). Build with `./dist/build.sh`, re-sign with the
Developer ID cert so Accessibility carries across rebuilds, then replace
`/Applications/InstantSpaceSwitcher.app` and relaunch. Needs Accessibility +
Input Monitoring permission.

### Editors

- [VS Code](https://code.visualstudio.com/)
- [Cursor](https://www.cursor.com/) - VS Code with AI

### Chrome Extensions

- [Duplicate Tab Shortcut](https://chromewebstore.google.com/detail/duplicate-tab-shortcut/klehggjefofgiajjfpoebdidnpjmljhb)
- [Google Search Keyboard Shortcuts](https://chromewebstore.google.com/detail/google-search-keyboard-sh/iobmefdldoplhmonnnkchglfdeepnfhd?hl=en)
- [Tab to Window/Popup Keyboard Shortcuts](https://chromewebstore.google.com/detail/tab-to-windowpopup-keyboa/adbkphmimfcaeonicpmamfddbbnphikh?hl=en)
- [uBlock Origin](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm)
- [Dark Reader](https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh)
- [Bitwarden](https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb)

## Git Multi-Account Setup

Seamlessly use both work and personal GitHub accounts with automatic SSH key and
email selection based on repo owner.

See [docs/git-multi-account-setup.md](docs/git-multi-account-setup.md) for full
setup instructions.
