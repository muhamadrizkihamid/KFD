---
name: agent-squad:init
description: Initialize Agent Squad framework in the current project
argument-hint: "[--auto]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

<objective>
Initialize the Agent Squad framework in the current project directory.

This command:
1. Auto-detects project type and structure
2. Asks for project config (or uses --auto to infer from codebase)
3. Creates `.agent-squad/` directory with all config files
4. Creates `.env.local` template with placeholders
5. Creates project-specific steering files (product, tech, structure)
</objective>

<steps>

## Step 1 — Detect project type

Run these checks in parallel:
```bash
# Check project type signals
ls package.json 2>/dev/null && cat package.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('node:', d.get('name','?'), '|', list(d.get('dependencies',{}).keys())[:5])" || true
ls pom.xml 2>/dev/null && echo "java/spring" || true
ls requirements.txt 2>/dev/null && echo "python" || true
ls composer.json 2>/dev/null && echo "php/laravel" || true
ls go.mod 2>/dev/null && echo "golang" || true
ls Cargo.toml 2>/dev/null && echo "rust" || true

# Check existing git remote
git remote -v 2>/dev/null || true

# Check if .env.local already exists
ls .env.local 2>/dev/null && echo "env-exists" || true

# Check if .agent-squad already initialized
ls .agent-squad 2>/dev/null && echo "already-init" || true
```

If `.agent-squad/` already exists → ask user: "Framework already initialized. Reinitialize? (yes/no)"

## Step 2 — Gather project config

Ask the user these questions (one message, collect all answers):

```
Agent Squad — Project Setup

I detected: [auto-detected info from Step 1]

Please confirm or fill in the following:

1. Project name: [detected name or ?]
2. App URL (local dev): [e.g. http://localhost:3000]
3. Default git branch: [main / master / ?]
4. Tech stack summary: [detected or describe briefly]
5. Source folder structure: [e.g. src/controllers/, src/views/ or auto-detect]
6. Docker app service name: [e.g. myapp-api] (leave blank if no Docker)
7. GitHub repo (owner/repo): [e.g. myorg/myapp]
8. GitLab repo (full path): [e.g. group/project] (leave blank if none)
9. GitLab URL: [e.g. https://gitlab.company.com] (leave blank if none)
10. Jira project key: [e.g. PROJ]
11. Jira URL: [e.g. https://company.atlassian.net]
12. Jira email: [your email]
```

If `--auto` flag: infer from codebase, skip questions, use defaults where needed.

## Step 3 — Auto-detect source structure

```bash
# Find key source directories
find . -maxdepth 4 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.java" -o -name "*.py" -o -name "*.php" -o -name "*.go" \) \
  | grep -v node_modules | grep -v .git | grep -v vendor | grep -v __pycache__ \
  | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -15
```

Use the most common directories as the project structure.

## Step 4 — Create .agent-squad/ directory structure

```bash
mkdir -p .agent-squad/lib
mkdir -p .agent-squad/steering
mkdir -p .agent-squad/context
mkdir -p .agent-squad/process
mkdir -p .agent-squad/tasks
mkdir -p .agent-squad/checklist
mkdir -p .agent-squad/design
```

## Step 5 — Create .env.local (if not exists)

Write `.env.local` with all variables filled from user answers + placeholders for tokens:

```bash
# Agent Squad — Environment Variables
# NEVER commit this file.

# Sprint
ISSUE_KEY=[JIRA_PROJECT_KEY]-1

# Project
PROJECT_NAME=[project name]
APP_URL=[app url]
GIT_DEFAULT_BRANCH=[branch]

# Git remote: "origin" | "gitlab" | "both"
GIT_REMOTE=[origin/gitlab/both based on answers]

# GitHub
GITHUB_TOKEN=your_github_token_here
GITHUB_OWNER=[owner]
GITHUB_REPO=[repo]

# GitLab (remove block if not used)
GITLAB_TOKEN=your_gitlab_token_here
GITLAB_URL=[gitlab url]
GITLAB_PROJECT=[gitlab project path]

# Jira
JIRA_URL=[jira url]
JIRA_TOKEN=your_jira_token_here
JIRA_EMAIL=[jira email]
JIRA_PROJECT=[jira project key]

# Docker (remove if not used)
DOCKER_APP_SERVICE=[docker service name]
DOCKER_COMPOSE_FILE=docker-compose.yml

# Database (fill if applicable)
DATABASE_URL=
```

If `.env.local` already exists → only ADD missing keys, do not overwrite existing values.

## Step 6 — Create shared libraries

Write `.agent-squad/lib/jira.sh` — copy from global template at `~/.claude/agent-squad/lib/jira.sh`
Write `.agent-squad/lib/git-remote.sh` — copy from global template at `~/.claude/agent-squad/lib/git-remote.sh`

## Step 7 — Create steering files (project-specific)

Write `.agent-squad/steering/product.md` with:
- Project name from user answers
- App URL
- Jira project key and URL
- Brief description (ask user or leave placeholder)

Write `.agent-squad/steering/tech.md` with:
- Auto-detected tech stack
- Auto-detected source folder paths
- Docker service name and compose file (if applicable)

Write `.agent-squad/steering/structure.md` with:
- Auto-detected folder structure
- GitHub/GitLab remote URLs
- Git branch

Write `.agent-squad/steering/security.md` — copy static template (project-agnostic)
Write `.agent-squad/steering/testing.md` — copy static template (project-agnostic)

## Step 8 — Create process files

Write `.agent-squad/process/SPRINT_MODES.md` — copy from global template
Write `.agent-squad/process/SCRUM_MASTER_PROCESS.md` — copy from global template

## Step 9 — Create context files

Write `.agent-squad/context/active-sprint.md` — initialized as IDLE
Write `.agent-squad/context/completed-sprints.md` — initialized empty

## Step 10 — Update .gitignore

Add `.env.local` to `.gitignore` if not already present.
Add `.agent-squad/tasks/`, `.agent-squad/checklist/`, `.agent-squad/design/` as tracked (do NOT ignore them).

## Step 11 — Post-init summary

Print to user:
```
Agent Squad initialized successfully!

Project : [PROJECT_NAME]
Mode    : [GIT_REMOTE]
Jira    : [JIRA_URL] / [JIRA_PROJECT]

Next steps:
1. Fill in tokens in .env.local:
   - GITHUB_TOKEN
   - GITLAB_TOKEN  (if using GitLab)
   - JIRA_TOKEN

2. In Jira: create an issue and move it to IN PLANNING

3. Set ISSUE_KEY in .env.local, then run:
   /agent-squad:sprint

Files created:
  .agent-squad/
  ├── lib/jira.sh
  ├── lib/git-remote.sh
  ├── steering/ (5 files)
  ├── context/  (2 files)
  ├── process/  (2 files)
  └── tasks/ checklist/ design/ (empty, filled per sprint)
```

</steps>
