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
- All config file symlinks/copies

**Options:**

```bash
./scripts/setup-macos.sh --dry-run   # Preview changes
./scripts/setup-macos.sh --skip-brew # Skip Homebrew
./scripts/setup-macos.sh --skip-apps # Install CLI tools, skip GUI apps
./scripts/verify-setup.sh            # Check setup status
./scripts/audit-brew.sh              # Compare installed Homebrew packages to Brewfile
```

### Git identity (day 1)

This repo is public and the clone above uses HTTPS, so **no SSH key or GitHub
login is needed to set up a new machine**. You do need both to push to this repo
and to do any real work, so once `setup-macos.sh` has installed `gh`:

```bash
./scripts/bootstrap-git-identity.sh            # or --dry-run to preview
```

It is idempotent and safe to re-run. It will:

1. Confirm `gh` is installed and your identity resolves (name/email come from
   `git/config` in this repo — see below).
2. Log in to GitHub (`gh auth login --git-protocol ssh --web`) if needed.
3. Generate `~/.ssh/id_ed25519` if you don't have one.
4. Add a `github.com` block to `~/.ssh/config` (`AddKeysToAgent` +
   `UseKeychain`) so the key survives reboots, and load it into the keychain.
5. Test `ssh -T git@github.com`, and **only if that fails**, register the public
   key with GitHub — requesting the `admin:public_key` scope on demand, since a
   default `gh auth login` doesn't grant it.
6. Switch this repo's `origin` from HTTPS to SSH so you can push.

If you'd rather do it by hand, GitHub's own docs cover the same ground:
[generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
and [adding it to your account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

**Global git config is tracked**, at `git/config` — the XDG path
(`~/.config/git/config`), which git reads natively, so cloning this repo
installs it with no symlink needed. The same trick already covers `git/ignore`.

> **`~/.gitconfig` must not exist.** If it does, git reads *both* files and
> `~/.gitconfig` wins every conflict, silently shadowing the tracked config. It
> also captures `git config --global` writes. With it gone, `git config --global`
> writes to the tracked file instead, so global config changes are version
> controlled automatically.

### Manual App Configuration

Some apps need manual setup after running the script:

| App              | Setup                                                        |
| ---------------- | ------------------------------------------------------------ |
| Keyboard Maestro | File → Start Syncing Macros → `km_macros.kmsync`             |
| iTerm2           | Preferences → General → Load from `~/.config/iterm2`         |
| Hammerspoon      | Grant Accessibility permission; enable "Launch at login"     |
| Thaw             | Grant Accessibility/Screen Recording; enable launch at login |
| Velja            | Set as default browser; quit before running `link-files.sh`  |
| Contexts         | License file is gitignored — copy it over by hand            |
| Raycast          | Sign in; Cloud Sync restores hotkeys/aliases/extensions      |
| Google Drive     | Sign in                                                      |
| TickTick         | Sign in                                                      |

### Login Items

```bash
./scripts/login-items.sh --export   # system -> config/login-items.yaml
./scripts/login-items.sh --apply    # config -> system (run by setup-macos.sh)
./scripts/login-items.sh --check    # report drift
```

Covers only the **legacy** login items System Events can set (System Settings →
General → Login Items). Apps that register via `SMAppService` — their own
"launch at login" toggle, e.g. Hammerspoon and Thaw — are owned by the app and
must still be enabled by hand, as the manual table above says.

Export skips items whose target no longer exists, so a deleted app can't be
carried onto a new machine. (Amethyst was exactly that: a login item macOS
itself reported as `path: missing value`.)

### Keyboard Shortcuts

```bash
./scripts/export-keyboard-shortcuts.sh   # system -> config/keyboard-shortcuts.yaml
./scripts/apply-keyboard-shortcuts.sh    # config -> system
```

`NSGlobalDomain` shortcuts (Minimize, Show Tab Bar) need a **logout/login** to
take effect; app-specific ones just need the app restarted.

Two sharp edges worth knowing:

- **Bindings match menu items by exact title, and macOS accepts a binding for a
  menu item that doesn't exist.** A shortcut for an uninstalled app, or one
  whose menu title changed, is a silent no-op that looks applied. `apply` now
  warns when the target app isn't installed. The Chrome entries are the live
  example: they target profiles by display name (`Josh (Personal)`), so on a
  fresh Chrome — where no profile has that name yet — they will bind to nothing
  until the profiles are recreated with matching names.
- **Only plain-ASCII shortcuts round-trip.** `defaults` renders a non-ASCII key
  (Tab/arrows/Escape) as a `\Uxxxx` escape, and PlistBuddy strips the backslash
  instead of decoding it, turning `^⇥` into the literal string `^U21e5`. Export
  therefore refuses (exit 1) to record anything that isn't modifiers plus one
  ASCII key, rather than silently committing a corrupted binding — which is what
  previously happened to a Messenger shortcut.

### Editor Extensions

VS Code and Cursor hold different extension sets, so they get one tracked list
each (`vscode/extensions-vscode.txt`, `vscode/extensions-cursor.txt`).

```bash
./scripts/editor-extensions.sh --export    # system -> repo
./scripts/editor-extensions.sh --install   # repo -> system (run by setup-macos.sh)
./scripts/editor-extensions.sh --check     # report drift
```

These are deliberately **not** `vscode` lines in the Brewfile. `brew bundle`
shells out to whatever `code` resolves to on PATH — and here `code` is *Cursor*
(`/opt/homebrew/bin/code` → `Cursor.app`), so those lines would install Cursor's
extensions into Cursor while claiming to describe VS Code. The script addresses
each editor's CLI by absolute path instead; VS Code's own CLI lives inside its
app bundle and is not the `code` on your PATH.

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

Some macOS apps (Contexts, Rectangle, Thaw, Velja) store settings in plist files
that can't be symlinked, because the apps rewrite them.

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

**Raycast is deliberately not synced here.** Its settings — hotkeys, aliases,
extensions, quicklinks — live in Raycast's own database and come back when you
sign in, because Cloud Sync restores them. Its plist used to be tracked, but it
held none of that; only leftovers like onboarding flags and window positions.
So on a new Mac: sign in to Raycast, and you're done.

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
├── git/
│   ├── config               # Global git config (XDG; read natively by git)
│   └── ignore               # Global gitignore (XDG)
├── scripts/
│   ├── setup-macos.sh        # macOS setup (run this)
│   ├── bootstrap-git-identity.sh # SSH key + GitHub auth (day 1)
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

**Do not install the Homebrew cask.** `jurplel/tap/instant-space-switcher`
installs upstream's build to `/Applications/InstantSpaceSwitcher.app` — the same
path the fork build uses — so it silently replaces the fork and the
move-window-and-follow feature disappears. It is deliberately absent from the
Brewfile, and `brew uninstall --cask` would delete the fork build, so if it ever
gets installed, remove it with
`rm -rf /opt/homebrew/Caskroom/instant-space-switcher` instead.

#### Setting it up on a new machine

Nothing here is automated by the setup scripts.

**1. Clone the fork** (the feature lives on a branch, not `main`):

```bash
git clone git@github.com:joshlebed/InstantSpaceSwitcher.git ~/code/InstantSpaceSwitcher
cd ~/code/InstantSpaceSwitcher
git checkout feature/move-window-and-follow
git remote add upstream git@github.com:jurplel/InstantSpaceSwitcher.git
```

**2. Get the signing certificate onto the new Mac — do this before the old one
is wiped.** This is the only step that can't be redone later.

The app is signed with `Developer ID Application: JOSHUA AARON LEBEDINSKY
(Q65U6C65ZZ)`. macOS ties Accessibility and Input Monitoring grants to the code
signature, so a stable identity means the grants survive rebuilds. `build.sh`
only signs **ad-hoc**, and an ad-hoc signature changes on every build — so
without the cert you must re-grant both permissions every single rebuild.

Apple does not store the private key, so it cannot be re-downloaded. Export it
from the old Mac:

> Keychain Access → My Certificates → `Developer ID Application: JOSHUA AARON
> LEBEDINSKY` → right-click → Export → `.p12` (set a password) → copy to the new
> Mac → double-click to import.

Verify it landed:

```bash
security find-identity -v -p codesigning   # should list the Developer ID Application identity
```

If you skip this, everything still works — you just re-grant permissions after
each rebuild.

**3. Build, sign, install:**

```bash
cd ~/code/InstantSpaceSwitcher
./dist/build.sh                    # universal release → build/InstantSpaceSwitcher.app (ad-hoc signed)

# Optional but recommended — re-sign so TCC grants survive rebuilds:
codesign --force --deep --options runtime \
  --sign "Developer ID Application: JOSHUA AARON LEBEDINSKY (Q65U6C65ZZ)" \
  build/InstantSpaceSwitcher.app

./dist/install.sh                  # quits, replaces /Applications, strips quarantine, launches
```

`install.sh --reset-permissions` also clears the existing TCC grants, which is
what you want if the signature changed and macOS is confused about the app.

**4. Grant permissions and autostart.** System Settings → Privacy & Security →
**Accessibility** and **Input Monitoring**. Then add it to Login Items (or run
`./scripts/login-items.sh --apply` from this repo, which includes it).

The installed build records the commit it came from, so you can always tell what
you're running:

```bash
defaults read /Applications/InstantSpaceSwitcher.app/Contents/Info GitCommitHash
```

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

