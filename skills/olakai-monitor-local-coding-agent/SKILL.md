---
name: olakai-monitor-local-coding-agent
description: |
  Set up and self-heal Olakai monitoring for the coding tool you are using —
  Claude Code, OpenAI Codex CLI, or Cursor. Installs hooks, creates the agent
  record, and explains how to enrich events with KPIs. This is the skill for
  "monitor my coding tool itself" (not for instrumenting your own agent's source
  code with the SDK — that is olakai-integrate).
  AUTO-INVOKE when user wants to: monitor Claude Code / Codex / Cursor sessions,
  monitor THIS coding tool, add observability to a local coding agent, track my
  own coding-assistant usage, set up olakai monitoring in this workspace, see
  what is being monitored on this machine, check if monitoring is working, or
  enable / repair hooks-based monitoring for any local coding agent.
  TRIGGER KEYWORDS: olakai monitor, monitor my coding tool, monitor this tool,
  monitor claude code, monitor codex, monitor cursor, codex cli, cursor hooks,
  local coding agent, local agent monitoring, olakai hooks, olakai monitor init,
  olakai monitor list, olakai monitor doctor, olakai monitor repair, monitor
  workspace, track sessions, is my monitoring working, monitoring not working,
  no events from claude code, claude code monitoring, codex monitoring,
  cursor monitoring, agents mine, where am i monitoring.
  DO NOT load for: instrumenting your own agent's SDK code (use olakai-integrate),
  creating agents from scratch with custom code (use olakai-new-project),
  generic SDK / KPI / event troubleshooting unrelated to a coding tool
  (use olakai-troubleshoot).
license: MIT
metadata:
  author: olakai
  version: "1.16.0"
---

# Monitor Local Coding Agents with Olakai

This skill sets up hooks-based monitoring for **local coding agents** and teaches you to **self-diagnose and repair** that monitoring. Every session in a monitored workspace reports activity to Olakai — no SDK code required.

## Is this the right skill?

| You want to… | Use |
|--------------|-----|
| Monitor **the coding tool itself** (Claude Code / Codex / Cursor sessions) | **this skill** |
| Check / fix your **own** monitoring ("is it working?", "no events") | **this skill** → [Self-healing](#self-healing-diagnose-and-repair-your-own-monitoring) |
| Instrument **your own agent's source code** with the `@olakai/sdk` / `olakai-sdk` | `olakai-integrate` |
| Build a brand-new agent project from scratch | `olakai-new-project` |
| Debug SDK / KPI / event issues unrelated to a coding tool | `olakai-troubleshoot` |

Three tools are supported, all behind the same `olakai monitor` command, gated by a `--tool` flag:

| Tool | `--tool` value | Minimum version |
|------|----------------|-----------------|
| Claude Code | `claude-code` | any current version |
| OpenAI Codex CLI | `codex` | `0.124.0` (stable hooks) |
| Cursor | `cursor` | `1.7` (hooks beta; validated against `3.x`) |

> **CLI requirement:** the `monitor list`, `monitor doctor`, `monitor repair`, and `agents mine` / `agents archive|rename|delete` commands documented here require **olakai-cli ≥ 0.7.0**. Older CLIs only have `init` / `status` / `disable`. Upgrade with `npm install -g olakai-cli@latest`.

**What you get:**
- Activity tracking on the **AI Coding Apps** tab in **Coding IQ → AI Impact** — a single table with all three tools' agents, filterable by source (`All / Claude Code / Codex / Cursor`).
- Session-level metrics (tokens, turns, model)
- KPI evaluation on local agent traffic (Time Saved, Value Created, Governance Compliance, ROI)
- Governance signals and policy enforcement

**What is NOT included yet:**
- Per-session cost tracking from the tool's own billing surface (Olakai computes its own model-based cost estimate)

## Two lenses: machine vs account

There are two distinct questions, answered by two distinct commands. Keep them straight.

| Question | Lens | Command | Source of truth |
|----------|------|---------|-----------------|
| "What is monitored on **THIS machine**, and where?" | **Machine** | `olakai monitor list` | Local registry at `~/.olakai/registry.json` |
| "What coding agents exist across my **whole account**?" | **Account** | `olakai agents mine` | Olakai backend (cross-machine) |

Why two lenses? **The backend has no scope model.** Agents are account-scoped only — there are no per-repo / per-workspace / per-host fields. So "where am I monitoring?" is a purely **machine-local** fact that nobody persists server-side. The CLI records it in a local registry (`~/.olakai/registry.json`) that `monitor list` reads. `monitor doctor` is what bridges the two lenses — it flags drift between the registry, the backend, and what is actually on disk.

```bash
# Machine lens — every workspace monitored on this box, grouped by tool,
# with scope + linked agent + a drift flag where registry/backend/disk disagree.
olakai monitor list
olakai monitor list --json

# Account lens — your coding agents across the whole Olakai account.
olakai agents mine
olakai agents mine --source claude-code      # filter to one tool
olakai agents mine --source codex --json
```

## Scope is honest per tool

**Where the hooks live differs by tool — this matters for what gets attributed.**

| Tool | Hook scope | Where hooks are written | Agent linkage (per-workspace) |
|------|-----------|-------------------------|-------------------------------|
| Claude Code | **Workspace** | `.claude/settings.json` (this workspace only) | `.olakai/monitor-claude-code.json` |
| Codex CLI | **Global** | `~/.codex/config.toml` (all workspaces) | `.olakai/monitor-codex.json` |
| Cursor | **Global** | `~/.cursor/hooks.json` (all workspaces) | `.olakai/monitor-cursor.json` |

For all three tools, the per-workspace `.olakai/monitor-<tool>.json` file holds the **agent linkage** (API key + agent ID + endpoint).

> ⚠️ **Unattributed activity caveat (Codex / Cursor).** Because Codex and Cursor install hooks **globally**, their hook fires in *every* workspace — including ones you never ran `olakai monitor init` in. When the hook fires in a workspace that has **no** `.olakai/monitor-<tool>.json`, it **silently exits** and that session is **NOT attributed to any agent** (no event is sent). This is expected: a global hook with no local linkage has nowhere to report. If you expect Codex/Cursor activity from a repo and see none, the most common cause is that you never ran `olakai monitor init --tool <tool>` *in that repo*. Run `olakai monitor list` to see exactly which workspaces are linked, and `olakai monitor doctor --tool <tool>` for an explanation in context.
>
> Claude Code does **not** have this caveat — its hooks are workspace-scoped, so they only fire where you installed them.

## Self-healing: diagnose and repair your own monitoring

If you are an installed coding agent and your monitoring seems broken (no events, missing KPIs, "is this even on?"), drive these commands in order. **Always start with `monitor list`, then `monitor doctor`, then escalate to `repair`.**

```bash
# 1. SEE — machine-wide picture: what's installed, where, and which entries are drifting.
olakai monitor list

# 2. DIAGNOSE — ordered health-check chain (registry → config → hooks → key → agent → events).
olakai monitor doctor --tool claude-code         # or codex / cursor; --all for every workspace

# 3. FIX — idempotent, best-effort auto-repair of what doctor flagged.
olakai monitor doctor --tool claude-code --fix

# 4. ESCALATE — forceful re-init that preserves agent linkage (heals a clobbered config).
olakai monitor repair --tool claude-code
```

`monitor doctor` runs an **ordered chain** — each step gates the next, so the first failure is usually the real problem: `registry-entry` → `config-valid` → `hooks-installed` → `api-key-valid` → `agent-exists` → `events-flowing`. `--fix` is idempotent and best-effort (adopts the registry entry, re-merges missing hooks, re-links a rejected key). It will **not** recreate a missing agent unless you add `--recreate-missing` — a deliberate guard so a transient 404 can't spawn a duplicate. On a true 404, prefer `olakai monitor repair --tool <tool>`, which re-merges hooks, migrates legacy config, re-links the key only if invalid, and recreates the agent only on a genuine 404.

> **For the full self-healing playbook** — every doctor check explained, the complete decision tree, `doctor --fix` vs `repair` comparison, and common repair scenarios — use the **`olakai-monitor-doctor`** skill.

## Prerequisites

```bash
which olakai || echo "CLI_NOT_INSTALLED"
olakai whoami 2>/dev/null || echo "NOT_AUTHENTICATED"
```

| Result | Action |
|--------|--------|
| `CLI_NOT_INSTALLED` | Run `npm install -g olakai-cli@latest`, then `olakai login` |
| `NOT_AUTHENTICATED` | Run `olakai login` |
| Shows email/account | Ready to proceed |

> **Not set up at all?** Use `/olakai-get-started` first.

You also need the local coding agent itself installed and operational in your workspace.

## Choose your tool

If you don't know which tool is in this workspace, run `olakai monitor init` with **no flag** — the CLI auto-detects the configured agent in interactive mode and prompts you to confirm. For scripted setup, always pass `--tool` explicitly.

```text
Are you monitoring …
├── Anthropic Claude Code? → --tool claude-code
├── OpenAI Codex CLI?      → --tool codex     (requires Codex CLI ≥ 0.124.0)
└── Cursor IDE/CLI?        → --tool cursor    (requires Cursor ≥ 1.7, hooks in beta)
```

You can install monitoring for **multiple tools** in the same workspace — each tool stores its config in its own settings file and creates its own agent record.

## Quick Setup — Claude Code

### Step 1: Initialize monitoring

```bash
olakai monitor init --tool claude-code
```

**What it does:**
1. Creates an agent with `AgentSource.CLAUDE_CODE` on your Olakai account
2. Writes `Stop` and `SubagentStop` hook entries to `.claude/settings.json` (**workspace-scoped**)
3. Saves configuration to `.olakai/monitor-claude-code.json` (API key, agent ID, endpoint). Pre-Stage-2 installs at `.claude/olakai-monitor.json` are auto-migrated on first read.
4. Records this workspace in the machine registry (`~/.olakai/registry.json`) so `monitor list` / `doctor` can see it.

The command is interactive — it prompts for an agent name if one is not provided, and lets you pick an existing agent or create a new one.

> **Re-running `olakai monitor init --tool claude-code`**: Settings-merge preserves any user-customized Olakai hook commands. It will not overwrite manually-edited commands. For a clean reinstall that refreshes hook commands, run `olakai monitor disable --tool claude-code` first, then `olakai monitor init --tool claude-code`. To heal a clobbered config without losing the agent, prefer `olakai monitor repair --tool claude-code`.

### Step 2: Verify

```bash
olakai monitor status --tool claude-code      # this workspace
olakai monitor doctor --tool claude-code      # full ordered health check
```

`status` confirms `Stop` and `SubagentStop` hooks are registered in `.claude/settings.json` and the config at `.olakai/monitor-claude-code.json` is valid. `doctor` runs the deeper chain (registry → config → hooks → key → agent → events).

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
2. Writes a `Stop` hook entry into the inline `[hooks]` block of `~/.codex/config.toml` (**global** — fires in every workspace). Comment-preserving TOML serialization isn't supported by `@iarna/toml`, so existing comments in your `~/.codex/config.toml` may be reformatted on first install — the CLI prints a warning when this happens.
3. Saves configuration to `.olakai/monitor-codex.json` (API key, agent ID, endpoint) and records this workspace in `~/.olakai/registry.json`.

> **Codex CLI ≥ 0.124.0 is required.** The hooks API was unstable in earlier Codex versions; the integration is only validated from `0.124.0` onward. Check with `codex --version` before running init.
>
> **Global-hook caveat:** because the Codex hook is global, running it in a workspace with no `.olakai/monitor-codex.json` produces **no event** (silent exit). See [Scope is honest per tool](#scope-is-honest-per-tool).

### Step 2: Verify

```bash
olakai monitor status --tool codex
olakai monitor doctor --tool codex
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
2. Writes `beforeSubmitPrompt`, `afterAgentResponse`, `sessionEnd`, and `stop` hook entries to `~/.cursor/hooks.json` (**global** per-user install — fires in every workspace)
3. Saves configuration to `.olakai/monitor-cursor.json` (API key, agent ID, endpoint) and records this workspace in `~/.olakai/registry.json`.

> **Cursor ≥ 1.7 is required and the Cursor hooks API is in beta.** The integration is validated against Cursor `3.x` but the upstream hook contract may shift. If hooks stop firing after a Cursor update, see [Troubleshooting](#troubleshooting).
>
> **Global-hook caveat:** as with Codex, the Cursor hook is global, so a workspace without `.olakai/monitor-cursor.json` produces no event. See [Scope is honest per tool](#scope-is-honest-per-tool).

### Step 2: Verify

```bash
olakai monitor status --tool cursor
olakai monitor doctor --tool cursor
```

### What gets captured (Cursor)

In addition to the standard fields (prompt, response, tokens, modelName, chatId, numTurns), Cursor hook events expose the active user's email, which is captured as:

- `userEmail` — automatically populated from the Cursor hook payload, so per-user analytics work without explicit identification
- `source` — `"cursor"`

## Pasted API key validation

When you select an **existing agent** during `olakai monitor init` and the CLI asks you to paste the API key, the CLI validates that the key actually resolves to the agent you picked:

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

Replace `AGENT_ID` with the ID shown by `olakai monitor status --tool <tool>` (or `olakai monitor list`).

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

```bash
# Health (machine, single-workspace, account)
olakai monitor list                                       # MACHINE: everything monitored on this box
olakai monitor doctor --tool <tool>                       # ordered health check (--all for every workspace)
olakai monitor status --tool <tool>                       # quick single-workspace status
olakai agents mine [--source claude-code|codex|cursor]    # ACCOUNT: your coding agents

# Events + KPIs for one agent
olakai activity list --agent-id AGENT_ID --limit 10
olakai activity sessions --agent-id AGENT_ID              # decoration status (DECORATED = KPIs populated)
olakai activity kpis --agent-id AGENT_ID --json
```

**Dashboard:** Navigate to **Coding IQ → AI Impact → AI Coding Apps** at https://app.olakai.ai. The unified table shows agents from all three tools side-by-side, with a **source filter chip** (`All / Claude Code / Codex / Cursor`, default `All`).

## Agent lifecycle (account-wide)

These act on the agent record on the Olakai backend, across all machines — not on local hooks:

```bash
olakai agents archive AGENT_ID                # hide an agent you no longer use
olakai agents archive AGENT_ID --unarchive    # bring it back
olakai agents rename AGENT_ID "New Name"      # rename
olakai agents delete AGENT_ID                 # permanent delete
```

> **Backend requirement:** `agents archive` / `rename` require a current Olakai backend (self-owner lifecycle support shipped alongside these CLI commands). Against older backends these are admin-only and `archive` may no-op silently — if archive appears to do nothing, your backend predates the feature.

To stop hooks on **this machine** without touching the account record, use `olakai monitor disable` instead (below).

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
- Removes this workspace's entry from the machine registry (`~/.olakai/registry.json`)

**What this does NOT do:**
- Does not delete the agent record on Olakai (use `olakai agents archive`/`delete` for that)
- Does not delete historical event data
- Does not affect other monitored tools or SDK-based monitoring

To re-enable, run `olakai monitor init --tool <tool>` again.

## Troubleshooting

> **No events, missing KPIs, deleted/404 agent, drifted config, hooks stopped firing?** That is the **self-healing playbook** — use the **`olakai-monitor-doctor`** skill, or just run `olakai monitor doctor --tool <tool>` (add `--fix` to auto-repair, or `olakai monitor repair --tool <tool>` to forcefully re-init while preserving the agent). The subsections below cover only setup-specific transcript/KPI issues that doctor does not auto-fix.

### Events appear but `prompt`, `response`, `tokens`, or `modelName` are empty/null

This usually means the transcript file at `transcript_path` (Claude Code) or the equivalent for Codex/Cursor could not be read or parsed. Common causes:

- CLI version too old — upgrade: `npm install -g olakai-cli@latest`
- Tool version too old — Codex must be ≥ `0.124.0`, Cursor must be ≥ `1.7`
- Transcript file moved or deleted between turn end and hook firing
- Transcript format changed in a newer tool version

For Claude Code specifically, the empty-parse silent-exit guard means the hook returns null (no event) when prompt empty AND response empty AND `numTurns` is 0 — protective against unrecognized payload shapes. If you see no events at all and debug mode shows `transcript-parsed: empty`, you've hit this guard.

Enable `OLAKAI_MONITOR_DEBUG=1` to confirm whether transcript reading succeeded. Look for `transcript-read-failed` or `transcript-parsed` entries in the debug log.

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

1. Check config exists: `cat .olakai/monitor-claude-code.json` (or the Codex/Cursor equivalent)
2. Verify API key is valid: `olakai agents get AGENT_ID --json | jq '.apiKey'`
3. Test connectivity: `olakai whoami`

### Deeper issues

Use `/olakai-troubleshoot` for comprehensive diagnostics including API key validation, endpoint connectivity, event payload inspection, and KPI formula debugging.

## Quick Reference

```bash
# Setup (pick the right --tool)
olakai monitor init --tool claude-code           # Claude Code (workspace-scoped hooks)
olakai monitor init --tool codex                 # Codex CLI (>= 0.124.0, global hooks)
olakai monitor init --tool cursor                # Cursor (>= 1.7, hooks beta, global hooks)

# See what's monitored (two lenses)
olakai monitor list                              # MACHINE: everything on this box + drift flags
olakai agents mine [--source claude-code|codex|cursor]   # ACCOUNT: agents across the whole account

# Diagnose + repair your own monitoring
olakai monitor doctor --tool <tool> [--fix] [--recreate-missing]
olakai monitor doctor --all                      # every workspace on this machine
olakai monitor repair --tool <tool>              # forceful re-init, preserves agent linkage
olakai monitor status --tool <claude-code|codex|cursor>
olakai monitor disable --tool <claude-code|codex|cursor>

# Agent lifecycle (account-wide, backend record)
olakai agents archive AGENT_ID [--unarchive]
olakai agents rename AGENT_ID "New Name"
olakai agents delete AGENT_ID

# Activity + KPIs — see "Checking Your Data" above
# Debug
export OLAKAI_MONITOR_DEBUG=1                     # Verbose dispatcher logs at /tmp/olakai-monitor-debug-<pid>.log
# Dashboard: Coding IQ -> AI Impact -> AI Coding Apps at https://app.olakai.ai
```
