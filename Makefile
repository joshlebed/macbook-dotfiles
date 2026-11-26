# Operator entry point for this repo. `make` lists every target.
#
# Deliberately thin: each target is one call into scripts/, karabiner/ or
# raycast/, which is where the logic and the reasoning live. Running those
# directly is always equivalent.
#
#   make link ARGS=--dry-run    ARGS is appended to the underlying script call
#   make -C ~/.config check     run from any directory
#
# Written for the GNU Make 3.81 that macOS ships — no 4.x features.

.DEFAULT_GOAL := help

# Formatter scope: hand-written docs and JS only. Left out on purpose —
#   config/*.yaml       link-files.sh and export-preferences.sh read these line
#                       by line in bash, not with a YAML parser, so layout matters
#   vscode/, zed/, ...  app-owned config; the apps rewrite it themselves
#   generated JSON      karabiner.json and _quicklinks.json have their own
#                       formatter (utils.js next to each)
PRETTIER       ?= pnpm dlx prettier@3
PRETTIER_GLOBS := '*.md' 'eslint.config.js' '.hammerspoon/*.md' \
	'karabiner/*.{js,md}' 'raycast/*.md' 'raycast/quicklinks/*.js'

# Aggregates run every member even after one fails (-k), so a single run reports
# everything. ARGS is cleared: it is meant for one script, not all of them.
run_all = @$(MAKE) --no-print-directory -k ARGS=

# Installs only when node_modules is missing or older than its lockfile.
%/node_modules: %/pnpm-lock.yaml
	cd $* && pnpm install --frozen-lockfile
	@touch $@

##@ Generated files

.PHONY: build
build: raycast-text karabiner quicklinks ## Regenerate all three generated outputs

.PHONY: check
check: ## Verify all three are up to date (writes nothing)
	$(run_all) raycast-text-check karabiner-check quicklinks-check

.PHONY: raycast-text
raycast-text: ## raycast/text/*.txt -> Raycast paste commands
	./scripts/build-raycast-text-paste-scripts.py

.PHONY: raycast-text-check
raycast-text-check: ## Verify the paste commands match their sources
	./scripts/build-raycast-text-paste-scripts.py --check

.PHONY: karabiner
karabiner: karabiner/node_modules ## karabiner.js -> karabiner.json, once
	cd karabiner && node karabiner-config-builder.js

.PHONY: karabiner-watch
karabiner-watch: karabiner/node_modules ## Same, rebuilding on every save
	cd karabiner && node karabiner-file-watcher.js

.PHONY: karabiner-check
karabiner-check: karabiner/node_modules ## Verify karabiner.json matches karabiner.js
	cd karabiner && node karabiner-config-builder.js --check

.PHONY: quicklinks
quicklinks: raycast/quicklinks/node_modules ## quicklinks-generator.js -> _quicklinks.json, once
	cd raycast/quicklinks && node quicklinks-config-builder.js

.PHONY: quicklinks-watch
quicklinks-watch: raycast/quicklinks/node_modules ## Same, rebuilding on every save
	cd raycast/quicklinks && node quicklinks-file-watcher.js

.PHONY: quicklinks-check
quicklinks-check: raycast/quicklinks/node_modules ## Verify _quicklinks.json matches its generator
	cd raycast/quicklinks && node quicklinks-config-builder.js --check

##@ Formatting

.PHONY: format
format: karabiner-format ## Prettier over hand-written docs and JS, plus karabiner-format
	$(PRETTIER) --write $(PRETTIER_GLOBS)

.PHONY: format-check
format-check: ## List files prettier would change (writes nothing)
	$(PRETTIER) --check $(PRETTIER_GLOBS)

.PHONY: karabiner-format
karabiner-format: karabiner/node_modules ## Re-sort karabiner.json in place, keeping edits made in the Karabiner UI
	cd karabiner && node config-formatter.js

##@ Repo -> this machine

.PHONY: setup
setup: ## Full macOS setup (ARGS=--dry-run | --skip-brew | --skip-apps)
	./scripts/setup-macos.sh $(ARGS)

.PHONY: link
link: ## Apply config/file-mappings.yaml: symlinks, copies, plists (ARGS=--dry-run)
	./scripts/link-files.sh $(ARGS)

.PHONY: brew
brew: ## Install everything in the Brewfile (ARGS=--skip-apps)
	./scripts/brew_install_all.sh $(ARGS)

.PHONY: extensions
extensions: ## Install the tracked VS Code and Cursor extensions
	./scripts/editor-extensions.sh --install

.PHONY: macos-defaults
macos-defaults: ## Apply macOS system defaults (ARGS=--dry-run)
	./scripts/apply-macos-defaults.sh $(ARGS)

.PHONY: login-items
login-items: ## Apply config/login-items.yaml
	./scripts/login-items.sh --apply

.PHONY: git-identity
git-identity: ## SSH key + GitHub auth for a new machine (ARGS=--dry-run)
	./scripts/bootstrap-git-identity.sh $(ARGS)

##@ This machine -> repo

.PHONY: prefs-export
prefs-export: ## Capture app preferences into preferences/ (ARGS=--dry-run)
	./scripts/export-preferences.sh $(ARGS)

.PHONY: extensions-export
extensions-export: ## Capture installed editor extensions into vscode/
	./scripts/editor-extensions.sh --export

.PHONY: login-items-export
login-items-export: ## Capture login items into config/login-items.yaml
	./scripts/login-items.sh --export

##@ Drift between this machine and the repo (read-only)

.PHONY: drift
drift: ## Run every check below
	$(run_all) link-check prefs-check brew-audit extensions-check macos-defaults-check login-items-check

.PHONY: verify
verify: ## Overall environment health (ARGS=--quick)
	./scripts/verify-setup.sh $(ARGS)

.PHONY: link-check
link-check: ## Symlinks, copies and plists vs config/file-mappings.yaml
	./scripts/link-files.sh --verify

.PHONY: prefs-check
prefs-check: ## App preferences vs preferences/ (ARGS=-v lists stripped churn keys)
	./scripts/export-preferences.sh --check $(ARGS)

.PHONY: brew-audit
brew-audit: ## Installed Homebrew packages vs the Brewfile
	./scripts/audit-brew.sh $(ARGS)

.PHONY: extensions-check
extensions-check: ## Installed editor extensions vs the tracked lists
	./scripts/editor-extensions.sh --check

.PHONY: macos-defaults-check
macos-defaults-check: ## macOS system defaults vs apply-macos-defaults.sh
	./scripts/apply-macos-defaults.sh --check

.PHONY: login-items-check
login-items-check: ## Login items vs config/login-items.yaml
	./scripts/login-items.sh --check

##@ Misc

.PHONY: clear-notifications
clear-notifications: ## Clear every macOS notification
	./scripts/clear-notifications.sh

.PHONY: help
help: ## List targets
	@echo 'Usage: make <target> [ARGS="flags for the underlying script"]'
	@awk -F ':.*## ' ' \
		/^##@ / { printf "\n%s\n", substr($$0, 5); next } \
		/^[a-zA-Z0-9_-]+:.*## / { printf "  %-22s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
