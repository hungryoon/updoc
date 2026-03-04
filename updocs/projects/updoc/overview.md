---
project: updoc
type: generic
synced_from: b9cf02e
synced_at: 2026-03-04
---

# updoc

<!-- updoc:begin -->

## Overview

A codebase documentation & planning plugin for Claude Code. Built with shell scripts, it directly explores project code to generate and maintain living documentation.

## Directory Structure

```
.
├── commands/          # Skill specs (up.md, uplan.md)
├── hooks/             # Session lifecycle hooks
├── scripts/           # Shell scripts (up.sh, init.sh, update-sync-state.sh)
└── templates/         # Config and document templates
```

## Entry Points

No standard entry points detected. This is a shell-script-based Claude Code plugin invoked via `/updoc:up` and `/updoc:uplan` commands.

## Configuration Files

- `updoc.config.json`

## Dependencies

No package-managed dependencies. Requires `bash` 3.2+, `jq` 1.6+, and `git`.

<!-- updoc:end -->
