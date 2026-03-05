#!/usr/bin/env bash
# init.sh — Detect project mode and output JSON for auto-initialization
# Usage: init.sh
# Output: JSON with mode (ready/empty) and detected projects

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check yq
if ! command -v yq &>/dev/null; then
  echo '{"error": "yq_not_found", "detail": "yq is required. Install: brew install yq"}' >&2
  exit 1
fi

# --- Helpers ---

# Append a JSON object string to a JSON array string
json_append() {
  local array="$1" item="$2"
  if [ "$array" = "[]" ]; then
    echo "[$item]"
  else
    echo "${array%]},$item]"
  fi
}

# Detect default branch for a git repo
# Usage: detect_default_branch "/path/to/repo"
detect_default_branch() {
  local repo_path="$1"

  # Try origin/HEAD
  local remote_head
  remote_head=$(cd "$repo_path" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  if [ -n "$remote_head" ]; then
    echo "$remote_head"
    return
  fi

  # Fallback: check if main branch exists
  if (cd "$repo_path" && git show-ref --verify --quiet refs/heads/main 2>/dev/null); then
    echo "main"
    return
  fi

  # Fallback: check if master branch exists
  if (cd "$repo_path" && git show-ref --verify --quiet refs/heads/master 2>/dev/null); then
    echo "master"
    return
  fi

  # Final fallback
  echo "main"
}

# Check if a directory contains a code project
# Usage: is_code_project "/path/to/dir"
is_code_project() {
  local dir="$1"
  local markers=(
    "package.json" "go.mod" "Cargo.toml" "pyproject.toml"
    "manage.py" "nest-cli.json" "next.config.js" "next.config.mjs"
    "setup.py" "requirements.txt" "pom.xml" "build.gradle"
    "Gemfile" "mix.exs" "pubspec.yaml"
  )

  for marker in "${markers[@]}"; do
    if [ -f "$dir/$marker" ]; then
      return 0
    fi
  done

  return 1
}

# Build project info JSON for a single project
# Usage: build_project_info "name" "path"
build_project_info() {
  local name="$1"
  local path="$2"

  local default_branch
  default_branch=$(detect_default_branch "$path")

  printf '{"name":"%s","path":"%s","default_branch":"%s"}' \
    "$name" "$path" "$default_branch"
}

# --- Main ---

main() {
  local mode="empty"
  local projects="[]"
  local repos_dir_exists=false
  local is_code_repo=false

  # Warn if cwd itself looks like a code project (not a dedicated docs repo)
  if is_code_project "."; then
    is_code_repo=true
  fi

  if [ -d "repos" ]; then
    repos_dir_exists=true
    for project_dir in repos/*/; do
      [ -d "$project_dir" ] || continue
      project_dir="${project_dir%/}"
      if is_code_project "$project_dir"; then
        local name
        name=$(basename "$project_dir")
        local project
        project=$(build_project_info "$name" "./$project_dir")
        projects=$(json_append "$projects" "$project")
      fi
    done

    local project_count
    project_count=$(echo "$projects" | yq -p json 'length')
    if [ "$project_count" -gt 0 ]; then
      mode="ready"
    fi
  fi

  printf '{"mode":"%s","projects":%s,"repos_dir_exists":%s,"is_code_repo":%s}\n' \
    "$mode" "$projects" "$repos_dir_exists" "$is_code_repo"
}

main
