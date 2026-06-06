---
title: "Context and Cost"
series: claude-code
order: 12
description: "The /context and /compact commands, why CLAUDE.md size matters, when to compact vs start a fresh session, and the cinema's /checkpoint command that turns context discipline into a slash invocation"
canonical_url: https://hungovercoders.com/training/claude-code/12-context-and-cost
---

Honest place to open this one: I'm still working on optimising the size of my CLAUDE.md files. The "just keep adding to it" reflex catches everyone the first few months, and a 30kB CLAUDE.md is ~10k tokens of your window gone before you've typed a single prompt — five sessions a day and you've burned through a real chunk of what you're paying for. This lesson is the antidote: `/context` to see exactly what's loaded, `/compact` to summarise mid-session when a long thread starts dragging, and the discipline rules around when *fresh session* beats *compact* beats *just-keep-going*. The cinema gets a `/checkpoint` slash command that asks the agent to audit its own context and recommend the next move.

## Pre-Requisites

- Lessons 8-11 finished — slash commands, skills, hooks, and subagents are now in your tool belt
- A few sessions of cinema work in your history (so `/context` has something to look at)
- An appreciation that tokens cost money and the context window is finite

## The Context Window — Finite, Valuable, Easy to Waste

Every session has a window — typically 200,000 tokens, up to 1,000,000 on extended context models. Everything in the conversation lives in that window: the system prompt, every loaded tool definition, every CLAUDE.md file, every Read result, every Bash output, every prior message. When the window fills, the agent starts forgetting the start of the conversation. When the window is *consistently* full of cruft, the same five tasks cost five times the tokens they need to.

Two reasons to care:

1. **Cost.** Anthropic prompt caching gives you a 5-minute TTL — within five minutes of the last call, the cached prefix is cheap. Past five minutes, you pay full price for the whole prefix on the next call. So idle sessions that wake up after a long pause re-pay for the world.
2. **Quality.** A 70%-full window means the agent's reasoning has to weigh the *actually-relevant* recent prompt against thousands of tokens of older context that may now be irrelevant. Things get diluted. Slower and worse answers.

The two built-in commands that put you in charge of this are `/context` and `/compact`.

## `/context` — Show Me What's Loaded

`/context` opens an overview of your current window usage:

```text
> /context
```

What you'll see (the categories vary slightly by model and version):

![A typical /context output. Terminal-style screenshot: header reading "Context Usage — Opus 4.7 (1M context)", 686.8k of 1m tokens used (69%), a horizontal usage bar showing the category split with most of the bar consumed by Messages (67.3%) and 30% free space. Category breakdown table: System prompt 8.8k (0.9%), System tools 15.4k (1.5%), Memory files 865 (0.1%), Skills 2.6k (0.3%), Messages 672.7k (67.3%), Free space 299.6k (30.0%). Below: Memory files lists ~/.claude/CLAUDE.md and the project CLAUDE.md with their token counts. Below that: Skills lists add-film, pair, audit, checkpoint as the loaded skills with combined token count.](/assets/training/claude-code/context-output-mockup.svg)

Three columns of useful information:

- **Where the tokens went** — usually 60–80% is messages (your conversation history); the rest is system prompt, tools, memory files, skills. If memory files or MCP tools are over 5% individually, you've got a discipline problem worth fixing at the source.
- **What's loaded right now** — the listed CLAUDE.md files, the active skills, the connected MCP servers' tools. Useful before adding *more* to remind yourself what's already there.
- **Free space** — the headroom. Under 30% headroom is the warning zone; under 10% is the panic zone.

`/context` is non-mutative. It just shows you. Run it whenever you feel a session "dragging" — it almost always tells you why.

## `/compact` — Summarise the Conversation and Keep Going

When the conversation history is the problem (lots of long Bash outputs, big file Reads, exploratory work that's no longer relevant), `/compact` asks the agent to summarise everything so far into a much smaller representation, then continues with that summary in place of the raw history.

```text
> /compact
```

```text
Compacting conversation...
Kept: 14% of original message tokens
New free space: 78%
```

The agent retains the *conclusions* from the prior work — what it found, what it changed, what it decided. It drops the *raw material* — the test outputs, the file contents it Read, the dead-end exploration. You carry on from a much lighter context.

The trade-off is real and worth knowing: **specific facts in the dropped material may now be unrecoverable** until you remind the agent (or re-Read the file). If you've been working with a file's exact line numbers and you `/compact`, the agent may need to Read the file again the next time you reference line 47. That's why the discipline below matters — `/compact` saves money but isn't free.

Compaction also runs *automatically* in the background when the conversation approaches its limit. The system summarises older messages and surfaces a summary so you can keep working without hitting a wall. Manual `/compact` lets you do it deliberately, on your terms, before the auto-pass triggers and picks moments you didn't.

## When Fresh Beats Compact Beats Just-Keep-Going

The honest decision tree, refined over enough long sessions:

| Situation | Right move | Why |
|---|---|---|
| New task, unrelated to current session | **Fresh session** | Old context is pure noise. Don't drag it in. |
| Same task, conversation getting unwieldy, mid-work | **/compact** | Free space, keep the decisions made so far |
| Same task, occasional clarifying question | **Just keep going** | Compaction is overhead; don't do it for fun |
| Window over 80%, mid-task | **/compact immediately** | The auto-compact may pick a bad moment |
| Window over 80%, near task end | **Finish the task, then fresh** | Don't disrupt the last mile |
| You're about to switch from "explore the codebase" to "make changes" | **Consider /compact** | The exploration's Reads are heavy; you've extracted the value |

The bias to break: people *compact too rarely*. The window crawls up, quality drops, costs creep, and they don't realise until they've burned hours. The discipline is to peek with `/context` at natural breakpoints — finished a feature, about to start a new file, returning after lunch — and act on what you see.

## CLAUDE.md Size — The Discipline That Pays in Every Session

Lesson 6 introduced project CLAUDE.md. Lesson 3 introduced the user-level one. Both are loaded into context on *every session*, so every byte you put in them costs tokens forever. A 30kB CLAUDE.md is ~10k tokens per session — across 50 sessions a week, that's 500k tokens of repeated overhead for the SAME static content.

Discipline rules:

1. **Lean on `@AGENTS.md` imports** to keep a single source of truth across tools (Claude Code, Cursor, etc.). One canonical file means one place to trim. The pattern from lesson 6 is exactly this.
2. **Audit periodically.** Open your CLAUDE.md every couple of weeks. Anything that's "nice to know" but hasn't been needed in actual sessions probably doesn't earn its tokens. Delete it.
3. **Move project-specific examples into skills, not CLAUDE.md.** Skills are loaded *on demand*; CLAUDE.md is loaded *always*. A 200-token skill that fires when relevant beats a 200-token CLAUDE.md section that fires *always whether you need it or not*.
4. **Don't put code samples in CLAUDE.md.** Reference the file by path. The agent can Read it when needed.

The 1M-context era softens this a little — there's more headroom — but caches still TTL after 5 minutes and bigger windows still take longer to attend to. Lean still wins.

## MCP Token Cost — Pre-Knowledge for Lesson 13

The next lesson wires the cinema's MCP server. The headline thing to take into this: every MCP server you connect adds *all of its tool definitions* to the system prompt. A modest server with 10 tools adds ~3k tokens. A rich server (20+ tools, verbose descriptions) can add 20k+. Stack four or five and you've burned 60k tokens before you've typed a prompt.

Mitigations the next lesson covers — Tool Search auto-loading, project-scoped `.mcp.json` instead of user-scoped — are the practical answers. The principle that earns them their keep is the principle of this lesson: *every token you spend on overhead is a token you don't have for the work.*

## Subagents as Context Saviours — The Pattern from Lesson 11

The reason lesson 11 exists in this series is the same reason this lesson does. When a 400-file grep would have poured 50k tokens of raw output into your parent context, a Task-tool subagent does the grep in *its own window*, returns a 200-token summary, and your parent context never knows. That's context discipline as architecture — built into the tool, not just into your habits.

The corollary: reach for a subagent specifically when the alternative is *the parent context absorbing material you don't need to read*. That's the trigger. Lesson 11's audit example was on the edge of justification because `films.json` is tiny; for a real codebase with thousands of files, every subagent earns its keep on context alone.

## The Bit the Docs Don't Mention

**`/compact` is destructive to recoverable detail.** If you've been working through a tricky bug and the agent's mid-debug, *don't* `/compact` right before asking the next question — the specific line numbers, exact error messages, and the chain of "I tried X, that failed, so I tried Y" may compress away. Compact at *breakpoints*: after a feature lands, after a refactor commits, after a test passes. Not mid-investigation.

**The 5-minute cache TTL changes the maths on long idle gaps.** If you walked away for 20 minutes and come back, the next call to the agent is *not* cheap — the whole prefix gets re-priced. Two practical responses: (1) plan long-running thinking into 5-minute-or-less chunks, or (2) accept the cost and don't worry about it for occasional gaps. The trap is *thinking the prompt cache always saves you* — past 5 minutes it doesn't.

**`/context` lies a little about MCP tool tokens.** MCP tools are listed in the breakdown, but the actual token cost is paid in the system prompt where the tool definitions live. The category percentages are guidance, not invoice-grade accuracy. Treat `/context` as a posture check, not a billing tool.

## Have a Go — Add `/checkpoint` to the Cinema

The cinema gets a discipline command. `/checkpoint` asks the agent to audit its own context awareness without calling any tools — *describe what you've loaded, estimate where the window is, recommend `/compact` or fresh*.

```
~/dev/learn.claude-code/
├── ...
└── .claude/
    └── commands/
        ├── film-pick.md          (lesson 8)
        ├── film-suggest.md       (lesson 8)
        └── checkpoint.md         ← lesson 12 adds
```

1. Drop in the `checkpoint.md` command (or `cp -r docs/12-context-and-cost/solution/. ~/dev/learn.claude-code/`).
2. Fire `/context` first to see the baseline of your current session. Note the percentage.
3. Fire `/checkpoint`. Read the agent's self-audit and recommendation. Notice it doesn't have invoice-grade numbers — it works from awareness, not introspection.
4. (Optional) Push the session deliberately into discomfort — Read every lesson README in sequence, watch `/context` climb. Then `/compact` and confirm the free space recovers.
5. Try `/checkpoint` again after the compact. The recommendation should now be *Continue*. Notice the agent has a coherent summary of the prior work but lost the verbatim file contents.
6. Commit and push:

```bash
git add .claude/commands/checkpoint.md
git commit -m "lesson 12: checkpoint command for context discipline"
git push
```

## My Verdict on Context Management

The two commands themselves are tiny — three keystrokes for `/context`, eight for `/compact`. The earned-the-hard-way value is the *posture* they enable: a habit of checking, a habit of compacting at the right moments, a habit of starting fresh when the task warrants it. That posture is what separates a session that bills £2 and finishes the task from a session that bills £8 and produces something worse.

The discipline that flows from it — keep CLAUDE.md lean, prefer skills over CLAUDE.md sections for sometimes-needed context, lean on subagents for grep-heavy work, be minimal with MCP servers — turns the agent from "convenient" into "sustainable". Without these habits, every session quietly degrades and every month's bill grows for the same amount of work.

What I'd do differently next time: I'd build the `/checkpoint` discipline command on day one, not after I'd already cluttered up CLAUDE.md and hit a wall. The habit is cheaper to learn deliberately than by force.

On to lesson 13, fellow hungovercoder — let's plug the external tap into the cinema and see the MCP token cost we just learned to watch.
