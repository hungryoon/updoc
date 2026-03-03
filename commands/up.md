---
name: up
description: 프로젝트 코드를 스캔해서 문서를 생성/갱신합니다.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
---

# /updoc:up

프로젝트 코드를 스캔해서 기술 문서를 생성(init) 또는 갱신(sync)하는 스킬.

## 실행 절차

### Step 1: 플러그인 루트 탐색 및 up.sh 실행

아래 bash를 실행해서 플러그인 루트(`UPDOC_ROOT`)를 찾고 up.sh를 실행한다:

```bash
# 1) 개발 모드: cwd에 scripts/up.sh가 있으면 여기가 플러그인 루트
if [ -f "./scripts/up.sh" ] && [ -f "./.claude-plugin/plugin.json" ]; then
  UPDOC_ROOT="."
# 2) 마켓플레이스 설치: 캐시에서 탐색
else
  UPDOC_ROOT=$(find ~/.claude/plugins/cache -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi

# 3) 못 찾으면 마켓플레이스 디렉토리 탐색
if [ -z "$UPDOC_ROOT" ] || [ ! -f "$UPDOC_ROOT/scripts/up.sh" ]; then
  UPDOC_ROOT=$(find ~/.claude/plugins/marketplaces -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi
```

UPDOC_ROOT를 찾지 못하면 에러: "updoc 스크립트를 찾을 수 없습니다. 플러그인이 설치되어 있는지 확인하세요."

이후 모든 스크립트/템플릿 참조에 `$UPDOC_ROOT`를 사용한다:
- 스크립트: `$UPDOC_ROOT/scripts/`
- 템플릿: `$UPDOC_ROOT/templates/`

### Step 1.5: 초기 설정 확인

`updoc.config.json`이 현재 디렉토리에 존재하는지 확인한다.

#### 이미 존재하는 경우 → Step 2로 진행

#### 존재하지 않는 경우 → 초기 설정 흐름:

1. init.sh 실행:
```bash
bash "$UPDOC_ROOT/scripts/init.sh"
```

2. stdout의 JSON을 파싱한다. `mode` 필드에 따라 분기:

**mode: "empty"** (프로젝트 코드가 감지되지 않은 경우):
- 아래 디렉토리를 생성한다:
  - `projects/`
  - `updocs/projects/`
  - `updocs/missions/`
- config는 생성하지 않는다
- 안내 메시지를 출력하고 종료:
```
프로젝트 코드가 감지되지 않았습니다.

디렉토리 구조를 생성했습니다:
  projects/
  updocs/projects/
  updocs/missions/

projects/ 폴더에 프로젝트를 clone한 뒤 다시 /updoc:up을 실행하세요.
예: git clone git@github.com:org/api.git projects/api
```

**mode: "single"** (현재 디렉토리가 프로젝트인 경우):
- 감지된 프로젝트 정보를 표시:
```
updoc 초기 설정을 시작합니다.

감지된 프로젝트:
  이름: {name}
  경로: .
  브랜치: {default_branch}
  프레임워크: {type}

이 설정으로 진행할까요? 프로젝트 설명을 추가하려면 입력해주세요.
```
- AskUserQuestion으로 사용자에게 확인
- AskUserQuestion으로 language 선택 (ko/en)
- `updoc.config.json`을 Write로 생성 (templates/config.json 구조 참고, projects 배열에 감지된 프로젝트 추가)
- Step 2로 계속 진행

**mode: "hub"** (projects/ 하위에 프로젝트가 감지된 경우):
- 감지된 프로젝트 목록을 표시:
```
projects/ 하위에서 프로젝트를 감지했습니다:
  1. {name} ({type}) — {path}
  2. {name} ({type}) — {path}

이 프로젝트들을 등록하고 문서를 생성할까요?
```
- AskUserQuestion으로 사용자에게 확인
- AskUserQuestion으로 language 선택
- `updoc.config.json`을 Write로 생성 (모든 감지된 프로젝트 포함)
- Step 2로 계속 진행

### Step 2: up.sh 실행

```bash
bash "$UPDOC_ROOT/scripts/up.sh"
```

stdout의 JSON 배열을 파싱한다. exit code가 0이 아니면 에러 JSON.

### Step 3: 에러 처리

JSON 배열의 각 항목에 `error` 필드가 있으면 에러. 하나라도 에러면 전부 중단.

에러별 안내:
- `branch_mismatch`: "{name}: default branch({default_branch})에서만 실행할 수 있습니다. 현재 브랜치: {current_branch}"
- `not_found`: "{name}: 프로젝트 경로를 찾을 수 없습니다."
- `git_not_available`: "{name}: git 저장소가 아닙니다."
- `extractor_failed`: "{name}: 코드 분석 실패 — {detail}"

에러 출력 후 종료. 문서 작성을 진행하지 않는다.

### Step 4: 프로젝트별 문서 처리

JSON 배열의 각 프로젝트에 대해 `mode`에 따라 분기:

#### Init 모드 (mode == "init")

1. docs 디렉토리 생성:
   ```
   {docs_config.path}/{docs_config.projects_dir}/{name}/
   {docs_config.path}/{docs_config.projects_dir}/{name}/domains/
   {docs_config.path}/{docs_config.missions_dir}/
   ```

2. `overview.md` 생성:
   - `$UPDOC_ROOT/templates/project-overview.md` 를 Read로 읽어 기반으로 생성
   - frontmatter 치환: `{name}` → 프로젝트 이름, `{type}` → type, `{commit}` → head, `{date}` → 현재 날짜
   - `<!-- updoc:begin -->` ~ `<!-- updoc:end -->` 마커 블록 안에 문서 내용 작성

3. 마커 블록 내용 작성 규칙:
   - **extraction JSON만 보고 작성**. 코드 파일을 직접 읽지 않는다.
   - language 언어로 작성 (en이면 영어, ko이면 한국어)
   - 작성 섹션:
     - **Overview**: 프로젝트 설명 (config의 description + extraction 기반)
     - **Directory Structure**: extraction.structure.directories 기반 트리
     - **Entry Points**: extraction.structure.entry_points (있으면)
     - **Configuration Files**: extraction.structure.config_files (있으면)
     - **Dependencies**: extraction.dependencies (있으면)
   - modules, routes, models가 빈 배열이면 해당 섹션을 생략하거나 "Generic extractor는 이 정보를 추출하지 않습니다. 프레임워크별 extractor가 필요합니다." 명시
   - **추측 금지**: extraction에 없는 정보를 추측하지 않음. 불확실하면 `TODO: 수동 확인 필요` 표기

#### Sync 모드 (mode == "sync")

1. 기존 overview.md 읽기:
   ```
   {docs_config.path}/{docs_config.projects_dir}/{name}/overview.md
   ```

2. **마커 블록만 교체**:
   - `<!-- updoc:begin -->` 부터 `<!-- updoc:end -->` 까지의 내용만 새로 작성
   - 마커 밖 내용은 **절대 수정하지 않는다**
   - frontmatter의 `synced_from`과 `synced_at`만 갱신

3. 내용 작성:
   - extraction 기반으로 마커 블록 내용을 새로 작성 (init과 동일한 규칙)
   - `changed_files`가 있으면 변경된 파일의 실제 코드를 읽어서 문서에 반영할지 Claude가 판단
   - 단, 마커 블록 밖에 사용자가 작성한 내용은 절대 건드리지 않는다

### Step 5: 미션 상태 감지

`missions_in_progress`에 `merged: true`인 항목이 있으면:
- 사용자에게 확인: "{slug} 브랜치({branch})가 머지됐습니다. 미션을 완료 처리할까요?"
- Y → 미션 파일의 frontmatter `status`를 `done`으로 변경
- N → 유지

### Step 6: sync state 갱신

각 프로젝트에 대해:
```bash
bash "$UPDOC_ROOT/scripts/update-sync-state.sh" "{name}" "{head}" "{type}"
```

### Step 7: 변경 리포트

language 언어로 변경 리포트 출력.

ko 예시:
```
## updoc 문서 갱신 완료

### updoc (init)
- 📄 updocs/projects/updoc/overview.md 생성
- 커밋: 592c292
- 타입: generic (extractor: generic)

동기화 상태가 updoc.config.json에 저장되었습니다.
```

en 예시:
```
## updoc Documentation Updated

### updoc (init)
- 📄 Created updocs/projects/updoc/overview.md
- Commit: 592c292
- Type: generic (extractor: generic)

Sync state saved to updoc.config.json.
```
