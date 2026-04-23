#!/usr/bin/env bash
# KFD — Kimid Falacy Done
# Installer v1.0
# Usage: bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                                                    ║${NC}"
echo -e "${BOLD}║    ██  ██  ████    ████                            ║${NC}"
echo -e "${BOLD}║    ██ ██   ██      ██  ██                          ║${NC}"
echo -e "${BOLD}║    ████    ████    ██  ██                          ║${NC}"
echo -e "${BOLD}║    ██ ██   ██      ██  ██                          ║${NC}"
echo -e "${BOLD}║    ██  ██  ██      ████                            ║${NC}"
echo -e "${BOLD}║                                                    ║${NC}"
echo -e "${BOLD}║    Kimid Falacy Done  —  v1.0                      ║${NC}"
echo -e "${BOLD}║    AI-powered sprint framework for Claude Code     ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Claude Code
if [ ! -d "$CLAUDE_DIR" ]; then
  echo -e "  ${RED}✗${NC} ~/.claude not found. Install Claude Code first."
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Claude Code found"

# Check existing
if [ -d "$CLAUDE_DIR/commands/kfd" ]; then
  echo -e "  ${YELLOW}!${NC} KFD already installed."
  read -r -p "  Update/reinstall? [y/N] " confirm
  [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "  Aborted." && exit 0
fi

echo ""
echo -e "${BOLD}Installing...${NC}"

# Commands
mkdir -p "$CLAUDE_DIR/commands/kfd"
cp "$SCRIPT_DIR/commands/kfd/"*.md "$CLAUDE_DIR/commands/kfd/"
echo -e "  ${GREEN}✓${NC} Commands: /kfd:init  /kfd:sprint  /kfd:status"

# Agents
mkdir -p "$CLAUDE_DIR/agents"
cp "$SCRIPT_DIR/agents/squad-"*.md "$CLAUDE_DIR/agents/"
echo -e "  ${GREEN}✓${NC} 7 agents installed (Scrum Master, Architect, Designers, Developers, Security, Tester)"

# Templates
mkdir -p "$CLAUDE_DIR/kfd/lib" "$CLAUDE_DIR/kfd/steering" "$CLAUDE_DIR/kfd/process"
cp "$SCRIPT_DIR/templates/lib/"*.sh      "$CLAUDE_DIR/kfd/lib/"
cp "$SCRIPT_DIR/templates/steering/"*.md "$CLAUDE_DIR/kfd/steering/"
cp "$SCRIPT_DIR/templates/process/"*.md  "$CLAUDE_DIR/kfd/process/"
chmod +x "$CLAUDE_DIR/kfd/lib/"*.sh
echo -e "  ${GREEN}✓${NC} Template library installed"

echo ""
echo -e "${BOLD}${GREEN}KFD installed successfully!${NC}"
echo ""
echo -e "${BOLD}Cara pakai di project:${NC}"
echo ""
echo -e "  ${BLUE}/kfd:init${NC}    — Setup KFD di project baru"
echo -e "  ${BLUE}/kfd:sprint${NC}  — Mulai sprint dari Jira issue"
echo -e "  ${BLUE}/kfd:status${NC}  — Lihat status sprint aktif"
echo ""
