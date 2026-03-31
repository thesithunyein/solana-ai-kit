#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "[test_install_agents_only] Installing --agents to temp directory: $TEMP_DIR"

# Initialize a git repo so submodule commands work
(cd "$TEMP_DIR" && git init -q)

# Run install.sh in agents-only mode
SOLANA_CLAUDE_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" --agents "$TEMP_DIR"

echo ""
echo "[test_install_agents_only] Verifying agents-only installation..."

# Agents, skills, rules should exist
assert_dir_exists "$TEMP_DIR/.claude/agents" ".claude/agents/ directory exists"
assert_dir_exists "$TEMP_DIR/.claude/skills" ".claude/skills/ directory exists"
assert_dir_exists "$TEMP_DIR/.claude/rules" ".claude/rules/ directory exists"
assert_file_exists "$TEMP_DIR/.claude/skills/SKILL.md" "SKILL.md exists"

# Count agents (should match full install)
AGENT_COUNT=$(find "$TEMP_DIR/.claude/agents" -name "*.md" | wc -l | tr -d ' ')
assert_eq "15" "$AGENT_COUNT" "Agent count is 15"

# Commands should NOT exist (agents-only mode)
TOTAL=$((TOTAL + 1))
if [ ! -d "$TEMP_DIR/.claude/commands" ]; then
  echo "  PASS: .claude/commands/ does NOT exist (agents-only mode)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .claude/commands/ should NOT exist in agents-only mode"
  FAIL=$((FAIL + 1))
fi

# settings.json should NOT exist
TOTAL=$((TOTAL + 1))
if [ ! -f "$TEMP_DIR/.claude/settings.json" ]; then
  echo "  PASS: settings.json does NOT exist (agents-only mode)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: settings.json should NOT exist in agents-only mode"
  FAIL=$((FAIL + 1))
fi

# CLAUDE.md should NOT exist
TOTAL=$((TOTAL + 1))
if [ ! -f "$TEMP_DIR/CLAUDE.md" ]; then
  echo "  PASS: CLAUDE.md does NOT exist (agents-only mode)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: CLAUDE.md should NOT exist in agents-only mode"
  FAIL=$((FAIL + 1))
fi

# CLAUDE.local.md should NOT exist
TOTAL=$((TOTAL + 1))
if [ ! -f "$TEMP_DIR/CLAUDE.local.md" ]; then
  echo "  PASS: CLAUDE.local.md does NOT exist (agents-only mode)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: CLAUDE.local.md should NOT exist in agents-only mode"
  FAIL=$((FAIL + 1))
fi

# .gitignore should have ext/ entry
assert_file_exists "$TEMP_DIR/.gitignore" ".gitignore exists"
GITIGNORE_CONTENT="$(cat "$TEMP_DIR/.gitignore")"
assert_contains "$GITIGNORE_CONTENT" ".claude/skills/ext/" ".gitignore contains ext/ entry"

print_summary
