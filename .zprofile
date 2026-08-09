# Symlinked to ~/.zprofile by scripts/link-files.sh (see README).
#
# Login shells only, and sourced AFTER /etc/zprofile. That ordering is the
# whole reason this file exists: /etc/zprofile runs `path_helper`, which
# rebuilds PATH from /etc/paths and /etc/paths.d and demotes fnm's entry
# (set in .zshenv) to the end -- behind /opt/homebrew/bin, which carries a
# `node` as neonctl's dependency.
#
# A login shell that is not interactive (`zsh -l -c ...`, `su -`, some launchd
# jobs) never reaches .zshrc, so re-asserting there alone is not enough.
[[ -n "$FNM_MULTISHELL_PATH" ]] && export PATH="$FNM_MULTISHELL_PATH/bin:$PATH"
