#!/usr/bin/env bash
# session-start.sh — Display updoc project status at session start
# Reads updoc.config.yaml from cwd and outputs status summary.

CONFIG_FILE="updoc.config.yaml"

# Exit silently if no config
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

# Check yq
if ! command -v yq &>/dev/null; then
  exit 0
fi

CONFIG=$(cat "$CONFIG_FILE")
VERSION=$(echo "$CONFIG" | yq '.version // "0.1.0"')
LANGUAGE=$(echo "$CONFIG" | yq '.language // "en"')
PROJECT_COUNT=$(echo "$CONFIG" | yq '.projects | length')
DOCS_PATH=$(echo "$CONFIG" | yq '.docs.path // "./docs"')
PROJECTS_DIR=$(echo "$CONFIG" | yq '.docs.projects_dir // "projects"')

# Count synced projects and get last sync info from docs frontmatter
SYNCED_COUNT=0
LAST_SYNC_DATE=""
LAST_SYNC_COMMIT=""

for i in $(seq 0 $((PROJECT_COUNT - 1))); do
  NAME=$(echo "$CONFIG" | yq ".projects[$i].name")
  OVERVIEW="${DOCS_PATH}/${PROJECTS_DIR}/${NAME}/overview.md"
  if [ -f "$OVERVIEW" ]; then
    COMMIT=$(yq --front-matter=extract '.synced_from' "$OVERVIEW" 2>/dev/null || echo "")
    DATE=$(yq --front-matter=extract '.synced_at' "$OVERVIEW" 2>/dev/null || echo "")
    if [ -n "$COMMIT" ] && [ "$COMMIT" != "null" ]; then
      SYNCED_COUNT=$((SYNCED_COUNT + 1))
      if [ -n "$DATE" ] && [ "$DATE" != "null" ]; then
        if [ -z "$LAST_SYNC_DATE" ] || [[ "$DATE" > "$LAST_SYNC_DATE" ]]; then
          LAST_SYNC_DATE="$DATE"
          LAST_SYNC_COMMIT="$COMMIT"
        fi
      fi
    fi
  fi
done

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
