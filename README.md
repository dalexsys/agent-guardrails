# AI Agent Guardrails & Multi-Agent Skills Pack

Universal security guardrails, fail-safe rules, and multi-agent coordination skills for **Cursor**, **Claude Code**, **GitHub Copilot**, **OpenCode**, and **Antigravity**.

Designed to prevent autonomous agents and subagents from implementing unfinished, deferred, or dangerous changes.

---

## ⚡ Quick Start (Install in 1 Command)

Run inside the root directory of any repository on any machine:

```bash
# Via GitHub CLI (recommended):
gh repo clone dalexsys/agent-guardrails /tmp/ag -- --depth=1 && /tmp/ag/install.sh && rm -rf /tmp/ag

# Or via Git SSH:
git clone --depth=1 git@github.com:dalexsys/agent-guardrails.git /tmp/ag && /tmp/ag/install.sh && rm -rf /tmp/ag
```

*(Tip: Add `alias init-guardrails='gh repo clone dalexsys/agent-guardrails /tmp/ag -- --depth=1 && /tmp/ag/install.sh && rm -rf /tmp/ag'` to your `~/.zshrc` or `~/.bashrc` to run it with a single word).*

---

## 🤖 Готовый промпт для любого ИИ-агента (Prompt for Agents)

Если вы открыли чат с агентом (Cursor, Claude Code, Antigravity, OpenCode, Codex и т.д.) в любом другом проекте и хотите, чтобы агент сам всё подключил, просто отправьте ему этот текст:

### Русский вариант:
```text
Подключи в наш проект правила безопасности и мультиагентные скиллы из репозитория dalexsys/agent-guardrails.
Выполни в корне проекта команду:
gh repo clone dalexsys/agent-guardrails /tmp/ag -- --depth=1 && /tmp/ag/install.sh && rm -rf /tmp/ag
Убедись, что созданы AGENTS.md, симлинки адаптеров (.cursorrules, CLAUDE.md и т.д.) и проверены скиллы opsx-team.
```

### English version:
```text
Install AI agent security guardrails and multi-agent skills from dalexsys/agent-guardrails.
Run in project root:
gh repo clone dalexsys/agent-guardrails /tmp/ag -- --depth=1 && /tmp/ag/install.sh && rm -rf /tmp/ag
Verify AGENTS.md, adapter symlinks (.cursorrules, CLAUDE.md), and opsx-team skills.
```

---

## 🛡️ The 4-Layer Defense Architecture

| Layer | Component | How It Protects |
|---|---|---|
| **Layer 1** | **Single Source of Truth + Adapters** | `AGENTS.md` sets core rules. Thin adapters (`.cursorrules`, `CLAUDE.md`, `.github/copilot-instructions.md`) route all LLMs to it. |
| **Layer 2** | **Directory Naming Convention** | Naming deferred changes with `STOP-...` (e.g. `openspec/changes/STOP-feature/`) provides physical filesystem-level gating. |
| **Layer 3** | **Runtime Protocol Guardrails** | OpenSpec CLI injects `STOP / СТОП Guardrail` in `operationGuidance` on every task fetch. |
| **Layer 4** | **Subagent Circuit Breaker** | Worker subagents (`opsx-worker`, `opsx2-worker-backend`, etc.) check change names and abort immediately if marked `STOP` or `СТОП`. |

---

## 📦 What Gets Installed

```text
├── AGENTS.md                          # Core guidelines & execution guardrails
├── .cursorrules                       # Cursor IDE rules adapter
├── CLAUDE.md                          # Claude Code adapter
├── .github/
│   └── copilot-instructions.md       # GitHub Copilot adapter
├── .cursor/
│   ├── commands/                      # /opsx-team, /opsx-team2 slash commands
│   └── skills/                        # Multi-agent coordinator skills
├── .opencode/
│   ├── agent/                         # Worker subagents with STOP circuit-breakers
│   ├── commands/                      # OpenCode slash commands
│   └── skills/                        # OpenCode Go tier routing skills
└── .agent/
    ├── workflows/                     # Antigravity workflows
    └── skills/                        # Antigravity skills
```

---

## 🛑 How to Freeze an OpenSpec Change

To prevent any agent or subagent from touching a change:

1. **Prefix the change folder with `STOP-`**:
   ```bash
   git mv openspec/changes/my-feature openspec/changes/STOP-my-feature
   ```

2. **Add the STOP banner to `proposal.md` and `tasks.md`**:
   ```markdown
   > [!CAUTION]
   > ### 🛑 STOP / СТОП — STRICT AGENT EXECUTION GUARDRAIL
   > Automated implementation is strictly forbidden without explicit human confirmation.
   ```

Any coordinator (`opsx-team`, `opsx-team2`) and subagent will automatically skip it during inventory and code execution.

---

## 📄 License

MIT
