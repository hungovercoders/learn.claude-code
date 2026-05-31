#!/bin/bash
mood="${1:-fun}"
jq -r --arg m "$mood" '
  [.[] | select(.mood == $m)] |
  if length == 0 then "No film for mood: \($m). Try another."
  else (.[0] | "\(.title) (\(.year)) — \(.runtime)min")
  end
' "$(dirname "$0")/films.json"
