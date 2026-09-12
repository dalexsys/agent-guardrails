# AGENTS.md

Agent-facing guidelines and operational contracts for this repository.

## Strict Rules for Agents

- **STOP / СТОП Change Execution Freeze**: Agents and subagents are **STRICTLY FORBIDDEN** from implementing or modifying any OpenSpec change that contains the marker `STOP` or `СТОП` (case-insensitive: `STOP`, `СТОП`, `[STOP]`, etc.) in its folder name, proposal, or tasks, or contains explicit execution guardrails prohibiting automated implementation without explicit human confirmation. Coordinators (`opsx-team`, `opsx-team2`) MUST automatically skip these changes during inventory, and subagents/apply workflows MUST immediately halt if assigned a change with this marker.
- **Strict Secret Isolation & Vault Policy**: Agents are **STRICTLY FORBIDDEN** from inserting real API keys, production tokens (`live_`, `sk-`, `ghp_`, `rllm_`), passwords, or secrets into repository files, deployment scripts, test fixtures, or markdown documents. Production credentials live **ONLY** in protected system vault files or environment variables with strict permissions (`0600`). Local development and automated test suites MUST ALWAYS use sanitized dummy placeholders and hermetic test fixtures.
