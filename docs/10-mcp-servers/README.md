---
title: "MCP Servers"
series: claude-code
order: 10
description: "Wire Claude Code to external systems via the Model Context Protocol — GitHub, filesystem, databases, and the tap to your own services"
canonical_url: https://hungovercoders.com/training/claude-code/10-mcp-servers
---

I wanted Claude to review a pull request without me having to copy the diff into the terminal. The agent already lived in my repo; the PR already lived on GitHub; what was missing was a pipe between the two. The Model Context Protocol — MCP — is that pipe. It's an open standard for connecting AI tools to external systems, and Claude Code ships with first-class support. This lesson is how I plugged the GitHub tap in, and what it cost me in tokens to keep it running.

## Pre-Requisites

- Claude Code installed (lesson 2)
- A GitHub account with a personal access token (for the example)
- Node.js ≥ 18 if you want to install MCP servers via `npx`

## Plugging in the External Tap — What MCP Is

MCP servers run as separate processes that Claude Code connects to at startup. Each server exposes one or more *capabilities* — read files in a directory, query a database, call the GitHub API, search the web, drive a browser. The agent sees those capabilities as tools, the same way it sees built-in tools like `Read` and `Bash`.

The ecosystem is wide. The official [MCP servers repo](https://github.com/modelcontextprotocol/servers) ships reference implementations for filesystem, GitHub, GitLab, Slack, Postgres, Redis, Brave Search, Puppeteer, and more. Third parties add their own. Need an integration that doesn't exist? Write your own server in any language — the protocol is small and documented.

## Three Scopes for Config

MCP server configuration lives in one of three places:

```
Local       (default)  Per-project, private to you. CLI manages it.
Project     .mcp.json  Per-project, committed to the repo. Shared with the team.
User        ~/.claude.json  Available in every project. Personal.
```

Use project scope for servers that anyone working in the repo needs (the GitHub MCP for a repo where everyone reviews PRs). Use user scope for your personal kit (a filesystem server pointed at your notes directory). Local scope is the default when you don't pick.

## The First Tap — Filesystem MCP

The cleanest one to start with is the filesystem MCP. It gives Claude controlled, sandboxed read/write access to a directory you choose — wider than the cwd it'd normally see, but restricted to the path you authorise.

Install it for the current session:

```bash
claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem /Users/me/notes
```

Now in a Claude Code session you can ask:

```text
> Search my notes directory for anything I've written about Tiny Rebel
  brewing methods and summarise the three most useful notes.
```

The agent uses the filesystem MCP's tools (`read_file`, `list_directory`, `search_files`) to do the work. No copy-pasting; no symlinking; no faff.

## The Second Tap — GitHub MCP

The one that earned its keep fastest for me. Add it with:

```bash
claude mcp add --transport stdio \
  --env GITHUB_TOKEN=$GITHUB_TOKEN \
  github -- npx -y @modelcontextprotocol/server-github
```

Set `GITHUB_TOKEN` to a [personal access token](https://github.com/settings/tokens) with `repo` and `read:org` scopes. Now:

```text
> Review PR 142 in hungovercoders/site. Read the diff, check it against
  the project's CLAUDE.md, and tell me whether it's safe to merge.
```

The agent fetches the PR via the GitHub MCP, reads the diff, cross-references your project conventions, and gives you the verdict. The whole loop happens without you leaving the terminal. For drive-by reviews this is the killer feature.

## Project-Scope Config — `.mcp.json`

If you want every developer on a project to share MCP config, commit it to the repo. Create `.mcp.json` at the project root:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres",
               "postgresql://localhost/brewbook_dev"]
    }
  }
}
```

The `${GITHUB_TOKEN}` interpolates from the environment. **Never commit a literal token to `.mcp.json`.** The shape is "config the team agrees on; secrets each developer brings themselves".

## Listing and Removing

```bash
claude mcp list             # what's configured
claude mcp remove github    # take a server out
claude mcp restart github   # reconnect after a crash
```

A server can be added at any scope, and the resolution order is local → project → user — first match wins. If you've got a personal `github` server and the project also defines one, the project one wins inside that repo.

## The Token Cost — The Bit That Matters

Each MCP server exposes a set of tool definitions, and *every tool definition costs context tokens*. A server with twenty tools adds twenty tool descriptions to the conversation header. Stack up four or five rich servers and you've burned 70,000 tokens before your first prompt.

Two mitigations:

1. **Tool Search** — built-in to Claude Code on Sonnet 4+ and Opus 4. When tool definitions exceed 10% of the context window, the agent dynamically loads only the tool schemas it needs for the current task. Drops context usage from ~72,000 tokens to ~8,700 in the typical case. You don't need to enable this; it activates automatically when the threshold is hit.
2. **Be selective about which servers are connected.** You don't need GitHub, Postgres, Puppeteer, and Brave Search all loaded for a session that's just reading some local files. Use user scope sparingly; favour project scope so the servers are only on when you're in the right repo.

## The Bit the Docs Don't Mention

First time I added the GitHub MCP I baked the token straight into my `~/.claude.json` because the install command suggested it. Worked fine — until I realised the file was getting backed up to a sync service, and the token went with it. Lesson learned: **`.claude.json` is not a secrets store.** Use environment variables and reference them in the config, or use a per-shell secret manager that injects them at startup. The `--env GITHUB_TOKEN=$GITHUB_TOKEN` form on the install command is the right pattern.

The other quiet thing: if a server fails to start, the agent silently doesn't get its tools — there's no loud error in the session. Check `claude mcp list` early in any session if you're expecting a server to be available and the agent is acting like it isn't.

## When to Reach for an MCP Server

Not every integration belongs as an MCP server. The honest criteria:

- **Reach for MCP** when the integration is *bidirectional* and you want Claude to *operate* on it, not just read it (write to GitHub, query a live database, drive a browser)
- **Skip MCP** when a single Bash call would do the same job (`gh pr view 142 --json` is sometimes simpler than wiring the GitHub MCP)
- **Definitely use MCP** for anything you'd reach for repeatedly in the same way (review PRs, search internal docs, query a known database)

## Have a Go

Wire two servers and feel the difference.

1. Add the filesystem MCP scoped to a directory of personal notes. Ask Claude to summarise something in that directory.
2. Add the GitHub MCP (with a token from a throwaway scope if you're nervous). Ask Claude to review an open PR.
3. Create a project-scope `.mcp.json` for one of your repos. Confirm it's used inside that repo and not elsewhere.
4. Run `claude mcp list` and consider which servers are *always* worth the context cost vs *sometimes* worth it. Remove the sometimes ones.

## My Verdict on MCP

MCP is the most leverage-per-line-of-config feature in Claude Code. One install command brings a whole external system into the agent's reach, and the ecosystem is wide enough that the integration you want probably already exists. The protocol being open means anyone can write a server; the protocol being small means doing so is a weekend project, not a quarter.

The cost discipline matters. Token cost compounds across servers, and it's easy to end up with a session that's 60% tool definitions before you've typed anything. The 10% Tool Search threshold helps, but the right habit is: *use the smallest set of MCP servers that does the job*.

What I'd do differently next time: I'd resist the urge to install every MCP server I read about. Twenty servers in `~/.claude.json` is a costume; three well-chosen ones in a per-project `.mcp.json` is a tool.

On to lesson 11, fellow hungovercoder — let's pour the whole round.
