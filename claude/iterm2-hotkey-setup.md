# Claude Code + iTerm2 Hotkey Window Integration

## Quick Setup

Run the setup script to enable iTerm2 API:
```bash
bash ~/.config/claude/setup-iterm2-api.sh
```

This creates a Python venv with the iTerm2 module and a `runpython` wrapper that auto-heals if anything breaks.

## Configure Claude Code to Open iTerm2 Automatically

### Option 1: Session Start Hook
Add to `~/.config/claude/settings.json`:
```json
{
  "hooks": {
    "on_session_start": "~/.iterm2/runpython ~/.iterm2/it2api hotkey-window"
  }
}
```

### Option 2: Custom Command
Create a Claude Code custom command at `~/.claude/commands/iterm.md`:
```markdown
---
name: iterm
description: Open iTerm2 hotkey window
---
Open the iTerm2 hotkey window
```

Then add a hook to execute on this command:
```json
{
  "hooks": {
    "on_command_iterm": "~/.iterm2/runpython ~/.iterm2/it2api hotkey-window"
  }
}
```

### Option 3: Shell Alias
Add to `~/.zshrc`:
```bash
# Auto-open iTerm when starting Claude Code
alias cc='claude-code && ~/.iterm2/runpython ~/.iterm2/it2api hotkey-window'
```

## Test It Works

```bash
# Test the command directly
~/.iterm2/runpython ~/.iterm2/it2api hotkey-window

# Or use the alias (if you added it during setup)
it2hw
```

## Troubleshooting

- **Python not found**: Install with `brew install python3`
- **Module errors**: Re-run `bash ~/.config/claude/setup-iterm2-api.sh`
- **Nothing happens**: Check iTerm2 → Preferences → Keys → Hotkey Window is configured