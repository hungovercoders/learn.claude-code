---
title: "Subagents and the Task Tool"
series: claude-code
order: 9
description: "When to send a junior Claude to the bar on your behalf — context isolation, parallelism, and the Task tool that orchestrates it"
canonical_url: https://hungovercoders.com/training/claude-code/09-subagents-task-tool
---

I wanted Claude to grep across about 400 files without filling my main context window with 400 chunks of text I didn't need to read. The shape of the problem was: I'm working on a specific task, and I need an answer about *somewhere else in the codebase* to make a decision. Reading all those files into context to answer the question would waste the context budget I needed for the actual work. Subagents are the fix. The Task tool lets the main session spawn a junior Claude, hand it the question, and get back just the answer — not the noise of the search.

## Pre-Requisites

- Comfortable with hooks and slash commands (lessons 6–8)
- A repo big enough that "search the whole thing" is a real operation
- An understanding that an agent's context window is a finite, valuable resource

## Sending Someone to the Bar — What a Subagent Is

A subagent is a named, isolated Claude instance. It runs *inside* your Claude Code session — same machine, same authentication — but it has:

- Its **own context window**, separate from yours
- A **custom system prompt** that defines its specialty
- Its **own tool allow-list**, often narrower than the parent
- Its **own model choice** (Sonnet for breadth, Opus for depth, Haiku for speed)

The parent calls a subagent via the `Task` tool. The subagent does its work — reads files, runs greps, even spawns its own tool calls — and returns *one final summary* to the parent. Everything in the middle stays in the subagent's window; the parent's context only sees the result.

That's the killer property: **context isolation**. A 400-file search that would have filled your main window with 50,000 tokens becomes a 200-token answer in the parent context. The subagent did the work; you got the conclusion.

## When to Reach for a Subagent

Two situations:

**1. Context protection.** Big searches, big reads, anything where the *raw input* you'd need to gather isn't worth keeping in conversation memory. "Find every place we set a `Content-Type` header and tell me which ones use a non-default value" — let a subagent do the grep work and give you the list.

**2. Parallelism.** When you've got several independent questions, you can spawn subagents in parallel and they'll run concurrently. "Audit the tests, audit the docs, audit the config — independently — and report back" is three subagents, ~3× the wall-clock speedup.

The catch on parallelism: subagents *don't share context in real time*. If subagent A's output changes what subagent B should do, you can't have them running at the same time. Sequential. Spawn A, wait, spawn B with A's output. Truly independent work is the parallel sweet spot.

## Built-In Subagents

Claude Code ships with a handful of specialised subagents. The one you'll meet first is the **Explore** agent — a read-only search agent purpose-built for "find me X in the codebase". It can grep, read, and locate without touching the filesystem in any way that changes state. It's the right default for "where is this defined?", "which files reference Y?", "give me the call sites of Z".

There's a **general-purpose** agent for open-ended research. There's a **Plan** agent for designing implementation strategies. Each has a different system prompt and a different shape of output. The agent selects which one based on the description of your task and the description of each available subagent.

## A Real Use Case — "Audit Before You Refactor"

Imagine you're about to rename a class. Before the refactor, you want to know:

- Every file that references the class
- Whether any of those files have tests
- Whether the docs mention it anywhere

Three independent reads. Three subagents:

```text
> I'm about to rename the OrderTicket class to KitchenTicket.
  Before I start, spawn three parallel subagents to audit:

  1. Find every file that imports or references OrderTicket
  2. Find any test files that exercise OrderTicket behaviour
  3. Search the docs/ directory for any mention of OrderTicket

  Report back a unified summary I can sanity-check before the refactor.
```

The main session orchestrates. Three Explore subagents fan out. Each one does its independent search, comes back with a list. The main session merges the three lists and presents them to you. Your context window contains *the summary*, not the underlying greps. The refactor proceeds with a known surface area.

## The Subagent's Allow-List Matters

By default, subagents inherit a sensible tool allow-list — Explore is read-only, general-purpose has more freedom. You can also create your own subagents via `/agents` and define their tool access yourself. Want a subagent that can run tests but never touch production secrets? Define it.

```text
> /agents
```

That opens a UI for creating subagents at the user level or project level. Each new subagent is saved as a markdown file in `.claude/agents/<name>.md` with frontmatter describing the name, description, allowed tools, and (optionally) model. The shape is similar to a skill, but the file *describes a worker*, not a one-shot prompt.

## The Bit the Docs Don't Mention

First time I used subagents I assumed they were a free speed-up. They're not free. Each subagent is *another Claude API call* — costs tokens, takes wall-clock time to spin up. For a 10-file search you'd burn more on the subagent overhead than on doing the grep inline. **The rule of thumb: subagents earn their keep when the inline alternative would put more than ~5,000 tokens of noise into the parent context.** Below that, just do the work inline.

The other quiet thing: subagents return a *summary*, not the raw result. If the summary is wrong or incomplete, the parent session has no way to inspect the underlying work. I've had subagents tell me "I found three matches" when I knew there were five — because the subagent's internal grep was filtered in a way I didn't ask for. The fix is to be precise in the task description: "list every match verbatim with file and line number" — make the summary structure-explicit, not vibe-based.

## Have a Go

Try these — the second one is the most instructive.

1. Open a real repo and ask Claude to spawn an Explore subagent to find every file referencing a specific function. Watch how the parent context stays small.
2. Spawn three subagents in parallel for three independent questions. Note the wall-clock vs sequential — and note when it's *not* faster (small searches).
3. Run `/agents` and create a personal subagent with a tightly-scoped allow-list (e.g. read-only + a single specific Bash matcher). Use it to audit a part of your codebase you don't fully trust yourself in.
4. Ask Claude to do something that *shouldn't* use a subagent (a quick single-file read, say) and notice if it offers to spawn one anyway. Push back if so — overusing subagents is a real failure mode.

## My Verdict on Subagents

Subagents are the right architectural answer to *agents have finite context*. The main session stays focused on the task you care about; the subagents handle the work that would otherwise drown it in detail. The Task tool's parallelism is a nice bonus for independent work, but the context-protection benefit is what earns subagents a permanent place in real workflows.

The risk is over-use. Every subagent costs tokens and time, and a session that delegates everything to subagents ends up slower than one that did the work inline. The discipline: spawn a subagent when the alternative would pollute the parent context with material you don't need to read, and not before.

What I'd do differently next time: I'd lean on the built-in **Explore** agent harder. I spent two weeks writing my own subagent prompts for "find X in the codebase" before realising the built-in one was already tuned for exactly that job and didn't need any of my prompt engineering.

On to lesson 10, fellow hungovercoder — let's plug an external tap into the bar.
