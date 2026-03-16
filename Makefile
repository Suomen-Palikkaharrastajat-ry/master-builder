.PHONY:

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

.PHONY: install
install: ## Install npm dependencies
	npm install

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

# ── Build ────────────────────────────────────────────────────────────────────

.PHONY: dev
dev: ## Start elm-pages dev server (uses local template/)
	$(MAKE) sync-assets
	elm-pages dev

.PHONY: watch
watch: ## Start dev server pointed at ./content (CONTENT_DIR=content)
	$(MAKE) CONTENT_DIR=content sync-assets
	CONTENT_DIR=content elm-pages dev

.PHONY: build
build: ## Build elm-pages site into dist/ (fetch content first when CONTENT_OWNER/CONTENT_REPO are set)
	bash scripts/fetch-content.sh
	$(MAKE) sync-assets
	elm-pages build

# ── Deploy ───────────────────────────────────────────────────────────────────

.PHONY: deploy
deploy: ## Commit and push to trigger CI deploy (requires clean working tree)
	git push origin main

.PHONY: test
test: ## Run smoke test against SITE_URL
	bash scripts/smoke-test.sh
