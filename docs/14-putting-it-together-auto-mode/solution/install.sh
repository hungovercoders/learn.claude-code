#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/skills ~/.claude/hooks ~/.claude/commands

for c in "$HERE"/.claude/commands/*.md; do
  ln -sf "$c" ~/.claude/commands/$(basename "$c")
done

for s in "$HERE"/.claude/skills/*/; do
  ln -sf "$s" ~/.claude/skills/$(basename "$s")
done

for h in "$HERE"/.claude/hooks/*.sh; do
  ln -sf "$h" ~/.claude/hooks/$(basename "$h")
done

echo "cinema kit installed. Slash commands, skills, and hooks symlinked from $HERE."
echo "The films-validate hook still only fires when settings.json wires it — see lesson 8."
