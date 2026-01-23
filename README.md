# Olakai Skills

Official skills for integrating AI agents with [Olakai](https://olakai.ai) - the enterprise AI observability and governance platform.

These skills follow the [Agent Skills Standard](https://skills.sh) and work with Claude Code, Cursor, VS Code Copilot, and other compatible AI coding assistants.

## Installation

### Using add-skill (Recommended)

```bash
# List available skills
npx add-skill olakai-ai/olakai-skills --list

# Install a specific skill
npx add-skill olakai-ai/olakai-skills/olakai-get-started
npx add-skill olakai-ai/olakai-skills/olakai-create-agent
npx add-skill olakai-ai/olakai-skills/olakai-add-monitoring
npx add-skill olakai-ai/olakai-skills/olakai-troubleshoot
npx add-skill olakai-ai/olakai-skills/generate-analytics-reports
```

### Manual Installation

```bash
# Clone to user-level skills directory
git clone https://github.com/olakai-ai/olakai-skills ~/.claude/skills/olakai-skills

# Or clone to project-level
git clone https://github.com/olakai-ai/olakai-skills .claude/skills/olakai-skills
```

## Available Skills

| Skill | Description |
|-------|-------------|
| **olakai-get-started** | Get started with Olakai - account setup, CLI install, authentication, first agent |
| **olakai-create-agent** | Create a new AI agent with Olakai monitoring from scratch |
| **olakai-add-monitoring** | Add Olakai monitoring to an existing AI agent or LLM integration |
| **olakai-troubleshoot** | Troubleshoot monitoring issues - missing events, KPI problems, SDK errors |
| **generate-analytics-reports** | Generate terminal-based analytics reports without the web UI |

## Bundled Agent

The **olakai-expert** agent combines all four skills into a single specialist:

| Agent | Description |
|-------|-------------|
| **olakai-expert** | Full Olakai integration specialist - creates agents, adds monitoring, troubleshoots issues, generates reports |

## Prerequisites

Before using these skills, ensure you have:

1. **Olakai CLI** installed: `npm install -g olakai-cli`
2. **CLI authenticated**: `olakai login`
3. **API key** for SDK integration (generated per-agent via CLI)

## The Golden Rule: Test - Fetch - Validate

**Always validate your Olakai integration by generating a test event and inspecting it:**

```bash
# 1. Run your agent/trigger LLM call
# 2. Fetch the event
olakai activity list --agent-id AGENT_ID --limit 1 --json
olakai activity get EVENT_ID --json | jq '{customData, kpiData}'

# 3. Validate:
#    - customData has all expected fields
#    - kpiData shows NUMBERS (not strings like "MyVariable")
#    - kpiData shows VALUES (not null)
```

## Quick Reference

```bash
# CLI Authentication
olakai login
olakai whoami

# View Activity
olakai activity list --limit 10
olakai activity get EVENT_ID --json

# Manage Agents (includes API key generation)
olakai agents list
olakai agents create --name "Agent Name" --with-api-key --json
olakai agents get AGENT_ID --json | jq '.apiKey'

# Manage KPIs
olakai kpis list --agent-id ID
olakai kpis create --formula "Variable" --agent-id ID

# Manage Custom Data
olakai custom-data list
olakai custom-data create --name "Field" --type NUMBER
```

## SDK Quick Start

**TypeScript:**
```typescript
import { OlakaiSDK } from "@olakai/sdk";
const olakai = new OlakaiSDK({ apiKey: process.env.OLAKAI_API_KEY! });
await olakai.init();
const openai = olakai.wrap(new OpenAI({ apiKey }), { provider: "openai" });
```

**Python:**
```python
from olakaisdk import olakai_config, instrument_openai
olakai_config(os.getenv("OLAKAI_API_KEY"))
instrument_openai()
```

## Optional: Improved Skill Discovery

For automatic skill activation (recommended for heavy Olakai users):

```bash
# Install activation hooks for improved auto-invocation rate
cp hooks/skill-activator.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/skill-activator.sh
```

See `hooks/README.md` for full setup instructions.

## Documentation

- [Olakai Documentation](https://app.olakai.ai/llms.txt)
- [TypeScript SDK](https://www.npmjs.com/package/@olakai/sdk)
- [Python SDK](https://pypi.org/project/olakai-sdk/)
- [CLI Reference](https://www.npmjs.com/package/olakai-cli)

## Agent Compatibility

See [AGENTS.md](AGENTS.md) for full compatibility information with various AI coding agents.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.

---

Built with love by [Olakai](https://olakai.ai)
