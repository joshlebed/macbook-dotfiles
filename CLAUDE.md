See @README.md for project documentation.

See @DEVELOPMENT.md for development documentation.

## Velja config

Tracked as a full plist copy at `preferences/com.sindresorhus.Velja.plist`
(see `copies:` in `config/file-mappings.yaml`). The target lives in Velja's
sandboxed container:
`~/Library/Containers/com.sindresorhus.Velja/Data/Library/Preferences/com.sindresorhus.Velja.plist`.

Use the standard preference-sync scripts:

```bash
./scripts/export-preferences.sh   # system → repo
./scripts/link-files.sh           # repo → system
```

Both go through `cfprefsd` (`defaults export` / `defaults import`) rather than
copying the file, so the old manual `killall cfprefsd` dance is no longer
needed — `link-files.sh` does it after importing. `defaults` resolves the bare
`com.sindresorhus.Velja` domain into the sandbox container on its own, so the
container path above matters only for reference.

**Still required**: quit Velja before running `link-files.sh`. A running app
holds its preferences in memory and flushes them over anything we write when it
exits. `link-files.sh` warns if it detects Velja running, but does not quit it
for you.

```bash
osascript -e 'quit app "Velja"'
./scripts/link-files.sh
open -a Velja
```

**Schema coupling**: Velja's `SS_App_runOnce__migrate_*` flags are deliberately
*not* filtered out of the exported plist. They record which data migrations have
run, and are coupled to the on-disk schema — restoring settings without them can
make Velja re-run a migration against already-migrated data. (The repo's
pre-rewrite Velja copy was a pre-3.2.1 snapshot storing
`defaultBrowser = com.google.Chrome`; the current schema is
`browser:com.google.Chrome`. Applying that old copy would have been a schema
downgrade.)

For debugging source-app rule mismatches: quit Velja, hold ⇧⌃ while
launching, then menu bar → Debug → Logs. The history view in Advanced
settings shows which source app Velja detected for each opened link.

Reference: https://sindresorhus.com/velja.
