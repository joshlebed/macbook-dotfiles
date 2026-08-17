# Raycast Config

This directory contains custom scripts and configuration for
[Raycast](https://raycast.com/), a productivity tool for macOS. Most Raycast
config is saved and synced via the Raycast app (via paid subscription). This
directory contains custom scripts and configuration for Raycast.

## Quicklinks

Quicklinks are synced automatically via the Raycast app. This directory is used
for editing them using the import/export feature.

### Usage

1. Type the quicklink name in Raycast to open the quicklink

### Editing Quicklinks

### Setup

```bash
cd ~/.config/raycast/quicklinks && pnpm install
```

### Editing Quicklinks

1. Run "Export Quicklinks" in Raycast and save the file to this directory with
   its default timestamp name as a backup to capture any quicklinks manually
   added which aren't tracked in quicklinks-generator.js

2. Run an intial build and start file watcher:

   ```bash
   cd ~/.config/raycast/quicklinks && pnpm run build
   ```

   note: you need `node` available on your `PATH` (not sure which minimum
   version)

3. Edit `quicklinks-generator.js` to add links
4. If you edited or removed a quicklink, delete it from the Raycast app (Raycast
   -> Settings -> Extensions -> Quicklinks) or delete all quicklinks. If you
   only added a quicklink, you can skip this step.
5. Run "Import Quicklinks" in Raycast and select `_quicklinks.json`

## Text Commands

Blocks of text you want to paste somewhere — prompts, boilerplate, instructions.
Each `text/*.txt` file is compiled into a Raycast script command that pastes it
into the frontmost app.

```bash
./scripts/build-raycast-text-paste-scripts.py           # build
./scripts/build-raycast-text-paste-scripts.py --check   # verify output is up to date
```

Edit a `.txt` file, run the build, done. Raycast picks the generated scripts up
off disk on its own — there is nothing to import and no Raycast interaction at
all.

### File format

```
---
name: thermo
icon: 🌡️        # optional, defaults to 📋
---
<everything from here to EOF is the text, byte for byte>
```

`name` becomes the command's title, which is what you type in Raycast root
search. The body is never parsed, quoted, indented or escaped — these are long
prompts full of backticks and blank lines, and any format that required escaping
them would be miserable to edit.

The text is baked into the generated script at build time, so nothing is read
from `text/` at run time.

Generated output goes to `scripts/generated/`. Never edit those; delete a source
file and its command disappears on the next build. Hand-written scripts in that
directory are left alone — generated ones carry an `@generated` marker.

### Why script commands and not Raycast Snippets

Snippets do **not** appear in Raycast's root search; only commands do, because
Raycast indexes their `@raycast.title`. Reaching a snippet means running Search
Snippets first, which defeats the point. A script command is findable by typing
its name.

Raycast picks these up as long as `scripts/` was added **with its
subdirectories** (see below); `generated/` is one of them.

### Gotchas

- **Snippet placeholders are rejected.** `{clipboard}`, `{cursor}`, `{date}` and
  friends are expanded by Raycast's snippet engine, which a script has no access
  to — it would paste the literal text. The build fails rather than generating
  something silently wrong. `quote.sh` is the hand-written script that does the
  clipboard-wrapping job properly.
- **Generated scripts clobber the clipboard**, then restore it after 0.15s.
  Text only: a non-text clipboard (image, files) is not preserved.

`text/archive/` holds a one-off export of the Raycast Snippets this replaced,
kept only because it contains text no longer in the repo. Nothing reads it.

## Scripts

Scripts are custom commands that can be run from Raycast.

### Setup

1. Go to Raycast -> Settings -> Extensions -> Scripts -> Script Commands -> Add
   Directories
2. Add this directory and its subdirectories to the list

### Usage

1. Type the script title in Raycast to run the script

### Adding New Scripts

When creating new scripts:

1. Use the standard Raycast script metadata format
2. Include descriptive titles and icons
3. Follow the existing pattern for script organization
4. Raycast will automatically pick up the new script
