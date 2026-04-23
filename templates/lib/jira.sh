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

jira_transition() {
  local KEY="${1:-$ISSUE_KEY}"
  local TARGET="$2"
  local TRANSITIONS
  TRANSITIONS=$(curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/$KEY/transitions")
  local TID
  TID=$(echo "$TRANSITIONS" | jq -r --arg t "$TARGET" \
    '.transitions[] | select(.to.name == $t) | .id' | head -1)
  if [ -z "$TID" ]; then
    echo "ERROR: no transition to '$TARGET' found for $KEY"
    echo "Available: $(echo "$TRANSITIONS" | jq -r '.transitions[].to.name' | tr '\n' ', ')"
    return 1
  fi
  curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "$JIRA_URL/rest/api/3/issue/$KEY/transitions" \
    -d "{\"transition\":{\"id\":\"$TID\"}}"
  echo "Moved $KEY → $TARGET"
}
