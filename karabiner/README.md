# instructions for karabiner config builds

to do an intial build and start file watcher:

```bash
cd ~/.config/karabiner && node file-watcher.js
```

to reformat `karabiner.json` for comparison and version control:

```bash
cd ~/.config/karabiner && node config-formatter.js
```

note: you need `node` available on your `PATH` (not sure which minimum version)
