# learn.claude-code — agent context

## What this repo is

A public tutorial for Claude Code (Anthropic's terminal-based AI coding agent). It serves two purposes simultaneously:
1. A forkable, runnable tutorial people can `git clone` and work through directly
2. A content source for `hungovercoders.com/training/claude-code`, where `docs/` files are rendered as lesson pages

## Repo layout

```
docs/   lesson directories in tutorial order — each contains README.md + (if hands-on) any example files referenced in the lesson
```

Every lesson is a directory under `docs/`. Hands-on lessons that demonstrate a config file, hook script, custom slash command, or MCP server include the example file alongside `README.md`. Concept-only lessons have only `README.md`.

```
docs/01-what-is-claude-code/README.md          ← concept only
docs/02-installation/README.md                  ← hands-on (commands the reader runs)
docs/05-slash-commands/README.md                ← hands-on
docs/05-slash-commands/example-command.md       ← runnable example file
docs/07-hooks/README.md
docs/07-hooks/example-hook.sh                   ← runnable example script
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

**Naming**: `docs/` directories use leading-zero numbering and kebab-case slugs — `01-what-is-claude-code`, `02-installation`, etc.

**Shell commands in lessons** are shown in fenced code blocks tagged ```bash. Where a command's output matters, show the output in a second block tagged ```text below the command.

**Config files and slash command markdown** use clean, minimal examples — no placeholder `TODO` lines, no dead options. Every example file must work as-is.

**Path conventions** — when a lesson references a file the reader creates (e.g. `~/.claude/settings.json`, `.claude/commands/my-command.md`), use the exact path the reader will type. Don't abbreviate to `<config>` or `<path>`.

**Reader trust** — assume the reader has a terminal and a code editor open. Don't explain what a shell is or what a markdown file is. Do explain anything Claude Code specific (skills, hooks, MCP, the difference between `.claude/commands/` and `.claude/skills/`).
