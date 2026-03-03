#!/usr/bin/env bash
# generic.sh — Generic extractor (Phase 1)
# Extracts directory structure, entry points, config files.
# modules/routes/models are left empty (framework-specific extractors fill those).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Extract project metadata as JSON
# Usage: extract "/path/to/project" "project-name"
extract() {
  local project_path="$1"
  local project_name="$2"

  if [ ! -d "$project_path" ]; then
    echo '{"error": "path_not_found"}' >&2
    return 1
  fi

  local directories
  directories=$(extract_directory_structure "$project_path")

  local entry_points
  entry_points=$(detect_entry_points "$project_path")

  local config_files
  config_files=$(detect_config_files "$project_path")

  local deps='{}'
  if [ -f "$project_path/package.json" ]; then
    deps=$(jq '{
      dependencies: (.dependencies // {} | keys),
      devDependencies: (.devDependencies // {} | keys)
    }' "$project_path/package.json" 2>/dev/null || echo '{}')
  elif [ -f "$project_path/pyproject.toml" ]; then
    deps='{}'
  elif [ -f "$project_path/go.mod" ]; then
    deps='{}'
  fi

  jq -n \
    --arg name "$project_name" \
    --argjson directories "$directories" \
    --argjson entry_points "$entry_points" \
    --argjson config_files "$config_files" \
    --argjson deps "$deps" \
    '{
      name: $name,
      framework: "generic",
      extractor_used: "generic",
      warnings: [],
      structure: {
        directories: $directories,
        entry_points: $entry_points,
        config_files: $config_files
      },
      modules: [],
      routes: [],
      models: [],
      dependencies: $deps
    }'
}

# Run directly if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  if [ $# -lt 2 ]; then
    echo "Usage: generic.sh <path> <name>" >&2
    exit 1
  fi
  extract "$1" "$2"
fi
