## Screenshot Annotator — Firefox WebExtension build
##
## Usage:
##   make dist   — build .xpi package into web-ext-artifacts/
##   make lint   — lint extension with web-ext
##   make clean  — remove build artifacts

SRC_DIR      := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ARTIFACTS    := $(SRC_DIR)web-ext-artifacts

# Run web-ext via nix without installing it permanently.
# Requires nix with flakes enabled (already available in this devenv).
WEB_EXT      := nix run nixpkgs\#web-ext --

# Files to exclude from the .xpi (web-ext also respects .gitignore)
IGNORE_FILES := Makefile web-ext-artifacts

.PHONY: dist lint clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

dist: ## Build .xpi side-loadable extension package
	$(WEB_EXT) build \
		--source-dir "$(SRC_DIR)" \
		--artifacts-dir "$(ARTIFACTS)" \
		--ignore-files $(IGNORE_FILES) \
		--overwrite-dest
	@# web-ext outputs .zip; rename to the conventional .xpi extension
	@cd "$(ARTIFACTS)" && \
		for f in *.zip; do mv "$$f" "$${f%.zip}.xpi"; done
	@echo ""
	@echo "Side-load in Firefox:"
	@echo "  about:debugging → This Firefox → Load Temporary Add-on"
	@echo "  → pick: $(ARTIFACTS)/*.xpi"

lint: ## Lint extension sources with web-ext
	$(WEB_EXT) lint \
		--source-dir "$(SRC_DIR)" \
		--ignore-files $(IGNORE_FILES)

clean: ## Remove build artifacts
	rm -rf "$(ARTIFACTS)"
