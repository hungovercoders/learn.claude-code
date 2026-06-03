---
title: "Subagents and the Task Tool"
series: claude-code
order: 11
description: "Add the cinema's /audit skill — three parallel Explore subagents that find duplicates, mood drift, and field issues in films.json without polluting the parent context"
canonical_url: https://hungovercoders.com/training/claude-code/11-subagents-task-tool
---

I wanted Claude to audit `films.json` for duplicate titles, mood drift away from the conventions in `CLAUDE.md`, and any rows the lesson-10 hook would have rejected if they'd been written today — *without* filling my main context window with three full reads of the file and three full chains of reasoning. Subagents are the fix. The Task tool lets the main session spawn three junior Claudes in parallel, hand each one a narrow question, and get back one unified report. In this lesson the cinema gets its `audit` skill, which is itself a skill that spawns three subagents.

## Pre-Requisites

- Comfortable with hooks, skills, and slash commands (lessons 8–10)
- The cinema's films.json with a few rows in it (more is better — the seed five is the minimum for the audit to find anything interesting)
- An understanding that an agent's context window is a finite, valuable resource

## Sending Someone to the Bar — What a Subagent Is

A subagent is a named, isolated Claude instance. It runs *inside* your Claude Code session — same machine, same authentication — but it has:

- Its **own context window**, separate from yours
- A **custom system prompt** that defines its speciality
- Its **own tool allow-list**, often narrower than the parent
- Its **own model choice** (Sonnet for breadth, Opus for depth, Haiku for speed)

The parent calls a subagent via the `Task` tool. The subagent does its work — reads files, runs greps, even spawns its own tool calls — and returns *one final summary* to the parent. Everything in the middle stays in the subagent's window; the parent's context only sees the result.

That's the killer property: **context isolation**. A 400-file search that would have filled your main window with 50,000 tokens becomes a 200-token answer in the parent context. The subagent did the work; you got the conclusion.

## When to Send Someone to the Bar

Two situations:

**1. Context protection.** Big searches, big reads, anything where the *raw input* you'd need to gather isn't worth keeping in conversation memory. The cinema's `audit` is exactly this: each subagent reads `films.json` and `CLAUDE.md` and does its analysis, then returns one paragraph of findings. The parent context never holds three copies of the catalogue.

**2. Parallelism.** When you've got several independent questions, you can spawn subagents in parallel and they'll run concurrently. *"Find duplicates, find mood drift, find field issues — independently — and report back"* is three subagents, ~3× the wall-clock speedup over doing them in sequence.

The catch on parallelism: subagents *don't share context in real time*. If subagent A's output changes what subagent B should do, you can't have them running at the same time. Sequential. Spawn A, wait, spawn B with A's output. Truly independent work is the parallel sweet spot — which is exactly why the audit's three foci were chosen to not depend on each other.

## The Regulars Behind the Bar

Claude Code ships with a handful of specialised subagents. The one you'll meet first is the **Explore** agent — a read-only search agent purpose-built for "find me X in the codebase". It can grep, read, and locate without touching the filesystem in any way that changes state. It's the right default for the cinema's audit because every subagent we spawn is going to *read* `films.json` and *report*, never write.

There's a **general-purpose** agent for open-ended research. There's a **Plan** agent for designing implementation strategies. Each has a different system prompt and a different shape of output. The agent selects which one based on the description of your task.

## The Cinema's `/audit` Skill — A Skill That Spawns Subagents

Here's a lovely shape — a *skill that spawns subagents*. The `audit` skill is a single user-facing invocation that delegates its actual work to three Explore agents in parallel. The reader fires `/audit`; three subagents run; one unified report comes back.

`~/dev/cinema/.claude/skills/audit/SKILL.md`:

```markdown
---
name: audit
description: Audit films.json for duplicates, mood drift, and missing fields using parallel subagents
allowed-tools: Read, Agent
disable-model-invocation: true
---

Audit `./films.json` for data quality. Spawn three parallel Explore
subagents in a single message:

1. **Duplicate detection** — read films.json and report any titles
   that appear more than once, or near-duplicates (same year + first
   five words of title).
2. **Mood drift** — read films.json and CLAUDE.md, list every mood
   value that doesn't appear in the conventions block, and propose
   either renaming or adding to the conventions.
3. **Missing or malformed fields** — every entry must have a
   four-digit year, a single-lowercase-word mood, and a runtime
   integer between 60 and 240. Report rows that fail.

Wait for all three to return. Combine the findings into one short
markdown report under headings *Duplicates*, *Mood drift*, *Field
issues*. End with a single recommended next action — the first
thing you would fix if you only had ten minutes.

Don't edit films.json. This is a read-only audit.
```

The frontmatter does the safety work. `allowed-tools: Read, Agent` means the skill can read files and spawn subagents — that's it. It can't `Edit`, can't run `Bash`, can't accidentally fix what it found. `disable-model-invocation: true` because audits are deliberate; you don't want Claude running `/audit` on its own at random.

Fire it:

```text
> /audit
```

What you see in the session: a single `Agent` tool call with three sub-tasks. Watch the parent context — it stays small. Each subagent's reads and reasoning happen in its own window. When all three return, the parent assembles their summaries into one report. Your main conversation gets the *report*, not the underlying greps.

This is the value. Three full reads of `films.json` would have eaten through the parent context; three subagents kept the parent's window clean for the *next* question you want to ask.

## Who Gets Past the Velvet Rope

By default, subagents inherit a sensible tool allow-list — Explore is read-only, general-purpose has more freedom. You can also create your own subagents via `/agents` and define their tool access yourself. Want a subagent that can run tests but never touch production secrets? Define it.

```text
> /agents
```

That opens a UI for creating subagents at the user level or project level. Each new subagent is saved as a markdown file in `.claude/agents/<name>.md` with frontmatter describing the name, description, allowed tools, and (optionally) model. The shape is similar to a skill, but the file *describes a worker*, not a one-shot prompt.

The cinema doesn't need a custom subagent — the built-in Explore agent does exactly the job. That's the right starting position: reach for the built-ins until they don't fit, then define your own.

## The Bit the Docs Don't Mention

First time I used subagents I assumed they were a free speed-up. They're not free. Each subagent is *another Claude API call* — costs tokens, takes wall-clock time to spin up. For a 10-file search you'd burn more on the subagent overhead than on doing the grep inline. **The rule of thumb: subagents earn their keep when the inline alternative would put more than ~5,000 tokens of noise into the parent context.** Below that, just do the work inline.

The cinema's audit barely clears that bar — `films.json` is small. The reason the skill still uses subagents is that the *parallelism* makes the audit finish in one wall-clock pass instead of three sequential passes, and the parent context stays cleaner for the next prompt. As `films.json` grows past 50 rows, the case for the audit-as-subagents shape gets stronger; below 10 rows, you could honestly do it inline and skip the overhead. The shape teaches the pattern, not the optimum.

The other quiet thing: subagents return a *summary*, not the raw result. If the summary is wrong or incomplete, the parent session has no way to inspect the underlying work. I've had subagents tell me "I found three matches" when I knew there were five — because the subagent's internal grep was filtered in a way I didn't ask for. The fix is to be precise in the task description: "list every match verbatim with file and line number" — make the summary structure-explicit, not vibe-based. The audit's three numbered foci do exactly this.

## Have a Go — Add the Audit Skill to the Cinema

```
~/dev/cinema/
├── ...
└── .claude/
    └── skills/
        ├── add-film/SKILL.md
        ├── pair/SKILL.md
        └── audit/SKILL.md           ← lesson 11 adds
```

1. Drop in the skill (or `cp -r docs/09-subagents-task-tool/solution/. ~/dev/cinema/`).
2. Add a few deliberately-dodgy films to your catalogue before running the audit — a duplicate, a mood that doesn't exist in your `CLAUDE.md` conventions, a row with a bad year. Use `/add-film` or edit `films.json` by hand (the lesson-10 hook will refuse anything that breaks the schema; for these tests you need the row to be valid JSON but conceptually dodgy).
3. Fire `/audit`. Watch the three subagents run. Read the unified report — does it catch what you planted?
4. Time `/audit` versus running the same three questions inline as separate prompts. Notice the parallelism win on wall-clock and the context-isolation win on token cost.
5. Try `/agents` and look at the built-in subagent definitions. The Explore agent is the one the cinema's audit reaches for; the others are there for different shapes of work.
6. Commit and push:

```bash
git add .claude/skills/audit/
git commit -m "lesson 11: audit skill spawning parallel subagents"
git push
```

## My Verdict on Subagents

Subagents are the right architectural answer to *agents have finite context*. The main session stays focused on the task you care about; the subagents handle the work that would otherwise drown it in detail. The Task tool's parallelism is a nice bonus for independent work, but the context-protection benefit is what earns subagents a permanent place in real workflows.

The risk is over-use. Every subagent costs tokens and time, and a session that delegates everything to subagents ends up slower than one that did the work inline. The discipline: spawn a subagent when the alternative would pollute the parent context with material you don't need to read, and not before. The cinema's audit is on the edge of justification for a 5-row catalogue; as the catalogue grows, the case strengthens. That edge-case shape is the right teaching example — it's the line, not the obvious win.

What I'd do differently next time: I'd lean on the built-in **Explore** agent harder. I spent two weeks writing my own subagent prompts for "find X in the codebase" before realising the built-in one was already tuned for exactly that job and didn't need any of my prompt engineering.

On to lesson 12, fellow hungovercoder — time to plug the external tap into the cinema.
