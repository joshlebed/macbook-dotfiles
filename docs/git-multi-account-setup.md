# Git Multi-Account Setup

This setup allows seamless use of both work and personal GitHub accounts. Just
use normal `git clone` commands — the correct SSH key and commit email are
selected automatically based on the repo owner.

## How It Works

Three files work together:

**1. `~/.ssh/config`** — Defines SSH host aliases with different keys

```
# Work (default)
Host github.com
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519          # work key

# Personal
Host github-personal
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_personal # personal key
```

**2. `~/.gitconfig`** — Conditionally loads personal config based on remote URL

```gitconfig
[user]
    name = Josh Lebedinsky
    email = josh.lebedinsky@keru.ai          # work email (default)

[includeIf "hasconfig:remote.*.url:*github.com:joshlebed/*"]
    path = ~/.gitconfig-personal
```

**3. `~/.gitconfig-personal`** — Personal email + URL rewriting

```gitconfig
[user]
    email = joshlebed@gmail.com

[url "git@github-personal:joshlebed/"]
    insteadOf = git@github.com:joshlebed/
```

## The Flow

When you run `git clone git@github.com:joshlebed/repo.git`:

```
git clone git@github.com:joshlebed/repo.git
                    ↓
    hasconfig:remote.*.url matches "joshlebed"
                    ↓
    loads ~/.gitconfig-personal
                    ↓
    insteadOf rewrites URL to git@github-personal:joshlebed/repo.git
                    ↓
    SSH sees "github-personal" host, uses personal key
                    ↓
    authenticates to github.com as joshlebed
```

## Examples

```bash
# Personal repos — auto-detected, uses personal key + email
git clone git@github.com:joshlebed/my-project.git
git clone git@github.com:clobraico22/lib-sync.git

# Work repos — uses work key + email (default)
git clone git@github.com:keru-ai/backend.git

# Commits in personal repos automatically use personal email
cd ~/code/my-project
git commit -m "fix bug"  # author: joshlebed@gmail.com

# Commits in work repos use work email
cd ~/code/backend
git commit -m "fix bug"  # author: josh.lebedinsky@keru.ai
```

## Adding More Personal Accounts

To add another GitHub username to use the personal key, add to
`~/.gitconfig-personal`:

```gitconfig
[url "git@github-personal:friend-username/"]
    insteadOf = git@github.com:friend-username/
```

And add the pattern to `~/.gitconfig`:

```gitconfig
[includeIf "hasconfig:remote.*.url:*github.com:friend-username/*"]
    path = ~/.gitconfig-personal
```
