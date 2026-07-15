# macOS Settings

## Scripted

Most of this file used to be a hand-run checklist. The parts that can be
scripted now are:

```bash
./scripts/apply-macos-defaults.sh            # key repeat, dock, scroll bars, motion...
./scripts/apply-macos-defaults.sh --check    # report anything that drifted
./scripts/login-items.sh --apply             # login items
```

`setup-macos.sh` runs both. See `scripts/apply-macos-defaults.sh` for the
exact settings and values.

## Still manual

These resist scripting, or aren't worth the risk of writing blind.

### System keyboard shortcuts

System Settings → Keyboard → Keyboard Shortcuts. These live in
`com.apple.symbolichotkeys` as opaque numeric IDs with binary values; writing
them blind is a good way to lose your keyboard, so they stay manual.

- Disable Launchpad and Dock shortcuts
- Disable display shortcuts
- Mission Control and Notification Center → `caps + g` and `option`
- Disable the "Show Spotlight Search" shortcut, or move it to
  `ctrl + option + command + space`
- Disable screenshot shortcuts, except "Save picture of selected area as a file"
  → `F13`
- Services → Files and Folders → "New iTerm2 Tab Here" → `cmd + shift + t`

### App menu shortcuts

System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts. These were
scripted for a while (`apply-keyboard-shortcuts.sh` wrote
`NSUserKeyEquivalents`), but the applied bindings didn't take on a new
machine, so they're manual again.

- All Applications
  - Minimize: `ctrl + option + cmd + m`
  - Show Tab Bar: `ctrl + option + cmd + t`
- Finder
  - Close Window: `shift + cmd + w`
- Google Chrome
  - Josh (Niteshift): `ctrl + option + cmd + i`
  - Josh (Personal): `ctrl + option + cmd + u`
- iTerm
  - New Tmux Tab: `ctrl + t`
- Spotify
  - Go Back: `cmd + [`
  - Go Forward: `cmd + ]`

Two things to know when setting these:

- Bindings match menu items by **exact title**, and macOS accepts a binding
  for a menu item that doesn't exist. The Chrome entries target profiles by
  display name, so recreate the profiles with exactly those names first.
- The All Applications shortcuts (Minimize, Show Tab Bar) need a
  **logout/login** to take effect; app-specific ones just need the app
  restarted.

### Other

- Text Input → Input Sources: disable auto-correct
  (the `-g` autocorrect defaults are scripted, but the Input Sources pane has
  its own per-source toggles)
- Lock screen timing
- Wallpaper + screen saver
- Sign in to iCloud / Google Drive / Raycast / TickTick

### Login items

Handled by `scripts/login-items.sh`, but only the legacy System Events kind.
Apps with their own "launch at login" toggle (Hammerspoon, Thaw) still need it
enabled in their own preferences — see the README's manual-app table.
