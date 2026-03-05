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

### Step 1.5: Check config

If `updoc.config.yaml` does not exist in the current directory:
- Print: "updoc is not initialized. Run /updoc:init first."
- Exit. Do not proceed.

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
   {docs_config.path}/{docs_config.wiki_dir}/
   {docs_config.path}/{docs_config.missions_dir}/
   ```

2. Create `overview.md` (developer technical docs):
   - Read `$UPDOC_ROOT/templates/project-overview.md` as a base
   - Substitute frontmatter: `{name}` → project name, `{commit}` → head, `{date}` → current date
   - Write documentation content inside `<!-- updoc:begin -->` ~ `<!-- updoc:end -->` marker block
   - Save to: `{docs_config.path}/{docs_config.projects_dir}/{name}/overview.md`

3. Create wiki (`{name}.md`) (non-developer service docs):
   - Read `$UPDOC_ROOT/templates/project-wiki.md` as a base
   - Substitute frontmatter: `{name}` → project name, `{commit}` → head, `{date}` → current date
   - Write documentation content inside `<!-- updoc:begin -->` ~ `<!-- updoc:end -->` marker block
   - Save to: `{docs_config.path}/{docs_config.wiki_dir}/{name}.md`

4. Overview marker block content (developer audience):
   - **Explore the project directly** using Glob, Grep, and Read tools to understand the codebase
   - Write in the language setting (en = English, ko = Korean)
   - Sections to write:
     - **Overview**: Project description and purpose
     - **Directory Structure**: Explore with Glob and summarize
     - **Entry Points**: Identify main entry point files
     - **Configuration Files**: List key config files found
     - **Dependencies**: Extract from package.json, go.mod, pyproject.toml, etc.
   - **No guessing**: If uncertain about something, mark `TODO: manual verification needed`

5. Wiki marker block content (non-developer audience):
   - **Explore the project directly** using Glob, Grep, and Read tools
   - Write in the language setting (en = English, ko = Korean)
   - Sections to write:
     - **What is this?**: Service purpose in plain language
     - **Key Features**: Main features the service provides
     - **How to Access**: URLs, environments, or deployment info (if discoverable from code)
     - **Policies & Configuration**: Key business rules, environment variables, feature flags
   - **No guessing**: If uncertain about something, mark `TODO: manual verification needed`
   - **Plain language**: Avoid code-level details. Focus on what the service does, not how it's built.

#### No-change mode (mode == "no_change")

No code changes since last sync. Skip documentation update for this project.

#### Sync mode (mode == "sync")

1. Read existing docs:
   - Overview: `{docs_config.path}/{docs_config.projects_dir}/{name}/overview.md`
   - Wiki: `{docs_config.path}/{docs_config.wiki_dir}/{name}.md`

2. **Replace marker block only** (for both overview and wiki):
   - Rewrite content from `<!-- updoc:begin -->` to `<!-- updoc:end -->` only
   - **Never modify** content outside markers
   - Update only `synced_from` and `synced_at` in frontmatter

3. Content writing:
   - Read the files listed in `changed_files` directly using Read tool
   - Determine which documentation sections need updating based on the changes
   - Rewrite the marker block with updated information
   - Never touch user-written content outside the marker block

### Step 4.5: Update docs/index.md

After processing all projects, update `{docs_config.path}/index.md`:
- If the file does not exist, create it using `$UPDOC_ROOT/templates/docs-index.md` as a base (replace `{hub_name}` with basename of cwd)
- Replace the content inside `<!-- updoc:begin -->` / `<!-- updoc:end -->` markers with the current project table:
  - Read the full project list from `updoc.config.yaml` (not just the ones processed in this run)
  - For each project, add a row: `| {name} | [wiki/{name}.md](wiki/{name}.md) | [projects/{name}/overview.md](projects/{name}/overview.md) |`
  - Include the table header: `| Project | Wiki | Technical |` and `|---------|------|-----------|`
- Never modify content outside the marker block

### Step 5: Change report

Output the change report in the configured language.

ko example:
```
## updoc 문서 갱신 완료

### updoc (init)
- 📄 docs/projects/updoc/overview.md 생성
- 📄 docs/wiki/updoc.md 생성
- 커밋: 592c292

동기화 완료.
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
- 📄 Created docs/projects/updoc/overview.md
- 📄 Created docs/wiki/updoc.md
- Commit: 592c292

Sync complete.
```

```
## updoc Documentation Updated

### updoc (no_change)
- ⏭️ No code changes since last sync — skipped
```
