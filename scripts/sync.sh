#!/usr/bin/env bash
#
# Rebuilds every derived directory from its source. Run this after editing
# anything under .agents/skills/ or .claude/agents/, then commit the result.
#
#   .agents/skills/   source        ->  .claude/skills/    byte-identical mirror
#   .claude/agents/   source        ->  .codex/agents/     generated TOML
#
# Nothing here is a symlink, because git checks symlinks out as plain text files
# on Windows without Developer Mode. The mirror is real files and CI fails any
# commit where the two copies differ.
#
#   ./scripts/sync.sh          rebuild
#   ./scripts/sync.sh --check  exit 1 if a rebuild would change anything

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1

fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -d .agents/skills ] || fail "no .agents/skills, run this from the repository"
[ -d .claude/agents ] || fail "no .claude/agents, run this from the repository"
command -v python3 >/dev/null || fail "python3 is required to generate the Codex subagents"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The skills mirror.
mkdir -p "$work/skills"
cp -R .agents/skills/. "$work/skills/"

# The Codex subagents.
mkdir -p "$work/codex"
for src in .claude/agents/*.md; do
  [ -e "$src" ] || continue
  python3 scripts/codex-agent-from-md.py "$src" "$work/codex/$(basename "${src%.md}").toml"
done

drift=0
if ! diff -r -q .claude/skills "$work/skills" >/dev/null 2>&1; then
  echo ".claude/skills is out of date with .agents/skills"
  diff -r -q .claude/skills "$work/skills" 2>&1 | sed 's/^/  /' || true
  drift=1
fi
if ! diff -r -q .codex/agents "$work/codex" >/dev/null 2>&1; then
  echo ".codex/agents is out of date with .claude/agents"
  diff -r -q .codex/agents "$work/codex" 2>&1 | sed 's/^/  /' || true
  drift=1
fi

if [ $CHECK -eq 1 ]; then
  if [ $drift -eq 1 ]; then
    echo
    echo "Run ./scripts/sync.sh and commit the result."
    exit 1
  fi
  echo "in sync"
  exit 0
fi

if [ $drift -eq 0 ]; then
  echo "already in sync, nothing to do"
  exit 0
fi

rm -rf .claude/skills .codex/agents
mkdir -p .claude/skills .codex/agents
cp -R "$work/skills/." .claude/skills/
cp -R "$work/codex/." .codex/agents/
echo "rebuilt .claude/skills and .codex/agents"
