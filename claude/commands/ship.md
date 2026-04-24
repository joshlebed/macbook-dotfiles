---
name: ship
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(gh pr create:*), Bash(gh pr merge:*), Bash(git pull:*)
description: Commit, push, open a PR, squash-merge, and clean up
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes:

1. Create a new branch (prefixed with `josh/`) if on main
2. Create a single commit with an appropriate message
3. Push the branch to origin
4. Create a pull request using `gh pr create`
5. Squash-merge the PR using `gh pr merge --squash --delete-branch`
6. Checkout main and pull: `git checkout main && git pull`

You MUST do all of the above in a single message. Do not use any other tools or do anything else.
