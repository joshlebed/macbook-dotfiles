See @README.md for project documentation.

See @DEVELOPMENT.md for development documentation.

## Velja config

Canonical source: `velja/rules.json`. Edit that file, then:

```bash
./scripts/sync-velja-rules.sh apply        # repo → system (quits + relaunches Velja)
./scripts/sync-velja-rules.sh export       # system → repo (after editing rules in Velja's GUI)
```

Why a script (not symlink/copy): Velja stores rules under the `rules` key of
its sandboxed plist at
`~/Library/Containers/com.sindresorhus.Velja/Data/Library/Preferences/com.sindresorhus.Velja.plist`
as an **array of JSON strings** (one stringified rule object per array
entry), not a nested dict. The script translates between repo JSON and the
plist representation, and runs the required `quit Velja → killall cfprefsd →
write plist → killall cfprefsd → relaunch` sequence — without flushing
`cfprefsd` before and after the write, the daemon's in-memory cache will
overwrite the file when Velja relaunches.

To add a new rule, prefer editing `velja/rules.json` directly and running
`apply`, rather than clicking through Velja's GUI and running `export`.
The repo file is the source of truth.

Reference: official Velja docs at https://sindresorhus.com/velja. The
export/import file format `rules.json` uses is the same one documented
there; our script just bypasses the GUI. For debugging (especially
source-app rule mismatches): quit Velja, hold ⇧⌃ while launching, then
menu bar → Debug → Logs. The history view in Advanced settings shows
which source app Velja detected for each opened link — useful for
verifying our `Source app: …` rules fire correctly.
