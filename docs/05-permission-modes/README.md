---
title: "Permission Modes and Safety"
series: claude-code
order: 5
description: "The five permission modes, the settings.json hierarchy, and the bouncer pattern that stops the agent doing something you didn't agree to — wired to the cinema repo"
canonical_url: https://hungovercoders.com/training/claude-code/05-permission-modes
---

Honest confession to open the lesson: I haven't leveraged permissions very well yet. My day-to-day is plan mode then auto-edit at home (more cavalier) and plan mode then manually accept edits at work — not because that's the optimal setup, but because I haven't taken the time to put the guardrails and practices in. And I've definitely sleep-walked into accepting things while pressing 2 over and over — the exact failure mode that turns an AI agent from a tool into a liability. This lesson is the antidote: the curated config I *should* have, in two layers — a user-level default and the first piece of Claude Code config that lands in your cinema repo. We build it together so you don't have to learn the discipline by force-pushing through it.

## Pre-Requisites

- Claude Code installed and authenticated (lesson 2)
- The cinema seed from lesson 1 (`~/dev/cinema/films.json` + `pick-film.sh`)
- Your user-level `~/.claude/CLAUDE.md` from lesson 3
- The cinema on a feature branch with a draft PR open (lesson 4) — every settings change in this lesson lands as a commit on that branch
- A text editor for `settings.json` files

## The Five Modes (and One Dangerous One)

Claude Code ships with five permission modes plus the explicit "I know what I'm doing" escape hatch. Each is a session-wide posture — set it when you launch the agent, switch it mid-session if you need to.

| Mode | What it does | Where it fits |
|---|---|---|
| `default` | Asks before every new tool category. | Anything touching a repo you care about. The bouncer is on the door. |
| `acceptEdits` | Auto-approves file edits; still asks for Bash. | Pair-coding through a known refactor where you don't want a prompt every five seconds. (My current cavalier-mode-at-home posture.) |
| `plan` | Read-only. The agent can't edit or run anything. | Exploration and design conversations. Lesson 7 is dedicated to this one. (My day-to-day starting posture for any non-trivial task.) |
| `dontAsk` | Auto-approves anything on your allow-list. | Scripted workflows once you've curated the allow-list properly — the version of this lesson where the cage works. |
| `bypassPermissions` | Approves everything. No prompts. | Throwaway sandboxes only. Never a real repo. |

The last one — `--dangerously-skip-permissions` on the command line — is for ephemeral containers where the worst-case blast radius is destroying the container itself. If you find yourself reaching for it in a real codebase, you're using the wrong tool; reach for `acceptEdits` and a curated allow-list instead.

## Setting the House Rules — `settings.json`

Permission rules live in `settings.json`. There are four layers, evaluated in order:

```
1. Enterprise   /Library/Application Support/ClaudeCode/managed-settings.json   (macOS — locked-down by IT)
2. User         ~/.claude/settings.json                                          (your personal defaults)
3. Project      .claude/settings.json                                            (committed to the repo)
4. Local        .claude/settings.local.json                                      (gitignored, your personal repo overrides)
```

You'll wire the cinema at the **project** layer in a moment. First the user-level shape, because it's the one that earns its keep across every project you touch.

A minimal user-level config that's saved me a lot of permission-prompt churn:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(npm test:*)"
    ],
    "ask": [
      "Bash(git push:*)",
      "Bash(rm:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(curl:*sudo*)",
      "WebFetch(domain:internal.company.com)"
    ]
  }
}
```

Three rules cover almost every case:

- **`allow`** — auto-approve. Use it for the boring reads (`Read`, `Grep`) and the safe commands you run a hundred times a day (`git status`, `git log`).
- **`ask`** — prompt every time, even if it's already in an allow pattern higher up. Use it for anything irreversible at the repo level (`git push`, `rm`).
- **`deny`** — refuse outright. Use it for the things you'd never want Claude doing without a human typing the command itself.

### Rule evaluation order — the bit that trips people up

**Deny rules win.** Then `ask`, then `allow`. First match wins within each category. So `Bash(rm -rf:*)` in `deny` blocks even though `Bash(rm:*)` would have asked — because deny is checked first.

The rules use glob patterns, not regex. `Bash(npm test:*)` matches `npm test`, `npm test:unit`, `npm test --coverage`. It does **not** match `npm install` or `npm run test` (note the spaces and colons). When in doubt, run `/permissions` inside a session to see the active list and the source file each rule came from.

## The First Cinema Config — Project-Level Permissions

The cinema repo is the perfect place to learn project-level config. Lesson 2 asked you to approve `Bash(./pick-film.sh:*)` and `Bash(jq:*)` interactively. Now you'll commit those approvals to the repo so every future cinema session starts with them already trusted — and crucially, *only* in this project. Pour them into `~/.claude/settings.json` and you've widened them to every directory you ever `claude` into; pour them into `.claude/settings.json` in the cinema repo and they only apply when you're working on the cinema.

```bash
mkdir -p ~/dev/cinema/.claude
```

`~/dev/cinema/.claude/settings.json`:

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
  }
}
```

The shape is the same as the user-level version. The contents are specific to this project. `Edit(./films.json)` is *also* the file your hook will police in lesson 10 — by the end of the series the cinema has *both* a permission rule that says "edits to films.json are pre-approved" *and* a hook that runs after every such edit and rolls back invalid ones. Belt and braces, picked deliberately for the file that holds the data.

The deny rules are project-scoped guardrails. You're saying "in this project, never `rm`, never `git push` — because the cinema's tiny and the consequences of a wrong `rm` or a wrong push are real". You might keep a wider deny list at user level; the project one is the *additional* layer specific to this project's risk profile.

## The Sandbox — OS-Level Backup

Permissions live inside Claude Code; the sandbox lives one layer below, at the OS level. The sandbox restricts what the `Bash` tool can do at the filesystem and network level — and unlike permission rules, it can't be argued with by a clever Claude. Two complementary layers:

```json
{
  "sandbox": {
    "enabled": true,
    "allowedDomains": ["github.com", "registry.npmjs.org"],
    "deniedDomains": ["*"]
  }
}
```

Honest pass: I haven't used the OS-level sandbox myself yet — it's on the list. The shape above is what to reach for the moment you're working on anything production-adjacent where a wrong network call would actually cost something. For personal sandboxes like the cinema, the in-Claude-Code permission layers are enough.

## The Bit the Docs Don't Mention

The glob patterns are not regex, and the precision will trip you if you don't know that. **`Bash(npm test:*)` matches `npm test`, `npm test:unit`, and `npm test --coverage` — but it does NOT match `npm install`, `npm run test`, or `npm test:` followed by anything other than its sub-arguments.** It's a common surprise the first time you add one; the agent keeps asking about `npm install` and you assume the rule is broken when in fact the rule is *exactly* what you wrote and what you wrote wasn't what you meant. Read your globs carefully; test them with `/permissions` inside a session before you trust them.

The other quiet thing: `/permissions` inside a session is the fastest way to debug. It shows you which file each rule came from, which is invaluable when your project-level config is doing something your user-level config didn't expect.

## Live-Switching Modes

You don't have to commit at launch time. Once inside a session:

- `/permissions` — view and edit the active permission set
- Shift-Tab — cycle through modes (default → acceptEdits → plan → default)
- `/sandbox` — toggle the OS-level sandbox

My current pattern: **plan mode first to have the design conversation, then drop to default or acceptEdits to execute.** At home where the worst-case blast radius is small I'll trust auto-edits sooner; at work I drop to manually accepting edits until the project's cage is fully built. *That's* the posture that needs the rest of the series — the dontAsk + tight allow-list version is what's coming together by lesson 13.

## Have a Go — Add the First Claude Config to the Cinema

```
~/dev/cinema/
├── films.json
├── pick-film.sh
└── .claude/
    └── settings.json      ← lesson 5 adds this
```

Get permissions feeling comfortable before lesson 6:

1. Create `~/.claude/settings.json` with the user-level config from the "Setting the House Rules" section. Open a Claude Code session and run `/permissions` to confirm the rules loaded.
2. Add `~/dev/cinema/.claude/settings.json` with the project-level config from the "First Cinema Config" section. Start a session in the cinema with `cd ~/dev/cinema && claude` and run `/permissions` again — confirm the project rules stack on top of the user defaults, and that `/permissions` shows the source file each came from.
3. In the cinema session, ask Claude to run `./pick-film.sh wales`. It should run with no prompt — your project allow-list pre-approved it.
4. Ask Claude to `rm films.json`. Watch the project deny rule win even though `Bash(rm:*)` would have asked.
5. Launch with `claude --permission-mode plan` from inside the cinema. Ask it to refactor `pick-film.sh` and watch it refuse to edit anything. We'll properly meet plan mode in lesson 7.

6. Commit the new `.claude/settings.json` to your feature branch and push it to your draft PR from lesson 4:

```bash
git add .claude/settings.json
git commit -m "lesson 5: project-level permissions"
git push
```

The PR now shows the permissions block. Every subsequent lesson commits to the same branch — by lesson 13 the PR diff is the whole story of how the cage got built.

The full `solution/` for this lesson is the project-level settings.json above — `cp -r docs/03-permission-modes/solution/. ~/dev/cinema/` if you'd rather not retype it.

## My Verdict on the Permissions Model

The permissions system is the bit of Claude Code that most justifies trusting an AI agent inside a real repo. The deny-first ordering is the right design — it means a `deny` rule survives no matter what allow rules accumulate above it. The four-layer settings hierarchy mirrors the way real teams work (enterprise lockdown, personal preferences, project policy, personal overrides) without forcing everyone into the same config.

What I'd do differently if I were starting again: I'd set up the **user-level** `settings.json` and the project-level deny list before I ever opened a real session in auto-mode. Every session you run before those exist is one where you're either reading prompts carefully (good but slow) or — like me, honestly — pressing 2 without quite reading and hoping for the best (fast, until it isn't). Curating the permissions up front is what turns *"I should be more careful"* into *"the cage is being careful for me."*

On to lesson 6, fellow hungovercoder — time to write the project-level recipe card the agent reads before pouring anything.
