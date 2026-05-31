---
title: "Putting It Together"
series: claude-code
order: 11
description: "Wire the cinema's install.sh so the whole kit runs from any directory — the capstone that turns ten lessons of files into one portable workflow"
canonical_url: https://hungovercoders.com/training/claude-code/11-putting-it-together
---

Across the previous ten lessons your `~/dev/cinema/` directory has accumulated a `films.json`, a `pick-film.sh`, a `CLAUDE.md`, a project-level `settings.json`, two slash commands, three skills, a schema-checking hook, an MCP server wiring, and a plan-mode artefact. This is the lesson where they stop feeling like ten separate pieces and start composing into one workflow you actually use. We do one last thing — write an `install.sh` that symlinks the cinema's `.claude/` contents into your user-level `~/.claude/` — and then we use the kit end-to-end from a directory that isn't the cinema. That portability is what earns the kit its keep.

## Pre-Requisites

- All previous lessons (you don't need to remember every line, but the *shapes* should be familiar)
- A `~/dev/cinema/` that's grown over the lessons (or `cp -r learn.claude-code/project/. ~/dev/cinema/` for the impatient route — same end state)

## The Whole Round — What We've Got

```
~/dev/cinema/
├── films.json                     (lesson 1)
├── pick-film.sh                   (lesson 1)
├── CLAUDE.md                      (lesson 4)
├── plans/lesson-05-mcp-feature.md (lesson 5)
├── scripts/build-cinema-db.sh     (lesson 10)
├── .mcp.json                      (lesson 10)
└── .claude/
    ├── settings.json              (lessons 3, 8)
    ├── commands/                  (lesson 6)
    │   ├── film-pick.md
    │   └── film-suggest.md
    ├── skills/                    (lessons 7, 9)
    │   ├── add-film/SKILL.md
    │   ├── pair/SKILL.md
    │   └── audit/SKILL.md
    └── hooks/                     (lesson 8)
        └── films-validate.sh
```

Eleven files of behaviour, one JSON catalogue, one shell script. The Cinema Companion isn't a fictional demo any more — it picks films, validates writes, recommends pairings, audits its own data, and queries itself via SQL. The last thing we add is the one that makes it *portable*.

## Step 1 — The Install Script

The cinema's behaviour lives in `~/dev/cinema/.claude/`. By default Claude Code only loads project-level skills, commands, and hooks when you're working *inside* `~/dev/cinema/`. Useful — but I want `/pair` and `/film-suggest` available from anywhere on my machine, so I can ask them about a film while I'm in a totally different repo writing a blog post about it. The fix is symlinks: the cinema is still the source of truth, but the user-level Claude Code directories point at it.

`~/dev/cinema/install.sh`:

```bash
#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/skills ~/.claude/hooks ~/.claude/commands

for c in "$HERE"/.claude/commands/*.md; do
  ln -sf "$c" ~/.claude/commands/$(basename "$c")
done

for s in "$HERE"/.claude/skills/*/; do
  ln -sf "$s" ~/.claude/skills/$(basename "$s")
done

for h in "$HERE"/.claude/hooks/*.sh; do
  ln -sf "$h" ~/.claude/hooks/$(basename "$h")
done

echo "cinema kit installed. Slash commands, skills, and hooks symlinked from $HERE."
echo "The films-validate hook still only fires when settings.json wires it — see lesson 8."
```

```bash
chmod +x ~/dev/cinema/install.sh
~/dev/cinema/install.sh
```

```text
cinema kit installed. Slash commands, skills, and hooks symlinked from /Users/dave/dev/cinema.
The films-validate hook still only fires when settings.json wires it — see lesson 8.
```

The cinema's `.claude/` directory stays in one place; the user-level Claude Code dirs point at it. You can move the cinema to a different folder, rerun `install.sh`, and everything keeps working — because the script captures `pwd` and rewrites the symlinks. Move the library, rerun the script, the kit follows.

The deliberate omission: the script does *not* wire `films-validate.sh` as a global hook. The hook is project-specific — it knows the cinema's schema. Globalising it would fire jq schema checks against random JSON files in unrelated repos. The hook stays project-scoped via the cinema's `.claude/settings.json`; the install script only globalises the things that are safe to globalise (commands and skills with no side effects, the hook *script* itself if you want to wire it manually elsewhere).

## Step 2 — Pouring the Round

From any directory:

```bash
cd ~/dev/some-other-project
claude
```

```text
> /film-suggest "Friday night, knackered"
```

The agent reads `films.json` via the symlinked `/film-suggest` command. Wait — `films.json` lives at `~/dev/cinema/`, not in this directory. Two options. Either the command's body specifies an absolute path (rewrite the skill to read `~/dev/cinema/films.json`), or the command stays directory-relative and you only invoke it from inside the cinema. The honest answer for a *catalogue-bound* command is the second: `/film-suggest` and `/film-pick` make sense in the cinema. *They* don't generalise.

The *shape* generalises, though. That's the next step.

## Step 3 — The Whole Kit, Cinema-Sized

Inside the cinema, the full kit becomes one composed workflow. Three real commands, in order, on a Friday night:

```text
> /audit
```

Three subagents fan out. The unified report comes back: one duplicate, one mood that drifted from the conventions. You note them mentally; the data quality is good enough to pour.

```text
> /film-suggest "knackered Tuesday"
```

The agent reads `films.json` and `CLAUDE.md` and recommends *Twin Town*.

```text
> /pair "Twin Town"
```

The agent reads both files again, recommends salt-and-vinegar Tayto crisps, a pint of Cwtch, and a co-watcher who claims to remember the Lewis brothers.

Three commands, five features (CLAUDE.md, two skills, the audit's subagents, the validate hook silently guarding the catalogue), one chosen film, one paired round. The pieces compose.

## The Bit the Docs Don't Mention

I'll be honest, the first time I tried this exact pattern in a writing library I had the skills in the right place but a voice file *not* symlinked — I'd just hardcoded the path to wherever the library happened to live. Everything worked until I moved the library to a different folder, and then nothing worked, and I had no idea why because all the slash commands still appeared in `/help`. **Install scripts that symlink reference content into stable user-level paths are the difference between "this is portable" and "this works on the machine you built it on".** That's not a Claude Code lesson per se, but it's the lesson the official docs don't quite spell out for personal libraries.

The cinema's `install.sh` is deliberately small — three symlink loops, twenty lines, no error handling beyond `set -euo pipefail`. That's the right starting size. The temptation will be to add idempotency checks, log files, dry-run modes; resist that until the workflow demands them.

## Have a Go — Install and Run the Kit

```
~/dev/cinema/
├── ...
└── install.sh                    ← lesson 11 adds
```

1. Drop in `install.sh` (or `cp docs/11-putting-it-together/solution/install.sh ~/dev/cinema/`).
2. `chmod +x ~/dev/cinema/install.sh && ~/dev/cinema/install.sh`.
3. Confirm the symlinks exist: `ls -la ~/.claude/commands/ ~/.claude/skills/ ~/.claude/hooks/`. The cinema's files should be reachable from those user-level paths.
4. Open a session from inside the cinema and run the three-command Friday-night workflow above. Notice that all the pieces wire together — the audit, the suggestion, the pairing — without you having to retype any context.
5. Move the cinema directory somewhere else (`mv ~/dev/cinema ~/dev/another/cinema`), rerun `install.sh` from the new location, and confirm everything still works.

## The Verdict on the System as a Whole

Claude Code earns its keep when the pieces stop feeling like separate features and start composing into a workflow you actually use without thinking. The shape that worked for the cinema — *one project repo + a small install script + CLAUDE.md + slash commands + skills + a hook + an MCP server* — is the shape I now reach for whenever I'd otherwise be retyping the same instructions into a chat window. The portability matters; the composability matters; the source-control matters. None of those are technically *required* by Claude Code, but it's the combination that makes the tool worth more than the chat window.

The big takeaway across the eleven lessons: **the agent isn't the product, the system you build around it is**. The model is the same model that powers Claude.ai. What makes Claude Code different is that it sits inside a configurable, scriptable, version-controllable shell where you can encode the way *you* work and have the agent follow it without retyping. That's the thing AI tutorials can't fake — your shape of the system is yours.

## Where the Cinema Shape Goes Next

The cinema shape generalises. The same five pieces — a small data file, a script that operates on it, a `CLAUDE.md` that explains it, skills that wrap it, a hook that polices it — fit a hundred other workflows. Three real ones I've used the shape for:

- **A writing library.** Replace `films.json` with `voice/style-guide.md`, the slash commands with `/draft` and `/polish`, the schema hook with a word-count log. The hungovercoders content library at `~/dev/hungovercoders/library/` is built on exactly this shape — same install script, same skills + hook + voice file pattern. The cinema was the warm-up.
- **A release-notes library.** `changelogs/<version>.md` as the catalogue, `format-release-notes.sh` as the picker, a `/release-notes` skill that bundles the most recent tag, a hook that refuses pushes without an unreleased entry.
- **A code-review library.** A `voice/review-style.md` as the rules, a `/review` skill that walks a diff against them, a hook that logs review outcomes per repo.

Each of those is the cinema's shape, repotted into a different domain. The directories are different; the *pattern* is the same. You build one of these and the second one takes a tenth of the time, because the install script and the settings.json wiring carry over.

What I'd do differently if I were starting eleven lessons ago: I'd build the cinema *first*, before adopting Claude Code for any real work. The series exists because I learned the lessons in the wrong order; you don't have to. Three files (`films.json`, `pick-film.sh`, `CLAUDE.md`) and one weekend afternoon would have saved me the first month of inconsistent results. The setup feels like overhead until you've got it; after that, every session starts from a known-good base, and the agent feels like a tool you sharpened rather than a chatbot you negotiated with.

Well done on the series, fellow hungovercoder. Cheers — and watch this space for more.
