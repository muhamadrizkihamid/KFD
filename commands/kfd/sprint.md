---
name: kfd:sprint
description: Run a full KFD sprint end-to-end (Scrum Master → all agents → IN REVIEW)
argument-hint: "[ISSUE_KEY]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Agent
---

<objective>
Orchestrate a complete KFD sprint autonomously: from IN PLANNING through every agent in the
detected pipeline, with loop-back routing on rejections, until the Jira board reaches IN REVIEW
(or BLOCKED on hard-stop).

This command IS the orchestrator. It runs in the main thread. Each squad agent is invoked via
the **Agent tool** (with `subagent_type: "squad-<role>"`). Sub-agents return structured
trailers (`VERDICT:`, `INVOKE_NEXT:`, `SPRINT_MODE:`, `LOOP_COUNT:`) that you parse to decide
the next step.

Do NOT do agent work yourself. You are the conductor — agents are the musicians.

If ISSUE_KEY is passed as argument, override the value in `.env.local` before starting.
</objective>

<state-machine>
The orchestrator implements a 6-step state machine. Every loop-back, hard-stop, and close
decision flows through these states:

1. **INIT** — Validate env + tokens; invoke `squad-scrum-master` with `PHASE: SPRINT_START`;
   parse return trailer for `SPRINT_MODE`.

2. **PIPELINE** — Walk the agent sequence for the detected mode (with parallel branches in
   `full` mode). Each agent invocation includes the issue context and is expected to end with
   a `VERDICT:` trailer.

3. **VERDICT** — After every agent returns, parse its final lines for one of:
   `DONE` / `CLEAR` / `RISK` / `APPROVED` / `REJECTED` / `BLOCKED`. Branch accordingly.

4. **LOOP-BACK** — On `REJECTED` (Tester) or `RISK` containing HIGH severity (Security):
   invoke `squad-scrum-master` with `PHASE: LOOP_BACK_ROUTE`, pass the failing comment,
   read its `INVOKE_NEXT:` to know which agent to re-run. Continue from that re-run point
   forward (Security inline + Tester always re-execute after a fix).

5. **HARD-STOP** — If `LOOP_COUNT` exceeds 3 OR Security HIGH stays unresolved after a
   loop-back attempt OR Scrum Master returns `INVOKE_NEXT: ESCALATE`: invoke `squad-scrum-master`
   with `PHASE: ESCALATE_TO_PO`, then exit. Do NOT call CLOSE.

6. **CLOSE** — Tester returns `APPROVED`: invoke `squad-scrum-master` with `PHASE: SPRINT_CLOSE`
   and the detected `SPRINT_MODE`. It commits, pushes, runs Docker, moves the board to IN
   REVIEW, posts the SPRINT REPORT.
</state-machine>

<invocation-shape>
Every agent call uses the Agent tool with this shape (pseudocode — actual call is JSON via
the Agent tool):

```
Agent(
  subagent_type: "squad-<role>",        // e.g. "squad-architect"
  description:   "<3-5 word summary>",  // e.g. "Architect spec for KO-1"
  prompt:        "<full prompt body — see templates per agent below>"
)
```

The full conversation/file context is NOT inherited by the sub-agent. Pass everything it
needs explicitly in the prompt body.
</invocation-shape>

<steps>

## Step 1 — Validate initialization

```bash
ls .agent-squad 2>/dev/null || echo "NOT_INIT"
```

If the output is `NOT_INIT` → tell the user: `Project not initialized. Run /kfd:init first.` and stop.

## Step 2 — Load .env.local and resolve ISSUE_KEY

```bash
source .env.local
echo "Issue   : $ISSUE_KEY"
echo "Project : $PROJECT_NAME"
echo "Jira    : $JIRA_URL"
```

If an argument was passed (e.g. `/kfd:sprint PROJ-42`), update `.env.local` so `ISSUE_KEY` reflects
the new value, then re-source. Use the Edit tool on `.env.local`, never `sed`.

## Step 3 — Validate tokens

Confirm none of these are placeholder values (`your_*_here`): `JIRA_TOKEN`, `GITHUB_TOKEN`,
and `GITLAB_TOKEN` if `GIT_REMOTE` is `gitlab` or `both`. If any is placeholder, list which
ones to the user and stop.

## Step 4 — INIT: Scrum Master Sprint Start

Invoke `squad-scrum-master` via the Agent tool with this prompt body:

```
PHASE: SPRINT_START
ISSUE_KEY: <ISSUE_KEY from env>

Run only the SPRINT START PROTOCOL section of your agent definition:
  - Read Jira issue
  - Auto-detect SPRINT_MODE
  - Update .agent-squad/context/active-sprint.md (set Loop-back: 0/3)
  - Move board to "In Progress"
  - Post SPRINT STARTED comment to Jira

End your final message with these two lines exactly, on their own lines, no markdown:
  SPRINT_MODE: <full|api_only|frontend_only|bugfix|hotfix|design|audit>
  VERDICT: DONE

Do NOT call other agents. Do NOT run close protocol.
```

Parse the agent's return for `SPRINT_MODE: <value>`. Store as `SPRINT_MODE`. Initialize
`LOOP_COUNT=0`.

Verdict handling for SPRINT_START:
- `VERDICT: DONE` → continue to Step 5.
- `VERDICT: BLOCKED` → SM detected a board transition failure. Print to user the SM's
  full Reason line (and any "Available transitions" / "Current status" hints from its
  output). DO NOT call any other agent. The user must fix the workflow or move the board
  manually, then re-run `/kfd:sprint`. Exit.
- Trailer missing or any other verdict → abort with: "Scrum Master SPRINT_START did not
  return a parseable VERDICT trailer. Full return text:" followed by the agent's last 30
  lines verbatim. Exit.

Note: when SPRINT_START succeeds, the active-sprint.md file is now populated with the issue
identity, why-this-mode rationale, AC, and pipeline plan. From this point onward, you (the
orchestrator) are responsible for appending verdicts to its `## Progress log` section after
each agent return — see Step 5b.

## Step 5 — PIPELINE: dispatch by SPRINT_MODE

Based on `SPRINT_MODE`, follow exactly one of the pipeline blocks below. After each agent returns,
**always** parse its final lines for `VERDICT:` and any `Severity:` markers. The decision logic
after every agent is in **Step 6**.

### Common context block

Every non-SM agent invocation should include this header in the prompt body so the agent has
the run-time context it cannot derive from its own definition file:

```
ISSUE_KEY: <value>
SPRINT_MODE: <value>
PROJECT_NAME: <value from env>

You are running as part of an orchestrated /kfd:sprint pipeline. Follow your agent definition's
WORK PROTOCOL exactly. Read the inputs it lists. Post the Jira comment(s) it specifies.

End your final chat message with the trailer described in your agent file's "Return trailer"
section. Without it, the orchestrator will halt the sprint with an error.
```

### Pipeline: `full`

**5.1** Invoke `squad-architect` (sequential). Prompt body = common context + this:
```
PHASE: ARCHITECT
Produce .agent-squad/tasks/$ISSUE_KEY-PROMPT.md and .agent-squad/checklist/$ISSUE_KEY-TESTER.md
per your WORK PROTOCOL. Trailer required: VERDICT: DONE
```

**5.2** In a **single message**, invoke **both** of the following via two parallel Agent calls.
Wait for both to return before continuing.

- `squad-app-designer` — prompt body = common context + this:
  ```
  PHASE: UI_SPEC
  Read .agent-squad/tasks/$ISSUE_KEY-PROMPT.md, produce .agent-squad/design/$ISSUE_KEY-UI-SPEC.md
  Trailer required: VERDICT: DONE
  ```
- `squad-security-analyst` — prompt body = common context + this:
  ```
  PHASE: PLANNING_REVIEW
  Read .agent-squad/tasks/$ISSUE_KEY-PROMPT.md and steering/security.md.
  Post planning review comment per TRIGGER POINT 1 of your agent definition.
  Trailer required: VERDICT: CLEAR or VERDICT: FLAGS
  ```

**5.3** In a **single message**, invoke **both** of the following via two parallel Agent calls.
Pass each developer the planning-review FLAGS list (if any) from 5.2.

- `squad-backend-developer` — prompt body = common context + this:
  ```
  PHASE: IMPLEMENT_BE
  Read .agent-squad/tasks/$ISSUE_KEY-PROMPT.md and steering/{tech,security,testing}.md.
  Implement, test, and post the 4 mandatory outputs + DONE comment per your WORK PROTOCOL.
  Planning review flags to address: <flags from 5.2 or "none">
  Trailer required: VERDICT: DONE
  ```
- `squad-frontend-developer` — prompt body = common context + this:
  ```
  PHASE: IMPLEMENT_FE
  Read .agent-squad/design/$ISSUE_KEY-UI-SPEC.md, .agent-squad/tasks/$ISSUE_KEY-PROMPT.md, and steering/{tech,testing}.md.
  Implement, test, and post the 4 mandatory outputs + DONE comment per your WORK PROTOCOL.
  Planning review flags to address: <flags from 5.2 or "none">
  Trailer required: VERDICT: DONE
  ```

**5.4** Invoke `squad-security-analyst` (sequential). Prompt body = common context + this:
```
PHASE: INLINE_REVIEW
Review BE + FE implementations per TRIGGER POINT 2 of your agent definition.
Trailer required: VERDICT: CLEAR or VERDICT: RISK (with Severity: line if RISK)
```

**5.5** Invoke `squad-tester` (sequential). Prompt body = common context + this:
```
PHASE: TEST
Read .agent-squad/checklist/$ISSUE_KEY-TESTER.md and verify all prerequisites + items per your WORK PROTOCOL.
Trailer required: VERDICT: APPROVED or VERDICT: REJECTED (or VERDICT: BLOCKED if prerequisites missing)
```

**5.6** On `APPROVED` → go to Step 8 (CLOSE).

### Pipeline: `api_only`

Same structure as `full`, but **omit App Designer entirely** and **omit Frontend Developer**.
Order: `squad-architect` → `squad-security-analyst (PLANNING_REVIEW)` → `squad-backend-developer`
→ `squad-security-analyst (INLINE_REVIEW)` → `squad-tester` → CLOSE.

When invoking `squad-tester`, add to the prompt: `Skip the FE 4-outputs prerequisite — sprint mode is api_only.`

### Pipeline: `frontend_only`

`squad-architect` → `squad-app-designer` → `squad-security-analyst (PLANNING_REVIEW)`
→ `squad-frontend-developer` → `squad-security-analyst (INLINE_REVIEW)` → `squad-tester` → CLOSE.

When invoking `squad-tester`, add: `Skip the BE 4-outputs prerequisite — sprint mode is frontend_only.`

### Pipeline: `bugfix`

**5.1** Invoke `squad-architect` with prompt suffix: `BRIEF_MODE: true — produce a brief spec
only, no full design. Identify whether the fix is BE, FE, or both, and state it clearly in
your DONE comment's Handoff line.`

**5.2** Parse the architect's `Handoff:` line to determine BE / FE / both. Invoke the relevant
developer(s). If both, parallel-invoke in a single message.

**5.3** `squad-security-analyst (INLINE_REVIEW)` → **5.4** `squad-tester` → CLOSE.

### Pipeline: `hotfix`

**5.1** Read the SM start comment to determine BE/FE scope. If unclear, parallel-invoke both
developers. Add to each developer's prompt: `HOTFIX_MODE: true — work directly from the Jira
issue description. There is no architect prompt file. Skip the prompt-file-read step in your
WORK PROTOCOL.`

**5.2** `squad-security-analyst (INLINE_REVIEW)` → **5.3** `squad-tester` → CLOSE.

When invoking the Tester for hotfix, add: `The architect checklist file does not exist for
hotfix mode — derive your checklist from the Jira issue acceptance criteria directly.`

### Pipeline: `design`

`squad-architect` → `squad-app-designer` → CLOSE (no devs, no security, no tester).
Scrum Master will skip code push and Docker per its close-behavior matrix.

### Pipeline: `audit`

Invoke `squad-security-analyst` with prompt body = common context + this:
```
PHASE: AUDIT_FULL_SCAN
Run codebase-wide security scan per your HARD RULES (audit mode line). Post a RISK REPORT
comment to Jira summarizing findings with severity levels.
Trailer required: VERDICT: DONE (regardless of findings — they are reported, not blocking)
```
Then go directly to CLOSE.

## Step 5b — Append to active-sprint.md after EVERY agent return

Immediately after parsing each agent's `VERDICT:` trailer (and BEFORE deciding next steps in
Step 6), append a single line to `.agent-squad/context/active-sprint.md` under the
`## Progress log` section.

Format:
```
- [HH:MM] [AGENT-ID] — <verdict> — <one-line summary you derive from the return text>
```

Examples:
```
- [09:42] [squad-architect] — DONE — produced PROMPT.md + TESTER.md, 3 BE files + 2 FE files planned
- [09:51] [squad-app-designer] — DONE — UI spec for /login redirect-back flow
- [09:51] [squad-security-analyst PLANNING_REVIEW] — FLAGS — flag localStorage token exposure
- [10:08] [squad-backend-developer] — DONE — auth middleware, 12 tests passing
- [10:09] [squad-frontend-developer] — DONE — AuthGuard component, all states handled
- [10:14] [squad-security-analyst INLINE_REVIEW] — CLEAR — no HIGH severity findings
- [10:18] [squad-tester] — APPROVED — all 8 checklist items + 4 AC pass
```

Use the Edit tool to append. This is the orchestrator's job — agents do not write to
`active-sprint.md` themselves, so YOU must do this. Without this, `completed-sprints.md`
at close time will be missing the chronological pipeline trace.

## Step 6 — VERDICT handling (after every agent return)

Parse the agent's return text for the trailer line `VERDICT: <value>`. Apply this table:

| Returning agent       | Verdict             | Next action                                                                      |
|-----------------------|---------------------|----------------------------------------------------------------------------------|
| any                   | `DONE`              | Continue to next pipeline step                                                   |
| Security planning     | `CLEAR` or `FLAGS`  | Continue (devs will address flags inline)                                        |
| Security inline       | `CLEAR`             | Continue to Tester                                                               |
| Security inline       | `RISK` (HIGH)       | LOOP-BACK with payload = security comment                                        |
| Security inline       | `RISK` (LOW/MED)    | Continue to Tester (debt logged)                                                 |
| Tester                | `APPROVED`          | Go to Step 8 (CLOSE)                                                             |
| Tester                | `REJECTED`          | LOOP-BACK with payload = tester rejection comment                                |
| Tester                | `BLOCKED`           | Hard error — surface to user, do not auto-fix                                    |
| any                   | missing/garbled     | Abort with: "Agent X did not return a parseable VERDICT trailer"                 |

Severity detection for Security: search the agent's return text for `Severity: HIGH` or
`HIGH severity`. If present and verdict is `RISK`, treat as HIGH.

## Step 7 — LOOP-BACK handler

When triggered, invoke `squad-scrum-master` via the Agent tool with this prompt:

```
PHASE: LOOP_BACK_ROUTE
ISSUE_KEY: <value>
LOOP_COUNT: <current count>
FAILING_AGENT: <agent-id-that-returned-rejection>
FAILURE_PAYLOAD:
<the failing agent's full return text>

Run the LOOP-BACK ROUTING PROTOCOL section of your definition. Determine target agent,
update active-sprint.md loop-back counter, post routing comment to Jira.

End with:
  INVOKE_NEXT: <agent-id-or-ESCALATE>
  LOOP_COUNT: <new count>
```

Parse Scrum Master's return for `INVOKE_NEXT: <value>` and `LOOP_COUNT: <new>`.

- `INVOKE_NEXT: ESCALATE` → go to **Step 9** (HARD-STOP).
- `INVOKE_NEXT: <agent-id>` → invoke that agent with the failure payload as additional context
  in its prompt body, then **re-run Security inline + Tester from there** (always re-validate
  after a fix).

Update local `LOOP_COUNT` to the value returned by Scrum Master.

If `LOOP_COUNT > 3` after the increment, jump to HARD-STOP without invoking anyone else.

## Step 8 — CLOSE: Scrum Master Sprint Close

Before invoking, read `.agent-squad/context/active-sprint.md` so you can hand SM the full
progress log + identity block. This avoids SM having to re-derive everything from Jira.

Invoke `squad-scrum-master` via the Agent tool with this prompt:

```
PHASE: SPRINT_CLOSE
ISSUE_KEY: <value>
SPRINT_MODE: <SPRINT_MODE>
LOOP_COUNT_USED: <final LOOP_COUNT>

Run only the SPRINT CLOSE PROTOCOL section of your definition.
Honor the close-behavior matrix for SPRINT_MODE — design and audit must NOT push or run Docker.

When you write the entry into completed-sprints.md, source the substantive content from:
  - .agent-squad/context/active-sprint.md (progress log + identity block, already populated by the orchestrator)
  - The DONE comments posted to Jira by Architect, Backend Developer, Frontend Developer
    (call jira_read_issue + scan recent comments via curl)
  - The Security Analyst's inline review comment (LOW/MEDIUM findings → tech debt)

Do NOT write literal "<...>" placeholders. The completed-sprints.md entry must be
substantive — anyone reading it next quarter should understand what the sprint produced
and which decisions matter for future work.

End your final message with: VERDICT: DONE
(or VERDICT: CLOSE_FAILED with a Reason: line if anything failed — including board
transition to IN REVIEW failing.)
```

If `VERDICT: DONE`: print to user a concise summary —
```
✓ Sprint <ISSUE_KEY> closed (mode: <SPRINT_MODE>)
✓ Board: IN REVIEW
✓ App: <APP_URL> (verified)
Loop-backs used: <LOOP_COUNT>/3
```

If `VERDICT: CLOSE_FAILED`: surface the Scrum Master's Reason line directly to the user, do
not retry automatically (close failures usually mean push/docker errors that need human eyes).

## Step 9 — HARD-STOP handler

Invoke `squad-scrum-master` via the Agent tool with this prompt:

```
PHASE: ESCALATE_TO_PO
ISSUE_KEY: <value>
Reason: <one of: loop_back_exceeded | scope_change | security_high_unresolved>
Last failure: <relevant excerpt>

Run the ESCALATION PROTOCOL: move board to BLOCKED, post escalation comment, set
active-sprint.md Status: BLOCKED.

End with: VERDICT: ESCALATED
```

Then print to user:
```
✗ Sprint <ISSUE_KEY> halted — escalated to Product Owner
✗ Board: BLOCKED
Reason: <reason>
Re-run /kfd:sprint after PO resolves the blocker.
```

EXIT — do not call CLOSE.

</steps>

<orchestration-rules>

These are non-negotiable rules for you (the orchestrator) while running this command:

1. **Never do agent work yourself.** No code edits, no Jira posts, no design. Only Bash for env
   loading + token check, and the Agent tool for spawning sub-agents. Edit on `.env.local` only
   when the user passes ISSUE_KEY as argument.

2. **Always invoke parallel agents in a single message.** In `full` mode, the Designer + Security
   planning step (5.2) and the BE + FE step (5.3) MUST be a single message containing two Agent
   tool calls. Sequential invocation defeats the parallelism.

3. **Always parse the trailer.** Every Agent return must yield a `VERDICT:` line. If absent,
   abort with a clear error — do not guess the verdict from prose.

4. **Loop-back goes through Scrum Master.** Never decide routing yourself. The routing logic
   lives in `squad-scrum-master.md` LOOP-BACK ROUTING PROTOCOL section.

5. **After a successful fix loop-back, always re-run Security inline + Tester.** Skipping
   re-validation is a hard rule violation.

6. **Never re-invoke an agent that returned successfully.** Forward progress only, except when
   loop-back routing explicitly says to re-run.

7. **Surface every halt to the user with the reason.** Hard-stops, abort-on-missing-trailer, and
   close failures all need a clear single-paragraph explanation.

</orchestration-rules>
