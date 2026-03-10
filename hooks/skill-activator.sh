#!/bin/bash
# Olakai Skill Activator Hook
# Improves automatic skill discovery for Olakai-related prompts
# Install: See README.md in this directory

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

# Pattern matches Olakai-related keywords
OLAKAI_PATTERNS="olakai|observability|agent.*monitor|monitor.*agent|KPI.*track|track.*KPI|governance|event.*log|sdk.*integrat|AI.*agent|agent.*metric|@olakai/sdk|olakai-sdk|olakai-cli"

if echo "$PROMPT" | grep -qiE "$OLAKAI_PATTERNS"; then
  cat << 'EOF'
SKILL EVALUATION REQUIRED:

Step 1 - EVALUATE: This prompt relates to Olakai or AI agent monitoring.
Step 2 - SELECT: Choose the appropriate skill:
  - Building new agent -> Skill("olakai-new-project")
  - Adding to existing code -> Skill("olakai-integrate")
  - Something broken/not working -> Skill("olakai-troubleshoot")
  - Analytics/reports/metrics -> Skill("olakai-reports")
Step 3 - ACTIVATE: Invoke the skill NOW before proceeding.

CRITICAL: Skipping skill activation results in incomplete answers.
EOF
fi
