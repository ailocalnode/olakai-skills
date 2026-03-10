# Olakai Skill Activation Hooks

These optional hooks improve automatic skill discovery from ~20% to ~84% activation rate.

## Installation

### 1. Create hooks directory

```bash
mkdir -p ~/.claude/hooks
```

### 2. Copy the activator script

```bash
cp skill-activator.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/skill-activator.sh
```

### 3. Add to your Claude Code settings

Add this to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "command": "bash ~/.claude/hooks/skill-activator.sh"
      }
    ]
  }
}
```

Or copy from the provided snippet:

```bash
# If you don't have existing hooks, you can use the snippet directly
cat settings-snippet.json
```

## How It Works

The hook intercepts prompts containing Olakai-related keywords and injects a "forced evaluation" instruction that prompts Claude to actively check and invoke appropriate skills.

### Detected Keywords

The hook triggers on these patterns:

- `olakai` - direct product mention
- `observability` - core product feature
- `agent.*monitor` / `monitor.*agent` - monitoring context
- `KPI.*track` / `track.*KPI` - KPI functionality
- `governance` - compliance/governance features
- `event.*log` - event tracking
- `sdk.*integrat` - SDK integration
- `AI.*agent` - AI agent context
- `agent.*metric` - agent metrics
- `@olakai/sdk` / `olakai-sdk` - SDK package names
- `olakai-cli` - CLI tool

### Skill Routing

| Intent | Skill |
|--------|-------|
| Creating new agents | `olakai-new-project` |
| Adding to existing code | `olakai-integrate` |
| Debugging/troubleshooting | `olakai-troubleshoot` |
| Reports/analytics | `olakai-reports` |

## Uninstalling

To remove the hook:

1. Delete the script:
   ```bash
   rm ~/.claude/hooks/skill-activator.sh
   ```

2. Remove the hook configuration from `~/.claude/settings.json`

## Troubleshooting

### Hook not triggering

1. Verify the script is executable:
   ```bash
   ls -la ~/.claude/hooks/skill-activator.sh
   ```

2. Test the script manually:
   ```bash
   echo '{"prompt": "help me set up olakai"}' | bash ~/.claude/hooks/skill-activator.sh
   ```

3. Check settings.json syntax:
   ```bash
   cat ~/.claude/settings.json | jq .
   ```

### False positives

If the hook triggers on unrelated prompts, you can make the patterns more specific by editing `skill-activator.sh`.
