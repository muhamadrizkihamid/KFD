# SPRINT_MODES.md
# Defines all sprint mode pipelines
# Read by: Scrum Master (auto-detect step)

---

## AUTO-DETECT HIERARCHY

1. Jira Labels (highest priority — explicit PO intent)
2. Issue Type (Bug, Story, Task, Sub-task)
3. Title Keywords (fallback)
4. Default: `full`

---

## LABEL REFERENCE (set in Jira by PO)

| Label           | Sprint Mode   |
|-----------------|---------------|
| `full`          | full          |
| `api-only`      | api_only      |
| `frontend-only` | frontend_only |
| `hotfix`        | hotfix        |
| `bugfix`        | bugfix        |
| `design`        | design        |
| `audit`         | audit         |

---

## ISSUE TYPE REFERENCE

| Jira Issue Type | Default Mode |
|-----------------|--------------|
| Bug             | bugfix       |
| Story           | full         |
| Task            | full         |
| Sub-task        | bugfix       |

---

## TITLE KEYWORD REFERENCE

| Keywords                     | Mode hint  |
|------------------------------|------------|
| fix, patch, revert           | bugfix     |
| api, endpoint, route         | api_only   |
| audit, security scan         | audit      |

---

## PIPELINE PER MODE

### `full` — All 7 agents
```
SM → Arch → Designer + Sec(plan) → BE + FE → Sec(inline) → Test → SM(close)
```
Use for: New feature with UI + API + data layer

### `api_only` — Skip UI agents
```
SM → Arch → Sec(plan) → BE → Sec(inline) → Test → SM(close)
```
Use for: API changes only, no UI

### `frontend_only` — Skip backend
```
SM → Arch → Designer → Sec(plan) → FE → Sec(inline) → Test → SM(close)
```
Use for: UI changes using existing API

### `bugfix` — Skip Designer
```
SM → Arch(brief) → BE/FE → Sec(inline) → Test → SM(close)
```
Use for: Non-critical bug fix

### `hotfix` — Skip Arch + Designer
```
SM → BE/FE(direct) → Sec(inline) → Test → SM(close)
```
Use for: Critical production bug, clear scope

### `design` — No code produced
```
SM → Arch → Designer → SM(close, no push)
```
Use for: Planning phase, producing specs only

### `audit` — Security only
```
SM → Sec(full scan) → SM(close, no push)
```
Use for: Periodic security review

---

## CLOSE BEHAVIOR PER MODE

| Mode          | Push Code | Docker Verify | Prisma/DB Migrate |
|---------------|-----------|--------------|-------------------|
| full          | Yes       | Yes          | If schema changed |
| api_only      | Yes       | Yes          | If schema changed |
| frontend_only | Yes       | Yes          | No                |
| bugfix        | Yes       | Yes          | If schema changed |
| hotfix        | Yes       | Yes          | If schema changed |
| design        | No        | No           | No                |
| audit         | No        | No           | No                |
