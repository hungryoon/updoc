---
project: updoc
type: generic
synced_from: 613293d
synced_at: 2026-03-04
---

# updoc

<!-- updoc:begin -->

## Overview

A codebase documentation & planning plugin for Claude Code. Built with shell scripts, it scans project metadata and generates living documentation.

## Directory Structure

```
.
├── commands/
├── hooks/
├── scripts/
│   ├── extractors/
│   └── lib/
└── templates/
```

## Entry Points

No standard entry points detected. This is a shell-script-based Claude Code plugin invoked via `/updoc:up` and `/updoc:uplan` commands.

## Configuration Files

- `updoc.config.json`

## Dependencies

No package-managed dependencies. Requires `bash` 3.2+, `jq` 1.6+, and `git`.

<!-- updoc:end -->
