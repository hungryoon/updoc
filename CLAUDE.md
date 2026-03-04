# updoc

Claude Code plugin for code documentation & mission planning.

## Architecture

Shell scripts + command specs (md) + templates. No build step, no runtime dependencies beyond `bash 3.2+`, `jq 1.6+`, `git`.

## Key Files

| Path | Purpose |
|------|---------|
| `commands/up.md` | `/updoc:up` skill spec (English) |
| `commands/uplan.md` | `/updoc:uplan` skill spec (English) |
| `scripts/up.sh` | Scan orchestration — validates projects, outputs JSON |
| `scripts/init.sh` | Project detection (single/hub/empty mode) |
| `scripts/update-sync-state.sh` | Updates sync commit/date in config |
| `hooks/session-start.sh` | Session status display (projects, sync state) |
| `templates/` | Config, overview, mission templates |
| `updoc.config.json` | Per-workspace config (committed) |
| `concept.md` | Design philosophy & phase roadmap (detailed) |

## Config Structure (`updoc.config.json`)

- `language` — single string (`"en"`, `"ko"`)
- `projects[]` — array of `{ name, path, type, default_branch, description, last_sync_commit, last_sync_date }`
- `docs` — `{ path, projects_dir, missions_dir }`

## Development Rules

- **Command specs** are written in English (`commands/*.md`)
- **README** maintained in English (`README.md`) + Korean (`README.ko.md`)
- **Marker blocks** (`<!-- updoc:begin -->` / `<!-- updoc:end -->`) — never modify content outside these markers
- **No guessing** — if Claude can't confirm it from the codebase, don't document it. Use `TODO: manual verification needed`
- **Docs reflect merged code only** — `/updoc:up` is blocked on non-default branches

## Testing

```bash
# Scan orchestration — verify JSON output
bash scripts/up.sh

# Project detection
bash scripts/init.sh

# Session status display
bash hooks/session-start.sh
```

## Version Management

Keep versions in sync across these three files:

1. `.claude-plugin/plugin.json`
2. `updoc.config.json`
3. `templates/config.json`
