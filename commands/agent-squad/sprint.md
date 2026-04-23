---
name: agent-squad:sprint
description: Start a sprint for the current ISSUE_KEY in .env.local
argument-hint: "[ISSUE_KEY]"
allowed-tools:
  - Read
  - Write
  - Bash
---

<objective>
Trigger a sprint for the current project. Activates the squad-scrum-master agent to begin.

If ISSUE_KEY is passed as argument, override the value in .env.local.
</objective>

<steps>

## Step 1 — Validate initialization

```bash
ls .agent-squad 2>/dev/null || echo "NOT_INIT"
```

If `.agent-squad/` does not exist → tell user: "Project not initialized. Run /agent-squad:init first."

## Step 2 — Load ISSUE_KEY

```bash
source .env.local
echo "Issue: $ISSUE_KEY"
echo "Project: $PROJECT_NAME"
echo "Jira: $JIRA_URL"
```

If argument provided (e.g. `/agent-squad:sprint PROJ-42`), use that as ISSUE_KEY and update .env.local.

## Step 3 — Validate tokens

Check that these are not placeholder values:
- `JIRA_TOKEN` — must not be `your_jira_token_here`
- `GITHUB_TOKEN` — must not be `your_github_token_here`

If any token is placeholder → tell user which tokens still need to be filled.

## Step 4 — Hand off to Scrum Master

Activate the `squad-scrum-master` agent with full context:
- Current project directory
- .env.local values
- .agent-squad/ structure

The Scrum Master will:
1. Read the Jira issue
2. Auto-detect sprint mode
3. Begin the sprint pipeline
</steps>
