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

1. **Every lesson adds at least one concrete artefact** to the reader's local `learn.claude-code/` workspace directory. Even concept-only lessons (`07-plan-mode`, `11-subagents-task-tool`) produce something tangible — a saved plan file, a written audit report.
2. **Every lesson's deliverable lives in `docs/NN-slug/solution/`** as the *delta* — only the new or changed files for that lesson. A forker who falls behind can `cp -r docs/08-custom-slash-commands/solution/. ~/dev/learn.claude-code/` and pick up where the lesson ended. Lessons whose deliverable is *proof* or lives *outside the project tree* (e.g. lesson 2's "run claude in your cinema repo", lesson 3's `~/.claude/CLAUDE.md` template) omit the `solution/` directory entirely.

**The auto-mode destination.** The arc is deliberate: each lesson 4 onward adds a *cage layer* that makes auto-mode (`claude --dangerously-skip-permissions` plus the harness Auto Mode bias) incrementally safer on the cinema. Lesson 13 is the proof — launch auto-mode and watch the layers catch every failure mode. When writing or editing a lesson, frame the deliverable not just as "feature N" but as "the layer that lets you trust the agent with X more rope."

The full set of `solution/` deltas, merged in lesson order, must equal `project/` file-by-file. `task verify-solutions` enforces this — any drift fails the check.

## Lesson layout

Every `docs/NN-slug/` contains:

```
README.md               The lesson — prose + the deliverable framed against the cinema arc
solution/               Files the reader adds in this lesson (the delta)
```

Hands-on lessons that introduce a config file, hook script, custom slash command, or MCP server keep the example file *only* under `solution/` — not duplicated alongside `README.md`. The lesson prose embeds the file contents inline in fenced code blocks for the reader, and points to `solution/` as the canonical copy.

```
docs/08-custom-slash-commands/README.md                            ← lesson prose
docs/08-custom-slash-commands/solution/.claude/commands/film-pick.md   ← delta
docs/08-custom-slash-commands/solution/.claude/commands/film-suggest.md ← delta
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

**Naming**: `docs/` directories use leading-zero numbering and kebab-case slugs — `01-what-is-claude-code`, `02-installation-first-session`, etc. The exception is the cheat sheet at `docs/cheatsheet/` (no number, `order: 99` in frontmatter so the site sorts it last).

**Shell commands in lessons** are shown in fenced code blocks tagged ```bash. Where a command's output matters, show the output in a second block tagged ```text below the command.

**Path conventions** — when a lesson references a file the reader adds, use the exact path inside their workspace (`~/dev/learn.claude-code/.claude/commands/film-pick.md`). Don't abbreviate. Match the path the `solution/` ships at. The workspace directory is always `~/dev/learn.claude-code/` — matches what `git clone` produces, so the manual-create and clone-the-repo paths converge. The "cinema" naming stays as the *project metaphor* (the Cinema Companion kit being built), not as a directory name.

**Reader trust** — assume the reader has a terminal and a code editor open, and that they've worked through prior lessons (so the cinema repo already exists from lesson 1). Don't re-explain things from earlier lessons. Do call out anything Claude Code specific that's coming up for the first time.

**Voice** — dataGriff voice guide (loaded via the hungovercoders content library). Mood-led, opinionated, Welsh/craft-beer references welcome where they fit naturally. Keep deliberate plain English over jargon.

## The Cinema Companion arc — what each lesson adds

| # | Lesson | Solution delta | Cage layer |
| - | - | - | - |
| 1 | what-is-claude-code | `films.json`, `pick-film.sh` (the seed) | — |
| 2 | installation-first-session | No new files — proof of a working `claude` session against the seed | — |
| 3 | user-level-claude-md | No project delta — `~/.claude/CLAUDE.md` template embedded in the lesson prose | Personal defaults applied to every session everywhere |
| 4 | branch-and-draft-pr | `.github/pull_request_template.md` | Branch isolation; every change visible on remote |
| 5 | permission-modes | `.claude/settings.json` (permissions block) | Project-scoped allow + deny; deny wins |
| 6 | claude-md-project-context | `CLAUDE.md` | Conventions + "never do" encoded |
| 7 | plan-mode | `plans/mcp-feature.md` | Plan-before-execute discipline |
| 8 | custom-slash-commands | `.claude/commands/film-pick.md`, `.claude/commands/film-suggest.md` | `allowed-tools` narrowing per command |
| 9 | skills | `.claude/skills/add-film/SKILL.md`, `.claude/skills/pair/SKILL.md` | `disable-model-invocation` on writes + tight `allowed-tools` |
| 10 | hooks | `.claude/hooks/films-validate.sh`, project `.claude/settings.json` (hook wiring) | Schema enforcement — the agent cannot break the catalogue |
| 11 | subagents-task-tool | `.claude/skills/audit/SKILL.md` | Context isolation |
| 12 | mcp-servers | `.mcp.json`, `scripts/build-cinema-db.sh` | Bounded external access via typed tools |
| 13 | putting-it-together-auto-mode | `install.sh` (and `project/README.md` for forkers) | The proof — auto-mode runs safely because of layers 4–12 |
| 99 | cheatsheet | No solution delta — reference page. Keys, built-in commands, lifecycle events, exit codes, file paths, the cinema-specific commands, the branch/PR workflow, the auto-mode safety checklist. Links each section back to its source lesson. | — |

When adding or restructuring a lesson, update both this table and `project/` so they stay in lockstep. The cheat sheet is a reference *summary*, not a source of truth — when commands or shortcuts change, update the lesson first and then mirror the change in the cheat sheet.

## Lessons 4 onwards commit + push

Every lesson from 4 onwards ends with a `git commit` + `git push` step. The reader is on a feature branch with a draft PR opened in lesson 4; each subsequent lesson lands one commit on that PR. By lesson 13 the PR diff is the whole build, ready for review or merge. When writing or editing a lesson's "Have a Go", keep this closing step.
