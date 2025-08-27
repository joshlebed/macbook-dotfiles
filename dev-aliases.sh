#!/usr/bin/env bash
# Portable Development Shell Scripts
# Source this file from ~/.zshrc or ~/.bashrc:
#   source "$PATH_TO_DEV_SHELL_SCRIPTS"/dev_aliases.sh


###############################################################################
# CORE UTILITIES - Repository Detection and Path Management
###############################################################################

# Detect if we're inside a Git repository and return its root
_find_git_repo_from_cwd() {
  local current_dir="$PWD"
  while [[ "$current_dir" != "/" ]]; do
    if [[ -d "$current_dir/.git" ]]; then
      echo "$current_dir"
      return 0
    fi
    current_dir="$(dirname "$current_dir")"
  done
  return 1
}

# Get the repository path (try detection first, fallback to default)
_get_repo_path() {
  local repo_path
  if repo_path=$(_find_git_repo_from_cwd); then
    printf '\e[32m✅ in repo at: %s\e[0m\n' "$repo_path" >&2
    echo "$repo_path"
    return 0
  fi

  printf '\e[33m⚠️  Not currently in a git repo\e[0m\n' >&2
  return 1
}

###############################################################################
# NAVIGATION COMMANDS - Quick directory jumping
###############################################################################

go-to-root-of-current-git-repo() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$git_root" ]]; then
    echo "Failed to get root of current git repo" >&2
    return 1
  fi
  cd "$git_root" || return 1
}

repo() {
  cd "$(_get_repo_path)" || return 1
}

repo-local() {
  cd "$(_get_repo_path)/local" || return 1
}


###############################################################################
# UTILITY ALIASES
###############################################################################

alias claude-danger="claude --dangerously-skip-permissions"
claude-danger-repo() {
  if go-to-root-of-current-git-repo 2>/dev/null; then
    printf '\e[32m✅ navigated to top of git repo at: %s\e[0m\n' "$PWD" >&2
  else
    printf '\e[33m⚠️  Not currently in a git repo\e[0m\n' >&2
    return 1
  fi
  claude-danger "$@"
}
alias cl="claude-danger-repo"
