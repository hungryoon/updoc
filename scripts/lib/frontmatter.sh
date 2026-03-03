#!/usr/bin/env bash
# frontmatter.sh — Parse YAML frontmatter from markdown files
# Extracts key-value pairs from --- delimited frontmatter blocks

# Get a single frontmatter value from a markdown file
# Usage: get_frontmatter_value "file.md" "key"
get_frontmatter_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    return 1
  fi

  # Extract content between first --- and second ---
  sed -n '/^---$/,/^---$/p' "$file" | \
    grep "^${key}:" | \
    sed "s/^${key}:[[:space:]]*//" | \
    head -1
}
