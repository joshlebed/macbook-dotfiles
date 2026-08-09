# Symlinked to ~/.zshenv by scripts/link-files.sh (see README).
#
# .zshenv is sourced by EVERY zsh invocation, including non-interactive ones
# (`zsh -c ...`, git hooks, cron, LaunchAgents, Raycast scripts). .zshrc is not.
# Keep this file minimal and side-effect-free for that reason.
#
# fnm lives here rather than in .zshrc so scripts get the same node as the
# terminal. Before this, an interactive shell got fnm's node and a script got
# Homebrew's — two different major versions.
#
# NOTE: this does not finish the job on macOS. /etc/zprofile runs
# `brew shellenv` AFTER .zshenv and re-prepends /opt/homebrew/bin, which would
# shadow fnm's node again in login shells. .zshrc re-asserts the PATH entry set
# here; see the fnm block at the end of that file.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell zsh --use-on-cd --version-file-strategy recursive)"
fi
