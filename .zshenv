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
  # --log-level error silences fnm's "Using Node v26.7.0" line, which it prints
  # on every cd that changes version. Errors still surface; `quiet` would mute
  # those too.
  eval "$(fnm env --shell zsh --use-on-cd --version-file-strategy recursive --log-level error)"

  # niteshift has to run node 22, but nothing inside that repo says so: its
  # package.json declares only `engines.node: ">=20.19.0"`, and fnm resolves a
  # range to the newest installed match — 26 — which beats the default. Pinning
  # by path here is what keeps the repo itself untouched.
  #
  # This is registered after fnm's own chpwd hook so it runs second and wins,
  # and is also called once immediately: that hook only fires on cd, so a
  # script started with its cwd already inside the repo never triggers one.
  autoload -U add-zsh-hook
  _fnm_niteshift_pin() {
    case "$PWD/" in
      "$HOME"/code/niteshift/* | "$HOME"/.superset/worktrees/niteshift/*)
        fnm use 22 --silent-if-unchanged
        ;;
    esac
  }
  add-zsh-hook chpwd _fnm_niteshift_pin
  _fnm_niteshift_pin
fi
