---
title: "CLAUDE.md and Project Context"
series: claude-code
order: 4
description: "Write a project context file the agent will actually read, follow, and respect — without stuffing it like a Sunday roast"
canonical_url: https://hungovercoders.com/training/claude-code/04-claude-md-project-context
---

I wanted the agent to stop forgetting that this project uses tabs not spaces, that we run tests with `bun test` not `npm test`, and that the database migrations live in `infra/db/` not `src/migrations/`. I'd been retyping the same five reminders into the opening prompt of every session. The fix is a `CLAUDE.md` file — but the catch is, the moment you treat it like a wiki page, Claude starts ignoring half of it. This lesson is about writing one that survives.

## Pre-Requisites

- A repo with real conventions worth documenting (tabs vs spaces, custom test command, deploy script — anything you find yourself repeating to a new hire)
- Claude Code installed and authenticated
- About fifteen minutes to do the `/init` and prune cycle properly

## The Recipe Card the Agent Reads First

`CLAUDE.md` is a markdown file at the root of your project that Claude Code reads into context at the start of every session. Anything in here is part of every conversation about this codebase. It's the closest thing the agent has to institutional memory.

There's a user-level version too — `~/.claude/CLAUDE.md` — which gets loaded for *every* session across every project. Use that for your personal preferences (terse responses, conventional commits, no emoji unless asked). Use the project-level one for things specific to *this* repo.

The hierarchy:

```
~/.claude/CLAUDE.md           Personal defaults — every project, every session.
<repo>/CLAUDE.md              Project context — read on every session in this repo.
<repo>/<subdir>/CLAUDE.md     Sub-project context — read when work happens in that subdir.
```

You can also point to other files using `@filename` syntax. A single line `@AGENTS.md` in `CLAUDE.md` means "load AGENTS.md at the same time" — useful if you've already got an `AGENTS.md` (as we do in this repo) and don't want to duplicate.

## Starting the Pour — `/init`

Inside any repo, run:

```bash
claude
```

Then type:

```text
> /init
```

Claude inspects the project structure and writes a starter `CLAUDE.md` for you. It'll look at your `package.json` (or `pyproject.toml`, or `Cargo.toml`), notice your test runner, scan a few files for code style, and produce a first draft.

**Don't accept the first draft.** Read it, prune it, and rewrite the bits that don't match how you actually work. The starter is a base camp, not a destination.

## The WHY / WHAT / HOW Pattern

The cleanest mental model I've found for what goes in a `CLAUDE.md`:

- **WHY** — what is this project, who is it for, what problem does it solve
- **WHAT** — the architecture in one paragraph, the directories that matter, the boundaries to respect
- **HOW** — the commands to run things (test, build, deploy), the conventions to follow, the things to never do

Here's a real shape that earns its keep. This is the `CLAUDE.md` for a fictional Welsh craft beer ordering app I keep around as a reference:

```markdown
# brewbook — agent context

## What this project is

A small ordering app for Tiny Rebel pop-up bars. Customers tap a tablet at the
door, pick a flight of three beers from the current keg list, and the kitchen
gets a ticket. Bun + SQLite + htmx. Single binary deploy.

## Repo layout

- `src/server/`  — Bun HTTP handlers
- `src/web/`     — htmx templates (no React, no SPA — keep it that way)
- `db/`          — SQLite schema, migrations, and the `keg-list.sql` seed file
- `scripts/`     — deploy and ops scripts

## Commands

- `bun dev`           — start the dev server
- `bun test`          — run all tests (DO NOT use `npm test` — this is a Bun project)
- `bun db:migrate`    — apply pending migrations
- `./scripts/deploy`  — single-command deploy to the Pi at the bar

## Code style

- Tabs, not spaces
- British English everywhere (`flavour`, `colour`, `behaviour`)
- No comments unless the *why* is non-obvious — the code should explain itself

## Things to never do

- Add a JavaScript framework to `src/web/` — the htmx-only constraint is load-bearing
- Edit the seed file `db/keg-list.sql` to add test fixtures; use a separate
  seed file in `db/test-fixtures/` instead
```

That whole file is under 40 lines. It tells the agent everything it can't infer from the code. **It does not** restate things Claude can see for itself (the language, the obvious file layout, what `package.json` already declares).

## Progressive Disclosure — The Real Discipline

The mistake I made on my first proper `CLAUDE.md` was treating it as a wiki page. I wrote a long, well-organised document explaining the architecture, the API endpoints, the database schema, the deployment process. It was a lovely document. Claude ignored half of it.

The fix is *progressive disclosure*: don't put information in `CLAUDE.md` — put a *pointer* to it.

Instead of:

```markdown
## Architecture

The system has three components:
1. The order intake service receives tablet taps via WebSocket...
[200 more lines]
```

Write:

```markdown
## Architecture

See `docs/architecture.md` for the full system diagram. The headline:
intake service → ticket queue → kitchen display. Each is a separate Bun
process talking over Unix sockets.
```

The agent reads the headline. If it needs the detail, it knows where to look. Your `CLAUDE.md` stays under the 150-line ceiling where Claude actually pays attention to every word.

## The Bit the Docs Don't Mention

This is the bit the docs don't quite spell out: `CLAUDE.md` instructions get followed about 70% of the time. For anything that must always happen — "never commit secrets", "always run `bun test` before declaring done" — **don't put it in `CLAUDE.md`, put it in a hook**. Lesson 8 covers hooks. The short version: instructions in `CLAUDE.md` are suggestions; hooks are enforcement. Use the right tool for the right job.

## Have a Go

Get one repo's `CLAUDE.md` to a state you actually trust.

1. Run `/init` in a repo. Read every line of the generated file before saving.
2. Prune it down to under 50 lines. Delete anything Claude could infer from `package.json`, the README, or a five-second `ls`.
3. Add a `## Things to never do` section with three real entries from your project. (Real ones — not "be careful with `rm`". Things specific to *this* codebase.)
4. Start a new session and ask Claude something that should require the `CLAUDE.md` to answer correctly (e.g. *"What's the command to run the tests?"*). Confirm it uses your custom command, not the default it would have guessed.

## My Verdict on CLAUDE.md

`CLAUDE.md` is the highest-leverage configuration file in Claude Code. The agent reads it on every session, so a well-written one improves every interaction. But it punishes ambition — write too much and you train yourself to *think* the agent has the context, when really half the file is being skipped. The discipline is brevity.

The team-level upside of committing `CLAUDE.md` to your repo is real: every developer on the project gets a consistent agent, and the file itself becomes a kind of executable onboarding doc. Newcomers read it; the agent reads it; it stays accurate because both groups notice when it drifts.

What I'd do differently next time: start the file at *ten lines*, not the `/init` starter. Force myself to justify every section as I add it. The starter is convenient but it's full of things that *look* useful and are actually noise.

On to lesson 5, fellow hungovercoder — let's brew the plan before we pour anything.
