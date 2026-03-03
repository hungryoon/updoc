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
DOCS_PATH=$(echo "$CONFIG" | jq -r '.docs.path // "./updocs"')
MISSIONS_DIR=$(echo "$CONFIG" | jq -r '.docs.missions_dir // "missions"')

# Count synced projects
SYNCED_COUNT=$(echo "$CONFIG" | jq '[.projects[] | select(.last_sync_commit != null)] | length')

# Get last sync info
LAST_SYNC_DATE=$(echo "$CONFIG" | jq -r '[.projects[] | select(.last_sync_date != null) | .last_sync_date] | sort | last // empty')
LAST_SYNC_COMMIT=$(echo "$CONFIG" | jq -r '[.projects[] | select(.last_sync_commit != null)] | last | .last_sync_commit // empty')

# Find active missions
MISSIONS_PATH="$DOCS_PATH/$MISSIONS_DIR"
ACTIVE_MISSIONS_EN=""
ACTIVE_MISSIONS_KO=""
if [ -d "$MISSIONS_PATH" ]; then
  for f in "$MISSIONS_PATH"/*.md; do
    [ -f "$f" ] || continue
    STATUS=$(sed -n '/^---$/,/^---$/p' "$f" | grep "^status:" | sed 's/^status:[[:space:]]*//' | head -1)
    if [ "$STATUS" != "done" ] && [ -n "$STATUS" ]; then
      SLUG=$(sed -n '/^---$/,/^---$/p' "$f" | grep "^slug:" | sed 's/^slug:[[:space:]]*//' | head -1)
      BRANCH=$(sed -n '/^---$/,/^---$/p' "$f" | grep "^branch:" | sed 's/^branch:[[:space:]]*//' | head -1)
      if [ -n "$SLUG" ]; then
        ACTIVE_MISSIONS_EN="$ACTIVE_MISSIONS_EN  - $SLUG ($STATUS"
        ACTIVE_MISSIONS_KO="$ACTIVE_MISSIONS_KO  - $SLUG ($STATUS"
        if [ -n "$BRANCH" ]; then
          ACTIVE_MISSIONS_EN="$ACTIVE_MISSIONS_EN, branch: $BRANCH"
          ACTIVE_MISSIONS_KO="$ACTIVE_MISSIONS_KO, 브랜치: $BRANCH"
        fi
        ACTIVE_MISSIONS_EN="$ACTIVE_MISSIONS_EN)\n"
        ACTIVE_MISSIONS_KO="$ACTIVE_MISSIONS_KO)\n"
      fi
    fi
  done
fi

# --- Output ---

if [ "$LANGUAGE" = "en" ]; then
  echo ""
  echo "📋 updoc v${VERSION}"
  echo "Projects: ${PROJECT_COUNT} registered / ${SYNCED_COUNT} synced"
  if [ -n "$LAST_SYNC_DATE" ]; then
    echo "Last sync: ${LAST_SYNC_DATE} (${LAST_SYNC_COMMIT})"
  fi
  if [ -n "$ACTIVE_MISSIONS_EN" ]; then
    echo ""
    echo "⚡ Active missions:"
    printf "$ACTIVE_MISSIONS_EN"
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
  if [ -n "$ACTIVE_MISSIONS_KO" ]; then
    echo ""
    echo "⚡ 진행 중 미션:"
    printf "$ACTIVE_MISSIONS_KO"
  fi
  echo ""
  echo "💡 /updoc:up — 문서 갱신  |  /updoc:uplan — 기획 시작"
fi
