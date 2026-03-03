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

### Step 1: Find plugin root and gather context

Run the following bash to locate the plugin root (`UPDOC_ROOT`):

```bash
# 1) Dev mode: if scripts/uplan-prepare.sh exists in cwd, this is the plugin root
if [ -f "./scripts/uplan-prepare.sh" ] && [ -f "./.claude-plugin/plugin.json" ]; then
  UPDOC_ROOT="."
# 2) Marketplace install: search cache
else
  UPDOC_ROOT=$(find ~/.claude/plugins/cache -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi

# 3) Fallback: search marketplaces directory
if [ -z "$UPDOC_ROOT" ] || [ ! -f "$UPDOC_ROOT/scripts/uplan-prepare.sh" ]; then
  UPDOC_ROOT=$(find ~/.claude/plugins/marketplaces -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi
```

If UPDOC_ROOT is not found, error: "Cannot find updoc scripts. Please verify the plugin is installed."

### Step 2: Gather context

```bash
bash "$UPDOC_ROOT/scripts/uplan-prepare.sh" "{title}"
```

Parse JSON. If `error` field exists, print error and exit.

### Step 3: Check documentation existence

If any project has `overview_exists: false`:
- Warning: "Documentation not found for the following projects: {names}. Running `/updoc:up` first is recommended."
- If user wants to continue, proceed without docs (limited planning)

### Step 4: Load context

1. Read overview.md for all projects with `overview_exists: true`
2. Reference product_docs if present (skip if none)
3. Read existing mission files if any (for deduplication + context)

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

1. Template path: Read `$UPDOC_ROOT/templates/mission.md` as a base
2. Substitute frontmatter:
   - `{slug}` → suggested_slug or user-specified slug
   - `{date}` → current date (YYYY-MM-DD)
   - `{branch}` → branch name based on slug (e.g., `feat/upick`)
3. Fill each section with planning conversation results
4. Write in the configured language
5. Save file: `{docs_config.path}/{docs_config.missions_dir}/{date}-{slug}.md` (date in YYYY-MM-DD format)

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
2. 미션 파일의 status를 `in-progress`로 변경
3. 각 프로젝트 디렉토리에서 태스크 수행:
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
2. Change mission status to `in-progress`
3. Work on tasks in each project directory:
   - `cd .` (updoc)
```

Include API contract summary if applicable.
