---
name: push
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*)
description: Write a smart commit message and push to remote
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes:

1. Stage all changed files with `git add -A`
2. Write a concise, descriptive commit message that summarizes what changed and why. Use conventional commit style (e.g. `feat:`, `fix:`, `refactor:`, `chore:`). The message should be specific — not generic like "update files".
3. Commit the changes
4. Push the current branch to origin

You MUST do all of the above in a single message. Do not use any other tools or do anything else. If there are no changes to commit, just say so.
