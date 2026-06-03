---
title: "Skills"
series: claude-code
order: 9
description: "Promote the cinema from slash commands to skills — /add-film with the disable-model-invocation safety belt, and /pair that reads films.json + CLAUDE.md as supporting files"
canonical_url: https://hungovercoders.com/training/claude-code/09-skills
---

I wanted to know whether the next file should go in `.claude/commands/` or `.claude/skills/`. The cinema's two slash commands from lesson 8 work, but the next two things I want — a *write* command for `films.json` and a *pairings* recommendation that reads multiple supporting files — both want capabilities a plain slash command doesn't quite stretch to. Skills aren't a new feature competing with slash commands. They're the same idea with a bigger toolkit: supporting files alongside the prompt, and richer safety controls. Lesson 9 adds two of them to the cinema.

## Pre-Requisites

- Lesson 8 finished — `/film-pick` and `/film-suggest` working inside the cinema
- The cinema seed, `CLAUDE.md`, and project-level settings in place

## Specialist Brewers — What a Skill Is

A skill is a *directory* containing a `SKILL.md` file and any supporting files the prompt needs. The directory name is the skill name; the `SKILL.md` is the prompt that fires when the skill is invoked.

```
.claude/skills/release-notes/
├── SKILL.md          ← the prompt + frontmatter
├── template.md       ← supporting file the SKILL.md references
└── changelog.sh      ← a script the prompt asks Claude to run
```

The contents of `SKILL.md` look almost identical to a slash command file. Type `/release-notes` and the skill fires. Same interface as a slash command. The difference is that the prompt can reference `./template.md` and `./changelog.sh` — files that live next to it in the same directory — and the safety controls go further.

## Two Locations, Same Story

Skills live in the same two locations as slash commands:

```
.claude/skills/<name>/SKILL.md            Project-specific, committed to the repo
~/.claude/skills/<name>/SKILL.md          Personal, available across projects
```

Project skills get shared with the team. Personal skills are yours. The cinema's two new skills are project-scoped — they only make sense inside `~/dev/cinema/`. Personal skills would be your `/standup`, `/lint`, `/draft` — the cross-cutting ones that apply anywhere.

## The Bit That Confused Me — Skills vs Slash Commands

Here's what I had to look up to be sure I understood. Both `.claude/commands/<name>.md` and `.claude/skills/<name>/SKILL.md` produce a working `/name` slash command. The interface is the same. What differs:

| Feature | Slash command | Skill |
|---|---|---|
| Single markdown file | ✓ | (it's a directory with `SKILL.md`) |
| Supporting files alongside | ✗ | ✓ |
| Auto-invocation by Claude | ✓ (limited) | ✓ (richer) |
| `disable-model-invocation` field | ✓ | ✓ |
| Recommended for new work | for simple prompts | for anything more |

The official guidance in 2026 is: **use a skill if the workflow needs supporting files or you want auto-invocation to work cleanly**. Use a plain slash command for tight, prompt-only workflows. Both keep working — but new functionality lands on skills first.

The cinema's lesson 8 commands stayed as plain commands because they were one-line wrappers. The two we add here both need more: `/add-film` needs safety controls so the agent doesn't auto-invoke it, and `/pair` needs to read both `films.json` and `CLAUDE.md` as part of its reasoning.

## Auto-Invocation — When Claude Loads It Without Being Asked

The headline feature skills add over slash commands is *contextual auto-invocation*. If your `SKILL.md` describes itself well in the `description` field, Claude can pick the skill up automatically when the conversation matches.

Example: a skill described as `"Generate release notes from git history"` will get auto-loaded if you say *"can you write up the release notes for v2"*, without you needing to type `/release-notes`. The model reads the descriptions of available skills the same way it reads the descriptions of tools, and picks one when it fits.

This is brilliant for skills that *help*. It's dangerous for skills that *do things*. You don't want Claude deciding to invoke `/deploy-production` because your code looks finished. The control is `disable-model-invocation: true`. **As a rule of thumb: if the worst-case outcome would make you regret it, set `disable-model-invocation: true`.** That's exactly why `/add-film` below has it set and `/pair` doesn't.

## The First Skill — `/add-film` With Both Safety Belts

The cinema's `/add-film` skill is a *write* — it appends a new film to `films.json`. Writes are the precise category where you want a deliberate keystroke, not a model decision. Two frontmatter fields do the work: `allowed-tools` limits the toolbox to `Read` and `Edit` only (no Bash, no rm), and `disable-model-invocation: true` means the skill only fires when the human types `/add-film`.

`~/dev/cinema/.claude/skills/add-film/SKILL.md`:

```markdown
---
name: add-film
description: Add a film to films.json in the current directory
allowed-tools: Read, Edit
argument-hint: "<title>" <year> <mood> <runtime>
disable-model-invocation: true
---

The arguments are: $ARGUMENTS

Parse them as: a quoted title (multi-word), then a year (4-digit
integer), then a mood (single lowercase word), then a runtime in
minutes (integer).

Read `./films.json`. Append a new object `{ "title", "year", "mood",
"runtime" }` to the end of the array, preserving the order and
formatting of existing entries. Don't reformat the rest of the
file — only add the new entry on its own line just before the
closing `]`.

If `films.json` does not exist in the current directory, stop and
say so. Don't create it.

The `films-validate.sh` PostToolUse hook will re-check the schema
on the Edit — if you broke the structure, the hook will block the
write and tell you why.
```

Fire it:

```text
> /add-film "Pride" 2014 wales 119
```

The agent reads `films.json`, edits in the new row, and stops. The Edit can't go anywhere outside the file because `allowed-tools` doesn't list Bash, Write, or anything else. The lesson 10 hook will re-check the schema on the Edit — belt and braces.

## The Second Skill — `/pair` With Two Supporting Files

The cinema's `/pair` skill reads both `films.json` and `CLAUDE.md` to recommend a snack, a drink, and a co-watcher archetype for a given film or mood. It's a great example of the difference a skill makes — a plain slash command can reference `$ARGUMENTS` and tell Claude what to do, but a skill can tell Claude to *read these specific files* as part of every invocation. The skill becomes a tiny program with its own data sources.

`~/dev/cinema/.claude/skills/pair/SKILL.md`:

```markdown
---
name: pair
description: Pair a film to a snack, a drink, and a co-watcher archetype
allowed-tools: Read
argument-hint: <title or mood>
---

Read `./films.json` and `./CLAUDE.md`.

The argument is either a film title from the catalogue or a mood
word: $ARGUMENTS

If it's a mood, pick the best-fit film from the catalogue first.
Then recommend:

- **Snack** — one specific snack that fits the runtime and mood.
  Pretzels for short comedies, slow-cooked nachos for anything over
  two hours, toast for a homesick rewatch.
- **Drink** — one Tiny Rebel beer or a non-alcoholic alternative.
  Cwtch for cosy, Mango Punk for fun, a brew for the homesick ones.
- **Co-watcher archetype** — one sentence describing the kind of
  person this film is best watched with. "Someone who quotes Spaced
  unprompted." "A parent who remembers the original."

Keep each line one short paragraph. No bullets. Close with:
"That's the round in. Enjoy, fellow hungovercoder."
```

```text
> /pair "Twin Town"
```

```text
Twin Town is 99 minutes of Cardiff in-jokes — short enough that
you want a snack that holds up through the second half. A bag of
salt-and-vinegar Tayto crisps works hard here.

Drink: Tiny Rebel Cwtch. It's a Welsh red ale and the film is a
Welsh comedy — house preferences in CLAUDE.md tell you exactly
which way the pairing should land.

Watch with someone who claims they once knew the Lewis brothers.
There is always such a person and they will quote the bowls
scene before you do.

That's the round in. Enjoy, fellow hungovercoder.
```

Notice `/pair` doesn't have `disable-model-invocation` set. It's read-only — the worst it can do is recommend the wrong snack. Auto-invocation is fine; if the user says *"what should I pair with Hot Fuzz tonight?"*, Claude can reach for `/pair` without being asked. The skill ladder runs: *read-only and harmless → no safety belt needed*. *Writes or external side effects → disable model invocation*. *Both, with a tight `allowed-tools` list*.

## The Bit the Docs Don't Mention

I'll be honest, the history of "commands vs skills" tripped me up for a couple of days. The two used to be genuinely distinct — different directories, different capabilities, different invocation models. Then Anthropic unified them: both produce a `/slash-command` interface, both can be auto-invoked, both support the same frontmatter fields. The naming inconsistency in the docs hasn't fully caught up, so you'll see articles from 2025 treating them as separate things. **In 2026, treat them as the same thing with different file shapes.** A skill is just "a slash command that lives in a directory with friends".

## Have a Go — Add the Two Skills to the Cinema

```
~/dev/cinema/
├── ...
└── .claude/
    ├── ...
    └── skills/
        ├── add-film/SKILL.md      ← lesson 9 adds
        └── pair/SKILL.md          ← lesson 9 adds
```

1. Create both skills above. Or `cp -r docs/07-skills/solution/. ~/dev/cinema/` to drop them in.
2. Fire `/add-film "Pride" 2014 wales 119` and confirm a new row appears at the end of `films.json`.
3. Try to trigger `/add-film` *without* typing it — phrase a question like *"I just watched a great film called Pride from 2014, add it to the catalogue"* and notice the agent will *not* auto-invoke the skill because of `disable-model-invocation: true`. It'll suggest you run the command yourself.
4. Fire `/pair "Hot Fuzz"` and watch the agent `Read` both `films.json` and `CLAUDE.md` before answering.
5. Make a deliberately bad `description` on a copy of `/pair` and notice the difference in auto-invocation. Description quality is the auto-invocation knob.
6. Commit and push:

```bash
git add .claude/skills/
git commit -m "lesson 9: add-film + pair skills"
git push
```

## My Verdict on Skills

Skills are the right shape for anything more than a one-shot prompt. The ability to keep supporting files next to the prompt — templates, sample data, reference lists, scripts — is genuinely useful, and the auto-invocation behaviour makes the agent feel proactive in a way slash commands never quite did. The two skills the cinema added in this lesson use both features: `/add-film` leans on `allowed-tools` + `disable-model-invocation` to be a tight write-only tool; `/pair` leans on Read to cross-reference two files of supporting context.

The risk is the same as with any "AI picks the action" feature: you have to be deliberate about which skills you let Claude reach for itself. `disable-model-invocation: true` is the load-bearing setting that separates "I want this skill ready when asked" from "I want Claude to use this when it judges fit". Get into the habit of setting it on anything irreversible from day one.

What I'd do differently next time: I'd skip writing any plain slash commands altogether and go straight to skills, even for one-file prompts. The directory overhead is trivial; the upgrade path when you eventually need a supporting file is free. Future-me would thank past-me for not having two parallel directories of half-the-same-thing.

On to lesson 10, fellow hungovercoder — let's put a bouncer on the cinema door.
