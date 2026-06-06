---
title: "MCP Servers"
series: claude-code
order: 12
description: "Implement the lesson-7 plan — wire a local SQLite MCP server into the cinema so Claude can query films through SQL while films.json stays the human-editable source of truth"
canonical_url: https://hungovercoders.com/training/claude-code/12-mcp-servers
---

MCP is the pipe between Claude Code and an external system that speaks something other than the agent's native tool set. The one I lean on hardest in real work is the **Linear MCP** — I use it to write plans out to Linear for peer refinement once a design is settled, then have agents action the resulting issues with context from the related projects and initiatives. For the cinema we'll wire a simpler one — a local SQLite MCP server pointed at a `cinema.db` built from `films.json` — so Claude can answer *"which mood has the fewest films?"* in SQL instead of shelling out to `jq` and parsing the result. The plan we wrote in lesson 7 with `--permission-mode plan` becomes the thing we wire up here.

## Pre-Requisites

- The lesson-7 plan at `plans/mcp-feature.md` (we wrote it; this lesson executes it)
- `uvx` or `uv` installed (`brew install uv` on macOS), or `pipx` as an alternative — used to launch the SQLite MCP server
- `sqlite3` on your PATH (ships with macOS; `apt install sqlite3` on Debian/Ubuntu)

## Plugging in the External Tap — What MCP Is

MCP servers run as separate processes that Claude Code connects to at startup. Each server exposes one or more *capabilities* — read files in a directory, query a database, call the GitHub API, search the web, drive a browser. The agent sees those capabilities as tools, the same way it sees built-in tools like `Read` and `Bash`.

The ecosystem is wide. The official [MCP servers repo](https://github.com/modelcontextprotocol/servers) ships reference implementations for filesystem, GitHub, GitLab, Slack, Postgres, SQLite, Brave Search, Puppeteer, and more. Third parties add their own. Need an integration that doesn't exist? Write your own server in any language — the protocol is small and documented.

## Three Scopes for Config

MCP server configuration lives in one of three places:

```
Local       (default)  Per-project, private to you. CLI manages it.
Project     .mcp.json  Per-project, committed to the repo. Shared with the team.
User        ~/.claude.json  Available in every project. Personal.
```

Use project scope for servers that anyone working in the repo needs (the cinema's SQLite server is exactly this — the database file lives inside the project and the server only makes sense pointed at it). Use user scope for your personal kit (a filesystem server pointed at your notes directory). Local scope is the default when you don't pick.

## The Cinema's Tap — SQLite via `mcp-server-sqlite`

The plan from lesson 7 specifies SQLite, with `films.json` as the editable source of truth and `cinema.db` as a derived projection. The reasons restated: SQL is the right query language for "fewest films by mood", "average runtime", "everything with year > 2010", and the JSON file stays human-editable for `/add-film` and direct prods.

Two files do all the wiring.

`~/dev/cinema/.mcp.json`:

```json
{
  "mcpServers": {
    "cinema-db": {
      "command": "uvx",
      "args": [
        "mcp-server-sqlite",
        "--db-path",
        "${CLAUDE_PROJECT_DIR}/cinema.db"
      ]
    }
  }
}
```

The `${CLAUDE_PROJECT_DIR}` interpolates to the project root at runtime, so the server resolves to `~/dev/cinema/cinema.db` whatever directory the agent is operating in. `uvx` launches the SQLite MCP server in an ephemeral environment — no global install, no version drift.

The build script that creates the database from `films.json`:

`~/dev/cinema/scripts/build-cinema-db.sh`:

```bash
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
```

Run it once after cloning the kit:

```bash
chmod +x ~/dev/cinema/scripts/build-cinema-db.sh
~/dev/cinema/scripts/build-cinema-db.sh
```

```text
cinema.db rebuilt: 5 films.
```

The `watched_at` column gets created but stays NULL — the plan-mode write specifically marked a watch-log write path as out of scope. The `films_by_mood` view answers the original question — "which mood has the fewest films?" — in one MCP call.

## Adding It from the CLI Instead

The cinema commits its config to `.mcp.json` so every forker gets the same server. If you'd rather add it imperatively for a one-off, the CLI does it too:

```bash
claude mcp add --transport stdio cinema-db -- \
  uvx mcp-server-sqlite --db-path "$(pwd)/cinema.db"
```

Either path lands the server. The committed `.mcp.json` is the team-friendly version; the CLI is the personal-shell version.

## Using It

Open a session in the cinema:

```bash
cd ~/dev/cinema
claude
```

Confirm the server is loaded:

```text
> /mcp
```

Should show `cinema-db` with the SQLite tool list. Then ask a question that the JSON catalogue alone wouldn't answer cleanly:

```text
> Which mood currently has the fewest films, and what's the average
  runtime across the whole catalogue?
```

The agent uses the SQLite MCP's `read_query` tool to run `SELECT * FROM films_by_mood ORDER BY n ASC LIMIT 1` and `SELECT AVG(runtime) FROM films`. Two SQL queries, one English answer. No `jq` parsing, no manual aggregation, no copy-pasting from the terminal.

That's the value. The agent gained a *query language*, not just a *data file*.

## The Token Cost — The Bit That Matters

Each MCP server exposes a set of tool definitions, and *every tool definition costs context tokens*. A server with twenty tools adds twenty tool descriptions to the conversation header. Stack up four or five rich servers and you've burned 70,000 tokens before your first prompt.

Two mitigations:

1. **Tool Search** — built-in to Claude Code on Sonnet 4+ and Opus 4. When tool definitions exceed 10% of the context window, the agent dynamically loads only the tool schemas it needs for the current task. Drops context usage from ~72,000 tokens to ~8,700 in the typical case. You don't need to enable this; it activates automatically when the threshold is hit.
2. **Be selective about which servers are connected.** You don't need GitHub, Postgres, Puppeteer, and Brave Search all loaded for a session that's just querying cinema.db. Favour project scope so servers are only on when you're in the right repo — `.mcp.json` does exactly that. The cinema's server only loads inside `~/dev/cinema/`; everywhere else, it isn't there.

## The Bit the Docs Don't Mention

The cinema's one-way sync (films.json → cinema.db via `build-cinema-db.sh`) is the kind of gotcha worth knowing about for *any* MCP server that wraps a derived projection: when you mutate the source of truth, the derived store is stale until you rebuild. The MCP server happily returns the old data without warning you it's behind. The fix is conscious: keep one direction (JSON is the source, the DB is the projection) and run the rebuild step before you trust the next MCP answer. Automatic sync via a watcher would be cleverer; the manual rebuild keeps the kit small and the source-of-truth direction one-way. Live with the build step; gain the predictability.

The other quiet thing: if a server fails to start, the agent silently doesn't get its tools — there's no loud error in the session. Check `/mcp` early in any session if you're expecting a server to be available and the agent is acting like it isn't. `claude mcp list` from the shell shows the same information from outside the session.

## MCP vs `gh` / `psql` — When to Reach for Which

A real question I had once the Linear MCP was wired: when *should* I add an MCP server for something like GitHub vs just letting Claude use the `gh` CLI on demand? The honest answer that came out of using both:

- **`gh` (or `psql`, or any CLI) is fine when the interaction is occasional, one-shot, and read-mostly.** "Look at PR 142, summarise the diff" — `gh pr view 142` does the job. No MCP needed. I've never felt the GitHub MCP add anything for this shape.
- **MCP earns its keep when the integration is *bidirectional and repeated in the same shape*** — write plans to Linear, action issues with project context, cross-reference related initiatives. That's the Linear MCP case, and it's the case where wiring once and getting structured tools every session pays for itself.
- **MCP also wins when the *tool surface* matters** — Claude reasons better when it can call `mcp__linear__create_issue` than when it has to construct the right `gh` invocation each time. Typed tool definitions are easier on the agent than free-form Bash.

Rule of thumb: if you'd reach for the CLI three times a week in the same way, the MCP earns its keep. If it's once a fortnight, the CLI is fine.

## When to Reach for an MCP Server

Not every integration belongs as an MCP server. The honest criteria:

- **Reach for MCP** when the integration is *bidirectional* and you want Claude to *operate* on it, not just read it (write to GitHub, query a live database, drive a browser). The cinema's SQLite is exactly this — read queries are tools the agent can call.
- **Skip MCP** when a single Bash call would do the same job. `cat films.json` was fine; needing SQL is the trigger that justifies the server.
- **Definitely use MCP** for anything you'd reach for repeatedly in the same way.

## Have a Go — Wire the Cinema's MCP

```
~/dev/cinema/
├── ...
├── .mcp.json                          ← lesson 12 adds
├── scripts/
│   └── build-cinema-db.sh             ← lesson 12 adds
└── cinema.db                          ← generated, not committed
```

1. Drop in `.mcp.json` and `scripts/build-cinema-db.sh` (or `cp -r docs/10-mcp-servers/solution/. ~/dev/cinema/`).
2. `chmod +x scripts/build-cinema-db.sh && ./scripts/build-cinema-db.sh`. Confirm `cinema.db` is created with the right row count.
3. Inside `claude`, run `/mcp` and confirm `cinema-db` is loaded.
4. Ask the agent the question from the lesson-7 plan: *"Which mood currently has the fewest films?"* Watch the SQL fly.
5. Add a film via `/add-film`. Notice the MCP still reports the old count until you rerun `build-cinema-db.sh`. Make peace with the deliberate one-way sync, or pencil in a `SessionStart` hook that rebuilds the DB on every session — your call.
6. Commit and push:

```bash
git add .mcp.json scripts/build-cinema-db.sh
git commit -m "lesson 12: MCP server + cinema.db build script"
git push
```

## My Verdict on MCP

MCP is the most value-per-line-of-config feature in Claude Code. One install command brings a whole external system into the agent's reach, and the ecosystem is wide enough that the integration you want probably already exists. The protocol being open means anyone can write a server; the protocol being small means doing so is a weekend project, not a quarter.

The cost discipline matters. Token cost compounds across servers, and it's easy to end up with a session that's 60% tool definitions before you've typed anything. The 10% Tool Search threshold helps, but the right habit is: *use the smallest set of MCP servers that does the job*. The cinema's single SQLite server is exactly this — one server, one well-scoped data source, project-scoped so it never pollutes other repos.

What I'd do differently next time: nothing radical — sticking with one or two well-chosen servers (Linear for me; SQLite for the cinema) and reaching for `gh` and friends from the shell for everything else has worked well. The temptation to install every MCP server you read about is real, but a session loaded with twenty servers is a costume; one well-chosen server in a per-project `.mcp.json` is a tool.

On to lesson 13, fellow hungovercoder — let's pour the whole round and turn the agent loose.
