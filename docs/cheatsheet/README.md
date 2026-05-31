---
title: "Cheat Sheet"
series: claude-code
order: 99
description: "Keyboard shortcuts, built-in commands, lifecycle events, and the cinema-specific commands you've added across the eleven lessons — one page to keep open while you work"
canonical_url: https://hungovercoders.com/training/claude-code/cheatsheet
---

One page to keep open while you work. Reference shape, not narrative — every row links back to the lesson where the detail lives.

## Keyboard shortcuts (in a `claude` session)

| Shortcut | What it does |
| - | - |
| **Shift-Tab** | Cycle permission mode: default → acceptEdits → plan → default ([lesson 3](../03-permission-modes/), [lesson 5](../05-plan-mode/)) |
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
| `--dangerously-skip-permissions` | No prompts at all. Sandboxes only. **Never on a real repo.** |
| `--model <id>` | Override session model (e.g. `claude-sonnet-4-6`) |
| `--help` | All flags |

## Built-in slash commands

| Command | Purpose |
| - | - |
| `/help` | List available commands |
| `/init` | Generate a starter `CLAUDE.md` for this project ([lesson 4](../04-claude-md-project-context/)) |
| `/permissions` | View + edit active permission rules, show source file per rule ([lesson 3](../03-permission-modes/)) |
| `/sandbox` | Toggle the OS-level sandbox |
| `/plan` | Switch the active session into plan mode ([lesson 5](../05-plan-mode/)) |
| `/agents` | Manage subagents (definitions live in `.claude/agents/<name>.md`) ([lesson 9](../09-subagents-task-tool/)) |
| `/mcp` | List MCP servers currently connected and their tools ([lesson 10](../10-mcp-servers/)) |
| `/clear` | Reset the current session's context |
| `/model` | Switch model mid-session |

## Permission modes ([lesson 3](../03-permission-modes/))

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

## `CLAUDE.md` layout ([lesson 4](../04-claude-md-project-context/))

```
~/.claude/CLAUDE.md                Personal defaults — every project
<repo>/CLAUDE.md                   Project context — every session in this repo
<repo>/<subdir>/CLAUDE.md          Sub-project context
```

Use `@filename` inside a CLAUDE.md to inline-load another file (e.g. `@AGENTS.md`). Keep the file under ~150 lines; use progressive disclosure (point at detail, don't restate it).

## Custom slash commands + skills ([lesson 6](../06-custom-slash-commands/), [lesson 7](../07-skills/))

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

## Hooks ([lesson 8](../08-hooks/))

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

Wiring lives in `settings.json` under `hooks.<event>` with an optional `matcher` regex on tool names (e.g. `"Edit|Write"`).

## Subagents ([lesson 9](../09-subagents-task-tool/))

Spawn via the `Task` tool. Built-in agents:

| Agent | Use for |
| - | - |
| `Explore` | Read-only search — "find X in the codebase" |
| `general-purpose` | Open-ended research |
| `Plan` | Designing implementation strategies |

Custom subagents: define via `/agents` or as `.claude/agents/<name>.md`. Rule of thumb: subagents earn their keep when the inline alternative would dump more than ~5,000 tokens of noise into the parent context.

## MCP ([lesson 10](../10-mcp-servers/))

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
| `~/.claude/CLAUDE.md` | User-level project context (every session) |
| `~/.claude/commands/<name>.md` | User-level slash commands |
| `~/.claude/skills/<name>/SKILL.md` | User-level skills |
| `~/.claude/hooks/<name>.sh` | User-level hook scripts |
| `~/.claude/plans/<file>.md` | Default location for plan-mode artefacts |
| `~/.claude/logs/` | Where hook scripts write logs (by convention) |
| `~/.claude/config.json` | Encrypted auth token — **not a secrets store** |
| `<repo>/CLAUDE.md` | Project context |
| `<repo>/.claude/settings.json` | Project-level permissions + hooks |
| `<repo>/.claude/settings.local.json` | Personal overrides (gitignored) |
| `<repo>/.claude/commands/<name>.md` | Project-level slash commands |
| `<repo>/.claude/skills/<name>/SKILL.md` | Project-level skills |
| `<repo>/.claude/hooks/<name>.sh` | Project-level hook scripts |
| `<repo>/.mcp.json` | Project-level MCP server config |
| `${CLAUDE_PROJECT_DIR}` | Resolves to the project root at runtime (use in settings.json paths) |

## The Cinema Companion — what you typed by lesson eleven

After the install script:

| Command | What it does |
| - | - |
| `/film-pick <mood>` | Wrap `pick-film.sh` — deterministic pick from films.json ([lesson 6](../06-custom-slash-commands/)) |
| `/film-suggest <mood>` | Claude-reasoned suggestion that reads films.json + CLAUDE.md ([lesson 6](../06-custom-slash-commands/)) |
| `/add-film "<title>" <year> <mood> <runtime>` | Skill — append to films.json. `disable-model-invocation: true`. ([lesson 7](../07-skills/)) |
| `/pair <title-or-mood>` | Skill — snack + Tiny Rebel beer + co-watcher archetype ([lesson 7](../07-skills/)) |
| `/audit` | Skill — three parallel Explore subagents over films.json ([lesson 9](../09-subagents-task-tool/)) |

The `films-validate.sh` PostToolUse hook fires automatically on every `Edit|Write` and refuses writes that break the films.json schema.

```bash
~/dev/cinema/install.sh             # symlink .claude/* into ~/.claude/
~/dev/cinema/scripts/build-cinema-db.sh   # rebuild cinema.db for the MCP server
~/dev/cinema/pick-film.sh <mood>    # still runs from the shell, no claude required
```

## When in doubt

- Permissions misbehaving → `/permissions` shows the active list and the source file per rule.
- Hook silently not firing → `ls -l ~/.claude/hooks/` first. The missing executable bit costs a morning.
- MCP server not available → `/mcp` inside the session, or `claude mcp list` from the shell.
- Plan mode stuck → `/plan` to re-enter explicitly. Avoid combining with `--dangerously-skip-permissions`.
- Cinema preview mismatched → rerun `./scripts/build-cinema-db.sh` after `/add-film` (one-way sync is deliberate).
