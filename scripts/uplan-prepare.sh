#!/usr/bin/env bash
# uplan-prepare.sh — Gather context for mission planning
# Usage: uplan-prepare.sh ["mission title"]
# Output: JSON with project docs, existing missions, suggested slug

set -uo pipefail

CONFIG_FILE="updoc.config.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check jq
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq_not_found", "detail": "jq is required. Install: brew install jq"}' >&2
  exit 1
fi

source "$SCRIPT_DIR/lib/frontmatter.sh"

if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"error": "config_not_found"}'
  exit 1
fi

TITLE="${1:-}"
CONFIG=$(cat "$CONFIG_FILE")

LANG_DISPLAY=$(echo "$CONFIG" | jq -r '.language.display // "ko"')
LANG_DOCUMENT=$(echo "$CONFIG" | jq -r '.language.document // "en"')
DOCS_PATH=$(echo "$CONFIG" | jq -r '.docs.path // "./updocs"')
PROJECTS_DIR=$(echo "$CONFIG" | jq -r '.docs.projects_dir // "projects"')
MISSIONS_DIR=$(echo "$CONFIG" | jq -r '.docs.missions_dir // "missions"')
PROJECT_COUNT=$(echo "$CONFIG" | jq '.projects | length')

# --- Projects ---

PROJECTS="[]"
if [ "$PROJECT_COUNT" -gt 0 ]; then
for i in $(seq 0 $((PROJECT_COUNT - 1))); do
  NAME=$(echo "$CONFIG" | jq -r ".projects[$i].name")
  OVERVIEW_PATH="$DOCS_PATH/$PROJECTS_DIR/$NAME/overview.md"
  OVERVIEW_EXISTS="false"
  [ -f "$OVERVIEW_PATH" ] && OVERVIEW_EXISTS="true"

  DOMAINS_PATH="$DOCS_PATH/$PROJECTS_DIR/$NAME/domains"
  DOMAINS="[]"
  if [ -d "$DOMAINS_PATH" ]; then
    DOMAIN_FILES=""
    for df in "$DOMAINS_PATH"/*.md; do
      [ -f "$df" ] || continue
      DOMAIN_FILES="$DOMAIN_FILES$(basename "$df" .md)"$'\n'
    done
    if [ -n "$DOMAIN_FILES" ]; then
      DOMAINS=$(echo "$DOMAIN_FILES" | jq -R -s 'split("\n") | map(select(. != ""))')
    fi
  fi

  PROJECTS=$(echo "$PROJECTS" | jq \
    --arg name "$NAME" \
    --arg overview_path "$OVERVIEW_PATH" \
    --argjson overview_exists "$OVERVIEW_EXISTS" \
    --arg domains_path "$DOMAINS_PATH" \
    --argjson domains "$DOMAINS" \
    '. + [{
      name: $name,
      overview_path: $overview_path,
      overview_exists: $overview_exists,
      domains_path: $domains_path,
      domains: $domains
    }]')
done
fi

# --- Product docs ---

PRODUCT_DOCS="[]"
PRODUCT_PATH="$DOCS_PATH/product"
if [ -d "$PRODUCT_PATH" ]; then
  PRODUCT_FILES=""
  while IFS= read -r pf; do
    [ -n "$pf" ] || continue
    PRODUCT_FILES="$PRODUCT_FILES$pf"$'\n'
  done < <(find "$PRODUCT_PATH" -name "*.md" -type f 2>/dev/null)
  if [ -n "$PRODUCT_FILES" ]; then
    PRODUCT_DOCS=$(echo "$PRODUCT_FILES" | jq -R -s 'split("\n") | map(select(. != ""))')
  fi
fi

# --- Missions ---

MISSIONS="[]"
MISSIONS_PATH="$DOCS_PATH/$MISSIONS_DIR"
if [ -d "$MISSIONS_PATH" ]; then
  for mf in "$MISSIONS_PATH"/*.md; do
    [ -f "$mf" ] || continue

    SLUG=$(get_frontmatter_value "$mf" "slug")
    STATUS=$(get_frontmatter_value "$mf" "status")
    [ -z "$SLUG" ] && continue

    MISSIONS=$(echo "$MISSIONS" | jq \
      --arg slug "$SLUG" \
      --arg status "${STATUS:-draft}" \
      --arg path "$mf" \
      '. + [{slug: $slug, status: $status, path: $path}]')
  done
fi

# --- Suggested slug ---

SUGGESTED_SLUG=""
if [ -n "$TITLE" ]; then
  # Convert title to slug: lowercase, spaces to hyphens, remove special chars
  SUGGESTED_SLUG="feat-$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9가-힣-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"
fi

# --- Output ---

jq -n \
  --argjson projects "$PROJECTS" \
  --argjson product_docs "$PRODUCT_DOCS" \
  --argjson missions "$MISSIONS" \
  --arg suggested_slug "$SUGGESTED_SLUG" \
  --arg lang_display "$LANG_DISPLAY" \
  --arg lang_document "$LANG_DOCUMENT" \
  --arg docs_path "$DOCS_PATH" \
  --arg missions_dir "$MISSIONS_DIR" \
  '{
    projects: $projects,
    product_docs: $product_docs,
    missions: $missions,
    suggested_slug: $suggested_slug,
    language: { display: $lang_display, document: $lang_document },
    docs_config: { path: $docs_path, missions_dir: $missions_dir }
  }'
