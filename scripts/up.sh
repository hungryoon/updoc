#!/usr/bin/env bash
# up.sh — Produce JSON metadata for the up skill
# Reads updoc.config.json from cwd, validates each project, determines mode.
# Output: JSON array to stdout. All diagnostics go to stderr.

set -uo pipefail

CONFIG_FILE="updoc.config.json"

# Check jq
if ! command -v jq &>/dev/null; then
  echo '[{"error": "jq_not_found", "detail": "jq is required. Install: brew install jq"}]' >&2
  exit 1
fi

# --- Helpers ---

die() {
  echo "$1" >&2
  exit 1
}

read_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    die "updoc.config.json not found in $(pwd)"
  fi
  cat "$CONFIG_FILE"
}

project_count() {
  echo "$1" | jq '.projects | length'
}

project_field() {
  local config="$1" index="$2" field="$3"
  echo "$config" | jq -r ".projects[$index].$field"
}

# --- Main ---

main() {
  local config
  config=$(read_config) || exit 1

  local count
  count=$(project_count "$config")

  if [ "$count" -eq 0 ]; then
    echo "[]"
    exit 0
  fi

  # Global config fields
  local language docs_path projects_dir missions_dir
  language=$(echo "$config" | jq -r '.language // "en"')
  docs_path=$(echo "$config" | jq -r '.docs.path // "./updocs"')
  projects_dir=$(echo "$config" | jq -r '.docs.projects_dir // "projects"')
  missions_dir=$(echo "$config" | jq -r '.docs.missions_dir // "missions"')

  local results="[]"
  local has_error=false

  for i in $(seq 0 $((count - 1))); do
    local name path default_branch last_sync_commit
    name=$(project_field "$config" "$i" "name")
    path=$(project_field "$config" "$i" "path")
    default_branch=$(project_field "$config" "$i" "default_branch")
    last_sync_commit=$(project_field "$config" "$i" "last_sync_commit")

    [ "$last_sync_commit" = "null" ] && last_sync_commit=""

    # --- Validations ---

    if [ ! -d "$path" ]; then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        '. + [{"name": $name, "error": "not_found"}]')
      has_error=true
      continue
    fi

    if ! (cd "$path" && git rev-parse --git-dir >/dev/null 2>&1); then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        '. + [{"name": $name, "error": "git_not_available"}]')
      has_error=true
      continue
    fi

    local current_branch
    current_branch=$(cd "$path" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    if [ "$current_branch" != "$default_branch" ]; then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        --arg current "$current_branch" \
        --arg default "$default_branch" \
        '. + [{"name": $name, "error": "branch_mismatch", "current_branch": $current, "default_branch": $default}]')
      has_error=true
      continue
    fi

    # --- Mode & Diff ---

    local head
    head=$(cd "$path" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    local mode="init"
    local changed_files="[]"

    if [ -n "$last_sync_commit" ]; then
      local raw_diff filtered_diff
      raw_diff=$(cd "$path" && git diff --name-only "$last_sync_commit" HEAD -- . 2>/dev/null || echo "")

      # Strip leading "./" and trailing "/" from docs_path for grep pattern
      local normalized_docs
      normalized_docs=$(echo "$docs_path" | sed 's|^\./||' | sed 's|/$||')

      # Exclude updoc-managed files from diff to prevent sync loop
      if [ -n "$raw_diff" ]; then
        filtered_diff=$(echo "$raw_diff" | grep -v "^${normalized_docs}/" | grep -v "^updoc\.config\.json$" || true)
      fi

      if [ -n "$filtered_diff" ]; then
        mode="sync"
        changed_files=$(echo "$filtered_diff" | jq -R -s 'split("\n") | map(select(. != ""))')
      else
        mode="no_change"
        changed_files="[]"
      fi
    fi

    # --- Build result ---

    local project_result
    project_result=$(jq -n \
      --arg name "$name" \
      --arg mode "$mode" \
      --arg head "$head" \
      --arg current_branch "$current_branch" \
      --arg default_branch "$default_branch" \
      --argjson changed_files "$changed_files" \
      --arg language "$language" \
      --arg docs_path "$docs_path" \
      --arg projects_dir "$projects_dir" \
      --arg missions_dir "$missions_dir" \
      '{
        name: $name,
        mode: $mode,
        head: $head,
        current_branch: $current_branch,
        default_branch: $default_branch,
        changed_files: $changed_files,
        language: $language,
        docs_config: { path: $docs_path, projects_dir: $projects_dir, missions_dir: $missions_dir }
      }')

    results=$(echo "$results" | jq --argjson proj "$project_result" '. + [$proj]')
  done

  # If any error, output only errors
  if [ "$has_error" = true ]; then
    echo "$results" | jq '[.[] | select(.error)]'
    exit 1
  fi

  echo "$results" | jq .
}

main
