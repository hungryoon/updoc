---
name: init
description: Set up updoc in the current directory.
disable-model-invocation: true
allowed-tools: Read, Bash, Write, AskUserQuestion
---

# /updoc:init

A skill that initializes updoc in the current directory — detects projects, creates directories and config.

## Procedure

### Step 1: Find plugin root

Run the following bash to locate the plugin root (`UPDOC_ROOT`):

```bash
# 1) Dev mode: if scripts/init.sh exists in cwd, this is the plugin root
if [ -f "./scripts/init.sh" ] && [ -f "./.claude-plugin/plugin.json" ]; then
  UPDOC_ROOT="."
# 2) Marketplace install: search cache
else
  UPDOC_ROOT=$(find ~/.claude/plugins/cache -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi

# 3) Fallback: search marketplaces directory
if [ -z "$UPDOC_ROOT" ] || [ ! -f "$UPDOC_ROOT/scripts/init.sh" ]; then
  UPDOC_ROOT=$(find ~/.claude/plugins/marketplaces -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi
```

If UPDOC_ROOT is not found, error: "Cannot find updoc scripts. Please verify the plugin is installed."

Use `$UPDOC_ROOT` for all subsequent script/template references:
- Scripts: `$UPDOC_ROOT/scripts/`
- Templates: `$UPDOC_ROOT/templates/`

### Step 2: Check existing config

If `updoc.config.yaml` already exists in the current directory:
- Print: "updoc is already initialized. Run /updoc:up to update docs."
- Exit. Do not proceed.

### Step 3: Detect projects

Run init.sh:
```bash
bash "$UPDOC_ROOT/scripts/init.sh"
```

Parse the JSON from stdout.

If `is_code_repo` is `true`, print a warning before proceeding:
```
Warning: This directory looks like a code project (found package.json, go.mod, etc.).

updoc works best in a dedicated docs repo where you clone projects into repos/.
Mixing code and docs in the same repo can cause sync conflicts and messy commit history.
```

Then use AskUserQuestion to ask if they want to continue anyway (Yes / No). If No, exit.

### Step 4: Create directories

Always create these directories (skip any that already exist):
- `repos/`
- `docs/wiki/`
- `docs/projects/`
- `docs/missions/`

### Step 4.5: Set up CLAUDE.md rules

Add updoc workspace rules to `CLAUDE.md`:
- If `CLAUDE.md` does not exist, create it with the content below
- If `CLAUDE.md` exists, check if it already contains `## updoc Rules`. If not, append the content below to the end of the file

Content to add:
```
## updoc Rules

- **Never modify files under `repos/`** — these are source clones managed by git. Read-only.
- **All documentation work happens in `docs/`** — create and edit docs only in the docs directory.
- **Marker blocks are sacred** — only modify content between `<!-- updoc:begin -->` and `<!-- updoc:end -->`.
```

### Step 5: Set up .gitignore

- If `.gitignore` does not exist, create it with a single line: `repos/`
- If `.gitignore` exists, check if it contains `repos/`:
  - If not found, append `repos/` to the file
  - If already present, skip

### Step 6: Register projects

If `mode` is `"ready"` (projects detected under `repos/`):
- Display detected project list with details:
```
Starting updoc initial setup.

Detected {count} project(s) under repos/:

  {name}
    Path: {path}
    Branch: {default_branch}

Register these projects and generate documentation?
```
- AskUserQuestion to confirm with user. If No, exit.

If `mode` is `"empty"` (no projects detected):
- Continue with empty projects list (projects: [])

### Step 7: Select language

AskUserQuestion to select language (en/ko).

### Step 8: Create config

Create `updoc.config.yaml` with Write — refer to `$UPDOC_ROOT/templates/config.yaml` for structure. Include:
- Selected language
- All detected projects (or empty array). If no projects detected, write `projects: []` followed by the commented example from the template
- `docs.path`: `"./docs"`
- `docs.projects_dir`: `"projects"`
- `docs.wiki_dir`: `"wiki"`
- `docs.missions_dir`: `"missions"`

### Step 9: Create docs/index.md

Create `docs/index.md` using `$UPDOC_ROOT/templates/docs-index.md` as a base:
- Replace `{hub_name}` with the current directory name (basename of cwd)
- Build the project table inside `<!-- updoc:begin -->` / `<!-- updoc:end -->` markers:
  - For each registered project, add a row: `| {name} | [wiki/{name}/index.md](wiki/{name}/index.md) | [projects/{name}/overview.md](projects/{name}/overview.md) |`
  - If no projects registered, leave the table with headers only (no rows)

### Step 10: Completion message

If projects were registered:
- Print: "updoc initialized. Run /updoc:up to generate documentation."

If no projects were registered:
- Print: "updoc initialized. Clone repos into repos/ and run /updoc:up."
