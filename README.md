[English](README.md) | [한국어](README.ko.md)

<div align="center">

# updoc

**Rotten docs ALWAYS make rotten plans. Updoc keeps them fresh.**

A Claude Code plugin that scans your code, writes living documentation,<br>
and plans features based on what _actually_ exists — not what you remember.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue?style=for-the-badge)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Plugin-6B4FBB?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIxMCIgZmlsbD0id2hpdGUiLz48L3N2Zz4=)](https://github.com/anthropics/claude-code)
[![bash](https://img.shields.io/badge/bash-3.2+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

<br>

```
/updoc:up
```

**First docs in under 2 minutes.** Install → run → done.

[Quick Start](#quick-start) · [How It Works](#how-it-works) · [Commands](#commands) · [Setup](#setup)

</div>

---

## The Problem

You're building across projects. API here, frontend there. You ask Claude to plan a feature.

But the docs Claude reads? Last updated 6 weeks ago.

To fill the gap between docs and reality, Claude starts reading your source code. File after file after file. Tokens melting away.

After burning all those tokens, here's what Claude plans:

- A module you **renamed** three weeks ago
- An endpoint you **deleted** last sprint
- A pattern you **abandoned** at 2am on a Tuesday

Tokens burned. Plans wrong. You fix it yourself. Manually. Every time.

---

## The Fix

```
/updoc:init     →  Set up updoc in a new docs repo.
/updoc:up       →  Docs match your code. Right now.
/updoc:uplan    →  Plan features from real docs, not ancient ones.
```

Three commands. That's the entire API.

---

## Quick Start

### 1. Install

```
/plugin marketplace add hungryoon/updoc
/plugin install updoc@updoc
```

### 2. Set up a docs repo

```bash
mkdir my-docs && cd my-docs && git init
```

### 3. Clone repos

Clone your projects into `repos/`:

```bash
git clone git@github.com:org/api.git repos/api
git clone git@github.com:org/web.git repos/web
```

### 4. Initialize

```
/updoc:init
```

updoc scans `repos/`, detects projects, and creates:
- `updoc.config.yaml` — project registry + settings
- `docs/` — documentation directories
- `.gitignore` — excludes `repos/` from commits

### 5. Generate docs

```
/updoc:up
```

Next time you merge code, run it again. Docs stay current.

---

## How It Works

### The Loop

Most documentation is one-way: write docs → neglect → docs rot → repeat.

updoc is a cycle:

```
    ┌──────────────────────────────────────────────────────┐
    │                                                      │
    ▼                                                      │
 /updoc:up                                                 │
 Scan code → Explore project → Generate docs               │
    │                                                      │
    ▼                                                      │
 /updoc:uplan "feature"                                    │
 Read real docs → Analyze impact → Mission doc + tasks     │
    │                                                      │
    ▼                                                      │
 Build on feat branch                                      │
 (Superpowers, Cursor, your workflow — updoc doesn't care) │
    │                                                      │
    ▼                                                      │
 Merge to main ────────────────────────────────────────────┘
```

Every cycle: docs get more accurate, plans get closer to reality.

**The cycle never breaks. Docs never fall behind.**

### What You Get

**After `/updoc:up`** — generated `docs/projects/my-project/overview.md`:

```markdown
---
project: my-project
synced_from: a1b2c3d
synced_at: 2026-03-03
---

# my-project

My custom intro. updoc never touches this part.

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

## My Architecture Notes

This section is mine. updoc will never touch it. Ever.
```

**After `/updoc:uplan "Add game tab"`** — generated `docs/missions/feat-game-tab.md`:

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

## Commands

### `/updoc:init` — Set Up Docs

Scans `repos/` for code projects, registers them in `updoc.config.yaml`, and sets up the docs directory structure. Run once per docs repo.

What it does:
1. Detects projects under `repos/` (default branch)
2. Asks for confirmation
3. Creates `updoc.config.yaml` with registered projects
4. Creates `docs/` directory structure
5. Adds `repos/` to `.gitignore`

### `/updoc:up` — Make Docs Catch Up

Scans your code on the default branch. Generates or updates documentation.

|                   | First Run                                           | After That                    |
| ----------------- | --------------------------------------------------- | ----------------------------- |
| **What happens**  | Creates `overview.md` + wiki (`{name}.md`) | Updates only the marker block |
| **Your notes**    | —                                                   | **Untouched. Always.**        |
| **What it reads** | Full project exploration                             | Only changes since last sync  |

**Branch protection:** Only runs on `main` (or your default branch). Feature branch → blocked. Only merged code is reflected in docs.

**No guessing:** If Claude can't confirm it from the codebase, it doesn't write it. You'll see `TODO: manual verification needed` instead of plausible lies.

### `/updoc:uplan` — Plan From Reality

```
/updoc:uplan "Add payment system"
```

Reads your actual, current documentation. Produces a mission document with:

- **Impact scope** — which projects, which parts get affected
- **API contracts** — endpoints + request/response schema (if projects talk to each other)
- **Task list** — attributed to each project, ready to hand off

No docs for a project? updoc doesn't guess. It says _"run `/updoc:up` first."_

---

## Directory Structure

Projects are cloned under `repos/`, docs live separately. Documentation commits never interfere with code history.

```
my-docs/                  ← your docs repo
├── repos/                ← git cloned source code (gitignored)
│   ├── api/
│   └── web/
├── docs/                 ← documentation root (committed)
│   ├── index.md
│   ├── wiki/             ← what it does
│   ├── projects/         ← how it's built
│   └── missions/         ← what to build
└── updoc.config.yaml     ← config (committed)
```

One `/updoc:up` → all projects documented (both technical and wiki docs).
One `/updoc:uplan` → cross-project impact analysis + API contracts.

### Adding a Project Later

1. Clone into `repos/`:
   ```bash
   git clone git@github.com:org/payments.git repos/payments
   ```

2. Add to `updoc.config.yaml`:
   ```yaml
   projects:
     - name: api
       path: ./repos/api
       default_branch: main
     - name: payments          # ← new
       path: ./repos/payments
       default_branch: main
   ```

3. Run `/updoc:up` to generate docs for the new project.

---

## Principles

> These are not suggestions. These are rules updoc enforces.

**Docs reflect reality.** Only merged code gets documented. Feature branches are blocked. Your docs are always a snapshot of what's actually running.

**No guessing.** Claude explores your codebase directly using Glob, Grep, and Read. If it can't confirm something from the code, it doesn't write it.

**Your notes are never touched.** The marker block system (`<!-- updoc:begin/end -->`) separates updoc's sections from yours. Notes, architecture decisions, caveats — all preserved through every sync.

**Plans, not implementation.** `/updoc:uplan` defines _what_ to build and _where_. _How_ to build it is up to your execution tool. Pairs well with [Superpowers](https://github.com/obra/superpowers), GSD, or whatever you use.

---

## Session Start

When you start a session, updoc shows you where things stand:

```
📋 updoc v0.3.0
Projects: 3 registered / 3 synced
Last sync: 2026-03-03 (a1b2c3d)

💡 /updoc:up — Update docs  |  /updoc:uplan — Start planning
```

---

## What updoc Is Not

|              | updoc                         | Not updoc                 |
| ------------ | ----------------------------- | ------------------------- |
| **Purpose**  | Document & plan               | Generate code             |
| **Scope**    | "What to build, where"        | "How to build it"         |
| **Reads**    | Your codebase directly        | —                         |
| **Opinions** | Only merged code, no guessing | None about your stack     |

updoc handles **what to build**. Tools like [Superpowers](https://github.com/obra/superpowers) handle **how to build it**. They pair well.

```
updoc:        Scan → Document → Plan → API contracts + tasks
                                          ↓
Superpowers:                    Branch → Implement → Test → Review → Merge
                                                                       ↓
updoc:                                                         Run again → Update docs
```

---

## Setup

### Prerequisites

`bash` 3.2+ &nbsp;·&nbsp; `yq` 4+ &nbsp;·&nbsp; `git`

### Install

```
/plugin marketplace add hungryoon/updoc
/plugin install updoc@updoc
```

### Config

`/updoc:init` generates `updoc.config.yaml` on first run. This file is committed to the repo.

<details>
<summary><strong>Config Reference</strong></summary>

| Field                       | What                             | Default      |
| --------------------------- | -------------------------------- | ------------ |
| `language`                  | Output & docs language           | `en`         |
| `projects[].default_branch` | Branch for doc updates           | `main`       |
| `docs.path`                 | Docs root                        | `./docs`     |
| `docs.projects_dir`         | Technical docs subdirectory      | `projects`   |
| `docs.wiki_dir`             | Wiki docs subdirectory           | `wiki`       |
| `docs.missions_dir`         | Mission docs subdirectory        | `missions`   |

</details>

---

<details>
<summary><strong>Under the Hood</strong></summary>

### Code Exploration

Claude directly explores your codebase using Glob, Grep, and Read tools. No shell-based extractors — Claude reads and understands your code to produce richer, more accurate documentation.

### Marker Blocks

```
synced_from: abc1234   ← updoc updates
synced_at: 2026-03-03  ← updoc updates

# Project Name

My custom intro        ← YOURS. untouched.

<!-- updoc:begin -->
(auto-generated)       ← UPDOC. refreshed every sync.
<!-- updoc:end -->

## My Notes            ← YOURS. untouched.
```

### Missions

Mission documents live in `docs/missions/`. They're simple markdown files with a slug and creation date — git handles the rest (branches, merges, lifecycle).

</details>

---

## License

Apache-2.0

---

<div align="center">

**Rotten docs ALWAYS make rotten plans. Updoc keeps them fresh.**

`/updoc:up`

</div>

