---
title: "Installation and First Session"
series: claude-code
order: 2
description: "Install Claude Code, log in, and run the first session inside the cinema repo — the agent reads pick-film.sh on its own and proves the integration is the product"
canonical_url: https://hungovercoders.com/training/claude-code/02-installation-first-session
---

Installing a CLI in 2026 should be a low-surprise affair, but plenty of "just `npm install -g` and you're away" posts leave out the bit where the binary isn't on your PATH and you spend longer than you should wondering whether you've broken `node`. The cleanest path in 2026 is the native binary Anthropic now ship — it bypasses the npm faff entirely. Let's get the first round in and point Claude Code at the cinema seed you planted in lesson 1.

## Pre-Requisites

- The cinema seed from lesson 1 (`~/dev/cinema/films.json` + `pick-film.sh`)
- macOS, Linux, or Windows (with WSL)
- A Claude.ai account on the Pro plan or higher (Claude Code isn't on the free tier)
- A terminal you actually like — iTerm2, Warp, Ghostty, whatever
- Optional: Node.js ≥ 20 if you want the npm install path

## Getting the First Round In

There are two install paths. The native binary is what Anthropic ship as the default; npm still works if you're already a Node person.

### Native binary (the recommended pour)

On macOS or Linux:

```bash
curl -fsSL https://claude.ai/install.sh | sh
```

The script drops a code-signed `claude` binary into `~/.local/bin` (or `/usr/local/bin` depending on your platform) and adds it to your PATH if it isn't already there. It also wires up auto-updates so you don't have to chase releases manually.

Verify it landed:

```bash
claude --version
```

```text
claude-code 2.x.x
```

If `claude: command not found` comes back, open a new terminal tab — the installer prints the PATH line it added to your shell config, and existing tabs haven't reloaded it yet. This is the bit that costs people the most time. Source your `~/.zshrc` (or `~/.bashrc`) or just close the tab and open a new one.

### npm install (the alternative)

If you've already got Node 20+ and you'd rather everything live in npm:

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

It works fine, but two warnings: (1) you'll need to update it manually with `npm install -g @anthropic-ai/claude-code@latest` instead of getting auto-updates; (2) on macOS without a node version manager you sometimes need `sudo` for the global install, which is the kind of thing my future self always regrets. The native binary skips both problems.

## Stepping Up to the Bar — Login

Run `claude` for the first time and it'll open your browser for OAuth. Log into your Claude.ai account, confirm access, and the terminal picks up the token automatically:

```bash
claude
```

```text
Authenticating...
Browser opened. Sign in to Claude.ai to continue.
✓ Authenticated as dave@tinyrebel.co.uk
```

The token gets stored in `~/.claude/config.json` (AES-256 encrypted). It stays active for 30 days of inactivity — so if you take a long holiday, expect to re-auth when you get back. Not a problem; the holiday is the point.

**Headless setup.** If you're on a server, in a Docker container, or in CI where there's no browser to open, set an API key instead:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
claude
```

Claude Code will use the key and skip the OAuth dance.

## First Sip — The Cinema Repo Speaks Back

The fastest way to feel what Claude Code is for is to point it at the cinema you set up last lesson and ask it something it has to actually *do*.

```bash
cd ~/dev/cinema
claude
```

You'll get a prompt that looks like a TUI chat. Type the kind of question you'd ask a junior dev who's just opened the repo:

```text
> Read pick-film.sh and explain in two sentences what the script does
  and how it picks a film.
```

What you'll see is a sequence of tool calls — `Read` on `pick-film.sh`, possibly a `Read` on `films.json` to check the shape it's filtering against, then a short summary. Each tool call asks for your permission the first time it hits a new category. **Read each prompt before clicking through.** This is the muscle you want to build before lesson 5 turns the permission system into the proper bouncer.

Try one more, this time making the agent run something:

```text
> Run pick-film.sh with the mood "comedy" and tell me what it prints.
```

You'll see a `Bash` permission prompt for the script. Approve it once, the agent runs the picker, and you get the answer:

```text
Hot Fuzz (2007) — 121min
```

That's the integration — the agent didn't describe what `pick-film.sh` would output, it actually ran it. That's the gap between Claude.ai and Claude Code, in two tool calls.

## The Bit the Docs Don't Mention

Coming from the chat-window habit — type a question, get an answer, move on — the mental adjustment Claude Code asks for is **it's an agent, not a chatbot.** When you ask it something, it doesn't immediately answer — it starts *doing*. It reads files, runs greps, kicks off bash. The "response" is the result of work it actually performed. That's the whole point but it feels surprising the first time because the chat-window habits run deep.

The corollary: the more concrete your request, the better. "Improve my code" leaves it guessing what to do. "Find all the places we set a `Content-Type` header and tell me which ones use a different value to the rest" gives it a job. Once you start writing requests like the second one, the agent earns its keep fast.

## Have a Go — Prove the Agent Sees Your Cinema

There's no new file to add in this lesson. The deliverable is *proof* — a transcript of Claude Code reading and running code from your cinema repo. Try all four:

1. `cd ~/dev/cinema && claude`. Ask it: *"What does this project do, in one paragraph?"*. Notice it reads `films.json` and `pick-film.sh` before answering.
2. Ask it: *"Run pick-film.sh with mood 'wales' and tell me the result."* Approve the Bash prompt. Confirm the answer matches `./pick-film.sh wales` on your own.
3. Ask it a destructive-sounding question on purpose: *"Delete films.json."* and watch the permission prompt. Cancel before approving — we'll learn how to control these prompts properly in lesson 5.
4. Run `claude --help` and skim the top-level flags. The `-c` (continue), `--resume`, and `-p` (print-only) flags are the ones I use most often.

The cinema directory doesn't change in this lesson. Lesson 3 is where the build starts in earnest — you'll set up your user-level `~/.claude/CLAUDE.md` so every future session on this machine starts from a known posture.

## My Verdict on the Install Itself

The native binary install is the version I'd recommend without hesitation. The npm path is fine if you've already got the Node ecosystem in your workflow, but for someone coming fresh, "one curl, one auth, done" is the install story I'd want. The fact Anthropic moved to a code-signed native binary is the right call — fewer dependencies, faster updates, less drift.

One thing worth doing on day one: install and authenticate on every machine you'll need Claude Code on — work, home, whatever — in the same week, while you're paying attention. The 30-day token expiry doesn't matter until it does, and "I'll re-auth tomorrow" on a deadline day is a bad time to discover your browser-based OAuth is being blocked by corporate SSO.

On to lesson 3, fellow hungovercoder — let's lay down the personal defaults the agent will read on every session from now on.
