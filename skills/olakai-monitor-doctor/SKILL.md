---
name: olakai-monitor-doctor
description: |
  Diagnose and repair Olakai monitoring for a local coding tool you already set
  up — Claude Code, OpenAI Codex CLI, or Cursor. Drives `olakai monitor list`,
  `olakai monitor doctor [--fix]`, and `olakai monitor repair` to self-heal
  hooks-based monitoring (no events, missing KPIs, broken/deleted agent, drifted
  config). For first-time setup use olakai-monitor-local-coding-agent instead.
  AUTO-INVOKE when user says: my coding-tool monitoring isn't working, no events
  from Claude Code / Codex / Cursor, is monitoring on / working, check my olakai
  monitoring, what's monitored on this machine, monitor doctor, monitor repair,
  monitor list, fix my monitoring, my monitored agent disappeared / 404, hooks
  stopped firing, re-link my monitoring key.
  TRIGGER KEYWORDS: olakai monitor doctor, olakai monitor repair, olakai monitor
  list, monitor not working, no events claude code, no events codex, no events
  cursor, fix monitoring, repair monitoring, agent 404, agent missing, hooks
  stopped firing, drift, registry, agents mine, where am i monitoring, is my
  monitoring working, self-heal monitoring.
  DO NOT load for: first-time setup of a coding tool (use
  olakai-monitor-local-coding-agent), instrumenting your own agent's SDK code
  (use olakai-integrate), generic SDK / KPI / event troubleshooting unrelated to
  a coding tool (use olakai-troubleshoot).
license: MIT
metadata:
  author: olakai
  version: "1.16.0"
---

# Self-Heal Local Coding Agent Monitoring

This skill diagnoses and repairs **already-installed** hooks-based monitoring for a local coding tool (Claude Code, Codex CLI, Cursor). Use it when monitoring seems broken: no events, missing KPIs, a deleted/404 agent, or a clobbered config.

> **First-time setup?** Use `olakai-monitor-local-coding-agent` instead — it covers `init`, what each tool captures, and KPI configuration. This skill is the **repair** half.

> **CLI requirement:** `monitor list`, `monitor doctor`, `monitor repair`, and `agents mine` require **olakai-cli ≥ 0.7.0**. Older CLIs only have `init` / `status` / `disable`. Upgrade: `npm install -g olakai-cli@latest`.

## The three commands, in order

If your monitoring seems broken, drive these in order. **Always start with `monitor list`, then `monitor doctor`, then escalate to `repair`.**

```bash
# 1. SEE — machine-wide picture: what's installed, where, and which entries are drifting.
olakai monitor list

# 2. DIAGNOSE — ordered health-check chain for the current workspace + tool.
olakai monitor doctor --tool claude-code         # or codex / cursor
olakai monitor doctor --all                       # every workspace on this machine

# 3. FIX — idempotent, best-effort auto-repair of what doctor flagged.
olakai monitor doctor --tool claude-code --fix

# 4. ESCALATE — forceful re-init that preserves agent linkage (heals a clobbered config).
olakai monitor repair --tool claude-code
```

## Two lenses: machine vs account

Two distinct questions, two distinct commands. Keep them straight.

| Question | Lens | Command | Source of truth |
|----------|------|---------|-----------------|
| "What is monitored on **THIS machine**, and where?" | **Machine** | `olakai monitor list` | Local registry at `~/.olakai/registry.json` |
| "What coding agents exist across my **whole account**?" | **Account** | `olakai agents mine` | Olakai backend (cross-machine) |

**The backend has no scope model** — agents are account-scoped only, with no per-repo / per-workspace / per-host fields. So "where am I monitoring?" is a purely **machine-local** fact that nobody persists server-side; the CLI records it in `~/.olakai/registry.json`, which `monitor list` reads. `monitor doctor` bridges the two lenses — it flags drift between the registry, the backend, and what's actually on disk.

```bash
olakai monitor list                              # MACHINE: every monitored workspace, grouped by tool
olakai monitor list --json
olakai agents mine                               # ACCOUNT: your coding agents across the whole account
olakai agents mine --source claude-code          # filter to one tool
olakai agents mine --source codex --json
```

## What each doctor check means

`monitor doctor` runs an **ordered chain** — each step gates the next, so the first failure is usually the real problem:

| # | Check | PASS means | A FAIL points to |
|---|-------|-----------|------------------|
| 1 | `registry-entry` | This workspace is recorded in `~/.olakai/registry.json` | Never inited here, or registry wiped → `--fix` adopts the on-disk config into the registry |
| 2 | `config-valid` | `.olakai/monitor-<tool>.json` exists and parses (key, agentId, endpoint) | Missing/corrupt config → `monitor repair` re-writes it |
| 3 | `hooks-installed` | The tool's settings file has the Olakai hook entries | Hooks removed or a settings edit clobbered them → `--fix` re-merges them |
| 4 | `api-key-valid` | The stored key authenticates (`GET /api/monitoring/prompt/me`) | Key revoked/rotated → `--fix` rotates a fresh key on the *same* agent and rewrites the config (cross-wired-key detection is a `monitor init` feature, not `doctor`) |
| 5 | `agent-exists` | The linked agent still exists on the backend | Agent deleted (404) → recreation is **gated** behind `--recreate-missing` or `repair` (so a transient 404 can't spawn a duplicate) |
| 6 | `events-flowing` | Recent events exist for this agent (metadata probe) | Hooks installed but never fired → run a turn, then re-check; if still empty see the unattributed-activity caveat below |

`--fix` is **idempotent and best-effort**: it adopts the registry entry, re-merges missing hooks, and re-links a rejected key. It will **not** recreate a missing agent unless you add `--recreate-missing` — a deliberate guard against a flaky/transient 404 spawning a duplicate agent.

## Decision tree

```
Want the machine-wide picture ("what's monitored here")?
└── olakai monitor list   (account-wide instead? → olakai agents mine)

No events appearing?
└── olakai monitor doctor --tool <tool>      ← always start here
    ├── registry-entry FAIL  → olakai monitor doctor --tool <tool> --fix   (adopts config into registry)
    ├── hooks-installed FAIL → olakai monitor doctor --tool <tool> --fix   (re-merges hooks)
    ├── api-key-valid FAIL   → olakai monitor doctor --tool <tool> --fix   (re-links a fresh key)
    ├── agent-exists FAIL (404)
    │   ├── olakai monitor repair --tool <tool>                  (recommended — preserves linkage)
    │   └── olakai monitor doctor --tool <tool> --fix --recreate-missing
    └── events-flowing FAIL  → run one turn, re-check; Codex/Cursor in an un-inited repo
                               → silent-exit (see unattributed-activity caveat)

Config clobbered / settings file edited by hand / legacy layout?
└── olakai monitor repair --tool <tool>
    (always re-merges hooks, migrates legacy config, re-links key only if invalid,
     recreates the agent only on a TRUE 404 — never duplicates a healthy agent)
```

## `doctor --fix` vs `repair` — when to use which

| | `monitor doctor --fix` | `monitor repair --tool <t>` |
|---|------------------------|------------------------------|
| Intent | Surgical: fix only what a check flagged | Forceful re-init that **preserves** agent linkage |
| Hooks | Re-merges only if `hooks-installed` failed | **Always** re-merges (heals a clobbered settings file) |
| Legacy config | — | Migrates legacy config layout |
| API key | Re-links only if invalid | Re-links only if invalid |
| Missing agent | Recreates only with `--recreate-missing` | Recreates only on a **true 404** |
| Use when | Doctor told you exactly what's wrong | "Just make it work again" / settings got mangled |

## Scope honesty (why some sessions aren't tracked)

Where the hooks live differs by tool, and that drives what gets attributed:

| Tool | Hook scope | Where hooks are written |
|------|-----------|-------------------------|
| Claude Code | **Workspace** | `.claude/settings.json` (this workspace only) |
| Codex CLI | **Global** | `~/.codex/config.toml` (all workspaces) |
| Cursor | **Global** | `~/.cursor/hooks.json` (all workspaces) |

For all three, the per-workspace `.olakai/monitor-<tool>.json` holds the agent linkage (key + agent ID + endpoint).

> ⚠️ **Unattributed-activity caveat (Codex / Cursor).** Because Codex and Cursor hooks are **global**, they fire in *every* workspace — including ones you never ran `init` in. When the hook fires in a workspace with **no** `.olakai/monitor-<tool>.json`, it **silently exits** and that session is **NOT attributed to any agent** (no event). This is expected: a global hook with no local linkage has nowhere to report. If you expect Codex/Cursor activity from a repo and see none, the most common cause is you never ran `olakai monitor init --tool <tool>` *in that repo*. Run `olakai monitor list` to see which workspaces are linked, and `olakai monitor doctor --tool <tool>` for an in-context explanation.
>
> Claude Code does **not** have this caveat — its hooks are workspace-scoped, so they only fire where you installed them.

## Common scenarios

### "No events from my coding tool"

```bash
olakai monitor doctor --tool <tool>     # read the first failing check
olakai monitor doctor --tool <tool> --fix   # auto-repair registry/hooks/key
```

If `events-flowing` is the only failure: run one real turn and re-check. For Codex/Cursor, confirm you ran `init` **in this repo** (global-hook silent-exit otherwise).

### "My monitored agent disappeared / doctor says 404"

```bash
olakai monitor repair --tool <tool>                          # recommended — recreates only on a true 404
# or explicitly:
olakai monitor doctor --tool <tool> --fix --recreate-missing
```

### "Hooks stopped firing after a tool update (esp. Cursor)"

```bash
olakai monitor repair --tool cursor     # re-merges hook entries, preserves the agent
cursor --version                        # confirm >= 1.7
```

### "I edited my settings file by hand and broke it"

```bash
olakai monitor repair --tool <tool>     # always re-merges hooks + migrates legacy config
```

## Validate the fix (Golden Rule)

After repairing, confirm with a real event:

```bash
# 1. Run one turn in the coding tool
# 2. Fetch the latest event
olakai activity list --agent-id AGENT_ID --limit 1 --json
# 3. Inspect it
olakai activity get EVENT_ID --json | jq '{source, customData, kpiData}'
```

Confirm: event exists with a recent timestamp; `source` matches your `--tool`; `prompt`/`response`/`tokens`/`modelName` are populated; `kpiData` shows numbers (not strings or nulls). Find `AGENT_ID` via `olakai monitor status --tool <tool>` or `olakai monitor list`.

## Debug mode

When doctor passes but events still seem off, watch the dispatcher directly:

```bash
export OLAKAI_MONITOR_DEBUG=1           # then run a turn
# Inspect /tmp/olakai-monitor-debug-<pid>.log for:
#   dispatcher/posting    — payload about to be posted
#   dispatcher/posted     — HTTP status + 500-byte response preview
#   dispatcher/post-error — error details if the POST failed
#   transcript-read-failed / transcript-parsed — transcript parsing signals
```

## Quick Reference

```bash
# See (two lenses)
olakai monitor list [--json]                                 # MACHINE: what's monitored here + drift
olakai agents mine [--source claude-code|codex|cursor] [--json]   # ACCOUNT: agents across the account

# Diagnose + repair
olakai monitor doctor --tool <tool> [--fix] [--recreate-missing]
olakai monitor doctor --all [--fix]                          # every workspace on this machine
olakai monitor repair --tool <tool>                          # forceful re-init, preserves agent

# Agent lifecycle (account-wide; requires current backend)
olakai agents archive AGENT_ID [--unarchive]
olakai agents rename AGENT_ID "New Name"
olakai agents delete AGENT_ID

# Debug
export OLAKAI_MONITOR_DEBUG=1
```

## Related skills

- `olakai-monitor-local-coding-agent` — first-time setup (`init`), per-tool capture details, KPI configuration.
- `olakai-troubleshoot` — generic SDK / KPI / event diagnostics (string KPIs, null KPIs, customData pipeline) not specific to a coding tool.
