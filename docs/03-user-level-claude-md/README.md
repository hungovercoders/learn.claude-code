---
title: "User-Level CLAUDE.md and Personal Patterns"
series: claude-code
order: 3
description: "Write the personal defaults the agent reads at the start of every session — terse responses, conventional commits, no emoji, the things you never want to retype into a chat window again"
canonical_url: https://hungovercoders.com/training/claude-code/03-user-level-claude-md
---

I was repeating myself across sessions with the same development-discipline reminders — *don't work in main, ensure branches, commit and raise a draft PR* — over and over, in every project. That's the kind of repetition `~/.claude/CLAUDE.md` is for: a personal defaults file that loads into every session on this machine, in every project, before the agent does anything else. Whatever you're tired of retyping — workflow rules, response posture, code-style preferences, no emoji — this is where you stop having to. Before we touch the cinema in earnest, set the defaults you want the agent to bring with it.

## Pre-Requisites

- Claude Code installed and authenticated (lesson 2)
- About fifteen minutes to write the file properly the first time
- A view on how you actually want the agent to behave — terse vs verbose, what to never do, what conventions to assume

## Two Layers, Different Jobs

`CLAUDE.md` is the recipe card the agent reads at the start of every session. It lives in two places, doing two different jobs.

```
~/.claude/CLAUDE.md           Personal defaults — every project, every session.
<repo>/CLAUDE.md              Project context — every session in this repo.
```

This lesson is the user-level file. Lesson 6 is the project-level one — the cinema gets its own. Both load on the same session; the user-level file is read first, the project-level layered on top. Personal posture, then project specifics. That ordering matters — the project file can override the user file for project-specific exceptions, but most of the time they compose.

Why this lesson is first: every session you run from lesson 4 onwards starts with these personal defaults loaded. The cinema build doesn't happen in a vacuum — it happens under the posture you set here. Get this right once and every project on this machine benefits.

## What Goes In, What Stays Out

The user-level file is for *how you want the agent to behave with you*. Not what the project is, not what files to read — those are project concerns. Here:

- **Role and posture** — what you do, how you want the agent to address you
- **How you work** — terse vs verbose, plan before code vs go fast, recommend vs list options
- **Code style defaults** — comments, error handling, abstractions you don't want
- **Tracking conventions** — commit message format, where tickets live
- **Things to never do at user level** — modify configs in installed locations vs source, edit secrets, push without asking

What stays out:

- Project architecture, file paths, conventions for *one repo* — those belong in the project's own `CLAUDE.md` (lesson 6)
- Anything you'd be embarrassed to share if someone glanced at your screen — the file is private to your machine but the *outputs* are visible

## A Worked Template — The Hungovercoder Default

Drop this in `~/.claude/CLAUDE.md`, then prune to fit you. Under 50 lines on purpose — the agent reads every word, padding crowds out the signal.

```markdown
# About me

I'm a working developer using Claude Code daily. Full-stack, some
data engineering, DevOps when the deploy script breaks. I read code
faster than I read prose explaining code.

# How I work

- I prefer concise, direct responses. No preamble, no trailing
  recap, no "Great question!". Match response length to the task.
- When writing code: no unnecessary comments, no over-engineering,
  no placeholder TODOs. If you'd want a comment to explain *why*,
  keep it. If it'd only restate *what*, delete it.
- When I ask what to do, give me a recommendation and the key
  tradeoff — not a numbered list of every option.
- Prefer editing existing files over creating new ones.
- Plan before acting. For anything more than a one-line change,
  describe what you'll do before you do it.
- Flag security issues immediately and stop until I respond.

# Conventions

- Commit messages: conventional commits format (feat:, fix:, chore:).
  Body lines under 72 chars. No emoji in commit messages.
- No emoji anywhere unless I ask for them.
- Tracking tool is defined per-project — ask if it isn't obvious
  from a `CONTRIBUTING.md` or `.github/`.

# Configuration management

- Config file changes go in `~/dotfiles` and source-controlled —
  never edit `~/.zshrc`, `~/.claude/settings.json`, etc. directly
  in their installed location. Edit in dotfiles, then symlink or
  install.
- Never put secrets, credentials, API keys, or PII into anything
  source-controlled. Environment variables and 1Password CLI for
  credentials.

# Things to never do

- Push to `main` directly. Always a branch + PR.
- Force-push to a shared branch without explicit say-so.
- Run `--no-verify` on a commit. If a hook fails, fix the cause.
- Disable a failing test to make CI green. Investigate why.
```

Notice what's *not* in there. There's no project list, no file paths, no architecture, no test commands. Those are project-level concerns. This file is the posture the agent takes with *you* in any project.

## How to Test It Actually Loaded

Ask Claude something simple in any project. Watch the response shape — terse, no preamble, recommendation-not-list, no emoji. If the response still opens with "Great question!" the file probably isn't being read. Check:

```bash
ls -la ~/.claude/CLAUDE.md
claude /memory          # show the loaded CLAUDE.md files in the current session
```

The `/memory` slash command (or `/help` to find the variant on your Claude Code version) lists every CLAUDE.md in scope. If `~/.claude/CLAUDE.md` is absent from the list, the file isn't where Claude Code expects it. Make sure the path is exactly `~/.claude/CLAUDE.md` — not `~/.claude/CLAUDE.MD`, not `~/.claudemd`.

## The Bit the Docs Don't Mention

Two things worth knowing — both about *what* belongs in this file, not how to write it.

**File size discipline matters more than the docs let on.** A 200-line user CLAUDE.md feels reassuring — you've written down every preference you can think of — but the agent compresses long files into a summary in its working context. The first thirty lines get the most attention. **Lead with the rules you'd want followed if only the first thirty lines made it through.** Posture and "never do" first; nice-to-haves later. (Optimising the size of your CLAUDE.md is an ongoing discipline — mine is still a work in progress, and that's normal.)

**This file is *user-level* and global** — it composes with *every* project's CLAUDE.md. That means a rule here applies to projects you didn't write the user file for. "No emoji" is universal; "use kebab-case for filenames" is not. If a preference is universal across your work, it belongs here. If it's tied to a specific language, framework, or team, it belongs in the project-level CLAUDE.md (lesson 6).

## How This Loads Alongside the Project File

When you start a session in the cinema (or any repo with a project-level `CLAUDE.md`), Claude Code reads both:

1. `~/.claude/CLAUDE.md` — first. Your personal posture.
2. `<repo>/CLAUDE.md` — second, layered on top. Project specifics.

If the project file says *"use tabs not spaces in this repo"*, that wins for this repo even though your user file might prefer spaces. The project context overrides at the leaf. The user file sets the default for everything the project file doesn't explicitly cover.

The cinema's project file (lesson 6) describes `films.json`'s schema and `pick-film.sh`'s contract. Your user file sets the posture the agent takes when reading them. They compose. By lesson 14 you've got both files working in concert.

## Source-Control the File — `datagriff/dotfiles` Style

A practice worth lifting out of the "Have a Go" list because it pays off the moment your machine changes: **source-control your user CLAUDE.md.** Mine lives in a `datagriff/dotfiles` repo at `~/dotfiles/.claude/CLAUDE.md` with a symlink to `~/.claude/CLAUDE.md`. New laptop, fresh install, one clone + one symlink, the agent's defaults follow me.

```bash
# In your dotfiles repo (create one if you don't have one — five-minute job)
mkdir -p ~/dotfiles/.claude
mv ~/.claude/CLAUDE.md ~/dotfiles/.claude/CLAUDE.md
ln -s ~/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md
git add .claude/CLAUDE.md
git commit -m "feat: track user CLAUDE.md"
```

The same advice applies to anything else in `~/.claude/` that has behaviour (the user-level `settings.json` you write in lesson 5; user-level hook scripts; user-level skills) — they all benefit from living in dotfiles and getting symlinked in. **If it has behaviour, source-control it.** That's a hungovercoders rule that long predates AI agents and still works.

## Have a Go — Plant the Personal Posture

```
~/.claude/
└── CLAUDE.md          ← lesson 3 adds this
```

There's no `solution/` directory in this lesson — the deliverable lives outside the cinema repo. The lesson is the template.

1. Create `~/.claude/CLAUDE.md` with the template above. Edit it to fit you — prune what doesn't apply, add what does. Keep it under 50 lines.
2. Open Claude Code in any project (the cinema, or another repo you've got handy). Type `/memory` (or `/help` to find the equivalent on your version) and confirm `~/.claude/CLAUDE.md` is listed.
3. Ask a one-line code question — *"how do I get the current epoch in bash?"* — and watch the response shape. Terse, no preamble, no emoji. If you're getting trailing recap or unwanted openers, sharpen the relevant lines in the file and try again.
4. Move the file into a dotfiles repo and symlink it back (see the section above). If you don't have a dotfiles repo yet, this is a fine excuse to start one.

The cinema directory doesn't change this lesson. Lesson 4 is where the cinema gets its first piece of remote presence — a feature branch and a draft PR — so that every commit from lesson 5 onwards lands somewhere safe and reviewable.

## My Verdict on User-Level CLAUDE.md

`~/.claude/CLAUDE.md` is the file that most changes how Claude Code feels day-to-day. The agent reads it on every session in every project, so a sharp file improves every interaction — and a sloppy file makes every interaction subtly worse. The discipline is *brevity weighted toward the rules that matter*: posture and the "never do" list in the first thirty lines; the rest is bonus.

What I'd do differently if I were starting again: I'd write the file before I ever opened a real repo with Claude Code, even if it was rough — and I'd source-control it in dotfiles from day one. The default-default posture is fine, but every session you run before the file exists is one where you're either retyping reminders or accepting outputs that drift from what you'd want. The file feels like work-to-add until it's there; after that it just earns its keep silently on every session.

On to lesson 4, fellow hungovercoder — let's get the cinema onto a feature branch with a draft PR before anything else lands.
