---
title: "What is Claude Code?"
series: claude-code
order: 1
description: "An honest first look at Anthropic's terminal-based coding agent, the moving parts you'll meet across the series, and the Cinema Companion you'll build as we go"
canonical_url: https://hungovercoders.com/training/claude-code/01-what-is-claude-code
---

I'll be honest about why I'm here. I was happy using Copilot in an agentic chat interface and felt I was doing OK there. What made me reach for Claude Code was outside pressure: the industry trumpets and increased usage around me made me want to see what the fuss was about and ensure I was skilled in something becoming increasingly common. The love came later — it's now awesome, including straight from the terminal, and using it with multi-threaded terminal tools like [cmux](https://github.com/coder/cmux) or [zed](https://zed.dev) has really opened my eyes. This lesson is what I'd want a fellow hungovercoder to know before they start, plus the small kit we're going to build across the series so the pieces stop feeling like separate features and start composing.

## Texting a Mate vs Sitting Next to One

[Claude.ai](https://claude.ai) is texting a mate who happens to be a brilliant developer. You describe a problem, paste a snippet, and they reply with something useful. They're sharp, they're patient, they know the answer. But they can't see your screen. Every bit of context costs a paste, every error message you forgot to share is a wrong turn, and by the third round-trip you've lost the thread of what you were doing.

Claude Code is the same mate, sat at the desk next to you. They can `ls` your repo, `grep` for the function that's calling the broken one, run your test suite, read the failure, edit the file, run the test again. The conversation goes from describing to pointing — *"this thing here, why does it do that?"* — because they're looking at exactly what you're looking at.

That distinction is most of the point. The chat window doesn't know what's in your `src/`. Claude Code does — because it can `ls` and `grep` and `Read` like you do. You stop describing your codebase and start letting the agent see it.

## What Ships With Claude Code

Out of the box you get:

- **Tool use.** It runs `Bash`, edits files, searches with `grep`, reads files, fetches URLs. Every action is a tool call you can see and (by default) approve.
- **CLAUDE.md** — a project file you fill in once that gives the agent persistent context. Code style, the things to avoid, the things to always do. It's the recipe card the agent reads before doing anything.
- **Slash commands.** Type `/init`, `/permissions`, `/agents`, `/help`. You can write your own — markdown files in `.claude/commands/` that fire on a slash.
- **Skills.** The newer cousin of slash commands. A folder under `.claude/skills/` with a `SKILL.md` and any supporting scripts. Claude can pick them up automatically when the task fits.
- **Hooks.** Shell scripts that fire before or after tool calls. The bouncer at the door — useful for guardrails, audit logs, or auto-running formatters.
- **MCP servers.** External integrations via the Model Context Protocol. Wire up GitHub, a database, Gmail, anything with an MCP server.
- **Subagents.** It can spawn helper Claudes for big searches or parallel work. You don't burn your main context window on a grep that returns 400 hits.
- **Plan mode.** A read-only thinking gear where the agent investigates the problem and writes a plan before it changes a single file. The bit that stops it from "vibing" at your codebase.

You'll meet every one of those in this series — each as a concrete thing you add to a small project, not as a feature in isolation.

## What We're Building — the Cinema Companion

Each lesson adds one file (or one set of files) to one growing kit. By lesson thirteen you'll have a small Cinema Companion that picks a film by mood, validates its own catalogue, pairs the pick with a snack and a drink, and runs from any directory on your machine.

The seed is two files — `films.json` and `pick-film.sh`. They are the same two files my [launch blog post](https://hungovercoders.com/blog/2026-05-25-building-a-film-picker-with-claude-code) ships, which is the twenty-minute appetiser version of this series. The tutorial extends them. You don't need to have read the blog first; the seed below is the whole starting point.

```
~/dev/learn.claude-code/
├── films.json        ← lesson 1
└── pick-film.sh      ← lesson 1
```

By lesson thirteen that directory will also contain a `CLAUDE.md`, two slash commands, three skills, a schema-checking hook, an MCP server wiring, and an `install.sh` that symlinks the whole `.claude/` directory into `~/.claude/`. Each lesson ends with "add this to your cinema repo." Each step is small. The composition is the point.

## The Bit the Docs Don't Mention

Lesson 13 has a real story about getting into an auto-edit "accept changes" loop without thinking — pressing yes through what turned out to be a force push that rewrote history on a repo. The takeaway from that story is the whole shape of this series: **getting guardrails in with an intent to use auto mode as a discipline is a better goal than lazily pressing 2 over and over.** The permissions system is the first guardrail and lesson 5 is where it goes in. It's not optional reading.

## When to Reach for Claude Code (and When Not To)

Reach for it when:

- You're inside a real codebase and the work spans more than one file
- You want it to actually run the thing, not just describe it
- You're doing a refactor, a migration, or a hunt across a repo

Stay in the chat window when:

- You just want a quick code snippet with no context (faster in the browser)
- You're brainstorming an idea, not editing code
- You don't have a codebase open — Claude Code without files is just a worse chat

Most working developers I know end up using both. The chat window for the quick stuff, Claude Code for anything that lives in a real codebase. They do different jobs.

## Have a Go — Plant the Seed

This lesson's deliverable is the smallest possible thing: a working film picker with no Claude Code in it yet. Two files, eight lines of bash, five films of catalogue. Lesson two installs Claude Code and points it at this directory.

`~/dev/learn.claude-code/films.json`:

```json
[
  { "title": "The Mandalorian and Grogu", "year": 2026, "mood": "fun",      "runtime": 105 },
  { "title": "Twin Town",                  "year": 1997, "mood": "cardiff",  "runtime": 99  },
  { "title": "How Green Was My Valley",    "year": 1941, "mood": "homesick", "runtime": 118 },
  { "title": "Hedd Wyn",                   "year": 1992, "mood": "wales",    "runtime": 123 },
  { "title": "Hot Fuzz",                   "year": 2007, "mood": "comedy",   "runtime": 121 }
]
```

`~/dev/learn.claude-code/pick-film.sh`:

```bash
#!/bin/bash
mood="${1:-fun}"
jq -r --arg m "$mood" '
  [.[] | select(.mood == $m)] |
  if length == 0 then "No film for mood: \($m). Try another."
  else (.[0] | "\(.title) (\(.year)) — \(.runtime)min")
  end
' "$(dirname "$0")/films.json"
```

```bash
mkdir -p ~/dev/learn.claude-code
cd ~/dev/learn.claude-code
# Paste the two files above into this directory, then:
chmod +x pick-film.sh
./pick-film.sh wales
```

```text
Hedd Wyn (1992) — 123min
```

Or, if you'd rather skip the typing and copy from the repo:

```bash
git clone https://github.com/hungovercoders/learn.claude-code.git ~/dev/learn.claude-code
cd ~/dev/learn.claude-code
cp -r docs/01-what-is-claude-code/solution/. .
chmod +x pick-film.sh
```

Both paths leave you sat in the same `~/dev/learn.claude-code/` — eight lines of bash and a small JSON file. (The clone path also gives you `docs/`, `project/`, and the rest of this tutorial as reference material alongside; the manual path keeps your workspace empty.) That's the canvas. The next twelve lessons paint Claude Code onto it.

Also worth a skim before lesson two:

1. The [Claude Code overview docs](https://code.claude.com/docs/en/overview) — get the shape, don't read every section.
2. The [Claude Code best-practices page](https://code.claude.com/docs/en/best-practices) — find the bit about CLAUDE.md being overstuffed. We'll come back to that in lessons 3 and 6.
3. `node -v` in your terminal — confirm you've got Node ≥ 20 if you'd rather install Claude Code via npm than the native binary.

## My Verdict at the End of Lesson One

I use Claude Code all the time now for parallel threads of work, and development output and idea delivery is through the roof. I still need to harden up the tooling to make rapid change safe in all the places — which is exactly why the cinema we're about to build is small and scoped. The hello world of the SDLC in isolation before tackling complex codebases is the right place to learn the discipline.

What I'd do differently if I were starting again: you can't really skip the "use it and see what breaks" phase, but with the discipline now, the move is to set up the guardrails and race for auto-mode proficiency as quickly as possible. That's where maximum throughput lives — embedding the policies then letting rip with development knowing the guardrails are there. The next twelve lessons are that race, run small.

On to lesson 2, fellow hungovercoder — let's get the first round in.
