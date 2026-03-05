#!/usr/bin/env bash
# up.sh — Produce JSON metadata for the up skill
# Reads updoc.config.yaml from cwd, validates each project, determines mode.
# Output: JSON array to stdout. All diagnostics go to stderr.

set -uo pipefail

CONFIG_FILE="updoc.config.yaml"

# Check yq
if ! command -v yq &>/dev/null; then
  echo '[{"error": "yq_not_found", "detail": "yq is required. Install: brew install yq"}]' >&2
  exit 1
fi

# --- Helpers ---

die() {
  echo "$1" >&2
  exit 1
}

# Append a JSON object string to a JSON array string
json_append() {
  local array="$1" item="$2"
  if [ "$array" = "[]" ]; then
    echo "[$item]"
  else
    echo "${array%]},$item]"
  fi
}

read_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    die "updoc.config.yaml not found in $(pwd)"
  fi
  cat "$CONFIG_FILE"
}

project_count() {
  echo "$1" | yq '.projects | length'
}

project_field() {
  local config="$1" index="$2" field="$3"
  echo "$config" | yq ".projects[$index].$field"
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
  local language docs_path projects_dir wiki_dir missions_dir
  language=$(echo "$config" | yq '.language // "en"')
  docs_path=$(echo "$config" | yq '.docs.path // "./docs"')
  projects_dir=$(echo "$config" | yq '.docs.projects_dir // "projects"')
  wiki_dir=$(echo "$config" | yq '.docs.wiki_dir // "wiki"')
  missions_dir=$(echo "$config" | yq '.docs.missions_dir // "missions"')

  local results="[]"
  local has_error=false

  for i in $(seq 0 $((count - 1))); do
    local name path default_branch last_sync_commit
    name=$(project_field "$config" "$i" "name")
    path=$(project_field "$config" "$i" "path")
    default_branch=$(project_field "$config" "$i" "default_branch")

    # Read last_sync_commit from generated docs frontmatter
    local overview_path="${docs_path}/${projects_dir}/${name}/overview.md"
    last_sync_commit=""
    if [ -f "$overview_path" ]; then
      last_sync_commit=$(yq --front-matter=extract '.synced_from' "$overview_path" 2>/dev/null || echo "")
      [ "$last_sync_commit" = "null" ] && last_sync_commit=""
    fi

    # --- Validations ---

    if [ ! -d "$path" ]; then
      results=$(json_append "$results" "$(printf '{"name":"%s","error":"not_found"}' "$name")")
      has_error=true
      continue
    fi

    if ! (cd "$path" && git rev-parse --git-dir >/dev/null 2>&1); then
      results=$(json_append "$results" "$(printf '{"name":"%s","error":"git_not_available"}' "$name")")
      has_error=true
      continue
    fi

    local current_branch
    current_branch=$(cd "$path" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    if [ "$current_branch" != "$default_branch" ]; then
      results=$(json_append "$results" "$(printf '{"name":"%s","error":"branch_mismatch","current_branch":"%s","default_branch":"%s"}' \
        "$name" "$current_branch" "$default_branch")")
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
        filtered_diff=$(echo "$raw_diff" | grep -v "^${normalized_docs}/" | grep -v "^updoc\.config\.yaml$" || true)
      fi

      if [ -n "$filtered_diff" ]; then
        mode="sync"
        # Build JSON array from newline-separated file list
        changed_files="["
        local first=true
        while IFS= read -r file; do
          [ -z "$file" ] && continue
          $first || changed_files+=","
          changed_files+="\"$file\""
          first=false
        done <<< "$filtered_diff"
        changed_files+="]"
      else
        mode="no_change"
        changed_files="[]"
      fi
    fi

    # --- Build result ---

    local project_result
    project_result=$(printf '{"name":"%s","mode":"%s","head":"%s","current_branch":"%s","default_branch":"%s","changed_files":%s,"language":"%s","docs_config":{"path":"%s","projects_dir":"%s","wiki_dir":"%s","missions_dir":"%s"}}' \
      "$name" "$mode" "$head" "$current_branch" "$default_branch" \
      "$changed_files" "$language" "$docs_path" "$projects_dir" \
      "$wiki_dir" "$missions_dir")

    results=$(json_append "$results" "$project_result")
  done

  # If any error, output only errors
  if [ "$has_error" = true ]; then
    echo "$results" | yq -p json -o json '[.[] | select(.error)]'
    exit 1
  fi

  echo "$results" | yq -p json -o json '.'
}

main
