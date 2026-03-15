#!/usr/bin/env bash
# fetch-content.sh — Sync the template/ directory from an external content repo.
#
# Environment variables:
#   CONTENT_OWNER   GitHub owner (user or org) of the content repo
#   CONTENT_REPO    GitHub repo name of the content repo
#   CONTENT_REF     Branch/tag/SHA to check out (default: main)
#   CONTENT_PAT     Personal Access Token for private repos (optional)
#   CONTENT_DIR     Subdirectory inside the content repo to use (default: template)
#
# When CONTENT_OWNER and CONTENT_REPO are not set, this script is a no-op so
# that local development with a local template/ directory works without config.
set -euo pipefail

CONTENT_OWNER="${CONTENT_OWNER:-}"
CONTENT_REPO="${CONTENT_REPO:-}"
CONTENT_REF="${CONTENT_REF:-main}"
CONTENT_PAT="${CONTENT_PAT:-}"
CONTENT_DIR="${CONTENT_DIR:-template}"

if [ -z "$CONTENT_OWNER" ] || [ -z "$CONTENT_REPO" ]; then
  echo "fetch-content: CONTENT_OWNER/CONTENT_REPO not set — using local template/ directory."
  exit 0
fi

# Build clone URL (use token for private repos)
if [ -n "$CONTENT_PAT" ]; then
  CLONE_URL="https://${CONTENT_PAT}@github.com/${CONTENT_OWNER}/${CONTENT_REPO}.git"
else
  CLONE_URL="https://github.com/${CONTENT_OWNER}/${CONTENT_REPO}.git"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "fetch-content: cloning ${CONTENT_OWNER}/${CONTENT_REPO}@${CONTENT_REF} ..."
git clone --depth=1 --branch "$CONTENT_REF" --single-branch "$CLONE_URL" "$TMPDIR/content-repo"

SRC="$TMPDIR/content-repo/${CONTENT_DIR}"
if [ ! -d "$SRC" ]; then
  echo "fetch-content: ERROR — directory '${CONTENT_DIR}' not found in ${CONTENT_OWNER}/${CONTENT_REPO}" >&2
  exit 1
fi

DEST="$(dirname "$0")/../template"
DEST="$(realpath "$DEST")"

echo "fetch-content: syncing ${SRC}/ -> ${DEST}/"
rm -rf "$DEST"
cp -r "$SRC" "$DEST"

echo "fetch-content: done. $(find "$DEST" -type f | wc -l | tr -d ' ') files synced."
