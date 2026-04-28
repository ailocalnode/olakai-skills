---
name: olakai-monitor-local-coding-agent
description: |
  Set up Olakai monitoring for local coding agents — Claude Code, Codex CLI, or Cursor —
  via hooks. Configures the agent record, installs the right hooks for the chosen tool,
  and explains how to enrich events with KPIs.
  AUTO-INVOKE when user wants to: monitor Claude Code / Codex / Cursor sessions,
  add observability to local coding agents, track local AI usage, set up olakai
  monitoring in this workspace, observe local agent activity, or enable hooks-based
  monitoring for any local coding agent.
  TRIGGER KEYWORDS: olakai monitor, local agent, monitor claude code, monitor codex,
  monitor cursor, codex cli, cursor hooks, track sessions, local agent monitoring,
  observe local agent, olakai hooks, olakai monitor init, monitor workspace,
  local AI tracking, claude code monitoring, codex monitoring, cursor monitoring,
  local coding agent.
  DO NOT load for: adding monitoring to custom SDK code (use olakai-integrate),
  creating agents from scratch with custom code (use olakai-new-project),
  troubleshooting existing monitoring (use olakai-troubleshoot).
license: MIT
metadata:
  author: olakai
  version: "1.15.0"
---

# Monitor Local Coding Agents with Olakai

This skill sets up hooks-based monitoring for **local coding agents**. Every session in this workspace automatically reports activity to Olakai — no SDK code required.

Three tools are supported, all behind the same `olakai monitor` command, gated by a `--tool` flag:

| Tool | `--tool` value | Minimum version |
|------|----------------|-----------------|
| Claude Code | `claude-code` | any current version |
| OpenAI Codex CLI | `codex` | `0.124.0` (stable hooks) |
| Cursor | `cursor` | `1.7` (hooks beta; validated against `3.x`) |

**What you get:**
- Activity tracking on the **AI Coding Apps** tab in **Coding IQ → AI Impact** — a single table with all three tools' agents, filterable by source (`All / Claude Code / Codex / Cursor`).
- Session-level metrics (tokens, turns, model)
- KPI evaluation on local agent traffic (Time Saved, Value Created, Governance Compliance, ROI)
- Governance signals and policy enforcement

**What is NOT included yet:**
- Per-session cost tracking from the tool's own billing surface (Olakai computes its own model-based cost estimate)

## Choose your tool

If you don't know which tool is in this workspace, run `olakai monitor init` with **no flag** — the CLI auto-detects the configured agent in interactive mode and prompts you to confirm. For scripted setup, always pass `--tool` explicitly.

```text
Are you monitoring …
├── Anthropic Claude Code? → --tool claude-code
├── OpenAI Codex CLI?      → --tool codex     (requires Codex CLI ≥ 0.124.0)
└── Cursor IDE/CLI?        → --tool cursor    (requires Cursor ≥ 1.7, hooks in beta)
```

You can install monitoring for **multiple tools** in the same workspace — each tool stores its config in its own settings file and creates its own agent record.

## Prerequisites

Before starting, verify these requirements:

```bash
# 1. CLI installed?
which olakai || echo "CLI_NOT_INSTALLED"

# 2. Authenticated?
olakai whoami 2>/dev/null || echo "NOT_AUTHENTICATED"
```

| Result | Action |
|--------|--------|
| `CLI_NOT_INSTALLED` | Run `npm install -g olakai-cli@latest`, then `olakai login` |
| `NOT_AUTHENTICATED` | Run `olakai login` |
| Shows email/account | Ready to proceed |

> **Not set up at all?** Use `/olakai-get-started` first.

You also need the local coding agent itself installed and operational in your workspace.

## Quick Setup — Claude Code

### Step 1: Initialize monitoring

```bash
olakai monitor init --tool claude-code
```

**What it does:**
1. Creates an agent with `AgentSource.CLAUDE_CODE` on your Olakai account
2. Writes `Stop` and `SubagentStop` hook entries to `.claude/settings.json`
3. Saves configuration to `.olakai/monitor-claude-code.json` (API key, agent ID, endpoint). Pre-Stage-2 installs at `.claude/olakai-monitor.json` are auto-migrated on first read.

The command is interactive — it prompts for an agent name if one is not provided, and lets you pick an existing agent or create a new one.

> **Re-running `olakai monitor init --tool claude-code`**: Settings-merge preserves any user-customized Olakai hook commands. It will not overwrite manually-edited commands. For a clean reinstall that refreshes hook commands, run `olakai monitor disable --tool claude-code` first, then `olakai monitor init --tool claude-code`.

### Step 2: Verify

```bash
olakai monitor status --tool claude-code
```

Confirms `Stop` and `SubagentStop` hooks are registered in `.claude/settings.json` and the config at `.olakai/monitor-claude-code.json` is valid.

### What gets captured (Claude Code)

Two hooks are installed by default:

- **Stop hook** — fires at the end of each top-level Claude Code turn
- **SubagentStop hook** — fires when a subagent (launched via the Agent tool) finishes

Both hooks read Claude Code's transcript JSONL file (at `transcript_path` from the hook event) and extract:

| Field | Description |
|-------|-------------|
| `prompt` | Last non-meta user message in the session transcript |
| `response` | Last assistant message text (tool-only turns preserve the prior text response) |
| `chatId` | Claude Code `session_id` — groups all turns of a conversation |
| `modelName` | Model from the last assistant message (e.g., `claude-sonnet-4-5`) |
| `tokens` | Input (incl. cache_creation + cache_read) + output tokens from last turn's `usage` |
| `customData.inputTokens` / `outputTokens` | Last turn's usage broken down |
| `customData.numTurns` | Count of non-sidechain assistant messages in the session |
| `customData.latencyMs` | Integer milliseconds from the user message timestamp to the assistant response timestamp |
| `customData.subagent` | Subagent name, set only on `SubagentStop` events |
| `customData.skill` | Slash-command skill name, set when the user turn begins with `/<skill>` |
| `customData.sessionId` / `transcriptPath` / `cwd` / `stopHookActive` / `hookEvent` | Raw hook event metadata |
| `source` | Top-level `"claude-code"` tag |

**Notes on token counts**: Token totals include cache tokens (cache_creation + cache_read) because real Claude Code sessions typically show very high cache-read volume. Excluding cache would massively under-report billable volume.

**Empty-parse safeguard**: If the transcript parser produces an empty prompt, empty response, AND zero turns, the hook returns null and does not fire an event — defensive against unrecognized payload shapes from future Claude Code versions.

## Quick Setup — Codex CLI

### Step 1: Initialize monitoring

```bash
olakai monitor init --tool codex
```

**What it does:**
1. Creates an agent with `AgentSource.CODEX` on your Olakai account
2. Writes a `Stop` hook entry into the inline `[hooks]` block of `~/.codex/config.toml` (the canonical Codex configuration file). Comment-preserving TOML serialization isn't supported by `@iarna/toml`, so existing comments in your `~/.codex/config.toml` may be reformatted on first install — the CLI prints a warning when this happens.
3. Saves configuration to `.olakai/monitor-codex.json` (API key, agent ID, endpoint)

> **Codex CLI ≥ 0.124.0 is required.** The hooks API was unstable in earlier Codex versions; the integration is only validated from `0.124.0` onward. Check with `codex --version` before running init.

### Step 2: Verify

```bash
olakai monitor status --tool codex
```

### What gets captured (Codex)

Codex hooks fire on session turn completion. The integration captures:

- `prompt` / `response` — last user/assistant turn from Codex's transcript
- `chatId` — Codex session identifier
- `modelName` — model from the last assistant message
- `tokens` — input + output token totals from the turn's usage
- `customData.inputTokens` / `outputTokens` — usage broken down
- `customData.numTurns` — turn count for the session
- `source` — `"codex"`

## Quick Setup — Cursor

### Step 1: Initialize monitoring

```bash
olakai monitor init --tool cursor
```

**What it does:**
1. Creates an agent with `AgentSource.CURSOR` on your Olakai account
2. Writes `beforeSubmitPrompt`, `afterAgentResponse`, `sessionEnd`, and `stop` hook entries to `~/.cursor/hooks.json` (per-user install)
3. Saves configuration to `.olakai/monitor-cursor.json` (API key, agent ID, endpoint)

> **Cursor ≥ 1.7 is required and the Cursor hooks API is in beta.** The integration is validated against Cursor `3.x` but the upstream hook contract may shift. If hooks stop firing after a Cursor update, see [Troubleshooting](#troubleshooting).

### Step 2: Verify

```bash
olakai monitor status --tool cursor
```

### What gets captured (Cursor)

In addition to the standard fields (prompt, response, tokens, modelName, chatId, numTurns), Cursor hook events expose the active user's email, which is captured as:

- `userEmail` — automatically populated from the Cursor hook payload, so per-user analytics work without explicit identification
- `source` — `"cursor"`

## Pasted API key validation

When you select an **existing agent** during `olakai monitor init` and the CLI asks you to paste the API key, the CLI now validates that the key actually resolves to the agent you picked:

1. The CLI calls `GET /api/monitoring/prompt/me` with your pasted key
2. It checks the resolved agent ID matches the agent you selected from the list
3. If they don't match, you'll see a warning naming **both** agents (the one the key belongs to vs. the one you picked) and a prompt:

```text
Use the pasted key anyway? (y/n) [n]:
```

The default is **abort** — pressing Enter cancels the init and protects you from wiring a key into the wrong agent's config. Pick again, regenerate a fresh key for the right agent (`olakai agents get AGENT_ID --json | jq '.apiKey'`), or type `y` if you intentionally want a cross-wired setup (rare, usually a mistake).

## Validate via the Golden Rule

After completing your first task in the local agent, fetch and inspect the event:

```bash
# 1. Use the local agent normally — write code, ask questions, run a turn

# 2. Fetch the latest event for your agent
olakai activity list --agent-id AGENT_ID --limit 1 --json

# 3. Inspect it
olakai activity get EVENT_ID --json | jq '{source, customData, kpiData}'
```

Confirm:
- Event exists with a recent timestamp
- `source` is `"claude-code"`, `"codex"`, or `"cursor"` (matches your `--tool`)
- `prompt`, `response`, `tokens`, and `modelName` are populated (not empty/null)
- `customData` contains session metadata
- For Cursor specifically, `userEmail` is set from the hook payload
- `kpiData` shows numbers, not strings or nulls

Replace `AGENT_ID` with the ID shown by `olakai monitor status --tool <tool>`.

## KPI Configuration

Local agent traffic is evaluated by the same KPI system as SDK-monitored agents. New agents automatically receive **metric slot KPIs**:

| Slot KPI | Output Unit | Description |
|----------|-------------|-------------|
| Execution Cost | USD | Token-based cost estimate |
| Time Saved | minutes | `time_saved_estimator` classifier (CHAT scope) |
| Value Created | USD | Time Saved * hourly rate |
| Governance Compliance | % | Policy pass rate |

Plus the composite: **ROI** = Value Created / Execution Cost.

### Verify KPIs exist

```bash
olakai kpis list --agent-id AGENT_ID
```

If the Time Saved classifier is missing (can happen for CLI-created agents), add it manually:

```bash
olakai kpis create --name "Time Saved" \
  --calculator-id classifier --template-id time_saved_estimator \
  --scope CHAT --agent-id AGENT_ID
```

### Adding custom KPIs

If you want metrics beyond the defaults, register custom data fields first, then create formula-based KPIs:

```bash
# Example: track task complexity
olakai custom-data create --agent-id AGENT_ID --name "Complexity" --type STRING

olakai kpis create \
  --name "Complex Tasks" \
  --agent-id AGENT_ID \
  --calculator-id formula \
  --formula "IF(Complexity = \"complex\", 1, 0)" \
  --aggregation SUM
```

### Using classifier templates

Classifier templates provide AI-evaluated KPIs without writing formulas. They analyze the full conversation at the CHAT scope:

```bash
olakai kpis templates                              # List available templates

olakai kpis create --name "Session Sentiment" \
  --calculator-id classifier --template-id sentiment_scorer \
  --scope CHAT --agent-id AGENT_ID
```

> **Note:** Classifier KPIs run at CHAT scope, meaning they evaluate the entire session, not individual turns. Results appear after chat decoration processes (there may be a short delay).

## Checking Your Data

### Quick health check

```bash
olakai monitor status --tool <claude-code|codex|cursor>
```

### Recent events

```bash
olakai activity list --agent-id AGENT_ID --limit 10
```

### Session decoration status

```bash
olakai activity sessions --agent-id AGENT_ID
```

Sessions with `DECORATED` status have KPI data populated.

### KPI snapshot

```bash
olakai activity kpis --agent-id AGENT_ID --json
```

### Dashboard

Navigate to **Coding IQ → AI Impact → AI Coding Apps** in the Olakai web dashboard at https://app.olakai.ai. The unified table shows agents from all three tools side-by-side, with a **source filter chip** (`All / Claude Code / Codex / Cursor`, default `All`) so you can compare or focus on one tool.

## Disabling Monitoring

Each tool's monitoring is uninstalled independently:

```bash
olakai monitor disable --tool claude-code
olakai monitor disable --tool codex
olakai monitor disable --tool cursor
```

**What this does:**
- Removes the registered hooks from the tool's settings file
- Removes the corresponding `monitor-claude-code.json` / `monitor-codex.json` / `monitor-cursor.json` (and any legacy `.claude/olakai-monitor.json`)

**What this does NOT do:**
- Does not delete the agent record on Olakai
- Does not delete historical event data
- Does not affect other monitored tools or SDK-based monitoring

To re-enable, run `olakai monitor init --tool <tool>` again.

## Troubleshooting

### No events appearing

1. Check status: `olakai monitor status --tool <tool>`
2. Verify the tool's settings file contains the registered hook entries
3. Verify the corresponding `*-monitor.json` config exists and has a valid API key
4. Confirm you completed at least one turn after setup (hooks fire on Stop, not on Start)
5. **Enable debug mode**: `export OLAKAI_MONITOR_DEBUG=1`, do a turn, then inspect `/tmp/olakai-monitor-debug-<pid>.log`. Under debug, the dispatcher emits these structured events:
   - `dispatcher/posting` — payload about to be posted to Olakai
   - `dispatcher/posted` — HTTP status + a 500-byte preview of the response body
   - `dispatcher/post-error` — error details if the POST itself failed
   These are the most useful signals when events seem to disappear.

### Events appear but `prompt`, `response`, `tokens`, or `modelName` are empty/null

This usually means the transcript file at `transcript_path` (Claude Code) or the equivalent for Codex/Cursor could not be read or parsed. Common causes:

- CLI version too old — upgrade: `npm install -g olakai-cli@latest`
- Tool version too old — Codex must be ≥ `0.124.0`, Cursor must be ≥ `1.7`
- Transcript file moved or deleted between turn end and hook firing
- Transcript format changed in a newer tool version

For Claude Code specifically, the empty-parse silent-exit guard means the hook returns null (no event) when prompt empty AND response empty AND `numTurns` is 0 — protective against unrecognized payload shapes. If you see no events at all and debug mode shows `transcript-parsed: empty`, you've hit this guard.

Enable `OLAKAI_MONITOR_DEBUG=1` to confirm whether transcript reading succeeded. Look for `transcript-read-failed` or `transcript-parsed` entries in the debug log.

### Cursor: hooks stop firing after a Cursor update

Cursor's hook API is in beta. If a Cursor update breaks compatibility:

1. Confirm Cursor version: `cursor --version` — must be ≥ `1.7`
2. Re-run `olakai monitor init --tool cursor` to refresh hook entries
3. Check the [olakai-cli changelog](https://www.npmjs.com/package/olakai-cli) for compatibility notes against newer Cursor releases

### Events appear but no KPIs

KPIs must be configured on the agent:

```bash
olakai kpis list --agent-id AGENT_ID
```

If empty, add at minimum the Time Saved classifier:

```bash
olakai kpis create --name "Time Saved" \
  --calculator-id classifier --template-id time_saved_estimator \
  --scope CHAT --agent-id AGENT_ID
```

### Hook errors interrupting the session

The hook is designed to fail silently — errors in the monitoring hook should never interrupt your local agent session. If you suspect issues:

1. Check config exists: `cat .olakai/monitor-claude-code.json` (or the Codex/Cursor equivalent: `.olakai/monitor-codex.json`, `.olakai/monitor-cursor.json`)
2. Verify API key is valid: `olakai agents get AGENT_ID --json | jq '.apiKey'`
3. Test connectivity: `olakai whoami`

### Deeper issues

Use `/olakai-troubleshoot` for comprehensive diagnostics including:
- API key validation
- Endpoint connectivity
- Event payload inspection
- KPI formula debugging

## Quick Reference

```bash
# Setup (pick the right --tool)
olakai monitor init --tool claude-code           # Claude Code
olakai monitor init --tool codex                 # Codex CLI (>= 0.124.0)
olakai monitor init --tool cursor                # Cursor (>= 1.7, hooks beta)

# Status / disable
olakai monitor status --tool <claude-code|codex|cursor>
olakai monitor disable --tool <claude-code|codex|cursor>

# View activity
olakai activity list --agent-id AGENT_ID --limit 10
olakai activity get EVENT_ID --json
olakai activity sessions --agent-id AGENT_ID

# KPIs
olakai kpis list --agent-id AGENT_ID
olakai kpis create --calculator-id classifier --template-id time_saved_estimator --scope CHAT --agent-id AGENT_ID
olakai activity kpis --agent-id AGENT_ID --json

# Debug
export OLAKAI_MONITOR_DEBUG=1                    # Verbose dispatcher logs at /tmp/olakai-monitor-debug-<pid>.log

# Dashboard
# Coding IQ -> AI Impact -> AI Coding Apps at https://app.olakai.ai
```
