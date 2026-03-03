#!/usr/bin/env bash
# update-sync-state.sh — Update project sync state in updoc.config.json
# Usage: update-sync-state.sh PROJECT_NAME COMMIT_HASH [PROJECT_TYPE]

set -uo pipefail

CONFIG_FILE="updoc.config.json"

# Check jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install: brew install jq" >&2
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: update-sync-state.sh PROJECT_NAME COMMIT_HASH [PROJECT_TYPE]" >&2
  exit 1
fi

PROJECT_NAME="$1"
COMMIT_HASH="$2"
PROJECT_TYPE="${3:-}"
SYNC_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found" >&2
  exit 1
fi

# Verify project exists
PROJECT_EXISTS=$(jq --arg name "$PROJECT_NAME" '[.projects[] | select(.name == $name)] | length' "$CONFIG_FILE")
if [ "$PROJECT_EXISTS" -eq 0 ]; then
  echo "Error: project '$PROJECT_NAME' not found in $CONFIG_FILE" >&2
  exit 1
fi

# Build jq filter
if [ -n "$PROJECT_TYPE" ]; then
  jq \
    --arg name "$PROJECT_NAME" \
    --arg commit "$COMMIT_HASH" \
    --arg date "$SYNC_DATE" \
    --arg type "$PROJECT_TYPE" \
    '.projects = [.projects[] | if .name == $name then
      .last_sync_commit = $commit |
      .last_sync_date = $date |
      .type = $type
    else . end]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
else
  jq \
    --arg name "$PROJECT_NAME" \
    --arg commit "$COMMIT_HASH" \
    --arg date "$SYNC_DATE" \
    '.projects = [.projects[] | if .name == $name then
      .last_sync_commit = $commit |
      .last_sync_date = $date
    else . end]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
fi

mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
echo "Updated sync state for $PROJECT_NAME: commit=$COMMIT_HASH, date=$SYNC_DATE" >&2
