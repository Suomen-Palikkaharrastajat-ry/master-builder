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

node_modules: package.json package-lock.json
	npm install
	@touch node_modules

.PHONY: install
install: node_modules ## Install npm dependencies

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

.PHONY: sync-fonts
sync-fonts: ## Copy font files from vendor/design-guide/fonts/ to public/fonts/
	@mkdir -p public/fonts
	@find vendor/design-guide/fonts -maxdepth 1 -name "*.ttf" | while IFS= read -r f; do \
		cp "$$f" "public/fonts/$$(basename "$$f")"; \
	done

# ── Clean ────────────────────────────────────────────────────────────────────

.PHONY: clean
clean: ## Remove build artifacts (dist/, elm-stuff/, .elm-pages/, gen/)
	rm -rf dist elm-stuff .elm-pages gen

# ── Vendor / submodules ──────────────────────────────────────────────────────

.PHONY: vendor
vendor: ## Init and update all git submodules to their pinned commits
	@# In CI environments (GitHub Actions, Netlify) SSH access is unavailable;
	@# rewrite git@github.com: to https://github.com/ so submodules clone via HTTPS.
	@[ -z "$$CI" ] || git config --global url."https://github.com/".insteadOf "git@github.com:"
	git submodule update --init --recursive

# ── Build ────────────────────────────────────────────────────────────────────

.PHONY: dev
dev: vendor ## Start elm-pages dev server (uses local template/)
	$(MAKE) sync-assets
	$(MAKE) sync-fonts
	elm-pages dev

.PHONY: watch
watch: vendor ## Start dev server pointed at ./content (CONTENT_DIR=content)
	$(MAKE) CONTENT_DIR=content sync-assets
	$(MAKE) sync-fonts
	CONTENT_DIR=content elm-pages dev

.PHONY: build-admin
build-admin: node_modules ## Build standalone admin app into public/admin/
	mkdir -p public/admin
	cd admin-app && npx elm-optimize-level-2 src/Main.elm --output elm.js
	cp admin-app/elm.js public/admin/elm.js
	./node_modules/.bin/esbuild admin-app/main.js --bundle --minify --outfile=public/admin/main.js
	cp admin-app/index.html public/admin/index.html

.PHONY: build
build: vendor ## Build elm-pages site into dist/ (fetch content first when CONTENT_OWNER/CONTENT_REPO are set)
	bash scripts/fetch-content.sh
	$(MAKE) sync-assets
	$(MAKE) CONTENT_DIR=content sync-assets
	$(MAKE) sync-fonts
	$(MAKE) build-admin
	elm-pages build

# ── Deploy ───────────────────────────────────────────────────────────────────

.PHONY: deploy
deploy: ## Commit and push to trigger CI deploy (requires clean working tree)
	git push origin main

.PHONY: check
check: ## Check Elm formatting (no changes)
	elm-format --validate app/ src/

.PHONY: format
format: ## Auto-format Elm source files
	elm-format --yes app/ src/

.PHONY: test
test: ## Run smoke test against SITE_URL
	bash scripts/smoke-test.sh
