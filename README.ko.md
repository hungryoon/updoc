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
/updoc:init     →  새 문서 레포에 updoc을 설정합니다.
/updoc:up       →  문서를 코드에 맞춥니다. 지금 바로.
/updoc:uplan    →  최신 문서를 기반으로 기능을 기획합니다.
```

명령어 세 개. 그게 전부입니다.

---

## 빠른 시작

### 1. 설치

```
/plugin marketplace add hungryoon/updoc
/plugin install updoc@updoc
```

### 2. 문서 레포 구성

```bash
mkdir my-docs && cd my-docs && git init
```

### 3. 레포 클론

프로젝트를 `repos/`에 클론합니다:

```bash
git clone git@github.com:org/api.git repos/api
git clone git@github.com:org/web.git repos/web
```

### 4. 초기화

```
/updoc:init
```

updoc이 `repos/`를 스캔해서 프로젝트를 감지하고 다음을 생성합니다:
- `updoc.config.yaml` — 프로젝트 등록 + 설정
- `docs/` — 문서 디렉토리
- `.gitignore` — `repos/`를 커밋에서 제외

### 5. 문서 생성

```
/updoc:up
```

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
 코드 스캔 → 프로젝트 탐색 → 문서 생성                         │
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

**`/updoc:up` 실행 후** — `docs/projects/my-project/overview.md`가 생성됩니다:

```markdown
---
project: my-project
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

**`/updoc:uplan "게임 탭 추가"` 실행 후** — `docs/missions/feat-game-tab.md`가 생성됩니다:

```markdown
---
slug: feat-game-tab
created: 2026-03-03
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

### `/updoc:init` — 문서 설정

`repos/`에서 코드 프로젝트를 스캔하고, `updoc.config.yaml`에 등록하고, 문서 디렉토리 구조를 설정합니다. 문서 레포당 한 번만 실행합니다.

동작 순서:
1. `repos/` 하위 프로젝트 감지 (기본 브랜치)
2. 확인 질문
3. 등록된 프로젝트로 `updoc.config.yaml` 생성
4. `docs/` 디렉토리 구조 생성
5. `.gitignore`에 `repos/` 추가

### `/updoc:up` — 문서를 코드에 맞추기

기본 브랜치에서 코드를 스캔하고, 문서를 생성하거나 갱신합니다.

|                   | 최초 실행                                    | 이후                          |
| ----------------- | -------------------------------------------- | ----------------------------- |
| **동작**          | `overview.md` + 프로젝트 파일 3개 + 위키 파일 4개 생성 | 마커 블록만 갱신              |
| **사용자 메모**   | —                                            | **절대 수정하지 않습니다.**   |
| **읽는 범위**     | 전체 프로젝트 탐색                           | 마지막 동기화 이후 변경분만   |

**브랜치 보호:** `main` (또는 설정된 기본 브랜치)에서만 실행됩니다. 피처 브랜치에서는 차단됩니다. 머지된 코드만 문서에 반영됩니다.

**추측 금지:** Claude가 코드베이스에서 확인할 수 없는 정보는 쓰지 않습니다. 그럴듯한 거짓말 대신 AskUserQuestion으로 사용자에게 확인합니다.

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

## 디렉토리 구조

프로젝트를 `repos/` 하위에 클론하고, 문서는 별도로 관리합니다. 문서 커밋이 코드 히스토리를 방해하지 않습니다.

```
my-docs/                  ← 문서 레포
├── repos/                ← git clone된 소스코드 (gitignored)
│   ├── api/
│   └── web/
├── docs/                 ← 문서 루트 (커밋 대상)
│   ├── index.md
│   ├── wiki/             ← 무엇을 하는가
│   ├── projects/         ← 어떻게 만들어졌는가
│   └── missions/         ← 무엇을 만들 것인가
└── updoc.config.yaml     ← 설정 (커밋 대상)
```

`/updoc:up` 한 번 → 모든 프로젝트 문서화 (기술 문서 + 위키 문서).
`/updoc:uplan` 한 번 → 프로젝트 간 영향 분석 + API 계약.

### 프로젝트 추가

1. `repos/`에 클론:
   ```bash
   git clone git@github.com:org/payments.git repos/payments
   ```

2. `updoc.config.yaml`에 추가:
   ```yaml
   projects:
     - name: api
       path: ./repos/api
       default_branch: main
     - name: payments          # ← 추가
       path: ./repos/payments
       default_branch: main
   ```

3. `/updoc:up`을 실행하면 새 프로젝트의 문서가 생성됩니다.

---

## 원칙

> 제안이 아닙니다. updoc이 지키는 규칙입니다.

**문서는 현실을 반영합니다.** 머지된 코드만 문서화됩니다. 피처 브랜치에서는 실행이 차단됩니다. 문서는 항상 실제 동작 중인 코드의 스냅샷입니다.

**추측하지 않습니다.** Claude가 Glob, Grep, Read 도구로 코드베이스를 직접 탐색합니다. 코드에서 확인할 수 없으면 AskUserQuestion으로 사용자에게 확인합니다.

**사용자 메모는 절대 건드리지 않습니다.** 마커 블록 시스템 (`<!-- updoc:begin/end -->`)이 updoc 영역과 사용자 영역을 구분합니다. 직접 작성한 메모, 아키텍처 결정, 주의사항 — 매번 동기화해도 그대로 보존됩니다.

**기획만 합니다. 구현은 하지 않습니다.** `/updoc:uplan`은 _무엇을_ 어디에 만들지를 정의합니다. _어떻게_ 만들지는 실행 도구가 결정합니다. [Superpowers](https://github.com/obra/superpowers), GSD 등 원하는 도구와 함께 사용할 수 있습니다.

---

## 세션 시작

세션을 시작하면 updoc이 현재 상태를 보여줍니다:

```
📋 updoc v0.3.2
프로젝트: 3개 등록 / 3개 동기화 완료
마지막 동기화: 2026-03-03 (a1b2c3d)

💡 /updoc:up — 문서 갱신  |  /updoc:uplan — 기획 시작
```

---

## updoc이 아닌 것

|              | updoc                         | updoc이 아닌 것             |
| ------------ | ----------------------------- | --------------------------- |
| **목적**     | 문서화 & 기획                 | 코드 생성                   |
| **범위**     | "무엇을, 어디에 만들지"       | "어떻게 만들지"             |
| **읽는 것**  | 코드베이스 직접 탐색          | —                           |
| **의견**     | 머지된 코드만, 추측 없음      | 기술 스택에 대한 의견 없음  |

updoc은 **무엇을 만들지**를 담당합니다. [Superpowers](https://github.com/obra/superpowers) 같은 도구가 **어떻게 만들지**를 담당합니다. 같이 쓰면 좋습니다.

```
updoc:        스캔 → 문서화 → 기획 → API 계약 + 태스크
                                          ↓
Superpowers:                    브랜치 → 구현 → 테스트 → 리뷰 → 머지
                                                                       ↓
updoc:                                                         다시 실행 → 문서 갱신
```

---

## 설정

### 필수 조건

`bash` 3.2+ &nbsp;·&nbsp; `yq` 4+ &nbsp;·&nbsp; `git`

### 설치

```
/plugin marketplace add hungryoon/updoc
/plugin install updoc@updoc
```

### 설정 파일

`/updoc:init`을 실행하면 `updoc.config.yaml`이 생성됩니다. 이 파일은 레포에 커밋됩니다.

<details>
<summary><strong>설정 레퍼런스</strong></summary>

| 필드                        | 설명                            | 기본값       |
| --------------------------- | ------------------------------- | ------------ |
| `language`                  | 출력 및 문서 언어               | `en`         |
| `projects[].default_branch` | 문서 갱신 대상 브랜치           | `main`       |
| `docs.path`                 | 문서 루트                       | `./docs`     |
| `docs.projects_dir`         | 기술 문서 하위 디렉토리         | `projects`   |
| `docs.wiki_dir`             | 위키 문서 하위 디렉토리         | `wiki`       |
| `docs.missions_dir`         | 미션 문서 하위 디렉토리         | `missions`   |

</details>

---

<details>
<summary><strong>내부 구조</strong></summary>

### 코드 탐색

Claude가 Glob, Grep, Read 도구로 코드베이스를 직접 탐색합니다. 셸 기반 extractor 없이 — Claude가 코드를 읽고 이해하여 더 풍부하고 정확한 문서를 생성합니다.

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

### 미션

미션 문서는 `docs/missions/`에 저장됩니다. slug와 생성일만 있는 간단한 마크다운 파일이며 — 나머지(브랜치, 머지, 생명주기)는 git이 관리합니다.

</details>

---

## License

Apache-2.0

---

<div align="center">

**상한 문서는 언제나 상한 계획을 낳습니다. updoc이 신선하게 유지해드립니다.**

`/updoc:up`

</div>
