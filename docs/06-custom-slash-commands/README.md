---
title: "Custom Slash Commands"
series: claude-code
order: 6
description: "Write your own slash commands — the markdown-file prompt templates that turn repeatable workflows into one-line invocations"
canonical_url: https://hungovercoders.com/training/claude-code/06-custom-slash-commands
---

I wanted to stop typing the same fifteen-sentence prompt every time I asked Claude to scaffold a new tutorial repo. Three sentences setting up context, eight describing the structure, four about the voice. By the end of the week I'd typed it six times and watched the agent do six slightly different things in response — because *I* was the inconsistent bit. The fix is a custom slash command: write the prompt once as a markdown file, fire it with `/your-name` from anywhere. This lesson is how.

## Pre-Requisites

- Claude Code installed and authenticated (lesson 2)
- A workflow you actually repeat enough to justify a command (if it's not a real one, this lesson won't stick)
- A text editor

## What a Slash Command Actually Is

A slash command is a markdown file with YAML frontmatter. That's the whole thing. When you type `/your-command` inside Claude Code, the agent reads the file, applies any arguments you passed, and runs whatever the body of the file tells it to do.

Two locations:

```
.claude/commands/<name>.md            Project-specific. Committed to the repo.
~/.claude/commands/<name>.md          Personal. Available in every project.
```

Project commands live with the repo, get shared with the team, and version themselves alongside your code. Personal commands are your own — your `/standup`, your `/lint`, your `/fix-tests`. The hungovercoders setup uses personal commands installed via symlinks so they're sourced from a repo (`library/`) but available everywhere. Lesson 7 covers the skills directory, which is the newer cousin of this pattern.

## Pouring Your Own Cocktail — The Frontmatter

The frontmatter declares the command's metadata and (importantly) what tools it's allowed to use. The fields that matter:

```yaml
---
description: One-line summary shown in /help
allowed-tools: Read, Write, Edit, Bash, WebSearch
argument-hint: <slug> "<Title>"
model: claude-sonnet-4-6
disable-model-invocation: false
---
```

- **`description`** — what the command does. Shown when the user types `/` to filter the list.
- **`allowed-tools`** — the *only* tools the command can use. A `/lint` command listing only `Bash(npm run lint:*)` can't accidentally start editing files; a `/deploy-check` listing `Bash(gh:*)` and `Read` can't push. This is the single most underused field and the most security-relevant one.
- **`argument-hint`** — what to type after the command, shown as autocomplete help.
- **`model`** — pin a specific model for this command. Useful if a command works best on Opus and you want to override the session default.
- **`disable-model-invocation`** — set to `true` to stop the agent from auto-invoking this command on its own. By default, custom commands can be auto-selected when the task fits.

## Crafting a Real One — `/beer-pick`

Let's build something themed. A command that picks a beer from a list based on a mood you pass in. It's daft, but the shape is exactly what a real one looks like.

Create `~/.claude/commands/beer-pick.md`:

```markdown
---
description: Recommend a beer from the Tiny Rebel range based on a mood
allowed-tools: WebFetch
argument-hint: <mood — e.g. "celebratory", "hungover", "Tuesday">
---

The user is asking for a beer recommendation. Their mood is: $ARGUMENTS

Pick one beer from this list and explain why it fits the mood in two sentences:

- Cwtch — Welsh red ale, comforting, warming, a hug in a glass
- Tiny IPA — light, sessionable, low-ABV, easy on a school night
- Mango Punk — bright, fruity, IPA, good for a sunny afternoon
- Clwb Tropica — tropical pale ale, summer vibes, ridiculous in winter
- Dirty Stout — chocolate stout, big-bodied, evening drink only

End your response with: "Cheers, fellow hungovercoder."
```

Save it. Open any Claude Code session. Type:

```text
> /beer-pick Tuesday
```

The agent responds with a recommendation following the rules in your file. The `$ARGUMENTS` placeholder gets replaced with whatever you typed after the command name.

You can use positional arguments too — `$1`, `$2` — if you need to handle multiple values. Multi-word arguments need quoting: `/beer-pick "Sunday afternoon"` makes `$ARGUMENTS` expand to `Sunday afternoon`.

You'll find this example file alongside this lesson at `example-beer-pick.md` — copy it to `~/.claude/commands/beer-pick.md` (or rename it on the way) and try it.

## A More Useful One — `/lint`

The daft one teaches the mechanism. Here's a real one I use on every project. Drop this in `.claude/commands/lint.md` at the repo root:

```markdown
---
description: Run the project linter and ask Claude to fix anything actionable
allowed-tools: Bash(npm run lint:*), Bash(npm run format:*), Read, Edit
---

Run `npm run lint` and report what it finds.

If there are auto-fixable issues, run `npm run format`. For anything that
needs a human decision, list the file and line with a one-line explanation
of what's wrong. Don't fix issues that change behaviour — only style.
```

That `allowed-tools` line is the safety belt. The command can run lint, run format, read files, and edit. It can't `git commit`, it can't `rm`, it can't push. The blast radius is exactly what the command needs and nothing more.

## The Bit the Docs Don't Mention

First time I wrote a slash command I assumed `$ARGUMENTS` worked like shell expansion. It doesn't quite. `$ARGUMENTS` is a literal string substitution — everything after the command name goes in as one blob. Quotes are *preserved* in the substitution, not consumed by it. If you type `/beer-pick "Sunday afternoon"`, the body sees `"Sunday afternoon"` *with* the quotes. For most cases this doesn't matter; for the cases where you're trying to do something clever with arguments, it'll trip you up.

The second quiet thing: command files are *also* read into context when the agent is browsing for help. If you write a huge prose document inside a command file, it inflates the agent's context on every session that lists the commands. Keep them tight. The hc- skills in the hungovercoders library are all under 100 lines for this reason.

## Have a Go

Build something real. Don't skip this lesson by reading-only.

1. Create `~/.claude/commands/beer-pick.md` from the example above. Confirm `/beer-pick Tuesday` works.
2. Look at three of your own repeated workflows. Pick the most annoying one. Write a slash command for it — short, with a tight `allowed-tools` list.
3. Add `argument-hint` to a command that takes input and confirm the autocomplete shows it when you type `/your-command<space>`.
4. Use `/permissions` to confirm your `allowed-tools` is doing what you think it's doing. Try to make the command do something it shouldn't — confirm it can't.

## My Verdict on Custom Slash Commands

Custom slash commands are the second-highest-leverage feature in Claude Code, after `CLAUDE.md`. They let you turn *prompts you'd otherwise retype* into reusable, version-controlled, share-with-the-team primitives. The `allowed-tools` field is what makes them safe to use in real codebases — without it, every command would carry the blast radius of a free-form session.

The thing that surprised me: once I had three custom commands I used regularly, my muscle memory shifted. I stopped reaching for prose and started reaching for `/` first. That's a bigger productivity jump than any single command's content. The interface change is the real product.

What I'd do differently next time: I'd write the *first* command as a personal one in `~/.claude/commands/` before I tried writing a project command. Project commands tempt you to over-engineer because they're for the team; personal ones force you to keep it shabby and useful, which is the right starting energy.

On to lesson 7, fellow hungovercoder — let's meet skills, the newer cousin who shares a flat with slash commands.
