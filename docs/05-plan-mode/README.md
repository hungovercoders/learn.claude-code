---
title: "Plan Mode"
series: claude-code
order: 5
description: "The read-only thinking gear that turns Claude from a code-vibing tool into one that actually plans before it pours"
canonical_url: https://hungovercoders.com/training/claude-code/05-plan-mode
---

I wanted Claude to stop diving in. I'd ask for a refactor and within four seconds it would be three files deep into edits, with a plan I never agreed to. Sometimes that's fine — small tasks reward speed. For anything that spanned more than one file, though, I wanted it to *think first, edit second*. That's exactly what plan mode is for, and it's the mode I now reach for whenever the request would make a senior dev say "give me a minute" before opening the editor.

## Pre-Requisites

- Claude Code installed (lesson 2)
- A repo with at least one task you'd describe as "more than fifteen minutes of work"
- The patience to read a plan before approving it

## Brewing the Plan Before You Pour

Plan mode is a session-wide posture. While it's on:

- Claude can `Read`, `Grep`, `Glob`, `Bash` (read-only commands), `WebFetch`, `WebSearch`
- Claude **cannot** `Edit`, `Write`, run `Bash` commands that modify state, or call any tool that changes the world

The end state of a plan-mode session is a written plan — usually saved as a markdown file under `~/.claude/plans/` — that you read, approve, push back on, or scrap. Approval flips the session out of plan mode and the agent executes.

The pitch in one line: **plan mode lets you have the architecture conversation without paying for the implementation rollback.**

## Three Ways to Enter

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

## What a Plan Mode Session Looks Like

Real one I ran this week, on a fictional `brewbook` repo I keep around for testing:

```text
> /plan
> The pop-up bar at Newport wants the tablet to show the carbonation level
  of each beer on the keg list. Plan how to add this.
```

What Claude does next:

1. `Read`s `db/keg-list.sql` to understand the current schema
2. `Grep`s for the existing `beer` model definitions
3. `Read`s the htmx template that renders the keg list
4. `Read`s the migration file naming convention
5. Writes a plan to `~/.claude/plans/add-carbonation-to-keg-list.md`
6. Calls `ExitPlanMode`

The plan it produced was four sections: schema change, migration file, model field, template binding. With file paths and the exact migration filename it intended to create. I read it, asked one clarifying question (use `INT` for carbonation volumes, not a `FLOAT` — fixed range 0–5), and approved. The execution that followed touched exactly the four files in the plan.

That's the value. Not the plan itself — I could have produced that plan in fifteen minutes. The value is that *the agent's execution matched the plan it told me about*, because I read it before approving.

## Editing the Plan, Approving the Plan

When Claude calls `ExitPlanMode`, you get a prompt to approve, edit, or reject:

- **Approve** — the agent exits plan mode and executes
- **Edit** — open the plan file in your editor, change it, save, then approve. The edited file is what the agent executes against.
- **Reject** — back to plan mode. Tell Claude what was wrong; it'll revise.

For non-trivial work, the edit step is where I earn my keep. The agent's plan is usually 80% right; the edits I make are the 20% that's project-specific (the team-isn't-ready-for-that-yet, the we-haven't-shipped-the-prereq, the let's-not-touch-that-file). Plan mode doesn't replace your judgement; it gives your judgement something to react to.

## The Bit the Docs Don't Mention

I'll be honest — plan mode has a few rough edges in 2026 that you'll meet eventually. The biggest one: if you launched with `--dangerously-skip-permissions` and then Shift-Tabbed into plan mode, the `ExitPlanMode` confirmation flow sometimes doesn't transition you back to act mode properly. I've also had sessions where rejecting an `ExitPlanMode` call got interpreted as "do this differently" rather than "stay in plan mode" — the agent occasionally treats the rejection text as new guidance rather than a no.

The workaround: when in doubt, type `/plan` again to explicitly re-enter, and avoid combining plan mode with `--dangerously-skip-permissions` in the same session. Use `--permission-mode plan` from a clean launch instead.

There's an active [GitHub issue](https://github.com/anthropics/claude-code/issues/32934) on this — worth a skim if you start using plan mode heavily.

## When to Reach for Plan Mode (and When Not To)

Plan mode shines for:

- Refactors that touch more than one or two files
- Adding a feature that crosses a layer boundary (schema → model → API → UI)
- Migrations and renames where you want the file list before you start
- Anything where you'd ask a senior dev "show me your plan first"

Skip plan mode for:

- Typo fixes, single-line changes, simple renames
- "Run the tests and tell me what failed" — no plan needed, just execute
- Exploratory work where the goal is to *learn* the codebase rather than change it (default mode is fine for read-only exploration; plan mode is for *planning a change*)

## Have a Go

Pick one repo and try this exact exercise.

1. Launch `claude --permission-mode plan` in a project. Confirm the agent refuses to edit anything when you ask it to.
2. Ask it to plan a real change — something multi-file you'd been putting off. Read the plan it produces top to bottom before approving.
3. Reject the plan once and ask it to consider an edge case (e.g. "what about existing rows in the database?"). Watch how the second plan compares.
4. Approve a plan, then open `~/.claude/plans/` and read the file. It stays around after the session — useful for retrospectives.

## My Verdict on Plan Mode

Plan mode is the feature that turned Claude Code from "useful for small jobs" to "useful for the jobs I'd usually do solo on a Saturday morning". The discipline it imposes — separating *thinking* from *doing* — is exactly the discipline a good developer already brings to non-trivial work, and the agent benefits from being held to the same standard.

The rough edges around `ExitPlanMode` mean I wouldn't yet rely on it for fully unattended automation, but for human-in-the-loop work it's the single biggest quality jump I've found in any AI coding tool. The fact you can edit the plan file directly before approval is the killer feature — you stop having to *describe* what you want and start *handing the agent the corrected document*.

What I'd do differently if I were learning this again: I'd start *every* refactor in plan mode for a fortnight, even the small ones, just to build the habit of reading the plan before approving. Once the habit is there, the cost is tiny and the upside is "I never get surprised by what the agent did".

On to lesson 6, fellow hungovercoder — let's pour our own custom cocktails.
