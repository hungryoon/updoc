#!/usr/bin/env bash
# init.sh — Detect project mode and output JSON for auto-initialization
# Usage: init.sh
# Output: JSON with mode (single/hub/empty) and detected projects

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check jq
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq_not_found", "detail": "jq is required. Install: brew install jq"}' >&2
  exit 1
fi

# --- Helpers ---

# Detect framework type from project files
# Usage: detect_framework "/path/to/project"
# Returns: framework name string (generic, nestjs, nextjs, fastapi, etc.)
detect_framework() {
  local project_path="$1"

  # NestJS
  if [ -f "$project_path/nest-cli.json" ] || \
     ([ -f "$project_path/package.json" ] && grep -q '"@nestjs/core"' "$project_path/package.json" 2>/dev/null); then
    echo "nestjs"
    return
  fi

  # Next.js
  if [ -f "$project_path/next.config.js" ] || [ -f "$project_path/next.config.mjs" ] || \
     ([ -f "$project_path/package.json" ] && grep -q '"next"' "$project_path/package.json" 2>/dev/null); then
    echo "nextjs"
    return
  fi

  # Nuxt
  if [ -f "$project_path/nuxt.config.ts" ] || \
     ([ -f "$project_path/package.json" ] && grep -q '"nuxt"' "$project_path/package.json" 2>/dev/null); then
    echo "nuxt"
    return
  fi

  # FastAPI / Python
  if [ -f "$project_path/pyproject.toml" ] && grep -q 'fastapi' "$project_path/pyproject.toml" 2>/dev/null; then
    echo "fastapi"
    return
  fi

  # Django
  if [ -f "$project_path/manage.py" ] && grep -q 'django' "$project_path/manage.py" 2>/dev/null; then
    echo "django"
    return
  fi

  # Go
  if [ -f "$project_path/go.mod" ]; then
    echo "go"
    return
  fi

  # Rust
  if [ -f "$project_path/Cargo.toml" ]; then
    echo "rust"
    return
  fi

  # Express (generic Node.js with express)
  if [ -f "$project_path/package.json" ] && grep -q '"express"' "$project_path/package.json" 2>/dev/null; then
    echo "express"
    return
  fi

  # Generic fallback
  echo "generic"
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

  local type
  type=$(detect_framework "$path")

  jq -n \
    --arg name "$name" \
    --arg path "$path" \
    --arg default_branch "$default_branch" \
    --arg type "$type" \
    '{name: $name, path: $path, default_branch: $default_branch, type: $type}'
}

# --- Main ---

main() {
  local mode="empty"
  local projects="[]"

  # 1. Check if current directory is a code project
  if is_code_project "."; then
    mode="single"
    local name
    name=$(basename "$(pwd)")
    local project
    project=$(build_project_info "$name" ".")
    projects=$(echo "[$project]" | jq .)
  # 2. Check projects/ subdirectory for code projects
  elif [ -d "projects" ]; then
    for project_dir in projects/*/; do
      [ -d "$project_dir" ] || continue
      # Remove trailing slash
      project_dir="${project_dir%/}"
      if is_code_project "$project_dir"; then
        local name
        name=$(basename "$project_dir")
        local project
        project=$(build_project_info "$name" "./$project_dir")
        projects=$(echo "$projects" | jq --argjson proj "$project" '. + [$proj]')
      fi
    done

    local project_count
    project_count=$(echo "$projects" | jq 'length')
    if [ "$project_count" -gt 0 ]; then
      mode="hub"
    fi
  fi

  # Output
  jq -n \
    --arg mode "$mode" \
    --argjson projects "$projects" \
    '{mode: $mode, projects: $projects}'
}

main
