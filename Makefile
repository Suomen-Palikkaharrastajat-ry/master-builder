.PHONY:

ELM_PAGES ?= elm-pages
ELM_TAILWIND ?= elm-tailwind-classes
CONTENT_DIR ?= template

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
	bash scripts/fetch-content.sh

.PHONY: sync-assets
sync-assets: ## Copy non-markdown assets from $(CONTENT_DIR) to public/
	@find "$(CONTENT_DIR)" -type f -not -name "*.md" -not -path "*/.git/*" | while IFS= read -r f; do \
		rel="$${f#$(CONTENT_DIR)/}"; \
		dest="public/$$rel"; \
		mkdir -p "$$(dirname "$$dest")"; \
		cp "$$f" "$$dest"; \
	done

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
	cd vendor/design-guide && $(MAKE) dist
	rm -rf vendor/design-tokens/src
	mkdir -p vendor/design-tokens/src
	cp -r vendor/design-guide/dist/design-tokens-elm/src/* vendor/design-tokens/src/
	cp vendor/design-guide/dist/design-tokens-elm/elm.json vendor/design-tokens/elm.json
	@echo "Design tokens updated in vendor/design-tokens/"

# ── Build ────────────────────────────────────────────────────────────────────

.PHONY: dev
dev: ## Start elm-pages dev server (uses local template/)
	$(MAKE) sync-assets
	$(ELM_TAILWIND) gen
	$(ELM_PAGES) dev

.PHONY: watch
watch: ## Start dev server pointed at ./content (CONTENT_DIR=content)
	$(MAKE) CONTENT_DIR=content sync-assets
	$(ELM_TAILWIND) gen
	CONTENT_DIR=content $(ELM_PAGES) dev

.PHONY: build
build: ## Build elm-pages site into dist/ (fetch content first when CONTENT_OWNER/CONTENT_REPO are set)
	bash scripts/fetch-content.sh
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
	bash scripts/smoke-test.sh
