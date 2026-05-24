---
title: "Skills"
series: claude-code
order: 7
description: "The skills directory, SKILL.md, and the difference between a slash command and a skill that knows when to show up on its own"
canonical_url: https://hungovercoders.com/training/claude-code/07-skills
---

I wanted to know whether the file should go in `.claude/commands/` or `.claude/skills/`. I'd written four custom prompts and split them across both directories based on what each tutorial happened to recommend. The agent worked, but I had no real model for which thing was which. After reading the docs properly and watching how the two behave in practice, here's the version of this I wish someone had handed me on day one. Skills aren't a new feature competing with slash commands — they're the same idea with a bigger toolkit.

## Pre-Requisites

- Lesson 6 finished (you've written a real slash command)
- A workflow that needs supporting files (a template, a script, a sample config) — not just a prompt
- Comfort with creating directories and `.md` files

## Specialist Brewers — What a Skill Is

A skill is a *directory* containing a `SKILL.md` file and any supporting files the prompt needs. The directory name is the skill name; the `SKILL.md` is the prompt that fires when the skill is invoked.

```
.claude/skills/release-notes/
├── SKILL.md          ← the prompt + frontmatter
├── template.md       ← supporting file the SKILL.md references
└── changelog.sh      ← a script the prompt asks Claude to run
```

The contents of `SKILL.md` look almost identical to a slash command file:

```markdown
---
name: release-notes
description: Generate release notes for the most recent version tag, using the project's template
allowed-tools: Bash(git log:*), Bash(git tag:*), Read, Edit
disable-model-invocation: false
---

Use ./template.md as the structure. Get the most recent two tags with
`git tag --sort=-v:refname | head -2`, then `git log <prev>..<latest> --oneline`,
group commits by conventional-commit type, and write the output to RELEASE_NOTES.md.
```

Type `/release-notes` and the skill fires. Same interface as a slash command. The difference is that the prompt can reference `./template.md` and `./changelog.sh` — files that live next to it in the same directory.

## Two Locations, Same Story

Skills live in the same two locations as slash commands:

```
.claude/skills/<name>/SKILL.md            Project-specific, committed to the repo
~/.claude/skills/<name>/SKILL.md          Personal, available across projects
```

Project skills get shared with the team. Personal skills are yours. The hungovercoders setup uses both — personal ones for content workflows, project ones for repo-specific automations.

## The Bit That Confused Me — Skills vs Slash Commands

Here's what I had to look up to be sure I understood. Both `.claude/commands/<name>.md` and `.claude/skills/<name>/SKILL.md` produce a working `/name` slash command. The interface is the same. What differs:

| Feature | Slash command | Skill |
|---|---|---|
| Single markdown file | ✓ | (it's a directory with `SKILL.md`) |
| Supporting files alongside | ✗ | ✓ |
| Auto-invocation by Claude | ✓ (limited) | ✓ (richer) |
| `disable-model-invocation` field | ✓ | ✓ |
| Recommended for new work | for simple prompts | for anything more |

The official guidance in 2026 is: **use a skill if the workflow needs supporting files or you want auto-invocation to work cleanly**. Use a plain slash command for tight, prompt-only workflows. There's no migration deadline — both keep working — but new functionality lands on skills first.

## Auto-Invocation — When Claude Loads It Without Being Asked

The headline feature skills add over slash commands is *contextual auto-invocation*. If your `SKILL.md` describes itself well in the `description` field, Claude can pick the skill up automatically when the conversation matches.

Example: a skill described as `"Generate release notes from git history"` will get auto-loaded if you say *"can you write up the release notes for v2"*, without you needing to type `/release-notes`. The model reads the descriptions of available skills the same way it reads the descriptions of tools, and picks one when it fits.

This is brilliant for skills that *help*. It's dangerous for skills that *do things*. You don't want Claude deciding to invoke `/deploy-production` because your code looks finished. The control is `disable-model-invocation: true`:

```yaml
---
name: deploy
description: Deploy the current branch to production via the GitHub Actions deploy workflow
disable-model-invocation: true
---
```

That setting means: only the human can fire this skill. Claude can see it exists, but won't auto-invoke. Use it for anything with side effects, anything irreversible, anything that talks to a system outside your repo. **As a rule of thumb: if the worst-case outcome would make you regret it, set `disable-model-invocation: true`.**

## Building a Real Skill — The Themed Example

A simple skill that recommends a beer flight based on a meal. Drop it in `~/.claude/skills/beer-flight/SKILL.md`:

```markdown
---
name: beer-flight
description: Recommend a three-beer flight from the Tiny Rebel range to pair with a meal
allowed-tools: Read
argument-hint: <meal — e.g. "Sunday roast", "Thai green curry">
disable-model-invocation: false
---

The user is eating: $ARGUMENTS

Read ./beers.md for the current Tiny Rebel range. Pick three beers that
together form a flight matched to the meal. Order them from lightest to
strongest. Explain each pairing in one sentence.

End with: "Cheers, fellow hungovercoder."
```

And alongside it, `~/.claude/skills/beer-flight/beers.md`:

```markdown
- Tiny IPA          3.5%  light, sessionable, citrus
- Cwtch             4.6%  red ale, comforting, malty
- Mango Punk        5.6%  IPA, bright, fruity
- Clwb Tropica      5.5%  tropical pale ale, summer
- Dirty Stout       6.5%  chocolate stout, rich
```

That `./beers.md` file is the bit a slash command couldn't do — supporting files referenced by the prompt. You can update the beer list without touching the prompt; you can write longer reference material in the supporting file without bloating `SKILL.md`.

The runnable version of both files is alongside this lesson at `example-skill/`. Copy the directory to `~/.claude/skills/beer-flight/` and fire it with `/beer-flight "Sunday roast"`.

## The Bit the Docs Don't Mention

I'll be honest, the history of "commands vs skills" tripped me up for a couple of days. The two used to be genuinely distinct — different directories, different capabilities, different invocation models. Then Anthropic unified them: both produce a `/slash-command` interface, both can be auto-invoked, both support the same frontmatter fields. The naming inconsistency in the docs hasn't fully caught up, so you'll see articles from 2025 treating them as separate things. **In 2026, treat them as the same thing with different file shapes.** A skill is just "a slash command that lives in a directory with friends".

## Have a Go

Build a skill, not a command.

1. Pick a workflow you'd written as a slash command. Promote it to a skill: create `.claude/skills/<name>/SKILL.md` and move any reference material into a supporting file alongside.
2. Add `disable-model-invocation: true` to one of your existing skills that has side effects. Confirm it can only fire when you type `/<name>`.
3. Write the `description` field for that skill carefully. Then leave a session running and notice whether Claude reaches for it in conversations where the topic matches.
4. Make a skill with a deliberately bad `description` ("does stuff") and notice the difference. Description quality is the auto-invocation knob.

## My Verdict on Skills

Skills are the right shape for anything more than a one-shot prompt. The ability to keep supporting files next to the prompt — templates, sample data, reference lists, scripts — is genuinely useful, and the auto-invocation behaviour makes the agent feel proactive in a way slash commands never quite did.

The risk is the same as with any "AI picks the action" feature: you have to be deliberate about which skills you let Claude reach for itself. `disable-model-invocation: true` is the load-bearing setting that separates "I want this skill ready when asked" from "I want Claude to use this when it judges fit". Get into the habit of setting it on anything irreversible from day one.

What I'd do differently next time: I'd skip writing any plain slash commands altogether and go straight to skills, even for one-file prompts. The directory overhead is trivial; the upgrade path when you eventually need a supporting file is free. Future-me would thank past-me for not having two parallel directories of half-the-same-thing.

On to lesson 8, fellow hungovercoder — let's put a bouncer on the door.
