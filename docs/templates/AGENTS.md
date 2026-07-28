# AGENTS.md

Skeleton for a family app repo. Keep the heading order; fill in per-repo detail.
Do **not** copy the design-system token tables here — link to the canonical
source instead (see the Style Guide section).

## Project Overview

<!-- One paragraph: what this repo produces and how it fits the family. -->

## Repository Layout

<!-- Table or tree of the key directories. Follow the standard app layout in
     docs/conventions.md (statics/, elm-app/, assets/, fixtures/, pkgs/, vendor/). -->

## Development Environment

<!-- devenv shell usage; note that `make vendor` must run before `devenv shell`
     so vendor/master-builder (npm-tools, statics-common, etc.) is present. -->

## Build and Test Commands

<!-- Reference the standard Makefile vocabulary from docs/conventions.md. -->

## Code Style

<!-- Elm: elm-format + elm-review (shared LlmAgent rules). Haskell: fourmolu + hlint. -->

## Architecture Notes

## Known Gotchas

## Manual E2E Test Checklist

## Style Guide

The design-system reference (color tokens, typography, logos, WCAG) is the
**single source of truth** in
[`vendor/master-builder/AGENTS.md`](vendor/master-builder/AGENTS.md), section
"Design system". Do not duplicate the token tables here. Machine-readable token
definitions live in the `design-guide` repo's `content/*.toml`.

## Security Considerations

## Git / commit rules

<!-- Conventional Commits. Add per-repo specifics. -->
