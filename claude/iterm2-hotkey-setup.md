# Claude Code + iTerm2 Integration

Click Claude Code notifications → Opens iTerm2 hotkey window

## ✨ One-Command Setup

```bash
bash ~/.config/claude/setup-iterm2-api.sh
```

That's it! The script handles everything:
- ✅ Installs terminal-notifier (if Homebrew is available)
- ✅ Creates Python venv at `~/.iterm2/venv/`
- ✅ Installs iTerm2 Python module
- ✅ Creates self-healing `runpython` wrapper
- ✅ Optionally adds `it2hw` alias

## 📋 Prerequisites

1. **iTerm2** with hotkey window configured:
   - iTerm2 → Preferences → Keys → Hotkey Window
   - Set your preferred hotkey (e.g., ⌥Space)

2. **Python 3** installed (usually comes with macOS)
   - If missing: `brew install python3`

## 🧪 Test It Works

```bash
# Test the notification (click it to open iTerm2)
echo '{"transcript_path": "/tmp/test"}' | ~/.config/claude/notify-end.sh
```

## 📁 What Gets Installed

| Component | Location | Purpose |
|-----------|----------|---------|
| Python venv | `~/.iterm2/venv/` | Isolated Python with iTerm2 module |
| runpython | `~/.iterm2/runpython` | Wrapper that auto-heals if things break |
| Notify hook | `~/.config/claude/notify-end.sh` | Creates clickable notifications |

## 🔧 Troubleshooting

```bash
# If anything goes wrong, just re-run:
bash ~/.config/claude/setup-iterm2-api.sh

# Missing dependencies?
brew install python3 terminal-notifier

# iTerm2 not opening? Check:
# iTerm2 → Preferences → Keys → Hotkey Window is configured
# iTerm2 → Preferences → General → Magic → Enable Python API
```