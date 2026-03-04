---
slug: feat-simplify-language
created: 2026-03-03
status: done
completed: 2026-03-04
branch: feat/simplify-language
---

# feat-simplify-language

## Background

The current `updoc.config.json` stores language as an object with two fields: `language.display` (CLI output language) and `language.document` (generated docs language). Since the config file is committed to the repo and shared, `display` cannot serve as a personal preference. There is no per-user, per-repo config mechanism in Claude Code.

## AS-IS

```json
"language": { "display": "ko", "document": "en" }
```

- Two separate language fields read by 3 scripts (`up.sh`, `uplan-prepare.sh`, `session-start.sh`)
- Two separate variables tracked throughout the codebase (`lang_display`/`lang_document`, `LANG_DISPLAY`/`LANG_DOCUMENT`)
- Two command specs reference both fields (`commands/up.md`, `commands/uplan.md`)
- Two README files document both fields in Config Reference tables

## TO-BE

```json
"language": "en"
```

- Single `language` string controls both CLI output and document generation
- One variable per script
- Simpler config, fewer moving parts

## Impact Scope

- **updoc** (scripts): `up.sh`, `uplan-prepare.sh`, `session-start.sh` — change jq extraction from `.language.display`/`.language.document` to `.language`
- **updoc** (config): `templates/config.json`, `updoc.config.json` — flatten language object to string
- **updoc** (commands): `commands/up.md`, `commands/uplan.md` — update language references
- **updoc** (docs): `README.md`, `README.ko.md` — update Config Reference tables

## API Contracts

N/A — internal config change only.

## Tasks

- updoc-1: Flatten language in `templates/config.json` and `updoc.config.json`
- updoc-2: Update `scripts/up.sh` — single `language` variable, update JSON output
- updoc-3: Update `scripts/uplan-prepare.sh` — single `LANGUAGE` variable, update JSON output
- updoc-4: Update `hooks/session-start.sh` — single `LANGUAGE` variable
- updoc-5: Update `commands/up.md` and `commands/uplan.md` — replace `language.display`/`language.document` references
- updoc-6: Update `README.md` and `README.ko.md` Config Reference tables
