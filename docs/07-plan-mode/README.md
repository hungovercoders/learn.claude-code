---
title: "Plan Mode"
series: claude-code
order: 7
description: "The read-only thinking gear that turns Claude from code-vibing tool into one that plans before it pours — used to design the cinema's lesson-12 MCP feature"
canonical_url: https://hungovercoders.com/training/claude-code/07-plan-mode
---

Plan mode has been smooth for me from the offset, and it's the mode I reach for first on anything bigger than a one-line change. Not because the agent is bad at diving in (sometimes diving in is the right move), but because plan mode turns the session into a *conversation* — Claude reads the relevant files, drafts an approach, hands it back to me, and I get to push on it before any edits land. It's the single feature that helps me have a real conversation with Claude rather than just issuing instructions. In this lesson we use it for a real job — designing the MCP feature we'll wire in lesson 12 — and ship the plan file alongside the cinema as a permanent artefact.

## Pre-Requisites

- The cinema with `CLAUDE.md` (lesson 6) — plan mode reads it like every other session does
- The cinema on a feature branch with a draft PR open (lesson 4)
- A spare twenty minutes to read a plan properly before approving

## Brewing the Plan Before You Pour

Plan mode is a session-wide posture. While it's on:

- Claude can `Read`, `Grep`, `Glob`, `Bash` (read-only commands), `WebFetch`, `WebSearch`
- Claude **cannot** `Edit`, `Write`, run `Bash` commands that modify state, or call any tool that changes the world

The end state of a plan-mode session is a written plan — usually saved as a markdown file under `~/.claude/plans/` (user-level) or `plans/` inside your project — that you read, approve, push back on, or scrap. Approval flips the session out of plan mode and the agent executes.

The pitch in one line: **plan mode lets you have the architecture conversation without paying for the implementation rollback.**

## Three Doors Into the Snug

Pick whichever fits your flow:

```bash
claude --permission-mode plan
```

Launches Claude Code already in plan mode. Good for "I know this task needs planning" kicks.

```text
> /plan
```

Switch mid-session by typing the `/plan` slash command. Good when you started in default mode, realised this is bigger than you thought, and want to back out of edit territory.

**Shift-Tab twice** — cycles the permission mode through default → acceptEdits → plan → default. Quickest in muscle memory once you've got the cycle down.

You'll see the prompt change to indicate plan mode is active. Any tool call that would modify state gets refused with a system reminder.

## The Plan for Lesson 12 — A Real Session

Lesson 12 wires an MCP server into the cinema. The job is non-trivial — choose a server, decide whether the data source stays JSON or moves to SQLite, design the build step, decide whether `films.json` stays the source of truth or becomes a derived view. That's exactly the shape plan mode is for: more than one file, more than fifteen minutes, *I'd want to read a plan before I touched anything*.

```bash
cd ~/dev/learn.claude-code
claude --permission-mode plan
```

```text
> Plan how to add an MCP server to the cinema that lets the agent query
  films through SQL rather than only through pick-film.sh. I want to
  keep films.json as the editable source. Output a plan file at
  plans/mcp-feature.md.
```

What Claude does next:

1. `Read`s `CLAUDE.md` to anchor on the conventions
2. `Read`s `films.json` for the schema
3. `Read`s `pick-film.sh` to understand the existing query surface
4. `WebFetch` on the [MCP server registry](https://modelcontextprotocol.io/servers) to pick a SQLite server
5. Writes a plan to `plans/mcp-feature.md`
6. Calls `ExitPlanMode`

The plan it ought to produce — and the one we use in lesson 12 — is the one shipped in `solution/plans/mcp-feature.md`. Five short sections: **context** (why move to SQLite), **approach** (wire mcp-server-sqlite, build cinema.db from films.json, keep JSON as source of truth, ship a derived view), **out of scope** (no watch-log write path, no auth), **verification** (build script produces N rows, claude lists the table). That's the value — not the plan itself, but the fact that *the lesson-12 execution will match the plan we agreed to here*, because we read it before approving.

## Editing the Plan, Approving the Plan

When Claude calls `ExitPlanMode`, you get a prompt to approve, edit, or reject:

- **Approve** — the agent exits plan mode and executes
- **Edit** — open the plan file in your editor, change it, save, then approve. The edited file is what the agent executes against.
- **Reject** — back to plan mode. Tell Claude what was wrong; it'll revise.

For non-trivial work, the edit step is where I earn my keep. The agent's plan is usually 80% right; the edits I make are the 20% that's project-specific (the team-isn't-ready-for-that-yet, the we-haven't-shipped-the-prereq, the let's-not-touch-that-file). Plan mode doesn't replace your judgement; it gives your judgement something to react to.

In this lesson the plan stays *unexecuted* — we approve the file as a plan, not as a change. Lesson 12 reads it back when we're ready to wire MCP for real. That's a useful pattern: a plan file as a deliberate handoff to a future session.

## The Bit the Docs Don't Mention

Plan mode is the feature I most want to flag as the **dialogue tool**, not just the thinking gear the docs frame it as. Most write-ups treat it as a safety mechanism — read-only so the agent can't break anything while it thinks. That's true and useful, but it undersells the other half: plan mode is where you have the *architecture conversation* with the agent, and that conversation is the whole game on non-trivial work. The plan is a draft you can argue with, sharpen, and hand back. Default-mode work is "agent does, you check." Plan mode is "agent proposes, you agree." Different relationship.

Practical consequence: don't reach for plan mode only on the jobs you're nervous about. Reach for it on the jobs where the *shape* matters — schema choices, file layouts, what to put in scope, what to keep out. Those are the conversations worth having with claude before any code lands.

## When to Brew a Plan, When to Pour Straight

Plan mode shines for:

- Refactors that touch more than one or two files (the lesson-12 MCP wiring is exactly this shape)
- Adding a feature that crosses a layer boundary (schema → model → API → UI)
- Migrations and renames where you want the file list before you start
- Anything where you'd ask a senior dev "show me your plan first"

Skip plan mode for:

- Typo fixes, single-line changes, simple renames
- "Run the tests and tell me what failed" — no plan needed, just execute
- Exploratory work where the goal is to *learn* the codebase rather than change it (default mode is fine for read-only exploration; plan mode is for *planning a change*)

## Have a Go — Ship the Lesson-12 Plan

```
~/dev/learn.claude-code/
├── films.json
├── pick-film.sh
├── CLAUDE.md
├── plans/
│   └── mcp-feature.md             ← lesson 7 adds this
└── .claude/
    └── settings.json
```

1. Launch `claude --permission-mode plan` in the cinema. Confirm the agent refuses to edit anything when you ask it to (try a small edit deliberately).
2. Ask it to plan the lesson-12 MCP feature with the prompt above. Read the plan top to bottom. Reject and ask for a sharper out-of-scope section if it's too ambitious. Iterate.
3. Approve a version you'd be happy to hand to a future-you. Save it as `plans/mcp-feature.md` inside the cinema. (Or `cp docs/07-plan-mode/solution/plans/mcp-feature.md ~/dev/learn.claude-code/plans/` if you'd rather use mine.)
4. Open the file and read it cold a day later. If it still makes sense without the session context, the plan is doing its job.
5. Commit and push:

```bash
git add plans/mcp-feature.md
git commit -m "lesson 7: plan-mode artefact for the MCP feature"
git push
```

This is the cinema's first deliberate *time-shifted handoff* — a file written today that another session reads next week. The plan-mode artefact is small, but it's the thing that makes lesson 12's wiring feel like execution rather than improvisation.

## My Verdict on Plan Mode

Plan mode is the feature I've used most consistently from the offset. The discipline it imposes — separating *thinking* from *doing* — is exactly the discipline a good developer already brings to non-trivial work, and the agent benefits from being held to the same standard. Smooth in practice, no rough edges I've hit. The fact you can edit the plan file directly before approval is the killer feature — you stop having to *describe* what you want and start *handing the agent the corrected document*.

What I'd do differently if I were learning this again: nothing here, actually — I reached for plan mode from the start and it's stayed in my muscle memory. If anything I'd encourage a *fellow hungovercoder* coming in fresh to lean on it even on small tasks the first week, just to get the habit of reading the plan before approving. Once that's in, the cost is tiny and the upside is "I never get surprised by what the agent did."

On to lesson 8, fellow hungovercoder — let's pour our own custom cocktails.
