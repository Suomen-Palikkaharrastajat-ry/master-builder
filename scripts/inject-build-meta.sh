#!/usr/bin/env bash
set -euo pipefail

SHA="${GITHUB_SHA:-local}"
RUN_ID="${GITHUB_RUN_ID:-0}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Detect owner/repo from the git remote or from the CI env var
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
  OWNER="${GITHUB_REPOSITORY%%/*}"
  REPO="${GITHUB_REPOSITORY##*/}"
else
  REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
  # Handle both SSH (git@github.com:owner/repo.git) and HTTPS
  OWNER=$(echo "$REMOTE" | sed 's|.*[:/]\([^/]*\)/[^/]*\.git|\1|')
  REPO=$(echo "$REMOTE"  | sed 's|.*/\([^/]*\)\.git|\1|')
fi

OAUTH_CLIENT_ID="${OAUTH_CLIENT_ID:-}"
OAUTH_PROXY_URL="${OAUTH_PROXY_URL:-}"

# Content repo — defaults to the code repo when not explicitly set
CONTENT_OWNER="${CONTENT_OWNER:-$OWNER}"
CONTENT_REPO="${CONTENT_REPO:-$REPO}"

# Detect if repo is private via gh CLI (returns "true" or "false")
IS_PRIVATE=$(gh repo view "${GITHUB_REPOSITORY:-}" --json isPrivate -q .isPrivate 2>/dev/null || echo "false")
REPO_SCOPE="public_repo"
if [ "$IS_PRIVATE" = "true" ]; then
  REPO_SCOPE="repo"
fi

cat > public/site-config.json <<EOF
{
  "buildSha": "$SHA",
  "buildTimestamp": "$TIMESTAMP",
  "runId": "$RUN_ID",
  "owner": "$OWNER",
  "repo": "$REPO",
  "contentOwner": "$CONTENT_OWNER",
  "contentRepo": "$CONTENT_REPO",
  "oauthClientId": "$OAUTH_CLIENT_ID",
  "oauthProxyUrl": "$OAUTH_PROXY_URL",
  "repoScope": "$REPO_SCOPE"
}
EOF

echo "site-config.json written: sha=$SHA ts=$TIMESTAMP owner=$OWNER repo=$REPO contentOwner=$CONTENT_OWNER contentRepo=$CONTENT_REPO"
