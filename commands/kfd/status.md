---
name: kfd:status
description: Show KFD sprint status and squad state
allowed-tools:
  - Read
  - Bash
---

<objective>
Display current state of the Agent Squad for this project.
</objective>

<steps>

## Step 1 — Check initialization

```bash
ls .agent-squad 2>/dev/null || echo "NOT_INIT"
```

If not initialized → "Not initialized. Run /agent-squad:init"

## Step 2 — Read active sprint context

Read `.agent-squad/context/active-sprint.md`

## Step 3 — Read .env.local

```bash
source .env.local 2>/dev/null
echo "Project : $PROJECT_NAME"
echo "Issue   : $ISSUE_KEY"
echo "Remote  : $GIT_REMOTE"
echo "Jira    : $JIRA_URL / $JIRA_PROJECT"
echo "App     : $APP_URL"
```

## Step 4 — Read Jira issue status (if ISSUE_KEY set)

```bash
source .agent-squad/lib/jira.sh
jira_read_issue "$ISSUE_KEY"
```

## Step 5 — Read recent sprint history

Read last 3 entries from `.agent-squad/context/completed-sprints.md`

## Step 6 — Display summary

```
Agent Squad Status — [PROJECT_NAME]

Active Sprint : [ISSUE_KEY] — [title] — [status]
Sprint Mode  : [mode]
Loop-back    : [N/3]

Last 3 Sprints:
  [ISSUE-1] [title] — DONE
  [ISSUE-2] [title] — IN REVIEW
  [ISSUE-3] [title] — BLOCKED

Open Tech Debt: [count] items
  Run /agent-squad:status --debt to see full list

Remote : [GIT_REMOTE] (GitHub [owner/repo] + GitLab [project])
App    : [APP_URL]
```

</steps>
