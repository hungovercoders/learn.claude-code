#!/bin/bash
# PreToolUse hook for Bash — blocks rm -rf and similar destructive commands.
# Exit 2 + stderr message = Claude sees the feedback and reconsiders.
#
# Install:
#   cp example-hook.sh ~/.claude/hooks/guard-rm.sh
#   chmod +x ~/.claude/hooks/guard-rm.sh
#
# Then add to ~/.claude/settings.json:
#   { "hooks": { "PreToolUse": [ { "matcher": "Bash",
#       "hooks": [ { "type": "command",
#                    "command": "$HOME/.claude/hooks/guard-rm.sh" } ] } ] } }

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

if echo "$command" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f|rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'; then
  echo "Refusing rm -rf: '$command'. If you genuinely need this, the human must run it." >&2
  exit 2
fi

exit 0
