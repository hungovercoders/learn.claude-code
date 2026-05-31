# learn.claude-code — agent context

## What this repo is

A public tutorial for Claude Code (Anthropic's terminal-based AI coding agent). It serves two purposes simultaneously:
1. A forkable, runnable tutorial people can `git clone` and work through directly, building one cumulative project as they go
2. A content source for `hungovercoders.com/training/claude-code`, where `docs/` files are rendered as lesson pages

## Repo layout

```
project/                The finished Cinema Companion — reference end-state
docs/                   Lesson directories in tutorial order
  NN-slug/README.md     The lesson prose
  NN-slug/solution/     The new files this lesson adds to the project
Taskfile.yml            task verify-solutions: rebuilds project/ from solution/ deltas
```

## The cumulative-project convention

This series diverges from the per-lesson-freestanding pattern other `learn.*` repos use. Claude Code's features compose (skill calls hook, hook validates skill output, subagent reviews the work), so the tutorial composes too — one project, growing one deliverable at a time.

Two non-negotiables:

1. **Every lesson adds at least one concrete artefact** to the reader's local `cinema/` directory. Even concept-only lessons (`05-plan-mode`, `09-subagents-task-tool`) produce something tangible — a saved plan file, a written audit report.
2. **Every lesson's deliverable lives in `docs/NN-slug/solution/`** as the *delta* — only the new or changed files for that lesson. A forker who falls behind can `cp -r docs/06-custom-slash-commands/solution/. ~/dev/cinema/` and pick up where the lesson ended.

The full set of `solution/` deltas, merged in lesson order, must equal `project/` file-by-file. `task verify-solutions` enforces this — any drift fails the check.

## Lesson layout

Every `docs/NN-slug/` contains:

```
README.md               The lesson — prose + the deliverable framed against the cinema arc
solution/               Files the reader adds in this lesson (the delta)
```

Hands-on lessons that introduce a config file, hook script, custom slash command, or MCP server keep the example file *only* under `solution/` — not duplicated alongside `README.md`. The lesson prose embeds the file contents inline in fenced code blocks for the reader, and points to `solution/` as the canonical copy.

```
docs/06-custom-slash-commands/README.md                            ← lesson prose
docs/06-custom-slash-commands/solution/.claude/commands/film-pick.md   ← delta
docs/06-custom-slash-commands/solution/.claude/commands/film-suggest.md ← delta
```

## Conventions

**Frontmatter is required on every `README.md`.** The site build fails without it. Required fields:

```yaml
---
title: "Human-readable title"
series: claude-code
order: N
description: "One sentence, no trailing period."
canonical_url: https://hungovercoders.com/training/claude-code/NN-slug
---
```

**Naming**: `docs/` directories use leading-zero numbering and kebab-case slugs — `01-what-is-claude-code`, `02-installation-first-session`, etc.

**Shell commands in lessons** are shown in fenced code blocks tagged ```bash. Where a command's output matters, show the output in a second block tagged ```text below the command.

**Path conventions** — when a lesson references a file the reader adds, use the exact path inside their cinema repo (`~/dev/cinema/.claude/commands/film-pick.md`). Don't abbreviate. Match the path the `solution/` ships at.

**Reader trust** — assume the reader has a terminal and a code editor open, and that they've worked through prior lessons (so the cinema repo already exists from lesson 1). Don't re-explain things from earlier lessons. Do call out anything Claude Code specific that's coming up for the first time.

**Voice** — dataGriff voice guide (loaded via the hungovercoders content library). Mood-led, opinionated, Welsh/craft-beer references welcome where they fit naturally. Keep deliberate plain English over jargon.

## The Cinema Companion arc — what each lesson adds

| # | Lesson | Solution delta |
| - | - | - |
| 1 | what-is-claude-code | `films.json`, `pick-film.sh` (the seed) |
| 2 | installation-first-session | No new files — proof of a working `claude` session against the seed |
| 3 | permission-modes | `~/.claude/settings.json` (user-level allowlist for `jq` and `bash pick-film.sh`) |
| 4 | claude-md-project-context | `CLAUDE.md` |
| 5 | plan-mode | `plans/lesson-05-mcp-feature.md` |
| 6 | custom-slash-commands | `.claude/commands/film-pick.md`, `.claude/commands/film-suggest.md` |
| 7 | skills | `.claude/skills/add-film/SKILL.md`, `.claude/skills/pair/SKILL.md` |
| 8 | hooks | `.claude/hooks/films-validate.sh`, project `.claude/settings.json` (hook wiring) |
| 9 | subagents-task-tool | `.claude/skills/audit/SKILL.md` |
| 10 | mcp-servers | `.mcp.json`, `scripts/build-cinema-db.sh` |
| 11 | putting-it-together | `install.sh` (and `project/README.md` for forkers) |

When adding or restructuring a lesson, update both this table and `project/` so they stay in lockstep.
