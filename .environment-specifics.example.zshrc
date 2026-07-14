# Local-only shell environment.
#
# Copy to ~/.environment-specifics.zshrc and fill in real values:
#
#   cp ~/.config/.environment-specifics.example.zshrc ~/.environment-specifics.zshrc
#   chmod 600 ~/.environment-specifics.zshrc
#
# This file is a tracked template; the real file is gitignored. It is sourced at
# the end of .zshrc, so it can override anything above it.
#
# Everything here is either a secret or a machine-specific path, which is why
# none of it lives in the repo. Anything you add locally should be listed here
# with an empty value, so a new machine knows the variable exists — an undefined
# variable fails silently and confusingly at the point of use, usually much
# later and far from the cause.

# ---------------------------------------------------------------------------
# Home Assistant — used by restart-ha() in .zshrc
# ---------------------------------------------------------------------------
export HOME_ASSISTANT_URL="http://192.168.0.181:8123"
export HOME_ASSISTANT_TOKEN=""

# ---------------------------------------------------------------------------
# Niteshift (work) — path to the local checkout
# ---------------------------------------------------------------------------
export PATH_TO_NITESHIFT_REPO="${HOME}/code/niteshift"

# Work dev aliases. Guarded: without the guard, a missing checkout makes every
# new shell print a "no such file or directory" error.
if [[ -f "${PATH_TO_NITESHIFT_REPO}/scripts/dev-aliases.sh" ]]; then
  source "${PATH_TO_NITESHIFT_REPO}/scripts/dev-aliases.sh"
fi

# ---------------------------------------------------------------------------
# API keys
# ---------------------------------------------------------------------------

# shell-ai — the `q` and `shell-ai` commands (Brewfile: ibigio/tap/shell-ai)
export SHELL_AI_OPENAI_API_KEY=""

# tmuxai (Brewfile: tmuxai)
export TMUXAI_OPENROUTER_API_KEY=""

# vaic
export VAIC_OPENAI_API_KEY=""

# ---------------------------------------------------------------------------
# PATH additions specific to this machine
# ---------------------------------------------------------------------------
# e.g. export PATH="${HOME}/code/some-tool:${PATH}"
