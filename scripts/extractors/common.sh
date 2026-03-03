#!/usr/bin/env bash
# common.sh — Shared utilities for all extractors
# Single source of truth for exclude patterns and helper functions

# Single source of truth: directories to exclude from scanning
EXCLUDE_DIRS=(
  ".git" "node_modules" "dist" "build"
  ".claude" ".claude-plugin" "__pycache__" ".venv" "venv"
  "coverage" ".nyc_output" ".next" ".nuxt" "updocs"
)

# Convert newline-separated string to JSON array
# Usage: to_json_array "$input"
to_json_array() {
  local input="$1"
  if [ -z "$input" ]; then
    echo "[]"
  else
    echo "$input" | jq -R -s 'split("\n") | map(select(. != ""))'
  fi
}

# Extract directory structure as JSON array (top 3 levels, directories only)
# Usage: extract_directory_structure "/path/to/project"
extract_directory_structure() {
  local project_path="$1"
  local max_depth="${2:-3}"

  local exclude_args=""
  for dir_name in "${EXCLUDE_DIRS[@]}"; do
    exclude_args="$exclude_args -not -path ./${dir_name} -not -path ./${dir_name}/*"
  done

  local dirs
  local old_noglob
  old_noglob=$(set +o | grep noglob)
  set -f
  dirs=$(cd "$project_path" && eval "find . -maxdepth $max_depth -type d $exclude_args" 2>/dev/null | sort)
  eval "$old_noglob"

  to_json_array "$dirs"
}

# Detect entry point files in a project
# Usage: detect_entry_points "/path/to/project"
detect_entry_points() {
  local project_path="$1"

  local entry_points=""
  local candidates=(
    "main.ts" "main.js" "index.ts" "index.js"
    "app.ts" "app.js" "server.ts" "server.js"
    "main.py" "app.py" "manage.py" "__main__.py"
    "main.go" "cmd/main.go"
    "Makefile" "Dockerfile" "docker-compose.yml" "docker-compose.yaml"
  )

  for candidate in "${candidates[@]}"; do
    if [ -f "$project_path/$candidate" ]; then
      entry_points="$entry_points$candidate"$'\n'
    fi
  done

  # Check src/ variants
  for candidate in "main.ts" "main.js" "index.ts" "index.js" "app.ts" "app.js"; do
    if [ -f "$project_path/src/$candidate" ]; then
      entry_points="${entry_points}src/$candidate"$'\n'
    fi
  done

  to_json_array "$entry_points"
}

# Detect configuration files in a project
# Usage: detect_config_files "/path/to/project"
detect_config_files() {
  local project_path="$1"

  local config_files=""
  local candidates=(
    "package.json" "tsconfig.json" "tsconfig.build.json"
    "pyproject.toml" "setup.py" "setup.cfg" "requirements.txt"
    "go.mod" "go.sum" "Cargo.toml"
    "nest-cli.json" ".eslintrc.js" ".eslintrc.json" ".prettierrc"
    "webpack.config.js" "vite.config.ts" "vite.config.js"
    "next.config.js" "next.config.mjs" "nuxt.config.ts"
    "babel.config.js" "jest.config.js" "jest.config.ts"
    "vitest.config.ts" ".env.example"
    "updoc.config.json"
  )

  for candidate in "${candidates[@]}"; do
    if [ -f "$project_path/$candidate" ]; then
      config_files="$config_files$candidate"$'\n'
    fi
  done

  to_json_array "$config_files"
}

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
