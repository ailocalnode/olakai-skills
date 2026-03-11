#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0

echo "=== Validating SKILL.md frontmatter ==="
for file in skills/*/SKILL.md; do
  skill_name=$(basename "$(dirname "$file")")

  if ! head -1 "$file" | grep -q '^---$'; then
    echo "FAIL: $file — missing YAML frontmatter"
    status=1
    continue
  fi

  frontmatter=$(sed -n '1,/^---$/{ /^---$/d; p; }' "$file" | tail -n +1)

  for field in name description; do
    if ! echo "$frontmatter" | grep -q "^${field}:"; then
      echo "FAIL: $file — missing field: $field"
      status=1
    fi
  done

  echo "  OK: $skill_name"
done

echo ""
echo "=== Verifying symlinks ==="
for link in plugins/olakai/skills/*/; do
  link="${link%/}"
  if [ -L "$link" ]; then
    if [ ! -e "$link/SKILL.md" ]; then
      echo "FAIL: broken symlink — $link"
      status=1
    else
      echo "  OK: $(basename "$link") -> $(readlink "$link")"
    fi
  fi
done

for skill_dir in skills/*/; do
  skill_name=$(basename "$skill_dir")
  if [ ! -L "plugins/olakai/skills/$skill_name" ]; then
    echo "FAIL: missing symlink for $skill_name"
    status=1
  fi
done

echo ""
echo "=== Linting markdown ==="
if command -v npx &>/dev/null; then
  npx --yes markdownlint-cli2 "skills/**/*.md" --config .markdownlint.json && echo "  OK: no lint errors" || status=1
else
  echo "SKIP: npx not found — install Node.js to run markdown lint"
fi

echo ""
if [ $status -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
fi
exit $status
