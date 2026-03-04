#!/usr/bin/env bash
# session-start.sh — Display updoc project status at session start
# Reads updoc.config.json from cwd and outputs status summary.

CONFIG_FILE="updoc.config.json"

# Exit silently if no config
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

# Check jq
if ! command -v jq &>/dev/null; then
  exit 0
fi

CONFIG=$(cat "$CONFIG_FILE")
VERSION=$(echo "$CONFIG" | jq -r '.version // "0.1.0"')
LANGUAGE=$(echo "$CONFIG" | jq -r '.language // "en"')
PROJECT_COUNT=$(echo "$CONFIG" | jq '.projects | length')

# Count synced projects
SYNCED_COUNT=$(echo "$CONFIG" | jq '[.projects[] | select(.last_sync_commit != null)] | length')

# Get last sync info
LAST_SYNC_DATE=$(echo "$CONFIG" | jq -r '[.projects[] | select(.last_sync_date != null) | .last_sync_date] | sort | last // empty')
LAST_SYNC_COMMIT=$(echo "$CONFIG" | jq -r '[.projects[] | select(.last_sync_commit != null)] | last | .last_sync_commit // empty')

# --- Output ---

if [ "$LANGUAGE" = "en" ]; then
  echo ""
  echo "📋 updoc v${VERSION}"
  echo "Projects: ${PROJECT_COUNT} registered / ${SYNCED_COUNT} synced"
  if [ -n "$LAST_SYNC_DATE" ]; then
    echo "Last sync: ${LAST_SYNC_DATE} (${LAST_SYNC_COMMIT})"
  fi
  echo ""
  echo "💡 /updoc:up — Update docs  |  /updoc:uplan — Start planning"
else
  echo ""
  echo "📋 updoc v${VERSION}"
  echo "프로젝트: ${PROJECT_COUNT}개 등록 / ${SYNCED_COUNT}개 동기화 완료"
  if [ -n "$LAST_SYNC_DATE" ]; then
    echo "마지막 동기화: ${LAST_SYNC_DATE} (${LAST_SYNC_COMMIT})"
  fi
  echo ""
  echo "💡 /updoc:up — 문서 갱신  |  /updoc:uplan — 기획 시작"
fi
