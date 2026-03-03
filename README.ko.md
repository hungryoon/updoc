[English](README.md) | [한국어](README.ko.md)

<div align="center">

# updoc

**상한 문서는 언제나 상한 계획을 낳습니다. updoc이 신선하게 유지해드립니다.**

코드를 스캔해서 문서를 최신 상태로 유지하고,<br>
기억이 아닌 _실제 코드_ 를 기반으로 기능을 기획하는 Claude Code 플러그인입니다.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue?style=for-the-badge)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Plugin-6B4FBB?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIxMCIgZmlsbD0id2hpdGUiLz48L3N2Zz4=)](https://github.com/anthropics/claude-code)
[![bash](https://img.shields.io/badge/bash-3.2+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

<br>

```
/updoc:up
```

**첫 문서 생성까지 2분이면 충분합니다.** 설치 → 실행 → 끝.

[빠른 시작](#빠른-시작) · [작동 방식](#작동-방식) · [명령어](#명령어) · [설정](#설정)

</div>

---

## 문제

프로젝트를 여러 개 동시에 개발하다 보면, 새 기능이 필요할 때 Claude에게 기획을 맡기게 됩니다.

그런데 Claude가 참고하는 문서는 6주 전이 마지막 업데이트입니다.

문서와 실제 코드의 차이를 메우려고 Claude는 소스 코드를 직접 읽기 시작합니다. 파일 하나, 또 하나, 또 하나. 토큰이 녹아내립니다.

그렇게 토큰을 태우고 나온 기획 결과:

- 3주 전에 **이름을 바꾼** 모듈
- 지난 스프린트에 **삭제한** 엔드포인트
- 화요일 새벽 2시에 **포기한** 패턴

토큰은 토큰대로 쓰고, 잘못된 기획은 직접 잡아내야 합니다. 수동으로. 매번.

---

## 해결

```
/updoc:up       →  문서를 코드에 맞춥니다. 지금 바로.
/updoc:uplan    →  최신 문서를 기반으로 기능을 기획합니다.
```

명령어 두 개. 그게 전부입니다.

---

## 빠른 시작

### 1. 설치

```
/plugin marketplace add hungryoon/updoc
/plugin install updoc@updoc
```

### 2. 실행

```
/updoc:up
```

처음 실행하면 updoc이 프로젝트를 감지하고 자동으로 설정합니다.

다음에 코드를 머지하면 다시 실행하세요. 문서가 최신 상태로 유지됩니다.

---

## 작동 방식

### 루프

보통 문서화는 일방통행입니다: 문서 작성 → 방치 → 문서 부패 → 반복.

updoc은 순환합니다:

```
    ┌──────────────────────────────────────────────────────┐
    │                                                      │
    ▼                                                      │
 /updoc:up                                                 │
 코드 스캔 → 메타데이터 추출 → 문서 생성                       │
    │                                                      │
    ▼                                                      │
 /updoc:uplan "기능"                                        │
 실제 문서 읽기 → 영향 분석 → 미션 문서 + 태스크               │
    │                                                      │
    ▼                                                      │
 feat 브랜치에서 구현                                        │
 (Superpowers, Cursor, 원하는 도구 — updoc은 상관하지 않음)    │
    │                                                      │
    ▼                                                      │
 main에 머지 ──────────────────────────────────────────────┘
```

사이클을 돌릴수록 문서는 정확해지고, 기획의 맥락은 현실에 가까워집니다.

**순환은 끊기지 않습니다. 문서는 뒤처지지 않습니다.**

### 결과물

**`/updoc:up` 실행 후** — `updocs/projects/my-project/overview.md`가 생성됩니다:

```markdown
---
project: my-project
type: nestjs
synced_from: a1b2c3d
synced_at: 2026-03-03
---

# my-project

직접 작성한 소개. updoc은 이 부분을 절대 건드리지 않습니다.

<!-- updoc:begin -->

## Overview

A REST API service built with NestJS, handling user authentication
and payment processing.

## Directory Structure

src/
├── modules/
│ ├── auth/
│ ├── payments/
│ └── users/
├── guards/
└── main.ts

## Entry Points

- `src/main.ts`

## Configuration Files

- `nest-cli.json`, `tsconfig.json`, `.env.example`

## Dependencies

@nestjs/core, @nestjs/jwt, stripe, prisma

<!-- updoc:end -->

## 아키텍처 메모

이 섹션은 제 것입니다. updoc이 절대 건드리지 않습니다.
```

**`/updoc:uplan "게임 탭 추가"` 실행 후** — `updocs/missions/feat-game-tab.md`가 생성됩니다:

```markdown
---
slug: feat-game-tab
status: draft
branch: feat/game-tab
---

# feat-game-tab

## Background

Users currently have no in-app engagement features beyond core functionality.

## Impact Scope

- api: New /games endpoint, score tracking module
- web: Game tab component, leaderboard page

## API Contracts

POST /api/games/complete
→ { game_id, score, duration }
← { rank, personal_best, leaderboard_position }

## Tasks

- api-1: Create games module with score tracking
- api-2: Add leaderboard query endpoint
- web-1: Build game tab with embedded game component
- web-2: Add leaderboard page with real-time updates
```

---

## 명령어

### `/updoc:up` — 문서를 코드에 맞추기

기본 브랜치에서 코드를 스캔하고, 문서를 생성하거나 갱신합니다.

|                   | 최초 실행                      | 이후                          |
| ----------------- | ------------------------------ | ----------------------------- |
| **동작**          | `overview.md`를 처음부터 생성  | 마커 블록만 갱신              |
| **사용자 메모**   | —                              | **절대 수정하지 않습니다.**   |
| **읽는 범위**     | 전체 프로젝트 스캔             | 마지막 동기화 이후 변경분만   |

**브랜치 보호:** `main` (또는 설정된 기본 브랜치)에서만 실행됩니다. 피처 브랜치에서는 차단됩니다. 머지된 코드만 문서에 반영됩니다.

**추측 금지:** Extractor가 찾지 못한 정보는 Claude도 쓰지 않습니다. 그럴듯한 거짓말 대신 `TODO: 수동 확인 필요`를 남깁니다.

### `/updoc:uplan` — 현실 기반 기획

```
/updoc:uplan "결제 시스템 추가"
```

지금 실제로 존재하는 문서를 읽고, 미션 문서를 생성합니다:

- **영향 범위** — 어떤 프로젝트의 어떤 부분이 영향을 받는지
- **API 계약** — 엔드포인트 + 요청/응답 스키마 (프로젝트 간 통신이 있을 때)
- **태스크 목록** — 프로젝트별로 할당되어 바로 작업 가능

프로젝트 문서가 없으면 추측하지 않고 _"`/updoc:up`을 먼저 실행하세요."_ 라고 안내합니다.

---

## 멀티 프로젝트

updoc은 레포가 아닌 **프로젝트** 단위로 동작합니다. 모노레포든, 멀티레포든 상관없습니다.

```json
{
  "projects": [
    { "name": "api",    "path": "./packages/api" },
    { "name": "web",    "path": "./packages/web" },
    { "name": "shared", "path": "./packages/shared" }
  ]
}
```

`/updoc:up` 한 번 → 모든 프로젝트 문서화.
`/updoc:uplan` 한 번 → 프로젝트 간 영향 분석 + API 계약.

---

## 원칙

> 제안이 아닙니다. updoc이 지키는 규칙입니다.

**문서는 현실을 반영합니다.** 머지된 코드만 문서화됩니다. 피처 브랜치에서는 실행이 차단됩니다. 문서는 항상 실제 동작 중인 코드의 스냅샷입니다.

**추측하지 않습니다.** Extractor는 파일 시스템에서 구조화된 메타데이터를 추출합니다 — LLM이 개입하지 않습니다. Claude는 그 데이터만 보고 문서를 작성합니다. 데이터에 없으면 쓰지 않습니다.

**사용자 메모는 절대 건드리지 않습니다.** 마커 블록 시스템 (`<!-- updoc:begin/end -->`)이 updoc 영역과 사용자 영역을 구분합니다. 직접 작성한 메모, 아키텍처 결정, 주의사항 — 매번 동기화해도 그대로 보존됩니다.

**기획만 합니다. 구현은 하지 않습니다.** `/updoc:uplan`은 _무엇을_ 어디에 만들지를 정의합니다. _어떻게_ 만들지는 실행 도구가 결정합니다. [Superpowers](https://github.com/obra/superpowers), GSD 등 원하는 도구와 함께 사용할 수 있습니다.

---

## 세션 시작

세션을 시작하면 updoc이 현재 상태를 보여줍니다:

```
📋 updoc v0.1.0
프로젝트: 3개 등록 / 3개 동기화 완료
마지막 동기화: 2026-03-03 (a1b2c3d)

⚡ 진행 중 미션:
  - feat-game-tab (in-progress, 브랜치: feat/game-tab)

💡 /updoc:up — 문서 갱신  |  /updoc:uplan — 기획 시작
```

미션 브랜치가 머지되면 updoc이 자동으로 감지합니다:

```
feat-game-tab 브랜치가 머지되었습니다. 미션을 완료 처리할까요? [Y/n]
```

---

## updoc이 아닌 것

|              | updoc                         | updoc이 아닌 것             |
| ------------ | ----------------------------- | --------------------------- |
| **목적**     | 문서화 & 기획                 | 코드 생성                   |
| **범위**     | "무엇을, 어디에 만들지"       | "어떻게 만들지"             |
| **읽는 것**  | 구조화된 메타데이터           | 소스 코드 직접              |
| **의견**     | 머지된 코드만, 추측 없음      | 기술 스택에 대한 의견 없음  |

updoc은 **무엇을 만들지**를 담당합니다. [Superpowers](https://github.com/obra/superpowers) 같은 도구가 **어떻게 만들지**를 담당합니다. 같이 쓰면 좋습니다.

```
updoc:        스캔 → 문서화 → 기획 → API 계약 + 태스크
                                          ↓
Superpowers:                    브랜치 → 구현 → 테스트 → 리뷰 → 머지
                                                                       ↓
updoc:                                              머지 감지 → 문서 갱신
```

---

## 설정

### 필수 조건

`bash` 3.2+ &nbsp;·&nbsp; `jq` 1.6+ &nbsp;·&nbsp; `git`

### 설치

```
/plugin marketplace add hungryoon/updoc
/plugin install updoc@updoc
```

### 설정 파일

`/updoc:up`을 처음 실행하면 `updoc.config.json`이 자동으로 생성됩니다. 수동 설정이 필요 없습니다.

<details>
<summary><strong>설정 레퍼런스</strong></summary>

| 필드                        | 설명                            | 기본값       |
| --------------------------- | ------------------------------- | ------------ |
| `language.display`          | CLI 출력 언어                   | `ko`         |
| `language.document`         | 생성되는 문서 언어              | `en`         |
| `projects[].type`           | 프레임워크 (`null` = 자동 감지) | `null`       |
| `projects[].default_branch` | 문서 갱신 대상 브랜치           | `main`       |
| `docs.path`                 | 문서 루트                       | `./updocs`   |
| `docs.projects_dir`         | 프로젝트 문서 하위 디렉토리     | `projects`   |
| `docs.missions_dir`         | 미션 문서 하위 디렉토리         | `missions`   |

</details>

<details>
<summary><strong>멀티 프로젝트 (Hub 모드)</strong></summary>

여러 프로젝트를 관리하는 문서 전용 레포:

```bash
mkdir my-docs && cd my-docs && git init
git clone git@github.com:org/api.git projects/api
git clone git@github.com:org/web.git projects/web
/updoc:up   # projects/ 하위 프로젝트를 자동 감지
```

</details>

---

<details>
<summary><strong>내부 구조</strong></summary>

### Extractor

파일 시스템에서 구조화된 메타데이터를 추출하는 셸 스크립트입니다. LLM 없이 순수 파일 분석만 수행합니다.

```json
{
  "name": "my-api",
  "framework": "nestjs",
  "structure": {
    "directories": ["./src", "./src/modules", "./src/guards"],
    "entry_points": ["src/main.ts"],
    "config_files": ["nest-cli.json", "tsconfig.json"]
  },
  "modules": [],
  "routes": [],
  "dependencies": { "dependencies": ["@nestjs/core", "stripe"] }
}
```

Claude는 Extractor가 찾은 것만 문서화합니다. 그 이상은 쓰지 않습니다.

현재(Phase 1)는 **generic extractor** (트리 + 진입점 + 설정 파일)를 제공합니다.
프레임워크별 extractor (NestJS, Next.js, FastAPI)는 이후 버전에서 추가됩니다.

### 마커 블록

```
synced_from: abc1234   ← updoc이 갱신
synced_at: 2026-03-03  ← updoc이 갱신

# Project Name

직접 작성한 소개        ← 사용자 영역. 수정 안 함.

<!-- updoc:begin -->
(자동 생성)             ← UPDOC 영역. 매 동기화마다 갱신.
<!-- updoc:end -->

## 내 메모              ← 사용자 영역. 수정 안 함.
```

### 미션 생명주기

```
draft  →  in-progress  →  done
  ↑          ↑               ↑
uplan     작업 시작      updoc이 머지된
생성                     브랜치를 감지
```

</details>

---

## License

Apache-2.0

---

<div align="center">

**상한 문서는 언제나 상한 계획을 낳습니다. updoc이 신선하게 유지해드립니다.**

`/updoc:up`

</div>
