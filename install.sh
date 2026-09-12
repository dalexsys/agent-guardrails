#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# AI Agent Guardrails & Multi-Agent Skills Installer
# Target: Cursor, Claude Code, GitHub Copilot, OpenCode, Antigravity
# Repository: https://github.com/dalexsys/agent-guardrails
# ==============================================================================

TARGET_DIR="${1:-$PWD}"
REPO_OWNER="dalexsys"
REPO_NAME="agent-guardrails"
BRANCH="main"

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${BLUE}==> Installing AI Agent Guardrails in: ${TARGET_DIR}${NC}"

# 1. Determine if running locally or via remote curl pipe
SCRIPT_DIR=""
TMP_DIR=""
if [ -f "${BASH_SOURCE[0]:-}" ] && [ -d "$(dirname "${BASH_SOURCE[0]}")/templates" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    echo -e "${BLUE}--> Fetching latest guardrails bundle from GitHub...${NC}"
    if command -v git >/dev/null 2>&1; then
        git clone --quiet --depth=1 "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$TMP_DIR"
        SCRIPT_DIR="$TMP_DIR"
    else
        curl -fsSL "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz" | tar -xz -C "$TMP_DIR"
        SCRIPT_DIR="$TMP_DIR/${REPO_NAME}-${BRANCH}"
    fi
fi

cd "$TARGET_DIR"

# 2. Setup AGENTS.md (Single Source of Truth)
if [ ! -f "AGENTS.md" ]; then
    echo -e "${GREEN}✔ Creating AGENTS.md with strict guardrails...${NC}"
    cp "$SCRIPT_DIR/templates/AGENTS.md" AGENTS.md
else
    if ! grep -q -i "STOP / СТОП" AGENTS.md; then
        echo -e "${YELLOW}✔ Injecting STOP / СТОП freeze rule into existing AGENTS.md...${NC}"
        cat << 'RULE_EOF' >> AGENTS.md

## Strict Rules for Agents

- **STOP / СТОП Change Execution Freeze**: Agents and subagents are **STRICTLY FORBIDDEN** from implementing or modifying any OpenSpec change that contains the marker `STOP` or `СТОП` (case-insensitive: `STOP`, `СТОП`, `[STOP]`, etc.) in its folder name, proposal, or tasks, or contains explicit execution guardrails prohibiting automated implementation without explicit human confirmation. Coordinators (`opsx-team`, `opsx-team2`) MUST automatically skip these changes during inventory, and subagents/apply workflows MUST immediately halt if assigned a change with this marker.
- **Strict Secret Isolation & Vault Policy**: Agents are **STRICTLY FORBIDDEN** from inserting real API keys, production tokens, passwords, or secrets into repository files, deployment scripts, or test fixtures.
RULE_EOF
    else
        echo -e "${GREEN}✔ AGENTS.md already contains STOP / СТОП rule.${NC}"
    fi
fi

# 3. Setup Tool Adapters (.cursorrules, CLAUDE.md, .github/copilot-instructions.md)
echo -e "${GREEN}✔ Installing IDE adapters (.cursorrules, CLAUDE.md, .github/copilot-instructions.md)...${NC}"
cp "$SCRIPT_DIR/templates/.cursorrules" .cursorrules
cp "$SCRIPT_DIR/templates/CLAUDE.md" CLAUDE.md
mkdir -p .github
cp "$SCRIPT_DIR/templates/copilot-instructions.md" .github/copilot-instructions.md

# 4. Install Skills & Commands
# Cursor
mkdir -p .cursor/commands .cursor/skills
cp -r "$SCRIPT_DIR/bundle/.cursor/commands/"* .cursor/commands/
cp -r "$SCRIPT_DIR/bundle/.cursor/skills/"* .cursor/skills/
echo -e "${GREEN}✔ Installed Cursor skills & slash commands (.cursor/skills, .cursor/commands)${NC}"

# OpenCode
mkdir -p .opencode/agent .opencode/commands .opencode/skills
cp -r "$SCRIPT_DIR/bundle/.opencode/agent/"* .opencode/agent/
cp -r "$SCRIPT_DIR/bundle/.opencode/commands/"* .opencode/commands/
cp -r "$SCRIPT_DIR/bundle/.opencode/skills/"* .opencode/skills/
echo -e "${GREEN}✔ Installed OpenCode subagents & skills (.opencode/agent, .opencode/skills)${NC}"

# Antigravity
mkdir -p .agent/workflows .agent/skills
cp -r "$SCRIPT_DIR/bundle/.agent/workflows/"* .agent/workflows/
cp -r "$SCRIPT_DIR/bundle/.agent/skills/"* .agent/skills/
echo -e "${GREEN}✔ Installed Antigravity skills & workflows (.agent/skills, .agent/workflows)${NC}"

# 5. Check OpenSpec config if present
if [ -f "openspec/config.yaml" ]; then
    if ! grep -q -i "STOP / СТОП Guardrail" openspec/config.yaml; then
        echo -e "${YELLOW}ℹ Tip: Add STOP / СТОП Guardrail to 'operations.apply.guidance' in openspec/config.yaml${NC}"
    else
        echo -e "${GREEN}✔ OpenSpec config.yaml contains STOP / СТОП guardrail.${NC}"
    fi
fi

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}🎉 All Agent Guardrails successfully installed!${NC}"
echo -e "   • Active in: Cursor, Claude Code, GitHub Copilot, OpenCode, Antigravity"
echo -e "   • Any OpenSpec change with 'STOP-' or 'СТОП' in its name is now frozen."
echo -e "${BLUE}================================================================${NC}"
