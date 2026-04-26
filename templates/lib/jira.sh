#!/usr/bin/env bash
# .agent-squad/lib/jira.sh — shared Jira helpers
# Usage: source .agent-squad/lib/jira.sh
# Requires: JIRA_URL, JIRA_EMAIL, JIRA_TOKEN, ISSUE_KEY from .env.local

set -euo pipefail

if [ -z "${JIRA_URL:-}" ]; then
  source .env.local
fi

jira_read_issue() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY" | python3 -c "
import sys, json
d = json.load(sys.stdin)
f = d['fields']
print('Title    :', f['summary'])
print('Status   :', f['status']['name'])
print('Priority :', f.get('priority', {}).get('name', '?'))
print('Type     :', f.get('issuetype', {}).get('name', '?'))
print('Labels   :', ', '.join(f.get('labels', [])) or 'none')
print('Components:', ', '.join(c['name'] for c in f.get('components', [])) or 'none')
def adf_text(node):
    if not node: return ''
    if node.get('type') == 'text': return node.get('text', '')
    return ' '.join(adf_text(c) for c in node.get('content', []))
desc = f.get('description', '')
print('Description:', adf_text(desc) if isinstance(desc, dict) else (desc or '(empty)'))
"
}

jira_get_labels() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY?fields=labels" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(' '.join(d['fields'].get('labels', [])))
" 2>/dev/null || echo ""
}

jira_get_type() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY?fields=issuetype" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['fields'].get('issuetype', {}).get('name', 'Story'))
" 2>/dev/null || echo "Story"
}

jira_get_title() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY?fields=summary" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['fields'].get('summary', ''))
" 2>/dev/null || echo ""
}

jira_get_components() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY?fields=components" | python3 -c "
import sys, json
d = json.load(sys.stdin)
comps = d['fields'].get('components', [])
print(' '.join(c.get('name','') for c in comps))
" 2>/dev/null || echo ""
}

jira_post_comment() {
  local KEY="${1:-$ISSUE_KEY}"
  local TEXT="$2"
  local PAYLOAD
  PAYLOAD=$(jq -n --arg t "$TEXT" '{
    body: {
      type: "doc", version: 1,
      content: (
        $t | split("\n") | map(
          if length > 0
          then { type: "paragraph", content: [{ type: "text", text: . }] }
          else { type: "paragraph", content: [{ type: "text", text: " " }] }
          end
        )
      )
    }
  }')
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "$JIRA_URL/rest/api/3/issue/$KEY/comment" \
    --data-binary "$PAYLOAD"
}

jira_get_status() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY?fields=status" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['fields'].get('status', {}).get('name', '?'))
" 2>/dev/null || echo "?"
}

jira_list_transitions() {
  local KEY="${1:-$ISSUE_KEY}"
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY/transitions" \
    | jq -r '.transitions[].to.name' 2>/dev/null
}

# Aliases tried in order when the literal target name doesn't match.
# Match is case-insensitive. Workflow names vary across Jira projects.
_jira_transition_aliases() {
  local TARGET_LOWER="$1"
  case "$TARGET_LOWER" in
    "in progress")
      echo "In Progress"
      echo "IN PROGRESS"
      echo "In Development"
      echo "In Dev"
      echo "Doing"
      echo "Start Progress"
      echo "Start Work"
      echo "Started"
      echo "WIP"
      ;;
    "in review")
      echo "In Review"
      echo "IN REVIEW"
      echo "Code Review"
      echo "Review"
      echo "Ready for Review"
      echo "PR Review"
      echo "QA Review"
      ;;
    "blocked")
      echo "Blocked"
      echo "BLOCKED"
      echo "On Hold"
      echo "Paused"
      ;;
    "done")
      echo "Done"
      echo "DONE"
      echo "Closed"
      echo "Resolved"
      echo "Completed"
      ;;
    *)
      # Unknown target: just try the literal value
      echo "$1"
      ;;
  esac
}

jira_transition() {
  local KEY="${1:-$ISSUE_KEY}"
  local TARGET="$2"
  local TRANSITIONS
  TRANSITIONS=$(curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY/transitions")

  local TARGET_LOWER
  TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

  # 1) Try exact literal match (case-insensitive on .to.name).
  local TID
  TID=$(echo "$TRANSITIONS" | jq -r --arg t "$TARGET_LOWER" \
    '.transitions[] | select((.to.name | ascii_downcase) == $t) | .id' | head -1)
  local MATCHED_NAME=""
  if [ -n "$TID" ]; then
    MATCHED_NAME=$(echo "$TRANSITIONS" | jq -r --arg t "$TARGET_LOWER" \
      '.transitions[] | select((.to.name | ascii_downcase) == $t) | .to.name' | head -1)
  fi

  # 2) Walk the alias list for known target buckets.
  if [ -z "$TID" ]; then
    while IFS= read -r ALIAS; do
      [ -z "$ALIAS" ] && continue
      local ALIAS_LOWER
      ALIAS_LOWER=$(echo "$ALIAS" | tr '[:upper:]' '[:lower:]')
      TID=$(echo "$TRANSITIONS" | jq -r --arg t "$ALIAS_LOWER" \
        '.transitions[] | select((.to.name | ascii_downcase) == $t) | .id' | head -1)
      if [ -n "$TID" ]; then
        MATCHED_NAME=$(echo "$TRANSITIONS" | jq -r --arg t "$ALIAS_LOWER" \
          '.transitions[] | select((.to.name | ascii_downcase) == $t) | .to.name' | head -1)
        break
      fi
    done < <(_jira_transition_aliases "$TARGET_LOWER")
  fi

  if [ -z "$TID" ]; then
    local AVAILABLE
    AVAILABLE=$(echo "$TRANSITIONS" | jq -r '.transitions[].to.name' | paste -sd ', ' -)
    echo "ERROR: no transition to '$TARGET' (or known aliases) found for $KEY" >&2
    echo "Available transitions: ${AVAILABLE:-<none>}" >&2
    echo "Current status: $(jira_get_status "$KEY")" >&2
    return 1
  fi

  local RESPONSE
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "$JIRA_URL/rest/api/3/issue/$KEY/transitions" \
    -d "{\"transition\":{\"id\":\"$TID\"}}")

  if [ "$RESPONSE" != "204" ]; then
    echo "ERROR: transition POST returned HTTP $RESPONSE for $KEY → '$MATCHED_NAME' (id $TID)" >&2
    return 1
  fi

  echo "Moved $KEY → $MATCHED_NAME"
}

# Verify the issue is actually in the expected status (or one of its aliases).
# Returns 0 on match, 1 otherwise. Use AFTER jira_transition to confirm the move took effect.
jira_verify_transition() {
  local KEY="${1:-$ISSUE_KEY}"
  local EXPECTED="$2"
  local CURRENT
  CURRENT=$(jira_get_status "$KEY")
  local CURRENT_LOWER EXPECTED_LOWER
  CURRENT_LOWER=$(echo "$CURRENT" | tr '[:upper:]' '[:lower:]')
  EXPECTED_LOWER=$(echo "$EXPECTED" | tr '[:upper:]' '[:lower:]')

  if [ "$CURRENT_LOWER" = "$EXPECTED_LOWER" ]; then
    return 0
  fi

  while IFS= read -r ALIAS; do
    [ -z "$ALIAS" ] && continue
    local ALIAS_LOWER
    ALIAS_LOWER=$(echo "$ALIAS" | tr '[:upper:]' '[:lower:]')
    if [ "$CURRENT_LOWER" = "$ALIAS_LOWER" ]; then
      return 0
    fi
  done < <(_jira_transition_aliases "$EXPECTED_LOWER")

  echo "VERIFY FAILED: $KEY is '$CURRENT', expected '$EXPECTED' (or alias)" >&2
  return 1
}
