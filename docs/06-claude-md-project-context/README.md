---
title: "CLAUDE.md and Project Context"
series: claude-code
order: 6
description: "Write the recipe card the cinema's agent reads at the start of every session — without stuffing it like a Sunday roast"
canonical_url: https://hungovercoders.com/training/claude-code/06-claude-md-project-context
---

Lesson 3 was the personal-defaults CLAUDE.md — the things you'd want true in every session everywhere. This one is the project-level layer that tells Claude what's specific to *this* repo: in our case the cinema's data shape, what `pick-film.sh` does, the mood conventions, where new films go in `films.json`. Without a project CLAUDE.md you find yourself retyping the same project-specific context into every opening prompt; with one, the agent reads it on session start and you can get to the work. The catch is, the moment you treat it like a wiki page, Claude starts ignoring half of it. This lesson is the one that earns its keep in every session that follows.

## Pre-Requisites

- The cinema seed (`~/dev/learn.claude-code/films.json` + `pick-film.sh`)
- Your user-level `~/.claude/CLAUDE.md` from lesson 3 — this lesson's project-level file *composes* with it
- The cinema on a feature branch with a draft PR open (lesson 4)
- The project-level `.claude/settings.json` from lesson 5
- About fifteen minutes to do the `/init` and prune cycle properly

## The Recipe Card the Agent Reads First

`CLAUDE.md` is a markdown file at the root of your project that Claude Code reads into context at the start of every session. Anything in here is part of every conversation about this codebase. It's the closest thing the agent has to institutional memory.

You wrote the user-level version in lesson 3 — `~/.claude/CLAUDE.md` — which gets loaded for *every* session across every project, encoding your personal defaults (terse responses, conventional commits, no emoji unless asked). This lesson layers the *project-level* file on top, for things specific to *this* repo.

The hierarchy:

```
~/.claude/CLAUDE.md           Personal defaults — every project, every session.
<repo>/CLAUDE.md              Project context — read on every session in this repo.
<repo>/<subdir>/CLAUDE.md     Sub-project context — read when work happens in that subdir.
```

You can also point to other files using `@filename` syntax. A single line `@AGENTS.md` in `CLAUDE.md` means "load AGENTS.md at the same time" — useful if you've already got an `AGENTS.md` (as we do in this very repo) and don't want to duplicate.

**A practice I lean on across my own projects:** write the bulk of the project context into `AGENTS.md` (the open standard for *any* coding agent, not just Claude Code), then have a one-line `CLAUDE.md` that says `@AGENTS.md`. One source of truth, multiple agents reading it. The cinema follows the simpler "CLAUDE.md is the canonical file" pattern for the lesson, but the AGENTS-first pattern is what I'd reach for on a real project where more than one tool might read the context.

## Starting the Pour — `/init`

Inside the cinema, run:

```bash
cd ~/dev/learn.claude-code
claude
```

Then type:

```text
> /init
```

Claude inspects the project, notices `films.json`, reads `pick-film.sh`, scans the directory layout, and writes a starter `CLAUDE.md`. It'll get the data shape right and the picker's contract roughly correct.

**Don't accept the first draft.** Read it, prune it, and rewrite the bits that don't match how you actually work. The starter is a base camp, not a destination — `/init` will pad it with things it can already see in the code, and those are the bits to delete.

## The WHY / WHAT / HOW Pattern

The cleanest mental model I've found for what goes in a `CLAUDE.md`:

- **WHY** — what is this project, who is it for, what problem does it solve
- **WHAT** — the architecture in one paragraph, the directories that matter, the boundaries to respect
- **HOW** — the commands to run things (test, build, deploy), the conventions to follow, the things to never do

The cinema's version, pruned to the lines that actually earn their keep:

```markdown
# cinema — agent context

## What this is

A small CLI for picking a film by mood, plus a Claude Code kit that
extends it. Bash + jq + a JSON catalogue. No Python, no Node, no
dependencies beyond `jq`.

The kit grows across the eleven `learn.claude-code` lessons — by
lesson eleven this directory holds the picker, two slash commands,
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
```

Under fifty lines. It tells the agent everything it can't infer from the code. **It does not** restate things Claude can see for itself — there's no point telling it the project is bash, it can read the shebang.

It also mentions files we haven't built yet (`install.sh`, `films-validate.sh`, `.mcp.json`). That's deliberate — the `CLAUDE.md` describes the *intended shape*, not just today's state. As the cinema grows the description stays accurate, and Claude reads the same file every session.

## Progressive Disclosure — The Real Discipline

The temptation with a project-level CLAUDE.md is to treat it as a wiki page — explain the architecture, list every endpoint, walk through the deployment, document every convention you can think of. The result is a lovely document Claude reads the first thirty lines of and then summarises the rest into a vibe. Optimising the size of CLAUDE files is an ongoing discipline; mine is still a work in progress.

The fix is *progressive disclosure*: don't put information in `CLAUDE.md` — put a *pointer* to it.

Instead of:

```markdown
## The picker algorithm

`pick-film.sh` takes a mood, runs a jq filter on films.json that selects
all matching rows, then prints the first one. The mood matching is exact
(no fuzzy matching), case-sensitive, and...
[40 more lines]
```

Write:

```markdown
## The picker algorithm

See `pick-film.sh`. One-line summary: jq filters films.json by exact
mood match, prints the first row formatted as "Title (Year) — Nmin".
```

The agent reads the headline. If it needs the detail, it knows where to look. Your `CLAUDE.md` stays under the 150-line ceiling where Claude actually pays attention to every word.

## The Bit the Docs Don't Mention

This is the bit the docs don't quite spell out: `CLAUDE.md` instructions get followed about 70% of the time. For anything that must always happen — "never commit secrets", "always run tests before declaring done", "films.json must keep its schema" — **don't put it in `CLAUDE.md`, put it in a hook**. Lesson 10 covers hooks. The short version: instructions in `CLAUDE.md` are suggestions; hooks are enforcement. Use the right tool for the right job. That's exactly what we'll do for `films.json` schema validation — `CLAUDE.md` says "don't break the schema", the lesson 10 hook *enforces* it.

## Have a Go — Add CLAUDE.md to the Cinema

```
~/dev/learn.claude-code/
├── films.json
├── pick-film.sh
├── CLAUDE.md             ← lesson 6 adds this
└── .claude/
    └── settings.json
```

1. `/init` in the cinema. Read every line of the generated file before saving.
2. Replace the generated content with the cinema version above (or `cp docs/04-claude-md-project-context/solution/CLAUDE.md ~/dev/learn.claude-code/`).
3. Start a new session and ask Claude something only the `CLAUDE.md` can answer correctly: *"What schema do films.json entries follow?"* or *"What's the mood convention?"*. Confirm the answer matches the file you just wrote.
4. Ask it a question the `CLAUDE.md` doesn't cover (e.g. *"How many films are currently in the catalogue?"*) and watch it `Read` `films.json` to find out — `CLAUDE.md` for the rules, the code for the detail.
5. Commit the new `CLAUDE.md` to your feature branch and push:

```bash
git add CLAUDE.md
git commit -m "lesson 6: project CLAUDE.md"
git push
```

## My Verdict on CLAUDE.md

`CLAUDE.md` is the most-useful configuration file in Claude Code. The agent reads it on every session, so a well-written one improves every interaction. But it punishes ambition — write too much and you train yourself to *think* the agent has the context, when really half the file is being skipped. The discipline is brevity.

The team-level upside of committing `CLAUDE.md` to your repo is real: every developer on the project gets a consistent agent, and the file itself becomes a kind of executable onboarding doc. Newcomers read it; the agent reads it; it stays accurate because both groups notice when it drifts. The cinema's `CLAUDE.md` is also the file that links the lessons together — every future lesson assumes the agent has read it.

What I'd do differently next time: start the file at *ten lines*, not the `/init` starter. Force myself to justify every section as I add it. The starter is convenient but it's full of things that *look* useful and are actually noise.

On to lesson 7, fellow hungovercoder — let's brew the plan before we pour anything.
