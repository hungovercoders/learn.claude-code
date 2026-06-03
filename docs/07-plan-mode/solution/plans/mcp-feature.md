# Plan: wire a local cinema database via MCP

## Context

`films.json` is a fine catalogue for one viewer, but the moment we want
"films I haven't seen yet", "ratings over time", or "which moods are
under-served" the flat file falls over. SQLite handles those without
adding infrastructure — one file on disk, every query in SQL.

Wiring SQLite as an MCP server (rather than letting the agent shell
out to `sqlite3`) means the agent can query it through a typed
interface, can't shell-inject by accident, and gets the schema for
free in every session. It also keeps `films.json` as the
human-editable source of truth — the DB is a derived projection.

## Approach

1. Add `mcp-server-sqlite` to `.mcp.json` at project root. Point it
   at `${CLAUDE_PROJECT_DIR}/cinema.db`.
2. Write `scripts/build-cinema-db.sh` — reads `films.json`, recreates
   `cinema.db` with one `films` table (title, year, mood, runtime)
   and a generated `watched_at` column initialised to NULL.
3. Add the DB build as a step in `install.sh` so a fresh fork has a
   ready database the moment the kit is installed.
4. Add one read-only view `films_by_mood` so the most common query
   ("how many fun films do I have") is one MCP call.
5. Leave `films.json` as the write surface — the `/add-film` skill
   keeps writing to JSON, the build script regenerates the DB. No
   two-way sync, no drift.

## Out of scope

- A `watched_at` write path. The point of this lesson is wiring MCP,
  not building a watch log.
- Auth or remote DB. SQLite is local-only, which matches the
  hungovercoders worldview (small, cheap, yours).

## Verification

- `./scripts/build-cinema-db.sh` produces a `cinema.db` with as many
  rows as `films.json` has entries.
- `claude` in the project directory shows the `cinema-db` MCP server
  loaded and lists the `films` table when asked.
- A natural-language query ("which mood has the fewest films")
  returns a correct answer without the agent shelling out to
  `sqlite3` directly.
