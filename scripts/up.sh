#!/usr/bin/env bash
# up.sh — Orchestrate project scanning and produce JSON for the up skill
# Reads updoc.config.json from cwd, validates each project, runs extractors.
# Output: JSON array to stdout. All diagnostics go to stderr.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="updoc.config.json"

# Check jq
if ! command -v jq &>/dev/null; then
  echo '[{"error": "jq_not_found", "detail": "jq is required. Install: brew install jq"}]' >&2
  exit 1
fi

source "$SCRIPT_DIR/lib/frontmatter.sh"

# --- Helpers ---

die() {
  echo "$1" >&2
  exit 1
}

# Read config
read_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    die "updoc.config.json not found in $(pwd)"
  fi
  cat "$CONFIG_FILE"
}

# Get project count from config
project_count() {
  echo "$1" | jq '.projects | length'
}

# Get a project field
project_field() {
  local config="$1"
  local index="$2"
  local field="$3"
  echo "$config" | jq -r ".projects[$index].$field"
}

# Detect missions in progress whose branches have been merged into default branch
detect_merged_missions() {
  local docs_path="$1"
  local missions_dir="$2"
  local default_branch="$3"
  local missions_path="$docs_path/$missions_dir"

  if [ ! -d "$missions_path" ]; then
    echo "[]"
    return
  fi

  local result="[]"
  for mission_file in "$missions_path"/*.md; do
    [ -f "$mission_file" ] || continue

    local status
    status=$(get_frontmatter_value "$mission_file" "status")
    [ "$status" = "done" ] && continue

    local slug
    slug=$(get_frontmatter_value "$mission_file" "slug")
    local branch
    branch=$(get_frontmatter_value "$mission_file" "branch")

    if [ -z "$slug" ]; then
      continue
    fi

    local merged="false"
    if [ -n "$branch" ]; then
      # Check if branch has been merged into default branch
      if git branch --merged "$default_branch" 2>/dev/null | grep -q "$branch"; then
        merged="true"
      fi
    fi

    result=$(echo "$result" | jq \
      --arg slug "$slug" \
      --arg status "${status:-draft}" \
      --arg branch "${branch:-}" \
      --arg path "$mission_file" \
      --argjson merged "$merged" \
      '. + [{slug: $slug, status: $status, branch: $branch, path: $path, merged: $merged}]')
  done

  echo "$result"
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

  # Detect missions once (shared across all projects)
  local missions_in_progress
  missions_in_progress=$(detect_merged_missions "$docs_path" "$missions_dir" "$(echo "$config" | jq -r '.projects[0].default_branch // "main"')")

  local results="[]"
  local has_error=false

  for i in $(seq 0 $((count - 1))); do
    local name path type default_branch last_sync_commit description
    name=$(project_field "$config" "$i" "name")
    path=$(project_field "$config" "$i" "path")
    type=$(project_field "$config" "$i" "type")
    default_branch=$(project_field "$config" "$i" "default_branch")
    last_sync_commit=$(project_field "$config" "$i" "last_sync_commit")
    description=$(project_field "$config" "$i" "description")

    # Handle null values from jq
    [ "$type" = "null" ] && type=""
    [ "$last_sync_commit" = "null" ] && last_sync_commit=""
    [ "$description" = "null" ] && description=""

    # --- Validations ---

    # Check path exists
    if [ ! -d "$path" ]; then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        '. + [{"name": $name, "error": "not_found"}]')
      has_error=true
      continue
    fi

    # Check git available
    if ! (cd "$path" && git rev-parse --git-dir >/dev/null 2>&1); then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        '. + [{"name": $name, "error": "git_not_available"}]')
      has_error=true
      continue
    fi

    # Check branch
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

    # --- Extract ---

    # Determine type
    local detected_type="$type"
    if [ -z "$detected_type" ]; then
      detected_type=$(cd "$path" && source "$SCRIPT_DIR/extractors/common.sh" && detect_framework ".")
    fi

    # Select extractor
    local extractor_used="$detected_type"
    local extractor_script="$SCRIPT_DIR/extractors/${detected_type}.sh"
    local warnings="[]"

    if [ ! -f "$extractor_script" ]; then
      extractor_script="$SCRIPT_DIR/extractors/generic.sh"
      extractor_used="generic"
      if [ "$detected_type" != "generic" ]; then
        warnings='["extractor_fallback"]'
      fi
    fi

    # Run extractor
    local extraction
    local extract_exit=0
    extraction=$(cd "$path" && bash "$extractor_script" "." "$name" 2>/dev/null) || extract_exit=$?

    if [ "$extract_exit" -ne 0 ] || [ -z "$extraction" ]; then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        --arg detail "Extractor $extractor_used failed" \
        '. + [{"name": $name, "error": "extractor_failed", "detail": $detail}]')
      has_error=true
      continue
    fi

    # Validate JSON
    if ! echo "$extraction" | jq . >/dev/null 2>&1; then
      results=$(echo "$results" | jq \
        --arg name "$name" \
        --arg detail "Invalid JSON from extractor" \
        '. + [{"name": $name, "error": "extractor_failed", "detail": $detail}]')
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
        changed_files=$(source "$SCRIPT_DIR/extractors/common.sh" && to_json_array "$filtered_diff")
      else
        mode="no_change"
        changed_files="[]"
      fi
    fi

    # --- Build result ---

    local project_result
    project_result=$(jq -n \
      --arg name "$name" \
      --arg description "$description" \
      --arg mode "$mode" \
      --arg head "$head" \
      --arg current_branch "$current_branch" \
      --arg default_branch "$default_branch" \
      --arg type "$detected_type" \
      --arg extractor_used "$extractor_used" \
      --argjson warnings "$warnings" \
      --argjson extraction "$extraction" \
      --argjson changed_files "$changed_files" \
      --arg language "$language" \
      --arg docs_path "$docs_path" \
      --arg projects_dir "$projects_dir" \
      --arg missions_dir "$missions_dir" \
      --argjson missions_in_progress "$missions_in_progress" \
      '{
        name: $name,
        description: $description,
        mode: $mode,
        head: $head,
        current_branch: $current_branch,
        default_branch: $default_branch,
        type: $type,
        extractor_used: $extractor_used,
        warnings: $warnings,
        extraction: $extraction,
        changed_files: $changed_files,
        language: $language,
        docs_config: { path: $docs_path, projects_dir: $projects_dir, missions_dir: $missions_dir },
        missions_in_progress: $missions_in_progress
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
