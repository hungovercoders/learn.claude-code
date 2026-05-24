---
title: "What is Claude Code?"
series: claude-code
order: 1
description: "An honest first look at Anthropic's terminal-based coding agent and why it earns a permanent seat at your workstation"
canonical_url: https://hungovercoders.com/training/claude-code/01-what-is-claude-code
---

I wanted to stop tab-switching between my editor and a chat window every five minutes. I'd been doing the dance for a year — paste code into Claude.ai, copy the suggestion back, run it, paste the error, copy the fix back. By the end of a Friday afternoon I'd done it forty times and could feel the keyboard shortcut wearing into my thumb. So when Anthropic shipped Claude Code — an agent that *lives in the terminal next to your code* — I cracked it open the same week. This lesson is what I'd want a fellow hungovercoder to know before they start.

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

You'll meet every one of those in this series.

## The Bit the Docs Don't Mention

I'll be honest — the first time I let Claude Code loose I gave it a task in my home directory by mistake and watched it try to `find . -name "*.tsx"` against my entire `~`. It didn't break anything because the default permissions made it ask before each Bash call. But I felt my chest tighten while I waited. **The permissions system is real and you should learn it before you turn anything off.** That lesson three exists for a reason and it's not optional reading.

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

## Have a Go

You don't write code in this lesson — you set up the lay of the land. Try these:

1. Skim the [Claude Code overview docs](https://code.claude.com/docs/en/overview). Don't read every section; get the shape.
2. Look at the [Claude Code best-practices page](https://code.claude.com/docs/en/best-practices) and find the bit about CLAUDE.md being overstuffed. We'll come back to that in lesson 4.
3. Open your terminal and check whether you've got `node` ≥ 20 installed (`node -v`). Lesson 2 installs the CLI.
4. Think of one repo you'd want the agent to live inside. Have it ready for the rest of the series.

## My Verdict at the End of Lesson One

Claude Code is the version of an AI assistant I actually use every day. Not because the model is better than the one in the chat window — same model under the hood — but because *the integration is the product*. The agent sees what I see, runs what I'd run, and reads the same errors I'd read. That changes the work. The chat window is a clever consultant; Claude Code is a junior dev who stayed for the next round.

What I'd do differently if I were learning this again: I'd spend less time reading the docs and more time pointing it at a real repo from day one. The shape of the tool only makes sense once it's working on something you actually care about.

On to lesson 2, fellow hungovercoder — let's get the first round in.
