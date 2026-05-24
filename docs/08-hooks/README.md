---
title: "Hooks"
series: claude-code
order: 8
description: "Shell scripts that fire at lifecycle events — the bouncer pattern that enforces what CLAUDE.md only suggests"
canonical_url: https://hungovercoders.com/training/claude-code/08-hooks
---

I wanted Claude to *always* run the formatter after editing a file, not just when it remembered to. I'd written it into `CLAUDE.md` ("always run `bun fmt` after editing"), and it followed the rule maybe seven times out of ten. The rest of the time the diff came back unformatted and I had to ask. Hooks are the fix: shell scripts that fire automatically at points in the session, with exit codes that can outright block or silently allow. They're the bouncer who actually checks the wristband, not the bar manager who *hopes* people respect the dress code.

## Pre-Requisites

- Claude Code installed and authenticated (lesson 2)
- Comfort with shell scripts and exit codes
- A repo where you've got at least one "this should always happen" rule

## When Hooks Fire

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

The stderr-not-stdout detail is the bit I got wrong the first time. I wrote a PreToolUse hook that printed the deny reason to stdout and exited 2 — Claude got blocked but had no idea why, because the message went to the wrong stream. Print to stderr, always, when you want Claude to read the feedback.

## Configuring Hooks

Hooks live in `settings.json` under a `hooks` key. They can be at the user level (`~/.claude/settings.json`), project level (`.claude/settings.json`), or local-override (`.claude/settings.local.json`).

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/guard-rm.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/auto-format.sh" }
        ]
      }
    ]
  }
}
```

The `matcher` field is a regex (or comma-list) of tool names. `"Edit|Write"` fires for both `Edit` and `Write` tool calls; `"Bash"` fires only for Bash. Omit the matcher for events that don't have one (UserPromptSubmit, SessionStart).

## The Bouncer — A Real PreToolUse Hook

A hook that blocks `rm -rf` calls outright. Drop this in `~/.claude/hooks/guard-rm.sh`:

```bash
#!/bin/bash
# PreToolUse hook for Bash — blocks rm -rf and similar destructive commands.
# Exit 2 + stderr message = Claude sees the feedback and reconsiders.

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

if echo "$command" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f|rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'; then
  echo "Refusing rm -rf: '$command'. If you genuinely need this, the human must run it." >&2
  exit 2
fi

exit 0
```

```bash
chmod +x ~/.claude/hooks/guard-rm.sh
```

Now any `Bash` call where the agent tries to `rm -rf <anything>` is blocked, with the message going back to Claude so it can choose a different approach. Allow rules in `settings.json` can be argued with by a clever prompt; this hook can't.

You'll find the runnable version of this script alongside this lesson at `example-hook.sh`.

## The Cleaner — A PostToolUse Hook

The flip side: run a formatter after every edit. Drop this in `~/.claude/hooks/auto-format.sh`:

```bash
#!/bin/bash
# PostToolUse hook for Edit/Write — auto-formats the file that was just edited.

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // ""')

case "$file" in
  *.ts|*.tsx|*.js|*.jsx) npx prettier --write "$file" >/dev/null 2>&1 ;;
  *.py)                  ruff format "$file" >/dev/null 2>&1 ;;
  *.go)                  gofmt -w "$file" >/dev/null 2>&1 ;;
  *.rs)                  rustfmt "$file" >/dev/null 2>&1 ;;
esac

exit 0
```

It always exits 0 — formatting is best-effort, not a guardrail. If `prettier` isn't installed, the hook still exits cleanly; the edit doesn't get rolled back.

## The Logger — A UserPromptSubmit Hook

Want a record of every prompt you've ever sent? UserPromptSubmit gives you that:

```bash
#!/bin/bash
# UserPromptSubmit hook — log every prompt to a file with timestamp.

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""')
mkdir -p "$HOME/.claude/logs"
echo "[$(date -Iseconds)] $prompt" >> "$HOME/.claude/logs/prompts.log"
exit 0
```

Wire it up in `settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "$HOME/.claude/hooks/log-prompt.sh" } ] }
    ]
  }
}
```

Now every prompt you submit is in `~/.claude/logs/prompts.log`. Useful for retrospectives, useful for sharing how you actually use the tool with the rest of the team.

## The Bit the Docs Don't Mention

This is the bit the docs don't quite emphasise: **exit 2 reads stderr, not stdout**. I wasted a Tuesday morning on this. My PreToolUse hook was blocking calls correctly but Claude had no idea why, because I'd `echo "reason for block"` instead of `echo "reason for block" >&2`. The agent saw the block, didn't see the message, and just retried the same command. Once I redirected to stderr, the agent got the feedback and adapted on the next try.

The other quiet thing: don't put expensive work in `PreToolUse`. It fires before *every* tool call, so a 200ms hook adds 200ms × N to your session latency. Keep the bouncer fast. Audit logging belongs in `PostToolUse` (after the work is already done) or `UserPromptSubmit` (once per turn).

## When NOT to Use a Hook

A hook is not always the right answer.

- For one-off per-project rules, `CLAUDE.md` is lighter. Hooks shine when you'd rather *enforce* than *suggest*.
- For tool restrictions, `settings.json` deny rules are simpler than a PreToolUse hook. Use the hook when you need *logic* the deny-rule globs can't express.
- For "do this thing whenever I ask Claude to do it", that's a slash command or skill, not a hook.

## Have a Go

Wire up two hooks before moving on.

1. Drop the `guard-rm.sh` hook into `~/.claude/hooks/`, make it executable, and add the PreToolUse entry to your settings. Confirm Claude is blocked when it tries `rm -rf node_modules`, and that it sees the feedback message.
2. Add the `auto-format.sh` hook for your favourite language. Edit a file via Claude Code and confirm the formatter runs automatically afterward.
3. Wire up the prompt logger. Use the agent for ten minutes, then look at `~/.claude/logs/prompts.log` and see what you actually asked for.
4. Write a UserPromptSubmit hook that *adds* context — for example, injecting the current `git status` summary into every prompt automatically. (Hint: stdout of UserPromptSubmit gets prepended to the user's prompt.)

## My Verdict on Hooks

Hooks are the feature that turn Claude Code from "convenient" to "production-grade". The CLAUDE.md gets you suggestion; settings.json gets you permission; hooks get you *enforcement*. The three layers complement each other and the right answer for a given rule depends on whether you need the rule to be a *signal* (CLAUDE.md), a *gate* (settings.json), or a *guarantee* (hook).

The exit-code semantics — 0/1/2 with the stderr-feedback quirk — feels slightly clunky on first read but it's actually quite clean once you've got the muscle memory. Stderr for "Claude reads this", stdout for "the human reads this", exit 2 for "stop". A whole shell-script-shaped API in three rules.

What I'd do differently next time: I'd write the guard-rm hook on day one. It's twenty lines of shell, takes ten minutes to wire up, and it permanently raises the floor on what the agent can do to your machine by accident.

On to lesson 9, fellow hungovercoder — let's send someone to the bar on our behalf.
