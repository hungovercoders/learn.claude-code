---
title: "Custom Slash Commands"
series: claude-code
order: 6
description: "Write the cinema's first two slash commands — /film-pick and /film-suggest — and turn repeatable prompts into one-line invocations"
canonical_url: https://hungovercoders.com/training/claude-code/06-custom-slash-commands
---

I wanted to stop typing the same six-sentence prompt every time I asked Claude to pick a film for the evening. Three sentences setting the rules, two pointing at `films.json`, one closing line. By the end of the week I'd typed it eight times. The fix is a custom slash command: write the prompt once as a markdown file, fire it with `/your-name` from anywhere. This lesson is two of them — `/film-pick` (a thin wrapper around `pick-film.sh`) and `/film-suggest` (Claude-reasoned recommendation). Both live in the cinema and get used through the rest of the series.

## Pre-Requisites

- The cinema with `CLAUDE.md` and project-level settings (lessons 1–5)
- Claude Code installed and authenticated
- A text editor

## What a Slash Command Actually Is

A slash command is a markdown file with YAML frontmatter. That's the whole thing. When you type `/your-command` inside Claude Code, the agent reads the file, applies any arguments you passed, and runs whatever the body of the file tells it to do.

Two locations:

```
.claude/commands/<name>.md            Project-specific. Committed to the repo.
~/.claude/commands/<name>.md          Personal. Available in every project.
```

Project commands live with the repo, get shared with the team, and version themselves alongside your code. The cinema's commands are project-scoped — they only make sense inside `~/dev/cinema/` because they reference `films.json`. Personal commands are your own — your `/standup`, your `/fix-tests`, your `/lint`. Lesson 7 covers the skills directory, which is the newer cousin of this pattern.

## Pouring Your Own Cocktail — The Frontmatter

The frontmatter declares the command's metadata and (importantly) what tools it's allowed to use. The fields that matter:

```yaml
---
description: One-line summary shown in /help
allowed-tools: Read, Write, Edit, Bash, WebSearch
argument-hint: <mood — e.g. "fun", "cosy">
model: claude-sonnet-4-6
disable-model-invocation: false
---
```

- **`description`** — what the command does. Shown when the user types `/` to filter the list.
- **`allowed-tools`** — the *only* tools the command can use. A `/lint` command listing only `Bash(npm run lint:*)` can't accidentally start editing files; a `/film-pick` listing `Bash` only can't go reading random files. This is the single most underused field and the most security-relevant one.
- **`argument-hint`** — what to type after the command, shown as autocomplete help.
- **`model`** — pin a specific model for this command.
- **`disable-model-invocation`** — set to `true` to stop the agent from auto-invoking this command on its own. By default, custom commands can be auto-selected when the task fits.

## Crafting the First One — `/film-pick`

The first command is the thinnest possible wrapper: shell out to `pick-film.sh` and show the result. No reasoning, no creativity — just turn `/film-pick wales` into the same answer `./pick-film.sh wales` would have produced.

`~/dev/cinema/.claude/commands/film-pick.md`:

```markdown
---
description: Pick a film from films.json by mood, using pick-film.sh
allowed-tools: Bash
argument-hint: <mood — e.g. "fun", "cosy", "cardiff", "wales">
---

The user wants a film for tonight. Their mood is: $ARGUMENTS

Run `bash pick-film.sh "$ARGUMENTS"` from the project root and show
the result verbatim. If the picker prints "No film for mood", suggest
the closest mood from the conventions in CLAUDE.md.

End with: "Reach for the popcorn, fellow hungovercoder."
```

Fire it inside the cinema:

```text
> /film-pick wales
```

```text
Hedd Wyn (1992) — 123min

Reach for the popcorn, fellow hungovercoder.
```

The `$ARGUMENTS` placeholder gets replaced with whatever you typed after the command name. You can use positional arguments too — `$1`, `$2` — if you need to handle multiple values. Multi-word arguments need quoting: `/film-pick "big night"` makes `$ARGUMENTS` expand to `big night`.

## Crafting the Second One — `/film-suggest`

The first command was a wrapper. The second is *reasoning*. Same data, different output: hand Claude the catalogue and ask for a recommendation with a one-line justification, rather than a deterministic first-match.

`~/dev/cinema/.claude/commands/film-suggest.md`:

```markdown
---
description: Suggest a film for a mood using the cinema catalogue plus light reasoning
allowed-tools: Read
argument-hint: <mood or short description — e.g. "knackered Tuesday", "big-night", "raining">
---

Read `./films.json`. The user's mood is: $ARGUMENTS

Pick ONE film from the list that best fits the mood. Explain why in
two sentences, leaning on the runtime and the Welsh/Mandalorian house
preferences in CLAUDE.md. If none truly fit, say so and suggest what
mood to add to the catalogue next.

End with: "Reach for the popcorn, fellow hungovercoder."
```

```text
> /film-suggest "knackered Tuesday"
```

```text
Twin Town (1997) — 99 minutes is the sweet spot for a school-night
Tuesday when energy is low but you still want something with bite.
The Cardiff in-jokes do half the lifting and you'll be in bed by
half-eleven.

Reach for the popcorn, fellow hungovercoder.
```

Two commands, two postures. `/film-pick` is the bartender pouring exactly what's on the tap. `/film-suggest` is the bartender saying "you look like you want a Cwtch tonight" — same catalogue, different output shape. Notice the `allowed-tools` difference: `/film-pick` needs Bash to run the script; `/film-suggest` only needs Read because all the work happens in the agent's head over the JSON. **Pick the narrowest tool list each command can do its job with.** That's the safety belt.

## The Bit the Docs Don't Mention

First time I wrote a slash command I assumed `$ARGUMENTS` worked like shell expansion. It doesn't quite. `$ARGUMENTS` is a literal string substitution — everything after the command name goes in as one blob. Quotes are *preserved* in the substitution, not consumed by it. If you type `/film-suggest "knackered Tuesday"`, the body sees `"knackered Tuesday"` *with* the quotes. For most cases this doesn't matter; for the cases where you're trying to do something clever with arguments, it'll trip you up.

The second quiet thing: command files are *also* read into context when the agent is browsing for help. If you write a huge prose document inside a command file, it inflates the agent's context on every session that lists the commands. Keep them tight. Both cinema commands above are under 15 lines for this reason.

## Have a Go — Add the Two Commands to the Cinema

```
~/dev/cinema/
├── films.json
├── pick-film.sh
├── CLAUDE.md
├── plans/lesson-05-mcp-feature.md
└── .claude/
    ├── settings.json
    └── commands/
        ├── film-pick.md          ← lesson 6 adds
        └── film-suggest.md       ← lesson 6 adds
```

1. Create the two files above. Or `cp -r docs/06-custom-slash-commands/solution/. ~/dev/cinema/` if you'd rather not retype.
2. Inside the cinema, type `/` and confirm both commands show up with their descriptions.
3. Compare the two: `/film-pick fun` and `/film-suggest fun` against the same catalogue. Watch how the deterministic wrapper differs from the reasoned suggestion.
4. Try the empty-result path on both: `/film-pick disco`. `pick-film.sh` returns "No film for mood: disco" — `/film-pick` suggests a closer mood, `/film-suggest` suggests adding `disco` to the catalogue. Same input, different shape of helpfulness.
5. Look at your own work for a workflow you'd write into a personal command at `~/.claude/commands/`. Pick the most annoying one — write the smallest possible version, with a tight `allowed-tools` list.

## My Verdict on Custom Slash Commands

Custom slash commands are the second-most-useful feature in Claude Code, after `CLAUDE.md`. They let you turn *prompts you'd otherwise retype* into reusable, version-controlled, share-with-the-team primitives. The `allowed-tools` field is what makes them safe to use in real codebases — without it, every command would carry the blast radius of a free-form session.

The thing that surprised me: once I had `/film-pick` and `/film-suggest` in muscle memory I stopped thinking about the catalogue and started thinking about the *interface*. That's a bigger productivity jump than any single command's content. The interface change is the real product.

What I'd do differently next time: I'd write the *first* command as a personal one in `~/.claude/commands/` before I tried writing a project command. Project commands tempt you to over-engineer because they're for the team; personal ones force you to keep it shabby and useful, which is the right starting energy.

On to lesson 7, fellow hungovercoder — let's meet skills, the newer cousin who shares a flat with slash commands.
