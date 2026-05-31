---
title: "Plan Mode"
series: claude-code
order: 5
description: "The read-only thinking gear that turns Claude from code-vibing tool into one that plans before it pours — used to design the cinema's lesson-10 MCP feature"
canonical_url: https://hungovercoders.com/training/claude-code/05-plan-mode
---

I wanted Claude to stop diving in. I'd ask for a refactor and within four seconds it would be three files deep into edits, with a plan I never agreed to. Sometimes that's fine — small tasks reward speed. For anything that spanned more than one file, though, I wanted it to *think first, edit second*. That's exactly what plan mode is for, and it's the mode I now reach for whenever the request would make a senior dev say "give me a minute" before opening the editor. In this lesson we use plan mode for a real job — design the MCP feature we'll wire in lesson 10 — and ship the plan file alongside the cinema as a permanent artefact.

## Pre-Requisites

- The cinema with `CLAUDE.md` (lesson 4) — plan mode reads it like every other session does
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

## The Plan for Lesson 10 — A Real Session

Lesson 10 wires an MCP server into the cinema. The job is non-trivial — choose a server, decide whether the data source stays JSON or moves to SQLite, design the build step, decide whether `films.json` stays the source of truth or becomes a derived view. That's exactly the shape plan mode is for: more than one file, more than fifteen minutes, *I'd want to read a plan before I touched anything*.

```bash
cd ~/dev/cinema
claude --permission-mode plan
```

```text
> Plan how to add an MCP server to the cinema that lets the agent query
  films through SQL rather than only through pick-film.sh. I want to
  keep films.json as the editable source. Output a plan file at
  plans/lesson-05-mcp-feature.md.
```

What Claude does next:

1. `Read`s `CLAUDE.md` to anchor on the conventions
2. `Read`s `films.json` for the schema
3. `Read`s `pick-film.sh` to understand the existing query surface
4. `WebFetch` on the [MCP server registry](https://modelcontextprotocol.io/servers) to pick a SQLite server
5. Writes a plan to `plans/lesson-05-mcp-feature.md`
6. Calls `ExitPlanMode`

The plan it ought to produce — and the one we use in lesson 10 — is the one shipped in `solution/plans/lesson-05-mcp-feature.md`. Five short sections: **context** (why move to SQLite), **approach** (wire mcp-server-sqlite, build cinema.db from films.json, keep JSON as source of truth, ship a derived view), **out of scope** (no watch-log write path, no auth), **verification** (build script produces N rows, claude lists the table). That's the value — not the plan itself, but the fact that *the lesson-10 execution will match the plan we agreed to here*, because we read it before approving.

## Editing the Plan, Approving the Plan

When Claude calls `ExitPlanMode`, you get a prompt to approve, edit, or reject:

- **Approve** — the agent exits plan mode and executes
- **Edit** — open the plan file in your editor, change it, save, then approve. The edited file is what the agent executes against.
- **Reject** — back to plan mode. Tell Claude what was wrong; it'll revise.

For non-trivial work, the edit step is where I earn my keep. The agent's plan is usually 80% right; the edits I make are the 20% that's project-specific (the team-isn't-ready-for-that-yet, the we-haven't-shipped-the-prereq, the let's-not-touch-that-file). Plan mode doesn't replace your judgement; it gives your judgement something to react to.

In this lesson the plan stays *unexecuted* — we approve the file as a plan, not as a change. Lesson 10 reads it back when we're ready to wire MCP for real. That's a useful pattern: a plan file as a deliberate handoff to a future session.

## The Bit the Docs Don't Mention

I'll be honest — plan mode has a few rough edges in 2026 that you'll meet eventually. The biggest one: if you launched with `--dangerously-skip-permissions` and then Shift-Tabbed into plan mode, the `ExitPlanMode` confirmation flow sometimes doesn't transition you back to act mode properly. I've also had sessions where rejecting an `ExitPlanMode` call got interpreted as "do this differently" rather than "stay in plan mode" — the agent occasionally treats the rejection text as new guidance rather than a no.

The workaround: when in doubt, type `/plan` again to explicitly re-enter, and avoid combining plan mode with `--dangerously-skip-permissions` in the same session. Use `--permission-mode plan` from a clean launch instead. There's an active [GitHub issue](https://github.com/anthropics/claude-code/issues/32934) on this — worth a skim if you start using plan mode heavily.

## When to Brew a Plan, When to Pour Straight

Plan mode shines for:

- Refactors that touch more than one or two files (the lesson-10 MCP wiring is exactly this shape)
- Adding a feature that crosses a layer boundary (schema → model → API → UI)
- Migrations and renames where you want the file list before you start
- Anything where you'd ask a senior dev "show me your plan first"

Skip plan mode for:

- Typo fixes, single-line changes, simple renames
- "Run the tests and tell me what failed" — no plan needed, just execute
- Exploratory work where the goal is to *learn* the codebase rather than change it (default mode is fine for read-only exploration; plan mode is for *planning a change*)

## Have a Go — Ship the Lesson-10 Plan

```
~/dev/cinema/
├── films.json
├── pick-film.sh
├── CLAUDE.md
├── plans/
│   └── lesson-05-mcp-feature.md   ← lesson 5 adds this
└── .claude/
    └── settings.json
```

1. Launch `claude --permission-mode plan` in the cinema. Confirm the agent refuses to edit anything when you ask it to (try a small edit deliberately).
2. Ask it to plan the lesson-10 MCP feature with the prompt above. Read the plan top to bottom. Reject and ask for a sharper out-of-scope section if it's too ambitious. Iterate.
3. Approve a version you'd be happy to hand to a future-you. Save it as `plans/lesson-05-mcp-feature.md` inside the cinema. (Or `cp docs/05-plan-mode/solution/plans/lesson-05-mcp-feature.md ~/dev/cinema/plans/` if you'd rather use mine.)
4. Open the file and read it cold a day later. If it still makes sense without the session context, the plan is doing its job.

This is the cinema's first deliberate *time-shifted handoff* — a file written today that another session reads next week. The plan-mode artefact is small, but it's the thing that makes lesson 10's wiring feel like execution rather than improvisation.

## My Verdict on Plan Mode

Plan mode is the feature that turned Claude Code from "useful for small jobs" to "useful for the jobs I'd usually do solo on a Saturday morning". The discipline it imposes — separating *thinking* from *doing* — is exactly the discipline a good developer already brings to non-trivial work, and the agent benefits from being held to the same standard.

The rough edges around `ExitPlanMode` mean I wouldn't yet rely on it for fully unattended automation, but for human-in-the-loop work it's the single biggest quality jump I've found in any AI coding tool. The fact you can edit the plan file directly before approval is the killer feature — you stop having to *describe* what you want and start *handing the agent the corrected document*.

What I'd do differently if I were learning this again: I'd start *every* refactor in plan mode for a fortnight, even the small ones, just to build the habit of reading the plan before approving. Once the habit is there, the cost is tiny and the upside is "I never get surprised by what the agent did".

On to lesson 6, fellow hungovercoder — let's pour our own custom cocktails.
