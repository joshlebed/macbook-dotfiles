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

**Important — sandboxed app caveat**: before running `link-files.sh`, quit
Velja first. Otherwise `cfprefsd`'s in-memory cache will overwrite the file
when Velja relaunches. Recommended sequence:

```bash
osascript -e 'quit app "Velja"'
killall cfprefsd 2>/dev/null
./scripts/link-files.sh
killall cfprefsd 2>/dev/null
open -a Velja
```

For debugging source-app rule mismatches: quit Velja, hold ⇧⌃ while
launching, then menu bar → Debug → Logs. The history view in Advanced
settings shows which source app Velja detected for each opened link.

Reference: https://sindresorhus.com/velja.
