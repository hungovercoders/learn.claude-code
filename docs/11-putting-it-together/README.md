---
title: "Putting It Together"
series: claude-code
order: 11
description: "One realistic workflow that uses CLAUDE.md, custom skills, a hook, and a subagent — proof that the pieces compose into a system"
canonical_url: https://hungovercoders.com/training/claude-code/11-putting-it-together
---

I wanted to feel whether all this layers into a tool that earns its keep, or whether it's just clever pieces that don't actually compose. The honest test is to build one workflow that uses several features in service of a real outcome — not a contrived demo. So this lesson is exactly that: a personal "content workshop" setup that I run from any directory on my machine, built from the pieces we covered across lessons 4 to 10. By the end you'll have something that turns three commands into a publishable draft, and you'll see how `CLAUDE.md`, skills, hooks, and subagents work together instead of in isolation.

## Pre-Requisites

- All previous lessons (you don't need to remember every line, but the *shapes* should be familiar)
- A repo where you write *anything* repeatedly — blog posts, lesson content, release notes, design docs
- Ten minutes for setup and twenty for a real test run

## The Whole Round — The Setup

Here's the shape we're building. It's a personal library that lives in one git repo and gets symlinked into your user-level Claude Code directory by an install script. Once installed, the skills are available from any directory; the project where you actually *use* them doesn't need to know the library exists.

```
~/dev/my-writing-lib/
├── install.sh                  Symlinks skills + voice content into ~/.claude/
├── voice/
│   └── style-guide.md          Your voice rules. AI-loaded at run time.
├── skills/
│   ├── draft/SKILL.md          /draft — kick off a new draft
│   └── polish/SKILL.md         /polish — review and tighten a draft
└── hooks/
    └── word-count.sh           PostToolUse hook — logs word count after every edit
```

This shape is doing a few things at once:

- **Source of truth in one repo** so the workflow itself is version-controlled
- **Symlinked into user-level Claude Code dirs** so the skills work from anywhere
- **A `CLAUDE.md` in each writing repo** that points the agent at the project-specific rules without restating the voice rules
- **A hook that fires automatically** to keep a writing log

The hungovercoders content workflow in `~/dev/hungovercoders/library/` is built on exactly this pattern — we built it across this very series of lessons. The shape generalises.

## Step 1 — The Voice Layer (`voice/style-guide.md`)

The first file is the *opinion* of the system. It's not Claude Code config; it's the writing rules you want the agent to apply. For a writer it's a voice guide. For a code reviewer it'd be the code conventions. For a release-notes job it'd be the changelog format.

The skills (next step) read this file at run time. It's the single source of truth for "how I want the output to sound".

## Step 2 — The Skills (`skills/draft/`, `skills/polish/`)

Two skills that bracket the writing process.

`skills/draft/SKILL.md`:

```markdown
---
name: draft
description: Start a new draft on a topic, following the style guide
allowed-tools: Read, Write, WebSearch
argument-hint: <topic>
---

Read ~/.claude/my-writing-lib/voice/style-guide.md for the voice rules.

The topic is: $ARGUMENTS

Research the topic with WebSearch — find the official docs and one
real-world example. Then write a 500-word draft following the voice
rules. Save the draft to ./draft.md in the current directory.
```

`skills/polish/SKILL.md`:

```markdown
---
name: polish
description: Polish an existing draft against the style guide, spawning parallel reviewers
allowed-tools: Read, Edit, Agent
disable-model-invocation: true
---

Read ./draft.md and ~/.claude/my-writing-lib/voice/style-guide.md.

Spawn three parallel subagents to review the draft:
1. One checks for voice rule violations (filler words, "leverage", "robust")
2. One checks for structural issues (does it open with a want? does it close with energy?)
3. One checks for missing opinion beats (honest moment, verdict, what-I'd-do-differently)

Take the union of their feedback and apply the changes via Edit. Don't
rewrite — only fix what was flagged.
```

Two things to notice. The `draft` skill is plain — auto-invocation is fine because it only writes a new file. The `polish` skill has `disable-model-invocation: true` because polishing rewrites existing work and I want to be the one who decides when. Same pattern, two different safety postures.

The `polish` skill also uses the `Agent` tool to spawn subagents — three parallel reviewers, each with a narrow focus. The parent skill orchestrates; the subagents do the per-rule work; the unified feedback goes back to the parent. Context isolation in action.

## Step 3 — The Hook (`hooks/word-count.sh`)

A small `PostToolUse` hook that fires after every `Edit` or `Write` and logs the word count of the file to a daily log. Not enforcement — just observability.

```bash
#!/bin/bash
input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // ""')
[ -f "$file" ] || exit 0

words=$(wc -w < "$file")
mkdir -p "$HOME/.claude/logs"
echo "[$(date -Iseconds)] $words words in $file" >> "$HOME/.claude/logs/writing.log"
exit 0
```

Three months later, that log tells you which projects you actually write in. Useful for retrospectives, useful for not lying to yourself.

## Step 4 — The Install Script (`install.sh`)

The bit that makes the whole library portable. Run it once after cloning the repo; rerun it whenever you move the library.

```bash
#!/bin/bash
set -euo pipefail
LIB="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/skills ~/.claude/hooks ~/.claude/my-writing-lib/voice

for s in "$LIB"/skills/*/; do
  ln -sf "$s" ~/.claude/skills/$(basename "$s")
done

for h in "$LIB"/hooks/*.sh; do
  ln -sf "$h" ~/.claude/hooks/$(basename "$h")
done

for v in "$LIB"/voice/*; do
  ln -sf "$v" ~/.claude/my-writing-lib/voice/$(basename "$v")
done

echo "writing library installed. Skills, hooks, and voice content symlinked."
```

The library can live anywhere — the install script captures `pwd` and symlinks from there. Move the library, rerun the script, everything keeps working.

## Step 5 — The Settings (`~/.claude/settings.json`)

Wire the hook in:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/word-count.sh" }
        ]
      }
    ]
  }
}
```

That's the whole config. Skills auto-load from `~/.claude/skills/`; the voice file is read by the skills at run time; the hook fires on every edit.

## Step 6 — Using It

From any directory:

```text
> /draft "Quick Beer with Bento"
```

The agent reads the voice guide, researches Bento, writes a 500-word draft to `./draft.md`.

```text
> /polish
```

Three subagents fan out and review in parallel. The parent applies their feedback. The hook silently logs the word count on every edit.

Three commands, four features (CLAUDE.md if your repo has one, skills, hooks, subagents), one publishable draft. The pieces compose.

## The Bit the Docs Don't Mention

I'll be honest, the first time I tried this exact pattern I had the skills in the right place but the voice guide *not* symlinked — I'd just hardcoded the path to wherever the library happened to live. Everything worked until I moved the library to a different folder, and then nothing worked, and I had no idea why because all the slash commands still appeared in `/help`. **Install scripts that symlink reference content into stable user-level paths are the difference between "this is portable" and "this works on the machine you built it on".** That's not a Claude Code lesson per se, but it's the lesson the official docs don't quite spell out for personal libraries.

## Have a Go

This is the lesson where you build something real, not just read.

1. Create a writing library (or a code-review library, or a release-notes library — whatever your actual job involves) with the same shape: `voice/`, `skills/`, `hooks/`, `install.sh`.
2. Write two skills that bracket your most-repeated workflow: one to kick off, one to wrap up.
3. Add one hook that observes (logs, counts, notifies). Don't make it block on the first version — observability earns its keep faster than enforcement.
4. Run the workflow on a real piece of work. Notice what's slow, what's clunky, what works first time. Iterate the library.

## My Verdict on the System as a Whole

Claude Code earns its keep when the pieces stop feeling like separate features and start composing into a workflow you actually use without thinking. The shape that worked for me — *library repo + install script + skills + hooks + voice files* — is the shape I now reach for whenever I'd otherwise be retyping the same instructions into a chat window. The portability matters; the composability matters; the source-control matters. None of those are technically *required* by Claude Code, but it's the combination that makes the tool worth more than the chat window.

The big takeaway across the eleven lessons: **the agent isn't the product, the system you build around it is**. The model is the same model that powers Claude.ai. What makes Claude Code different is that it sits inside a configurable, scriptable, version-controllable shell where you can encode the way *you* work and have the agent follow it without retyping. That's the thing AI tutorials can't fake — your shape of the system is yours.

What I'd do differently if I were starting eleven lessons ago: I'd build the library *first*, before writing a single piece of content with Claude. Three skills and one voice file in a public repo would have saved me the first month of inconsistent results. The setup feels like overhead until you've got it; after that, every session starts from a known-good base, and the agent feels like a tool you sharpened rather than a chatbot you negotiated with.

Well done on the series, fellow hungovercoder. Cheers — and watch this space for more.
