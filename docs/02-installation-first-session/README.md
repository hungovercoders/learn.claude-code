---
title: "Installation and First Session"
series: claude-code
order: 2
description: "Install Claude Code, log in, and run the first session that proves the agent is actually doing something"
canonical_url: https://hungovercoders.com/training/claude-code/02-installation-first-session
---

I wanted Claude Code on my machine in less than ten minutes, with no surprises. I'd seen enough "just `npm install -g` and you're away" blog posts to know they usually leave out the bit where the binary isn't on your PATH and you spend a quarter of an hour wondering whether you've broken `node`. So I went looking for the cleanest install path in 2026 — and it turns out Anthropic now ship a native binary that bypasses the npm faff entirely. Let's pour the first one.

## Pre-Requisites

- macOS, Linux, or Windows (with WSL)
- A Claude.ai account on the Pro plan or higher (Claude Code isn't on the free tier)
- A terminal you actually like — iTerm2, Warp, Ghostty, whatever
- A real project repo to point it at (any git repo will do)
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
✓ Authenticated as you@example.com
```

The token gets stored in `~/.claude/config.json` (AES-256 encrypted). It stays active for 30 days of inactivity — so if you take a long holiday, expect to re-auth when you get back. Not a problem; the holiday is the point.

**Headless setup.** If you're on a server, in a Docker container, or in CI where there's no browser to open, set an API key instead:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
claude
```

Claude Code will use the key and skip the OAuth dance.

## First Sip — A Real Session

The fastest way to feel what Claude Code is for is to point it at a real repo. Open a project — any project — and run:

```bash
cd ~/code/your-project
claude
```

You'll get a prompt that looks like a TUI chat. Type a real task. Try something it has to actually *do*, not just describe:

```text
> Look in src/ and tell me which file has the most TODO comments,
  then read me the first three lines of each TODO.
```

What you'll see is a sequence of tool calls — `Bash grep`, then `Read` on each file it finds, then a summary at the end. Each tool call asks for your permission the first time it hits a new category. **Read each prompt before clicking through.** This is the muscle you want to build before lesson 3 turns the permission system into the proper bouncer.

## The Bit the Docs Don't Mention

First time I ran Claude Code I assumed it would behave like the chat window — type a question, get an answer, move on. The mental adjustment that took me about a session to make: **it's an agent, not a chatbot.** When you ask it something, it doesn't immediately answer — it starts *doing*. It reads files, runs greps, kicks off bash. The "response" is the result of work it actually performed. That's the whole point but it feels surprising the first time because the chat-window habits run deep.

The corollary: the more concrete your request, the better. "Improve my code" leaves it guessing what to do. "Find all the places we set a `Content-Type` header and tell me which ones use a different value to the rest" gives it a job. Once you start writing requests like the second one, the agent earns its keep fast.

## Have a Go

Try these before moving on. Don't read the next lesson until you've done at least the first three.

1. Install Claude Code via the native binary and confirm `claude --version` returns a version.
2. Run `claude` in any git repo and ask it: *"What does this project do, in one paragraph?"*. Notice how it reads `README.md` before answering.
3. Ask it a destructive-sounding question on purpose: *"Delete every file in `node_modules`."* and watch the permission prompt. Cancel before approving — we'll learn how to control these prompts properly in the next lesson.
4. Run `claude --help` and skim the top-level flags. The `-c` (continue), `--resume`, and `-p` (print-only) flags are the ones I use most often.

## My Verdict on the Install Itself

The native binary install is the version I'd recommend without hesitation. The npm path is fine if you've already got the Node ecosystem in your workflow, but for someone coming fresh, "one curl, one auth, done" is the install story I'd want. The fact Anthropic moved to a code-signed native binary is the right call — fewer dependencies, faster updates, less drift.

One thing I'd do differently next time: I'd run the install on my work machine *and* my home machine on the same evening, and confirm both auth flows work, before relying on it for any real work. The 30-day token expiry doesn't matter until it does — and "I'll re-auth tomorrow" on a deadline day is a bad time to discover your browser-based OAuth is being blocked by corporate SSO.

On to lesson 3, fellow hungovercoder — let's lock the cellar before someone helps themselves.
