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
