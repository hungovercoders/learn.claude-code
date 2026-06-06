---
title: "Hooks"
series: claude-code
order: 10
description: "Add the cinema's schema-checking PostToolUse hook — the bouncer that refuses films.json writes that break the rules CLAUDE.md only suggests"
canonical_url: https://hungovercoders.com/training/claude-code/10-hooks
---

I wanted `films.json` to *always* parse as JSON and *always* satisfy its schema, not just when Claude felt like it. The `CLAUDE.md` from lesson 6 says "moods are single lowercase words" and "runtime is between 60 and 240" — and from a few sessions in, Claude was following the rule maybe seven times out of ten. The rest of the time a bad row slipped in. Hooks are the fix: shell scripts that fire automatically at points in the session, with exit codes that can outright block or silently allow. They're the bouncer who actually checks the wristband, not the bar manager who *hopes* people respect the dress code.

## Pre-Requisites

- Lessons 8 and 9 finished — slash commands and skills installed in the cinema
- Comfort with shell scripts and exit codes
- `jq` installed (you've been using it since lesson 1)

## Last Orders — When Hooks Fire

Hooks run at lifecycle events. The ones you'll use most:

| Event | When it fires | Best for |
|---|---|---|
| `SessionStart` | Once when Claude Code starts | Injecting environment context, logging |
| `UserPromptSubmit` | Every time you submit a prompt | Validating input, adding context to the conversation |
| `PreToolUse` | Before every tool call | Guardrails — block, ask, allow, or rewrite the call |
| `PostToolUse` | After every tool call | Formatting, testing, audit logging |
| `Stop` | End of an agent turn | Cleanup, notifications |
| `SessionEnd` | When Claude Code exits | Final logging, state persistence |

Two cadences matter: **per turn** (UserPromptSubmit, Stop) and **per tool call** (PreToolUse, PostToolUse). A turn might involve twenty tool calls; the per-tool-call hooks fire for each one.

## Exit Codes — The Bit That Trips People Up

Hooks communicate with Claude Code via *exit code* and via *what they print to stderr*. Three outcomes:

- **Exit 0** — success, continue normally. Anything written to stdout is logged but not shown to Claude.
- **Exit 2** — **blocking error.** Claude Code halts the action; the contents of *stderr* are fed back to Claude as feedback. Use this for guardrails — the hook denies the tool call.
- **Any other non-zero** — non-blocking error. The hook failed but Claude continues. Stderr is shown to the human, not to Claude.

The stderr-not-stdout detail is the bit most newcomers get wrong. A common mistake is writing the deny reason to stdout and exiting 2 — Claude gets blocked but has no idea why, because the message went to the wrong stream. **Print to stderr, always, when you want Claude to read the feedback.** Even the official Anthropic tutorials don't quite emphasise it, which is why it's the first thing to flag.

## Wiring Up the Cinema Door

Hooks live in `settings.json` under a `hooks` key. They can be at the user level (`~/.claude/settings.json`), project level (`.claude/settings.json`), or local-override (`.claude/settings.local.json`). The cinema's hook is project-scoped — it knows the *cinema's* schema specifically. A general JSON validator would live at user level instead.

The hook itself: `~/dev/learn.claude-code/.claude/hooks/films-validate.sh`:

```bash
#!/bin/bash
# PostToolUse hook on Edit|Write. If films.json was touched, schema-check it.
# Exit 2 = block + send stderr back to Claude as feedback.

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // ""')

case "$file" in
  */films.json|films.json)
    if ! jq empty "$file" >/dev/null 2>&1; then
      echo "films.json no longer parses as JSON. Last edit broke the structure." >&2
      exit 2
    fi
    # Schema: array of objects with title (string), year (4-digit int),
    # mood (single lowercase word), runtime (int 60-240).
    bad=$(jq -r '
      to_entries
      | map(select(
          (.value.title | type) != "string"
          or (.value.year | type) != "number"
          or (.value.year < 1900 or .value.year > 2100)
          or (.value.mood | test("^[a-z]+(-[a-z]+)*$") | not)
          or (.value.runtime | type) != "number"
          or (.value.runtime < 60 or .value.runtime > 240)
        ))
      | map("row \(.key): \(.value)")
      | .[]
    ' "$file" 2>/dev/null)
    if [ -n "$bad" ]; then
      echo "films.json failed schema check:" >&2
      echo "$bad" >&2
      exit 2
    fi
    ;;
esac

exit 0
```

```bash
chmod +x ~/dev/learn.claude-code/.claude/hooks/films-validate.sh
```

The `case "$file"` switch is doing the cinema-scoping. It only runs the jq schema check when `films.json` was the file edited; for anything else, the hook is a no-op exit 0. That means the hook can sit in the project's PostToolUse list without slowing every edit — it does ~5ms of pattern-match work, then exits.

## Updating `settings.json` — Both Blocks Now

Lesson 5 wired the `permissions` block. Lesson 10 adds the `hooks` block alongside it. The full project `settings.json`:

`~/dev/learn.claude-code/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(jq:*)",
      "Bash(./pick-film.sh:*)",
      "Bash(bash pick-film.sh:*)",
      "Read(./films.json)",
      "Read(./CLAUDE.md)",
      "Edit(./films.json)"
    ],
    "deny": [
      "Bash(rm:*)",
      "Bash(git push:*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/films-validate.sh" }
        ]
      }
    ]
  }
}
```

The `matcher` field is a regex of tool names. `"Edit|Write"` fires for both. Omit the matcher for events that don't have one (UserPromptSubmit, SessionStart). `${CLAUDE_PROJECT_DIR}` resolves to the project root at runtime, so the path works regardless of which subdirectory the agent is operating in.

## Proving the Bouncer Works

Two tests. First: trigger an invalid write through `/add-film`:

```text
> /add-film "Bad" 999 BIG 10000
```

`add-film` writes the row, the hook fires, the schema check finds three problems (year < 1900, mood not lowercase-words, runtime > 240). The hook exits 2 with the stderr message. Claude reads the feedback and either fixes the row or backs out. You watch the JSON catch the bad row and roll back.

Second: edit a valid row by hand or by `/add-film "Pride" 2014 wales 119`. The hook fires, jq parses cleanly, schema check passes, exit 0. Silent success.

The hook is *project-scoped* on purpose. The cinema's schema is the cinema's business. Drop the same hook into another repo and the `case` switch makes it a no-op there (no `films.json`, no validation). That's why the hook lives inside `~/dev/learn.claude-code/.claude/hooks/`, not in `~/.claude/hooks/`. **The shape generalises** — every project gets its own schema-checking PostToolUse hook for its own load-bearing JSON files, each kept inside the project where it belongs.

## A Brief Tour of the Other Patterns

The cinema only needs the one hook. But while we're here, three other shapes worth knowing.

**User-level guard against `rm -rf`** (the classic). Drop this at `~/.claude/hooks/guard-rm.sh`:

```bash
#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')
if echo "$command" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f|rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'; then
  echo "Refusing rm -rf: '$command'. The human must run it." >&2
  exit 2
fi
exit 0
```

Wire it as a `PreToolUse` hook with matcher `Bash` in `~/.claude/settings.json`. Now any session on this machine, in any project, can't `rm -rf` through Claude Code. The cinema's project-level `deny: ["Bash(rm:*)"]` from lesson 5 is the same belt, narrower.

**User-level auto-format on Edit/Write** (the cleaner). Same pattern as `films-validate.sh` but runs `prettier`/`ruff`/`gofmt` instead of jq. Best as a user-level `PostToolUse` so it covers every project.

**Prompt logger** (the recorder). A `UserPromptSubmit` hook that appends every prompt to a daily log. Useful for retrospectives and for sharing how you actually use the tool with the rest of the team.

Each of these is one shell script and three lines of `settings.json`. The shape is small; the discipline is choosing which level — user, project, or local — they belong to. The cinema's films-validate is project-scoped because the schema is project-specific; guard-rm is user-scoped because `rm -rf` is dangerous everywhere.

## The Bit the Docs Don't Mention

**Exit 2 reads stderr, not stdout** — already flagged above but worth repeating because it's the single most common hook bug. Echo to `>&2` when you want Claude to read the feedback. Echo to stdout when you only want the human to see it. Mix them up and you'll have a hook that blocks correctly but Claude has no idea why and just retries the same command.

The other quiet thing: **don't put expensive work in `PreToolUse`.** It fires before *every* tool call, so a 200ms hook adds 200ms × N to your session latency. The cinema's hook is `PostToolUse` *and* short-circuits with `case` for non-films.json files, which keeps it well under 10ms on the no-op path. Honest disclosure on my side: the cinema's hook is the first hook I've written *in anger* for a real-ish project — every other hook I've touched has been in Anthropic's own tutorials. The cinema is where I find out which of these gotchas actually bites in practice.

## When the Bouncer Isn't the Answer

A hook is not always the right answer.

- For one-off per-project rules, `CLAUDE.md` is lighter. Hooks shine when you'd rather *enforce* than *suggest*.
- For tool restrictions, `settings.json` deny rules are simpler than a PreToolUse hook. Use the hook when you need *logic* the deny-rule globs can't express (the cinema's schema check is exactly that — globs can't express "must be 4-digit year and lowercase mood").
- For "do this thing whenever I ask Claude to do it", that's a slash command or skill, not a hook.

## Have a Go — Wire the Cinema's Hook

```
~/dev/learn.claude-code/
├── ...
└── .claude/
    ├── settings.json                    ← updated with hooks block
    └── hooks/
        └── films-validate.sh            ← lesson 10 adds
```

1. Drop in the hook and the updated `settings.json`. Or `cp -r docs/08-hooks/solution/. ~/dev/learn.claude-code/` for the lazy path.
2. `chmod +x ~/dev/learn.claude-code/.claude/hooks/films-validate.sh` — the most-skipped step. If it isn't executable, the hook silently doesn't fire and you'll be debugging a regex that wasn't the problem.
3. Try `/add-film "Bad" 999 BIG 10000`. Watch the hook block and the feedback get passed back to Claude.
4. Try `/add-film "Pride" 2014 wales 119`. Watch it succeed silently.
5. (Optional) Add the user-level `guard-rm.sh` from above to `~/.claude/hooks/` and `~/.claude/settings.json`. Different scope, same shape.
6. Commit and push:

```bash
git add .claude/hooks/ .claude/settings.json
git commit -m "lesson 10: films-validate hook + settings wiring"
git push
```

## My Verdict on Hooks

Hooks are the feature that turn Claude Code from "convenient" to "production-grade". The CLAUDE.md gets you suggestion; settings.json gets you permission; hooks get you *enforcement*. The three layers complement each other and the right answer for a given rule depends on whether you need the rule to be a *signal* (CLAUDE.md), a *gate* (settings.json), or a *guarantee* (hook).

For the cinema specifically, the films-validate hook is the file that *makes the kit trustworthy*. Without it, the schema is a promise; with it, the schema is an enforced rule. Same one line of stderr-feedback that the `/add-film` skill references — *"the films-validate.sh PostToolUse hook will re-check the schema"* — is the line that turns three independent pieces (CLAUDE.md, skill, hook) into a system that polices itself.

What I'd do differently next time: I'd write the validate hook on day one. It's twenty lines of shell, takes ten minutes to wire up, and it permanently raises the floor on what the agent can do to your catalogue by accident.

On to lesson 11, fellow hungovercoder — let's send three subagents to audit the catalogue at the same time.
