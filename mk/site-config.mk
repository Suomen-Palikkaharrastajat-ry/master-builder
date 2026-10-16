# Shared make targets for a site's config.toml.
#
# Include from an app's Makefile, after setting what differs:
#
#   SITE_CONFIG_HASKELL := statics/src/SiteConfig.hs   # leave unset without a Haskell generator
#   SITE_CONFIG_I18N    := elm-app/src elm-app/main.js statics/src statics/app
#   include vendor/master-builder/mk/site-config.mk
#
# config.toml is the single source of the site's URL, title, text and settings
# (see docs/site-config.md). Vite reads it directly; the files these targets
# write are derived from it and committed.

SITE_CONFIG ?= vendor/master-builder/packages/site-config
SITE_CONFIG_FIXTURE ?= elm-app/tests/SiteFixture.elm
SITE_CONFIG_I18N ?= elm-app/src elm-app/main.js

# What a build that reads config.toml depends on, including the hub's shared fonts.
SITE_CONFIG_DEPS := config.toml $(SITE_CONFIG)/family.toml $(wildcard $(SITE_CONFIG)/*.mjs) $(wildcard $(SITE_CONFIG)/../../public/fonts/*)

.PHONY: site-config
site-config: ## Regenerate the files derived from config.toml
	node $(SITE_CONFIG)/gen-fixture.mjs --config config.toml --out $(SITE_CONFIG_FIXTURE)
ifdef SITE_CONFIG_HASKELL
	node $(SITE_CONFIG)/gen-haskell.mjs --config config.toml --out $(SITE_CONFIG_HASKELL)
endif

.PHONY: site-config-check
site-config-check: ## Check config.toml, its derived files, and that display text stays in translations
	node $(SITE_CONFIG)/gen-fixture.mjs --config config.toml --out $(SITE_CONFIG_FIXTURE) --check
ifdef SITE_CONFIG_HASKELL
	node $(SITE_CONFIG)/gen-haskell.mjs --config config.toml --out $(SITE_CONFIG_HASKELL) --check
endif
	node $(SITE_CONFIG)/../../script/check-i18n.mjs $(SITE_CONFIG_I18N)
