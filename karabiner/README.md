# karabiner config

## setup

```bash
cd ~/.config/karabiner && pnpm install
```

## instructions for karabiner config builds

to do an intial build and start file watcher:

```bash
cd ~/.config/karabiner && npm run build
```

to reformat `karabiner.json` for comparison and version control:

```bash
cd ~/.config/karabiner && npm run format
```

note: you need `node` available on your `PATH` (not sure which minimum version)
