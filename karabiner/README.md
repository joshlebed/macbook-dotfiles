# karabiner config

Keyboard remapping via [Karabiner-Elements](https://karabiner-elements.pqrs.org/).

**`karabiner.json` is generated — never edit it directly.** All changes go in
`karabiner.js`.

## Conceptual model

The config is built around a **Caps Lock layer** called `nav_mode`:

- **Caps Lock held** = activates `nav_mode` variable (value 1)
- **Caps Lock released** = deactivates `nav_mode` (value 0)
- **Caps Lock tapped alone** = Escape

When `nav_mode` is active, the right hand becomes a Vim-like navigation cluster
(IJKL as arrows), plus tab/desktop/window management on surrounding keys. See
`karabiner.js` for the full mapping table.

Other rules outside `nav_mode` (in `misc_shortcuts`) handle app-specific
overrides, Cmd+W behavior, and volume control.

## How the config is structured

```
karabiner.js          ← source of truth, edit this
  ├── nav_mappings[]  ← nav_mode bindings (auto-wrapped with nav_mode condition)
  ├── misc_shortcuts  ← non-nav rules (app overrides, function keys, etc.)
  ├── command_for_raycast ← tap-Command = Raycast
  └── profiles[]      ← Global VIM (active), Tetris, Empty
        ↓
karabiner-config-builder.js  ← builds JSON from JS export
        ↓
karabiner.json        ← generated output, read by Karabiner-Elements
```

## Setup

```bash
cd ~/.config/karabiner && pnpm install
```

## Build

Start file watcher (rebuilds on save):

```bash
karabiner-build          # shell alias defined in .zshrc
# or: cd ~/.config/karabiner && pnpm run build
```

Open in editor and start watcher:

```bash
karabiner-dev            # shell alias: opens VS Code + starts watcher
```

Reformat `karabiner.json` for clean diffs:

```bash
cd ~/.config/karabiner && pnpm run format
```

Requires Node.js on PATH.

## How to modify

### Add a nav_mode binding

Add an entry to the `nav_mappings` array. The build system automatically wraps
each entry with the `nav_mode` variable condition. Example:

```js
{ from: { key_code: "n" }, to: { key_code: "tab" } },
```

If the mapping needs an app-specific condition, add a `conditions` array — it
will be merged with the nav_mode condition automatically.

### Add an app-specific override (outside nav_mode)

Add a manipulator to `misc_shortcuts.manipulators[]` with a
`frontmost_application_if` condition. To find an app's bundle identifier:

```bash
osascript -e 'id of app "AppName"'
```

Escape dots in the bundle ID with `\\.` (Karabiner uses regex matching).

### Add a new profile

Add a profile object to the `config.profiles` array. Set `selected: true` on
the one you want active.

## Intermediate keys (F16/F17/F18)

Several nav_mode bindings emit F-key combinations that are **not final
actions** — they're intermediate signals consumed by other automation tools
(Keyboard Maestro, Hammerspoon, etc.). If you see a mapping that outputs an
F16, F17, or F18 combo, check what downstream tool is listening for it before
changing it.

## Devices

The config includes device entries with vendor/product IDs. Devices with
`simple_modifications: switch_command_and_option` are external keyboards that
need Cmd/Option swapped (non-Apple layout).

## TODO: document these

- [ ] Map which downstream tool consumes each F16/F17/F18 combo (KM macro names
      or Hammerspoon bindings) so the connection is traceable
- [ ] Identify the 3 device vendor/product IDs (which physical keyboards are
      1452:832, 9494:4, 12951:6505?)
- [ ] Clarify what `quickfire_karabiner.js` is — still used or dead code?
- [ ] Address the TODO on `command_for_raycast` (line ~373 in karabiner.js) re:
      shift+cmd triggering Raycast unintentionally
- [ ] Document the F17/F18 volume control chain — what hardware or macro
      produces F17/F18 as input?
