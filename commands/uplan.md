---
name: uplan
description: Plan missions based on project documentation.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
---

# /updoc:uplan

A skill that creates mission (planning) documents based on project documentation.

**Usage:** `/updoc:uplan "mission title"` or `/updoc:uplan` (title decided during conversation)

## Procedure

### Step 1: Find plugin root

Run the following bash to locate the plugin root (`UPDOC_ROOT`):

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

### Step 2: Gather context

Read `updoc.config.yaml` and extract project info:

```bash
yq -o json '{language: .language, projects: [.projects[] | {name, path, default_branch}], docs: .docs}' updoc.config.yaml
```

List existing mission files:

```bash
ls updocs/missions/*.md 2>/dev/null
```

### Step 3: Check documentation existence

For each project, check if `{docs.path}/{docs.projects_dir}/{name}/overview.md` exists.

If any project has no overview.md:
- Warning: "Documentation not found for the following projects: {names}. Running `/updoc:up` first is recommended."
- If user wants to continue, proceed without docs (limited planning)

### Step 4: Load context

1. Read overview.md for all projects that have one
2. Read existing mission files if any (for deduplication + context)

### Step 5: Planning conversation

Have a conversation with the user to flesh out the mission:

1. **Background**: Why this mission is needed
2. **AS-IS**: Current state (based on project docs)
3. **TO-BE**: Target state
4. **Impact Scope**: Which parts of which projects are affected
   - Analyze **based on project docs only**. Do not guess information not in docs
   - If docs are insufficient, mark "TODO: re-analyze after /updoc:up"
5. **API Contracts**: Write if cross-project communication is needed
   - Endpoints + request/response schemas
   - Do not include implementation details (DB schemas, internal logic)
6. **Tasks**: Format as `{project-name}-{number}`
   - Attribute each task to its project
   - Never reuse task numbers

### Step 6: Create mission document

**Language enforcement**: The mission document MUST be written in the language specified by `updoc.config.yaml`'s `language` field. This overrides the conversation language. `"en"` = English, `"ko"` = Korean. This applies to all prose, headings, and descriptions.

1. Template path: Read `$UPDOC_ROOT/templates/mission.md` as a base
2. Substitute frontmatter:
   - `{slug}` → suggested slug or user-specified slug
   - `{date}` → current date (YYYY-MM-DD)
3. Fill each section with planning conversation results
4. Write in the configured language
5. Save file: `{docs.path}/{docs.missions_dir}/{date}-{slug}.md` (date in YYYY-MM-DD format)

### Step 7: Output next steps summary (required)

After mission creation, always output the following (in the configured language):

ko example:
```
## 다음 단계

### 미션: feat-upick-추가
- 📄 updocs/missions/2026-03-03-feat-upick-추가.md 생성됨

### 프로젝트별 태스크
#### updoc
- updoc-1: upick 스킬 구조 설계
- updoc-2: upick.sh 스크립트 구현
- updoc-3: commands/upick.md 작성

### 시작하기
1. `git checkout -b feat/upick`
2. 각 프로젝트 디렉토리에서 태스크 수행:
   - `cd .` (updoc)
```

en example:
```
## Next Steps

### Mission: feat-upick
- 📄 Created updocs/missions/2026-03-03-feat-upick.md

### Tasks by Project
#### updoc
- updoc-1: Design upick skill structure
- updoc-2: Implement upick.sh script
- updoc-3: Write commands/upick.md

### Getting Started
1. `git checkout -b feat/upick`
2. Work on tasks in each project directory:
   - `cd .` (updoc)
```

Include API contract summary if applicable.
