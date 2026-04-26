#!/usr/bin/env bash
# KFD — Kimid Falacy Done
# Update script: pull latest KFD + patch initialized projects
# Usage:
#   bash update.sh                          — update global only
#   bash update.sh --project /path/myapp    — update global + patch project
#   bash update.sh --skip-pull              — skip git pull (offline)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROJECT=""
SKIP_PULL=0

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project|-p) PROJECT="$2"; shift 2 ;;
    --skip-pull)  SKIP_PULL=1;  shift   ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Header ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}    K F D   -   Kimid Falacy Done${NC}"
echo -e "${CYAN}    Update / Patch Tool${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# ── Step 1: Git pull ───────────────────────────────────────────────────────────
if [[ $SKIP_PULL -eq 0 ]]; then
  echo -e "  Pulling latest KFD from GitHub..."

  git_status=$(git -C "$SCRIPT_DIR" status --porcelain 2>/dev/null || true)
  if [[ -n "$git_status" ]]; then
    echo -e "  ${YELLOW}[!]${NC} Working tree has local changes — skipping git pull."
    echo -e "  ${GRAY}    Commit or stash your changes first, or use --skip-pull.${NC}"
    echo ""
  else
    if git -C "$SCRIPT_DIR" pull --ff-only 2>&1 | sed 's/^/      /'; then
      echo -e "  ${GREEN}[OK]${NC} Pulled latest from origin/main"
    else
      echo -e "  ${YELLOW}[!]${NC} git pull failed — continuing with local version."
    fi
  fi
  echo ""
fi

# ── Step 2: Verify Claude Code ─────────────────────────────────────────────────
if [[ ! -d "$CLAUDE_DIR" ]]; then
  echo -e "  ${RED}[X]${NC} ~/.claude not found. Install Claude Code first."
  exit 1
fi

# ── Step 3: Update global ~/.claude/ files ─────────────────────────────────────
echo -e "  Updating global KFD files..."

mkdir -p "$CLAUDE_DIR/commands/kfd"
cp "$SCRIPT_DIR/commands/kfd/"*.md "$CLAUDE_DIR/commands/kfd/"
echo -e "  ${GREEN}[OK]${NC} Commands updated  (commands/kfd/)"

mkdir -p "$CLAUDE_DIR/agents"
cp "$SCRIPT_DIR/agents/squad-"*.md "$CLAUDE_DIR/agents/"
echo -e "  ${GREEN}[OK]${NC} Agents updated    (agents/squad-*.md)"

mkdir -p "$CLAUDE_DIR/kfd/lib" "$CLAUDE_DIR/kfd/steering" "$CLAUDE_DIR/kfd/process"
cp "$SCRIPT_DIR/templates/lib/"*.sh      "$CLAUDE_DIR/kfd/lib/"
cp "$SCRIPT_DIR/templates/steering/"*.md "$CLAUDE_DIR/kfd/steering/"
cp "$SCRIPT_DIR/templates/process/"*.md  "$CLAUDE_DIR/kfd/process/"
chmod +x "$CLAUDE_DIR/kfd/lib/"*.sh
echo -e "  ${GREEN}[OK]${NC} Templates updated (lib/, steering/, process/)"

KFD_VERSION=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "$KFD_VERSION" > "$CLAUDE_DIR/kfd/.kfd-version"

echo ""
echo -e "  Global update done. ${GRAY}(version: $KFD_VERSION)${NC}"
echo ""

# ── Step 4: Project patch (optional) ──────────────────────────────────────────
if [[ -z "$PROJECT" ]]; then
  echo -e "  Patch an initialized project? (leave blank to skip)"
  read -r -p "  Project path: " PROJECT
  PROJECT="${PROJECT//\"/}"
fi

if [[ -z "$PROJECT" ]]; then
  echo ""
  echo -e "  ${GRAY}Skipped project patch.${NC}"
  echo ""
  echo -e "  ${GRAY}To patch a project later, run:${NC}"
  echo -e "  ${GRAY}  bash update.sh --project <path-to-project>${NC}"
  echo ""
  exit 0
fi

# Validate project
AGENT_SQUAD_DIR="$PROJECT/.agent-squad"
if [[ ! -d "$AGENT_SQUAD_DIR" ]]; then
  echo ""
  echo -e "  ${RED}[X]${NC} .agent-squad/ not found in: $PROJECT"
  echo -e "  ${GRAY}    Run /kfd:init in that project first.${NC}"
  exit 1
fi

echo ""
echo -e "  Patching project: $PROJECT"

# Backup
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_DIR="$AGENT_SQUAD_DIR/.kfd-backup/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

for item in "$AGENT_SQUAD_DIR/lib" "$AGENT_SQUAD_DIR/process" \
            "$AGENT_SQUAD_DIR/steering/security.md" "$AGENT_SQUAD_DIR/steering/testing.md"; do
  [[ -e "$item" ]] && cp -r "$item" "$BACKUP_DIR/"
done
echo -e "  ${GRAY}[OK] Backup saved → .agent-squad/.kfd-backup/$TIMESTAMP/${NC}"

# Patch: lib
mkdir -p "$AGENT_SQUAD_DIR/lib"
cp "$CLAUDE_DIR/kfd/lib/"*.sh "$AGENT_SQUAD_DIR/lib/"
chmod +x "$AGENT_SQUAD_DIR/lib/"*.sh
echo -e "  ${GREEN}[OK]${NC} lib/         patched (jira.sh, git-remote.sh)"

# Patch: process
mkdir -p "$AGENT_SQUAD_DIR/process"
cp "$CLAUDE_DIR/kfd/process/"*.md "$AGENT_SQUAD_DIR/process/"
echo -e "  ${GREEN}[OK]${NC} process/     patched (SPRINT_MODES, SCRUM_MASTER_PROCESS)"

# Patch: steering static only
cp "$CLAUDE_DIR/kfd/steering/security.md" "$AGENT_SQUAD_DIR/steering/"
cp "$CLAUDE_DIR/kfd/steering/testing.md"  "$AGENT_SQUAD_DIR/steering/"
echo -e "  ${GREEN}[OK]${NC} steering/    patched (security.md, testing.md)"
echo -e "  ${GRAY}[--] steering/    kept    (product.md, tech.md, structure.md — project config)${NC}"

# Version marker
echo "$KFD_VERSION" > "$AGENT_SQUAD_DIR/.kfd-version"
echo -e "  ${GREEN}[OK]${NC} .kfd-version written ($KFD_VERSION)"

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "  ${GREEN}KFD updated successfully!${NC}"
echo ""
echo -e "  Global : ~/.claude/commands/kfd/ + agents/ + templates/"
echo -e "  Project: $PROJECT"
echo -e "  Version: $KFD_VERSION"
echo ""
echo -e "  ${GRAY}Backup of overwritten files:${NC}"
echo -e "  ${GRAY}.agent-squad/.kfd-backup/$TIMESTAMP/${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
