---
name: up
description: Scan project code to generate or update documentation.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
---

# /updoc:up

A skill that scans project code to generate (full scan) or update (sync) technical documentation.

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

### Step 2: Run up.sh (auto pull + scan)

```bash
UPDOC_ROOT="$UPDOC_ROOT" bash "$UPDOC_ROOT/scripts/up.sh"
```

Parse the JSON array from stdout. If exit code is non-zero, it's error JSON.

**Auto pull**: up.sh automatically runs `git pull --ff-only` for each project before scanning. The `pull_status` field in each result indicates:
- `"pulled"` — new commits were fetched
- `"up_to_date"` — already at latest
- `"pull_failed"` — pull failed (continues with current HEAD; stderr has warning)

### Step 3: Error handling

If any item in the JSON array has an `error` field, it's an error. If any error exists, abort all.

Error messages:
- `version_mismatch`: "Config version ({config_version}) does not match plugin version ({plugin_version}). Please update updoc.config.yaml or reinstall the plugin."
- `branch_mismatch`: "{name}: Can only run on default branch ({default_branch}). Current branch: {current_branch}"
- `not_found`: "{name}: Project path not found."
- `git_not_available`: "{name}: Not a git repository."

Print errors and exit. Do not proceed with documentation.

### Step 4: Per-project documentation

**Language enforcement**: All documentation content MUST be written in the language specified by the `language` field in the JSON output. This overrides the conversation language. `"en"` = English, `"ko"` = Korean. This applies to all prose, headings, and descriptions within marker blocks.

For each project in the JSON array, branch based on `mode`:

#### Full scan mode (mode == "full_scan")

1. Create docs directories:
   ```
   {docs_config.path}/{docs_config.projects_dir}/{name}/
   {docs_config.path}/{docs_config.wiki_dir}/{name}/
   {docs_config.path}/{docs_config.missions_dir}/
   ```

2. Create project overview files (developer technical docs, 4 files):

   a. `overview.md` (hub file — has sync tracking frontmatter):
      - Read `$UPDOC_ROOT/templates/project-overview.md` as a base
      - Substitute frontmatter: `{name}` -> project name, `{commit}` -> head, `{date}` -> current date
      - Write inside `<!-- updoc:begin -->` ~ `<!-- updoc:end -->`: Project description and purpose summary
      - The `## Sections` at the bottom links to the other 3 files (already in template)
      - Save to: `{docs_config.path}/{docs_config.projects_dir}/{name}/overview.md`

   b. `architecture.md` (minimal frontmatter — `project` only):
      - Read `$UPDOC_ROOT/templates/project-architecture.md` as a base
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: Directory structure, entry points, module organization
      - Save to: `{docs_config.path}/{docs_config.projects_dir}/{name}/architecture.md`

   c. `configuration.md` (minimal frontmatter — `project` only):
      - Read `$UPDOC_ROOT/templates/project-configuration.md` as a base
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: Config files, environment variables, feature flags
      - Save to: `{docs_config.path}/{docs_config.projects_dir}/{name}/configuration.md`

   d. `dependencies.md` (minimal frontmatter — `project` only):
      - Read `$UPDOC_ROOT/templates/project-dependencies.md` as a base
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: Dependencies from package.json, go.mod, pyproject.toml, etc.
      - Save to: `{docs_config.path}/{docs_config.projects_dir}/{name}/dependencies.md`

3. Create wiki files (non-developer service docs, 4 files):

   a. `index.md` (hub file, minimal frontmatter — `project` only):
      - Read `$UPDOC_ROOT/templates/wiki-index.md` as a base
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: Service purpose in plain language, with links to sub-pages
      - Include `## Pages` section linking to features.md, access.md, policies.md
      - Save to: `{docs_config.path}/{docs_config.wiki_dir}/{name}/index.md`

   b. `features.md` (minimal frontmatter — `project` only):
      - Read `$UPDOC_ROOT/templates/wiki-index.md` as a base (reuse template structure)
      - Replace title with `# {name} — Features`
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: Key features the service provides
      - Save to: `{docs_config.path}/{docs_config.wiki_dir}/{name}/features.md`

   c. `access.md` (minimal frontmatter — `project` only):
      - Same template approach
      - Replace title with `# {name} — Access`
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: URLs, environments, deployment info (if discoverable)
      - Save to: `{docs_config.path}/{docs_config.wiki_dir}/{name}/access.md`

   d. `policies.md` (minimal frontmatter — `project` only):
      - Same template approach
      - Replace title with `# {name} — Policies`
      - Substitute frontmatter: `{name}` -> project name
      - Write inside markers: Business rules, environment variables, feature flags
      - Save to: `{docs_config.path}/{docs_config.wiki_dir}/{name}/policies.md`

4. Content guidelines for all files:
   - **Explore the project directly** using Glob, Grep, and Read tools to understand the codebase
   - Write in the language specified by the `language` field
   - **No guessing**: If uncertain about something, ask the user using AskUserQuestion before writing. Do not guess or leave TODOs — resolve ambiguity before documenting.
   - Wiki files: **Plain language**. Avoid code-level details. Focus on what the service does, not how it's built.

#### No-change mode (mode == "no_change")

No code changes since last sync. Skip documentation update for this project.

#### Sync mode (mode == "sync")

1. Read existing docs — all files in both directories:
   - Project files: `{docs_config.path}/{docs_config.projects_dir}/{name}/` (overview.md, architecture.md, configuration.md, dependencies.md)
   - Wiki files: `{docs_config.path}/{docs_config.wiki_dir}/{name}/` (index.md, features.md, access.md, policies.md)

2. Analyze `changed_files` to determine which sections need updating:
   - Directory structure changes -> architecture.md
   - Config/env file changes -> configuration.md
   - Dependency file changes (package.json, go.mod, etc.) -> dependencies.md
   - Feature/logic changes -> overview.md + wiki files as appropriate
   - Only update files where changes are relevant

3. For each file that needs updating:
   - **Replace marker block only**: Rewrite content from `<!-- updoc:begin -->` to `<!-- updoc:end -->` only
   - **Never modify** content outside markers
   - **Frontmatter**: Only update `synced_from` and `synced_at` in `overview.md`. Other files have minimal frontmatter (`project` only) — do not add sync fields to them.
   - Read the changed source files directly using Read tool

### Step 4.5: Update docs/index.md

After processing all projects, update `{docs_config.path}/index.md`:
- If the file does not exist, create it using `$UPDOC_ROOT/templates/docs-index.md` as a base (replace `{hub_name}` with basename of cwd)
- Replace the content inside `<!-- updoc:begin -->` / `<!-- updoc:end -->` markers with the current project table:
  - Read the full project list from `updoc.config.yaml` (not just the ones processed in this run)
  - For each project, add a row: `| {name} | [wiki/{name}/index.md](wiki/{name}/index.md) | [projects/{name}/overview.md](projects/{name}/overview.md) |`
  - Include the table header: `| Project | Wiki | Technical |` and `|---------|------|-----------|`
- Never modify content outside the marker block

### Step 5: Change report

Output the change report in the configured language. List each file individually.

ko example:
```
## updoc 문서 갱신 완료

### updoc (full_scan) — pulled
- 📄 docs/projects/updoc/overview.md 생성
- 📄 docs/projects/updoc/architecture.md 생성
- 📄 docs/projects/updoc/configuration.md 생성
- 📄 docs/projects/updoc/dependencies.md 생성
- 📄 docs/wiki/updoc/index.md 생성
- 📄 docs/wiki/updoc/features.md 생성
- 📄 docs/wiki/updoc/access.md 생성
- 📄 docs/wiki/updoc/policies.md 생성
- 커밋: 592c292

동기화 완료.
```

```
## updoc 문서 갱신 완료

### updoc (sync) — up_to_date
- 📝 docs/projects/updoc/architecture.md 업데이트
- 📝 docs/wiki/updoc/features.md 업데이트
- 커밋: a1b2c3d

동기화 완료.
```

```
## updoc 문서 갱신 완료

### updoc (no_change) — pull_failed
- ⏭️ 마지막 동기화 이후 코드 변경 없음 — 건너뜀
```

en example:
```
## updoc Documentation Updated

### updoc (full_scan) — pulled
- 📄 Created docs/projects/updoc/overview.md
- 📄 Created docs/projects/updoc/architecture.md
- 📄 Created docs/projects/updoc/configuration.md
- 📄 Created docs/projects/updoc/dependencies.md
- 📄 Created docs/wiki/updoc/index.md
- 📄 Created docs/wiki/updoc/features.md
- 📄 Created docs/wiki/updoc/access.md
- 📄 Created docs/wiki/updoc/policies.md
- Commit: 592c292

Sync complete.
```

```
## updoc Documentation Updated

### updoc (sync) — up_to_date
- 📝 Updated docs/projects/updoc/architecture.md
- 📝 Updated docs/wiki/updoc/features.md
- Commit: a1b2c3d

Sync complete.
```

```
## updoc Documentation Updated

### updoc (no_change) — pull_failed
- ⏭️ No code changes since last sync — skipped
```
