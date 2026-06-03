---
title: "What is Claude Code?"
series: claude-code
order: 1
description: "An honest first look at Anthropic's terminal-based coding agent, the eleven moving parts you'll meet across the series, and the Cinema Companion you'll build as we go"
canonical_url: https://hungovercoders.com/training/claude-code/01-what-is-claude-code
---

I wanted to stop tab-switching between my editor and a chat window every five minutes. I'd been doing the dance for a year — paste code into Claude.ai, copy the suggestion back, run it, paste the error, copy the fix back. By the end of a Friday afternoon I'd done it forty times and could feel the keyboard shortcut wearing into my thumb. So when Anthropic shipped Claude Code — an agent that *lives in the terminal next to your code* — I cracked it open the same week. This lesson is what I'd want a fellow hungovercoder to know before they start, plus the small kit we're going to build across the series so the pieces stop feeling like separate features and start composing.

## Pouring Your Own Pint, Not Ordering at the Bar

[Claude.ai](https://claude.ai) is the pub. You walk in, ask for a pint of clarity, and someone behind the bar pours it for you. It's clean, it's friendly, and the staff know what they're doing. But you have to go *to* the pub, you can't take your code with you, and every round starts a fresh tab.

Claude Code is the kit you set up at home. It's a CLI tool you install once and run from inside your project. It can read your files, edit them, run `git`, run your tests, search the codebase, kick off a build, and read the result. It's not a chatbot you copy into; it's an agent that *operates on your repo*.

That distinction is most of the point. The chat window doesn't know what's in your `src/`. Claude Code does — because it can `ls` and `grep` and `Read` like you do. You stop describing your codebase and start letting the agent see it.

## What's Actually in the Glass

Out of the box you get:

- **Tool use.** It runs `Bash`, edits files, searches with `grep`, reads files, fetches URLs. Every action is a tool call you can see and (by default) approve.
- **CLAUDE.md** — a project file you fill in once that gives the agent persistent context. Code style, the things to avoid, the things to always do. It's the recipe card it reads before pouring anything.
- **Slash commands.** Type `/init`, `/permissions`, `/agents`, `/help`. You can write your own — markdown files in `.claude/commands/` that fire on a slash.
- **Skills.** The newer cousin of slash commands. A folder under `.claude/skills/` with a `SKILL.md` and any supporting scripts. Claude can pick them up automatically when the task fits.
- **Hooks.** Shell scripts that fire before or after tool calls. The bouncer at the door — useful for guardrails, audit logs, or auto-running formatters.
- **MCP servers.** External integrations via the Model Context Protocol. Wire up GitHub, a database, Gmail, anything with an MCP server.
- **Subagents.** It can spawn helper Claudes for big searches or parallel work. You don't burn your main context window on a grep that returns 400 hits.
- **Plan mode.** A read-only thinking gear where the agent investigates the problem and writes a plan before it changes a single file. The bit that stops it from "vibing" at your codebase.

You'll meet every one of those in this series — each as a concrete thing you add to a small project, not as a feature in isolation.

## What We're Building — the Cinema Companion

Each lesson adds one file (or one set of files) to one growing kit. By lesson eleven you'll have a small Cinema Companion that picks a film by mood, validates its own catalogue, pairs the pick with a snack and a drink, and runs from any directory on your machine.

The seed is two files — `films.json` and `pick-film.sh`. They are the same two files my [launch blog post](https://hungovercoders.com/blog/2026-05-25-building-a-film-picker-with-claude-code) ships, which is the twenty-minute appetiser version of this series. The tutorial extends them. You don't need to have read the blog first; the seed below is the whole starting point.

```
~/dev/cinema/
├── films.json        ← lesson 1
└── pick-film.sh      ← lesson 1
```

By lesson eleven that directory will also contain a `CLAUDE.md`, two slash commands, three skills, a schema-checking hook, an MCP server wiring, and an `install.sh` that symlinks the whole `.claude/` directory into `~/.claude/`. Each lesson ends with "add this to your cinema repo." Each step is small. The composition is the point.

## The Bit the Docs Don't Mention

I'll be honest — the first time I let Claude Code loose I gave it a task in my home directory by mistake and watched it try to `find . -name "*.tsx"` against my entire `~`. It didn't break anything because the default permissions made it ask before each Bash call. But I felt my chest tighten while I waited. **The permissions system is real and you should learn it before you turn anything off.** Lesson three exists for a reason and it's not optional reading.

## When to Reach for Claude Code (and When Not To)

Reach for it when:

- You're inside a real codebase and the work spans more than one file
- You want it to actually run the thing, not just describe it
- You're doing a refactor, a migration, or a hunt across a repo

Stay in the chat window when:

- You just want a quick code snippet with no context (faster in the browser)
- You're brainstorming an idea, not editing code
- You don't have a codebase open — Claude Code without files is just a worse chat

Most working developers I know end up using both. Pub on the way home, kit at home on a Sunday afternoon. They do different jobs.

## Have a Go — Plant the Seed

This lesson's deliverable is the smallest possible thing: a working film picker with no Claude Code in it yet. Two files, eight lines of bash, five films of catalogue. Lesson two installs Claude Code and points it at this directory.

`~/dev/cinema/films.json`:

```json
[
  { "title": "The Mandalorian and Grogu", "year": 2026, "mood": "fun",      "runtime": 105 },
  { "title": "Twin Town",                  "year": 1997, "mood": "cardiff",  "runtime": 99  },
  { "title": "How Green Was My Valley",    "year": 1941, "mood": "homesick", "runtime": 118 },
  { "title": "Hedd Wyn",                   "year": 1992, "mood": "wales",    "runtime": 123 },
  { "title": "Hot Fuzz",                   "year": 2007, "mood": "comedy",   "runtime": 121 }
]
```

`~/dev/cinema/pick-film.sh`:

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
mkdir -p ~/dev/cinema
# Paste the two files above into ~/dev/cinema/, then:
chmod +x ~/dev/cinema/pick-film.sh
~/dev/cinema/pick-film.sh wales
```

```text
Hedd Wyn (1992) — 123min
```

Or, if you'd rather skip the typing and copy from the repo:

```bash
git clone https://github.com/hungovercoders/learn.claude-code.git
cp -r learn.claude-code/docs/01-what-is-claude-code/solution/. ~/dev/cinema/
chmod +x ~/dev/cinema/pick-film.sh
```

Both paths leave you with the same `~/dev/cinema/` — eight lines of bash and a small JSON file. That's the canvas. The next ten lessons paint Claude Code onto it.

Also worth a skim before lesson two:

1. The [Claude Code overview docs](https://code.claude.com/docs/en/overview) — get the shape, don't read every section.
2. The [Claude Code best-practices page](https://code.claude.com/docs/en/best-practices) — find the bit about CLAUDE.md being overstuffed. We'll come back to that in lessons 3 and 6.
3. `node -v` in your terminal — confirm you've got Node ≥ 20 if you'd rather install Claude Code via npm than the native binary.

## My Verdict at the End of Lesson One

Claude Code is the version of an AI assistant I actually use every day. Not because the model is better than the one in the chat window — same model under the hood — but because *the integration is the product*. The agent sees what I see, runs what I'd run, and reads the same errors I'd read. That changes the work. The chat window is a clever consultant; Claude Code is a junior dev who stayed for the next round.

What I'd do differently if I were learning this again: I'd spend less time reading the docs and more time pointing it at a real repo from day one. The shape of the tool only makes sense once it's working on something you actually care about. Hence the cinema — small enough to fit in your head, big enough by lesson eleven to feel like a workflow.

On to lesson 2, fellow hungovercoder — let's get the first round in.
