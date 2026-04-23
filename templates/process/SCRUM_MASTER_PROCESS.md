# SCRUM_MASTER_PROCESS.md
# Loop-Back Routing for Scrum Master

---

## LOOP-BACK ROUTING TABLE

| Finding                        | Route To           | Action                                   |
|--------------------------------|--------------------|------------------------------------------|
| Code implementation wrong      | BE or FE Developer | Post comment with specific failing items |
| Design-level vulnerability     | Architect          | Post comment requesting spec revision    |
| Spec ambiguous or incomplete   | Architect          | Post comment with ambiguity details      |
| UI not matching UI spec        | Frontend Developer | Post comment with specific mismatches    |
| UI spec unclear                | App Designer       | Post comment requesting spec update      |
| Scope changed mid-sprint       | PO escalation      | Post comment requesting PO decision      |
| Loop-back > 2x same issue      | Architect          | Root cause resolution required           |
| Loop-back > 3x total           | PO escalation      | Sprint halted                            |

---

## LOOP-BACK COUNTER

- Starts at 0 when sprint begins
- Tester REJECTED = +1
- Security HIGH RISK requiring rework = +1
- Counter resets on new sprint (new ISSUE_KEY)
- Track in every routing comment: `Loop-back count: N/3`

---

## ROUTING COMMENT FORMAT

```bash
source .agent-squad/lib/jira.sh
jira_post_comment "$ISSUE_KEY" "$(cat <<'EOF'
[SCRUM MASTER] — LOOP BACK — YYYY-MM-DD

Task    : Routing rejection/risk finding
Verdict : DONE

Details:
- Finding: [summary]
- Severity: [LOW/MEDIUM/HIGH]
- Loop-back count: N/3
- Decision: [routing table row that matched]

Handoff : [Agent] — [specific action required]
EOF
)"
```

---

## ESCALATION TO PO

Trigger: loop-back > 3x OR scope change

```bash
jira_transition "$ISSUE_KEY" "BLOCKED"
jira_post_comment "$ISSUE_KEY" "$(cat <<'EOF'
[SCRUM MASTER] — ESCALATION TO PO — YYYY-MM-DD

Task    : Sprint halted
Verdict : ESCALATED

Blocking issues:
- [issue]

Loop-back count: 3/3 (maximum reached)

Handoff : Product Owner — decide how to proceed before sprint resumes.
EOF
)"
```

---

## HARD RULES

1. Never make technical decisions
2. Never write code
3. Always include loop-back count in routing comments
4. Always escalate to PO at loop-back > 3
5. Never move board to DONE — Product Owner only
6. ISSUE_KEY comes from .env.local — set by PO before sprint
