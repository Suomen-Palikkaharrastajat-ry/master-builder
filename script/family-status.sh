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
# GH_TOKEN). A repository the token cannot read (competitions is private) is
# reported as "no access" instead of failing the run. Run it from a hub
# checkout whose origin/main is up to date; the script fetches it.
set -euo pipefail

ORG="${FAMILY_ORG:-Suomen-Palikkaharrastajat-ry}"
# Repositories that pin the hub as the submodule vendor/master-builder.
SUBMODULE_CONSUMERS="${FAMILY_SUBMODULE_CONSUMERS:-event-calendar service-map planet competitions brick-frame membership-card}"
# Content repositories built by the hub's reusable workflow.
WORKFLOW_CONSUMERS="${FAMILY_WORKFLOW_CONSUMERS:-website guides logo}"

cd "$(dirname "$0")/.."
command -v gh >/dev/null || { echo "family-status: the gh CLI is required" >&2; exit 2; }
git fetch --quiet origin main 2>/dev/null || echo "family-status: could not fetch origin/main; counts use the local copy" >&2
today="$(date -u +%Y-%m-%d)"

rows=()
for repo in $SUBMODULE_CONSUMERS; do
  if pin="$(gh api "repos/$ORG/$repo/contents/vendor/master-builder" --jq .sha 2>/dev/null)" && [ -n "$pin" ]; then
    if git cat-file -e "$pin^{commit}" 2>/dev/null; then
      behind="$(git rev-list --count "$pin..origin/main")"
    else
      behind="unknown (pin not in this clone)"
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
      rows+=("| $repo | workflow \`deploy-content.yml@$ref\` | \`$ref\` (unpinned) | 0 (follows \`$ref\`) | $today |")
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

if [ "${1:-}" = "--update" ]; then
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
