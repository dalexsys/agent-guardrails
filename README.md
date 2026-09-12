# AI Agent Guardrails & Multi-Agent Skills Pack

Universal security guardrails, fail-safe rules, and multi-agent coordination skills for **Cursor**, **Claude Code**, **GitHub Copilot**, **OpenCode**, and **Antigravity**.

Designed to prevent autonomous agents and subagents from implementing unfinished, deferred, or dangerous changes.

---

## ⚡ Quick Start (Install in 1 Command)

Run inside the root directory of any repository on any machine:

```bash
curl -fsSL https://raw.githubusercontent.com/dalexsys/agent-guardrails/main/install.sh | bash
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
