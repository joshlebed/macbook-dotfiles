# macOS Settings

## Scripted

Most of this file used to be a hand-run checklist. The parts that can be
scripted now are:

```bash
./scripts/apply-macos-defaults.sh            # key repeat, dock, scroll bars, motion...
./scripts/apply-macos-defaults.sh --check    # report anything that drifted
./scripts/login-items.sh --apply             # login items
./scripts/apply-keyboard-shortcuts.sh        # app menu shortcuts
```

`setup-macos.sh` runs all three. See `scripts/apply-macos-defaults.sh` for the
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

Note: app menu shortcuts (Finder, Chrome, Spotify, iTerm, global Minimize/Show
Tab Bar) are **not** in this list — `apply-keyboard-shortcuts.sh` handles those.

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
