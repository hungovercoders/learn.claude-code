---
title: "Branch, Draft PR, and Worktrees from Session One"
series: claude-code
order: 4
description: "Two layers of isolation before any Claude Code config lands — a feature branch with a draft PR (so main is untouchable) plus git worktrees (so parallel Claude sessions can't tread on each other). The floor the auto-mode lesson stands on."
canonical_url: https://hungovercoders.com/training/claude-code/04-branch-and-draft-pr
---

I wanted the agent to be able to work on real code without me worrying about the worst case. The worst case for an AI agent is "it edited something and I didn't notice, and now it's on `main`, and now it's deployed." Branch isolation plus a draft PR pushed on day one solves both halves: `main` is untouchable because we're never on it; the changes are visible on remote the moment they're made; and a `git reset --hard` is one keystroke away. This lesson is the floor that the rest of the series — and the auto-mode lesson at the end — stands on.

## Pre-Requisites

- The cinema seed from lesson 1 in `~/dev/learn.claude-code/`
- Git installed and configured (`git config --global user.name` set)
- The `gh` CLI installed and authenticated (`brew install gh && gh auth login` on macOS; `apt install gh` on Debian/Ubuntu)
- A GitHub account for the remote (any plan, public or private repo)

## The Discipline in One Sentence

**Never work on `main`. Push to remote on session one. Open a draft PR before the second commit lands.**

That's the whole rule. Everything in this lesson is the mechanics of holding the rule in place across the next ten lessons.

## Why This, Why Now

Three reasons this lesson lives where it does in the series — before permissions, before CLAUDE.md, before any skill or hook.

**Reason one: reversibility.** Every lesson from 5 onwards lands a real file in your cinema. If lesson 8's `/film-suggest` skill turns out to be wrong, or lesson 10's hook script has a typo that blocks everything, you want a `git reset --hard origin/main` to undo it cleanly. That's only safe if you've been working on a branch.

**Reason two: visibility.** Pushing every commit to a draft PR means each lesson's deliverable shows up as a diff on GitHub. You — or anyone else — can read the whole build at any point. Lesson 13's auto-mode demo can fan out across a dozen tool calls; the PR diff at the end is your audit log.

**Reason three: auto-mode safety, which is the real prize.** Lesson 13 lets the agent run with `--dangerously-skip-permissions`. If the agent goes wrong, the only thing protecting your repo's `main` branch is that the agent isn't on it. The branch isolation set up in this lesson is exactly that.

## Setting Up the Cinema as a Repo

If you cloned `learn.claude-code` and copied `docs/01-what-is-claude-code/solution/` into `~/dev/learn.claude-code/`, you've got the files but you haven't got a git repo yet. Initialise one:

```bash
cd ~/dev/learn.claude-code
git init
git add films.json pick-film.sh
git commit -m "lesson 1: seed cinema with films.json and pick-film.sh"
```

```text
[main (root-commit) a1b2c3d] lesson 1: seed cinema with films.json and pick-film.sh
 2 files changed, 16 insertions(+)
 create mode 100644 films.json
 create mode 100755 pick-film.sh
```

Now create a GitHub repo for it (private is fine — the kit is yours):

```bash
gh repo create cinema --private --source=. --remote=origin
git push -u origin main
```

```text
✓ Created repository <you>/cinema on GitHub
✓ Added remote https://github.com/<you>/cinema.git
```

`main` exists on remote and contains the seed. From this point on, you never commit to `main` directly again.

## Cutting the Feature Branch

```bash
git checkout -b feat/cinema-build
```

This branch is where the entire build lives. By lesson 13 it'll have nine commits from lessons 5–13, plus this lesson's PR template. Push it now so the remote knows about it:

```bash
git push -u origin feat/cinema-build
```

## Opening the Draft PR

Before you write the first piece of Claude Code config, open the PR. Empty (well, just the branch tip) is fine — it's a *placeholder for the work to come*, not a description of finished work.

```bash
gh pr create --draft \
  --title "Build out the cinema kit" \
  --body "Building the Cinema Companion across lessons 5–13. Tracking progress in the PR description as each lesson lands."
```

```text
https://github.com/<you>/cinema/pull/1
```

Open it in the browser:

```bash
gh pr view --web
```

That URL is where every subsequent lesson's commit will show up. You can leave the browser tab open as a live progress view.

## The PR Template — A Cage Checklist

A PR template at `.github/pull_request_template.md` populates the description of every new PR opened against the repo. We use it for the cage checklist — one tickable item per safety layer this series adds. As each lesson lands its deliverable, you tick the box; by lesson 13 you can look at the PR description and *see* the cage you've built.

`~/dev/learn.claude-code/.github/pull_request_template.md`:

```markdown
## Summary

<one or two sentences on what this PR changes>

## Cage layers ticked

Each lesson of learn.claude-code adds one safety layer that makes
auto-mode (lesson 13) safer. Tick as the layer lands.

- [x] Lesson 4 — Branch + draft PR. `main` untouchable; changes visible on remote.
- [ ] Lesson 5 — Permission modes. Project-scoped allow + deny rules.
- [ ] Lesson 6 — CLAUDE.md. Project conventions + things-to-never-do.
- [ ] Lesson 7 — Plan mode. Plan-before-execute discipline documented.
- [ ] Lesson 8 — Slash commands. `allowed-tools` narrowing per command.
- [ ] Lesson 9 — Skills. `disable-model-invocation` on writes.
- [ ] Lesson 10 — Hooks. Schema enforcement on every write to films.json.
- [ ] Lesson 11 — Subagents. Context isolation on the audit.
- [ ] Lesson 12 — MCP servers. Bounded external access via typed tools.
- [ ] Lesson 13 — install.sh + auto-mode proof.

## Test plan

- [ ] `bash pick-film.sh wales` returns a film
- [ ] `/film-pick`, `/film-suggest`, `/add-film`, `/pair`, `/audit` all invoke
- [ ] `films-validate.sh` blocks a bad row
- [ ] `claude --dangerously-skip-permissions` exercises the kit without touching `main`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Drop the file in:

```bash
mkdir -p ~/dev/learn.claude-code/.github
# Paste the template above, or copy from the lesson's solution/:
cp docs/04-branch-and-draft-pr/solution/.github/pull_request_template.md ~/dev/learn.claude-code/.github/
```

Commit and push:

```bash
git add .github/pull_request_template.md
git commit -m "lesson 4: PR template tracking the cage checklist"
git push
```

That commit shows up on the draft PR. The lesson 4 box stays ticked; the rest get ticked as you go. By lesson 13 the PR description is the build's table of contents.

## The Second Layer — Worktrees for Parallel Isolation

The branch + draft PR pattern protects you from the agent touching `main`. It does not protect you from *parallel work on yourself* — specifically, from having multiple pieces of work going on in different terminals against the same repo and accidentally polluting branches as the context flips. I've definitely lived that one — same repo, two terminals, lost track of which branch a half-staged change belonged to.

The fix is **git worktrees**. A worktree is a separate working directory that points at the same `.git` (so it shares history and objects) but has its own branch, its own index, its own staged state. You don't switch branches in one directory; you have a directory per branch. Each Claude session lives in its own working tree and cannot accidentally trip the others.

The minimum useful set of commands:

```bash
# Add a worktree at a sibling path, on a new branch
git worktree add ../learn.claude-code-experiment -b feat/experiment

# List every worktree this repo has
git worktree list

# Remove a worktree when you're done with it (don't `rm -rf`)
git worktree remove ../learn.claude-code-experiment
git branch -d feat/experiment   # delete the branch too if you don't need it
```

Applied to the cinema: keep your main build at `~/dev/learn.claude-code/` on `feat/cinema-build`. When you want to try something risky — a different hook shape, an experimental skill, an auto-mode session with a sharp-edged prompt — spin a worktree:

```bash
cd ~/dev/learn.claude-code
git worktree add ../learn.claude-code-experiment -b feat/experiment
cd ../learn.claude-code-experiment
claude
```

The experiment runs in a completely separate working directory. If it goes wrong you `git worktree remove ../learn.claude-code-experiment` and the failure leaves no trace in the main build. Two parallel `claude` sessions — one in `~/dev/learn.claude-code/` working on the lesson-by-lesson build, one in `~/dev/learn.claude-code-experiment/` exploring — share history through `.git` but can't see each other's uncommitted work. That's the second layer of isolation. The branch protects `main`; the worktree protects parallel work from itself.

There's an auto-mode payoff too. Lesson 13 lets the agent run with `--dangerously-skip-permissions`. The safest place to do that on something you genuinely care about is a *fresh worktree* — if the agent does something surprising, the worktree gets removed and your main build is untouched. We'll come back to this in lesson 13.

### "Why Not Just Use Worktrees Always Instead of Branches?"

A fair question the moment you understand worktrees: if a worktree gives me a clean directory per branch, why bother with branches in the first place — why not have one worktree per piece of work, full stop, and skip the branch-swapping discipline entirely?

The honest answer: **branches are the *unit* the rest of git (and GitHub) is built around — push, PR, review, merge.** A worktree is just a *checkout shape* — a separate working directory pointing at a branch. You still need the branch underneath for the PR to exist. So the answer isn't "worktrees replace branches"; it's "worktrees are how you have multiple branches *open at the same time*." When you only have one active piece of work, branches alone are fine — `git switch` and you're done. When you've got two pieces of work that you want both visible and in separate `claude` sessions, that's the worktree case.

The other small reason: worktrees have a tiny maintenance cost — each one creates a directory plus metadata in `.git/worktrees/` that needs cleaning up with `git worktree remove` when you're done. One worktree is fine, ten neglected ones are a mess. Branches are cheaper to leave lying around.

### The Bit the Docs Don't Mention About Worktrees

Three things worth knowing — the first one is what I had to investigate when I tried worktrees and didn't immediately understand the cleanup model.

**Never `rm -rf` a worktree directory.** Use `git worktree remove`. Removing the directory directly leaves stale metadata in `.git/worktrees/` that won't bite you immediately, but accumulates over a few months until `git worktree list` becomes confusing. `git worktree prune` cleans up after the fact — but the discipline is to use `git worktree remove` in the first place.

**The index is per-worktree; the stash is shared.** Each worktree has its own `index` and its own `HEAD`, which is what saves you from the branch-swap problem. But `git stash` operates on a *single repo-wide stash list* — so if you stash work in one worktree and `git stash pop` in another, you get the stashed changes in the wrong directory. For Claude Code use, *commit early instead of stash*. Commits are per-branch (and you're on different branches in each worktree), so they never cross over.

**The first worktree (the one at the original repo root) is the "main" worktree.** You can't `git worktree remove` it. If you want to delete it you have to move one of the other worktrees into its place first. Worth knowing once, never bites again.

### When Not to Use a Worktree

A worktree is for *parallel work you want to keep going at the same time*. If you'd be done with the experiment in five minutes and going back to `feat/cinema-build`, a worktree is overkill — just `git stash`, switch, switch back, `git stash pop`. The worktree pattern earns its keep when:

- The experiment will take more than one Claude session
- You want both directories visible in your editor at the same time
- You want to run `claude` in both simultaneously
- You're about to use `--dangerously-skip-permissions` and want a throwaway working tree as the safety net

## The Cadence — How Every Future Lesson Ends

This is the discipline you carry from here:

1. Read the lesson's prose.
2. Add the file(s) to the cinema (or `cp` from the lesson's `solution/`).
3. Test the deliverable works.
4. `git add`, `git commit -m "lesson N: <one-line description>"`, `git push`.
5. Tick the matching box in the PR description (edit it on GitHub).

Eleven small commits by the time you reach lesson 13. The PR diff is the whole story.

## The Bit the Docs Don't Mention

Two gotchas worth knowing.

**Don't squash the draft PR mid-series.** GitHub's "Squash and merge" UI is tempting once you've got eight commits — but each lesson's commit is a useful boundary you'll want to keep if you ever come back to debug *which lesson introduced the regression*. Save the squash for the final merge to `main`, after lesson 13. Or merge with a regular merge commit and keep all eleven.

**Use `gh pr view --json` from Claude Code sessions.** Once you're a few lessons in, the agent can read the PR state directly through `gh` rather than you describing it. *"Read the open draft PR, summarise where I am in the series, and tell me which boxes are still unticked"* becomes a useful prompt by lesson 9.

## When the Branch Discipline Isn't Worth It

A small honesty pass: for a one-line config tweak to your personal `~/.claude/settings.json` you do not need a branch and a draft PR. The discipline pays off on the cinema because the cinema is *gaining behaviour* you'll want to audit. For a five-second personal preference change, commit it on `main` of your dotfiles repo and move on. The branch-and-PR pattern is for *building behaviour onto a project*, not for every keystroke.

## Have a Go — Lock the Door, Then Open the Window

```
~/dev/learn.claude-code/
├── ...
└── .github/
    └── pull_request_template.md     ← lesson 4 adds this
```

1. `cd ~/dev/learn.claude-code && git init` if you haven't already. Push to `main` on a new GitHub repo.
2. `git checkout -b feat/cinema-build && git push -u origin feat/cinema-build`.
3. `gh pr create --draft --title "Build out the cinema kit" --body "..."`. Open it in the browser.
4. Add `.github/pull_request_template.md` from the template above (or `cp` the solution). Commit, push.
5. Refresh the PR in your browser — the PR description should now show the cage checklist with lesson 4's box ticked.
6. Try, just to feel the safety net: pretend to mess up. Create a junk file, commit it. Run `git reset --hard HEAD~1`. The file is gone, your branch is clean, and `main` was never involved. That's the floor you've built.
7. **Add a worktree as a dry run.** From `~/dev/learn.claude-code/`, run `git worktree add ../learn.claude-code-experiment -b feat/experiment`. `cd ../learn.claude-code-experiment` and `ls` — the cinema files are there, but you're on `feat/experiment` and `git status` is its own clean slate. Open `claude` in this new directory if you've got energy and try the same first-session prompt from lesson 2. Then `cd ~/dev/learn.claude-code && git worktree remove ../learn.claude-code-experiment` to clean up. The pattern is now in your hands.

## My Verdict on the Branch + Draft PR + Worktree Pattern

The pattern is the cheapest insurance Claude Code offers. Three commands at the start of a build (`git checkout -b`, `git push`, `gh pr create --draft`) and a five-second commit-and-push at the end of each lesson. Total overhead: maybe two minutes per lesson, generously. What you gain: a fully reversible build, a remote-visible diff at every step, a structured PR description with the cage checklist as you go, and a load-bearing safety floor for the auto-mode lesson at the end. Worktrees add the second axis: parallel safety. One `git worktree add` and you can run two Claude sessions on the same repo without either one stepping on the other's working state.

What I'd do differently next time: I'd build the branch-and-draft-PR habit into *every* multi-lesson tutorial I work through, not just this one — and I'd reach for `git worktree add` the moment I had two pieces of work that wanted their own terminals instead of doing the "multiple terminals on the same repo" dance and polluting branches. Both habits cost almost nothing to set up; the second one is the one I'm still building muscle memory for.

On to lesson 5, fellow hungovercoder — let's wire the project's first set of allow and deny rules.
