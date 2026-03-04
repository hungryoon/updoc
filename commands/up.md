---
name: up
description: Scan project code to generate or update documentation.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
---

# /updoc:up

A skill that scans project code to generate (init) or update (sync) technical documentation.

## Procedure

### Step 1: Find plugin root and run up.sh

Run the following bash to locate the plugin root (`UPDOC_ROOT`) and run up.sh:

```bash
# 1) Dev mode: if scripts/up.sh exists in cwd, this is the plugin root
if [ -f "./scripts/up.sh" ] && [ -f "./.claude-plugin/plugin.json" ]; then
  UPDOC_ROOT="."
# 2) Marketplace install: search cache
else
  UPDOC_ROOT=$(find ~/.claude/plugins/cache -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi

# 3) Fallback: search marketplaces directory
if [ -z "$UPDOC_ROOT" ] || [ ! -f "$UPDOC_ROOT/scripts/up.sh" ]; then
  UPDOC_ROOT=$(find ~/.claude/plugins/marketplaces -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi
```

If UPDOC_ROOT is not found, error: "Cannot find updoc scripts. Please verify the plugin is installed."

Use `$UPDOC_ROOT` for all subsequent script/template references:
- Scripts: `$UPDOC_ROOT/scripts/`
- Templates: `$UPDOC_ROOT/templates/`

### Step 1.5: Check initial setup

Check if `updoc.config.json` exists in the current directory.

#### Already exists → Proceed to Step 2

#### Does not exist → Initial setup flow:

1. Run init.sh:
```bash
bash "$UPDOC_ROOT/scripts/init.sh"
```

2. Parse the JSON from stdout. Branch based on the `mode` field:

**mode: "empty"** (no project code detected):
- Create the following directories:
  - `projects/`
  - `updocs/projects/`
  - `updocs/missions/`
- Do not create config
- Print a message and exit:
```
No project code detected.

Created directory structure:
  projects/
  updocs/projects/
  updocs/missions/

Clone a project into projects/ and run /updoc:up again.
e.g.: git clone git@github.com:org/api.git projects/api
```

**mode: "single"** (current directory is a project):
- Display detected project info:
```
Starting updoc initial setup.

Detected project:
  Name: {name}
  Path: .
  Branch: {default_branch}
  Framework: {type}

Proceed with this setup? Enter a project description if you'd like to add one.
```
- AskUserQuestion to confirm with user
- AskUserQuestion to select language (ko/en)
- Create `updoc.config.json` with Write (refer to templates/config.json structure, add detected project to projects array)
- Continue to Step 2

**mode: "hub"** (projects detected under projects/):
- Display detected project list:
```
Detected projects under projects/:
  1. {name} ({type}) — {path}
  2. {name} ({type}) — {path}

Register these projects and generate documentation?
```
- AskUserQuestion to confirm with user
- AskUserQuestion to select language
- Create `updoc.config.json` with Write (include all detected projects)
- Continue to Step 2

### Step 2: Run up.sh

```bash
bash "$UPDOC_ROOT/scripts/up.sh"
```

Parse the JSON array from stdout. If exit code is non-zero, it's error JSON.

### Step 3: Error handling

If any item in the JSON array has an `error` field, it's an error. If any error exists, abort all.

Error messages:
- `branch_mismatch`: "{name}: Can only run on default branch ({default_branch}). Current branch: {current_branch}"
- `not_found`: "{name}: Project path not found."
- `git_not_available`: "{name}: Not a git repository."

Print errors and exit. Do not proceed with documentation.

### Step 4: Per-project documentation

For each project in the JSON array, branch based on `mode`:

#### Init mode (mode == "init")

1. Create docs directories:
   ```
   {docs_config.path}/{docs_config.projects_dir}/{name}/
   {docs_config.path}/{docs_config.projects_dir}/{name}/domains/
   {docs_config.path}/{docs_config.missions_dir}/
   ```

2. Create `overview.md`:
   - Read `$UPDOC_ROOT/templates/project-overview.md` as a base
   - Substitute frontmatter: `{name}` → project name, `{type}` → type (from config or detect via init.sh), `{commit}` → head, `{date}` → current date
   - Write documentation content inside `<!-- updoc:begin -->` ~ `<!-- updoc:end -->` marker block

3. Marker block content rules:
   - **Explore the project directly** using Glob, Grep, and Read tools to understand the codebase
   - Write in the language setting (en = English, ko = Korean)
   - Sections to write:
     - **Overview**: Project description and purpose
     - **Directory Structure**: Explore with Glob and summarize
     - **Entry Points**: Identify main entry point files
     - **Configuration Files**: List key config files found
     - **Dependencies**: Extract from package.json, go.mod, pyproject.toml, etc.
   - **No guessing**: If uncertain about something, mark `TODO: manual verification needed`

#### No-change mode (mode == "no_change")

No code changes since last sync. Skip documentation update for this project.

#### Sync mode (mode == "sync")

1. Read existing overview.md:
   ```
   {docs_config.path}/{docs_config.projects_dir}/{name}/overview.md
   ```

2. **Replace marker block only**:
   - Rewrite content from `<!-- updoc:begin -->` to `<!-- updoc:end -->` only
   - **Never modify** content outside markers
   - Update only `synced_from` and `synced_at` in frontmatter

3. Content writing:
   - Read the files listed in `changed_files` directly using Read tool
   - Determine which documentation sections need updating based on the changes
   - Rewrite the marker block with updated information
   - Never touch user-written content outside the marker block

### Step 5: Update sync state

For each project where mode is "init" or "sync":
```bash
bash "$UPDOC_ROOT/scripts/update-sync-state.sh" "{name}" "{head}" "{type}"
```

Skip `no_change` projects — their sync state is already current.

### Step 6: Change report

Output the change report in the configured language.

ko example:
```
## updoc 문서 갱신 완료

### updoc (init)
- 📄 updocs/projects/updoc/overview.md 생성
- 커밋: 592c292

동기화 상태가 updoc.config.json에 저장되었습니다.
```

```
## updoc 문서 갱신 완료

### updoc (no_change)
- ⏭️ 마지막 동기화 이후 코드 변경 없음 — 건너뜀
```

en example:
```
## updoc Documentation Updated

### updoc (init)
- 📄 Created updocs/projects/updoc/overview.md
- Commit: 592c292

Sync state saved to updoc.config.json.
```

```
## updoc Documentation Updated

### updoc (no_change)
- ⏭️ No code changes since last sync — skipped
```
