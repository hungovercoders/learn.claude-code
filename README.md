# learn.claude-code

A hands-on hungovercoders tutorial for Claude Code — Anthropic's terminal-based AI coding agent. Eleven lessons that walk you through installation, permissions, project context, plan mode, custom slash commands, skills, hooks, subagents, and MCP servers — then string the lot together into a workflow you actually use.

Read the lessons in order at [hungovercoders.com/training/claude-code](https://hungovercoders.com/training/claude-code), or clone this repo and work through them locally with Claude Code itself sat next to the docs.

## What you build along the way — the Cinema Companion

This series isn't a feature tour. It's a build-along. Each lesson adds one concrete piece — a command, a skill, a hook, a plan, an MCP wiring — to a single growing kit called the Cinema Companion: a small CLI that picks a film by mood, validates its own catalogue, pairs the pick to a snack and a drink, and runs from any directory by lesson eleven.

The finished kit ships in [`project/`](./project/) — fork the repo, work through the lessons, and by the end your local `~/dev/cinema/` matches what's in `project/` file-by-file.

```
project/
├── films.json                 Catalogue (lesson 1 seed)
├── pick-film.sh               Bash + jq picker (lesson 1 seed)
├── CLAUDE.md                  Project context (lesson 4)
├── install.sh                 Symlinks .claude/ into ~/.claude/ (lesson 11)
├── plans/lesson-05-mcp-feature.md   Plan-mode artefact (lesson 5)
├── scripts/build-cinema-db.sh Builds cinema.db (lesson 10)
├── .mcp.json                  MCP server wiring (lesson 10)
└── .claude/
    ├── settings.json          Permissions + hook wiring (lessons 3, 8)
    ├── commands/              /film-pick, /film-suggest (lesson 6)
    ├── skills/                /add-film, /pair, /audit (lessons 7, 9)
    └── hooks/                 films-validate.sh (lesson 8)
```

Each lesson directory under [`docs/`](./docs/) ships a `solution/` containing only the new files that lesson adds. If you get stuck, `cp -r docs/06-custom-slash-commands/solution/. ~/dev/cinema/` and carry on. The full set of `solution/` deltas reassembles into `project/` — that's what `task verify-solutions` checks.

## Fork and follow

```bash
git clone https://github.com/hungovercoders/learn.claude-code.git
cd learn.claude-code
# Read docs/01-what-is-claude-code/README.md to start.
# Copy the lesson 1 seed somewhere you'll keep editing:
mkdir -p ~/dev/cinema
cp -r docs/01-what-is-claude-code/solution/. ~/dev/cinema/
```

Then work through the lessons in order — each one tells you what to add to `~/dev/cinema/`, and ships its delta in `solution/` for when you want to skip ahead or recover from a tangent.

## How it differs from the launch blog post

The companion blog post — *[Building a Film Picker with Claude Code](https://hungovercoders.com/blog/2026-05-25-building-a-film-picker-with-claude-code)* — is the twenty-minute appetiser: same film theme, three files, one skill, one hook. The tutorial extends those three files into the full kit: two slash commands, two skills, a schema-checking hook, a subagent audit, an MCP server, and an install script. Read the blog first if you want the taste; read the series if you want the build.
