# updoc

Claude Code plugin for code documentation & mission planning.

## Architecture

Shell scripts + command specs (md) + templates. No build step, no runtime dependencies beyond `bash 3.2+`, `yq 4+`, `git`.

## Key Files

| Path | Purpose |
|------|---------|
| `commands/init.md` | `/updoc:init` skill spec (English) |
| `commands/up.md` | `/updoc:up` skill spec (English) |
| `commands/uplan.md` | `/updoc:uplan` skill spec (English) |
| `scripts/up.sh` | Scan orchestration — validates projects, outputs JSON |
| `scripts/init.sh` | Project detection under `repos/` |
| `hooks/session-start.sh` | Session status display (projects, sync state) |
| `templates/` | Config, overview, wiki, mission, index templates |
| `templates/project-wiki.md` | Wiki template for non-developer docs |
| `templates/docs-index.md` | Index template for docs |
| `updoc.config.yaml` | Per-workspace config (committed) |
| `concept.md` | Phase 1 design origin (historical, may differ from current) |

## Config Structure (`updoc.config.yaml`)

- `language` — single string (`"en"`, `"ko"`)
- `projects[]` — array of `{ name, path, default_branch }`
- `docs` — `{ path, projects_dir, wiki_dir, missions_dir }`

## Development Rules

- **Command specs** are written in English (`commands/*.md`)
- **README** maintained in English (`README.md`) + Korean (`README.ko.md`)
- **Marker blocks** (`<!-- updoc:begin -->` / `<!-- updoc:end -->`) — never modify content outside these markers
- **No guessing** — if Claude can't confirm it from the codebase, don't document it. Use `TODO: manual verification needed`
- **Docs reflect merged code only** — `/updoc:up` is blocked on non-default branches
- **Dedicated docs repo** — projects are cloned under `repos/`, docs live separately

## Testing

```bash
# Scan orchestration — verify JSON output
bash scripts/up.sh

# Project detection
bash scripts/init.sh

# Session status display (requires updoc.config.yaml + docs with frontmatter)
bash hooks/session-start.sh
```

## Version Management

Keep versions in sync across these two files:

1. `.claude-plugin/plugin.json`
2. `templates/config.yaml`
