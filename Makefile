ELM_PAGES ?= elm-pages
ELM_TAILWIND ?= elm-tailwind-classes
CONTENT_DIR ?= template

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ── Development environment ──────────────────────────────────────────────────

.PHONY: shell
shell: ## Enter devenv shell
	devenv shell

.PHONY: develop
develop: devenv.local.nix devenv.local.yaml ## Bootstrap opinionated development environment
	devenv shell --profile=devcontainer -- code .

devenv.local.nix:
	cp devenv.local.nix.example devenv.local.nix

devenv.local.yaml:
	cp devenv.local.yaml.example devenv.local.yaml

# ── Content ──────────────────────────────────────────────────────────────────

.PHONY: fetch-content
fetch-content: ## Sync content/ from external repo (set CONTENT_OWNER, CONTENT_REPO, CONTENT_REF)
	bash deploy/fetch-content.sh

.PHONY: sync-assets
sync-assets: ## Copy non-markdown assets from $(CONTENT_DIR) to public/
	@find "$(CONTENT_DIR)" -type f -not -name "*.md" -not -path "*/.git/*" -not -path "*/reference/*" | while IFS= read -r f; do \
		rel="$${f#$(CONTENT_DIR)/}"; \
		dest="public/$$rel"; \
		mkdir -p "$$(dirname "$$dest")"; \
		cp "$$f" "$$dest"; \
	done
	@if [ -d "$(CONTENT_DIR)/public" ]; then \
		cp -r "$(CONTENT_DIR)/public/." public/; \
	fi

# ── Clean ────────────────────────────────────────────────────────────────────

.PHONY: clean
clean: ## Remove build artifacts (dist/, elm-stuff/, .elm-pages/, gen/, .elm-tailwind/)
	rm -rf dist elm-stuff .elm-pages gen .elm-tailwind

# ── Vendor / submodules ──────────────────────────────────────────────────────

.PHONY: vendor
vendor: ## Init and update all git submodules to their pinned commits
	@# In CI environments (GitHub Actions, Netlify) SSH access is unavailable;
	@# rewrite git@github.com: to https://github.com/ so submodules clone via HTTPS.
	@[ -z "$$CI" ] || git config --global url."https://github.com/".insteadOf "git@github.com:"
	git submodule update --init --recursive

.PHONY: design-tokens
design-tokens: ## Regenerate design tokens from vendor/design-guide (requires submodule checkout)
	cd vendor/design-guide && devenv shell -- $(MAKE) dist
	rm -rf vendor/design-tokens/src
	mkdir -p vendor/design-tokens/src
	cp -r vendor/design-guide/dist/design-tokens-elm/src/* vendor/design-tokens/src/
	cp vendor/design-guide/dist/design-tokens-elm/elm.json vendor/design-tokens/elm.json
	@echo "Design tokens updated in vendor/design-tokens/"

# ── Build ────────────────────────────────────────────────────────────────────

# ESM `import` (used by elm-pages.config.mjs) does not respect NODE_PATH —
# only CJS `require()` does. Creating a node_modules symlink pointing at the
# Nix store tree lets Node's standard module resolution find the packages.
# NODE_PATH is set by devenv (env.NODE_PATH) and flake.nix (shellHook) to the
# npmTools derivation's lib/node_modules directory.
.PHONY: node_modules
node_modules: ## Symlink node_modules → Nix store (requires NODE_PATH from devenv/nix develop)
	@[ -n "$$NODE_PATH" ] && { [ -L node_modules ] || rm -rf node_modules; \
	  ln -sfn "$$(echo "$$NODE_PATH" | cut -d: -f1)" node_modules; } \
	  || echo "node_modules: NODE_PATH not set, skipping symlink"

.PHONY: dev
dev: node_modules ## Start elm-pages dev server (uses local template/)
	$(MAKE) sync-assets
	$(ELM_TAILWIND) gen
	$(ELM_PAGES) dev

.PHONY: watch
watch: node_modules ## Start dev server pointed at ./content (CONTENT_DIR=content)
	$(MAKE) CONTENT_DIR=content sync-assets
	$(ELM_TAILWIND) gen
	CONTENT_DIR=content $(ELM_PAGES) dev

.PHONY: build
build: node_modules ## Build elm-pages site into dist/ (fetch content first when CONTENT_OWNER/CONTENT_REPO are set)
	bash deploy/fetch-content.sh
	$(MAKE) sync-assets
	$(MAKE) CONTENT_DIR=content sync-assets
	$(ELM_TAILWIND) gen
	$(ELM_PAGES) build

.PHONY: all
all: clean build ## Clean and rebuild everything

# ── Deploy ───────────────────────────────────────────────────────────────────

.PHONY: deploy
deploy: ## Commit and push to trigger CI deploy (requires clean working tree)
	git push origin main

.PHONY: check
check: ## Check Elm formatting and elm-review rules (no changes)
	elm-format --validate app/ src/
	elm-review --config review

.PHONY: format
format: ## Auto-format Elm source files
	elm-format --yes app/ src/

.PHONY: test
test: ## Run smoke test against SITE_URL
	bash deploy/smoke-test.sh
