---
name: uplan
description: 프로젝트 문서를 기반으로 미션을 기획합니다.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
---

# /updoc:uplan

프로젝트 문서를 기반으로 미션(기획 문서)을 작성하는 스킬.

**사용법:** `/updoc:uplan "미션 제목"` 또는 `/updoc:uplan` (제목은 대화 중 결정)

## 실행 절차

### Step 1: 플러그인 루트 탐색 및 컨텍스트 수집

아래 bash를 실행해서 플러그인 루트(`UPDOC_ROOT`)를 찾는다:

```bash
# 1) 개발 모드: cwd에 scripts/uplan-prepare.sh가 있으면 여기가 플러그인 루트
if [ -f "./scripts/uplan-prepare.sh" ] && [ -f "./.claude-plugin/plugin.json" ]; then
  UPDOC_ROOT="."
# 2) 마켓플레이스 설치: 캐시에서 탐색
else
  UPDOC_ROOT=$(find ~/.claude/plugins/cache -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi

# 3) 못 찾으면 마켓플레이스 디렉토리 탐색
if [ -z "$UPDOC_ROOT" ] || [ ! -f "$UPDOC_ROOT/scripts/uplan-prepare.sh" ]; then
  UPDOC_ROOT=$(find ~/.claude/plugins/marketplaces -maxdepth 6 -path "*/updoc/*/.claude-plugin/plugin.json" -print -quit 2>/dev/null | sed 's|/.claude-plugin/plugin.json||')
fi
```

UPDOC_ROOT를 찾지 못하면 에러: "updoc 스크립트를 찾을 수 없습니다. 플러그인이 설치되어 있는지 확인하세요."

### Step 2: 컨텍스트 수집

```bash
bash "$UPDOC_ROOT/scripts/uplan-prepare.sh" "{제목}"
```

JSON 파싱. `error` 필드가 있으면 에러 출력 후 종료.

### Step 3: 문서 존재 확인

`overview_exists: false`인 프로젝트가 있으면:
- 경고: "다음 프로젝트의 문서가 아직 없습니다: {names}. `/updoc:up`을 먼저 실행하는 것을 권장합니다."
- 사용자가 계속 진행을 원하면 문서 없이 진행 (제한적 기획)

### Step 4: 컨텍스트 로드

1. `overview_exists: true`인 모든 프로젝트의 overview.md를 Read로 읽기
2. product_docs가 있으면 참조 (없으면 생략)
3. 기존 미션 파일이 있으면 Read로 읽기 (중복 방지 + 컨텍스트)

### Step 5: 기획 대화

사용자와 대화하며 미션을 구체화한다:

1. **배경**: 왜 이 미션이 필요한지
2. **AS-IS**: 현재 상태 (프로젝트 문서 기반)
3. **TO-BE**: 목표 상태
4. **영향 범위**: 어떤 프로젝트의 어떤 부분이 영향받는지
   - **프로젝트 문서 기반으로만** 분석. 문서에 없는 정보는 추측하지 않음
   - 문서가 불충분하면 "TODO: /updoc:up 이후 재분석 필요" 표기
5. **API 계약**: 프로젝트 간 통신이 필요하면 작성
   - 엔드포인트 + request/response 스키마
   - 구현 방식(DB 스키마, 내부 로직)은 적지 않음
6. **태스크**: `{프로젝트명}-{순번}` 형식
   - 각 태스크에 프로젝트 귀속 명시
   - 순번 재사용 금지

### Step 6: 미션 문서 생성

1. 템플릿 경로: `$UPDOC_ROOT/templates/mission.md` 를 Read로 읽어 기반으로 생성
2. frontmatter 치환:
   - `{slug}` → suggested_slug 또는 사용자 지정 slug
   - `{date}` → 현재 날짜 (YYYY-MM-DD)
   - `{branch}` → slug 기반 브랜치명 (예: `feat/upick`)
3. 각 섹션을 기획 대화 결과로 채움
4. language 언어로 작성
5. 파일 저장: `{docs_config.path}/{docs_config.missions_dir}/{date}-{slug}.md` (date는 YYYY-MM-DD 형식)

### Step 7: 다음 단계 요약 출력 (필수)

미션 생성 후 반드시 다음 정보를 출력한다 (language 언어로):

ko 예시:
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

en 예시:
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

API 계약이 있으면 요약도 포함한다.
