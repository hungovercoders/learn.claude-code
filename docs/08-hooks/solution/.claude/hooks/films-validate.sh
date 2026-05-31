#!/bin/bash
# PostToolUse hook on Edit|Write. If films.json was touched, schema-check it.
# Exit 2 = block + send stderr back to Claude as feedback.

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // ""')

case "$file" in
  */films.json|films.json)
    if ! jq empty "$file" >/dev/null 2>&1; then
      echo "films.json no longer parses as JSON. Last edit broke the structure." >&2
      exit 2
    fi
    # Schema: array of objects with title (string), year (4-digit int),
    # mood (single lowercase word), runtime (int 60-240).
    bad=$(jq -r '
      to_entries
      | map(select(
          (.value.title | type) != "string"
          or (.value.year | type) != "number"
          or (.value.year < 1900 or .value.year > 2100)
          or (.value.mood | test("^[a-z]+(-[a-z]+)*$") | not)
          or (.value.runtime | type) != "number"
          or (.value.runtime < 60 or .value.runtime > 240)
        ))
      | map("row \(.key): \(.value)")
      | .[]
    ' "$file" 2>/dev/null)
    if [ -n "$bad" ]; then
      echo "films.json failed schema check:" >&2
      echo "$bad" >&2
      exit 2
    fi
    ;;
esac

exit 0
