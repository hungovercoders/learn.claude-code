---
title: "Putting It Together and Safe Auto-Mode"
series: claude-code
order: 13
description: "Wire the cinema's install.sh, then prove the kit makes auto-mode safe — launch with --dangerously-skip-permissions and watch the cage you built across twelve lessons keep the agent honest"
canonical_url: https://hungovercoders.com/training/claude-code/13-putting-it-together-auto-mode
---

Across the previous twelve lessons your `~/dev/learn.claude-code/` directory has accumulated a `films.json`, a `pick-film.sh`, a `CLAUDE.md`, a project-level `settings.json` with permissions *and* hooks, two slash commands, three skills, a schema-checking hook, an MCP server wiring, a plan-mode artefact, a feature branch, an open draft PR with a cage checklist, and a user-level `~/.claude/CLAUDE.md` setting the posture for every session. This is the lesson where they stop feeling like twelve separate pieces and start composing — first into one portable workflow you actually use, and then into something you can hand to the agent on auto-mode and *walk away from*. The cage you built is what earns that.

## Pre-Requisites

- All previous lessons (you don't need to remember every line, but the *shapes* should be familiar)
- A `~/dev/learn.claude-code/` that's grown over the lessons (or `cp -r learn.claude-code/project/. ~/dev/learn.claude-code/` for the impatient route — same end state)
- The draft PR from lesson 4 still open. By the end of this lesson it'll have its final box ticked.

## The Whole Round — What We've Got

```
~/dev/learn.claude-code/
├── films.json                     (lesson 1)
├── pick-film.sh                   (lesson 1)
├── CLAUDE.md                      (lesson 6)
├── plans/mcp-feature.md           (lesson 7)
├── scripts/build-cinema-db.sh     (lesson 12)
├── .mcp.json                      (lesson 12)
├── .github/
│   └── pull_request_template.md   (lesson 4)
└── .claude/
    ├── settings.json              (lessons 5, 10)
    ├── commands/                  (lesson 8)
    │   ├── film-pick.md
    │   └── film-suggest.md
    ├── skills/                    (lessons 9, 11)
    │   ├── add-film/SKILL.md
    │   ├── pair/SKILL.md
    │   └── audit/SKILL.md
    └── hooks/                     (lesson 10)
        └── films-validate.sh
```

Plus your `~/.claude/CLAUDE.md` (lesson 3) and the cinema sitting on `feat/cinema-build` with the draft PR you opened in lesson 4. Twelve files of behaviour, one JSON catalogue, one shell script. The Cinema Companion picks films, validates writes, recommends pairings, audits its own data, and queries itself via SQL. The last two things we add are the one that makes it *portable* (install.sh) and the proof that the cage works (auto-mode).

## Step 1 — The Install Script

The cinema's behaviour lives in `~/dev/learn.claude-code/.claude/`. By default Claude Code only loads project-level skills, commands, and hooks when you're working *inside* `~/dev/learn.claude-code/`. Useful — but I want `/pair` and `/film-suggest` available from anywhere on my machine, so I can ask them about a film while I'm in a totally different repo writing a blog post about it. The fix is symlinks: the cinema is still the source of truth, but the user-level Claude Code directories point at it.

`~/dev/learn.claude-code/install.sh`:

```bash
#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/skills ~/.claude/hooks ~/.claude/commands

for c in "$HERE"/.claude/commands/*.md; do
  ln -sf "$c" ~/.claude/commands/$(basename "$c")
done

for s in "$HERE"/.claude/skills/*/; do
  ln -sf "$s" ~/.claude/skills/$(basename "$s")
done

for h in "$HERE"/.claude/hooks/*.sh; do
  ln -sf "$h" ~/.claude/hooks/$(basename "$h")
done

echo "cinema kit installed. Slash commands, skills, and hooks symlinked from $HERE."
echo "The films-validate hook still only fires when settings.json wires it — see lesson 10."
```

```bash
chmod +x ~/dev/learn.claude-code/install.sh
~/dev/learn.claude-code/install.sh
```

```text
cinema kit installed. Slash commands, skills, and hooks symlinked from /Users/dave/dev/learn.claude-code.
The films-validate hook still only fires when settings.json wires it — see lesson 10.
```

The cinema's `.claude/` directory stays in one place; the user-level Claude Code dirs point at it. You can move the cinema to a different folder, rerun `install.sh`, and everything keeps working — because the script captures `pwd` and rewrites the symlinks.

The deliberate omission: the script does *not* wire `films-validate.sh` as a global hook. The hook is project-specific — it knows the cinema's schema. Globalising it would fire jq schema checks against random JSON files in unrelated repos. The hook stays project-scoped via the cinema's `.claude/settings.json`; the install script only globalises the things that are safe to globalise (commands and skills with no side effects).

## Step 2 — A Hand-Driven Round

Inside the cinema, the full kit becomes one composed workflow. Three real commands, in order, on a Friday night:

```text
> /audit
```

Three subagents fan out. The unified report comes back: one duplicate, one mood that drifted from the conventions. Note them mentally; the data quality is good enough to pour.

```text
> /film-suggest "knackered Tuesday"
```

The agent reads `films.json` and `CLAUDE.md` and recommends *Twin Town*.

```text
> /pair "Twin Town"
```

The agent recommends salt-and-vinegar Tayto crisps, a pint of Cwtch, and a co-watcher who claims to remember the Lewis brothers.

Three commands, five features (CLAUDE.md, two skills, the audit's subagents, the validate hook silently guarding the catalogue), one chosen film, one paired round. The pieces compose. That's the kit, used by hand.

## Step 3 — The Cage You Built

Before we turn the agent loose, take stock of what the last twelve lessons earned you. Each lesson added one *cage layer* — a constraint, a guardrail, an enforcement point — that narrows what the agent can do unsupervised. The whole cage:

| Layer | Where it came from | What it stops |
| - | - | - |
| Personal posture | Lesson 3 — `~/.claude/CLAUDE.md` | Verbose, plausibly-wrong answers; emoji; preamble |
| Branch isolation | Lesson 4 — `feat/cinema-build` + draft PR | The agent touching `main`; invisible changes |
| Permissions allow + deny | Lesson 5 — `.claude/settings.json` | Unapproved Bash; `rm`; `git push` |
| Project conventions | Lesson 6 — `CLAUDE.md` | Wrong schema assumptions; "Cardiff" spelled "cardif" |
| Plan-before-execute | Lesson 7 — `plans/mcp-feature.md` | Big changes landing without you reading the plan first |
| Tool narrowing | Lesson 8 — `allowed-tools` per command | A `/film-pick` shelling out to anything other than the picker |
| Write safety belts | Lesson 9 — `disable-model-invocation` on `/add-film` | The agent appending rows on a hunch |
| Schema enforcement | Lesson 10 — `films-validate.sh` PostToolUse | A bad year, a non-lowercase mood, a 10000-minute runtime |
| Context isolation | Lesson 11 — `audit` skill spawns subagents | Three full reads of films.json polluting the main window |
| Bounded external access | Lesson 12 — `.mcp.json` + SQLite | Free-form `sqlite3` shelling out instead of typed queries |

Ten layers. Each one is small. Together they're the difference between "the agent might do something wrong on its own" and "the agent can run unsupervised on this project because every wrong thing it might do is already blocked."

Now we let it run.

## Step 4 — Auto-Mode, Two Postures at Once

Claude Code's `--dangerously-skip-permissions` flag is the CLI side of auto-mode. It removes the permission prompts. Combined with the harness Auto Mode bias — the agent acts without stopping to ask clarifying questions — you get "set the task, walk away, come back to a finished diff." Both postures compose; you can use either on its own, but the lesson is the pair.

Launch — and if you want the extra belt, do it in a fresh worktree spun off your build branch so the entire blast radius is one directory you can delete afterwards:

```bash
cd ~/dev/learn.claude-code
git worktree add ../learn.claude-code-automode feat/automode-demo
cd ../learn.claude-code-automode
claude --dangerously-skip-permissions
```

(Skip the worktree step if you're confident; the cage works either way. The worktree is the "I'd like a second seatbelt" option from lesson 4.)

You're now in a session with no prompts. Whatever the agent tries to do, it does. The *only* thing protecting your repo is the cage from lessons 4–12 — plus, if you took the worktree path, the fact that the working directory is a throwaway you can remove with one command.

Give it a task that exercises the kit:

```text
> Audit films.json, fix anything you find wrong (renaming bad moods,
  removing duplicates), then add three Welsh films from the 1990s
  that aren't already in the catalogue. Pair Hot Fuzz with a snack,
  a drink, and a co-watcher archetype. Commit each step and push.
```

What you watch happen, in order:

1. `/audit` fires. Three Explore subagents read `films.json` and `CLAUDE.md` in their own context windows. One paragraph of findings comes back.
2. The agent decides to rename a row's mood from `Wales` to `wales` to match the convention. It calls `Edit` on `films.json`. The `films-validate.sh` hook fires. The schema check passes; the edit lands.
3. The agent tries to `Bash` an `rm films.json.bak` — there's no backup file, so it's a no-op, but watch what happens if it tried `rm films.json` instead. The project-level `deny: ["Bash(rm:*)"]` from lesson 5 blocks it cold. The auto-mode flag does *not* override deny rules.
4. The agent fires `/add-film` three times in sequence — *because we typed the request, the `disable-model-invocation: true` belt doesn't apply (the user invoked the skill, even at one remove)*. Each addition triggers the hook. Two pass. One — a year that doesn't parse — fails schema check. The hook exits 2. The agent reads the stderr feedback, fixes the year, retries. Pass.
5. The agent `Read`s `films.json` again to find Hot Fuzz, then fires `/pair "Hot Fuzz"`. Snack: pretzels. Drink: Mango Punk. Co-watcher: someone who quotes Spaced unprompted.
6. The agent `git add`, `git commit`, `git push`es each step to `feat/cinema-build`. The draft PR you opened in lesson 4 picks up four new commits.

Nothing touched `main`. Nothing got past the schema hook. Nothing escaped the allow-and-deny list. The agent ran the whole task without you reading a permission prompt — because the cage already said no to everything you would have said no to.

Open the PR in your browser:

```bash
gh pr view --web
```

The diff is there, every commit labelled, the cage checklist now fully ticked because lesson 13 just landed. That's the audit trail. If anything looks wrong, `git reset --hard origin/feat/cinema-build~4` rolls back the auto-mode session and you start again with a sharper prompt. And if you ran the demo inside a worktree, the nuclear option is one line — `cd ~/dev/learn.claude-code && git worktree remove ../learn.claude-code-automode && git branch -D feat/automode-demo` — and the entire experiment is gone, your main build untouched.

## The Honest Moment That Earned the Cage

This is the moment to land the honest story that justifies the whole twelve-lesson cage we just built. Mine:

> I got in an auto-edit "accept changes" loop without thinking and kept pressing yes without planning or reading correctly. I ended up doing a force push and rewriting history on a repo, so I lost all public lineage. Luckily it wasn't an important repo, but it made me realise: it's very easy to give brain over. **Getting guardrails in with an intent to use auto mode as a discipline is a better goal than lazily pressing 2 over and over.**

That's the lesson I learned the hard way and that this whole series is the cure for. Every cage layer from lessons 4–12 — branch isolation, deny rules, project CLAUDE.md, allowed-tools narrowing, hooks, MCP — exists precisely so the *next* time the agent ends up in an accept loop, the loop runs against a cage instead of an open repo. Force-pushing inside this cage costs you nothing — the worktree gets removed, the branch gets reset, the PR diff shows you exactly what happened. Force-pushing without the cage cost me public lineage. The series exists so you don't pay that tax.

## The Bit the Docs Don't Mention

Two things the docs don't quite spell out about auto-mode.

**The deny rules are the load-bearing belt, not the allow list.** Auto-mode skips the *prompt* for tool use, but it does not override `deny` rules in `settings.json` or hook exit-2 blocks. That's why we layered both. The allow list is what you've pre-approved for ergonomics; the deny list is what stops the agent doing genuinely wrong things. If you only had time to write one of them before turning auto-mode on, write the deny list. Then the hooks. Then maybe one or two specific allows.

**`disable-model-invocation: true` matters less when *you* asked for the work.** I labelled `/add-film` as `disable-model-invocation: true` in lesson 9 to stop the agent deciding to add rows on its own initiative. In an auto-mode session where the human asked for additions, the agent invoking `/add-film` is fine — *the human's request is the invocation*. The flag stops *autonomous* invocation, not user-driven sub-invocation. That distinction is easy to miss; the docs gloss over it.

## Have a Go — Install, Run, Auto-Mode

```
~/dev/learn.claude-code/
├── ...
└── install.sh                    ← lesson 13 adds
```

1. Drop in `install.sh` (or `cp docs/13-putting-it-together-auto-mode/solution/install.sh ~/dev/learn.claude-code/`).
2. `chmod +x ~/dev/learn.claude-code/install.sh && ~/dev/learn.claude-code/install.sh`.
3. Run the three-command hand-driven round inside the cinema. Confirm everything composes.
4. **Then the proof.** Launch `claude --dangerously-skip-permissions` and hand it the audit-fix-add-pair task above. Watch the hook block bad rows. Watch the deny list block any `rm`. Watch the PR diff fill up.
5. Tick the lesson 13 box in the PR description on GitHub. Commit, push, tick. The PR is now ready for merge — every box ticked, every commit labelled, every cage layer demonstrated.
6. (Optional but recommended) Read the PR diff cold. If a stranger handed you this PR, would you merge it? The whole point of the cage is that the answer can be *yes*.

## The Verdict on the System as a Whole

Claude Code earns its keep when the pieces stop feeling like separate features and start composing into a workflow you actually use — and then *trust*. The shape that worked for the cinema — *one project repo + a small install script + CLAUDE.md + slash commands + skills + a hook + an MCP server + branch isolation + a draft PR cage checklist* — is the shape that turns "AI agent" into "team member you let work overnight." The portability matters; the composability matters; the source-control matters; the branch isolation matters most.

The big takeaway across the thirteen lessons: **the agent isn't the product, the cage you build around it is**. The model is the same model that powers Claude.ai. What makes Claude Code different is that it sits inside a configurable, scriptable, version-controllable shell where you can encode the way *you* work, the rules of *this* project, and the boundaries the agent must not cross — and then let it run inside those boundaries unsupervised. That's the destination the series was always aiming at. You can't fake the cage; the cage is yours.

## Where the Cinema Shape Goes Next — Library, or Just a Skill?

The cinema shape generalises, but it's worth being honest about *when* it generalises into a whole library vs *when* you just want a single skill. The library shape — multiple skills + voice/reference files + a hook + an install script + a CLAUDE.md — is the right reach when the use case has **several composing pieces** that share state. The single-skill shape is the right reach when the use case has **one focused job** and one prompt.

**The one I've actually built — a writing library.** The hungovercoders content library at `~/dev/hungovercoders/library/` is the cinema's shape repotted into a media workflow: `voice/datagriff-voice-guide.md` plus `voice/facts/<topic>.md` source-of-truth files (replacing `films.json`); `hc-write-lessons`, `hc-launch`, `hc-review-blog`, `hc-review-series`, `hc-social`, and `hc-datagriff-interview` skills (replacing the `/film-pick`/`/film-suggest`/`/pair` set); install script symlinks everything into `~/.claude/`. Multiple skills, shared reference files, real workflow — the library shape earns its keep here because the pieces compose into the same daily job. This is the one place I've gone full library, and it's been the right call.

**Two more shapes where I'd reach for *just a skill*, not a library.** Release-notes generation — a `/release-notes` skill that reads the most recent tag and shapes the output — is one focused job. No supporting files beyond the prompt, no shared state, no install script needed. Same for a code-review skill that walks a diff against a short review-style guide. Both useful; both would just be `~/.claude/skills/<name>/SKILL.md` files, not full libraries. **A skill is the cinema-shape minus the install script and the supporting cast.** Reach for it when one prompt does the job; promote to a library when the workflow grows pieces that want to live together.

The judgment call is the same one this series taught: **the agent isn't the product, the shape you build around it is.** Sometimes that shape is a library; sometimes that shape is a single skill. The cinema teaches the library shape because it's the bigger reach; once you've internalised it, dialling down to a skill is cheap.

What I'd do differently if I were starting again: you can't really skip the "use it and see what breaks" phase — that's how you find out where the rope is. But with the discipline now, the move is to **set up the guardrails and race for auto-mode proficiency as quickly as possible.** That's where maximum throughput lives — embedding the policies then letting rip with development knowing the guardrails are there. The twelve lessons of cage exist so the race is short and the rope doesn't bite. The setup feels like overhead until you've got it; after that every session starts from a known-good base, auto-mode is a one-flag decision rather than a stomach-clench, and the agent feels like a tool you sharpened rather than a chatbot you negotiated with.

Well done on the series, fellow hungovercoder. Merge the PR, raise a Cwtch, and watch this space for more.
