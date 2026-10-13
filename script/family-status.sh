#!/usr/bin/env bash
# Prints the hub version status of every repository in the family as a
# Markdown table: how each depends on master-builder, which commit it pins and
# how far that is behind the hub's main branch.
#
# usage: script/family-status.sh [--update]
#
#   --update   also rewrite the table between the family-status markers in
#              docs/family.md
#
# Reads other repositories through the GitHub API (the `gh` CLI, which honours
# GH_TOKEN; `--update` also needs python3). A repository the token cannot read
# (competitions is private) is reported as "no access" instead of failing the
# run, but the script stops if it cannot reach GitHub at all, and `--update`
# refuses to write a table that has "no access" rows. Run it from a hub
# checkout with an `origin` remote; the script fetches origin/main.
set -euo pipefail

update=false
for arg in "$@"; do
  case "$arg" in
    --update) update=true ;;
    *) echo "usage: script/family-status.sh [--update]" >&2; exit 2 ;;
  esac
done

ORG="${FAMILY_ORG:-Suomen-Palikkaharrastajat-ry}"
# Repositories that pin the hub as the submodule vendor/master-builder.
SUBMODULE_CONSUMERS="${FAMILY_SUBMODULE_CONSUMERS:-event-calendar service-map planet competitions brick-frame membership-card}"
# Content repositories built by the hub's reusable workflow.
WORKFLOW_CONSUMERS="${FAMILY_WORKFLOW_CONSUMERS:-website guides logo}"

cd "$(dirname "$0")/.."
command -v gh >/dev/null || { echo "family-status: the gh CLI is required" >&2; exit 2; }
# A public repository must be readable; otherwise the token or the network is
# the problem, and every row would wrongly read "no access".
gh api "repos/$ORG/master-builder" --jq .name >/dev/null 2>&1 || {
  echo "family-status: cannot read $ORG/master-builder through the GitHub API; check GH_TOKEN and the network" >&2
  exit 1
}
git fetch --quiet origin main 2>/dev/null || echo "family-status: could not fetch origin/main; counts use the local copy" >&2
have_main=true
git rev-parse --verify --quiet origin/main >/dev/null || have_main=false
today="$(date -u +%Y-%m-%d)"

rows=()
for repo in $SUBMODULE_CONSUMERS; do
  if pin="$(gh api "repos/$ORG/$repo/contents/vendor/master-builder" --jq .sha 2>/dev/null)" && [ -n "$pin" ]; then
    if ! $have_main; then
      behind="unknown (no origin/main here)"
    elif ! git cat-file -e "$pin^{commit}" 2>/dev/null; then
      behind="unknown (pin not in this clone)"
    elif ! git merge-base --is-ancestor "$pin" origin/main; then
      behind="unknown (pin is not on main)"
    else
      behind="$(git rev-list --count "$pin..origin/main")"
    fi
    rows+=("| $repo | submodule \`vendor/master-builder\` | \`${pin:0:7}\` | $behind | $today |")
  else
    rows+=("| $repo | submodule \`vendor/master-builder\` | no access | no access | $today |")
  fi
done
for repo in $WORKFLOW_CONSUMERS; do
  ref=""
  if files="$(gh api "repos/$ORG/$repo/contents/.github/workflows" --jq '.[].name' 2>/dev/null)"; then
    for file in $files; do
      found="$(gh api "repos/$ORG/$repo/contents/.github/workflows/$file" --jq .content 2>/dev/null | base64 -d 2>/dev/null | grep -o 'deploy-content\.yml@[A-Za-z0-9._/-]*' | head -n 1 || true)"
      [ -n "$found" ] && ref="${found#deploy-content.yml@}" && break
    done
    if [ -n "$ref" ]; then
      if [ "$ref" = "main" ]; then
        rows+=("| $repo | workflow \`deploy-content.yml@$ref\` | \`$ref\` (unpinned) | 0 (follows \`$ref\`) | $today |")
      else
        rows+=("| $repo | workflow \`deploy-content.yml@$ref\` | \`$ref\` | see the ref | $today |")
      fi
    else
      rows+=("| $repo | workflow \`deploy-content.yml\` | not found | unknown | $today |")
    fi
  else
    rows+=("| $repo | workflow \`deploy-content.yml\` | no access | no access | $today |")
  fi
done

table="$(
  echo "| Repo | Depends on hub via | Pinned commit | Commits behind main | Checked on |"
  echo "|---|---|---|---|---|"
  printf '%s\n' "${rows[@]}"
)"
echo "$table"

if $update; then
  if printf '%s\n' "${rows[@]}" | grep -q "no access"; then
    echo "family-status: not updating docs/family.md: some repositories could not be read" >&2
    exit 1
  fi
  command -v python3 >/dev/null || { echo "family-status: --update needs python3" >&2; exit 2; }
  doc="docs/family.md"
  start='<!-- family-status:start -->'
  end='<!-- family-status:end -->'
  grep -q "$start" "$doc" || { echo "family-status: $doc has no status markers" >&2; exit 1; }
  FAMILY_TABLE="$table" python3 - "$doc" "$start" "$end" <<'PY'
import os, sys
path, start, end = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
head, rest = text.split(start, 1)
_, tail = rest.split(end, 1)
open(path, "w", encoding="utf-8").write(head + start + "\n" + os.environ["FAMILY_TABLE"] + "\n" + end + tail)
PY
  echo "family-status: updated $doc" >&2
fi
