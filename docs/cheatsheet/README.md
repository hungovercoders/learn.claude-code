---
title: "Cheat Sheet"
series: claude-code
order: 99
description: "Keyboard shortcuts, built-in commands, lifecycle events, branch + PR workflow, auto-mode safety checklist, and the cinema-specific commands you've added across the fourteen lessons — one page to keep open while you work"
canonical_url: https://hungovercoders.com/training/claude-code/cheatsheet
---

One page to keep open while you work. Reference shape, not narrative — every row links back to the lesson where the detail lives.

## Keyboard shortcuts (in a `claude` session)

| Shortcut | What it does |
| - | - |
| **Shift-Tab** | Cycle permission mode: default → acceptEdits → plan → default ([lesson 5](../05-permission-modes/), [lesson 7](../07-plan-mode/)) |
| **Esc** | Cancel the current tool call (the prompt is preserved) |
| **Ctrl-C** | Cancel the in-flight turn |
| **Ctrl-C twice** | Exit the session |
| **Ctrl-D** | Exit the session at an empty prompt |
| **Up / Down** | History — previous and next prompts |
| **Ctrl-R** | Reverse-search the prompt history |
| **/** at empty prompt | Open the slash-command picker (filters as you type) |
| **@** at empty prompt | Reference a file path (autocompletes) |

## Install + auth ([lesson 2](../02-installation-first-session/))

```bash
# Native binary (recommended)
curl -fsSL https://claude.ai/install.sh | sh
claude --version

# Or npm
npm install -g @anthropic-ai/claude-code

# First run opens browser OAuth. Headless / CI:
export ANTHROPIC_API_KEY=sk-ant-...
claude
```

## CLI flags

| Flag | What it does |
| - | - |
| `-c`, `--continue` | Resume the most recent session in this directory |
| `--resume <id>` | Resume a specific past session |
| `-p`, `--print` | One-shot non-interactive prompt, prints result and exits |
| `--permission-mode <mode>` | Launch in `default` / `acceptEdits` / `plan` / `dontAsk` / `bypassPermissions` |
| `--dangerously-skip-permissions` | Auto-mode. No prompts. Safe on the cinema by [lesson 14](../14-putting-it-together-auto-mode/) because of the cage. Not safe in general. |
| `--model <id>` | Override session model (e.g. `claude-sonnet-4-6`) |
| `--help` | All flags |

## Auto-mode + safety ([lesson 14](../14-putting-it-together-auto-mode/))

Two complementary postures:

- **`--dangerously-skip-permissions`** — the CLI flag. The agent stops asking before tool calls. *Deny rules and hooks still apply.*
- **Harness Auto Mode bias** — the agent stops asking clarifying questions and bias toward action.

Compose them on a project where the cage exists; never on a project where it doesn't.

### The cage checklist (lessons 4–13)

Auto-mode is safe on a project when all of these are in place:

- [ ] On a feature branch, never `main` ([lesson 4](../04-branch-and-draft-pr/))
- [ ] Draft PR open; every commit visible on remote ([lesson 4](../04-branch-and-draft-pr/))
- [ ] For risky auto-mode runs, in a throwaway `git worktree` ([lesson 4](../04-branch-and-draft-pr/))
- [ ] Project `.claude/settings.json` with a *deny* list ([lesson 5](../05-permission-modes/))
- [ ] Project `CLAUDE.md` encoding the conventions and "never do" rules ([lesson 6](../06-claude-md-project-context/))
- [ ] Slash commands and skills with tight `allowed-tools` ([lesson 8](../08-custom-slash-commands/), [lesson 9](../09-skills/))
- [ ] `disable-model-invocation: true` on anything that writes or has external side effects ([lesson 9](../09-skills/))
- [ ] PostToolUse hook enforcing the load-bearing invariants ([lesson 10](../10-hooks/))
- [ ] `/context` peeked at and `/compact` discipline applied at session breakpoints ([lesson 12](../12-context-and-cost/))
- [ ] MCP servers exposing typed tools instead of free-form Bash ([lesson 13](../13-mcp-servers/))

If three or more are missing, drop back to `default` or `acceptEdits` mode.

## Branch + draft PR workflow ([lesson 4](../04-branch-and-draft-pr/))

```bash
# At project init
git checkout -b feat/build
git push -u origin feat/build
gh pr create --draft --title "..." --body "..."
gh pr view --web

# After each lesson's deliverable
git add <files>
git commit -m "lesson N: <one-line description>"
git push

# When something goes wrong under auto-mode
git reset --hard origin/feat/build~N    # roll back the last N commits
```

The PR template at `.github/pull_request_template.md` (lesson 4 ships one) populates the description with a cage checklist you tick as each lesson lands.

## Worktrees — parallel session isolation ([lesson 4](../04-branch-and-draft-pr/))

A worktree is a separate working directory pointing at the same `.git`. Each worktree has its own branch, index, and HEAD — so two Claude sessions in two worktrees can't trip each other.

```bash
# Spin a worktree on a new branch at a sibling path
git worktree add ../learn.claude-code-experiment -b feat/experiment

# List every worktree this repo has
git worktree list

# Remove a worktree when done (don't rm -rf — leaves stale metadata)
git worktree remove ../learn.claude-code-experiment
git branch -d feat/experiment

# Clean up after a previous rm -rf if it happened
git worktree prune
```

When to reach for a worktree:

- Parallel work you want to keep running for more than a few minutes
- Both directories visible in your editor at the same time
- Two `claude` sessions running simultaneously on the same repo
- About to use `--dangerously-skip-permissions` and want a throwaway working tree as a safety net (auto-mode in a fresh worktree blast-radius-contains itself)

When *not* to:

- A five-minute swap to check something — `git stash` then `git stash pop` is faster
- Read-only inspection of another branch — `git show` or `git log` is enough

**Gotchas:** stash is repo-wide (don't share state across worktrees that way — commit instead). The original/root worktree can't be removed. Each worktree has its own index, so staged files in one are invisible to another.

## Built-in slash commands

| Command | Purpose |
| - | - |
| `/help` | List available commands |
| `/init` | Generate a starter `CLAUDE.md` for this project ([lesson 6](../06-claude-md-project-context/)) |
| `/memory` | Show the loaded CLAUDE.md files in this session ([lesson 3](../03-user-level-claude-md/)) |
| `/permissions` | View + edit active permission rules, show source file per rule ([lesson 5](../05-permission-modes/)) |
| `/sandbox` | Toggle the OS-level sandbox |
| `/plan` | Switch the active session into plan mode ([lesson 7](../07-plan-mode/)) |
| `/agents` | Manage subagents (definitions live in `.claude/agents/<name>.md`) ([lesson 11](../11-subagents-task-tool/)) |
| `/context` | Show what's loaded in the current session (system prompt, tools, memory files, messages) with token counts and % usage ([lesson 12](../12-context-and-cost/)) |
| `/compact` | Summarise the conversation so far and continue with the compressed history — free tokens mid-session ([lesson 12](../12-context-and-cost/)) |
| `/mcp` | List MCP servers currently connected and their tools ([lesson 13](../13-mcp-servers/)) |
| `/clear` | Reset the current session's context |
| `/model` | Switch model mid-session |

## Permission modes ([lesson 5](../05-permission-modes/))

| Mode | Behaviour |
| - | - |
| `default` | Asks before every new tool category |
| `acceptEdits` | Auto-approves file edits; still asks for Bash |
| `plan` | Read-only — no edits, no state-changing Bash |
| `dontAsk` | Auto-approves anything on the allow-list |
| `bypassPermissions` | Approves everything. Throwaway sandboxes only. |

Rule evaluation: **deny wins**, then `ask`, then `allow`. First match wins within a category. Globs, not regex — `Bash(npm test:*)` does **not** match `npm install`.

## Settings file hierarchy

```
1. Enterprise   /Library/Application Support/ClaudeCode/managed-settings.json
2. User         ~/.claude/settings.json
3. Project      <repo>/.claude/settings.json
4. Local        <repo>/.claude/settings.local.json   (gitignored)
```

Later layers override earlier ones, with the deny-wins rule on top.

## `CLAUDE.md` layout ([lesson 3](../03-user-level-claude-md/), [lesson 6](../06-claude-md-project-context/))

```
~/.claude/CLAUDE.md                Personal defaults — every project (lesson 3)
<repo>/CLAUDE.md                   Project context — every session in this repo (lesson 6)
<repo>/<subdir>/CLAUDE.md          Sub-project context
```

User-level reads first; project layers on top. Use `@filename` inside a CLAUDE.md to inline-load another file (e.g. `@AGENTS.md`). Keep each file under ~150 lines; progressive disclosure beats wiki-page exhaustiveness.

## Custom slash commands + skills ([lesson 8](../08-custom-slash-commands/), [lesson 9](../09-skills/))

| Shape | Lives at | When to use |
| - | - | - |
| **Slash command** (single file) | `.claude/commands/<name>.md` or `~/.claude/commands/<name>.md` | Tight, prompt-only workflows |
| **Skill** (directory) | `.claude/skills/<name>/SKILL.md` or `~/.claude/skills/<name>/SKILL.md` | Anything that needs supporting files or richer auto-invocation |

Frontmatter fields that matter:

| Field | Purpose |
| - | - |
| `description` | Shown in `/help` and used by Claude to decide auto-invocation |
| `allowed-tools` | The *only* tools the command/skill can use. Tighter = safer. |
| `argument-hint` | Autocomplete hint shown after the slash command |
| `disable-model-invocation` | `true` = only fires when the human types it. Use for anything irreversible. |
| `model` | Pin a specific model for this command |

Argument substitution: `$ARGUMENTS` (everything after the command name), `$1`, `$2` for positional.

## Hooks ([lesson 10](../10-hooks/))

| Event | Cadence | Best for |
| - | - | - |
| `SessionStart` | Once per session | Inject context, log start |
| `UserPromptSubmit` | Per turn | Validate input, inject context (stdout is prepended to the user prompt) |
| `PreToolUse` | Per tool call | Guardrails (block / allow / rewrite) |
| `PostToolUse` | Per tool call | Format, validate, audit-log |
| `Stop` | Per agent turn | Cleanup, notifications |
| `SessionEnd` | Once per session | Final logging, state persistence |

### Hook exit codes

| Exit | Meaning |
| - | - |
| `0` | Success — continue. stdout is logged, not shown to Claude. |
| `2` | **Blocking.** Tool call halts; **stderr is fed back to Claude as feedback**. |
| any other non-zero | Non-blocking error. stderr shown to the human only. |

Wiring lives in `settings.json` under `hooks.<event>` with an optional `matcher` regex on tool names (e.g. `"Edit|Write"`). **Hooks still fire under `--dangerously-skip-permissions`** — they're the load-bearing safety belt for auto-mode.

## Subagents ([lesson 11](../11-subagents-task-tool/))

Spawn via the `Task` tool. Built-in agents:

| Agent | Use for |
| - | - |
| `Explore` | Read-only search — "find X in the codebase" |
| `general-purpose` | Open-ended research |
| `Plan` | Designing implementation strategies |

Custom subagents: define via `/agents` or as `.claude/agents/<name>.md`. Rule of thumb: subagents earn their keep when the inline alternative would dump more than ~5,000 tokens of noise into the parent context.

## Context + cost ([lesson 12](../12-context-and-cost/))

| Command | Use |
| - | - |
| `/context` | Show what's loaded and how much window's used. Run at session breakpoints. |
| `/compact` | Summarise the conversation so far and continue. Free tokens mid-session. |
| `/checkpoint` | Cinema-specific. Asks the agent to self-audit context and recommend continue / `/compact` / fresh session. |
| `/clear` | Reset the session entirely. Cheaper than `/compact` when starting a new task. |

Discipline:

- Over 70% and mid-task → `/compact` immediately.
- New task, unrelated to current session → fresh session, always.
- CLAUDE.md is loaded *every session* — keep it tight.
- MCP tools cost system-prompt tokens. Only connect the servers you need for this session.
- Subagents save context: 50k-token grep in a subagent returns as a 200-token summary.

## MCP ([lesson 13](../13-mcp-servers/))

```bash
claude mcp list                              # what's connected
claude mcp add --transport stdio <name> -- <cmd>   # add one
claude mcp remove <name>                     # take one out
claude mcp restart <name>                    # reconnect after crash
```

Config scopes:

```
Local    (default)        Per-project, private, managed by CLI
Project  .mcp.json        Per-project, committed, team-shared
User     ~/.claude.json   Available everywhere, personal
```

Resolution order: local → project → user. **Never commit literal tokens** — use `${ENV_VAR}` interpolation in `.mcp.json` and bring secrets from the shell. Tool-Search auto-activates when tool definitions exceed 10% of the context window.

## File paths reference

| Path | What's there |
| - | - |
| `~/.claude/settings.json` | User-level permissions, hooks, MCP |
| `~/.claude/CLAUDE.md` | User-level project context (every session) — [lesson 3](../03-user-level-claude-md/) |
| `~/.claude/commands/<name>.md` | User-level slash commands |
| `~/.claude/skills/<name>/SKILL.md` | User-level skills |
| `~/.claude/hooks/<name>.sh` | User-level hook scripts |
| `~/.claude/plans/<file>.md` | Default location for plan-mode artefacts |
| `~/.claude/logs/` | Where hook scripts write logs (by convention) |
| `~/.claude/config.json` | Encrypted auth token — **not a secrets store** |
| `<repo>/CLAUDE.md` | Project context — [lesson 6](../06-claude-md-project-context/) |
| `<repo>/.claude/settings.json` | Project-level permissions + hooks |
| `<repo>/.claude/settings.local.json` | Personal overrides (gitignored) |
| `<repo>/.claude/commands/<name>.md` | Project-level slash commands |
| `<repo>/.claude/skills/<name>/SKILL.md` | Project-level skills |
| `<repo>/.claude/hooks/<name>.sh` | Project-level hook scripts |
| `<repo>/.mcp.json` | Project-level MCP server config |
| `<repo>/.github/pull_request_template.md` | PR template — [lesson 4](../04-branch-and-draft-pr/) |
| `${CLAUDE_PROJECT_DIR}` | Resolves to the project root at runtime (use in settings.json paths) |

## The Cinema Companion — what you typed by lesson fourteen

After the install script:

| Command | What it does |
| - | - |
| `/film-pick <mood>` | Wrap `pick-film.sh` — deterministic pick from films.json ([lesson 8](../08-custom-slash-commands/)) |
| `/film-suggest <mood>` | Claude-reasoned suggestion that reads films.json + CLAUDE.md ([lesson 8](../08-custom-slash-commands/)) |
| `/add-film "<title>" <year> <mood> <runtime>` | Skill — append to films.json. `disable-model-invocation: true`. ([lesson 9](../09-skills/)) |
| `/pair <title-or-mood>` | Skill — snack + Tiny Rebel beer + co-watcher archetype ([lesson 9](../09-skills/)) |
| `/audit` | Skill — three parallel Explore subagents over films.json ([lesson 11](../11-subagents-task-tool/)) |
| `/checkpoint` | Command — agent self-audits context and recommends continue / `/compact` / fresh ([lesson 12](../12-context-and-cost/)) |

The `films-validate.sh` PostToolUse hook fires automatically on every `Edit|Write` and refuses writes that break the films.json schema.

```bash
~/dev/learn.claude-code/install.sh             # symlink .claude/* into ~/.claude/
~/dev/learn.claude-code/scripts/build-cinema-db.sh   # rebuild cinema.db for the MCP server
~/dev/learn.claude-code/pick-film.sh <mood>    # still runs from the shell, no claude required
claude --dangerously-skip-permissions     # auto-mode, safe because of the cage (lesson 14)
```

## When in doubt

- Permissions misbehaving → `/permissions` shows the active list and the source file per rule.
- Hook silently not firing → `ls -l ~/.claude/hooks/` first. The missing executable bit costs a morning.
- MCP server not available → `/mcp` inside the session, or `claude mcp list` from the shell.
- Plan mode stuck → `/plan` to re-enter explicitly. Avoid combining with `--dangerously-skip-permissions`.
- Cinema preview mismatched → rerun `./scripts/build-cinema-db.sh` after `/add-film` (one-way sync is deliberate).
- Auto-mode about to do something irreversible → confirm a `deny` rule covers it, or the operation is on a feature branch you can `git reset --hard` from.
- User-level CLAUDE.md not loading → `/memory` lists which CLAUDE.md files are in scope. If `~/.claude/CLAUDE.md` is missing, check the exact path (case-sensitive).
