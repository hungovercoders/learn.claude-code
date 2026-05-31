#!/bin/bash
# Rebuilds cinema.db from films.json. Idempotent — drops and recreates.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DB="$HERE/cinema.db"
JSON="$HERE/films.json"

rm -f "$DB"
sqlite3 "$DB" <<SQL
CREATE TABLE films (
  title    TEXT NOT NULL,
  year     INTEGER NOT NULL,
  mood     TEXT NOT NULL,
  runtime  INTEGER NOT NULL,
  watched_at TEXT
);
CREATE VIEW films_by_mood AS
  SELECT mood, COUNT(*) AS n FROM films GROUP BY mood ORDER BY n DESC;
SQL

jq -r '.[] | [.title, .year, .mood, .runtime] | @csv' "$JSON" |
  sqlite3 "$DB" ".mode csv" ".import /dev/stdin films" 2>/dev/null

echo "cinema.db rebuilt: $(sqlite3 "$DB" 'SELECT COUNT(*) FROM films') films."
