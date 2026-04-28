---
name: olakai-monitor-claude-code
description: |
  Renamed to olakai-monitor-local-coding-agent. This skill now covers all three
  local coding agents (Claude Code, Codex CLI, Cursor) under one entry point.
  Existing plugin installs that reference olakai-monitor-claude-code continue
  to resolve here so they don't break — but the canonical, up-to-date guidance
  lives in olakai-monitor-local-coding-agent. Load that skill instead.
license: MIT
metadata:
  author: olakai
  version: "1.15.0"
---

# Renamed: olakai-monitor-claude-code → olakai-monitor-local-coding-agent

This skill has been renamed and broadened. The Olakai CLI's `olakai monitor` command now supports three local coding agents — Claude Code, OpenAI Codex CLI, and Cursor — gated by a `--tool` flag. The skill's name was generalized to match.

**Use the new skill instead:** [`olakai-monitor-local-coding-agent`](../olakai-monitor-local-coding-agent/SKILL.md)

This stub is preserved only so that existing plugin installs and references to `olakai-monitor-claude-code` continue to resolve. Do not author new content here.
