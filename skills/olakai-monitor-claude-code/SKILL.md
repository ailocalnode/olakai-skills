---
name: olakai-monitor-claude-code
description: |
  Set up Olakai monitoring for local Claude Code agents. Configures hooks,
  creates the agent record, and explains how to enrich events with KPIs.
  AUTO-INVOKE when user wants to: monitor Claude Code sessions, add observability
  to local agents, track local AI usage, set up olakai monitoring in this workspace,
  observe local agent activity, or enable hooks-based monitoring.
  TRIGGER KEYWORDS: olakai monitor, local agent, monitor claude code, track sessions,
  local agent monitoring, observe local agent, olakai hooks, olakai monitor init,
  monitor workspace, local AI tracking, claude code monitoring.
  DO NOT load for: adding monitoring to custom SDK code (use olakai-integrate),
  creating agents from scratch with custom code (use olakai-new-project),
  troubleshooting existing monitoring (use olakai-troubleshoot).
license: MIT
metadata:
  author: olakai
  version: "1.13.1"
---

# Monitor Claude Code with Olakai

This skill sets up hooks-based monitoring for Claude Code local agents. Once configured, every Claude Code session in this workspace automatically reports activity to Olakai — no SDK code required.

**What you get:**
- Activity tracking in the **Agent IQ > Local Agents** tab
- Session-level metrics (tokens, turns, model)
- KPI evaluation on local agent traffic (Time Saved, Value Created, Governance Compliance)
- Governance signals and policy enforcement

**What is NOT included yet:**
- Per-session cost tracking (coming in a future release)

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

You must also be running inside a Claude Code session in a project directory (the workspace where `.claude/` lives or will be created).

## Quick Setup

### Step 1: Initialize monitoring

Run this single command from your project root:

```bash
olakai monitor init
```

**What it does:**
1. Creates an agent with `AgentSource.CLAUDE_CODE` on your Olakai account
2. Writes a Stop hook entry to `.claude/settings.json`
3. Saves configuration to `.claude/olakai-monitor.json` (API key, agent ID, endpoint)

The command is interactive — it will prompt for an agent name if one is not provided.

### Step 2: Verify setup

```bash
olakai monitor status
```

Expected output confirms:
- Hook is registered in `.claude/settings.json`
- Config file exists at `.claude/olakai-monitor.json`
- Agent ID and endpoint are valid

### Step 3: Do some work

Use Claude Code normally — write code, debug, refactor, research. Each session automatically sends an event when Claude Code stops (the Stop hook fires).

### Step 4: Validate events

After completing at least one task, verify events are flowing:

```bash
# List recent events for your local agent
olakai activity list --agent-id AGENT_ID --limit 5
```

Replace `AGENT_ID` with the ID shown by `olakai monitor status`.

### Golden Rule: Test, Fetch, Validate

```bash
# 1. Complete a Claude Code task (generates an event via the Stop hook)

# 2. Fetch the latest event
olakai activity list --agent-id AGENT_ID --limit 1 --json

# 3. Inspect it
olakai activity get EVENT_ID --json | jq '{source, customData}'
```

Confirm:
- Event exists and has recent timestamp
- `source` is `"claude-code"`
- `prompt`, `response`, `tokens`, and `modelName` are populated (not empty/null)
- `customData` contains session metadata (sessionId, numTurns, inputTokens, outputTokens)

## What Gets Tracked

The Stop hook fires at the end of each Claude Code turn. It reads Claude Code's transcript JSONL file (at `transcript_path` from the hook event) and extracts:

| Field | Description |
|-------|-------------|
| `prompt` | Last non-meta user message in the session transcript |
| `response` | Last assistant message text (tool-only turns preserve the prior text response) |
| `chatId` | Claude Code `session_id` — groups all turns of a conversation |
| `modelName` | Model from the last assistant message (e.g., `claude-sonnet-4-5`) |
| `tokens` | Input (incl. cache_creation + cache_read) + output tokens from last turn's `usage` |
| `customData.inputTokens` / `outputTokens` | Last turn's usage broken down |
| `customData.numTurns` | Count of non-sidechain assistant messages in the session |
| `customData.sessionId` / `transcriptPath` / `cwd` / `stopHookActive` / `hookEvent` | Raw Stop event metadata |
| `source` | Top-level `"claude-code"` tag |

All of this is captured automatically by the hook. No SDK code or manual instrumentation is needed.

**Notes on token counts**: Token totals include cache tokens (cache_creation + cache_read) because real Claude Code sessions typically show very high cache-read volume (tens of thousands) vs tiny uncached input. Excluding cache would massively under-report billable volume.

**Fields not captured**: Claude Code's Stop hook does not expose `duration`, `stop_reason`, or `total_cost`. These are omitted rather than fabricated. If future Claude Code versions expose them via the hook event or transcript, they can be added.

**Debug mode**: Set `OLAKAI_MONITOR_DEBUG=1` in your environment to log the raw stdin payload and constructed monitoring payload to `/tmp/olakai-monitor-debug-<pid>.log`. Useful when events aren't arriving or look wrong. Turn off when done (no-op by default so hooks stay fast and silent).

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

You should see the slot KPIs listed. If the Time Saved classifier is missing (can happen for CLI-created agents), add it manually:

```bash
olakai kpis create --name "Time Saved" \
  --calculator-id classifier --template-id time_saved_estimator \
  --scope CHAT --agent-id AGENT_ID
```

### Adding custom KPIs

If you want metrics beyond the defaults, create custom formula-based KPIs. First, register any custom data fields you plan to use:

```bash
# Example: track task complexity as a custom field
olakai custom-data create --agent-id AGENT_ID --name "Complexity" --type STRING

# Then create a KPI that uses it
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
# List available templates
olakai kpis templates

# Add a sentiment scorer
olakai kpis create --name "Session Sentiment" \
  --calculator-id classifier --template-id sentiment_scorer \
  --scope CHAT --agent-id AGENT_ID
```

> **Note:** Classifier KPIs run at CHAT scope, meaning they evaluate the entire session, not individual turns. Results appear after chat decoration processes (there may be a short delay).

## Checking Your Data

### Quick health check

```bash
olakai monitor status
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

Navigate to **Agent IQ > Local Agents** in the Olakai web dashboard at https://app.olakai.ai to see:
- Session timeline
- KPI trends
- Token usage breakdown
- Governance compliance

## Disabling Monitoring

To remove hooks and stop sending events:

```bash
olakai monitor disable
```

**What this does:**
- Removes the Stop hook from `.claude/settings.json`
- Removes `.claude/olakai-monitor.json`

**What this does NOT do:**
- Does not delete the agent record on Olakai
- Does not delete historical event data
- Does not affect other agents or SDK-based monitoring

To re-enable later, run `olakai monitor init` again.

## Troubleshooting

### No events appearing

1. Check hook status: `olakai monitor status`
2. Verify `.claude/settings.json` contains the Stop hook entry
3. Verify `.claude/olakai-monitor.json` exists and has a valid API key
4. Confirm you completed at least one Claude Code task after setup (the hook fires on Stop, not on Start)
5. For deep diagnostics, enable debug mode: `export OLAKAI_MONITOR_DEBUG=1` then do a Claude Code turn. Inspect `/tmp/olakai-monitor-debug-<pid>.log` to see the raw Stop event from stdin and the constructed monitoring payload.

### Events appear but `prompt`, `response`, `tokens`, or `modelName` are empty/null

This means the transcript file at `transcript_path` could not be read or parsed. Common causes:

- CLI version older than `0.1.15` — earlier versions tried to extract fields directly from the Stop event (which doesn't contain them). Upgrade: `npm install -g olakai-cli@latest`
- Transcript file moved or deleted between the turn ending and the hook running
- Transcript JSONL format changed in a newer Claude Code version

Enable `OLAKAI_MONITOR_DEBUG=1` to see whether transcript reading succeeded. Look for `transcript-read-failed` or `transcript-parsed` entries in the debug log.

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

### Hook errors in Claude Code

The hook is designed to fail silently — errors in the monitoring hook should never interrupt your Claude Code session. If you suspect issues:

1. Check config exists: `cat .claude/olakai-monitor.json`
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
# Setup
olakai monitor init              # Initialize monitoring for this workspace
olakai monitor status            # Check hook and config status
olakai monitor disable           # Remove hooks and config

# View activity
olakai activity list --agent-id AGENT_ID --limit 10
olakai activity get EVENT_ID --json
olakai activity sessions --agent-id AGENT_ID

# KPIs
olakai kpis list --agent-id AGENT_ID
olakai kpis create --calculator-id classifier --template-id time_saved_estimator --scope CHAT --agent-id AGENT_ID
olakai activity kpis --agent-id AGENT_ID --json

# Dashboard
# Agent IQ > Local Agents at https://app.olakai.ai
```
