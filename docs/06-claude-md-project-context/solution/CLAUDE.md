# cinema — agent context

## What this is

A small CLI for picking a film by mood, plus a Claude Code kit that
extends it. Bash + jq + a JSON catalogue. No Python, no Node, no
dependencies beyond `jq`.

The kit grows across the fourteen `learn.claude-code` lessons — by
lesson fourteen this directory holds the picker, three slash commands,
two skills, a validation hook, an MCP wiring, and an install script
that symlinks the whole `.claude/` directory into `~/.claude/`.

## Files

- `films.json`   — array of `{title, year, mood, runtime}` objects.
                   Append new films to the end; never reorder.
- `pick-film.sh` — the picker script. One argument (a mood) → one
                   matching film.
- `install.sh`   — run once after cloning. Symlinks `.claude/` into
                   `~/.claude/` so the skills and hook are live from
                   any directory.

## Conventions

- Moods are single lowercase words ("fun", "homesick", "cardiff",
  "cosy", "comedy", "wales", "big-night").
- Welsh and modern releases preferred. Twin Town, Hedd Wyn, How
  Green Was My Valley, anything Mandalorian.
- Runtime in minutes (integer). Year is a four-digit integer.

## Adding films

Either edit `films.json` directly, or use the `/add-film` skill —
`/add-film "Title" 2026 mood 105`. The `films-validate.sh` hook
fires on every edit and refuses writes that break the schema.

## What lives where

- Slash commands and skills under `.claude/commands/` and
  `.claude/skills/` are project-scoped. They only make sense inside
  this repo.
- The `films-validate.sh` hook is *also* project-scoped — it knows
  the films.json schema specifically. A general JSON validator
  would live at user level instead (`~/.claude/hooks/`).
- The MCP server config under `.mcp.json` is project-scoped and
  speaks to a local `cinema.db` SQLite file.
