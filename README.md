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
| Raycast          | Sign in; Cloud Sync restores hotkeys/aliases/extensions — incl. ⌘G → Smart Search (see [raycast/README.md](raycast/README.md#hotkeys)) |
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

App menu shortcuts (System Settings → Keyboard → App Shortcuts) are set **by
hand** — the checklist lives in [mac-settings.md](mac-settings.md). They were
scripted for a while (`apply-keyboard-shortcuts.sh` wrote
`NSUserKeyEquivalents`), but the applied bindings didn't take on a new machine,
so the scripts were removed and the manual checklist restored.

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

### Node (fnm)

Node is managed by [fnm](https://github.com/Schniz/fnm), not nvm and not
Homebrew. **Node 26 is the default**; 22 is installed alongside it, so
`fnm use 22` works without a download.

```bash
fnm list                 # what's installed, and which is default
fnm default 26           # change the default (do this deliberately)
fnm install 24 && fnm use 24
```

`.nvmrc` / `.node-version` files are picked up automatically on `cd`, searching
upward to the repo root (`--use-on-cd --version-file-strategy recursive`), so a
monorepo subdirectory still resolves the root's pinned version. fnm *also*
reads `engines.node` from `package.json`, and resolves a range to the newest
**installed** match — so `">=20.19.0"` selects 26, not 20.

**niteshift is pinned to node 22 by path**, in `.zshenv`. It can't be pinned
from inside the repo: it has no version file, and the `engines.node` range
above is what silently promotes it to 26. Pinning by path is what lets the repo
itself stay untouched. The pin is a `chpwd` hook registered *after* fnm's own,
so it runs second and wins, plus one call at shell start — that hook only fires
on `cd`, so a script launched with its cwd already inside the repo would
otherwise never trigger one. It covers `~/code/niteshift` and
`~/.superset/worktrees/niteshift`.

fnm's `Using Node v26.7.0` line on every version change is silenced with
`--log-level error`, which still lets genuine errors through. (`quiet` would
mute those too.)

**Why three files.** The fnm setup is split across `.zshenv`, `.zprofile`, and
the end of `.zshrc`, which looks redundant but isn't — each covers a case the
others miss:

| File | Sourced by | Why it's needed |
| --- | --- | --- |
| `.zshenv` | **every** zsh, incl. non-interactive | Runs `fnm env`. Scripts, git hooks and cron never read `.zshrc`, so without this they got a different node than the terminal. |
| `.zprofile` | login shells, after `/etc/zprofile` | macOS's `/etc/zprofile` runs `path_helper`, which rebuilds `PATH` and demotes fnm's entry. Re-asserts it. |
| `.zshrc` (last line) | interactive shells | Re-asserts again, after every other `PATH` prepend in the file. Must stay last. |

Only `.zshenv` evaluates `fnm env`; the other two just re-prepend
`$FNM_MULTISHELL_PATH/bin`, so no extra multishell directories are allocated.

This was a real bug, not theoretical: an interactive shell ran node 22 while
`zsh -c` ran Homebrew's node 26.

**Homebrew's `node` is deliberately not in the Brewfile.** It remains installed
only as `neonctl`'s dependency (receipt marked as a dependency, not
on-request, so `audit-brew.sh` stays quiet). Adding `brew "node"` back would
reintroduce a second runtime on `PATH`.

On Linux, `setup-linux-dev.sh` installs fnm from a pinned release and applies
the same default — 26, with 22 installed alongside it, matching macOS. See
`FNM_RELEASE` / `FNM_DEFAULT_NODE` / `FNM_EXTRA_NODE` near the top of
`install_fnm()`.

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
- [fnm](https://github.com/Schniz/fnm) - node version manager (see [Node (fnm)](#node-fnm))

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
- [InstantSpaceSwitcher](https://github.com/jurplel/InstantSpaceSwitcher) - instant Space switching, no slide animation (see [below](#instantspaceswitcher))

### InstantSpaceSwitcher

[jurplel/InstantSpaceSwitcher](https://github.com/jurplel/InstantSpaceSwitcher)
switches Spaces with no slide animation, by synthesizing a trackpad dock-swipe
gesture at an artificially high velocity. It's in the Brewfile:

```bash
brew install --cask jurplel/tap/instant-space-switcher
```

Then grant **Accessibility** (System Settings → Privacy & Security) and add it
to Login Items — `./scripts/login-items.sh --apply` already includes it.

**Wiring.** `caps+d` / `caps+f` on Karabiner's nav layer emit **`⌃⌥⌘←` / `⌃⌥⌘→`**,
which is ISS's *own default hotkey* — not a macOS shortcut.

That distinction is the whole trick, so don't "simplify" it:

- macOS's native "move left/right a space" is plain `ctrl+←` / `ctrl+→`, and it
  stays enabled. Symbolic hotkeys match an exact modifier set, so `⌃⌥⌘←` never
  triggers it. Only ISS fires, and the switch is instant.
- Emitting plain `ctrl+←` instead would hit the *native* shortcut and animate.
  Making that work would mean rebinding ISS **and** disabling symbolic hotkeys
  79/81 — otherwise both fire and you jump two Spaces.

So nothing needs disabling, and pressing `ctrl+←` by hand still does the normal
animated switch.

If you ever rebind ISS's hotkey in its preferences, update `karabiner/karabiner.js`
(`// spaces nav`) to match. ISS stores hotkeys in `com.interversehq.InstantSpaceSwitcher`
as `JSONEncoder`-encoded blobs under `hotkey.left` / `hotkey.right`, so scripting
that side is possible but awkward — moving the Karabiner mapping is the easy half.

**Only 2 of ISS's 13 hotkeys are enabled.** Out of the box it also grabs
`⌃⌥⌘1`–`⌃⌥⌘0` (jump to space 1–10) and `⌃⌥⌘+` (last space), none of which are
used here. Those are turned off, so ISS squats two global shortcuts instead of
thirteen.

Unlike the hotkey combos, the enable flags are plain booleans (`enabled.left`,
`enabled.right`, `enabled.space1`…`space10`, `enabled.lastSpace`), so they're
scriptable directly:

```bash
osascript -e 'quit app "InstantSpaceSwitcher"'   # it rewrites its plist on exit
for i in 1 2 3 4 5 6 7 8 9 10; do
  defaults write com.interversehq.InstantSpaceSwitcher "enabled.space$i" -bool false
done
defaults write com.interversehq.InstantSpaceSwitcher "enabled.lastSpace" -bool false
open -a InstantSpaceSwitcher
```

This is tracked as a plist copy (`config/file-mappings.yaml`), so
`./scripts/link-files.sh` reapplies it on a new machine and
`./scripts/export-preferences.sh --check` reports drift. ISS treats a *missing*
flag as enabled, so `enabled.left` / `enabled.right` are stored explicitly
`true` — the file states the intent rather than depending on that default.

#### Why upstream, not the old fork

A [personal fork](https://github.com/joshlebed/InstantSpaceSwitcher) was used
until 2026-09. It added exactly one feature — **move window & follow** on
`caps+cmd+d`/`caps+cmd+f`, via a cursor-warp drag-carry — and it never worked
for Electron apps (Claude, ChatGPT), whose in-app drag loop swallows the
Space-switch keystroke. Instant switching itself was always 100% upstream code;
the fork's 6 commits touched none of it.

Dropped because the fork had drifted 9 commits behind upstream, missing among
other things `fix: guard CF null returns in ISS event-tap setup` — a hardening
fix in the event tap the entire app runs on. It also required a full Xcode
toolchain to rebuild, where the cask updates with `brew upgrade`.

**The cask is not notarized.** It is ad-hoc signed too (`Signature=adhoc`,
`TeamIdentifier=not set`) and `spctl -a -t install` rejects it, which is why
upstream's README has a whole section on getting past "Apple could not verify…".
Installing via the cask and launching with `open -a InstantSpaceSwitcher` worked
first try regardless. If a future machine does get blocked, follow
[upstream's instructions](https://wiki.hacks.guide/wiki/Open_unsigned_applications_on_macOS_Sequoia_and_newer)
or clear the flag with `xattr -d com.apple.quarantine /Applications/InstantSpaceSwitcher.app`.

That means ad-hoc signing was never a *fork-specific* problem — but the exposure
differs a lot. macOS ties Accessibility grants to the code signature, and an
ad-hoc signature changes with every build. Rebuilding the fork locally meant
re-granting constantly; with the cask it only happens when a new version ships.
The Developer ID that fixed this properly lived only in one machine's keychain
and can't be reissued by Apple, so it isn't a portable answer.

**Note:** `caps+cmd+d` / `caps+cmd+f` still emit `⌥⇧⌘F16` / `⌥⌘F16` from the nav
layer. Keyboard Maestro and Hammerspoon don't bind those (Hammerspoon takes only
bare and shift `F16`, for directional focus), and Raycast's config database is
encrypted, so the consumer is unconfirmed — most likely a Raycast window-management
hotkey. Worth confirming and documenting here.

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

