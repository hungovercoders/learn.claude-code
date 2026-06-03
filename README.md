# learn.claude-code

A hands-on hungovercoders tutorial for Claude Code — Anthropic's terminal-based AI coding agent. Thirteen lessons that walk you from personal defaults through installation, branch isolation, permissions, project context, plan mode, custom slash commands, skills, hooks, subagents, and MCP servers — landing at a final lesson where you launch the agent in auto-mode on the project you've built and watch it run safely, because every prior lesson laid down a layer of the cage that makes auto-mode safe.

Read the lessons in order at [hungovercoders.com/training/claude-code](https://hungovercoders.com/training/claude-code), or clone this repo and work through them locally with Claude Code itself sat next to the docs.

## What you build along the way — the Cinema Companion

This series isn't a feature tour. It's a build-along with a destination. Each lesson adds one concrete piece — a command, a skill, a hook, a plan, an MCP wiring — to a single growing kit called the Cinema Companion: a small CLI that picks a film by mood, validates its own catalogue, pairs the pick to a snack and a drink, and runs from any directory by lesson thirteen.

The destination is *safe auto-mode*. By lesson 13 the cinema has enough scaffolding — branch isolation, deny rules, schema-enforcing hooks, allowed-tools narrowing, MCP-bounded external access — that you can launch the agent with `claude --dangerously-skip-permissions` *plus* the harness Auto Mode bias and trust it to act unsupervised. The cage you build in lessons 4–12 is what earns that.

The finished kit ships in [`project/`](./project/) — fork the repo, work through the lessons, and by the end your local `~/dev/cinema/` matches what's in `project/` file-by-file.

```
project/
├── films.json                 Catalogue (lesson 1 seed)
├── pick-film.sh               Bash + jq picker (lesson 1 seed)
├── CLAUDE.md                  Project context (lesson 6)
├── install.sh                 Symlinks .claude/ into ~/.claude/ (lesson 13)
├── plans/mcp-feature.md       Plan-mode artefact (lesson 7)
├── scripts/build-cinema-db.sh Builds cinema.db (lesson 12)
├── .mcp.json                  MCP server wiring (lesson 12)
├── .github/
│   └── pull_request_template.md   PR checklist (lesson 4)
└── .claude/
    ├── settings.json          Permissions + hook wiring (lessons 5, 10)
    ├── commands/              /film-pick, /film-suggest (lesson 8)
    ├── skills/                /add-film, /pair, /audit (lessons 9, 11)
    └── hooks/                 films-validate.sh (lesson 10)
```

Each lesson directory under [`docs/`](./docs/) ships a `solution/` containing only the new files that lesson adds. If you get stuck, `cp -r docs/08-custom-slash-commands/solution/. ~/dev/cinema/` and carry on. The full set of `solution/` deltas reassembles into `project/` — that's what `task verify-solutions` checks.

There's also a one-page [cheat sheet](./docs/cheatsheet/) — keyboard shortcuts, built-in slash commands, permission modes, hook exit codes, file paths, the cinema-specific commands, the branch/PR workflow, and the auto-mode safety checklist. Reference shape, links every section back to its source lesson. Keep it open while you work.

## Fork and follow

```bash
git clone https://github.com/hungovercoders/learn.claude-code.git
cd learn.claude-code
# Read docs/01-what-is-claude-code/README.md to start.
# Copy the lesson 1 seed somewhere you'll keep editing:
mkdir -p ~/dev/cinema
cp -r docs/01-what-is-claude-code/solution/. ~/dev/cinema/
```

Then work through the lessons in order — each one tells you what to add to `~/dev/cinema/`, and ships its delta in `solution/` for when you want to skip ahead or recover from a tangent. Lessons 4 onwards each end with a `git commit` + `git push` so the kit grows visibly on your draft PR.

## The 13 lessons at a glance

| # | Lesson | The cage layer it adds |
| - | - | - |
| 1 | What is Claude Code | — |
| 2 | Installation + first session | — |
| 3 | User-level CLAUDE.md and personal patterns | Personal defaults applied everywhere |
| 4 | Branch + draft PR from session one | Main untouchable; every change visible on remote |
| 5 | Permission modes | Project-scoped allow + deny; deny wins |
| 6 | CLAUDE.md and project context | Conventions and "never do" encoded |
| 7 | Plan mode | Plan-before-execute discipline |
| 8 | Custom slash commands | `allowed-tools` narrowing |
| 9 | Skills | `disable-model-invocation` on writes + tight `allowed-tools` |
| 10 | Hooks | Schema enforcement — the agent cannot break the catalogue |
| 11 | Subagents and the Task tool | Context isolation — big work stays out of the main window |
| 12 | MCP servers | Bounded external access via typed tools |
| 13 | Putting it together and safe auto-mode | The proof — `--dangerously-skip-permissions` runs safely because of layers 4–12 |

## How it differs from the launch blog post

The companion blog post — *[Building a Film Picker with Claude Code](https://hungovercoders.com/blog/2026-05-25-building-a-film-picker-with-claude-code)* — is the twenty-minute appetiser: same film theme, three files, one skill, one hook. The tutorial extends those three files into the full kit with a destination: two slash commands, three skills, a schema-checking hook, a subagent audit, an MCP server, an install script, and the auto-mode proof. Read the blog first if you want the taste; read the series if you want the build.
